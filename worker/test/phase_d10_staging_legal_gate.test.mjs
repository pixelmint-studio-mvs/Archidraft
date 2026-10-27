import test from 'node:test';
import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import esbuild from 'esbuild';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const workerRoot = path.resolve(__dirname, '..');

process.env.NODE_ENV = 'test';

const bundlePath = path.join(workerRoot, 'node_modules', '.test_app_bundle_phase_d10_legal.mjs');
esbuild.buildSync({
  entryPoints: [path.join(workerRoot, 'src', 'index.ts')],
  bundle: true,
  format: 'esm',
  platform: 'node',
  write: true,
  outfile: bundlePath,
});

const { default: app } = await import(`file://${bundlePath}`);
const { assertTermsAccepted } = await import(`file://${bundlePath}`);

function createIsolatedTestDb() {
  const db = new DatabaseSync(':memory:');
  const migrationsDir = path.join(workerRoot, 'migrations');
  const migrationFiles = fs.readdirSync(migrationsDir)
    .filter(f => f.endsWith('.sql'))
    .sort();

  for (const file of migrationFiles) {
    const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf8');
    db.exec(sql);
  }

  const d1 = {
    prepare(sql) {
      return {
        bind(...params) {
          return {
            async first() {
              const stmt = db.prepare(sql);
              return stmt.get(...params);
            },
            async all() {
              const stmt = db.prepare(sql);
              return { results: stmt.all(...params) };
            },
            async run() {
              const stmt = db.prepare(sql);
              const info = stmt.run(...params);
              return { success: true, meta: { changes: info.changes } };
            }
          };
        },
        async first() {
          const stmt = db.prepare(sql);
          return stmt.get();
        },
        async all() {
          const stmt = db.prepare(sql);
          return { results: stmt.all() };
        },
        async run() {
          const stmt = db.prepare(sql);
          const info = stmt.run();
          return { success: true, meta: { changes: info.changes } };
        }
      };
    },
    async batch(statements) {
      const results = [];
      db.exec('BEGIN TRANSACTION');
      try {
        for (const s of statements) {
          results.push(await s.run());
        }
        db.exec('COMMIT');
        return results;
      } catch (err) {
        db.exec('ROLLBACK');
        throw err;
      }
    },
    _rawDb: db
  };

  return d1;
}

