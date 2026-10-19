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

// Set NODE_ENV to test so auth.ts activates safe test-token mode
process.env.NODE_ENV = 'test';

// 1. Bundle worker/src/index.ts in-memory for testing
const bundlePath = path.join(workerRoot, 'node_modules', '.test_app_bundle.mjs');
const buildResult = esbuild.buildSync({
  entryPoints: [path.join(workerRoot, 'src', 'index.ts')],
  bundle: true,
  format: 'esm',
  platform: 'node',
  write: true,
  outfile: bundlePath,
});

const { default: app } = await import(`file://${bundlePath}`);

// 2. Setup isolated in-memory SQLite database and apply real schema migrations
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

  // D1 Database API Wrapper around SQLite DatabaseSync
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
      for (const stmt of statements) {
        await stmt.run();
      }
      return [];
    }
  };

  // Mock R2 Storage Bucket
  const storage = {
    async get(key) {
      return {
        body: 'test-drawing-binary-stream',
        httpEtag: 'mock-etag-1234',
        writeHttpMetadata(headers) {
          headers.set('content-type', 'application/acad');
        }
      };
    },
    async put(key, body, options) {
      return {};
    }
  };

  return { rawDb: db, env: { DB: d1, STORAGE: storage } };
}

// Helper: Seed initial test users, projects, and assignments
function seedTestData(rawDb) {
  const insertUser = rawDb.prepare('INSERT INTO users (id, email, name, role) VALUES (?, ?, ?, ?)');
  insertUser.run('client-1', 'client1@test.com', 'Client One', 'CLIENT');
  insertUser.run('client-2', 'client2@test.com', 'Client Two', 'CLIENT');
  insertUser.run('draughtsman-1', 'draughtsman1@test.com', 'Draughtsman One', 'DRAUGHTSMAN');
  insertUser.run('draughtsman-2', 'draughtsman2@test.com', 'Draughtsman Two', 'DRAUGHTSMAN');
  insertUser.run('draughtsman-rejected', 'd_rejected@test.com', 'Draughtsman Rejected', 'DRAUGHTSMAN');
  insertUser.run('draughtsman-replaced', 'd_replaced@test.com', 'Draughtsman Replaced', 'DRAUGHTSMAN');
  insertUser.run('engineer-1', 'engineer1@test.com', 'Engineer One', 'ENGINEER');
  insertUser.run('student-1', 'student1@test.com', 'Student One', 'STUDENT');
  insertUser.run('guest-1', 'guest1@test.com', 'Guest Actor', 'GUEST');
  insertUser.run('admin-1', 'admin1@test.com', 'Admin One', 'ADMIN');
  insertUser.run('studio-admin-1', 'studioadmin1@test.com', 'Studio Admin', 'STUDIO_ADMIN');

  const insertProject = rawDb.prepare(`
    INSERT INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, draughtsman_id, draughtsman_name, current_assignment_id)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  // Projects owned by Client 1
  insertProject.run('prj-draft-c1', 'client-1', 'Client 1 Draft Villa', '101 Pine St', 'Floor Plan', 'Architectural', '2500 sq ft', 'DRAFT', null, null, null);
  insertProject.run('prj-submitted-c1', 'client-1', 'Client 1 Submitted Tower', '202 Oak St', 'Structural Framing', 'Structural', '3500 sq ft', 'SUBMITTED', null, null, null);
  insertProject.run('prj-accepted-c1', 'client-1', 'Client 1 Active Commercial', '303 Maple Blvd', 'MEP Layout', 'Commercial', '8000 sq ft', 'IN_PROGRESS', 'draughtsman-1', 'Draughtsman One', 'asg-accepted-1');
  insertProject.run('prj-pending-c1', 'client-1', 'Client 1 Pending Acceptance', '404 Birch Way', 'Facade', 'Architectural', '1800 sq ft', 'WAITING_ACCEPTANCE', 'draughtsman-2', 'Draughtsman Two', 'asg-pending-2');
  insertProject.run('prj-rejected-c1', 'client-1', 'Client 1 Rejected Asg Project', '505 Cedar Ave', 'Sections', 'Architectural', '2000 sq ft', 'WAITING_ASSIGNMENT', null, null, null);
  insertProject.run('prj-replaced-c1', 'client-1', 'Client 1 Replaced Asg Project', '606 Elm St', 'Elevations', 'Architectural', '2200 sq ft', 'IN_PROGRESS', 'draughtsman-1', 'Draughtsman One', 'asg-accepted-1');
  insertProject.run('prj-review-c1', 'client-1', 'Client 1 Review Project', '707 Spruce Rd', 'Detail Drawings', 'Architectural', '3000 sq ft', 'UNDER_CLIENT_REVIEW', 'draughtsman-1', 'Draughtsman One', 'asg-review-5');

  // Project owned by Client 2
  insertProject.run('prj-draft-c2', 'client-2', 'Client 2 Draft Project', '808 Walnut Ct', 'Roof Plan', 'Architectural', '1500 sq ft', 'DRAFT', null, null, null);

  const insertAssignment = rawDb.prepare(`
    INSERT INTO assignments (id, project_id, draughtsman_id, status)
    VALUES (?, ?, ?, ?)
  `);
  insertAssignment.run('asg-accepted-1', 'prj-accepted-c1', 'draughtsman-1', 'ACCEPTED');
  insertAssignment.run('asg-pending-2', 'prj-pending-c1', 'draughtsman-2', 'PENDING');
  insertAssignment.run('asg-rejected-3', 'prj-rejected-c1', 'draughtsman-rejected', 'REJECTED');
  insertAssignment.run('asg-replaced-4', 'prj-replaced-c1', 'draughtsman-replaced', 'REPLACED');
  insertAssignment.run('asg-review-5', 'prj-review-c1', 'draughtsman-1', 'ACCEPTED');

  const insertFile = rawDb.prepare(`
    INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  insertFile.run(
    'file-c1-drawing',
    'prj-accepted-c1',
    'client-1',
    'initial_brief.dwg',
    'initial_brief.dwg',
    'projects/prj-accepted-c1/client_upload/initial_brief.dwg',
    'application/acad',
    1024,
    'client_upload',
    'COMPLETED'
  );

  const insertDrawingVersion = rawDb.prepare(`
    INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by)
    VALUES (?, ?, ?, ?, ?)
  `);
  insertDrawingVersion.run('ver-1', 'prj-review-c1', 'file-c1-drawing', 1, 'draughtsman-1');
}

// Helper: Make authenticated test request to Hono app
async function testRequest(env, path, options = {}) {
  const headers = { ...options.headers };
  if (options.token !== null && !headers['Authorization'] && !headers['authorization']) {
    headers['Authorization'] = `Bearer mock-token:${options.token || 'client-1'}`;
  }
  return app.request(path, {
    method: options.method || 'GET',
    headers,
    body: options.body ? JSON.stringify(options.body) : undefined,
  }, env);
}

// =========================================================================
// TEST SUITES
// =========================================================================

test('1. Authentication Middleware & Token Verification', async (t) => {
  const { env } = createIsolatedTestDb();

  await t.test('Rejects request with missing Authorization header (401)', async () => {
    const res = await app.request('/api/projects', { method: 'GET' }, env);
    assert.equal(res.status, 401);
    const body = await res.json();
    assert.match(body.error, /Missing or invalid Authorization header/);
  });

  await t.test('Rejects request with non-Bearer Authorization header (401)', async () => {
    const res = await app.request('/api/projects', {
      method: 'GET',
      headers: { Authorization: 'Basic dXNlcjpwYXNz' }
    }, env);
    assert.equal(res.status, 401);
    const body = await res.json();
    assert.match(body.error, /Missing or invalid Authorization header/);
  });

  await t.test('Rejects request with invalid Bearer token (401)', async () => {
    const res = await app.request('/api/projects', {
      method: 'GET',
      headers: { Authorization: 'Bearer bogus-unverified-token-xyz' }
    }, env);
    assert.equal(res.status, 401);
    const body = await res.json();
    assert.match(body.error, /Invalid Firebase token/);
  });
});

test('2. Role Provisioning Security (POST /api/users & PATCH /api/users/me)', async (t) => {
  const { rawDb, env } = createIsolatedTestDb();

  await t.test('Allows legitimate CLIENT self-registration (200)', async () => {
    const res = await testRequest(env, '/api/users', {
      method: 'POST',
      token: 'new-client-user',
      body: { email: 'newclient@test.com', name: 'New Client', role: 'CLIENT', mobile: '123456789' }
    });
    assert.equal(res.status, 200);
    const userInDb = rawDb.prepare('SELECT role FROM users WHERE id = ?').get('new-client-user');
    assert.equal(userInDb.role, 'CLIENT');
  });

  await t.test('Allows legitimate DRAUGHTSMAN self-registration (200)', async () => {
    const res = await testRequest(env, '/api/users', {
      method: 'POST',
      token: 'new-draughtsman-user',
      body: { email: 'newdraughtsman@test.com', name: 'New Draughtsman', role: 'DRAUGHTSMAN', mobile: '987654321' }
    });
    assert.equal(res.status, 200);
    const userInDb = rawDb.prepare('SELECT role FROM users WHERE id = ?').get('new-draughtsman-user');
    assert.equal(userInDb.role, 'DRAUGHTSMAN');
  });

  await t.test('BLOCKS unauthorized self-registration as ENGINEER (400)', async () => {
    const res = await testRequest(env, '/api/users', {
      method: 'POST',
      token: 'unauthorized-engineer',
      body: { email: 'fakeengineer@test.com', name: 'Fake Engineer', role: 'ENGINEER' }
    });
    assert.equal(res.status, 400);
    const body = await res.json();
    assert.match(body.error, /Invalid role. Only CLIENT and DRAUGHTSMAN are permitted/);
    const userInDb = rawDb.prepare('SELECT * FROM users WHERE id = ?').get('unauthorized-engineer');
    assert.equal(userInDb, undefined);
  });

  await t.test('BLOCKS unauthorized self-registration as STUDENT (400)', async () => {
    const res = await testRequest(env, '/api/users', {
      method: 'POST',
      token: 'unauthorized-student',
      body: { email: 'fakestudent@test.com', name: 'Fake Student', role: 'STUDENT' }
    });
    assert.equal(res.status, 400);
    const body = await res.json();
    assert.match(body.error, /Invalid role. Only CLIENT and DRAUGHTSMAN are permitted/);
  });

  await t.test('BLOCKS unauthorized self-registration as ADMIN or STUDIO_ADMIN (400)', async () => {
    const res = await testRequest(env, '/api/users', {
      method: 'POST',
      token: 'unauthorized-admin',
      body: { email: 'fakeadmin@test.com', name: 'Fake Admin', role: 'ADMIN' }
    });
    assert.equal(res.status, 400);
    const body = await res.json();
    assert.match(body.error, /Invalid role. Only CLIENT and DRAUGHTSMAN are permitted/);
  });

  await t.test('Prevents user from mutating own role via PATCH /api/users/me', async () => {
    seedTestData(rawDb);
    const res = await testRequest(env, '/api/users/me', {
      method: 'PATCH',
      token: 'client-1',
      body: { name: 'Client 1 Updated', role: 'ADMIN' }
    });
    assert.equal(res.status, 200);
    const user = rawDb.prepare('SELECT role, name FROM users WHERE id = ?').get('client-1');
    assert.equal(user.name, 'Client 1 Updated');
    assert.equal(user.role, 'CLIENT'); // Role remains strictly CLIENT
  });
});

test('3. Student and Unknown-Role Project Access Denied (Deny-by-Default)', async (t) => {
  const { rawDb, env } = createIsolatedTestDb();
  seedTestData(rawDb);

  await t.test('STUDENT receives 403 Forbidden on GET /api/projects', async () => {
    const res = await testRequest(env, '/api/projects', { token: 'student-1' });
    assert.equal(res.status, 403);
    const body = await res.json();
    assert.match(body.error, /Insufficient role permissions/);
  });

  await t.test('STUDENT receives 403 Forbidden on GET /api/projects/:id', async () => {
    const res = await testRequest(env, '/api/projects/prj-accepted-c1', { token: 'student-1' });
    assert.equal(res.status, 403);
  });

  await t.test('STUDENT receives 403 Forbidden on GET /api/projects/:id/files', async () => {
    const res = await testRequest(env, '/api/projects/prj-accepted-c1/files', { token: 'student-1' });
    assert.equal(res.status, 403);
  });

  await t.test('STUDENT receives 403 Forbidden on GET /api/files/:fileId/download', async () => {
    const res = await testRequest(env, '/api/files/file-c1-drawing/download', { token: 'student-1' });
    assert.equal(res.status, 403);
  });

  await t.test('UNKNOWN / GUEST role receives 403 Forbidden on GET /api/projects', async () => {
    const res = await testRequest(env, '/api/projects', { token: 'guest-1' });
    assert.equal(res.status, 403);
  });

  await t.test('UNKNOWN / GUEST role receives 403 Forbidden on GET /api/projects/:id', async () => {
    const res = await testRequest(env, '/api/projects/prj-accepted-c1', { token: 'guest-1' });
    assert.equal(res.status, 403);
  });
});

test('4. Cross-Client Isolation & Resource Ownership', async (t) => {
  const { rawDb, env } = createIsolatedTestDb();
  seedTestData(rawDb);

  await t.test('Client A lists only their own projects (excluding Client B projects)', async () => {
    const res = await testRequest(env, '/api/projects', { token: 'client-1' });
    assert.equal(res.status, 200);
    const projects = await res.json();
    assert.ok(projects.length > 0);
    assert.ok(projects.every(p => p.client_id === 'client-1'));
  });

  await t.test('Client B is DENIED access to Client A project details (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-accepted-c1', { token: 'client-2' });
    assert.equal(res.status, 403);
  });

  await t.test('Client B is DENIED access to Client A project activity logs (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-accepted-c1/activity', { token: 'client-2' });
    assert.equal(res.status, 403);
  });

  await t.test('Client B is DENIED access to Client A project files (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-accepted-c1/files', { token: 'client-2' });
    assert.equal(res.status, 403);
  });

  await t.test('Client B is DENIED downloading Client A project file (403)', async () => {
    const res = await testRequest(env, '/api/files/file-c1-drawing/download', { token: 'client-2' });
    assert.equal(res.status, 403);
  });

  await t.test('Client A CAN access own project details and download file (200)', async () => {
    const resDetail = await testRequest(env, '/api/projects/prj-accepted-c1', { token: 'client-1' });
    assert.equal(resDetail.status, 200);

    const resDownload = await testRequest(env, '/api/files/file-c1-drawing/download', { token: 'client-1' });
    assert.equal(resDownload.status, 200);
  });
});

