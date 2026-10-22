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

const bundlePath = path.join(workerRoot, 'node_modules', '.test_app_contract_bundle.mjs');
esbuild.buildSync({
  entryPoints: [path.join(workerRoot, 'src', 'index.ts')],
  bundle: true,
  format: 'esm',
  platform: 'node',
  write: true,
  outfile: bundlePath,
});

const { default: app } = await import(`file://${bundlePath}`);

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

  const storage = {
    async get(key) {
      return {
        body: 'test-binary-stream',
        httpEtag: 'mock-etag-1234',
        writeHttpMetadata(headers) {
          headers.set('content-type', 'application/pdf');
        }
      };
    },
    async put(key, body, options) {
      return {};
    }
  };

  return { rawDb: db, env: { DB: d1, STORAGE: storage } };
}

function seedTestData(rawDb) {
  const insertUser = rawDb.prepare('INSERT INTO users (id, email, name, role) VALUES (?, ?, ?, ?)');
  insertUser.run('student-1', 'student1@test.com', 'Student One', 'STUDENT');
  insertUser.run('student-2', 'student2@test.com', 'Student Two', 'STUDENT');
  insertUser.run('admin-1', 'admin1@test.com', 'Admin One', 'ADMIN');
  insertUser.run('engineer-1', 'engineer1@test.com', 'Engineer One', 'ENGINEER');
  insertUser.run('draughtsman-1', 'draughtsman1@test.com', 'Draughtsman One', 'DRAUGHTSMAN');

  // Module
  rawDb.prepare("INSERT INTO training_modules (id, category, type, level, title, description) VALUES (?, ?, ?, ?, ?, ?)").run(
    'mod-test-1', 'Architectural', 'Module', 'Beginner', 'Floor Plan Design', 'Module 101'
  );

  // Training project
  rawDb.prepare(`
    INSERT INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, is_training_project, training_module_id, draughtsman_id, draughtsman_name)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run('prj-student-1', 'admin-1', 'Studio Training Villa', '123 Studio Way', 'Ground Floor Plan', 'Architectural', '2000 sq ft', 'IN_PROGRESS', 1, 'mod-test-1', 'student-1', 'Student One');

  // Assignment
  rawDb.prepare(`
    INSERT INTO student_assignments (id, student_id, project_id, assignment_type, status)
    VALUES (?, ?, ?, 'PRACTICAL', 'ACCEPTED')
  `).run('sa-student-1', 'student-1', 'prj-student-1');

  // Draft file
  rawDb.prepare(`
    INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run('file-draft-1', 'prj-student-1', 'student-1', 'draft_v1.dwg', 'draft_v1.dwg', 'files/prj-student-1/draft_v1.dwg', 'application/acad', 1024, 'workspace_draft', 'COMPLETED');

  // Seed active Terms and consent for test users
  rawDb.prepare(`
    INSERT INTO legal_documents (id, document_type, version, title, content, effective_at, status, is_mandatory, locale)
    VALUES ('doc-terms-asc', 'TERMS_AND_CONDITIONS', '1.0.0', 'Platform Terms', '# Terms', CURRENT_TIMESTAMP, 'EFFECTIVE', 1, 'en-IN')
  `).run();

  const insertEvent = rawDb.prepare(`
    INSERT INTO legal_consent_events (id, user_id, document_id, document_type, document_version, action_type, consent_purpose, idempotency_key, ip_hash, source)
    VALUES (?, ?, 'doc-terms-asc', 'TERMS_AND_CONDITIONS', '1.0.0', 'ACCEPT', 'DEFAULT', ?, 'hash-ip', 'WEB_APP')
  `);

  const insertConsent = rawDb.prepare(`
    INSERT INTO user_consent_state (id, user_id, consent_type, purpose_tag, current_status, accepted_version, last_event_id, updated_at)
    VALUES (?, ?, 'TERMS', 'DEFAULT', 'ACCEPTED', '1.0.0', ?, CURRENT_TIMESTAMP)
  `);

  for (const uid of ['student-1', 'student-2', 'engineer-1', 'draughtsman-1']) {
    const eventId = 'evt-terms-' + uid;
    insertEvent.run(eventId, uid, 'idem-' + uid);
    insertConsent.run('cst-' + uid, uid, eventId);
  }
}

async function testRequest(env, path, options = {}) {
  const headers = { ...options.headers };
  if (options.token !== null && !headers['Authorization'] && !headers['authorization']) {
    headers['Authorization'] = `Bearer mock-token:${options.token || 'student-1'}`;
  }
  return app.request(path, {
    method: options.method || 'GET',
    headers,
    body: options.body ? JSON.stringify(options.body) : undefined,
  }, env);
}

// -------------------------------------------------------------
// TESTS
// -------------------------------------------------------------

test('1. Student Drawing Submission & Version Creation', async (t) => {
  const { rawDb, env } = createIsolatedTestDb();
  seedTestData(rawDb);

  await t.test('Student can submit draft -> transitions to UNDER_ENGINEER_REVIEW and creates drawing_version', async () => {
    const res = await testRequest(env, '/api/projects/submit-drawing', {
      method: 'POST',
      token: 'student-1',
      body: {
        projectId: 'prj-student-1',
        actionId: 'act-submit-1',
        draftFileId: 'file-draft-1'
      }
    });

    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.success, true);

    const project = rawDb.prepare('SELECT status, last_action_id FROM projects WHERE id = ?').get('prj-student-1');
    assert.equal(project.status, 'UNDER_ENGINEER_REVIEW');

    const versions = rawDb.prepare('SELECT * FROM drawing_versions WHERE project_id = ?').all('prj-student-1');
    assert.equal(versions.length, 1);
    assert.equal(versions[0].version_number, 1);
    assert.equal(versions[0].file_id, 'file-draft-1');
    assert.equal(versions[0].uploaded_by, 'student-1');
  });

  await t.test('Unassigned student is BLOCKED from submitting (403)', async () => {
    const res = await testRequest(env, '/api/projects/submit-drawing', {
      method: 'POST',
      token: 'student-2',
      body: {
        projectId: 'prj-student-1',
        actionId: 'act-submit-2',
        draftFileId: 'file-draft-1'
      }
    });

    assert.equal(res.status, 403);
  });
});

