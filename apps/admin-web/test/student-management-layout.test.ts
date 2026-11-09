import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

describe('Admin Portal — Student Management Interface Layout Tests', () => {
  const studentsPagePath = path.resolve(process.cwd(), 'src/app/students/page.tsx');
  const pageContent = fs.readFileSync(studentsPagePath, 'utf-8');

  const sidebarPath = path.resolve(process.cwd(), 'src/components/layout/Sidebar.tsx');
  const sidebarContent = fs.readFileSync(sidebarPath, 'utf-8');

  test('Page retains exact title "Student Management"', () => {
    assert.match(
      pageContent,
      /title="Student Management"/,
      'Page title must remain "Student Management"'
    );
  });

  test('Preserves the three Student Overview KPI cards intact', () => {
    assert.match(pageContent, /Total Enrolled Students/);
    assert.match(pageContent, /Student Portal Status/);
    assert.match(pageContent, /Learning Curriculums/);
  });

  test('Displays the Student Management buttons in a dedicated action row', () => {
    assert.match(
      pageContent,
      /grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3 sm:gap-4 mb-6/,
      'Must contain a responsive grid on desktop for the student options'
    );
  });

  test('Contains all exact button labels with no extra descriptions or complex wording', () => {
    assert.match(pageContent, /<span>Assign Projects<\/span>/);
    assert.match(pageContent, /<span>Training Modules<\/span>/);
    assert.match(pageContent, /<span>Learning Plans<\/span>/);
    assert.match(pageContent, /<span>Student Progress<\/span>/);
    assert.match(pageContent, /<span>Student Submissions<\/span>/);
    assert.match(pageContent, /<span>Certificate & Registry<\/span>/);
  });

  test('Each button navigates to the corresponding existing feature interface', () => {
    assert.match(pageContent, /href="\/teaching\/assignments"/);
    assert.match(pageContent, /href="\/teaching\/modules"/);
    assert.match(pageContent, /href="\/teaching\/learning-plans"/);
    assert.match(pageContent, /href="\/teaching\/progress"/);
    assert.match(pageContent, /href="\/students\/submissions"/);
    assert.match(pageContent, /href="\/certificates"/);
  });

  test('Visual styling matches the Archi Draft reference button specifications', () => {
    assert.match(pageContent, /bg-\[#0d1c32\]/);
    assert.match(pageContent, /hover:bg-\[#15294a\]/);
    assert.match(pageContent, /text-white text-xs font-mono font-semibold/);
    assert.match(pageContent, /rounded-xl/);
    assert.match(pageContent, /border border-slate-800/);
  });

  test('Action row is positioned above the Student Directory search bar and table', () => {
    const actionRowIndex = pageContent.indexOf('Student Management Action Row');
    const searchBarIndex = pageContent.indexOf('Control Toolbar & Demo Fixture Switcher');
    const tableIndex = pageContent.indexOf('Student Directory Table');

    assert.ok(actionRowIndex !== -1, 'Action row must exist');
    assert.ok(searchBarIndex !== -1, 'Search bar must exist');
    assert.ok(tableIndex !== -1, 'Directory table must exist');

    assert.ok(
      actionRowIndex < searchBarIndex,
      'Action row must be positioned above search toolbar'
    );
    assert.ok(
      searchBarIndex < tableIndex,
      'Search toolbar must be positioned above directory table'
    );
  });

  test('Search input and student table directory functionality are preserved', () => {
    assert.match(pageContent, /placeholder="Search by student name, college, email\.\.\."/);
    assert.match(pageContent, /paginatedStudents\.map/);
    assert.match(pageContent, /openAssignProjectModal/);
    assert.match(pageContent, /openStudentDetails/);
  });

  test('Sidebar has completely removed the Teaching Students category', () => {
    assert.equal(
      sidebarContent.includes("'Teaching Students'"),
      false,
      'Teaching Students category must not exist in Sidebar'
    );
    assert.equal(
      sidebarContent.includes("'Assign Projects'"),
      false,
      'Assign Projects link must not exist in Sidebar'
    );
    assert.equal(
      sidebarContent.includes("'Training Modules'"),
      false,
      'Training Modules link must not exist in Sidebar'
    );
    assert.equal(
      sidebarContent.includes("'Student Learning Plans'"),
      false,
      'Student Learning Plans link must not exist in Sidebar'
    );
    assert.equal(
      sidebarContent.includes("'Student Progress'"),
      false,
      'Student Progress link must not exist in Sidebar'
    );
  });

  test('Sidebar has exact required categories in order: Overview, Quick Access, Settings & Support (with Workflow removed)', () => {
    assert.match(sidebarContent, /title:\s*'Overview'/);
    assert.match(sidebarContent, /title:\s*'Quick Access'/);
    assert.match(sidebarContent, /title:\s*'(?:Settings|SETTINGS & SUPPORT)'/);
    assert.equal(sidebarContent.includes("title: 'Workflow'"), false);
  });

  test('Sidebar does not contain Student Submissions outside in Workflow', () => {
    assert.equal(
      sidebarContent.includes("'Student Submissions'"),
      false,
      'Student Submissions must not appear in the Sidebar'
    );
  });

  test('Sidebar Quick Access category contains single Students entry pointing to /students', () => {
    assert.match(
      sidebarContent,
      /name:\s*'Students',\s*href:\s*'\/students',\s*icon:\s*GraduationCap/
    );
  });
});
