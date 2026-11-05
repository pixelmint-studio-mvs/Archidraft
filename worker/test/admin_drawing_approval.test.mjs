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

const bundlePath = path.join(workerRoot, 'node_modules', '.test_app_admin_drawing_approval_bundle.mjs');
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
              const info = stmt.run(...args);
              return { success: true, meta: { changes: info.changes }, changes: info.changes };
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
          return { success: true, meta: { changes: info.changes }, changes: info.changes };
        }
      };
    },
    async batch(statements) {
      db.exec('BEGIN TRANSACTION');
      try {
        const results = [];
        for (const s of statements) {
          results.push(await s.run());
        }
        db.exec('COMMIT');
        return results;
      } catch (e) {
        db.exec('ROLLBACK');
        throw e;
      }
    }
  };

  const storageMap = new Map();
  const storage = {
    async get(key) {
      if (!storageMap.has(key)) return null;
      const data = storageMap.get(key);
      return {
        httpEtag: '"mock-etag"',
        writeHttpMetadata(headers) {
          headers.set('content-type', data.contentType || 'application/octet-stream');
        },
        body: data.buffer,
      };
    },
    async put(key, stream, options) {
      if (stream && typeof stream.getReader === 'function') {
        const reader = stream.getReader();
        while (!(await reader.read()).done) {}
      }
      storageMap.set(key, {
        buffer: Buffer.from('mock-file-content'),
        contentType: options?.httpMetadata?.contentType
      });
      return { size: 2048 };
    }
  };

  const env = {
    DB: d1,
    STORAGE: storage,
    ENVIRONMENT: 'development',
    ALLOWED_ORIGINS: 'http://localhost:3000,http://localhost:8787'
  };

  return { rawDb: db, env, storageMap };
}

function seedBaselineData(rawDb) {
  // Users
  rawDb.exec(`
    INSERT INTO users (id, email, name, role, status) VALUES 
      ('eng-1', 'engineer@example.com', 'Alice Engineer', 'ENGINEER', 'ACTIVE'),
      ('drg-1', 'draughtsman@example.com', 'Bob Draughtsman', 'DRAUGHTSMAN', 'ACTIVE'),
      ('drg-2', 'draughtsman2@example.com', 'Dave Draughtsman', 'DRAUGHTSMAN', 'ACTIVE'),
      ('adm-1', 'admin@example.com', 'Sarah Admin', 'STUDIO_ADMIN', 'ACTIVE'),
      ('stu-1', 'student@example.com', 'Sam Student', 'STUDENT', 'ACTIVE');
  `);

  // Legal consent seeding
  rawDb.prepare(`
    INSERT INTO legal_documents (id, document_type, version, title, content, effective_at, status, is_mandatory, locale)
    VALUES ('doc-terms-ada', 'TERMS_AND_CONDITIONS', '1.0.0', 'Platform Terms', '# Terms', CURRENT_TIMESTAMP, 'EFFECTIVE', 1, 'en-IN')
  `).run();

  const insertEvent = rawDb.prepare(`
    INSERT INTO legal_consent_events (id, user_id, document_id, document_type, document_version, action_type, consent_purpose, idempotency_key, ip_hash, source)
    VALUES (?, ?, 'doc-terms-ada', 'TERMS_AND_CONDITIONS', '1.0.0', 'ACCEPT', 'DEFAULT', ?, 'hash-ip', 'WEB_APP')
  `);

  const insertConsent = rawDb.prepare(`
    INSERT INTO user_consent_state (id, user_id, consent_type, purpose_tag, current_status, accepted_version, last_event_id, updated_at)
    VALUES (?, ?, 'TERMS', 'DEFAULT', 'ACCEPTED', '1.0.0', ?, CURRENT_TIMESTAMP)
  `);

  for (const uid of ['eng-1', 'drg-1', 'drg-2', 'adm-1', 'stu-1']) {
    const eventId = 'evt-terms-' + uid;
    insertEvent.run(eventId, uid, 'idem-' + uid);
    insertConsent.run('cst-' + uid, uid, eventId);
  }

  // Commercial Project
  rawDb.exec(`
    INSERT INTO projects (id, client_id, draughtsman_id, project_name, project_address, drawing_name, drawing_type, project_area, status, correction_round, is_training_project)
    VALUES ('prj-comm-1', 'eng-1', 'drg-1', 'Skyline Tower', '100 Main St', 'Floor Plan L1', 'Architectural', '1000 sqft', 'IN_PROGRESS', 0, 0);

    INSERT INTO assignments (id, project_id, draughtsman_id, status)
    VALUES ('asg-1', 'prj-comm-1', 'drg-1', 'ACCEPTED');
  `);

  // Student Training Project
  rawDb.exec(`
    INSERT INTO training_modules (id, title, category, type, level, publication_status)
    VALUES ('mod-1', 'Basic CAD Drafting', 'CAD', 'DRAWING', 'BEGINNER', 'PUBLISHED');

    INSERT INTO projects (id, client_id, draughtsman_id, project_name, project_address, drawing_name, drawing_type, project_area, status, correction_round, is_training_project, training_module_id)
    VALUES ('prj-train-1', 'adm-1', 'stu-1', 'Practical Exercise 1', 'Virtual Lab', 'Standard Wall Detail', 'Architectural', '500 sqft', 'IN_PROGRESS', 0, 1, 'mod-1');

    INSERT INTO student_assignments (id, project_id, student_id, assignment_type, status)
    VALUES ('sa-1', 'prj-train-1', 'stu-1', 'PRACTICAL', 'ACCEPTED');
  `);
}

async function testRequest(env, path, options = {}) {
  const headers = { ...options.headers };
  if (options.token !== null && !headers['Authorization'] && !headers['authorization']) {
    headers['Authorization'] = `Bearer mock-token:${options.token || 'drg-1'}`;
  }
  const body = (options.body && typeof options.body === 'object' && !(options.body instanceof Uint8Array))
    ? JSON.stringify(options.body)
    : options.body;
  if (body && !headers['Content-Type']) {
    headers['Content-Type'] = 'application/json';
  }

  return app.request(path, {
    method: options.method || 'GET',
    headers,
    body,
  }, env);
}

// =========================================================================
// SUITE 1: End-to-End Workflow & Core Invariants
// =========================================================================

