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

const bundlePath = path.join(workerRoot, 'node_modules', '.test_app_bundle_phase_c.mjs');
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
          const results = stmt.all();
          return { results };
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

  const storedObjects = new Map();
  const storage = {
    async get(key) {
      const obj = storedObjects.get(key);
      if (!obj) return null;
      return {
        body: new TextEncoder().encode(obj.data),
        httpEtag: 'test-etag',
        writeHttpMetadata(headers) {
          headers.set('content-type', obj.contentType || 'application/octet-stream');
        }
      };
    },
    async put(key, body, options) {
      storedObjects.set(key, { data: 'test-content', contentType: options?.httpMetadata?.contentType });
      return { size: 1234 };
    }
  };

  return { rawDb: db, env: { DB: d1, STORAGE: storage } };
}

function seedBaselineData(rawDb) {
  rawDb.exec(`
    INSERT INTO users (id, email, name, role, status) VALUES
      ('admin-1', 'admin@draughtsmanstudio.com', 'Studio Admin', 'ADMIN', 'ACTIVE'),
      ('eng-1', 'engineer1@example.com', 'Structural Engineer', 'ENGINEER', 'ACTIVE'),
      ('eng-2', 'engineer2@example.com', 'Civil Engineer', 'CLIENT', 'ACTIVE'),
      ('eng-suspended', 'suspended@example.com', 'Suspended Engineer', 'ENGINEER', 'SUSPENDED'),
      ('drg-1', 'draughtsman1@example.com', 'Senior Draughtsman', 'DRAUGHTSMAN', 'ACTIVE'),
      ('student-1', 'student1@example.com', 'Junior Student', 'STUDENT', 'ACTIVE');
  `);

  rawDb.prepare(`
    INSERT INTO legal_documents (id, document_type, version, title, content, effective_at, status, is_mandatory, locale)
    VALUES ('doc-terms-v1', 'TERMS_AND_CONDITIONS', '1.0.0', 'Platform Terms', '# Terms', CURRENT_TIMESTAMP, 'EFFECTIVE', 1, 'en-IN')
  `).run();

  const insertEvent = rawDb.prepare(`
    INSERT INTO legal_consent_events (id, user_id, document_id, document_type, document_version, action_type, consent_purpose, idempotency_key, ip_hash, source)
    VALUES (?, ?, 'doc-terms-v1', 'TERMS_AND_CONDITIONS', '1.0.0', 'ACCEPT', 'DEFAULT', ?, 'hash-ip', 'WEB_APP')
  `);
  const insertConsent = rawDb.prepare(`
    INSERT INTO user_consent_state (id, user_id, consent_type, purpose_tag, current_status, accepted_version, last_event_id, updated_at)
    VALUES (?, ?, 'TERMS', 'DEFAULT', 'ACCEPTED', '1.0.0', ?, CURRENT_TIMESTAMP)
  `);

  for (const uid of ['admin-1', 'eng-1', 'eng-2', 'eng-suspended', 'drg-1', 'student-1']) {
    insertEvent.run('evt-' + uid, uid, 'idem-' + uid);
    insertConsent.run('cst-' + uid, uid, 'evt-' + uid);
  }
}

async function testRequest(env, path, options = {}) {
  const headers = { ...options.headers };
  if (options.token) {
    headers['Authorization'] = `Bearer mock-token:${options.token}`;
  }
  if (options.body) {
    headers['Content-Type'] = 'application/json';
  }

  return app.request(path, {
    method: options.method || 'GET',
    headers,
    body: options.body ? JSON.stringify(options.body) : undefined,
  }, env);
}

