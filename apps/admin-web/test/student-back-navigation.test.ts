import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

describe('Admin Portal — Student Management Back Navigation Contract Tests', () => {
  const assignmentsPage = fs.readFileSync(
    path.resolve(process.cwd(), 'src/app/teaching/assignments/page.tsx'),
    'utf-8'
  );
  const modulesPage = fs.readFileSync(
    path.resolve(process.cwd(), 'src/app/teaching/modules/page.tsx'),
    'utf-8'
  );
  const learningPlansPage = fs.readFileSync(
    path.resolve(process.cwd(), 'src/app/teaching/learning-plans/page.tsx'),
    'utf-8'
  );
  const progressPage = fs.readFileSync(
    path.resolve(process.cwd(), 'src/app/teaching/progress/page.tsx'),
    'utf-8'
  );
  const submissionsPage = fs.readFileSync(
    path.resolve(process.cwd(), 'src/app/students/submissions/page.tsx'),
    'utf-8'
  );
  const adminShell = fs.readFileSync(
    path.resolve(process.cwd(), 'src/components/layout/AdminShell.tsx'),
    'utf-8'
  );
  const header = fs.readFileSync(
    path.resolve(process.cwd(), 'src/components/layout/Header.tsx'),
    'utf-8'
  );
  const sidebar = fs.readFileSync(
    path.resolve(process.cwd(), 'src/components/layout/Sidebar.tsx'),
    'utf-8'
  );
  const studentsPage = fs.readFileSync(
    path.resolve(process.cwd(), 'src/app/students/page.tsx'),
    'utf-8'
  );

  // ── 1. Five Management Sections Back Navigation Configuration ───────────────
  describe('All Five Management Sections configure Back navigation', () => {
    test('1. Assign Projects configures backHref="/students"', () => {
      assert.match(assignmentsPage, /backHref="\/students"/);
      assert.match(assignmentsPage, /backLabel="Back"/);
    });

    test('2. Training Modules configures backHref="/students"', () => {
      assert.match(modulesPage, /backHref="\/students"/);
      assert.match(modulesPage, /backLabel="Back"/);
    });

    test('3. Learning Plans configures backHref="/students"', () => {
      assert.match(learningPlansPage, /backHref="\/students"/);
      assert.match(learningPlansPage, /backLabel="Back"/);
    });

    test('4. Student Progress configures backHref="/students"', () => {
      assert.match(progressPage, /backHref="\/students"/);
      assert.match(progressPage, /backLabel="Back"/);
    });

    test('5. Student Submissions configures backHref="/students"', () => {
      assert.match(submissionsPage, /backHref="\/students"/);
      assert.match(submissionsPage, /backLabel="Back"/);
    });
  });

  // ── 2. AdminShell & Header Architecture ──────────────────────────────────────
  describe('AdminShell and Header UI Layout Contract', () => {
    test('AdminShellProps supports backHref and backLabel', () => {
      assert.match(adminShell, /backHref\?:\s*string/);
      assert.match(adminShell, /backLabel\?:\s*string/);
      assert.match(adminShell, /backHref=\{backHref\}/);
      assert.match(adminShell, /backLabel=\{backLabel\}/);
    });

    test('Header component renders single ArrowLeft with highlighting brand colors and refined UI', () => {
      assert.match(header, /backHref\?:\s*string/);
      assert.match(header, /<Link[\s\S]*href=\{backHref\}[\s\S]*>[\s\S]*<\/Link>/);
      assert.match(header, /ArrowLeft/);
      // Highlighting colors: Archi Draft Blueprint blue background, border, and text
      assert.match(header, /bg-blue-50/);
      assert.match(header, /text-\[#0453cd\]/);
      assert.match(header, /border-blue-200/);

      // Verify button appears before title h2 in DOM order
      const backButtonIdx = header.indexOf('href={backHref}');
      const titleIdx = header.indexOf('<h2');
      assert.ok(backButtonIdx !== -1, 'Back button link must exist in Header');
      assert.ok(titleIdx !== -1, 'Title h2 must exist in Header');
      assert.ok(
        backButtonIdx < titleIdx,
        'Back button must be positioned above the page title h2'
      );
    });
  });

  // ── 3. Strict Sidebar Integrity ─────────────────────────────────────────────
  describe('Sidebar Navigation Integrity', () => {
    test('Students entry remains under QUICK ACCESS pointing to /students', () => {
      assert.match(sidebar, /title:\s*'Quick Access'/);
      assert.match(sidebar, /name:\s*'Students',\s*href:\s*'\/students',\s*icon:\s*GraduationCap/);
    });

    test('Sidebar does NOT contain separate TEACHING STUDENTS category heading', () => {
      assert.equal(sidebar.includes("'Teaching Students'"), false);
    });

    test('Sidebar does NOT contain individual links for the student management options', () => {
      assert.equal(sidebar.includes("'Assign Projects'"), false);
      assert.equal(sidebar.includes("'Training Modules'"), false);
      assert.equal(sidebar.includes("'Student Learning Plans'"), false);
      assert.equal(sidebar.includes("'Student Progress'"), false);
      assert.equal(sidebar.includes("'Student Submissions'"), false);
    });
  });

  // ── 4. Student Management Homepage Intact ────────────────────────────────────
  describe('Student Management Homepage Integrity (/students)', () => {
    test('Displays all five options side-by-side in responsive grid', () => {
      assert.match(
        studentsPage,
        /grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3 sm:gap-4 mb-6/
      );
      assert.match(studentsPage, /href="\/teaching\/assignments"/);
      assert.match(studentsPage, /href="\/teaching\/modules"/);
      assert.match(studentsPage, /href="\/teaching\/learning-plans"/);
      assert.match(studentsPage, /href="\/teaching\/progress"/);
      assert.match(studentsPage, /href="\/students\/submissions"/);
    });
  });
});

