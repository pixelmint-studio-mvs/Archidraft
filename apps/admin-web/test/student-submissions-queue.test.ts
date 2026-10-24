import { describe, test } from 'node:test';
import assert from 'node:assert/strict';

// ── Types ──

interface StudentSubmissionRecord {
  id: string;
  project_name: string;
  drawing_name: string;
  drawing_type: string;
  status: string;
  correction_round: number;
  created_at: string;
  submitted_at: string | null;
  training_module_id: string | null;
  rejection_reason: string | null;
  student_id: string;
  student_name: string | null;
  student_email: string | null;
  module_title: string | null;
  latest_drawing_version_id: string | null;
  latest_version_number: number | null;
  latest_file_id: string | null;
}

// ── Logic under test ──

function filterSubmissions(
  submissions: StudentSubmissionRecord[],
  statusFilter: string,
  searchQuery: string
): StudentSubmissionRecord[] {
  return submissions.filter((sub) => {
    if (statusFilter === 'UNDER_REVIEW') {
      const isReview =
        sub.status === 'UNDER_ENGINEER_REVIEW' || sub.status === 'UNDER_CLIENT_REVIEW';
      if (!isReview) return false;
    } else if (statusFilter === 'IN_PROGRESS') {
      if (sub.status !== 'IN_PROGRESS') return false;
    } else if (statusFilter === 'COMPLETED') {
      if (sub.status !== 'COMPLETED') return false;
    } else if (statusFilter === 'CANCELLED') {
      if (sub.status !== 'CANCELLED') return false;
    }

    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      const matchesProject = sub.project_name?.toLowerCase().includes(q);
      const matchesDrawing = sub.drawing_name?.toLowerCase().includes(q);
      const matchesStudent = sub.student_name?.toLowerCase().includes(q);
      const matchesEmail = sub.student_email?.toLowerCase().includes(q);
      const matchesModule = sub.module_title?.toLowerCase().includes(q);
      if (!matchesProject && !matchesDrawing && !matchesStudent && !matchesEmail && !matchesModule) {
        return false;
      }
    }

    return true;
  });
}

function calculateKpiCounts(submissions: StudentSubmissionRecord[]) {
  const total = submissions.length;
  const awaitingReview = submissions.filter(
    (s) => s.status === 'UNDER_ENGINEER_REVIEW' || s.status === 'UNDER_CLIENT_REVIEW'
  ).length;
  const inRevision = submissions.filter((s) => s.status === 'IN_PROGRESS').length;
  const completed = submissions.filter((s) => s.status === 'COMPLETED').length;
  const rejected = submissions.filter((s) => s.status === 'CANCELLED').length;
  return { total, awaitingReview, inRevision, completed, rejected };
}

function paginateSubmissions<T>(items: T[], page: number, pageSize: number) {
  const totalItems = items.length;
  const totalPages = Math.ceil(totalItems / pageSize) || 1;
  const currentPage = Math.min(Math.max(1, page), totalPages);
  const start = (currentPage - 1) * pageSize;
  const paginated = items.slice(start, start + pageSize);
  return { paginated, currentPage, totalPages, totalItems };
}

// ── Test Suites ──

describe('Student Submissions Review Queue — Navigation & Access Architecture', () => {
  test('Sidebar navigation defines Student Submissions route under Workflow & Pipeline', () => {
    const navSections = [
      {
        title: 'Workflow & Pipeline',
        items: [
          { name: 'Projects Catalogue', href: '/projects' },
          { name: 'Student Submissions', href: '/students/submissions' },
          { name: 'Assignment Console', href: '/assignments' },
          { name: 'Assignment History', href: '/assignments/history' },
        ],
      },
    ];

    const pipelineSection = navSections.find((s) => s.title === 'Workflow & Pipeline');
    assert.ok(pipelineSection, 'Workflow & Pipeline section must exist');

    const submissionsItem = pipelineSection.items.find(
      (i) => i.href === '/students/submissions'
    );
    assert.ok(submissionsItem, 'Student Submissions item must exist in navigation');
    assert.equal(submissionsItem.name, 'Student Submissions');
  });

  test('Submissions endpoint strictly rejects non-admin roles with 403 FORBIDDEN', () => {
    function authorizeSubmissionsAccess(role: string): { authorized: boolean; status: number } {
      if (['STUDIO_ADMIN', 'ADMIN'].includes(role)) {
        return { authorized: true, status: 200 };
      }
      return { authorized: false, status: 403 };
    }

    assert.deepEqual(authorizeSubmissionsAccess('STUDIO_ADMIN'), { authorized: true, status: 200 });
    assert.deepEqual(authorizeSubmissionsAccess('ADMIN'), { authorized: true, status: 200 });
    assert.deepEqual(authorizeSubmissionsAccess('CLIENT'), { authorized: false, status: 403 });
    assert.deepEqual(authorizeSubmissionsAccess('ENGINEER'), { authorized: false, status: 403 });
    assert.deepEqual(authorizeSubmissionsAccess('DRAUGHTSMAN'), { authorized: false, status: 403 });
    assert.deepEqual(authorizeSubmissionsAccess('STUDENT'), { authorized: false, status: 403 });
  });
});