test('PHASE C: Admin Project Creation, Redline Corrections, and Collaboration Hub Suite', async (t) => {
  const { rawDb, env } = createIsolatedTestDb();
  seedBaselineData(rawDb);

  await t.test('1. POST /api/admin/projects - Studio Admin can initiate project for Engineer', async () => {
    const actionId = 'action-admin-create-001';
    const payload = {
      clientId: 'eng-1',
      projectName: 'Metro Station Structural Framing',
      drawingType: 'STRUCTURAL',
      projectAddress: '100 Metro Rail Blvd',
      drawingName: 'Structural Framing Package (1:100)',
      projectArea: 5500,
      actionId,
    };

    const res = await testRequest(env, '/api/admin/projects', {
      method: 'POST',
      token: 'admin-1',
      body: payload,
    });
    assert.equal(res.status, 201);
    const data = await res.json();
    assert.equal(data.success, true);
    assert.ok(data.id);

    // Verify database record
    const project = rawDb.prepare('SELECT * FROM projects WHERE id = ?').get(data.id);
    assert.equal(project.client_id, 'eng-1');
    assert.equal(project.project_name, 'Metro Station Structural Framing');
    assert.equal(project.status, 'SUBMITTED');
    assert.equal(project.last_action_id, actionId);

    // Verify activity log
    const log = rawDb.prepare('SELECT * FROM activity_logs WHERE project_id = ?').get(data.id);
    assert.equal(log.actor_id, 'admin-1');
    assert.equal(log.action_type, 'PROJECT_CREATED_BY_ADMIN');

    // Verify notification sent to the Engineer
    const notif = rawDb.prepare('SELECT * FROM notifications WHERE project_id = ? AND user_id = ?').get(data.id, 'eng-1');
    assert.ok(notif);
    assert.equal(notif.type, 'NEW_PROJECT');
  });

  await t.test('2. POST /api/admin/projects - Non-admin roles are strictly rejected with 403', async () => {
    const payload = {
      clientId: 'eng-1',
      projectName: 'Unauthorized Project',
      drawingType: 'FLOOR_PLAN',
    };

    // Engineer caller
    const resEng = await testRequest(env, '/api/admin/projects', {
      method: 'POST',
      token: 'eng-1',
      body: payload,
    });
    assert.equal(resEng.status, 403);

    // Draughtsman caller
    const resDrg = await testRequest(env, '/api/admin/projects', {
      method: 'POST',
      token: 'drg-1',
      body: payload,
    });
    assert.equal(resDrg.status, 403);
  });

  await t.test('3. POST /api/admin/projects - Invalid clientId is rejected with 400', async () => {
    // Target client is a draughtsman, not an engineer
    const payload = {
      clientId: 'drg-1',
      projectName: 'Invalid Client Project',
      drawingType: 'FLOOR_PLAN',
    };
    const res = await testRequest(env, '/api/admin/projects', {
      method: 'POST',
      token: 'admin-1',
      body: payload,
    });
    assert.equal(res.status, 400);
    const data = await res.json();
    assert.equal(data.code, 'INVALID_ENGINEER');
  });

  await t.test('3b. POST /api/admin/projects - Suspended target Engineer is rejected with 403 ACCOUNT_SUSPENDED', async () => {
    const payload = {
      clientId: 'eng-suspended',
      projectName: 'Suspended Account Project',
      drawingType: 'FLOOR_PLAN',
    };
    const res = await testRequest(env, '/api/admin/projects', {
      method: 'POST',
      token: 'admin-1',
      body: payload,
    });
    assert.equal(res.status, 403);
    const data = await res.json();
    assert.equal(data.code, 'ACCOUNT_SUSPENDED');
  });

  await t.test('4. POST /api/admin/projects - Idempotent retry returns success without duplication', async () => {
    const actionId = 'action-admin-idempotent-002';
    const payload = {
      id: 'PRJ-IDEMP-001',
      clientId: 'eng-2',
      projectName: 'Idempotency Test Project',
      drawingType: 'FLOOR_PLAN',
      actionId,
    };

    const res1 = await testRequest(env, '/api/admin/projects', {
      method: 'POST',
      token: 'admin-1',
      body: payload,
    });
    assert.equal(res1.status, 201);

    const res2 = await testRequest(env, '/api/admin/projects', {
      method: 'POST',
      token: 'admin-1',
      body: payload,
    });
    assert.equal(res2.status, 200);
    const data2 = await res2.json();
    assert.equal(data2.idempotent, true);
  });

  await t.test('5. POST /api/projects/request-correction - Admin can request redline correction with pin annotation', async () => {
    // Setup a project in UNDER_ENGINEER_REVIEW with full schema fields
    rawDb.exec(`
      INSERT INTO projects (id, client_id, draughtsman_id, project_name, project_address, drawing_name, drawing_type, project_area, status, last_action_id, correction_round)
      VALUES ('prj-review-001', 'eng-1', 'drg-1', 'Review Project', 'Site A', 'Drawing 1', 'FLOOR_PLAN', '1500', 'UNDER_ENGINEER_REVIEW', 'act-0', 0);
      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES ('file-dwg-1', 'prj-review-001', 'drg-1', 'floor_plan_v1.dwg', 'floor_plan_v1.dwg', 'projects/prj-review-001/dwg.dwg', 'application/acad', 50000, 'draughtsman_version', 'COMPLETED');
      INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by)
      VALUES ('ver-001', 'prj-review-001', 'file-dwg-1', 1, 'drg-1');
    `);

    const correctionPayload = {
      projectId: 'prj-review-001',
      actionId: 'action-corr-001',
      correctionId: 'corr-001',
      targetVersionId: 'ver-001',
      description: '[PIN:0.3540,0.6820] Realign load bearing column grid lines',
    };

    const res = await testRequest(env, '/api/projects/request-correction', {
      method: 'POST',
      token: 'admin-1',
      body: correctionPayload,
    });
    assert.equal(res.status, 200);
    const data = await res.json();
    assert.equal(data.success, true);
    assert.equal(data.newRound, 1);

    // Verify correction record in database
    const corr = rawDb.prepare('SELECT * FROM corrections WHERE id = ?').get('corr-001');
    assert.equal(corr.round_number, 1);
    assert.equal(corr.description, '[PIN:0.3540,0.6820] Realign load bearing column grid lines');
    assert.equal(corr.status, 'OPEN');

    // Verify project transitioned to IN_PROGRESS
    const project = rawDb.prepare('SELECT status, correction_round FROM projects WHERE id = ?').get('prj-review-001');
    assert.equal(project.status, 'IN_PROGRESS');
    assert.equal(project.correction_round, 1);
  });

  await t.test('6. POST /api/projects/:projectId/comments - Validates attachment_file_id and persists reference', async () => {
    // Seed a completed file
    rawDb.exec(`
      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES ('file-voice-001', 'prj-review-001', 'eng-1', 'voice_note_123.m4a', 'voice_note_123.m4a', 'projects/prj-review-001/chat/voice_note_123.m4a', 'audio/mp4', 145000, 'chat_attachment', 'COMPLETED');
    `);

    const commentPayload = {
      content: 'Please listen to the column grid realignment instruction voice note.',
      attachment_file_id: 'file-voice-001',
    };

    const res = await testRequest(env, '/api/projects/prj-review-001/comments', {
      method: 'POST',
      token: 'admin-1',
      body: commentPayload,
    });
    assert.equal(res.status, 201);
    const data = await res.json();
    assert.equal(data.success, true);
    assert.equal(data.comment.attachment_file_id, 'file-voice-001');
    assert.equal(data.comment.attachment_name, 'voice_note_123.m4a');
    assert.equal(data.comment.attachment_type, 'audio/mp4');

    // Verify query through GET /api/projects/:projectId/comments
    const getRes = await testRequest(env, '/api/projects/prj-review-001/comments', {
      method: 'GET',
      token: 'admin-1',
    });
    assert.equal(getRes.status, 200);
    const comments = await getRes.json();
    const voiceComment = comments.find(c => c.attachment_file_id === 'file-voice-001');
    assert.ok(voiceComment);
    assert.equal(voiceComment.attachment_name, 'voice_note_123.m4a');
    assert.equal(voiceComment.attachment_type, 'audio/mp4');
  });

  await t.test('7. POST /api/projects/:projectId/comments - Rejects invalid or uncompleted attachment_file_id with 400', async () => {
    const invalidPayload = {
      content: 'Comment with bogus attachment',
      attachment_file_id: 'file-nonexistent-999',
    };

    const res = await testRequest(env, '/api/projects/prj-review-001/comments', {
      method: 'POST',
      token: 'admin-1',
      body: invalidPayload,
    });
    assert.equal(res.status, 400);
    const data = await res.json();
    assert.equal(data.code, 'INVALID_ATTACHMENT');
  });

  await t.test('8. GET /api/admin/dashboard - Exposes authoritative counts matching Worker schema', async () => {
    const res = await testRequest(env, '/api/admin/dashboard', {
      method: 'GET',
      token: 'admin-1',
    });
    assert.equal(res.status, 200);
    const data = await res.json();

    assert.equal(typeof data.totalProjects, 'number');
    assert.equal(typeof data.activeProjects, 'number');
    assert.equal(typeof data.projectsAwaitingAssignment, 'number');
    assert.equal(typeof data.projectsUnderClientReview, 'number');
    assert.equal(typeof data.completedProjects, 'number');
    assert.equal(typeof data.activeDraughtsmen, 'number');
    assert.equal(typeof data.pendingAssignments, 'number');
  });
});
