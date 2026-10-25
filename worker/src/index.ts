import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { verifyFirebaseToken } from './auth';

type Bindings = {
  DB: D1Database;
  STORAGE: R2Bucket;
};

type Variables = {
  uid: string;
};

const app = new Hono<{ Bindings: Bindings; Variables: Variables }>();

app.use('*', cors());

// Helper: Get user from D1
async function getUser(db: D1Database, uid: string) {
  try {
    return await db.prepare('SELECT * FROM users WHERE id = ?').bind(uid).first();
  } catch {
    return null;
  }
}

// Auth Middleware
app.use('*', async (c, next) => {
  const authHeader = c.req.header('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return c.json({ error: 'Unauthorized: Missing or invalid Authorization header' }, 401);
  }

  const token = authHeader.split('Bearer ')[1];
  const payload = await verifyFirebaseToken(token);
  
  if (!payload || !payload.sub) {
    return c.json({ error: 'Unauthorized: Invalid Firebase token' }, 401);
  }

  c.set('uid', payload.sub);

  // Authoritative Account Governance Enforcement
  // Suspended accounts are immediately blocked from mutating or querying operational endpoints
  const dbUser = await getUser(c.env.DB, payload.sub);
  if (dbUser && (dbUser as any).status === 'SUSPENDED') {
    // Permit read of own profile so client displays suspension notification
    if (c.req.path !== '/api/users/me') {
      return c.json({
        error: 'Account suspended: Administrative access restriction in effect',
        code: 'ACCOUNT_SUSPENDED',
      }, 403);
    }
  }

  await next();
});

// User Profile sync — called immediately after Firebase registration.
// SECURITY: Role must be CLIENT or DRAUGHTSMAN. ADMIN cannot be self-created.
app.post('/api/users', async (c) => {
  const uid = c.get('uid');
  const body = await c.req.json();
  const { email, name, mobile, role } = body;

  // Enforce role allowlist at the backend level.
  const allowedRoles = ['CLIENT', 'DRAUGHTSMAN', 'STUDENT'];
  const safeRole = allowedRoles.includes(role) ? role : null;
  if (!safeRole) {
    return c.json({ error: 'Invalid role. Only CLIENT, DRAUGHTSMAN, and STUDENT are permitted.' }, 400);
  }

  const db = c.env.DB;
  const existing = await getUser(db, uid);
  if (!existing) {
    await db.prepare('INSERT INTO users (id, email, name, mobile, role) VALUES (?, ?, ?, ?, ?)')
      .bind(uid, email, name, mobile ?? '', safeRole)
      .run();
  } else {
    // On subsequent calls (e.g. retry after email verification), only update
    // safe non-privileged fields. Role is NEVER updated here.
    await db.prepare('UPDATE users SET name = ?, mobile = COALESCE(?, mobile) WHERE id = ?')
      .bind(name, mobile ?? null, uid)
      .run();
  }
  return c.json({ success: true });
});

app.get('/api/users/me', async (c) => {
  const uid = c.get('uid');
  const user = await getUser(c.env.DB, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);
  return c.json(user);
});

// Update authenticated user's own editable profile fields.
// SECURITY: role and email are NOT in the allowed set — they cannot be changed here.
app.patch('/api/users/me', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const body = await c.req.json();

  const {
    name,
    mobile,
    qualification,
    dateOfBirth,
    address,
    companyName,
    collegeName,
  } = body;

  await db.prepare(`
    UPDATE users SET
      name = COALESCE(?, name),
      mobile = COALESCE(?, mobile),
      qualification = COALESCE(?, qualification),
      date_of_birth = COALESCE(?, date_of_birth),
      address = COALESCE(?, address),
      company_name = COALESCE(?, company_name),
      college_name = COALESCE(?, college_name),
      updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `).bind(
    name ?? null,
    mobile ?? null,
    qualification ?? null,
    dateOfBirth ?? null,
    address ?? null,
    companyName ?? null,
    collegeName ?? null,
    uid,
  ).run();

  return c.json({ success: true });
});


app.get('/api/users', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);
  if (!user || user.role !== 'ADMIN') return c.json({ error: 'Permission denied' }, 403);
  
  const role = c.req.query('role');
  if (role) {
    const { results } = await db.prepare('SELECT * FROM users WHERE role = ?').bind(role).all();
    return c.json(results);
  }
  
  const { results } = await db.prepare('SELECT * FROM users').all();
  return c.json(results);
});

// Admin: Get specific user details with associated projects or assignments
app.get('/api/users/:id', async (c) => {
  const uid = c.get('uid');
  const targetId = c.req.param('id');
  const db = c.env.DB;
  const adminUser = await getUser(db, uid);
  if (!adminUser || adminUser.role !== 'ADMIN') return c.json({ error: 'Permission denied' }, 403);

  const targetUser = await getUser(db, targetId);
  if (!targetUser) return c.json({ error: 'User not found' }, 404);

  let projects: any[] = [];
  if (targetUser.role === 'CLIENT') {
    const { results } = await db.prepare('SELECT * FROM projects WHERE client_id = ? ORDER BY created_at DESC').bind(targetId).all();
    projects = results;
  } else if (targetUser.role === 'DRAUGHTSMAN') {
    const { results } = await db.prepare('SELECT a.*, p.project_name, p.status as project_status, p.drawing_type, p.project_area FROM assignments a JOIN projects p ON a.project_id = p.id WHERE a.draughtsman_id = ? ORDER BY a.created_at DESC').bind(targetId).all();
    projects = results;
  }

  return c.json({
    user: targetUser,
    projects,
  });
});

// Admin: Account Governance — Suspend or reactivate user accounts
app.patch('/api/users/:id/status', async (c) => {
  const uid = c.get('uid');
  const targetId = c.req.param('id');
  const db = c.env.DB;

  const adminUser = await getUser(db, uid);
  if (!adminUser || adminUser.role !== 'ADMIN') {
    return c.json({ error: 'Permission denied: Studio Admin required' }, 403);
  }

  const targetUser = await getUser(db, targetId);
  if (!targetUser) return c.json({ error: 'User not found' }, 404);

  const body = await c.req.json();
  const { status, reason } = body;

  if (!status || !['ACTIVE', 'SUSPENDED'].includes(status)) {
    return c.json({ error: 'Invalid status. Permitted values: ACTIVE, SUSPENDED' }, 400);
  }

  // Prevent admin self-suspension
  if (targetId === uid && status === 'SUSPENDED') {
    return c.json({ error: 'Self-governance restriction: You cannot suspend your own administrative account' }, 400);
  }

  // Idempotency: if status already matches, return success without unnecessary mutation
  if ((targetUser as any).status === status) {
    return c.json({ success: true, status, idempotent: true });
  }

  // Defensive fallback: ensure status column exists if migration not yet applied
  try {
    await db.prepare("ALTER TABLE users ADD COLUMN status TEXT NOT NULL DEFAULT 'ACTIVE'").run();
  } catch {}

  await db.prepare('UPDATE users SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?')
    .bind(status, targetId)
    .run();

  return c.json({ success: true, status, userId: targetId });
});

// Admin: Unified platform statistics covering all three portals & activity
app.get('/api/admin/stats', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);
  if (!user || user.role !== 'ADMIN') return c.json({ error: 'Permission denied' }, 403);

  const { results: projectStats } = await db.prepare('SELECT status, COUNT(*) as count FROM projects GROUP BY status').all();
  const byStatus: Record<string, number> = {};
  let totalProjects = 0;
  for (const row of projectStats as any[]) {
    byStatus[row.status] = row.count;
    totalProjects += row.count;
  }

  const { results: userStats } = await db.prepare('SELECT role, COUNT(*) as count FROM users GROUP BY role').all();
  const byRole: Record<string, number> = {};
  let totalUsers = 0;
  for (const row of userStats as any[]) {
    byRole[row.role] = row.count;
    totalUsers += row.count;
  }

  const { results: recentActivity } = await db.prepare('SELECT * FROM activity_logs ORDER BY timestamp DESC LIMIT 20').all();

  return c.json({
    projects: {
      total: totalProjects,
      byStatus,
    },
    users: {
      total: totalUsers,
      byRole,
      registeredEngineers: (byRole['ENGINEER'] || 0) + (byRole['CLIENT'] || 0),
    },
    recentActivity: recentActivity || [],
  });
});

// ──────────────────────────────────────────────────────────────────────────────
// Admin: Persistent Studio Governance Settings (D1 Backed)
// ──────────────────────────────────────────────────────────────────────────────

async function ensureSettingsTable(db: any) {
  await db.prepare(`
    CREATE TABLE IF NOT EXISTS studio_settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_by TEXT
    )
  `).run().catch(() => {});
}

