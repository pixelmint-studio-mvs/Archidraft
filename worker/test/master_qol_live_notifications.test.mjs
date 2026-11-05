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

const bundlePath = path.join(workerRoot, 'node_modules', '.test_app_qol_notifications_bundle.mjs');
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
      } catch (err) {
        db.exec('ROLLBACK');
        throw err;
      }
    },
    async exec(sql) {
      return db.exec(sql);
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
  rawDb.exec(`
    INSERT INTO users (id, email, name, role, status) VALUES 
      ('eng-1', 'engineer@client.com', 'Edward Engineer', 'ENGINEER', 'ACTIVE'),
      ('drg-1', 'draughtsman@archidraft.com', 'David Draughtsman', 'DRAUGHTSMAN', 'ACTIVE'),
      ('drg-2', 'draughtsman2@archidraft.com', 'Diana Draughtsman', 'DRAUGHTSMAN', 'ACTIVE'),
      ('adm-1', 'admin@archidraft.com', 'Sarah Studio Admin', 'STUDIO_ADMIN', 'ACTIVE');
  `);

  rawDb.prepare(`
    INSERT INTO legal_documents (id, document_type, version, title, content, effective_at, status, is_mandatory, locale)
    VALUES ('doc-terms-qol', 'TERMS_AND_CONDITIONS', '1.0.0', 'Platform Terms', '# Terms', CURRENT_TIMESTAMP, 'EFFECTIVE', 1, 'en-IN')
  `).run();

  const insertEvent = rawDb.prepare(`
    INSERT INTO legal_consent_events (id, user_id, document_id, document_type, document_version, action_type, consent_purpose, idempotency_key, ip_hash, source)
    VALUES (?, ?, 'doc-terms-qol', 'TERMS_AND_CONDITIONS', '1.0.0', 'ACCEPT', 'DEFAULT', ?, 'hash-ip', 'WEB_APP')
  `);

  const insertConsent = rawDb.prepare(`
    INSERT INTO user_consent_state (id, user_id, consent_type, purpose_tag, current_status, accepted_version, last_event_id, updated_at)
    VALUES (?, ?, 'TERMS', 'DEFAULT', 'ACCEPTED', '1.0.0', ?, CURRENT_TIMESTAMP)
  `);

  for (const uid of ['eng-1', 'drg-1', 'drg-2', 'adm-1']) {
    const eventId = 'evt-terms-' + uid;
    insertEvent.run(eventId, uid, 'idem-' + uid);
    insertConsent.run('cst-' + uid, uid, eventId);
  }
}

