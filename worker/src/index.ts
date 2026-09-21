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

app.use('*', cors({
  origin: '*',
  allowHeaders: ['X-File-Name', 'X-Action-Id', 'Content-Type', 'Authorization', 'Content-Length'],
  allowMethods: ['POST', 'GET', 'OPTIONS', 'PUT', 'DELETE', 'PATCH'],
}));

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
  await next();
});

// Helper: Get user from D1
async function getUser(db: D1Database, uid: string) {
  return await db.prepare('SELECT * FROM users WHERE id = ?').bind(uid).first();
}

// Helper: Check if student is assigned to training project
async function verifyStudentAssignment(db: D1Database, uid: string, projectId: string): Promise<boolean> {
  const assignment = await db.prepare('SELECT 1 FROM student_assignments WHERE student_id = ? AND project_id = ?').bind(uid, projectId).first();
  return !!assignment;
}

// User Profile sync
app.post('/api/users', async (c) => {
  const uid = c.get('uid');
  const body = await c.req.json();
  const { email, name, role, mobile, college_name } = body;

  const db = c.env.DB;
  const existing = await getUser(db, uid);
  if (!existing) {
    await db.prepare(
      'INSERT INTO users (id, email, name, role, mobile, college_name) VALUES (?, ?, ?, ?, ?, ?)'
    )
      .bind(uid, email, name, role, mobile || null, college_name || null)
      .run();
  } else {
    // Only update name, not role (role is privileged)
    await db.prepare('UPDATE users SET name = ? WHERE id = ?').bind(name, uid).run();
  }
  return c.json({ success: true });
});

app.get('/api/users/me', async (c) => {
  const uid = c.get('uid');
  const user = await getUser(c.env.DB, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);
  return c.json(user);
});

app.get('/api/users', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);
  if (!user || user.role !== 'STUDIO_ADMIN') return c.json({ error: 'Permission denied' }, 403);
  
  const role = c.req.query('role');
  if (role) {
    const { results } = await db.prepare('SELECT * FROM users WHERE role = ?').bind(role).all();
    return c.json(results);
  }
  
  const { results } = await db.prepare('SELECT * FROM users').all();
  return c.json(results);
});

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

