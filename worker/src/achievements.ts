export interface AchievementDto {
  id: string;
  title: string;
  description: string;
  category: string;
  icon: string;
  isUnlocked: boolean;
  unlockedAt: string | null;
  currentProgress: number;
  targetProgress: number;
}

export function formatTimestamp(raw: any): string | null {
  if (!raw) return null;
  if (typeof raw === 'string') {
    const normalized = raw.includes('T') ? raw : raw.replace(' ', 'T') + (raw.endsWith('Z') ? '' : 'Z');
    const d = new Date(normalized);
    if (!isNaN(d.getTime())) {
      return d.toISOString();
    }
  }
  const d = new Date(raw);
  if (!isNaN(d.getTime())) {
    return d.toISOString();
  }
  return String(raw);
}

export async function getStudentAchievements(db: D1Database, uid: string): Promise<AchievementDto[]> {
  const [
    lessonResult,
    moduleResult,
    projectResult,
    evalResult,
    credResult
  ] = await db.batch([
    // 1. First Lesson Completed: Student has completed at least one training lesson
    db.prepare(`
      SELECT COUNT(id) as count, MIN(completed_at) as earliest_at
      FROM student_lesson_progress
      WHERE student_id = ? AND status = 'COMPLETED'
    `).bind(uid),

    // 2. Foundational Master: Student has completed at least one training module
    db.prepare(`
      SELECT 
        (SELECT COUNT(id) FROM student_progress WHERE student_id = ? AND status = 'Completed') as sp_count,
        (SELECT MIN(COALESCE(updated_at, CURRENT_TIMESTAMP)) FROM student_progress WHERE student_id = ? AND status = 'Completed') as sp_earliest,
        (SELECT COUNT(id) FROM student_credentials WHERE student_id = ? AND type = 'MODULE_COMPLETION') as cred_count,
        (SELECT MIN(issued_at) FROM student_credentials WHERE student_id = ? AND type = 'MODULE_COMPLETION') as cred_earliest
    `).bind(uid, uid, uid, uid),

    // 3. Studio Ready: Student has completed at least one practical project in student workflow
    db.prepare(`
      SELECT COUNT(p.id) as count, MIN(COALESCE(p.approved_at, p.created_at)) as earliest_at
      FROM projects p
      JOIN student_assignments sa ON p.id = sa.project_id
      WHERE sa.student_id = ? AND p.status = 'COMPLETED' AND p.is_training_project = 1
    `).bind(uid),

    // 4. First Approved Drawing: Student received at least one approved evaluation on submitted work
    db.prepare(`
      SELECT COUNT(e.id) as count, MIN(e.created_at) as earliest_at
      FROM evaluations e
      JOIN projects p ON e.project_id = p.id
      JOIN student_assignments sa ON p.id = sa.project_id
      WHERE sa.student_id = ? AND p.is_training_project = 1 AND e.overall_result = 'APPROVED'
    `).bind(uid),

    // 5. Certified Draughtsman: Student has earned at least one formal credential
    db.prepare(`
      SELECT COUNT(id) as count, MIN(issued_at) as earliest_at
      FROM student_credentials
      WHERE student_id = ?
    `).bind(uid)
  ]);

  const lessonRow: any = lessonResult.results?.[0] || {};
  const lessonCount = Number(lessonRow.count || 0);
  const lessonUnlocked = lessonCount > 0;
  const lessonEarliest = lessonUnlocked ? formatTimestamp(lessonRow.earliest_at) : null;

  const moduleRow: any = moduleResult.results?.[0] || {};
  const moduleCount = Number(moduleRow.sp_count || 0) + Number(moduleRow.cred_count || 0);
  const moduleUnlocked = moduleCount > 0;
  const moduleEarliest = moduleUnlocked ? formatTimestamp(moduleRow.sp_earliest || moduleRow.cred_earliest) : null;

  const projectRow: any = projectResult.results?.[0] || {};
  const projectCount = Number(projectRow.count || 0);
  const projectUnlocked = projectCount > 0;
  const projectEarliest = projectUnlocked ? formatTimestamp(projectRow.earliest_at) : null;

  const evalRow: any = evalResult.results?.[0] || {};
  const evalCount = Number(evalRow.count || 0);
  const evalUnlocked = evalCount > 0;
  const evalEarliest = evalUnlocked ? formatTimestamp(evalRow.earliest_at) : null;

  const credRow: any = credResult.results?.[0] || {};
  const credCount = Number(credRow.count || 0);
  const credUnlocked = credCount > 0;
  const credEarliest = credUnlocked ? formatTimestamp(credRow.earliest_at) : null;

  return [
    {
      id: 'first_lesson_completed',
      title: 'First Blueprint Step',
      description: 'Completed your first training lesson',
      category: 'LEARNING',
      icon: 'school_outlined',
      isUnlocked: lessonUnlocked,
      unlockedAt: lessonEarliest,
      currentProgress: lessonUnlocked ? 1 : 0,
      targetProgress: 1,
    },
    {
      id: 'first_module_completed',
      title: 'Foundational Master',
      description: 'Completed your first training module',
      category: 'LEARNING',
      icon: 'workspace_premium_outlined',
      isUnlocked: moduleUnlocked,
      unlockedAt: moduleEarliest,
      currentProgress: moduleUnlocked ? 1 : 0,
      targetProgress: 1,
    },
    {
      id: 'first_practical_project_completed',
      title: 'Studio Ready',
      description: 'Completed your first practical project assignment',
      category: 'PRACTICAL',
      icon: 'assignment_turned_in_outlined',
      isUnlocked: projectUnlocked,
      unlockedAt: projectEarliest,
      currentProgress: projectUnlocked ? 1 : 0,
      targetProgress: 1,
    },
    {
      id: 'first_approved_drawing',
      title: 'First Approved Drawing',
      description: 'Received an approved evaluation on submitted drawing work',
      category: 'PRACTICAL',
      icon: 'verified_outlined',
      isUnlocked: evalUnlocked,
      unlockedAt: evalEarliest,
      currentProgress: evalUnlocked ? 1 : 0,
      targetProgress: 1,
    },
    {
      id: 'first_credential_earned',
      title: 'Certified Draughtsman',
      description: 'Earned your first official course or project credential',
      category: 'ACHIEVEMENT',
      icon: 'military_tech_outlined',
      isUnlocked: credUnlocked,
      unlockedAt: credEarliest,
      currentProgress: credUnlocked ? 1 : 0,
      targetProgress: 1,
    },
  ];
}