const DEFAULT_STUDIO_SETTINGS: Record<string, any> = {
  multiDiscipline: true,
  turnaround: '72 Hours Standard',
  autoRasterizer: true,
  strictLayerCompliance: true,
  maxUploadCeiling: '500 MB per DWG',
  notifySubmissions: true,
  notifyAssignments: true,
  notifyCorrections: true,
  notifyDigest: false,
};

app.get('/api/admin/settings', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);
  if (!user || user.role !== 'ADMIN') return c.json({ error: 'Permission denied: Studio Admin required' }, 403);

  await ensureSettingsTable(db);
  const { results } = await db.prepare('SELECT * FROM studio_settings').all();

  const settings: Record<string, any> = { ...DEFAULT_STUDIO_SETTINGS };
  let lastUpdatedAt = null;
  let lastUpdatedBy = null;

  if (results && results.length > 0) {
    for (const row of results as any[]) {
      try {
        settings[row.key] = JSON.parse(row.value);
      } catch {
        settings[row.key] = row.value;
      }
      if (row.updated_at) lastUpdatedAt = row.updated_at;
      if (row.updated_by) lastUpdatedBy = row.updated_by;
    }
  }

  return c.json({
    settings,
    updated_at: lastUpdatedAt,
    updated_by: lastUpdatedBy,
  });
});

app.put('/api/admin/settings', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);
  if (!user || user.role !== 'ADMIN') return c.json({ error: 'Permission denied: Studio Admin required' }, 403);

  await ensureSettingsTable(db);
  const body = await c.req.json();
  const incoming = body.settings || body;

  // Validate allowed ranges
  const validTurnarounds = ['72 Hours Standard', '48 Hours Expedited', '24 Hours Priority'];
  if (incoming.turnaround && !validTurnarounds.includes(incoming.turnaround)) {
    return c.json({ error: 'Invalid turnaround option' }, 400);
  }

  const validCeilings = ['100 MB per DWG', '250 MB per DWG', '500 MB per DWG', '1 GB per DWG'];
  if (incoming.maxUploadCeiling && !validCeilings.includes(incoming.maxUploadCeiling)) {
    return c.json({ error: 'Invalid max upload ceiling option' }, 400);
  }

  const batch: any[] = [];
  const allowedKeys = [
    'multiDiscipline',
    'turnaround',
    'autoRasterizer',
    'strictLayerCompliance',
    'maxUploadCeiling',
    'notifySubmissions',
    'notifyAssignments',
    'notifyCorrections',
    'notifyDigest',
  ];

  for (const key of allowedKeys) {
    if (incoming[key] !== undefined) {
      const serializedValue = JSON.stringify(incoming[key]);
      batch.push(
        db.prepare(
          'INSERT INTO studio_settings (key, value, updated_at, updated_by) VALUES (?, ?, CURRENT_TIMESTAMP, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = CURRENT_TIMESTAMP, updated_by = excluded.updated_by'
        ).bind(key, serializedValue, uid)
      );
    }
  }

  if (batch.length > 0) {
    await db.batch(batch);
  }

  return c.json({ success: true, message: 'Studio governance settings updated successfully' });
});

// Maximum concurrent active project assignments per draughtsman (authoritative studio capacity)
const MAX_DRAUGHTSMAN_CAPACITY = 4;

// Helper: Query dynamic studio upload ceiling from D1 (with 50MB safe fallback)
async function getEffectiveMaxUploadCeilingBytes(db: any): Promise<number> {
  const DEFAULT_CEILING_BYTES = 50 * 1024 * 1024; // 50MB safe default
  try {
    await ensureSettingsTable(db);
    const row = await db.prepare("SELECT value FROM studio_settings WHERE key = 'maxUploadCeiling'").first();
    if (!row || !row.value) return DEFAULT_CEILING_BYTES;

    let raw = row.value;
    try { raw = JSON.parse(raw); } catch {}

    if (typeof raw === 'string') {
      const match = raw.match(/(\d+)\s*(GB|MB)/i);
      if (match) {
        const num = parseInt(match[1], 10);
        const unit = match[2].toUpperCase();
        if (unit === 'GB') return num * 1024 * 1024 * 1024;
        if (unit === 'MB') return num * 1024 * 1024;
      }
    } else if (typeof raw === 'number' && raw > 0) {
      return raw;
    }
    return DEFAULT_CEILING_BYTES;
  } catch {
    return DEFAULT_CEILING_BYTES;
  }
}

// Helper: Query dynamic studio turnaround SLA from D1 (with 72h safe fallback)
async function getEffectiveTurnaroundHours(db: any): Promise<{ hours: number; label: string }> {
  const DEFAULT = { hours: 72, label: '72 Hours Standard' };
  try {
    await ensureSettingsTable(db);
    const row = await db.prepare("SELECT value FROM studio_settings WHERE key = 'turnaround'").first();
    if (!row || !row.value) return DEFAULT;

    let raw = row.value;
    try { raw = JSON.parse(raw); } catch {}

    if (typeof raw === 'string') {
      if (raw.includes('24')) return { hours: 24, label: '24 Hours Priority' };
      if (raw.includes('48')) return { hours: 48, label: '48 Hours Expedited' };
      if (raw.includes('72')) return { hours: 72, label: '72 Hours Standard' };
    }
    return DEFAULT;
  } catch {
    return DEFAULT;
  }
}

// Helper: UUID v4 (simple fallback for action/log IDs if client doesn't provide it)
function uuidv4() {
  return crypto.randomUUID();
}

// ==========================================
// PROJECTS API
// ==========================================

app.get('/api/projects', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);
  
  if (!user) return c.json({ error: 'User not found' }, 404);

  const status = c.req.query('status');
  let query = 'SELECT * FROM projects WHERE 1=1';
  const params: any[] = [];

  if (user.role === 'CLIENT') {
    query += ' AND client_id = ?';
    params.push(uid);
  } else if (user.role === 'DRAUGHTSMAN') {
    query += ' AND draughtsman_id = ?';
    params.push(uid);
  }
  
  if (status) {
    query += ' AND status = ?';
    params.push(status);
  }

  const { results } = await db.prepare(query).bind(...params).all();
  return c.json(results);
});

// Save a draft project
app.post('/api/projects', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);
  if (!user || user.role !== 'CLIENT') return c.json({ error: 'Only clients can create projects' }, 403);

  const body = await c.req.json();
  const projectId = body.id || uuidv4();
  
  await db.prepare(`
    INSERT INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status)
    VALUES (?, ?, ?, ?, ?, ?, ?, 'DRAFT')
    ON CONFLICT(id) DO UPDATE SET
      project_name = excluded.project_name,
      project_address = excluded.project_address,
      drawing_name = excluded.drawing_name,
      drawing_type = excluded.drawing_type,
      project_area = excluded.project_area
  `).bind(
    projectId, uid, body.project_name, body.project_address, body.drawing_name, body.drawing_type, body.project_area
  ).run();

  return c.json({ id: projectId });
});

app.post('/api/projects/submit', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const body = await c.req.json();
  const { projectId, actionId } = body;
  
  const user = await getUser(db, uid);
  if (!user || user.role !== 'CLIENT') return c.json({ error: 'Only clients can submit projects' }, 403);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  if (project.client_id !== uid) return c.json({ error: 'Permission denied' }, 403);
  if (project.status === 'SUBMITTED' && project.last_action_id === actionId) return c.json({ success: true });
  if (project.status !== 'DRAFT') return c.json({ error: 'Only DRAFT projects can be submitted' }, 400);

  const batch = [
    db.prepare(`UPDATE projects SET status = 'SUBMITTED', submitted_at = CURRENT_TIMESTAMP, last_action_id = ? WHERE id = ?`).bind(actionId, projectId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, projectId, 'PROJECT_SUBMITTED', uid, 'CLIENT', 'Client submitted the project brief.'
    )
  ];
  await db.batch(batch);
  return c.json({ success: true });
});