app.get('/api/projects/:projectId', async (c) => {
  const uid = c.get('uid');
  const projectId = c.req.param('projectId');
  const db = c.env.DB;
  const user = await getUser(db, uid);
  
  if (!user) return c.json({ error: 'User not found' }, 404);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  if (user.role === 'CLIENT' && project.client_id !== uid) return c.json({ error: 'Forbidden' }, 403);
  if (user.role === 'DRAUGHTSMAN' && project.draughtsman_id !== uid) return c.json({ error: 'Forbidden' }, 403);
  if (user.role === 'STUDENT') {
    if (project.is_training_project !== 1) return c.json({ error: 'Forbidden' }, 403);
    const isAssigned = await verifyStudentAssignment(db, uid, projectId);
    if (!isAssigned) return c.json({ error: 'Forbidden' }, 403);
  }

  return c.json(project);
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
  if (!user || (user.role !== 'DRAUGHTSMAN' && user.role !== 'STUDENT')) return c.json({ error: 'Only draughtsmen or students can submit drawings' }, 403);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  
  if (user.role === 'DRAUGHTSMAN' && project.draughtsman_id !== uid) return c.json({ error: 'Not assigned to you' }, 403);
  if (user.role === 'STUDENT') {
    if (project.is_training_project !== 1) return c.json({ error: 'Forbidden' }, 403);
    const isAssigned = await verifyStudentAssignment(db, uid, projectId);
    if (!isAssigned) return c.json({ error: 'Forbidden' }, 403);
  }
  if (project.status === 'UNDER_CLIENT_REVIEW' && project.last_action_id === actionId) return c.json({ success: true });
  if (project.status !== 'IN_PROGRESS') return c.json({ error: 'Project is not in IN_PROGRESS state' }, 400);

  const batch = [
    db.prepare(`UPDATE projects SET status = 'UNDER_CLIENT_REVIEW', last_action_id = ? WHERE id = ?`).bind(actionId, projectId),
    db.prepare(`UPDATE corrections SET status = 'RESOLVED', resolved_at = CURRENT_TIMESTAMP WHERE project_id = ? AND status = 'OPEN'`).bind(projectId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, projectId, 'DRAWING_SUBMITTED', uid, 'DRAUGHTSMAN', 'Draughtsman submitted the drawing for client review.'
    ),
    db.prepare(`INSERT INTO notifications (id, user_id, project_id, type, title, message) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      uuidv4(), project.client_id, projectId, 'DRAWING_SUBMITTED', 'Drawing Submitted', 'A drawing has been submitted for your review.'
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
  if (!user || user.role !== 'STUDIO_ADMIN') return c.json({ error: 'Only admins can approve projects' }, 403);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  if (project.status === 'WAITING_ASSIGNMENT' && project.last_action_id === actionId) return c.json({ success: true });
  if (project.status !== 'SUBMITTED') return c.json({ error: 'Project is not in SUBMITTED state' }, 400);

  const batch = [
    db.prepare(`UPDATE projects SET status = 'WAITING_ASSIGNMENT', approved_at = CURRENT_TIMESTAMP, last_action_id = ? WHERE id = ?`).bind(actionId, projectId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, projectId, 'PROJECT_APPROVED', uid, 'STUDIO_ADMIN', 'Studio Admin approved the project.'
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
  if (!user || user.role !== 'STUDIO_ADMIN') return c.json({ error: 'Only admins can reject projects' }, 403);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  if (project.status === 'CANCELLED' && project.last_action_id === actionId) return c.json({ success: true });
  if (project.status !== 'SUBMITTED') return c.json({ error: 'Project is not in SUBMITTED state' }, 400);

  const batch = [
    db.prepare(`UPDATE projects SET status = 'CANCELLED', rejection_reason = ?, cancelled_at = CURRENT_TIMESTAMP, last_action_id = ? WHERE id = ?`).bind(reason, actionId, projectId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, projectId, 'PROJECT_REJECTED', uid, 'STUDIO_ADMIN', 'Studio Admin rejected the project. Reason: ' + reason
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
    db.prepare(`UPDATE projects SET status = 'COMPLETED', last_action_id = ? WHERE id = ?`).bind(actionId, projectId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, projectId, 'PROJECT_COMPLETED', uid, 'CLIENT', 'Client approved the final drawing.'
    ),
    db.prepare(`INSERT INTO notifications (id, user_id, project_id, type, title, message) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      uuidv4(), project.draughtsman_id, projectId, 'PROJECT_COMPLETED', 'Project Approved', 'The client has approved the final drawing.'
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
    ),
    db.prepare(`INSERT INTO notifications (id, user_id, project_id, type, title, message) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      uuidv4(), project.draughtsman_id, projectId, 'CORRECTION_REQUESTED', 'Correction Requested', `Client has requested a correction (Round ${newRound}).`
    )
  ];
  await db.batch(batch);
  return c.json({ success: true, newRound });
});

app.post('/api/projects/assign', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const body = await c.req.json();
  const { projectId, actionId, draughtsmanId } = body;
  
  const user = await getUser(db, uid);
  if (!user || user.role !== 'STUDIO_ADMIN') return c.json({ error: 'Only admins can assign projects' }, 403);

  const dMan = await getUser(db, draughtsmanId);
  if (!dMan || dMan.role !== 'DRAUGHTSMAN') return c.json({ error: 'Invalid draughtsman ID' }, 400);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  if (project.status === 'WAITING_ACCEPTANCE' && project.last_action_id === actionId) return c.json({ success: true });
  if (project.status !== 'WAITING_ASSIGNMENT') return c.json({ error: 'Project is not in WAITING_ASSIGNMENT state' }, 400);

  const assignmentId = uuidv4();

  const batch = [
    db.prepare(`INSERT INTO assignments (id, project_id, draughtsman_id, status) VALUES (?, ?, ?, 'PENDING')`).bind(assignmentId, projectId, draughtsmanId),
    db.prepare(`UPDATE projects SET status = 'WAITING_ACCEPTANCE', draughtsman_id = ?, draughtsman_name = ?, current_assignment_id = ?, assigned_at = CURRENT_TIMESTAMP, last_action_id = ? WHERE id = ?`).bind(draughtsmanId, dMan.name, assignmentId, actionId, projectId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, projectId, 'DRAUGHTSMAN_ASSIGNED', uid, 'STUDIO_ADMIN', 'Studio Admin assigned draughtsman: ' + dMan.name
    ),
    db.prepare(`INSERT INTO notifications (id, user_id, project_id, type, title, message) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      uuidv4(), draughtsmanId, projectId, 'DRAUGHTSMAN_ASSIGNED', 'New Assignment', 'You have been assigned to a new project.'
    )
  ];
  await db.batch(batch);
  return c.json({ success: true });
});

