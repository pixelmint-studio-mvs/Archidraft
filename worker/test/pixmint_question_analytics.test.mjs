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

const bundlePath = path.join(workerRoot, 'node_modules', '.test_pixmint_analytics_bundle.mjs');
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
    .filter((f) => f.endsWith('.sql'))
    .sort();

  for (const file of migrationFiles) {
    const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf8');
    db.exec(sql);
  }

  const d1 = {
    prepare(sql) {
      const execAll = (...args) => {
        const stmt = db.prepare(sql);
        return { results: stmt.all(...args) };
      };
      const execFirst = (...args) => {
        const stmt = db.prepare(sql);
        return stmt.get(...args) || null;
      };
      const execRun = (...args) => {
        const stmt = db.prepare(sql);
        const info = stmt.run(...args);
        return { success: true, meta: { changes: info.changes } };
      };
      return {
        bind(...args) {
          return {
            first: async () => execFirst(...args),
            all: async () => execAll(...args),
            run: async () => execRun(...args),
          };
        },
        first: async (...args) => execFirst(...args),
        all: async (...args) => execAll(...args),
        run: async (...args) => execRun(...args),
      };
    },
    rawDb: db,
  };

  return d1;
}

test('PIXMINT BOT 2.0 — Question Analytics & Knowledge Gap Audit Integration Suite', async (t) => {
  const d1 = createIsolatedTestDb();
  const rawDb = d1.rawDb;

  const adminUid = 'admin_audit_user_01';
  const engineerUid = 'engineer_alice_01';
  const draughtsmanUid = 'draughtsman_bob_01';
  const studentUid = 'student_charlie_01';

  // Seed users in D1
  rawDb.exec(`
    INSERT INTO users (id, email, role, name, status, verification_status) VALUES
      ('${adminUid}', 'admin@archidraft.com', 'STUDIO_ADMIN', 'Admin User', 'ACTIVE', 'APPROVED'),
      ('${engineerUid}', 'alice@archidraft.com', 'ENGINEER', 'Alice Engineer', 'ACTIVE', 'APPROVED'),
      ('${draughtsmanUid}', 'bob@archidraft.com', 'DRAUGHTSMAN', 'Bob Draughtsman', 'ACTIVE', 'APPROVED'),
      ('${studentUid}', 'charlie@archidraft.com', 'STUDENT', 'Charlie Student', 'ACTIVE', 'APPROVED');
  `);

  const now = Date.now();
  const session1 = 'session_eng_redline_1';
  const session2 = 'session_drt_redline_2';
  const session3 = 'session_eng_approval_3';
  const session4 = 'session_stu_curriculum_4';

  // Seed chat sessions across Engineer, Draughtsman, Student
  rawDb.exec(`
    INSERT INTO chat_sessions (id, user_id, user_role, title, is_archived, created_at, updated_at) VALUES
      ('${session1}', '${engineerUid}', 'engineer', 'Redline Discussion', 0, ${now - 3600000}, ${now}),
      ('${session2}', '${draughtsmanUid}', 'draughtsman', 'Drawing Markups', 0, ${now - 7200000}, ${now}),
      ('${session3}', '${engineerUid}', 'engineer', 'Admin Review Question', 0, ${now - 86400000}, ${now}),
      ('${session4}', '${studentUid}', 'student', 'Module 1 Question', 0, ${now - 172800000}, ${now});
  `);

  // Seed user questions (semantically similar variations)
  rawDb.exec(`
    INSERT INTO chat_messages (id, session_id, user_id, sender, content, created_at) VALUES
      ('msg_q1', '${session1}', '${engineerUid}', 'user', 'How do I add redline annotations?', ${now - 3500000}),
      ('msg_a1', '${session1}', 'pixmint_bot', 'bot', 'Redline annotations can be placed directly on drawing sheets using the annotation pin tool.', ${now - 3499000}),
      ('msg_q2', '${session2}', '${draughtsmanUid}', 'user', 'How can I place redline pins on drawings?', ${now - 7100000}),
      ('msg_a2', '${session2}', 'pixmint_bot', 'bot', 'Click the pin icon in the drawing toolbar and drop it onto the sheet.', ${now - 7099000}),
      ('msg_q3', '${session1}', '${engineerUid}', 'user', 'How do I mark corrections on drawings?', ${now - 3400000}),
      ('msg_a3', '${session1}', 'pixmint_bot', 'bot', 'Use the drawing correction tools in your review portal.', ${now - 3399000}),
      ('msg_q4', '${session3}', '${engineerUid}', 'user', 'What are the rules for drawing approval workflow?', ${now - 86000000}),
      ('msg_a4', '${session3}', 'pixmint_bot', 'bot', 'Drawings enter UNDER_ADMIN_REVIEW upon draughtsman upload and require admin sign-off.', ${now - 85999000}),
      ('msg_q5', '${session4}', '${studentUid}', 'user', 'When is my student curriculum assignment due?', ${now - 172000000}),
      ('msg_a5', '${session4}', 'pixmint_bot', 'bot', 'Check your student dashboard for individual target completion dates.', ${now - 171999000});
  `);

  // Seed user feedback
  rawDb.exec(`
    INSERT INTO user_feedback (id, message_id, user_id, rating, feedback_text, created_at) VALUES
      ('fb_1', 'msg_a1', '${engineerUid}', 1, 'Clear explanation on pin placement', ${now - 3400000}),
      ('fb_2', 'msg_a3', '${engineerUid}', -1, 'Did not explain how to delete a mark', ${now - 3300000});
  `);

  // Seed an unanswered question for knowledge gap detection
  rawDb.exec(`
    INSERT INTO unanswered_questions (id, user_id, user_role, query, failure_reason, created_at) VALUES
      ('uq_1', '${draughtsmanUid}', 'draughtsman', 'How do I place redline pins in multi-page PDF?', 'Low confidence matching chunk', ${now - 7000000}),
      ('uq_2', '${draughtsmanUid}', 'draughtsman', 'What are the electrical symbols for circuit breaker panels?', 'No matching knowledge chunk found', ${now - 5000000});
  `);

  const mockEnv = {
    DB: d1,
    AI_PROVIDER: 'local_grounded',
    STAGING_SECRET: 'test_staging_secret',
  };

  function makeAuthHeaders(uid, extra = {}) {
    return {
      'Content-Type': 'application/json',
      Authorization: `Bearer mock-token:${uid}`,
      ...extra,
    };
  }

  await t.test('1. Security Gate: Non-admin users receive 403 on question-analytics', async () => {
    const res = await app.request('/api/pixmint/admin/question-analytics', {
      method: 'GET',
      headers: makeAuthHeaders(engineerUid),
    }, mockEnv);
    assert.strictEqual(res.status, 403);
    const body = await res.json();
    assert.strictEqual(body.code, 'FORBIDDEN');
  });

  await t.test('2. Admin accesses question-analytics successfully (200 OK)', async () => {
    const res = await app.request('/api/pixmint/admin/question-analytics?timeRange=all', {
      method: 'GET',
      headers: makeAuthHeaders(adminUid),
    }, mockEnv);
    const bodyText = await res.text();
    if (res.status !== 200) {
      console.error('Test 2 Error Body:', bodyText);
    }
    assert.strictEqual(res.status, 200);
    const data = JSON.parse(bodyText);

    assert.ok(data.summary, 'Must return summary KPIs');
    assert.ok(data.frequentlyAskedQuestions, 'Must return FAQ list');
    assert.ok(data.knowledgeGaps, 'Must return knowledge gaps list');

    // Summary metrics
    assert.strictEqual(data.summary.totalQuestionsAnalyzed, 5, 'Must analyze 5 user queries');
    assert.ok(data.summary.uniqueQuestionGroups >= 3, 'Must have at least 3 distinct groups');
    assert.strictEqual(data.summary.unansweredQuestionCount, 2, 'Must record 2 unanswered questions');
    assert.strictEqual(data.summary.negativeFeedbackCount, 1, 'Must record 1 negative feedback');
  });

  await t.test('3. Semantic & Normalized Grouping: Groups variations under Redline Annotations', async () => {
    const res = await app.request('/api/pixmint/admin/question-analytics?timeRange=all', {
      method: 'GET',
      headers: makeAuthHeaders(adminUid),
    }, mockEnv);
    const data = await res.json();

    const redlineFaq = data.frequentlyAskedQuestions.find((f) => f.id === 'redline_annotations');
    assert.ok(redlineFaq, 'Must create group for redline_annotations');
    assert.strictEqual(redlineFaq.topic, 'Redline Annotations & Drawing Corrections');
    assert.strictEqual(redlineFaq.timesAsked, 3, 'Must group the 3 redline variations together');

    // Variations check (3 chat queries + 1 unanswered query)
    assert.strictEqual(redlineFaq.originalVariations.length, 4, 'Must preserve all 4 phrasing variations');
    const texts = redlineFaq.originalVariations.map((v) => v.text);
    assert.ok(texts.includes('How do I add redline annotations?'));
    assert.ok(texts.includes('How can I place redline pins on drawings?'));
    assert.ok(texts.includes('How do I mark corrections on drawings?'));
    assert.ok(texts.includes('How do I place redline pins in multi-page PDF?'));

    // Portal distribution
    assert.strictEqual(redlineFaq.portals.engineer, 2, '2 inquiries from engineer portal');
    assert.strictEqual(redlineFaq.portals.draughtsman, 1, '1 inquiry from draughtsman portal');
    assert.strictEqual(redlineFaq.portals.student, 0, '0 inquiries from student portal');

    // Feedback correlation
    assert.strictEqual(redlineFaq.positiveFeedbackCount, 1);
    assert.strictEqual(redlineFaq.negativeFeedbackCount, 1);
    assert.ok(redlineFaq.feedbackComments.includes('Did not explain how to delete a mark'));
  });

  await t.test('4. Portal Filter: Filters analysis strictly to Engineer inquiries', async () => {
    const res = await app.request('/api/pixmint/admin/question-analytics?portal=engineer&timeRange=all', {
      method: 'GET',
      headers: makeAuthHeaders(adminUid),
    }, mockEnv);
    const data = await res.json();
    assert.strictEqual(res.status, 200);

    // Only engineer messages should be analyzed (3 messages: msg_q1, msg_q3, msg_q4)
    assert.strictEqual(data.summary.totalQuestionsAnalyzed, 3);
    for (const faq of data.frequentlyAskedQuestions) {
      assert.strictEqual(faq.portals.draughtsman, 0, 'Draughtsman inquiries must be excluded');
      assert.strictEqual(faq.portals.student, 0, 'Student inquiries must be excluded');
    }
  });

  await t.test('5. Knowledge Gap Detection: Flags topics with unanswered queries or missing docs', async () => {
    const res = await app.request('/api/pixmint/admin/question-analytics?timeRange=all', {
      method: 'GET',
      headers: makeAuthHeaders(adminUid),
    }, mockEnv);
    const data = await res.json();

    assert.ok(data.knowledgeGaps.length >= 1, 'Must detect at least 1 knowledge gap');
    const electricalGap = data.knowledgeGaps.find((g) => g.id.includes('electrical'));
    const redlineGap = data.knowledgeGaps.find((g) => g.id.includes('redline'));

    assert.ok(electricalGap || redlineGap, 'Must flag electrical or redline gap');
    if (redlineGap) {
      assert.ok(redlineGap.flagReason.length > 0, 'Must provide flag reason');
      assert.ok(redlineGap.recommendedAction.length > 0, 'Must provide recommended action');
    }
  });
});
