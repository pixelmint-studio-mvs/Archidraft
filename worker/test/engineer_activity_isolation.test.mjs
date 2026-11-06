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

const bundlePath = path.join(workerRoot, 'node_modules', '.test_app_activity_bundle.mjs');
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

function seedBaselineConsent(rawDb, uids) {
  rawDb.prepare(`
    INSERT OR REPLACE INTO legal_documents (id, document_type, version, title, content, effective_at, status, is_mandatory, locale)
    VALUES ('doc-terms-iso', 'TERMS_AND_CONDITIONS', '1.0.0', 'Platform Terms', '# Terms', CURRENT_TIMESTAMP, 'EFFECTIVE', 1, 'en-IN')
  `).run();

  const insertEvent = rawDb.prepare(`
    INSERT INTO legal_consent_events (id, user_id, document_id, document_type, document_version, action_type, consent_purpose, idempotency_key, ip_hash, source)
    VALUES (?, ?, 'doc-terms-iso', 'TERMS_AND_CONDITIONS', '1.0.0', 'ACCEPT', 'DEFAULT', ?, 'hash-ip', 'WEB_APP')
  `);

  const insertConsent = rawDb.prepare(`
    INSERT OR REPLACE INTO user_consent_state (id, user_id, consent_type, purpose_tag, current_status, accepted_version, last_event_id, updated_at)
    VALUES (?, ?, 'TERMS', 'DEFAULT', 'ACCEPTED', '1.0.0', ?, CURRENT_TIMESTAMP)
  `);

  for (const uid of uids) {
    const eventId = 'evt-terms-' + uid;
    insertEvent.run(eventId, uid, 'idem-' + uid);
    insertConsent.run('cst-' + uid, uid, eventId);
  }
}

