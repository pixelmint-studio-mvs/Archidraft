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

const bundlePath = path.join(workerRoot, 'node_modules', '.test_app_bundle_phase_b.mjs');
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

function seedBaselineData(rawDb) {
  // Users
  const insertUser = rawDb.prepare('INSERT INTO users (id, email, name, role, status) VALUES (?, ?, ?, ?, ?)');
  insertUser.run('eng-1', 'eng1@archidraft.com', 'Engineer One', 'ENGINEER', 'ACTIVE');
  insertUser.run('eng-2', 'eng2@archidraft.com', 'Engineer Two', 'ENGINEER', 'ACTIVE');
  insertUser.run('legacy-client', 'client@archidraft.com', 'Legacy Client', 'CLIENT', 'ACTIVE');
  insertUser.run('draughtsman-1', 'drg1@archidraft.com', 'Draughtsman One', 'DRAUGHTSMAN', 'ACTIVE');
  insertUser.run('draughtsman-cap', 'cap@archidraft.com', 'Draughtsman Cap', 'DRAUGHTSMAN', 'ACTIVE');
  insertUser.run('suspended-user', 'suspended@archidraft.com', 'Suspended Eng', 'ENGINEER', 'SUSPENDED');
  insertUser.run('admin-1', 'admin@draughtsmanstudio.com', 'Studio Admin', 'ADMIN', 'ACTIVE');

  // Terms and conditions
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

  for (const uid of ['eng-1', 'eng-2', 'legacy-client', 'draughtsman-1', 'draughtsman-cap', 'suspended-user', 'admin-1']) {
    insertEvent.run('evt-' + uid, uid, 'idem-' + uid);
    insertConsent.run('cst-' + uid, uid, 'evt-' + uid);
  }
}

