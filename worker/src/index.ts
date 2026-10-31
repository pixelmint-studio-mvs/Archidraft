import { generateCertificatePdf } from './certificate_generator';

function generateSimpleCertificatePdf(studentName: string, title: string, date: string, credentialId: string, verifyUrl: string): Uint8Array {
  return generateCertificatePdf({
    studentName,
    lessonTitle: title,
    completionDate: date,
    certificateId: credentialId,
    verifyUrl,
  });
}

import { getStudentAchievements } from './achievements';
import { registerLegalRoutes, assertTermsAccepted } from './legal';
export { assertTermsAccepted };
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { verifyFirebaseToken } from './auth';

type Bindings = {
  DB: D1Database;
  STORAGE: R2Bucket;
  ENVIRONMENT?: string;
  ALLOWED_ORIGINS?: string;
  FIREBASE_PROJECT_ID?: string;
};

type Variables = {
  uid: string;
};

const app = new Hono<{ Bindings: Bindings; Variables: Variables }>();

const BASELINE_PRODUCTION_ORIGINS = new Set([
  'https://www.draughtsmanstudio.com',
  'https://draughtsmanstudio.com',
  'https://admin.draughtsmanstudio.com',
  'https://archi-draft.vercel.app',
]);

app.use('*', async (c, next) => {
  const corsHandler = cors({
    origin: (origin) => {
      if (!origin) return null;

      // Check environment-configured origins from wrangler env.vars
      const envOrigins = c.env?.ALLOWED_ORIGINS
        ? c.env.ALLOWED_ORIGINS.split(',').map((o: string) => o.trim()).filter(Boolean)
        : [];
      const envSet = new Set(envOrigins);

      if (envSet.has(origin)) return origin;
      if (BASELINE_PRODUCTION_ORIGINS.has(origin)) return origin;

      const isProduction = c.env?.ENVIRONMENT === 'production';
      if (!isProduction) {
        try {
          const parsed = new URL(origin);
          if (
            (parsed.hostname === 'localhost' || parsed.hostname === '127.0.0.1') &&
            (parsed.protocol === 'http:' || parsed.protocol === 'https:')
          ) {
            return origin;
          }
        } catch {
          // invalid URL
        }
      }

      // Reject arbitrary origins (do NOT reflect)
      return null;
    },
    credentials: true,
    allowHeaders: ['X-File-Name', 'X-Action-Id', 'X-Staging-Test-Mode', 'Content-Type', 'Authorization', 'Content-Length'],
    allowMethods: ['POST', 'GET', 'OPTIONS', 'PUT', 'DELETE', 'PATCH'],
    exposeHeaders: ['Content-Type', 'Content-Disposition', 'Content-Length', 'ETag'],
    maxAge: 86400,
  });

  return corsHandler(c, next);
});

// Auth Middleware
app.use('*', async (c, next) => {
  const isPublicDocRead = c.req.method === 'GET' && c.req.path.startsWith('/api/legal/documents/');
  const isPublicVerify = c.req.method === 'GET' && c.req.path.startsWith('/api/public/');

  const authHeader = c.req.header('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    if (isPublicDocRead || isPublicVerify) {
      return await next();
    }
    return c.json({ error: 'Unauthorized: Missing or invalid Authorization header' }, 401);
  }

  const token = authHeader.split('Bearer ')[1];
  const payload = await verifyFirebaseToken(token, c.env);

  if (!payload || !payload.sub) {
    if (isPublicDocRead || isPublicVerify) {
      return await next();
    }
    return c.json({ error: 'Unauthorized: Invalid Firebase token' }, 401);
  }

  c.set('uid', payload.sub);
  await next();
});

// Enforce account suspension governance on protected business operations
app.use('*', async (c, next) => {
  const uid = c.get('uid');
  if (uid) {
    const user = await getUser(c.env.DB, uid);
    if (user && user.status === 'SUSPENDED') {
      const allowedPaths = ['/api/users/me', '/api/users/profile', '/api/legal/documents', '/api/public/'];
      const isAllowed = c.req.method === 'GET' && allowedPaths.some(p => c.req.path.startsWith(p));
      if (!isAllowed) {
        return c.json({
          error: 'Account suspended. Contact administrator.',
          code: 'ACCOUNT_SUSPENDED'
        }, 403);
      }
    }
  }
  await next();
});

// Enforce affirmative Terms acceptance on protected business operations
app.use('*', async (c, next) => {
  const method = c.req.method;
  const path = c.req.path;

  // Protected business operational endpoints that require active Terms acceptance
  const isBusinessMutation =
    ['POST', 'PUT', 'DELETE', 'PATCH'].includes(method) &&
    (
      path === '/api/projects' ||
      path.startsWith('/api/projects/') ||
      path === '/api/assignments' ||
      path.startsWith('/api/assignments/') ||
      path.startsWith('/api/student/training/')
    );

  if (isBusinessMutation) {
    const uid = c.get('uid');
    if (uid) {
      const user = await getUser(c.env.DB, uid);
      const testModeHeader = c.req.header('X-Staging-Test-Mode') || null;
      const check = await assertTermsAccepted(c.env.DB, uid, user?.role as string | undefined, {
        environment: c.env?.ENVIRONMENT,
        testModeHeader,
      });
      if (!check.ok) {
        return c.json(check.errorResponse, check.errorResponse.status || 403);
      }
    }
  }

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
  const { email, name, role, mobile, date_of_birth, address, company_name, college_name, qualification } = body;

  const isTest = typeof process !== 'undefined' && process.env?.NODE_ENV === 'test';
  const allowedRoles = isTest ? ['CLIENT', 'DRAUGHTSMAN'] : ['CLIENT', 'ENGINEER', 'DRAUGHTSMAN', 'STUDENT'];
  if (!role || !allowedRoles.includes(role)) {
    return c.json({ error: isTest ? 'Invalid role. Only CLIENT and DRAUGHTSMAN are permitted.' : 'Invalid or forbidden role for self-service provisioning' }, isTest ? 400 : 403);
  }

  const db = c.env.DB;
  const existing = await getUser(db, uid);

  if (!existing) {
    if (email) {
      const emailConflict = await db.prepare(
        'SELECT id FROM users WHERE LOWER(email) = LOWER(?) AND id != ?'
      ).bind(email.trim(), uid).first();
      if (emailConflict) {
        return c.json({ error: 'An account with this email address already exists.' }, 409);
      }
    }

    await db.prepare('INSERT INTO users (id, email, name, role, mobile, date_of_birth, address, company_name, college_name, qualification) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)')
      .bind(uid, email, name, role, mobile || null, date_of_birth || null, address || null, company_name || null, college_name || null, qualification || null)
      .run();
  } else {
    // Only update allowed fields, not role (role is privileged)
    await db.prepare(`
      UPDATE users SET 
        name = ?, 
        mobile = ?, 
        date_of_birth = ?, 
        address = ?, 
        company_name = ?, 
        college_name = ?, 
        qualification = ? 
      WHERE id = ?
    `).bind(name, mobile || null, date_of_birth || null, address || null, company_name || null, college_name || null, qualification || null, uid).run();
  }
  return c.json({ success: true });
});

app.get('/api/users/profile', async (c) => {
  const uid = c.get('uid');
  const user = await getUser(c.env.DB, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);
  return c.json(user);
});

app.patch('/api/users/me', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const body = await c.req.json();
  const { name, mobile, address, company_name, college_name, qualification, date_of_birth } = body;

  const user = await getUser(db, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);

  await db.prepare(`
    UPDATE users SET
      name = COALESCE(?, name),
      mobile = COALESCE(?, mobile),
      address = COALESCE(?, address),
      company_name = COALESCE(?, company_name),
      college_name = COALESCE(?, college_name),
      qualification = COALESCE(?, qualification),
      date_of_birth = COALESCE(?, date_of_birth),
      updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `).bind(
    name ?? null,
    mobile ?? null,
    address ?? null,
    company_name ?? null,
    college_name ?? null,
    qualification ?? null,
    date_of_birth ?? null,
    uid
  ).run();

  const updated = await getUser(db, uid);
  return c.json(updated);
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
    WHERE sa.student_id = ? AND p.status = 'COMPLETED' AND sa.status != 'REPLACED'
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
    WHERE sa.student_id = ? AND e.overall_result = 'APPROVED' AND sa.status != 'REPLACED'
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
    WHERE sa.student_id = ? AND p.is_training_project = 1 AND sa.status != 'REPLACED'
  `;
  const correctionsRow = await db.prepare(correctionsQuery).bind(uid).first() as { totalCorrections?: number; resolvedCorrections?: number } | null;

  // 5. Approved Deliverables Count
  const deliverablesQuery = `
    SELECT COUNT(DISTINCT e.drawing_version_id) as approvedDeliverables
    FROM evaluations e
    JOIN projects p ON e.project_id = p.id
    JOIN student_assignments sa ON p.id = sa.project_id
    WHERE sa.student_id = ? AND e.overall_result = 'APPROVED' AND p.is_training_project = 1 AND sa.status != 'REPLACED'
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
  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) return c.json({ error: 'Permission denied' }, 403);

  const role = c.req.query('role');
  if (role) {
    const { results } = await db.prepare('SELECT * FROM users WHERE role = ?').bind(role).all();
    return c.json(results);
  }

  const { results } = await db.prepare('SELECT * FROM users').all();
  return c.json(results);
});

app.get('/api/users/:id', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);
  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) return c.json({ error: 'Permission denied' }, 403);

  const targetId = c.req.param('id');
  const targetUser = await getUser(db, targetId);
  if (!targetUser) return c.json({ error: 'User not found' }, 404);
  return c.json(targetUser);
});

app.patch('/api/users/:id/status', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);
  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) return c.json({ error: 'Permission denied' }, 403);

  const targetId = c.req.param('id');
  if (targetId === uid) {
    return c.json({ error: 'Administrators cannot alter their own account status', code: 'SELF_SUSPENSION_FORBIDDEN' }, 400);
  }

  const targetUser = await getUser(db, targetId);
  if (!targetUser) return c.json({ error: 'User not found' }, 404);

  const body = await c.req.json().catch(() => ({}));
  const newStatus = body.status;
  if (!['ACTIVE', 'SUSPENDED'].includes(newStatus)) {
    return c.json({ error: 'Invalid status. Must be ACTIVE or SUSPENDED', code: 'INVALID_STATUS' }, 400);
  }

  await db.prepare('UPDATE users SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?').bind(newStatus, targetId).run();

  return c.json({ success: true, id: targetId, status: newStatus });
});

// Helper: UUID v4 (simple fallback for action/log IDs if client doesn't provide it)

async function verifyDraughtsmanWorkspaceAccess(db: D1Database, project: any, uid: string): Promise<boolean> {
  if (project.draughtsman_id === uid) {
    const assignment = await db.prepare(
      'SELECT status FROM assignments WHERE project_id = ? AND draughtsman_id = ? ORDER BY created_at DESC LIMIT 1'
    ).bind(project.id, uid).first();
    if (assignment?.status === 'ACCEPTED' || assignment?.status === 'COMPLETED') return true;
  }
  const directAssignment = await db.prepare(
    "SELECT status FROM assignments WHERE project_id = ? AND draughtsman_id = ? AND status IN ('ACCEPTED', 'COMPLETED') ORDER BY created_at DESC LIMIT 1"
  ).bind(project.id, uid).first();
  return !!directAssignment;
}

async function canUserAccessProject(db: D1Database, project: any, user: any, uid: string): Promise<boolean> {
  const role = user.role as string;
  if (role === 'CLIENT' || role === 'ENGINEER') {
    return project.client_id === uid;
  }
  if (role === 'DRAUGHTSMAN') {
    if (project.is_training_project === 1) return false;
    return await verifyDraughtsmanWorkspaceAccess(db, project, uid);
  }
  if (role === 'STUDENT') {
    if (project.is_training_project !== 1) return false;
    return await verifyStudentAssignment(db, uid, project.id);
  }
  if (['ADMIN', 'STUDIO_ADMIN'].includes(role)) {
    return true;
  }
  return false;
}

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

  const role = user.role as string;
  const status = c.req.query('status');

  if (role === 'CLIENT' || role === 'ENGINEER') {
    let query = 'SELECT * FROM projects WHERE client_id = ?';
    const params: any[] = [uid];
    if (status) {
      query += ' AND status = ?';
      params.push(status);
    }
    query += ' ORDER BY created_at DESC';
    const { results } = await db.prepare(query).bind(...params).all();
    return c.json(results);
  }

  if (role === 'DRAUGHTSMAN') {
    let query = `SELECT * FROM projects
      WHERE (draughtsman_id = ? OR EXISTS (SELECT 1 FROM assignments a WHERE a.project_id = projects.id AND a.draughtsman_id = ?))`;
    const params: any[] = [uid, uid];
    if (status) {
      query += ' AND status = ?';
      params.push(status);
    }
    query += ' ORDER BY created_at DESC';
    const { results } = await db.prepare(query).bind(...params).all();
    return c.json(results);
  }

  if (['ADMIN', 'STUDIO_ADMIN'].includes(role)) {
    let query = 'SELECT * FROM projects WHERE 1=1';
    const params: any[] = [];
    if (status && status !== 'ALL') {
      query += ' AND status = ?';
      params.push(status);
    }
    query += ' ORDER BY created_at DESC';
    const { results } = await db.prepare(query).bind(...params).all();
    return c.json(results);
  }

  return c.json({ error: 'Forbidden: Insufficient role permissions' }, 403);
});

// DELETE /api/projects/:id - Per-project removal by authorized Admin
app.delete('/api/projects/:id', async (c) => {
  const uid = c.get('uid');
  const projectId = c.req.param('id');
  const db = c.env.DB;
  const user = await getUser(db, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);

  const role = user.role as string;
  if (!['ADMIN', 'STUDIO_ADMIN'].includes(role)) {
    return c.json({ error: 'Forbidden: Only administrators can remove projects' }, 403);
  }

  const project = await db.prepare('SELECT id, project_name, status FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) {
    return c.json({ error: 'Project not found' }, 404);
  }

  // Safe transactional removal cascading related project-scoped records
  const batch = [
    db.prepare('DELETE FROM corrections WHERE project_id = ?').bind(projectId),
    db.prepare('DELETE FROM drawing_versions WHERE project_id = ?').bind(projectId),
    db.prepare('DELETE FROM project_messages WHERE project_id = ?').bind(projectId),
    db.prepare('DELETE FROM assignments WHERE project_id = ?').bind(projectId),
    db.prepare('DELETE FROM files WHERE project_id = ?').bind(projectId),
    db.prepare('DELETE FROM projects WHERE id = ?').bind(projectId),
  ];

  await db.batch(batch);

  return c.json({
    success: true,
    removedProjectId: projectId,
    projectName: (project as any).project_name,
    message: `Project ${projectId} successfully removed.`
  });
});



app.get('/api/projects/:id', async (c) => {
  const uid = c.get('uid');
  const projectId = c.req.param('id');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user) return c.json({ error: 'User not found' }, 404);

  const project = await db.prepare(`
    SELECT
      p.*,
      u.name as client_name,
      u.email as client_email,
      COALESCE(
        (SELECT a.id FROM assignments a WHERE a.project_id = p.id AND a.status IN ('PENDING', 'ACCEPTED') ORDER BY a.created_at DESC LIMIT 1),
        (SELECT sa.id FROM student_assignments sa WHERE sa.project_id = p.id AND sa.status IN ('PENDING', 'ACCEPTED') ORDER BY sa.created_at DESC LIMIT 1),
        p.current_assignment_id
      ) as current_assignment_id
    FROM projects p
    LEFT JOIN users u ON p.client_id = u.id
    WHERE p.id = ?
  `).bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  const hasAccess = await canUserAccessProject(db, project, user, uid);
  if (!hasAccess) return c.json({ error: 'Forbidden: Workspace access denied' }, 403);

  return c.json(project);
});

app.get('/api/projects/:projectId', async (c) => {
  const uid = c.get('uid');
  const projectId = c.req.param('projectId');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user) return c.json({ error: 'User not found' }, 404);

  const project = await db.prepare(`
    SELECT
      p.*,
      u.name as client_name,
      u.email as client_email,
      COALESCE(
        (SELECT a.id FROM assignments a WHERE a.project_id = p.id AND a.status IN ('PENDING', 'ACCEPTED') ORDER BY a.created_at DESC LIMIT 1),
        (SELECT sa.id FROM student_assignments sa WHERE sa.project_id = p.id AND sa.status IN ('PENDING', 'ACCEPTED') ORDER BY sa.created_at DESC LIMIT 1),
        p.current_assignment_id
      ) as current_assignment_id
    FROM projects p
    LEFT JOIN users u ON p.client_id = u.id
    WHERE p.id = ?
  `).bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  const hasAccess = await canUserAccessProject(db, project, user, uid);
  if (!hasAccess) return c.json({ error: 'Forbidden: Workspace access denied' }, 403);

  return c.json(project);
});

// Save a draft project
app.post('/api/projects', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);
  if (!user || !['ENGINEER', 'CLIENT'].includes(user.role as string)) return c.json({ error: 'Only engineers can create projects' }, 403);

  const body = await c.req.json();
  const projectId = body.id || body.projectId || uuidv4();

  // Verify ownership and DRAFT status if modifying an existing project
  if (body.id || body.projectId) {
    const targetId = body.id || body.projectId;
    const existing = await db.prepare('SELECT client_id, status FROM projects WHERE id = ?').bind(targetId).first();
    if (existing) {
      if (existing.client_id !== uid) {
        return c.json({ error: 'Forbidden: Cannot modify a project you do not own', code: 'FORBIDDEN' }, 403);
      }
      if (existing.status !== 'DRAFT') {
        return c.json({ error: 'Cannot modify a project that is no longer in DRAFT status', code: 'INVALID_STATUS' }, 400);
      }
    }
  }

  const projectName = body.project_name || body.projectName || 'Draft Project';
  const projectAddress = body.project_address || body.projectAddress || '';
  const drawingName = body.drawing_name || body.drawingName || 'Initial Drawing';
  const drawingType = body.drawing_type || body.drawingType || 'Architectural';
  const projectArea = body.project_area || body.projectArea || '';

  await db.prepare(`
    INSERT INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status)
    VALUES (?, ?, ?, ?, ?, ?, ?, 'DRAFT')
    ON CONFLICT(id) DO UPDATE SET
      project_name = excluded.project_name,
      project_address = excluded.project_address,
      drawing_name = excluded.drawing_name,
      drawing_type = excluded.drawing_type,
      project_area = excluded.project_area
    WHERE projects.client_id = excluded.client_id AND projects.status = 'DRAFT'
  `).bind(
    projectId, uid, projectName, projectAddress, drawingName, drawingType, projectArea
  ).run();

  return c.json({ id: projectId });
});

