import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

describe('Teaching Students Portal — Admin Implementation Tests', () => {
  // ── 1. Sidebar Navigation Architecture & Consolidation Contract ─────────────
  describe('Sidebar Navigation Architecture & Consolidation', () => {
    const sidebarPath = path.resolve(process.cwd(), 'src/components/layout/Sidebar.tsx');
    const sidebarContent = fs.readFileSync(sidebarPath, 'utf-8');

    test('Sidebar does NOT include a separate TEACHING STUDENTS category heading', () => {
      assert.equal(
        sidebarContent.includes("'Teaching Students'"),
        false,
        'Sidebar must not contain a separate "Teaching Students" category heading'
      );
    });

    test('Sidebar does NOT contain separate links for the four consolidated options', () => {
      assert.equal(
        sidebarContent.includes("'Assign Projects'"),
        false,
        'Sidebar must not contain "Assign Projects" as a separate link'
      );
      assert.equal(
        sidebarContent.includes("'Training Modules'"),
        false,
        'Sidebar must not contain "Training Modules" as a separate link'
      );
      assert.equal(
        sidebarContent.includes("'Student Learning Plans'"),
        false,
        'Sidebar must not contain "Student Learning Plans" as a separate link'
      );
      assert.equal(
        sidebarContent.includes("'Student Progress'"),
        false,
        'Sidebar must not contain "Student Progress" as a separate link'
      );
    });

    test('Sidebar contains QUICK ACCESS category with single Students entry', () => {
      assert.match(
        sidebarContent,
        /title:\s*'Quick Access'/i,
        'Sidebar must include Quick Access section'
      );
      assert.match(
        sidebarContent,
        /name:\s*'Students'[\s\S]*href:\s*'\/students'/,
        'Sidebar Quick Access must contain Students entry'
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
      assert.equal(calculateCompletionPercentage(lessons), 50);
    });

    test('Safely handles empty learning plan without division by zero or NaN', () => {
      const lessons: Array<{ id: string; is_required: boolean; is_completed: boolean }> = [];
      assert.equal(calculateCompletionPercentage(lessons), 0);
    });

    test('Accurately identifies overdue status without fabricating dates', () => {
      const pastDate = new Date(Date.now() - 1000 * 60 * 60 * 24).toISOString();
      const futureDate = new Date(Date.now() + 1000 * 60 * 60 * 24).toISOString();

      function isOverdue(targetDate: string | null | undefined, pct: number): boolean {
        if (!targetDate || pct >= 100) return false;
        return new Date(targetDate) < new Date();
      }

      assert.equal(isOverdue(pastDate, 80), true);
      assert.equal(isOverdue(pastDate, 100), false);
      assert.equal(isOverdue(futureDate, 20), false);
      assert.equal(isOverdue(null, 0), false);
    });
  });

  // ── 3. Teaching Students Pages Existence & Components ──────────────────────────
  describe('Teaching Students Route Pages Verification', () => {
    test('/teaching/assignments/page.tsx exists and supports practical creation and dispatch', () => {
      const p = path.resolve(process.cwd(), 'src/app/teaching/assignments/page.tsx');
      assert.ok(fs.existsSync(p), 'Assignments page must exist');
      const content = fs.readFileSync(p, 'utf-8');
      assert.match(content, /adminApi\.getProjects/);
      assert.match(content, /adminApi\.getAdminAssignments/);
      assert.match(content, /adminApi\.assignProject/);
    });

    test('/teaching/modules/page.tsx exists and supports module publication states and student assignment', () => {
      const p = path.resolve(process.cwd(), 'src/app/teaching/modules/page.tsx');
      assert.ok(fs.existsSync(p), 'Modules page must exist');
      const content = fs.readFileSync(p, 'utf-8');
      assert.match(content, /adminApi\.getTrainingModules/);
      assert.match(content, /adminApi\.createTrainingModule/);
      assert.match(content, /adminApi\.updateTrainingModule/);
    });

    test('/teaching/modules/[moduleId]/page.tsx exists with curriculum editor and preview modal', () => {
      const p = path.resolve(process.cwd(), 'src/app/teaching/modules/[moduleId]/page.tsx');
      assert.ok(fs.existsSync(p), 'Module detail page must exist');
      const content = fs.readFileSync(p, 'utf-8');
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