app.post('/api/projects/submit-drawing', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const body = await c.req.json();
  const { projectId, actionId } = body;
  
  const user = await getUser(db, uid);
  if (!user || user.role !== 'DRAUGHTSMAN') return c.json({ error: 'Only draughtsmen can submit drawings' }, 403);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  if (project.draughtsman_id !== uid) return c.json({ error: 'Not assigned to you' }, 403);
  if (project.status === 'UNDER_CLIENT_REVIEW' && project.last_action_id === actionId) return c.json({ success: true });
  if (project.status !== 'IN_PROGRESS') return c.json({ error: 'Project is not in IN_PROGRESS state' }, 400);

  // 1. Verify a valid drawing version exists
  const latestVersion = await db.prepare('SELECT * FROM drawing_versions WHERE project_id = ? ORDER BY version_number DESC LIMIT 1').bind(projectId).first();
  if (!latestVersion) return c.json({ error: 'No drawing version uploaded yet.' }, 400);

  // 2. No invalid correction state blocks submission (e.g. unstarted OPEN corrections)
  const openCorrection = await db.prepare('SELECT * FROM corrections WHERE project_id = ? AND status = ?').bind(projectId, 'OPEN').first();
  if (openCorrection) return c.json({ error: 'Cannot submit with unstarted corrections. Start the correction first.' }, 400);

  const batch = [
    db.prepare(`UPDATE projects SET status = 'UNDER_CLIENT_REVIEW', last_action_id = ? WHERE id = ?`).bind(actionId, projectId),
    db.prepare(`UPDATE corrections SET status = 'RESOLVED', resolved_at = CURRENT_TIMESTAMP WHERE project_id = ? AND status = 'IN_PROGRESS'`).bind(projectId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, projectId, 'DRAWING_SUBMITTED', uid, 'DRAUGHTSMAN', `Draughtsman submitted drawing version ${latestVersion.version_number} for client review.`
    )
  ];
  await db.batch(batch);
  return c.json({ success: true });
});

app.post('/api/projects/request-correction', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const body = await c.req.json();
  const { projectId, actionId, description, targetVersionId } = body;
  
  const user = await getUser(db, uid);
  if (!user || user.role !== 'CLIENT') return c.json({ error: 'Only clients can request corrections' }, 403);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  if (project.client_id !== uid) return c.json({ error: 'Permission denied' }, 403);
  if (project.status === 'IN_PROGRESS' && project.last_action_id === actionId) return c.json({ success: true });
  if (project.status !== 'UNDER_CLIENT_REVIEW') return c.json({ error: 'Project is not in UNDER_CLIENT_REVIEW state' }, 400);

  // Check 3-round limit
  const currentRound = (project.correction_round as number) || 0;
  if (currentRound >= 3) {
    return c.json({ error: 'Maximum correction limit (3 rounds) has been reached.' }, 400);
  }

  const correctionId = uuidv4();
  const nextRound = currentRound + 1;

  const batch = [
    db.prepare(`UPDATE projects SET status = 'IN_PROGRESS', correction_round = ?, last_action_id = ? WHERE id = ?`).bind(nextRound, actionId, projectId),
    db.prepare(`INSERT INTO corrections (id, project_id, requested_by, target_version_id, round_number, description, status) VALUES (?, ?, ?, ?, ?, ?, 'OPEN')`).bind(
      correctionId, projectId, uid, targetVersionId, nextRound, description
    ),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, projectId, 'CORRECTION_REQUESTED', uid, 'CLIENT', `Client requested correction round ${nextRound}.`
    )
  ];
  await db.batch(batch);
  return c.json({ success: true, correctionId });
});

app.post('/api/projects/:projectId/corrections/:correctionId/start', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const projectId = c.req.param('projectId');
  const correctionId = c.req.param('correctionId');
  const body = await c.req.json();
  const { actionId } = body;
  
  const user = await getUser(db, uid);
  if (!user || user.role !== 'DRAUGHTSMAN') return c.json({ error: 'Only draughtsmen can start corrections' }, 403);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  
  const hasAccess = await verifyDraughtsmanWorkspaceAccess(db, project, uid);
  if (!hasAccess) return c.json({ error: 'Not assigned to you or not accepted' }, 403);

  const correction = await db.prepare('SELECT * FROM corrections WHERE id = ? AND project_id = ?').bind(correctionId, projectId).first();
  if (!correction) return c.json({ error: 'Correction not found' }, 404);
  
  if (correction.status === 'IN_PROGRESS') return c.json({ success: true }); // Idempotent
  if (correction.status !== 'OPEN') return c.json({ error: 'Correction is not OPEN' }, 400);

  const batch = [
    db.prepare(`UPDATE corrections SET status = 'IN_PROGRESS' WHERE id = ?`).bind(correctionId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, projectId, 'CORRECTION_STARTED', uid, 'DRAUGHTSMAN', 'Draughtsman started working on the correction.'
    )
  ];
  await db.batch(batch);
  return c.json({ success: true });
});

app.post('/api/projects/approve', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const body = await c.req.json();
  const { projectId, actionId } = body;
  
  const user = await getUser(db, uid);
  if (!user || user.role !== 'ADMIN') return c.json({ error: 'Only admins can approve projects' }, 403);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  if (project.status === 'WAITING_ASSIGNMENT' && project.last_action_id === actionId) return c.json({ success: true });
  if (project.status !== 'SUBMITTED') return c.json({ error: 'Project is not in SUBMITTED state' }, 400);

  const batch = [
    db.prepare(`UPDATE projects SET status = 'WAITING_ASSIGNMENT', approved_at = CURRENT_TIMESTAMP, last_action_id = ? WHERE id = ?`).bind(actionId, projectId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, projectId, 'PROJECT_APPROVED', uid, 'ADMIN', 'Studio Admin approved the project.'
    )
  ];
  await db.batch(batch);
  return c.json({ success: true });
});

app.post('/api/projects/reject', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const body = await c.req.json();
  const { projectId, actionId, reason } = body;
  
  const user = await getUser(db, uid);
  if (!user || user.role !== 'ADMIN') return c.json({ error: 'Only admins can reject projects' }, 403);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  if (project.status === 'CANCELLED' && project.last_action_id === actionId) return c.json({ success: true });
  if (project.status !== 'SUBMITTED') return c.json({ error: 'Project is not in SUBMITTED state' }, 400);

  const batch = [
    db.prepare(`UPDATE projects SET status = 'CANCELLED', rejection_reason = ?, cancelled_at = CURRENT_TIMESTAMP, last_action_id = ? WHERE id = ?`).bind(reason, actionId, projectId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, projectId, 'PROJECT_REJECTED', uid, 'ADMIN', 'Studio Admin rejected the project. Reason: ' + reason
    )
  ];
  await db.batch(batch);
  return c.json({ success: true });
});

app.post('/api/projects/approve-final', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const body = await c.req.json();
  const { projectId, actionId } = body;
  
  const user = await getUser(db, uid);
  if (!user || user.role !== 'CLIENT') return c.json({ error: 'Only clients can approve final drawings' }, 403);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  if (project.client_id !== uid) return c.json({ error: 'Permission denied' }, 403);
  if (project.status === 'COMPLETED' && project.last_action_id === actionId) return c.json({ success: true });
  if (project.status !== 'UNDER_CLIENT_REVIEW') return c.json({ error: 'Project is not in UNDER_CLIENT_REVIEW state' }, 400);

  const batch = [
    db.prepare(`UPDATE projects SET status = 'COMPLETED', completed_at = CURRENT_TIMESTAMP, last_action_id = ? WHERE id = ?`).bind(actionId, projectId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, projectId, 'PROJECT_COMPLETED', uid, 'CLIENT', 'Client approved the final drawing.'
    )
  ];
  await db.batch(batch);
  return c.json({ success: true });
});

app.post('/api/projects/request-correction', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const body = await c.req.json();
  const { projectId, actionId, correctionId, targetVersionId, description } = body;
  
  const user = await getUser(db, uid);
  if (!user || user.role !== 'CLIENT') return c.json({ error: 'Only clients can request corrections' }, 403);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  if (project.client_id !== uid) return c.json({ error: 'Permission denied' }, 403);
  
  if (project.status === 'IN_PROGRESS' && project.last_action_id === actionId) return c.json({ success: true });
  if (project.status !== 'UNDER_CLIENT_REVIEW') return c.json({ error: 'Project is not in UNDER_CLIENT_REVIEW state' }, 400);

  const currentRound = (project.correction_round as number) || 0;
  if (currentRound >= 3) {
    return c.json({ error: 'Maximum correction rounds (3) exceeded' }, 400);
  }

  const newRound = currentRound + 1;

  const batch = [
    db.prepare(`
      INSERT INTO corrections (id, project_id, requested_by, target_version_id, round_number, description, status)
      VALUES (?, ?, ?, ?, ?, ?, 'OPEN')
    `).bind(correctionId, projectId, uid, targetVersionId, newRound, description),
    db.prepare(`UPDATE projects SET status = 'IN_PROGRESS', correction_round = ?, last_action_id = ? WHERE id = ?`).bind(newRound, actionId, projectId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, projectId, 'CORRECTION_REQUESTED', uid, 'CLIENT', `Client requested correction (Round ${newRound}).`
    )
  ];
  await db.batch(batch);
  return c.json({ success: true, newRound });
});