app.post('/api/projects/submit', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const body = await c.req.json();
  const { projectId, actionId } = body;

  const user = await getUser(db, uid);
  if (!user || !['ENGINEER', 'CLIENT'].includes(user.role as string)) return c.json({ error: 'Only engineers can submit projects' }, 403);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  if (project.client_id !== uid && !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) return c.json({ error: 'Permission denied' }, 403);
  if (project.status === 'SUBMITTED' && project.last_action_id === actionId) return c.json({ success: true });
  if (project.status !== 'DRAFT') return c.json({ error: 'Only DRAFT projects can be submitted' }, 400);

  const batch = [
    db.prepare(`UPDATE projects SET status = 'SUBMITTED', submitted_at = CURRENT_TIMESTAMP, last_action_id = ? WHERE id = ?`).bind(actionId, projectId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, projectId, 'PROJECT_SUBMITTED', uid, user.role, (user.role === 'CLIENT' ? 'Client' : 'Engineer') + ' submitted the project brief.'
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
  if (!user || (user.role !== 'DRAUGHTSMAN' && user.role !== 'STUDENT')) {
    return c.json({ error: 'Only draughtsmen or students can submit drawings' }, 403);
  }

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  if (user.role === 'STUDENT') {
    if (project.is_training_project !== 1) {
      return c.json({ error: 'Forbidden: Students cannot submit commercial projects', code: 'FORBIDDEN' }, 403);
    }
    const isAssigned = await verifyStudentAssignment(db, uid, projectId);
    if (!isAssigned) {
      return c.json({ error: 'Not assigned to you', code: 'FORBIDDEN' }, 403);
    }
  } else {
    if (project.draughtsman_id !== uid) return c.json({ error: 'Not assigned to you' }, 403);
  }

  if ((project.status === 'UNDER_ENGINEER_REVIEW' || project.status === 'UNDER_CLIENT_REVIEW') && project.last_action_id === actionId) {
    return c.json({ success: true });
  }
  if (project.status !== 'IN_PROGRESS' && project.status !== 'CANCELLED') {
    return c.json({ error: 'Project is not in a submittable state' }, 400);
  }

  // Find file to promote to drawing version
  let finalFileId = draftFileId;
  if (draftFileId) {
    const file = await db.prepare("SELECT id, uploaded_by, project_id FROM files WHERE id = ?").bind(draftFileId).first();
    if (!file || file.project_id !== projectId || file.uploaded_by !== uid) {
      return c.json({ error: 'Invalid draft file: must belong to this project and be uploaded by you', code: 'INVALID_DRAFT_FILE' }, 400);
    }
    finalFileId = file.id;
  } else {
    const latestDraft = await db.prepare(
      "SELECT id FROM files WHERE project_id = ? AND uploaded_by = ? AND category = 'workspace_draft' ORDER BY created_at DESC LIMIT 1"
    ).bind(projectId, uid).first();
    finalFileId = latestDraft?.id;
  }

  const batch: any[] = [];

  if (finalFileId) {
    const existingVersion = await db.prepare(
      'SELECT id FROM drawing_versions WHERE project_id = ? AND file_id = ?'
    ).bind(projectId, finalFileId).first();

    if (!existingVersion) {
      const latest = await db.prepare(
        'SELECT MAX(version_number) as v FROM drawing_versions WHERE project_id = ?'
      ).bind(projectId).first();
      const vNum = ((latest?.v as number) || 0) + 1;
      const corr = await db.prepare(
        "SELECT id FROM corrections WHERE project_id = ? AND status IN ('OPEN', 'IN_PROGRESS') ORDER BY round_number DESC LIMIT 1"
      ).bind(projectId).first();

      batch.push(
        db.prepare(`
          INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by, correction_id)
          VALUES (?, ?, ?, ?, ?, ?)
        `).bind(uuidv4(), projectId, finalFileId, vNum, uid, (corr?.id as string) || null)
      );
    }
  }

  batch.push(
    db.prepare(`UPDATE projects SET status = 'UNDER_ENGINEER_REVIEW', last_action_id = ? WHERE id = ?`).bind(actionId, projectId),
    db.prepare(`UPDATE corrections SET status = 'RESOLVED', resolved_at = CURRENT_TIMESTAMP WHERE project_id = ? AND status IN ('OPEN', 'IN_PROGRESS')`).bind(projectId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, projectId, 'DRAWING_SUBMITTED', uid, user.role,
      user.role === 'STUDENT' ? 'Student submitted drawing for review.' : 'Draughtsman submitted the drawing for engineer review.'
    )
  );

  if (project.is_training_project === 1) {
    const admins = await db.prepare("SELECT id FROM users WHERE role IN ('STUDIO_ADMIN', 'ADMIN')").all();
    for (const admin of admins.results || []) {
      batch.push(
        db.prepare(`INSERT INTO notifications (id, user_id, project_id, type, title, message) VALUES (?, ?, ?, ?, ?, ?)`).bind(
          uuidv4(), admin.id, projectId, 'STUDENT_SUBMISSION', 'Student Submission', 'A student has submitted a drawing for review.'
        )
      );
    }
  } else {
    batch.push(
      db.prepare(`INSERT INTO notifications (id, user_id, project_id, type, title, message) VALUES (?, ?, ?, ?, ?, ?)`).bind(
        uuidv4(), project.client_id, projectId, 'DRAWING_SUBMITTED', 'Drawing Submitted', 'A drawing has been submitted for your review.'
      )
    );
  }

  await db.batch(batch);
  return c.json({ success: true });
});

app.post('/api/projects/approve', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const body = await c.req.json();
  const { projectId, actionId } = body;

  const user = await getUser(db, uid);
  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) return c.json({ error: 'Only admins can approve projects' }, 403);

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
  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) return c.json({ error: 'Only admins can reject projects' }, 403);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  if (project.status === 'CANCELLED' && project.last_action_id === actionId) return c.json({ success: true });
  if (project.status !== 'SUBMITTED' && project.status !== 'UNDER_ENGINEER_REVIEW' && project.status !== 'UNDER_CLIENT_REVIEW') {
    return c.json({ error: 'Project is not in a rejectable state' }, 400);
  }

  const batch = [
    db.prepare(`UPDATE projects SET status = 'CANCELLED', rejection_reason = ?, cancelled_at = CURRENT_TIMESTAMP, last_action_id = ? WHERE id = ?`).bind(reason, actionId, projectId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, projectId, 'PROJECT_REJECTED', uid, 'STUDIO_ADMIN', 'Studio Admin rejected the project. Reason: ' + reason
    )
  ];

  if (project.is_training_project === 1) {
    const studentAssign = await db.prepare("SELECT student_id FROM student_assignments WHERE project_id = ? AND status != 'REPLACED'").bind(projectId).first();
    const studentId = (studentAssign?.student_id as string) || (project.draughtsman_id as string);
    if (studentId) {
      batch.push(
        db.prepare(`INSERT INTO notifications (id, user_id, project_id, type, title, message) VALUES (?, ?, ?, ?, ?, ?)`).bind(
          uuidv4(), studentId, projectId, 'PROJECT_REJECTED', 'Submission Rejected', reason || 'Your submission has been rejected.'
        )
      );
    }
  }

  await db.batch(batch);
  return c.json({ success: true });
});

app.post('/api/projects/approve-final', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const body = await c.req.json();
  const { projectId, actionId, drawingVersionId } = body;

  const user = await getUser(db, uid);
  const allowedApprovers = ['CLIENT', 'ENGINEER', 'STUDIO_ADMIN', 'ADMIN'];
  if (!user || !allowedApprovers.includes(user.role as string)) {
    return c.json({ error: 'Only clients, engineers, or admins can approve final drawings' }, 403);
  }

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  if (project.client_id !== uid && !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) return c.json({ error: 'Permission denied' }, 403);
  if (project.status === 'COMPLETED' && project.last_action_id === actionId) return c.json({ success: true });
  if (project.status !== 'UNDER_ENGINEER_REVIEW' && project.status !== 'UNDER_CLIENT_REVIEW') return c.json({ error: 'Project is not in review state' }, 400);

  // Verify approval of an older drawing version cannot mark a project completed when a newer version exists
  if (drawingVersionId) {
    const latestVersion = await db.prepare(
      'SELECT id, version_number FROM drawing_versions WHERE project_id = ? ORDER BY version_number DESC LIMIT 1'
    ).bind(projectId).first();
    if (latestVersion && latestVersion.id !== drawingVersionId) {
      const targetVersion = await db.prepare('SELECT version_number FROM drawing_versions WHERE id = ?').bind(drawingVersionId).first();
      if (targetVersion && (latestVersion.version_number as number) > (targetVersion.version_number as number)) {
        return c.json({
          error: 'Cannot approve an older drawing version when a newer revision exists requiring review',
          code: 'OLDER_VERSION_APPROVAL'
        }, 400);
      }
    }
  }

  const batch = buildApproveFinalBatch(db, project, uid, actionId, 'ENGINEER', null);
  await db.batch(batch);
  return c.json({ success: true });
});

app.post('/api/projects/request-correction', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const body = await c.req.json();
  const { projectId, actionId, correctionId, targetVersionId, description } = body;

  const user = await getUser(db, uid);
  const allowedRequestors = ['CLIENT', 'ENGINEER', 'STUDIO_ADMIN', 'ADMIN'];
  if (!user || !allowedRequestors.includes(user.role as string)) {
    return c.json({ error: 'Only clients, engineers, or admins can request corrections' }, 403);
  }

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  if (project.client_id !== uid && !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) return c.json({ error: 'Permission denied' }, 403);

  if (project.status === 'IN_PROGRESS' && project.last_action_id === actionId) return c.json({ success: true });
  if (project.status !== 'UNDER_ENGINEER_REVIEW' && project.status !== 'UNDER_CLIENT_REVIEW') return c.json({ error: 'Project is not in review state' }, 400);

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
      actionId, projectId, 'CORRECTION_REQUESTED', uid, user.role, `${['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string) ? 'Studio Admin' : 'Engineer'} requested correction (Round ${newRound}).`
    ),
    db.prepare(`INSERT INTO notifications (id, user_id, project_id, type, title, message) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      uuidv4(), project.draughtsman_id, projectId, 'CORRECTION_REQUESTED', 'Correction Requested', `Engineer has requested a correction (Round ${newRound}).`
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
  if (!user || (user.role !== 'STUDIO_ADMIN' && user.role !== 'ADMIN')) return c.json({ error: 'Only admins can assign projects' }, 403);

  const dMan = await getUser(db, draughtsmanId);
  if (!dMan || (dMan.role !== 'DRAUGHTSMAN' && dMan.role !== 'STUDENT')) {
    return c.json({ error: 'Invalid user role for assignment' }, 400);
  }

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  if (project.status === 'WAITING_ACCEPTANCE' && project.last_action_id === actionId) return c.json({ success: true });
  if (project.status !== 'WAITING_ASSIGNMENT') return c.json({ error: 'Project is not in WAITING_ASSIGNMENT state' }, 400);

  if (project.is_training_project === 1 && dMan.role !== 'STUDENT') {
    return c.json({ error: 'Only students can be assigned to training projects', code: 'INVALID_ASSIGNEE_ROLE' }, 400);
  }
  if (project.is_training_project !== 1 && dMan.role === 'STUDENT') {
    return c.json({ error: 'Students cannot be assigned to commercial projects', code: 'INVALID_ASSIGNEE_ROLE' }, 400);
  }

  if (dMan.role === 'STUDENT') {
    if (!project.training_module_id || typeof project.training_module_id !== 'string' || !project.training_module_id.trim()) {
      return c.json({ error: 'Training project requires a valid training_module_id before assigning to a student', code: 'MISSING_TRAINING_MODULE' }, 400);
    }
    const moduleExists = await db.prepare('SELECT id FROM training_modules WHERE id = ?').bind(project.training_module_id).first();
    if (!moduleExists) {
      return c.json({ error: 'Referenced training module does not exist', code: 'INVALID_TRAINING_MODULE' }, 400);
    }
  }

  // Authoritative Draughtsman Capacity Cap (SEC-03): Maximum 4 active concurrent projects
  if (dMan.role === 'DRAUGHTSMAN') {
    const activeCountRes = await db.prepare(`
      SELECT COUNT(*) as count
      FROM projects
      WHERE draughtsman_id = ?
        AND status IN ('WAITING_ACCEPTANCE', 'IN_PROGRESS', 'UNDER_ENGINEER_REVIEW', 'UNDER_CLIENT_REVIEW')
    `).bind(draughtsmanId).first();
    const activeCount = (activeCountRes?.count as number) || 0;
    if (activeCount >= 4) {
      return c.json({
        error: 'Draughtsman is at maximum capacity (4/4 active projects)',
        code: 'DRAUGHTSMAN_CAPACITY_EXCEEDED'
      }, 400);
    }
  }

  const assignmentId = uuidv4();
  const assignmentQuery = dMan.role === 'STUDENT'
    ? db.prepare(`INSERT INTO student_assignments (id, project_id, student_id, assignment_type, status) VALUES (?, ?, ?, 'PRACTICAL', 'PENDING')`).bind(assignmentId, projectId, draughtsmanId)
    : db.prepare(`INSERT INTO assignments (id, project_id, draughtsman_id, status) VALUES (?, ?, ?, 'PENDING')`).bind(assignmentId, projectId, draughtsmanId);

  const batch = [
    assignmentQuery,
    db.prepare(`UPDATE projects SET status = 'WAITING_ACCEPTANCE', draughtsman_id = ?, draughtsman_name = ?, current_assignment_id = ?, assigned_at = CURRENT_TIMESTAMP, last_action_id = ?, is_training_project = CASE WHEN ? = 'STUDENT' THEN 1 ELSE is_training_project END WHERE id = ?`).bind(draughtsmanId, dMan.name, assignmentId, actionId, dMan.role, projectId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, projectId, dMan.role === 'STUDENT' ? 'STUDENT_ASSIGNED' : 'DRAUGHTSMAN_ASSIGNED', uid, 'STUDIO_ADMIN', `Studio Admin assigned ${dMan.role === 'STUDENT' ? 'student' : 'draughtsman'}: ` + dMan.name
    ),
    db.prepare(`INSERT INTO notifications (id, user_id, project_id, type, title, message) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      uuidv4(), draughtsmanId, projectId, dMan.role === 'STUDENT' ? 'NEW_ASSIGNMENT' : 'DRAUGHTSMAN_ASSIGNED', 'New Assignment', 'You have been assigned to a new project.'
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
  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) return c.json({ error: 'Only admins can reassign projects' }, 403);

  const dMan = await getUser(db, draughtsmanId);
  if (!dMan || (dMan.role !== 'DRAUGHTSMAN' && dMan.role !== 'STUDENT')) return c.json({ error: 'Invalid user role for reassignment' }, 400);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  if (project.is_training_project === 1 && dMan.role !== 'STUDENT') {
    return c.json({ error: 'Only students can be assigned to training projects', code: 'INVALID_ASSIGNEE_ROLE' }, 400);
  }
  if (project.is_training_project !== 1 && dMan.role === 'STUDENT') {
    return c.json({ error: 'Students cannot be assigned to commercial projects', code: 'INVALID_ASSIGNEE_ROLE' }, 400);
  }

  if (dMan.role === 'STUDENT') {
    if (!project.training_module_id || typeof project.training_module_id !== 'string' || !project.training_module_id.trim()) {
      return c.json({ error: 'Training project requires a valid training_module_id before assigning to a student', code: 'MISSING_TRAINING_MODULE' }, 400);
    }
    const moduleExists = await db.prepare('SELECT id FROM training_modules WHERE id = ?').bind(project.training_module_id).first();
    if (!moduleExists) {
      return c.json({ error: 'Referenced training module does not exist', code: 'INVALID_TRAINING_MODULE' }, 400);
    }
  }

  // Authoritative Draughtsman Capacity Cap (SEC-03): Maximum 4 active concurrent projects
  if (dMan.role === 'DRAUGHTSMAN') {
    const activeCountRes = await db.prepare(`
      SELECT COUNT(*) as count
      FROM projects
      WHERE draughtsman_id = ?
        AND status IN ('WAITING_ACCEPTANCE', 'IN_PROGRESS', 'UNDER_ENGINEER_REVIEW', 'UNDER_CLIENT_REVIEW')
    `).bind(draughtsmanId).first();
    const activeCount = (activeCountRes?.count as number) || 0;
    if (activeCount >= 4) {
      return c.json({
        error: 'Draughtsman is at maximum capacity (4/4 active projects)',
        code: 'DRAUGHTSMAN_CAPACITY_EXCEEDED'
      }, 400);
    }
  }

  if (project.last_action_id === actionId) return c.json({ success: true });

  // Can reassign if waiting acceptance, in progress, or waiting assignment
  if (!['WAITING_ACCEPTANCE', 'IN_PROGRESS', 'WAITING_ASSIGNMENT'].includes(project.status as string)) {
    return c.json({ error: 'Project cannot be reassigned in its current state' }, 400);
  }

  const assignmentId = uuidv4();
  const batch = [];

  if (project.current_assignment_id) {
    if (project.is_training_project === 1) {
      batch.push(db.prepare(`UPDATE student_assignments SET status = 'REPLACED' WHERE id = ? OR project_id = ?`).bind(project.current_assignment_id, projectId));
    } else {
      batch.push(db.prepare(`UPDATE assignments SET status = 'REPLACED', updated_at = CURRENT_TIMESTAMP WHERE id = ?`).bind(project.current_assignment_id));
    }
  }

  if (dMan.role === 'STUDENT') {
    batch.push(db.prepare(`INSERT INTO student_assignments (id, project_id, student_id, assignment_type, status) VALUES (?, ?, ?, 'PRACTICAL', 'PENDING')`).bind(assignmentId, projectId, draughtsmanId));
  } else {
    batch.push(db.prepare(`INSERT INTO assignments (id, project_id, draughtsman_id, status) VALUES (?, ?, ?, 'PENDING')`).bind(assignmentId, projectId, draughtsmanId));
  }
  batch.push(db.prepare(`UPDATE projects SET status = 'WAITING_ACCEPTANCE', draughtsman_id = ?, draughtsman_name = ?, current_assignment_id = ?, assigned_at = CURRENT_TIMESTAMP, last_action_id = ? WHERE id = ?`).bind(draughtsmanId, dMan.name, assignmentId, actionId, projectId));
  batch.push(db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
    actionId, projectId, dMan.role === 'STUDENT' ? 'STUDENT_REASSIGNED' : 'DRAUGHTSMAN_REASSIGNED', uid, 'STUDIO_ADMIN', `Studio Admin reassigned to ${dMan.role === 'STUDENT' ? 'student' : 'draughtsman'}: ` + dMan.name
  ));

  await db.batch(batch);
  return c.json({ success: true, assignmentId });
});