test('5. Draughtsman Assignment Lifecycle & Access Control', async (t) => {
  const { rawDb, env } = createIsolatedTestDb();
  seedTestData(rawDb);

  await t.test('Draughtsman with ACCEPTED assignment can access project (200)', async () => {
    const res = await testRequest(env, '/api/projects/prj-accepted-c1', { token: 'draughtsman-1' });
    assert.equal(res.status, 200);
    const project = await res.json();
    assert.equal(project.id, 'prj-accepted-c1');
  });

  await t.test('Draughtsman with PENDING assignment is DENIED project access (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-pending-c1', { token: 'draughtsman-2' });
    assert.equal(res.status, 403);
  });

  await t.test('Draughtsman whose assignment was REJECTED has access revoked (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-rejected-c1', { token: 'draughtsman-rejected' });
    assert.equal(res.status, 403);
  });

  await t.test('Draughtsman whose assignment was REPLACED has access revoked (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-replaced-c1', { token: 'draughtsman-replaced' });
    assert.equal(res.status, 403);
  });

  await t.test('Unassigned draughtsman is DENIED project access (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-draft-c1', { token: 'draughtsman-2' });
    assert.equal(res.status, 403);
  });
});

test('6. Engineer Review Scope & Draft Exclusion', async (t) => {
  const { rawDb, env } = createIsolatedTestDb();
  seedTestData(rawDb);

  await t.test('Engineer project list EXCLUDES client DRAFT projects', async () => {
    const res = await testRequest(env, '/api/projects', { token: 'engineer-1' });
    assert.equal(res.status, 200);
    const projects = await res.json();
    assert.ok(projects.length > 0);
    assert.ok(projects.every(p => p.status !== 'DRAFT'), 'Engineer received a DRAFT project!');
  });

  await t.test('Engineer direct access to Client DRAFT project is DENIED (403)', async () => {
    const res = await testRequest(env, '/api/projects/prj-draft-c1', { token: 'engineer-1' });
    assert.equal(res.status, 403);
  });

  await t.test('Engineer direct access to SUBMITTED and IN_PROGRESS projects is ALLOWED (200)', async () => {
    const resSub = await testRequest(env, '/api/projects/prj-submitted-c1', { token: 'engineer-1' });
    assert.equal(resSub.status, 200);

    const resProg = await testRequest(env, '/api/projects/prj-accepted-c1', { token: 'engineer-1' });
    assert.equal(resProg.status, 200);
  });
});