// ──────────────────────────────────────────────────────────────────────────────
// Admin: Pin a redline correction on a drawing version.
//
// Smallest compatible API change — new ADMIN-only route. Writes to the same
// `corrections` table with the same (id, project_id, requested_by,
// target_version_id, round_number, description, status) schema.
//
// Optional pin coordinates are embedded as a compact prefix in the `description`
// field: "[PIN:0.4521,0.3182] Your annotation text here". This prefix is
// human-readable text — Flutter apps and the draughtsman portal already render
// `description` as a plain string, so they will display the full prefixed value
// without any change.  The admin portal parses the prefix to render visual pins.
//
// Security model preserved:
//   - ADMIN role required (403 otherwise)
//   - Same 3-round cap enforced server-side
//   - actionId idempotency via last_action_id
//   - Audit trail written to activity_logs
// ──────────────────────────────────────────────────────────────────────────────
app.post('/api/admin/projects/:projectId/corrections', async (c) => {
  const uid = c.get('uid');
  const projectId = c.req.param('projectId');
  const db = c.env.DB;

  const user = await getUser(db, uid);
  if (!user || user.role !== 'ADMIN') return c.json({ error: 'Permission denied' }, 403);

  const body = await c.req.json();
  const { actionId, description, targetVersionId, pinX, pinY } = body;

  if (!actionId || !description?.trim() || !targetVersionId) {
    return c.json({ error: 'actionId, description, and targetVersionId are required' }, 400);
  }

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  // Idempotency: if this actionId was already processed, return success immediately
  if (project.last_action_id === actionId) return c.json({ success: true });

  // Admin may annotate any active (non-terminal) project state
  const activeStatuses = ['SUBMITTED', 'WAITING_ASSIGNMENT', 'WAITING_ACCEPTANCE', 'IN_PROGRESS', 'UNDER_CLIENT_REVIEW'];
  if (!activeStatuses.includes(project.status as string)) {
    return c.json({ error: `Cannot add a correction to a project in ${project.status} state` }, 400);
  }

  // Enforce the shared 3-round correction cap — same rule as CLIENT flow
  const currentRound = (project.correction_round as number) || 0;
  if (currentRound >= 3) {
    return c.json({ error: 'Maximum correction limit (3 rounds) has been reached.' }, 400);
  }

  // Encode pin coordinates into description if provided.
  // Format: "[PIN:0.4521,0.3182] annotation text"
  // Backwards-compatible: other apps render description as plain text.
  const encodedDescription =
    pinX !== undefined && pinY !== undefined
      ? `[PIN:${Number(pinX).toFixed(4)},${Number(pinY).toFixed(4)}] ${description.trim()}`
      : description.trim();

  const correctionId = uuidv4();
  const nextRound = currentRound + 1;

  // Note: project status is NOT changed here — admin annotations do not
  // advance or revert the CLIENT/DRAUGHTSMAN state machine.
  const batch = [
    db.prepare(
      `INSERT INTO corrections (id, project_id, requested_by, target_version_id, round_number, description, status) VALUES (?, ?, ?, ?, ?, ?, 'OPEN')`
    ).bind(correctionId, projectId, uid, targetVersionId, nextRound, encodedDescription),
    db.prepare(
      `UPDATE projects SET correction_round = ?, last_action_id = ? WHERE id = ?`
    ).bind(nextRound, actionId, projectId),
    db.prepare(
      `INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`
    ).bind(
      actionId,
      projectId,
      'ADMIN_REDLINE_PINNED',
      uid,
      'ADMIN',
      `Admin pinned redline correction (Round ${nextRound}) on drawing version ${targetVersionId}.`
    ),
  ];
  await db.batch(batch);
  return c.json({ success: true, correctionId, round: nextRound });
});

app.post('/api/projects/assign', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const body = await c.req.json();
  const { projectId, actionId, draughtsmanId } = body;
  
  const user = await getUser(db, uid);
  if (!user || user.role !== 'ADMIN') return c.json({ error: 'Only admins can assign projects' }, 403);

  const dMan = await getUser(db, draughtsmanId);
  if (!dMan || dMan.role !== 'DRAUGHTSMAN') return c.json({ error: 'Invalid draughtsman ID' }, 400);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  if (project.status === 'WAITING_ACCEPTANCE' && project.last_action_id === actionId) return c.json({ success: true, idempotent: true });
  if (project.status !== 'WAITING_ASSIGNMENT') return c.json({ error: 'Project is not in WAITING_ASSIGNMENT state' }, 400);

  // Authoritative Draughtsman Capacity Check (maximum 4 active assignments)
  const activeRow = await db.prepare(`
    SELECT COUNT(*) as activeCount 
    FROM assignments a 
    JOIN projects p ON a.project_id = p.id 
    WHERE a.draughtsman_id = ? 
      AND a.status IN ('PENDING', 'ACCEPTED')
      AND p.status NOT IN ('COMPLETED', 'CANCELLED')
      AND a.project_id != ?
  `).bind(draughtsmanId, projectId).first();

  const activeCount = (activeRow?.activeCount as number) || 0;
  if (activeCount >= MAX_DRAUGHTSMAN_CAPACITY) {
    return c.json({
      error: `Draughtsman ${dMan.name} is at maximum capacity (${MAX_DRAUGHTSMAN_CAPACITY}/${MAX_DRAUGHTSMAN_CAPACITY} active projects)`,
      code: 'DRAUGHTSMAN_CAPACITY_EXCEEDED',
      currentWorkload: activeCount,
      maxCapacity: MAX_DRAUGHTSMAN_CAPACITY,
    }, 400);
  }

  const { label: slaLabel } = await getEffectiveTurnaroundHours(db);
  const assignmentId = uuidv4();

  const batch = [
    db.prepare(`INSERT INTO assignments (id, project_id, draughtsman_id, status) VALUES (?, ?, ?, 'PENDING')`).bind(assignmentId, projectId, draughtsmanId),
    db.prepare(`UPDATE projects SET status = 'WAITING_ACCEPTANCE', draughtsman_id = ?, draughtsman_name = ?, current_assignment_id = ?, assigned_at = CURRENT_TIMESTAMP, last_action_id = ? WHERE id = ?`).bind(draughtsmanId, dMan.name, assignmentId, actionId, projectId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, projectId, 'DRAUGHTSMAN_ASSIGNED', uid, 'ADMIN', `Studio Admin assigned draughtsman: ${dMan.name} (Turnaround SLA: ${slaLabel})`
    )
  ];
  await db.batch(batch);
  return c.json({ success: true, assignmentId });
});

app.post('/api/projects/reassign', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const body = await c.req.json();
  const { projectId, actionId, draughtsmanId } = body;
  
  const user = await getUser(db, uid);
  if (!user || user.role !== 'ADMIN') return c.json({ error: 'Only admins can reassign projects' }, 403);

  const dMan = await getUser(db, draughtsmanId);
  if (!dMan || dMan.role !== 'DRAUGHTSMAN') return c.json({ error: 'Invalid draughtsman ID' }, 400);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  
  if (project.last_action_id === actionId) return c.json({ success: true, idempotent: true });
  
  // Can reassign if waiting acceptance, in progress, or waiting assignment
  if (!['WAITING_ACCEPTANCE', 'IN_PROGRESS', 'WAITING_ASSIGNMENT'].includes(project.status as string)) {
    return c.json({ error: 'Project cannot be reassigned in its current state' }, 400);
  }

  // Authoritative Draughtsman Capacity Check for destination draughtsman
  const activeRow = await db.prepare(`
    SELECT COUNT(*) as activeCount 
    FROM assignments a 
    JOIN projects p ON a.project_id = p.id 
    WHERE a.draughtsman_id = ? 
      AND a.status IN ('PENDING', 'ACCEPTED')
      AND p.status NOT IN ('COMPLETED', 'CANCELLED')
      AND a.project_id != ?
  `).bind(draughtsmanId, projectId).first();

  const activeCount = (activeRow?.activeCount as number) || 0;
  if (activeCount >= MAX_DRAUGHTSMAN_CAPACITY) {
    return c.json({
      error: `Destination Draughtsman ${dMan.name} is at maximum capacity (${MAX_DRAUGHTSMAN_CAPACITY}/${MAX_DRAUGHTSMAN_CAPACITY} active projects)`,
      code: 'DRAUGHTSMAN_CAPACITY_EXCEEDED',
      currentWorkload: activeCount,
      maxCapacity: MAX_DRAUGHTSMAN_CAPACITY,
    }, 400);
  }

  const { label: slaLabel } = await getEffectiveTurnaroundHours(db);
  const assignmentId = uuidv4();
  const batch = [];
  
  if (project.current_assignment_id) {
    batch.push(db.prepare(`UPDATE assignments SET status = 'REPLACED', updated_at = CURRENT_TIMESTAMP WHERE id = ?`).bind(project.current_assignment_id));
  }

  batch.push(db.prepare(`INSERT INTO assignments (id, project_id, draughtsman_id, status) VALUES (?, ?, ?, 'PENDING')`).bind(assignmentId, projectId, draughtsmanId));
  batch.push(db.prepare(`UPDATE projects SET status = 'WAITING_ACCEPTANCE', draughtsman_id = ?, draughtsman_name = ?, current_assignment_id = ?, assigned_at = CURRENT_TIMESTAMP, last_action_id = ? WHERE id = ?`).bind(draughtsmanId, dMan.name, assignmentId, actionId, projectId));
  batch.push(db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
    actionId, projectId, 'DRAUGHTSMAN_REASSIGNED', uid, 'ADMIN', `Studio Admin reassigned to draughtsman: ${dMan.name} (Turnaround SLA: ${slaLabel})`
  ));

  await db.batch(batch);
  return c.json({ success: true, assignmentId });
});

