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

const bundlePath = path.join(workerRoot, 'node_modules', '.test_app_registration_bundle.mjs');
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
        buf = Buffer.concat(chunks.map(c => Buffer.from(c)));
      } else {
        buf = Buffer.from('mock');
      }
      storageMap.set(key, {
        body: buf,
        size: buf.length,
        httpMetadata: options?.httpMetadata || {},
        httpEtag: 'mock-etag',
        writeHttpMetadata(headers) {
          if (options?.httpMetadata?.contentType) {
            headers.set('content-type', options.httpMetadata.contentType);
          }
        }
      });
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

  return { rawDb: db, env };
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

test('Registration Proof Verification, Admin Approval, and Email Workflow', async (t) => {
  const { rawDb, env } = createIsolatedTestDb();

  // Seed Admin user
  rawDb.prepare(`
    INSERT INTO users (id, email, name, role, status, verification_status)
    VALUES ('admin-01', 'admin@draughtsmanstudio.com', 'Studio Admin', 'STUDIO_ADMIN', 'ACTIVE', 'APPROVED')
  `).run();

  await t.test('1. Proof Upload Validation: Rejects invalid file types and oversized files', async () => {
    // Attempt upload with invalid extension (.exe)
    const invalidExtRes = await apiRequest(env, '/api/registration/proof', {
      method: 'POST',
      token: 'eng-applicant-01',
      headers: {
        'X-File-Name': 'malicious_degree.exe',
        'Content-Type': 'application/octet-stream',
        'Content-Length': '100',
      },
      body: new Uint8Array([0x4D, 0x5A, 0x90]),
    });
    assert.equal(invalidExtRes.status, 400);
    const extErr = await invalidExtRes.json();
    assert.equal(extErr.code, 'INVALID_FILE_TYPE');

    // Attempt upload with oversized file (> 10MB)
    const oversizedRes = await apiRequest(env, '/api/registration/proof', {
      method: 'POST',
      token: 'eng-applicant-01',
      headers: {
        'X-File-Name': 'huge_degree.pdf',
        'Content-Type': 'application/pdf',
        'Content-Length': String(11 * 1024 * 1024),
      },
      body: new Uint8Array(10),
    });
    assert.equal(oversizedRes.status, 400);
    const sizeErr = await oversizedRes.json();
    assert.equal(sizeErr.code, 'FILE_TOO_LARGE');
  });

  await t.test('2. Engineer Registration with Degree Certificate Proof', async () => {
    // Step A: Upload proof file
    const dummyPdf = new Uint8Array([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34]);
    const uploadRes = await apiRequest(env, '/api/registration/proof', {
      method: 'POST',
      token: 'eng-applicant-01',
      headers: {
        'X-File-Name': 'btech_civil_degree.pdf',
        'Content-Type': 'application/pdf',
        'Content-Length': String(dummyPdf.length),
      },
      body: dummyPdf,
    });
    assert.equal(uploadRes.status, 200);
    const uploadData = await uploadRes.json();
    assert.equal(uploadData.success, true);
    assert.equal(uploadData.file_name, 'btech_civil_degree.pdf');
    assert.ok(uploadData.file_id);
    assert.ok(uploadData.object_key);

    // Step B: Submit registration form
    const regRes = await apiRequest(env, '/api/registration/submit', {
      method: 'POST',
      token: 'eng-applicant-01',
      body: {
        name: 'Er. Rajesh Kumar',
        email: 'rajesh.kumar@engineerfirm.com',
        role: 'ENGINEER',
        mobile: '+91 98765 11111',
        company_name: 'Kumar & Associates',
        proof_file_id: uploadData.file_id,
        proof_file_name: uploadData.file_name,
        proof_file_size: uploadData.file_size,
        proof_content_type: uploadData.content_type,
        proof_object_key: uploadData.object_key,
        proof_document_type: 'Engineering degree or relevant qualification certificate',
      },
    });
    assert.equal(regRes.status, 200);
    const regData = await regRes.json();
    assert.equal(regData.success, true);
    assert.equal(regData.verification_status, 'PENDING');

    // Step C: Verify user and registration records in DB
    const userInDb = rawDb.prepare('SELECT * FROM users WHERE id = ?').get('eng-applicant-01');
    assert.ok(userInDb);
    assert.equal(userInDb.verification_status, 'PENDING');
    assert.equal(userInDb.role, 'ENGINEER');

    const regInDb = rawDb.prepare('SELECT * FROM registration_verifications WHERE user_id = ?').get('eng-applicant-01');
    assert.ok(regInDb);
    assert.equal(regInDb.status, 'PENDING');
    assert.equal(regInDb.file_name, 'btech_civil_degree.pdf');

    // Step D: Verify exact registration acknowledgement email logged
    const emailLog = rawDb.prepare(`
      SELECT * FROM email_logs WHERE LOWER(recipient_email) = LOWER(?) AND template_type = 'REGISTRATION_RECEIVED'
    `).get('rajesh.kumar@engineerfirm.com');
    assert.ok(emailLog);
    assert.equal(emailLog.subject, 'Archi Draft Registration Received');
    assert.match(emailLog.details, /Dear Er\. Rajesh Kumar/);
    assert.match(emailLog.details, /Your registration status: Pending Review/);
    assert.match(emailLog.details, /\*\*Archi Draft Team\*\*\s+Draughtsman Studio/);
  });

  await t.test('3. Draughtsman Registration with Qualification Certificate Proof', async () => {
    const dummyJpg = new Uint8Array([0xFF, 0xD8, 0xFF, 0xE0]);
    const uploadRes = await apiRequest(env, '/api/registration/proof', {
      method: 'POST',
      token: 'drg-applicant-01',
      headers: {
        'X-File-Name': 'draughtsman_diploma.jpg',
        'Content-Type': 'image/jpeg',
        'Content-Length': String(dummyJpg.length),
      },
      body: dummyJpg,
    });
    assert.equal(uploadRes.status, 200);
    const uploadData = await uploadRes.json();

    const regRes = await apiRequest(env, '/api/registration/submit', {
      method: 'POST',
      token: 'drg-applicant-01',
      body: {
        name: 'Suresh Patel',
        email: 'suresh.patel@draughtsman.studio',
        role: 'DRAUGHTSMAN',
        mobile: '+91 98765 22222',
        qualification: 'Diploma in Civil Draughtsmanship',
        proof_file_id: uploadData.file_id,
        proof_file_name: uploadData.file_name,
        proof_file_size: uploadData.file_size,
        proof_content_type: uploadData.content_type,
        proof_object_key: uploadData.object_key,
        proof_document_type: 'Draughtsmanship degree, diploma, or relevant qualification certificate',
      },
    });
    assert.equal(regRes.status, 200);

    const user = rawDb.prepare('SELECT * FROM users WHERE id = ?').get('drg-applicant-01');
    assert.equal(user.verification_status, 'PENDING');
  });

  await t.test('4. Student Registration with Valid Student ID Card', async () => {
    const dummyPng = new Uint8Array([0x89, 0x50, 0x4E, 0x47]);
    const uploadRes = await apiRequest(env, '/api/registration/proof', {
      method: 'POST',
      token: 'stu-applicant-01',
      headers: {
        'X-File-Name': 'college_id_card.png',
        'Content-Type': 'image/png',
        'Content-Length': String(dummyPng.length),
      },
      body: dummyPng,
    });
    assert.equal(uploadRes.status, 200);
    const uploadData = await uploadRes.json();

    const regRes = await apiRequest(env, '/api/registration/submit', {
      method: 'POST',
      token: 'stu-applicant-01',
      body: {
        name: 'Anita Desai',
        email: 'anita.desai@architecture.edu',
        role: 'STUDENT',
        mobile: '+91 98765 33333',
        college_name: 'National School of Architecture',
        proof_file_id: uploadData.file_id,
        proof_file_name: uploadData.file_name,
        proof_file_size: uploadData.file_size,
        proof_content_type: uploadData.content_type,
        proof_object_key: uploadData.object_key,
        proof_document_type: 'Valid Student ID card',
      },
    });
    assert.equal(regRes.status, 200);

    const user = rawDb.prepare('SELECT * FROM users WHERE id = ?').get('stu-applicant-01');
    assert.equal(user.verification_status, 'PENDING');
  });

  await t.test('5. Mandatory Proof Validation: Registration fails if proof is missing', async () => {
    const noProofRes = await apiRequest(env, '/api/registration/submit', {
      method: 'POST',
      token: 'no-proof-user',
      body: {
        name: 'No Proof User',
        email: 'noproof@test.com',
        role: 'ENGINEER',
      },
    });
    assert.equal(noProofRes.status, 400);
    const err = await noProofRes.json();
    assert.equal(err.code, 'PROOF_REQUIRED');
  });

  await t.test('6. Backend Access Enforcement: PENDING user is BLOCKED from protected features', async () => {
    // Engineer trying to create a project while PENDING
    const projRes = await apiRequest(env, '/api/projects', {
      method: 'POST',
      token: 'eng-applicant-01',
      body: {
        project_name: 'Skyline Tower',
        project_address: '123 High St',
        drawing_name: 'Structural Plan',
        drawing_type: 'STRUCTURAL',
        project_area: '1500',
      },
    });
    assert.equal(projRes.status, 403);
    const projErr = await projRes.json();
    assert.equal(projErr.code, 'REGISTRATION_PENDING');

    // But PENDING user CAN check /api/users/me and /api/registration/status
    const meRes = await apiRequest(env, '/api/users/me', {
      token: 'eng-applicant-01',
    });
    assert.equal(meRes.status, 200);
    const meData = await meRes.json();
    assert.equal(meData.verification_status, 'PENDING');
    assert.ok(meData.registration);

    const statusRes = await apiRequest(env, '/api/registration/status', {
      token: 'eng-applicant-01',
    });
    assert.equal(statusRes.status, 200);
    const statusData = await statusRes.json();
    assert.equal(statusData.verification_status, 'PENDING');

    // And user can access their own uploaded proof
    const proofRes = await apiRequest(env, '/api/registration/proof', {
      token: 'eng-applicant-01',
    });
    assert.equal(proofRes.status, 200);
  });

  await t.test('7. Admin Portal: Review Queue, Search, Filters, and Proof Access', async () => {
    // Non-admin is DENIED access to /api/admin/registrations
    const unauthRes = await apiRequest(env, '/api/admin/registrations', {
      token: 'eng-applicant-01',
    });
    assert.equal(unauthRes.status, 403);

    // Admin lists all registrations
    const listRes = await apiRequest(env, '/api/admin/registrations', {
      token: 'admin-01',
    });
    assert.equal(listRes.status, 200);
    const list = await listRes.json();
    assert.equal(list.length, 3); // 3 applicants registered above

    // Search by name
    const searchRes = await apiRequest(env, '/api/admin/registrations?search=Rajesh', {
      token: 'admin-01',
    });
    assert.equal(searchRes.status, 200);
    const searchResults = await searchRes.json();
    assert.equal(searchResults.length, 1);
    assert.equal(searchResults[0].name, 'Er. Rajesh Kumar');

    // Filter by role
    const studentFilterRes = await apiRequest(env, '/api/admin/registrations?role=STUDENT', {
      token: 'admin-01',
    });
    assert.equal(studentFilterRes.status, 200);
    const studentList = await studentFilterRes.json();
    assert.equal(studentList.length, 1);
    assert.equal(studentList[0].role, 'STUDENT');

    // Admin downloads proof document securely
    const regItem = list.find(r => r.name === 'Er. Rajesh Kumar');
    const adminProofRes = await apiRequest(env, `/api/admin/registrations/${regItem.id}/proof`, {
      token: 'admin-01',
    });
    assert.equal(adminProofRes.status, 200);
  });

  await t.test('8. Admin Approval Workflow: Grants access & sends approval email', async () => {
    const regItem = rawDb.prepare("SELECT * FROM registration_verifications WHERE user_id = 'eng-applicant-01'").get();

    // Admin approves Engineer registration
    const approveRes = await apiRequest(env, `/api/admin/registrations/${regItem.id}/approve`, {
      method: 'POST',
      token: 'admin-01',
    });
    assert.equal(approveRes.status, 200);
    const approveData = await approveRes.json();
    assert.equal(approveData.success, true);
    assert.equal(approveData.registration.status, 'APPROVED');
    assert.equal(approveData.registration.reviewed_by, 'admin-01');
    assert.ok(approveData.registration.reviewed_at);

    // Verify user in DB is now APPROVED
    const userAfter = rawDb.prepare('SELECT verification_status FROM users WHERE id = ?').get('eng-applicant-01');
    assert.equal(userAfter.verification_status, 'APPROVED');

    // Verify approval notification email was dispatched
    const approveEmail = rawDb.prepare(`
      SELECT * FROM email_logs WHERE LOWER(recipient_email) = LOWER(?) AND template_type = 'REGISTRATION_APPROVED'
    `).get('rajesh.kumar@engineerfirm.com');
    assert.ok(approveEmail);
    assert.equal(approveEmail.subject, 'Archi Draft Registration Approved');

    // Self-approval is FORBIDDEN
    const selfApproveRes = await apiRequest(env, `/api/admin/registrations/${regItem.id}/approve`, {
      method: 'POST',
      token: 'eng-applicant-01', // eng-applicant trying to approve someone or themselves
    });
    assert.equal(selfApproveRes.status, 403); // Non-admin cannot call approve
  });

  await t.test('9. Admin Rejection Workflow: Restricts access, records reason, & sends rejection email', async () => {
    const regItem = rawDb.prepare("SELECT * FROM registration_verifications WHERE user_id = 'drg-applicant-01'").get();

    // Admin rejects Draughtsman registration with reason
    const rejectRes = await apiRequest(env, `/api/admin/registrations/${regItem.id}/reject`, {
      method: 'POST',
      token: 'admin-01',
      body: {
        reason: 'The qualification diploma certificate provided is illegible. Please re-scan and contact administration.',
      },
    });
    assert.equal(rejectRes.status, 200);
    const rejectData = await rejectRes.json();
    assert.equal(rejectData.success, true);
    assert.equal(rejectData.registration.status, 'REJECTED');
    assert.match(rejectData.registration.rejection_reason, /illegible/);

    // Verify user in DB is REJECTED
    const userAfter = rawDb.prepare('SELECT verification_status, rejection_reason FROM users WHERE id = ?').get('drg-applicant-01');
    assert.equal(userAfter.verification_status, 'REJECTED');
    assert.match(userAfter.rejection_reason, /illegible/);

    // Verify rejection notification email was dispatched
    const rejectEmail = rawDb.prepare(`
      SELECT * FROM email_logs WHERE LOWER(recipient_email) = LOWER(?) AND template_type = 'REGISTRATION_REJECTED'
    `).get('suresh.patel@draughtsman.studio');
    assert.ok(rejectEmail);
    assert.equal(rejectEmail.subject, 'Archi Draft Registration Update');
    assert.match(rejectEmail.details, /illegible/);

    // Rejected user is restricted from protected features
    const protectedRes = await apiRequest(env, '/api/projects', {
      method: 'POST',
      token: 'drg-applicant-01',
      body: { project_name: 'Test' },
    });
    assert.equal(protectedRes.status, 403);
    const err = await protectedRes.json();
    assert.equal(err.code, 'REGISTRATION_REJECTED');
    assert.match(err.rejection_reason, /illegible/);
  });
});
