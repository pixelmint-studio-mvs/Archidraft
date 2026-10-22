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

// Set NODE_ENV to test so auth.ts activates safe test-token mode for testing
process.env.NODE_ENV = 'test';

// Polyfill Cloudflare Workers streaming globals for Node test environment
if (!globalThis.FixedLengthStream) {
  globalThis.FixedLengthStream = class FixedLengthStream extends TransformStream {
    constructor(expectedLength) {
      super();
      this.expectedLength = expectedLength;
    }
  };
}

// Bundle worker/src/index.ts for testing
const bundlePath = path.join(workerRoot, 'node_modules', '.test_app_f1_bundle.mjs');
esbuild.buildSync({
  entryPoints: [path.join(workerRoot, 'src', 'index.ts')],
  bundle: true,
  format: 'esm',
  platform: 'node',
  write: true,
  outfile: bundlePath,
});

const { default: app } = await import(`file://${bundlePath}`);

// Setup isolated in-memory SQLite database and apply real schema migrations
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

  const storedFiles = new Map();
  const storage = {
    async get(key) {
      if (!storedFiles.has(key)) return null;
      return {
        body: storedFiles.get(key),
        httpEtag: 'etag-' + key,
        writeHttpMetadata(headers) {
          headers.set('content-type', 'application/acad');
        }
      };
    },
    async put(key, body, options) {
      if (body && typeof body.getReader === 'function') {
        const reader = body.getReader();
        while (true) {
          const { done } = await reader.read();
          if (done) break;
        }
      }
      storedFiles.set(key, 'mock-binary');
      return { key, size: 14 };
    },
    async delete(key) {
      storedFiles.delete(key);
      return;
    }
  };

  return { rawDb: db, env: { DB: d1, STORAGE: storage, ENVIRONMENT: 'test' }, storedFiles };
}

// Helper: HTTP request dispatcher to Hono app
async function testRequest(env, path, options = {}) {
  const headers = { ...options.headers };
  if (options.token !== false) {
    headers['Authorization'] = `Bearer mock-token:${options.token || 'eng-a'}`;
  }
  if (options.body && typeof options.body === 'object') {
    headers['Content-Type'] = 'application/json';
  }

  const req = new Request(`http://localhost${path}`, {
    method: options.method || 'GET',
    headers,
    body: options.body ? (typeof options.body === 'string' ? options.body : JSON.stringify(options.body)) : undefined,
  });

  return await app.fetch(req, env);
}