app.post('/api/assignments/accept', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const body = await c.req.json();
  const { assignmentId, projectId, actionId } = body;
  
  const user = await getUser(db, uid);
  if (!user || user.role !== 'DRAUGHTSMAN') return c.json({ error: 'Only draughtsmen can accept assignments' }, 403);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  if (project.status === 'IN_PROGRESS' && project.last_action_id === actionId) return c.json({ success: true });
  
  if (project.current_assignment_id !== assignmentId) return c.json({ error: 'Not the current assignment' }, 400);
  if (project.draughtsman_id !== uid) return c.json({ error: 'Not assigned to you' }, 403);
  if (project.status !== 'WAITING_ACCEPTANCE') return c.json({ error: 'Project is not in WAITING_ACCEPTANCE state' }, 400);

  const assignment = await db.prepare('SELECT * FROM assignments WHERE id = ?').bind(assignmentId).first();
  if (!assignment) return c.json({ error: 'Assignment not found' }, 404);
  if (assignment.status !== 'PENDING') return c.json({ error: 'Assignment is not PENDING' }, 400);

  const batch = [
    db.prepare(`UPDATE assignments SET status = 'ACCEPTED', updated_at = CURRENT_TIMESTAMP WHERE id = ?`).bind(assignmentId),
    db.prepare(`UPDATE projects SET status = 'IN_PROGRESS', last_action_id = ? WHERE id = ?`).bind(actionId, projectId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, projectId, 'ASSIGNMENT_ACCEPTED', uid, 'DRAUGHTSMAN', 'Draughtsman accepted the assignment.'
    )
  ];
  await db.batch(batch);
  return c.json({ success: true });
});

app.post('/api/assignments/reject', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const body = await c.req.json();
  const { assignmentId, projectId, actionId } = body;
  
  const user = await getUser(db, uid);
  if (!user || user.role !== 'DRAUGHTSMAN') return c.json({ error: 'Only draughtsmen can reject assignments' }, 403);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  if (project.status === 'WAITING_ASSIGNMENT' && project.last_action_id === actionId) return c.json({ success: true });
  
  if (project.current_assignment_id !== assignmentId) return c.json({ error: 'Not the current assignment' }, 400);
  if (project.draughtsman_id !== uid) return c.json({ error: 'Not assigned to you' }, 403);
  if (project.status !== 'WAITING_ACCEPTANCE') return c.json({ error: 'Project is not in WAITING_ACCEPTANCE state' }, 400);

  const assignment = await db.prepare('SELECT * FROM assignments WHERE id = ?').bind(assignmentId).first();
  if (!assignment) return c.json({ error: 'Assignment not found' }, 404);
  if (assignment.status !== 'PENDING') return c.json({ error: 'Assignment is not PENDING' }, 400);

  const batch = [
    db.prepare(`UPDATE assignments SET status = 'REJECTED', updated_at = CURRENT_TIMESTAMP WHERE id = ?`).bind(assignmentId),
    db.prepare(`UPDATE projects SET status = 'WAITING_ASSIGNMENT', draughtsman_id = NULL, draughtsman_name = NULL, current_assignment_id = NULL, last_action_id = ? WHERE id = ?`).bind(actionId, projectId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, projectId, 'ASSIGNMENT_REJECTED', uid, 'DRAUGHTSMAN', 'Draughtsman rejected the assignment.'
    )
  ];
  await db.batch(batch);
  return c.json({ success: true });
});

app.get('/api/assignments', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);
  
  if (!user) return c.json({ error: 'User not found' }, 404);
  if (user.role !== 'DRAUGHTSMAN') return c.json({ error: 'Only draughtsmen can view assignments' }, 403);

  const { results } = await db.prepare('SELECT * FROM assignments WHERE draughtsman_id = ? ORDER BY created_at DESC').bind(uid).all();
  return c.json(results);
});

// GET /api/assignments/:id — Resolves assignment by either assignmentId or projectId
app.get('/api/assignments/:id', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const assignmentId = c.req.param('id');
  const user = await getUser(db, uid);

  if (!user) return c.json({ error: 'User not found' }, 404);

  const assignment = await db.prepare(`
    SELECT
      a.*,
      p.project_name, p.drawing_type, p.drawing_name, p.project_address, p.project_area,
      p.submitted_at, p.approved_at, p.assigned_at, p.rejected_at, p.cancelled_at
    FROM assignments a
    LEFT JOIN projects p ON a.project_id = p.id
    WHERE a.id = ? OR a.project_id = ?
    ORDER BY (CASE WHEN a.id = ? THEN 1 ELSE 2 END), a.created_at DESC
    LIMIT 1
  `).bind(assignmentId, assignmentId, assignmentId).first();

  if (!assignment) return c.json({ error: 'Assignment not found' }, 404);

  if (user.role === 'DRAUGHTSMAN' && assignment.draughtsman_id !== uid) {
    return c.json({ error: 'Permission denied' }, 403);
  }

  return c.json(assignment);
});

// Admin: Global cross-project assignment history (Authoritative Stitch Screen 07 ledger)
app.get('/api/admin/assignments', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);
  
  if (!user || user.role !== 'ADMIN') {
    return c.json({ error: 'Permission denied: Studio Admin required' }, 403);
  }

  const status = c.req.query('status');
  const draughtsmanId = c.req.query('draughtsmanId');
  const projectId = c.req.query('projectId');

  let query = `
    SELECT 
      a.id,
      a.project_id,
      a.draughtsman_id,
      a.status,
      a.created_at,
      a.updated_at,
      p.project_name,
      p.status as project_status,
      p.drawing_type,
      p.project_area,
      p.client_id,
      c.name as client_name,
      d.name as draughtsman_name,
      d.email as draughtsman_email
    FROM assignments a
    LEFT JOIN projects p ON a.project_id = p.id
    LEFT JOIN users c ON p.client_id = c.id
    LEFT JOIN users d ON a.draughtsman_id = d.id
    WHERE 1=1
  `;
  const params: any[] = [];

  if (status && status !== 'ALL') {
    query += ' AND a.status = ?';
    params.push(status);
  }
  if (draughtsmanId) {
    query += ' AND a.draughtsman_id = ?';
    params.push(draughtsmanId);
  }
  if (projectId) {
    query += ' AND a.project_id = ?';
    params.push(projectId);
  }

  query += ' ORDER BY a.created_at DESC';

  const { results } = await db.prepare(query).bind(...params).all();
  return c.json(results || []);
});

// ==========================================
// STORAGE API (Streaming via Worker)
// ==========================================

async function verifyDraughtsmanWorkspaceAccess(db: D1Database, project: any, uid: string) {
  if (project.draughtsman_id !== uid) return false;
  if (!project.current_assignment_id) return false;
  const assignment = await db.prepare('SELECT status FROM assignments WHERE id = ?').bind(project.current_assignment_id).first();
  if (!assignment || assignment.status !== 'ACCEPTED') return false;
  return true;
}

