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

const bundlePath = path.join(workerRoot, 'node_modules', '.test_role_id_bundle.mjs');
esbuild.buildSync({
  entryPoints: [path.join(workerRoot, 'src', 'index.ts')],
  bundle: true,
  format: 'esm',
  platform: 'node',
  write: true,
  outfile: bundlePath,
});

const {
  default: app,
  getRolePrefix,
  formatRoleId,
  allocateIdentificationNumber,
  backfillAllUserIdentificationNumbers
} = await import(`file://${bundlePath}`);

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
    }
  };

  const storageMap = new Map();
  const storage = {
    async put(key, body, options) {
      let buf = Buffer.from('mock');
      storageMap.set(key, { body: buf, size: buf.length, httpMetadata: options?.httpMetadata || {} });
      return { size: buf.length };
    },
    async get(key) {
      return storageMap.get(key) || null;
    },
    async delete(key) {
      storageMap.delete(key);
    }
  };

  const env = {
    DB: d1,
    STORAGE: storage,
    ENVIRONMENT: 'test',
  };

  return { rawDb: db, env, d1 };
}

async function apiRequest(env, path, options = {}) {
  const headers = { ...(options.headers || {}) };
  if (options.token !== false) {
    const rawToken = options.token || 'admin-01';
    const token = (rawToken.startsWith('mock-token:') || rawToken.startsWith('TEST_UID_'))
      ? rawToken
      : `mock-token:${rawToken}`;
    headers['Authorization'] = `Bearer ${token}`;
  }
  if (options.body && typeof options.body === 'object' && !headers['Content-Type']) {
    headers['Content-Type'] = 'application/json';
  }

  const req = new Request(`http://localhost${path}`, {
    method: options.method || 'GET',
    headers,
    body: options.body ? JSON.stringify(options.body) : undefined,
  });

  return await app.fetch(req, env);
}