// Seed comprehensive multi-user fixtures: Engineers A/B/C, Draughtsmen A/B/C, Students A/B/C, Admin
function seedIsolationFixtures(rawDb, storedFiles) {
  const insertUser = rawDb.prepare('INSERT INTO users (id, email, name, role) VALUES (?, ?, ?, ?)');
  // Engineers
  insertUser.run('eng-a', 'engineer_a@archidraft.test', 'Engineer Alice', 'ENGINEER');
  insertUser.run('eng-b', 'engineer_b@archidraft.test', 'Engineer Bob', 'ENGINEER');
  insertUser.run('eng-c', 'engineer_c@archidraft.test', 'Engineer Charlie', 'ENGINEER');
  // Draughtsmen
  insertUser.run('drg-a', 'draughtsman_a@archidraft.test', 'Draughtsman Dan', 'DRAUGHTSMAN');
  insertUser.run('drg-b', 'draughtsman_b@archidraft.test', 'Draughtsman Dave', 'DRAUGHTSMAN');
  insertUser.run('drg-c', 'draughtsman_c@archidraft.test', 'Draughtsman Derek', 'DRAUGHTSMAN');
  // Students
  insertUser.run('stu-a', 'student_a@archidraft.test', 'Student Sam', 'STUDENT');
  insertUser.run('stu-b', 'student_b@archidraft.test', 'Student Sally', 'STUDENT');
  insertUser.run('stu-c', 'student_c@archidraft.test', 'Student Steve', 'STUDENT');
  // Admin
  insertUser.run('adm-1', 'admin@archidraft.test', 'Studio Admin', 'ADMIN');

  // Seed Commercial Project owned by Engineer A, assigned to Draughtsman A
  const insertProject = rawDb.prepare(`
    INSERT INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, draughtsman_id, draughtsman_name, current_assignment_id, is_training_project)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  insertProject.run('prj-eng-a', 'eng-a', 'Engineer A Villa', '101 Alpha Way', 'Floor Plan', 'Architectural', '2500 sq ft', 'IN_PROGRESS', 'drg-a', 'Draughtsman Dan', 'asg-drg-a', 0);
  insertProject.run('prj-eng-b', 'eng-b', 'Engineer B Tower', '202 Beta St', 'HVAC Plan', 'Mechanical', '5000 sq ft', 'IN_PROGRESS', 'drg-b', 'Draughtsman Dave', 'asg-drg-b', 0);
  
  // Seed Project under review owned by Engineer A
  insertProject.run('prj-review-a', 'eng-a', 'Engineer A Review Project', '303 Alpha Blvd', 'Structural', 'Structural', '3000 sq ft', 'UNDER_ENGINEER_REVIEW', 'drg-a', 'Draughtsman Dan', 'asg-review-a', 0);

  // Seed Training Projects for Students
  insertProject.run('prj-train-a', 'adm-1', 'Training Residential Plan', 'Train Sector 1', 'Ground Floor', 'Architectural', '1200 sq ft', 'IN_PROGRESS', null, null, null, 1);
  insertProject.run('prj-train-b', 'adm-1', 'Training Interior Office', 'Train Sector 2', 'Lighting Plan', 'Interior', '800 sq ft', 'IN_PROGRESS', null, null, null, 1);
  insertProject.run('prj-train-c', 'adm-1', 'Training Unassigned Project', 'Train Sector 3', 'Roof Plan', 'Architectural', '1000 sq ft', 'PENDING', null, null, null, 1);

  // Assignments
  const insertAssignment = rawDb.prepare('INSERT INTO assignments (id, project_id, draughtsman_id, status) VALUES (?, ?, ?, ?)');
  insertAssignment.run('asg-drg-a', 'prj-eng-a', 'drg-a', 'ACCEPTED');
  insertAssignment.run('asg-drg-b', 'prj-eng-b', 'drg-b', 'ACCEPTED');
  insertAssignment.run('asg-review-a', 'prj-review-a', 'drg-a', 'ACCEPTED');

  // Student Assignments
  const insertStudentAssignment = rawDb.prepare('INSERT INTO student_assignments (id, student_id, project_id, assignment_type, status) VALUES (?, ?, ?, ?, ?)');
  insertStudentAssignment.run('asg-stu-a', 'stu-a', 'prj-train-a', 'PRACTICAL', 'ACCEPTED');
  insertStudentAssignment.run('asg-stu-b', 'stu-b', 'prj-train-b', 'PRACTICAL', 'ACCEPTED');

  // Files & Storage
  const insertFile = rawDb.prepare(`
    INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  // Engineer A's private brief file
  insertFile.run('file-eng-a-brief', 'prj-eng-a', 'eng-a', 'brief_a.dwg', 'brief_a.dwg', 'projects/prj-eng-a/client_upload/brief_a.dwg', 'application/acad', 1024, 'client_upload', 'COMPLETED');
  storedFiles.set('projects/prj-eng-a/client_upload/brief_a.dwg', 'content-of-brief-a');

  // Engineer B's private brief file
  insertFile.run('file-eng-b-brief', 'prj-eng-b', 'eng-b', 'brief_b.dwg', 'brief_b.dwg', 'projects/prj-eng-b/client_upload/brief_b.dwg', 'application/acad', 1024, 'client_upload', 'COMPLETED');
  storedFiles.set('projects/prj-eng-b/client_upload/brief_b.dwg', 'content-of-brief-b');

  // Training Project A instructor reference file
  insertFile.run('file-ref-train-a', 'prj-train-a', 'adm-1', 'reference_a.dwg', 'reference_a.dwg', 'projects/prj-train-a/reference/reference_a.dwg', 'application/acad', 1024, 'client_upload', 'COMPLETED');
  storedFiles.set('projects/prj-train-a/reference/reference_a.dwg', 'content-of-ref-a');

  // Student A's submitted drawing
  insertFile.run('file-stu-a-drawing', 'prj-train-a', 'stu-a', 'submission_v1.dwg', 'submission_v1.dwg', 'projects/prj-train-a/workspace_draft/submission_v1.dwg', 'application/acad', 2048, 'workspace_draft', 'COMPLETED');
  storedFiles.set('projects/prj-train-a/workspace_draft/submission_v1.dwg', 'content-of-student-a-drawing');

  // Student B's submitted drawing
  insertFile.run('file-stu-b-drawing', 'prj-train-b', 'stu-b', 'submission_b_v1.dwg', 'submission_b_v1.dwg', 'projects/prj-train-b/workspace_draft/submission_b_v1.dwg', 'application/acad', 2048, 'workspace_draft', 'COMPLETED');
  storedFiles.set('projects/prj-train-b/workspace_draft/submission_b_v1.dwg', 'content-of-student-b-drawing');

  // Drawing version for prj-review-a
  insertFile.run('file-review-a-ver1', 'prj-review-a', 'drg-a', 'draft_rev_v1.dwg', 'draft_rev_v1.dwg', 'projects/prj-review-a/draughtsman_version/draft_rev_v1.dwg', 'application/acad', 4096, 'draughtsman_version', 'COMPLETED');
  storedFiles.set('projects/prj-review-a/draughtsman_version/draft_rev_v1.dwg', 'content-of-review-drawing-a');

  rawDb.prepare(`
    INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by, created_at)
    VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
  `).run('ver-review-a-1', 'prj-review-a', 'file-review-a-ver1', 1, 'drg-a');

  // Drawing version for Student A
  rawDb.prepare(`
    INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by, created_at)
    VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
  `).run('ver-train-a-1', 'prj-train-a', 'file-stu-a-drawing', 1, 'stu-a');

  // Extra files for deletion tests: unpromoted workspace drafts
  insertFile.run('file-drg-a-draft', 'prj-eng-a', 'drg-a', 'draft_dan.dwg', 'draft_dan.dwg', 'projects/prj-eng-a/workspace_draft/draft_dan.dwg', 'application/acad', 512, 'workspace_draft', 'COMPLETED');
  storedFiles.set('projects/prj-eng-a/workspace_draft/draft_dan.dwg', 'content-of-dan-draft');

  insertFile.run('file-stu-a-draft', 'prj-train-a', 'stu-a', 'draft_sam.dwg', 'draft_sam.dwg', 'projects/prj-train-a/workspace_draft/draft_sam.dwg', 'application/acad', 512, 'workspace_draft', 'COMPLETED');
  storedFiles.set('projects/prj-train-a/workspace_draft/draft_sam.dwg', 'content-of-sam-draft');

  insertFile.run('file-to-admin-delete', 'prj-eng-a', 'drg-a', 'cleanup.dwg', 'cleanup.dwg', 'projects/prj-eng-a/workspace_draft/cleanup.dwg', 'application/acad', 256, 'workspace_draft', 'COMPLETED');
  storedFiles.set('projects/prj-eng-a/workspace_draft/cleanup.dwg', 'content-of-cleanup');

  // Seed evaluations
  const insertEval = rawDb.prepare(`
    INSERT INTO evaluations (id, project_id, drawing_version_id, evaluator_id, overall_result, general_feedback, criteria_json, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
  `);
  insertEval.run('eval-eng-a', 'prj-eng-a', 'ver-review-a-1', 'eng-a', 'APPROVED', 'Great work Dan', '{"Accuracy": 5, "Technical Standards": 5}');
  insertEval.run('eval-train-a', 'prj-train-a', 'ver-train-a-1', 'adm-1', 'APPROVED', 'Excellent exercise Sam', '{"Accuracy": 5, "Technical Standards": 5}');

  // Seed active Terms and consent for test users
  rawDb.prepare(`
    INSERT INTO legal_documents (id, document_type, version, title, content, effective_at, status, is_mandatory, locale)
    VALUES ('doc-terms-iso', 'TERMS_AND_CONDITIONS', '1.0.0', 'Platform Terms', '# Terms', CURRENT_TIMESTAMP, 'EFFECTIVE', 1, 'en-IN')
  `).run();

  const insertEvent = rawDb.prepare(`
    INSERT INTO legal_consent_events (id, user_id, document_id, document_type, document_version, action_type, consent_purpose, idempotency_key, ip_hash, source)
    VALUES (?, ?, 'doc-terms-iso', 'TERMS_AND_CONDITIONS', '1.0.0', 'ACCEPT', 'DEFAULT', ?, 'hash-ip', 'WEB_APP')
  `);

  const insertConsent = rawDb.prepare(`
    INSERT INTO user_consent_state (id, user_id, consent_type, purpose_tag, current_status, accepted_version, last_event_id, updated_at)
    VALUES (?, ?, 'TERMS', 'DEFAULT', 'ACCEPTED', '1.0.0', ?, CURRENT_TIMESTAMP)
  `);

  for (const uid of ['eng-a', 'eng-b', 'eng-c', 'drg-a', 'drg-b', 'stu-a', 'stu-b']) {
    const eventId = 'evt-terms-' + uid;
    insertEvent.run(eventId, uid, 'idem-' + uid);
    insertConsent.run('cst-' + uid, uid, eventId);
  }
}

// =========================================================================
// TEST SUITE: FINDING F1-01 (TEST_UID_ AUTHENTICATION BYPASS REMEDIATION)
// =========================================================================
test('Finding F1-01: TEST_UID_ Authentication Bypass Gating & Hardening', async (t) => {
  const { rawDb, env, storedFiles } = createIsolatedTestDb();
  seedIsolationFixtures(rawDb, storedFiles);

  await t.test('Rejects TEST_UID_ forged token in production-configured environment (401)', async () => {
    const prodEnv = { ...env, ENVIRONMENT: 'production' };
    const res = await testRequest(prodEnv, '/api/users/me', {
      headers: { Authorization: 'Bearer TEST_UID_eng-a' },
      token: false,
    });
    assert.equal(res.status, 401);
    const body = await res.json();
    assert.match(body.error, /Unauthorized/);
  });

  await t.test('Rejects mock-token in production-configured environment (401)', async () => {
    const prodEnv = { ...env, ENVIRONMENT: 'production' };
    const res = await testRequest(prodEnv, '/api/users/me', {
      headers: { Authorization: 'Bearer mock-token:eng-a' },
      token: false,
    });
    assert.equal(res.status, 401);
  });

  await t.test('Rejects missing Authorization header (401)', async () => {
    const res = await testRequest(env, '/api/users/me', { token: false });
    assert.equal(res.status, 401);
  });

  await t.test('Rejects non-Bearer Authorization header (401)', async () => {
    const res = await testRequest(env, '/api/users/me', {
      headers: { Authorization: 'Basic Zm9vOmJhcg==' },
      token: false,
    });
    assert.equal(res.status, 401);
  });

  await t.test('Rejects malformed or bogus Bearer token (401)', async () => {
    const res = await testRequest(env, '/api/users/me', {
      headers: { Authorization: 'Bearer bogus.jwt.token' },
      token: false,
    });
    assert.equal(res.status, 401);
  });

  await t.test('Accepts test credentials ONLY in test environment (200)', async () => {
    const res = await testRequest(env, '/api/users/me', { token: 'eng-a' });
    assert.equal(res.status, 200);
    const user = await res.json();
    assert.equal(user.id, 'eng-a');
    assert.equal(user.role, 'ENGINEER');
  });
});

// =========================================================================
// TEST SUITE: FINDING F1-02 (FILE UPLOAD CATEGORY DENY-BY-DEFAULT)
// =========================================================================
test('Finding F1-02: File Upload Category Authorization & Deny-by-Default', async (t) => {
  const { rawDb, env, storedFiles } = createIsolatedTestDb();
  seedIsolationFixtures(rawDb, storedFiles);

  await t.test('Rejects upload with unsupported or unknown category (400)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/files?category=malicious_category', {
      method: 'POST',
      token: 'eng-a',
      headers: {
        'X-Action-Id': 'act-up-unsupp',
        'X-File-Name': 'test.dwg',
        'Content-Length': '10',
      },
      body: 'binarydata'
    });
    assert.equal(res.status, 400);
    const body = await res.json();
    assert.match(body.error, /Invalid category/);
  });

  await t.test('Rejects upload without category query parameter (400)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/files', {
      method: 'POST',
      token: 'eng-a',
      headers: {
        'X-Action-Id': 'act-up-nocat',
        'X-File-Name': 'test.dwg',
        'Content-Length': '10',
      },
      body: 'binarydata'
    });
    assert.equal(res.status, 400);
  });

  await t.test('Engineer B is DENIED uploading client_upload to Engineer A project (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/files?category=client_upload', {
      method: 'POST',
      token: 'eng-b',
      headers: {
        'X-Action-Id': 'act-up-eng-b',
        'X-File-Name': 'forged_brief.dwg',
        'Content-Length': '10',
      },
      body: 'binarydata'
    });
    assert.equal(res.status, 403);
    // Verify no file record created
    const file = rawDb.prepare('SELECT * FROM files WHERE id = ?').get('act-up-eng-b');
    assert.equal(file, undefined);
  });

  await t.test('Engineer B is DENIED uploading workspace_draft to Engineer A project (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/files?category=workspace_draft', {
      method: 'POST',
      token: 'eng-b',
      headers: {
        'X-Action-Id': 'act-up-eng-b-draft',
        'X-File-Name': 'forged_draft.dwg',
        'Content-Length': '10',
      },
      body: 'binarydata'
    });
    assert.equal(res.status, 403);
  });

  await t.test('Draughtsman B is DENIED uploading draughtsman_version to Draughtsman A project (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/files?category=draughtsman_version', {
      method: 'POST',
      token: 'drg-b',
      headers: {
        'X-Action-Id': 'act-up-drg-b',
        'X-File-Name': 'stolen_version.dwg',
        'Content-Length': '10',
      },
      body: 'binarydata'
    });
    assert.equal(res.status, 403);
  });

  await t.test('Student B is DENIED uploading workspace_draft to Student A training project (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-train-a/files?category=workspace_draft', {
      method: 'POST',
      token: 'stu-b',
      headers: {
        'X-Action-Id': 'act-up-stu-b-draft',
        'X-File-Name': 'impersonated_drawing.dwg',
        'Content-Length': '10',
      },
      body: 'binarydata'
    });
    assert.equal(res.status, 403);
  });

  await t.test('Unassigned Student C is DENIED uploading to unassigned training project (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-train-c/files?category=workspace_draft', {
      method: 'POST',
      token: 'stu-c',
      headers: {
        'X-Action-Id': 'act-up-stu-c',
        'X-File-Name': 'unassigned.dwg',
        'Content-Length': '10',
      },
      body: 'binarydata'
    });
    assert.equal(res.status, 403);
  });

  await t.test('Authorized Engineer A CAN upload client_upload to own project (200)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/files?category=client_upload', {
      method: 'POST',
      token: 'eng-a',
      headers: {
        'X-Action-Id': 'act-up-eng-a-legit',
        'X-File-Name': 'new_spec.pdf',
        'Content-Length': '13',
      },
      body: 'legitspecdata'
    });
    assert.equal(res.status, 200);
    const file = rawDb.prepare('SELECT * FROM files WHERE id = ?').get('act-up-eng-a-legit');
    assert.equal(file.status, 'COMPLETED');
    assert.equal(file.uploaded_by, 'eng-a');
  });

  await t.test('Authorized Draughtsman A CAN upload draughtsman_version to assigned project (200)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/files?category=draughtsman_version', {
      method: 'POST',
      token: 'drg-a',
      headers: {
        'X-Action-Id': 'act-up-drg-a-legit',
        'X-File-Name': 'floor_v2.dwg',
        'Content-Length': '14',
      },
      body: 'legitdrawingv2'
    });
    assert.equal(res.status, 200);
    const file = rawDb.prepare('SELECT * FROM files WHERE id = ?').get('act-up-drg-a-legit');
    assert.equal(file.status, 'COMPLETED');
    assert.equal(file.uploaded_by, 'drg-a');
  });

  await t.test('Authorized Student A CAN upload workspace_draft to assigned training project (200)', async () => {
    const res = await testRequest(env, '/api/projects/prj-train-a/files?category=workspace_draft', {
      method: 'POST',
      token: 'stu-a',
      headers: {
        'X-Action-Id': 'act-up-stu-a-legit',
        'X-File-Name': 'draft_submission.dwg',
        'Content-Length': '12',
      },
      body: 'studentdraft'
    });
    assert.equal(res.status, 200);
    const file = rawDb.prepare('SELECT * FROM files WHERE id = ?').get('act-up-stu-a-legit');
    assert.equal(file.status, 'COMPLETED');
    assert.equal(file.uploaded_by, 'stu-a');
  });
});