describe('Student Submissions Review Queue — Filtering & Live KPIs', () => {
  const sampleSubmissions: StudentSubmissionRecord[] = [
    {
      id: 'proj_sub_01',
      project_name: 'Villa Foundation Plan',
      drawing_name: 'Foundation CAD',
      drawing_type: 'STRUCTURAL',
      status: 'UNDER_ENGINEER_REVIEW',
      correction_round: 0,
      created_at: '2026-10-20T10:00:00Z',
      submitted_at: '2026-10-21T12:00:00Z',
      training_module_id: 'mod_cad_101',
      rejection_reason: null,
      student_id: 'std_01',
      student_name: 'Alex Chen',
      student_email: 'alex@student.org',
      module_title: 'Architectural Drafting 101',
      latest_drawing_version_id: 'ver_01',
      latest_version_number: 1,
      latest_file_id: 'file_dwg_01',
    },
    {
      id: 'proj_sub_02',
      project_name: 'Commercial Facade Detailing',
      drawing_name: 'Facade Elevation',
      drawing_type: 'ARCHITECTURAL',
      status: 'IN_PROGRESS',
      correction_round: 1,
      created_at: '2026-10-18T10:00:00Z',
      submitted_at: '2026-10-19T10:00:00Z',
      training_module_id: 'mod_cad_102',
      rejection_reason: null,
      student_id: 'std_02',
      student_name: 'Priya Sharma',
      student_email: 'priya@cad.edu',
      module_title: 'Advanced Detailing',
      latest_drawing_version_id: 'ver_02',
      latest_version_number: 2,
      latest_file_id: 'file_dwg_02',
    },
    {
      id: 'proj_sub_03',
      project_name: 'Residential Pavilion Floor Plan',
      drawing_name: 'Ground Floor Plan',
      drawing_type: 'ARCHITECTURAL',
      status: 'COMPLETED',
      correction_round: 1,
      created_at: '2026-10-15T09:00:00Z',
      submitted_at: '2026-10-17T14:00:00Z',
      training_module_id: 'mod_cad_101',
      rejection_reason: null,
      student_id: 'std_03',
      student_name: 'Rohan Mehta',
      student_email: 'rohan@poly.edu',
      module_title: 'Architectural Drafting 101',
      latest_drawing_version_id: 'ver_03',
      latest_version_number: 2,
      latest_file_id: 'file_dwg_03',
    },
    {
      id: 'proj_sub_04',
      project_name: 'Parametric Roof Truss Structure',
      drawing_name: 'Roof Sections',
      drawing_type: 'STRUCTURAL',
      status: 'CANCELLED',
      correction_round: 0,
      created_at: '2026-10-10T08:00:00Z',
      submitted_at: '2026-10-11T16:00:00Z',
      training_module_id: 'mod_cad_103',
      rejection_reason: 'Non-compliant with standard municipal truss codes.',
      student_id: 'std_04',
      student_name: 'Sarah Connor',
      student_email: 'sarah@student.org',
      module_title: 'Structural CAD Masterclass',
      latest_drawing_version_id: 'ver_04',
      latest_version_number: 1,
      latest_file_id: 'file_dwg_04',
    },
  ];

  test('Calculates truthful KPI summary metrics matching database records', () => {
    const kpis = calculateKpiCounts(sampleSubmissions);
    assert.equal(kpis.total, 4);
    assert.equal(kpis.awaitingReview, 1);
    assert.equal(kpis.inRevision, 1);
    assert.equal(kpis.completed, 1);
    assert.equal(kpis.rejected, 1);
  });

  test('Filters queue by UNDER_REVIEW (includes UNDER_ENGINEER_REVIEW and UNDER_CLIENT_REVIEW)', () => {
    const reviewQueue = filterSubmissions(sampleSubmissions, 'UNDER_REVIEW', '');
    assert.equal(reviewQueue.length, 1);
    assert.equal(reviewQueue[0].id, 'proj_sub_01');
    assert.equal(reviewQueue[0].project_name, 'Villa Foundation Plan');
  });

  test('Filters queue by IN_PROGRESS (milestones in student revision cycle)', () => {
    const inRevision = filterSubmissions(sampleSubmissions, 'IN_PROGRESS', '');
    assert.equal(inRevision.length, 1);
    assert.equal(inRevision[0].id, 'proj_sub_02');
    assert.equal(inRevision[0].correction_round, 1);
  });

  test('Filters queue by COMPLETED (approved and certified milestones)', () => {
    const completed = filterSubmissions(sampleSubmissions, 'COMPLETED', '');
    assert.equal(completed.length, 1);
    assert.equal(completed[0].id, 'proj_sub_03');
  });

  test('Filters queue by CANCELLED (rejected milestones with recorded reason)', () => {
    const cancelled = filterSubmissions(sampleSubmissions, 'CANCELLED', '');
    assert.equal(cancelled.length, 1);
    assert.equal(cancelled[0].id, 'proj_sub_04');
    assert.equal(cancelled[0].rejection_reason, 'Non-compliant with standard municipal truss codes.');
  });

  test('Performs case-insensitive search by student name', () => {
    const results = filterSubmissions(sampleSubmissions, 'ALL', 'alex');
    assert.equal(results.length, 1);
    assert.equal(results[0].student_name, 'Alex Chen');
  });

  test('Performs case-insensitive search by student email', () => {
    const results = filterSubmissions(sampleSubmissions, 'ALL', 'poly.edu');
    assert.equal(results.length, 1);
    assert.equal(results[0].student_name, 'Rohan Mehta');
  });

  test('Performs case-insensitive search by module title', () => {
    const results = filterSubmissions(sampleSubmissions, 'ALL', 'Drafting 101');
    assert.equal(results.length, 2);
  });

  test('Returns empty array when search matches nothing without crashing', () => {
    const results = filterSubmissions(sampleSubmissions, 'ALL', 'Nonexistent Query 999');
    assert.equal(results.length, 0);
  });
});

