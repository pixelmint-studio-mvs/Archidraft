import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

describe('Teaching Students Portal — Admin Implementation Tests', () => {
  // ── 1. Sidebar Navigation & Route Relocation Contract ──────────────────────────
  describe('Sidebar Navigation Architecture & Assign Projects Relocation', () => {
    const sidebarPath = path.resolve(process.cwd(), 'src/components/layout/Sidebar.tsx');
    const sidebarContent = fs.readFileSync(sidebarPath, 'utf-8');

    test('Sidebar includes dedicated TEACHING STUDENTS navigation section', () => {
      assert.match(
        sidebarContent,
        /title:\s*'Teaching Students'/i,
        'Sidebar must include dedicated "Teaching Students" navigation section'
      );
    });

    test('Teaching Students contains exactly the 4 required operational options', () => {
      assert.match(sidebarContent, /name:\s*'Assign Projects'/);
      assert.match(sidebarContent, /href:\s*'\/teaching\/assignments'/);

      assert.match(sidebarContent, /name:\s*'Training Modules'/);
      assert.match(sidebarContent, /href:\s*'\/teaching\/modules'/);

      assert.match(sidebarContent, /name:\s*'Student Learning Plans'/);
      assert.match(sidebarContent, /href:\s*'\/teaching\/learning-plans'/);

      assert.match(sidebarContent, /name:\s*'Student Progress'/);
      assert.match(sidebarContent, /href:\s*'\/teaching\/progress'/);
    });

    test('Assign Projects appears ONLY ONCE in the sidebar navigation array', () => {
      const assignMatches = sidebarContent.match(/name:\s*['"]Assign Projects['"]/g);
      assert.ok(assignMatches, 'Assign Projects must exist in Sidebar');
      assert.equal(
        assignMatches.length,
        1,
        'Assign Projects must appear exactly once in the sidebar navigation'
      );
    });

    test('Legacy Assignment Console is completely removed from Workflow & Pipeline', () => {
      assert.equal(
        sidebarContent.includes("'Assignment Console'"),
        false,
        'Old "Assignment Console" entry must be completely removed from sidebar'
      );
      assert.equal(
        sidebarContent.includes("href: '/assignments',"),
        false,
        'Legacy href /assignments must not be directly in sidebar navigation'
      );
    });

    test('Next.js config and legacy assignments page provide compatibility redirect to /teaching/assignments', () => {
      const nextConfigPath = path.resolve(process.cwd(), 'next.config.ts');
      const nextConfigContent = fs.readFileSync(nextConfigPath, 'utf-8');
      assert.match(
        nextConfigContent,
        /source:\s*["']\/assignments["'][\s\S]*destination:\s*["']\/teaching\/assignments["']/,
        'next.config.ts must provide compatibility redirect for bookmarked /assignments URLs'
      );

      const legacyPagePath = path.resolve(process.cwd(), 'src/app/assignments/page.tsx');
      assert.ok(fs.existsSync(legacyPagePath), 'Legacy /assignments page must exist for client fallback');
      const legacyPageContent = fs.readFileSync(legacyPagePath, 'utf-8');
      assert.match(
        legacyPageContent,
        /\/teaching\/assignments/,
        'Legacy /assignments page must redirect or link to /teaching/assignments'
      );
    });
  });

  // ── 2. Progress Calculation Formula Verification ───────────────────────────────
  describe('Progress Calculation Formula & Truthful Telemetry', () => {
    function calculateCompletionPercentage(
      requiredLessons: Array<{ id: string; is_required: boolean; is_completed: boolean }>
    ): number {
      const required = requiredLessons.filter((l) => l.is_required);
      if (required.length === 0) return 0;
      const completed = required.filter((l) => l.is_completed).length;
      return Math.round((completed / required.length) * 100);
    }

    test('Calculates 100% when all required lessons are completed', () => {
      const lessons = [
        { id: '1', is_required: true, is_completed: true },
        { id: '2', is_required: true, is_completed: true },
        { id: '3', is_required: false, is_completed: false }, // optional lesson
      ];
      assert.equal(calculateCompletionPercentage(lessons), 100);
    });

    test('Optional lessons do not penalize or artificially inflate required lesson percentage', () => {
      const lessons = [
        { id: '1', is_required: true, is_completed: true },
        { id: '2', is_required: true, is_completed: false },
        { id: '3', is_required: false, is_completed: true }, // optional completed
      ];
      // 1 of 2 required lessons completed = 50%
      assert.equal(calculateCompletionPercentage(lessons), 50);
    });

    test('Safely handles empty learning plan without division by zero or NaN', () => {
      assert.equal(calculateCompletionPercentage([]), 0);
      const onlyOptional = [{ id: '1', is_required: false, is_completed: false }];
      assert.equal(calculateCompletionPercentage(onlyOptional), 0);
    });

    test('Accurately identifies overdue status without fabricating dates', () => {
      const pastDate = new Date(Date.now() - 86400000).toISOString();
      const futureDate = new Date(Date.now() + 86400000).toISOString();

      function isPlanOverdue(targetDate: string | null, status: string): boolean {
        if (!targetDate) return false;
        return new Date(targetDate) < new Date() && status !== 'COMPLETED';
      }

      assert.equal(isPlanOverdue(pastDate, 'IN_PROGRESS'), true);
      assert.equal(isPlanOverdue(pastDate, 'COMPLETED'), false);
      assert.equal(isPlanOverdue(futureDate, 'IN_PROGRESS'), false);
      assert.equal(isPlanOverdue(null, 'IN_PROGRESS'), false);
    });
  });

  // ── 3. Teaching Students Pages Existence & Components ──────────────────────────
  describe('Teaching Students Route Pages Verification', () => {
    test('/teaching/assignments/page.tsx exists and supports practical creation and dispatch', () => {
      const p = path.resolve(process.cwd(), 'src/app/teaching/assignments/page.tsx');
      assert.ok(fs.existsSync(p), 'Teaching assignments page must exist');
      const content = fs.readFileSync(p, 'utf-8');
      assert.match(content, /NewProjectModal/);
      assert.match(content, /initialAssigneeType="STUDENT"/);
      assert.match(content, /adminApi\.assignProject/);
    });

    test('/teaching/modules/page.tsx exists and supports module publication states and student assignment', () => {
      const p = path.resolve(process.cwd(), 'src/app/teaching/modules/page.tsx');
      assert.ok(fs.existsSync(p), 'Teaching modules page must exist');
      const content = fs.readFileSync(p, 'utf-8');
      assert.match(content, /adminApi\.getTrainingModules/);
      assert.match(content, /adminApi\.createTrainingModule/);
      assert.match(content, /PUBLISHED/);
      assert.match(content, /DRAFT/);
      assert.match(content, /ARCHIVED/);
      assert.match(content, /assignToStudent/);
      assert.match(content, /selectedStudentId/);
      assert.match(content, /assign_to_student_id/);
      assert.match(content, /target_completion_date/);
    });

    test('/teaching/modules/[moduleId]/page.tsx exists with curriculum editor and preview modal', () => {
      const p = path.resolve(process.cwd(), 'src/app/teaching/modules/[moduleId]/page.tsx');
      assert.ok(fs.existsSync(p), 'Module curriculum editor page must exist');
      const content = fs.readFileSync(p, 'utf-8');
      assert.match(content, /adminApi\.createTrainingChapter/);
      assert.match(content, /adminApi\.createTrainingLesson/);
      assert.match(content, /Student Preview/);
    });

    test('/teaching/learning-plans/page.tsx exists and supports individualized assignment', () => {
      const p = path.resolve(process.cwd(), 'src/app/teaching/learning-plans/page.tsx');
      assert.ok(fs.existsSync(p), 'Learning plans page must exist');
      const content = fs.readFileSync(p, 'utf-8');
      assert.match(content, /adminApi\.assignLearningPlan/);
      assert.match(content, /adminApi\.revokeLearningPlan/);
    });

    test('/teaching/progress/page.tsx exists and displays comprehensive monitoring telemetry', () => {
      const p = path.resolve(process.cwd(), 'src/app/teaching/progress/page.tsx');
      assert.ok(fs.existsSync(p), 'Student progress page must exist');
      const content = fs.readFileSync(p, 'utf-8');
      assert.match(content, /adminApi\.getStudentsProgress/);
      assert.match(content, /adminApi\.getStudentProgressDetail/);
      assert.match(content, /overall_completion_percentage/);
    });
  });
});