// =========================================================================
// TEST SUITE: FINDING F1-03 (STUDENT FILE DOWNLOAD AUTHORIZATION)
// =========================================================================
test('Finding F1-03: Student File Download Authorization & Privacy', async (t) => {
  const { rawDb, env, storedFiles } = createIsolatedTestDb();
  seedIsolationFixtures(rawDb, storedFiles);

  await t.test('Assigned Student A CAN download instructor reference file for assigned project (200)', async () => {
    const res = await testRequest(env, '/api/files/file-ref-train-a/download', { token: 'stu-a' });
    assert.equal(res.status, 200);
    assert.equal(res.headers.get('content-type'), 'application/acad');
  });

  await t.test('Assigned Student A CAN download their own submitted drawing (200)', async () => {
    const res = await testRequest(env, '/api/files/file-stu-a-drawing/download', { token: 'stu-a' });
    assert.equal(res.status, 200);
  });

  await t.test('Student B is DENIED downloading Student A private drawing (403)', async () => {
    const res = await testRequest(env, '/api/files/file-stu-a-drawing/download', { token: 'stu-b' });
    assert.equal(res.status, 403);
    const body = await res.json();
    assert.match(body.error, /Forbidden: Access to project file denied/);
  });

  await t.test('Student A is DENIED downloading Student B private drawing (403)', async () => {
    const res = await testRequest(env, '/api/files/file-stu-b-drawing/download', { token: 'stu-a' });
    assert.equal(res.status, 403);
  });

  await t.test('Student is DENIED downloading commercial project files (403)', async () => {
    const res = await testRequest(env, '/api/files/file-eng-a-brief/download', { token: 'stu-a' });
    assert.equal(res.status, 403);
  });

  await t.test('Unassigned Student C is DENIED downloading reference file for Project A (403)', async () => {
    const res = await testRequest(env, '/api/files/file-ref-train-a/download', { token: 'stu-c' });
    assert.equal(res.status, 403);
  });

  await t.test('Guessed or non-existent file ID returns 404', async () => {
    const res = await testRequest(env, '/api/files/bogus-guessed-file-id/download', { token: 'stu-a' });
    assert.equal(res.status, 404);
  });

  await t.test('Authorized Engineer A CAN download own project file (200)', async () => {
    const res = await testRequest(env, '/api/files/file-eng-a-brief/download', { token: 'eng-a' });
    assert.equal(res.status, 200);
  });

  await t.test('Assigned Draughtsman A CAN download assigned project file (200)', async () => {
    const res = await testRequest(env, '/api/files/file-eng-a-brief/download', { token: 'drg-a' });
    assert.equal(res.status, 200);
  });
});

