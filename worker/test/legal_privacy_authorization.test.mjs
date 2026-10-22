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

// Helper to create an isolated, in-memory SQLite database and apply migrations 0001 through 0016
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

test('Phase E: Legal & Privacy Database Schema & Constraint Validation', async (t) => {
  const db = createIsolatedTestDb();

  // Seed baseline test users into users table
  db.prepare(`
    INSERT INTO users (id, email, name, role) 
    VALUES 
      ('usr-engineer-01', 'eng@example.com', 'Engineer One', 'CLIENT'),
      ('usr-draughtsman-01', 'drg@example.com', 'Draughtsman One', 'DRAUGHTSMAN'),
      ('usr-admin-01', 'admin@example.com', 'Admin One', 'ADMIN');
  `).run();

  await t.test('1. Schema Creation & Index Inventory Verification', () => {
    const tables = db.prepare(`
      SELECT name FROM sqlite_master 
      WHERE type = 'table' AND tbl_name IN ('legal_documents', 'legal_consent_events', 'user_consent_state', 'privacy_requests')
      ORDER BY name;
    `).all();

    const expectedTables = ['legal_consent_events', 'legal_documents', 'privacy_requests', 'user_consent_state'];
    assert.deepEqual(tables.map(t => t.name), expectedTables, 'All 4 legal/privacy tables must exist');

    const indexes = db.prepare(`
      SELECT name, tbl_name FROM sqlite_master 
      WHERE type = 'index' AND tbl_name IN ('legal_documents', 'legal_consent_events', 'user_consent_state', 'privacy_requests')
      ORDER BY name;
    `).all();

    // 11 explicit indexes + 4 primary key autoindexes = 15 total index entries
    assert.equal(indexes.length, 15, 'Exactly 15 index records (11 explicit + 4 autoindexes) must exist in sqlite_master');

    const indexNames = indexes.map(i => i.name);
    // Explicit unique and partial unique indexes
    assert.ok(indexNames.includes('idx_legal_docs_type_version_locale'), 'Missing idx_legal_docs_type_version_locale');
    assert.ok(indexNames.includes('idx_single_effective_doc'), 'Missing idx_single_effective_doc');
    assert.ok(indexNames.includes('idx_consent_events_idempotency'), 'Missing idx_consent_events_idempotency');
    assert.ok(indexNames.includes('idx_user_consent_state_unique'), 'Missing idx_user_consent_state_unique');

    // Autoindexes for primary keys
    assert.ok(indexNames.includes('sqlite_autoindex_legal_documents_1'), 'Missing autoindex for legal_documents PK');
    assert.ok(indexNames.includes('sqlite_autoindex_legal_consent_events_1'), 'Missing autoindex for legal_consent_events PK');
    assert.ok(indexNames.includes('sqlite_autoindex_user_consent_state_1'), 'Missing autoindex for user_consent_state PK');
    assert.ok(indexNames.includes('sqlite_autoindex_privacy_requests_1'), 'Missing autoindex for privacy_requests PK');
  });

  await t.test('2. Foreign Key Behavior & Referencing Integrity (ON DELETE RESTRICT)', () => {
    // Attempt inserting a consent event for a non-existent user
    assert.throws(() => {
      db.prepare(`
        INSERT INTO legal_consent_events (
          id, user_id, document_id, document_type, document_version, action_type, 
          idempotency_key, ip_hash
        ) VALUES (
          'evt-err-01', 'non-existent-user', 'doc-fake-01', 'TERMS_AND_CONDITIONS', '1.0.0', 
          'TERMS_ACCEPTED', 'idem-fake-01', 'hash123'
        );
      `).run();
    }, /FOREIGN KEY constraint failed/, 'Should reject consent event with non-existent user_id');

    // Insert a valid document
    db.prepare(`
      INSERT INTO legal_documents (
        id, document_type, version, title, content, effective_at, status, is_mandatory
      ) VALUES (
        'doc-terms-v1', 'TERMS_AND_CONDITIONS', '1.0.0', 'Platform Terms', '# Terms', '2026-10-22 00:00:00', 'EFFECTIVE', 1
      );
    `).run();

    // Attempt inserting consent event for existing user but non-existent document
    assert.throws(() => {
      db.prepare(`
        INSERT INTO legal_consent_events (
          id, user_id, document_id, document_type, document_version, action_type, 
          idempotency_key, ip_hash
        ) VALUES (
          'evt-err-02', 'usr-engineer-01', 'doc-non-existent', 'TERMS_AND_CONDITIONS', '1.0.0', 
          'TERMS_ACCEPTED', 'idem-fake-02', 'hash123'
        );
      `).run();
    }, /FOREIGN KEY constraint failed/, 'Should reject consent event with non-existent document_id');

    // Insert a valid consent event referencing existing user and existing document
    db.prepare(`
      INSERT INTO legal_consent_events (
        id, user_id, document_id, document_type, document_version, action_type, 
        idempotency_key, ip_hash
      ) VALUES (
        'evt-valid-01', 'usr-engineer-01', 'doc-terms-v1', 'TERMS_AND_CONDITIONS', '1.0.0', 
        'TERMS_ACCEPTED', 'idem-valid-01', 'hash123'
      );
    `).run();

    // Verify ON DELETE RESTRICT: Attempting to delete usr-engineer-01 must fail
    assert.throws(() => {
      db.prepare("DELETE FROM users WHERE id = 'usr-engineer-01';").run();
    }, /FOREIGN KEY constraint failed/, 'ON DELETE RESTRICT must prevent deleting user with active consent records');
  });

  await t.test('3. Document Version Uniqueness & Singularity Rule (Single EFFECTIVE Version)', () => {
    // Attempt duplicate (document_type, version, locale)
    assert.throws(() => {
      db.prepare(`
        INSERT INTO legal_documents (
          id, document_type, version, title, content, effective_at, status, is_mandatory, locale
        ) VALUES (
          'doc-terms-dup', 'TERMS_AND_CONDITIONS', '1.0.0', 'Duplicate Terms', '# Dup', '2026-10-22 00:00:00', 'DRAFT', 1, 'en-IN'
        );
      `).run();
    }, /UNIQUE constraint failed/, 'Duplicate (document_type, version, locale) must be rejected');

    // Attempt multiple EFFECTIVE versions for same (document_type, locale)
    assert.throws(() => {
      db.prepare(`
        INSERT INTO legal_documents (
          id, document_type, version, title, content, effective_at, status, is_mandatory, locale
        ) VALUES (
          'doc-terms-v2', 'TERMS_AND_CONDITIONS', '2.0.0', 'Terms v2', '# V2', '2026-10-23 00:00:00', 'EFFECTIVE', 1, 'en-IN'
        );
      `).run();
    }, /UNIQUE constraint failed/, 'Partial unique index must prevent second EFFECTIVE document for same type and locale');

    // Verify atomic transition: Supersede v1 and make v2 EFFECTIVE
    db.exec(`
      UPDATE legal_documents SET status = 'SUPERSEDED' WHERE id = 'doc-terms-v1';
      INSERT INTO legal_documents (
        id, document_type, version, title, content, effective_at, status, is_mandatory, locale
      ) VALUES (
        'doc-terms-v2', 'TERMS_AND_CONDITIONS', '2.0.0', 'Terms v2', '# V2', '2026-10-23 00:00:00', 'EFFECTIVE', 1, 'en-IN'
      );
    `);

    const effectiveDocs = db.prepare(`
      SELECT id, version, status FROM legal_documents 
      WHERE document_type = 'TERMS_AND_CONDITIONS' AND locale = 'en-IN' AND status = 'EFFECTIVE';
    `).all();

    assert.equal(effectiveDocs.length, 1, 'Exactly one version must be EFFECTIVE after transition');
    assert.equal(effectiveDocs[0].id, 'doc-terms-v2', 'New version must be the active EFFECTIVE version');
  });

  await t.test('4. Consent Event Idempotency & Deduplication', () => {
    // Insert initial event with distinct idempotency key
    db.prepare(`
      INSERT INTO legal_consent_events (
        id, user_id, document_id, document_type, document_version, action_type, 
        idempotency_key, ip_hash
      ) VALUES (
        'evt-idem-01', 'usr-draughtsman-01', 'doc-terms-v2', 'TERMS_AND_CONDITIONS', '2.0.0', 
        'TERMS_ACCEPTED', 'idem-unique-key-xyz', 'salt_hash_1'
      );
    `).run();

    // Concurrent duplicate submission with identical idempotency_key must fail
    assert.throws(() => {
      db.prepare(`
        INSERT INTO legal_consent_events (
          id, user_id, document_id, document_type, document_version, action_type, 
          idempotency_key, ip_hash
        ) VALUES (
          'evt-idem-02', 'usr-draughtsman-01', 'doc-terms-v2', 'TERMS_AND_CONDITIONS', '2.0.0', 
          'TERMS_ACCEPTED', 'idem-unique-key-xyz', 'salt_hash_1'
        );
      `).run();
    }, /UNIQUE constraint failed.*idempotency_key/, 'Duplicate idempotency key must be rejected by database');
  });

  await t.test('5. Consistency Between Consent Events & Current Consent State', () => {
    // Insert privacy policy document
    db.prepare(`
      INSERT INTO legal_documents (
        id, document_type, version, title, content, effective_at, status, is_mandatory
      ) VALUES (
        'doc-priv-v1', 'PRIVACY_POLICY', '1.0.0', 'Privacy Policy', '# Privacy', '2026-10-22 00:00:00', 'EFFECTIVE', 0
      );
    `).run();

    // 1. Initial Grant of optional consent
    db.exec(`
      INSERT INTO legal_consent_events (
        id, user_id, document_id, document_type, document_version, action_type, consent_purpose,
        idempotency_key, ip_hash
      ) VALUES (
        'evt-opt-grant-1', 'usr-engineer-01', 'doc-priv-v1', 'OPTIONAL_CONSENT', '1.0.0', 'OPTIONAL_CONSENT_GRANTED', 'MARKETING_COMMUNICATIONS',
        'idem-opt-01', 'hash_eng'
      );

      INSERT INTO user_consent_state (
        id, user_id, consent_type, purpose_tag, current_status, accepted_version, last_event_id
      ) VALUES (
        'st-opt-01', 'usr-engineer-01', 'OPTIONAL_PURPOSE', 'MARKETING_COMMUNICATIONS', 'GRANTED', '1.0.0', 'evt-opt-grant-1'
      );
    `);

    // Verify state record
    let state = db.prepare("SELECT * FROM user_consent_state WHERE user_id = 'usr-engineer-01' AND purpose_tag = 'MARKETING_COMMUNICATIONS';").get();
    assert.equal(state.current_status, 'GRANTED');
    assert.equal(state.last_event_id, 'evt-opt-grant-1');

    // 2. Withdrawal of optional consent creates a NEW event and updates state
    db.exec(`
      INSERT INTO legal_consent_events (
        id, user_id, document_id, document_type, document_version, action_type, consent_purpose,
        idempotency_key, ip_hash
      ) VALUES (
        'evt-opt-withdrawn-1', 'usr-engineer-01', 'doc-priv-v1', 'OPTIONAL_CONSENT', '1.0.0', 'OPTIONAL_CONSENT_WITHDRAWN', 'MARKETING_COMMUNICATIONS',
        'idem-opt-02', 'hash_eng'
      );

      UPDATE user_consent_state 
      SET current_status = 'WITHDRAWN', last_event_id = 'evt-opt-withdrawn-1', updated_at = CURRENT_TIMESTAMP
      WHERE user_id = 'usr-engineer-01' AND purpose_tag = 'MARKETING_COMMUNICATIONS';
    `);

    // Verify historical events: BOTH events exist, neither was deleted
    const events = db.prepare("SELECT action_type FROM legal_consent_events WHERE user_id = 'usr-engineer-01' AND consent_purpose = 'MARKETING_COMMUNICATIONS' ORDER BY recorded_at ASC;").all();
    assert.equal(events.length, 2, 'Both granted and withdrawn events must be preserved in ledger');
    assert.equal(events[0].action_type, 'OPTIONAL_CONSENT_GRANTED');
    assert.equal(events[1].action_type, 'OPTIONAL_CONSENT_WITHDRAWN');

    // Verify state: shows WITHDRAWN
    state = db.prepare("SELECT * FROM user_consent_state WHERE user_id = 'usr-engineer-01' AND purpose_tag = 'MARKETING_COMMUNICATIONS';").get();
    assert.equal(state.current_status, 'WITHDRAWN');
    assert.equal(state.last_event_id, 'evt-opt-withdrawn-1');

    // Verify User Consent State Uniqueness: duplicate (user_id, consent_type, purpose_tag) must fail
    assert.throws(() => {
      db.prepare(`
        INSERT INTO user_consent_state (
          id, user_id, consent_type, purpose_tag, current_status, accepted_version, last_event_id
        ) VALUES (
          'st-opt-dup', 'usr-engineer-01', 'OPTIONAL_PURPOSE', 'MARKETING_COMMUNICATIONS', 'GRANTED', '1.0.0', 'evt-opt-grant-1'
        );
      `).run();
    }, /UNIQUE constraint failed/, 'Duplicate (user_id, consent_type, purpose_tag) must be rejected');
  });

  await t.test('6. Privacy-Request Record Integrity & Schema Isolation Assumptions', () => {
    // Insert privacy requests for Engineer and Draughtsman
    db.prepare(`
      INSERT INTO privacy_requests (
        id, user_id, request_type, details, statutory_basis, statutory_deadline, operational_target_date
      ) VALUES 
        ('REQ-20261022-0001', 'usr-engineer-01', 'DATA_ACCESS', 'Export all drawing history', 'DPDP_SEC_11', NULL, '2026-11-06 00:00:00'),
        ('REQ-20261022-0002', 'usr-draughtsman-01', 'GRIEVANCE', 'Dispute over drawing credits', 'IT_SPDI_RULE_5_9', '2026-11-21 00:00:00', '2026-11-06 00:00:00');
    `).run();

    // Schema user-isolation query assumption
    const engRequests = db.prepare("SELECT id, request_type FROM privacy_requests WHERE user_id = 'usr-engineer-01';").all();
    assert.equal(engRequests.length, 1);
    assert.equal(engRequests[0].id, 'REQ-20261022-0001');

    const drgRequests = db.prepare("SELECT id, request_type FROM privacy_requests WHERE user_id = 'usr-draughtsman-01';").all();
    assert.equal(drgRequests.length, 1);
    assert.equal(drgRequests[0].id, 'REQ-20261022-0002');

    // Attempting invalid foreign key for privacy request must fail
    assert.throws(() => {
      db.prepare(`
        INSERT INTO privacy_requests (
          id, user_id, request_type, details, statutory_basis, operational_target_date
        ) VALUES 
          ('REQ-INVALID', 'ghost-user', 'DATA_ACCESS', 'Details', 'DPDP_SEC_11', '2026-11-06');
      `).run();
    }, /FOREIGN KEY constraint failed/, 'Privacy request referencing non-existent user must fail');
  });

  await t.test('7. Expected Failure Behavior for Invalid Database Operations (NOT NULL Constraints)', () => {
    // Null document_type in legal_documents
    assert.throws(() => {
      db.prepare("INSERT INTO legal_documents (id, version, title, content, effective_at) VALUES ('doc-null', '1.0', 'T', 'C', datetime('now'));").run();
    }, /NOT NULL constraint failed/, 'Missing document_type must fail');

    // Null action_type in legal_consent_events
    assert.throws(() => {
      db.prepare(`
        INSERT INTO legal_consent_events (
          id, user_id, document_id, document_type, document_version, idempotency_key, ip_hash
        ) VALUES ('e-null', 'usr-engineer-01', 'doc-terms-v2', 'TERMS', '2.0', 'idem-null', 'hash');
      `).run();
    }, /NOT NULL constraint failed/, 'Missing action_type must fail');

    // Null operational_target_date in privacy_requests
    assert.throws(() => {
      db.prepare(`
        INSERT INTO privacy_requests (
          id, user_id, request_type, details, statutory_basis
        ) VALUES ('req-null', 'usr-engineer-01', 'DATA_ACCESS', 'details', 'DPDP');
      `).run();
    }, /NOT NULL constraint failed/, 'Missing operational_target_date must fail');
  });
});


