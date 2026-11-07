process.env.NODE_ENV = 'test';
import esbuild from 'esbuild';
import test from 'node:test';
import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const workerRoot = path.resolve(__dirname, '..');

// Helper to bundle worker app
async function buildTestApp() {
  const bundlePath = path.join(workerRoot, 'node_modules', '.test_app_bundle_telemetry_accuracy.mjs');
  esbuild.buildSync({
    entryPoints: [path.join(workerRoot, 'src', 'index.ts')],
    bundle: true,
    format: 'esm',
    platform: 'node',
    write: true,
    outfile: bundlePath,
  });

  const { default: app } = await import(`file://${bundlePath}`);
  return app;
}

function createStatement(sqliteDb, sql, boundArgs = []) {
  return {
    bind(...args) {
      return createStatement(sqliteDb, sql, args);
    },
    async first(col) {
      const stmt = sqliteDb.prepare(sql);
      const row = stmt.get(...boundArgs);
      if (!row) return null;
      if (col) return row[col];
      return row;
    },
    async all() {
      const stmt = sqliteDb.prepare(sql);
      const results = stmt.all(...boundArgs);
      return { results, success: true, meta: { changes: 0 } };
    },
    async run() {
      const stmt = sqliteDb.prepare(sql);
      const info = stmt.run(...boundArgs);
      return { success: true, meta: { changes: info.changes, last_row_id: Number(info.lastInsertRowid) } };
    }
  };
}

function createD1Adapter(sqliteDb) {
  return {
    prepare(sql) {
      return createStatement(sqliteDb, sql);
    },
    async batch(statements) {
      const results = [];
      for (const s of statements) {
        results.push(await s.all());
      }
      return results;
    },
    async exec(sql) {
      sqliteDb.exec(sql);
      return { count: 1, duration: 0 };
    }
  };
}

// Minimal R2 Mock for testing
function createMockR2() {
  return {
    async list(options) {
      return {
        objects: [
          { key: 'drawings/test1.dwg', size: 2458920 },
          { key: 'drawings/test2.dwg', size: 2461040 },
        ],
        truncated: false,
      };
    },
    async get(key) {
      return null;
    },
    async put(key, value) {
      return { key };
    },
  };
}

// Load SQLite DB from Miniflare state
function getMiniflareDb() {
  const dbPath = path.join(
    workerRoot,
    '.wrangler',
    'state',
    'v3',
    'd1',
    'miniflare-D1DatabaseObject',
    'fdc94e68165493d9beefe9c542c3ccf242c09e8c388eef5ade0878b760405048.sqlite'
  );
  return new DatabaseSync(dbPath);
}

