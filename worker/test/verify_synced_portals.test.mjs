import test from 'node:test';
import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import esbuild from 'esbuild';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const workerRoot = path.resolve(__dirname, '..');

process.env.NODE_ENV = 'test';

const bundlePath = path.join(workerRoot, 'node_modules', '.test_verify_portals_bundle.mjs');
esbuild.buildSync({
  entryPoints: [path.join(workerRoot, 'src', 'index.ts')],
  bundle: true,
  format: 'esm',
  platform: 'node',
  write: true,
  outfile: bundlePath,
});

const { default: app } = await import(`file://${bundlePath}`);

const dbPath = path.join(workerRoot, '.wrangler', 'state', 'v3', 'd1', 'miniflare-D1DatabaseObject', 'fdc94e68165493d9beefe9c542c3ccf242c09e8c388eef5ade0878b760405048.sqlite');
const db = new DatabaseSync(dbPath);

function createStatement(sqliteDb, sql, boundArgs = []) {
  return {
    bind(...args) {
      return createStatement(sqliteDb, sql, args);
    },
    async first(col) {
      const stmt = sqliteDb.prepare(sql);
      const row = stmt.get(...boundArgs);
      if (!row) return null;
      if (col) return row[col];
      return row;
    },
    async all() {
      const stmt = sqliteDb.prepare(sql);
      const results = stmt.all(...boundArgs);
      return { results, success: true, meta: { changes: 0 } };
    },
    async run() {
      const stmt = sqliteDb.prepare(sql);
      const info = stmt.run(...boundArgs);
      return { success: true, meta: { changes: info.changes, last_row_id: Number(info.lastInsertRowid) } };
    }
  };
}

function createD1Adapter(sqliteDb) {
  return {
    prepare(sql) {
      return createStatement(sqliteDb, sql);
    },
    async batch(statements) {
      const results = [];
      for (const s of statements) {
        results.push(await s.all());
      }
      return results;
    },
    async exec(sql) {
      sqliteDb.exec(sql);
      return { count: 1, duration: 0 };
    }
  };
}

const env = {
  DB: createD1Adapter(db),
  ENVIRONMENT: 'development',
  ALLOWED_ORIGINS: 'http://localhost:3000,http://localhost:8787',
};

async function testRequest(path, options = {}) {
  const headers = { ...options.headers };
  if (options.token) {
    headers['Authorization'] = `Bearer mock-token:${options.token}`;
  }
  return app.request(path, {
    method: options.method || 'GET',
    headers,
    body: options.body ? JSON.stringify(options.body) : undefined
  }, env);
}

test('PORTAL DATA VERIFICATION: 1. Engineer Portal', async () => {
  const res = await testRequest('/api/projects', { token: 'KXAR90JgoVYLuOKzkbxpKTC8ATa2' });
  assert.equal(res.status, 200);
  const data = await res.json();
  assert.ok(Array.isArray(data), 'Returns projects array');
  assert.equal(data.length, 8, `Expected exactly 8 commercial projects for Engineer, got ${data.length}`);
  console.log(`✓ 1. Engineer Projects Feed: ${data.length} projects retrieved`);
  for (const p of data.slice(0, 4)) {
    console.log(`   - [${p.status}] ${p.project_name} (${p.project_area} sqft, ${p.drawing_type})`);
  }
});

test('PORTAL DATA VERIFICATION: 2. Draughtsman Portal', async () => {
  const res = await testRequest('/api/assignments', { token: 'TJjtkBm3lgRlpKtcI5u3jpYPH9s1' });
  assert.equal(res.status, 200);
  const data = await res.json();
  assert.ok(Array.isArray(data), 'Returns assignments array');
  assert.equal(data.length, 5, `Expected exactly 5 assignments for Draughtsman, got ${data.length}`);
  console.log(`✓ 2. Draughtsman Assignments Feed: ${data.length} assignments retrieved`);
  for (const a of data) {
    console.log(`   - Assignment ${a.id.slice(0, 8)}... [${a.status}] -> Project: ${a.project_name || a.project_id}`);
  }
});

