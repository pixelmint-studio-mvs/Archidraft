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

const bundlePath = path.join(workerRoot, 'node_modules', '.test_app_bundle_corr_start.mjs');
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
      for (const s of statements) {
        await s.run();
      }
      return [];
    }
  };

  return { rawDb: db, env: { DB: d1, ENVIRONMENT: 'test' } };
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

test('Correction Round Start & Full Lifecycle Suite', async (t) => {
  const { rawDb, env } = createIsolatedTestDb();

  // Seed baseline users
  rawDb.exec(`
    INSERT INTO users (id, email, name, role, status) VALUES
      ('admin-1', 'admin@example.com', 'Admin User', 'STUDIO_ADMIN', 'ACTIVE'),
      ('eng-1', 'eng@example.com', 'Engineer One', 'ENGINEER', 'ACTIVE'),
      ('draughtsman-1', 'dm@example.com', 'Assigned Draughtsman', 'DRAUGHTSMAN', 'ACTIVE'),
      ('draughtsman-other', 'other@example.com', 'Other Draughtsman', 'DRAUGHTSMAN', 'ACTIVE'),
      ('student-1', 'student@example.com', 'Student Draughtsman', 'STUDENT', 'ACTIVE');
  `);

  // Seed legal documents & consent
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

  for (const uid of ['admin-1', 'eng-1', 'draughtsman-1', 'draughtsman-other', 'student-1']) {
    insertEvent.run('evt-' + uid, uid, 'idem-' + uid);
    insertConsent.run('cst-' + uid, uid, 'evt-' + uid);
  }

  // Seed standard commercial project
  rawDb.exec(`
    INSERT INTO projects (id, client_id, draughtsman_id, project_name, project_address, drawing_name, drawing_type, project_area, status, correction_round)
    VALUES ('prj-corr-001', 'eng-1', 'draughtsman-1', 'MVS-1 Test Commercial', '123 Main St', 'Plan 1', 'Architectural', '2500 sqft', 'IN_PROGRESS', 1);

    INSERT INTO assignments (id, project_id, draughtsman_id, status)
    VALUES ('asg-001', 'prj-corr-001', 'draughtsman-1', 'ACCEPTED');

    INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
    VALUES ('file-v1-001', 'prj-corr-001', 'draughtsman-1', 'plan_v1.dxf', 'plan_v1.dxf', 'projects/prj-corr-001/plan_v1.dxf', 'application/dxf', 1024, 'draughtsman_version', 'COMPLETED');

    INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by)
    VALUES ('ver-001', 'prj-corr-001', 'file-v1-001', 1, 'draughtsman-1');

    INSERT INTO corrections (id, project_id, requested_by, target_version_id, round_number, description, status)
    VALUES ('corr-round-1', 'prj-corr-001', 'eng-1', 'ver-001', 1, 'FIX THIS: Adjust column grid', 'OPEN');
  `);

  await t.test('1. Assigned Draughtsman successfully starts correction round (transitions OPEN -> IN_PROGRESS)', async () => {
    const res = await testRequest(env, '/api/projects/prj-corr-001/corrections/corr-round-1/start', {
      method: 'POST',
      token: 'draughtsman-1',
      body: { actionId: 'act-start-001' },
    });
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.success, true);
    assert.equal(body.status, 'IN_PROGRESS');
    assert.equal(body.correctionId, 'corr-round-1');

    // Verify DB update
    const row = rawDb.prepare('SELECT status FROM corrections WHERE id = ?').get('corr-round-1');
    assert.equal(row.status, 'IN_PROGRESS');

    // Verify activity log
    const log = rawDb.prepare("SELECT * FROM activity_logs WHERE action_type = 'CORRECTION_STARTED'").get();
    assert.ok(log);
    assert.equal(log.actor_id, 'draughtsman-1');
  });

  await t.test('2. Idempotent retry returns success without duplicating activity logs', async () => {
    const res = await testRequest(env, '/api/projects/prj-corr-001/corrections/corr-round-1/start', {
      method: 'POST',
      token: 'draughtsman-1',
      body: { actionId: 'act-start-001' },
    });
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.success, true);
    assert.equal(body.status, 'IN_PROGRESS');

    // Verify single activity log exists
    const logs = rawDb.prepare("SELECT * FROM activity_logs WHERE action_type = 'CORRECTION_STARTED'").all();
    assert.equal(logs.length, 1);
  });

  await t.test('3. Unrelated Draughtsman is rejected with 403 Forbidden', async () => {
    const res = await testRequest(env, '/api/projects/prj-corr-001/corrections/corr-round-1/start', {
      method: 'POST',
      token: 'draughtsman-other',
      body: { actionId: 'act-start-other' },
    });
    assert.equal(res.status, 403);
  });

  await t.test('4. Engineer is rejected with 403 Forbidden (only assigned worker/admin can start correction round)', async () => {
    const res = await testRequest(env, '/api/projects/prj-corr-001/corrections/corr-round-1/start', {
      method: 'POST',
      token: 'eng-1',
      body: { actionId: 'act-start-eng' },
    });
    assert.equal(res.status, 403);
  });

  await t.test('5. Non-existent correction returns 404', async () => {
    const res = await testRequest(env, '/api/projects/prj-corr-001/corrections/corr-nonexistent/start', {
      method: 'POST',
      token: 'draughtsman-1',
      body: { actionId: 'act-start-404' },
    });
    assert.equal(res.status, 404);
  });

  await t.test('6. Non-existent project returns 404', async () => {
    const res = await testRequest(env, '/api/projects/prj-nonexistent/corrections/corr-round-1/start', {
      method: 'POST',
      token: 'draughtsman-1',
      body: { actionId: 'act-start-404p' },
    });
    assert.equal(res.status, 404);
  });

  await t.test('7. Subsequent drawing submission links IN_PROGRESS correction and resolves it', async () => {
    // Draughtsman uploads new draft file
    rawDb.exec(`
      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES ('file-v2-002', 'prj-corr-001', 'draughtsman-1', 'plan_v2.dxf', 'plan_v2.dxf', 'projects/prj-corr-001/plan_v2.dxf', 'application/dxf', 2048, 'workspace_draft', 'COMPLETED');
    `);

    const submitRes = await testRequest(env, '/api/projects/submit-drawing', {
      method: 'POST',
      token: 'draughtsman-1',
      body: {
        projectId: 'prj-corr-001',
        actionId: 'act-submit-v2',
        draftFileId: 'file-v2-002',
      },
    });
    assert.equal(submitRes.status, 200);

    // Verify drawing version was created with correction_id linked
    const v2 = rawDb.prepare('SELECT * FROM drawing_versions WHERE version_number = 2').get();
    assert.ok(v2);
    assert.equal(v2.correction_id, 'corr-round-1');

    // Verify correction is now RESOLVED
    const corr = rawDb.prepare('SELECT status, resolved_at FROM corrections WHERE id = ?').get('corr-round-1');
    assert.equal(corr.status, 'RESOLVED');
    assert.ok(corr.resolved_at);

    // Verify project transitioned to UNDER_ENGINEER_REVIEW
    const prj = rawDb.prepare('SELECT status FROM projects WHERE id = ?').get('prj-corr-001');
    assert.equal(prj.status, 'UNDER_ENGINEER_REVIEW');
  });

  await t.test('8. Resolved correction cannot be re-started (400)', async () => {
    const res = await testRequest(env, '/api/projects/prj-corr-001/corrections/corr-round-1/start', {
      method: 'POST',
      token: 'draughtsman-1',
      body: { actionId: 'act-start-resolved' },
    });
    assert.equal(res.status, 400);
    const body = await res.json();
    assert.match(body.error, /already been resolved/i);
  });
});
