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

const bundlePath = path.join(workerRoot, 'node_modules', '.test_app_unlimited_cap_bundle.mjs');
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
    headers['Authorization'] = `Bearer mock-token:${options.token || 'admin-1'}`;
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
    VALUES ('doc-terms-cap', 'TERMS_AND_CONDITIONS', '1.0.0', 'Platform Terms', '# Terms', CURRENT_TIMESTAMP, 'EFFECTIVE', 1, 'en-IN')
  `).run();

  const insertEvent = rawDb.prepare(`
    INSERT INTO legal_consent_events (id, user_id, document_id, document_type, document_version, action_type, consent_purpose, idempotency_key, ip_hash, source)
    VALUES (?, ?, 'doc-terms-cap', 'TERMS_AND_CONDITIONS', '1.0.0', 'ACCEPT', 'DEFAULT', ?, 'hash-ip', 'WEB_APP')
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

test('Draughtsman Unlimited Multi-Project Capacity Suite', async (t) => {
  const { rawDb, env } = createIsolatedTestDb();

  rawDb.prepare(`
    INSERT OR REPLACE INTO users (id, email, role, name, status)
    VALUES
      ('eng-client', 'client@firm.com', 'ENGINEER', 'Edward Engineer', 'ACTIVE'),
      ('admin-1', 'admin@archidraft.com', 'STUDIO_ADMIN', 'Studio QC Admin', 'ACTIVE'),
      ('draughtsman-multi', 'dm_multi@archidraft.com', 'DRAUGHTSMAN', 'Senior Draftsman Multi', 'ACTIVE')
  `).run();

  seedBaselineConsent(rawDb, ['eng-client', 'admin-1', 'draughtsman-multi']);

  // Create 7 projects in WAITING_ASSIGNMENT status
  for (let i = 1; i <= 7; i++) {
    rawDb.prepare(`
      INSERT INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status)
      VALUES (?, 'eng-client', ?, '123 Main St', 'Plan', 'Architectural', '2500', 'WAITING_ASSIGNMENT')
    `).run(`proj-multi-${i}`, `Multi Project ${i}`);
  }

  await t.test('1. Admin sequentially assigns 1st through 7th project to the same Draughtsman', async () => {
    for (let i = 1; i <= 7; i++) {
      const res = await testRequest(env, '/api/projects/assign', {
        method: 'POST',
        token: 'admin-1',
        body: {
          projectId: `proj-multi-${i}`,
          draughtsmanId: 'draughtsman-multi',
          actionId: `action-assign-${i}`
        }
      });
      assert.equal(res.status, 200, `Assignment of project ${i} must succeed without capacity limit`);
      const body = await res.json();
      assert.equal(body.success, true);
      assert.ok(body.assignmentId);
    }

    // Verify all 7 projects are now WAITING_ACCEPTANCE with draughtsman-multi
    const assignedCount = rawDb.prepare(`
      SELECT COUNT(*) as count
      FROM projects
      WHERE draughtsman_id = 'draughtsman-multi' AND status = 'WAITING_ACCEPTANCE'
    `).get();
    assert.equal(assignedCount.count, 7, 'All 7 projects must be assigned to draughtsman-multi');
  });

  await t.test('2. Reassigning an 8th project to the same Draughtsman succeeds', async () => {
    rawDb.prepare(`
      INSERT INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, draughtsman_id, draughtsman_name)
      VALUES ('proj-multi-8', 'eng-client', 'Multi Project 8', '123 Main St', 'Plan', 'Architectural', '2500', 'IN_PROGRESS', 'draughtsman-other', 'Other Draughtsman')
    `).run();

    const res = await testRequest(env, '/api/projects/reassign', {
      method: 'POST',
      token: 'admin-1',
      body: {
        projectId: 'proj-multi-8',
        draughtsmanId: 'draughtsman-multi',
        actionId: 'action-reassign-8'
      }
    });
    assert.equal(res.status, 200, 'Reassignment to draughtsman with 7 active projects must succeed');
    const body = await res.json();
    assert.equal(body.success, true);
  });

  await t.test('3. Idempotent retry of existing assignment succeeds', async () => {
    const res = await testRequest(env, '/api/projects/assign', {
      method: 'POST',
      token: 'admin-1',
      body: {
        projectId: 'proj-multi-1',
        draughtsmanId: 'draughtsman-multi',
        actionId: 'action-assign-1'
      }
    });
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.success, true);
  });

  await t.test('4. Non-admin is forbidden from assigning (403)', async () => {
    const res = await testRequest(env, '/api/projects/assign', {
      method: 'POST',
      token: 'eng-client',
      body: {
        projectId: 'proj-multi-1',
        draughtsmanId: 'draughtsman-multi',
        actionId: 'action-assign-unauth'
      }
    });
    assert.equal(res.status, 403);
  });
});

