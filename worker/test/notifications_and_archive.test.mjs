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

if (!globalThis.FixedLengthStream) {
  globalThis.FixedLengthStream = class FixedLengthStream extends TransformStream {
    constructor(expectedLength) {
      super();
      this.expectedLength = expectedLength;
    }
  };
}

const bundlePath = path.join(workerRoot, 'node_modules', '.test_app_notifications_archive_bundle.mjs');
esbuild.buildSync({
  entryPoints: [path.join(workerRoot, 'src', 'index.ts')],
  bundle: true,
  format: 'esm',
  platform: 'node',
  write: true,
  outfile: bundlePath,
});

const { default: app } = await import(`file://${bundlePath}`);

function createTestDb() {
  const db = new DatabaseSync(':memory:');
  const migrationsDir = path.join(workerRoot, 'migrations');
  // Exclude 0021_project_archives.sql so test strictly mirrors remote staging schema without 0021
  const migrationFiles = fs.readdirSync(migrationsDir)
    .filter(f => f.endsWith('.sql') && !f.includes('0021'))
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
      for (const s of statements) {
        await s.run();
      }
      return [];
    },
    async exec(sql) {
      db.exec(sql);
      return { count: 0, duration: 0 };
    }
  };

  return { rawDb: db, d1 };
}

function makeEnv(d1) {
  return {
    DB: d1,
    ENVIRONMENT: 'test',
    JWT_SECRET: 'test-secret-at-least-32-chars-long-for-testing',
    R2: {
      get: async () => null,
      put: async () => {},
      delete: async () => {},
    },
  };
}

function authHeader(uid) {
  return {
    Authorization: `Bearer mock-token:${uid}`,
  };
}