test('7. Workflow Policy Compliance: Final Approval & Correction Actions', async (t) => {
  const { rawDb, env } = createIsolatedTestDb();
  seedTestData(rawDb);

  await t.test('Engineer is BLOCKED from approving final drawings (403)', async () => {
    const res = await testRequest(env, '/api/projects/approve-final', {
      method: 'POST',
      token: 'engineer-1',
      body: { projectId: 'prj-review-c1', actionId: 'act-eng-app-1' }
    });
    assert.equal(res.status, 403);
    const body = await res.json();
    assert.match(body.error, /Only clients or admins can approve final drawings/);
  });

  await t.test('Engineer is BLOCKED from requesting corrections (403)', async () => {
    const res = await testRequest(env, '/api/projects/request-correction', {
      method: 'POST',
      token: 'engineer-1',
      body: {
        projectId: 'prj-review-c1',
        actionId: 'act-eng-corr-1',
        correctionId: 'corr-eng-1',
        targetVersionId: 'ver-1',
        description: 'Engineer correction'
      }
    });
    assert.equal(res.status, 403);
    const body = await res.json();
    assert.match(body.error, /Only clients or admins can request corrections/);
  });

  await t.test('Owning Client CAN request correction (200, status -> IN_PROGRESS)', async () => {
    const res = await testRequest(env, '/api/projects/request-correction', {
      method: 'POST',
      token: 'client-1',
      body: {
        projectId: 'prj-review-c1',
        actionId: 'act-client-corr-1',
        correctionId: 'corr-c1-1',
        targetVersionId: 'ver-1',
        description: 'Please adjust pillar dimensions.'
      }
    });
    assert.equal(res.status, 200);
    const prj = rawDb.prepare('SELECT status, correction_round FROM projects WHERE id = ?').get('prj-review-c1');
    assert.equal(prj.status, 'IN_PROGRESS');
    assert.equal(prj.correction_round, 1);
  });

  await t.test('Owning Client CAN approve final drawing (200, status -> COMPLETED)', async () => {
    // Reset status to UNDER_CLIENT_REVIEW for test
    rawDb.prepare("UPDATE projects SET status = 'UNDER_CLIENT_REVIEW' WHERE id = ?").run('prj-review-c1');

    const res = await testRequest(env, '/api/projects/approve-final', {
      method: 'POST',
      token: 'client-1',
      body: { projectId: 'prj-review-c1', actionId: 'act-client-app-1' }
    });
    assert.equal(res.status, 200);
    const prj = rawDb.prepare('SELECT status FROM projects WHERE id = ?').get('prj-review-c1');
    assert.equal(prj.status, 'COMPLETED');
  });

  await t.test('Admin CAN approve final drawing on behalf of client (200)', async () => {
    rawDb.prepare("UPDATE projects SET status = 'UNDER_CLIENT_REVIEW' WHERE id = ?").run('prj-review-c1');

    const res = await testRequest(env, '/api/projects/approve-final', {
      method: 'POST',
      token: 'admin-1',
      body: { projectId: 'prj-review-c1', actionId: 'act-admin-app-1' }
    });
    assert.equal(res.status, 200);
    const prj = rawDb.prepare('SELECT status FROM projects WHERE id = ?').get('prj-review-c1');
    assert.equal(prj.status, 'COMPLETED');
  });
});