// =========================================================================
// TEST SUITE: FINDING F1-04 (EVALUATION STATUS ALIAS NORMALIZATION)
// =========================================================================
test('Finding F1-04: Evaluation Status Normalization (CORRECTION_REQUIRED)', async (t) => {
  const { rawDb, env, storedFiles } = createIsolatedTestDb();
  seedIsolationFixtures(rawDb, storedFiles);

  await t.test('Accepts CORRECTION_REQUIRED and normalizes to NEEDS_CORRECTION (200)', async () => {
    const res = await testRequest(env, '/api/projects/evaluate', {
      method: 'POST',
      token: 'adm-1',
      body: {
        projectId: 'prj-review-a',
        actionId: 'act-eval-alias-1',
        drawingVersionId: 'ver-review-a-1',
        overallResult: 'CORRECTION_REQUIRED',
        generalFeedback: 'Adjust wall thicknesses per standard.',
        criteriaJson: { 'Accuracy': 4, 'Technical Standards': 3 }
      }
    });
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.success, true);
    assert.ok(body.evaluationId);

    // Verify evaluation was saved with normalized canonical value
    const evalRecord = rawDb.prepare('SELECT * FROM evaluations WHERE id = ?').get(body.evaluationId);
    assert.equal(evalRecord.overall_result, 'NEEDS_CORRECTION');

    // Verify project state transitioned to IN_PROGRESS and correction round incremented
    const project = rawDb.prepare('SELECT status, correction_round FROM projects WHERE id = ?').get('prj-review-a');
    assert.equal(project.status, 'IN_PROGRESS');
    assert.equal(project.correction_round, 1);
  });

  await t.test('Accepts canonical NEEDS_CORRECTION directly (200)', async () => {
    // Reset status to review
    rawDb.prepare("UPDATE projects SET status = 'UNDER_ENGINEER_REVIEW' WHERE id = ?").run('prj-review-a');
    const res = await testRequest(env, '/api/projects/evaluate', {
      method: 'POST',
      token: 'adm-1',
      body: {
        projectId: 'prj-review-a',
        actionId: 'act-eval-canon-1',
        drawingVersionId: 'ver-review-a-1',
        overallResult: 'NEEDS_CORRECTION',
        generalFeedback: 'Need minor fix.',
        criteriaJson: { 'Accuracy': 5, 'Technical Standards': 4 }
      }
    });
    assert.equal(res.status, 200);
    const body = await res.json();
    const evalRecord = rawDb.prepare('SELECT overall_result FROM evaluations WHERE id = ?').get(body.evaluationId);
    assert.equal(evalRecord.overall_result, 'NEEDS_CORRECTION');
  });

  await t.test('Rejects unsupported evaluation status like PENDING_REVISION (400)', async () => {
    rawDb.prepare("UPDATE projects SET status = 'UNDER_ENGINEER_REVIEW' WHERE id = ?").run('prj-review-a');
    const res = await testRequest(env, '/api/projects/evaluate', {
      method: 'POST',
      token: 'adm-1',
      body: {
        projectId: 'prj-review-a',
        actionId: 'act-eval-bad',
        drawingVersionId: 'ver-review-a-1',
        overallResult: 'PENDING_REVISION',
        criteriaJson: { 'Accuracy': 5, 'Technical Standards': 4 }
      }
    });
    assert.equal(res.status, 400);
    const body = await res.json();
    assert.match(body.error, /Invalid overall result/);
  });
});