test('Admin-Mediated Drawing Approval Workflow — End-to-End Suite', async (t) => {
  const { rawDb, env, storageMap } = createIsolatedTestDb();
  seedBaselineData(rawDb);

  // Setup initial draft file for Draughtsman
  rawDb.exec(`
    INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
    VALUES 
      ('file-draft-1', 'prj-comm-1', 'drg-1', 'floor_plan_v1.dwg', 'floor_plan_v1.dwg', 'projects/prj-comm-1/workspace_draft/floor_plan_v1.dwg', 'application/acad', 2048, 'workspace_draft', 'COMPLETED');
  `);
  storageMap.set('projects/prj-comm-1/workspace_draft/floor_plan_v1.dwg', {
    buffer: Buffer.from('dwg-v1-data'),
    contentType: 'application/acad'
  });

  let v1Id;

  await t.test('1. Initial submission enters Admin review (UNDER_ADMIN_REVIEW)', async () => {
    const res = await testRequest(env, '/api/projects/submit-drawing', {
      method: 'POST',
      token: 'drg-1',
      body: {
        projectId: 'prj-comm-1',
        actionId: 'act-submit-v1',
        draftFileId: 'file-draft-1'
      }
    });
    assert.equal(res.status, 200);

    const project = rawDb.prepare('SELECT status FROM projects WHERE id = ?').get('prj-comm-1');
    assert.equal(project.status, 'UNDER_ADMIN_REVIEW', 'Commercial project must enter UNDER_ADMIN_REVIEW');

    const version = rawDb.prepare('SELECT * FROM drawing_versions WHERE project_id = ?').get('prj-comm-1');
    assert.ok(version);
    assert.equal(version.version_number, 1);
    assert.equal(version.approval_status, 'PENDING', 'New deliverable must be marked PENDING approval');
    v1Id = version.id;

    // Check notification sent to Admin
    const adminNotif = rawDb.prepare("SELECT * FROM notifications WHERE user_id = 'adm-1' AND type = 'DRAWING_SUBMITTED_FOR_ADMIN'").get();
    assert.ok(adminNotif, 'Studio Admin must receive DRAWING_SUBMITTED_FOR_ADMIN notification');

    // Check NO notification sent to Engineer
    const engNotif = rawDb.prepare("SELECT * FROM notifications WHERE user_id = 'eng-1'").get();
    assert.equal(engNotif, undefined, 'Engineer must NOT be notified before Admin approval');
  });

  await t.test('2. Pending drawing is inaccessible to Engineer in queries', async () => {
    // Engineer queries drawing_versions
    const versionsRes = await testRequest(env, '/api/projects/prj-comm-1/drawing_versions', {
      token: 'eng-1'
    });
    assert.equal(versionsRes.status, 200);
    const versions = await versionsRes.json();
    assert.equal(versions.length, 0, 'Engineer query must completely omit pending drawing versions');

    // Admin queries drawing_versions: sees pending version
    const adminVersionsRes = await testRequest(env, '/api/projects/prj-comm-1/drawing_versions', {
      token: 'adm-1'
    });
    const adminVersions = await adminVersionsRes.json();
    assert.equal(adminVersions.length, 1);
    assert.equal(adminVersions[0].approval_status, 'PENDING');

    // Engineer queries files list: excludes unapproved deliverables and drafts
    const filesRes = await testRequest(env, '/api/projects/prj-comm-1/files', {
      token: 'eng-1'
    });
    const files = await filesRes.json();
    assert.equal(files.length, 0, 'Engineer files list must exclude unapproved deliverables');
  });

  await t.test('3. Direct download of unapproved deliverables is blocked (403 DELIVERABLE_UNAPPROVED)', async () => {
    rawDb.exec(`UPDATE files SET category = 'draughtsman_version' WHERE id = 'file-draft-1'`);

    const res = await testRequest(env, '/api/files/file-draft-1/download', {
      token: 'eng-1'
    });
    assert.equal(res.status, 403);
    const body = await res.json();
    assert.equal(body.code, 'DELIVERABLE_UNAPPROVED');
  });

  await t.test('4. Workspace drafts are inaccessible to Engineer (403 DRAFT_ACCESS_DENIED)', async () => {
    rawDb.exec(`
      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES ('file-draft-wip', 'prj-comm-1', 'drg-1', 'wip.dwg', 'wip.dwg', 'projects/prj-comm-1/workspace_draft/wip.dwg', 'application/acad', 1024, 'workspace_draft', 'COMPLETED');
    `);
    storageMap.set('projects/prj-comm-1/workspace_draft/wip.dwg', {
      buffer: Buffer.from('wip-data'),
      contentType: 'application/acad'
    });

    const res = await testRequest(env, '/api/files/file-draft-wip/download', {
      token: 'eng-1'
    });
    assert.equal(res.status, 403);
    const body = await res.json();
    assert.equal(body.code, 'DRAFT_ACCESS_DENIED');
  });

  await t.test('5. Unauthorized users cannot approve or reject drawing', async () => {
    // Engineer attempt to approve
    const engApprove = await testRequest(env, '/api/projects/admin-approve-drawing', {
      method: 'POST',
      token: 'eng-1',
      body: { projectId: 'prj-comm-1', drawingVersionId: v1Id }
    });
    assert.equal(engApprove.status, 403);

    // Draughtsman attempt to approve
    const drgApprove = await testRequest(env, '/api/projects/admin-approve-drawing', {
      method: 'POST',
      token: 'drg-1',
      body: { projectId: 'prj-comm-1', drawingVersionId: v1Id }
    });
    assert.equal(drgApprove.status, 403);

    // Engineer attempt to request revision via admin endpoint
    const engRev = await testRequest(env, '/api/projects/admin-request-revision', {
      method: 'POST',
      token: 'eng-1',
      body: { projectId: 'prj-comm-1', drawingVersionId: v1Id, feedback: 'Fix walls' }
    });
    assert.equal(engRev.status, 403);
  });

  await t.test('6. Admin rejection requests Draughtsman revision without incrementing correction rounds', async () => {
    const res = await testRequest(env, '/api/projects/admin-request-revision', {
      method: 'POST',
      token: 'adm-1',
      body: {
        projectId: 'prj-comm-1',
        drawingVersionId: v1Id,
        actionId: 'act-qc-reject-1',
        feedback: 'Linework violates CAD Layer Standard 2.1; grid line 3 is missing.'
      }
    });
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.approvalStatus, 'REJECTED');
    assert.equal(body.projectStatus, 'IN_PROGRESS');

    // Verify drawing version updated
    const v1 = rawDb.prepare('SELECT * FROM drawing_versions WHERE id = ?').get(v1Id);
    assert.equal(v1.approval_status, 'REJECTED');
    assert.equal(v1.reviewed_by, 'adm-1');
    assert.ok(v1.reviewed_at);
    assert.ok(v1.review_feedback.includes('Layer Standard'));

    // Invariant: projects.correction_round is NEVER incremented by Admin QC rework!
    const project = rawDb.prepare('SELECT status, correction_round FROM projects WHERE id = ?').get('prj-comm-1');
    assert.equal(project.status, 'IN_PROGRESS');
    assert.equal(project.correction_round, 0, 'Admin QC rework must NEVER increment correction_round');

    // Verify audit record in drawing_version_reviews
    const review = rawDb.prepare('SELECT * FROM drawing_version_reviews WHERE drawing_version_id = ?').get(v1Id);
    assert.ok(review);
    assert.equal(review.decision, 'REJECTED');
    assert.equal(review.reviewer_id, 'adm-1');

    // Draughtsman receives rework notification
    const drgNotif = rawDb.prepare("SELECT * FROM notifications WHERE user_id = 'drg-1' AND type = 'ADMIN_REVISION_REQUESTED'").get();
    assert.ok(drgNotif, 'Draughtsman must receive internal rework notification');

    // Engineer receives zero notification
    const engNotifs = rawDb.prepare("SELECT * FROM notifications WHERE user_id = 'eng-1'").all();
    assert.equal(engNotifs.length, 0, 'Engineer must remain completely unaware of internal rework');
  });

  let v2Id;
  await t.test('7. Draughtsman resubmits corrected draft -> creates v2 and enters UNDER_ADMIN_REVIEW', async () => {
    rawDb.exec(`
      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES ('file-draft-2', 'prj-comm-1', 'drg-1', 'floor_plan_v2.dwg', 'floor_plan_v2.dwg', 'projects/prj-comm-1/workspace_draft/floor_plan_v2.dwg', 'application/acad', 2048, 'workspace_draft', 'COMPLETED');
    `);
    storageMap.set('projects/prj-comm-1/workspace_draft/floor_plan_v2.dwg', {
      buffer: Buffer.from('dwg-v2-data'),
      contentType: 'application/acad'
    });

    const res = await testRequest(env, '/api/projects/submit-drawing', {
      method: 'POST',
      token: 'drg-1',
      body: {
        projectId: 'prj-comm-1',
        actionId: 'act-submit-v2',
        draftFileId: 'file-draft-2'
      }
    });
    assert.equal(res.status, 200);

    const project = rawDb.prepare('SELECT status, correction_round FROM projects WHERE id = ?').get('prj-comm-1');
    assert.equal(project.status, 'UNDER_ADMIN_REVIEW');
    assert.equal(project.correction_round, 0);

    const v2 = rawDb.prepare('SELECT * FROM drawing_versions WHERE version_number = 2').get();
    assert.ok(v2);
    assert.equal(v2.approval_status, 'PENDING');
    v2Id = v2.id;
  });

  await t.test('8. Admin can approve pending version -> releases to Engineer (UNDER_ENGINEER_REVIEW)', async () => {
    rawDb.exec(`UPDATE files SET category = 'draughtsman_version' WHERE id = 'file-draft-2'`);

    const res = await testRequest(env, '/api/projects/admin-approve-drawing', {
      method: 'POST',
      token: 'adm-1',
      body: {
        projectId: 'prj-comm-1',
        drawingVersionId: v2Id,
        actionId: 'act-admin-appr-v2',
        feedback: 'Linework standards verified. Deliverable released to client.'
      }
    });
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.approvalStatus, 'APPROVED');
    assert.equal(body.projectStatus, 'UNDER_ENGINEER_REVIEW');

    const v2 = rawDb.prepare('SELECT * FROM drawing_versions WHERE id = ?').get(v2Id);
    assert.equal(v2.approval_status, 'APPROVED');

    const project = rawDb.prepare('SELECT status FROM projects WHERE id = ?').get('prj-comm-1');
    assert.equal(project.status, 'UNDER_ENGINEER_REVIEW');

    // Engineer receives DRAWING_READY_FOR_REVIEW notification
    const engNotif = rawDb.prepare("SELECT * FROM notifications WHERE user_id = 'eng-1' AND type = 'DRAWING_READY_FOR_REVIEW'").get();
    assert.ok(engNotif);

    // Engineer queries drawing_versions: sees v2 without internal feedback
    const engVersionsRes = await testRequest(env, '/api/projects/prj-comm-1/drawing_versions', {
      token: 'eng-1'
    });
    const engVersions = await engVersionsRes.json();
    assert.equal(engVersions.length, 1);
    assert.equal(engVersions[0].version_number, 2);
    assert.equal(engVersions[0].approval_status, 'APPROVED');
    assert.equal(engVersions[0].review_feedback, undefined, 'Internal review_feedback must be redacted from Engineer');

    // Engineer can now download v2 deliverable
    const downloadRes = await testRequest(env, '/api/files/file-draft-2/download', {
      token: 'eng-1'
    });
    assert.equal(downloadRes.status, 200);
  });

  await t.test('9. Engineer requests client revision (Round 1) -> opens correction and enters IN_PROGRESS', async () => {
    const res = await testRequest(env, '/api/projects/request-correction', {
      method: 'POST',
      token: 'eng-1',
      body: {
        projectId: 'prj-comm-1',
        correctionId: 'corr-round-1',
        targetVersionId: v2Id,
        description: 'Client requests doorway shifted 500mm east.',
        actionId: 'act-eng-corr-1'
      }
    });
    assert.equal(res.status, 200);

    const project = rawDb.prepare('SELECT status, correction_round FROM projects WHERE id = ?').get('prj-comm-1');
    assert.equal(project.status, 'IN_PROGRESS');
    assert.equal(project.correction_round, 1);

    const corr = rawDb.prepare('SELECT * FROM corrections WHERE id = ?').get('corr-round-1');
    assert.equal(corr.status, 'OPEN');
    assert.equal(corr.round_number, 1);
  });

  let v3Id;
  await t.test('10. Draughtsman resubmits corrected drawing -> correction transitions to IN_REVIEW', async () => {
    rawDb.exec(`
      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES ('file-draft-3', 'prj-comm-1', 'drg-1', 'floor_plan_v3.dwg', 'floor_plan_v3.dwg', 'projects/prj-comm-1/workspace_draft/floor_plan_v3.dwg', 'application/acad', 2048, 'workspace_draft', 'COMPLETED');
    `);
    storageMap.set('projects/prj-comm-1/workspace_draft/floor_plan_v3.dwg', {
      buffer: Buffer.from('dwg-v3-data'),
      contentType: 'application/acad'
    });

    const res = await testRequest(env, '/api/projects/submit-drawing', {
      method: 'POST',
      token: 'drg-1',
      body: {
        projectId: 'prj-comm-1',
        actionId: 'act-submit-v3',
        draftFileId: 'file-draft-3'
      }
    });
    assert.equal(res.status, 200);

    const project = rawDb.prepare('SELECT status, correction_round FROM projects WHERE id = ?').get('prj-comm-1');
    assert.equal(project.status, 'UNDER_ADMIN_REVIEW');

    // Invariant: Correction transitions to IN_REVIEW (NOT RESOLVED!)
    const corr = rawDb.prepare('SELECT * FROM corrections WHERE id = ?').get('corr-round-1');
    assert.equal(corr.status, 'IN_REVIEW', 'Correction must transition to IN_REVIEW on submission');

    const v3 = rawDb.prepare('SELECT * FROM drawing_versions WHERE version_number = 3').get();
    assert.ok(v3);
    assert.equal(v3.approval_status, 'PENDING');
    v3Id = v3.id;
  });

  await t.test('11. Historical approved version (v2) remains accessible while v3 is pending review', async () => {
    // Engineer queries drawing_versions: v2 is returned, v3 is NOT returned
    const res = await testRequest(env, '/api/projects/prj-comm-1/drawing_versions', {
      token: 'eng-1'
    });
    const versions = await res.json();
    assert.equal(versions.length, 1);
    assert.equal(versions[0].version_number, 2, 'Historical approved v2 must remain visible');

    // Engineer can download v2
    const v2Download = await testRequest(env, '/api/files/file-draft-2/download', {
      token: 'eng-1'
    });
    assert.equal(v2Download.status, 200, 'Historical approved v2 deliverable must remain downloadable');

    // Engineer cannot download pending v3
    rawDb.exec(`UPDATE files SET category = 'draughtsman_version' WHERE id = 'file-draft-3'`);
    const v3Download = await testRequest(env, '/api/files/file-draft-3/download', {
      token: 'eng-1'
    });
    assert.equal(v3Download.status, 403, 'Pending v3 deliverable must be blocked from download');
    const v3Body = await v3Download.json();
    assert.equal(v3Body.code, 'DELIVERABLE_UNAPPROVED');
  });

  await t.test('12. Correction remains IN_REVIEW through Admin approval', async () => {
    const res = await testRequest(env, '/api/projects/admin-approve-drawing', {
      method: 'POST',
      token: 'adm-1',
      body: {
        projectId: 'prj-comm-1',
        drawingVersionId: v3Id,
        actionId: 'act-admin-appr-v3',
        feedback: 'Doorway repositioning conforms to redline markup.'
      }
    });
    assert.equal(res.status, 200);

    const project = rawDb.prepare('SELECT status FROM projects WHERE id = ?').get('prj-comm-1');
    assert.equal(project.status, 'UNDER_ENGINEER_REVIEW');

    // Invariant: Correction REMAINS in IN_REVIEW while Engineer inspects
    const corr = rawDb.prepare('SELECT * FROM corrections WHERE id = ?').get('corr-round-1');
    assert.equal(corr.status, 'IN_REVIEW', 'Correction must remain IN_REVIEW after Admin approval');
  });

  await t.test('13. Correction resolves only after Engineer acceptance (approve-final)', async () => {
    const res = await testRequest(env, '/api/projects/approve-final', {
      method: 'POST',
      token: 'eng-1',
      body: {
        projectId: 'prj-comm-1',
        drawingVersionId: v3Id,
        actionId: 'act-eng-final-appr'
      }
    });
    assert.equal(res.status, 200);

    const project = rawDb.prepare('SELECT status FROM projects WHERE id = ?').get('prj-comm-1');
    assert.equal(project.status, 'COMPLETED');

    // Invariant: Correction transitions to RESOLVED only upon final Engineer approval
    const corr = rawDb.prepare('SELECT * FROM corrections WHERE id = ?').get('corr-round-1');
    assert.equal(corr.status, 'RESOLVED');
    assert.ok(corr.resolved_at);
  });

  await t.test('14. Review history access policy: Admins & Draughtsmen allowed; Engineers blocked', async () => {
    // Admin query sees full review history
    const res = await testRequest(env, '/api/projects/prj-comm-1/drawing_version_reviews', {
      token: 'adm-1'
    });
    assert.equal(res.status, 200);
    const reviews = await res.json();
    assert.equal(reviews.length, 3, 'Must have recorded 3 review events');

    // Assigned Draughtsman can access review feedback to address redlines
    const drgRes = await testRequest(env, '/api/projects/prj-comm-1/drawing_version_reviews', {
      token: 'drg-1'
    });
    assert.equal(drgRes.status, 200, 'Assigned draughtsman must be allowed access to review history');
    const drgReviews = await drgRes.json();
    assert.equal(drgReviews.length, 3);
    assert.ok(drgReviews[0].feedback.includes('Layer Standard'));

    // Engineer query must be strictly BLOCKED (403) from internal Studio review history
    const engRes = await testRequest(env, '/api/projects/prj-comm-1/drawing_version_reviews', {
      token: 'eng-1'
    });
    assert.equal(engRes.status, 403, 'Engineer must be forbidden from internal studio review history');
    const engBody = await engRes.json();
    assert.equal(engBody.code, 'FORBIDDEN');
  });

  await t.test('15. Duplicate or stale review requests are rejected safely', async () => {
    // Attempt to re-approve already approved version
    const reApprove = await testRequest(env, '/api/projects/admin-approve-drawing', {
      method: 'POST',
      token: 'adm-1',
      body: { projectId: 'prj-comm-1', drawingVersionId: v3Id }
    });
    assert.equal(reApprove.status, 400);

    // Attempt to reject already approved version
    const reReject = await testRequest(env, '/api/projects/admin-request-revision', {
      method: 'POST',
      token: 'adm-1',
      body: { projectId: 'prj-comm-1', drawingVersionId: v3Id, feedback: 'Cannot reject now' }
    });
    assert.equal(reReject.status, 400);

    // Attempt to review with missing feedback
    const noFeedback = await testRequest(env, '/api/projects/admin-request-revision', {
      method: 'POST',
      token: 'adm-1',
      body: { projectId: 'prj-comm-1', drawingVersionId: 'nonexistent-id', feedback: '' }
    });
    assert.equal(noFeedback.status, 400);
  });

  await t.test('16. Student/teaching submission workflow remains isolated', async () => {
    rawDb.exec(`
      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES ('file-stu-dwg', 'prj-train-1', 'stu-1', 'task1.dwg', 'task1.dwg', 'projects/prj-train-1/workspace_draft/task1.dwg', 'application/acad', 1024, 'workspace_draft', 'COMPLETED');
    `);

    // Student submits drawing
    const stuSubmit = await testRequest(env, '/api/projects/submit-drawing', {
      method: 'POST',
      token: 'stu-1',
      body: {
        projectId: 'prj-train-1',
        actionId: 'act-stu-submit-1',
        draftFileId: 'file-stu-dwg'
      }
    });
    assert.equal(stuSubmit.status, 200);

    // Student project enters UNDER_ENGINEER_REVIEW (student evaluation rubric queue), NOT commercial UNDER_ADMIN_REVIEW
    const trainProject = rawDb.prepare('SELECT status FROM projects WHERE id = ?').get('prj-train-1');
    assert.equal(trainProject.status, 'UNDER_ENGINEER_REVIEW');

    // Commercial Admin Drawing Approval endpoint rejects training project
    const adminAppr = await testRequest(env, '/api/projects/admin-approve-drawing', {
      method: 'POST',
      token: 'adm-1',
      body: {
        projectId: 'prj-train-1',
        drawingVersionId: 'some-id',
        actionId: 'act-fail'
      }
    });
    assert.equal(adminAppr.status, 400);
    const body = await adminAppr.json();
    assert.equal(body.code, 'TRAINING_PROJECT_NOT_SUPPORTED');
  });
});