test('2. Admin Endpoints: Student Submissions & Profile Retrieval', async (t) => {
  const { rawDb, env } = createIsolatedTestDb();
  seedTestData(rawDb);

  // Submit drawing first
  await testRequest(env, '/api/projects/submit-drawing', {
    method: 'POST',
    token: 'student-1',
    body: { projectId: 'prj-student-1', actionId: 'act-sub', draftFileId: 'file-draft-1' }
  });

  await t.test('Admin can list student submissions via /api/admin/student-submissions', async () => {
    const res = await testRequest(env, '/api/admin/student-submissions', {
      method: 'GET',
      token: 'admin-1'
    });

    assert.equal(res.status, 200);
    const submissions = await res.json();
    assert.equal(submissions.length, 1);
    assert.equal(submissions[0].id, 'prj-student-1');
    assert.equal(submissions[0].student_name, 'Student One');
    assert.equal(submissions[0].student_email, 'student1@test.com');
    assert.equal(submissions[0].latest_version_number, 1);
  });

  await t.test('Non-admin is DENIED access to /api/admin/student-submissions (403)', async () => {
    const res = await testRequest(env, '/api/admin/student-submissions', {
      method: 'GET',
      token: 'student-1'
    });
    assert.equal(res.status, 403);
  });

  await t.test('Admin can retrieve student details via /api/admin/students/:id', async () => {
    const res = await testRequest(env, '/api/admin/students/student-1', {
      method: 'GET',
      token: 'admin-1'
    });

    assert.equal(res.status, 200);
    const data = await res.json();
    assert.equal(data.profile.name, 'Student One');
    assert.equal(data.assignments.length, 1);
  });
});