// =========================================================================
// TEST SUITE: MANDATORY CROSS-USER DATA ISOLATION (SECTION 7)
// =========================================================================
test('Section 7: Cross-User Data Isolation (Engineers, Draughtsmen, Students, Admin)', async (t) => {
  const { rawDb, env, storedFiles } = createIsolatedTestDb();
  seedIsolationFixtures(rawDb, storedFiles);

  // 1. ENGINEER ISOLATION
  await t.test('Engineer A private project is INVISIBLE to Engineer B and C in project list', async () => {
    const resB = await testRequest(env, '/api/projects', { token: 'eng-b' });
    assert.equal(resB.status, 200);
    const projectsB = await resB.json();
    assert.ok(projectsB.every(p => p.client_id !== 'eng-a'), 'Engineer B saw Engineer A project in list!');

    const resC = await testRequest(env, '/api/projects', { token: 'eng-c' });
    assert.equal(resC.status, 200);
    const projectsC = await resC.json();
    assert.ok(projectsC.every(p => p.client_id !== 'eng-a'), 'Engineer C saw Engineer A project in list!');
  });

  await t.test('Engineer B is DENIED direct access to Engineer A private project (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a', { token: 'eng-b' });
    assert.equal(res.status, 403);
    const body = await res.json();
    assert.match(body.error, /Forbidden/);
  });

  await t.test('Engineer C is DENIED direct access to Engineer A private project (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a', { token: 'eng-c' });
    assert.equal(res.status, 403);
  });

  await t.test('Engineer B cannot read Engineer A project files (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/files', { token: 'eng-b' });
    assert.equal(res.status, 403);
  });

  await t.test('Engineer B cannot download Engineer A project files (403)', async () => {
    const res = await testRequest(env, '/api/files/file-eng-a-brief/download', { token: 'eng-b' });
    assert.equal(res.status, 403);
  });

  await t.test('Engineer B cannot read Engineer A collaboration messages (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/messages', { token: 'eng-b' });
    assert.equal(res.status, 403);
  });

  await t.test('Engineer B cannot send messages to Engineer A project (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/messages', {
      method: 'POST',
      token: 'eng-b',
      body: { message: 'Infiltrating project A' }
    });
    assert.equal(res.status, 403);
  });

  await t.test('Engineer B cannot evaluate or approve Engineer A project (403)', async () => {
    const res = await testRequest(env, '/api/projects/evaluate', {
      method: 'POST',
      token: 'eng-b',
      body: {
        projectId: 'prj-review-a',
        actionId: 'act-eval-unauth-b',
        drawingVersionId: 'ver-review-a-1',
        overallResult: 'APPROVED',
        criteriaJson: { 'Accuracy': 5, 'Technical Standards': 5 }
      }
    });
    assert.equal(res.status, 403);
  });

  // 2. DRAUGHTSMAN ISOLATION
  await t.test('Draughtsman B is DENIED direct access to Draughtsman A assigned project (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a', { token: 'drg-b' });
    assert.equal(res.status, 403);
  });

  await t.test('Draughtsman B cannot read Project A messages (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/messages', { token: 'drg-b' });
    assert.equal(res.status, 403);
  });

  await t.test('Draughtsman B cannot download Project A files (403)', async () => {
    const res = await testRequest(env, '/api/files/file-eng-a-brief/download', { token: 'drg-b' });
    assert.equal(res.status, 403);
  });

  await t.test('Unassigned Draughtsman C cannot access any project (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a', { token: 'drg-c' });
    assert.equal(res.status, 403);
  });

  // 3. STUDENT ISOLATION
  await t.test('Student B is DENIED direct access to Student A training project (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-train-a', { token: 'stu-b' });
    assert.equal(res.status, 403);
  });

  await t.test('Student B cannot view Student A drawings or versions (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-train-a/drawing_versions', { token: 'stu-b' });
    assert.equal(res.status, 403);
  });

  await t.test('Student B cannot download Student A submission file (403)', async () => {
    const res = await testRequest(env, '/api/files/file-stu-a-drawing/download', { token: 'stu-b' });
    assert.equal(res.status, 403);
  });

  await t.test('Student B cannot submit drawings to Student A project (403)', async () => {
    const res = await testRequest(env, '/api/projects/submit-drawing', {
      method: 'POST',
      token: 'stu-b',
      body: { projectId: 'prj-train-a', fileId: 'file-stu-b-drawing' }
    });
    assert.equal(res.status, 403);
  });

  // 4. CROSS-ROLE PRIVILEGE SEPARATION
  await t.test('Student cannot create commercial projects via POST /api/projects (403)', async () => {
    const res = await testRequest(env, '/api/projects', {
      method: 'POST',
      token: 'stu-a',
      body: { projectName: 'Student Commercial Tower' }
    });
    assert.equal(res.status, 403);
  });

  await t.test('Draughtsman cannot create commercial projects via POST /api/projects (403)', async () => {
    const res = await testRequest(env, '/api/projects', {
      method: 'POST',
      token: 'drg-a',
      body: { projectName: 'Draughtsman Project' }
    });
    assert.equal(res.status, 403);
  });

  await t.test('Non-Admin (Student) cannot access admin endpoints (403)', async () => {
    const res = await testRequest(env, '/api/admin/student-submissions', { token: 'stu-a' });
    assert.equal(res.status, 403);
  });

  await t.test('Admin CAN access projects and review submissions (200)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a', { token: 'adm-1' });
    assert.equal(res.status, 200);
  });
});

// =========================================================================
// TEST SUITE: FINDING F1.1-01 (EVALUATIONS ACCESS ISOLATION)
// =========================================================================
test('Finding F1.1-01: Evaluations Access Isolation (GET /api/projects/:projectId/evaluations)', async (t) => {
  const { rawDb, env, storedFiles } = createIsolatedTestDb();
  seedIsolationFixtures(rawDb, storedFiles);

  await t.test('Owning Engineer A CAN read own project evaluations (200)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/evaluations', { token: 'eng-a' });
    assert.equal(res.status, 200);
    const evals = await res.json();
    assert.equal(evals.length, 1);
    assert.equal(evals[0].id, 'eval-eng-a');
  });

  await t.test('Unrelated Engineer B is DENIED reading Engineer A project evaluations (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/evaluations', { token: 'eng-b' });
    assert.equal(res.status, 403);
  });

  await t.test('Unrelated Engineer C is DENIED reading Engineer A project evaluations (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/evaluations', { token: 'eng-c' });
    assert.equal(res.status, 403);
  });

  await t.test('Assigned Draughtsman A CAN read assigned Project A evaluations (200)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/evaluations', { token: 'drg-a' });
    assert.equal(res.status, 200);
    const evals = await res.json();
    assert.equal(evals.length, 1);
  });

  await t.test('Unrelated Draughtsman B is DENIED reading Project A evaluations (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/evaluations', { token: 'drg-b' });
    assert.equal(res.status, 403);
  });

  await t.test('Assigned Student A CAN read assigned training project evaluations (200)', async () => {
    const res = await testRequest(env, '/api/projects/prj-train-a/evaluations', { token: 'stu-a' });
    assert.equal(res.status, 200);
    const evals = await res.json();
    assert.equal(evals.length, 1);
    assert.equal(evals[0].id, 'eval-train-a');
  });

  await t.test('Unassigned Student B is DENIED reading Student A training project evaluations (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-train-a/evaluations', { token: 'stu-b' });
    assert.equal(res.status, 403);
  });

  await t.test('Student A is DENIED reading commercial project evaluations (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/evaluations', { token: 'stu-a' });
    assert.equal(res.status, 403);
  });

  await t.test('Admin CAN read any project evaluations (200)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/evaluations', { token: 'adm-1' });
    assert.equal(res.status, 200);
  });

  await t.test('Non-existent project evaluations return 404', async () => {
    const res = await testRequest(env, '/api/projects/prj-non-existent/evaluations', { token: 'eng-a' });
    assert.equal(res.status, 404);
  });
});

// =========================================================================
// TEST SUITE: FINDING F1.1-02 (FILE DELETION ACCESS CONTROL)
// =========================================================================
test('Finding F1.1-02: File Deletion Access Control (DELETE /api/projects/:projectId/files/:fileId)', async (t) => {
  const { rawDb, env, storedFiles } = createIsolatedTestDb();
  seedIsolationFixtures(rawDb, storedFiles);

  await t.test('Draughtsman A is DENIED deleting Engineer A brief file (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/files/file-eng-a-brief', {
      method: 'DELETE',
      token: 'drg-a'
    });
    assert.equal(res.status, 403);
    // Verify D1 record and storage object still exist
    const file = rawDb.prepare('SELECT id FROM files WHERE id = ?').get('file-eng-a-brief');
    assert.ok(file);
    assert.ok(storedFiles.has('projects/prj-eng-a/client_upload/brief_a.dwg'));
  });

  await t.test('Student A is DENIED deleting instructor reference file (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-train-a/files/file-ref-train-a', {
      method: 'DELETE',
      token: 'stu-a'
    });
    assert.equal(res.status, 403);
    const file = rawDb.prepare('SELECT id FROM files WHERE id = ?').get('file-ref-train-a');
    assert.ok(file);
    assert.ok(storedFiles.has('projects/prj-train-a/reference/reference_a.dwg'));
  });

  await t.test('Engineer B is DENIED deleting Engineer A file (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/files/file-eng-a-brief', {
      method: 'DELETE',
      token: 'eng-b'
    });
    assert.equal(res.status, 403);
  });

  await t.test('Draughtsman A is DENIED deleting formal submitted drawing version (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-review-a/files/file-review-a-ver1', {
      method: 'DELETE',
      token: 'drg-a'
    });
    assert.equal(res.status, 403);
    const file = rawDb.prepare('SELECT id FROM files WHERE id = ?').get('file-review-a-ver1');
    assert.ok(file);
  });

  await t.test('Draughtsman A CAN delete own unpromoted workspace draft (200)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/files/file-drg-a-draft', {
      method: 'DELETE',
      token: 'drg-a'
    });
    assert.equal(res.status, 200);
    // Verify removed from D1 and storage
    const file = rawDb.prepare('SELECT id FROM files WHERE id = ?').get('file-drg-a-draft');
    assert.equal(file, undefined);
    assert.equal(storedFiles.has('projects/prj-eng-a/workspace_draft/draft_dan.dwg'), false);
  });

  await t.test('Student A CAN delete own unpromoted workspace draft (200)', async () => {
    const res = await testRequest(env, '/api/projects/prj-train-a/files/file-stu-a-draft', {
      method: 'DELETE',
      token: 'stu-a'
    });
    assert.equal(res.status, 200);
    const file = rawDb.prepare('SELECT id FROM files WHERE id = ?').get('file-stu-a-draft');
    assert.equal(file, undefined);
  });

  await t.test('Admin CAN delete a file for administrative cleanup (200)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/files/file-to-admin-delete', {
      method: 'DELETE',
      token: 'adm-1'
    });
    assert.equal(res.status, 200);
    const file = rawDb.prepare('SELECT id FROM files WHERE id = ?').get('file-to-admin-delete');
    assert.equal(file, undefined);
  });

  await t.test('Deleting non-existent file returns 404', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/files/file-non-existent', {
      method: 'DELETE',
      token: 'eng-a'
    });
    assert.equal(res.status, 404);
  });

  await t.test('Deleting file from wrong project returns 404', async () => {
    // file-eng-b-brief belongs to prj-eng-b, not prj-eng-a
    const res = await testRequest(env, '/api/projects/prj-eng-a/files/file-eng-b-brief', {
      method: 'DELETE',
      token: 'eng-a'
    });
    assert.equal(res.status, 404);
  });
});