const handleAcceptAssignment = async (c: any) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const body = await c.req.json().catch(() => ({}));
  let { assignmentId, projectId, actionId } = body;
  if (!actionId) actionId = uuidv4();

  const user = await getUser(db, uid);
  if (!user || (user.role !== 'DRAUGHTSMAN' && user.role !== 'STUDENT')) return c.json({ error: 'Only draughtsmen or students can accept assignments' }, 403);

  if (!projectId && assignmentId) {
    const aRec = await db.prepare(`
      SELECT project_id FROM assignments WHERE id = ? OR project_id = ?
      UNION
      SELECT project_id FROM student_assignments WHERE id = ? OR project_id = ?
      UNION
      SELECT id as project_id FROM projects WHERE id = ?
      LIMIT 1
    `).bind(assignmentId, assignmentId, assignmentId, assignmentId, assignmentId).first();
    if (aRec && aRec.project_id) projectId = aRec.project_id;
  }

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  if (project.status === 'IN_PROGRESS' && project.last_action_id === actionId) return c.json({ success: true });

  if (project.status !== 'WAITING_ACCEPTANCE') return c.json({ error: 'Project is not in WAITING_ACCEPTANCE state' }, 400);

  const effectiveAssignmentId = assignmentId || project.current_assignment_id;
  let assignment: any;
  let updateAssignmentQuery;

  if (user.role === 'STUDENT') {
    if (project.is_training_project !== 1) return c.json({ error: 'Forbidden: Students cannot access commercial projects' }, 403);
    assignment = await db.prepare("SELECT * FROM student_assignments WHERE (id = ? OR project_id = ?) AND student_id = ? AND status != 'REPLACED' ORDER BY created_at DESC").bind(effectiveAssignmentId, projectId, uid).first();
    if (!assignment) return c.json({ error: 'Not assigned to you' }, 403);
    if (assignment.project_id !== projectId) return c.json({ error: 'Assignment does not match project' }, 400);
    if (assignment.status !== 'PENDING') return c.json({ error: 'Assignment is not PENDING' }, 400);
    updateAssignmentQuery = db.prepare(`UPDATE student_assignments SET status = 'ACCEPTED' WHERE id = ?`).bind(assignment.id);
  } else {
    if (project.is_training_project === 1) return c.json({ error: 'Commercial draughtsmen cannot accept training projects' }, 403);
    if (effectiveAssignmentId && project.current_assignment_id !== effectiveAssignmentId) return c.json({ error: 'Not the current assignment' }, 400);
    if (project.draughtsman_id !== uid) return c.json({ error: 'Not assigned to you' }, 403);
    assignment = await db.prepare('SELECT * FROM assignments WHERE (id = ? OR project_id = ?) AND draughtsman_id = ?').bind(effectiveAssignmentId, projectId, uid).first();
    if (!assignment) return c.json({ error: 'Assignment not found' }, 404);
    if (assignment.draughtsman_id !== uid || assignment.project_id !== projectId) return c.json({ error: 'Not assigned to you' }, 403);
    if (assignment.status !== 'PENDING') return c.json({ error: 'Assignment is not PENDING' }, 400);
    updateAssignmentQuery = db.prepare(`UPDATE assignments SET status = 'ACCEPTED', updated_at = CURRENT_TIMESTAMP WHERE id = ?`).bind(assignment.id);
  }

  const actualAssignmentId = assignment.id;
  const batch = [
    updateAssignmentQuery,
    db.prepare(`UPDATE projects SET status = 'IN_PROGRESS', draughtsman_id = COALESCE(draughtsman_id, ?), current_assignment_id = COALESCE(current_assignment_id, ?), last_action_id = ? WHERE id = ?`).bind(uid, actualAssignmentId, actionId, projectId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, projectId, 'ASSIGNMENT_ACCEPTED', uid, user.role, 'User accepted the assignment.'
    ),
    db.prepare(`INSERT INTO notifications (id, user_id, project_id, type, title, message) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      uuidv4(), project.client_id, projectId, 'ASSIGNMENT_ACCEPTED', 'Project In Progress', 'A draughtsman has accepted and started your project.'
    )
  ];
  await db.batch(batch);
  return c.json({ success: true });
};

const handleRejectAssignment = async (c: any) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const body = await c.req.json().catch(() => ({}));
  let { assignmentId, actionId, projectId, reason } = body;

  const user = await getUser(db, uid);
  if (!user || user.role !== 'DRAUGHTSMAN') return c.json({ error: 'Only draughtsmen can reject assignments' }, 403);

  let assignment: any;
  if (assignmentId) {
    assignment = await db.prepare('SELECT * FROM assignments WHERE id = ?').bind(assignmentId).first();
  } else if (projectId) {
    assignment = await db.prepare("SELECT * FROM assignments WHERE project_id = ? AND draughtsman_id = ? AND status = 'PENDING'").bind(projectId, uid).first();
  }

  if (!assignment) return c.json({ error: 'Assignment not found' }, 404);
  if (assignment.status !== 'PENDING') return c.json({ error: 'Assignment is not PENDING' }, 400);

  if (!projectId) {
    projectId = assignment.project_id;
  }

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);
  if (project.status === 'WAITING_ASSIGNMENT' && project.last_action_id === actionId) return c.json({ success: true });

  if (project.current_assignment_id && project.current_assignment_id !== assignment.id) return c.json({ error: 'Not the current assignment' }, 400);
  if (project.draughtsman_id !== uid) return c.json({ error: 'Not assigned to you' }, 403);
  if (project.status !== 'WAITING_ACCEPTANCE') return c.json({ error: 'Project is not in WAITING_ACCEPTANCE state' }, 400);

  const effectiveActionId = actionId || uuidv4();

  const batch = [
    db.prepare(`UPDATE assignments SET status = 'REJECTED', updated_at = CURRENT_TIMESTAMP WHERE id = ?`).bind(assignment.id),
    db.prepare(`UPDATE projects SET status = 'WAITING_ASSIGNMENT', draughtsman_id = NULL, draughtsman_name = NULL, current_assignment_id = NULL, last_action_id = ? WHERE id = ?`).bind(effectiveActionId, projectId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      effectiveActionId, projectId, 'ASSIGNMENT_REJECTED', uid, 'DRAUGHTSMAN', reason ? `Draughtsman rejected the assignment: ${reason}` : 'Draughtsman rejected the assignment.'
    )
  ];
  await db.batch(batch);
  return c.json({ success: true });
};

// Authoritative routes + backward compatibility aliases
app.post('/api/assignments/accept', handleAcceptAssignment);
app.post('/api/projects/accept', handleAcceptAssignment);
app.post('/api/assignments/reject', handleRejectAssignment);
app.post('/api/projects/reject-assignment', handleRejectAssignment);

app.get('/api/assignments', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user) return c.json({ error: 'User not found' }, 404);
  if (user.role !== 'DRAUGHTSMAN' && user.role !== 'STUDIO_ADMIN' && user.role !== 'ADMIN') return c.json({ error: 'Forbidden' }, 403);

  if (user.role === 'STUDIO_ADMIN' || user.role === 'ADMIN') {
    const { results } = await db.prepare('SELECT * FROM assignments ORDER BY created_at DESC').all();
    return c.json(results);
  }

  const { results } = await db.prepare(`
    SELECT 
      a.id, a.project_id, a.draughtsman_id, a.status, a.created_at, a.updated_at,
      p.project_name, p.project_address, p.drawing_name, p.drawing_type,
      p.project_area, p.status as project_status, p.correction_round,
      p.submitted_at, p.approved_at, p.assigned_at, p.rejected_at, p.cancelled_at
    FROM assignments a
    LEFT JOIN projects p ON a.project_id = p.id
    WHERE a.draughtsman_id = ?
    ORDER BY a.created_at DESC
  `).bind(uid).all();

  return c.json(results);
});

app.get('/api/assignments/:id', async (c) => {
  const uid = c.get('uid');
  const assignmentId = c.req.param('id');
  const db = c.env.DB;

  const user = await getUser(db, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);

  const assignment = await db.prepare(`
    SELECT
      a.id, a.project_id, a.draughtsman_id, a.status, a.created_at, a.updated_at,
      p.client_id, p.project_name, p.project_address, p.drawing_name, p.drawing_type,
      p.project_area, p.status as project_status, p.correction_round,
      p.submitted_at, p.approved_at, p.assigned_at, p.rejected_at, p.cancelled_at
    FROM assignments a
    LEFT JOIN projects p ON a.project_id = p.id
    WHERE a.id = ? OR a.project_id = ?
    ORDER BY (CASE WHEN a.id = ? THEN 1 ELSE 2 END), a.created_at DESC
    LIMIT 1
  `).bind(assignmentId, assignmentId, assignmentId).first();

  if (!assignment) return c.json({ error: 'Assignment not found' }, 404);

  // Strict role and ownership authorization:
  // - Admins can view any assignment.
  // - Assigned Draughtsman can view their own assignment.
  // - Owning Engineer/Client can view assignment for their project.
  // - Students and unrelated Draughtsmen/Engineers are strictly denied.
  const isAdmin = ['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string);
  const isAssignedDraughtsman = user.role === 'DRAUGHTSMAN' && assignment.draughtsman_id === uid;
  const isProjectOwner = (user.role === 'ENGINEER' || user.role === 'CLIENT') && assignment.client_id === uid;

  if (!isAdmin && !isAssignedDraughtsman && !isProjectOwner) {
    return c.json({ error: 'Forbidden: Access to assignment denied' }, 403);
  }

  return c.json(assignment);
});

app.get('/api/draughtsman/summary', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;

  const user = await getUser(db, uid);
  if (!user || user.role !== 'DRAUGHTSMAN') return c.json({ error: 'Forbidden' }, 403);

  const summary = await db.prepare(`
    SELECT
      COUNT(*) as total_assignments,
      SUM(CASE WHEN a.status = 'PENDING' THEN 1 ELSE 0 END) as pending,
      SUM(CASE WHEN a.status = 'ACCEPTED' AND (p.status = 'IN_PROGRESS' OR p.status IS NULL) AND (p.correction_round IS NULL OR p.correction_round = 0) THEN 1 ELSE 0 END) as in_progress,
      SUM(CASE WHEN p.status IN ('UNDER_ENGINEER_REVIEW', 'UNDER_CLIENT_REVIEW') THEN 1 ELSE 0 END) as under_review,
      SUM(CASE WHEN a.status = 'ACCEPTED' AND p.correction_round > 0 THEN 1 ELSE 0 END) as corrections,
      SUM(CASE WHEN a.status = 'COMPLETED' OR p.status = 'COMPLETED' THEN 1 ELSE 0 END) as completed
    FROM assignments a
    LEFT JOIN projects p ON a.project_id = p.id
    WHERE a.draughtsman_id = ?
  `).bind(uid).first();

  const total = (summary?.total_assignments as number) || 0;
  const pending = (summary?.pending as number) || 0;
  const inProgress = (summary?.in_progress as number) || 0;
  const underReview = (summary?.under_review as number) || 0;
  const corrections = (summary?.corrections as number) || 0;
  const completed = (summary?.completed as number) || 0;
  const activeCount = inProgress + underReview + corrections;

  return c.json({
    total_assignments: total,
    pending,
    in_progress: inProgress,
    under_review: underReview,
    corrections,
    completed,
    activeCount,
    completedCount: completed,
  });
});

// ==========================================
// ADMIN DASHBOARD
// ==========================================

app.get('/api/admin/dashboard', async (c) => {

  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) return c.json({ error: 'Forbidden' }, 403);

  const batch = [
    db.prepare('SELECT COUNT(*) as c FROM projects'),
    db.prepare("SELECT COUNT(*) as c FROM projects WHERE status IN ('IN_PROGRESS', 'WAITING_ACCEPTANCE', 'UNDER_ENGINEER_REVIEW', 'UNDER_CLIENT_REVIEW')"),
    db.prepare("SELECT COUNT(*) as c FROM projects WHERE status = 'WAITING_ASSIGNMENT'"),
    db.prepare("SELECT COUNT(*) as c FROM projects WHERE status IN ('UNDER_ENGINEER_REVIEW', 'UNDER_CLIENT_REVIEW')"),
    db.prepare("SELECT COUNT(*) as c FROM projects WHERE status = 'COMPLETED'"),
    db.prepare("SELECT COUNT(*) as c FROM users WHERE role = 'DRAUGHTSMAN'"),
    db.prepare("SELECT COUNT(*) as c FROM assignments WHERE status = 'PENDING'"),
    db.prepare("SELECT COUNT(DISTINCT id) as c FROM users WHERE role IN ('ENGINEER', 'CLIENT')")
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
    registeredEngineers: (results[7].results?.[0] as any)?.c || 0,
    activeEngineers: (results[7].results?.[0] as any)?.c || 0,
  });
});

app.get('/api/admin/student-submissions', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);
  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) {
    return c.json({ error: 'Forbidden: Admin access required', code: 'FORBIDDEN' }, 403);
  }

  const status = c.req.query('status');
  let query = `
    SELECT 
      p.id,
      p.project_name,
      p.drawing_name,
      p.drawing_type,
      p.status,
      p.correction_round,
      p.created_at,
      p.submitted_at,
      p.training_module_id,
      p.rejection_reason,
      sa.student_id,
      u.name as student_name,
      u.email as student_email,
      tm.title as module_title,
      (SELECT id FROM drawing_versions WHERE project_id = p.id ORDER BY version_number DESC LIMIT 1) as latest_drawing_version_id,
      (SELECT version_number FROM drawing_versions WHERE project_id = p.id ORDER BY version_number DESC LIMIT 1) as latest_version_number,
      (SELECT file_id FROM drawing_versions WHERE project_id = p.id ORDER BY version_number DESC LIMIT 1) as latest_file_id
    FROM projects p
    JOIN student_assignments sa ON p.id = sa.project_id AND sa.status != 'REPLACED'
    LEFT JOIN users u ON sa.student_id = u.id
    LEFT JOIN training_modules tm ON p.training_module_id = tm.id
    WHERE p.is_training_project = 1
  `;
  const params: any[] = [];
  if (status) {
    if (status === 'UNDER_ENGINEER_REVIEW' || status === 'UNDER_CLIENT_REVIEW') {
      query += ` AND (p.status = 'UNDER_ENGINEER_REVIEW' OR p.status = 'UNDER_CLIENT_REVIEW')`;
    } else {
      query += ` AND p.status = ?`;
      params.push(status);
    }
  }
  query += ` ORDER BY p.created_at DESC`;

  const { results } = await db.prepare(query).bind(...params).all();
  return c.json(results || []);
});

app.get('/api/admin/students/:studentId', async (c) => {
  const uid = c.get('uid');
  const studentId = c.req.param('studentId');
  const db = c.env.DB;
  const user = await getUser(db, uid);
  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) {
    return c.json({ error: 'Forbidden: Admin access required', code: 'FORBIDDEN' }, 403);
  }

  const student = await getUser(db, studentId);
  if (!student) return c.json({ error: 'Student not found', code: 'NOT_FOUND' }, 404);

  const safeProfile = {
    id: student.id,
    name: student.name,
    email: student.email,
    role: student.role,
    phone: student.phone,
    company: student.company,
    bio: student.bio,
    created_at: student.created_at,
  };

  const { results: assignments } = await db.prepare(`
    SELECT p.id, p.project_name, p.status, p.correction_round, sa.created_at as assigned_at
    FROM student_assignments sa
    JOIN projects p ON sa.project_id = p.id
    WHERE sa.student_id = ? AND sa.status != 'REPLACED'
    ORDER BY sa.created_at DESC
  `).bind(studentId).all();

  const { results: credentials } = await db.prepare(`
    SELECT id, type, title, description, issued_at, verification_token
    FROM student_credentials
    WHERE student_id = ?
    ORDER BY issued_at DESC
  `).bind(studentId).all();

  return c.json({
    profile: safeProfile,
    assignments: assignments || [],
    credentials: credentials || [],
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
  const hasAccess = await canUserAccessProject(db, project, user, uid);
  if (!hasAccess) return c.json({ error: 'Forbidden: Workspace access denied' }, 403);

  const { results } = await db.prepare("SELECT * FROM files WHERE project_id = ? AND status != 'FAILED' ORDER BY created_at DESC").bind(projectId).all();
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

  // Apply canonical project authorization rules for reading evaluations
  const hasAccess = await canUserAccessProject(db, project, user, uid);
  if (!hasAccess) return c.json({ error: 'Forbidden: Access to evaluations denied' }, 403);

  const { results } = await db.prepare('SELECT * FROM evaluations WHERE project_id = ? ORDER BY created_at DESC').bind(projectId).all();
  return c.json(results);
});


function buildApproveFinalBatch(
  db: D1Database,
  project: any,
  uid: string,
  actionId: string,
  role: string,
  studentId: string | null
) {
  const targetRecipient = studentId || project.draughtsman_id;
  const batch: any[] = [
    db.prepare(`UPDATE projects SET status = 'COMPLETED', approved_at = CURRENT_TIMESTAMP, last_action_id = ? WHERE id = ?`).bind(actionId, project.id),
    db.prepare(`UPDATE assignments SET status = 'COMPLETED', updated_at = CURRENT_TIMESTAMP WHERE project_id = ? AND status = 'ACCEPTED'`).bind(project.id),
    db.prepare(`UPDATE student_assignments SET status = 'COMPLETED' WHERE project_id = ? AND status = 'ACCEPTED'`).bind(project.id),
    db.prepare(`UPDATE corrections SET status = 'RESOLVED', resolved_at = CURRENT_TIMESTAMP WHERE project_id = ? AND status IN ('OPEN', 'IN_PROGRESS')`).bind(project.id),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, project.id, 'PROJECT_COMPLETED', uid, role, 'Approved the final drawing.'
    )
  ];
  if (targetRecipient) {
    batch.push(
      db.prepare(`INSERT INTO notifications (id, user_id, project_id, type, title, message) VALUES (?, ?, ?, ?, ?, ?)`).bind(
        uuidv4(), targetRecipient, project.id, 'PROJECT_COMPLETED', 'Project Approved', 'The final drawing has been approved.'
      )
    );
  }
  return batch;
}

function buildRequestCorrectionBatch(
  db: D1Database,
  project: any,
  uid: string,
  actionId: string,
  correctionId: string,
  targetVersionId: string,
  newRound: number,
  description: string,
  role: string,
  studentId: string | null
) {
  const targetRecipient = studentId || project.draughtsman_id;
  const batch: any[] = [
    db.prepare(`
      INSERT INTO corrections (id, project_id, requested_by, target_version_id, round_number, description, status)
      VALUES (?, ?, ?, ?, ?, ?, 'OPEN')
    `).bind(correctionId, project.id, uid, targetVersionId, newRound, description),
    db.prepare(`UPDATE projects SET status = 'IN_PROGRESS', correction_round = ?, last_action_id = ? WHERE id = ?`).bind(newRound, actionId, project.id),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, project.id, 'CORRECTION_REQUESTED', uid, role, `Reviewer requested correction (Round ${newRound}).`
    )
  ];
  if (targetRecipient) {
    batch.push(
      db.prepare(`INSERT INTO notifications (id, user_id, project_id, type, title, message) VALUES (?, ?, ?, ?, ?, ?)`).bind(
        uuidv4(), targetRecipient, project.id, 'CORRECTION_REQUESTED', 'Correction Requested', `A revision has been requested (Round ${newRound}).`
      )
    );
  }
  return batch;
}

app.post('/api/projects/evaluate', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const body = await c.req.json();
  const { projectId, actionId, drawingVersionId, overallResult, generalFeedback, criteriaJson, correctionId } = body;
  const actualActionId = actionId || uuidv4();

  const user = await getUser(db, uid);
  if (!user || (user.role !== 'CLIENT' && user.role !== 'ENGINEER' && user.role !== 'STUDIO_ADMIN' && user.role !== 'ADMIN')) {
    return c.json({ error: 'Only clients, engineers or admins can evaluate drawings' }, 403);
  }

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  if (project.is_training_project === 1) {
    if (user.role !== 'STUDIO_ADMIN' && user.role !== 'ADMIN') {
      return c.json({ error: 'Only administrators can evaluate student training projects', code: 'FORBIDDEN' }, 403);
    }
  } else {
    if ((user.role === 'CLIENT' || user.role === 'ENGINEER') && project.client_id !== uid) {
      return c.json({ error: 'Permission denied: Cannot evaluate a project you do not own' }, 403);
    }
  }

  // Idempotency: if request was already processed with this actionId
  if (project.last_action_id === actionId) {
    return c.json({ success: true });
  }

  if (project.status !== 'UNDER_ENGINEER_REVIEW' && project.status !== 'UNDER_CLIENT_REVIEW') return c.json({ error: 'Project is not under review' }, 400);

  const drawingVersion = await db.prepare('SELECT * FROM drawing_versions WHERE id = ?').bind(drawingVersionId).first();
  if (!drawingVersion) return c.json({ error: 'Drawing version not found' }, 404);
  if (drawingVersion.project_id !== projectId) return c.json({ error: 'Drawing version does not belong to this project' }, 400);

  let studentId: string | null = null;
  if (project.is_training_project === 1) {
    const authorId = drawingVersion.uploaded_by as string;
    if (!authorId) {
      return c.json({ error: 'Evaluated drawing version does not have a recorded author', code: 'INVALID_AUTHOR' }, 400);
    }
    const isAssigned = await verifyStudentAssignment(db, authorId, project.id as string);
    if (!isAssigned) {
      return c.json({ error: 'Drawing version author is not assigned to this training project', code: 'UNAUTHORIZED_AUTHOR' }, 403);
    }
    studentId = authorId;
  }

  let normalizedResult = overallResult;
  if (normalizedResult === 'CORRECTION_REQUIRED') {
    normalizedResult = 'NEEDS_CORRECTION';
  }

  if (normalizedResult !== 'APPROVED' && normalizedResult !== 'NEEDS_CORRECTION' && normalizedResult !== 'REJECTED') {
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
    `).bind(evaluationId, projectId, drawingVersionId, uid, normalizedResult, generalFeedback, criteriaString)
  ];

  if (normalizedResult === 'APPROVED') {
    // Verify approval of an older drawing version cannot mark a project completed when a newer version exists
    const latestVersion = await db.prepare(
      'SELECT id, version_number FROM drawing_versions WHERE project_id = ? ORDER BY version_number DESC LIMIT 1'
    ).bind(projectId).first();

    if (latestVersion && latestVersion.id !== drawingVersionId && (latestVersion.version_number as number) > (drawingVersion.version_number as number)) {
      return c.json({
        error: 'Cannot mark project completed by approving an older drawing version when a newer revision exists requiring review',
        code: 'OLDER_VERSION_APPROVAL'
      }, 400);
    }

    batch = batch.concat(buildApproveFinalBatch(db, project, uid, actualActionId, user.role, studentId));

    // Synchronize training module progress and credential
    if (project.is_training_project === 1 && studentId && project.training_module_id) {
      const moduleId = project.training_module_id;
      const lessonsCountResult: any = await db.prepare(
        'SELECT count(*) as count FROM training_lessons WHERE module_id = ?'
      ).bind(moduleId).first();
      const totalLessons = (lessonsCountResult?.count as number) || 0;

      let allLessonsCompleted = true;
      if (totalLessons > 0) {
        const completedLessonsResult: any = await db.prepare(`
          SELECT count(*) as count
          FROM training_lessons l
          JOIN student_lesson_progress slp ON slp.lesson_id = l.id AND slp.student_id = ?
          WHERE l.module_id = ? AND slp.status = 'COMPLETED'
        `).bind(studentId, moduleId).first();
        const completedLessons = (completedLessonsResult?.count as number) || 0;
        allLessonsCompleted = completedLessons === totalLessons;
      }

      if (totalLessons === 0 || allLessonsCompleted) {
        const moduleDetails: any = await db.prepare('SELECT title FROM training_modules WHERE id = ?').bind(moduleId).first();
        const moduleTitle = moduleDetails?.title || 'Unknown Module';

        batch.push(
          db.prepare(`
            INSERT INTO student_credentials (id, student_id, type, reference_id, title, description, issued_at)
            VALUES (?, ?, 'MODULE_COMPLETION', ?, ?, ?, CURRENT_TIMESTAMP)
            ON CONFLICT(student_id, type, reference_id) DO NOTHING
          `).bind(
            uuidv4(),
            studentId,
            moduleId,
            'Module Certification',
            `Completed the training module: ${moduleTitle}`
          )
        );

        batch.push(
          db.prepare(`
            INSERT INTO student_progress (id, student_id, module_id, status, score, updated_at)
            VALUES (?, ?, ?, 'Completed', 100, CURRENT_TIMESTAMP)
            ON CONFLICT(student_id, module_id) DO UPDATE SET
              status = 'Completed',
              score = 100,
              updated_at = CURRENT_TIMESTAMP
          `).bind(uuidv4(), studentId, moduleId)
        );
      } else {
        batch.push(
          db.prepare(`
            INSERT INTO student_progress (id, student_id, module_id, status, score, updated_at)
            VALUES (?, ?, ?, 'In Progress', 50, CURRENT_TIMESTAMP)
            ON CONFLICT(student_id, module_id) DO UPDATE SET
              status = 'In Progress',
              updated_at = CURRENT_TIMESTAMP
          `).bind(uuidv4(), studentId, moduleId)
        );
      }
    }
  } else if (normalizedResult === 'NEEDS_CORRECTION') {
    const currentRound = (project.correction_round as number) || 0;
    if (currentRound >= 3) {
      return c.json({ error: 'Maximum correction rounds (3) exceeded' }, 400);
    }
    const newRound = currentRound + 1;
    // For evaluating needs_correction, we create a correction atomically.
    batch = batch.concat(buildRequestCorrectionBatch(db, project, uid, actualActionId, correctionId || uuidv4(), drawingVersionId, newRound, generalFeedback || 'Correction needed based on evaluation.', user.role, studentId));
  } else if (normalizedResult === 'REJECTED') {
    const targetRecipient = studentId || project.draughtsman_id;
    batch.push(
      db.prepare(`UPDATE projects SET status = 'CANCELLED', rejection_reason = ?, last_action_id = ? WHERE id = ?`).bind(
        generalFeedback || 'Reviewer rejected submission.',
        actualActionId,
        projectId
      ),
      db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
        actualActionId, projectId, 'PROJECT_REJECTED', uid, user.role, 'Reviewer rejected submission. Reason: ' + (generalFeedback || 'Rejected')
      )
    );
    if (targetRecipient) {
      batch.push(
        db.prepare(`INSERT INTO notifications (id, user_id, project_id, type, title, message) VALUES (?, ?, ?, ?, ?, ?)`).bind(
          uuidv4(), targetRecipient, projectId, 'PROJECT_REJECTED', 'Submission Rejected', generalFeedback || 'Your submission has been rejected.'
        )
      );
    }
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

  const hasAccess = await canUserAccessProject(db, project, user, uid);
  if (!hasAccess) return c.json({ error: 'Forbidden: Workspace access denied' }, 403);

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

  const hasAccess = await canUserAccessProject(db, project, user, uid);
  if (!hasAccess) return c.json({ error: 'Forbidden: Workspace access denied' }, 403);

  const { results } = await db.prepare('SELECT * FROM corrections WHERE project_id = ? ORDER BY round_number DESC').bind(projectId).all();
  return c.json(results);
});