test('Notifications Clearing & Project Removal Suite (No Archive Dependency)', async (t) => {
  const { rawDb, d1 } = createTestDb();
  const env = makeEnv(d1);

  // Seed users
  rawDb.exec(`
    INSERT INTO users (id, email, name, role) VALUES
      ('admin-1', 'admin@example.com', 'Admin User', 'ADMIN'),
      ('draught-1', 'draught1@example.com', 'Draughtsman 1', 'DRAUGHTSMAN'),
      ('draught-2', 'draught2@example.com', 'Draughtsman 2', 'DRAUGHTSMAN'),
      ('client-1', 'client@example.com', 'Client Engineer', 'ENGINEER');
  `);

  // Seed terms accepted
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

  for (const uid of ['admin-1', 'draught-1', 'draught-2', 'client-1']) {
    const eventId = 'evt-terms-' + uid;
    insertEvent.run(eventId, uid, 'idem-' + uid);
    insertConsent.run('cst-' + uid, uid, eventId);
  }

  await t.test('1. Clear notifications deletes only the caller notifications (tenant isolation)', async () => {
    // Seed notifications for draught-1 and draught-2
    rawDb.exec(`
      INSERT INTO notifications (id, user_id, type, title, message) VALUES
        ('notif-1', 'draught-1', 'PROJECT_APPROVED', 'N1', 'Msg 1'),
        ('notif-2', 'draught-1', 'CORRECTION_REQUESTED', 'N2', 'Msg 2'),
        ('notif-3', 'draught-2', 'CHAT_MESSAGE', 'N3', 'Msg 3');
    `);

    // Draughtsman 1 clears their notifications
    const res = await app.request('/api/notifications', {
      method: 'DELETE',
      headers: authHeader('draught-1'),
    }, env);
    assert.equal(res.status, 200);

    // Verify draught-1 notifications are empty
    const check1 = await app.request('/api/notifications', {
      method: 'GET',
      headers: authHeader('draught-1'),
    }, env);
    const list1 = await check1.json();
    assert.equal(list1.length, 0, 'Draughtsman 1 notifications must be cleared');

    // Verify draught-2 notification still intact (tenant isolation)
    const check2 = await app.request('/api/notifications', {
      method: 'GET',
      headers: authHeader('draught-2'),
    }, env);
    const list2 = await check2.json();
    assert.equal(list2.length, 1, 'Draughtsman 2 notification must remain intact');
    assert.equal(list2[0].id, 'notif-3');
  });

  await t.test('2. Projects and assignments endpoints work without migration 0021 and completed projects are visible', async () => {
    rawDb.exec(`
      INSERT INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, draughtsman_id)
      VALUES
        ('p-completed-1', 'client-1', 'Completed Villa', 'Addr 1', 'D1', 'ARCHITECTURAL', '250m2', 'COMPLETED', 'draught-1'),
        ('p-active-1', 'client-1', 'Active Building', 'Addr 2', 'D2', 'STRUCTURAL', '500m2', 'IN_PROGRESS', 'draught-1');
      INSERT INTO assignments (id, project_id, draughtsman_id, status)
      VALUES ('a-1', 'p-completed-1', 'draught-1', 'COMPLETED');
    `);

    // Admin project listing returns all projects including completed projects
    const adminProjectsRes = await app.request('/api/projects', {
      method: 'GET',
      headers: authHeader('admin-1'),
    }, env);
    assert.equal(adminProjectsRes.status, 200);
    const adminProjects = await adminProjectsRes.json();
    assert.equal(adminProjects.length, 2);
    assert.ok(adminProjects.some(p => p.id === 'p-completed-1' && p.status === 'COMPLETED'));

    // Draughtsman project listing returns assigned projects
    const dProjectsRes = await app.request('/api/projects', {
      method: 'GET',
      headers: authHeader('draught-1'),
    }, env);
    assert.equal(dProjectsRes.status, 200);
    const dProjects = await dProjectsRes.json();
    assert.equal(dProjects.length, 2);

    // Draughtsman assignments listing works without schema errors
    const dAssignRes = await app.request('/api/assignments', {
      method: 'GET',
      headers: authHeader('draught-1'),
    }, env);
    assert.equal(dAssignRes.status, 200);
    const dAssign = await dAssignRes.json();
    assert.equal(dAssign.length, 1);
    assert.equal(dAssign[0].id, 'a-1');
    assert.equal(dAssign[0].project_status, 'COMPLETED');
  });

  await t.test('3. Project archive and restore endpoints are completely removed (404)', async () => {
    const archRes = await app.request('/api/projects/p-completed-1/archive', {
      method: 'POST',
      headers: authHeader('admin-1'),
    }, env);
    assert.equal(archRes.status, 404, 'Archive endpoint must return 404');

    const restRes = await app.request('/api/projects/p-completed-1/restore', {
      method: 'POST',
      headers: authHeader('admin-1'),
    }, env);
    assert.equal(restRes.status, 404, 'Restore endpoint must return 404');
  });

  await t.test('4. DELETE /api/projects/:id safely removes project and cascades cleanly without archive dependencies', async () => {
    // Seed target project with related child records
    rawDb.exec(`
      INSERT INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, draughtsman_id)
      VALUES
        ('p-delete-target', 'client-1', 'Target Project', 'Addr', 'D-T', 'ARCHITECTURAL', '100m2', 'DRAFT', NULL),
        ('p-preserve-untouched', 'client-1', 'Keep Me Project', 'Addr', 'D-K', 'ARCHITECTURAL', '100m2', 'DRAFT', NULL);
      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category)
      VALUES ('f-1', 'p-delete-target', 'admin-1', 'plan.dwg', 'plan.dwg', 'path/plan.dwg', 'application/acad', 1024, 'CAD');
      INSERT INTO project_messages (id, project_id, sender_id, sender_name, sender_role, message)
      VALUES ('m-1', 'p-delete-target', 'admin-1', 'Admin User', 'ADMIN', 'Initial kick-off');
    `);

    // Non-admin attempt must be rejected (403)
    const forbiddenRes = await app.request('/api/projects/p-delete-target', {
      method: 'DELETE',
      headers: authHeader('draught-1'),
    }, env);
    assert.equal(forbiddenRes.status, 403, 'Non-admin must not delete projects');

    // Admin deletion of target project
    const delRes = await app.request('/api/projects/p-delete-target', {
      method: 'DELETE',
      headers: authHeader('admin-1'),
    }, env);
    assert.equal(delRes.status, 200);
    const delData = await delRes.json();
    assert.equal(delData.success, true);
    assert.equal(delData.removedProjectId, 'p-delete-target');

    // Verify target project is removed
    const checkTarget = await app.request('/api/projects/p-delete-target', {
      method: 'GET',
      headers: authHeader('admin-1'),
    }, env);
    assert.equal(checkTarget.status, 404, 'Deleted project must return 404');

    // Verify cascaded records in files and messages are cleaned up
    const fCount = rawDb.prepare('SELECT count(*) as c FROM files WHERE project_id = ?').get('p-delete-target');
    assert.equal(fCount.c, 0, 'Related files must be deleted');

    // Verify untouched project is strictly intact
    const checkUntouched = await app.request('/api/projects/p-preserve-untouched', {
      method: 'GET',
      headers: authHeader('admin-1'),
    }, env);
    assert.equal(checkUntouched.status, 200, 'Untouched project must remain fully accessible');
  });
});