// =========================================================================
// SUITE 2: Phase 1.2 Security Remediation — 12 Explicit Regression Tests
// =========================================================================

test('Phase 1.2 Security Remediation — Explicit Regression Test Suite', async (t) => {
  const { rawDb, env, storageMap } = createIsolatedTestDb();
  seedBaselineData(rawDb);

  // Setup auxiliary project for remediation tests
  rawDb.exec(`
    INSERT INTO projects (id, client_id, draughtsman_id, project_name, project_address, drawing_name, drawing_type, project_area, status, correction_round, is_training_project)
    VALUES ('prj-sec-1', 'eng-1', 'drg-1', 'Security Tower', '200 Sec Way', 'Sec Plan', 'Architectural', '2000 sqft', 'IN_PROGRESS', 0, 0);

    INSERT INTO assignments (id, project_id, draughtsman_id, status)
    VALUES ('asg-sec-1', 'prj-sec-1', 'drg-1', 'ACCEPTED');
  `);

  await t.test('Scenario 1: Engineer-owned file linked to a PENDING drawing version is blocked (403)', async () => {
    // Engineer uploaded a file
    rawDb.exec(`
      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES ('file-eng-pending', 'prj-sec-1', 'eng-1', 'site_sketch.dwg', 'site_sketch.dwg', 'projects/prj-sec-1/client_upload/site_sketch.dwg', 'application/acad', 1024, 'client_upload', 'COMPLETED');

      INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by, approval_status)
      VALUES ('dv-pending-eng', 'prj-sec-1', 'file-eng-pending', 1, 'drg-1', 'PENDING');
    `);
    storageMap.set('projects/prj-sec-1/client_upload/site_sketch.dwg', {
      buffer: Buffer.from('data-pending'),
      contentType: 'application/acad'
    });

    const res = await testRequest(env, '/api/files/file-eng-pending/download', { token: 'eng-1' });
    assert.equal(res.status, 403, 'Engineer must be blocked from downloading pending deliverable even if engineer uploaded file');
    const body = await res.json();
    assert.equal(body.code, 'DELIVERABLE_UNAPPROVED');
  });

  await t.test('Scenario 2: Engineer-owned file linked to a REJECTED drawing version is blocked (403)', async () => {
    rawDb.exec(`
      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES ('file-eng-rejected', 'prj-sec-1', 'eng-1', 'old_sketch.dwg', 'old_sketch.dwg', 'projects/prj-sec-1/client_upload/old_sketch.dwg', 'application/acad', 1024, 'client_upload', 'COMPLETED');

      INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by, approval_status)
      VALUES ('dv-rejected-eng', 'prj-sec-1', 'file-eng-rejected', 2, 'drg-1', 'REJECTED');
    `);
    storageMap.set('projects/prj-sec-1/client_upload/old_sketch.dwg', {
      buffer: Buffer.from('data-rejected'),
      contentType: 'application/acad'
    });

    const res = await testRequest(env, '/api/files/file-eng-rejected/download', { token: 'eng-1' });
    assert.equal(res.status, 403);
    const body = await res.json();
    assert.equal(body.code, 'DELIVERABLE_UNAPPROVED');
  });

  await t.test('Scenario 3: Engineer-owned ordinary reference file is accessible (200)', async () => {
    rawDb.exec(`
      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES ('file-eng-ref', 'prj-sec-1', 'eng-1', 'brief_spec.pdf', 'brief_spec.pdf', 'projects/prj-sec-1/reference/brief_spec.pdf', 'application/pdf', 1024, 'reference', 'COMPLETED');
    `);
    storageMap.set('projects/prj-sec-1/reference/brief_spec.pdf', {
      buffer: Buffer.from('data-pdf-spec'),
      contentType: 'application/pdf'
    });

    const res = await testRequest(env, '/api/files/file-eng-ref/download', { token: 'eng-1' });
    assert.equal(res.status, 200, 'Engineer must be allowed to download own reference file');
  });

  await t.test('Scenario 4: Admin-uploaded internal attachment is inaccessible to Engineer (403)', async () => {
    rawDb.exec(`
      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES ('file-adm-qc', 'prj-sec-1', 'adm-1', 'internal_qc.pdf', 'internal_qc.pdf', 'projects/prj-sec-1/admin_internal/internal_qc.pdf', 'application/pdf', 512, 'admin_internal', 'COMPLETED');
    `);
    storageMap.set('projects/prj-sec-1/admin_internal/internal_qc.pdf', {
      buffer: Buffer.from('internal-qc-data'),
      contentType: 'application/pdf'
    });

    // 1. Direct download blocked
    const res = await testRequest(env, '/api/files/file-adm-qc/download', { token: 'eng-1' });
    assert.equal(res.status, 403);
    const body = await res.json();
    assert.equal(body.code, 'INTERNAL_FILE_ACCESS_DENIED');

    // 2. File list query excludes internal attachment
    const listRes = await testRequest(env, '/api/projects/prj-sec-1/files', { token: 'eng-1' });
    assert.equal(listRes.status, 200);
    const list = await listRes.json();
    assert.equal(list.some(f => f.id === 'file-adm-qc'), false, 'Internal file must be omitted from files query');

    // 3. Draughtsman also blocked from raw admin_internal attachments
    const drgRes = await testRequest(env, '/api/files/file-adm-qc/download', { token: 'drg-1' });
    assert.equal(drgRes.status, 403);
    const drgBody = await drgRes.json();
    assert.equal(drgBody.code, 'INTERNAL_FILE_ACCESS_DENIED');
  });

  await t.test('Scenario 5: Draughtsman-uploaded project chat attachment is accessible to Engineer (200)', async () => {
    rawDb.exec(`
      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES ('file-drg-chat', 'prj-sec-1', 'drg-1', 'site_photo.jpg', 'site_photo.jpg', 'projects/prj-sec-1/chat_attachment/site_photo.jpg', 'image/jpeg', 2048, 'chat_attachment', 'COMPLETED');
    `);
    storageMap.set('projects/prj-sec-1/chat_attachment/site_photo.jpg', {
      buffer: Buffer.from('jpg-data'),
      contentType: 'image/jpeg'
    });

    const res = await testRequest(env, '/api/files/file-drg-chat/download', { token: 'eng-1' });
    assert.equal(res.status, 200, 'Legitimate chat attachment must be accessible to project client');
  });

  await t.test('Scenario 6: Approved drawing download succeeds (200)', async () => {
    rawDb.exec(`
      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES ('file-deliv-appr', 'prj-sec-1', 'drg-1', 'appr_plan.dwg', 'appr_plan.dwg', 'projects/prj-sec-1/draughtsman_version/appr_plan.dwg', 'application/acad', 4096, 'draughtsman_version', 'COMPLETED');

      INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by, approval_status)
      VALUES ('dv-approved-deliv', 'prj-sec-1', 'file-deliv-appr', 3, 'drg-1', 'APPROVED');
    `);
    storageMap.set('projects/prj-sec-1/draughtsman_version/appr_plan.dwg', {
      buffer: Buffer.from('dwg-approved-data'),
      contentType: 'application/acad'
    });

    const res = await testRequest(env, '/api/files/file-deliv-appr/download', { token: 'eng-1' });
    assert.equal(res.status, 200);
  });

  await t.test('Scenario 7: Pending drawing download is blocked (403)', async () => {
    rawDb.exec(`
      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES ('file-deliv-pending', 'prj-sec-1', 'drg-1', 'pend_plan.dwg', 'pend_plan.dwg', 'projects/prj-sec-1/draughtsman_version/pend_plan.dwg', 'application/acad', 4096, 'draughtsman_version', 'COMPLETED');

      INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by, approval_status)
      VALUES ('dv-pending-deliv', 'prj-sec-1', 'file-deliv-pending', 4, 'drg-1', 'PENDING');
    `);
    storageMap.set('projects/prj-sec-1/draughtsman_version/pend_plan.dwg', {
      buffer: Buffer.from('dwg-pending-data'),
      contentType: 'application/acad'
    });

    const res = await testRequest(env, '/api/files/file-deliv-pending/download', { token: 'eng-1' });
    assert.equal(res.status, 403);
    const body = await res.json();
    assert.equal(body.code, 'DELIVERABLE_UNAPPROVED');
  });

  await t.test('Scenario 8: Previous approved drawing remains accessible while newer version is pending', async () => {
    // dv-approved-deliv (v3) is APPROVED
    // dv-pending-deliv (v4) is PENDING
    const v3Res = await testRequest(env, '/api/files/file-deliv-appr/download', { token: 'eng-1' });
    assert.equal(v3Res.status, 200, 'Previous approved v3 deliverable must remain downloadable');

    const v4Res = await testRequest(env, '/api/files/file-deliv-pending/download', { token: 'eng-1' });
    assert.equal(v4Res.status, 403, 'Pending v4 deliverable must be blocked');

    const listRes = await testRequest(env, '/api/projects/prj-sec-1/drawing_versions', { token: 'eng-1' });
    const versions = await listRes.json();
    assert.equal(versions.length, 1, 'Only approved versions should be listed');
    assert.equal(versions[0].id, 'dv-approved-deliv');
  });

  await t.test('Scenario 9: Historical completed project with multiple versions resolves safely', async () => {
    rawDb.exec(`
      INSERT INTO projects (id, client_id, draughtsman_id, project_name, project_address, drawing_name, drawing_type, project_area, status, correction_round, is_training_project)
      VALUES ('prj-hist-comp', 'eng-1', 'drg-1', 'Historical Villa', '300 Past Ave', 'Final Plan', 'Architectural', '3000 sqft', 'COMPLETED', 2, 0);

      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES 
        ('f-h-v1', 'prj-hist-comp', 'drg-1', 'v1.dwg', 'v1.dwg', 'projects/prj-hist-comp/v1.dwg', 'application/acad', 1024, 'draughtsman_version', 'COMPLETED'),
        ('f-h-v2', 'prj-hist-comp', 'drg-1', 'v2.dwg', 'v2.dwg', 'projects/prj-hist-comp/v2.dwg', 'application/acad', 1024, 'draughtsman_version', 'COMPLETED'),
        ('f-h-v3', 'prj-hist-comp', 'drg-1', 'v3.dwg', 'v3.dwg', 'projects/prj-hist-comp/v3.dwg', 'application/acad', 1024, 'draughtsman_version', 'COMPLETED');

      INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by, approval_status)
      VALUES 
        ('dv-h-1', 'prj-hist-comp', 'f-h-v1', 1, 'drg-1', 'REJECTED'),
        ('dv-h-2', 'prj-hist-comp', 'f-h-v2', 2, 'drg-1', 'REJECTED'),
        ('dv-h-3', 'prj-hist-comp', 'f-h-v3', 3, 'drg-1', 'APPROVED');
    `);
    storageMap.set('projects/prj-hist-comp/v3.dwg', { buffer: Buffer.from('v3'), contentType: 'application/acad' });

    // Approved terminal version is downloadable
    const res = await testRequest(env, '/api/files/f-h-v3/download', { token: 'eng-1' });
    assert.equal(res.status, 200);

    // Approve final on already completed project is idempotent
    const compRes = await testRequest(env, '/api/projects/approve-final', {
      method: 'POST',
      token: 'eng-1',
      body: { projectId: 'prj-hist-comp', actionId: 'act-hist-comp-repeat' }
    });
    assert.equal(compRes.status, 400); // cannot re-complete if not in review state
  });

  await t.test('Scenario 10: Correction lifecycle across multiple rounds isolates states correctly', async () => {
    // Setup fresh project in review
    rawDb.exec(`
      INSERT INTO projects (id, client_id, draughtsman_id, project_name, project_address, drawing_name, drawing_type, project_area, status, correction_round, is_training_project)
      VALUES ('prj-lifecycle-1', 'eng-1', 'drg-1', 'Multi Round Project', '400 Cycle Rd', 'Cycle Plan', 'Architectural', '2000 sqft', 'UNDER_ENGINEER_REVIEW', 0, 0);

      INSERT INTO assignments (id, project_id, draughtsman_id, status)
      VALUES ('asg-lc-1', 'prj-lifecycle-1', 'drg-1', 'ACCEPTED');

      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES 
        ('f-lc-v1', 'prj-lifecycle-1', 'drg-1', 'lcv1.dwg', 'lcv1.dwg', 'projects/prj-lifecycle-1/lcv1.dwg', 'application/acad', 1024, 'draughtsman_version', 'COMPLETED');

      INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by, approval_status)
      VALUES ('dv-lc-1', 'prj-lifecycle-1', 'f-lc-v1', 1, 'drg-1', 'APPROVED');
    `);

    // Round 1 correction request
    const r1 = await testRequest(env, '/api/projects/request-correction', {
      method: 'POST',
      token: 'eng-1',
      body: {
        projectId: 'prj-lifecycle-1',
        correctionId: 'corr-lc-1',
        targetVersionId: 'dv-lc-1',
        description: 'First revision requested'
      }
    });
    assert.equal(r1.status, 200);

    let corr1 = rawDb.prepare('SELECT * FROM corrections WHERE id = ?').get('corr-lc-1');
    assert.equal(corr1.status, 'OPEN');

    // Draughtsman resubmits for round 1
    rawDb.exec(`
      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES ('f-lc-v2', 'prj-lifecycle-1', 'drg-1', 'lcv2.dwg', 'lcv2.dwg', 'projects/prj-lifecycle-1/lcv2.dwg', 'application/acad', 1024, 'workspace_draft', 'COMPLETED');
    `);
    const sub1 = await testRequest(env, '/api/projects/submit-drawing', {
      method: 'POST',
      token: 'drg-1',
      body: { projectId: 'prj-lifecycle-1', draftFileId: 'f-lc-v2', actionId: 'act-sub-lc-v2' }
    });
    assert.equal(sub1.status, 200);

    corr1 = rawDb.prepare('SELECT * FROM corrections WHERE id = ?').get('corr-lc-1');
    assert.equal(corr1.status, 'IN_REVIEW');

    const v2 = rawDb.prepare('SELECT id FROM drawing_versions WHERE project_id = ? AND version_number = 2').get('prj-lifecycle-1');

    // Admin approves v2 -> correction remains IN_REVIEW
    const appv2 = await testRequest(env, '/api/projects/admin-approve-drawing', {
      method: 'POST',
      token: 'adm-1',
      body: { projectId: 'prj-lifecycle-1', drawingVersionId: v2.id, actionId: 'act-app-lc-v2' }
    });
    assert.equal(appv2.status, 200);

    corr1 = rawDb.prepare('SELECT * FROM corrections WHERE id = ?').get('corr-lc-1');
    assert.equal(corr1.status, 'IN_REVIEW', 'Correction must remain IN_REVIEW after admin approval');

    // Round 2 correction request
    const r2 = await testRequest(env, '/api/projects/request-correction', {
      method: 'POST',
      token: 'eng-1',
      body: {
        projectId: 'prj-lifecycle-1',
        correctionId: 'corr-lc-2',
        targetVersionId: v2.id,
        description: 'Second revision requested'
      }
    });
    assert.equal(r2.status, 200);

    let corr2 = rawDb.prepare('SELECT * FROM corrections WHERE id = ?').get('corr-lc-2');
    assert.equal(corr2.status, 'OPEN');

    // Draughtsman resubmits for round 2
    rawDb.exec(`
      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES ('f-lc-v3', 'prj-lifecycle-1', 'drg-1', 'lcv3.dwg', 'lcv3.dwg', 'projects/prj-lifecycle-1/lcv3.dwg', 'application/acad', 1024, 'workspace_draft', 'COMPLETED');
    `);
    const sub2 = await testRequest(env, '/api/projects/submit-drawing', {
      method: 'POST',
      token: 'drg-1',
      body: { projectId: 'prj-lifecycle-1', draftFileId: 'f-lc-v3', actionId: 'act-sub-lc-v3' }
    });
    assert.equal(sub2.status, 200);

    corr2 = rawDb.prepare('SELECT * FROM corrections WHERE id = ?').get('corr-lc-2');
    assert.equal(corr2.status, 'IN_REVIEW');

    const v3 = rawDb.prepare('SELECT id FROM drawing_versions WHERE project_id = ? AND version_number = 3').get('prj-lifecycle-1');

    // Admin approves v3
    await testRequest(env, '/api/projects/admin-approve-drawing', {
      method: 'POST',
      token: 'adm-1',
      body: { projectId: 'prj-lifecycle-1', drawingVersionId: v3.id, actionId: 'act-app-lc-v3' }
    });

    // Engineer approves final drawing -> resolves corrections
    const fin = await testRequest(env, '/api/projects/approve-final', {
      method: 'POST',
      token: 'eng-1',
      body: { projectId: 'prj-lifecycle-1', drawingVersionId: v3.id }
    });
    assert.equal(fin.status, 200);

    corr2 = rawDb.prepare('SELECT * FROM corrections WHERE id = ?').get('corr-lc-2');
    assert.equal(corr2.status, 'RESOLVED');
  });

  await t.test('Scenario 11: Review-history role permissions across all roles', async () => {
    // 1. Unassigned draughtsman is denied
    const unassignedDrg = await testRequest(env, '/api/projects/prj-sec-1/drawing_version_reviews', { token: 'drg-2' });
    assert.equal(unassignedDrg.status, 403);

    // 2. Student is denied
    const stu = await testRequest(env, '/api/projects/prj-sec-1/drawing_version_reviews', { token: 'stu-1' });
    assert.equal(stu.status, 403);

    // 3. Engineer is denied
    const eng = await testRequest(env, '/api/projects/prj-sec-1/drawing_version_reviews', { token: 'eng-1' });
    assert.equal(eng.status, 403);

    // 4. Admin is permitted
    const adm = await testRequest(env, '/api/projects/prj-sec-1/drawing_version_reviews', { token: 'adm-1' });
    assert.equal(adm.status, 200);

    // 5. Assigned Draughtsman is permitted
    const drg = await testRequest(env, '/api/projects/prj-sec-1/drawing_version_reviews', { token: 'drg-1' });
    assert.equal(drg.status, 200);
  });

  await t.test('Scenario 12: Duplicate, stale, and invalid review requests are rejected safely', async () => {
    // 1. Approve-final when project is not in review state (it is currently IN_PROGRESS)
    const errApproveFinal = await testRequest(env, '/api/projects/approve-final', {
      method: 'POST',
      token: 'eng-1',
      body: { projectId: 'prj-sec-1', drawingVersionId: 'dv-approved-deliv' }
    });
    assert.equal(errApproveFinal.status, 400);
    const body1 = await errApproveFinal.json();
    assert.equal(body1.code, 'NOT_IN_REVIEW_STATE');

    // 2. Admin approve with nonexistent version ID
    const errVersion = await testRequest(env, '/api/projects/admin-approve-drawing', {
      method: 'POST',
      token: 'adm-1',
      body: { projectId: 'prj-sec-1', drawingVersionId: 'non-existent-version-id' }
    });
    assert.equal(errVersion.status, 400);

    // 3. Approve-final without drawingVersionId on project with unapproved deliverable
    rawDb.exec(`UPDATE projects SET status = 'UNDER_ENGINEER_REVIEW' WHERE id = 'prj-sec-1'`);
    // Latest version on prj-sec-1 is dv-pending-deliv (v4, PENDING)
    const errOmittedId = await testRequest(env, '/api/projects/approve-final', {
      method: 'POST',
      token: 'eng-1',
      body: { projectId: 'prj-sec-1' } // drawingVersionId omitted!
    });
    assert.equal(errOmittedId.status, 400);
    const body3 = await errOmittedId.json();
    assert.equal(body3.code, 'DELIVERABLE_UNAPPROVED');
  });
});