app.get('/api/projects/:projectId/files', async (c) => {
  const uid = c.get('uid');
  const projectId = c.req.param('projectId');
  const db = c.env.DB;
  const user = await getUser(db, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  // Check authorization
  if (user.role === 'CLIENT' && project.client_id !== uid) return c.json({ error: 'Forbidden' }, 403);
  if (user.role === 'DRAUGHTSMAN') {
    const hasAccess = await verifyDraughtsmanWorkspaceAccess(db, project, uid);
    if (!hasAccess) return c.json({ error: 'Forbidden: Workspace access denied' }, 403);
  }

  const { results } = await db.prepare('SELECT * FROM files WHERE project_id = ? ORDER BY created_at DESC').bind(projectId).all();
  return c.json(results);
});

app.get('/api/projects/:projectId/drawing_versions', async (c) => {
  const uid = c.get('uid');
  const projectId = c.req.param('projectId');
  const db = c.env.DB;
  const user = await getUser(db, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  if (user.role === 'CLIENT' && project.client_id !== uid) return c.json({ error: 'Forbidden' }, 403);
  if (user.role === 'DRAUGHTSMAN') {
    const hasAccess = await verifyDraughtsmanWorkspaceAccess(db, project, uid);
    if (!hasAccess) return c.json({ error: 'Forbidden: Workspace access denied' }, 403);
  }

  const { results } = await db.prepare('SELECT dv.*, f.original_name, f.sanitized_name, f.size FROM drawing_versions dv JOIN files f ON dv.file_id = f.id WHERE dv.project_id = ? ORDER BY dv.version_number DESC').bind(projectId).all();
  return c.json(results);
});

app.get('/api/projects/:projectId/corrections', async (c) => {
  const uid = c.get('uid');
  const projectId = c.req.param('projectId');
  const db = c.env.DB;
  const user = await getUser(db, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  if (user.role === 'CLIENT' && project.client_id !== uid) return c.json({ error: 'Forbidden' }, 403);
  if (user.role === 'DRAUGHTSMAN') {
    const hasAccess = await verifyDraughtsmanWorkspaceAccess(db, project, uid);
    if (!hasAccess) return c.json({ error: 'Forbidden: Workspace access denied' }, 403);
  }

  const { results } = await db.prepare('SELECT * FROM corrections WHERE project_id = ? ORDER BY round_number DESC').bind(projectId).all();
  return c.json(results);
});

app.post('/api/projects/:projectId/files', async (c) => {
  const uid = c.get('uid');
  const projectId = c.req.param('projectId');
  const category = c.req.query('category');
  
  if (!category || !['client_upload', 'draughtsman_version', 'correction_attachment'].includes(category)) {
    return c.json({ error: 'Invalid category' }, 400);
  }

  const actionId = c.req.header('X-Action-Id');
  if (!actionId) return c.json({ error: 'X-Action-Id header is required' }, 400);

  const fileName = c.req.header('X-File-Name');
  if (!fileName) return c.json({ error: 'X-File-Name header is required' }, 400);

  // Validate extension server-side
  const sanitizedName = fileName.replace(/[^a-zA-Z0-9.-]/g, '_');
  const ext = sanitizedName.split('.').pop()?.toLowerCase();
  const allowedExtensions = ['pdf', 'dwg', 'dxf', 'png', 'jpg', 'jpeg', 'zip'];
  
  if (!ext || !allowedExtensions.includes(ext)) {
    return c.json({ error: 'Invalid file extension. Allowed: ' + allowedExtensions.join(', ') }, 400);
  }

  // Authoritative MIME mapping
  const mimeMap: Record<string, string> = {
    pdf: 'application/pdf',
    png: 'image/png',
    jpg: 'image/jpeg',
    jpeg: 'image/jpeg',
    zip: 'application/zip',
    dwg: 'application/acad',
    dxf: 'application/dxf',
  };
  const contentType = mimeMap[ext] || 'application/octet-stream';

  const db = c.env.DB;
  const user = await getUser(db, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  // Authorization checks
  if (category === 'client_upload' || category === 'correction_attachment') {
    if (user.role !== 'ADMIN' && (user.role !== 'CLIENT' || project.client_id !== uid)) {
      return c.json({ error: 'Forbidden' }, 403);
    }
  } else if (category === 'draughtsman_version') {
    const hasAccess = await verifyDraughtsmanWorkspaceAccess(db, project, uid);
    if (!hasAccess || project.status !== 'IN_PROGRESS') {
      return c.json({ error: 'Forbidden: Workspace access denied or invalid project state' }, 403);
    }
  }

  // Idempotency Check
  const existingFile = await db.prepare('SELECT * FROM files WHERE id = ?').bind(actionId).first();
  if (existingFile) {
    if (existingFile.status === 'COMPLETED') {
      return c.json(existingFile);
    }
    // If REQUESTED or FAILED, we will overwrite and retry the upload
  }

  const categoryPath = category === 'draughtsman_version' ? 'draughtsman_versions' : category;
  const objectKey = `projects/${projectId}/${categoryPath}/${actionId}_${sanitizedName}`;

  // Check dynamic studio upload ceiling from D1 settings
  const maxUploadCeilingBytes = await getEffectiveMaxUploadCeilingBytes(db);
  const contentLengthHeader = c.req.header('Content-Length');
  if (contentLengthHeader) {
    const declaredBytes = parseInt(contentLengthHeader, 10);
    if (!isNaN(declaredBytes) && declaredBytes > maxUploadCeilingBytes) {
      const limitMB = Math.round(maxUploadCeilingBytes / (1024 * 1024));
      return c.json({
        error: `File size exceeds studio upload ceiling of ${limitMB} MB`,
        code: 'UPLOAD_SIZE_EXCEEDED',
        maxCeilingBytes: maxUploadCeilingBytes,
      }, 413);
    }
  }

  // Insert or Update metadata as REQUESTED
  await db.prepare(`
    INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status)
    VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?, 'REQUESTED')
    ON CONFLICT(id) DO UPDATE SET 
      status = 'REQUESTED',
      created_at = CURRENT_TIMESTAMP
  `).bind(actionId, projectId, uid, fileName, sanitizedName, objectKey, contentType, category).run();

  try {
    if (!c.req.raw.body) throw new Error('Empty body');

    let byteCount = 0;

    // True server-side dynamic upload ceiling limit using TransformStream
    const transform = new TransformStream({
      transform(chunk, controller) {
        byteCount += chunk.length;
        if (byteCount > maxUploadCeilingBytes) {
          const limitMB = Math.round(maxUploadCeilingBytes / (1024 * 1024));
          controller.error(new Error(`File exceeds studio upload ceiling (${limitMB} MB limit)`));
        } else {
          controller.enqueue(chunk);
        }
      }
    });

    const streamToR2 = c.req.raw.body.pipeThrough(transform);

    await c.env.STORAGE.put(objectKey, streamToR2, {
      httpMetadata: { contentType: contentType }
    });

    // Update status to COMPLETED and save actual byte count
    await db.prepare(`UPDATE files SET status = 'COMPLETED', size = ? WHERE id = ?`).bind(byteCount, actionId).run();
    
    if (category === 'draughtsman_version') {
      const latest = await db.prepare('SELECT MAX(version_number) as v FROM drawing_versions WHERE project_id = ?').bind(projectId).first();
      const vNum = ((latest?.v as number) || 0) + 1;
      const corr = await db.prepare('SELECT id FROM corrections WHERE project_id = ? AND status IN ("OPEN", "IN_PROGRESS")').bind(projectId).first();
      
      await db.prepare(`
        INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by, correction_id) 
        VALUES (?, ?, ?, ?, ?, ?)
      `).bind(uuidv4(), projectId, actionId, vNum, uid, (corr?.id as string) || null).run();
    }

    // Log activity
    await db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      uuidv4(), projectId, 'FILE_UPLOADED', uid, user.role, `Uploaded ${category} file: ${sanitizedName}`
    ).run();

    const fileMeta = await db.prepare('SELECT * FROM files WHERE id = ?').bind(actionId).first();
    return c.json(fileMeta);
  } catch (err: any) {
    // Mark as FAILED
    await db.prepare(`UPDATE files SET status = 'FAILED' WHERE id = ?`).bind(actionId).run();
    console.error('Upload failed:', err);
    const isSizeError = err?.message && err.message.includes('exceeds studio upload ceiling');
    return c.json({
      error: err.message || 'Upload failed',
      code: isSizeError ? 'UPLOAD_SIZE_EXCEEDED' : 'STORAGE_ERROR'
    }, isSizeError ? 413 : 500);
  }
});

app.get('/api/files/:fileId/download', async (c) => {
  const uid = c.get('uid');
  const fileId = c.req.param('fileId');
  
  const db = c.env.DB;
  const user = await getUser(db, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);

  const fileMeta = await db.prepare('SELECT * FROM files WHERE id = ?').bind(fileId).first();
  if (!fileMeta) return c.json({ error: 'File not found' }, 404);
  if (fileMeta.status !== 'COMPLETED') return c.json({ error: 'File upload not complete' }, 400);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(fileMeta.project_id).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  // Authorization checks
  if (user.role === 'CLIENT' && project.client_id !== uid) return c.json({ error: 'Forbidden' }, 403);
  if (user.role === 'DRAUGHTSMAN') {
    const hasAccess = await verifyDraughtsmanWorkspaceAccess(db, project, uid);
    if (!hasAccess) return c.json({ error: 'Forbidden: Workspace access denied' }, 403);
  }

  const object = await c.env.STORAGE.get(fileMeta.object_key as string);
  if (!object) return c.json({ error: 'File object missing in R2' }, 404);

  const headers = new Headers();
  object.writeHttpMetadata(headers as any);
  headers.set('etag', object.httpEtag);
  headers.set('Content-Disposition', `attachment; filename="${fileMeta.sanitized_name}"`);

  return new Response(object.body, { headers });
});

// ──────────────────────────────────────────
// ADMIN PANEL ENDPOINTS
// ──────────────────────────────────────────

// GET /api/admin/stats — Dashboard aggregate statistics (ADMIN only)
app.get('/api/admin/stats', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);
  if (!user || user.role !== 'ADMIN') return c.json({ error: 'Permission denied' }, 403);

  const [
    totalProjects,
    byStatus,
    totalUsers,
    usersByRole,
    recentActivity,
  ] = await Promise.all([
    db.prepare('SELECT COUNT(*) as count FROM projects').first(),
    db.prepare(`
      SELECT status, COUNT(*) as count FROM projects GROUP BY status
    `).all(),
    db.prepare('SELECT COUNT(*) as count FROM users').first(),
    db.prepare(`
      SELECT role, COUNT(*) as count FROM users GROUP BY role
    `).all(),
    db.prepare(`
      SELECT * FROM activity_logs ORDER BY timestamp DESC LIMIT 20
    `).all(),
  ]);

  const statusCounts: Record<string, number> = {};
  for (const row of (byStatus.results || [])) {
    statusCounts[row.status as string] = row.count as number;
  }

  const roleCounts: Record<string, number> = {};
  for (const row of (usersByRole.results || [])) {
    roleCounts[row.role as string] = row.count as number;
  }

  return c.json({
    projects: {
      total: totalProjects?.count ?? 0,
      byStatus: statusCounts,
    },
    users: {
      total: totalUsers?.count ?? 0,
      byRole: roleCounts,
      registeredEngineers: (roleCounts['ENGINEER'] || 0) + (roleCounts['CLIENT'] || 0),
    },
    recentActivity: recentActivity.results || [],
  });
});

// GET /api/admin/dashboard — Authoritative executive platform metrics across portals
app.get('/api/admin/dashboard', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) {
    return c.json({ error: 'Permission denied' }, 403);
  }

  const batch = [
    db.prepare('SELECT COUNT(*) as c FROM projects'),
    db.prepare("SELECT COUNT(*) as c FROM projects WHERE status = 'SUBMITTED'"),
    db.prepare("SELECT COUNT(*) as c FROM projects WHERE status = 'IN_PROGRESS'"),
    db.prepare("SELECT COUNT(*) as c FROM projects WHERE status IN ('UNDER_ENGINEER_REVIEW', 'UNDER_CLIENT_REVIEW')"),
    db.prepare("SELECT COUNT(*) as c FROM projects WHERE status = 'COMPLETED'"),
    db.prepare("SELECT COUNT(*) as c FROM users WHERE role = 'DRAUGHTSMAN'"),
    db.prepare("SELECT COUNT(*) as c FROM assignments WHERE status = 'PENDING'"),
    db.prepare("SELECT COUNT(DISTINCT id) as c FROM users WHERE role IN ('ENGINEER', 'CLIENT')")
  ];

  const results = await db.batch(batch);

  return c.json({
    totalProjects: (results[0].results?.[0] as any)?.c || 0,
    submittedProjects: (results[1].results?.[0] as any)?.c || 0,
    activeProjects: (results[2].results?.[0] as any)?.c || 0,
    inReviewProjects: (results[3].results?.[0] as any)?.c || 0,
    completedProjects: (results[4].results?.[0] as any)?.c || 0,
    activeDraughtsmen: (results[5].results?.[0] as any)?.c || 0,
    pendingAssignments: (results[6].results?.[0] as any)?.c || 0,
    registeredEngineers: (results[7].results?.[0] as any)?.c || 0,
    activeEngineers: (results[7].results?.[0] as any)?.c || 0,
  });
});