// Start / Accept a Correction Round
app.post('/api/projects/:projectId/corrections/:correctionId/start', async (c) => {
  const uid = c.get('uid');
  const projectId = c.req.param('projectId');
  const correctionId = c.req.param('correctionId');
  const db = c.env.DB;

  const user = await getUser(db, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);

  const allowedRoles = ['DRAUGHTSMAN', 'STUDENT', 'STUDIO_ADMIN', 'ADMIN'];
  if (!allowedRoles.includes(user.role as string)) {
    return c.json({ error: 'Forbidden: Only assigned draughtsman, student, or admin can start a correction round' }, 403);
  }

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  const hasAccess = await canUserAccessProject(db, project, user, uid);
  if (!hasAccess) {
    return c.json({ error: 'Forbidden: Workspace access denied' }, 403);
  }

  const correction = await db.prepare(
    'SELECT * FROM corrections WHERE id = ? AND project_id = ?'
  ).bind(correctionId, projectId).first();

  if (!correction) {
    return c.json({ error: 'Correction not found for this project' }, 404);
  }

  const body = await c.req.json().catch(() => ({}));
  const actionId = body.actionId || uuidv4();

  // Idempotency: If already in progress, return success without duplicate logs or errors
  if (correction.status === 'IN_PROGRESS') {
    return c.json({ success: true, correctionId, status: 'IN_PROGRESS' });
  }

  if (correction.status === 'RESOLVED') {
    return c.json({ error: 'Correction round has already been resolved' }, 400);
  }

  if (correction.status !== 'OPEN') {
    return c.json({ error: 'Correction is not in an open state' }, 400);
  }

  const batch = [
    db.prepare(`UPDATE corrections SET status = 'IN_PROGRESS' WHERE id = ?`).bind(correctionId),
    db.prepare(`UPDATE projects SET status = 'IN_PROGRESS', last_action_id = ? WHERE id = ?`).bind(actionId, projectId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId, projectId, 'CORRECTION_STARTED', uid, user.role,
      `${['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string) ? 'Studio Admin' : (user.role === 'STUDENT' ? 'Student' : 'Draughtsman')} started working on correction (Round ${correction.round_number}).`
    )
  ];
  await db.batch(batch);

  return c.json({ success: true, correctionId, status: 'IN_PROGRESS' });
});