test('8. Admin & Studio Admin Privileged Operations', async (t) => {
  const { rawDb, env } = createIsolatedTestDb();
  seedTestData(rawDb);

  await t.test('Admin lists all projects including drafts (200)', async () => {
    const res = await testRequest(env, '/api/projects', { token: 'admin-1' });
    assert.equal(res.status, 200);
    const projects = await res.json();
    assert.ok(projects.some(p => p.status === 'DRAFT'));
  });

  await t.test('Admin can access any project directly (200)', async () => {
    const res = await testRequest(env, '/api/projects/prj-draft-c2', { token: 'admin-1' });
    assert.equal(res.status, 200);
  });

  await t.test('Admin can approve submitted project (200, status -> WAITING_ASSIGNMENT)', async () => {
    const res = await testRequest(env, '/api/projects/approve', {
      method: 'POST',
      token: 'admin-1',
      body: { projectId: 'prj-submitted-c1', actionId: 'act-app-1' }
    });
    assert.equal(res.status, 200);
    const prj = rawDb.prepare('SELECT status FROM projects WHERE id = ?').get('prj-submitted-c1');
    assert.equal(prj.status, 'WAITING_ASSIGNMENT');
  });

  await t.test('Admin can assign draughtsman to project (200, status -> WAITING_ACCEPTANCE)', async () => {
    const res = await testRequest(env, '/api/projects/assign', {
      method: 'POST',
      token: 'admin-1',
      body: { projectId: 'prj-submitted-c1', draughtsmanId: 'draughtsman-1', actionId: 'act-asg-1' }
    });
    assert.equal(res.status, 200);
    const prj = rawDb.prepare('SELECT status, draughtsman_id FROM projects WHERE id = ?').get('prj-submitted-c1');
    assert.equal(prj.status, 'WAITING_ACCEPTANCE');
    assert.equal(prj.draughtsman_id, 'draughtsman-1');
  });

  await t.test('Non-admin (CLIENT) attempting to assign draughtsman is DENIED (403)', async () => {
    const res = await testRequest(env, '/api/projects/assign', {
      method: 'POST',
      token: 'client-1',
      body: { projectId: 'prj-submitted-c1', draughtsmanId: 'draughtsman-1', actionId: 'act-unauth-asg' }
    });
    assert.equal(res.status, 403);
  });
});
