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

const bundlePath = path.join(workerRoot, 'node_modules', '.test_lesson_cert_bundle.mjs');
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
      db.exec('BEGIN TRANSACTION');
      try {
        for (const s of statements) {
          await s.run();
        }
        db.exec('COMMIT');
        return statements.map(() => ({ success: true }));
      } catch (e) {
        db.exec('ROLLBACK');
        throw e;
      }
    },
    raw: db
  };

  return { d1, sqlite: db };
}

function createMockStorage() {
  const store = new Map();
  return {
    async put(key, value, options) {
      store.set(key, { value, options });
      return { key };
    },
    async get(key) {
      if (!store.has(key)) return null;
      const item = store.get(key);
      return {
        body: item.value,
        httpEtag: 'test-etag',
        writeHttpMetadata(headers) {
          headers.set('Content-Type', item.options?.httpMetadata?.contentType || 'application/pdf');
        }
      };
    },
    async delete(key) {
      store.delete(key);
    },
    has(key) {
      return store.has(key);
    }
  };
}

test('Student Lesson Completion Certificate E2E Lifecycle', async (t) => {
  const { d1, sqlite } = createIsolatedTestDb();
  const storage = createMockStorage();

  const studentA = { id: 'student-alpha', name: 'Sarah Connor' };
  const studentB = { id: 'student-bravo', name: 'Kyle Reese' };

  sqlite.exec(`
    INSERT INTO users (id, email, name, role, status) VALUES
      ('student-alpha', 'alpha@archi.test', 'Sarah Connor', 'STUDENT', 'ACTIVE'),
      ('student-bravo', 'bravo@archi.test', 'Kyle Reese', 'STUDENT', 'ACTIVE');

    INSERT INTO legal_documents (id, document_type, version, title, content, effective_at, status, is_mandatory, locale)
    VALUES ('doc-terms-cert', 'TERMS_AND_CONDITIONS', '1.0.0', 'Platform Terms', '# Terms', CURRENT_TIMESTAMP, 'EFFECTIVE', 1, 'en-IN');

    INSERT INTO legal_consent_events (id, user_id, document_id, document_type, document_version, action_type, consent_purpose, idempotency_key, ip_hash, source)
    VALUES
      ('evt-terms-alpha', 'student-alpha', 'doc-terms-cert', 'TERMS_AND_CONDITIONS', '1.0.0', 'ACCEPT', 'DEFAULT', 'idem-alpha', 'hash', 'WEB'),
      ('evt-terms-bravo', 'student-bravo', 'doc-terms-cert', 'TERMS_AND_CONDITIONS', '1.0.0', 'ACCEPT', 'DEFAULT', 'idem-bravo', 'hash', 'WEB');

    INSERT INTO user_consent_state (id, user_id, consent_type, purpose_tag, current_status, accepted_version, last_event_id, updated_at)
    VALUES
      ('cst-alpha', 'student-alpha', 'TERMS', 'DEFAULT', 'ACCEPTED', '1.0.0', 'evt-terms-alpha', CURRENT_TIMESTAMP),
      ('cst-bravo', 'student-bravo', 'TERMS', 'DEFAULT', 'ACCEPTED', '1.0.0', 'evt-terms-bravo', CURRENT_TIMESTAMP);
  `);

  // Setup module, chapter, and lesson
  const moduleId = 'mod-foundation-01';
  sqlite.prepare(`
    INSERT INTO training_modules (id, title, description, category, type, level)
    VALUES (?, 'Reinforced Concrete Detailing', 'Structural foundation training', 'STRUCTURAL', 'LESSONS_ONLY', 'BEGINNER')
  `).run(moduleId);

  const chapterId = 'ch-01';
  sqlite.prepare(`
    INSERT INTO training_chapters (id, module_id, title, chapter_order)
    VALUES (?, ?, 'Foundation Systems', 1)
  `).run(chapterId, moduleId);

  const lessonId = 'les-rc-footing';
  const lessonExactTitle = 'Isolated Footing Reinforcement Detailing';
  sqlite.prepare(`
    INSERT INTO training_lessons (id, chapter_id, module_id, title, content, is_required, lesson_order)
    VALUES (?, ?, ?, ?, 'Detailed instructions on footing rebar schedules.', 1, 1)
  `).run(lessonId, chapterId, moduleId, lessonExactTitle);

  // Assign learning plan to Student A
  sqlite.prepare(`
    INSERT INTO student_learning_plans (id, student_id, module_id, assigned_by, status)
    VALUES ('lp-01', 'student-alpha', ?, 'admin-1', 'ASSIGNED')
  `).run(moduleId);

  const env = {
    DB: d1,
    STORAGE: storage,
    ENVIRONMENT: 'test',
    STAGING_TEST_ALLOWLIST: 'student-alpha,student-bravo'
  };

  await t.test('1. Student A completes required lesson and automatically receives issued certificate', async () => {
    const res = await app.request(`/api/student/training/lessons/${lessonId}/progress`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer mock-token:${studentA.id}`
      },
      body: JSON.stringify({ status: 'COMPLETED' })
    }, env);

    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.success, true);
    assert.equal(body.status, 'COMPLETED');
    assert.ok(body.certificate, 'Certificate payload must be returned');
    assert.match(body.certificate.id, /^DS-AD-LES-[A-Z0-9]+$/);
    assert.equal(body.certificate.title, lessonExactTitle);
    assert.equal(body.certificate.moduleTitle, 'Reinforced Concrete Detailing');
    assert.ok(body.certificate.verificationToken);
    assert.match(body.certificate.verifyUrl, new RegExp(`https://www.draughtsmanstudio.com/verify\\?id=${body.certificate.id}&token=${body.certificate.verificationToken}`));

    // Verify storage has PDF stored
    const expectedKey = `certificates/${studentA.id}/${body.certificate.id}.pdf`;
    assert.ok(storage.has(expectedKey), 'Certificate PDF must be saved to R2 storage');
  });

  await t.test('2. Completed lesson detail includes certificate metadata', async () => {
    const res = await app.request(`/api/student/training/lessons/${lessonId}`, {
      headers: {
        'Authorization': `Bearer mock-token:${studentA.id}`
      }
    }, env);

    assert.equal(res.status, 200);
    const lesson = await res.json();
    assert.equal(lesson.status, 'COMPLETED');
    assert.match(lesson.certificate_id, /^DS-AD-LES-/);
    assert.ok(lesson.verification_token);
  });

  await t.test('3. Student credentials list includes the issued certificate with module and lesson details', async () => {
    const res = await app.request('/api/student/credentials', {
      headers: {
        'Authorization': `Bearer mock-token:${studentA.id}`
      }
    }, env);

    assert.equal(res.status, 200);
    const creds = await res.json();
    assert.ok(creds.length >= 1);
    const cred = creds.find(c => c.type === 'LESSON_COMPLETION');
    assert.ok(cred, 'Must contain LESSON_COMPLETION credential');
    assert.equal(cred.title, lessonExactTitle);
    assert.equal(cred.lessonTitle, lessonExactTitle);
    assert.equal(cred.moduleTitle, 'Reinforced Concrete Detailing');
    assert.match(cred.id, /^DS-AD-LES-/);
    assert.ok(cred.verificationToken);
  });

  await t.test('4. Student can download their certificate PDF directly and self-healing regenerates if missing', async () => {
    const cred = sqlite.prepare("SELECT id, certificate_object_key FROM student_credentials WHERE student_id = ? AND type = 'LESSON_COMPLETION'").get(studentA.id);
    
    // Normal download from storage
    const res = await app.request(`/api/student/credentials/${cred.id}/certificate`, {
      headers: {
        'Authorization': `Bearer mock-token:${studentA.id}`
      }
    }, env);

    assert.equal(res.status, 200);
    assert.equal(res.headers.get('Content-Disposition'), `attachment; filename="Certificate_${cred.id}.pdf"`);
    const pdfBytes = await res.arrayBuffer();
    assert.ok(pdfBytes.byteLength > 100000, 'PDF size must be substantial (>100KB due to embedded template)');
    
    // Header check %PDF-1.4
    const head = new Uint8Array(pdfBytes.slice(0, 8));
    const magic = String.fromCharCode(...head);
    assert.match(magic, /%PDF-1\./);

    // Test self-healing: purge storage and ensure endpoint regenerates seamlessly
    await storage.delete(cred.certificate_object_key);
    assert.equal(storage.has(cred.certificate_object_key), false);

    const healedRes = await app.request(`/api/student/credentials/${cred.id}/certificate`, {
      headers: {
        'Authorization': `Bearer mock-token:${studentA.id}`
      }
    }, env);

    assert.equal(healedRes.status, 200);
    const healedBytes = await healedRes.arrayBuffer();
    assert.ok(healedBytes.byteLength > 100000);
    assert.ok(storage.has(cred.certificate_object_key), 'Storage entry was healed');
  });

  await t.test('5. Public verification succeeds using either verification token or certificate ID', async () => {
    const cred = sqlite.prepare("SELECT id, verification_token FROM student_credentials WHERE student_id = ? AND type = 'LESSON_COMPLETION'").get(studentA.id);

    // Verify via verification token
    const resToken = await app.request(`/api/public/credentials/verify/${cred.verification_token}`, {}, env);
    assert.equal(resToken.status, 200);
    const bodyToken = await resToken.json();
    assert.equal(bodyToken.valid, true);
    assert.equal(bodyToken.credential.id, cred.id);
    assert.equal(bodyToken.credential.recipientName, 'Sarah Connor');
    assert.equal(bodyToken.credential.title, lessonExactTitle);
    assert.equal(bodyToken.credential.lessonTitle, lessonExactTitle);
    assert.equal(bodyToken.credential.moduleTitle, 'Reinforced Concrete Detailing');
    assert.equal(bodyToken.credential.issuingAuthority, 'Draughtsman Studio & Archi Draft');

    // Verify via certificate ID (e.g. DS-AD-LES-XXXX)
    const resId = await app.request(`/api/public/credentials/verify/${cred.id}`, {}, env);
    assert.equal(resId.status, 200);
    const bodyId = await resId.json();
    assert.equal(bodyId.valid, true);
    assert.equal(bodyId.credential.id, cred.id);
    assert.equal(bodyId.credential.recipientName, 'Sarah Connor');

    // Non-existent certificate returns 404
    const res404 = await app.request('/api/public/credentials/verify/NON-EXISTENT-ID', {}, env);
    assert.equal(res404.status, 404);
    const body404 = await res404.json();
    assert.equal(body404.valid, false);

    // CORS verification from Draughtsman Studio domain
    const resCors = await app.request(`/api/public/credentials/verify/${cred.id}`, {
      headers: {
        'Origin': 'https://www.draughtsmanstudio.com'
      }
    }, env);
    assert.equal(resCors.status, 200);
    assert.equal(resCors.headers.get('Access-Control-Allow-Origin'), 'https://www.draughtsmanstudio.com');
    assert.equal(resCors.headers.get('Access-Control-Allow-Credentials'), 'true');

    // CORS verification from unapproved domain is rejected
    const resUnapprovedCors = await app.request(`/api/public/credentials/verify/${cred.id}`, {
      headers: {
        'Origin': 'https://evil-unapproved.com'
      }
    }, env);
    assert.equal(resUnapprovedCors.status, 200);
    assert.equal(resUnapprovedCors.headers.get('Access-Control-Allow-Origin'), null);

    // Non-GET requests require authentication (narrow exemption check)
    const resPost = await app.request(`/api/public/credentials/verify/${cred.id}`, {
      method: 'POST'
    }, env);
    assert.equal(resPost.status, 401);
  });

  await t.test('6. Student B cannot access or download Student A’s certificate (Strict Isolation)', async () => {
    const cred = sqlite.prepare('SELECT id FROM student_credentials WHERE student_id = ?').get(studentA.id);

    const resB = await app.request(`/api/student/credentials/${cred.id}/certificate`, {
      headers: {
        'Authorization': `Bearer mock-token:${studentB.id}`
      }
    }, env);

    assert.equal(resB.status, 404, 'Student B cannot see or download Student A credential');
  });

  await t.test('7. Idempotency: Re-submitting completed lesson preserves existing certificate ID', async () => {
    const credBefore = sqlite.prepare('SELECT id, verification_token FROM student_credentials WHERE student_id = ?').get(studentA.id);

    const res = await app.request(`/api/student/training/lessons/${lessonId}/progress`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer mock-token:${studentA.id}`
      },
      body: JSON.stringify({ status: 'COMPLETED' })
    }, env);

    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.certificate.id, credBefore.id, 'Must preserve existing certificate ID');
    assert.equal(body.certificate.verificationToken, credBefore.verification_token);
  });
});