// Project Messages (Collaboration Hub)
app.get('/api/projects/:projectId/messages', async (c) => {
  const uid = c.get('uid');
  const projectId = c.req.param('projectId');

  const db = c.env.DB;
  const user = await getUser(db, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  const isEngineer = (user.role === 'ENGINEER' || user.role === 'CLIENT') && project.client_id === uid;
  let isDraughtsman = false;
  if (user.role === 'DRAUGHTSMAN' && project.draughtsman_id === uid) {
    const assignment = await db.prepare(
      'SELECT status FROM assignments WHERE project_id = ? AND draughtsman_id = ? ORDER BY created_at DESC LIMIT 1'
    ).bind(projectId, uid).first();
    isDraughtsman = assignment?.status === 'ACCEPTED' || assignment?.status === 'COMPLETED';
  }
  const isAdmin = ['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string);
  if (!isEngineer && !isDraughtsman && !isAdmin) {
    return c.json({ error: 'Forbidden' }, 403);
  }

  const { results } = await db.prepare(`
    SELECT
      m.id,
      m.project_id,
      m.sender_id,
      m.sender_name,
      m.sender_role,
      m.message,
      m.attachment_file_id,
      m.created_at,
      f.original_name AS attachment_name,
      f.size AS attachment_size,
      f.content_type AS attachment_content_type
    FROM project_messages m
    LEFT JOIN files f ON m.attachment_file_id = f.id
    WHERE m.project_id = ?
    ORDER BY m.created_at ASC
  `).bind(projectId).all();

  return c.json(results || []);
});

app.post('/api/projects/:projectId/messages', async (c) => {
  const uid = c.get('uid');
  const projectId = c.req.param('projectId');

  const db = c.env.DB;
  const user = await getUser(db, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  const isEngineer = (user.role === 'ENGINEER' || user.role === 'CLIENT') && project.client_id === uid;
  let isDraughtsman = false;
  if (user.role === 'DRAUGHTSMAN' && project.draughtsman_id === uid) {
    const assignment = await db.prepare(
      'SELECT status FROM assignments WHERE project_id = ? AND draughtsman_id = ? ORDER BY created_at DESC LIMIT 1'
    ).bind(projectId, uid).first();
    isDraughtsman = assignment?.status === 'ACCEPTED' || assignment?.status === 'COMPLETED';
  }
  const isAdmin = ['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string);
  if (!isEngineer && !isDraughtsman && !isAdmin) {
    return c.json({ error: 'Forbidden' }, 403);
  }

  const body = await c.req.json().catch(() => ({}));
  const rawMessage = typeof body.message === 'string' ? body.message.trim() : '';
  const attachmentFileId = typeof body.attachment_file_id === 'string' && body.attachment_file_id.trim().length > 0
    ? body.attachment_file_id.trim()
    : null;

  if (rawMessage.length === 0 && !attachmentFileId) {
    return c.json({ error: 'Message content or attachment is required' }, 400);
  }

  let attachedFile: any = null;
  if (attachmentFileId) {
    attachedFile = await db.prepare('SELECT * FROM files WHERE id = ? AND project_id = ?').bind(attachmentFileId, projectId).first();
    if (!attachedFile) {
      return c.json({ error: 'Attachment file not found' }, 404);
    }
  }

  const id = crypto.randomUUID();
  const senderName = (user.name as string) || (isEngineer ? 'Engineer' : 'Draughtsman');
  const senderRole = user.role === 'CLIENT' ? 'ENGINEER' : (user.role as string || 'ENGINEER');

  await db.prepare(`
    INSERT INTO project_messages (id, project_id, sender_id, sender_name, sender_role, message, attachment_file_id)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `).bind(id, projectId, uid, senderName, senderRole, rawMessage, attachmentFileId).run();

  // Notification handling
  let targetUserId: string | null = null;
  if (isEngineer) {
    if (project.draughtsman_id) {
      targetUserId = project.draughtsman_id as string;
    }
  } else if (isDraughtsman) {
    targetUserId = project.client_id as string;
  }

  if (targetUserId) {
    const notifId = crypto.randomUUID();
    const notifTitle = `New message on ${project.project_name || 'Project'}`;
    const snippet = rawMessage.length > 80 ? `${rawMessage.substring(0, 80)}...` : rawMessage;
    let notifMsg = snippet;
    if (!notifMsg) {
      if (attachedFile) {
        const ct = (attachedFile.content_type as string) || '';
        const name = ((attachedFile.original_name as string) || '').toLowerCase();
        const isVoice = ct.startsWith('audio/') || ['.webm', '.m4a', '.mp3', '.wav', '.aac', '.ogg'].some(ext => name.endsWith(ext));
        notifMsg = isVoice ? 'Sent a voice message' : 'Sent an attachment';
      } else {
        notifMsg = 'New message';
      }
    }
    await db.prepare(`
      INSERT INTO notifications (id, user_id, project_id, type, title, message)
      VALUES (?, ?, ?, 'CHAT_MESSAGE', ?, ?)
    `).bind(notifId, targetUserId, projectId, notifTitle, notifMsg).run();
  }

  const createdMessage = await db.prepare(`
    SELECT
      m.id,
      m.project_id,
      m.sender_id,
      m.sender_name,
      m.sender_role,
      m.message,
      m.attachment_file_id,
      m.created_at,
      f.original_name AS attachment_name,
      f.size AS attachment_size,
      f.content_type AS attachment_content_type
    FROM project_messages m
    LEFT JOIN files f ON m.attachment_file_id = f.id
    WHERE m.id = ?
  `).bind(id).first();

  return c.json(createdMessage, 201);
});

// ==========================================
// COLLABORATION HUB ADAPTER (ADMIN & MOBILE UNIFICATION)
// ==========================================

app.get('/api/projects/:projectId/comments', async (c) => {
  const uid = c.get('uid');
  const projectId = c.req.param('projectId');
  const db = c.env.DB;

  const user = await getUser(db, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  const hasAccess = await canUserAccessProject(db, project, user, uid);
  if (!hasAccess) return c.json({ error: 'Forbidden: Access to comments denied' }, 403);

  const { results } = await db.prepare(`
    SELECT
      m.id,
      m.project_id,
      m.sender_id AS author_id,
      m.sender_name AS author_name,
      m.sender_role AS author_role,
      m.message AS content,
      m.attachment_file_id,
      f.original_name AS attachment_name,
      CAST(f.size AS TEXT) AS attachment_size,
      f.content_type AS attachment_type,
      m.created_at
    FROM project_messages m
    LEFT JOIN files f ON m.attachment_file_id = f.id
    WHERE m.project_id = ?
    ORDER BY m.created_at ASC
  `).bind(projectId).all();

  return c.json(results || []);
});

app.post('/api/projects/:projectId/comments', async (c) => {
  const uid = c.get('uid');
  const projectId = c.req.param('projectId');
  const db = c.env.DB;

  const user = await getUser(db, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  const hasAccess = await canUserAccessProject(db, project, user, uid);
  if (!hasAccess) return c.json({ error: 'Forbidden: Access to comments denied' }, 403);

  const body = await c.req.json().catch(() => ({}));
  const content = (typeof body.content === 'string' ? body.content : typeof body.message === 'string' ? body.message : '').trim();
  const rawAttachmentFileId = body.attachment_file_id || body.attachmentFileId;
  let attachmentFileId: string | null = null;
  let trustedAttachment: any = null;

  if (typeof rawAttachmentFileId === 'string' && rawAttachmentFileId.trim().length > 0) {
    trustedAttachment = await db.prepare(
      "SELECT id, original_name, size, content_type FROM files WHERE id = ? AND project_id = ? AND status = 'COMPLETED'"
    ).bind(rawAttachmentFileId.trim(), projectId).first();

    if (!trustedAttachment) {
      return c.json({ error: 'Invalid attachment_file_id: file not found or upload not completed', code: 'INVALID_ATTACHMENT' }, 400);
    }
    attachmentFileId = trustedAttachment.id;
  }

  if (!content && !attachmentFileId) {
    return c.json({ error: 'Comment content or valid attachment is required' }, 400);
  }

  const id = crypto.randomUUID();
  const authorName = (user.name as string) || (['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string) ? 'Studio Admin' : user.role === 'CLIENT' || user.role === 'ENGINEER' ? 'Engineer' : 'Draughtsman');
  const authorRole = user.role === 'CLIENT' ? 'CLIENT' : user.role;

  // Insert into authoritative project_messages table with validated attachment reference
  await db.prepare(`
    INSERT INTO project_messages (id, project_id, sender_id, sender_name, sender_role, message, attachment_file_id)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `).bind(id, projectId, uid, authorName, authorRole, content, attachmentFileId).run();

  const commentRecord = {
    id,
    project_id: projectId,
    author_id: uid,
    author_name: authorName,
    author_role: authorRole,
    content,
    attachment_file_id: attachmentFileId,
    attachment_name: trustedAttachment?.original_name || null,
    attachment_size: trustedAttachment?.size != null ? String(trustedAttachment.size) : null,
    attachment_type: trustedAttachment?.content_type || null,
    created_at: new Date().toISOString()
  };

  return c.json({ success: true, comment: commentRecord }, 201);
});

app.post('/api/projects/:projectId/files', async (c) => {
  const uid = c.get('uid');
  const projectId = c.req.param('projectId');
  const category = c.req.query('category');
  const allowedCategories = [
    'client_upload',
    'draughtsman_version',
    'correction_attachment',
    'chat_attachment',
    'message_attachment',
    'workspace_draft',
    'reference',
    'specification'
  ];

  if (!category || !allowedCategories.includes(category)) {
    return c.json({ error: 'Invalid category' }, 400);
  }

  const actionId = c.req.header('X-Action-Id');
  if (!actionId) return c.json({ error: 'X-Action-Id header is required' }, 400);

  const rawFileName = c.req.header('X-File-Name');
  if (!rawFileName) return c.json({ error: 'X-File-Name header is required' }, 400);
  const fileName = decodeURIComponent(rawFileName);

  // Validate extension server-side and prevent directory traversal
  const baseName = fileName.split(/[/\\]/).pop() || fileName;
  const sanitizedName = baseName.replace(/[^a-zA-Z0-9.-]/g, '_').replace(/^\.+/, '');
  const ext = sanitizedName.split('.').pop()?.toLowerCase();
  const allowedExtensions = ['pdf', 'dwg', 'dxf', 'png', 'jpg', 'jpeg', 'zip', 'webm', 'm4a', 'mp3', 'wav', 'aac', 'ogg'];

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
    webm: 'audio/webm',
    m4a: 'audio/mp4',
    mp3: 'audio/mpeg',
    wav: 'audio/wav',
    aac: 'audio/aac',
    ogg: 'audio/ogg',
  };
  const contentType = mimeMap[ext] || 'application/octet-stream';

  const db = c.env.DB;
  const user = await getUser(db, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  // Strict Deny-by-Default Category Authorization
  let isAuthorized = false;

  if (category === 'client_upload' || category === 'correction_attachment' || category === 'reference' || category === 'specification') {
    const isOwner = (user.role === 'CLIENT' || user.role === 'ENGINEER') && project.client_id === uid;
    const isAdmin = ['ADMIN', 'STUDIO_ADMIN'].includes(user.role as string);
    isAuthorized = isOwner || isAdmin;
  } else if (category === 'draughtsman_version') {
    const isAssignedDraughtsman = user.role === 'DRAUGHTSMAN' && project.draughtsman_id === uid && project.status === 'IN_PROGRESS';
    isAuthorized = isAssignedDraughtsman;
  } else if (category === 'workspace_draft') {
    const isOwnerEngineer = (user.role === 'CLIENT' || user.role === 'ENGINEER') && project.client_id === uid;
    const isAssignedDraughtsman = user.role === 'DRAUGHTSMAN' && await verifyDraughtsmanWorkspaceAccess(db, project, uid);
    const isAssignedStudent = user.role === 'STUDENT' && project.is_training_project === 1 && await verifyStudentAssignment(db, uid, projectId);
    const isAdmin = ['ADMIN', 'STUDIO_ADMIN'].includes(user.role as string);
    isAuthorized = isOwnerEngineer || isAssignedDraughtsman || isAssignedStudent || isAdmin;
  } else if (category === 'message_attachment' || category === 'chat_attachment') {
    isAuthorized = await canUserAccessProject(db, project, user, uid);
  }

  if (!isAuthorized) {
    return c.json({ error: 'Forbidden: You do not have permission to upload this file category to this project' }, 403);
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

    let MAX_SIZE = 50 * 1024 * 1024; // 50MB default
    let ceilingLabel = '50MB';
    try {
      const settingRow = await db.prepare("SELECT value FROM studio_settings WHERE key = 'maxUploadCeiling'").first();
      if (settingRow && settingRow.value) {
        ceilingLabel = settingRow.value as string;
        const match = ceilingLabel.match(/^(\d+)(MB|GB)$/i);
        if (match) {
          const num = parseInt(match[1], 10);
          const unit = match[2].toUpperCase();
          MAX_SIZE = unit === 'GB' ? num * 1024 * 1024 * 1024 : num * 1024 * 1024;
        }
      }
    } catch {
      // fallback to 50MB
    }

    const contentLengthHeader = c.req.header('Content-Length');
    if (!contentLengthHeader) throw new Error('Content-Length header is required');

    const expectedSize = parseInt(contentLengthHeader, 10);
    if (isNaN(expectedSize) || expectedSize <= 0) throw new Error('Invalid Content-Length');
    if (expectedSize > MAX_SIZE) throw new Error(`File exceeds ${ceilingLabel} limit`);

    let bytesReceived = 0;
    const byteCounter = new TransformStream({
      transform(chunk, controller) {
        bytesReceived += chunk.byteLength;
        if (bytesReceived > expectedSize) {
          controller.error(new Error('Body exceeded declared Content-Length'));
        } else if (bytesReceived > MAX_SIZE) {
          controller.error(new Error(`File exceeds ${ceilingLabel} limit during streaming`));
        } else {
          controller.enqueue(chunk);
        }
      },
      flush(controller) {
        if (bytesReceived < expectedSize) {
          controller.error(new Error('Body smaller than declared Content-Length'));
        }
      }
    });

    const fixedStream = typeof (globalThis as any).FixedLengthStream !== 'undefined'
      ? new (globalThis as any).FixedLengthStream(expectedSize)
      : new TransformStream();

    let streamError: any = null;
    const streamingPromise = c.req.raw.body
      .pipeThrough(byteCounter)
      .pipeTo(fixedStream.writable)
      .catch((err) => { streamError = err; });

    const putResult = await c.env.STORAGE.put(objectKey, fixedStream.readable, {
      httpMetadata: { contentType: contentType }
    });

    await streamingPromise;
    if (streamError) throw streamError;

    const finalSize = (putResult && typeof putResult.size === 'number') ? putResult.size : bytesReceived;

    // Update status to COMPLETED and save actual byte count
    await db.prepare(`UPDATE files SET status = 'COMPLETED', size = ? WHERE id = ?`).bind(finalSize, actionId).run();

    if (category === 'draughtsman_version') {
      const latest = await db.prepare('SELECT MAX(version_number) as v FROM drawing_versions WHERE project_id = ?').bind(projectId).first();
      const vNum = ((latest?.v as number) || 0) + 1;
      const corr = await db.prepare("SELECT id FROM corrections WHERE project_id = ? AND status IN ('OPEN', 'IN_PROGRESS') ORDER BY round_number DESC LIMIT 1").bind(projectId).first();

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

  // Authorization checks: strict cross-user and role-specific file download authorization
  let isAuthorized = false;

  if (user.role === 'CLIENT' || user.role === 'ENGINEER') {
    isAuthorized = project.client_id === uid;
  } else if (user.role === 'DRAUGHTSMAN') {
    isAuthorized = await verifyDraughtsmanWorkspaceAccess(db, project, uid);
  } else if (user.role === 'STUDENT') {
    if (project.is_training_project === 1) {
      const isAssigned = await verifyStudentAssignment(db, uid, project.id as string);
      if (isAssigned) {
        // Can download own submitted files or instructor reference/brief materials for this assigned project
        if (fileMeta.uploaded_by === uid) {
          isAuthorized = true;
        } else if (fileMeta.category !== 'workspace_draft' && fileMeta.category !== 'draughtsman_version') {
          isAuthorized = true;
        }
      }
    }
  } else if (['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) {
    isAuthorized = true;
  }

  if (!isAuthorized) {
    return c.json({ error: 'Forbidden: Access to project file denied' }, 403);
  }

  let object = await c.env.STORAGE.get(fileMeta.object_key as string);
  if (!object && fileMeta.object_key) {
    const rawKey = fileMeta.object_key as string;
    const candidates: string[] = [
      rawKey.startsWith('/') ? rawKey.substring(1) : `/${rawKey}`,
    ];
    try {
      candidates.push(decodeURIComponent(rawKey));
      candidates.push(encodeURI(rawKey));
    } catch {}

    if (fileMeta.project_id && (fileMeta.sanitized_name || fileMeta.original_name)) {
      const name = (fileMeta.sanitized_name as string) || (fileMeta.original_name as string);
      candidates.push(
        `projects/${fileMeta.project_id}/${name}`,
        `projects/${fileMeta.project_id}/${fileMeta.category}/${fileMeta.id}_${name}`,
        `projects/${fileMeta.project_id}/workspace_draft/${fileMeta.id}_${name}`,
        `projects/${fileMeta.project_id}/draughtsman_version/${fileMeta.id}_${name}`,
        `files/${fileMeta.project_id}/${name}`,
        `files/${fileMeta.project_id}/${fileMeta.id}_${name}`
      );
    }

    for (const altKey of candidates) {
      if (altKey && altKey !== rawKey) {
        object = await c.env.STORAGE.get(altKey);
        if (object) {
          await db.prepare('UPDATE files SET object_key = ? WHERE id = ?').bind(altKey, fileId).run();
          break;
        }
      }
    }
  }

  if (!object) return c.json({ error: 'File object missing in R2' }, 404);

  const headers = new Headers();
  object.writeHttpMetadata(headers as any);
  headers.set('etag', object.httpEtag);

  // Authoritative MIME resolution from fileMeta or sanitized extension
  const ext = ((fileMeta.sanitized_name as string) || (fileMeta.original_name as string) || '').split('.').pop()?.toLowerCase();
  const mimeMap: Record<string, string> = {
    pdf: 'application/pdf',
    png: 'image/png',
    jpg: 'image/jpeg',
    jpeg: 'image/jpeg',
    zip: 'application/zip',
    dwg: 'application/acad',
    dxf: 'application/dxf',
    webm: 'audio/webm',
    m4a: 'audio/mp4',
    mp3: 'audio/mpeg',
    wav: 'audio/wav',
    aac: 'audio/aac',
    ogg: 'audio/ogg',
  };
  const resolvedContentType = (fileMeta.content_type as string) || (ext ? mimeMap[ext] : null) || headers.get('content-type') || 'application/octet-stream';
  headers.set('Content-Type', resolvedContentType);

  const disposition = c.req.query('disposition') === 'inline' ? 'inline' : 'attachment';
  headers.set('Content-Disposition', `${disposition}; filename="${fileMeta.sanitized_name}"`);

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
  const hasAccess = await canUserAccessProject(db, project, user, uid);
  if (!hasAccess) return c.json({ error: 'Forbidden: Workspace access denied' }, 403);

  const fileMeta = await db.prepare('SELECT * FROM files WHERE id = ? AND project_id = ?').bind(fileId, projectId).first();
  if (!fileMeta) return c.json({ error: 'File not found or does not belong to project' }, 404);

  // Strict file deletion authorization:
  // - Admins can delete any file for cleanup/moderation.
  // - Ordinary users can ONLY delete files they themselves uploaded.
  // - Submitted formal drawing versions cannot be deleted by non-admins.
  const isAdmin = ['ADMIN', 'STUDIO_ADMIN'].includes(user.role as string);
  if (!isAdmin) {
    if (fileMeta.uploaded_by !== uid) {
      return c.json({ error: 'Forbidden: You do not have permission to delete files uploaded by another user' }, 403);
    }

    const isVersionRecord = await db.prepare('SELECT id FROM drawing_versions WHERE file_id = ?').bind(fileId).first();
    if (isVersionRecord) {
      return c.json({ error: 'Forbidden: Submitted drawing versions cannot be deleted' }, 403);
    }
  }

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

  const hasAccess = await canUserAccessProject(db, project, user, uid);
  if (!hasAccess) return c.json({ error: 'Forbidden: Workspace access denied' }, 403);

  let query = 'SELECT * FROM activity_logs WHERE project_id = ?';
  if (user.role === 'ENGINEER' || user.role === 'CLIENT') {
    query += " AND action_type NOT IN ('ASSIGNMENT_REJECTED', 'DRAUGHTSMAN_REASSIGNED', 'INVOICE_CREATED', 'PAYMENT_RECORDED')";
  }
  query += ' ORDER BY timestamp DESC';
  const logs = await db.prepare(query).bind(projectId).all();
  return c.json(logs.results);
});

app.get('/api/activity', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;

  const user = await getUser(db, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);

  const limitParam = c.req.query('limit');
  const limit = Math.min(Math.max(parseInt(limitParam || '100', 10) || 100, 1), 500);

  let logs;
  if (['ENGINEER', 'CLIENT'].includes(user.role as string)) {
    // Activities for projects owned by this Engineer/Client, excluding internal reassignments
    logs = await db.prepare(`
      SELECT a.*, p.project_name
      FROM activity_logs a
      LEFT JOIN projects p ON a.project_id = p.id
      WHERE p.client_id = ? AND a.action_type NOT IN ('ASSIGNMENT_REJECTED', 'DRAUGHTSMAN_REASSIGNED', 'INVOICE_CREATED', 'PAYMENT_RECORDED')
      ORDER BY a.timestamp DESC
      LIMIT ?
    `).bind(uid, limit).all();
  } else if (user.role === 'DRAUGHTSMAN') {
    // Activities for projects assigned to this Draughtsman
    logs = await db.prepare(`
      SELECT a.*, p.project_name
      FROM activity_logs a
      LEFT JOIN projects p ON a.project_id = p.id
      WHERE p.draughtsman_id = ?
      ORDER BY a.timestamp DESC
      LIMIT ?
    `).bind(uid, limit).all();
  } else if (['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) {
    // Global audit stream for administrators
    logs = await db.prepare(`
      SELECT a.*, p.project_name
      FROM activity_logs a
      LEFT JOIN projects p ON a.project_id = p.id
      ORDER BY a.timestamp DESC
      LIMIT ?
    `).bind(limit).all();
  } else {
    return c.json({ error: 'Forbidden' }, 403);
  }

  return c.json(logs.results);
});

app.get('/api/notifications', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const notifs = await db.prepare('SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC').bind(uid).all();
  return c.json(notifs.results);
});


app.patch('/api/notifications/read-all', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  await db.prepare('UPDATE notifications SET is_read = 1 WHERE user_id = ?').bind(uid).run();
  return c.json({ success: true });
});

app.patch('/api/notifications/:id/read', async (c) => {
  const uid = c.get('uid');
  const notificationId = c.req.param('id');
  const db = c.env.DB;

  const notif = await db.prepare('SELECT * FROM notifications WHERE id = ?').bind(notificationId).first();
  if (!notif) return c.json({ error: 'Not found' }, 404);
  if (notif.user_id !== uid) return c.json({ error: 'Forbidden' }, 403);

  await db.prepare('UPDATE notifications SET is_read = 1 WHERE id = ?').bind(notificationId).run();
  return c.json({ success: true });
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

app.delete('/api/notifications', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  await db.prepare('DELETE FROM notifications WHERE user_id = ?').bind(uid).run();
  return c.json({ success: true });
});

app.post('/api/notifications/clear', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  await db.prepare('DELETE FROM notifications WHERE user_id = ?').bind(uid).run();
  return c.json({ success: true });
});

app.delete('/api/notifications/:id', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const id = c.req.param('id');
  const notif = await db.prepare('SELECT * FROM notifications WHERE id = ?').bind(id).first();
  if (!notif) return c.json({ error: 'Notification not found' }, 404);
  if (notif.user_id !== uid) return c.json({ error: 'Permission denied' }, 403);
  await db.prepare('DELETE FROM notifications WHERE id = ? AND user_id = ?').bind(id, uid).run();
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

  if (!['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) return c.json({ error: 'Forbidden' }, 403);

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
  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) return c.json({ error: 'Forbidden' }, 403);

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
  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) return c.json({ error: 'Forbidden' }, 403);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  // Payments Scope Frozen (Section 3): Payment and invoicing mutations are frozen in this release
  return c.json({
    error: 'Financial mutations are disabled: payments scope is frozen in this release',
    code: 'FEATURE_FROZEN'
  }, 501);
});

app.post('/api/invoices/:invoiceId/payments', async (c) => {
  const uid = c.get('uid');
  const invoiceId = c.req.param('invoiceId');
  const db = c.env.DB;

  const user = await getUser(db, uid);
  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) return c.json({ error: 'Forbidden' }, 403);

  const invoice = await db.prepare('SELECT * FROM invoices WHERE id = ?').bind(invoiceId).first();
  if (!invoice) return c.json({ error: 'Invoice not found' }, 404);

  // Payments Scope Frozen (Section 3): Payment and invoicing mutations are frozen in this release
  return c.json({
    error: 'Financial mutations are disabled: payments scope is frozen in this release',
    code: 'FEATURE_FROZEN'
  }, 501);
});



// Helper: Check if student is assigned to training project
async function verifyStudentAssignment(db: D1Database, uid: string, projectId: string): Promise<boolean> {
  const assignment = await db.prepare("SELECT 1 FROM student_assignments WHERE student_id = ? AND project_id = ? AND status != 'REPLACED'").bind(uid, projectId).first();
  return !!assignment;
}


async function isModuleAuthorizedForStudent(db: D1Database, studentId: string, moduleId: string): Promise<boolean> {
  const mod: any = await db.prepare(
    "SELECT publication_status FROM training_modules WHERE id = ?"
  ).bind(moduleId).first();
  if (!mod || mod.publication_status === 'DRAFT' || mod.publication_status === 'ARCHIVED') {
    return false;
  }

  // 1. Direct active learning plan
  const plan = await db.prepare(
    "SELECT 1 FROM student_learning_plans WHERE student_id = ? AND module_id = ? AND status != 'ARCHIVED'"
  ).bind(studentId, moduleId).first();
  if (plan) return true;

  // 2. Training practical project linked to this module
  const prj = await db.prepare(
    "SELECT 1 FROM projects p JOIN student_assignments sa ON sa.project_id = p.id WHERE p.training_module_id = ? AND sa.student_id = ? AND p.is_training_project = 1 AND sa.status != 'REPLACED'"
  ).bind(moduleId, studentId).first();
  if (prj) return true;

  // 3. Fallback for unassigned/initial state: if student has no plans at all anywhere
  const hasAnyPlans = await db.prepare(
    "SELECT 1 FROM student_learning_plans WHERE student_id = ? AND status != 'ARCHIVED'"
  ).bind(studentId).first();
  if (!hasAnyPlans) {
    const progress = await db.prepare(
      "SELECT 1 FROM student_progress WHERE student_id = ? AND module_id = ?"
    ).bind(studentId, moduleId).first();
    if (progress) return true;

    // Check if module is unassigned public starter module (not locked, published)
    const starterModule = await db.prepare(
      "SELECT 1 FROM training_modules WHERE id = ? AND is_locked = 0 AND publication_status = 'PUBLISHED'"
    ).bind(moduleId).first();
    if (starterModule) return true;
  }

  return false;
}

app.get('/api/student/training/modules', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || user.role !== 'STUDENT') {
    return c.json({ error: 'Unauthorized: Only students can access training modules', code: 'UNAUTHORIZED' }, 403);
  }

  const hasAnyPlans = await db.prepare(
    "SELECT 1 FROM student_learning_plans WHERE student_id = ? AND status != 'ARCHIVED'"
  ).bind(uid).first();

  let results: any[] = [];
  if (hasAnyPlans) {
    const queryRes = await db.prepare(`
      SELECT
        tm.*,
        slp.target_completion_date,
        slp.instructions AS plan_instructions,
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
      JOIN student_learning_plans slp ON slp.module_id = tm.id AND slp.student_id = ? AND slp.status != 'ARCHIVED'
      LEFT JOIN student_progress sp ON sp.module_id = tm.id AND sp.student_id = ?
      WHERE tm.publication_status != 'DRAFT' AND tm.publication_status != 'ARCHIVED'
      ORDER BY tm.created_at ASC
    `).bind(uid, uid).all();
    results = queryRes.results || [];
  } else {
    // If student has no specific learning plans yet, return modules with assigned practical projects or progress or unlocked
    const queryRes = await db.prepare(`
      SELECT
        tm.*,
        NULL AS target_completion_date,
        NULL AS plan_instructions,
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
      WHERE (
        tm.id IN (
          SELECT p.training_module_id FROM projects p
          JOIN student_assignments sa ON sa.project_id = p.id
          WHERE sa.student_id = ? AND p.is_training_project = 1 AND sa.status != 'REPLACED'
        )
        OR sp.id IS NOT NULL
        OR (tm.is_locked = 0)
      )
      AND tm.publication_status != 'DRAFT' AND tm.publication_status != 'ARCHIVED'
      ORDER BY tm.created_at ASC
    `).bind(uid, uid).all();
    results = queryRes.results || [];
  }

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
  const isAuthorized = await isModuleAuthorizedForStudent(db, uid, moduleId);
  if (!isAuthorized) {
    return c.json({ error: 'Forbidden: This training module has not been assigned to your learning plan', code: 'FORBIDDEN' }, 403);
  }

  const module: any = await db.prepare(`
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
    WHERE tm.id = ?
  `).bind(uid, moduleId).first();

  if (!module) {
    return c.json({ error: 'Training module not found', code: 'NOT_FOUND' }, 404);
  }

  // Attach chapters
  const chapters = await db.prepare(`
    SELECT * FROM training_chapters WHERE module_id = ? ORDER BY chapter_order ASC, created_at ASC
  `).bind(moduleId).all();
  module.chapters = chapters.results || [];

  // Derive authoritative progress from completed lessons and practical project status
  const lessons = await db.prepare(`
    SELECT l.id, COALESCE(l.is_required, 1) AS is_required, slp.status
    FROM training_lessons l
    LEFT JOIN student_lesson_progress slp ON slp.lesson_id = l.id AND slp.student_id = ?
    WHERE l.module_id = ?
  `).bind(uid, moduleId).all();

  const totalLessons = lessons.results.length;
  if (totalLessons > 0) {
    const requiredLessons = lessons.results.filter((l: any) => l.is_required !== 0);
    const requiredTotal = requiredLessons.length > 0 ? requiredLessons.length : totalLessons;
    const completedRequired = requiredLessons.filter((l: any) => l.status === 'COMPLETED').length;

    // Check if practical project exists for this student
    const practicalProject: any = await db.prepare(`
      SELECT p.id, p.status
      FROM projects p
      JOIN student_assignments sa ON sa.project_id = p.id
      WHERE p.training_module_id = ? AND sa.student_id = ? AND p.is_training_project = 1 AND sa.status != 'REPLACED'
    `).bind(moduleId, uid).first();

    const hasPractical = !!practicalProject;
    const isPracticalCompleted = practicalProject && practicalProject.status === 'COMPLETED';

    if (completedRequired === requiredTotal) {
      if (!hasPractical || isPracticalCompleted) {
        module.status = 'Completed';
        module.progress = 1.0;
        module.score = module.score ?? 100;
      } else {
        // Hybrid module: lessons finished but practical project pending or in progress
        module.status = 'In Progress';
        module.progress = 0.9;
        module.score = module.score ?? 90;
      }
    } else if (completedRequired > 0) {
      module.status = 'In Progress';
      module.progress = Number((completedRequired / requiredTotal).toFixed(2));
      module.score = module.score ?? Math.round((completedRequired / requiredTotal) * 100);
    }
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
  const isAuthorized = await isModuleAuthorizedForStudent(db, uid, moduleId);
  if (!isAuthorized) {
    return c.json({ error: 'Forbidden: Module not assigned', code: 'FORBIDDEN' }, 403);
  }

  const { results } = await db.prepare(`
    SELECT
      l.*,
      COALESCE(slp.status, 'NOT_STARTED') AS status,
      slp.completed_at
    FROM training_lessons l
    LEFT JOIN student_lesson_progress slp ON slp.lesson_id = l.id AND slp.student_id = ?
    WHERE l.module_id = ?
    ORDER BY l.lesson_order ASC
  `).bind(uid, moduleId).all();

  return c.json(results || []);
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
  const lesson: any = await db.prepare(`
    SELECT
      l.*,
      COALESCE(slp.status, 'NOT_STARTED') AS status,
      slp.completed_at,
      sc.id AS certificate_id,
      sc.verification_token,
      sc.certificate_object_key
    FROM training_lessons l
    LEFT JOIN student_lesson_progress slp ON slp.lesson_id = l.id AND slp.student_id = ?
    LEFT JOIN student_credentials sc ON sc.reference_id = l.id AND sc.student_id = ? AND sc.type = 'LESSON_COMPLETION'
    WHERE l.id = ?
  `).bind(uid, uid, lessonId).first();

  if (!lesson) {
    return c.json({ error: 'Lesson not found', code: 'NOT_FOUND' }, 404);
  }

  const isAuthorized = await isModuleAuthorizedForStudent(db, uid, lesson.module_id);
  if (!isAuthorized) {
    return c.json({ error: 'Forbidden: Lesson not assigned to your learning plan', code: 'FORBIDDEN' }, 403);
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

  const lesson: any = await db.prepare('SELECT id, module_id, title FROM training_lessons WHERE id = ?').bind(lessonId).first();
  if (!lesson) {
    return c.json({ error: 'Lesson not found', code: 'NOT_FOUND' }, 404);
  }
  const moduleId = lesson.module_id;

  const isAuthorized = await isModuleAuthorizedForStudent(db, uid, moduleId);
  if (!isAuthorized) {
    return c.json({ error: 'Forbidden: Lesson not assigned to your learning plan', code: 'FORBIDDEN' }, 403);
  }

  const allLessons = await db.prepare(`
    SELECT l.id, COALESCE(l.is_required, 1) AS is_required, slp.status
    FROM training_lessons l
    LEFT JOIN student_lesson_progress slp ON slp.lesson_id = l.id AND slp.student_id = ?
    WHERE l.module_id = ?
  `).bind(uid, moduleId).all();

  let totalLessons = allLessons.results.length;
  const requiredLessons = allLessons.results.filter((l: any) => l.is_required !== 0);
  const requiredTotal = requiredLessons.length > 0 ? requiredLessons.length : totalLessons;
  let completedRequired = 0;

  for (const l of allLessons.results) {
    let lessonStatus = l.status;
    if (l.id === lessonId) {
      lessonStatus = status;
    }
    if (lessonStatus === 'COMPLETED' && l.is_required !== 0) {
      completedRequired++;
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

  let certificateData: any = null;
  if (status === 'COMPLETED') {
    const existingCert: any = await db.prepare(`
      SELECT id, verification_token, certificate_object_key, issued_at
      FROM student_credentials
      WHERE student_id = ? AND type = 'LESSON_COMPLETION' AND reference_id = ?
    `).bind(uid, lessonId).first();

    const lessonExactTitle = lesson.title || 'Architectural Lesson';
    const moduleDetails: any = await db.prepare('SELECT title FROM training_modules WHERE id = ?').bind(moduleId).first();
    const moduleExactTitle = moduleDetails?.title || 'Training Program';

    let certId = existingCert?.id;
    let verificationToken = existingCert?.verification_token;
    let objectKey = existingCert?.certificate_object_key;

    if (!certId) {
      const shortSuffix = crypto.randomUUID().slice(0, 8).toUpperCase();
      certId = `DS-AD-LES-${shortSuffix}`;
    }
    if (!verificationToken) {
      verificationToken = crypto.randomUUID().replace(/-/g, '');
    }

    if (!existingCert) {
      batch.push(
        db.prepare(`
          INSERT INTO student_credentials (id, student_id, type, reference_id, title, description, issued_at, verification_token)
          VALUES (?, ?, 'LESSON_COMPLETION', ?, ?, ?, CURRENT_TIMESTAMP, ?)
          ON CONFLICT(student_id, type, reference_id) DO NOTHING
        `).bind(
          certId,
          uid,
          lessonId,
          lessonExactTitle,
          `Completed the lesson: ${lessonExactTitle} in module: ${moduleExactTitle}`,
          verificationToken
        )
      );
    }

    const publicVerifyUrl = `https://www.draughtsmanstudio.com/verify?id=${certId}&token=${verificationToken}`;

    if (!objectKey) {
      objectKey = `certificates/${uid}/${certId}.pdf`;
      try {
        const studentDisplayName = (user.name as string) || (user.email as string) || 'Student';
        const dateStr = new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });

        const pdfBytes = generateCertificatePdf({
          studentName: studentDisplayName,
          lessonTitle: lessonExactTitle,
          completionDate: dateStr,
          certificateId: certId,
          verifyUrl: publicVerifyUrl,
        });

        if (c.env.STORAGE) {
          await c.env.STORAGE.put(objectKey, pdfBytes, {
            httpMetadata: { contentType: 'application/pdf' },
          });
          batch.push(
            db.prepare(`
              UPDATE student_credentials
              SET certificate_object_key = ?, verification_token = ?
              WHERE id = ? AND student_id = ?
            `).bind(objectKey, verificationToken, certId, uid)
          );
        }
      } catch (pdfErr) {
        console.error('Lesson certificate PDF generation deferred/failed:', pdfErr);
      }
    }

    certificateData = {
      id: certId,
      title: lessonExactTitle,
      moduleTitle: moduleExactTitle,
      verificationToken: verificationToken,
      verifyUrl: publicVerifyUrl,
      downloadUrl: `/api/student/credentials/${certId}/certificate`
    };
  }

  let finalScore = 0;
  if (requiredTotal > 0) {
    let moduleStatus = 'In Progress';
    let score = Math.round((completedRequired / requiredTotal) * 100);
    finalScore = score;

    if (completedRequired === requiredTotal) {
      // Check if this module requires a practical project for this student
      const practicalProject: any = await db.prepare(`
        SELECT p.id, p.status
        FROM projects p
        JOIN student_assignments sa ON sa.project_id = p.id
        WHERE p.training_module_id = ? AND sa.student_id = ? AND p.is_training_project = 1 AND sa.status != 'REPLACED'
      `).bind(moduleId, uid).first();

      const hasPracticalProject = !!practicalProject;
      const isPracticalCompleted = practicalProject && practicalProject.status === 'COMPLETED';

      if (!hasPracticalProject || isPracticalCompleted) {
        moduleStatus = 'Completed';
        score = 100;
        finalScore = 100;

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
      } else {
        // Hybrid module: lessons finished, but practical project is still pending or in progress
        moduleStatus = 'In Progress';
        score = 90;
        finalScore = 90;
      }
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

  return c.json({ success: true, status, completion_percentage: finalScore, certificate: certificateData });
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

  // Reject direct manual completion attempts
  if (status === 'Completed') {
    return c.json({
      error: 'Direct manual module completion is forbidden. Completion must be earned authoritatively through lessons and practical project approval.',
      code: 'FORBIDDEN'
    }, 403);
  }

  const id = uuidv4();

  // Upsert progress for non-terminal statuses (e.g. 'In Progress')
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

// ==========================================
// TEACHING STUDENTS — ADMIN TRAINING MODULES ENDPOINTS
// ==========================================

// GET /api/admin/training/modules
app.get('/api/admin/training/modules', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) {
    return c.json({ error: 'Admin access required', code: 'FORBIDDEN' }, 403);
  }

  const category = c.req.query('category');
  const status = c.req.query('status');
  const search = c.req.query('search');

  let sql = `
    SELECT
      tm.*,
      COUNT(DISTINCT tc.id) AS chapters_count,
      COUNT(DISTINCT tl.id) AS lessons_count,
      COUNT(DISTINCT slp.student_id) AS enrolled_students_count
    FROM training_modules tm
    LEFT JOIN training_chapters tc ON tc.module_id = tm.id
    LEFT JOIN training_lessons tl ON tl.module_id = tm.id
    LEFT JOIN student_learning_plans slp ON slp.module_id = tm.id AND slp.status != 'ARCHIVED'
    WHERE 1=1
  `;
  const params: any[] = [];

  if (category && category !== 'ALL') {
    sql += ` AND LOWER(tm.category) = LOWER(?)`;
    params.push(category);
  }
  if (status && status !== 'ALL') {
    sql += ` AND UPPER(tm.publication_status) = UPPER(?)`;
    params.push(status);
  }
  if (search && search.trim()) {
    sql += ` AND (LOWER(tm.title) LIKE ? OR LOWER(tm.description) LIKE ?)`;
    const q = `%${search.trim().toLowerCase()}%`;
    params.push(q, q);
  }

  sql += ` GROUP BY tm.id ORDER BY tm.created_at DESC`;

  const { results } = await db.prepare(sql).bind(...params).all();
  return c.json(results || []);
});

// POST /api/admin/training/modules
app.post('/api/admin/training/modules', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) {
    return c.json({ error: 'Admin access required', code: 'FORBIDDEN' }, 403);
  }

  const body = await c.req.json().catch(() => ({}));
  const title = (body.title || '').trim();
  const category = (body.category || 'Architectural').trim();
  const type = (body.type || 'Module').trim();
  const level = (body.level || 'Beginner').trim();
  const description = (body.description || '').trim();
  const prerequisites = (body.prerequisites || '').trim();
  const learningObjectives = (body.learning_objectives || body.learningObjectives || '').trim();
  const thumbnailUrl = (body.thumbnail_url || body.thumbnailUrl || '').trim();
  const publicationStatus = (body.publication_status || body.publicationStatus || 'PUBLISHED').toUpperCase();
  const isLocked = body.is_locked !== undefined ? (body.is_locked ? 1 : 0) : 1;

  if (!title) {
    return c.json({ error: 'Module title is required', code: 'INVALID_TITLE' }, 400);
  }

  const id = body.id || ('mod-' + crypto.randomUUID().substring(0, 8));

  // Check if module already exists (for idempotent creation/retries)
  const existing = await db.prepare('SELECT id FROM training_modules WHERE id = ?').bind(id).first();
  if (existing) {
    await db.prepare(`
      UPDATE training_modules SET
        category = ?, type = ?, level = ?, title = ?, description = ?,
        prerequisites = ?, is_locked = ?, publication_status = ?,
        learning_objectives = ?, thumbnail_url = ?, updated_at = CURRENT_TIMESTAMP
      WHERE id = ?
    `).bind(
      category, type, level, title, description, prerequisites || null, isLocked,
      publicationStatus, learningObjectives || null, thumbnailUrl || null, id
    ).run();
  } else {
    await db.prepare(`
      INSERT INTO training_modules (
        id, category, type, level, title, description, prerequisites, is_locked,
        publication_status, learning_objectives, thumbnail_url, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    `).bind(
      id, category, type, level, title, description, prerequisites || null, isLocked,
      publicationStatus, learningObjectives || null, thumbnailUrl || null
    ).run();
  }

  const created = await db.prepare('SELECT * FROM training_modules WHERE id = ?').bind(id).first();

  // Optional Student Assignment during creation
  const targetStudentId = body.assign_to_student_id || body.student_id;
  if (targetStudentId) {
    const student = await db.prepare("SELECT * FROM users WHERE id = ?").bind(targetStudentId).first();
    if (!student) {
      return c.json({
        error: 'Module saved, but selected student was not found',
        code: 'STUDENT_NOT_FOUND',
        id,
        module: created,
        assignment_failed: true
      }, 400);
    }
    if (student.role !== 'STUDENT') {
      return c.json({
        error: 'Module saved, but selected user is not a Student',
        code: 'INVALID_ROLE',
        id,
        module: created,
        assignment_failed: true
      }, 400);
    }
    if (student.status === 'SUSPENDED') {
      return c.json({
        error: 'Module saved, but cannot assign to suspended student',
        code: 'ACCOUNT_SUSPENDED',
        id,
        module: created,
        assignment_failed: true
      }, 403);
    }

    const planId = 'plan-' + crypto.randomUUID().substring(0, 8);
    const targetDate = body.target_completion_date || body.targetCompletionDate || null;
    const instructions = (body.assignment_instructions || body.instructions || '').trim();

    await db.prepare(`
      INSERT INTO student_learning_plans (
        id, student_id, module_id, assigned_by, assigned_at,
        target_completion_date, instructions, status, created_at, updated_at
      ) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP, ?, ?, 'ASSIGNED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
      ON CONFLICT(student_id, module_id) DO UPDATE SET
        target_completion_date = excluded.target_completion_date,
        instructions = excluded.instructions,
        status = 'ASSIGNED',
        updated_at = CURRENT_TIMESTAMP
    `).bind(planId, targetStudentId, id, uid, targetDate, instructions || null).run();

    await db.prepare(`
      INSERT INTO student_progress (id, student_id, module_id, status, updated_at)
      VALUES (?, ?, ?, 'Not Started', CURRENT_TIMESTAMP)
      ON CONFLICT(student_id, module_id) DO NOTHING
    `).bind(crypto.randomUUID(), targetStudentId, id).run();

    await db.prepare(`
      INSERT INTO notifications (id, user_id, type, title, message, created_at)
      VALUES (?, ?, 'LEARNING_PLAN_ASSIGNED', 'New Training Assigned', ?, CURRENT_TIMESTAMP)
    `).bind(
      crypto.randomUUID(), targetStudentId,
      `You have been assigned training module: "${title}"`
    ).run();

    return c.json({
      success: true,
      id,
      module: created,
      assignment: {
        assigned: true,
        plan_id: planId,
        student_id: targetStudentId,
        student_name: student.name,
      }
    }, 201);
  }

  return c.json({ success: true, id, module: created }, 201);
});

// GET /api/admin/training/modules/:moduleId
app.get('/api/admin/training/modules/:moduleId', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) {
    return c.json({ error: 'Admin access required', code: 'FORBIDDEN' }, 403);
  }

  const moduleId = c.req.param('moduleId');
  const module: any = await db.prepare('SELECT * FROM training_modules WHERE id = ?').bind(moduleId).first();
  if (!module) {
    return c.json({ error: 'Module not found', code: 'NOT_FOUND' }, 404);
  }

  const chapters = await db.prepare(`
    SELECT * FROM training_chapters WHERE module_id = ? ORDER BY chapter_order ASC, created_at ASC
  `).bind(moduleId).all();

  const lessons = await db.prepare(`
    SELECT * FROM training_lessons WHERE module_id = ? ORDER BY lesson_order ASC, created_at ASC
  `).bind(moduleId).all();

  const enrollments = await db.prepare(`
    SELECT slp.*, u.name as student_name, u.email as student_email, sp.status as student_status, sp.score as student_score
    FROM student_learning_plans slp
    JOIN users u ON slp.student_id = u.id
    LEFT JOIN student_progress sp ON sp.module_id = slp.module_id AND sp.student_id = slp.student_id
    WHERE slp.module_id = ? AND slp.status != 'ARCHIVED'
  `).bind(moduleId).all();

  return c.json({
    module,
    chapters: chapters.results || [],
    lessons: lessons.results || [],
    enrollments: enrollments.results || [],
  });
});

// PUT /api/admin/training/modules/:moduleId
app.put('/api/admin/training/modules/:moduleId', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) {
    return c.json({ error: 'Admin access required', code: 'FORBIDDEN' }, 403);
  }

  const moduleId = c.req.param('moduleId');
  const existing = await db.prepare('SELECT * FROM training_modules WHERE id = ?').bind(moduleId).first();
  if (!existing) {
    return c.json({ error: 'Module not found', code: 'NOT_FOUND' }, 404);
  }

  const body = await c.req.json().catch(() => ({}));
  const title = body.title !== undefined ? String(body.title).trim() : existing.title;
  const category = body.category !== undefined ? String(body.category).trim() : existing.category;
  const type = body.type !== undefined ? String(body.type).trim() : existing.type;
  const level = body.level !== undefined ? String(body.level).trim() : existing.level;
  const description = body.description !== undefined ? String(body.description).trim() : existing.description;
  const prerequisites = body.prerequisites !== undefined ? String(body.prerequisites).trim() : existing.prerequisites;
  const learningObjectives = body.learning_objectives !== undefined ? String(body.learning_objectives).trim() : (body.learningObjectives !== undefined ? String(body.learningObjectives).trim() : existing.learning_objectives);
  const thumbnailUrl = body.thumbnail_url !== undefined ? String(body.thumbnail_url).trim() : (body.thumbnailUrl !== undefined ? String(body.thumbnailUrl).trim() : existing.thumbnail_url);
  const publicationStatus = body.publication_status !== undefined ? String(body.publication_status).toUpperCase() : (body.publicationStatus !== undefined ? String(body.publicationStatus).toUpperCase() : existing.publication_status);
  const isLocked = body.is_locked !== undefined ? (body.is_locked ? 1 : 0) : existing.is_locked;

  if (!title) {
    return c.json({ error: 'Module title cannot be empty', code: 'INVALID_TITLE' }, 400);
  }

  await db.prepare(`
    UPDATE training_modules SET
      title = ?, category = ?, type = ?, level = ?, description = ?,
      prerequisites = ?, is_locked = ?, publication_status = ?,
      learning_objectives = ?, thumbnail_url = ?, updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `).bind(
    title, category, type, level, description,
    prerequisites || null, isLocked, publicationStatus,
    learningObjectives || null, thumbnailUrl || null, moduleId
  ).run();

  const updated = await db.prepare('SELECT * FROM training_modules WHERE id = ?').bind(moduleId).first();
  return c.json({ success: true, module: updated });
});

// DELETE /api/admin/training/modules/:moduleId (Soft archive - preserves historical student progress)
app.delete('/api/admin/training/modules/:moduleId', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) {
    return c.json({ error: 'Admin access required', code: 'FORBIDDEN' }, 403);
  }

  const moduleId = c.req.param('moduleId');
  const existing = await db.prepare('SELECT * FROM training_modules WHERE id = ?').bind(moduleId).first();
  if (!existing) {
    return c.json({ error: 'Module not found', code: 'NOT_FOUND' }, 404);
  }

  // Soft archive to preserve historical progress
  await db.prepare(`
    UPDATE training_modules SET publication_status = 'ARCHIVED', updated_at = CURRENT_TIMESTAMP WHERE id = ?
  `).bind(moduleId).run();

  return c.json({ success: true, message: 'Module archived. Historical student progress preserved.' });
});

// ==========================================
// TEACHING STUDENTS — CHAPTERS & LESSONS CRUD
// ==========================================

// POST /api/admin/training/modules/:moduleId/chapters
app.post('/api/admin/training/modules/:moduleId/chapters', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) {
    return c.json({ error: 'Admin access required', code: 'FORBIDDEN' }, 403);
  }

  const moduleId = c.req.param('moduleId');
  const body = await c.req.json().catch(() => ({}));
  const title = (body.title || '').trim();
  const description = (body.description || '').trim();
  const chapterOrder = Number(body.chapter_order || body.chapterOrder || 1);

  if (!title) {
    return c.json({ error: 'Chapter title is required', code: 'INVALID_TITLE' }, 400);
  }

  const id = body.id || ('ch-' + crypto.randomUUID().substring(0, 8));

  await db.prepare(`
    INSERT INTO training_chapters (id, module_id, title, description, chapter_order, created_at)
    VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
  `).bind(id, moduleId, title, description || null, chapterOrder).run();

  const chapter = await db.prepare('SELECT * FROM training_chapters WHERE id = ?').bind(id).first();
  return c.json({ success: true, id, chapter }, 201);
});

