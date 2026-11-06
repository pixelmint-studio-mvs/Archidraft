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

const bundlePath = path.join(workerRoot, 'node_modules', '.test_reg_role_mapping_bundle.mjs');
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
  allocateIdentificationNumber,
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
      let buf;
      if (body instanceof Uint8Array || Buffer.isBuffer(body)) {
        buf = Buffer.from(body);
      } else if (typeof body === 'string') {
        buf = Buffer.from(body, 'utf8');
      } else if (body && typeof body.getReader === 'function') {
        const reader = body.getReader();
        const chunks = [];
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          chunks.push(value);
        }
        buf = Buffer.concat(chunks);
      } else {
        buf = Buffer.from('mock');
      }
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
  if (options.body && typeof options.body === 'object' && !(options.body instanceof Uint8Array) && !headers['Content-Type']) {
    headers['Content-Type'] = 'application/json';
  }

  const req = new Request(`http://localhost${path}`, {
    method: options.method || 'GET',
    headers,
    body: options.body ? (typeof options.body === 'string' || options.body instanceof Uint8Array ? options.body : JSON.stringify(options.body)) : undefined,
  });

  return await app.fetch(req, env);
}

test('Registration Role Mapping & Lifecycle Suite', async (t) => {
  const { rawDb, env } = createIsolatedTestDb();

  // Admin user
  rawDb.prepare(`
    INSERT INTO users (id, email, name, role, status, verification_status)
    VALUES ('admin-01', 'admin@draughtsmanstudio.com', 'Studio Admin', 'STUDIO_ADMIN', 'ACTIVE', 'APPROVED')
  `).run();

  await t.test('1. Engineer/Architect registration maps and persists to ENGINEER with ENG_ ID and degree certificate', async () => {
    const uid = 'eng-test-user-01';
    const dummyPdf = new Uint8Array([0x25, 0x50, 0x44, 0x46]);

    // Step A: Upload proof
    const uploadRes = await apiRequest(env, '/api/registration/proof', {
      method: 'POST',
      token: uid,
      headers: {
        'X-File-Name': 'btech_civil_degree.pdf',
        'Content-Type': 'application/pdf',
        'Content-Length': String(dummyPdf.length),
      },
      body: dummyPdf,
    });
    assert.strictEqual(uploadRes.status, 200);
    const uploadData = await uploadRes.json();

    // Step B: Submit registration as ENGINEER
    const submitRes = await apiRequest(env, '/api/registration/submit', {
      method: 'POST',
      token: uid,
      body: {
        name: 'Er. Arvind Sharma',
        email: 'arvind.sharma@engineerfirm.com',
        role: 'ENGINEER',
        mobile: '+91 98765 33333',
        company_name: 'Sharma Structural Consultants',
        proof_file_id: uploadData.file_id,
        proof_file_name: uploadData.file_name,
        proof_file_size: uploadData.file_size,
        proof_content_type: uploadData.content_type,
        proof_object_key: uploadData.object_key,
        proof_document_type: 'DEGREE_CERTIFICATE',
      },
    });
    assert.strictEqual(submitRes.status, 200);

    // Verify DB users row
    const user = rawDb.prepare('SELECT * FROM users WHERE id = ?').get(uid);
    assert.ok(user, 'User must exist in users table');
    assert.strictEqual(user.role, 'ENGINEER', 'Expected stored role to be ENGINEER, not STUDENT');
    assert.strictEqual(user.verification_status, 'PENDING');
    assert.match(user.identification_number, /^ENG_\d{2,}$/, 'Identification number must have ENG_ prefix');

    // Verify DB registration_verifications row
    const reg = rawDb.prepare('SELECT * FROM registration_verifications WHERE user_id = ?').get(uid);
    assert.ok(reg);
    assert.strictEqual(reg.role, 'ENGINEER');
    assert.strictEqual(reg.document_type, 'DEGREE_CERTIFICATE');

    // Verify /api/users/me returns ENGINEER
    const meRes = await apiRequest(env, '/api/users/me', { token: uid });
    assert.strictEqual(meRes.status, 200);
    const meData = await meRes.json();
    assert.strictEqual(meData.role, 'ENGINEER');
    assert.strictEqual(meData.identification_number, user.identification_number);
  });

  await t.test('2. Draughtsman registration maps and persists to DRAUGHTSMAN with DM_ ID and qualification certificate', async () => {
    const uid = 'drg-test-user-01';
    const dummyJpg = new Uint8Array([0xFF, 0xD8, 0xFF, 0xE0]);

    // Step A: Upload proof
    const uploadRes = await apiRequest(env, '/api/registration/proof', {
      method: 'POST',
      token: uid,
      headers: {
        'X-File-Name': 'draughtsman_cert.jpg',
        'Content-Type': 'image/jpeg',
        'Content-Length': String(dummyJpg.length),
      },
      body: dummyJpg,
    });
    assert.strictEqual(uploadRes.status, 200);
    const uploadData = await uploadRes.json();

    // Step B: Submit registration as DRAUGHTSMAN
    const submitRes = await apiRequest(env, '/api/registration/submit', {
      method: 'POST',
      token: uid,
      body: {
        name: 'Kavita Patel',
        email: 'kavita.patel@draughtsman.studio',
        role: 'DRAUGHTSMAN',
        mobile: '+91 98765 44444',
        qualification: 'Diploma in Civil Drafting',
        proof_file_id: uploadData.file_id,
        proof_file_name: uploadData.file_name,
        proof_file_size: uploadData.file_size,
        proof_content_type: uploadData.content_type,
        proof_object_key: uploadData.object_key,
        proof_document_type: 'QUALIFICATION_CERTIFICATE',
      },
    });
    assert.strictEqual(submitRes.status, 200);

    // Verify DB users row
    const user = rawDb.prepare('SELECT * FROM users WHERE id = ?').get(uid);
    assert.ok(user);
    assert.strictEqual(user.role, 'DRAUGHTSMAN', 'Expected stored role to be DRAUGHTSMAN');
    assert.strictEqual(user.verification_status, 'PENDING');
    assert.match(user.identification_number, /^DM_\d{2,}$/, 'Identification number must have DM_ prefix');

    // Verify DB registration_verifications row
    const reg = rawDb.prepare('SELECT * FROM registration_verifications WHERE user_id = ?').get(uid);
    assert.ok(reg);
    assert.strictEqual(reg.role, 'DRAUGHTSMAN');
    assert.strictEqual(reg.document_type, 'QUALIFICATION_CERTIFICATE');

    // Verify /api/users/me returns DRAUGHTSMAN
    const meRes = await apiRequest(env, '/api/users/me', { token: uid });
    assert.strictEqual(meRes.status, 200);
    const meData = await meRes.json();
    assert.strictEqual(meData.role, 'DRAUGHTSMAN');
  });

  await t.test('3. Student registration maps and persists to STUDENT with ST_ ID and student ID card', async () => {
    const uid = 'stu-test-user-01';
    const dummyPng = new Uint8Array([0x89, 0x50, 0x4E, 0x47]);

    // Step A: Upload proof
    const uploadRes = await apiRequest(env, '/api/registration/proof', {
      method: 'POST',
      token: uid,
      headers: {
        'X-File-Name': 'college_id.png',
        'Content-Type': 'image/png',
        'Content-Length': String(dummyPng.length),
      },
      body: dummyPng,
    });
    assert.strictEqual(uploadRes.status, 200);
    const uploadData = await uploadRes.json();

    // Step B: Submit registration as STUDENT
    const submitRes = await apiRequest(env, '/api/registration/submit', {
      method: 'POST',
      token: uid,
      body: {
        name: 'Rohan Mehra',
        email: 'rohan.mehra@engineeringcollege.edu',
        role: 'STUDENT',
        mobile: '+91 98765 55555',
        college_name: 'Government Engineering College',
        proof_file_id: uploadData.file_id,
        proof_file_name: uploadData.file_name,
        proof_file_size: uploadData.file_size,
        proof_content_type: uploadData.content_type,
        proof_object_key: uploadData.object_key,
        proof_document_type: 'STUDENT_ID',
      },
    });
    assert.strictEqual(submitRes.status, 200);

    // Verify DB users row
    const user = rawDb.prepare('SELECT * FROM users WHERE id = ?').get(uid);
    assert.ok(user);
    assert.strictEqual(user.role, 'STUDENT', 'Expected stored role to be STUDENT');
    assert.strictEqual(user.verification_status, 'PENDING');
    assert.match(user.identification_number, /^ST_\d{2,}$/, 'Identification number must have ST_ prefix');

    // Verify DB registration_verifications row
    const reg = rawDb.prepare('SELECT * FROM registration_verifications WHERE user_id = ?').get(uid);
    assert.ok(reg);
    assert.strictEqual(reg.role, 'STUDENT');
    assert.strictEqual(reg.document_type, 'STUDENT_ID');

    // Verify /api/users/me returns STUDENT
    const meRes = await apiRequest(env, '/api/users/me', { token: uid });
    assert.strictEqual(meRes.status, 200);
    const meData = await meRes.json();
    assert.strictEqual(meData.role, 'STUDENT');
  });

  await t.test('4. Race condition prevention: GET /api/users/me before registration does not lock user as STUDENT', async () => {
    const uid = 'eng-race-condition-uid';

    // Step A: Simulate Flutter authStateChanges immediately firing GET /api/users/me upon Firebase user creation
    const prematureMeRes = await apiRequest(env, '/api/users/me', { token: uid });
    assert.strictEqual(prematureMeRes.status, 404, 'Premature /api/users/me must return 404 and NOT insert a fake STUDENT');

    // Check DB: user should NOT be created as a student
    const prematureUser = rawDb.prepare('SELECT * FROM users WHERE id = ?').get(uid);
    assert.strictEqual(prematureUser, undefined, 'User must not be prematurely created in users table');

    // Step B: Now user finishes proof upload and calls /api/registration/submit as ENGINEER
    const dummyPdf = new Uint8Array([0x25, 0x50, 0x44, 0x46]);
    const uploadRes = await apiRequest(env, '/api/registration/proof', {
      method: 'POST',
      token: uid,
      headers: {
        'X-File-Name': 'engineer_degree_cert.pdf',
        'Content-Type': 'application/pdf',
        'Content-Length': String(dummyPdf.length),
      },
      body: dummyPdf,
    });
    assert.strictEqual(uploadRes.status, 200);
    const uploadData = await uploadRes.json();

    const submitRes = await apiRequest(env, '/api/registration/submit', {
      method: 'POST',
      token: uid,
      body: {
        name: 'Er. Meera Nair',
        email: 'meera.nair@structeng.com',
        role: 'ENGINEER',
        mobile: '+91 98765 66666',
        proof_file_id: uploadData.file_id,
        proof_file_name: uploadData.file_name,
        proof_file_size: uploadData.file_size,
        proof_content_type: uploadData.content_type,
        proof_object_key: uploadData.object_key,
        proof_document_type: 'DEGREE_CERTIFICATE',
      },
    });
    assert.strictEqual(submitRes.status, 200);

    // Stored role must be ENGINEER, not STUDENT
    const userInDb = rawDb.prepare('SELECT * FROM users WHERE id = ?').get(uid);
    assert.ok(userInDb);
    assert.strictEqual(userInDb.role, 'ENGINEER');
    assert.match(userInDb.identification_number, /^ENG_\d{2,}$/);

    // GET /api/users/me must now return ENGINEER
    const meRes = await apiRequest(env, '/api/users/me', { token: uid });
    assert.strictEqual(meRes.status, 200);
    const meData = await meRes.json();
    assert.strictEqual(meData.role, 'ENGINEER');
  });

  await t.test('5. Existing user desync recovery: POST /api/registration/submit updates role if user record pre-existed', async () => {
    const uid = 'drg-preexisting-uid';

    // Simulate an existing user row that was somehow created with role STUDENT and ST_ ID
    rawDb.prepare(`
      INSERT INTO users (id, email, name, role, verification_status, identification_number)
      VALUES (?, 'raj.draftsman@firm.com', 'Raj', 'STUDENT', 'PENDING', 'ST_99')
    `).run(uid);

    // Now submit registration as DRAUGHTSMAN
    const submitRes = await apiRequest(env, '/api/registration/submit', {
      method: 'POST',
      token: uid,
      body: {
        name: 'Raj Draughtsman',
        email: 'raj.draftsman@firm.com',
        role: 'DRAUGHTSMAN',
        mobile: '+91 98765 77777',
        proof_file_id: 'proof-drg-99',
        proof_file_name: 'diploma.pdf',
        proof_document_type: 'QUALIFICATION_CERTIFICATE',
      },
    });
    assert.strictEqual(submitRes.status, 200);

    // User table role MUST be updated from STUDENT to DRAUGHTSMAN
    const userInDb = rawDb.prepare('SELECT * FROM users WHERE id = ?').get(uid);
    assert.strictEqual(userInDb.role, 'DRAUGHTSMAN', 'Pre-existing user role must be updated to DRAUGHTSMAN');
    assert.match(userInDb.identification_number, /^DM_\d{2,}$/, 'Mismatched ST_ ID must be replaced with DM_ ID');
  });

  await t.test('6. Admin approval endpoint sets role to reg.role and ensures matching ID prefix', async () => {
    const uid = 'eng-approval-test-uid';

    // Simulate user who submitted as ENGINEER, but user record had STUDENT
    rawDb.prepare(`
      INSERT INTO users (id, email, name, role, verification_status, identification_number)
      VALUES (?, 'alok.architect@firm.com', 'Alok Nath', 'STUDENT', 'PENDING', 'ST_88')
    `).run(uid);

    const regId = 'reg-eng-alok-01';
    rawDb.prepare(`
      INSERT INTO registration_verifications (id, user_id, name, email, role, mobile, document_type, file_id, file_name, status)
      VALUES (?, ?, 'Alok Nath', 'alok.architect@firm.com', 'ENGINEER', '+919876588888', 'DEGREE_CERTIFICATE', 'f-1', 'degree.pdf', 'PENDING')
    `).run(regId, uid);

    // Admin approves the registration
    const approveRes = await apiRequest(env, `/api/admin/registrations/${regId}/approve`, {
      method: 'POST',
      token: 'admin-01',
    });
    assert.strictEqual(approveRes.status, 200);

    // DB verification: users.role MUST be ENGINEER, status APPROVED, ID prefix ENG_
    const userInDb = rawDb.prepare('SELECT * FROM users WHERE id = ?').get(uid);
    assert.strictEqual(userInDb.role, 'ENGINEER', 'Admin approval must set users.role = reg.role');
    assert.strictEqual(userInDb.verification_status, 'APPROVED');
    assert.match(userInDb.identification_number, /^ENG_\d{2,}$/, 'ID must have ENG_ prefix');
  });

  await t.test('7. Self-healing on GET /api/users/me synchronizes role and ID from authoritative registration', async () => {
    const uid = 'drg-desync-heal-uid';

    // Create desynchronized user: users has STUDENT with ST_77, but registration_verifications has DRAUGHTSMAN
    rawDb.prepare(`
      INSERT INTO users (id, email, name, role, verification_status, identification_number)
      VALUES (?, 'healed.drg@firm.com', 'Healed Draughtsman', 'STUDENT', 'PENDING', 'ST_77')
    `).run(uid);

    rawDb.prepare(`
      INSERT INTO registration_verifications (id, user_id, name, email, role, mobile, document_type, file_id, file_name, status)
      VALUES ('reg-heal-01', ?, 'Healed Draughtsman', 'healed.drg@firm.com', 'DRAUGHTSMAN', '+919876599999', 'QUALIFICATION_CERTIFICATE', 'f-2', 'cert.pdf', 'PENDING')
    `).run(uid);

    // User logs in or fetches /api/users/me
    const meRes = await apiRequest(env, '/api/users/me', { token: uid });
    assert.strictEqual(meRes.status, 200);
    const meData = await meRes.json();

    assert.strictEqual(meData.role, 'DRAUGHTSMAN', 'Self-healing must return DRAUGHTSMAN');
    assert.match(meData.identification_number, /^DM_\d{2,}$/, 'Self-healing must assign DM_ ID');

    // Verify DB was persisted
    const healedUser = rawDb.prepare('SELECT * FROM users WHERE id = ?').get(uid);
    assert.strictEqual(healedUser.role, 'DRAUGHTSMAN');
    assert.match(healedUser.identification_number, /^DM_\d{2,}$/);
  });
});