// =========================================================================
// TEST SUITE: FINDING F1.1-03 (ASSIGNMENT DETAIL AUTHORIZATION)
// =========================================================================
test('Finding F1.1-03: Assignment Detail Authorization (GET /api/assignments/:id)', async (t) => {
  const { rawDb, env, storedFiles } = createIsolatedTestDb();
  seedIsolationFixtures(rawDb, storedFiles);

  await t.test('Assigned Draughtsman A CAN view own assignment asg-drg-a (200)', async () => {
    const res = await testRequest(env, '/api/assignments/asg-drg-a', { token: 'drg-a' });
    assert.equal(res.status, 200);
    const asg = await res.json();
    assert.equal(asg.id, 'asg-drg-a');
    assert.equal(asg.draughtsman_id, 'drg-a');
  });

  await t.test('Draughtsman B is DENIED viewing Draughtsman A assignment asg-drg-a (403)', async () => {
    const res = await testRequest(env, '/api/assignments/asg-drg-a', { token: 'drg-b' });
    assert.equal(res.status, 403);
  });

  await t.test('Owning Engineer A CAN view assignment asg-drg-a for own project (200)', async () => {
    const res = await testRequest(env, '/api/assignments/asg-drg-a', { token: 'eng-a' });
    assert.equal(res.status, 200);
    const asg = await res.json();
    assert.equal(asg.id, 'asg-drg-a');
  });

  await t.test('Unrelated Engineer B is DENIED viewing Project A assignment asg-drg-a (403)', async () => {
    const res = await testRequest(env, '/api/assignments/asg-drg-a', { token: 'eng-b' });
    assert.equal(res.status, 403);
  });

  await t.test('Student A is DENIED viewing commercial assignment asg-drg-a (403)', async () => {
    const res = await testRequest(env, '/api/assignments/asg-drg-a', { token: 'stu-a' });
    assert.equal(res.status, 403);
  });

  await t.test('Admin CAN view any assignment (200)', async () => {
    const res = await testRequest(env, '/api/assignments/asg-drg-a', { token: 'adm-1' });
    assert.equal(res.status, 200);
  });

  await t.test('Non-existent assignment returns 404', async () => {
    const res = await testRequest(env, '/api/assignments/asg-non-existent', { token: 'drg-a' });
    assert.equal(res.status, 404);
  });
});