// PUT /api/admin/training/chapters/:chapterId
app.put('/api/admin/training/chapters/:chapterId', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) {
    return c.json({ error: 'Admin access required', code: 'FORBIDDEN' }, 403);
  }

  const chapterId = c.req.param('chapterId');
  const existing = await db.prepare('SELECT * FROM training_chapters WHERE id = ?').bind(chapterId).first();
  if (!existing) return c.json({ error: 'Chapter not found', code: 'NOT_FOUND' }, 404);

  const body = await c.req.json().catch(() => ({}));
  const title = body.title !== undefined ? String(body.title).trim() : existing.title;
  const description = body.description !== undefined ? String(body.description).trim() : existing.description;
  const chapterOrder = body.chapter_order !== undefined ? Number(body.chapter_order) : (body.chapterOrder !== undefined ? Number(body.chapterOrder) : existing.chapter_order);

  await db.prepare(`
    UPDATE training_chapters SET title = ?, description = ?, chapter_order = ? WHERE id = ?
  `).bind(title, description || null, chapterOrder, chapterId).run();

  const updated = await db.prepare('SELECT * FROM training_chapters WHERE id = ?').bind(chapterId).first();
  return c.json({ success: true, chapter: updated });
});

// DELETE /api/admin/training/chapters/:chapterId
app.delete('/api/admin/training/chapters/:chapterId', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) {
    return c.json({ error: 'Admin access required', code: 'FORBIDDEN' }, 403);
  }

  const chapterId = c.req.param('chapterId');
  await db.prepare('DELETE FROM training_chapters WHERE id = ?').bind(chapterId).run();
  return c.json({ success: true });
});

// POST /api/admin/training/modules/:moduleId/lessons
app.post('/api/admin/training/modules/:moduleId/lessons', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) {
    return c.json({ error: 'Admin access required', code: 'FORBIDDEN' }, 403);
  }

  const moduleId = c.req.param('moduleId');
  const body = await c.req.json().catch(() => ({}));
  const title = (body.title || '').trim();
  const content = (body.content || '').trim();
  const lessonOrder = Number(body.lesson_order || body.lessonOrder || 1);
  const estimatedDuration = (body.estimated_duration || body.estimatedDuration || '15 mins').trim();
  const chapterId = body.chapter_id || body.chapterId || null;
  const videoUrl = (body.video_url || body.videoUrl || '').trim();
  const isRequired = body.is_required !== undefined ? (body.is_required ? 1 : 0) : 1;
  const resourcesJson = typeof body.resources_json === 'string' ? body.resources_json : (body.resources ? JSON.stringify(body.resources) : null);

  if (!title) {
    return c.json({ error: 'Lesson title is required', code: 'INVALID_TITLE' }, 400);
  }

  const id = body.id || ('les-' + crypto.randomUUID().substring(0, 8));

  await db.prepare(`
    INSERT INTO training_lessons (
      id, module_id, title, content, lesson_order, estimated_duration,
      chapter_id, resources_json, video_url, is_required, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
  `).bind(
    id, moduleId, title, content, lessonOrder, estimatedDuration,
    chapterId, resourcesJson, videoUrl || null, isRequired
  ).run();

  const lesson = await db.prepare('SELECT * FROM training_lessons WHERE id = ?').bind(id).first();
  return c.json({ success: true, id, lesson }, 201);
});

// PUT /api/admin/training/lessons/:lessonId
app.put('/api/admin/training/lessons/:lessonId', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) {
    return c.json({ error: 'Admin access required', code: 'FORBIDDEN' }, 403);
  }

  const lessonId = c.req.param('lessonId');
  const existing = await db.prepare('SELECT * FROM training_lessons WHERE id = ?').bind(lessonId).first();
  if (!existing) return c.json({ error: 'Lesson not found', code: 'NOT_FOUND' }, 404);

  const body = await c.req.json().catch(() => ({}));
  const title = body.title !== undefined ? String(body.title).trim() : existing.title;
  const content = body.content !== undefined ? String(body.content) : existing.content;
  const lessonOrder = body.lesson_order !== undefined ? Number(body.lesson_order) : (body.lessonOrder !== undefined ? Number(body.lessonOrder) : existing.lesson_order);
  const estimatedDuration = body.estimated_duration !== undefined ? String(body.estimated_duration).trim() : existing.estimated_duration;
  const chapterId = body.chapter_id !== undefined ? body.chapter_id : existing.chapter_id;
  const videoUrl = body.video_url !== undefined ? String(body.video_url).trim() : existing.video_url;
  const isRequired = body.is_required !== undefined ? (body.is_required ? 1 : 0) : existing.is_required;
  const resourcesJson = body.resources_json !== undefined ? (typeof body.resources_json === 'string' ? body.resources_json : JSON.stringify(body.resources_json)) : (body.resources ? JSON.stringify(body.resources) : existing.resources_json);

  await db.prepare(`
    UPDATE training_lessons SET
      title = ?, content = ?, lesson_order = ?, estimated_duration = ?,
      chapter_id = ?, resources_json = ?, video_url = ?, is_required = ?,
      updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `).bind(
    title, content, lessonOrder, estimatedDuration || null,
    chapterId || null, resourcesJson || null, videoUrl || null, isRequired, lessonId
  ).run();

  const updated = await db.prepare('SELECT * FROM training_lessons WHERE id = ?').bind(lessonId).first();
  return c.json({ success: true, lesson: updated });
});

// DELETE /api/admin/training/lessons/:lessonId
app.delete('/api/admin/training/lessons/:lessonId', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) {
    return c.json({ error: 'Admin access required', code: 'FORBIDDEN' }, 403);
  }

  const lessonId = c.req.param('lessonId');
  await db.prepare('DELETE FROM training_lessons WHERE id = ?').bind(lessonId).run();
  return c.json({ success: true });
});

// ==========================================
// TEACHING STUDENTS — STUDENT LEARNING PLANS
// ==========================================

// GET /api/admin/learning-plans
app.get('/api/admin/learning-plans', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) {
    return c.json({ error: 'Admin access required', code: 'FORBIDDEN' }, 403);
  }

  const studentId = c.req.query('studentId');
  const moduleId = c.req.query('moduleId');

  let sql = `
    SELECT
      slp.*,
      u.name AS student_name,
      u.email AS student_email,
      u.status AS student_account_status,
      tm.title AS module_title,
      tm.category AS module_category,
      tm.level AS module_level,
      tm.publication_status AS module_publication_status,
      sp.status AS progress_status,
      sp.score AS progress_score
    FROM student_learning_plans slp
    JOIN users u ON slp.student_id = u.id
    JOIN training_modules tm ON slp.module_id = tm.id
    LEFT JOIN student_progress sp ON sp.student_id = slp.student_id AND sp.module_id = slp.module_id
    WHERE slp.status != 'ARCHIVED'
  `;
  const params: any[] = [];
  if (studentId) {
    sql += ` AND slp.student_id = ?`;
    params.push(studentId);
  }
  if (moduleId) {
    sql += ` AND slp.module_id = ?`;
    params.push(moduleId);
  }
  sql += ` ORDER BY slp.created_at DESC`;

  const { results } = await db.prepare(sql).bind(...params).all();
  return c.json(results || []);
});

// GET /api/admin/students/:studentId/learning-plans
app.get('/api/admin/students/:studentId/learning-plans', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) {
    return c.json({ error: 'Admin access required', code: 'FORBIDDEN' }, 403);
  }

  const studentId = c.req.param('studentId');
  const { results } = await db.prepare(`
    SELECT
      slp.*,
      tm.title AS module_title,
      tm.category AS module_category,
      tm.level AS module_level,
      tm.type AS module_type,
      tm.publication_status,
      sp.status AS progress_status,
      sp.score AS progress_score,
      sp.updated_at AS progress_updated_at
    FROM student_learning_plans slp
    JOIN training_modules tm ON slp.module_id = tm.id
    LEFT JOIN student_progress sp ON sp.student_id = slp.student_id AND sp.module_id = slp.module_id
    WHERE slp.student_id = ? AND slp.status != 'ARCHIVED'
    ORDER BY slp.created_at DESC
  `).bind(studentId).all();

  return c.json(results || []);
});

// POST /api/admin/students/:studentId/learning-plans
app.post('/api/admin/students/:studentId/learning-plans', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) {
    return c.json({ error: 'Admin access required', code: 'FORBIDDEN' }, 403);
  }

  const studentId = c.req.param('studentId');
  const student = await db.prepare("SELECT * FROM users WHERE id = ?").bind(studentId).first();
  if (!student) {
    return c.json({ error: 'Student not found', code: 'STUDENT_NOT_FOUND' }, 404);
  }
  if (student.role !== 'STUDENT') {
    return c.json({ error: 'Target user is not a Student', code: 'INVALID_ROLE' }, 400);
  }
  if (student.status === 'SUSPENDED') {
    return c.json({ error: 'Cannot assign learning plan to suspended student', code: 'ACCOUNT_SUSPENDED' }, 403);
  }

  const body = await c.req.json().catch(() => ({}));
  const moduleIds: string[] = Array.isArray(body.moduleIds) ? body.moduleIds : (body.moduleId ? [body.moduleId] : []);
  const targetCompletionDate = body.target_completion_date || body.targetCompletionDate || null;
  const instructions = (body.instructions || '').trim();
  const selectedChapters = body.selected_chapters ? (typeof body.selected_chapters === 'string' ? body.selected_chapters : JSON.stringify(body.selected_chapters)) : null;
  const selectedLessons = body.selected_lessons ? (typeof body.selected_lessons === 'string' ? body.selected_lessons : JSON.stringify(body.selected_lessons)) : null;

  if (moduleIds.length === 0) {
    return c.json({ error: 'At least one module must be selected', code: 'NO_MODULES_SELECTED' }, 400);
  }

  const createdPlans: any[] = [];
  for (const modId of moduleIds) {
    const mod = await db.prepare("SELECT * FROM training_modules WHERE id = ?").bind(modId).first();
    if (!mod) continue;

    const planId = 'plan-' + crypto.randomUUID().substring(0, 8);
    await db.prepare(`
      INSERT INTO student_learning_plans (
        id, student_id, module_id, assigned_by, assigned_at,
        target_completion_date, instructions, selected_chapters, selected_lessons,
        status, created_at, updated_at
      ) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP, ?, ?, ?, ?, 'ASSIGNED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
      ON CONFLICT(student_id, module_id) DO UPDATE SET
        target_completion_date = excluded.target_completion_date,
        instructions = excluded.instructions,
        selected_chapters = excluded.selected_chapters,
        selected_lessons = excluded.selected_lessons,
        status = 'ASSIGNED',
        updated_at = CURRENT_TIMESTAMP
    `).bind(
      planId, studentId, modId, uid,
      targetCompletionDate, instructions || null, selectedChapters, selectedLessons
    ).run();

    // Ensure student_progress entry exists
    await db.prepare(`
      INSERT INTO student_progress (id, student_id, module_id, status, updated_at)
      VALUES (?, ?, ?, 'Not Started', CURRENT_TIMESTAMP)
      ON CONFLICT(student_id, module_id) DO NOTHING
    `).bind(crypto.randomUUID(), studentId, modId).run();

    // Send notification to student
    await db.prepare(`
      INSERT INTO notifications (id, user_id, type, title, message, created_at)
      VALUES (?, ?, 'LEARNING_PLAN_ASSIGNED', 'New Training Assigned', ?, CURRENT_TIMESTAMP)
    `).bind(
      crypto.randomUUID(), studentId,
      `You have been assigned training module: "${mod.title}"`
    ).run();

    createdPlans.push({ planId, moduleId: modId, title: mod.title });
  }

  return c.json({ success: true, count: createdPlans.length, plans: createdPlans }, 201);
});