test('Phase 1.4 Backend Remediation — Concurrency, Provenance & Internal Access Regression Suite', async (t) => {
  const { rawDb, env, storageMap } = createIsolatedTestDb();
  seedBaselineData(rawDb);

  // Seed baseline project
  rawDb.exec(`
    INSERT INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, draughtsman_id)
    VALUES ('prj-c1', 'eng-1', 'Concurrency Test Project', '123 Test Ave', 'Architectural Plan', 'Floor Plan', '2000 sqft', 'UNDER_ADMIN_REVIEW', 'drg-1');

    INSERT INTO assignments (id, project_id, draughtsman_id, status)
    VALUES ('asg-c1', 'prj-c1', 'drg-1', 'ACCEPTED');

    -- Drawing file and version 1
    INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
    VALUES ('file-v1', 'prj-c1', 'drg-1', 'plan_v1.pdf', 'plan_v1.pdf', 'projects/prj-c1/draughtsman_version/plan_v1.pdf', 'application/pdf', 1024, 'draughtsman_version', 'COMPLETED');

    INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by, approval_status, approval_source)
    VALUES ('dv-v1', 'prj-c1', 'file-v1', 1, 'drg-1', 'PENDING', 'ADMIN_REVIEW');
  `);

  storageMap.set('projects/prj-c1/draughtsman_version/plan_v1.pdf', { buffer: Buffer.from('mock pdf'), contentType: 'application/pdf' });

  await t.test('Scenario 13: Draughtsman self-uploaded internal QC file is blocked from download and excluded from file list query', async () => {
    // Draughtsman uploads internal QC files
    rawDb.exec(`
      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status) VALUES
        ('file-drg-int', 'prj-c1', 'drg-1', 'internal_memo.pdf', 'internal_memo.pdf', 'projects/prj-c1/admin_internal/internal_memo.pdf', 'application/pdf', 512, 'admin_internal', 'COMPLETED'),
        ('file-drg-qc', 'prj-c1', 'drg-1', 'qc_notes.pdf', 'qc_notes.pdf', 'projects/prj-c1/qc_notes/qc_notes.pdf', 'application/pdf', 512, 'qc_notes', 'COMPLETED'),
        ('file-drg-draft', 'prj-c1', 'drg-1', 'draft_model.dwg', 'draft_model.dwg', 'projects/prj-c1/workspace_draft/draft_model.dwg', 'application/octet-stream', 2048, 'workspace_draft', 'COMPLETED');
    `);
    storageMap.set('projects/prj-c1/admin_internal/internal_memo.pdf', { buffer: Buffer.from('memo'), contentType: 'application/pdf' });
    storageMap.set('projects/prj-c1/qc_notes/qc_notes.pdf', { buffer: Buffer.from('notes'), contentType: 'application/pdf' });
    storageMap.set('projects/prj-c1/workspace_draft/draft_model.dwg', { buffer: Buffer.from('draft dwg'), contentType: 'application/octet-stream' });

    // 1. Draughtsman download of admin_internal file uploaded by themselves is BLOCKED (403 INTERNAL_FILE_ACCESS_DENIED)
    const resInt = await testRequest(env, '/api/files/file-drg-int/download', { token: 'drg-1' });
    assert.equal(resInt.status, 403);
    const bodyInt = await resInt.json();
    assert.equal(bodyInt.code, 'INTERNAL_FILE_ACCESS_DENIED');

    // 2. Draughtsman download of qc_notes file uploaded by themselves is BLOCKED (403 INTERNAL_FILE_ACCESS_DENIED)
    const resQc = await testRequest(env, '/api/files/file-drg-qc/download', { token: 'drg-1' });
    assert.equal(resQc.status, 403);
    const bodyQc = await resQc.json();
    assert.equal(bodyQc.code, 'INTERNAL_FILE_ACCESS_DENIED');

    // 3. Draughtsman download of legitimate workspace draft SUCCEEDS (200)
    const resDraft = await testRequest(env, '/api/files/file-drg-draft/download', { token: 'drg-1' });
    assert.equal(resDraft.status, 200);

    // 4. Draughtsman file list query excludes internal files
    const resList = await testRequest(env, '/api/projects/prj-c1/files', { token: 'drg-1' });
    assert.equal(resList.status, 200);
    const filesList = await resList.json();
    const listedIds = filesList.map(f => f.id);
    assert.ok(!listedIds.includes('file-drg-int'), 'admin_internal file must not be listed for draughtsman');
    assert.ok(!listedIds.includes('file-drg-qc'), 'qc_notes file must not be listed for draughtsman');
    assert.ok(listedIds.includes('file-drg-draft'), 'workspace_draft must be listed for draughtsman');
    assert.ok(listedIds.includes('file-v1'), 'draughtsman_version must be listed for draughtsman');

    // 5. Studio Admin CAN access the internal files
    const resAdminDownload = await testRequest(env, '/api/files/file-drg-int/download', { token: 'adm-1' });
    assert.equal(resAdminDownload.status, 200);
  });

  await t.test('Scenario 14: Concurrent Admin decisions race: approve vs revision request collision handling', async () => {
    // 1. Admin A approves version 1
    const resApprove = await testRequest(env, '/api/projects/admin-approve-drawing', {
      method: 'POST',
      token: 'adm-1',
      body: {
        projectId: 'prj-c1',
        drawingVersionId: 'dv-v1',
        feedback: 'Approved by Admin A'
      }
    });
    assert.equal(resApprove.status, 200);
    const approveBody = await resApprove.json();
    assert.equal(approveBody.approvalStatus, 'APPROVED');
    assert.equal(approveBody.projectStatus, 'UNDER_ENGINEER_REVIEW');

    // 2. Admin B concurrently or subsequently attempts to request revision on that same version
    const resReject = await testRequest(env, '/api/projects/admin-request-revision', {
      method: 'POST',
      token: 'adm-1',
      body: {
        projectId: 'prj-c1',
        drawingVersionId: 'dv-v1',
        feedback: 'Late review by Admin B'
      }
    });
    // Expected: 400 because project status is now UNDER_ENGINEER_REVIEW, not UNDER_ADMIN_REVIEW
    assert.equal(resReject.status, 400);
    const rejectBody = await resReject.json();
    assert.equal(rejectBody.code, 'INVALID_PROJECT_STATUS');

    // 3. Test atomic conditional batch collision
    rawDb.exec(`
      INSERT INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, draughtsman_id)
      VALUES ('prj-c2', 'eng-1', 'Race Project', '456 Race Rd', 'Structural Plan', 'Floor Plan', '1500 sqft', 'UNDER_ADMIN_REVIEW', 'drg-1');

      INSERT INTO assignments (id, project_id, draughtsman_id, status)
      VALUES ('asg-c2', 'prj-c2', 'drg-1', 'ACCEPTED');

      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES ('file-v2-race', 'prj-c2', 'drg-1', 'race_v1.pdf', 'race_v1.pdf', 'projects/prj-c2/draughtsman_version/race_v1.pdf', 'application/pdf', 1024, 'draughtsman_version', 'COMPLETED');

      INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by, approval_status, approval_source)
      VALUES ('dv-v2-race', 'prj-c2', 'file-v2-race', 1, 'drg-1', 'PENDING', 'ADMIN_REVIEW');
    `);
    storageMap.set('projects/prj-c2/draughtsman_version/race_v1.pdf', { buffer: Buffer.from('race pdf'), contentType: 'application/pdf' });

    // If version is updated concurrently right before decision
    rawDb.exec(`UPDATE drawing_versions SET approval_status = 'APPROVED' WHERE id = 'dv-v2-race'`);
    const resConflict = await testRequest(env, '/api/projects/admin-request-revision', {
      method: 'POST',
      token: 'adm-1',
      body: {
        projectId: 'prj-c2',
        drawingVersionId: 'dv-v2-race',
        feedback: 'Revision requested'
      }
    });
    assert.equal(resConflict.status, 400);

    // Reset to PENDING, but project status is changed
    rawDb.exec(`UPDATE drawing_versions SET approval_status = 'PENDING' WHERE id = 'dv-v2-race'`);
    rawDb.exec(`UPDATE projects SET status = 'IN_PROGRESS' WHERE id = 'prj-c2'`);
    const resConflictProj = await testRequest(env, '/api/projects/admin-approve-drawing', {
      method: 'POST',
      token: 'adm-1',
      body: {
        projectId: 'prj-c2',
        drawingVersionId: 'dv-v2-race',
        feedback: 'Approve'
      }
    });
    assert.equal(resConflictProj.status, 400);
  });

  await t.test('Scenario 15: No partial project/version state transition on conflict', async () => {
    // Verify that prj-c2 state remains intact without partial updates
    const row = rawDb.prepare('SELECT status FROM projects WHERE id = ?').get('prj-c2');
    assert.equal(row.status, 'IN_PROGRESS');

    const vRow = rawDb.prepare('SELECT approval_status FROM drawing_versions WHERE id = ?').get('dv-v2-race');
    assert.equal(vRow.approval_status, 'PENDING');

    const reviews = rawDb.prepare('SELECT COUNT(*) as count FROM drawing_version_reviews WHERE project_id = ?').get('prj-c2');
    assert.equal(reviews.count, 0, 'Must have zero reviews inserted on aborted attempt');
  });

  await t.test('Scenario 16: Historical terminal-version access in completed projects', async () => {
    // Setup a completed project with multiple versions
    rawDb.exec(`
      INSERT INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, approved_at)
      VALUES ('prj-hist-1', 'eng-1', 'Historical Completed Project', '789 Heritage Way', 'Historic Map', 'Site Plan', '5000 sqft', 'COMPLETED', '2026-01-15 12:00:00');

      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status) VALUES
        ('file-h1', 'prj-hist-1', 'drg-1', 'hist_v1.pdf', 'hist_v1.pdf', 'projects/prj-hist-1/draughtsman_version/hist_v1.pdf', 'application/pdf', 1024, 'draughtsman_version', 'COMPLETED'),
        ('file-h2', 'prj-hist-1', 'drg-1', 'hist_v2.pdf', 'hist_v2.pdf', 'projects/prj-hist-1/draughtsman_version/hist_v2.pdf', 'application/pdf', 1024, 'draughtsman_version', 'COMPLETED'),
        ('file-h3', 'prj-hist-1', 'drg-1', 'hist_v3.pdf', 'hist_v3.pdf', 'projects/prj-hist-1/draughtsman_version/hist_v3.pdf', 'application/pdf', 1024, 'draughtsman_version', 'COMPLETED');

      INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by, approval_status, approval_source, reviewed_at) VALUES
        ('dv-h1', 'prj-hist-1', 'file-h1', 1, 'drg-1', 'PENDING', 'UNVERIFIED_HISTORICAL', NULL),
        ('dv-h2', 'prj-hist-1', 'file-h2', 2, 'drg-1', 'APPROVED', 'LEGACY_CORRECTION_TARGET', NULL),
        ('dv-h3', 'prj-hist-1', 'file-h3', 3, 'drg-1', 'APPROVED', 'LEGACY_COMPLETED_ACCEPTANCE', '2026-01-15 12:00:00');
    `);
    storageMap.set('projects/prj-hist-1/draughtsman_version/hist_v1.pdf', { buffer: Buffer.from('hist v1'), contentType: 'application/pdf' });
    storageMap.set('projects/prj-hist-1/draughtsman_version/hist_v2.pdf', { buffer: Buffer.from('hist v2'), contentType: 'application/pdf' });
    storageMap.set('projects/prj-hist-1/draughtsman_version/hist_v3.pdf', { buffer: Buffer.from('hist v3'), contentType: 'application/pdf' });

    // 1. Terminal accepted version (v3) is accessible to Engineer
    const resV3 = await testRequest(env, '/api/files/file-h3/download', { token: 'eng-1' });
    assert.equal(resV3.status, 200);

    // 2. Correction target version (v2) is accessible to Engineer
    const resV2 = await testRequest(env, '/api/files/file-h2/download', { token: 'eng-1' });
    assert.equal(resV2.status, 200);

    // 3. Unapproved intermediate version (v1) is BLOCKED for Engineer
    const resV1 = await testRequest(env, '/api/files/file-h1/download', { token: 'eng-1' });
    assert.equal(resV1.status, 403);
    const bodyV1 = await resV1.json();
    assert.equal(bodyV1.code, 'DELIVERABLE_UNAPPROVED');

    // 4. In files list, only approved versions appear for Engineer
    const resList = await testRequest(env, '/api/projects/prj-hist-1/files', { token: 'eng-1' });
    assert.equal(resList.status, 200);
    const list = await resList.json();
    const ids = list.map(f => f.id);
    assert.ok(ids.includes('file-h3'), 'Terminal v3 must be listed');
    assert.ok(ids.includes('file-h2'), 'Approved v2 must be listed');
    assert.ok(!ids.includes('file-h1'), 'Unapproved v1 must NOT be listed');
  });

  await t.test('Scenario 17: Legacy provenance and NULL review timestamps', async () => {
    // Query historical records and verify approval_source and reviewed_at
    const v1 = rawDb.prepare('SELECT approval_status, approval_source, reviewed_at FROM drawing_versions WHERE id = ?').get('dv-h1');
    assert.equal(v1.approval_status, 'PENDING');
    assert.equal(v1.approval_source, 'UNVERIFIED_HISTORICAL');
    assert.equal(v1.reviewed_at, null);

    const v2 = rawDb.prepare('SELECT approval_status, approval_source, reviewed_at FROM drawing_versions WHERE id = ?').get('dv-h2');
    assert.equal(v2.approval_status, 'APPROVED');
    assert.equal(v2.approval_source, 'LEGACY_CORRECTION_TARGET');
    assert.equal(v2.reviewed_at, null, 'Legacy correction target must have NULL reviewed_at');

    const v3 = rawDb.prepare('SELECT approval_status, approval_source, reviewed_at FROM drawing_versions WHERE id = ?').get('dv-h3');
    assert.equal(v3.approval_status, 'APPROVED');
    assert.equal(v3.approval_source, 'LEGACY_COMPLETED_ACCEPTANCE');
    assert.equal(v3.reviewed_at, '2026-01-15 12:00:00', 'Completed project terminal version inherits approved_at');

    // Modern version has approval_source = ADMIN_REVIEW
    const modernV = rawDb.prepare('SELECT approval_source FROM drawing_versions WHERE id = ?').get('dv-v1');
    assert.equal(modernV.approval_source, 'ADMIN_REVIEW');
  });

  await t.test('Scenario 18: Draughtsman file upload transitions project to UNDER_ADMIN_REVIEW and correction to IN_REVIEW', async () => {
    // 1. Setup project in IN_PROGRESS with an OPEN correction
    rawDb.exec(`
      INSERT INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, draughtsman_id)
      VALUES ('prj-upload-qc', 'eng-1', 'QC Upload Project', '101 QC Blvd', 'Correction Drawing', 'Architectural', '2000 sqft', 'IN_PROGRESS', 'drg-1');

      INSERT INTO assignments (id, project_id, draughtsman_id, status)
      VALUES ('asg-upload-qc', 'prj-upload-qc', 'drg-1', 'ACCEPTED');

      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES ('file-qc-v1', 'prj-upload-qc', 'drg-1', 'initial_v1.dxf', 'initial_v1.dxf', 'projects/prj-upload-qc/draughtsman_version/initial_v1.dxf', 'application/dxf', 1024, 'draughtsman_version', 'COMPLETED');

      INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by, approval_status, approval_source)
      VALUES ('dv-upload-v1', 'prj-upload-qc', 'file-qc-v1', 1, 'drg-1', 'APPROVED', 'ADMIN_REVIEW');

      INSERT INTO corrections (id, project_id, target_version_id, requested_by, round_number, description, status)
      VALUES ('corr-upload-qc', 'prj-upload-qc', 'dv-upload-v1', 'eng-1', 1, 'Please adjust stairs', 'IN_PROGRESS');
    `);

    // 2. Upload deliverable with category 'draughtsman_version'
    const fileBytes = '03_CORRECTION_01 CAD CONTENT';
    const resUpload = await testRequest(env, '/api/projects/prj-upload-qc/files?category=draughtsman_version', {
      method: 'POST',
      token: 'drg-1',
      headers: {
        'X-Action-Id': 'act-upload-qc-v2',
        'X-File-Name': '03_CORRECTION_01.dxf',
        'Content-Length': String(fileBytes.length),
      },
      body: fileBytes,
    });

    assert.equal(resUpload.status, 200);
    const uploadedFile = await resUpload.json();
    assert.equal(uploadedFile.status, 'COMPLETED');

    // 3. Verify project transitioned to UNDER_ADMIN_REVIEW
    const updatedProj = rawDb.prepare('SELECT status FROM projects WHERE id = ?').get('prj-upload-qc');
    assert.equal(updatedProj.status, 'UNDER_ADMIN_REVIEW', 'Project must transition to UNDER_ADMIN_REVIEW upon draughtsman_version upload');

    // 4. Verify correction transitioned to IN_REVIEW
    const updatedCorr = rawDb.prepare('SELECT status FROM corrections WHERE id = ?').get('corr-upload-qc');
    assert.equal(updatedCorr.status, 'IN_REVIEW', 'Active correction must transition to IN_REVIEW upon resubmission');

    // 5. Verify drawing version created with status PENDING
    const dv = rawDb.prepare('SELECT * FROM drawing_versions WHERE project_id = ? ORDER BY version_number DESC').get('prj-upload-qc');
    assert.ok(dv, 'Drawing version must exist');
    assert.equal(dv.approval_status, 'PENDING');
    assert.equal(dv.correction_id, 'corr-upload-qc');

    // 6. Admin can now approve deliverable cleanly without stuck loading or status error
    const resApprove = await testRequest(env, '/api/projects/admin-approve-drawing', {
      method: 'POST',
      token: 'adm-1',
      body: {
        projectId: 'prj-upload-qc',
        drawingVersionId: dv.id,
        feedback: 'Approved by studio QC'
      }
    });
    assert.equal(resApprove.status, 200);
    const approveData = await resApprove.json();
    assert.equal(approveData.approvalStatus, 'APPROVED');
    assert.equal(approveData.projectStatus, 'UNDER_ENGINEER_REVIEW');
  });

  await t.test('Scenario 19: Clear all notifications clears user notifications completely', async () => {
    // 1. Seed notifications for adm-1
    rawDb.exec(`
      INSERT INTO notifications (id, user_id, project_id, type, title, message)
      VALUES
        ('notif-adm-test-1', 'adm-1', 'prj-upload-qc', 'TEST', 'Test 1', 'Message 1'),
        ('notif-adm-test-2', 'adm-1', 'prj-upload-qc', 'TEST', 'Test 2', 'Message 2');
    `);

    // 2. Fetch notifications
    const resListBefore = await testRequest(env, '/api/notifications', { token: 'adm-1' });
    assert.equal(resListBefore.status, 200);
    const listBefore = await resListBefore.json();
    assert.ok(listBefore.length >= 2);

    // 3. Clear all via DELETE /api/notifications
    const resClear = await testRequest(env, '/api/notifications', {
      method: 'DELETE',
      token: 'adm-1'
    });
    assert.equal(resClear.status, 200);

    // 4. Fetch notifications after clear
    const resListAfter = await testRequest(env, '/api/notifications', { token: 'adm-1' });
    assert.equal(resListAfter.status, 200);
    const listAfter = await resListAfter.json();
    assert.equal(listAfter.length, 0, 'Notifications for adm-1 must be empty after clear all');
  });

  await t.test('Scenario 20: Initial drawing upload transitions project to UNDER_ADMIN_REVIEW and prevents false 400 on submit-drawing', async () => {
    // 1. Setup project in IN_PROGRESS with no prior drawing versions
    rawDb.exec(`
      INSERT INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, draughtsman_id)
      VALUES ('prj-init-sub', 'eng-1', 'Initial Drawing Project', '200 Initial Way', 'Floor Plan', 'Architectural', '1500 sqft', 'IN_PROGRESS', 'drg-1');

      INSERT INTO assignments (id, project_id, draughtsman_id, status)
      VALUES ('asg-init-sub', 'prj-init-sub', 'drg-1', 'ACCEPTED');
    `);

    // 2. Upload initial deliverable with category 'draughtsman_version'
    const fileBytes = 'INITIAL CAD BLUEPRINT CONTENT';
    const resUpload = await testRequest(env, '/api/projects/prj-init-sub/files?category=draughtsman_version', {
      method: 'POST',
      token: 'drg-1',
      headers: {
        'X-Action-Id': 'act-init-upload-v1',
        'X-File-Name': 'initial_floorplan.dxf',
        'Content-Length': String(fileBytes.length),
      },
      body: fileBytes,
    });

    assert.equal(resUpload.status, 200);

    // 3. Project must be in UNDER_ADMIN_REVIEW
    const proj = rawDb.prepare('SELECT status, last_action_id FROM projects WHERE id = ?').get('prj-init-sub');
    assert.equal(proj.status, 'UNDER_ADMIN_REVIEW');

    // 4. Version v1 created as PENDING
    const dv = rawDb.prepare('SELECT version_number, approval_status FROM drawing_versions WHERE project_id = ?').get('prj-init-sub');
    assert.equal(dv.version_number, 1);
    assert.equal(dv.approval_status, 'PENDING');

    // 5. Subsequent submit-drawing call (e.g. from UI button or duplicate tap) must return 200 OK without false 400 error
    const resSubmit = await testRequest(env, '/api/projects/submit-drawing', {
      method: 'POST',
      token: 'drg-1',
      body: {
        projectId: 'prj-init-sub',
        actionId: 'act-followup-submit-btn',
      }
    });

    assert.equal(resSubmit.status, 200, 'Follow-up submit-drawing must return 200 OK when project already in UNDER_ADMIN_REVIEW');
    const submitJson = await resSubmit.json();
    assert.equal(submitJson.success, true);
  });

  await t.test('Scenario 21: Correction upload increments version and prevents false 400 on subsequent submit-drawing', async () => {
    // 1. Setup project in IN_PROGRESS with an OPEN correction (Round 1)
    rawDb.exec(`
      INSERT INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, draughtsman_id, correction_round)
      VALUES ('prj-corr-sub', 'eng-1', 'Correction Project', '300 Revision Rd', 'Elevation', 'Architectural', '2200 sqft', 'IN_PROGRESS', 'drg-1', 1);

      INSERT INTO assignments (id, project_id, draughtsman_id, status)
      VALUES ('asg-corr-sub', 'prj-corr-sub', 'drg-1', 'ACCEPTED');

      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES ('file-corr-v1', 'prj-corr-sub', 'drg-1', 'elevation_v1.dxf', 'elevation_v1.dxf', 'projects/prj-corr-sub/draughtsman_version/elevation_v1.dxf', 'application/dxf', 1024, 'draughtsman_version', 'COMPLETED');

      INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by, approval_status)
      VALUES ('dv-corr-v1', 'prj-corr-sub', 'file-corr-v1', 1, 'drg-1', 'APPROVED');

      INSERT INTO corrections (id, project_id, target_version_id, requested_by, round_number, description, status)
      VALUES ('corr-rev-1', 'prj-corr-sub', 'dv-corr-v1', 'eng-1', 1, 'Adjust parapet wall height', 'IN_PROGRESS');
    `);

    // 2. Upload correction deliverable
    const corrBytes = 'CORRECTION REV 2 CAD DATA';
    const resUpload = await testRequest(env, '/api/projects/prj-corr-sub/files?category=draughtsman_version', {
      method: 'POST',
      token: 'drg-1',
      headers: {
        'X-Action-Id': 'act-corr-upload-v2',
        'X-File-Name': 'elevation_v2.dxf',
        'Content-Length': String(corrBytes.length),
      },
      body: corrBytes,
    });

    assert.equal(resUpload.status, 200);

    // 3. Verify project is UNDER_ADMIN_REVIEW and correction is IN_REVIEW
    const proj = rawDb.prepare('SELECT status FROM projects WHERE id = ?').get('prj-corr-sub');
    assert.equal(proj.status, 'UNDER_ADMIN_REVIEW');

    const corr = rawDb.prepare('SELECT status FROM corrections WHERE id = ?').get('corr-rev-1');
    assert.equal(corr.status, 'IN_REVIEW');

    // 4. Verify version 2 created linked to correction
    const dv2 = rawDb.prepare('SELECT version_number, correction_id, approval_status FROM drawing_versions WHERE project_id = ? AND version_number = 2').get('prj-corr-sub');
    assert.ok(dv2);
    assert.equal(dv2.correction_id, 'corr-rev-1');
    assert.equal(dv2.approval_status, 'PENDING');

    // 5. Subsequent submit-drawing must not fail with 400
    const resSubmit = await testRequest(env, '/api/projects/submit-drawing', {
      method: 'POST',
      token: 'drg-1',
      body: {
        projectId: 'prj-corr-sub',
        actionId: 'act-corr-followup',
      }
    });

    assert.equal(resSubmit.status, 200);
    const submitJson = await resSubmit.json();
    assert.equal(submitJson.success, true);
  });

  await t.test('Scenario 22: Idempotent upload retry does not create duplicate drawing versions', async () => {
    // 1. Setup project in IN_PROGRESS
    rawDb.exec(`
      INSERT INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, draughtsman_id)
      VALUES ('prj-retry-idemp', 'eng-1', 'Idempotent Retry Project', '400 Idemp Ln', 'Section A', 'Architectural', '1800 sqft', 'IN_PROGRESS', 'drg-1');

      INSERT INTO assignments (id, project_id, draughtsman_id, status)
      VALUES ('asg-retry-idemp', 'prj-retry-idemp', 'drg-1', 'ACCEPTED');
    `);

    const fileBytes = 'SECTION A CAD DATA';
    const actionId = 'act-idemp-first-try';

    // 2. First upload attempt succeeds on server
    const res1 = await testRequest(env, '/api/projects/prj-retry-idemp/files?category=draughtsman_version', {
      method: 'POST',
      token: 'drg-1',
      headers: {
        'X-Action-Id': actionId,
        'X-File-Name': 'section_a.dxf',
        'Content-Length': String(fileBytes.length),
      },
      body: fileBytes,
    });
    assert.equal(res1.status, 200);

    const countBefore = rawDb.prepare('SELECT count(*) as count FROM drawing_versions WHERE project_id = ?').get('prj-retry-idemp').count;
    assert.equal(countBefore, 1);

    // 3. Client retries with same actionId (simulating network disconnection before receiving response)
    const resRetry = await testRequest(env, '/api/projects/prj-retry-idemp/files?category=draughtsman_version', {
      method: 'POST',
      token: 'drg-1',
      headers: {
        'X-Action-Id': actionId,
        'X-File-Name': 'section_a.dxf',
        'Content-Length': String(fileBytes.length),
      },
      body: fileBytes,
    });

    assert.equal(resRetry.status, 200, 'Idempotent retry must succeed with 200');

    // 4. Drawing versions count must still be exactly 1 (no duplicate versions created)
    const countAfter = rawDb.prepare('SELECT count(*) as count FROM drawing_versions WHERE project_id = ?').get('prj-retry-idemp').count;
    assert.equal(countAfter, 1, 'Idempotent retry must not create duplicate drawing versions');
  });

  await t.test('Scenario 23: Genuine HTTP 400 errors are preserved when project is not in submittable state', async () => {
    // 1. Setup project in COMPLETED status
    rawDb.exec(`
      INSERT INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, draughtsman_id)
      VALUES ('prj-completed-err', 'eng-1', 'Completed Project', '500 Done St', 'Plan', 'Architectural', '2000 sqft', 'COMPLETED', 'drg-1');
    `);

    // 2. Attempt submit-drawing on COMPLETED project -> must reject with 400
    const resSubmit = await testRequest(env, '/api/projects/submit-drawing', {
      method: 'POST',
      token: 'drg-1',
      body: {
        projectId: 'prj-completed-err',
        actionId: 'act-completed-err-try',
      }
    });

    assert.equal(resSubmit.status, 400);
    const errJson = await resSubmit.json();
    assert.equal(errJson.error, 'Project is not in a submittable state');

    // 3. Attempt draughtsman_version file upload on COMPLETED project -> must reject with 403 Forbidden
    const resUpload = await testRequest(env, '/api/projects/prj-completed-err/files?category=draughtsman_version', {
      method: 'POST',
      token: 'drg-1',
      headers: {
        'X-Action-Id': 'act-comp-upload-try',
        'X-File-Name': 'illegal_upload.dxf',
        'Content-Length': '10',
      },
      body: '0123456789',
    });

    assert.equal(resUpload.status, 403);
  });
});