// =========================================================================
// PHASE 3: MASTER DIRECTIVE - 12 ACCOUNT ISOLATION & DATA INTEGRITY SCENARIOS
// =========================================================================
test('Phase 3: Comprehensive Account Isolation & Data Integrity (12 Scenarios)', async (t) => {
  const { rawDb, env, storedFiles } = createIsolatedTestDb();
  seedIsolationFixtures(rawDb, storedFiles);

  // 1. Account A cannot read Account B's private project
  await t.test('1. Account A cannot read Account B private project (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-b', { token: 'eng-a' });
    assert.equal(res.status, 403);
    const body = await res.json();
    assert.match(body.error, /Forbidden/);
  });

  // 2. Account A cannot alter or delete Account B's project
  await t.test('2. Account A cannot alter or delete Account B project (403)', async () => {
    // Attempt to alter project via POST /api/projects with Account B project ID
    const alterRes = await testRequest(env, '/api/projects', {
      method: 'POST',
      token: 'eng-a',
      body: {
        id: 'prj-eng-b',
        projectName: 'Hijacked by Alice',
        projectAddress: 'Malicious Address'
      }
    });
    assert.equal(alterRes.status, 403);

    // Verify D1 record for prj-eng-b is untouched
    const proj = rawDb.prepare('SELECT project_name, project_address, client_id FROM projects WHERE id = ?').get('prj-eng-b');
    assert.equal(proj.project_name, 'Engineer B Tower');
    assert.equal(proj.client_id, 'eng-b');

    // Attempt to submit Account B's project
    const submitRes = await testRequest(env, '/api/projects/submit', {
      method: 'POST',
      token: 'eng-a',
      body: { projectId: 'prj-eng-b', actionId: 'act-unauth-submit' }
    });
    assert.equal(submitRes.status, 403);

    // Attempt to delete Account B's brief file
    const delRes = await testRequest(env, '/api/projects/prj-eng-b/files/file-eng-b-brief', {
      method: 'DELETE',
      token: 'eng-a'
    });
    assert.equal(delRes.status, 403);
    assert.ok(storedFiles.has('projects/prj-eng-b/client_upload/brief_b.dwg'));
  });

  // 3. Account A cannot read or overwrite Account B's drawing or drawing version
  await t.test('3. Account A cannot read or overwrite Account B drawing or version (403/400)', async () => {
    // Read attempt on private file
    const readRes = await testRequest(env, '/api/files/file-eng-b-brief/download', { token: 'eng-a' });
    assert.equal(readRes.status, 403);

    // Overwrite / cross-project draft file promotion attempt
    const hijackRes = await testRequest(env, '/api/projects/submit-drawing', {
      method: 'POST',
      token: 'drg-a',
      body: {
        projectId: 'prj-eng-a',
        actionId: 'act-hijack-drawing',
        draftFileId: 'file-eng-b-brief' // File belonging to Account B
      }
    });
    assert.equal(hijackRes.status, 400);
    const body = await hijackRes.json();
    assert.match(body.error, /Invalid draft file/);
  });

  // 4. An unassigned Draughtsman cannot access a project assigned to another Draughtsman
  await t.test('4. Unassigned Draughtsman cannot access project assigned to another (403)', async () => {
    // Draughtsman B attempts to access Project A (assigned to Draughtsman A)
    const resProj = await testRequest(env, '/api/projects/prj-eng-a', { token: 'drg-b' });
    assert.equal(resProj.status, 403);

    const resAsg = await testRequest(env, '/api/assignments/asg-drg-a', { token: 'drg-b' });
    assert.equal(resAsg.status, 403);

    const resFiles = await testRequest(env, '/api/projects/prj-eng-a/files', { token: 'drg-b' });
    assert.equal(resFiles.status, 403);
  });

  // 5. An authorized assigned Draughtsman can access the intended assignment
  await t.test('5. Authorized assigned Draughtsman can access intended assignment (200)', async () => {
    const resAsg = await testRequest(env, '/api/assignments/asg-drg-a', { token: 'drg-a' });
    assert.equal(resAsg.status, 200);
    const asgData = await resAsg.json();
    assert.equal(asgData.id, 'asg-drg-a');
    assert.equal(asgData.project_name, 'Engineer A Villa');

    const resProj = await testRequest(env, '/api/projects/prj-eng-a', { token: 'drg-a' });
    assert.equal(resProj.status, 200);
  });

  // 6. An Engineer cannot access another Engineer's private records without authorization
  await t.test('6. Engineer cannot access another Engineer private records (403)', async () => {
    // Evaluations
    const resEval = await testRequest(env, '/api/projects/prj-eng-a/evaluations', { token: 'eng-b' });
    assert.equal(resEval.status, 403);

    // Collaboration messages
    const resMsg = await testRequest(env, '/api/projects/prj-eng-a/messages', { token: 'eng-b' });
    assert.equal(resMsg.status, 403);

    // Drawing versions
    const resVer = await testRequest(env, '/api/projects/prj-eng-a/drawing_versions', { token: 'eng-b' });
    assert.equal(resVer.status, 403);

    // Corrections
    const resCorr = await testRequest(env, '/api/projects/prj-eng-a/corrections', { token: 'eng-b' });
    assert.equal(resCorr.status, 403);
  });

  // 7. A Student cannot access another Student's private training records or submissions
  await t.test('7. Student cannot access another Student private training records (403/404)', async () => {
    // Student B attempts to access Student A training project
    const resProj = await testRequest(env, '/api/projects/prj-train-a', { token: 'stu-b' });
    assert.equal(resProj.status, 403);

    // Student B attempts to view Student A drawing versions
    const resVer = await testRequest(env, '/api/projects/prj-train-a/drawing_versions', { token: 'stu-b' });
    assert.equal(resVer.status, 403);

    // Student B attempts to download Student A submission drawing
    const resDl = await testRequest(env, '/api/files/file-stu-a-drawing/download', { token: 'stu-b' });
    assert.equal(resDl.status, 403);

    // Student B attempts to access Student A credential certificate
    const resCert = await testRequest(env, '/api/student/credentials/cred-stu-a/certificate', { token: 'stu-b' });
    assert.equal(resCert.status, 404); // Scoped by student_id in query
  });

  // 8. Tampered UID, email, role, project ID, assignment ID, drawing ID, or file key cannot bypass backend authorization
  await t.test('8. Tampered parameters cannot bypass backend authorization (403/401)', async () => {
    // Client-supplied role in profile update cannot grant ADMIN role
    const resRole = await testRequest(env, '/api/users', {
      method: 'POST',
      token: 'eng-a',
      body: { name: 'Alice Hacker', role: 'ADMIN' }
    });
    // In test environment, allowedRoles is CLIENT, DRAUGHTSMAN; in production, self-service ADMIN is rejected
    assert.ok(resRole.status === 400 || resRole.status === 403);
    const userRow = rawDb.prepare('SELECT role FROM users WHERE id = ?').get('eng-a');
    assert.equal(userRow.role, 'ENGINEER');

    // Missing or invalid Authorization header returns 401
    const resNoToken = await testRequest(env, '/api/projects', {
      method: 'POST',
      token: false,
      body: { projectName: 'Forged' }
    });
    assert.equal(resNoToken.status, 401);

    const resBadHeader = await testRequest(env, '/api/projects', {
      method: 'POST',
      token: false,
      headers: { 'Authorization': 'Basic invalid-token' },
      body: { projectName: 'Forged' }
    });
    assert.equal(resBadHeader.status, 401);

    // Path traversal in file request returns 404
    const resPathTrav = await testRequest(env, '/api/files/..%2F..%2Fetc/download', { token: 'eng-a' });
    assert.equal(resPathTrav.status, 404);
  });

  // 9. Legal acceptance and consent records cannot be changed or accessed by an unauthorized account
  await t.test('9. Legal records cannot be modified or accessed cross-account (200 scoped / 403 admin)', async () => {
    // User A privacy requests are strictly isolated to User A
    const resPrivReq = await testRequest(env, '/api/users/me/privacy-requests', { token: 'eng-a' });
    assert.equal(resPrivReq.status, 200);
    const privData = await resPrivReq.json();
    assert.ok(Array.isArray(privData.requests));

    // Ordinary user cannot inspect platform-wide consent audit logs
    const resConsents = await testRequest(env, '/api/admin/legal/consents', { token: 'eng-a' });
    assert.equal(resConsents.status, 403);
  });

  // 10. Existing authorized Admin capabilities continue to work without granting ordinary users Admin access
  await t.test('10. Admin capabilities work for Admin, denied for ordinary users (200 vs 403)', async () => {
    // Admin can inspect any commercial project
    const adminRes = await testRequest(env, '/api/projects/prj-eng-a', { token: 'adm-1' });
    assert.equal(adminRes.status, 200);

    // Admin can access student profile management
    const adminStuRes = await testRequest(env, '/api/admin/students/stu-a', { token: 'adm-1' });
    assert.equal(adminStuRes.status, 200);

    // Ordinary engineer cannot access admin student management
    const engStuRes = await testRequest(env, '/api/admin/students/stu-a', { token: 'eng-a' });
    assert.equal(engStuRes.status, 403);
  });

  // 11. Failed unauthorized operations do not partially modify another account's records
  await t.test('11. Failed unauthorized operations do not partially modify records', async () => {
    // Record baseline state of Engineer B project
    const beforeProj = rawDb.prepare('SELECT * FROM projects WHERE id = ?').get('prj-eng-b');

    // Attempt unauthorized evaluation by Engineer A on Engineer B project
    const resEval = await testRequest(env, '/api/projects/evaluate', {
      method: 'POST',
      token: 'eng-a',
      body: {
        projectId: 'prj-eng-b',
        actionId: 'act-unauth-eval',
        drawingVersionId: 'ver-review-a-1',
        overallResult: 'APPROVED'
      }
    });
    assert.equal(resEval.status, 403);

    // Verify baseline state is 100% identical
    const afterProj = rawDb.prepare('SELECT * FROM projects WHERE id = ?').get('prj-eng-b');
    assert.deepEqual(beforeProj, afterProj);
  });

  // 12. Existing legitimate Engineer-Draughtsman collaboration continues to work
  await t.test('12. Existing legitimate Engineer-Draughtsman collaboration continues to work', async () => {
    // Engineer A sends collaboration message on Project A
    const msgRes = await testRequest(env, '/api/projects/prj-eng-a/messages', {
      method: 'POST',
      token: 'eng-a',
      body: { message: 'Hello Dan, please review the revised wall schedule.' }
    });
    assert.equal(msgRes.status, 201);

    // Assigned Draughtsman A reads collaboration message
    const readMsgRes = await testRequest(env, '/api/projects/prj-eng-a/messages', { token: 'drg-a' });
    assert.equal(readMsgRes.status, 200);
    const messages = await readMsgRes.json();
    assert.ok(messages.some(m => m.message.includes('revised wall schedule')));

    // Assigned Draughtsman A downloads Engineer A brief
    const dlBriefRes = await testRequest(env, '/api/files/file-eng-a-brief/download', { token: 'drg-a' });
    assert.equal(dlBriefRes.status, 200);
  });
});

