import { Hono } from 'hono';
import { verifyFirebaseToken } from './auth';

type Bindings = {
  DB: D1Database;
  STORAGE: R2Bucket;
};

type Variables = {
  uid: string;
};

const app = new Hono<{ Bindings: Bindings; Variables: Variables }>();

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

// User Profile sync
app.post('/api/users', async (c) => {
  const uid = c.get('uid');
  const body = await c.req.json();
  const { email, name, role } = body;

  const db = c.env.DB;
  const existing = await getUser(db, uid);
  if (!existing) {
    await db.prepare('INSERT INTO users (id, email, name, role) VALUES (?, ?, ?, ?)')
      .bind(uid, email, name, role || 'CLIENT')
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
  if (!['WAITING_ACCEPTANCE', 'IN_PROGRESS', 'WAITING_ASSIGNMENT'].includes(project.status)) {
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

  const { results } = await db.prepare('SELECT * FROM files WHERE project_id = ? ORDER BY created_at DESC').bind(projectId).all();
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
    if (user.role !== 'CLIENT' || project.client_id !== uid) return c.json({ error: 'Forbidden' }, 403);
  } else if (category === 'draughtsman_version') {
    if (user.role !== 'DRAUGHTSMAN' || project.draughtsman_id !== uid || project.status !== 'IN_PROGRESS') {
      return c.json({ error: 'Forbidden or invalid project state' }, 403);
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
    let byteCount = 0;

    // True server-side 50MB limit using TransformStream
    const transform = new TransformStream({
      transform(chunk, controller) {
        byteCount += chunk.length;
        if (byteCount > MAX_SIZE) {
          controller.error(new Error('File exceeds 50MB limit'));
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

  const object = await c.env.STORAGE.get(fileMeta.object_key);
  if (!object) return c.json({ error: 'File object missing in R2' }, 404);

  const headers = new Headers();
  object.writeHttpMetadata(headers as any);
  headers.set('etag', object.httpEtag);
  headers.set('Content-Disposition', `attachment; filename="${fileMeta.sanitized_name}"`);

  return new Response(object.body, { headers });
});

export default app;
