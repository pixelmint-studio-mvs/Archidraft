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

const bundlePath = path.join(workerRoot, 'node_modules', '.test_app_bundle_helpdesk.mjs');
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
      for (const s of statements) {
        results.push(await s.run());
      }
      return results;
    }
  };

  return { raw: db, d1 };
}

function mockToken(uidOrRole = 'admin-1', maybeUid) {
  const uid = maybeUid || uidOrRole;
  return `mock-token:${uid}`;
}

test('PixelMint Studio MVS — Centralized Help Desk & Incident Management System', async (t) => {
  const { raw, d1 } = createIsolatedTestDb();

  // Seed sample users
  raw.exec(`
    INSERT INTO users (id, email, name, role, status) VALUES
      ('admin-1', 'admin@draughtsmanstudio.com', 'Studio Administrator', 'STUDIO_ADMIN', 'ACTIVE'),
      ('student-1', 'student1@example.com', 'Student One', 'STUDENT', 'ACTIVE'),
      ('student-2', 'student2@example.com', 'Student Two', 'STUDENT', 'ACTIVE');
  `);

  const env = {
    DB: d1,
    ENVIRONMENT: 'test',
    NODE_ENV: 'test',
    FIREBASE_PROJECT_ID: 'archi-draft',
  };

  await t.test('1. Automatic Error Beacon & Unique Ticket Generation', async () => {
    const res = await app.request('/api/helpdesk/report', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        title: 'Component Render Crash in Drawing Viewer',
        category: 'FRONTEND',
        severity: 'CRITICAL',
        affected_module: 'DrawingViewer',
        error_message: 'Cannot read properties of undefined (reading "dimensions")',
        stack_trace: 'TypeError: Cannot read properties\n  at DrawingViewer.render (DrawingViewer.tsx:42:15)',
        page_route: '/projects/proj-101/view',
      }),
    }, env);

    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.strictEqual(body.success, true);
    assert.ok(body.ticketId.startsWith('PM-HELP-'));
    assert.strictEqual(body.isNew, true);

    // Verify stored record in database
    const ticket = raw.prepare('SELECT * FROM helpdesk_tickets WHERE id = ?').get(body.ticketId);
    assert.ok(ticket);
    assert.strictEqual(ticket.severity, 'CRITICAL');
    assert.strictEqual(ticket.category, 'FRONTEND');
    assert.strictEqual(ticket.status, 'OPEN');
    assert.strictEqual(ticket.occurrence_count, 1);

    // Verify timeline event
    const events = raw.prepare('SELECT * FROM helpdesk_events WHERE ticket_id = ?').all(body.ticketId);
    assert.strictEqual(events.length, 2); // CREATED + EMAIL_DISPATCHED
    assert.strictEqual(events[0].event_type, 'CREATED');

    // Verify email log entry dispatched to pixelmintstudiomvs@gmail.com
    const emailLog = raw.prepare('SELECT * FROM helpdesk_email_logs WHERE ticket_id = ?').get(body.ticketId);
    assert.ok(emailLog);
    assert.strictEqual(emailLog.recipient, 'pixelmintstudiomvs@gmail.com');
    assert.strictEqual(emailLog.status, 'SENT');
  });

  await t.test('2. Deduplication Fingerprinting & Recurrence Grouping', async () => {
    // Send second identical error
    const res = await app.request('/api/helpdesk/report', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        title: 'Component Render Crash in Drawing Viewer',
        category: 'FRONTEND',
        severity: 'CRITICAL',
        affected_module: 'DrawingViewer',
        error_message: 'Cannot read properties of undefined (reading "dimensions")',
        page_route: '/projects/proj-102/view',
      }),
    }, env);

    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.strictEqual(body.success, true);
    assert.strictEqual(body.isNew, false, 'Should be detected as recurrence');

    // Verify occurrence count incremented to 2
    const ticket = raw.prepare('SELECT * FROM helpdesk_tickets WHERE id = ?').get(body.ticketId);
    assert.strictEqual(ticket.occurrence_count, 2);

    // Verify recurrence event added
    const events = raw.prepare("SELECT * FROM helpdesk_events WHERE ticket_id = ? AND event_type = 'RECURRENCE'").all(body.ticketId);
    assert.strictEqual(events.length, 1);

    // Verify duplicate suppression: no second email storm within 15min window
    const emailLogs = raw.prepare('SELECT * FROM helpdesk_email_logs WHERE ticket_id = ?').all(body.ticketId);
    assert.strictEqual(emailLogs.length, 2);
    assert.strictEqual(emailLogs[1].status, 'SUPPRESSED_DUPLICATE');
  });

  await t.test('3. User-Submitted Support Ticket & Self-Service History', async () => {
    const studentToken = mockToken('STUDENT', 'student-1', 'student1@example.com');

    // Submit ticket
    const res = await app.request('/api/helpdesk/tickets', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${studentToken}`,
      },
      body: JSON.stringify({
        subject: 'Certificate Download Link Returns Error 404',
        description: 'When clicking on the verification link on my module certificate, it says not found.',
        category: 'CERTIFICATE_ISSUES',
        affected_feature: 'Student Certificates',
        priority_suggestion: 'HIGH',
      }),
    }, env);

    assert.strictEqual(res.status, 201);
    const body = await res.json();
    assert.strictEqual(body.success, true);
    assert.ok(body.ticketId.startsWith('PM-HELP-'));

    // Verify user can fetch their ticket
    const myTicketsRes = await app.request('/api/helpdesk/my-tickets', {
      headers: { Authorization: `Bearer ${studentToken}` },
    }, env);
    assert.strictEqual(myTicketsRes.status, 200);
    const myTickets = await myTicketsRes.json();
    assert.strictEqual(myTickets.length, 1);
    assert.strictEqual(myTickets[0].title, 'Certificate Download Link Returns Error 404');
    assert.strictEqual(myTickets[0].is_user_submitted, 1);

    // Verify Student 2 sees 0 tickets (Strict Isolation)
    const student2Token = mockToken('STUDENT', 'student-2', 'student2@example.com');
    const student2Res = await app.request('/api/helpdesk/my-tickets', {
      headers: { Authorization: `Bearer ${student2Token}` },
    }, env);
    assert.strictEqual(student2Res.status, 200);
    const student2Tickets = await student2Res.json();
    assert.strictEqual(student2Tickets.length, 0);
  });

  await t.test('4. Admin RBAC & Help Desk Metrics Telemetry', async () => {
    const studentToken = mockToken('STUDENT', 'student-1', 'student1@example.com');
    const adminToken = mockToken('STUDIO_ADMIN', 'admin-1', 'admin@draughtsmanstudio.com');

    // 1. Non-admin is strictly rejected with 403
    const deniedRes = await app.request('/api/admin/helpdesk/stats', {
      headers: { Authorization: `Bearer ${studentToken}` },
    }, env);
    assert.strictEqual(deniedRes.status, 403);

    // 2. Admin successfully retrieves real aggregated KPIs
    const statsRes = await app.request('/api/admin/helpdesk/stats', {
      headers: { Authorization: `Bearer ${adminToken}` },
    }, env);
    assert.strictEqual(statsRes.status, 200);
    const stats = await statsRes.json();

    assert.strictEqual(stats.totalReports, 2);
    assert.strictEqual(stats.openTickets, 2);
    assert.strictEqual(stats.criticalIssues, 1);
    assert.strictEqual(stats.highPriority, 1);
    assert.ok(stats.categoryDistribution.FRONTEND >= 1);
  });

  await t.test('5. Admin Ticket Investigation, Triage & Resolution Workflow', async () => {
    const adminToken = mockToken('STUDIO_ADMIN', 'admin-1', 'admin@draughtsmanstudio.com');

    // List tickets
    const listRes = await app.request('/api/admin/helpdesk/tickets?status=OPEN', {
      headers: { Authorization: `Bearer ${adminToken}` },
    }, env);
    assert.strictEqual(listRes.status, 200);
    const list = await listRes.json();
    assert.strictEqual(list.total, 2);
    const ticketId = list.tickets[0].id;

    // View ticket details
    const detailRes = await app.request(`/api/admin/helpdesk/tickets/${ticketId}`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    }, env);
    assert.strictEqual(detailRes.status, 200);
    const detail = await detailRes.json();
    assert.ok(detail.ticket);
    assert.ok(Array.isArray(detail.events));
    assert.ok(Array.isArray(detail.email_logs));

    // Post internal investigation note
    const noteRes = await app.request(`/api/admin/helpdesk/tickets/${ticketId}/comments`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${adminToken}`,
      },
      body: JSON.stringify({
        comment: 'Investigated DrawingViewer dimensions null check. Patch deployed in commit e9a2bc.',
      }),
    }, env);
    assert.strictEqual(noteRes.status, 201);

    // Resolve ticket
    const resolveRes = await app.request(`/api/admin/helpdesk/tickets/${ticketId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${adminToken}`,
      },
      body: JSON.stringify({
        status: 'RESOLVED',
        resolution_notes: 'Resolved by guarding dimensions object before canvas initialization.',
      }),
    }, env);
    assert.strictEqual(resolveRes.status, 200);
    const resolveBody = await resolveRes.json();
    assert.strictEqual(resolveBody.ticket.status, 'RESOLVED');
    assert.ok(resolveBody.ticket.resolved_at);

    // Verify audit history includes resolution
    const auditRes = await app.request(`/api/admin/helpdesk/tickets/${ticketId}`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    }, env);
    const updatedDetail = await auditRes.json();
    const resolvedEvent = updatedDetail.events.find(e => e.event_type === 'RESOLVED');
    assert.ok(resolvedEvent, 'RESOLVED audit event must be present in timeline');
  });

  await t.test('6. System Health Diagnostics Endpoint', async () => {
    const adminToken = mockToken('STUDIO_ADMIN', 'admin-1', 'admin@draughtsmanstudio.com');

    const healthRes = await app.request('/api/admin/helpdesk/health', {
      headers: { Authorization: `Bearer ${adminToken}` },
    }, env);
    assert.strictEqual(healthRes.status, 200);
    const health = await healthRes.json();

    assert.ok(health.status);
    assert.ok(health.checks.WORKER_API);
    assert.ok(health.checks.D1_DATABASE);
    assert.strictEqual(health.checks.D1_DATABASE.status, 'OPERATIONAL');
  });

  await t.test('7. Settings & Diagnostic Test Email to pixelmintstudiomvs@gmail.com', async () => {
    const adminToken = mockToken('STUDIO_ADMIN', 'admin-1', 'admin@draughtsmanstudio.com');

    // Retrieve default settings
    const settingsRes = await app.request('/api/admin/helpdesk/settings', {
      headers: { Authorization: `Bearer ${adminToken}` },
    }, env);
    assert.strictEqual(settingsRes.status, 200);
    const settings = await settingsRes.json();
    assert.strictEqual(settings.notification_email, 'pixelmintstudiomvs@gmail.com');

    // Send test email
    const testEmailRes = await app.request('/api/admin/helpdesk/settings/test-email', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${adminToken}`,
      },
      body: JSON.stringify({}),
    }, env);
    assert.strictEqual(testEmailRes.status, 200);
    const testEmailBody = await testEmailRes.json();
    assert.strictEqual(testEmailBody.success, true);
    assert.strictEqual(testEmailBody.status, 'SENT');

    // Verify test email was logged in helpdesk_email_logs
    const testLog = raw.prepare("SELECT * FROM helpdesk_email_logs WHERE subject LIKE '%[TEST NOTIFICATION]%'").get();
    assert.ok(testLog);
    assert.strictEqual(testLog.recipient, 'pixelmintstudiomvs@gmail.com');
  });
});