// =========================================================================
// PHASE F: HTTP REST API & END-TO-END AUTHORIZATION SUITE
// =========================================================================

// Ensure NODE_ENV is test for mock tokens
process.env.NODE_ENV = 'test';

const bundlePath = path.join(workerRoot, 'node_modules', '.test_app_bundle_legal.mjs');
esbuild.buildSync({
  entryPoints: [path.join(workerRoot, 'src', 'index.ts')],
  bundle: true,
  format: 'esm',
  platform: 'node',
  write: true,
  outfile: bundlePath,
});

const { default: app } = await import(`file://${bundlePath}`);

function createApiTestEnv() {
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

  const d1 = {
    prepare(sql) {
      return {
        bind(...args) {
          return {
            async first() {
              const stmt = db.prepare(sql);
              return stmt.get(...args);
            },
            async all() {
              const stmt = db.prepare(sql);
              const results = stmt.all(...args);
              return { results };
            },
            async run() {
              const stmt = db.prepare(sql);
              stmt.run(...args);
              return { success: true };
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
          stmt.run();
          return { success: true };
        }
      };
    },
    async batch(statements) {
      const results = [];
      for (const stmt of statements) {
        if (stmt.all) {
          results.push(await stmt.all());
        } else if (stmt.run) {
          results.push(await stmt.run());
        } else {
          results.push({ results: [] });
        }
      }
      return results;
    }
  };

  const storage = {
    async get(key) { return null; },
    async put(key, body) { return {}; }
  };

  return { rawDb: db, env: { DB: d1, STORAGE: storage } };
}

async function apiRequest(env, pathStr, options = {}) {
  const headers = { ...(options.headers || {}) };
  if (options.token !== null && !headers['Authorization'] && !headers['authorization']) {
    headers['Authorization'] = `Bearer mock-token:${options.token || 'usr-engineer-01'}`;
  }
  return app.request(pathStr, {
    method: options.method || 'GET',
    headers,
    body: options.body ? JSON.stringify(options.body) : undefined,
  }, env);
}

test('Phase F: Legal & Privacy Backend HTTP API & Authorization Suite', async (t) => {
  const { rawDb, env } = createApiTestEnv();

  // Seed baseline users
  rawDb.prepare(`
    INSERT INTO users (id, email, name, role) 
    VALUES 
      ('usr-engineer-01', 'eng@example.com', 'Engineer One', 'CLIENT'),
      ('usr-draughtsman-01', 'drg@example.com', 'Draughtsman One', 'DRAUGHTSMAN'),
      ('usr-admin-01', 'admin@example.com', 'Admin One', 'ADMIN');
  `).run();

  // Seed initial documents
  rawDb.prepare(`
    INSERT INTO legal_documents (id, document_type, version, title, content, effective_at, status, is_mandatory, locale)
    VALUES 
      ('doc-terms-draft', 'TERMS_AND_CONDITIONS', '0.9.0', 'Draft Terms', '# Draft', '2026-10-20', 'DRAFT', 1, 'en-IN'),
      ('doc-terms-v1', 'TERMS_AND_CONDITIONS', '1.0.0', 'Platform Terms v1', '# Terms 1.0', '2026-10-21', 'EFFECTIVE', 1, 'en-IN'),
      ('doc-priv-v1', 'PRIVACY_POLICY', '1.0.0', 'Privacy Policy v1', '# Privacy 1.0', '2026-10-21', 'EFFECTIVE', 0, 'en-IN');
  `).run();

  await t.test('1. Public Legal Documents Retrieval & Non-Disclosure of Drafts', async () => {
    // Unauthenticated GET /api/legal/documents/current
    const res = await apiRequest(env, '/api/legal/documents/current', { token: null });
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.ok(Array.isArray(body.documents));
    assert.equal(body.documents.length, 2);

    const docIds = body.documents.map(d => d.id);
    assert.ok(docIds.includes('doc-terms-v1'), 'Must include effective Terms v1');
    assert.ok(docIds.includes('doc-priv-v1'), 'Must include effective Privacy v1');
    assert.ok(!docIds.includes('doc-terms-draft'), 'DRAFT documents must NEVER be exposed publicly');

    // GET /api/legal/documents/:type/current
    const termsRes = await apiRequest(env, '/api/legal/documents/TERMS_AND_CONDITIONS/current', { token: null });
    assert.equal(termsRes.status, 200);
    const termsBody = await termsRes.json();
    assert.equal(termsBody.document.version, '1.0.0');
    assert.equal(termsBody.document.content, '# Terms 1.0');

    // Missing type returns 404 with explicit error code
    const notFoundRes = await apiRequest(env, '/api/legal/documents/NON_EXISTENT_TYPE/current', { token: null });
    assert.equal(notFoundRes.status, 404);
    const notFoundBody = await notFoundRes.json();
    assert.equal(notFoundBody.code, 'NO_EFFECTIVE_VERSION');

    // GET /api/legal/documents/:type/history (DRAFT must be excluded)
    const histRes = await apiRequest(env, '/api/legal/documents/TERMS_AND_CONDITIONS/history', { token: null });
    assert.equal(histRes.status, 200);
    const histBody = await histRes.json();
    assert.equal(histBody.versions.length, 1);
    assert.equal(histBody.versions[0].id, 'doc-terms-v1');
  });

  await t.test('2. Authentication Enforcement on Protected Legal Endpoints', async () => {
    // GET /api/users/me/legal-status without auth -> 401
    const res1 = await apiRequest(env, '/api/users/me/legal-status', { token: null });
    assert.equal(res1.status, 401);

    // POST /api/legal/accept-terms without auth -> 401
    const res2 = await apiRequest(env, '/api/legal/accept-terms', { 
      token: null, 
      method: 'POST', 
      body: { documentId: 'doc-terms-v1' } 
    });
    assert.equal(res2.status, 401);

    // POST /api/users/me/privacy-requests with invalid token -> 401
    const res3 = await apiRequest(env, '/api/users/me/privacy-requests', {
      headers: { 'Authorization': 'Bearer invalid-token-xyz' },
      method: 'POST',
      body: { requestType: 'DATA_ACCESS', details: 'Export' }
    });
    assert.equal(res3.status, 401);
  });

  await t.test('3. User Legal Status & Mandatory Terms Acceptance Lifecycle', async () => {
    // Check initial status for usr-engineer-01 before accepting Terms
    const statusRes1 = await apiRequest(env, '/api/users/me/legal-status', { token: 'usr-engineer-01' });
    assert.equal(statusRes1.status, 200);
    const status1 = await statusRes1.json();
    assert.equal(status1.termsAccepted, false);
    assert.equal(status1.reacceptanceRequired, false);
    assert.equal(status1.requiresAction, true);
    assert.equal(status1.latestTermsVersion, '1.0.0');

    // Attempt accepting non-existent or draft document -> 400
    const errRes = await apiRequest(env, '/api/legal/accept-terms', {
      token: 'usr-engineer-01',
      method: 'POST',
      body: { documentId: 'doc-terms-draft' } // DRAFT cannot be accepted
    });
    assert.equal(errRes.status, 400);

    // Accept valid effective Terms v1.0.0
    const acceptRes = await apiRequest(env, '/api/legal/accept-terms', {
      token: 'usr-engineer-01',
      method: 'POST',
      body: { 
        documentId: 'doc-terms-v1', 
        version: '1.0.0', 
        idempotencyKey: 'idem-test-eng-v1' 
      }
    });
    assert.equal(acceptRes.status, 200);
    const acceptBody = await acceptRes.json();
    assert.equal(acceptBody.success, true);
    assert.ok(acceptBody.eventId);

    // Idempotency: submitting same idempotencyKey again returns 200 and does not duplicate event
    const dupRes = await apiRequest(env, '/api/legal/accept-terms', {
      token: 'usr-engineer-01',
      method: 'POST',
      body: { 
        documentId: 'doc-terms-v1', 
        version: '1.0.0', 
        idempotencyKey: 'idem-test-eng-v1' 
      }
    });
    assert.equal(dupRes.status, 200);
    const dupBody = await dupRes.json();
    assert.equal(dupBody.idempotent, true);
    assert.equal(dupBody.eventId, acceptBody.eventId);

    // Verify database record count
    const events = rawDb.prepare("SELECT * FROM legal_consent_events WHERE user_id = 'usr-engineer-01' AND action_type = 'TERMS_ACCEPTED';").all();
    assert.equal(events.length, 1, 'Only one consent event must exist after duplicate submissions');

    // Verify legal status after acceptance
    const statusRes2 = await apiRequest(env, '/api/users/me/legal-status', { token: 'usr-engineer-01' });
    const status2 = await statusRes2.json();
    assert.equal(status2.termsAccepted, true);
    assert.equal(status2.acceptedTermsVersion, '1.0.0');
    assert.equal(status2.requiresAction, false);
  });

  await t.test('4. Separate Privacy Notice Acknowledgment & Granular Optional Consent', async () => {
    // 1. Acknowledge Privacy Notice
    const privAckRes = await apiRequest(env, '/api/legal/acknowledge-privacy', {
      token: 'usr-engineer-01',
      method: 'POST',
      body: { documentId: 'doc-priv-v1', version: '1.0.0' }
    });
    assert.equal(privAckRes.status, 200);
    const privAckBody = await privAckRes.json();
    assert.equal(privAckBody.success, true);

    // Check status: notice acknowledged, optional consent defaults to false / OFF
    let statusRes = await apiRequest(env, '/api/users/me/legal-status', { token: 'usr-engineer-01' });
    let status = await statusRes.json();
    assert.equal(status.privacyNoticeAcknowledged, true);
    assert.equal(status.optionalConsents.MARKETING_COMMUNICATIONS || false, false, 'Optional consent must default to OFF');

    // 2. Grant optional marketing consent
    const grantRes = await apiRequest(env, '/api/legal/consent', {
      token: 'usr-engineer-01',
      method: 'POST',
      body: { purpose: 'MARKETING_COMMUNICATIONS', granted: true }
    });
    assert.equal(grantRes.status, 200);
    const grantBody = await grantRes.json();
    assert.equal(grantBody.status, 'GRANTED');

    statusRes = await apiRequest(env, '/api/users/me/legal-status', { token: 'usr-engineer-01' });
    status = await statusRes.json();
    assert.equal(status.optionalConsents.MARKETING_COMMUNICATIONS, true);

    // 3. Withdraw optional marketing consent
    const withdrawRes = await apiRequest(env, '/api/legal/consent', {
      token: 'usr-engineer-01',
      method: 'POST',
      body: { purpose: 'MARKETING_COMMUNICATIONS', granted: false }
    });
    assert.equal(withdrawRes.status, 200);
    const withdrawBody = await withdrawRes.json();
    assert.equal(withdrawBody.status, 'WITHDRAWN');

    statusRes = await apiRequest(env, '/api/users/me/legal-status', { token: 'usr-engineer-01' });
    status = await statusRes.json();
    assert.equal(status.optionalConsents.MARKETING_COMMUNICATIONS, false);

    // Verify event ledger preserved BOTH events
    const optEvents = rawDb.prepare("SELECT action_type FROM legal_consent_events WHERE user_id = 'usr-engineer-01' AND consent_purpose = 'MARKETING_COMMUNICATIONS' ORDER BY recorded_at ASC;").all();
    assert.equal(optEvents.length, 2);
    assert.equal(optEvents[0].action_type, 'OPTIONAL_CONSENT_GRANTED');
    assert.equal(optEvents[1].action_type, 'OPTIONAL_CONSENT_WITHDRAWN');
  });

  await t.test('5. Effective-Version Transition & Mandatory Re-acceptance Requirement', async () => {
    // Admin creates Terms v2.0.0
    const createRes = await apiRequest(env, '/api/admin/legal/documents', {
      token: 'usr-admin-01',
      method: 'POST',
      body: {
        id: 'doc-terms-v2',
        documentType: 'TERMS_AND_CONDITIONS',
        version: '2.0.0',
        title: 'Platform Terms v2',
        content: '# Terms 2.0 Updated',
        isMandatory: true,
        locale: 'en-IN',
        changeSummary: 'Updated data licensing section'
      }
    });
    assert.equal(createRes.status, 201);

    // Admin publishes Terms v2.0.0 -> becomes EFFECTIVE, supersedes v1.0.0
    const pubRes = await apiRequest(env, '/api/admin/legal/documents/doc-terms-v2/publish', {
      token: 'usr-admin-01',
      method: 'POST'
    });
    assert.equal(pubRes.status, 200);

    // Engineer status now requires re-acceptance
    const statusRes = await apiRequest(env, '/api/users/me/legal-status', { token: 'usr-engineer-01' });
    const status = await statusRes.json();
    assert.equal(status.termsAccepted, false, 'Terms must no longer be accepted because active version is 2.0.0');
    assert.equal(status.reacceptanceRequired, true, 'Re-acceptance is required');
    assert.equal(status.requiresAction, true);
    assert.equal(status.acceptedTermsVersion, '1.0.0');
    assert.equal(status.latestTermsVersion, '2.0.0');

    // Engineer accepts new Terms v2.0.0
    const reacceptRes = await apiRequest(env, '/api/legal/accept-terms', {
      token: 'usr-engineer-01',
      method: 'POST',
      body: { documentId: 'doc-terms-v2', version: '2.0.0' }
    });
    assert.equal(reacceptRes.status, 200);

    // Engineer status is once again compliant
    const statusResAfter = await apiRequest(env, '/api/users/me/legal-status', { token: 'usr-engineer-01' });
    const statusAfter = await statusResAfter.json();
    assert.equal(statusAfter.termsAccepted, true);
    assert.equal(statusAfter.reacceptanceRequired, false);
    assert.equal(statusAfter.acceptedTermsVersion, '2.0.0');
  });

  await t.test('6. Privacy Requests & Grievance Redressal (User Isolation & Ownership)', async () => {
    // Engineer submits data access request
    const engReqRes = await apiRequest(env, '/api/users/me/privacy-requests', {
      token: 'usr-engineer-01',
      method: 'POST',
      body: {
        requestType: 'DATA_ACCESS',
        details: 'Requesting complete export of project drawings and interaction logs'
      }
    });
    assert.equal(engReqRes.status, 201);
    const engReq = (await engReqRes.json()).request;
    assert.equal(engReq.statutoryBasis, 'DPDP_SEC_11');
    assert.equal(engReq.statutoryDeadline, null);
    assert.ok(engReq.operationalTargetDate);

    // Draughtsman submits grievance redressal
    const drgReqRes = await apiRequest(env, '/api/users/me/privacy-requests', {
      token: 'usr-draughtsman-01',
      method: 'POST',
      body: {
        requestType: 'GRIEVANCE',
        details: 'Grievance regarding CAD portfolio attribution removal'
      }
    });
    assert.equal(drgReqRes.status, 201);
    const drgReq = (await drgReqRes.json()).request;
    assert.equal(drgReq.statutoryBasis, 'IT_SPDI_RULE_5_9');
    assert.ok(drgReq.statutoryDeadline, 'IT SPDI Rule 5(9) specifies a 30-day statutory redressal deadline');

    // Strict user isolation verification
    const engListRes = await apiRequest(env, '/api/users/me/privacy-requests', { token: 'usr-engineer-01' });
    const engList = (await engListRes.json()).requests;
    assert.equal(engList.length, 1);
    assert.equal(engList[0].id, engReq.id);

    const drgListRes = await apiRequest(env, '/api/users/me/privacy-requests', { token: 'usr-draughtsman-01' });
    const drgList = (await drgListRes.json()).requests;
    assert.equal(drgList.length, 1);
    assert.equal(drgList[0].id, drgReq.id);

    // Validation failures
    const shortReq = await apiRequest(env, '/api/users/me/privacy-requests', {
      token: 'usr-engineer-01',
      method: 'POST',
      body: { requestType: 'DATA_ACCESS', details: 'hi' } // < 5 chars
    });
    assert.equal(shortReq.status, 400);

    const invalidTypeReq = await apiRequest(env, '/api/users/me/privacy-requests', {
      token: 'usr-engineer-01',
      method: 'POST',
      body: { requestType: 'UNRECOGNIZED_TYPE', details: 'Valid length details' }
    });
    assert.equal(invalidTypeReq.status, 400);
  });

  await t.test('7. Admin Privileged Legal Operations & Access Control', async () => {
    // Non-admin (Engineer) attempting to access admin endpoints -> 403 Forbidden
    const unauthDocList = await apiRequest(env, '/api/admin/legal/documents', { token: 'usr-engineer-01' });
    assert.equal(unauthDocList.status, 403);

    const unauthPrivList = await apiRequest(env, '/api/admin/legal/privacy-requests', { token: 'usr-engineer-01' });
    assert.equal(unauthPrivList.status, 403);

    const unauthConsents = await apiRequest(env, '/api/admin/legal/consents', { token: 'usr-engineer-01' });
    assert.equal(unauthConsents.status, 403);

    // Admin lists all privacy requests
    const adminPrivRes = await apiRequest(env, '/api/admin/legal/privacy-requests', { token: 'usr-admin-01' });
    assert.equal(adminPrivRes.status, 200);
    const adminPrivList = (await adminPrivRes.json()).requests;
    assert.equal(adminPrivList.length, 2, 'Admin can see both Engineer and Draughtsman requests');

    // Admin resolves Engineer request
    const engReqId = adminPrivList.find(r => r.user_id === 'usr-engineer-01').id;
    const resolveRes = await apiRequest(env, `/api/admin/legal/privacy-requests/${engReqId}/resolve`, {
      token: 'usr-admin-01',
      method: 'POST',
      body: {
        status: 'RESOLVED',
        resolutionNotes: 'Data export compiled and dispatched via secure channel.'
      }
    });
    assert.equal(resolveRes.status, 200);

    // Admin views consent ledger
    const consentRes = await apiRequest(env, '/api/admin/legal/consents', { token: 'usr-admin-01' });
    assert.equal(consentRes.status, 200);
    const consents = (await consentRes.json()).events;
    assert.ok(consents.length >= 4, 'Consent ledger contains all recorded events');
  });

  await t.test('8. Server-Side Mandatory Terms Enforcement & Maintenance Mode', async () => {
    // 1. Setup test users:
    // - usr-unaccepted-eng: ENGINEER who has never accepted Terms
    // - usr-outdated-eng: ENGINEER who accepted outdated v1.0.0 (active is v2.0.0)
    // - usr-accepted-eng: ENGINEER who accepted current v2.0.0
    rawDb.prepare(`
      INSERT INTO users (id, email, name, role) 
      VALUES 
        ('usr-unaccepted-eng', 'unaccepted@example.com', 'Unaccepted Eng', 'ENGINEER'),
        ('usr-outdated-eng', 'outdated@example.com', 'Outdated Eng', 'ENGINEER'),
        ('usr-accepted-eng', 'accepted@example.com', 'Accepted Eng', 'ENGINEER');
    `).run();

    // Outdated consent event & state for usr-outdated-eng (v1.0.0)
    rawDb.prepare(`
      INSERT INTO legal_consent_events (id, user_id, document_id, document_type, document_version, action_type, consent_purpose, idempotency_key, ip_hash, source)
      VALUES ('evt-outdated-eng', 'usr-outdated-eng', 'doc-terms-v1', 'TERMS_AND_CONDITIONS', '1.0.0', 'ACCEPT', 'DEFAULT', 'idem-outdated-eng', 'hash-ip', 'WEB_APP');
    `).run();
    rawDb.prepare(`
      INSERT INTO user_consent_state (id, user_id, consent_type, purpose_tag, current_status, accepted_version, last_event_id, updated_at)
      VALUES ('st-outdated-eng', 'usr-outdated-eng', 'TERMS', 'DEFAULT', 'ACCEPTED', '1.0.0', 'evt-outdated-eng', CURRENT_TIMESTAMP);
    `).run();

    // Valid current consent event & state for usr-accepted-eng (v2.0.0)
    rawDb.prepare(`
      INSERT INTO legal_consent_events (id, user_id, document_id, document_type, document_version, action_type, consent_purpose, idempotency_key, ip_hash, source)
      VALUES ('evt-accepted-eng', 'usr-accepted-eng', 'doc-terms-v2', 'TERMS_AND_CONDITIONS', '2.0.0', 'ACCEPT', 'DEFAULT', 'idem-accepted-eng', 'hash-ip', 'WEB_APP');
    `).run();
    rawDb.prepare(`
      INSERT INTO user_consent_state (id, user_id, consent_type, purpose_tag, current_status, accepted_version, last_event_id, updated_at)
      VALUES ('st-accepted-eng', 'usr-accepted-eng', 'TERMS', 'DEFAULT', 'ACCEPTED', '2.0.0', 'evt-accepted-eng', CURRENT_TIMESTAMP);
    `).run();

    // 2. Unaccepted user is BLOCKED from business mutations (POST /api/projects)
    const unacceptedRes = await apiRequest(env, '/api/projects', {
      token: 'usr-unaccepted-eng',
      method: 'POST',
      body: { project_name: 'Tower A', project_address: '100 Road', drawing_name: 'D1', drawing_type: 'ARCHITECTURAL', project_area: '1000' }
    });
    assert.equal(unacceptedRes.status, 403);
    const unacceptedJson = await unacceptedRes.json();
    assert.equal(unacceptedJson.code, 'TERMS_ACCEPTANCE_REQUIRED');
    assert.equal(unacceptedJson.requiredVersion, '2.0.0');

    // 3. Client-supplied headers/claims CANNOT bypass the gate
    const spoofHeaderRes = await apiRequest(env, '/api/projects', {
      token: 'usr-unaccepted-eng',
      method: 'POST',
      headers: {
        'x-terms-accepted': 'true',
        'x-terms-version': '2.0.0',
        'x-user-role': 'ADMIN'
      },
      body: { project_name: 'Spoofed Tower', termsAccepted: true, acceptedVersion: '2.0.0' }
    });
    assert.equal(spoofHeaderRes.status, 403);
    const spoofJson = await spoofHeaderRes.json();
    assert.equal(spoofJson.code, 'TERMS_ACCEPTANCE_REQUIRED');

    // 4. User who only accepted outdated version (1.0.0) is BLOCKED
    const outdatedRes = await apiRequest(env, '/api/projects', {
      token: 'usr-outdated-eng',
      method: 'POST',
      body: { project_name: 'Tower B', project_address: '101 Road', drawing_name: 'D2', drawing_type: 'ARCHITECTURAL', project_area: '1200' }
    });
    assert.equal(outdatedRes.status, 403);
    const outdatedJson = await outdatedRes.json();
    assert.equal(outdatedJson.code, 'TERMS_ACCEPTANCE_REQUIRED');
    assert.equal(outdatedJson.requiredVersion, '2.0.0');
    assert.equal(outdatedJson.acceptedVersion, '1.0.0');

    // 5. User who accepted current effective Terms (2.0.0) SUCCEEDS
    const acceptedRes = await apiRequest(env, '/api/projects', {
      token: 'usr-accepted-eng',
      method: 'POST',
      body: { project_name: 'Tower C', project_address: '102 Road', drawing_name: 'D3', drawing_type: 'ARCHITECTURAL', project_area: '1500' }
    });
    assert.equal(acceptedRes.status, 200);

    // 6. Admin is exempt and can perform operations regardless of personal acceptance state
    const adminRes = await apiRequest(env, '/api/projects', {
      token: 'usr-admin-01',
      method: 'POST',
      body: { project_name: 'Admin Project', project_address: 'Admin HQ', drawing_name: 'ADM', drawing_type: 'ARCHITECTURAL', project_area: '5000' }
    });
    // Note: Admin gets 403 'Only engineers can create projects' from project creation handler, NOT from the terms gate!
    // This proves the terms gate allowed the request through to the business logic handler.
    assert.equal(adminRes.status, 403);
    const adminJson = await adminRes.json();
    assert.equal(adminJson.error, 'Only engineers can create projects');

    // 7. When mandatory terms are missing from system (Maintenance Mode)
    // Archive the active terms so no EFFECTIVE mandatory terms exist
    rawDb.prepare("UPDATE legal_documents SET status = 'ARCHIVED' WHERE status = 'EFFECTIVE' AND document_type = 'TERMS_AND_CONDITIONS';").run();

    const maintRes = await apiRequest(env, '/api/projects', {
      token: 'usr-accepted-eng',
      method: 'POST',
      body: { project_name: 'Tower Maint', project_address: '103 Road', drawing_name: 'D4', drawing_type: 'ARCHITECTURAL', project_area: '2000' }
    });
    assert.equal(maintRes.status, 503);
    const maintJson = await maintRes.json();
    assert.equal(maintJson.code, 'TERMS_MAINTENANCE_MODE');

    // Restore v2.0.0 to EFFECTIVE for subsequent tests
    rawDb.prepare("UPDATE legal_documents SET status = 'EFFECTIVE' WHERE id = 'doc-terms-v2';").run();

    // 8. Essential legal and privacy recovery endpoints remain accessible even for unaccepted users
    const legalStatusRes = await apiRequest(env, '/api/users/me/legal-status', { token: 'usr-unaccepted-eng' });
    assert.equal(legalStatusRes.status, 200);

    const publicDocsRes = await apiRequest(env, '/api/legal/documents/current', { token: null });
    assert.equal(publicDocsRes.status, 200);

    const privacyReqRes = await apiRequest(env, '/api/users/me/privacy-requests', {
      token: 'usr-unaccepted-eng',
      method: 'POST',
      body: { requestType: 'DATA_ACCESS', details: 'Unaccepted user data inquiry' }
    });
    assert.equal(privacyReqRes.status, 201);
  });

  await t.test('9. Public Exemption Hardening & Public Certificate Privacy', async () => {
    // 1. Non-GET request to public legal docs path is rejected (401 Unauthorized without auth)
    const postPublicLegal = await apiRequest(env, '/api/legal/documents/current', {
      token: null,
      method: 'POST',
      body: { malicious: 'payload' }
    });
    assert.equal(postPublicLegal.status, 401, 'POST to public legal document path must require authentication');

    // 2. Non-GET request to certificate verify path is rejected (401 Unauthorized without auth)
    const postVerify = await apiRequest(env, '/api/public/credentials/verify/fake-token', {
      token: null,
      method: 'POST',
      body: { spoof: 'data' }
    });
    assert.equal(postVerify.status, 401, 'POST to credential verification must require authentication');

    // 3. Unknown route beneath public exemption prefix returns 404 Not Found
    const unknownPublic = await apiRequest(env, '/api/public/unknown-subpath', {
      token: null,
      method: 'GET'
    });
    assert.equal(unknownPublic.status, 404, 'Unknown public path must return 404');

    // 4. Public Certificate Verification: User without display_name masks email address
    rawDb.prepare(`
      INSERT INTO users (id, email, name, role) 
      VALUES ('usr-student-anon', 'private.student.email@university.edu', '', 'STUDENT');
    `).run();

    rawDb.prepare(`
      INSERT INTO student_credentials (id, student_id, type, reference_id, title, verification_token, issued_at)
      VALUES ('cred-anon-01', 'usr-student-anon', 'MODULE_COMPLETION', 'mod-test-01', 'Structural Foundations', 'anon-cert-token-xyz', CURRENT_TIMESTAMP);
    `).run();

    const verifyRes = await apiRequest(env, '/api/public/credentials/verify/anon-cert-token-xyz', { token: null });
    assert.equal(verifyRes.status, 200);
    const verifyBody = await verifyRes.json();
    assert.equal(verifyBody.valid, true);
    assert.equal(verifyBody.credential.recipientName, 'Verified Student', 'Must use neutral display name, not raw email');

    // Strict guarantee: raw email address is NEVER present in the serialized response
    const rawResponseText = JSON.stringify(verifyBody);
    assert.ok(!rawResponseText.includes('private.student.email@university.edu'), 'Raw email must not leak in verification payload');
    assert.ok(!rawResponseText.includes('@'), 'No email address may leak in public credential response');
  });
});