test('3. Review Decision Flow: Request Revision -> Resubmit -> Approve', async (t) => {
  const { rawDb, env } = createIsolatedTestDb();
  seedTestData(rawDb);

  // 1. Initial Student submission
  await testRequest(env, '/api/projects/submit-drawing', {
    method: 'POST',
    token: 'student-1',
    body: { projectId: 'prj-student-1', actionId: 'act-sub-1', draftFileId: 'file-draft-1' }
  });

  const v1 = rawDb.prepare('SELECT id FROM drawing_versions WHERE project_id = ?').get('prj-student-1');

  // 2. Admin requests revision
  await t.test('Admin requests revision with correction instructions', async () => {
    const res = await testRequest(env, '/api/projects/evaluate', {
      method: 'POST',
      token: 'admin-1',
      body: {
        projectId: 'prj-student-1',
        actionId: 'act-eval-corr-1',
        drawingVersionId: v1.id,
        overallResult: 'NEEDS_CORRECTION',
        generalFeedback: 'Adjust door clearance and window annotations.',
        criteriaJson: { 'Accuracy': 3, 'Technical Standards': 3 }
      }
    });

    assert.equal(res.status, 200);

    const project = rawDb.prepare('SELECT status, correction_round FROM projects WHERE id = ?').get('prj-student-1');
    assert.equal(project.status, 'IN_PROGRESS');
    assert.equal(project.correction_round, 1);

    const corrections = rawDb.prepare('SELECT * FROM corrections WHERE project_id = ?').all('prj-student-1');
    assert.equal(corrections.length, 1);
    assert.equal(corrections[0].status, 'OPEN');
    assert.equal(corrections[0].round_number, 1);
  });

  // 3. Student uploads revised draft and resubmits
  rawDb.prepare(`
    INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run('file-draft-2', 'prj-student-1', 'student-1', 'draft_v2.dwg', 'draft_v2.dwg', 'files/prj-student-1/draft_v2.dwg', 'application/acad', 2048, 'workspace_draft', 'COMPLETED');

  await t.test('Student resubmits revised draft -> creates Version 2 and resolves open correction', async () => {
    const res = await testRequest(env, '/api/projects/submit-drawing', {
      method: 'POST',
      token: 'student-1',
      body: {
        projectId: 'prj-student-1',
        actionId: 'act-sub-2',
        draftFileId: 'file-draft-2'
      }
    });

    assert.equal(res.status, 200);

    const project = rawDb.prepare('SELECT status FROM projects WHERE id = ?').get('prj-student-1');
    assert.equal(project.status, 'UNDER_ENGINEER_REVIEW');

    const versions = rawDb.prepare('SELECT * FROM drawing_versions WHERE project_id = ? ORDER BY version_number ASC').all('prj-student-1');
    assert.equal(versions.length, 2);
    assert.equal(versions[1].version_number, 2);
    assert.equal(versions[1].file_id, 'file-draft-2');

    const correction = rawDb.prepare('SELECT status FROM corrections WHERE id = ?').get(versions[1].correction_id);
    assert.equal(correction.status, 'RESOLVED');
  });

  const v2 = rawDb.prepare('SELECT id FROM drawing_versions WHERE project_id = ? AND version_number = 2').get('prj-student-1');

  // 4. Admin approves Version 2
  await t.test('Admin approves drawing -> transitions to COMPLETED and stores rubric', async () => {
    const res = await testRequest(env, '/api/projects/evaluate', {
      method: 'POST',
      token: 'admin-1',
      body: {
        projectId: 'prj-student-1',
        actionId: 'act-eval-appr-1',
        drawingVersionId: v2.id,
        overallResult: 'APPROVED',
        generalFeedback: 'Excellent work! Standards met perfectly.',
        criteriaJson: { 'Accuracy': 5, 'Technical Standards': 5 }
      }
    });

    assert.equal(res.status, 200);

    const project = rawDb.prepare('SELECT status FROM projects WHERE id = ?').get('prj-student-1');
    assert.equal(project.status, 'COMPLETED');

    const evaluation = rawDb.prepare('SELECT * FROM evaluations WHERE drawing_version_id = ?').get(v2.id);
    assert.equal(evaluation.overall_result, 'APPROVED');
  });
});

test('4. Review Decision Flow: Rejection', async (t) => {
  const { rawDb, env } = createIsolatedTestDb();
  seedTestData(rawDb);

  // Submit drawing
  await testRequest(env, '/api/projects/submit-drawing', {
    method: 'POST',
    token: 'student-1',
    body: { projectId: 'prj-student-1', actionId: 'act-sub-rej', draftFileId: 'file-draft-1' }
  });

  const v1 = rawDb.prepare('SELECT id FROM drawing_versions WHERE project_id = ?').get('prj-student-1');

  await t.test('Admin rejects submission via /api/projects/evaluate -> status CANCELLED and rejection reason stored', async () => {
    const res = await testRequest(env, '/api/projects/evaluate', {
      method: 'POST',
      token: 'admin-1',
      body: {
        projectId: 'prj-student-1',
        actionId: 'act-eval-rej-1',
        drawingVersionId: v1.id,
        overallResult: 'REJECTED',
        generalFeedback: 'Scope completely mismatched. Re-enrollment required.',
        criteriaJson: { 'Accuracy': 1, 'Technical Standards': 1 }
      }
    });

    assert.equal(res.status, 200);

    const project = rawDb.prepare('SELECT status, rejection_reason FROM projects WHERE id = ?').get('prj-student-1');
    assert.equal(project.status, 'CANCELLED');
    assert.equal(project.rejection_reason, 'Scope completely mismatched. Re-enrollment required.');

    const notif = rawDb.prepare("SELECT * FROM notifications WHERE user_id = 'student-1' AND type = 'PROJECT_REJECTED'").get();
    assert.ok(notif, 'Student should receive rejection notification');
  });
});