test('PHASE B: Security & Safe Integration Remediation Suite', async (t) => {
  const { rawDb, env } = createIsolatedTestDb();
  seedBaselineData(rawDb);

  // -------------------------------------------------------------
  // 1. Cross-Tenant Project Isolation (SEC-01)
  // -------------------------------------------------------------
  await t.test('1. SEC-01: Cross-tenant isolation & IDOR prevention', async (t) => {
    rawDb.prepare(`
      INSERT INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, draughtsman_id)
      VALUES
        ('prj-eng1-submitted', 'eng-1', 'Eng1 Tower', '101 Pine', 'Framing', 'Architectural', '2000', 'SUBMITTED', NULL),
        ('prj-client-active', 'legacy-client', 'Client Commercial', '202 Oak', 'Layout', 'Architectural', '5000', 'IN_PROGRESS', 'draughtsman-1')
    `).run();

    // Engineer 2 attempts to list projects
    const listRes = await testRequest(env, '/api/projects', { token: 'eng-2' });
    assert.equal(listRes.status, 200);
    const listData = await listRes.json();
    assert.equal(listData.length, 0, 'Engineer 2 must not see projects belonging to Engineer 1 or Legacy Client');

    // Engineer 2 attempts IDOR direct access to Engineer 1 project
    const idorRes1 = await testRequest(env, '/api/projects/prj-eng1-submitted', { token: 'eng-2' });
    assert.equal(idorRes1.status, 403, 'Engineer 2 must be denied access to Engineer 1 project');

    // Engineer 2 attempts IDOR direct access to Legacy Client non-draft project
    const idorRes2 = await testRequest(env, '/api/projects/prj-client-active', { token: 'eng-2' });
    assert.equal(idorRes2.status, 403, 'Engineer 2 must not see Legacy Client project even if non-draft');

    // Engineer 1 CAN access own project
    const ownRes = await testRequest(env, '/api/projects/prj-eng1-submitted', { token: 'eng-1' });
    assert.equal(ownRes.status, 200);

    // Admin CAN access all projects
    const adminRes = await testRequest(env, '/api/projects/prj-eng1-submitted', { token: 'admin-1' });
    assert.equal(adminRes.status, 200);
  });

  // -------------------------------------------------------------
  // 2. Account Suspension Governance (SEC-02)
  // -------------------------------------------------------------
  await t.test('2. SEC-02: Account suspension enforcement and administration', async (t) => {
    // Suspended user can view profile to learn suspension status
    const meRes = await testRequest(env, '/api/users/me', { token: 'suspended-user' });
    assert.equal(meRes.status, 200);
    const meData = await meRes.json();
    assert.equal(meData.status, 'SUSPENDED');

    // Suspended user is denied creating project (403 ACCOUNT_SUSPENDED)
    const createRes = await testRequest(env, '/api/projects', {
      method: 'POST',
      token: 'suspended-user',
      body: { project_name: 'Suspended Project Attempt' }
    });
    assert.equal(createRes.status, 403);
    const createErr = await createRes.json();
    assert.equal(createErr.code, 'ACCOUNT_SUSPENDED');

    // Admin can inspect user detail
    const userDetailRes = await testRequest(env, '/api/users/suspended-user', { token: 'admin-1' });
    assert.equal(userDetailRes.status, 200);
    const userDetail = await userDetailRes.json();
    assert.equal(userDetail.status, 'SUSPENDED');

    // Admin cannot suspend own account
    const selfRes = await testRequest(env, '/api/users/admin-1/status', {
      method: 'PATCH',
      token: 'admin-1',
      body: { status: 'SUSPENDED' }
    });
    assert.equal(selfRes.status, 400);
    const selfErr = await selfRes.json();
    assert.equal(selfErr.code, 'SELF_SUSPENSION_FORBIDDEN');

    // Ordinary user cannot alter account status
    const unauthStatusRes = await testRequest(env, '/api/users/eng-1/status', {
      method: 'PATCH',
      token: 'eng-2',
      body: { status: 'SUSPENDED' }
    });
    assert.equal(unauthStatusRes.status, 403);

    // Admin can reactivate suspended user
    const reactivateRes = await testRequest(env, '/api/users/suspended-user/status', {
      method: 'PATCH',
      token: 'admin-1',
      body: { status: 'ACTIVE' }
    });
    assert.equal(reactivateRes.status, 200);
    const reactivateData = await reactivateRes.json();
    assert.equal(reactivateData.status, 'ACTIVE');

    // Re-suspended user for test purity
    await testRequest(env, '/api/users/suspended-user/status', {
      method: 'PATCH',
      token: 'admin-1',
      body: { status: 'SUSPENDED' }
    });
  });

  // -------------------------------------------------------------
  // 3. Draughtsman Capacity Cap (SEC-03)
  // -------------------------------------------------------------
  await t.test('3. SEC-03: Draughtsman 4-active project workload cap', async (t) => {
    // Seed 3 active projects assigned to draughtsman-cap
    rawDb.prepare(`
      INSERT INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, draughtsman_id, draughtsman_name)
      VALUES
        ('cap-prj-1', 'eng-1', 'Active 1', '101 Pine', 'Framing', 'Architectural', '2000', 'IN_PROGRESS', 'draughtsman-cap', 'Draughtsman Cap'),
        ('cap-prj-2', 'eng-1', 'Active 2', '101 Pine', 'Framing', 'Architectural', '2000', 'WAITING_ACCEPTANCE', 'draughtsman-cap', 'Draughtsman Cap'),
        ('cap-prj-3', 'eng-1', 'Active 3', '101 Pine', 'Framing', 'Architectural', '2000', 'UNDER_ENGINEER_REVIEW', 'draughtsman-cap', 'Draughtsman Cap'),
        ('cap-prj-waiting-4', 'eng-1', 'Queue 4', '101 Pine', 'Framing', 'Architectural', '2000', 'WAITING_ASSIGNMENT', NULL, NULL),
        ('cap-prj-waiting-5', 'eng-1', 'Queue 5', '101 Pine', 'Framing', 'Architectural', '2000', 'WAITING_ASSIGNMENT', NULL, NULL),
        ('cap-prj-completed', 'eng-1', 'Done Past', '101 Pine', 'Framing', 'Architectural', '2000', 'COMPLETED', 'draughtsman-cap', 'Draughtsman Cap')
    `).run();

    // 4th assignment should SUCCEED (reaching 4/4)
    const asg4Res = await testRequest(env, '/api/projects/assign', {
      method: 'POST',
      token: 'admin-1',
      body: {
        projectId: 'cap-prj-waiting-4',
        draughtsmanId: 'draughtsman-cap',
        actionId: 'action-asg-4'
      }
    });
    assert.equal(asg4Res.status, 200, '4th active project assignment must be permitted');

    // Idempotent retry on 4th assignment must SUCCEED
    const retry4Res = await testRequest(env, '/api/projects/assign', {
      method: 'POST',
      token: 'admin-1',
      body: {
        projectId: 'cap-prj-waiting-4',
        draughtsmanId: 'draughtsman-cap',
        actionId: 'action-asg-4'
      }
    });
    assert.equal(retry4Res.status, 200, 'Idempotent retry on 4th assignment must succeed');

    // 5th assignment must be REJECTED (exceeds capacity cap)
    const asg5Res = await testRequest(env, '/api/projects/assign', {
      method: 'POST',
      token: 'admin-1',
      body: {
        projectId: 'cap-prj-waiting-5',
        draughtsmanId: 'draughtsman-cap',
        actionId: 'action-asg-5'
      }
    });
    assert.equal(asg5Res.status, 400, '5th assignment must be rejected due to capacity limit');
    const asg5Err = await asg5Res.json();
    assert.equal(asg5Err.code, 'DRAUGHTSMAN_CAPACITY_EXCEEDED');

    // Reassignment to draughtsman-cap when full must also be REJECTED
    rawDb.prepare(`
      INSERT INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, draughtsman_id, draughtsman_name)
      VALUES ('cap-prj-reassign-target', 'eng-1', 'Reassign Test', '101 Pine', 'Framing', 'Architectural', '2000', 'IN_PROGRESS', 'draughtsman-1', 'Draughtsman One')
    `).run();

    const reassignRes = await testRequest(env, '/api/projects/reassign', {
      method: 'POST',
      token: 'admin-1',
      body: {
        projectId: 'cap-prj-reassign-target',
        draughtsmanId: 'draughtsman-cap',
        actionId: 'action-reassign-blocked'
      }
    });
    assert.equal(reassignRes.status, 400, 'Reassignment to draughtsman at capacity must be rejected');
    const reassignErr = await reassignRes.json();
    assert.equal(reassignErr.code, 'DRAUGHTSMAN_CAPACITY_EXCEEDED');
  });

  // -------------------------------------------------------------
  // 4. Role Compatibility (ENGINEER and CLIENT)
  // -------------------------------------------------------------
  await t.test('4. Role compatibility: Both ENGINEER and CLIENT can create and submit', async (t) => {
    // Legacy CLIENT creates a project
    const clientCreateRes = await testRequest(env, '/api/projects', {
      method: 'POST',
      token: 'legacy-client',
      body: {
        id: 'prj-client-new-1',
        project_name: 'Client Villa',
        project_address: '505 Cedar',
        drawing_name: 'Floor Plan',
        drawing_type: 'Architectural',
        project_area: '3000 sq ft'
      }
    });
    assert.equal(clientCreateRes.status, 200, 'CLIENT role must be allowed to create draft project');

    // Legacy CLIENT submits the project
    const clientSubmitRes = await testRequest(env, '/api/projects/submit', {
      method: 'POST',
      token: 'legacy-client',
      body: {
        projectId: 'prj-client-new-1',
        actionId: 'act-client-sub-1'
      }
    });
    assert.equal(clientSubmitRes.status, 200, 'CLIENT role must be allowed to submit project');

    // ENGINEER creates and submits
    const engCreateRes = await testRequest(env, '/api/projects', {
      method: 'POST',
      token: 'eng-1',
      body: {
        id: 'prj-eng-new-1',
        project_name: 'Engineer Residence',
        project_address: '606 Elm',
        drawing_name: 'Framing Plan',
        drawing_type: 'Structural',
        project_area: '4500 sq ft'
      }
    });
    assert.equal(engCreateRes.status, 200, 'ENGINEER role must be allowed to create draft project');
  });

  // -------------------------------------------------------------
  // 5. Collaboration Hub Adapter (/comments <-> /messages)
  // -------------------------------------------------------------
  await t.test('5. Collaboration unification: Bidirectional comments & messages adapter', async (t) => {
    // Create an accessible project
    rawDb.prepare(`
      INSERT INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, draughtsman_id)
      VALUES ('collab-prj-1', 'eng-1', 'Collab Project', '101 Pine', 'Framing', 'Architectural', '2000', 'IN_PROGRESS', 'draughtsman-1')
    `).run();

    // Post comment via Admin /comments endpoint
    const postCommentRes = await testRequest(env, '/api/projects/collab-prj-1/comments', {
      method: 'POST',
      token: 'admin-1',
      body: {
        content: 'Admin architectural review note',
        attachmentName: 'markup.pdf',
        attachmentType: 'application/pdf'
      }
    });
    assert.equal(postCommentRes.status, 201);
    const postCommentData = await postCommentRes.json();
    assert.ok(postCommentData.success);
    assert.equal(postCommentData.comment.content, 'Admin architectural review note');

    // Mobile /messages endpoint MUST see the comment
    const getMessagesRes = await testRequest(env, '/api/projects/collab-prj-1/messages', {
      token: 'eng-1'
    });
    assert.equal(getMessagesRes.status, 200);
    const messages = await getMessagesRes.json();
    assert.equal(messages.length, 1);
    assert.equal(messages[0].message, 'Admin architectural review note');

    // Mobile /messages posts a message
    const postMessageRes = await testRequest(env, '/api/projects/collab-prj-1/messages', {
      method: 'POST',
      token: 'eng-1',
      body: {
        message: 'Engineer response from mobile portal'
      }
    });
    assert.equal(postMessageRes.status, 201);

    // Admin /comments endpoint MUST see the mobile message
    const getCommentsRes = await testRequest(env, '/api/projects/collab-prj-1/comments', {
      token: 'admin-1'
    });
    assert.equal(getCommentsRes.status, 200);
    const comments = await getCommentsRes.json();
    assert.equal(comments.length, 2);
    assert.equal(comments[1].content, 'Engineer response from mobile portal');

    // Unauthorized user cannot read comments
    const unauthCommentRes = await testRequest(env, '/api/projects/collab-prj-1/comments', {
      token: 'eng-2'
    });
    assert.equal(unauthCommentRes.status, 403);
  });

  // -------------------------------------------------------------
  // 6. Admin Settings Persistence (studio_settings)
  // -------------------------------------------------------------
  await t.test('6. Admin settings persistence in studio_settings', async (t) => {
    // Read default settings
    const getSetRes = await testRequest(env, '/api/admin/settings', { token: 'admin-1' });
    assert.equal(getSetRes.status, 200);
    const defaults = await getSetRes.json();
    assert.equal(defaults.turnaround, '24h');
    assert.equal(defaults.maxUploadCeiling, '50MB');

    // Non-admin blocked from settings
    const unauthSetRes = await testRequest(env, '/api/admin/settings', { token: 'eng-1' });
    assert.equal(unauthSetRes.status, 403);

    // Admin updates settings
    const putSetRes = await testRequest(env, '/api/admin/settings', {
      method: 'PUT',
      token: 'admin-1',
      body: {
        turnaround: '48h',
        maxUploadCeiling: '25MB',
        multiDiscipline: false
      }
    });
    assert.equal(putSetRes.status, 200);
    const putData = await putSetRes.json();
    assert.ok(putData.success);

    // Verify persisted in DB
    const verifySetRes = await testRequest(env, '/api/admin/settings', { token: 'admin-1' });
    const verified = await verifySetRes.json();
    assert.equal(verified.turnaround, '48h');
    assert.equal(verified.maxUploadCeiling, '25MB');
    assert.equal(verified.multiDiscipline, false);
  });

  // -------------------------------------------------------------
  // 7. Admin Assignment History Console
  // -------------------------------------------------------------
  await t.test('7. Admin assignment history console (/api/admin/assignments)', async (t) => {
    const asgHistRes = await testRequest(env, '/api/admin/assignments', { token: 'admin-1' });
    assert.equal(asgHistRes.status, 200);
    const asgHist = await asgHistRes.json();
    assert.ok(Array.isArray(asgHist));

    // Non-admin blocked
    const unauthHistRes = await testRequest(env, '/api/admin/assignments', { token: 'eng-1' });
    assert.equal(unauthHistRes.status, 403);
  });

  // -------------------------------------------------------------
  // 8. Payments Scope Freezing (501 FEATURE_FROZEN)
  // -------------------------------------------------------------
  await t.test('8. Payments scope freezing: 501 FEATURE_FROZEN on mutations', async (t) => {
    // Non-admin is denied (403)
    const unauthInvRes = await testRequest(env, '/api/projects/collab-prj-1/invoices', {
      method: 'POST',
      token: 'eng-1',
      body: { amount: 5000, due_date: '2026-12-31' }
    });
    assert.equal(unauthInvRes.status, 403);

    // Admin receives 501 FEATURE_FROZEN on invoice creation mutation
    const invRes = await testRequest(env, '/api/projects/collab-prj-1/invoices', {
      method: 'POST',
      token: 'admin-1',
      body: { amount: 5000, due_date: '2026-12-31' }
    });
    assert.equal(invRes.status, 501);
    const invErr = await invRes.json();
    assert.equal(invErr.code, 'FEATURE_FROZEN');

    // Admin receives 501 FEATURE_FROZEN on payment recording mutation
    rawDb.prepare(`
      INSERT INTO invoices (id, project_id, invoice_number, amount, currency, status, due_date, created_at)
      VALUES ('inv-collab-1', 'collab-prj-1', 'INV-COLLAB-1', 5000, 'INR', 'ISSUED', '2026-12-31', CURRENT_TIMESTAMP)
    `).run();

    const payRes = await testRequest(env, '/api/invoices/inv-collab-1/payments', {
      method: 'POST',
      token: 'admin-1',
      body: { amount: 5000, payment_method: 'MANUAL' }
    });
    assert.equal(payRes.status, 501);
    const payErr = await payRes.json();
    assert.equal(payErr.code, 'FEATURE_FROZEN');

    // Read-only financials inspection remains operational for admin
    const finRes = await testRequest(env, '/api/projects/collab-prj-1/financials', { token: 'admin-1' });
    assert.equal(finRes.status, 200);
  });
});