// GET /api/projects/:projectId — Single project fetch (role-scoped, normalized with client and assignment)
app.get('/api/projects/:projectId', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const projectId = c.req.param('projectId');
  const user = await getUser(db, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);

  const project = await db.prepare(`
    SELECT
      p.*,
      u.name as client_name,
      u.email as client_email,
      (SELECT a.id FROM assignments a WHERE a.project_id = p.id AND a.status IN ('PENDING', 'ACCEPTED') ORDER BY a.created_at DESC LIMIT 1) as current_assignment_id
    FROM projects p
    LEFT JOIN users u ON p.client_id = u.id
    WHERE p.id = ?
  `).bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  // Role-scoped access control
  if (user.role === 'CLIENT' && project.client_id !== uid) {
    return c.json({ error: 'Forbidden' }, 403);
  }
  if (user.role === 'DRAUGHTSMAN' && project.draughtsman_id !== uid) {
    return c.json({ error: 'Forbidden' }, 403);
  }
  // ADMIN can view any project

  const { hours: slaHours, label: slaLabel } = await getEffectiveTurnaroundHours(db);
  const baseTimestamp = (project as any).assigned_at || (project as any).submitted_at || (project as any).created_at;
  const estimatedDeadline = baseTimestamp
    ? new Date(new Date(baseTimestamp).getTime() + slaHours * 3600 * 1000).toISOString()
    : null;

  return c.json({
    ...project,
    turnaround_sla: slaLabel,
    turnaround_hours: slaHours,
    estimated_deadline: estimatedDeadline,
  });
});

// Alias for /api/projects/:id
app.get('/api/projects/:id', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const projectId = c.req.param('id');
  const user = await getUser(db, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);

  const project = await db.prepare(`
    SELECT
      p.*,
      u.name as client_name,
      u.email as client_email,
      (SELECT a.id FROM assignments a WHERE a.project_id = p.id AND a.status IN ('PENDING', 'ACCEPTED') ORDER BY a.created_at DESC LIMIT 1) as current_assignment_id
    FROM projects p
    LEFT JOIN users u ON p.client_id = u.id
    WHERE p.id = ?
  `).bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  if (user.role === 'CLIENT' && project.client_id !== uid) {
    return c.json({ error: 'Forbidden' }, 403);
  }
  if (user.role === 'DRAUGHTSMAN' && project.draughtsman_id !== uid) {
    return c.json({ error: 'Forbidden' }, 403);
  }

  const { hours: slaHours, label: slaLabel } = await getEffectiveTurnaroundHours(db);
  const baseTimestamp = (project as any).assigned_at || (project as any).submitted_at || (project as any).created_at;
  const estimatedDeadline = baseTimestamp
    ? new Date(new Date(baseTimestamp).getTime() + slaHours * 3600 * 1000).toISOString()
    : null;

  return c.json({
    ...project,
    turnaround_sla: slaLabel,
    turnaround_hours: slaHours,
    estimated_deadline: estimatedDeadline,
  });
});

// GET /api/projects/:projectId/activity — Activity logs for a project (role-scoped)
app.get('/api/projects/:projectId/activity', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const projectId = c.req.param('projectId');
  const user = await getUser(db, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  // Role-scoped access control
  if (user.role === 'CLIENT' && project.client_id !== uid) {
    return c.json({ error: 'Forbidden' }, 403);
  }
  if (user.role === 'DRAUGHTSMAN' && project.draughtsman_id !== uid) {
    return c.json({ error: 'Forbidden' }, 403);
  }
  // ADMIN can view any project's activity

  const { results } = await db.prepare(
    'SELECT * FROM activity_logs WHERE project_id = ? ORDER BY timestamp DESC'
  ).bind(projectId).all();

  return c.json(results || []);
});

// GET /api/projects/:projectId/assignments — Assignment history for a project (ADMIN only)
app.get('/api/projects/:projectId/assignments', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const projectId = c.req.param('projectId');
  const user = await getUser(db, uid);
  if (!user || user.role !== 'ADMIN') return c.json({ error: 'Permission denied' }, 403);

  const { results } = await db.prepare(`
    SELECT a.*, u.name as draughtsman_name, u.email as draughtsman_email
    FROM assignments a
    LEFT JOIN users u ON a.draughtsman_id = u.id
    WHERE a.project_id = ?
    ORDER BY a.created_at DESC
  `).bind(projectId).all();

  return c.json(results || []);
});