test('SYSTEM-WIDE DATA ACCURACY & LIVE SYNCHRONIZATION TEST SUITE', async (t) => {
  const app = await buildTestApp();
  const db = getMiniflareDb();
  const wrappedDb = createD1Adapter(db);
  const mockR2 = createMockR2();

  const adminUid = 'bCrLwG8lMRbViDOrBmClwc96xJ42'; // Admin user in D1
  const engineerUid = 'TJjtkBm3lgRlpKtcI5u3jpYPH9s1'; // Engineer user in D1

  const env = {
    DB: wrappedDb,
    STORAGE: mockR2,
    ENVIRONMENT: 'development',
    FIREBASE_PROJECT_ID: 'archi-draft-staging',
    ALLOWED_ORIGINS: 'http://localhost:3000,http://localhost:8787',
  };

  async function testRequest(path, options = {}) {
    const headers = { ...options.headers };
    if (options.token) {
      headers['Authorization'] = `Bearer mock-token:${options.token}`;
    }
    return app.request(path, {
      method: options.method || 'GET',
      headers,
      body: options.body ? JSON.stringify(options.body) : undefined
    }, env);
  }

  await t.test('1. Authoritative Storage Telemetry accurately reports genuine R2 storage and unprovisioned S3', async () => {
    const res = await testRequest('/api/admin/system/telemetry', { token: adminUid });

    assert.equal(res.status, 200, 'Admin should receive 200 OK');
    const data = await res.json();

    assert.equal(data.success, true);
    assert.ok(data.storage, 'Storage telemetry must be present');
    assert.equal(data.storage.provider, 'Cloudflare R2 Object Storage');
    assert.equal(data.storage.totalFiles, 7, 'Must report exact 7 files from files table');
    assert.equal(data.storage.totalBytes, 17351088, 'Must report exact 17,351,088 bytes (~16.55 MB)');
    assert.equal(data.storage.formattedTotalSize, '16.55 MB', 'Must correctly format binary/IEC MB');

    // Storage categories
    assert.ok(Array.isArray(data.storage.categories));
    assert.equal(data.storage.categories.length, 2);
    const drawingCat = data.storage.categories.find(c => c.category === 'DRAWING_VERSION');
    assert.ok(drawingCat);
    assert.equal(drawingCat.count, 4);
    assert.equal(drawingCat.totalBytes, 11215688);

    const studentCat = data.storage.categories.find(c => c.category === 'STUDENT_PRACTICAL');
    assert.ok(studentCat);
    assert.equal(studentCat.count, 3);
    assert.equal(studentCat.totalBytes, 6135400);

    // Dynamic Utility Quota verification (No fixed 10 TB limit)
    assert.equal(data.storage.quota.hasFixedQuota, false, 'R2 has no fixed 10 TB quota ceiling');
    assert.equal(data.storage.quota.model, 'DYNAMIC_UTILITY_BILLING');

    // External S3 CAD Vault verification
    assert.equal(data.storage.s3Status.configured, false, 'External S3 CAD Vault must be NOT CONFIGURED');
    assert.equal(data.storage.s3Status.status, 'NOT_CONFIGURED');
  });

  await t.test('2. Infrastructure Telemetry accurately reports Standalone CAD Engine and D1 Clean FK Integrity', async () => {
    const res = await testRequest('/api/admin/system/telemetry', { token: adminUid });
    const data = await res.json();

    assert.ok(data.infrastructure, 'Infrastructure telemetry must be present');
    assert.equal(data.infrastructure.workerGateway.status, 'ONLINE');
    assert.equal(data.infrastructure.database.status, 'ONLINE');
    assert.equal(data.infrastructure.database.foreignKeyCheck.status, 'CLEAN');
    assert.equal(data.infrastructure.database.foreignKeyCheck.violations, 0);

    // CAD Engine verification
    assert.equal(data.infrastructure.cadEngine.status, 'ONLINE');
    assert.equal(data.infrastructure.cadEngine.mode, 'STANDALONE (Local R2 Vector / Raster Streaming)');
    assert.equal(data.infrastructure.cadEngine.externalForgeApi.status, 'NOT_CONFIGURED');
  });

  await t.test('3. Statutory Legal Business Profile is distinct from Session Administrator', async () => {
    const res = await testRequest('/api/admin/system/telemetry', { token: adminUid });
    const data = await res.json();

    assert.ok(data.legalBusinessProfile, 'Legal business profile must be present');
    assert.equal(data.legalBusinessProfile.legalProprietor, 'MOHAMMED MOSIN S');
    assert.equal(data.legalBusinessProfile.operatingBrand, 'DRAUGHTSMAN STUDIO');
    assert.equal(data.legalBusinessProfile.productName, 'ARCHI DRAFT');
    assert.equal(data.legalBusinessProfile.supportEmail, 'support@draughtsmanstudio.com');
    assert.equal(data.legalBusinessProfile.grievanceEmail, 'mosin@draughtsmanstudio.com');
    assert.equal(data.legalBusinessProfile.physicalAddressStatus, 'PENDING_VERIFICATION');
    assert.equal(data.legalBusinessProfile.grievanceOfficerName, 'PENDING_VERIFICATION');

    // Session Admin distinction
    assert.ok(data.sessionAdmin, 'Session admin must be present');
    assert.equal(data.sessionAdmin.isDistinctFromProprietor, true);
    assert.ok(['ADMIN', 'STUDIO_ADMIN'].includes(data.sessionAdmin.role));
  });

  await t.test('4. Admin Financials Ledger accurately reflects D1 Invoices & Payments in Indian Rupees (INR)', async () => {
    const res = await testRequest('/api/admin/financials', { token: adminUid });

    assert.equal(res.status, 200, 'Should return 200 OK');
    const data = await res.json();

    assert.equal(data.success, true);
    assert.equal(data.currency, 'INR');
    assert.equal(data.currencySymbol, '₹');

    // Summary calculations
    assert.equal(data.summary.totalInvoiced, 113000, 'Total Invoiced: ₹45,000 + ₹68,000 = ₹1,13,000');
    assert.equal(data.summary.totalCollected, 113000, 'Total Collected: ₹45,000 + ₹68,000 = ₹1,13,000');
    assert.equal(data.summary.totalOutstanding, 0, 'Total Outstanding: ₹0');
    assert.equal(data.summary.collectionRate, 100, 'Collection Rate: 100%');
    assert.equal(data.summary.invoiceCount, 2);
    assert.equal(data.summary.paymentCount, 2);

    // Invoices list
    assert.equal(data.invoices.length, 2);
    const inv1 = data.invoices.find(i => i.invoice_number === 'INV-2026-0001');
    assert.ok(inv1, 'INV-2026-0001 must exist');
    assert.equal(inv1.amount, 45000);
    assert.equal(inv1.currency, 'INR');
    assert.equal(inv1.status, 'PAID');

    const inv2 = data.invoices.find(i => i.invoice_number === 'INV-2026-0002');
    assert.ok(inv2, 'INV-2026-0002 must exist');
    assert.equal(inv2.amount, 68000);
    assert.equal(inv2.currency, 'INR');
    assert.equal(inv2.status, 'PAID');

    // Payments list
    assert.equal(data.payments.length, 2);
    const pay1 = data.payments.find(p => p.id === 'pay-c74d-01');
    assert.ok(pay1);
    assert.equal(pay1.amount, 45000);
    assert.equal(pay1.payment_method, 'BANK_TRANSFER');

    const pay2 = data.payments.find(p => p.id === 'pay-08e9-01');
    assert.ok(pay2);
    assert.equal(pay2.amount, 68000);
    assert.equal(pay2.payment_method, 'NEFT');
  });

  await t.test('5. RBAC Security: Non-Admin role cannot access system telemetry or financials', async () => {
    // Engineer attempting to access telemetry
    const res1 = await testRequest('/api/admin/system/telemetry', { token: engineerUid });
    assert.equal(res1.status, 403, 'Non-admin must be rejected with 403 Forbidden');

    // Engineer attempting to access financials
    const res2 = await testRequest('/api/admin/financials', { token: engineerUid });
    assert.equal(res2.status, 403, 'Non-admin must be rejected with 403 Forbidden');
  });
});
