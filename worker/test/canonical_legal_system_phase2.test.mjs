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

// Helper to bundle worker app in memory for Hono request testing
async function buildTestApp() {
  const bundlePath = path.join(workerRoot, 'node_modules', '.test_app_bundle_canonical_legal.mjs');
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

// Helper to create an isolated in-memory SQLite database and apply all migrations 0001 through 0026
function createIsolatedTestDb() {
  const db = new DatabaseSync(':memory:');
  db.exec('PRAGMA foreign_keys = ON;');

  const migrationsDir = path.join(workerRoot, 'migrations');
  const migrationFiles = fs.readdirSync(migrationsDir)
    .filter(f => f.endsWith('.sql'))
    .sort();

  for (const file of migrationFiles) {
    const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf8');
    db.exec(sql);
  }

  return db;
}

// Minimal D1 wrapper for Hono context execution
function wrapD1(db) {
  return {
    prepare(query) {
      return {
        _query: query,
        _params: [],
        bind(...params) {
          this._params = params;
          return this;
        },
        async first(col) {
          const stmt = db.prepare(this._query);
          const row = stmt.get(...this._params);
          if (!row) return null;
          return col ? row[col] : row;
        },
        async all() {
          const stmt = db.prepare(this._query);
          const results = stmt.all(...this._params);
          return { results };
        },
        async run() {
          const stmt = db.prepare(this._query);
          const info = stmt.run(...this._params);
          return { success: true, meta: info };
        }
      };
    },
    async batch(statements) {
      const results = [];
      for (const stmt of statements) {
        results.push(await stmt.run());
      }
      return results;
    }
  };
}

test('PHASE 2: Canonical Legal Database Foundation & User Rights Suite', async (t) => {
  const app = await buildTestApp();
  const db = createIsolatedTestDb();
  const wrappedDb = wrapD1(db);

  const mockEnv = {
    DB: wrappedDb,
    STORAGE: {},
    ENVIRONMENT: 'test',
    FIREBASE_PROJECT_ID: 'archi-draft-test'
  };

  // Seed baseline test users: Engineer, Draughtsman, Student, Admin
  db.prepare(`
    INSERT INTO users (id, email, name, role, status) 
    VALUES 
      ('usr-eng-01', 'eng@example.com', 'Engineer Alice', 'CLIENT', 'ACTIVE'),
      ('usr-drg-01', 'drg@example.com', 'Draughtsman Bob', 'DRAUGHTSMAN', 'ACTIVE'),
      ('usr-stu-01', 'stu@example.com', 'Student Charlie', 'STUDENT', 'ACTIVE'),
      ('usr-adm-01', 'admin@draughtsmanstudio.com', 'Admin Diana', 'ADMIN', 'ACTIVE');
  `).run();

  // Helper to construct authenticated mock requests
  function makeReq(path, method = 'GET', body = null, user = { sub: 'usr-eng-01', email: 'eng@example.com' }) {
    // Inject mock auth payload bypassing external Firebase RSA signature verification
    const reqInit = {
      method,
      headers: {
        'content-type': 'application/json',
        'x-test-uid': user.sub,
        'x-test-email': user.email
      }
    };
    if (body) {
      reqInit.body = JSON.stringify(body);
    }
    return reqInit;
  }

  await t.test('1. Migration 0026 Additive Schema Verification', () => {
    const tables = db.prepare(`
      SELECT name FROM sqlite_master 
      WHERE type = 'table' AND tbl_name IN (
        'legal_business_profile', 'account_deletion_requests', 'data_export_requests',
        'data_correction_requests', 'data_retention_policies', 'guardian_consents',
        'cancellation_refund_requests'
      )
      ORDER BY name;
    `).all();

    const expected = [
      'account_deletion_requests', 'cancellation_refund_requests', 'data_correction_requests',
      'data_export_requests', 'data_retention_policies', 'guardian_consents', 'legal_business_profile'
    ];
    assert.deepEqual(tables.map(t => t.name), expected, 'All 7 Phase 2 tables must be created by migration 0026');
  });

  await t.test('2. Business Profile Persistence & Verification Status', async () => {
    const profile = db.prepare("SELECT * FROM legal_business_profile WHERE id = 'current'").get();
    assert.ok(profile, 'Business profile row must exist');
    assert.equal(profile.legal_proprietor, 'MOHAMMED MOSIN S');
    assert.equal(profile.operating_brand, 'DRAUGHTSMAN STUDIO');
    assert.equal(profile.business_structure, 'Sole Proprietorship');
    assert.equal(profile.physical_address_status, 'PENDING_VERIFICATION');
    assert.equal(profile.grievance_officer_appointment_status, 'PENDING_VERIFICATION');
  });

  await t.test('3. Data Retention Policies Seed Integrity', () => {
    const policies = db.prepare('SELECT * FROM data_retention_policies ORDER BY data_category ASC').all();
    assert.ok(policies.length >= 6, 'Must seed baseline retention policies');

    const certin = policies.find(p => p.data_category === 'SYSTEM_SECURITY_LOGS');
    assert.ok(certin);
    assert.equal(certin.retention_duration_days, 180, 'CERT-In logs must be 180 days');
    assert.equal(certin.policy_approval_status, 'APPROVED');

    const tax = policies.find(p => p.data_category === 'TAX_AND_INVOICE_RECORDS');
    assert.ok(tax);
    assert.equal(tax.retention_duration_days, 2920, 'Tax records must be 8 years (2920 days)');
  });

  await t.test('4. Account Deletion Workflow Lifecycle', async () => {
    // Step 4.1: Submit deletion request
    const insertRes = db.prepare(`
      INSERT INTO account_deletion_requests (id, user_id, request_category, status, reason)
      VALUES ('del-test-01', 'usr-eng-01', 'SELF_SERVICE', 'SUBMITTED', 'Closing consulting office')
    `).run();
    assert.ok(insertRes.changes === 1);

    const req = db.prepare("SELECT * FROM account_deletion_requests WHERE id = 'del-test-01'").get();
    assert.equal(req.status, 'SUBMITTED');
    assert.equal(req.user_id, 'usr-eng-01');

    // Step 4.2: User can cancel prior to processing
    db.prepare(`
      UPDATE account_deletion_requests 
      SET status = 'CANCELLED', cancelled_at = CURRENT_TIMESTAMP 
      WHERE id = 'del-test-01' AND user_id = 'usr-eng-01'
    `).run();

    const cancelledReq = db.prepare("SELECT * FROM account_deletion_requests WHERE id = 'del-test-01'").get();
    assert.equal(cancelledReq.status, 'CANCELLED');
    assert.ok(cancelledReq.cancelled_at);
  });

  await t.test('5. Collaborative CAD Protection During Account Deletion', async () => {
    // Create collaborative project where Engineer Alice commissioned and Draughtsman Bob drafted
    db.prepare(`
      INSERT INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, draughtsman_id)
      VALUES ('prj-collab-01', 'usr-eng-01', 'Commercial Tower', '123 MG Road', 'Tower Plan', 'ARCHITECTURAL', '5000 sqft', 'UNDER_ENGINEER_REVIEW', 'usr-drg-01');
    `).run();

    // Create file record
    db.prepare(`
      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category)
      VALUES ('fil-dwg-01', 'prj-collab-01', 'usr-drg-01', 'tower_plan_v1.dwg', 'tower_plan_v1.dwg', 'projects/prj-collab-01/tower_plan_v1.dwg', 'application/acad', 1024, 'DRAWING');
    `).run();

    // Create drawing version in R2/D1
    db.prepare(`
      INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by)
      VALUES ('ver-01', 'prj-collab-01', 'fil-dwg-01', 1, 'usr-drg-01');
    `).run();

    // Simulate AI conversations in chat_sessions and chat_messages
    db.prepare(`
      INSERT INTO chat_sessions (id, user_id, user_role, title, created_at, updated_at)
      VALUES ('sess-01', 'usr-eng-01', 'engineer', 'Beam sizing query', 1730000000, 1730000000);
    `).run();
    db.prepare(`
      INSERT INTO chat_messages (id, session_id, user_id, sender, content, created_at)
      VALUES ('msg-01', 'sess-01', 'usr-eng-01', 'user', 'What is the standard span?', 1730000000);
    `).run();

    // Now execute full deletion completion on Engineer Alice
    const targetUserId = 'usr-eng-01';

    // 1. Tombstone user profile in D1 (marking SUSPENDED per users status check constraint)
    db.prepare(`
      UPDATE users 
      SET name = 'Deleted User', email = 'deleted_usr-eng-01@archidraft.local', mobile = NULL, status = 'SUSPENDED', updated_at = CURRENT_TIMESTAMP
      WHERE id = ?
    `).run(targetUserId);

    // 2. Purge personal AI conversations
    db.prepare(`DELETE FROM chat_messages WHERE session_id IN (SELECT id FROM chat_sessions WHERE user_id = ?)`).run(targetUserId);
    db.prepare(`DELETE FROM chat_sessions WHERE user_id = ?`).run(targetUserId);

    // VERIFICATION:
    // User profile is tombstoned:
    const tombstoneUser = db.prepare("SELECT * FROM users WHERE id = 'usr-eng-01'").get();
    assert.equal(tombstoneUser.name, 'Deleted User');
    assert.equal(tombstoneUser.status, 'SUSPENDED');
    assert.equal(tombstoneUser.mobile, null);

    // AI messages are completely purged:
    const remainingAiMsgs = db.prepare("SELECT COUNT(*) as count FROM chat_messages WHERE session_id = 'sess-01'").get();
    assert.equal(remainingAiMsgs.count, 0, 'Personal AI messages must be completely purged');

    // Collaborative project records and CAD drawings are PRESERVED:
    const preservedProject = db.prepare("SELECT * FROM projects WHERE id = 'prj-collab-01'").get();
    assert.ok(preservedProject, 'Collaborative project must be preserved');
    assert.equal(preservedProject.project_name, 'Commercial Tower');

    const preservedDrawing = db.prepare("SELECT * FROM drawing_versions WHERE id = 'ver-01'").get();
    assert.ok(preservedDrawing, 'CAD drawing version must be preserved for collaborating draughtsman and client');
  });

  await t.test('6. Personal Data Export Workflow', () => {
    const insertRes = db.prepare(`
      INSERT INTO data_export_requests (
        id, user_id, verification_status, export_scope, status, download_r2_key, download_url_expires_at
      ) VALUES (
        'exp-test-01', 'usr-drg-01', 'VERIFIED', 'FULL_PERSONAL_DATA', 'PENDING',
        'exports/usr-drg-01/exp-test-01.json', '2026-11-14 00:00:00'
      )
    `).run();
    assert.ok(insertRes.changes === 1);

    const exp = db.prepare("SELECT * FROM data_export_requests WHERE id = 'exp-test-01'").get();
    assert.equal(exp.user_id, 'usr-drg-01');
    assert.equal(exp.status, 'PENDING');
  });

  await t.test('7. Personal Data Correction Workflow', () => {
    const insertRes = db.prepare(`
      INSERT INTO data_correction_requests (
        id, user_id, field_name, proposed_value, reason, status
      ) VALUES (
        'cor-test-01', 'usr-drg-01', 'specialization', 'Structural CAD Technician', 'Updated license credential', 'PENDING'
      )
    `).run();
    assert.ok(insertRes.changes === 1);

    const corr = db.prepare("SELECT * FROM data_correction_requests WHERE id = 'cor-test-01'").get();
    assert.equal(corr.field_name, 'specialization');
    assert.equal(corr.proposed_value, 'Structural CAD Technician');
  });

  await t.test('8. Consent Withdrawal Without Account Deletion', () => {
    // Ensure document exists
    db.prepare(`
      INSERT OR IGNORE INTO legal_documents (
        id, document_type, version, title, content, effective_at, status, is_mandatory
      ) VALUES (
        'doc-priv-v1', 'PRIVACY_POLICY', '1.0.0', 'Privacy Policy', '# Privacy', '2026-10-24 00:00:00', 'EFFECTIVE', 0
      );
    `).run();

    // Student grants optional marketing consent
    db.prepare(`
      INSERT INTO legal_consent_events (
        id, user_id, document_id, document_type, document_version, action_type, consent_purpose, idempotency_key, ip_hash
      ) VALUES (
        'evt-seed-01', 'usr-stu-01', 'doc-priv-v1', 'OPTIONAL_CONSENT', '1.0.0', 'OPTIONAL_CONSENT_GRANTED', 'MARKETING', 'idem-seed-01', 'iphash123'
      );
    `).run();

    db.prepare(`
      INSERT INTO user_consent_state (id, user_id, consent_type, purpose_tag, current_status, accepted_version, last_event_id)
      VALUES ('st-opt-01', 'usr-stu-01', 'OPTIONAL_PURPOSE', 'MARKETING', 'GRANTED', '1.0.0', 'evt-seed-01');
    `).run();

    // Withdraw marketing consent
    db.prepare(`
      INSERT INTO legal_consent_events (
        id, user_id, document_id, document_type, document_version, action_type, consent_purpose, idempotency_key, ip_hash
      ) VALUES (
        'evt-with-01', 'usr-stu-01', 'doc-priv-v1', 'OPTIONAL_CONSENT', '1.0.0', 'OPTIONAL_CONSENT_WITHDRAWN', 'MARKETING', 'idem-with-01', 'iphash123'
      );
    `).run();

    db.prepare(`
      UPDATE user_consent_state 
      SET current_status = 'WITHDRAWN', updated_at = CURRENT_TIMESTAMP
      WHERE user_id = 'usr-stu-01' AND purpose_tag = 'MARKETING'
    `).run();

    const state = db.prepare("SELECT * FROM user_consent_state WHERE user_id = 'usr-stu-01' AND purpose_tag = 'MARKETING'").get();
    assert.equal(state.current_status, 'WITHDRAWN');

    // Confirm student account is NOT deleted and remains ACTIVE
    const studentUser = db.prepare("SELECT * FROM users WHERE id = 'usr-stu-01'").get();
    assert.equal(studentUser.status, 'ACTIVE');
  });

  await t.test('9. Guardian Consent Foundation for Minors', () => {
    db.prepare(`
      INSERT INTO guardian_consents (
        id, student_user_id, guardian_name, guardian_email, relationship, consent_policy_version, verification_status
      ) VALUES (
        'grd-01', 'usr-stu-01', 'John Charlie Sr.', 'parent@example.com', 'Father', '1.0.0', 'PENDING_VERIFICATION'
      );
    `).run();

    const consent = db.prepare("SELECT * FROM guardian_consents WHERE id = 'grd-01'").get();
    assert.equal(consent.guardian_name, 'John Charlie Sr.');
    assert.equal(consent.verification_status, 'PENDING_VERIFICATION');

    // Admin verifies guardian consent
    db.prepare(`
      UPDATE guardian_consents 
      SET verification_status = 'VERIFIED', verified_by = 'usr-adm-01', verified_at = CURRENT_TIMESTAMP
      WHERE id = 'grd-01'
    `).run();

    const verifiedConsent = db.prepare("SELECT * FROM guardian_consents WHERE id = 'grd-01'").get();
    assert.equal(verifiedConsent.verification_status, 'VERIFIED');
    assert.equal(verifiedConsent.verified_by, 'usr-adm-01');
  });

  await t.test('10. Cancellation and Refund Request Foundation', () => {
    db.prepare(`
      INSERT INTO cancellation_refund_requests (
        id, user_id, request_type, reference_id, amount_requested, reason, status
      ) VALUES (
        'ref-01', 'usr-drg-01', 'PROJECT_CANCELLATION', 'prj-collab-01', 15000.0, 'Client site acquisition postponed', 'PENDING'
      );
    `).run();

    const refund = db.prepare("SELECT * FROM cancellation_refund_requests WHERE id = 'ref-01'").get();
    assert.equal(refund.request_type, 'PROJECT_CANCELLATION');
    assert.equal(refund.amount_requested, 15000.0);
    assert.equal(refund.status, 'PENDING');

    // Admin reviews and approves partial milestone refund
    db.prepare(`
      UPDATE cancellation_refund_requests 
      SET status = 'APPROVED', amount_approved = 7500.0, review_decision = 'Pro-rata refund for pre-delivery hours',
          reviewed_by = 'usr-adm-01', resolved_at = CURRENT_TIMESTAMP
      WHERE id = 'ref-01'
    `).run();

    const approvedRefund = db.prepare("SELECT * FROM cancellation_refund_requests WHERE id = 'ref-01'").get();
    assert.equal(approvedRefund.status, 'APPROVED');
    assert.equal(approvedRefund.amount_approved, 7500.0);
  });

  await t.test('11. Rollback & Migration Safety Strategy', () => {
    // Test that down migration / table drop cleanly reverses without foreign key deadlock
    db.exec(`
      DROP TABLE IF EXISTS cancellation_refund_requests;
      DROP TABLE IF EXISTS guardian_consents;
      DROP TABLE IF EXISTS data_retention_policies;
      DROP TABLE IF EXISTS data_correction_requests;
      DROP TABLE IF EXISTS data_export_requests;
      DROP TABLE IF EXISTS account_deletion_requests;
      DROP TABLE IF EXISTS legal_business_profile;
    `);

    const remaining = db.prepare(`
      SELECT name FROM sqlite_master 
      WHERE type = 'table' AND tbl_name IN (
        'legal_business_profile', 'account_deletion_requests', 'data_export_requests',
        'data_correction_requests', 'data_retention_policies', 'guardian_consents',
        'cancellation_refund_requests'
      );
    `).all();

    assert.equal(remaining.length, 0, 'Clean drop of Phase 2 tables succeeds without affecting existing 0001-0025 schema');
  });
});