// POST /api/projects/cancel — Admin cancels a project (ADMIN only)
app.post('/api/projects/cancel', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const body = await c.req.json();
  const { projectId, actionId, reason } = body;

  const user = await getUser(db, uid);
  if (!user || user.role !== 'ADMIN') return c.json({ error: 'Only admins can cancel projects' }, 403);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  // Cannot cancel already COMPLETED or CANCELLED projects
  if (project.status === 'COMPLETED' || project.status === 'CANCELLED') {
    return c.json({ error: `Cannot cancel project in ${project.status} state` }, 400);
  }

  // Idempotency check
  if (project.last_action_id === actionId) {
    return c.json({ message: 'Action already processed (idempotent)' }, 200);
  }

  const batch = [
    db.prepare(`UPDATE projects SET status = 'CANCELLED', cancelled_at = CURRENT_TIMESTAMP, last_action_id = ? WHERE id = ?`).bind(actionId, projectId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, projectId, 'PROJECT_CANCELLED', uid, 'ADMIN', 'Admin cancelled the project. Reason: ' + (reason || 'No reason provided')
    )
  ];

  // If there's an active assignment, cancel it too
  if (project.current_assignment_id) {
    batch.push(
      db.prepare(`UPDATE assignments SET status = 'CANCELLED', updated_at = CURRENT_TIMESTAMP WHERE id = ?`).bind(project.current_assignment_id)
    );
  }

  await db.batch(batch);
  return c.json({ message: 'Project cancelled successfully' });
});

// POST /api/admin/projects — Admin initiates a project brief for an Engineer (ADMIN only)
app.post('/api/admin/projects', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);
  if (!user || user.role !== 'ADMIN') {
    return c.json({ error: 'Permission denied: Only studio admins can initialize project briefs' }, 403);
  }

  const body = await c.req.json();
  const clientId = body.clientId || body.client_id;
  const projectName = body.projectName || body.project_name;
  const projectAddress = body.projectAddress || body.project_address;
  const drawingName = body.drawingName || body.drawing_name;
  const drawingType = body.drawingType || body.drawing_type;
  const projectArea = body.projectArea || body.project_area;
  const actionId = body.actionId || uuidv4();

  if (!projectName || !String(projectName).trim()) {
    return c.json({ error: 'Project name is required' }, 400);
  }
  if (!clientId || !String(clientId).trim()) {
    return c.json({ error: 'Associated Engineer (client) ID is required' }, 400);
  }
  if (!drawingType || !String(drawingType).trim()) {
    return c.json({ error: 'Drawing type is required' }, 400);
  }

  // Validate that the target user exists and has CLIENT (Engineer) role
  const engineer = await getUser(db, String(clientId).trim());
  if (!engineer || engineer.role !== 'CLIENT') {
    return c.json({ error: 'Invalid engineer association: User not found or does not have Engineer (CLIENT) role' }, 400);
  }

  // Idempotency: verify if this actionId was already processed
  const existingProject = await db.prepare('SELECT * FROM projects WHERE last_action_id = ?').bind(actionId).first();
  if (existingProject) {
    return c.json({ success: true, id: existingProject.id, idempotent: true }, 200);
  }

  const projectId = body.id || uuidv4();
  const address = (projectAddress && String(projectAddress).trim()) || 'Draughtsman Studio Scope';
  const dwgName = (drawingName && String(drawingName).trim()) || `${String(drawingType).trim()} Package`;
  const area = projectArea ? String(projectArea) : '1500';

  const { label: slaLabel } = await getEffectiveTurnaroundHours(db);

  const batch = [
    db.prepare(`
      INSERT INTO projects (
        id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, submitted_at, last_action_id
      ) VALUES (?, ?, ?, ?, ?, ?, ?, 'SUBMITTED', CURRENT_TIMESTAMP, ?)
    `).bind(
      projectId, String(clientId).trim(), String(projectName).trim(), address, dwgName, String(drawingType).trim(), area, actionId
    ),
    db.prepare(`
      INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details)
      VALUES (?, ?, ?, ?, ?, ?)
    `).bind(
      actionId, projectId, 'PROJECT_SUBMITTED', uid, 'ADMIN', `Studio Admin initialized project brief "${String(projectName).trim()}" for Engineer: ${engineer.name} (Turnaround SLA: ${slaLabel})`
    )
  ];

  await db.batch(batch);
  return c.json({ success: true, id: projectId }, 201);
});

// ──────────────────────────────────────────────────────────────────────────────
// Collaboration Hub: Persistent Project Discussion & Comments
// ──────────────────────────────────────────────────────────────────────────────

async function ensureCommentsTable(db: any) {
  await db.prepare(`
    CREATE TABLE IF NOT EXISTS project_comments (
      id TEXT PRIMARY KEY,
      project_id TEXT NOT NULL,
      author_id TEXT NOT NULL,
      author_name TEXT NOT NULL,
      author_role TEXT NOT NULL,
      content TEXT NOT NULL,
      attachment_name TEXT,
      attachment_size TEXT,
      attachment_type TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `).run().catch(() => {});
}

// GET /api/projects/:projectId/comments — Retrieve project discussion thread
app.get('/api/projects/:projectId/comments', async (c) => {
  const uid = c.get('uid');
  const projectId = c.req.param('projectId');
  const db = c.env.DB;
  const user = await getUser(db, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  // Authorization: ADMIN, assigned DRAUGHTSMAN, or project CLIENT
  if (user.role === 'ADMIN') {
    // Studio Admin has global project access
  } else if (user.role === 'CLIENT') {
    if (project.client_id !== uid) {
      return c.json({ error: 'Forbidden: You can only view comments on your own projects' }, 403);
    }
  } else if (user.role === 'DRAUGHTSMAN') {
    const hasAccess = await verifyDraughtsmanWorkspaceAccess(db, project, uid);
    if (!hasAccess) return c.json({ error: 'Forbidden: Workspace access denied' }, 403);
  } else {
    return c.json({ error: 'Forbidden: Insufficient privileges' }, 403);
  }

  await ensureCommentsTable(db);
  const { results } = await db.prepare(
    'SELECT * FROM project_comments WHERE project_id = ? ORDER BY created_at ASC'
  ).bind(projectId).all();

  return c.json(results || []);
});

// POST /api/projects/:projectId/comments — Post a persistent message to the project thread
app.post('/api/projects/:projectId/comments', async (c) => {
  const uid = c.get('uid');
  const projectId = c.req.param('projectId');
  const db = c.env.DB;
  const user = await getUser(db, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  // Authorization: ADMIN, assigned DRAUGHTSMAN, or project CLIENT
  if (user.role === 'ADMIN') {
    // Studio Admin has global project access
  } else if (user.role === 'CLIENT') {
    if (project.client_id !== uid) {
      return c.json({ error: 'Forbidden: You can only comment on your own projects' }, 403);
    }
  } else if (user.role === 'DRAUGHTSMAN') {
    const hasAccess = await verifyDraughtsmanWorkspaceAccess(db, project, uid);
    if (!hasAccess) return c.json({ error: 'Forbidden: You are not assigned to this project' }, 403);
  } else {
    return c.json({ error: 'Forbidden: Insufficient privileges' }, 403);
  }

  const body = await c.req.json();
  const content = body.content ? String(body.content).trim() : '';
  const actionId = body.actionId || uuidv4();
  const attachmentName = body.attachmentName || null;
  const attachmentSize = body.attachmentSize || null;
  const attachmentType = body.attachmentType || null;

  if (!content && !attachmentName) {
    return c.json({ error: 'Comment content or attachment is required' }, 400);
  }

  await ensureCommentsTable(db);

  // Idempotency: verify if actionId was already processed
  const existing = await db.prepare('SELECT * FROM project_comments WHERE id = ?').bind(actionId).first();
  if (existing) {
    return c.json({ success: true, comment: existing, idempotent: true }, 200);
  }

  const commentId = actionId;
  const batch = [
    db.prepare(`
      INSERT INTO project_comments (
        id, project_id, author_id, author_name, author_role, content, attachment_name, attachment_size, attachment_type
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      commentId, projectId, uid, user.name, user.role, content, attachmentName, attachmentSize, attachmentType
    ),
    db.prepare(`
      INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details)
      VALUES (?, ?, ?, ?, ?, ?)
    `).bind(
      uuidv4(), projectId, 'COMMENT_POSTED', uid, user.role, `${user.name} (${user.role}) posted a project message: "${content.substring(0, 60)}${content.length > 60 ? '...' : ''}"`
    )
  ];

  await db.batch(batch);

  const newComment = await db.prepare('SELECT * FROM project_comments WHERE id = ?').bind(commentId).first();
  return c.json({ success: true, comment: newComment }, 201);
});

export default app;
