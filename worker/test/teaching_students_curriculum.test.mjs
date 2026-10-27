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

const bundlePath = path.join(workerRoot, 'node_modules', '.test_teaching_students_bundle.mjs');
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
      for (const s of statements) {
        await s.run();
      }
      return { success: true };
    }
  };

  return { rawDb: db, d1 };
}

function createMockEnv(d1) {
  return {
    DB: d1,
    R2_BUCKET: {
      async get() { return null; },
      async put() { return { key: 'test' }; }
    },
    PROJECT_FILES_BUCKET: {
      async get() { return null; },
      async put() { return { key: 'test' }; }
    },
    NOTIFICATION_SERVICE_KEY: 'test-key',
    RATE_LIMITER: {
      async limit() { return { success: true }; }
    }
  };
}

test('Teaching Students Curriculum & Progress — Full End-to-End Suite', async (t) => {
  const { rawDb, d1 } = createIsolatedTestDb();
  const env = createMockEnv(d1);

  // Seed Admin, Student A, Student B
  rawDb.exec(`
    INSERT INTO users (id, email, name, role, status) VALUES
      ('admin-1', 'admin@archidraft.com', 'Studio Administrator', 'STUDIO_ADMIN', 'ACTIVE'),
      ('student-a', 'student.a@college.edu', 'Student Alice', 'STUDENT', 'ACTIVE'),
      ('student-b', 'student.b@college.edu', 'Student Bob', 'STUDENT', 'ACTIVE');

    INSERT INTO legal_documents (id, document_type, version, title, content, effective_at, status, is_mandatory, locale)
    VALUES ('doc-terms-ts', 'TERMS_AND_CONDITIONS', '1.0.0', 'Platform Terms', '# Terms', CURRENT_TIMESTAMP, 'EFFECTIVE', 1, 'en-IN');

    INSERT INTO legal_consent_events (id, user_id, document_id, document_type, document_version, action_type, consent_purpose, idempotency_key, ip_hash, source)
    VALUES
      ('evt-terms-a', 'student-a', 'doc-terms-ts', 'TERMS_AND_CONDITIONS', '1.0.0', 'ACCEPT', 'DEFAULT', 'idem-a', 'hash', 'WEB'),
      ('evt-terms-b', 'student-b', 'doc-terms-ts', 'TERMS_AND_CONDITIONS', '1.0.0', 'ACCEPT', 'DEFAULT', 'idem-b', 'hash', 'WEB');

    INSERT INTO user_consent_state (id, user_id, consent_type, purpose_tag, current_status, accepted_version, last_event_id, updated_at)
    VALUES
      ('cst-a', 'student-a', 'TERMS', 'DEFAULT', 'ACCEPTED', '1.0.0', 'evt-terms-a', CURRENT_TIMESTAMP),
      ('cst-b', 'student-b', 'TERMS', 'DEFAULT', 'ACCEPTED', '1.0.0', 'evt-terms-b', CURRENT_TIMESTAMP);
  `);

  let createdModuleId = '';
  let chapterId = '';
  let reqLessonId = '';
  let optLessonId = '';

  await t.test('1. Admin creates a persistent training module', async () => {
    const res = await app.request('/api/admin/training/modules', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer mock-token:admin-1',
      },
      body: JSON.stringify({
        title: 'Municipal Regulations & Setback Compliance',
        category: 'Approval',
        level: 'Intermediate',
        description: 'Comprehensive zoning, setback guidelines, and FAR calculation.',
        learning_objectives: '1. Calculate FAR. 2. Produce permit blueprints.',
        publication_status: 'PUBLISHED',
      }),
    }, env);

    assert.equal(res.status, 201);
    const body = await res.json();
    assert.equal(body.success, true);
    assert.ok(body.id);
    createdModuleId = body.id;

    // Verify persisted in DB
    const row = rawDb.prepare('SELECT * FROM training_modules WHERE id = ?').get(createdModuleId);
    assert.ok(row);
    assert.equal(row.title, 'Municipal Regulations & Setback Compliance');
    assert.equal(row.publication_status, 'PUBLISHED');
  });

  await t.test('2. Admin adds chapters and lessons with resources & requirement flags', async () => {
    // Add Chapter
    const chRes = await app.request(`/api/admin/training/modules/${createdModuleId}/chapters`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer mock-token:admin-1',
      },
      body: JSON.stringify({
        title: 'Chapter 01: Setback Geometries',
        description: 'Front, rear, and side setback calculations',
        chapter_order: 1,
      }),
    }, env);

    assert.equal(chRes.status, 201);
    const chBody = await chRes.json();
    chapterId = chBody.id;

    // Add Required Lesson
    const les1Res = await app.request(`/api/admin/training/modules/${createdModuleId}/lessons`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer mock-token:admin-1',
      },
      body: JSON.stringify({
        title: 'Front Setback Standards',
        chapter_id: chapterId,
        content: 'Front setbacks must adhere to municipal road-width standards.',
        estimated_duration: '15 mins',
        is_required: true,
        resources: [
          { id: 'res-1', name: 'Zoning_Table.pdf', url: 'https://example.com/zoning.pdf', type: 'PDF' }
        ],
      }),
    }, env);

    assert.equal(les1Res.status, 201);
    const les1Body = await les1Res.json();
    reqLessonId = les1Body.id;

    // Add Optional Lesson
    const les2Res = await app.request(`/api/admin/training/modules/${createdModuleId}/lessons`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer mock-token:admin-1',
      },
      body: JSON.stringify({
        title: 'Historical Heritage Exemptions',
        chapter_id: chapterId,
        content: 'Exemption clauses for designated heritage areas.',
        estimated_duration: '10 mins',
        is_required: false,
      }),
    }, env);

    assert.equal(les2Res.status, 201);
    const les2Body = await les2Res.json();
    optLessonId = les2Body.id;
  });

  await t.test('3. Student B cannot access unassigned module (Strict Backend Isolation)', async () => {
    // Student B requests module list -> should be empty
    const listRes = await app.request('/api/student/training/modules', {
      headers: { 'Authorization': 'Bearer mock-token:student-b' },
    }, env);
    assert.equal(listRes.status, 200);
    const listBody = await listRes.json();
    assert.equal(listBody.length, 0);

    // Student B tries to fetch the module directly -> 403 Forbidden
    const detailRes = await app.request(`/api/student/training/modules/${createdModuleId}`, {
      headers: { 'Authorization': 'Bearer mock-token:student-b' },
    }, env);
    assert.equal(detailRes.status, 403);

    // Student B tries to query lessons directly -> 403 Forbidden
    const lessonsRes = await app.request(`/api/student/training/modules/${createdModuleId}/lessons`, {
      headers: { 'Authorization': 'Bearer mock-token:student-b' },
    }, env);
    assert.equal(lessonsRes.status, 403);
  });

  await t.test('4. Admin assigns module to Student A with target date & instructions', async () => {
    const targetDate = new Date(Date.now() + 7 * 86400000).toISOString().split('T')[0];

    const assignRes = await app.request('/api/admin/students/student-a/learning-plans', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer mock-token:admin-1',
      },
      body: JSON.stringify({
        moduleIds: [createdModuleId],
        target_completion_date: targetDate,
        instructions: 'Complete required setback lessons before studio review.',
      }),
    }, env);

    assert.equal(assignRes.status, 201);
    const assignBody = await assignRes.json();
    assert.equal(assignBody.success, true);
    assert.equal(assignBody.count, 1);
  });

  await t.test('5. Student A can now access assigned module, while Student B remains isolated', async () => {
    // Student A queries modules
    const listA = await app.request('/api/student/training/modules', {
      headers: { 'Authorization': 'Bearer mock-token:student-a' },
    }, env);
    assert.equal(listA.status, 200);
    const modulesA = await listA.json();
    assert.equal(modulesA.length, 1);
    assert.equal(modulesA[0].id, createdModuleId);

    // Student A accesses module detail
    const detailA = await app.request(`/api/student/training/modules/${createdModuleId}`, {
      headers: { 'Authorization': 'Bearer mock-token:student-a' },
    }, env);
    assert.equal(detailA.status, 200);
    const dataA = await detailA.json();
    assert.equal(dataA.id, createdModuleId);
    assert.equal(dataA.chapters.length, 1);
    assert.equal(dataA.status, 'Not Started');

    // Student B remains strictly unauthorized
    const detailB = await app.request(`/api/student/training/modules/${createdModuleId}`, {
      headers: { 'Authorization': 'Bearer mock-token:student-b' },
    }, env);
    assert.equal(detailB.status, 403);
  });

  await t.test('6. Student A completes required lesson: completion persists and updates progress', async () => {
    const progRes = await app.request(`/api/student/training/lessons/${reqLessonId}/progress`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer mock-token:student-a',
      },
      body: JSON.stringify({ status: 'COMPLETED' }),
    }, env);

    assert.equal(progRes.status, 200);
    const progBody = await progRes.json();
    assert.equal(progBody.success, true);
    assert.equal(progBody.status, 'COMPLETED');
    assert.equal(progBody.completion_percentage, 100);

    // Re-query module detail: status should now be Completed
    const checkRes = await app.request(`/api/student/training/modules/${createdModuleId}`, {
      headers: { 'Authorization': 'Bearer mock-token:student-a' },
    }, env);
    const checkData = await checkRes.json();
    assert.equal(checkData.status, 'Completed');
    assert.equal(checkData.progress, 1.0);
  });

  await t.test('7. Admin progress monitoring displays accurate individual progress', async () => {
    // Overview
    const ovRes = await app.request('/api/admin/students-progress', {
      headers: { 'Authorization': 'Bearer mock-token:admin-1' },
    }, env);
    assert.equal(ovRes.status, 200);
    const overview = await ovRes.json();

    const stA = overview.find((s) => s.student_id === 'student-a');
    assert.ok(stA);
    assert.equal(stA.total_assigned_modules, 1);
    assert.equal(stA.completed_required_lessons, 1);
    assert.equal(stA.total_required_lessons, 1);
    assert.equal(stA.overall_completion_percentage, 100);

    const stB = overview.find((s) => s.student_id === 'student-b');
    assert.ok(stB);
    assert.equal(stB.total_assigned_modules, 0);
    assert.equal(stB.overall_completion_percentage, 0);

    // Detail Drill-down for Student A
    const dtRes = await app.request('/api/admin/students/student-a/progress-detail', {
      headers: { 'Authorization': 'Bearer mock-token:admin-1' },
    }, env);
    assert.equal(dtRes.status, 200);
    const detail = await dtRes.json();
    assert.equal(detail.student.id, 'student-a');
    assert.equal(detail.overallSummary.overall_completion_percentage, 100);
    assert.equal(detail.modules[0].module.id, createdModuleId);
    assert.ok(detail.modules[0].lessons[0].is_completed);
  });

  await t.test('8. Non-admin roles are rejected from managing modules and assigning plans', async () => {
    const unauthorizedRes = await app.request('/api/admin/training/modules', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer mock-token:student-a',
      },
      body: JSON.stringify({ title: 'Hacked Module' }),
    }, env);
    assert.equal(unauthorizedRes.status, 403);

    const unauthorizedAssign = await app.request('/api/admin/students/student-b/learning-plans', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer mock-token:student-a',
      },
      body: JSON.stringify({ moduleIds: [createdModuleId] }),
    }, env);
    assert.equal(unauthorizedAssign.status, 403);
  });

  await t.test('9. Module creation rejects missing title with 400 INVALID_TITLE', async () => {
    const res = await app.request('/api/admin/training/modules', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer mock-token:admin-1',
      },
      body: JSON.stringify({ title: '   ', category: 'Architectural' }),
    }, env);
    assert.equal(res.status, 400);
    const body = await res.json();
    assert.equal(body.code, 'INVALID_TITLE');
  });

  await t.test('10. Admin creates module with immediate student assignment', async () => {
    const targetDate = new Date(Date.now() + 7 * 86400000).toISOString().split('T')[0];
    const res = await app.request('/api/admin/training/modules', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer mock-token:admin-1',
      },
      body: JSON.stringify({
        title: 'BIM Revit Foundations',
        category: 'Structural',
        level: 'Intermediate',
        publication_status: 'PUBLISHED',
        assign_to_student_id: 'student-b',
        target_completion_date: targetDate,
        assignment_instructions: 'Complete family modeling before next review.',
      }),
    }, env);
    assert.equal(res.status, 201);
    const body = await res.json();
    assert.ok(body.id);
    assert.ok(body.assignment);
    assert.equal(body.assignment.assigned, true);
    assert.equal(body.assignment.student_id, 'student-b');

    // Verify learning plan persisted
    const plan = rawDb.prepare('SELECT * FROM student_learning_plans WHERE student_id = ? AND module_id = ?')
      .get('student-b', body.id);
    assert.ok(plan);
    assert.equal(plan.instructions, 'Complete family modeling before next review.');
  });

  await t.test('11. Module creation with invalid student ID saves module, returns 400 with ID', async () => {
    const res = await app.request('/api/admin/training/modules', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer mock-token:admin-1',
      },
      body: JSON.stringify({
        title: 'Interior Lighting Standards',
        category: 'Interior',
        assign_to_student_id: 'non-existent-student-999',
      }),
    }, env);
    assert.equal(res.status, 400);
    const body = await res.json();
    assert.equal(body.code, 'STUDENT_NOT_FOUND');
    assert.ok(body.id); // Module was saved
    assert.equal(body.assignment_failed, true);

    // Verify module actually exists in database
    const saved = rawDb.prepare('SELECT * FROM training_modules WHERE id = ?').get(body.id);
    assert.ok(saved);
    assert.equal(saved.title, 'Interior Lighting Standards');
  });

  await t.test('12. Idempotent retry with existing ID updates module without duplicate record error and assigns student', async () => {
    const customId = 'mod-retry-test-01';
    // 1st attempt: create module
    const res1 = await app.request('/api/admin/training/modules', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer mock-token:admin-1',
      },
      body: JSON.stringify({
        id: customId,
        title: 'Custom HVAC Drafting',
        category: 'Structural',
      }),
    }, env);
    assert.equal(res1.status, 201);

    // 2nd attempt: retry with same ID, this time assigning student-a
    const res2 = await app.request('/api/admin/training/modules', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer mock-token:admin-1',
      },
      body: JSON.stringify({
        id: customId,
        title: 'Custom HVAC Drafting (Updated)',
        category: 'Structural',
        assign_to_student_id: 'student-a',
      }),
    }, env);
    assert.equal(res2.status, 201);
    const body2 = await res2.json();
    assert.equal(body2.id, customId);
    assert.ok(body2.assignment?.assigned);

    // Verify only ONE module exists with this ID
    const count = rawDb.prepare('SELECT COUNT(*) as c FROM training_modules WHERE id = ?').get(customId);
    assert.equal(count.c, 1);
  });

  await t.test('13. Student cannot access a DRAFT module even if assigned to their learning plan', async () => {
    // Create draft module assigned to student-a
    const res = await app.request('/api/admin/training/modules', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer mock-token:admin-1',
      },
      body: JSON.stringify({
        title: 'Unreleased Advanced Parametrics',
        category: 'Architectural',
        publication_status: 'DRAFT',
        assign_to_student_id: 'student-a',
      }),
    }, env);
    assert.equal(res.status, 201);
    const body = await res.json();
    const draftModId = body.id;

    // Student A attempts to access module detail -> must be strictly rejected with 403
    const studentRes = await app.request(`/api/student/training/modules/${draftModId}`, {
      headers: { 'Authorization': 'Bearer mock-token:student-a' },
    }, env);
    assert.equal(studentRes.status, 403);
  });

  await t.test('14. Module catalogue queries and filters return expected records safely', async () => {
    const listRes = await app.request('/api/admin/training/modules', {
      headers: { 'Authorization': 'Bearer mock-token:admin-1' },
    }, env);
    assert.equal(listRes.status, 200);
    const all = await listRes.json();
    assert.ok(Array.isArray(all));
    assert.ok(all.length >= 4);

    // Filter by category
    const catRes = await app.request('/api/admin/training/modules?category=Approval', {
      headers: { 'Authorization': 'Bearer mock-token:admin-1' },
    }, env);
    assert.equal(catRes.status, 200);
    const approvalList = await catRes.json();
    assert.ok(approvalList.every((m) => m.category.toLowerCase() === 'approval'));

    // Empty result filter
    const emptyRes = await app.request('/api/admin/training/modules?category=NonExistentDiscipline', {
      headers: { 'Authorization': 'Bearer mock-token:admin-1' },
    }, env);
    assert.equal(emptyRes.status, 200);
    const emptyList = await emptyRes.json();
    assert.deepEqual(emptyList, []);
  });

  await t.test('15. Student with no assigned training returns clean unassigned state and 0% completion', async () => {
    rawDb.exec(`
      INSERT INTO users (id, email, name, role, status) VALUES
        ('student-unassigned', 'unassigned@college.edu', 'Student Unassigned', 'STUDENT', 'ACTIVE');
      INSERT INTO legal_consent_events (id, user_id, document_id, document_type, document_version, action_type, consent_purpose, idempotency_key, ip_hash, source)
      VALUES ('evt-terms-u', 'student-unassigned', 'doc-terms-ts', 'TERMS_AND_CONDITIONS', '1.0.0', 'ACCEPT', 'DEFAULT', 'idem-u', 'hash', 'WEB');
    `);
    const dtRes = await app.request('/api/admin/students/student-unassigned/progress-detail', {
      headers: { 'Authorization': 'Bearer mock-token:admin-1' },
    }, env);
    assert.equal(dtRes.status, 200);
    const detail = await dtRes.json();
    assert.equal(detail.student.id, 'student-unassigned');
    assert.equal(detail.overallSummary.total_assigned_modules, 0);
    assert.equal(detail.overallSummary.overall_completion_percentage, 0);
    assert.equal(detail.overallSummary.total_required_lessons, 0);
    assert.equal(detail.overallSummary.completed_required_lessons, 0);
    assert.equal(detail.overallSummary.has_overdue, false);
    assert.deepEqual(detail.modules, []);
    assert.ok(Array.isArray(detail.completionHistory));
  });

  await t.test('16. Nonexistent student returns 404 and non-admin request returns 403 on progress endpoints', async () => {
    const notFoundRes = await app.request('/api/admin/students/non-existent-student-999/progress-detail', {
      headers: { 'Authorization': 'Bearer mock-token:admin-1' },
    }, env);
    assert.equal(notFoundRes.status, 404);
    const errBody = await notFoundRes.json();
    assert.equal(errBody.code, 'NOT_FOUND');

    const unauthDetail = await app.request('/api/admin/students/student-a/progress-detail', {
      headers: { 'Authorization': 'Bearer mock-token:student-a' },
    }, env);
    assert.equal(unauthDetail.status, 403);

    const unauthOverview = await app.request('/api/admin/students-progress', {
      headers: { 'Authorization': 'Bearer mock-token:student-a' },
    }, env);
    assert.equal(unauthOverview.status, 403);
  });

  await t.test('17. Student with assigned module and lessons but no completed lessons shows 0% completion and progress object', async () => {
    // Create new student C and assign a module with 2 required lessons
    rawDb.exec(`
      INSERT INTO users (id, email, name, role, status) VALUES
        ('student-c', 'student.c@college.edu', 'Student Charlie', 'STUDENT', 'ACTIVE');
      INSERT INTO legal_consent_events (id, user_id, document_id, document_type, document_version, action_type, consent_purpose, idempotency_key, ip_hash, source)
      VALUES ('evt-terms-c', 'student-c', 'doc-terms-ts', 'TERMS_AND_CONDITIONS', '1.0.0', 'ACCEPT', 'DEFAULT', 'idem-c', 'hash', 'WEB');
    `);

    // Create module with 2 lessons
    const modRes = await app.request('/api/admin/training/modules', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer mock-token:admin-1',
      },
      body: JSON.stringify({
        title: 'Charlie Architecture Basics',
        category: 'Architectural',
        assign_to_student_id: 'student-c',
      }),
    }, env);
    assert.equal(modRes.status, 201);
    const modData = await modRes.json();
    const charlieModId = modData.id;

    // Add chapter and 2 required lessons
    const chRes = await app.request(`/api/admin/training/modules/${charlieModId}/chapters`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer mock-token:admin-1' },
      body: JSON.stringify({ title: 'Chapter 1: Intro' }),
    }, env);
    const chData = await chRes.json();

    await app.request(`/api/admin/training/modules/${charlieModId}/lessons`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer mock-token:admin-1' },
      body: JSON.stringify({ title: 'Lesson 1A', chapter_id: chData.id, is_required: 1 }),
    }, env);
    await app.request(`/api/admin/training/modules/${charlieModId}/lessons`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer mock-token:admin-1' },
      body: JSON.stringify({ title: 'Lesson 1B', chapter_id: chData.id, is_required: 1 }),
    }, env);

    // Detail check for Student C
    const dtRes = await app.request('/api/admin/students/student-c/progress-detail', {
      headers: { 'Authorization': 'Bearer mock-token:admin-1' },
    }, env);
    assert.equal(dtRes.status, 200);
    const detail = await dtRes.json();
    assert.equal(detail.student.id, 'student-c');
    assert.equal(detail.overallSummary.total_assigned_modules, 1);
    assert.equal(detail.overallSummary.overall_completion_percentage, 0);
    assert.equal(detail.overallSummary.total_required_lessons, 2);
    assert.equal(detail.overallSummary.completed_required_lessons, 0);
    assert.equal(detail.overallSummary.not_started_modules, 1);
    assert.equal(detail.overallSummary.completed_modules, 0);

    // Verify progress object exists on the module item (preventing Cannot read properties of undefined (reading 'completion_percentage'))
    assert.ok(detail.modules[0].progress, 'Module item must have progress object');
    assert.equal(detail.modules[0].progress.completion_percentage, 0);
    assert.equal(detail.modules[0].progress.total_required_lessons, 2);
    assert.equal(detail.modules[0].progress.completed_required_lessons, 0);
    assert.equal(detail.modules[0].progress.status, 'Not Started');
    assert.equal(detail.modules[0].chapters[0].lessons.length, 2);
  });

  await t.test('18. Student with partially completed required lessons calculates accurate completion percentage', async () => {
    // Complete 1 out of 2 required lessons for student-c
    const lessons = rawDb.prepare("SELECT id FROM training_lessons WHERE title = 'Lesson 1A'").all();
    assert.ok(lessons.length > 0);
    const lesson1AId = lessons[0].id;

    rawDb.exec(`
      INSERT INTO student_lesson_progress (id, student_id, lesson_id, status, completed_at)
      VALUES ('slp-c-1', 'student-c', '${lesson1AId}', 'COMPLETED', CURRENT_TIMESTAMP);
    `);

    const dtRes = await app.request('/api/admin/students/student-c/progress-detail', {
      headers: { 'Authorization': 'Bearer mock-token:admin-1' },
    }, env);
    assert.equal(dtRes.status, 200);
    const detail = await dtRes.json();
    assert.equal(detail.overallSummary.completed_required_lessons, 1);
    assert.equal(detail.overallSummary.total_required_lessons, 2);
    assert.equal(detail.overallSummary.overall_completion_percentage, 50);
    assert.equal(detail.modules[0].progress.completion_percentage, 50);
    assert.equal(detail.modules[0].progress.status, 'In Progress');

    // Overview check for student-c
    const ovRes = await app.request('/api/admin/students-progress', {
      headers: { 'Authorization': 'Bearer mock-token:admin-1' },
    }, env);
    const overview = await ovRes.json();
    const stC = overview.find((s) => s.student_id === 'student-c');
    assert.ok(stC);
    assert.equal(stC.overall_completion_percentage, 50);
    assert.equal(stC.completed_required_lessons, 1);
    assert.equal(stC.total_required_lessons, 2);
    assert.equal(stC.training_status, 'IN_PROGRESS');
  });

  await t.test('19. Optional lessons do not artificially inflate or penalize required lesson progress', async () => {
    // Add optional lesson to student-c's module
    const modules = rawDb.prepare("SELECT id FROM training_modules WHERE title = 'Charlie Architecture Basics'").all();
    const charlieModId = modules[0].id;

    const chapters = rawDb.prepare(`SELECT id FROM training_chapters WHERE module_id = '${charlieModId}'`).all();
    const chId = chapters[0].id;

    const optLessonRes = await app.request(`/api/admin/training/modules/${charlieModId}/lessons`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer mock-token:admin-1' },
      body: JSON.stringify({ title: 'Bonus Optional Walkthrough', chapter_id: chId, is_required: 0 }),
    }, env);
    const optLesson = await optLessonRes.json();

    // Complete the optional lesson
    rawDb.exec(`
      INSERT INTO student_lesson_progress (id, student_id, lesson_id, status, completed_at)
      VALUES ('slp-c-opt', 'student-c', '${optLesson.id}', 'COMPLETED', CURRENT_TIMESTAMP);
    `);

    // Verify required lessons count and percentage remain 1/2 and 50%
    const dtRes = await app.request('/api/admin/students/student-c/progress-detail', {
      headers: { 'Authorization': 'Bearer mock-token:admin-1' },
    }, env);
    const detail = await dtRes.json();
    assert.equal(detail.overallSummary.total_required_lessons, 2);
    assert.equal(detail.overallSummary.completed_required_lessons, 1);
    assert.equal(detail.overallSummary.overall_completion_percentage, 50);

    // Complete the second required lesson (Lesson 1B)
    const lessons1B = rawDb.prepare("SELECT id FROM training_lessons WHERE title = 'Lesson 1B'").all();
    rawDb.exec(`
      INSERT INTO student_lesson_progress (id, student_id, lesson_id, status, completed_at)
      VALUES ('slp-c-2', 'student-c', '${lessons1B[0].id}', 'COMPLETED', CURRENT_TIMESTAMP);
    `);

    // Now all required lessons are completed -> 100%
    const dtRes2 = await app.request('/api/admin/students/student-c/progress-detail', {
      headers: { 'Authorization': 'Bearer mock-token:admin-1' },
    }, env);
    const detail2 = await dtRes2.json();
    assert.equal(detail2.overallSummary.total_required_lessons, 2);
    assert.equal(detail2.overallSummary.completed_required_lessons, 2);
    assert.equal(detail2.overallSummary.overall_completion_percentage, 100);
    assert.equal(detail2.modules[0].progress.status, 'Completed');
  });

  await t.test('20. Learning plan with selected_chapters or selected_lessons only counts lessons belonging to that subset', async () => {
    // Seed Student D with a plan selecting only Lesson 1A
    rawDb.exec(`
      INSERT INTO users (id, email, name, role, status) VALUES
        ('student-d', 'student.d@college.edu', 'Student Dave', 'STUDENT', 'ACTIVE');
      INSERT INTO legal_consent_events (id, user_id, document_id, document_type, document_version, action_type, consent_purpose, idempotency_key, ip_hash, source)
      VALUES ('evt-terms-d', 'student-d', 'doc-terms-ts', 'TERMS_AND_CONDITIONS', '1.0.0', 'ACCEPT', 'DEFAULT', 'idem-d', 'hash', 'WEB');
    `);

    const modules = rawDb.prepare("SELECT id FROM training_modules WHERE title = 'Charlie Architecture Basics'").all();
    const charlieModId = modules[0].id;

    const lessons1A = rawDb.prepare("SELECT id FROM training_lessons WHERE title = 'Lesson 1A'").all();

    rawDb.exec(`
      INSERT INTO student_learning_plans (id, student_id, module_id, assigned_by, selected_lessons, status)
      VALUES ('plan-d-custom', 'student-d', '${charlieModId}', 'admin-1', '["${lessons1A[0].id}"]', 'ASSIGNED');
    `);

    const dtRes = await app.request('/api/admin/students/student-d/progress-detail', {
      headers: { 'Authorization': 'Bearer mock-token:admin-1' },
    }, env);
    assert.equal(dtRes.status, 200);
    const detail = await dtRes.json();
    // Only 1 lesson was in the selected_lessons plan
    assert.equal(detail.overallSummary.total_required_lessons, 1);
    assert.equal(detail.overallSummary.completed_required_lessons, 0);
    assert.equal(detail.overallSummary.overall_completion_percentage, 0);
  });

  await t.test('21. Practical projects with multiple evaluations only return latest evaluation without duplicate project rows', async () => {
    // Assign training project to student-a and create two evaluation rounds
    rawDb.exec(`
      INSERT INTO projects (id, project_name, project_address, project_area, drawing_name, drawing_type, status, correction_round, client_id, is_training_project)
      VALUES ('proj-train-1', 'Residential Ground Floor CAD', '123 Studio Way', 1200, 'GD-01', 'Architectural', 'COMPLETED', 2, 'admin-1', 1);

      INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
      VALUES
        ('file-t1', 'proj-train-1', 'student-a', 'cad_v1.dwg', 'cad_v1.dwg', 'obj-t1', 'application/acad', 4096, 'deliverable', 'CONFIRMED'),
        ('file-t2', 'proj-train-1', 'student-a', 'cad_v2.dwg', 'cad_v2.dwg', 'obj-t2', 'application/acad', 4096, 'deliverable', 'CONFIRMED');

      INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by)
      VALUES
        ('ver-1', 'proj-train-1', 'file-t1', 1, 'student-a'),
        ('ver-2', 'proj-train-1', 'file-t2', 2, 'student-a');

      INSERT INTO student_assignments (id, student_id, project_id, assignment_type, status)
      VALUES ('sa-train-1', 'student-a', 'proj-train-1', 'PROJECT', 'COMPLETED');

      INSERT INTO evaluations (id, project_id, drawing_version_id, evaluator_id, overall_result, general_feedback, criteria_json, created_at)
      VALUES
        ('eval-1', 'proj-train-1', 'ver-1', 'admin-1', 'NEEDS_CORRECTION', 'Revise grid offsets', '{"Accuracy":3}', '2026-10-01 10:00:00'),
        ('eval-2', 'proj-train-1', 'ver-2', 'admin-1', 'APPROVED', 'Flawless line weight and dimensions', '{"Accuracy":5,"Technical Standards":5}', '2026-10-02 12:00:00');
    `);

    const dtRes = await app.request('/api/admin/students/student-a/progress-detail', {
      headers: { 'Authorization': 'Bearer mock-token:admin-1' },
    }, env);
    assert.equal(dtRes.status, 200);
    const detail = await dtRes.json();

    // Project should appear exactly once (no duplicates from multiple evaluations)
    assert.equal(detail.practicalProjects.length, 1);
    const prj = detail.practicalProjects[0];
    assert.equal(prj.id, 'proj-train-1');
    assert.equal(prj.evaluation.overall_result, 'APPROVED');
    assert.equal(prj.evaluation.score, 100);
    assert.equal(prj.evaluation.general_feedback, 'Flawless line weight and dimensions');
  });

  await t.test('22. Overview endpoint supports filtering by status and search parameter', async () => {
    // Filter status=COMPLETED
    const compRes = await app.request('/api/admin/students-progress?status=COMPLETED', {
      headers: { 'Authorization': 'Bearer mock-token:admin-1' },
    }, env);
    assert.equal(compRes.status, 200);
    const compList = await compRes.json();
    assert.ok(compList.every((s) => s.overall_completion_percentage === 100));

    // Filter status=UNASSIGNED
    const unassignedRes = await app.request('/api/admin/students-progress?status=UNASSIGNED', {
      headers: { 'Authorization': 'Bearer mock-token:admin-1' },
    }, env);
    assert.equal(unassignedRes.status, 200);
    const unassignedList = await unassignedRes.json();
    assert.ok(unassignedList.every((s) => s.assigned_plans_count === 0));

    // Search query matching 'Alice'
    const searchRes = await app.request('/api/admin/students-progress?search=alice', {
      headers: { 'Authorization': 'Bearer mock-token:admin-1' },
    }, env);
    assert.equal(searchRes.status, 200);
    const searchList = await searchRes.json();
    assert.equal(searchList.length, 1);
    assert.equal(searchList[0].student_id, 'student-a');
  });
});