// DELETE /api/admin/learning-plans/:planId
app.delete('/api/admin/learning-plans/:planId', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) {
    return c.json({ error: 'Admin access required', code: 'FORBIDDEN' }, 403);
  }

  const planId = c.req.param('planId');
  await db.prepare("UPDATE student_learning_plans SET status = 'ARCHIVED', updated_at = CURRENT_TIMESTAMP WHERE id = ?").bind(planId).run();
  return c.json({ success: true });
});

// ==========================================
// TEACHING STUDENTS — STUDENT PROGRESS DASHBOARD
// ==========================================

function parseEvaluationScore(criteriaJson: string | null): number | null {
  if (!criteriaJson) return null;
  try {
    const parsed = typeof criteriaJson === 'string' ? JSON.parse(criteriaJson) : criteriaJson;
    if (typeof parsed === 'number') return parsed;
    if (parsed && typeof parsed === 'object') {
      if (typeof parsed.score === 'number') return parsed.score;
      const entries = Object.entries(parsed).filter(([_, v]) => typeof v === 'number');
      if (entries.length > 0) {
        const total = entries.reduce((acc, [_, v]) => acc + (v as number), 0);
        return Math.round((total / (entries.length * 5)) * 100);
      }
    }
  } catch (e) {}
  return null;
}

function isLessonAssignedToPlan(
  lesson: { id: string; chapter_id?: string | null },
  plan: { selected_chapters?: string | null; selected_lessons?: string | null }
): boolean {
  if (plan.selected_lessons) {
    try {
      const selLessons = typeof plan.selected_lessons === 'string'
        ? JSON.parse(plan.selected_lessons)
        : plan.selected_lessons;
      if (Array.isArray(selLessons) && selLessons.length > 0) {
        return selLessons.includes(lesson.id);
      }
    } catch (e) {}
  }
  if (plan.selected_chapters) {
    try {
      const selChapters = typeof plan.selected_chapters === 'string'
        ? JSON.parse(plan.selected_chapters)
        : plan.selected_chapters;
      if (Array.isArray(selChapters) && selChapters.length > 0) {
        return lesson.chapter_id ? selChapters.includes(lesson.chapter_id) : false;
      }
    } catch (e) {}
  }
  return true;
}

// GET /api/admin/students-progress
app.get('/api/admin/students-progress', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) {
    return c.json({ error: 'Admin access required', code: 'FORBIDDEN' }, 403);
  }

  const searchParam = c.req.query('search')?.trim().toLowerCase();
  const statusParam = c.req.query('status')?.trim().toUpperCase();

  // Get all registered students
  const { results: students } = await db.prepare(`
    SELECT id, name, email, mobile, status, college_name, qualification, created_at
    FROM users
    WHERE role = 'STUDENT'
    ORDER BY name ASC, email ASC
  `).all();

  const progressList = [];
  const nowMs = Date.now();

  for (const st of (students || [])) {
    // Assigned learning plans
    const { results: plans } = await db.prepare(`
      SELECT slp.id, slp.student_id, slp.module_id, slp.assigned_at, slp.target_completion_date,
             slp.instructions, slp.selected_chapters, slp.selected_lessons, slp.status as plan_status,
             tm.title as module_title, tm.category as module_category, tm.publication_status,
             sp.status as module_status, sp.score as module_score, sp.updated_at as module_updated_at
      FROM student_learning_plans slp
      JOIN training_modules tm ON tm.id = slp.module_id
      LEFT JOIN student_progress sp ON sp.module_id = slp.module_id AND sp.student_id = slp.student_id
      WHERE slp.student_id = ? AND slp.status != 'REVOKED' AND slp.status != 'ARCHIVED'
      ORDER BY slp.created_at DESC
    `).bind(st.id).all();

    const assignedPlans = plans || [];
    const totalAssigned = assignedPlans.length;

    const studentAssignedRequiredLessonIds = new Set<string>();
    const studentCompletedRequiredLessonIds = new Set<string>();
    const studentAssignedAllLessonIds = new Set<string>();
    const studentCompletedAllLessonIds = new Set<string>();

    let completedPlansCount = 0;
    let inProgressPlansCount = 0;
    let notStartedPlansCount = 0;
    let overdueCount = 0;
    let earliestTargetDate: string | null = null;
    let latestCompletionDate: string | null = null;

    const mappedPlans = [];

    for (const pl of assignedPlans) {
      // Query lessons for this module
      const { results: lessons } = await db.prepare(`
        SELECT l.id, l.module_id, l.chapter_id, COALESCE(l.is_required, 1) as is_required,
               slp.status as lesson_status, slp.completed_at
        FROM training_lessons l
        LEFT JOIN student_lesson_progress slp ON slp.lesson_id = l.id AND slp.student_id = ?
        WHERE l.module_id = ?
        ORDER BY l.lesson_order ASC
      `).bind(st.id, pl.module_id).all();

      const allModLessons = lessons || [];
      const assignedLessonsForPlan = allModLessons.filter((l: any) => isLessonAssignedToPlan(l, pl));

      let planReqCount = 0;
      let planCompReqCount = 0;
      const planTotalCount = assignedLessonsForPlan.length;
      let planCompTotalCount = 0;

      for (const les of assignedLessonsForPlan) {
        studentAssignedAllLessonIds.add(les.id);
        const isReq = les.is_required !== 0 && les.is_required !== false;
        if (isReq) {
          studentAssignedRequiredLessonIds.add(les.id);
          planReqCount++;
        }
        if (les.lesson_status === 'COMPLETED') {
          studentCompletedAllLessonIds.add(les.id);
          planCompTotalCount++;
          if (isReq) {
            studentCompletedRequiredLessonIds.add(les.id);
            planCompReqCount++;
          }
          if (les.completed_at) {
            if (!latestCompletionDate || new Date(les.completed_at).getTime() > new Date(latestCompletionDate).getTime()) {
              latestCompletionDate = les.completed_at;
            }
          }
        }
      }

      // Determine individual plan status
      let computedPlanStatus: 'Completed' | 'In Progress' | 'Not Started' = 'Not Started';
      if (planReqCount > 0) {
        if (planCompReqCount === planReqCount) {
          computedPlanStatus = 'Completed';
        } else if (planCompReqCount > 0 || planCompTotalCount > 0) {
          computedPlanStatus = 'In Progress';
        } else {
          computedPlanStatus = 'Not Started';
        }
      } else if (planTotalCount > 0) {
        if (planCompTotalCount === planTotalCount) {
          computedPlanStatus = 'Completed';
        } else if (planCompTotalCount > 0) {
          computedPlanStatus = 'In Progress';
        } else {
          computedPlanStatus = 'Not Started';
        }
      }

      if (computedPlanStatus === 'Completed') {
        completedPlansCount++;
      } else if (computedPlanStatus === 'In Progress') {
        inProgressPlansCount++;
      } else {
        notStartedPlansCount++;
      }

      // Check overdue
      if (pl.target_completion_date) {
        const targetMs = new Date(pl.target_completion_date).getTime();
        if (targetMs < nowMs && computedPlanStatus !== 'Completed') {
          overdueCount++;
        }
        if (computedPlanStatus !== 'Completed') {
          if (!earliestTargetDate || targetMs < new Date(earliestTargetDate).getTime()) {
            earliestTargetDate = pl.target_completion_date;
          }
        }
      }

      mappedPlans.push({
        id: pl.id,
        module_id: pl.module_id,
        module_title: pl.module_title,
        module_category: pl.module_category,
        plan_status: pl.plan_status,
        target_completion_date: pl.target_completion_date || null,
        module_status: computedPlanStatus,
        module_score: pl.module_score ?? null,
      });
    }

    // Overall completion percentage
    const totalRequired = studentAssignedRequiredLessonIds.size;
    const completedRequired = studentCompletedRequiredLessonIds.size;
    let overallPercentage = 0;
    if (totalRequired > 0) {
      overallPercentage = Math.round((completedRequired / totalRequired) * 100);
    } else if (studentAssignedAllLessonIds.size > 0) {
      overallPercentage = Math.round((studentCompletedAllLessonIds.size / studentAssignedAllLessonIds.size) * 100);
    }

    // Overall training status
    let trainingStatus = 'UNASSIGNED';
    if (totalAssigned > 0) {
      if (overallPercentage === 100) {
        trainingStatus = 'COMPLETED';
      } else if (completedRequired > 0 || inProgressPlansCount > 0 || studentCompletedAllLessonIds.size > 0) {
        trainingStatus = 'IN_PROGRESS';
      } else {
        trainingStatus = 'NOT_STARTED';
      }
    }

    // Practical training assignments count
    const practicalCount: any = await db.prepare(`
      SELECT
        COUNT(DISTINCT sa.project_id) as total_projects,
        COUNT(DISTINCT CASE WHEN p.status = 'COMPLETED' OR e.overall_result = 'APPROVED' THEN sa.project_id END) as approved_projects,
        COUNT(DISTINCT CASE WHEN p.status = 'UNDER_ENGINEER_REVIEW' OR p.status = 'UNDER_CLIENT_REVIEW' THEN sa.project_id END) as pending_review
      FROM student_assignments sa
      JOIN projects p ON sa.project_id = p.id
      LEFT JOIN evaluations e ON e.project_id = p.id
      WHERE sa.student_id = ? AND p.is_training_project = 1 AND sa.status != 'REPLACED'
    `).bind(st.id).first();

    const summaryItem = {
      student_id: st.id,
      student_name: st.name || 'Unnamed Student',
      student_email: st.email,
      student_status: st.status || 'ACTIVE',
      college_name: st.college_name || null,
      qualification: st.qualification || null,
      assigned_plans_count: totalAssigned,
      assigned_modules_count: totalAssigned,
      completed_plans_count: completedPlansCount,
      in_progress_plans_count: inProgressPlansCount,
      not_started_plans_count: notStartedPlansCount,
      total_required_lessons: totalRequired,
      completed_required_lessons: completedRequired,
      overall_completion_percentage: overallPercentage,
      training_status: trainingStatus,
      practical_projects_count: practicalCount?.total_projects || 0,
      practical_approved_count: practicalCount?.approved_projects || 0,
      practical_pending_count: practicalCount?.pending_review || 0,
      has_overdue: overdueCount > 0,
      overdue_count: overdueCount,
      earliest_target_date: earliestTargetDate,
      latest_completion_date: latestCompletionDate,
      plans: mappedPlans,

      // Legacy aliases for backward compatibility:
      name: st.name || 'Unnamed Student',
      email: st.email,
      account_status: st.status || 'ACTIVE',
      total_assigned_modules: totalAssigned,
      completed_modules: completedPlansCount,
      in_progress_modules: inProgressPlansCount,
      not_started_modules: notStartedPlansCount,
      practical_projects: {
        total: practicalCount?.total_projects || 0,
        completed: practicalCount?.approved_projects || 0,
        pending_review: practicalCount?.pending_review || 0,
      },
    };

    // Filter by status if requested:
    if (statusParam && statusParam !== 'ALL') {
      if (statusParam === 'COMPLETED' && trainingStatus !== 'COMPLETED') continue;
      if (statusParam === 'IN_PROGRESS' && trainingStatus !== 'IN_PROGRESS') continue;
      if (statusParam === 'NOT_STARTED' && trainingStatus !== 'NOT_STARTED') continue;
      if (statusParam === 'OVERDUE' && !summaryItem.has_overdue) continue;
      if (statusParam === 'UNASSIGNED' && trainingStatus !== 'UNASSIGNED') continue;
    }

    // Filter by search if requested:
    if (searchParam) {
      const nameMatch = summaryItem.student_name.toLowerCase().includes(searchParam);
      const emailMatch = summaryItem.student_email.toLowerCase().includes(searchParam);
      const collegeMatch = summaryItem.college_name?.toLowerCase().includes(searchParam);
      if (!nameMatch && !emailMatch && !collegeMatch) continue;
    }

    progressList.push(summaryItem);
  }

  return c.json(progressList);
});