test('Role-Based User Identification Number & Lifecycle Suite', async (t) => {
  const { rawDb, env, d1 } = createIsolatedTestDb();

  // Setup admin
  rawDb.prepare(`
    INSERT INTO users (id, email, name, role, status, verification_status)
    VALUES ('admin-01', 'admin@draughtsmanstudio.com', 'Studio Admin', 'STUDIO_ADMIN', 'ACTIVE', 'APPROVED')
  `).run();

  await t.test('1. Role prefix and format unit validation', () => {
    assert.strictEqual(getRolePrefix('ENGINEER'), 'ENG');
    assert.strictEqual(getRolePrefix('CLIENT'), 'ENG');
    assert.strictEqual(getRolePrefix('DRAUGHTSMAN'), 'DM');
    assert.strictEqual(getRolePrefix('STUDENT'), 'ST');
    assert.strictEqual(getRolePrefix('STUDIO_ADMIN'), null);

    assert.strictEqual(formatRoleId('ENG', 1), 'ENG_01');
    assert.strictEqual(formatRoleId('ENG', 9), 'ENG_09');
    assert.strictEqual(formatRoleId('ENG', 99), 'ENG_99');
    assert.strictEqual(formatRoleId('ENG', 100), 'ENG_100');
    assert.strictEqual(formatRoleId('DM', 5), 'DM_05');
    assert.strictEqual(formatRoleId('ST', 42), 'ST_42');
    assert.strictEqual(formatRoleId('ST', 150), 'ST_150');
  });

  await t.test('2. Sequential and independent generation across roles via registration', async () => {
    // 2 Engineers
    const eng1Res = await apiRequest(env, '/api/registration/submit', {
      token: 'uid-eng-1',
      method: 'POST',
      body: {
        name: 'Engineer One',
        email: 'eng1@firm.com',
        role: 'ENGINEER',
        mobile: '+919876543210',
        proof_file_id: 'proof-eng-1',
        proof_file_name: 'degree.pdf',
      }
    });
    assert.strictEqual(eng1Res.status, 200);

    const eng2Res = await apiRequest(env, '/api/registration/submit', {
      token: 'uid-eng-2',
      method: 'POST',
      body: {
        name: 'Engineer Two',
        email: 'eng2@firm.com',
        role: 'ENGINEER',
        mobile: '+919876543211',
        proof_file_id: 'proof-eng-2',
        proof_file_name: 'degree.pdf',
      }
    });
    assert.strictEqual(eng2Res.status, 200);

    // 2 Draughtsmen
    const dm1Res = await apiRequest(env, '/api/registration/submit', {
      token: 'uid-dm-1',
      method: 'POST',
      body: {
        name: 'Draughtsman One',
        email: 'dm1@studio.com',
        role: 'DRAUGHTSMAN',
        mobile: '+919876543212',
        proof_file_id: 'proof-dm-1',
        proof_file_name: 'diploma.pdf',
      }
    });
    assert.strictEqual(dm1Res.status, 200);

    const dm2Res = await apiRequest(env, '/api/registration/submit', {
      token: 'uid-dm-2',
      method: 'POST',
      body: {
        name: 'Draughtsman Two',
        email: 'dm2@studio.com',
        role: 'DRAUGHTSMAN',
        mobile: '+919876543213',
        proof_file_id: 'proof-dm-2',
        proof_file_name: 'diploma.pdf',
      }
    });
    assert.strictEqual(dm2Res.status, 200);

    // 2 Students
    const st1Res = await apiRequest(env, '/api/registration/submit', {
      token: 'uid-st-1',
      method: 'POST',
      body: {
        name: 'Student One',
        email: 'st1@univ.edu',
        role: 'STUDENT',
        mobile: '+919876543214',
        proof_file_id: 'proof-st-1',
        proof_file_name: 'student_id.pdf',
      }
    });
    assert.strictEqual(st1Res.status, 200);

    const st2Res = await apiRequest(env, '/api/registration/submit', {
      token: 'uid-st-2',
      method: 'POST',
      body: {
        name: 'Student Two',
        email: 'st2@univ.edu',
        role: 'STUDENT',
        mobile: '+919876543215',
        proof_file_id: 'proof-st-2',
        proof_file_name: 'student_id.pdf',
      }
    });
    assert.strictEqual(st2Res.status, 200);

    // Verify IDs in rawDb
    const eng1 = rawDb.prepare('SELECT identification_number FROM users WHERE id = ?').get('uid-eng-1');
    const eng2 = rawDb.prepare('SELECT identification_number FROM users WHERE id = ?').get('uid-eng-2');
    const dm1 = rawDb.prepare('SELECT identification_number FROM users WHERE id = ?').get('uid-dm-1');
    const dm2 = rawDb.prepare('SELECT identification_number FROM users WHERE id = ?').get('uid-dm-2');
    const st1 = rawDb.prepare('SELECT identification_number FROM users WHERE id = ?').get('uid-st-1');
    const st2 = rawDb.prepare('SELECT identification_number FROM users WHERE id = ?').get('uid-st-2');

    assert.strictEqual(eng1.identification_number, 'ENG_01');
    assert.strictEqual(eng2.identification_number, 'ENG_02');
    assert.strictEqual(dm1.identification_number, 'DM_01');
    assert.strictEqual(dm2.identification_number, 'DM_02');
    assert.strictEqual(st1.identification_number, 'ST_01');
    assert.strictEqual(st2.identification_number, 'ST_02');
  });

  await t.test('3. Idempotency: Repeated registration does not duplicate ID or alter existing ID', async () => {
    // Re-submit for uid-eng-1
    const retryRes = await apiRequest(env, '/api/registration/submit', {
      token: 'uid-eng-1',
      method: 'POST',
      body: {
        name: 'Engineer One Updated',
        email: 'eng1@firm.com',
        role: 'ENGINEER',
        mobile: '+919876543210',
        proof_file_id: 'proof-eng-1-new',
        proof_file_name: 'degree_new.pdf',
      }
    });
    assert.strictEqual(retryRes.status, 200);

    const eng1 = rawDb.prepare('SELECT identification_number FROM users WHERE id = ?').get('uid-eng-1');
    assert.strictEqual(eng1.identification_number, 'ENG_01', 'ID must remain permanent and unchanged');

    // Sequence for ENG should still be 2, next user gets ENG_03
    const eng3Id = await allocateIdentificationNumber(d1, 'ENGINEER');
    assert.strictEqual(eng3Id, 'ENG_03');
  });

  await t.test('4. Profile endpoints return identification_number accurately', async () => {
    // Approve dm-1 so profile endpoints can be accessed
    rawDb.prepare("UPDATE users SET verification_status = 'APPROVED' WHERE id = 'uid-dm-1'").run();

    const profileRes = await apiRequest(env, '/api/users/profile', {
      token: 'uid-dm-1',
      method: 'GET'
    });
    assert.strictEqual(profileRes.status, 200);
    const profile = await profileRes.json();
    assert.strictEqual(profile.identification_number, 'DM_01');

    const meRes = await apiRequest(env, '/api/users/me', {
      token: 'uid-dm-1',
      method: 'GET'
    });
    assert.strictEqual(meRes.status, 200);
    const me = await meRes.json();
    assert.strictEqual(me.identification_number, 'DM_01');
  });

  await t.test('5. Profile edits preserve ID and do not regenerate or delete it', async () => {
    const editRes = await apiRequest(env, '/api/users/me', {
      token: 'uid-dm-1',
      method: 'PATCH',
      body: {
        name: 'Draughtsman One Edited',
        mobile: '+919888877777',
        address: 'New Studio Address 101',
      }
    });
    assert.strictEqual(editRes.status, 200);
    const updated = await editRes.json();
    assert.strictEqual(updated.name, 'Draughtsman One Edited');
    assert.strictEqual(updated.identification_number, 'DM_01', 'ID must remain unchanged after profile patch');
  });

  await t.test('6. Admin registrations listing returns identification_number', async () => {
    const regRes = await apiRequest(env, '/api/admin/registrations', {
      token: 'admin-01',
      method: 'GET'
    });
    assert.strictEqual(regRes.status, 200);
    const regs = await regRes.json();
    const stReg = regs.find(r => r.user_id === 'uid-st-1');
    assert.ok(stReg);
    assert.strictEqual(stReg.identification_number, 'ST_01');
  });

  await t.test('7. Search by identification_number in Admin registrations', async () => {
    const searchRes = await apiRequest(env, '/api/admin/registrations?search=ST_02', {
      token: 'admin-01',
      method: 'GET'
    });
    assert.strictEqual(searchRes.status, 200);
    const results = await searchRes.json();
    assert.strictEqual(results.length, 1);
    assert.strictEqual(results[0].identification_number, 'ST_02');
  });

  await t.test('8. Lookup user by ID in /api/users/:id supports identification_number', async () => {
    const lookupRes = await apiRequest(env, '/api/users/DM_01', {
      token: 'admin-01',
      method: 'GET'
    });
    assert.strictEqual(lookupRes.status, 200);
    const user = await lookupRes.json();
    assert.strictEqual(user.id, 'uid-dm-1');
    assert.strictEqual(user.identification_number, 'DM_01');
  });

  await t.test('9. Existing user backfill migration allocates IDs and updates sequence correctly', async () => {
    // Insert 2 legacy unnumbered students
    rawDb.prepare(`
      INSERT INTO users (id, email, name, role, created_at)
      VALUES
        ('legacy-st-1', 'legacy1@univ.edu', 'Legacy Student 1', 'STUDENT', '2025-01-01 10:00:00'),
        ('legacy-st-2', 'legacy2@univ.edu', 'Legacy Student 2', 'STUDENT', '2025-01-02 10:00:00')
    `).run();

    // Call backfill function
    const backfillResult = await backfillAllUserIdentificationNumbers(d1);
    assert.ok(backfillResult.ST.assignedCount >= 2);

    const leg1 = rawDb.prepare('SELECT identification_number FROM users WHERE id = ?').get('legacy-st-1');
    const leg2 = rawDb.prepare('SELECT identification_number FROM users WHERE id = ?').get('legacy-st-2');

    assert.ok(leg1.identification_number.startsWith('ST_'));
    assert.ok(leg2.identification_number.startsWith('ST_'));
    assert.notStrictEqual(leg1.identification_number, leg2.identification_number);

    // Re-running backfill is completely idempotent
    const rerunResult = await backfillAllUserIdentificationNumbers(d1);
    assert.strictEqual(rerunResult.ST.assignedCount, 0, 'Re-running backfill should assign 0 new users');
  });

  await t.test('10. Self-healing schema initialization creates role_id_sequences dynamically if absent', async () => {
    // Drop sequences table and simulate un-migrated database
    rawDb.exec('DROP TABLE IF EXISTS role_id_sequences;');

    // Call allocateIdentificationNumber which triggers ensureIdentificationSchema
    const allocated = await allocateIdentificationNumber(d1, 'STUDENT');
    assert.ok(allocated, 'Should successfully allocate ID after self-healing schema initialization');
    assert.ok(allocated.startsWith('ST_'));

    // Check table was recreated
    const tableCheck = rawDb.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='role_id_sequences'").get();
    assert.ok(tableCheck, 'role_id_sequences table must be auto-created by ensureIdentificationSchema');
  });
});