test('PHASE D.10.3: Staging-Only Controlled Test-Acceptance Mechanism Suite', async (t) => {
  const db = createIsolatedTestDb();

  const STAGING_ENGINEER_UID = 'KXAR90JgoVYLuOKzkbxpKTC8ATa2';
  const STAGING_DRAUGHTSMAN_UID = 'TJjtkBm3lgRlpKtcI5u3jpYPH9s1';
  const ARBITRARY_USER_UID = 'arbitrary-user-uuid-999999999';

  await t.test('1. Production isolation: Impossible to activate in production environment', async () => {
    // Even with the test header and an authorized staging UID, production MUST fail closed
    const res = await assertTermsAccepted(db, STAGING_ENGINEER_UID, 'ENGINEER', {
      environment: 'production',
      testModeHeader: 'workflow-e2e',
    });

    assert.equal(res.ok, false);
    assert.ok(res.errorResponse.status === 403 || res.errorResponse.status === 503);
    assert.ok(res.errorResponse.code === 'TERMS_ACCEPTANCE_REQUIRED' || res.errorResponse.code === 'TERMS_MAINTENANCE_MODE');
  });

  await t.test('2. Fail-closed on missing, empty, or ambiguous environment', async () => {
    // Missing environment
    const resMissing = await assertTermsAccepted(db, STAGING_ENGINEER_UID, 'ENGINEER', {
      testModeHeader: 'workflow-e2e',
    });
    assert.equal(resMissing.ok, false);
    assert.ok(resMissing.errorResponse.status === 403 || resMissing.errorResponse.status === 503);
    assert.ok(resMissing.errorResponse.code === 'TERMS_ACCEPTANCE_REQUIRED' || resMissing.errorResponse.code === 'TERMS_MAINTENANCE_MODE');

    // Empty environment string
    const resEmpty = await assertTermsAccepted(db, STAGING_ENGINEER_UID, 'ENGINEER', {
      environment: '',
      testModeHeader: 'workflow-e2e',
    });
    assert.equal(resEmpty.ok, false);
    assert.ok(resEmpty.errorResponse.status === 403 || resEmpty.errorResponse.status === 503);

    // Development or test environment without explicit 'staging' match
    const resDev = await assertTermsAccepted(db, STAGING_ENGINEER_UID, 'ENGINEER', {
      environment: 'development',
      testModeHeader: 'workflow-e2e',
    });
    assert.equal(resDev.ok, false);
    assert.ok(resDev.errorResponse.status === 403 || resDev.errorResponse.status === 503);
  });

  await t.test('3. Staging environment without required test header fails closed', async () => {
    // Header omitted
    const resNoHeader = await assertTermsAccepted(db, STAGING_ENGINEER_UID, 'ENGINEER', {
      environment: 'staging',
      testModeHeader: null,
    });
    assert.equal(resNoHeader.ok, false);
    assert.ok(resNoHeader.errorResponse.status === 403 || resNoHeader.errorResponse.status === 503);
    assert.ok(resNoHeader.errorResponse.code === 'TERMS_ACCEPTANCE_REQUIRED' || resNoHeader.errorResponse.code === 'TERMS_MAINTENANCE_MODE');

    // Header has incorrect / invalid value
    const resWrongHeader = await assertTermsAccepted(db, STAGING_ENGINEER_UID, 'ENGINEER', {
      environment: 'staging',
      testModeHeader: 'invalid-header-token',
    });
    assert.equal(resWrongHeader.ok, false);
    assert.ok(resWrongHeader.errorResponse.status === 403 || resWrongHeader.errorResponse.status === 503);
  });

  await t.test('4. Staging environment with arbitrary user (not in test allowlist) fails closed', async () => {
    const resArbitrary = await assertTermsAccepted(db, ARBITRARY_USER_UID, 'ENGINEER', {
      environment: 'staging',
      testModeHeader: 'workflow-e2e',
    });
    assert.equal(resArbitrary.ok, false);
    assert.ok(resArbitrary.errorResponse.status === 403 || resArbitrary.errorResponse.status === 503);
    assert.ok(resArbitrary.errorResponse.code === 'TERMS_ACCEPTANCE_REQUIRED' || resArbitrary.errorResponse.code === 'TERMS_MAINTENANCE_MODE');
  });

  await t.test('5. Staging environment with verified test accounts and test header succeeds', async () => {
    // Engineer test account
    const resEng = await assertTermsAccepted(db, STAGING_ENGINEER_UID, 'ENGINEER', {
      environment: 'staging',
      testModeHeader: 'workflow-e2e',
    });
    assert.equal(resEng.ok, true);

    // Draughtsman test account
    const resDman = await assertTermsAccepted(db, STAGING_DRAUGHTSMAN_UID, 'DRAUGHTSMAN', {
      environment: 'staging',
      testModeHeader: 'workflow-e2e',
    });
    assert.equal(resDman.ok, true);
  });

  await t.test('6. Consent state invariance: Test mode never creates fabricated consent records', async () => {
    const consentRows = db._rawDb.prepare('SELECT count(*) as count FROM user_consent_state').get();
    assert.equal(consentRows.count, 0, 'Must have zero rows in user_consent_state');

    const eventRows = db._rawDb.prepare('SELECT count(*) as count FROM legal_consent_events').get();
    assert.equal(eventRows.count, 0, 'Must have zero rows in legal_consent_events');
  });

  await t.test('7. Admin roles remain exempt regardless of environment', async () => {
    const resAdminProd = await assertTermsAccepted(db, 'admin-1', 'ADMIN', {
      environment: 'production',
    });
    assert.equal(resAdminProd.ok, true);

    const resStudioAdmin = await assertTermsAccepted(db, 'studio-admin-1', 'STUDIO_ADMIN', {
      environment: 'staging',
    });
    assert.equal(resStudioAdmin.ok, true);
  });
});
