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

const bundlePath = path.join(workerRoot, 'node_modules', '.test_app_bundle_phase_d.mjs');
esbuild.buildSync({
  entryPoints: [path.join(workerRoot, 'src', 'index.ts')],
  bundle: true,
  format: 'esm',
  platform: 'node',
  write: true,
  outfile: bundlePath,
});

const { default: app } = await import(`file://${bundlePath}`);

function createIsolatedTestDb(customEnv = {}) {
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

  return {
    rawDb: db,
    env: {
      DB: d1,
      STORAGE: storage,
      ENVIRONMENT: 'test',
      ...customEnv,
    }
  };
}

function seedBaselineData(rawDb) {
  rawDb.exec(`
    INSERT INTO users (id, email, name, role, status) VALUES
      ('admin-1', 'admin@draughtsmanstudio.com', 'Studio Admin', 'ADMIN', 'ACTIVE'),
      ('eng-1', 'engineer1@example.com', 'Structural Engineer', 'ENGINEER', 'ACTIVE'),
      ('eng-2', 'engineer2@example.com', 'Civil Engineer', 'CLIENT', 'ACTIVE'),
      ('eng-suspended', 'suspended@example.com', 'Suspended Engineer', 'ENGINEER', 'SUSPENDED'),
      ('drg-1', 'draughtsman1@example.com', 'Senior Draughtsman', 'DRAUGHTSMAN', 'ACTIVE'),
      ('drg-2', 'draughtsman2@example.com', 'Junior Draughtsman', 'DRAUGHTSMAN', 'ACTIVE'),
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

  for (const uid of ['admin-1', 'eng-1', 'eng-2', 'eng-suspended', 'drg-1', 'drg-2', 'student-1']) {
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

test('PHASE D.1 Remediation: CORS Allowlist Suite', async (t) => {
  await t.test('Permits baseline production origin with credentials', async () => {
    const { env } = createIsolatedTestDb({ ENVIRONMENT: 'production' });
    const res = await app.request('/api/health', {
      method: 'OPTIONS',
      headers: {
        'Origin': 'https://admin.draughtsmanstudio.com',
        'Access-Control-Request-Method': 'GET',
      }
    }, env);

    assert.equal(res.status, 204);
    assert.equal(res.headers.get('Access-Control-Allow-Origin'), 'https://admin.draughtsmanstudio.com');
    assert.equal(res.headers.get('Access-Control-Allow-Credentials'), 'true');
  });

  await t.test('Permits baseline Vercel origin', async () => {
    const { env } = createIsolatedTestDb({ ENVIRONMENT: 'production' });
    const res = await app.request('/api/health', {
      method: 'OPTIONS',
      headers: {
        'Origin': 'https://archi-draft.vercel.app',
        'Access-Control-Request-Method': 'GET',
      }
    }, env);

    assert.equal(res.status, 204);
    assert.equal(res.headers.get('Access-Control-Allow-Origin'), 'https://archi-draft.vercel.app');
  });

  await t.test('Permits configured staging origin via ALLOWED_ORIGINS env var', async () => {
    const { env } = createIsolatedTestDb({
      ENVIRONMENT: 'staging',
      ALLOWED_ORIGINS: 'https://staging.draughtsmanstudio.com,https://preview-123.vercel.app'
    });
    const res = await app.request('/api/health', {
      method: 'OPTIONS',
      headers: {
        'Origin': 'https://staging.draughtsmanstudio.com',
        'Access-Control-Request-Method': 'POST',
      }
    }, env);

    assert.equal(res.status, 204);
    assert.equal(res.headers.get('Access-Control-Allow-Origin'), 'https://staging.draughtsmanstudio.com');
  });

  await t.test('Rejects arbitrary untrusted origin without reflecting it', async () => {
    const { env } = createIsolatedTestDb({ ENVIRONMENT: 'production' });
    const res = await app.request('/api/health', {
      method: 'OPTIONS',
      headers: {
        'Origin': 'https://malicious-attacker.com',
        'Access-Control-Request-Method': 'GET',
      }
    }, env);

    assert.equal(res.status, 204);
    assert.equal(res.headers.get('Access-Control-Allow-Origin'), null);
  });

  await t.test('Permits Draughtsman Studio public website origins in production', async () => {
    const { env } = createIsolatedTestDb({ ENVIRONMENT: 'production' });
    for (const origin of ['https://www.draughtsmanstudio.com', 'https://draughtsmanstudio.com']) {
      const res = await app.request('/api/health', {
        method: 'OPTIONS',
        headers: {
          'Origin': origin,
          'Access-Control-Request-Method': 'GET',
        }
      }, env);
      assert.equal(res.status, 204);
      assert.equal(res.headers.get('Access-Control-Allow-Origin'), origin);
      assert.equal(res.headers.get('Access-Control-Allow-Credentials'), 'true');
    }
  });

  await t.test('Disallows localhost in production environment', async () => {
    const { env } = createIsolatedTestDb({ ENVIRONMENT: 'production' });
    const res = await app.request('/api/health', {
      method: 'OPTIONS',
      headers: {
        'Origin': 'http://localhost:5173',
        'Access-Control-Request-Method': 'GET',
      }
    }, env);

    assert.equal(res.status, 204);
    assert.equal(res.headers.get('Access-Control-Allow-Origin'), null);
  });

  await t.test('Allows localhost in test / development environment', async () => {
    const { env } = createIsolatedTestDb({ ENVIRONMENT: 'development' });
    const res = await app.request('/api/health', {
      method: 'OPTIONS',
      headers: {
        'Origin': 'http://localhost:5173',
        'Access-Control-Request-Method': 'GET',
      }
    }, env);

    assert.equal(res.status, 204);
    assert.equal(res.headers.get('Access-Control-Allow-Origin'), 'http://localhost:5173');
  });
});

test('PHASE D.1 Remediation: Assignment Route Contracts & Compatibility Aliases', async (t) => {
  const { rawDb, env } = createIsolatedTestDb();
  seedBaselineData(rawDb);

  // Seed project in WAITING_ACCEPTANCE state with current assignment
  rawDb.exec(`
    INSERT INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, draughtsman_id, current_assignment_id)
    VALUES ('proj-compat-1', 'eng-1', 'Compat Test Project', '123 Main St', 'Plan 1', 'Architectural', '1500 sqft', 'WAITING_ACCEPTANCE', 'drg-1', 'asgn-compat-1');

    INSERT INTO assignments (id, project_id, draughtsman_id, status)
    VALUES ('asgn-compat-1', 'proj-compat-1', 'drg-1', 'PENDING');
  `);

  await t.test('POST /api/assignments/accept resolves by assignmentId', async () => {
    const res = await testRequest(env, '/api/assignments/accept', {
      method: 'POST',
      token: 'drg-1',
      body: {
        assignmentId: 'asgn-compat-1',
        actionId: 'action-accept-1',
      }
    });

    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.success, true);

    const project = rawDb.prepare('SELECT status FROM projects WHERE id = ?').get('proj-compat-1');
    assert.equal(project.status, 'IN_PROGRESS');
  });

  await t.test('POST /api/assignments/accept resolves by projectId when assignmentId omitted', async () => {
    // Reset to WAITING_ACCEPTANCE
    rawDb.exec(`
      UPDATE projects SET status = 'WAITING_ACCEPTANCE', draughtsman_id = 'drg-1', current_assignment_id = 'asgn-compat-1' WHERE id = 'proj-compat-1';
      UPDATE assignments SET status = 'PENDING' WHERE id = 'asgn-compat-1';
    `);

    const res = await testRequest(env, '/api/assignments/accept', {
      method: 'POST',
      token: 'drg-1',
      body: {
        projectId: 'proj-compat-1',
        actionId: 'action-accept-by-proj',
      }
    });

    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.success, true);

    const project = rawDb.prepare('SELECT status FROM projects WHERE id = ?').get('proj-compat-1');
    assert.equal(project.status, 'IN_PROGRESS');
  });

  await t.test('POST /api/projects/accept backward-compatibility alias works', async () => {
    // Reset to WAITING_ACCEPTANCE
    rawDb.exec(`
      UPDATE projects SET status = 'WAITING_ACCEPTANCE', draughtsman_id = 'drg-1', current_assignment_id = 'asgn-compat-1' WHERE id = 'proj-compat-1';
      UPDATE assignments SET status = 'PENDING' WHERE id = 'asgn-compat-1';
    `);

    const res = await testRequest(env, '/api/projects/accept', {
      method: 'POST',
      token: 'drg-1',
      body: {
        projectId: 'proj-compat-1',
        actionId: 'action-compat-alias-accept',
      }
    });

    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.success, true);

    const project = rawDb.prepare('SELECT status FROM projects WHERE id = ?').get('proj-compat-1');
    assert.equal(project.status, 'IN_PROGRESS');
  });

  await t.test('POST /api/projects/reject-assignment backward-compatibility alias works', async () => {
    // Reset to WAITING_ACCEPTANCE
    rawDb.exec(`
      UPDATE projects SET status = 'WAITING_ACCEPTANCE', draughtsman_id = 'drg-1', current_assignment_id = 'asgn-compat-1' WHERE id = 'proj-compat-1';
      UPDATE assignments SET status = 'PENDING' WHERE id = 'asgn-compat-1';
    `);

    const res = await testRequest(env, '/api/projects/reject-assignment', {
      method: 'POST',
      token: 'drg-1',
      body: {
        projectId: 'proj-compat-1',
        actionId: 'action-compat-alias-reject',
        reason: 'Too busy right now',
      }
    });

    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.success, true);

    const project = rawDb.prepare('SELECT status, current_assignment_id, draughtsman_id FROM projects WHERE id = ?').get('proj-compat-1');
    assert.equal(project.status, 'WAITING_ASSIGNMENT');
    assert.equal(project.current_assignment_id, null);
    assert.equal(project.draughtsman_id, null);
  });
});

test('PHASE D.1 Cross-Portal E2E Business Workflow Simulation', async (t) => {
  const { rawDb, env } = createIsolatedTestDb();
  seedBaselineData(rawDb);

  let createdProjectId = null;
  let activeAssignmentId = null;

  await t.test('Step 1: Engineer creates project and submits brief', async () => {
    // Create draft
    const createRes = await testRequest(env, '/api/projects', {
      method: 'POST',
      token: 'eng-1',
      body: {
        projectName: 'Modern Residential Villa',
        projectAddress: '42 Ocean Avenue',
        drawingName: 'Architectural Plan & Elevation',
        drawingType: 'Architectural',
        projectArea: '2500 sqft',
      }
    });

    assert.equal(createRes.status, 200);
    const createBody = await createRes.json();
    assert.ok(createBody.id);
    createdProjectId = createBody.id;

    // Submit project
    const submitRes = await testRequest(env, '/api/projects/submit', {
      method: 'POST',
      token: 'eng-1',
      body: {
        projectId: createdProjectId,
        actionId: 'action-e2e-eng-submit',
      }
    });
    assert.equal(submitRes.status, 200);

    const row = rawDb.prepare('SELECT status, client_id FROM projects WHERE id = ?').get(createdProjectId);
    assert.equal(row.status, 'SUBMITTED');
    assert.equal(row.client_id, 'eng-1');
  });

  await t.test('Step 2: Admin reviews project, approves to ready, and assigns Draughtsman', async () => {
    // Admin lists projects
    const listRes = await testRequest(env, '/api/projects', {
      method: 'GET',
      token: 'admin-1',
    });
    assert.equal(listRes.status, 200);
    const list = await listRes.json();
    assert.ok(list.some(p => p.id === createdProjectId));

    // Admin approves project to WAITING_ASSIGNMENT
    const approveRes = await testRequest(env, '/api/projects/approve', {
      method: 'POST',
      token: 'admin-1',
      body: {
        projectId: createdProjectId,
        actionId: 'action-e2e-admin-approve',
      }
    });
    assert.equal(approveRes.status, 200);

    // Admin assigns drg-1
    const assignRes = await testRequest(env, '/api/projects/assign', {
      method: 'POST',
      token: 'admin-1',
      body: {
        projectId: createdProjectId,
        draughtsmanId: 'drg-1',
        actionId: 'action-e2e-admin-assign',
      }
    });
    assert.equal(assignRes.status, 200);
    const assignBody = await assignRes.json();
    assert.equal(assignBody.success, true);
    assert.ok(assignBody.assignmentId);
    activeAssignmentId = assignBody.assignmentId;

    const row = rawDb.prepare('SELECT status, current_assignment_id, draughtsman_id FROM projects WHERE id = ?').get(createdProjectId);
    assert.equal(row.status, 'WAITING_ACCEPTANCE');
    assert.equal(row.current_assignment_id, activeAssignmentId);
    assert.equal(row.draughtsman_id, 'drg-1');
  });

  await t.test('Step 3: Draughtsman accepts assignment and submits deliverable', async () => {
    // Draughtsman views assignments
    const asgnRes = await testRequest(env, '/api/assignments', {
      method: 'GET',
      token: 'drg-1',
    });
    assert.equal(asgnRes.status, 200);

    // Draughtsman accepts
    const acceptRes = await testRequest(env, '/api/assignments/accept', {
      method: 'POST',
      token: 'drg-1',
      body: {
        assignmentId: activeAssignmentId,
        actionId: 'action-e2e-drg-accept',
      }
    });
    assert.equal(acceptRes.status, 200);

    let row = rawDb.prepare('SELECT status FROM projects WHERE id = ?').get(createdProjectId);
    assert.equal(row.status, 'IN_PROGRESS');

    // Draughtsman submits deliverable drawing
    const submitRes = await testRequest(env, '/api/projects/submit-drawing', {
      method: 'POST',
      token: 'drg-1',
      body: {
        projectId: createdProjectId,
        actionId: 'action-e2e-submit-dwg',
      }
    });
    assert.equal(submitRes.status, 200);

    row = rawDb.prepare('SELECT status FROM projects WHERE id = ?').get(createdProjectId);
    assert.equal(row.status, 'UNDER_ENGINEER_REVIEW');
  });

  await t.test('Step 4: Engineer approves final deliverable', async () => {
    const approveRes = await testRequest(env, '/api/projects/approve-final', {
      method: 'POST',
      token: 'eng-1',
      body: {
        projectId: createdProjectId,
        actionId: 'action-e2e-eng-approve',
      }
    });
    assert.equal(approveRes.status, 200);

    const row = rawDb.prepare('SELECT status FROM projects WHERE id = ?').get(createdProjectId);
    assert.equal(row.status, 'COMPLETED');
  });

  await t.test('Step 5: Correction cycle and revision cap enforcement', async () => {
    // Create second disposable project
    const p2Res = await testRequest(env, '/api/projects', {
      method: 'POST',
      token: 'eng-1',
      body: {
        projectName: 'Commercial Complex Wing B',
        projectAddress: '88 Commercial Rd',
        drawingName: 'Structural Framing',
        drawingType: 'Structural',
        projectArea: '10000 sqft',
      }
    });
    const p2Id = (await p2Res.json()).id;

    // Submit, approve, assign, accept, submit drawing to reach UNDER_ENGINEER_REVIEW
    await testRequest(env, '/api/projects/submit', {
      method: 'POST',
      token: 'eng-1',
      body: { projectId: p2Id, actionId: 'action-p2-submit' }
    });
    await testRequest(env, '/api/projects/approve', {
      method: 'POST',
      token: 'admin-1',
      body: { projectId: p2Id, actionId: 'action-p2-appr' }
    });
    await testRequest(env, '/api/projects/assign', {
      method: 'POST',
      token: 'admin-1',
      body: { projectId: p2Id, draughtsmanId: 'drg-1', actionId: 'action-p2-assign' }
    });
    await testRequest(env, '/api/assignments/accept', {
      method: 'POST',
      token: 'drg-1',
      body: { projectId: p2Id, actionId: 'action-p2-accept' }
    });
    await testRequest(env, '/api/projects/submit-drawing', {
      method: 'POST',
      token: 'drg-1',
      body: { projectId: p2Id, actionId: 'action-p2-submit-1' }
    });

    let p2Row = rawDb.prepare('SELECT status, correction_round FROM projects WHERE id = ?').get(p2Id);
    assert.equal(p2Row.status, 'UNDER_ENGINEER_REVIEW');

    // Seed file and drawing version v1 so foreign key passes
    rawDb.exec(`
      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES ('file-p2-v1', '${p2Id}', 'drg-1', 'drawing.dwg', 'drawing.dwg', 'obj-p2-v1', 'application/acad', 5000, 'workspace_draft', 'CONFIRMED');

      INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by)
      VALUES ('v1', '${p2Id}', 'file-p2-v1', 1, 'drg-1');
    `);

    // Round 1 correction
    const c1 = await testRequest(env, '/api/projects/request-correction', {
      method: 'POST',
      token: 'eng-1',
      body: {
        projectId: p2Id,
        correctionId: 'corr-1',
        targetVersionId: 'v1',
        description: 'Adjust grid spacing on grid 4',
        actionId: 'action-p2-corr-1',
      }
    });
    assert.equal(c1.status, 200);

    // Draughtsman resubmits
    await testRequest(env, '/api/projects/submit-drawing', {
      method: 'POST',
      token: 'drg-1',
      body: { projectId: p2Id, actionId: 'action-p2-submit-2' }
    });

    // Round 2 correction
    const c2 = await testRequest(env, '/api/projects/request-correction', {
      method: 'POST',
      token: 'eng-1',
      body: {
        projectId: p2Id,
        correctionId: 'corr-2',
        targetVersionId: 'v1',
        description: 'Column dimensions mismatch',
        actionId: 'action-p2-corr-2',
      }
    });
    assert.equal(c2.status, 200);

    // Draughtsman resubmits
    await testRequest(env, '/api/projects/submit-drawing', {
      method: 'POST',
      token: 'drg-1',
      body: { projectId: p2Id, actionId: 'action-p2-submit-3' }
    });

    // Round 3 correction (reaches cap of 3)
    const c3 = await testRequest(env, '/api/projects/request-correction', {
      method: 'POST',
      token: 'eng-1',
      body: {
        projectId: p2Id,
        correctionId: 'corr-3',
        targetVersionId: 'v1',
        description: 'Beam depth annotations missing',
        actionId: 'action-p2-corr-3',
      }
    });
    assert.equal(c3.status, 200);

    // Draughtsman resubmits
    await testRequest(env, '/api/projects/submit-drawing', {
      method: 'POST',
      token: 'drg-1',
      body: { projectId: p2Id, actionId: 'action-p2-submit-4' }
    });

    // Round 4 correction attempt MUST FAIL with 400
    const c4 = await testRequest(env, '/api/projects/request-correction', {
      method: 'POST',
      token: 'eng-1',
      body: {
        projectId: p2Id,
        correctionId: 'corr-4',
        targetVersionId: 'v1',
        description: 'Exceeding revision cap',
        actionId: 'action-p2-corr-4',
      }
    });
    assert.equal(c4.status, 400);
    const c4Body = await c4.json();
    assert.equal(c4Body.error, 'Maximum correction rounds (3) exceeded');
  });

  await t.test('Step 6: Student isolation verification', async () => {
    // Student attempts to view Commercial projects list
    const studentListRes = await testRequest(env, '/api/projects', {
      method: 'GET',
      token: 'student-1',
    });
    assert.equal(studentListRes.status, 403);

    // Student attempts to view Engineer's private project details
    const detailRes = await testRequest(env, `/api/projects/${createdProjectId}`, {
      method: 'GET',
      token: 'student-1',
    });
    assert.equal(detailRes.status, 403);
  });

  await t.test('Step 7: Suspended account handling', async () => {
    const res = await testRequest(env, '/api/projects', {
      method: 'POST',
      token: 'eng-suspended',
      body: {
        projectName: 'Suspended Project Attempt',
        projectAddress: 'Nowhere',
        drawingName: 'None',
        drawingType: 'Architectural',
        projectArea: '0',
      }
    });
    assert.equal(res.status, 403);
    const body = await res.json();
    assert.equal(body.error, 'Account suspended. Contact administrator.');
  });

  await t.test('Step 8: Frozen financial scope validation', async () => {
    // Invoicing mutation is frozen with 501 FEATURE_FROZEN
    const invRes = await testRequest(env, `/api/projects/${createdProjectId}/invoices`, {
      method: 'POST',
      token: 'admin-1',
      body: { amount: 15000, actionId: 'action-fin-inv' }
    });
    assert.equal(invRes.status, 501);
    const invBody = await invRes.json();
    assert.equal(invBody.code, 'FEATURE_FROZEN');

    // Seed invoice so payment mutation lookup succeeds before hitting frozen check
    rawDb.exec(`
      INSERT INTO invoices (id, project_id, invoice_number, amount, currency, status, due_date, created_at)
      VALUES ('inv-test', '${createdProjectId}', 'INV-TEST-001', 15000, 'INR', 'ISSUED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
    `);

    // Payment mutation is frozen with 501 FEATURE_FROZEN
    const payRes = await testRequest(env, `/api/invoices/inv-test/payments`, {
      method: 'POST',
      token: 'admin-1',
      body: { amount: 15000, actionId: 'action-fin-pay' }
    });
    assert.equal(payRes.status, 501);
    const payBody = await payRes.json();
    assert.equal(payBody.code, 'FEATURE_FROZEN');
  });

  await t.test('Step 9: Four-active-assignment capacity enforcement (SEC-03)', async () => {
    // Seed drg-2 with 4 active projects in IN_PROGRESS state
    for (let i = 1; i <= 4; i++) {
      rawDb.exec(`
        INSERT INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, draughtsman_id)
        VALUES ('cap-proj-${i}', 'eng-1', 'Capacity Test ${i}', 'Addr', 'Dwg', 'Arch', '1000', 'IN_PROGRESS', 'drg-2');
      `);
    }

    // Create a 5th project in WAITING_ASSIGNMENT state
    rawDb.exec(`
      INSERT INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status)
      VALUES ('cap-proj-5', 'eng-1', 'Capacity Test 5', 'Addr', 'Dwg', 'Arch', '1000', 'WAITING_ASSIGNMENT');
    `);

    // Admin attempts to assign drg-2 to the 5th project -> MUST FAIL with 400 DRAUGHTSMAN_CAPACITY_EXCEEDED
    const capRes = await testRequest(env, '/api/projects/assign', {
      method: 'POST',
      token: 'admin-1',
      body: {
        projectId: 'cap-proj-5',
        draughtsmanId: 'drg-2',
        actionId: 'action-cap-exceeded',
      }
    });

    assert.equal(capRes.status, 400);
    const capBody = await capRes.json();
    assert.equal(capBody.code, 'DRAUGHTSMAN_CAPACITY_EXCEEDED');
  });
});