async function testRequest(env, path, options = {}) {
  const headers = { ...options.headers };
  if (options.token !== null && !headers['Authorization'] && !headers['authorization']) {
    headers['Authorization'] = `Bearer mock-token:${options.token || 'adm-1'}`;
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

test('Master QoL & Notification Architecture — Comprehensive Lifecycle Suite', async (t) => {
  const { rawDb, env } = createIsolatedTestDb();
  seedBaselineData(rawDb);

  const projectId = 'prj-qol-001';

  await t.test('1. Engineer submits project brief -> Admin receives notification with project name', async () => {
    // Create draft project
    const createRes = await testRequest(env, '/api/projects', {
      method: 'POST',
      token: 'eng-1',
      body: {
        id: projectId,
        projectName: 'Skyline Tower',
        drawingName: 'GROUND FLOOR',
        drawingType: 'FLOOR_PLAN',
        projectAddress: '100 Main St',
        projectArea: '5000',
      },
    });
    assert.equal(createRes.status, 200);

    // Submit project brief
    const res = await testRequest(env, '/api/projects/submit', {
      method: 'POST',
      token: 'eng-1',
      body: { projectId, actionId: 'act-submit-1' },
    });
    assert.equal(res.status, 200);

    // Verify Admin receives notification
    const adminNotifsRes = await testRequest(env, '/api/notifications', { token: 'adm-1' });
    assert.equal(adminNotifsRes.status, 200);
    const adminNotifs = await adminNotifsRes.json();
    assert.ok(adminNotifs.length > 0);
    const briefNotif = adminNotifs.find((n) => n.type === 'PROJECT_SUBMITTED');
    assert.ok(briefNotif, 'Admin must receive PROJECT_SUBMITTED notification');
    assert.equal(briefNotif.project_id, projectId);
    assert.ok(briefNotif.message.includes('Skyline Tower'));
  });

  await t.test('2. Admin approves project to ready -> Admin receives PROJECT_READY_FOR_ASSIGNMENT notification', async () => {
    const res = await testRequest(env, '/api/projects/approve', {
      method: 'POST',
      token: 'adm-1',
      body: { projectId, actionId: 'act-approve-ready-1' },
    });
    assert.equal(res.status, 200);

    const adminNotifsRes = await testRequest(env, '/api/notifications', { token: 'adm-1' });
    const adminNotifs = await adminNotifsRes.json();
    const readyNotif = adminNotifs.find((n) => n.type === 'PROJECT_READY_FOR_ASSIGNMENT');
    assert.ok(readyNotif, 'Admin must receive PROJECT_READY_FOR_ASSIGNMENT notification');
    assert.ok(readyNotif.message.includes('Skyline Tower'));
  });

  await t.test('3. Admin assigns Draughtsman -> Draughtsman receives NEW_ASSIGNMENT notification', async () => {
    const res = await testRequest(env, '/api/projects/assign', {
      method: 'POST',
      token: 'adm-1',
      body: { projectId, draughtsmanId: 'drg-1', actionId: 'act-assign-1' },
    });
    assert.equal(res.status, 200);

    const dNotifsRes = await testRequest(env, '/api/notifications', { token: 'drg-1' });
    const dNotifs = await dNotifsRes.json();
    const assignNotif = dNotifs.find((n) => n.type === 'NEW_ASSIGNMENT' || n.type === 'DRAUGHTSMAN_ASSIGNED');
    assert.ok(assignNotif, 'Draughtsman must receive assignment notification');
    assert.equal(assignNotif.project_id, projectId);
    assert.ok(assignNotif.message.includes('Skyline Tower'));
  });

  await t.test('4. Draughtsman accepts assignment -> Engineer and Admin receive ASSIGNMENT_ACCEPTED notifications', async () => {
    const res = await testRequest(env, '/api/assignments/accept', {
      method: 'POST',
      token: 'drg-1',
      body: { projectId, actionId: 'act-accept-1' },
    });
    assert.equal(res.status, 200);

    // Check Engineer
    const engNotifsRes = await testRequest(env, '/api/notifications', { token: 'eng-1' });
    const engNotifs = await engNotifsRes.json();
    const engAcceptNotif = engNotifs.find((n) => n.type === 'ASSIGNMENT_ACCEPTED');
    assert.ok(engAcceptNotif, 'Engineer must be notified when Draughtsman accepts assignment');
    assert.ok(engAcceptNotif.message.includes('Skyline Tower'));

    // Check Admin
    const adminNotifsRes = await testRequest(env, '/api/notifications', { token: 'adm-1' });
    const adminNotifs = await adminNotifsRes.json();
    const adminAcceptNotif = adminNotifs.find((n) => n.type === 'ASSIGNMENT_ACCEPTED');
    assert.ok(adminAcceptNotif, 'Admin must be notified when Draughtsman accepts assignment');
  });

  await t.test('5. Draughtsman submits drawing -> Admin receives DRAWING_SUBMITTED_FOR_ADMIN; Engineer is NOT exposed', async () => {
    // Create draft file
    const fileId = 'file-draw-v1';
    rawDb.prepare(`
      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES (?, ?, ?, 'drawing_v1.dwg', 'drawing_v1.dwg', 'projects/prj-qol-001/workspace_draft/drawing_v1.dwg', 'application/acad', 1024, 'workspace_draft', 'COMPLETED')
    `).run(fileId, projectId, 'drg-1');

    const res = await testRequest(env, '/api/projects/submit-drawing', {
      method: 'POST',
      token: 'drg-1',
      body: { projectId, draftFileId: fileId, actionId: 'act-submit-dwg-1' },
    });
    assert.equal(res.status, 200);

    // Verify Admin notification
    const adminNotifsRes = await testRequest(env, '/api/notifications', { token: 'adm-1' });
    const adminNotifs = await adminNotifsRes.json();
    const dwgNotif = adminNotifs.find((n) => n.type === 'DRAWING_SUBMITTED_FOR_ADMIN');
    assert.ok(dwgNotif, 'Admin must receive DRAWING_SUBMITTED_FOR_ADMIN');
    assert.ok(dwgNotif.message.includes('Skyline Tower'));

    // Verify Engineer does NOT receive unapproved drawing notification
    const engNotifsRes = await testRequest(env, '/api/notifications', { token: 'eng-1' });
    const engNotifs = await engNotifsRes.json();
    const leak = engNotifs.find((n) => n.type === 'DRAWING_SUBMITTED_FOR_ADMIN' || n.type === 'DRAWING_READY_FOR_REVIEW');
    assert.equal(leak, undefined, 'Engineer must not receive unapproved drawing notification');
  });

  await t.test('6. Admin requests revision with feedback -> Draughtsman notified; Engineer receives ZERO internal QC notes', async () => {
    const dv = rawDb.prepare('SELECT id FROM drawing_versions WHERE project_id = ? AND version_number = 1').get(projectId);
    assert.ok(dv);

    const res = await testRequest(env, '/api/projects/admin-request-revision', {
      method: 'POST',
      token: 'adm-1',
      body: {
        projectId,
        drawingVersionId: dv.id,
        feedback: 'Fix line weights on column grid',
        actionId: 'act-req-rev-1',
      },
    });
    assert.equal(res.status, 200);

    // Draughtsman receives notification with feedback
    const dNotifsRes = await testRequest(env, '/api/notifications', { token: 'drg-1' });
    const dNotifs = await dNotifsRes.json();
    const revNotif = dNotifs.find((n) => n.type === 'ADMIN_REVISION_REQUESTED');
    assert.ok(revNotif, 'Draughtsman must receive ADMIN_REVISION_REQUESTED');
    assert.ok(revNotif.message.includes('Fix line weights on column grid'));
    assert.ok(revNotif.message.includes('Skyline Tower'));

    // Engineer must NEVER receive this internal rework notification
    const engNotifsRes = await testRequest(env, '/api/notifications', { token: 'eng-1' });
    const engNotifs = await engNotifsRes.json();
    const leak = engNotifs.find((n) => n.type === 'ADMIN_REVISION_REQUESTED');
    assert.equal(leak, undefined, 'Engineer must never receive internal QC revision notification');
  });

  await t.test('7. Draughtsman resubmits corrected drawing -> Admin receives DRAWING_RESUBMITTED_FOR_ADMIN', async () => {
    const fileId2 = 'file-draw-v2';
    rawDb.prepare(`
      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES (?, ?, ?, 'drawing_v2.dwg', 'drawing_v2.dwg', 'projects/prj-qol-001/workspace_draft/drawing_v2.dwg', 'application/acad', 2048, 'workspace_draft', 'COMPLETED')
    `).run(fileId2, projectId, 'drg-1');

    const res = await testRequest(env, '/api/projects/submit-drawing', {
      method: 'POST',
      token: 'drg-1',
      body: { projectId, draftFileId: fileId2, actionId: 'act-resubmit-dwg-2' },
    });
    assert.equal(res.status, 200);

    const adminNotifsRes = await testRequest(env, '/api/notifications', { token: 'adm-1' });
    const adminNotifs = await adminNotifsRes.json();
    const resubmitNotif = adminNotifs.find((n) => n.type === 'DRAWING_RESUBMITTED_FOR_ADMIN');
    assert.ok(resubmitNotif, 'Admin must receive DRAWING_RESUBMITTED_FOR_ADMIN');
    assert.ok(resubmitNotif.message.includes('Skyline Tower'));
  });

  await t.test('8. Admin approves drawing -> Engineer and Draughtsman receive notifications with project name', async () => {
    const dv2 = rawDb.prepare('SELECT id FROM drawing_versions WHERE project_id = ? AND version_number = 2').get(projectId);
    assert.ok(dv2);

    const res = await testRequest(env, '/api/projects/admin-approve-drawing', {
      method: 'POST',
      token: 'adm-1',
      body: {
        projectId,
        drawingVersionId: dv2.id,
        notes: 'Passed all Studio QC checks',
        actionId: 'act-appr-dwg-2',
      },
    });
    assert.equal(res.status, 200);

    // Engineer receives DRAWING_READY_FOR_REVIEW
    const engNotifsRes = await testRequest(env, '/api/notifications', { token: 'eng-1' });
    const engNotifs = await engNotifsRes.json();
    const readyNotif = engNotifs.find((n) => n.type === 'DRAWING_READY_FOR_REVIEW');
    assert.ok(readyNotif, 'Engineer must receive DRAWING_READY_FOR_REVIEW notification');
    assert.ok(readyNotif.message.includes('Skyline Tower'));

    // Draughtsman receives ADMIN_DRAWING_APPROVED
    const dNotifsRes = await testRequest(env, '/api/notifications', { token: 'drg-1' });
    const dNotifs = await dNotifsRes.json();
    const approvedNotif = dNotifs.find((n) => n.type === 'ADMIN_DRAWING_APPROVED');
    assert.ok(approvedNotif, 'Draughtsman must receive ADMIN_DRAWING_APPROVED notification');
    assert.ok(approvedNotif.message.includes('Skyline Tower'));
  });

  await t.test('9. Engineer requests correction -> Draughtsman and Admin receive notifications with round', async () => {
    const dv2 = rawDb.prepare('SELECT id FROM drawing_versions WHERE project_id = ? AND version_number = 2').get(projectId);

    const res = await testRequest(env, '/api/projects/request-correction', {
      method: 'POST',
      token: 'eng-1',
      body: {
        projectId,
        targetVersionId: dv2.id,
        description: 'Expand entrance lobby width by 1.5m',
        actionId: 'act-corr-1',
      },
    });
    assert.equal(res.status, 200);

    // Draughtsman receives CORRECTION_REQUESTED
    const dNotifsRes = await testRequest(env, '/api/notifications', { token: 'drg-1' });
    const dNotifs = await dNotifsRes.json();
    const corrNotif = dNotifs.find((n) => n.type === 'CORRECTION_REQUESTED');
    assert.ok(corrNotif, 'Draughtsman must receive CORRECTION_REQUESTED');
    assert.ok(corrNotif.message.includes('Round 1'));
    assert.ok(corrNotif.message.includes('Skyline Tower'));

    // Admin receives CORRECTION_REQUESTED
    const adminNotifsRes = await testRequest(env, '/api/notifications', { token: 'adm-1' });
    const adminNotifs = await adminNotifsRes.json();
    const adminCorrNotif = adminNotifs.find((n) => n.type === 'CORRECTION_REQUESTED');
    assert.ok(adminCorrNotif, 'Admin must receive CORRECTION_REQUESTED');
    assert.ok(adminCorrNotif.message.includes('Round 1'));
  });

  await t.test('10. Notification lifecycle: mark read, dismiss single, clear all (isolated per user)', async () => {
    // Get Draughtsman 1 notifications
    const d1Res = await testRequest(env, '/api/notifications', { token: 'drg-1' });
    const d1List = await d1Res.json();
    assert.ok(d1List.length >= 2);

    const firstNotif = d1List[0];
    assert.equal(firstNotif.is_read, 0);

    // Mark single notification read
    const readRes = await testRequest(env, `/api/notifications/${firstNotif.id}/read`, { method: 'POST', token: 'drg-1' });
    assert.equal(readRes.status, 200);

    // Dismiss single notification via POST /dismiss
    const secondNotif = d1List[1];
    const dismissRes = await testRequest(env, `/api/notifications/${secondNotif.id}/dismiss`, { method: 'POST', token: 'drg-1' });
    assert.equal(dismissRes.status, 200);

    // Draughtsman 2 should NOT have Draughtsman 1's notifications
    const d2Res = await testRequest(env, '/api/notifications', { token: 'drg-2' });
    const d2List = await d2Res.json();
    assert.equal(d2List.length, 0);

    // Draughtsman 1 clears all notifications
    const clearRes = await testRequest(env, '/api/notifications/clear', { method: 'POST', token: 'drg-1' });
    assert.equal(clearRes.status, 200);

    // Verify Draughtsman 1 has 0 notifications
    const d1AfterRes = await testRequest(env, '/api/notifications', { token: 'drg-1' });
    const d1After = await d1AfterRes.json();
    assert.equal(d1After.length, 0);

    // Verify Admin notifications were NOT deleted by Draughtsman's clear
    const adminCheckRes = await testRequest(env, '/api/notifications', { token: 'adm-1' });
    const adminCheck = await adminCheckRes.json();
    assert.ok(adminCheck.length > 0, 'Admin notifications must remain intact when another user clears their feed');
  });
});