test('PORTAL DATA VERIFICATION: 3. Student Portal - Modules, Metrics, Assignments, Portfolio & Credential', async () => {
  const studentUid = '2iypyxUntQX6djOzwjgPo5xWrGD2';

  // 1. Training Modules
  const modRes = await testRequest('/api/student/training/modules', { token: studentUid });
  assert.equal(modRes.status, 200);
  const modules = await modRes.json();
  const modArr = Array.isArray(modules) ? modules : modules.data;
  assert.equal(modArr.length, 3, `Expected 3 published modules, got ${modArr.length}`);
  console.log(`✓ 3a. Student Training Modules: ${modArr.length} modules available`);
  for (const m of modArr) {
    console.log(`   - ${m.id}: ${m.title} [${m.level}]`);
  }

  // 2. Student Practical Assignments
  const asgnRes = await testRequest('/api/student/assignments', { token: studentUid });
  assert.equal(asgnRes.status, 200);
  const asgns = await asgnRes.json();
  const asgnArr = Array.isArray(asgns) ? asgns : asgns.data;
  assert.equal(asgnArr.length, 2, `Expected 2 student practical projects, got ${asgnArr.length}`);
  console.log(`✓ 3b. Student Practical Assignments: ${asgnArr.length} assignments found`);
  for (const a of asgnArr) {
    console.log(`   - Assignment ${a.id}: Project ${a.project_name || a.project_id} [${a.status}]`);
  }

  // 3. Student Metrics & Studio Screen
  const metRes = await testRequest('/api/student/metrics', { token: studentUid });
  assert.equal(metRes.status, 200);
  const metrics = await metRes.json();
  console.log(`✓ 3c. Student Studio Metrics: Completed Projects=${metrics.activity.completedProjects}, Disciplines tracked=${metrics.disciplines.length}`);

  // 4. Student Portfolio
  const portRes = await testRequest('/api/student/portfolio', { token: studentUid });
  assert.equal(portRes.status, 200);
  const portData = await portRes.json();
  assert.ok(Array.isArray(portData.portfolio), 'Returns portfolio array');
  assert.equal(portData.portfolio.length, 2, `Expected 2 portfolio projects, got ${portData.portfolio.length}`);
  console.log(`✓ 3d. Student Portfolio: ${portData.portfolio.length} verified showcase projects rendered`);

  // 5. Student Credentials
  const crdRes = await testRequest('/api/student/credentials', { token: studentUid });
  assert.equal(crdRes.status, 200);
  const crds = await crdRes.json();
  const crdArr = Array.isArray(crds) ? crds : crds.data;
  assert.equal(crdArr.length, 1, `Expected 1 issued certificate, got ${crdArr.length}`);
  console.log(`✓ 3e. Student Issued Credentials: ${crdArr[0].title} (Token: ${crdArr[0].verificationToken})`);

  // 6. Security Invariant: Commercial Project Access Fence
  const commRes = await testRequest('/api/projects', { token: studentUid });
  assert.equal(commRes.status, 403, 'Commercial projects must be forbidden to Student');
  console.log('✓ 3f. Student RBAC Fence: Commercial projects feed strictly returns HTTP 403 Forbidden.');
});

test('PORTAL DATA VERIFICATION: 4. Admin Portal (Studio Administrator Primary)', async () => {
  const adminUid = 'bCrLwG8lMRbViDOrBmClwc96xJ42';

  const dashRes = await testRequest('/api/admin/dashboard', { token: adminUid });
  assert.equal(dashRes.status, 200);
  const dash = await dashRes.json();
  console.log('✓ 4a. Admin Dashboard Live KPIs:');
  console.log(`   - Total Projects:               ${dash.totalProjects}`);
  console.log(`   - Active Projects:              ${dash.activeProjects}`);
  console.log(`   - Completed Projects:           ${dash.completedProjects}`);
  console.log(`   - Projects Awaiting Assignment: ${dash.projectsAwaitingAssignment}`);
  console.log(`   - Active Draughtsmen:           ${dash.activeDraughtsmen}`);
  console.log(`   - Pending Assignments:          ${dash.pendingAssignments}`);
  console.log(`   - Registered Engineers:         ${dash.registeredEngineers}`);

  assert.equal(dash.totalProjects, 33, 'Total projects KPI matches');
  assert.equal(dash.completedProjects, 19, 'Completed projects KPI matches (17 commercial + 2 student)');
  assert.equal(dash.activeDraughtsmen, 3, 'Active draughtsmen count matches');

  // Admin All Projects
  const prjRes = await testRequest('/api/projects', { token: adminUid });
  assert.equal(prjRes.status, 200);
  const prjs = await prjRes.json();
  assert.equal(prjs.length, 33, `Admin should see all 33 projects, got ${prjs.length}`);
  console.log(`✓ 4b. Admin Unified Projects Feed: ${prjs.length} total projects visible`);

  // Admin Students Progress Directory
  const stuRes = await testRequest('/api/admin/students-progress', { token: adminUid });
  assert.equal(stuRes.status, 200);
  const stus = await stuRes.json();
  const stuArr = Array.isArray(stus) ? stus : (stus.data || stus.students);
  console.log(`✓ 4c. Admin Students Progress Directory: ${stuArr.length} student(s) tracked`);

  // Admin Student Submissions
  const subRes = await testRequest('/api/admin/student-submissions', { token: adminUid });
  assert.equal(subRes.status, 200);
  const subs = await subRes.json();
  const subArr = Array.isArray(subs) ? subs : subs.data;
  console.log(`✓ 4d. Admin Student Submissions: ${subArr.length} practical submissions available for grading`);

  // Admin Learning Plans
  const lpRes = await testRequest('/api/admin/learning-plans', { token: adminUid });
  assert.equal(lpRes.status, 200);
  const lps = await lpRes.json();
  const lpArr = Array.isArray(lps) ? lps : lps.data;
  console.log(`✓ 4e. Admin Learning Plans: ${lpArr.length} learning plan allocations active`);
});

test('PORTAL DATA VERIFICATION: 5. STUDIO_ADMIN Portal (Secondary Studio Admin)', async () => {
  const secondaryAdminUid = 'QBhduHDU1mYUxvtQ89adVnwQYCg1';

  const dashRes = await testRequest('/api/admin/dashboard', { token: secondaryAdminUid });
  assert.equal(dashRes.status, 200);
  const dash = await dashRes.json();
  assert.equal(dash.totalProjects, 33);
  assert.equal(dash.completedProjects, 19);
  console.log(`✓ 5. STUDIO_ADMIN Secondary Admin verified: Access to ${dash.totalProjects} total projects & ${dash.completedProjects} completed`);
});