test('Engineer Activity Feed Isolation & Internal QC Protection Suite', async (t) => {
  const { rawDb, env } = createIsolatedTestDb();

  // 1. Seed two Engineers, an Admin, and a Draughtsman
  rawDb.prepare(`
    INSERT OR REPLACE INTO users (id, email, role, name, status)
    VALUES
      ('eng-alice', 'alice@firm.com', 'ENGINEER', 'Alice Architect', 'ACTIVE'),
      ('eng-bob', 'bob@firm.com', 'ENGINEER', 'Bob Builder', 'ACTIVE'),
      ('admin-qc', 'admin@archidraft.com', 'STUDIO_ADMIN', 'Studio QC Admin', 'ACTIVE'),
      ('draughtsman-1', 'dm1@archidraft.com', 'DRAUGHTSMAN', 'Drafting Pro 1', 'ACTIVE')
  `).run();

  seedBaselineConsent(rawDb, ['eng-alice', 'eng-bob', 'admin-qc', 'draughtsman-1']);

  // 2. Seed Project A (owned by Alice) and Project B (owned by Bob)
  rawDb.prepare(`
    INSERT OR REPLACE INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, draughtsman_id, draughtsman_name)
    VALUES
      ('proj-alice-1', 'eng-alice', 'Alice Skyline Tower', '100 Market St', 'Floor Plan', 'Architectural', '5000', 'IN_PROGRESS', 'draughtsman-1', 'Drafting Pro 1'),
      ('proj-bob-1', 'eng-bob', 'Bob Harbor Bridge', '200 Waterfront Ave', 'Pier Elevation', 'Structural', '12000', 'IN_PROGRESS', 'draughtsman-1', 'Drafting Pro 1')
  `).run();

  // 3. Seed activity logs:
  // - Public activities on Alice's project
  // - Internal QC activities on Alice's project (ADMIN_REVISION_REQUESTED, DRAWING_SUBMITTED_FOR_ADMIN)
  // - Activities on Bob's project
  rawDb.prepare(`
    INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details, timestamp)
    VALUES
      ('act-alice-1', 'proj-alice-1', 'PROJECT_SUBMITTED', 'eng-alice', 'ENGINEER', 'Alice submitted project brief.', '2026-11-04 10:00:00'),
      ('act-alice-2', 'proj-alice-1', 'DRAUGHTSMAN_ASSIGNED', 'admin-qc', 'STUDIO_ADMIN', 'Studio Admin assigned Draughtsman.', '2026-11-04 10:05:00'),
      ('act-alice-3', 'proj-alice-1', 'DRAWING_SUBMITTED_FOR_ADMIN', 'draughtsman-1', 'DRAUGHTSMAN', 'Draughtsman submitted drawing deliverable for Studio QC.', '2026-11-04 10:10:00'),
      ('act-alice-4', 'proj-alice-1', 'ADMIN_REVISION_REQUESTED', 'admin-qc', 'STUDIO_ADMIN', 'Studio Admin requested internal revision: dimension error.', '2026-11-04 10:15:00'),
      ('act-alice-5', 'proj-alice-1', 'ADMIN_DRAWING_APPROVED', 'admin-qc', 'STUDIO_ADMIN', 'Studio Admin approved drawing deliverable for engineer review.', '2026-11-04 10:20:00'),
      ('act-bob-1', 'proj-bob-1', 'PROJECT_SUBMITTED', 'eng-bob', 'ENGINEER', 'Bob submitted project brief.', '2026-11-04 10:01:00'),
      ('act-bob-2', 'proj-bob-1', 'PROJECT_APPROVED', 'admin-qc', 'STUDIO_ADMIN', 'Studio Admin approved project.', '2026-11-04 10:06:00')
  `).run();

  await t.test('1. Alice calls /api/activity -> sees ONLY Alice projects, excludes Bob completely', async () => {
    const res = await testRequest(env, '/api/activity', {
      method: 'GET',
      token: 'eng-alice',
    });
    assert.equal(res.status, 200);
    const logs = await res.json();

    assert.ok(logs.length > 0, 'Alice should have activity logs');
    for (const log of logs) {
      assert.equal(log.project_id, 'proj-alice-1', 'Every activity item must belong to Alice project');
      assert.notEqual(log.project_id, 'proj-bob-1', 'Bob project activity must NEVER appear in Alice feed');
      assert.equal(log.project_name, 'Alice Skyline Tower', 'project_name must be populated on every item');
    }
  });

  await t.test('2. Alice cannot see internal Admin QC notes in /api/activity', async () => {
    const res = await testRequest(env, '/api/activity', {
      method: 'GET',
      token: 'eng-alice',
    });
    assert.equal(res.status, 200);
    const logs = await res.json();

    const actionTypes = logs.map(l => l.action_type);
    assert.ok(!actionTypes.includes('ADMIN_REVISION_REQUESTED'), 'ADMIN_REVISION_REQUESTED must be excluded from Engineer feed');
    assert.ok(!actionTypes.includes('DRAWING_SUBMITTED_FOR_ADMIN'), 'DRAWING_SUBMITTED_FOR_ADMIN must be excluded from Engineer feed');
    assert.ok(actionTypes.includes('PROJECT_SUBMITTED'), 'Public project activity must be present');
    assert.ok(actionTypes.includes('ADMIN_DRAWING_APPROVED'), 'Client-visible release activity must be present');
  });

  await t.test('3. Alice cannot see internal QC notes in /api/projects/:projectId/activity', async () => {
    const res = await testRequest(env, '/api/projects/proj-alice-1/activity', {
      method: 'GET',
      token: 'eng-alice',
    });
    assert.equal(res.status, 200);
    const logs = await res.json();

    const actionTypes = logs.map(l => l.action_type);
    assert.ok(!actionTypes.includes('ADMIN_REVISION_REQUESTED'), 'Project activity must exclude ADMIN_REVISION_REQUESTED for Engineer');
    assert.ok(!actionTypes.includes('DRAWING_SUBMITTED_FOR_ADMIN'), 'Project activity must exclude DRAWING_SUBMITTED_FOR_ADMIN for Engineer');
    for (const log of logs) {
      assert.equal(log.project_name, 'Alice Skyline Tower', 'Project activity item must include project_name');
    }
  });

  await t.test('4. Alice is forbidden from accessing Bob project activity directly (403)', async () => {
    const res = await testRequest(env, '/api/projects/proj-bob-1/activity', {
      method: 'GET',
      token: 'eng-alice',
    });
    assert.equal(res.status, 403, 'Access to another engineer project activity must be forbidden');
  });

  await t.test('5. Admin sees global activity audit stream including internal QC notes', async () => {
    const res = await testRequest(env, '/api/activity', {
      method: 'GET',
      token: 'admin-qc',
    });
    assert.equal(res.status, 200);
    const logs = await res.json();
    const actionTypes = logs.map(l => l.action_type);

    assert.ok(actionTypes.includes('ADMIN_REVISION_REQUESTED'), 'Admin must see internal QC notes');
    assert.ok(actionTypes.includes('DRAWING_SUBMITTED_FOR_ADMIN'), 'Admin must see submissions for admin');
    const projectIds = logs.map(l => l.project_id);
    assert.ok(projectIds.includes('proj-alice-1'), 'Admin sees Alice project');
    assert.ok(projectIds.includes('proj-bob-1'), 'Admin sees Bob project');
  });
});