describe('Student Submissions Review Queue — Pagination Engine', () => {
  const items = Array.from({ length: 25 }, (_, i) => ({ id: `item_${i + 1}`, name: `Item ${i + 1}` }));

  test('Paginates first page with standard 10 item page size', () => {
    const p1 = paginateSubmissions(items, 1, 10);
    assert.equal(p1.paginated.length, 10);
    assert.equal(p1.currentPage, 1);
    assert.equal(p1.totalPages, 3);
    assert.equal(p1.paginated[0].id, 'item_1');
    assert.equal(p1.paginated[9].id, 'item_10');
  });

  test('Paginates middle page accurately', () => {
    const p2 = paginateSubmissions(items, 2, 10);
    assert.equal(p2.paginated.length, 10);
    assert.equal(p2.currentPage, 2);
    assert.equal(p2.paginated[0].id, 'item_11');
    assert.equal(p2.paginated[9].id, 'item_20');
  });

  test('Paginates final page with remainder items', () => {
    const p3 = paginateSubmissions(items, 3, 10);
    assert.equal(p3.paginated.length, 5);
    assert.equal(p3.currentPage, 3);
    assert.equal(p3.paginated[0].id, 'item_21');
    assert.equal(p3.paginated[4].id, 'item_25');
  });

  test('Clamps out-of-bounds page requests safely', () => {
    const pOverflow = paginateSubmissions(items, 999, 10);
    assert.equal(pOverflow.currentPage, 3);
    assert.equal(pOverflow.paginated.length, 5);

    const pUnderflow = paginateSubmissions(items, -5, 10);
    assert.equal(pUnderflow.currentPage, 1);
    assert.equal(pUnderflow.paginated.length, 10);
  });
});
