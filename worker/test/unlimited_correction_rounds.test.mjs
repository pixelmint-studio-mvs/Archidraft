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

const bundlePath = path.join(workerRoot, 'node_modules', '.test_app_unlimited_correction_rounds_bundle.mjs');
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
      ('adm-1', 'admin@example.com', 'Sarah Admin', 'STUDIO_ADMIN', 'ACTIVE');
  `);

  // Legal consent
  rawDb.prepare(`
    INSERT INTO legal_documents (id, document_type, version, title, content, effective_at, status, is_mandatory, locale)
    VALUES ('doc-terms-unlimited', 'TERMS_AND_CONDITIONS', '1.0.0', 'Platform Terms', '# Terms', CURRENT_TIMESTAMP, 'EFFECTIVE', 1, 'en-IN')
  `).run();

  const insertEvent = rawDb.prepare(`
    INSERT INTO legal_consent_events (id, user_id, document_id, document_type, document_version, action_type, consent_purpose, idempotency_key, ip_hash, source)
    VALUES (?, ?, 'doc-terms-unlimited', 'TERMS_AND_CONDITIONS', '1.0.0', 'ACCEPT', 'DEFAULT', ?, 'hash-ip', 'WEB_APP')
  `);

  const insertConsent = rawDb.prepare(`
    INSERT INTO user_consent_state (id, user_id, consent_type, purpose_tag, current_status, accepted_version, last_event_id, updated_at)
    VALUES (?, ?, 'TERMS', 'DEFAULT', 'ACCEPTED', '1.0.0', ?, CURRENT_TIMESTAMP)
  `);

  for (const uid of ['eng-1', 'drg-1', 'adm-1']) {
    const eventId = 'evt-terms-' + uid;
    insertEvent.run(eventId, uid, 'idem-' + uid);
    insertConsent.run('cst-' + uid, uid, eventId);
  }
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

test('Unlimited Engineer Correction Rounds — Comprehensive Suite', async (t) => {
  const { rawDb, env } = createIsolatedTestDb();
  seedBaselineData(rawDb);

  const projectId = 'proj-unlimited-1';

  // Seed baseline project and assignment
  rawDb.exec(`
    INSERT INTO projects (
      id, client_id, draughtsman_id, project_name, project_address,
      drawing_name, drawing_type, project_area, status, correction_round
    ) VALUES (
      '${projectId}', 'eng-1', 'drg-1', 'Commercial Skyrise', '456 Tech Parkway',
      'Architectural Layout', 'ARCHITECTURAL', '5000 sq ft', 'WAITING_ACCEPTANCE', 0
    );

    INSERT INTO assignments (
      id, project_id, draughtsman_id, status, created_at, updated_at
    ) VALUES (
      'asg-unlimited-1', '${projectId}', 'drg-1', 'ACCEPTED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    );
  `);

  await t.test('1. Initial delivery v1 uploaded and approved by Admin -> reaches UNDER_ENGINEER_REVIEW', async () => {
    // Draughtsman uploads and submits initial deliverable
    rawDb.exec(`
      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES ('file-v1', '${projectId}', 'drg-1', 'skyrise_v1.dxf', 'skyrise_v1.dxf', 'projects/${projectId}/draughtsman_version/skyrise_v1.dxf', 'application/dxf', 2048, 'draughtsman_version', 'COMPLETED');

      INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by, approval_status)
      VALUES ('dv-v1', '${projectId}', 'file-v1', 1, 'drg-1', 'PENDING');

      UPDATE projects SET status = 'UNDER_ADMIN_REVIEW' WHERE id = '${projectId}';
    `);

    // Admin approves v1
    const appRes = await testRequest(env, '/api/projects/admin-approve-drawing', {
      method: 'POST',
      token: 'adm-1',
      body: {
        projectId,
        drawingVersionId: 'dv-v1',
        actionId: 'act-admin-app-v1',
        feedback: 'Linework standards verified.'
      }
    });
    assert.equal(appRes.status, 200);

    const prj = rawDb.prepare('SELECT status, correction_round FROM projects WHERE id = ?').get(projectId);
    assert.equal(prj.status, 'UNDER_ENGINEER_REVIEW');
    assert.equal(prj.correction_round, 0);
  });

  await t.test('2. Engineer requests Correction Round 1 -> project enters IN_PROGRESS with round 1', async () => {
    const res = await testRequest(env, '/api/projects/request-correction', {
      method: 'POST',
      token: 'eng-1',
      body: {
        projectId,
        targetVersionId: 'dv-v1',
        description: 'Extend west lobby corridor by 2.0m',
        actionId: 'act-corr-r1',
        correctionId: 'corr-r1'
      }
    });
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.newRound, 1);

    const prj = rawDb.prepare('SELECT status, correction_round FROM projects WHERE id = ?').get(projectId);
    assert.equal(prj.status, 'IN_PROGRESS');
    assert.equal(prj.correction_round, 1);

    const corr = rawDb.prepare('SELECT * FROM corrections WHERE id = ?').get('corr-r1');
    assert.equal(corr.round_number, 1);
    assert.equal(corr.status, 'OPEN');
    assert.equal(corr.description, 'Extend west lobby corridor by 2.0m');
  });

  await t.test('3. Admin QC revision does NOT increment Engineer correction round', async () => {
    // Draughtsman resubmits corrected drawing v2
    rawDb.exec(`
      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES ('file-v2-qc', '${projectId}', 'drg-1', 'skyrise_v2.dxf', 'skyrise_v2.dxf', 'projects/${projectId}/draughtsman_version/skyrise_v2.dxf', 'application/dxf', 2048, 'draughtsman_version', 'COMPLETED');

      INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by, approval_status, correction_id)
      VALUES ('dv-v2', '${projectId}', 'file-v2-qc', 2, 'drg-1', 'PENDING', 'corr-r1');

      UPDATE projects SET status = 'UNDER_ADMIN_REVIEW' WHERE id = '${projectId}';
      UPDATE corrections SET status = 'IN_REVIEW' WHERE id = 'corr-r1';
    `);

    // Studio Admin requests internal revision (rework)
    const revRes = await testRequest(env, '/api/projects/admin-request-revision', {
      method: 'POST',
      token: 'adm-1',
      body: {
        projectId,
        drawingVersionId: 'dv-v2',
        actionId: 'act-admin-rev-1',
        feedback: 'Wall hatching layers inconsistent with studio standard.'
      }
    });
    assert.equal(revRes.status, 200);

    const prj = rawDb.prepare('SELECT status, correction_round FROM projects WHERE id = ?').get(projectId);
    assert.equal(prj.status, 'IN_PROGRESS');
    // Critical: Engineer correction_round MUST REMAIN 1, NOT incremented
    assert.equal(prj.correction_round, 1);

    const dv = rawDb.prepare('SELECT approval_status FROM drawing_versions WHERE id = ?').get('dv-v2');
    assert.equal(dv.approval_status, 'REJECTED');
  });

  await t.test('4. Corrected drawing v3 approved by Admin -> releases to Engineer (still Round 1)', async () => {
    rawDb.exec(`
      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES ('file-v3', '${projectId}', 'drg-1', 'skyrise_v3.dxf', 'skyrise_v3.dxf', 'projects/${projectId}/draughtsman_version/skyrise_v3.dxf', 'application/dxf', 2048, 'draughtsman_version', 'COMPLETED');

      INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by, approval_status, correction_id)
      VALUES ('dv-v3', '${projectId}', 'file-v3', 3, 'drg-1', 'PENDING', 'corr-r1');

      UPDATE projects SET status = 'UNDER_ADMIN_REVIEW' WHERE id = '${projectId}';
    `);

    const appRes = await testRequest(env, '/api/projects/admin-approve-drawing', {
      method: 'POST',
      token: 'adm-1',
      body: {
        projectId,
        drawingVersionId: 'dv-v3',
        actionId: 'act-admin-app-v3',
        feedback: 'Hatching corrected and verified.'
      }
    });
    assert.equal(appRes.status, 200);

    const prj = rawDb.prepare('SELECT status, correction_round FROM projects WHERE id = ?').get(projectId);
    assert.equal(prj.status, 'UNDER_ENGINEER_REVIEW');
    assert.equal(prj.correction_round, 1);
  });

  await t.test('5. Unlimited Revisions: Engineer successfully requests Rounds 2, 3, 4, 5, and 6', async () => {
    for (let round = 2; round <= 6; round++) {
      // Engineer requests correction for this round
      const reqRes = await testRequest(env, '/api/projects/request-correction', {
        method: 'POST',
        token: 'eng-1',
        body: {
          projectId,
          targetVersionId: `dv-v${round + 1}`,
          description: `Engineer feedback for revision round ${round}`,
          actionId: `act-corr-r${round}`,
          correctionId: `corr-r${round}`
        }
      });
      assert.equal(reqRes.status, 200, `Round ${round} request must succeed with 200`);
      const body = await reqRes.json();
      assert.equal(body.newRound, round);

      let prj = rawDb.prepare('SELECT status, correction_round FROM projects WHERE id = ?').get(projectId);
      assert.equal(prj.status, 'IN_PROGRESS');
      assert.equal(prj.correction_round, round);

      // Verify correction row created
      const corr = rawDb.prepare('SELECT * FROM corrections WHERE id = ?').get(`corr-r${round}`);
      assert.equal(corr.round_number, round);
      assert.equal(corr.status, 'OPEN');

      // Draughtsman uploads new version
      const nextVersionNum = round + 2;
      const fileId = `file-v${nextVersionNum}`;
      const dvId = `dv-v${nextVersionNum}`;

      rawDb.exec(`
        INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
        VALUES ('${fileId}', '${projectId}', 'drg-1', 'skyrise_v${nextVersionNum}.dxf', 'skyrise_v${nextVersionNum}.dxf', 'projects/${projectId}/draughtsman_version/skyrise_v${nextVersionNum}.dxf', 'application/dxf', 2048, 'draughtsman_version', 'COMPLETED');

        INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by, approval_status, correction_id)
        VALUES ('${dvId}', '${projectId}', '${fileId}', ${nextVersionNum}, 'drg-1', 'PENDING', 'corr-r${round}');

        UPDATE projects SET status = 'UNDER_ADMIN_REVIEW' WHERE id = '${projectId}';
        UPDATE corrections SET status = 'IN_REVIEW' WHERE id = 'corr-r${round}';
      `);

      // Admin approves
      const adminApp = await testRequest(env, '/api/projects/admin-approve-drawing', {
        method: 'POST',
        token: 'adm-1',
        body: {
          projectId,
          drawingVersionId: dvId,
          actionId: `act-admin-app-v${nextVersionNum}`,
          feedback: `Admin verified quality for round ${round}`
        }
      });
      assert.equal(adminApp.status, 200);

      prj = rawDb.prepare('SELECT status, correction_round FROM projects WHERE id = ?').get(projectId);
      assert.equal(prj.status, 'UNDER_ENGINEER_REVIEW');
      assert.equal(prj.correction_round, round);
    }
  });

  await t.test('6. Concurrency & Idempotency: Duplicate correction requests handled safely', async () => {
    // Current project is in UNDER_ENGINEER_REVIEW with correction_round = 6
    // Duplicate submission with same actionId when IN_PROGRESS is idempotent
    const initialPrj = rawDb.prepare('SELECT status, correction_round FROM projects WHERE id = ?').get(projectId);
    assert.equal(initialPrj.status, 'UNDER_ENGINEER_REVIEW');
    assert.equal(initialPrj.correction_round, 6);

    // Request round 7
    const r7 = await testRequest(env, '/api/projects/request-correction', {
      method: 'POST',
      token: 'eng-1',
      body: {
        projectId,
        targetVersionId: 'dv-v8',
        description: 'Round 7 fine-tuning',
        actionId: 'act-r7-idempotent',
        correctionId: 'corr-r7'
      }
    });
    assert.equal(r7.status, 200);
    const r7Body = await r7.json();
    assert.equal(r7Body.newRound, 7);

    // Retry with SAME actionId -> returns idempotent 200 OK without incrementing again
    const r7Retry = await testRequest(env, '/api/projects/request-correction', {
      method: 'POST',
      token: 'eng-1',
      body: {
        projectId,
        targetVersionId: 'dv-v8',
        description: 'Round 7 fine-tuning',
        actionId: 'act-r7-idempotent',
        correctionId: 'corr-r7'
      }
    });
    assert.equal(r7Retry.status, 200);
    const r7RetryBody = await r7Retry.json();
    assert.equal(r7RetryBody.success, true);
    assert.equal(r7RetryBody.newRound, 7);

    // Conflicting request with DIFFERENT actionId while already IN_PROGRESS is rejected with 400
    const conflictRes = await testRequest(env, '/api/projects/request-correction', {
      method: 'POST',
      token: 'eng-1',
      body: {
        projectId,
        targetVersionId: 'dv-v8',
        description: 'Conflicting concurrent request',
        actionId: 'act-r7-conflicting',
        correctionId: 'corr-r7-conflict'
      }
    });
    assert.equal(conflictRes.status, 400);
    const conflictBody = await conflictRes.json();
    assert.equal(conflictBody.error, 'Project is not in review state');

    // State remains clean at round 7
    const prj = rawDb.prepare('SELECT status, correction_round FROM projects WHERE id = ?').get(projectId);
    assert.equal(prj.status, 'IN_PROGRESS');
    assert.equal(prj.correction_round, 7);
  });

  await t.test('7. Correction history and audit records are completely preserved', async () => {
    const corrections = rawDb.prepare('SELECT id, round_number, description FROM corrections WHERE project_id = ? ORDER BY round_number ASC').all(projectId);
    assert.equal(corrections.length, 7);
    for (let i = 0; i < 7; i++) {
      assert.equal(corrections[i].round_number, i + 1);
    }

    const reviews = rawDb.prepare('SELECT id, decision, feedback FROM drawing_version_reviews WHERE project_id = ?').all(projectId);
    assert.ok(reviews.length >= 7, 'All admin approvals and revisions must be audited');

    // Admin QC rework review exists
    const adminRev = reviews.find(r => r.decision === 'REJECTED');
    assert.ok(adminRev, 'Admin internal revision must be audited in reviews table');
    assert.equal(adminRev.feedback, 'Wall hatching layers inconsistent with studio standard.');
  });

  await t.test('8. Final Engineer approval transitions project to COMPLETED and resolves open corrections', async () => {
    // Draughtsman resubmits v9 for round 7
    rawDb.exec(`
      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES ('file-v9', '${projectId}', 'drg-1', 'skyrise_v9.dxf', 'skyrise_v9.dxf', 'projects/${projectId}/draughtsman_version/skyrise_v9.dxf', 'application/dxf', 2048, 'draughtsman_version', 'COMPLETED');

      INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by, approval_status, correction_id)
      VALUES ('dv-v9', '${projectId}', 'file-v9', 9, 'drg-1', 'APPROVED', 'corr-r7');

      UPDATE projects SET status = 'UNDER_ENGINEER_REVIEW' WHERE id = '${projectId}';
      UPDATE corrections SET status = 'IN_REVIEW' WHERE id = 'corr-r7';
    `);

    // Engineer approves final deliverable
    const finalAppRes = await testRequest(env, '/api/projects/approve-final', {
      method: 'POST',
      token: 'eng-1',
      body: {
        projectId,
        drawingVersionId: 'dv-v9',
        actionId: 'act-final-approve'
      }
    });
    assert.equal(finalAppRes.status, 200);

    const finalPrj = rawDb.prepare('SELECT status, correction_round FROM projects WHERE id = ?').get(projectId);
    assert.equal(finalPrj.status, 'COMPLETED');
    assert.equal(finalPrj.correction_round, 7);

    const finalCorr = rawDb.prepare('SELECT status FROM corrections WHERE id = ?').get('corr-r7');
    assert.equal(finalCorr.status, 'RESOLVED');
  });
});
