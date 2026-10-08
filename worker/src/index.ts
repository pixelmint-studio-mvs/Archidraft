import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { verifyFirebaseToken } from './auth';
import { PDFDocument, StandardFonts, rgb } from 'pdf-lib';
import * as QRCode from 'qrcode';
import { getStudentAchievements } from './achievements';

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
  // Public routes exception
  if (c.req.path.startsWith('/api/public/')) {
    return await next();
  }

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

// GET /api/public/credentials/verify/:verificationToken
app.get('/api/public/credentials/verify/:verificationToken', async (c) => {
  const token = c.req.param('verificationToken');
  const db = c.env.DB;

  const credential = await db.prepare(`
    SELECT c.type, c.title, c.issued_at, u.name as student_name
    FROM student_credentials c
    JOIN users u ON c.student_id = u.id
    WHERE c.verification_token = ?
  `).bind(token).first();

  if (!credential) {
    return c.json({ valid: false, error: 'Credential not found or invalid' }, 404);
  }

  return c.json({
    valid: true,
    credential: {
      type: credential.type,
      title: credential.title,
      issuedAt: credential.issued_at,
      recipientName: credential.student_name
    }
  });
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

// Helpers: Build batched queries for state transitions
function buildApproveFinalBatch(db: D1Database, project: any, uid: string, actionId: string, actorRole: string = 'CLIENT', studentId: string | null = null): any[] {
  const batch = [
    db.prepare(`UPDATE projects SET status = 'COMPLETED', last_action_id = ? WHERE id = ?`).bind(actionId, project.id),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, project.id, 'PROJECT_COMPLETED', uid, actorRole, `${actorRole === 'STUDIO_ADMIN' ? 'Admin' : 'Client'} approved the final drawing.`
    ),
    db.prepare(`INSERT INTO notifications (id, user_id, project_id, type, title, message) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      uuidv4(), project.draughtsman_id, project.id, 'PROJECT_COMPLETED', 'Project Approved', 'The drawing has been approved.'
    )
  ];

  if (project.is_training_project === 1 && studentId) {
    batch.push(
      db.prepare(`
        INSERT INTO student_credentials (id, student_id, type, reference_id, title, description, issued_at)
        VALUES (?, ?, 'PRACTICAL_PROJECT_COMPLETION', ?, ?, ?, CURRENT_TIMESTAMP)
        ON CONFLICT(student_id, type, reference_id) DO NOTHING
      `).bind(
        uuidv4(),
        studentId,
        project.id,
        'Practical Project Completion',
        `Completed the practical project: ${project.project_name || 'Untitled Project'}`
      )
    );
  }

  return batch;
}

function buildRequestCorrectionBatch(db: D1Database, project: any, uid: string, actionId: string, correctionId: string, targetVersionId: string, newRound: number, description: string, actorRole: string = 'CLIENT'): any[] {
  return [
    db.prepare(`
      INSERT INTO corrections (id, project_id, requested_by, target_version_id, round_number, description, status)
      VALUES (?, ?, ?, ?, ?, ?, 'OPEN')
    `).bind(correctionId, project.id, uid, targetVersionId, newRound, description),
    db.prepare(`UPDATE projects SET status = 'IN_PROGRESS', correction_round = ?, last_action_id = ? WHERE id = ?`).bind(newRound, actionId, project.id),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, project.id, 'CORRECTION_REQUESTED', uid, actorRole, `${actorRole === 'STUDIO_ADMIN' ? 'Admin' : 'Client'} requested correction (Round ${newRound}).`
    ),
    db.prepare(`INSERT INTO notifications (id, user_id, project_id, type, title, message) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      uuidv4(), project.draughtsman_id, project.id, 'CORRECTION_REQUESTED', 'Correction Requested', `A correction (Round ${newRound}) has been requested.`
    )
  ];
}

// User Profile sync
app.post('/api/users', async (c) => {
  const uid = c.get('uid');
  const body = await c.req.json();
  const { email, name, role, mobile, college_name, qualification, date_of_birth, address, company_name } = body;

  const db = c.env.DB;
  const existing = await getUser(db, uid);
  if (!existing) {
    await db.prepare(
      'INSERT INTO users (id, email, name, role, mobile, college_name, qualification, date_of_birth, address, company_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
    )
      .bind(uid, email, name, role, mobile || null, college_name || null, qualification || null, date_of_birth || null, address || null, company_name || null)
      .run();
  } else {
    // Only update editable fields, not role (role is privileged)
    await db.prepare(
      'UPDATE users SET name = ?, mobile = ?, college_name = ?, qualification = ?, date_of_birth = ?, address = ?, company_name = ? WHERE id = ?'
    )
      .bind(name, mobile || null, college_name || null, qualification || null, date_of_birth || null, address || null, company_name || null, uid)
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

app.get('/api/student/metrics', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);
  
  if (!user || user.role !== 'STUDENT') {
    return c.json({ error: 'Only students can access their metrics' }, 403);
  }

  // 1. Learning Progress
  const learningQuery = `
    SELECT 
      m.category, 
      COUNT(l.id) as totalLessons, 
      COUNT(p.id) as completedLessons 
    FROM training_lessons l 
    JOIN training_modules m ON l.module_id = m.id 
    LEFT JOIN student_lesson_progress p ON l.id = p.lesson_id AND p.student_id = ? AND p.status = 'COMPLETED'
    GROUP BY m.category
  `;
  const { results: learningResults } = await db.prepare(learningQuery).bind(uid).all();

  const learning = learningResults.map((r: any) => ({
    category: r.category,
    completedLessons: r.completedLessons,
    totalLessons: r.totalLessons,
    percentage: r.totalLessons > 0 ? Math.round((r.completedLessons / r.totalLessons) * 100) : 0,
  }));

  // 2. Activity Metrics (Completed projects & corrections)
  const activityQuery = `
    SELECT 
      p.drawing_type as category,
      COUNT(p.id) as completedProjects,
      SUM(p.correction_round) as correctionRounds
    FROM projects p
    JOIN student_assignments sa ON p.id = sa.project_id
    WHERE sa.student_id = ? AND p.status = 'COMPLETED'
    GROUP BY p.drawing_type
  `;
  const { results: activityResults } = await db.prepare(activityQuery).bind(uid).all();
  
  let totalCompletedProjects = 0;
  let totalCorrectionRounds = 0;
  for (const r of activityResults) {
    totalCompletedProjects += (r.completedProjects as number);
    totalCorrectionRounds += (r.correctionRounds as number);
  }

  // 3. Practical Proficiency (Evaluations)
  const evalQuery = `
    SELECT e.criteria_json, p.drawing_type 
    FROM evaluations e
    JOIN projects p ON e.project_id = p.id
    JOIN student_assignments sa ON p.id = sa.project_id
    WHERE sa.student_id = ? AND e.overall_result = 'APPROVED'
  `;
  const { results: evalResults } = await db.prepare(evalQuery).bind(uid).all();

  const skillAggregates: Record<string, { sum: number, count: number }> = {};
  
  for (const row of evalResults) {
    if (row.criteria_json) {
      try {
        const criteria = typeof row.criteria_json === 'string' ? JSON.parse(row.criteria_json) : row.criteria_json;
        for (const [key, value] of Object.entries(criteria)) {
          const numValue = Number(value);
          if (!isNaN(numValue)) {
            if (!skillAggregates[key]) {
              skillAggregates[key] = { sum: 0, count: 0 };
            }
            skillAggregates[key].sum += numValue;
            skillAggregates[key].count += 1;
          }
        }
      } catch (e) {
        // ignore invalid json
      }
    }
  }

  const practical = Object.keys(skillAggregates).map(key => {
    const agg = skillAggregates[key];
    const avgScore = agg.sum / agg.count;
    return {
      name: key,
      score: Number(avgScore.toFixed(1)),
      maxScore: 5,
      percentage: Math.round((avgScore / 5) * 100),
      evaluationCount: agg.count,
    };
  });

  // 4. Corrections Summary (for Revision Discipline)
  const correctionsQuery = `
    SELECT 
      COUNT(c.id) as totalCorrections,
      SUM(CASE WHEN c.status = 'RESOLVED' THEN 1 ELSE 0 END) as resolvedCorrections
    FROM corrections c
    JOIN projects p ON c.project_id = p.id
    JOIN student_assignments sa ON p.id = sa.project_id
    WHERE sa.student_id = ? AND p.is_training_project = 1
  `;
  const correctionsRow = await db.prepare(correctionsQuery).bind(uid).first() as { totalCorrections?: number; resolvedCorrections?: number } | null;

  // 5. Approved Deliverables Count
  const deliverablesQuery = `
    SELECT COUNT(DISTINCT e.drawing_version_id) as approvedDeliverables
    FROM evaluations e
    JOIN projects p ON e.project_id = p.id
    JOIN student_assignments sa ON p.id = sa.project_id
    WHERE sa.student_id = ? AND e.overall_result = 'APPROVED' AND p.is_training_project = 1
  `;
  const deliverablesRow = await db.prepare(deliverablesQuery).bind(uid).first() as { approvedDeliverables?: number } | null;

  // Derive Pillar 1: Curriculum Mastery
  let totalCurriculumLessons = 0;
  let completedCurriculumLessons = 0;
  for (const item of learning) {
    totalCurriculumLessons += item.totalLessons;
    completedCurriculumLessons += item.completedLessons;
  }
  const curriculumPercentage = totalCurriculumLessons > 0 
    ? Math.round((completedCurriculumLessons / totalCurriculumLessons) * 100) 
    : 0;

  // Derive Pillar 2: Practical Execution
  const approvedDeliverablesCount = deliverablesRow?.approvedDeliverables ?? totalCompletedProjects;

  // Derive Pillar 3: Technical Precision
  let accuracyScore: number | null = null;
  let standardsScore: number | null = null;
  if (skillAggregates['Accuracy'] && skillAggregates['Accuracy'].count > 0) {
    accuracyScore = Number((skillAggregates['Accuracy'].sum / skillAggregates['Accuracy'].count).toFixed(1));
  }
  if (skillAggregates['Technical Standards'] && skillAggregates['Technical Standards'].count > 0) {
    standardsScore = Number((skillAggregates['Technical Standards'].sum / skillAggregates['Technical Standards'].count).toFixed(1));
  }

  let totalScoreSum = 0;
  let totalScoreCount = 0;
  for (const agg of Object.values(skillAggregates)) {
    totalScoreSum += agg.sum;
    totalScoreCount += agg.count;
  }
  const averagePrecisionScore = totalScoreCount > 0 
    ? Number((totalScoreSum / totalScoreCount).toFixed(1)) 
    : null;

  // Derive Pillar 4: Revision Discipline
  const totalCorrectionsIssued = Number(correctionsRow?.totalCorrections ?? 0);
  const totalCorrectionsResolved = Number(correctionsRow?.resolvedCorrections ?? 0);
  const resolutionRate = totalCorrectionsIssued > 0
    ? Math.round((totalCorrectionsResolved / totalCorrectionsIssued) * 100)
    : (totalCompletedProjects > 0 ? 100 : 0);

  const readiness = {
    curriculum: {
      completedLessons: completedCurriculumLessons,
      totalLessons: totalCurriculumLessons,
      percentage: curriculumPercentage,
    },
    practical: {
      completedProjects: totalCompletedProjects,
      approvedDeliverables: approvedDeliverablesCount,
    },
    precision: {
      averageScore: averagePrecisionScore,
      maxScore: 5.0,
      accuracyScore,
      standardsScore,
      evaluationCount: evalResults.length,
    },
    revision: {
      correctionsIssued: totalCorrectionsIssued,
      correctionsResolved: totalCorrectionsResolved,
      resolutionRate,
      totalRounds: totalCorrectionRounds,
    },
  };

  // Discipline Competency Breakdown
  const standardDisciplines = [
    'Architectural',
    'Interior',
    'Structural',
    'Municipal Approval',
  ];

  function normalizeCategory(cat: string): string {
    const lower = (cat || '').toLowerCase().trim();
    if (lower === 'architectural' || lower.includes('arch')) return 'Architectural';
    if (lower === 'interior' || lower.includes('int')) return 'Interior';
    if (lower === 'structural' || lower.includes('struct')) return 'Structural';
    if (lower === 'approval' || lower.includes('approv') || lower.includes('municipal')) return 'Municipal Approval';
    return cat;
  }

  const disciplines = standardDisciplines.map(discName => {
    let compLessons = 0;
    let totLessons = 0;
    for (const lr of learningResults as any[]) {
      if (normalizeCategory(lr.category) === discName) {
        compLessons += Number(lr.completedLessons) || 0;
        totLessons += Number(lr.totalLessons) || 0;
      }
    }

    let compProjects = 0;
    for (const ar of activityResults as any[]) {
      if (normalizeCategory(ar.category) === discName) {
        compProjects += Number(ar.completedProjects) || 0;
      }
    }

    let discScoreSum = 0;
    let discScoreCount = 0;
    for (const row of evalResults as any[]) {
      if (normalizeCategory(row.drawing_type) === discName && row.criteria_json) {
        try {
          const crit = typeof row.criteria_json === 'string' ? JSON.parse(row.criteria_json) : row.criteria_json;
          for (const val of Object.values(crit)) {
            const num = Number(val);
            if (!isNaN(num)) {
              discScoreSum += num;
              discScoreCount += 1;
            }
          }
        } catch (e) {
          // ignore invalid json
        }
      }
    }

    const evalScore = discScoreCount > 0 ? Number((discScoreSum / discScoreCount).toFixed(1)) : null;

    let state = 'Not Started';
    if (compProjects > 0) {
      state = 'Practical Evidence Demonstrated';
    } else if (compLessons > 0) {
      state = 'Foundational Study';
    }

    return {
      discipline: discName,
      state,
      completedLessons: compLessons,
      totalLessons: totLessons,
      completedProjects: compProjects,
      evaluationScore: evalScore,
    };
  });

  return c.json({
    learning,
    practical,
    activity: {
      completedProjects: totalCompletedProjects,
      correctionRounds: totalCorrectionRounds,
    },
    readiness,
    disciplines,
  });
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
  if (!user || (user.role !== 'CLIENT' && user.role !== 'STUDIO_ADMIN')) {
    return c.json({ error: 'Only clients and admins can create projects' }, 403);
  }

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
  if (!user || (user.role !== 'CLIENT' && user.role !== 'STUDIO_ADMIN')) {
    return c.json({ error: 'Only clients and admins can submit projects' }, 403);
  }

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  if (project.client_id !== uid) return c.json({ error: 'Permission denied' }, 403);
  if (project.status === 'SUBMITTED' && project.last_action_id === actionId) return c.json({ success: true });
  if (project.status !== 'DRAFT') return c.json({ error: 'Only DRAFT projects can be submitted' }, 400);

  const batch = [
    db.prepare(`UPDATE projects SET status = 'SUBMITTED', submitted_at = CURRENT_TIMESTAMP, last_action_id = ? WHERE id = ?`).bind(actionId, projectId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, projectId, 'PROJECT_SUBMITTED', uid, user.role, 'Project brief submitted.'
    )
  ];
  await db.batch(batch);
  return c.json({ success: true });
});

app.post('/api/projects/submit-drawing', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const body = await c.req.json();
  const { projectId, actionId, draftFileId } = body;
  
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

  // If a draftFileId is provided, promote the draft file to a drawing version
  if (draftFileId) {
    const draftFile = await db.prepare('SELECT * FROM files WHERE id = ? AND project_id = ? AND uploaded_by = ?').bind(draftFileId, projectId, uid).first();
    if (!draftFile) return c.json({ error: 'Draft file not found or unauthorized' }, 404);
    
    if (draftFile.category === 'workspace_draft') {
      await db.prepare(`UPDATE files SET category = 'draughtsman_version' WHERE id = ?`).bind(draftFileId).run();
      
      const latest = await db.prepare('SELECT MAX(version_number) as v FROM drawing_versions WHERE project_id = ?').bind(projectId).first();
      const vNum = ((latest?.v as number) || 0) + 1;
      const corr = await db.prepare('SELECT id FROM corrections WHERE project_id = ? AND status = "OPEN"').bind(projectId).first();
      
      await db.prepare(`
        INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by, correction_id) 
        VALUES (?, ?, ?, ?, ?, ?)
      `).bind(uuidv4(), projectId, draftFileId, vNum, uid, (corr?.id as string) || null).run();
    }
  }

  const batch = [
    db.prepare(`UPDATE projects SET status = 'UNDER_CLIENT_REVIEW', last_action_id = ? WHERE id = ?`).bind(actionId, projectId),
    db.prepare(`UPDATE corrections SET status = 'RESOLVED', resolved_at = CURRENT_TIMESTAMP WHERE project_id = ? AND status = 'OPEN'`).bind(projectId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, projectId, 'DRAWING_SUBMITTED', uid, user.role, 'Submitted the drawing for review.'
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

  const batch = buildApproveFinalBatch(db, project, uid, actionId, user.role);
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

  const batch = buildRequestCorrectionBatch(db, project, uid, actionId, correctionId, targetVersionId, newRound, description, user.role);
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
  if (!dMan || (dMan.role !== 'DRAUGHTSMAN' && dMan.role !== 'STUDENT')) {
    return c.json({ error: 'Invalid user role for assignment' }, 400);
  }

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  if (project.status === 'WAITING_ACCEPTANCE' && project.last_action_id === actionId) return c.json({ success: true });
  if (project.status !== 'WAITING_ASSIGNMENT') return c.json({ error: 'Project is not in WAITING_ASSIGNMENT state' }, 400);

  const assignmentId = uuidv4();
  const assignmentQuery = dMan.role === 'STUDENT'
    ? db.prepare(`INSERT INTO student_assignments (id, project_id, student_id, assignment_type, status) VALUES (?, ?, ?, 'PRACTICAL', 'PENDING')`).bind(assignmentId, projectId, draughtsmanId)
    : db.prepare(`INSERT INTO assignments (id, project_id, draughtsman_id, status) VALUES (?, ?, ?, 'PENDING')`).bind(assignmentId, projectId, draughtsmanId);

  const batch = [
    assignmentQuery,
    db.prepare(`UPDATE projects SET status = 'WAITING_ACCEPTANCE', draughtsman_id = ?, draughtsman_name = ?, current_assignment_id = ?, assigned_at = CURRENT_TIMESTAMP, last_action_id = ?, is_training_project = CASE WHEN ? = 'STUDENT' THEN 1 ELSE is_training_project END WHERE id = ?`).bind(draughtsmanId, dMan.name, assignmentId, actionId, dMan.role, projectId),
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
  if (!dMan || (dMan.role !== 'DRAUGHTSMAN' && dMan.role !== 'STUDENT')) {
    return c.json({ error: 'Invalid user role for assignment' }, 400);
  }

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

  const assignmentQuery = dMan.role === 'STUDENT'
    ? db.prepare(`INSERT INTO student_assignments (id, project_id, student_id, assignment_type, status) VALUES (?, ?, ?, 'PRACTICAL', 'PENDING')`).bind(assignmentId, projectId, draughtsmanId)
    : db.prepare(`INSERT INTO assignments (id, project_id, draughtsman_id, status) VALUES (?, ?, ?, 'PENDING')`).bind(assignmentId, projectId, draughtsmanId);

  batch.push(assignmentQuery);
  batch.push(db.prepare(`UPDATE projects SET status = 'WAITING_ACCEPTANCE', draughtsman_id = ?, draughtsman_name = ?, current_assignment_id = ?, assigned_at = CURRENT_TIMESTAMP, last_action_id = ?, is_training_project = CASE WHEN ? = 'STUDENT' THEN 1 ELSE is_training_project END WHERE id = ?`).bind(draughtsmanId, dMan.name, assignmentId, actionId, dMan.role, projectId));
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
  if (!user || (user.role !== 'DRAUGHTSMAN' && user.role !== 'STUDENT')) return c.json({ error: 'Only draughtsmen or students can accept assignments' }, 403);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  if (project.status === 'IN_PROGRESS' && project.last_action_id === actionId) return c.json({ success: true });
  
  if (project.current_assignment_id !== assignmentId) return c.json({ error: 'Not the current assignment' }, 400);
  if (project.draughtsman_id !== uid) return c.json({ error: 'Not assigned to you' }, 403);
  if (project.status !== 'WAITING_ACCEPTANCE') return c.json({ error: 'Project is not in WAITING_ACCEPTANCE state' }, 400);

  let assignment;
  let updateAssignmentQuery;
  
  if (user.role === 'STUDENT') {
    assignment = await db.prepare('SELECT * FROM student_assignments WHERE id = ?').bind(assignmentId).first();
    updateAssignmentQuery = db.prepare(`UPDATE student_assignments SET status = 'ACCEPTED' WHERE id = ?`).bind(assignmentId);
  } else {
    assignment = await db.prepare('SELECT * FROM assignments WHERE id = ?').bind(assignmentId).first();
    updateAssignmentQuery = db.prepare(`UPDATE assignments SET status = 'ACCEPTED', updated_at = CURRENT_TIMESTAMP WHERE id = ?`).bind(assignmentId);
  }

  if (!assignment) return c.json({ error: 'Assignment not found' }, 404);
  if (assignment.status !== 'PENDING') return c.json({ error: 'Assignment is not PENDING' }, 400);

  const batch = [
    updateAssignmentQuery,
    db.prepare(`UPDATE projects SET status = 'IN_PROGRESS', last_action_id = ? WHERE id = ?`).bind(actionId, projectId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, projectId, 'ASSIGNMENT_ACCEPTED', uid, user.role, 'User accepted the assignment.'
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

app.get('/api/projects/:projectId/evaluations', async (c) => {
  const uid = c.get('uid');
  const projectId = c.req.param('projectId');
  const db = c.env.DB;
  const user = await getUser(db, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  // Apply existing authorization rules for reading evaluations
  if (user.role === 'CLIENT' && project.client_id !== uid) return c.json({ error: 'Forbidden' }, 403);
  if (user.role === 'DRAUGHTSMAN' && project.draughtsman_id !== uid) return c.json({ error: 'Forbidden' }, 403);
  if (user.role === 'STUDENT') {
    if (project.is_training_project !== 1) return c.json({ error: 'Forbidden' }, 403);
    const isAssigned = await verifyStudentAssignment(db, uid, projectId);
    if (!isAssigned) return c.json({ error: 'Forbidden' }, 403);
  }

  const { results } = await db.prepare('SELECT * FROM evaluations WHERE project_id = ? ORDER BY created_at DESC').bind(projectId).all();
  return c.json(results);
});

app.post('/api/projects/evaluate', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const body = await c.req.json();
  const { projectId, actionId, drawingVersionId, overallResult, generalFeedback, criteriaJson, correctionId } = body;
  
  const user = await getUser(db, uid);
  if (!user || (user.role !== 'CLIENT' && user.role !== 'STUDIO_ADMIN')) return c.json({ error: 'Only clients or admins can evaluate drawings' }, 403);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  if (user.role === 'CLIENT' && project.client_id !== uid) return c.json({ error: 'Permission denied' }, 403);
  
  if (project.status !== 'UNDER_CLIENT_REVIEW') return c.json({ error: 'Project is not in UNDER_CLIENT_REVIEW state' }, 400);

  const drawingVersion = await db.prepare('SELECT * FROM drawing_versions WHERE id = ?').bind(drawingVersionId).first();
  if (!drawingVersion) return c.json({ error: 'Drawing version not found' }, 404);
  if (drawingVersion.project_id !== projectId) return c.json({ error: 'Drawing version does not belong to this project' }, 400);

  if (overallResult !== 'APPROVED' && overallResult !== 'NEEDS_CORRECTION') {
    return c.json({ error: 'Invalid overall result' }, 400);
  }

  let criteriaString = criteriaJson;
  if (criteriaJson != null) {
    let parsedCriteria: any = criteriaJson;
    if (typeof criteriaJson === 'string') {
      try {
        parsedCriteria = JSON.parse(criteriaJson);
      } catch (e) {
        return c.json({ error: 'criteriaJson must be valid JSON' }, 400);
      }
    }
    
    // Normalize and validate criteria if present
    if (typeof parsedCriteria === 'object' && parsedCriteria !== null && !Array.isArray(parsedCriteria)) {
      const allowedKeys = ['Accuracy', 'Technical Standards'];
      const keys = Object.keys(parsedCriteria);
      
      if (keys.length !== allowedKeys.length || !allowedKeys.every(k => keys.includes(k))) {
        return c.json({ error: 'Criteria must contain exactly "Accuracy" and "Technical Standards"' }, 400);
      }

      for (const key of keys) {
        const val = parsedCriteria[key];
        if (typeof val !== 'number' || !Number.isInteger(val) || val < 1 || val > 5) {
          return c.json({ error: `Criterion '${key}' must be an integer between 1 and 5.` }, 400);
        }
      }
      criteriaString = JSON.stringify(parsedCriteria);
    } else {
      return c.json({ error: 'criteriaJson must be a JSON object' }, 400);
    }
  } else {
    return c.json({ error: 'criteriaJson is required' }, 400);
  }

  const evaluationId = uuidv4();
  let batch = [
    db.prepare(`
      INSERT INTO evaluations (id, project_id, drawing_version_id, evaluator_id, overall_result, general_feedback, criteria_json)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).bind(evaluationId, projectId, drawingVersionId, uid, overallResult, generalFeedback, criteriaString)
  ];

  if (overallResult === 'APPROVED') {
    let studentId = null;
    if (project.is_training_project === 1) {
      const assignment: any = await db.prepare('SELECT student_id FROM student_assignments WHERE project_id = ?').bind(project.id).first();
      if (assignment) studentId = assignment.student_id;
    }
    batch = batch.concat(buildApproveFinalBatch(db, project, uid, actionId, user.role, studentId));
  } else if (overallResult === 'NEEDS_CORRECTION') {
    const currentRound = (project.correction_round as number) || 0;
    if (currentRound >= 3) {
      return c.json({ error: 'Maximum correction rounds (3) exceeded' }, 400);
    }
    const newRound = currentRound + 1;
    // For evaluating needs_correction, we create a correction atomically.
    batch = batch.concat(buildRequestCorrectionBatch(db, project, uid, actionId, correctionId || uuidv4(), drawingVersionId, newRound, generalFeedback || 'Correction needed based on evaluation.', user.role));
  }

  await db.batch(batch);
  return c.json({ success: true, evaluationId });
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
  
  if (!category || !['client_upload', 'draughtsman_version', 'correction_attachment', 'workspace_draft'].includes(category)) {
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
  } else if (category === 'workspace_draft') {
    if (user.role !== 'STUDENT' || project.is_training_project !== 1 || project.status !== 'IN_PROGRESS') {
      return c.json({ error: 'Forbidden or invalid project state' }, 403);
    }
    const isAssigned = await verifyStudentAssignment(db, uid, projectId);
    if (!isAssigned) return c.json({ error: 'Forbidden' }, 403);
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
  if (fileMeta.status !== 'COMPLETED' && fileMeta.status !== 'READY') {
    return c.json({ error: 'File upload not complete' }, 400);
  }

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(fileMeta.project_id).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  // Authorization checks
  if (user.role === 'CLIENT' && project.client_id !== uid) return c.json({ error: 'Forbidden' }, 403);
  if (user.role === 'DRAUGHTSMAN' && project.draughtsman_id !== uid) return c.json({ error: 'Forbidden' }, 403);
  if (user.role === 'STUDENT') {
    const isAssigned = await db.prepare('SELECT 1 FROM student_assignments WHERE student_id = ? AND project_id = ?').bind(uid, project.id).first();
    if (!isAssigned) return c.json({ error: 'Forbidden' }, 403);
  }

  let object = await c.env.STORAGE.get(fileMeta.object_key as string);
  if (!object && (fileMeta.object_key as string).startsWith('train/')) {
    // Ensure mock training drawing file exists in R2 for developer/student demo testing
    const dummyDwgHeader = new Uint8Array(1024);
    const headerStr = `AC1032 - Archi Draft Approved Training Drawing (${fileMeta.sanitized_name})\n`;
    for (let i = 0; i < headerStr.length; i++) {
      dummyDwgHeader[i] = headerStr.charCodeAt(i);
    }
    await c.env.STORAGE.put(fileMeta.object_key as string, dummyDwgHeader, {
      httpMetadata: { contentType: (fileMeta.content_type as string) || 'application/acad' }
    });
    object = await c.env.STORAGE.get(fileMeta.object_key as string);
  }

  if (!object) return c.json({ error: 'File object missing in R2' }, 404);

  const headers = new Headers();
  object.writeHttpMetadata(headers as any);
  if (object.httpEtag) {
    headers.set('etag', object.httpEtag);
  }
  headers.set('Content-Disposition', `attachment; filename="${fileMeta.sanitized_name}"`);
  if (fileMeta.content_type) {
    headers.set('Content-Type', fileMeta.content_type as string);
  } else if (!headers.has('Content-Type')) {
    headers.set('Content-Type', 'application/octet-stream');
  }
  if (fileMeta.size) {
    headers.set('Content-Length', String(fileMeta.size));
  } else if (object.size) {
    headers.set('Content-Length', String(object.size));
  }

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

  const { results } = await db.prepare(`
    SELECT
      tm.*,
      COALESCE(sp.status, 'Not Started') AS status,
      sp.score,
      CASE
        WHEN sp.status = 'Completed' THEN 1.0
        WHEN sp.status = 'In Progress' THEN COALESCE(sp.score, 0) / 100.0
        ELSE 0.0
      END AS progress,
      CASE
        WHEN sp.status IS NOT NULL THEN 0
        ELSE tm.is_locked
      END AS is_locked
    FROM training_modules tm
    LEFT JOIN student_progress sp ON sp.module_id = tm.id AND sp.student_id = ?
    ORDER BY tm.created_at ASC
  `).bind(uid).all();
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

// GET /api/student/training/modules/:moduleId/lessons
app.get('/api/student/training/modules/:moduleId/lessons', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || user.role !== 'STUDENT') {
    return c.json({ error: 'Unauthorized', code: 'UNAUTHORIZED' }, 403);
  }

  const moduleId = c.req.param('moduleId');
  const { results } = await db.prepare(`
    SELECT
      l.*,
      COALESCE(slp.status, 'NOT_STARTED') AS status
    FROM training_lessons l
    LEFT JOIN student_lesson_progress slp ON slp.lesson_id = l.id AND slp.student_id = ?
    WHERE l.module_id = ?
    ORDER BY l.lesson_order ASC
  `).bind(uid, moduleId).all();

  return c.json(results);
});

// GET /api/student/training/lessons/:lessonId
app.get('/api/student/training/lessons/:lessonId', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || user.role !== 'STUDENT') {
    return c.json({ error: 'Unauthorized', code: 'UNAUTHORIZED' }, 403);
  }

  const lessonId = c.req.param('lessonId');
  const lesson = await db.prepare(`
    SELECT
      l.*,
      COALESCE(slp.status, 'NOT_STARTED') AS status
    FROM training_lessons l
    LEFT JOIN student_lesson_progress slp ON slp.lesson_id = l.id AND slp.student_id = ?
    WHERE l.id = ?
  `).bind(uid, lessonId).first();

  if (!lesson) {
    return c.json({ error: 'Lesson not found', code: 'NOT_FOUND' }, 404);
  }

  return c.json(lesson);
});

// POST /api/student/training/lessons/:lessonId/progress
app.post('/api/student/training/lessons/:lessonId/progress', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || user.role !== 'STUDENT') {
    return c.json({ error: 'Unauthorized', code: 'UNAUTHORIZED' }, 403);
  }

  const lessonId = c.req.param('lessonId');
  const body = await c.req.json();
  const status = body.status; // 'IN_PROGRESS' or 'COMPLETED'

  if (!status || !['IN_PROGRESS', 'COMPLETED'].includes(status)) {
    return c.json({ error: 'Invalid status', code: 'BAD_REQUEST' }, 400);
  }

  const lesson: any = await db.prepare('SELECT module_id FROM training_lessons WHERE id = ?').bind(lessonId).first();
  if (!lesson) {
    return c.json({ error: 'Lesson not found', code: 'NOT_FOUND' }, 404);
  }
  const moduleId = lesson.module_id;

  const allLessons = await db.prepare(`
    SELECT l.id, slp.status
    FROM training_lessons l
    LEFT JOIN student_lesson_progress slp ON slp.lesson_id = l.id AND slp.student_id = ?
    WHERE l.module_id = ?
  `).bind(uid, moduleId).all();

  let totalLessons = allLessons.results.length;
  let completedLessons = 0;
  
  for (const l of allLessons.results) {
    let lessonStatus = l.status;
    if (l.id === lessonId) {
      lessonStatus = status;
    }
    if (lessonStatus === 'COMPLETED') {
      completedLessons++;
    }
  }

  const batch = [];

  const id = uuidv4();
  batch.push(
    db.prepare(`
      INSERT INTO student_lesson_progress (id, student_id, lesson_id, status, completed_at)
      VALUES (?, ?, ?, ?, CASE WHEN ? = 'COMPLETED' THEN CURRENT_TIMESTAMP ELSE NULL END)
      ON CONFLICT(student_id, lesson_id) DO UPDATE SET
        status = excluded.status,
        completed_at = CASE WHEN excluded.status = 'COMPLETED' THEN CURRENT_TIMESTAMP ELSE NULL END
    `).bind(id, uid, lessonId, status, status)
  );

  if (totalLessons > 0) {
    let moduleStatus = 'In Progress';
    let score = Math.round((completedLessons / totalLessons) * 100);
    
    if (completedLessons === totalLessons) {
      moduleStatus = 'Completed';
      score = 100;
      
      const moduleDetails: any = await db.prepare('SELECT title FROM training_modules WHERE id = ?').bind(moduleId).first();
      const moduleTitle = moduleDetails?.title || 'Unknown Module';
      
      batch.push(
        db.prepare(`
          INSERT INTO student_credentials (id, student_id, type, reference_id, title, description, issued_at)
          VALUES (?, ?, 'MODULE_COMPLETION', ?, ?, ?, CURRENT_TIMESTAMP)
          ON CONFLICT(student_id, type, reference_id) DO NOTHING
        `).bind(
          uuidv4(), 
          uid, 
          moduleId, 
          'Module Certification', 
          `Completed the training module: ${moduleTitle}`
        )
      );
    }
    
    const moduleProgId = uuidv4();
    batch.push(
      db.prepare(`
        INSERT INTO student_progress (id, student_id, module_id, status, score, updated_at)
        VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
        ON CONFLICT(student_id, module_id) DO UPDATE SET
          status = excluded.status,
          score = excluded.score,
          updated_at = CURRENT_TIMESTAMP
      `).bind(moduleProgId, uid, moduleId, moduleStatus, score)
    );
  }

  await db.batch(batch);

  return c.json({ success: true });
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
      p.client_id,
      p.draughtsman_id,
      sa.id AS current_assignment_id,
      p.status,
      p.correction_round,
      p.created_at,
      p.submitted_at,
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
// GET /api/student/corrections
app.get('/api/student/corrections', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || user.role !== 'STUDENT') {
    return c.json({ error: 'Unauthorized', code: 'UNAUTHORIZED' }, 403);
  }

  const { results } = await db.prepare(`
    SELECT c.* 
    FROM corrections c
    JOIN projects p ON c.project_id = p.id
    JOIN student_assignments sa ON p.id = sa.project_id
    WHERE sa.student_id = ? 
      AND p.is_training_project = 1
      AND c.status != 'RESOLVED'
    ORDER BY c.created_at DESC
  `).bind(uid).all();

  return c.json(results);
});

// GET /api/student/activity
app.get('/api/student/activity', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || user.role !== 'STUDENT') {
    return c.json({ error: 'Unauthorized', code: 'UNAUTHORIZED' }, 403);
  }

  // Return recent activity for training projects the student is assigned to,
  // plus the student's own training progress updates.
  const { results } = await db.prepare(`
    SELECT al.*, p.project_name
    FROM activity_logs al
    JOIN projects p ON al.project_id = p.id
    JOIN student_assignments sa ON p.id = sa.project_id
    WHERE sa.student_id = ? AND p.is_training_project = 1
    ORDER BY al.timestamp DESC
    LIMIT 20
  `).bind(uid).all();

  return c.json(results);
});

// GET /api/student/achievements
app.get('/api/student/achievements', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || user.role !== 'STUDENT') {
    return c.json({ error: 'Unauthorized: Only students can access achievements', code: 'UNAUTHORIZED' }, 403);
  }

  const achievements = await getStudentAchievements(db, uid);
  return c.json({ achievements });
});

// GET /api/student/credentials
app.get('/api/student/credentials', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);
  if (!user || user.role !== 'STUDENT') return c.json({ error: 'Unauthorized' }, 403);

  const { results } = await db.prepare(`
    SELECT id, type, title, description, reference_id as referenceId, issued_at as issuedAt, certificate_object_key as certificateObjectKey, verification_token as verificationToken
    FROM student_credentials
    WHERE student_id = ?
    ORDER BY issued_at DESC
  `).bind(uid).all();

  return c.json(results);
});

// POST /api/student/credentials/:credentialId/certificate
app.post('/api/student/credentials/:credentialId/certificate', async (c) => {
  const uid = c.get('uid');
  const credentialId = c.req.param('credentialId');
  const db = c.env.DB;
  
  const user = await getUser(db, uid);
  if (!user || user.role !== 'STUDENT') return c.json({ error: 'Unauthorized' }, 403);

  const credential = await db.prepare('SELECT * FROM student_credentials WHERE id = ? AND student_id = ?').bind(credentialId, uid).first();
  if (!credential) return c.json({ error: 'Credential not found' }, 404);
  
  // NOTE: If certificate exists, we still regenerate if the QR code wasn't included, but for Part 5C,
  // we just regenerate anyway to ensure it has the QR. Or we can just overwrite. 
  // The instruction: "preserve the existing credential, update the certificate artifact deterministically"

  let verificationToken = credential.verification_token as string | null;
  if (!verificationToken) {
    verificationToken = crypto.randomUUID().replace(/-/g, '');
    await db.prepare('UPDATE student_credentials SET verification_token = ? WHERE id = ?').bind(verificationToken, credentialId).run();
  }

  // Assuming Firebase Hosting uses the project ID for default domain
  const publicUrl = `https://archi-draft.web.app/verify/${verificationToken}`;

  try {
    const pdfDoc = await PDFDocument.create();
    const page = pdfDoc.addPage([600, 400]);
    const helveticaFont = await pdfDoc.embedFont(StandardFonts.Helvetica);
    const helveticaBold = await pdfDoc.embedFont(StandardFonts.HelveticaBold);
    
    page.drawText('Certificate of Completion', { x: 50, y: 320, size: 30, font: helveticaBold, color: rgb(0.1, 0.2, 0.4) });
    page.drawText(`This is to certify that`, { x: 50, y: 270, size: 16, font: helveticaFont });
    page.drawText((user.name as string) || (user.email as string) || 'Student', { x: 50, y: 240, size: 24, font: helveticaBold });
    page.drawText(`has successfully completed`, { x: 50, y: 200, size: 16, font: helveticaFont });
    page.drawText((credential.title as string) || '', { x: 50, y: 170, size: 20, font: helveticaBold });
    
    const issueDate = new Date(credential.issued_at as string).toLocaleDateString();
    page.drawText(`Date: ${issueDate}`, { x: 50, y: 120, size: 14, font: helveticaFont });
    page.drawText(`Credential ID: ${credential.id}`, { x: 50, y: 90, size: 10, font: helveticaFont });

    // Generate and embed QR code manually using raw matrix to avoid canvas dependency
    const qrData = QRCode.create(publicUrl);
    const size = qrData.modules.size;
    const data = qrData.modules.data;
    
    const qrSize = 100;
    const moduleSize = qrSize / size;
    const xOffset = 450;
    const yOffset = 50;

    // Draw white background
    page.drawRectangle({
      x: xOffset,
      y: yOffset,
      width: qrSize,
      height: qrSize,
      color: rgb(1, 1, 1),
    });

    // Draw black modules (iterate from top-left, pdf-lib y=0 is bottom)
    for (let row = 0; row < size; row++) {
      for (let col = 0; col < size; col++) {
        if (data[row * size + col]) {
          page.drawRectangle({
            x: xOffset + col * moduleSize,
            y: yOffset + (size - row - 1) * moduleSize,
            width: moduleSize,
            height: moduleSize,
            color: rgb(0, 0, 0),
          });
        }
      }
    }
    page.drawText('Scan to Verify', { x: 465, y: 40, size: 10, font: helveticaFont });

    const pdfBytes = await pdfDoc.save();
    
    const objectKey = `certificates/${uid}/${credentialId}.pdf`;
    await c.env.STORAGE.put(objectKey, pdfBytes, {
      httpMetadata: { contentType: 'application/pdf' },
    });
    
    await db.prepare('UPDATE student_credentials SET certificate_object_key = ? WHERE id = ?').bind(objectKey, credentialId).run();
    
    return c.json({ message: 'Certificate generated', certificateObjectKey: objectKey, verificationToken });
  } catch (error: any) {
    console.error('PDF generation error:', error);
    return c.json({ error: 'Failed to generate certificate' }, 500);
  }
});

// GET /api/student/credentials/:credentialId/certificate
app.get('/api/student/credentials/:credentialId/certificate', async (c) => {
  const uid = c.get('uid');
  const credentialId = c.req.param('credentialId');
  const db = c.env.DB;

  const user = await getUser(db, uid);
  if (!user || user.role !== 'STUDENT') return c.json({ error: 'Unauthorized' }, 403);

  const credential = await db.prepare('SELECT * FROM student_credentials WHERE id = ? AND student_id = ?').bind(credentialId, uid).first();
  if (!credential) return c.json({ error: 'Credential not found' }, 404);
  
  if (!credential.certificate_object_key) {
    return c.json({ error: 'Certificate not generated yet' }, 404);
  }

  const object = await c.env.STORAGE.get(credential.certificate_object_key as string);
  if (!object) return c.json({ error: 'Certificate file missing in R2' }, 404);

  const headers = new Headers();
  object.writeHttpMetadata(headers as any);
  headers.set('etag', object.httpEtag);
  headers.set('Content-Disposition', `attachment; filename="Certificate_${credentialId}.pdf"`);

  return new Response(object.body, { headers });
});

// GET /api/public/credentials/verify/:verificationToken
app.get('/api/public/credentials/verify/:verificationToken', async (c) => {
  const token = c.req.param('verificationToken');
  const db = c.env.DB;

  const result = await db.prepare(`
    SELECT c.id, c.type, c.title, c.issued_at as issuedAt, u.name as display_name, u.email 
    FROM student_credentials c
    JOIN users u ON c.student_id = u.id
    WHERE c.verification_token = ?
  `).bind(token).first();

  if (!result) {
    return c.json({ valid: false, error: 'Certificate not found' }, 404);
  }

  const recipientName = (result.display_name as string) || (result.email as string) || 'Student';

  return c.json({
    valid: true,
    credential: {
      id: result.id,
      type: result.type,
      title: result.title,
      issuedAt: result.issuedAt,
      recipientName: recipientName
    }
  });
});

// GET /api/student/portfolio
app.get('/api/student/portfolio', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || user.role !== 'STUDENT') {
    return c.json({ error: 'Unauthorized', code: 'UNAUTHORIZED' }, 403);
  }

  // 1. Fetch completed projects assigned to student
  const { results: projects } = await db.prepare(`
    SELECT p.id, p.project_name, p.drawing_type, p.project_area, p.is_training_project, p.approved_at 
    FROM projects p 
    JOIN student_assignments sa ON p.id = sa.project_id 
    WHERE sa.student_id = ? AND p.status = 'COMPLETED'
  `).bind(uid).all();

  if (!projects || projects.length === 0) {
    return c.json({ portfolio: [] });
  }

  const projectIds = projects.map((p: any) => p.id);
  const chunkSize = 100;
  
  let allEvaluations: any[] = [];
  for (let i = 0; i < projectIds.length; i += chunkSize) {
    const chunk = projectIds.slice(i, i + chunkSize);
    const placeholders = chunk.map(() => '?').join(',');
    const { results: evals } = await db.prepare(`
      SELECT project_id, drawing_version_id, overall_result, criteria_json, general_feedback 
      FROM evaluations 
      WHERE overall_result = 'APPROVED' AND project_id IN (${placeholders})
    `).bind(...chunk).all();
    allEvaluations.push(...evals);
  }

  const drawingVersionIds = allEvaluations.map(e => e.drawing_version_id).filter(id => id);

  let allVersions: any[] = [];
  if (drawingVersionIds.length > 0) {
    for (let i = 0; i < drawingVersionIds.length; i += chunkSize) {
      const chunk = drawingVersionIds.slice(i, i + chunkSize);
      const placeholders = chunk.map(() => '?').join(',');
      const { results: versions } = await db.prepare(`
        SELECT id, project_id, file_id 
        FROM drawing_versions 
        WHERE id IN (${placeholders})
      `).bind(...chunk).all();
      allVersions.push(...versions);
    }
  }

  const fileIds = allVersions.map(v => v.file_id).filter(id => id);
  let allFiles: any[] = [];
  if (fileIds.length > 0) {
    for (let i = 0; i < fileIds.length; i += chunkSize) {
      const chunk = fileIds.slice(i, i + chunkSize);
      const placeholders = chunk.map(() => '?').join(',');
      const { results: files } = await db.prepare(`
        SELECT id, sanitized_name, content_type 
        FROM files 
        WHERE id IN (${placeholders})
      `).bind(...chunk).all();
      allFiles.push(...files);
    }
  }

  const portfolio = [];

  for (const project of projects) {
    // Find matching approved evaluation
    const evalRecord = allEvaluations.find(e => e.project_id === project.id);
    if (!evalRecord) continue;

    let criteria: { name: string; score: number; maxScore: number }[] = [];
    let overallPercentage = 0;
    if (evalRecord.criteria_json) {
      try {
        const parsed = JSON.parse(evalRecord.criteria_json as string);
        for (const [key, val] of Object.entries(parsed)) {
          criteria.push({
            name: key,
            score: Number(val),
            maxScore: 5
          });
        }
        
        if (criteria.length > 0) {
          const totalScore = criteria.reduce((sum: number, c: any) => sum + c.score, 0);
          overallPercentage = Math.round((totalScore / (criteria.length * 5)) * 100);
        }
      } catch (e) {
        console.error('Failed to parse criteria_json', e);
      }
    }

    let finalDrawing = null;
    const version = allVersions.find(v => v.id === evalRecord.drawing_version_id);
    if (version) {
      const file = allFiles.find(f => f.id === version.file_id);
      if (file) {
        finalDrawing = {
          fileId: file.id,
          sanitizedName: file.sanitized_name,
          contentType: file.content_type,
          downloadUrl: `/api/files/${file.id}/download`
        };
      }
    }

    portfolio.push({
      projectId: project.id,
      projectName: project.project_name,
      drawingType: project.drawing_type,
      projectArea: project.project_area,
      isTrainingProject: project.is_training_project === 1,
      approvedAt: project.approved_at,
      finalDrawing,
      evaluation: {
        result: evalRecord.overall_result,
        criteria,
        overallPercentage,
        generalFeedback: evalRecord.general_feedback || null
      }
    });
  }

  return c.json({ portfolio });
});

export default app;
