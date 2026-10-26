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
      if (body && typeof body.getReader === 'function') {
        const reader = body.getReader();
        while (true) {
          const { done } = await reader.read();
          if (done) break;
        }
      }
      return { size: 100 };
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
  const body = (options.body && typeof options.body === 'object' && !(options.body instanceof Uint8Array))
    ? JSON.stringify(options.body)
    : options.body;
  return app.request(path, {
    method: options.method || 'GET',
    headers,
    body,
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

test('5. Practical Assignment Dispatch, Validation & R2 Protection', async (t) => {
  const { rawDb, env } = createIsolatedTestDb();
  seedTestData(rawDb);

  // Setup test projects
  rawDb.prepare(`
    INSERT INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, is_training_project, training_module_id)
    VALUES 
      ('prj-commercial-unassigned', 'admin-1', 'Commercial Office', '77 Market St', 'Floor Plan', 'Architectural', '5000 sq ft', 'WAITING_ASSIGNMENT', 0, NULL),
      ('prj-training-no-mod', 'admin-1', 'Training Villa No Mod', '12 Academy Rd', 'Ground Plan', 'Architectural', '2000 sq ft', 'WAITING_ASSIGNMENT', 1, NULL),
      ('prj-training-bad-mod', 'admin-1', 'Training Villa Bad Mod', '12 Academy Rd', 'Ground Plan', 'Architectural', '2000 sq ft', 'WAITING_ASSIGNMENT', 1, 'non-existent-mod'),
      ('prj-training-ready', 'admin-1', 'Training Villa Valid', '12 Academy Rd', 'Ground Plan', 'Architectural', '2000 sq ft', 'WAITING_ASSIGNMENT', 1, 'mod-test-1')
  `).run();

  await t.test('Assigning student to commercial project fails with INVALID_ASSIGNEE_ROLE (400)', async () => {
    const res = await testRequest(env, '/api/projects/assign', {
      method: 'POST',
      token: 'admin-1',
      body: {
        projectId: 'prj-commercial-unassigned',
        actionId: 'act-assign-comm',
        draughtsmanId: 'student-2'
      }
    });

    assert.equal(res.status, 400);
    const body = await res.json();
    assert.equal(body.code, 'INVALID_ASSIGNEE_ROLE');
  });

  await t.test('Assigning student to training project with missing training_module_id fails (400)', async () => {
    const res = await testRequest(env, '/api/projects/assign', {
      method: 'POST',
      token: 'admin-1',
      body: {
        projectId: 'prj-training-no-mod',
        actionId: 'act-assign-no-mod',
        draughtsmanId: 'student-2'
      }
    });

    assert.equal(res.status, 400);
    const body = await res.json();
    assert.equal(body.code, 'MISSING_TRAINING_MODULE');
  });

  await t.test('Assigning student to training project with invalid training_module_id fails (400)', async () => {
    const res = await testRequest(env, '/api/projects/assign', {
      method: 'POST',
      token: 'admin-1',
      body: {
        projectId: 'prj-training-bad-mod',
        actionId: 'act-assign-bad-mod',
        draughtsmanId: 'student-2'
      }
    });

    assert.equal(res.status, 400);
    const body = await res.json();
    assert.equal(body.code, 'INVALID_TRAINING_MODULE');
  });

  await t.test('Assigning student to eligible training project succeeds (200)', async () => {
    const res = await testRequest(env, '/api/projects/assign', {
      method: 'POST',
      token: 'admin-1',
      body: {
        projectId: 'prj-training-ready',
        actionId: 'act-assign-ok',
        draughtsmanId: 'student-2'
      }
    });

    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.success, true);
    assert.ok(body.assignmentId);

    const project = rawDb.prepare('SELECT status, draughtsman_id, is_training_project FROM projects WHERE id = ?').get('prj-training-ready');
    assert.equal(project.status, 'WAITING_ACCEPTANCE');
    assert.equal(project.draughtsman_id, 'student-2');
    assert.equal(project.is_training_project, 1);

    const sa = rawDb.prepare('SELECT * FROM student_assignments WHERE project_id = ?').get('prj-training-ready');
    assert.ok(sa);
    assert.equal(sa.student_id, 'student-2');
    assert.equal(sa.status, 'PENDING');
  });

  await t.test('Reassigning student on training project succeeds and replaces previous assignment', async () => {
    const res = await testRequest(env, '/api/projects/reassign', {
      method: 'POST',
      token: 'admin-1',
      body: {
        projectId: 'prj-training-ready',
        actionId: 'act-reassign-ok',
        draughtsmanId: 'student-1'
      }
    });

    assert.equal(res.status, 200);
    const prevSa = rawDb.prepare("SELECT status FROM student_assignments WHERE project_id = ? AND student_id = 'student-2'").get('prj-training-ready');
    assert.equal(prevSa.status, 'REPLACED');

    const newSa = rawDb.prepare("SELECT status FROM student_assignments WHERE project_id = ? AND student_id = 'student-1'").get('prj-training-ready');
    assert.equal(newSa.status, 'PENDING');
  });

  await t.test('Deleting a student draft that is in drawing_versions is blocked with 403', async () => {
    // prj-student-1 already had draft file 'file-draft-1'
    // Submit drawing to promote it to drawing_versions
    await testRequest(env, '/api/projects/submit-drawing', {
      method: 'POST',
      token: 'student-1',
      body: { projectId: 'prj-student-1', actionId: 'act-sub-del-test', draftFileId: 'file-draft-1' }
    });

    const res = await testRequest(env, '/api/projects/prj-student-1/files/file-draft-1', {
      method: 'DELETE',
      token: 'student-1'
    });

    assert.equal(res.status, 403);
    const body = await res.json();
    assert.match(body.error, /Submitted drawing versions cannot be deleted/);
  });

  await t.test('Student can download reference and brief attachments on assigned project', async () => {
    rawDb.prepare(`
      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES 
        ('file-ref-1', 'prj-student-1', 'admin-1', 'brief.pdf', 'brief.pdf', 'projects/prj-student-1/reference/brief.pdf', 'application/pdf', 2048, 'reference', 'COMPLETED'),
        ('file-spec-1', 'prj-student-1', 'admin-1', 'spec.pdf', 'spec.pdf', 'projects/prj-student-1/specification/spec.pdf', 'application/pdf', 4096, 'specification', 'COMPLETED')
    `).run();

    const resRef = await testRequest(env, '/api/files/file-ref-1/download', {
      method: 'GET',
      token: 'student-1'
    });
    assert.equal(resRef.status, 200);

    const resSpec = await testRequest(env, '/api/files/file-spec-1/download', {
      method: 'GET',
      token: 'student-1'
    });
    assert.equal(resSpec.status, 200);
  });
});

test('6. Admin Direct Create & Assign Practical Project to Student', async (t) => {
  const { rawDb, env } = createIsolatedTestDb();
  seedTestData(rawDb);

  // Setup a suspended student to verify suspension check
  rawDb.prepare("INSERT INTO users (id, email, name, role, status) VALUES ('student-susp', 'susp@test.com', 'Suspended Student', 'STUDENT', 'SUSPENDED')").run();

  let createdProjectId = '';
  let createdAssignmentId = '';

  await t.test('Admin creates practical project directly assigned to student-1 (201)', async () => {
    const res = await testRequest(env, '/api/admin/projects', {
      method: 'POST',
      token: 'admin-1',
      body: {
        projectName: 'Villa CAD Drafting Practical',
        drawingType: 'FLOOR_PLAN',
        drawingName: 'Ground Floor Plan Package',
        projectAddress: 'Campus Studio Lab 2',
        instructions: 'Draft 2BHK layout with dimensions per NBC standards',
        projectArea: 1800,
        studentId: 'student-1',
        isTrainingProject: true,
        actionId: 'act-admin-create-assign-1'
      }
    });

    assert.equal(res.status, 201);
    const body = await res.json();
    assert.equal(body.success, true);
    assert.ok(body.id);
    assert.ok(body.assignmentId);

    createdProjectId = body.id;
    createdAssignmentId = body.assignmentId;

    // Verify DB state
    const proj = rawDb.prepare('SELECT * FROM projects WHERE id = ?').get(createdProjectId);
    assert.ok(proj);
    assert.equal(proj.status, 'WAITING_ACCEPTANCE');
    assert.equal(proj.draughtsman_id, 'student-1');
    assert.equal(proj.is_training_project, 1);
    assert.equal(proj.client_id, 'admin-1');
    assert.match(proj.project_address, /Instructions: Draft 2BHK layout/);

    const sa = rawDb.prepare('SELECT * FROM student_assignments WHERE id = ?').get(createdAssignmentId);
    assert.ok(sa);
    assert.equal(sa.student_id, 'student-1');
    assert.equal(sa.project_id, createdProjectId);
    assert.equal(sa.status, 'PENDING');

    const notif = rawDb.prepare("SELECT * FROM notifications WHERE user_id = 'student-1' AND project_id = ?").get(createdProjectId);
    assert.ok(notif);
    assert.equal(notif.type, 'NEW_ASSIGNMENT');

    const act = rawDb.prepare('SELECT * FROM activity_logs WHERE project_id = ? AND action_type = ?').get(createdProjectId, 'STUDENT_ASSIGNED');
    assert.ok(act);
    assert.match(act.details, /assigned practical project/);
  });

  await t.test('Assigned student-1 sees project in /api/student/assignments and can access detail', async () => {
    const listRes = await testRequest(env, '/api/student/assignments', {
      method: 'GET',
      token: 'student-1'
    });
    assert.equal(listRes.status, 200);
    const assignments = await listRes.json();
    const found = assignments.find((a) => a.id === createdProjectId);
    assert.ok(found, 'Created project must appear in assigned student list');
    assert.equal(found.status, 'WAITING_ACCEPTANCE');

    const detailRes = await testRequest(env, `/api/projects/${createdProjectId}`, {
      method: 'GET',
      token: 'student-1'
    });
    assert.equal(detailRes.status, 200);
    const detail = await detailRes.json();
    assert.equal(detail.id, createdProjectId);
    assert.equal(detail.project_name, 'Villa CAD Drafting Practical');
    assert.equal(detail.current_assignment_id, createdAssignmentId);
  });

  await t.test('Different student-2 is FORBIDDEN (403) from accessing the assigned project', async () => {
    const detailRes = await testRequest(env, `/api/projects/${createdProjectId}`, {
      method: 'GET',
      token: 'student-2'
    });
    assert.equal(detailRes.status, 403);
  });

  await t.test('Validation: Rejects missing projectName with 400', async () => {
    const res = await testRequest(env, '/api/admin/projects', {
      method: 'POST',
      token: 'admin-1',
      body: {
        projectName: '',
        drawingType: 'FLOOR_PLAN',
        studentId: 'student-1',
        isTrainingProject: true
      }
    });
    assert.equal(res.status, 400);
    const body = await res.json();
    assert.equal(body.code, 'INVALID_PROJECT_NAME');
  });

  await t.test('Validation: Rejects non-student user ID with 400 INVALID_STUDENT', async () => {
    const res = await testRequest(env, '/api/admin/projects', {
      method: 'POST',
      token: 'admin-1',
      body: {
        projectName: 'Some Assignment',
        drawingType: 'FLOOR_PLAN',
        studentId: 'engineer-1',
        isTrainingProject: true
      }
    });
    assert.equal(res.status, 400);
    const body = await res.json();
    assert.equal(body.code, 'INVALID_STUDENT');
  });

  await t.test('Validation: Rejects suspended student with 403 ACCOUNT_SUSPENDED', async () => {
    const res = await testRequest(env, '/api/admin/projects', {
      method: 'POST',
      token: 'admin-1',
      body: {
        projectName: 'Some Assignment',
        drawingType: 'FLOOR_PLAN',
        studentId: 'student-susp',
        isTrainingProject: true
      }
    });
    assert.equal(res.status, 403);
    const body = await res.json();
    assert.equal(body.code, 'ACCOUNT_SUSPENDED');
  });

  await t.test('Idempotency: Re-submitting with identical actionId returns success without duplicates', async () => {
    const res = await testRequest(env, '/api/admin/projects', {
      method: 'POST',
      token: 'admin-1',
      body: {
        id: createdProjectId,
        projectName: 'Villa CAD Drafting Practical',
        drawingType: 'FLOOR_PLAN',
        studentId: 'student-1',
        isTrainingProject: true,
        actionId: 'act-admin-create-assign-1'
      }
    });
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.idempotent, true);
    assert.equal(body.id, createdProjectId);
  });

  await t.test('Assigned student can accept the assignment via existing workflow', async () => {
    const res = await testRequest(env, '/api/projects/accept', {
      method: 'POST',
      token: 'student-1',
      body: {
        projectId: createdProjectId,
        assignmentId: createdAssignmentId
      }
    });
    assert.equal(res.status, 200);

    const proj = rawDb.prepare('SELECT status FROM projects WHERE id = ?').get(createdProjectId);
    assert.equal(proj.status, 'IN_PROGRESS');

    const sa = rawDb.prepare('SELECT status FROM student_assignments WHERE id = ?').get(createdAssignmentId);
    assert.equal(sa.status, 'ACCEPTED');
  });

  await t.test('Student can accept practical assignment when passing projectId as assignmentId to /api/assignments/accept', async () => {
    // Create project for student-2
    const createRes = await testRequest(env, '/api/admin/projects', {
      method: 'POST',
      token: 'admin-1',
      body: {
        projectName: 'Student 2 Test Project',
        drawingType: 'SECTION',
        studentId: 'student-2',
        isTrainingProject: true,
        actionId: 'act-s2-proj-create'
      }
    });
    assert.equal(createRes.status, 201);
    const createData = await createRes.json();
    const s2ProjectId = createData.id;

    // Call /api/assignments/accept passing ONLY assignmentId set to the project ID (matching Flutter client fallback)
    const acceptRes = await testRequest(env, '/api/assignments/accept', {
      method: 'POST',
      token: 'student-2',
      body: {
        assignmentId: s2ProjectId
      }
    });
    assert.equal(acceptRes.status, 200);

    const s2Proj = rawDb.prepare('SELECT status FROM projects WHERE id = ?').get(s2ProjectId);
    assert.equal(s2Proj.status, 'IN_PROGRESS');

    const s2Sa = rawDb.prepare('SELECT status FROM student_assignments WHERE project_id = ?').get(s2ProjectId);
    assert.equal(s2Sa.status, 'ACCEPTED');
  });

  await t.test('Admin can upload reference files with category=reference to practical project (200)', async () => {
    const fileContent = 'sample reference flowchart png content';
    const res = await testRequest(env, `/api/projects/${createdProjectId}/files?category=reference`, {
      method: 'POST',
      token: 'admin-1',
      headers: {
        'X-Action-Id': 'act-ref-file-up-1',
        'X-File-Name': 'Student-Admin Portal Flowchart.png',
        'Content-Length': String(fileContent.length),
        'Content-Type': 'image/png'
      },
      body: fileContent
    });
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.id, 'act-ref-file-up-1');
    assert.equal(body.category, 'reference');
    assert.equal(body.status, 'COMPLETED');

    // Verify stored in DB
    const dbFile = rawDb.prepare('SELECT * FROM files WHERE id = ?').get('act-ref-file-up-1');
    assert.ok(dbFile);
    assert.equal(dbFile.category, 'reference');
    assert.equal(dbFile.status, 'COMPLETED');
    assert.equal(dbFile.project_id, createdProjectId);
  });

  await t.test('Admin can upload specification files with category=specification to practical project (200)', async () => {
    const fileContent = 'sample specification pdf content';
    const res = await testRequest(env, `/api/projects/${createdProjectId}/files?category=specification`, {
      method: 'POST',
      token: 'admin-1',
      headers: {
        'X-Action-Id': 'act-spec-file-up-1',
        'X-File-Name': 'Architectural_Requirements.pdf',
        'Content-Length': String(fileContent.length),
        'Content-Type': 'application/pdf'
      },
      body: fileContent
    });
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.id, 'act-spec-file-up-1');
    assert.equal(body.category, 'specification');
    assert.equal(body.status, 'COMPLETED');
  });

  await t.test('Assigned student can list and download the uploaded reference file', async () => {
    // List files
    const listRes = await testRequest(env, `/api/projects/${createdProjectId}/files`, {
      method: 'GET',
      token: 'student-1'
    });
    assert.equal(listRes.status, 200);
    const files = await listRes.json();
    const refFile = files.find((f) => f.id === 'act-ref-file-up-1');
    assert.ok(refFile, 'Reference file must be listed in project files');
    assert.equal(refFile.category, 'reference');

    // Download file
    const dlRes = await testRequest(env, `/api/files/act-ref-file-up-1/download`, {
      method: 'GET',
      token: 'student-1'
    });
    assert.equal(dlRes.status, 200);
  });

  await t.test('Non-admin non-owner cannot upload reference files (403)', async () => {
    const fileContent = 'sample data';
    const res = await testRequest(env, `/api/projects/${createdProjectId}/files?category=reference`, {
      method: 'POST',
      token: 'student-2',
      headers: {
        'X-Action-Id': 'act-ref-file-forged',
        'X-File-Name': 'malicious.png',
        'Content-Length': String(fileContent.length),
      },
      body: fileContent
    });
    assert.equal(res.status, 403);
  });

  await t.test('Rejects upload with unapproved category (400)', async () => {
    const fileContent = 'sample data';
    const res = await testRequest(env, `/api/projects/${createdProjectId}/files?category=unauthorized_cat`, {
      method: 'POST',
      token: 'admin-1',
      headers: {
        'X-Action-Id': 'act-ref-file-bad',
        'X-File-Name': 'sample.pdf',
        'Content-Length': String(fileContent.length),
      },
      body: fileContent
    });
    assert.equal(res.status, 400);
    const body = await res.json();
    assert.match(body.error, /Invalid category/);
  });
});

