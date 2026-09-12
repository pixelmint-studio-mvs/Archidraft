import { Hono } from 'hono';
import { AppEnv } from '../types';
import { authMiddleware } from '../middleware/auth';

const projects = new Hono<AppEnv>();

// All project routes require authentication
projects.use('*', authMiddleware);

/**
 * Creates a new project draft
 */
projects.post('/', async (c) => {
  const user = c.get('user');
  if (user.role !== 'CLIENT') {
    return c.json({ error: 'Permission denied: Only clients can create drafts' }, 403);
  }

  const body = await c.req.json();
  const db = c.env.DB as any;

  const projectId = crypto.randomUUID();
  
  await db.prepare(
    'INSERT INTO projects (id, clientId, status, projectName, projectAddress, drawingName, drawingType, projectArea, estimatedAmount) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
  ).bind(
    projectId, 
    user.uid, 
    'DRAFT', 
    body.projectName || '', 
    body.projectAddress || '', 
    body.drawingName || '', 
    body.drawingType || '', 
    body.projectArea || null, 
    body.estimatedAmount || null
  ).run();

  return c.json({ projectId });
});

/**
 * Get all projects (Clients get theirs, Admins get all or by status)
 */
projects.get('/', async (c) => {
  const user = c.get('user');
  const db = c.env.DB as any;
  const status = c.req.query('status');
  
  if (user.role === 'CLIENT') {
    const { results } = await db.prepare('SELECT * FROM projects WHERE clientId = ? ORDER BY createdAt DESC').bind(user.uid).all();
    return c.json(results);
  } else {
    // ADMIN or DRAUGHTSMAN
    let query = 'SELECT * FROM projects ORDER BY createdAt DESC';
    let params: any[] = [];
    if (status) {
      query = 'SELECT * FROM projects WHERE status = ? ORDER BY createdAt DESC';
      params.push(status);
    }
    const { results } = await db.prepare(query).bind(...params).all();
    return c.json(results);
  }
});

/**
 * Get single project
 */
projects.get('/:id', async (c) => {
  const user = c.get('user');
  const projectId = c.req.param('id');
  const db = c.env.DB as any;

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  
  if (user.role === 'CLIENT' && project.clientId !== user.uid) {
    return c.json({ error: 'Permission denied' }, 403);
  }
  
  return c.json(project);
});

/**
 * Update an existing draft
 */
projects.patch('/:id', async (c) => {
  const user = c.get('user');
  const projectId = c.req.param('id');
  const body = await c.req.json();
  const db = c.env.DB as any;

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  if (project.clientId !== user.uid || project.status !== 'DRAFT') {
    return c.json({ error: 'Permission denied' }, 403);
  }

  // Dynamically build the update query for provided fields
  const updates: string[] = [];
  const params: any[] = [];
  const allowedFields = ['projectName', 'projectAddress', 'drawingName', 'drawingType', 'projectArea', 'estimatedAmount'];
  
  for (const field of allowedFields) {
    if (body[field] !== undefined) {
      updates.push(`${field} = ?`);
      params.push(body[field]);
    }
  }

  if (updates.length > 0) {
    params.push(projectId);
    await db.prepare(`UPDATE projects SET ${updates.join(', ')} WHERE id = ?`).bind(...params).run();
  }
  
  return c.json({ success: true });
});

/**
 * Post project actions (Submit, Cancel, Approve, Reject, Assign)
 */
projects.post('/:id/actions', async (c) => {
  const user = c.get('user');
  const projectId = c.req.param('id');
  const body = await c.req.json();
  const db = c.env.DB as any;
  
  const { action, actionId, reason, draughtsmanId } = body;
  
  if (!actionId || !action) return c.json({ error: 'Missing action or actionId' }, 400);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  // Idempotency check
  if (project.lastActionId === actionId) return c.json({ success: true, message: 'Idempotent' });

  const statements: any[] = [];
  let newStatus = project.status;
  
  if (action === 'submit') {
    if (user.role !== 'CLIENT' || project.clientId !== user.uid) return c.json({ error: 'Forbidden' }, 403);
    if (project.status !== 'DRAFT') return c.json({ error: 'Invalid status' }, 400);
    newStatus = 'SUBMITTED';
    statements.push(db.prepare('UPDATE projects SET status = ?, lastActionId = ?, submittedAt = CURRENT_TIMESTAMP WHERE id = ?').bind(newStatus, actionId, projectId));
  } else if (action === 'cancel') {
    if (user.role !== 'CLIENT' || project.clientId !== user.uid) return c.json({ error: 'Forbidden' }, 403);
    if (project.status !== 'DRAFT' && project.status !== 'SUBMITTED') return c.json({ error: 'Invalid status' }, 400);
    newStatus = 'CANCELLED';
    statements.push(db.prepare('UPDATE projects SET status = ?, lastActionId = ?, cancelledAt = CURRENT_TIMESTAMP WHERE id = ?').bind(newStatus, actionId, projectId));
  } else if (action === 'approve') {
    if (user.role !== 'ADMIN') return c.json({ error: 'Forbidden' }, 403);
    if (project.status !== 'SUBMITTED') return c.json({ error: 'Invalid status' }, 400);
    newStatus = 'WAITING_ASSIGNMENT';
    statements.push(db.prepare('UPDATE projects SET status = ?, lastActionId = ?, approvedAt = CURRENT_TIMESTAMP, approvedBy = ? WHERE id = ?').bind(newStatus, actionId, user.uid, projectId));
  } else if (action === 'reject') {
    if (user.role !== 'ADMIN') return c.json({ error: 'Forbidden' }, 403);
    if (project.status !== 'SUBMITTED') return c.json({ error: 'Invalid status' }, 400);
    newStatus = 'DRAFT'; // Back to draft for correction
    statements.push(db.prepare('UPDATE projects SET status = ?, lastActionId = ? WHERE id = ?').bind(newStatus, actionId, projectId));
    // TODO: store rejection reason (schema doesn't have rejectionReason, we could add it)
  } else if (action === 'assign') {
    if (user.role !== 'ADMIN') return c.json({ error: 'Forbidden' }, 403);
    if (project.status !== 'WAITING_ASSIGNMENT') return c.json({ error: 'Invalid status' }, 400);
    if (!draughtsmanId) return c.json({ error: 'Missing draughtsmanId' }, 400);
    
    newStatus = 'WAITING_ACCEPTANCE';
    statements.push(db.prepare('UPDATE projects SET status = ?, lastActionId = ? WHERE id = ?').bind(newStatus, actionId, projectId));
    
    const assignmentId = crypto.randomUUID();
    statements.push(db.prepare(
      'INSERT INTO assignments (id, projectId, draughtsmanId, status, assignedBy) VALUES (?, ?, ?, ?, ?)'
    ).bind(assignmentId, projectId, draughtsmanId, 'PENDING', user.uid));
  } else {
    return c.json({ error: 'Unknown action' }, 400);
  }

  // Create action log
  statements.push(db.prepare(
    'INSERT INTO activity_logs (id, projectId, actionType, actorId, actorRole, details) VALUES (?, ?, ?, ?, ?, ?)'
  ).bind(actionId, projectId, `PROJECT_${action.toUpperCase()}`, user.uid, user.role, reason ? JSON.stringify({ reason }) : null));

  await db.batch(statements);

  return c.json({ success: true, newStatus });
});

export default projects;