test('Finding F1.2-01: In-App Notifications Ownership & Cross-User Privacy', async (t) => {
  const { rawDb, env } = createIsolatedTestDb();
  seedIsolationFixtures(rawDb, new Map());

  // Seed private notifications for Engineer A and Engineer B
  const insertNotif = rawDb.prepare(
    'INSERT INTO notifications (id, user_id, project_id, type, title, message, is_read) VALUES (?, ?, ?, ?, ?, ?, ?)'
  );
  insertNotif.run('notif-eng-a-1', 'eng-a', 'prj-eng-a', 'STATUS_CHANGE', 'Drawing Uploaded', 'Draughtsman uploaded draft', 0);
  insertNotif.run('notif-eng-b-1', 'eng-b', 'prj-eng-b', 'STATUS_CHANGE', 'Project Assigned', 'Project was assigned', 0);

  await t.test('Engineer A list /api/notifications contains own notification and excludes Engineer B (200)', async () => {
    const res = await testRequest(env, '/api/notifications', { token: 'eng-a' });
    assert.equal(res.status, 200);
    const data = await res.json();
    assert.ok(data.some(n => n.id === 'notif-eng-a-1'));
    assert.ok(!data.some(n => n.id === 'notif-eng-b-1'));
  });

  await t.test('Engineer B list /api/notifications contains own notification and excludes Engineer A (200)', async () => {
    const res = await testRequest(env, '/api/notifications', { token: 'eng-b' });
    assert.equal(res.status, 200);
    const data = await res.json();
    assert.ok(data.some(n => n.id === 'notif-eng-b-1'));
    assert.ok(!data.some(n => n.id === 'notif-eng-a-1'));
  });

  await t.test('Engineer B is DENIED marking Engineer A notification as read via PATCH (403)', async () => {
    const res = await testRequest(env, '/api/notifications/notif-eng-a-1/read', {
      method: 'PATCH',
      token: 'eng-b'
    });
    assert.equal(res.status, 403);
  });

  await t.test('Engineer B is DENIED marking Engineer A notification as read via POST (403)', async () => {
    const res = await testRequest(env, '/api/notifications/notif-eng-a-1/read', {
      method: 'POST',
      token: 'eng-b'
    });
    assert.equal(res.status, 403);
  });

  await t.test('Engineer A CAN mark own notification as read via PATCH (200)', async () => {
    const res = await testRequest(env, '/api/notifications/notif-eng-a-1/read', {
      method: 'PATCH',
      token: 'eng-a'
    });
    assert.equal(res.status, 200);
    const row = rawDb.prepare('SELECT is_read FROM notifications WHERE id = ?').get('notif-eng-a-1');
    assert.equal(row.is_read, 1);
  });

  await t.test('Engineer A CAN mark all own notifications as read via PATCH /read-all (200)', async () => {
    // Re-seed unread notification
    insertNotif.run('notif-eng-a-2', 'eng-a', 'prj-eng-a', 'STATUS_CHANGE', 'New Correction', 'Please review markup', 0);
    const res = await testRequest(env, '/api/notifications/read-all', {
      method: 'PATCH',
      token: 'eng-a'
    });
    assert.equal(res.status, 200);
    const row = rawDb.prepare('SELECT is_read FROM notifications WHERE id = ?').get('notif-eng-a-2');
    assert.equal(row.is_read, 1);
  });
});

test('Finding F1.2-02: Project Financials & Invoicing Role Restrictions (ADMIN/STUDIO_ADMIN)', async (t) => {
  const { rawDb, env } = createIsolatedTestDb();
  seedIsolationFixtures(rawDb, new Map());

  // Non-admin roles (Engineer, Draughtsman, Student) cannot access financials
  await t.test('Engineer A is DENIED viewing project financials (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/financials', { token: 'eng-a' });
    assert.equal(res.status, 403);
  });

  await t.test('Draughtsman A is DENIED viewing project financials (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/financials', { token: 'drg-a' });
    assert.equal(res.status, 403);
  });

  await t.test('Student A is DENIED viewing project financials (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/financials', { token: 'stu-a' });
    assert.equal(res.status, 403);
  });

  await t.test('Admin adm-1 CAN view project financials (200)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/financials', { token: 'adm-1' });
    assert.equal(res.status, 200);
    const data = await res.json();
    assert.ok(data.hasOwnProperty('total_value'));
    assert.ok(data.hasOwnProperty('paid_amount'));
  });

  await t.test('Engineer A is DENIED updating project total_value via PATCH (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/financials/total_value', {
      method: 'PATCH',
      token: 'eng-a',
      body: { total_value: 50000 }
    });
    assert.equal(res.status, 403);
  });

  await t.test('Admin adm-1 CAN update project total_value via PATCH (200)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/financials/total_value', {
      method: 'PATCH',
      token: 'adm-1',
      body: { total_value: 50000 }
    });
    assert.equal(res.status, 200);
    const data = await res.json();
    assert.equal(data.total_value, 50000);
    const row = rawDb.prepare('SELECT total_value FROM projects WHERE id = ?').get('prj-eng-a');
    assert.equal(row.total_value, 50000);
  });

  await t.test('Engineer A is DENIED creating project invoice (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/invoices', {
      method: 'POST',
      token: 'eng-a',
      body: { amount: 20000, due_date: '2026-12-31' }
    });
    assert.equal(res.status, 403);
  });

  await t.test('Admin adm-1 receives 501 FEATURE_FROZEN when attempting to create invoice', async () => {
    const res = await testRequest(env, '/api/projects/prj-eng-a/invoices', {
      method: 'POST',
      token: 'adm-1',
      body: { amount: 20000, due_date: '2026-12-31' }
    });
    assert.equal(res.status, 501);
    const data = await res.json();
    assert.equal(data.code, 'FEATURE_FROZEN');
  });

  await t.test('Engineer A is DENIED recording payment on invoice (403)', async () => {
    const res = await testRequest(env, '/api/invoices/inv-dummy/payments', {
      method: 'POST',
      token: 'eng-a',
      body: { amount: 10000, payment_method: 'MANUAL' }
    });
    assert.equal(res.status, 403);
  });

  await t.test('Admin adm-1 receives 501 FEATURE_FROZEN when attempting to record payment', async () => {
    // Seed an invoice to test payment endpoint frozen behavior
    rawDb.prepare(`
      INSERT INTO invoices (id, project_id, invoice_number, amount, currency, status, due_date, created_at)
      VALUES ('inv-test-1', 'prj-eng-a', 'INV-20261023-TEST', 20000, 'INR', 'ISSUED', '2026-12-31', CURRENT_TIMESTAMP)
    `).run();

    const res = await testRequest(env, '/api/invoices/inv-test-1/payments', {
      method: 'POST',
      token: 'adm-1',
      body: { amount: 10000, payment_method: 'MANUAL' }
    });
    assert.equal(res.status, 501);
    const data = await res.json();
    assert.equal(data.code, 'FEATURE_FROZEN');
  });
});