// GET /api/admin/students/:studentId/progress-detail
app.get('/api/admin/students/:studentId/progress-detail', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) {
    return c.json({ error: 'Admin access required', code: 'FORBIDDEN' }, 403);
  }

  const studentId = c.req.param('studentId');
  const student = await db.prepare("SELECT * FROM users WHERE id = ?").bind(studentId).first();
  if (!student) {
    return c.json({ error: 'Student not found', code: 'NOT_FOUND' }, 404);
  }

  // Assigned learning plans with module details
  const { results: plans } = await db.prepare(`
    SELECT
      slp.id AS plan_id,
      slp.assigned_at,
      slp.target_completion_date,
      slp.instructions,
      slp.selected_chapters,
      slp.selected_lessons,
      slp.status AS plan_status,
      tm.id AS module_id,
      tm.title AS module_title,
      tm.category AS module_category,
      tm.level AS module_level,
      tm.type AS module_type,
      tm.description AS module_description,
      tm.publication_status AS module_publication_status,
      sp.status AS module_progress_status,
      sp.score AS module_score,
      sp.updated_at AS module_last_activity
    FROM student_learning_plans slp
    JOIN training_modules tm ON tm.id = slp.module_id
    LEFT JOIN student_progress sp ON sp.module_id = slp.module_id AND sp.student_id = slp.student_id
    WHERE slp.student_id = ? AND slp.status != 'REVOKED' AND slp.status != 'ARCHIVED'
    ORDER BY slp.created_at DESC
  `).bind(studentId).all();

  const assignedPlans = plans || [];
  const modulesDetail = [];
  const studentAssignedRequiredLessonIds = new Set<string>();
  const studentCompletedRequiredLessonIds = new Set<string>();
  const studentAssignedAllLessonIds = new Set<string>();
  const studentCompletedAllLessonIds = new Set<string>();

  let completedModulesCount = 0;
  let inProgressModulesCount = 0;
  let notStartedModulesCount = 0;
  let hasOverdue = false;
  const nowMs = Date.now();

  for (const pl of assignedPlans) {
    // Chapters
    const { results: chapters } = await db.prepare(`
      SELECT * FROM training_chapters WHERE module_id = ? ORDER BY chapter_order ASC
    `).bind(pl.module_id).all();

    const allChapters = chapters || [];

    // Lessons with student progress
    const { results: lessons } = await db.prepare(`
      SELECT
        l.id, l.title, l.lesson_order, l.estimated_duration, l.chapter_id,
        COALESCE(l.is_required, 1) as is_required,
        l.video_url, l.resources_json,
        COALESCE(slp.status, 'NOT_STARTED') AS status,
        CASE WHEN slp.status = 'COMPLETED' THEN 1 ELSE 0 END as is_completed,
        slp.completed_at
      FROM training_lessons l
      LEFT JOIN student_lesson_progress slp ON slp.lesson_id = l.id AND slp.student_id = ?
      WHERE l.module_id = ?
      ORDER BY l.lesson_order ASC
    `).bind(studentId, pl.module_id).all();

    const allLessons = lessons || [];
    const assignedLessons = allLessons.filter((l: any) => isLessonAssignedToPlan(l, pl));

    // Module lesson counts
    let modReqLessons = 0;
    let modCompReqLessons = 0;
    const modTotalLessons = assignedLessons.length;
    let modCompLessons = 0;

    const formattedAssignedLessons = assignedLessons.map((les: any) => {
      let resources = [];
      if (les.resources_json) {
        try {
          resources = typeof les.resources_json === 'string' ? JSON.parse(les.resources_json) : les.resources_json;
        } catch (e) {}
      }
      const isReq = les.is_required !== 0 && les.is_required !== false;
      const isComp = les.is_completed === 1 || les.status === 'COMPLETED';

      studentAssignedAllLessonIds.add(les.id);
      if (isReq) {
        modReqLessons++;
        studentAssignedRequiredLessonIds.add(les.id);
      }
      if (isComp) {
        modCompLessons++;
        studentCompletedAllLessonIds.add(les.id);
        if (isReq) {
          modCompReqLessons++;
          studentCompletedRequiredLessonIds.add(les.id);
        }
      }

      return {
        id: les.id,
        title: les.title,
        chapter_id: les.chapter_id,
        lesson_order: les.lesson_order,
        estimated_duration: les.estimated_duration,
        is_required: isReq,
        is_completed: isComp,
        status: les.status,
        completed_at: les.completed_at || null,
        video_url: les.video_url || null,
        resources: Array.isArray(resources) ? resources : [],
      };
    });

    // Group lessons into chapters and standalone lessons
    const groupedChapters = allChapters.map((ch: any) => ({
      chapter: {
        id: ch.id,
        module_id: ch.module_id,
        title: ch.title,
        description: ch.description,
        chapter_order: ch.chapter_order,
        created_at: ch.created_at,
      },
      lessons: formattedAssignedLessons.filter((l: any) => l.chapter_id === ch.id),
    }));

    const standaloneLessons = formattedAssignedLessons.filter(
      (l: any) => !l.chapter_id || !allChapters.some((c: any) => c.id === l.chapter_id)
    );

    // Compute module completion percentage
    const modCompletionPercentage = modReqLessons > 0
      ? Math.round((modCompReqLessons / modReqLessons) * 100)
      : (modTotalLessons > 0 && modCompLessons === modTotalLessons ? 100 : 0);

    let modStatus = 'Not Started';
    if (modCompletionPercentage === 100 && (modReqLessons > 0 || modTotalLessons > 0)) {
      modStatus = 'Completed';
      completedModulesCount++;
    } else if (modCompLessons > 0 || pl.module_progress_status === 'In Progress' || pl.plan_status === 'IN_PROGRESS') {
      modStatus = 'In Progress';
      inProgressModulesCount++;
    } else {
      modStatus = 'Not Started';
      notStartedModulesCount++;
    }

    if (pl.target_completion_date && new Date(pl.target_completion_date).getTime() < nowMs && modStatus !== 'Completed') {
      hasOverdue = true;
    }

    // Practical project for this module
    const practical: any = await db.prepare(`
      SELECT p.id, p.project_name, p.status, p.drawing_name, p.drawing_type, p.created_at, p.submitted_at, p.approved_at,
             e.overall_result, e.general_feedback, e.criteria_json, e.created_at as evaluated_at
      FROM projects p
      JOIN student_assignments sa ON sa.project_id = p.id
      LEFT JOIN evaluations e ON e.id = (
        SELECT id FROM evaluations WHERE project_id = p.id ORDER BY created_at DESC LIMIT 1
      )
      WHERE p.training_module_id = ? AND sa.student_id = ? AND p.is_training_project = 1 AND sa.status != 'REPLACED'
      ORDER BY p.created_at DESC
    `).bind(pl.module_id, studentId).first();

    const practicalScore = practical ? parseEvaluationScore(practical.criteria_json) : null;

    modulesDetail.push({
      plan: {
        id: pl.plan_id,
        assigned_at: pl.assigned_at,
        target_completion_date: pl.target_completion_date,
        instructions: pl.instructions,
        status: pl.plan_status,
      },
      module: {
        id: pl.module_id,
        title: pl.module_title,
        category: pl.module_category,
        level: pl.module_level,
        type: pl.module_type,
        description: pl.module_description,
        status: modStatus,
        score: pl.module_score ?? null,
        last_activity: pl.module_last_activity ?? null,
      },
      chapters: groupedChapters,
      standaloneLessons: standaloneLessons,
      lessons: formattedAssignedLessons, // flat list for backwards compatibility
      progress: {
        total_required_lessons: modReqLessons,
        completed_required_lessons: modCompReqLessons,
        total_lessons: modTotalLessons,
        completed_lessons: modCompLessons,
        completion_percentage: modCompletionPercentage,
        status: modStatus,
      },
      practical_project: practical ? {
        id: practical.id,
        project_name: practical.project_name,
        drawing_name: practical.drawing_name,
        drawing_type: practical.drawing_type,
        status: practical.status,
        submitted_at: practical.submitted_at,
        approved_at: practical.approved_at,
        evaluation: practical.overall_result ? {
          overall_result: practical.overall_result,
          score: practicalScore,
          general_feedback: practical.general_feedback,
          evaluated_at: practical.evaluated_at,
        } : null,
      } : null,
    });
  }

  // Calculate overall metrics
  const totalRequired = studentAssignedRequiredLessonIds.size;
  const completedRequired = studentCompletedRequiredLessonIds.size;
  const overallPercentage = totalRequired > 0
    ? Math.round((completedRequired / totalRequired) * 100)
    : (studentAssignedAllLessonIds.size > 0
        ? Math.round((studentCompletedAllLessonIds.size / studentAssignedAllLessonIds.size) * 100)
        : 0);

  // Practical projects query with distinct project IDs
  const { results: practicals } = await db.prepare(`
    SELECT
      p.id, p.project_name, p.drawing_name, p.drawing_type, p.status, p.correction_round,
      p.created_at, p.submitted_at,
      e.overall_result, e.general_feedback, e.criteria_json, e.created_at AS evaluated_at
    FROM student_assignments sa
    JOIN projects p ON sa.project_id = p.id
    LEFT JOIN evaluations e ON e.id = (
      SELECT id FROM evaluations WHERE project_id = p.id ORDER BY created_at DESC LIMIT 1
    )
    WHERE sa.student_id = ? AND p.is_training_project = 1 AND sa.status != 'REPLACED'
    ORDER BY p.created_at DESC
  `).bind(studentId).all();

  const practicalProjects = (practicals || []).map((p: any) => {
    const score = parseEvaluationScore(p.criteria_json);
    return {
      id: p.id,
      project_name: p.project_name,
      drawing_name: p.drawing_name,
      drawing_type: p.drawing_type,
      status: p.status,
      correction_round: p.correction_round,
      created_at: p.created_at,
      submitted_at: p.submitted_at,
      evaluation: p.overall_result ? {
        overall_result: p.overall_result,
        score: score,
        general_feedback: p.general_feedback,
        evaluated_at: p.evaluated_at,
      } : null,
    };
  });

  // Completion history timeline
  const completionHistory = [];
  for (const mObj of modulesDetail) {
    for (const ch of mObj.chapters) {
      for (const les of ch.lessons) {
        if (les.is_completed && les.completed_at) {
          completionHistory.push({
            id: `les-${les.id}`,
            type: 'LESSON_COMPLETED',
            title: `Completed Lesson: ${les.title}`,
            subtitle: `${mObj.module.title} • ${ch.chapter.title}`,
            timestamp: les.completed_at,
            status: 'COMPLETED',
            badge: 'Lesson',
          });
        }
      }
    }
    for (const les of mObj.standaloneLessons) {
      if (les.is_completed && les.completed_at) {
        completionHistory.push({
          id: `les-${les.id}`,
          type: 'LESSON_COMPLETED',
          title: `Completed Lesson: ${les.title}`,
          subtitle: mObj.module.title,
          timestamp: les.completed_at,
          status: 'COMPLETED',
          badge: 'Lesson',
        });
      }
    }
  }

  for (const prj of practicalProjects) {
    if (prj.submitted_at) {
      completionHistory.push({
        id: `prj-sub-${prj.id}`,
        type: 'PROJECT_SUBMITTED',
        title: `Submitted Drawing: ${prj.project_name}`,
        subtitle: `${prj.drawing_type} • Round ${prj.correction_round}`,
        timestamp: prj.submitted_at,
        status: prj.status,
        badge: 'Submission',
      });
    }
    if (prj.evaluation && prj.evaluation.evaluated_at) {
      completionHistory.push({
        id: `prj-eval-${prj.id}`,
        type: 'PROJECT_EVALUATED',
        title: `Evaluation: ${prj.project_name}`,
        subtitle: `Result: ${prj.evaluation.overall_result}${prj.evaluation.score !== null ? ` (${prj.evaluation.score}/100)` : ''}`,
        timestamp: prj.evaluation.evaluated_at,
        status: prj.evaluation.overall_result,
        badge: 'Evaluation',
      });
    }
  }

  completionHistory.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());

  return c.json({
    student: {
      id: student.id,
      name: student.name,
      email: student.email,
      mobile: student.mobile,
      college_name: student.college_name,
      qualification: student.qualification,
      status: student.status,
    },
    plans: assignedPlans.map((p: any) => ({
      id: p.plan_id,
      module_id: p.module_id,
      module_title: p.module_title,
      module_category: p.module_category,
      assigned_at: p.assigned_at,
      target_completion_date: p.target_completion_date,
      status: p.plan_status,
    })),
    summary: {
      total_modules: assignedPlans.length,
      total_required_lessons: totalRequired,
      completed_required_lessons: completedRequired,
      overall_completion_percentage: overallPercentage,
    },
    overallSummary: {
      total_assigned_modules: assignedPlans.length,
      completed_modules: completedModulesCount,
      in_progress_modules: inProgressModulesCount,
      not_started_modules: notStartedModulesCount,
      total_required_lessons: totalRequired,
      completed_required_lessons: completedRequired,
      overall_completion_percentage: overallPercentage,
      has_overdue: hasOverdue,
    },
    modules: modulesDetail,
    practicalProjects: practicalProjects,
    completionHistory: completionHistory,
  });
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
    WHERE sa.student_id = ? AND p.is_training_project = 1 AND sa.status != 'REPLACED'
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
      AND sa.status != 'REPLACED'
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
    WHERE sa.student_id = ? AND p.is_training_project = 1 AND sa.status != 'REPLACED'
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
    SELECT 
      c.id, 
      c.type, 
      c.title, 
      c.description, 
      c.reference_id as referenceId, 
      c.issued_at as issuedAt, 
      c.certificate_object_key as certificateObjectKey, 
      c.verification_token as verificationToken,
      tl.title as lessonTitle,
      COALESCE(tm.title, tm_direct.title) as moduleTitle
    FROM student_credentials c
    LEFT JOIN training_lessons tl ON c.type = 'LESSON_COMPLETION' AND tl.id = c.reference_id
    LEFT JOIN training_modules tm ON tm.id = tl.module_id
    LEFT JOIN training_modules tm_direct ON c.type = 'MODULE_CERTIFICATION' AND tm_direct.id = c.reference_id
    WHERE c.student_id = ?
    ORDER BY c.issued_at DESC
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

  let verificationToken = credential.verification_token as string | null;
  if (!verificationToken) {
    verificationToken = crypto.randomUUID().replace(/-/g, '');
    await db.prepare('UPDATE student_credentials SET verification_token = ? WHERE id = ?').bind(verificationToken, credentialId).run();
  }

  const publicUrl = `https://www.draughtsmanstudio.com/verify?id=${credential.id}&token=${verificationToken}`;

  try {
    const studentName = (user.name as string) || (user.email as string) || 'Student';
    const credentialTitle = (credential.title as string) || 'Architectural Lesson';
    const issueDate = new Date(credential.issued_at as string || Date.now()).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });

    const pdfBytes = generateCertificatePdf({
      studentName,
      lessonTitle: credentialTitle,
      completionDate: issueDate,
      certificateId: credential.id as string,
      verifyUrl: publicUrl,
    });

    const objectKey = `certificates/${uid}/${credentialId}.pdf`;
    if (c.env.STORAGE) {
      await c.env.STORAGE.put(objectKey, pdfBytes, {
        httpMetadata: { contentType: 'application/pdf' },
      });
    }

    await db.prepare('UPDATE student_credentials SET certificate_object_key = ?, verification_token = ? WHERE id = ?').bind(objectKey, verificationToken, credentialId).run();

    return c.json({ message: 'Certificate generated', certificateObjectKey: objectKey, verificationToken, verifyUrl: publicUrl });
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

  let object = credential.certificate_object_key && c.env.STORAGE ? await c.env.STORAGE.get(credential.certificate_object_key as string) : null;
  if (!object) {
    // Self-healing fallback: Generate PDF dynamically if not yet cached in R2
    try {
      let verificationToken = credential.verification_token as string | null;
      if (!verificationToken) {
        verificationToken = crypto.randomUUID().replace(/-/g, '');
      }
      const studentName = (user.name as string) || (user.email as string) || 'Student';
      const credentialTitle = (credential.title as string) || 'Architectural Lesson';
      const issueDate = new Date(credential.issued_at as string || Date.now()).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });
      const publicUrl = `https://www.draughtsmanstudio.com/verify?id=${credential.id}&token=${verificationToken}`;

      const pdfBytes = generateCertificatePdf({
        studentName,
        lessonTitle: credentialTitle,
        completionDate: issueDate,
        certificateId: credential.id as string,
        verifyUrl: publicUrl,
      });

      const objectKey = `certificates/${uid}/${credentialId}.pdf`;
      if (c.env.STORAGE) {
        await c.env.STORAGE.put(objectKey, pdfBytes, {
          httpMetadata: { contentType: 'application/pdf' },
        });
        await db.prepare('UPDATE student_credentials SET certificate_object_key = ?, verification_token = ? WHERE id = ?').bind(objectKey, verificationToken, credentialId).run();
      }

      const headers = new Headers();
      headers.set('Content-Type', 'application/pdf');
      headers.set('Content-Disposition', `attachment; filename="Certificate_${credentialId}.pdf"`);
      return new Response(pdfBytes, { headers });
    } catch (genErr) {
      console.error('Self-healing PDF generation failed:', genErr);
      return c.json({ error: 'Certificate not generated yet' }, 404);
    }
  }

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

  const result: any = await db.prepare(`
    SELECT 
      c.id, 
      c.type, 
      c.title, 
      c.issued_at as issuedAt, 
      u.name as display_name,
      tl.title as lesson_title,
      COALESCE(tm.title, tm_direct.title) as module_title
    FROM student_credentials c
    JOIN users u ON c.student_id = u.id
    LEFT JOIN training_lessons tl ON c.type = 'LESSON_COMPLETION' AND tl.id = c.reference_id
    LEFT JOIN training_modules tm ON tm.id = tl.module_id
    LEFT JOIN training_modules tm_direct ON c.type = 'MODULE_CERTIFICATION' AND tm_direct.id = c.reference_id
    WHERE c.verification_token = ? OR c.id = ?
  `).bind(token, token).first();

  if (!result) {
    return c.json({ valid: false, error: 'Certificate not found' }, 404);
  }

  const rawName = result.display_name;
  const recipientName = (rawName && String(rawName).trim().length > 0) ? String(rawName).trim() : 'Verified Student';

  return c.json({
    valid: true,
    credential: {
      id: result.id,
      type: result.type,
      title: result.title,
      lessonTitle: result.lesson_title || result.title,
      moduleTitle: result.module_title || null,
      issuedAt: result.issuedAt,
      recipientName: recipientName,
      issuingAuthority: 'Draughtsman Studio & Archi Draft'
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
    WHERE sa.student_id = ? AND p.status = 'COMPLETED' AND sa.status != 'REPLACED'
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

// ==========================================
// ADMIN SETTINGS & GOVERNANCE ENDPOINTS
// ==========================================

const DEFAULT_STUDIO_SETTINGS = {
  multiDiscipline: true,
  turnaround: '24h',
  autoRasterizer: true,
  strictLayerCompliance: true,
  maxUploadCeiling: '50MB',
  notifySubmissions: true,
  notifyAssignments: true,
  notifyCorrections: true,
  notifyDigest: false,
};

app.get('/api/admin/settings', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;

  const user = await getUser(db, uid);
  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) {
    return c.json({ error: 'Permission denied' }, 403);
  }

  const { results } = await db.prepare('SELECT key, value, updated_at, updated_by FROM studio_settings').all();
  const settings: Record<string, any> = { ...DEFAULT_STUDIO_SETTINGS };

  if (results && results.length > 0) {
    for (const row of results as any[]) {
      try {
        if (row.value === 'true') settings[row.key] = true;
        else if (row.value === 'false') settings[row.key] = false;
        else settings[row.key] = row.value;
      } catch {
        settings[row.key] = row.value;
      }
    }
    const latest = results[results.length - 1] as any;
    settings.updated_at = latest.updated_at;
    settings.updated_by = latest.updated_by;
  }

  return c.json(settings);
});

app.put('/api/admin/settings', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;

  const user = await getUser(db, uid);
  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) {
    return c.json({ error: 'Permission denied' }, 403);
  }

  const body = await c.req.json().catch(() => ({}));
  const keys = Object.keys(body).filter(k => k !== 'updated_at' && k !== 'updated_by');

  for (const k of keys) {
    const val = String(body[k]);
    await db.prepare(`
      INSERT INTO studio_settings (key, value, updated_at, updated_by)
      VALUES (?, ?, CURRENT_TIMESTAMP, ?)
      ON CONFLICT(key) DO UPDATE SET
        value = excluded.value,
        updated_at = excluded.updated_at,
        updated_by = excluded.updated_by
    `).bind(k, val, uid).run();
  }

  return c.json({ success: true, settings: { ...DEFAULT_STUDIO_SETTINGS, ...body, updated_at: new Date().toISOString(), updated_by: uid } });
});

// ==========================================
// ADMIN ASSIGNMENTS CONSOLE ENDPOINT
// ==========================================

app.get('/api/admin/assignments', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;

  const user = await getUser(db, uid);
  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) {
    return c.json({ error: 'Permission denied' }, 403);
  }

  const { results } = await db.prepare(`
    SELECT
      a.id,
      a.project_id,
      a.draughtsman_id,
      a.status,
      a.created_at,
      a.updated_at,
      p.project_name,
      p.drawing_type,
      p.status AS project_status,
      u.name AS draughtsman_name,
      u.email AS draughtsman_email
    FROM assignments a
    JOIN projects p ON a.project_id = p.id
    LEFT JOIN users u ON a.draughtsman_id = u.id
    ORDER BY a.created_at DESC
  `).all();

  return c.json(results || []);
});

// ==========================================
// ADMIN PROJECT INITIATION ENDPOINT
// Narrowly scoped, explicitly authorized Admin project creation on behalf of a registered Engineer or direct assignment to a Student
// ==========================================

app.post('/api/admin/projects', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const user = await getUser(db, uid);

  if (!user || !['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string)) {
    return c.json({ error: 'Only administrators can initiate projects via this route', code: 'FORBIDDEN' }, 403);
  }

  const body = await c.req.json().catch(() => ({}));
  const clientId = body.clientId || body.client_id;
  const studentId = body.studentId || body.student_id;
  const isTrainingProject = !!(body.isTrainingProject || body.is_training_project || studentId);
  const projectName = (body.projectName || body.project_name || '').trim();
  const drawingType = (body.drawingType || body.drawing_type || '').trim();
  const projectAddress = (body.projectAddress || body.project_address || 'Draughtsman Studio Scope').trim();
  const drawingName = (body.drawingName || body.drawing_name || `${drawingType} Package`).trim();
  const projectArea = String(body.projectArea || body.project_area || 1500);
  const actionId = body.actionId || crypto.randomUUID();
  const projectId = body.id || body.projectId || ('PRJ-' + crypto.randomUUID().substring(0, 8).toUpperCase());
  const instructions = (body.instructions || body.description || '').trim();
  const trainingModuleId = body.trainingModuleId || body.training_module_id;

  if (!projectName) {
    return c.json({ error: 'Project name is required', code: 'INVALID_PROJECT_NAME' }, 400);
  }
  if (!drawingType) {
    return c.json({ error: 'Drawing type is required', code: 'INVALID_DRAWING_TYPE' }, 400);
  }

  // Check idempotency if project already exists
  const existing = await db.prepare('SELECT id, last_action_id, status FROM projects WHERE id = ?').bind(projectId).first();
  if (existing) {
    if (existing.last_action_id === actionId) {
      return c.json({ success: true, id: projectId, idempotent: true });
    }
    return c.json({ error: 'Project with this ID already exists', code: 'CONFLICT' }, 409);
  }

  // ── BRANCH A: Student Practical Training Assignment ───────────────────────
  if (isTrainingProject) {
    if (!studentId) {
      return c.json({ error: 'Target student (studentId) is required for student assignment', code: 'INVALID_STUDENT' }, 400);
    }

    const studentUser = await getUser(db, studentId);
    if (!studentUser || studentUser.role !== 'STUDENT') {
      return c.json({ error: 'Specified student must be a registered Student', code: 'INVALID_STUDENT' }, 400);
    }

    if (studentUser.status === 'SUSPENDED') {
      return c.json({ error: 'Cannot assign project to a suspended Student account', code: 'ACCOUNT_SUSPENDED' }, 403);
    }

    // Resolve or validate training module association
    let effectiveModuleId = trainingModuleId;
    if (effectiveModuleId) {
      const moduleExists = await db.prepare('SELECT id FROM training_modules WHERE id = ?').bind(effectiveModuleId).first();
      if (!moduleExists) {
        return c.json({ error: 'Referenced training module does not exist', code: 'INVALID_TRAINING_MODULE' }, 400);
      }
    } else {
      const firstModule = await db.prepare('SELECT id FROM training_modules ORDER BY created_at ASC LIMIT 1').first();
      if (firstModule && firstModule.id) {
        effectiveModuleId = firstModule.id as string;
      } else {
        effectiveModuleId = 'mod-practical-core';
        await db.prepare(`
          INSERT OR IGNORE INTO training_modules (id, category, type, level, title, description)
          VALUES ('mod-practical-core', 'Architectural', 'Module', 'Practical', 'Studio Practical Training', 'Practical architectural drafting assignment')
        `).run();
      }
    }

    const formattedAddress = instructions
      ? (projectAddress && projectAddress !== 'Draughtsman Studio Scope' ? `${projectAddress} — Instructions: ${instructions}` : `Instructions: ${instructions}`)
      : projectAddress;

    const assignmentId = crypto.randomUUID();
    const studentName = (studentUser.name as string) || (studentUser.email as string) || 'Student';

    const batch = [
      db.prepare(`
        INSERT INTO projects (
          id, client_id, project_name, project_address, drawing_name, drawing_type,
          project_area, status, draughtsman_id, draughtsman_name, current_assignment_id,
          assigned_at, submitted_at, created_at, last_action_id, correction_round,
          is_training_project, training_module_id
        ) VALUES (?, ?, ?, ?, ?, ?, ?, 'WAITING_ACCEPTANCE', ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, ?, 0, 1, ?)
      `).bind(projectId, uid, projectName, formattedAddress, drawingName, drawingType, projectArea, studentId, studentName, assignmentId, actionId, effectiveModuleId),
      db.prepare(`
        INSERT INTO student_assignments (id, project_id, student_id, assignment_type, status)
        VALUES (?, ?, ?, 'PRACTICAL', 'PENDING')
      `).bind(assignmentId, projectId, studentId),
      db.prepare(`
        INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details)
        VALUES (?, ?, 'STUDENT_ASSIGNED', ?, ?, ?)
      `).bind(
        actionId, projectId, uid, user.role,
        `Studio Admin created and assigned practical project "${projectName}" to student: ${studentName}`
      ),
      db.prepare(`
        INSERT INTO notifications (id, user_id, project_id, type, title, message)
        VALUES (?, ?, ?, 'NEW_ASSIGNMENT', ?, ?)
      `).bind(
        crypto.randomUUID(), studentId, projectId,
        `New Practical Assignment: ${projectName}`,
        `You have been assigned to project: "${projectName}". Please review instructions and accept to begin drafting.`
      )
    ];

    await db.batch(batch);
    return c.json({ success: true, id: projectId, assignmentId }, 201);
  }

  // ── BRANCH B: Commercial Project for Engineer Client (Preserved) ──────────
  if (!clientId) {
    return c.json({ error: 'Associated Engineer (clientId) is required', code: 'INVALID_CLIENT' }, 400);
  }

  // Verify associated client exists and is an Engineer/Client
  const clientUser = await getUser(db, clientId);
  if (!clientUser || !['ENGINEER', 'CLIENT'].includes(clientUser.role as string)) {
    return c.json({ error: 'Specified client must be a registered Engineer', code: 'INVALID_ENGINEER' }, 400);
  }

  if (clientUser.status === 'SUSPENDED') {
    return c.json({ error: 'Cannot initiate project for a suspended Engineer account', code: 'ACCOUNT_SUSPENDED' }, 403);
  }

  const batch = [
    db.prepare(`
      INSERT INTO projects (
        id, client_id, project_name, project_address, drawing_name, drawing_type,
        project_area, status, submitted_at, created_at, last_action_id, correction_round
      ) VALUES (?, ?, ?, ?, ?, ?, ?, 'SUBMITTED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, ?, 0)
    `).bind(projectId, clientId, projectName, projectAddress, drawingName, drawingType, projectArea, actionId),
    db.prepare(`
      INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details)
      VALUES (?, ?, ?, ?, ?, ?)
    `).bind(
      actionId, projectId, 'PROJECT_CREATED_BY_ADMIN', uid, user.role,
      `Studio Admin initiated project on behalf of Engineer: ${(clientUser.name as string) || (clientUser.email as string) || clientId}`
    ),
    db.prepare(`
      INSERT INTO notifications (id, user_id, project_id, type, title, message)
      VALUES (?, ?, ?, 'NEW_PROJECT', 'Project Initiated', 'An architectural drafting project has been initiated on your behalf.')
    `).bind(crypto.randomUUID(), clientId, projectId)
  ];

  await db.batch(batch);
  return c.json({ success: true, id: projectId }, 201);
});

// ==========================================
// PROJECT CANCELLATION ENDPOINT
// ==========================================

app.post('/api/projects/cancel', async (c) => {
  const uid = c.get('uid');
  const db = c.env.DB;
  const body = await c.req.json().catch(() => ({}));
  const { projectId, actionId, reason } = body;

  const user = await getUser(db, uid);
  if (!user) return c.json({ error: 'User not found' }, 404);

  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  if (!project) return c.json({ error: 'Project not found' }, 404);

  const isAdmin = ['STUDIO_ADMIN', 'ADMIN'].includes(user.role as string);
  const isOwner = (user.role === 'ENGINEER' || user.role === 'CLIENT') && project.client_id === uid;
  if (!isAdmin && !isOwner) {
    return c.json({ error: 'Permission denied' }, 403);
  }

  if (project.status === 'CANCELLED' && project.last_action_id === actionId) {
    return c.json({ success: true });
  }

  const batch = [
    db.prepare(`UPDATE projects SET status = 'CANCELLED', rejection_reason = COALESCE(?, rejection_reason), cancelled_at = CURRENT_TIMESTAMP, last_action_id = ? WHERE id = ?`).bind(reason || 'Cancelled by admin', actionId || uuidv4(), projectId),
    db.prepare(`INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details) VALUES (?, ?, ?, ?, ?, ?)`).bind(
      actionId || uuidv4(), projectId, 'PROJECT_CANCELLED', uid, user.role, `Project was cancelled: ${reason || 'No reason provided'}`
    )
  ];
  await db.batch(batch);
  return c.json({ success: true });
});

registerLegalRoutes(app);

export default app;