app.post('/api/projects/reassign', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const body = await c.req.json();
  const { projectId, actionId, draughtsmanId } = body;
  
  const user = await getUser(db, uid);
  if (!user || user.role !== 'STUDIO_ADMIN') return c.json({ error: 'Only admins can reassign projects' }, 403);

  const dMan = await getUser(db, draughtsmanId);
  if (!dMan || dMan.role !== 'DRAUGHTSMAN') return c.json({ error: 'Invalid draughtsman ID' }, 400);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  
  if (project.last_action_id === actionId) return c.json({ success: true });
  
  // Can reassign if waiting acceptance, in progress, or waiting assignment
  if (!['WAITING_ACCEPTANCE', 'IN_PROGRESS', 'WAITING_ASSIGNMENT'].includes(project.status as string)) {
    return c.json({ error: 'Project cannot be reassigned in its current state' }, 400);
  }

  const assignmentId = uuidv4();
  const batch = [];
  
  if (project.current_assignment_id) {
    batch.push(db.prepare(`UPDATE assignments SET status = 'REPLACED', updated_at = CURRENT_TIMESTAMP WHERE id = ?`).bind(project.current_assignment_id));
  }

  batch.push(db.prepare(`INSERT INTO assignments (id, project_id, draughtsman_id, status) VALUES (?, ?, ?, 'PENDING')`).bind(assignmentId, projectId, draughtsmanId));
  batch.push(db.prepare(`UPDATE projects SET status = 'WAITING_ACCEPTANCE', draughtsman_id = ?, draughtsman_name = ?, current_assignment_id = ?, assigned_at = CURRENT_TIMESTAMP, last_action_id = ? WHERE id = ?`).bind(draughtsmanId, dMan.name, assignmentId, actionId, projectId));
  batch.push(db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
    actionId, projectId, 'DRAUGHTSMAN_REASSIGNED', uid, 'STUDIO_ADMIN', 'Studio Admin reassigned to draughtsman: ' + dMan.name
  ));

  await db.batch(batch);
  return c.json({ success: true });
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
    ),
    db.prepare(`INSERT INTO notifications (id, user_id, project_id, type, title, message) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      uuidv4(), project.client_id, projectId, 'ASSIGNMENT_ACCEPTED', 'Project In Progress', 'A draughtsman has accepted and started your project.'
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
  if (user.role !== 'DRAUGHTSMAN' && user.role !== 'STUDIO_ADMIN') return c.json({ error: 'Forbidden' }, 403);

  if (user.role === 'STUDIO_ADMIN') {
    const { results } = await db.prepare('SELECT * FROM assignments ORDER BY created_at DESC').all();
    return c.json(results);
  }

  const { results } = await db.prepare(`
    SELECT a.*, p.project_name, p.project_address, p.drawing_type 
    FROM assignments a 
    JOIN projects p ON a.project_id = p.id 
    WHERE a.draughtsman_id = ? 
    ORDER BY a.created_at DESC
  `).bind(uid).all();
  return c.json(results);
});

// ==========================================
// ADMIN DASHBOARD
// ==========================================

app.get('/api/admin/dashboard', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);
  
  if (!user || user.role !== 'STUDIO_ADMIN') return c.json({ error: 'Forbidden' }, 403);

  const batch = [
    db.prepare('SELECT COUNT(*) as c FROM projects'),
    db.prepare("SELECT COUNT(*) as c FROM projects WHERE status IN ('IN_PROGRESS', 'WAITING_ACCEPTANCE', 'UNDER_CLIENT_REVIEW')"),
    db.prepare("SELECT COUNT(*) as c FROM projects WHERE status = 'WAITING_ASSIGNMENT'"),
    db.prepare("SELECT COUNT(*) as c FROM projects WHERE status = 'UNDER_CLIENT_REVIEW'"),
    db.prepare("SELECT COUNT(*) as c FROM projects WHERE status = 'COMPLETED'"),
    db.prepare("SELECT COUNT(*) as c FROM users WHERE role = 'DRAUGHTSMAN'"),
    db.prepare("SELECT COUNT(*) as c FROM assignments WHERE status = 'PENDING'")
  ];

  const results = await db.batch(batch);

  return c.json({
    totalProjects: (results[0].results?.[0] as any)?.c || 0,
    activeProjects: (results[1].results?.[0] as any)?.c || 0,
    projectsAwaitingAssignment: (results[2].results?.[0] as any)?.c || 0,
    projectsUnderClientReview: (results[3].results?.[0] as any)?.c || 0,
    completedProjects: (results[4].results?.[0] as any)?.c || 0,
    activeDraughtsmen: (results[5].results?.[0] as any)?.c || 0,
    pendingAssignments: (results[6].results?.[0] as any)?.c || 0,
  });
});

// ==========================================
// STORAGE API (Streaming via Worker)
// ==========================================

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
  if (user.role === 'DRAUGHTSMAN' && project.draughtsman_id !== uid) return c.json({ error: 'Forbidden' }, 403);
  if (user.role === 'STUDENT') {
    if (project.is_training_project !== 1) return c.json({ error: 'Forbidden' }, 403);
    const isAssigned = await verifyStudentAssignment(db, uid, projectId);
    if (!isAssigned) return c.json({ error: 'Forbidden' }, 403);
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
  if (user.role === 'DRAUGHTSMAN' && project.draughtsman_id !== uid) return c.json({ error: 'Forbidden' }, 403);
  if (user.role === 'STUDENT') {
    if (project.is_training_project !== 1) return c.json({ error: 'Forbidden' }, 403);
    const isAssigned = await verifyStudentAssignment(db, uid, projectId);
    if (!isAssigned) return c.json({ error: 'Forbidden' }, 403);
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
  if (user.role === 'DRAUGHTSMAN' && project.draughtsman_id !== uid) return c.json({ error: 'Forbidden' }, 403);
  if (user.role === 'STUDENT') {
    if (project.is_training_project !== 1) return c.json({ error: 'Forbidden' }, 403);
    const isAssigned = await verifyStudentAssignment(db, uid, projectId);
    if (!isAssigned) return c.json({ error: 'Forbidden' }, 403);
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

  const rawFileName = c.req.header('X-File-Name');
  if (!rawFileName) return c.json({ error: 'X-File-Name header is required' }, 400);
  const fileName = decodeURIComponent(rawFileName);

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
    if (user.role !== 'CLIENT' || project.client_id !== uid) return c.json({ error: 'Forbidden' }, 403);
  } else if (category === 'draughtsman_version') {
    if (user.role === 'DRAUGHTSMAN') {
      if (project.draughtsman_id !== uid || project.status !== 'IN_PROGRESS') {
        return c.json({ error: 'Forbidden or invalid project state' }, 403);
      }
    } else if (user.role === 'STUDENT') {
      if (project.is_training_project !== 1 || project.status !== 'IN_PROGRESS') {
        return c.json({ error: 'Forbidden or invalid project state' }, 403);
      }
      const isAssigned = await verifyStudentAssignment(db, uid, projectId);
      if (!isAssigned) return c.json({ error: 'Forbidden' }, 403);
    } else {
      return c.json({ error: 'Forbidden' }, 403);
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

  const objectKey = `projects/${projectId}/${category}/${actionId}_${sanitizedName}`;

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

    const MAX_SIZE = 50 * 1024 * 1024;
    const contentLengthHeader = c.req.header('Content-Length');
    const contentLength = contentLengthHeader ? parseInt(contentLengthHeader, 10) : 0;
    
    if (contentLength > MAX_SIZE) {
      throw new Error('File exceeds 50MB limit');
    }

    await c.env.STORAGE.put(objectKey, c.req.raw.body, {
      httpMetadata: { contentType: contentType }
    });

    // Update status to COMPLETED and save actual byte count
    await db.prepare(`UPDATE files SET status = 'COMPLETED', size = ? WHERE id = ?`).bind(contentLength, actionId).run();
    
    if (category === 'draughtsman_version') {
      const latest = await db.prepare('SELECT MAX(version_number) as v FROM drawing_versions WHERE project_id = ?').bind(projectId).first();
      const vNum = ((latest?.v as number) || 0) + 1;
      const corr = await db.prepare('SELECT id FROM corrections WHERE project_id = ? AND status = "OPEN"').bind(projectId).first();
      
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
    return c.json({ error: err.message || 'Upload failed' }, 500);
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
  if (user.role === 'DRAUGHTSMAN' && project.draughtsman_id !== uid) return c.json({ error: 'Forbidden' }, 403);

  const object = await c.env.STORAGE.get(fileMeta.object_key as string);
  if (!object) return c.json({ error: 'File object missing in R2' }, 404);

  const headers = new Headers();
  object.writeHttpMetadata(headers as any);
  headers.set('etag', object.httpEtag);
  headers.set('Content-Disposition', `attachment; filename="${fileMeta.sanitized_name}"`);

  return new Response(object.body, { headers });
});

app.delete('/api/projects/:projectId/files/:fileId', async (c) => {
  const uid = c.get('uid');
  const projectId = c.req.param('projectId');
  const fileId = c.req.param('fileId');

  const db = c.env.DB;
  const user = await getUser(db, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  // Authorization checks
  if (user.role === 'CLIENT' && project.client_id !== uid) return c.json({ error: 'Forbidden' }, 403);
  if (user.role === 'DRAUGHTSMAN' && project.draughtsman_id !== uid) return c.json({ error: 'Forbidden' }, 403);

  const fileMeta = await db.prepare('SELECT * FROM files WHERE id = ? AND project_id = ?').bind(fileId, projectId).first();
  if (!fileMeta) return c.json({ error: 'File not found or does not belong to project' }, 404);

  try {
    // Delete from R2
    if (fileMeta.object_key) {
      await c.env.STORAGE.delete(fileMeta.object_key as string);
    }
    
    // Delete from D1
    await db.prepare('DELETE FROM files WHERE id = ?').bind(fileId).run();

    // Log activity
    await db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      uuidv4(), projectId, 'FILE_DELETED', uid, user.role, `Deleted file: ${fileMeta.sanitized_name}`
    ).run();

    return c.json({ success: true });
  } catch (err: any) {
    console.error('Delete failed:', err);
    return c.json({ error: 'Delete failed' }, 500);
  }
});

app.get('/api/projects/:projectId/activity', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const projectId = c.req.param('projectId');

  const user = await getUser(db, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  if (user.role === 'CLIENT' && project.client_id !== uid) return c.json({ error: 'Forbidden' }, 403);
  if (user.role === 'DRAUGHTSMAN' && project.draughtsman_id !== uid) return c.json({ error: 'Forbidden' }, 403);

  const logs = await db.prepare('SELECT * FROM activity_logs WHERE project_id = ? ORDER BY timestamp DESC').bind(projectId).all();
  return c.json(logs.results);
});

app.get('/api/notifications', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const notifs = await db.prepare('SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC').bind(uid).all();
  return c.json(notifs.results);
});

app.post('/api/notifications/:id/read', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const id = c.req.param('id');
  const notif = await db.prepare('SELECT * FROM notifications WHERE id = ?').bind(id).first();
  if (!notif) return c.json({ error: 'Notification not found' }, 404);
  if (notif.user_id !== uid) return c.json({ error: 'Permission denied' }, 403);
  await db.prepare('UPDATE notifications SET is_read = 1 WHERE id = ?').bind(id).run();
  return c.json({ success: true });
});

// ==========================================
// FINANCIALS API
// ==========================================

app.get('/api/projects/:projectId/financials', async (c) => {
  const uid = c.get('uid');
  const projectId = c.req.param('projectId');
  const db = c.env.DB;
  
  const user = await getUser(db, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  if (user.role === 'CLIENT' && project.client_id !== uid) return c.json({ error: 'Forbidden' }, 403);
  if (user.role !== 'CLIENT' && user.role !== 'STUDIO_ADMIN') return c.json({ error: 'Forbidden' }, 403);

  const { results: invoices } = await db.prepare('SELECT * FROM invoices WHERE project_id = ? ORDER BY created_at DESC').bind(projectId).all();
  
  const { results: payments } = await db.prepare(`
    SELECT p.* FROM payments p 
    JOIN invoices i ON p.invoice_id = i.id 
    WHERE i.project_id = ? ORDER BY p.processed_at DESC
  `).bind(projectId).all();

  const now = new Date().getTime();
  
  let paidAmount = 0;
  payments.forEach((p: any) => paidAmount += (p.amount as number));
  
  const mappedInvoices = invoices.map((inv: any) => {
    let currentStatus = inv.status;
    const dueTime = new Date(inv.due_date).getTime();
    if ((currentStatus === 'ISSUED' || currentStatus === 'PARTIALLY_PAID') && now > dueTime) {
      currentStatus = 'OVERDUE';
    }
    return { ...inv, status: currentStatus };
  });

  return c.json({
    total_value: project.total_value,
    paid_amount: paidAmount,
    outstanding_balance: project.total_value !== null ? (project.total_value as number) - paidAmount : null,
    invoices: mappedInvoices,
    payments: payments
  });
});

app.patch('/api/projects/:projectId/financials/total_value', async (c) => {
  const uid = c.get('uid');
  const projectId = c.req.param('projectId');
  const db = c.env.DB;
  
  const user = await getUser(db, uid);
  if (!user || user.role !== 'STUDIO_ADMIN') return c.json({ error: 'Forbidden' }, 403);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  const body = await c.req.json();
  const newTotalValue = body.total_value;

  const sumInvRes = await db.prepare('SELECT SUM(amount) as sum FROM invoices WHERE project_id = ?').bind(projectId).first();
  const sumInvoiced = (sumInvRes?.sum as number) || 0;
  
  const sumPayRes = await db.prepare(`
    SELECT SUM(p.amount) as sum FROM payments p JOIN invoices i ON p.invoice_id = i.id WHERE i.project_id = ?
  `).bind(projectId).first();
  const sumPaid = (sumPayRes?.sum as number) || 0;

  if (newTotalValue === null) {
    if (sumInvoiced > 0 || sumPaid > 0) {
      return c.json({ error: 'Cannot set total_value to null because invoices or payments exist.' }, 400);
    }
  } else {
    if (typeof newTotalValue !== 'number' || newTotalValue < 0) {
      return c.json({ error: 'Invalid total_value' }, 400);
    }
    if (newTotalValue < sumInvoiced) {
      return c.json({ error: 'New total_value cannot be less than total invoiced amount' }, 400);
    }
    if (newTotalValue < sumPaid) {
      return c.json({ error: 'New total_value cannot be less than total paid amount' }, 400);
    }
  }

  await db.prepare('UPDATE projects SET total_value = ? WHERE id = ?').bind(newTotalValue, projectId).run();
  
  await db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
    uuidv4(), projectId, 'TOTAL_VALUE_UPDATED', uid, 'STUDIO_ADMIN', `Updated total value to ${newTotalValue}`
  ).run();

  return c.json({ success: true, total_value: newTotalValue });
});

app.post('/api/projects/:projectId/invoices', async (c) => {
  const uid = c.get('uid');
  const projectId = c.req.param('projectId');
  const db = c.env.DB;
  
  const user = await getUser(db, uid);
  if (!user || user.role !== 'STUDIO_ADMIN') return c.json({ error: 'Forbidden' }, 403);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  if (project.total_value === null) {
    return c.json({ error: 'Project total_value is not set' }, 400);
  }

  const body = await c.req.json();
  const amount = body.amount;
  const due_date = body.due_date;

  if (typeof amount !== 'number' || amount <= 0) {
    return c.json({ error: 'Invalid invoice amount' }, 400);
  }
  if (!due_date) return c.json({ error: 'Missing due_date' }, 400);

  const sumInvRes = await db.prepare('SELECT SUM(amount) as sum FROM invoices WHERE project_id = ?').bind(projectId).first();
  const sumInvoiced = (sumInvRes?.sum as number) || 0;

  if (amount + sumInvoiced > (project.total_value as number)) {
    return c.json({ error: 'Invoice amount exceeds remaining project total_value' }, 400);
  }

  const invoiceId = uuidv4();
  const today = new Date().toISOString().split('T')[0].replace(/-/g, '');
  let invoiceNumber = `INV-${today}-${crypto.randomUUID().split('-')[0]}`;

  let retryCount = 0;
  while(true) {
    try {
      await db.prepare(`
        INSERT INTO invoices (id, project_id, invoice_number, amount, currency, status, due_date, created_at)
        VALUES (?, ?, ?, ?, 'INR', 'ISSUED', ?, CURRENT_TIMESTAMP)
      `).bind(invoiceId, projectId, invoiceNumber, amount, new Date(due_date).toISOString()).run();
      break;
    } catch (e: any) {
      if (e.message && e.message.includes('UNIQUE constraint failed') && retryCount < 5) {
        retryCount++;
        invoiceNumber = `INV-${today}-${crypto.randomUUID().split('-')[0]}`;
      } else {
        throw e;
      }
    }
  }

  await db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
    uuidv4(), projectId, 'INVOICE_CREATED', uid, 'STUDIO_ADMIN', `Created invoice ${invoiceNumber} for ${amount} INR`
  ).run();

  return c.json({ success: true, id: invoiceId, invoice_number: invoiceNumber });
});

app.post('/api/invoices/:invoiceId/payments', async (c) => {
  const uid = c.get('uid');
  const invoiceId = c.req.param('invoiceId');
  const db = c.env.DB;
  
  const user = await getUser(db, uid);
  if (!user || user.role !== 'STUDIO_ADMIN') return c.json({ error: 'Forbidden' }, 403);

  const invoice = await db.prepare('SELECT * FROM invoices WHERE id = ?').bind(invoiceId).first();
  if (!invoice) return c.json({ error: 'Invoice not found' }, 404);

  if (invoice.status !== 'ISSUED' && invoice.status !== 'PARTIALLY_PAID') {
    return c.json({ error: 'Invoice is not payable' }, 400);
  }

  const body = await c.req.json();
  const amount = body.amount;
  const payment_method = body.payment_method || 'MANUAL';

  if (typeof amount !== 'number' || amount <= 0) {
    return c.json({ error: 'Invalid payment amount' }, 400);
  }

  const sumPayRes = await db.prepare('SELECT SUM(amount) as sum FROM payments WHERE invoice_id = ?').bind(invoiceId).first();
  const sumPaid = (sumPayRes?.sum as number) || 0;

  const remainingBalance = (invoice.amount as number) - sumPaid;

  if (amount > remainingBalance) {
    return c.json({ error: 'Payment amount exceeds invoice remaining balance' }, 400);
  }

  const newSumPaid = sumPaid + amount;
  const newStatus = (newSumPaid >= (invoice.amount as number)) ? 'PAID' : 'PARTIALLY_PAID';

  const paymentId = uuidv4();

  const batch = [
    db.prepare(`
      INSERT INTO payments (id, invoice_id, amount, payment_method, processed_at, recorded_by)
      VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP, ?)
    `).bind(paymentId, invoiceId, amount, payment_method, uid),
    db.prepare('UPDATE invoices SET status = ? WHERE id = ?').bind(newStatus, invoiceId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      uuidv4(), invoice.project_id, 'PAYMENT_RECORDED', uid, 'STUDIO_ADMIN', `Recorded payment of ${amount} INR against ${invoice.invoice_number}`
    )
  ];

  await db.batch(batch);

  return c.json({ success: true, payment_id: paymentId, new_status: newStatus });
});

// ==========================================
// STUDENT TRAINING ENDPOINTS
// ==========================================

// GET /api/student/training/modules
app.get('/api/student/training/modules', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || user.role !== 'STUDENT') {
    return c.json({ error: 'Unauthorized: Only students can access training modules', code: 'UNAUTHORIZED' }, 403);
  }

  const { results } = await db.prepare('SELECT * FROM training_modules ORDER BY created_at ASC').all();
  return c.json(results);
});

// GET /api/student/training/modules/:moduleId
app.get('/api/student/training/modules/:moduleId', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || user.role !== 'STUDENT') {
    return c.json({ error: 'Unauthorized: Only students can access training modules', code: 'UNAUTHORIZED' }, 403);
  }

  const moduleId = c.req.param('moduleId');
  const module = await db.prepare('SELECT * FROM training_modules WHERE id = ?').bind(moduleId).first();

  if (!module) {
    return c.json({ error: 'Training module not found', code: 'NOT_FOUND' }, 404);
  }

  return c.json(module);
});

// GET /api/student/training/progress
app.get('/api/student/training/progress', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || user.role !== 'STUDENT') {
    return c.json({ error: 'Unauthorized: Only students can access training progress', code: 'UNAUTHORIZED' }, 403);
  }

  // Aggregate progress per category:
  // For each category, compute the fraction of modules the student has completed.
  // A module counts as "completed" if student_progress.status = 'Completed'.
  const { results } = await db.prepare(`
    SELECT
      tm.category,
      CAST(COUNT(CASE WHEN sp.status = 'Completed' THEN 1 END) AS REAL) / CAST(COUNT(tm.id) AS REAL) AS overall_progress
    FROM training_modules tm
    LEFT JOIN student_progress sp ON sp.module_id = tm.id AND sp.student_id = ?
    GROUP BY tm.category
    ORDER BY tm.category ASC
  `).bind(uid).all();

  return c.json(results);
});

// POST /api/student/training/progress
app.post('/api/student/training/progress', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || user.role !== 'STUDENT') {
    return c.json({ error: 'Unauthorized: Only students can update training progress', code: 'UNAUTHORIZED' }, 403);
  }

  const body = await c.req.json();
  const { module_id, status, score } = body;

  if (!module_id || !status) {
    return c.json({ error: 'Bad Request: Missing module_id or status', code: 'BAD_REQUEST' }, 400);
  }

  const id = uuidv4();
  
  // Upsert progress
  await db.prepare(`
    INSERT INTO student_progress (id, student_id, module_id, status, score, updated_at)
    VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
    ON CONFLICT(student_id, module_id) DO UPDATE SET
      status = excluded.status,
      score = excluded.score,
      updated_at = CURRENT_TIMESTAMP
  `).bind(id, uid, module_id, status, score || null).run();

  return c.json({ success: true });
});

// GET /api/student/assignments
app.get('/api/student/assignments', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || user.role !== 'STUDENT') {
    return c.json({ error: 'Unauthorized: Only students can access training assignments', code: 'UNAUTHORIZED' }, 403);
  }

  // Return project-shaped rows so Flutter's Project.fromMap works correctly.
  // sa.id becomes current_assignment_id; p.id becomes id (the project ID).
  const { results } = await db.prepare(`
    SELECT
      p.id,
      p.project_name,
      p.project_address,
      p.drawing_name,
      p.drawing_type,
      p.project_area,
      p.estimated_amount,
      p.client_id,
      p.draughtsman_id,
      sa.id AS current_assignment_id,
      p.status,
      p.correction_round,
      p.created_at,
      p.submitted_at,
      p.completed_at,
      p.last_action_id,
      p.training_module_id,
      p.is_training_project
    FROM student_assignments sa
    JOIN projects p ON sa.project_id = p.id
    WHERE sa.student_id = ? AND p.is_training_project = 1
    ORDER BY sa.created_at DESC
  `).bind(uid).all();

  return c.json(results);
});


export default app;
