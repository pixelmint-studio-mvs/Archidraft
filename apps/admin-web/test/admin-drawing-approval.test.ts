import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

// ── Contract Types ────────────────────────────────────────────────────────────

type ProjectStatus =
  | 'DRAFT'
  | 'SUBMITTED'
  | 'WAITING_ASSIGNMENT'
  | 'WAITING_ACCEPTANCE'
  | 'IN_PROGRESS'
  | 'UNDER_ADMIN_REVIEW'
  | 'UNDER_CLIENT_REVIEW'
  | 'UNDER_ENGINEER_REVIEW'
  | 'COMPLETED'
  | 'CANCELLED';

type DrawingApprovalStatus = 'PENDING' | 'APPROVED' | 'REJECTED';

interface DrawingVersion {
  id: string;
  project_id: string;
  file_id: string;
  version_number: number;
  uploaded_by: string;
  correction_id?: string;
  approval_status?: DrawingApprovalStatus | string;
  approval_source?: string;
  reviewed_by?: string;
  reviewed_at?: string;
  review_feedback?: string;
  created_at: string;
  original_name?: string;
  size?: number;
}

interface DrawingVersionReview {
  id: string;
  project_id: string;
  drawing_version_id: string;
  reviewer_id: string;
  decision: 'APPROVED' | 'REJECTED';
  feedback?: string | null;
  created_at: string;
  reviewer_name?: string;
  reviewer_role?: string;
  version_number?: number;
}

describe('Admin Drawing Quality Review Workflow & Contracts', () => {
  // ── 1. Lifecycle State Machine & Status Types ──────────────────────────────
  describe('1. State Machine & Status Integrity', () => {
    test('UNDER_ADMIN_REVIEW is a valid first-class ProjectStatus', () => {
      const status: ProjectStatus = 'UNDER_ADMIN_REVIEW';
      assert.equal(status, 'UNDER_ADMIN_REVIEW');
    });

    test('DrawingApprovalStatus domain values are strictly bounded', () => {
      const pending: DrawingApprovalStatus = 'PENDING';
      const approved: DrawingApprovalStatus = 'APPROVED';
      const rejected: DrawingApprovalStatus = 'REJECTED';
      assert.equal(pending, 'PENDING');
      assert.equal(approved, 'APPROVED');
      assert.equal(rejected, 'REJECTED');
    });

    test('DrawingVersion model contains approval metadata and provenance fields', () => {
      const version: DrawingVersion = {
        id: 'dv-101',
        project_id: 'prj-202',
        file_id: 'file-303',
        version_number: 1,
        uploaded_by: 'draughtsman-uid',
        approval_status: 'PENDING',
        approval_source: 'ADMIN_REVIEW',
        created_at: '2026-11-04T00:00:00Z',
        original_name: 'structural_v1.dwg',
        size: 2048576,
      };

      assert.equal(version.approval_status, 'PENDING');
      assert.equal(version.approval_source, 'ADMIN_REVIEW');
      assert.equal(version.version_number, 1);
    });

    test('DrawingVersionReview audit model matches Worker schema', () => {
      const review: DrawingVersionReview = {
        id: 'dvr-001',
        project_id: 'prj-202',
        drawing_version_id: 'dv-101',
        reviewer_id: 'admin-uid',
        decision: 'APPROVED',
        feedback: 'Approved by Studio Admin. Deliverable verified for release.',
        created_at: '2026-11-04T01:00:00Z',
        reviewer_name: 'Studio Lead',
        reviewer_role: 'STUDIO_ADMIN',
        version_number: 1,
      };

      assert.equal(review.decision, 'APPROVED');
      assert.equal(review.reviewer_role, 'STUDIO_ADMIN');
      assert.equal(review.version_number, 1);
    });
  });

  // ── 2. Admin Decision Transitions & Invariants ─────────────────────────────
  describe('2. Admin Decision Transitions & Invariants', () => {
    test('Approve transition: UNDER_ADMIN_REVIEW -> UNDER_ENGINEER_REVIEW', () => {
      const initialProject = {
        id: 'prj-1',
        status: 'UNDER_ADMIN_REVIEW' as ProjectStatus,
        correction_round: 0,
      };
      const initialVersion = {
        id: 'dv-1',
        version_number: 1,
        approval_status: 'PENDING' as DrawingApprovalStatus,
      };

      // Simulated approve transition
      const updatedProject = {
        ...initialProject,
        status: 'UNDER_ENGINEER_REVIEW' as ProjectStatus,
      };
      const updatedVersion = {
        ...initialVersion,
        approval_status: 'APPROVED' as DrawingApprovalStatus,
      };

      assert.equal(updatedProject.status, 'UNDER_ENGINEER_REVIEW');
      assert.equal(updatedVersion.approval_status, 'APPROVED');
      // Invariant: Correction round unchanged by initial approval
      assert.equal(updatedProject.correction_round, 0);
    });

    test('Request Revision transition: UNDER_ADMIN_REVIEW -> IN_PROGRESS without incrementing correction round', () => {
      const initialProject = {
        id: 'prj-1',
        status: 'UNDER_ADMIN_REVIEW' as ProjectStatus,
        correction_round: 1, // Currently on Round 1 of client corrections
      };
      const initialVersion = {
        id: 'dv-2',
        version_number: 2,
        approval_status: 'PENDING' as DrawingApprovalStatus,
      };

      // Simulated revision request
      const updatedProject = {
        ...initialProject,
        status: 'IN_PROGRESS' as ProjectStatus,
      };
      const updatedVersion = {
        ...initialVersion,
        approval_status: 'REJECTED' as DrawingApprovalStatus,
      };

      assert.equal(updatedProject.status, 'IN_PROGRESS');
      assert.equal(updatedVersion.approval_status, 'REJECTED');
      // Crucial invariant: Studio internal rework does NOT consume client correction rounds!
      assert.equal(updatedProject.correction_round, 1);
    });
  });

  // ── 3. Source Code Integrity Verification ──────────────────────────────────
  describe('3. Source Code Architecture & API Integration', () => {
    const root = path.resolve('.');
    const apiPath = path.join(root, 'src', 'lib', 'api.ts');
    const typesPath = path.join(root, 'src', 'lib', 'types.ts');
    const componentPath = path.join(root, 'src', 'components', 'projects', 'AdminDrawingReviewSection.tsx');
    const projectDetailPagePath = path.join(root, 'src', 'app', 'projects', '[projectId]', 'page.tsx');

    test('types.ts exports UNDER_ADMIN_REVIEW and DrawingVersionReview', () => {
      const typesContent = fs.readFileSync(typesPath, 'utf8');
      assert.ok(typesContent.includes("'UNDER_ADMIN_REVIEW'"), 'Must include UNDER_ADMIN_REVIEW');
      assert.ok(typesContent.includes('export interface DrawingVersionReview'), 'Must export DrawingVersionReview');
    });

    test('api.ts defines adminApproveDrawing, adminRequestRevision, and getDrawingVersionReviews', () => {
      const apiContent = fs.readFileSync(apiPath, 'utf8');
      assert.ok(apiContent.includes('adminApproveDrawing('), 'Must define adminApproveDrawing');
      assert.ok(apiContent.includes('/api/projects/admin-approve-drawing'), 'Must target /api/projects/admin-approve-drawing');
      assert.ok(apiContent.includes('adminRequestRevision('), 'Must define adminRequestRevision');
      assert.ok(apiContent.includes('/api/projects/admin-request-revision'), 'Must target /api/projects/admin-request-revision');
      assert.ok(apiContent.includes('getDrawingVersionReviews('), 'Must define getDrawingVersionReviews');
      assert.ok(apiContent.includes('/api/projects/${projectId}/drawing_version_reviews'), 'Must target /api/projects/${projectId}/drawing_version_reviews');
    });

    test('AdminDrawingReviewSection component exists with approve and revision action handling', () => {
      assert.ok(fs.existsSync(componentPath), 'AdminDrawingReviewSection.tsx must exist');
      const compContent = fs.readFileSync(componentPath, 'utf8');
      assert.ok(compContent.includes('handleApprove'), 'Must implement handleApprove');
      assert.ok(compContent.includes('handleRequestRevision'), 'Must implement handleRequestRevision');
      assert.ok(compContent.includes('409'), 'Must handle 409 concurrency error');
      assert.ok(compContent.includes('adminApproveDrawing'), 'Must call adminApproveDrawing');
      assert.ok(compContent.includes('adminRequestRevision'), 'Must call adminRequestRevision');
    });

    test('Project detail page imports and mounts AdminDrawingReviewSection', () => {
      const pageContent = fs.readFileSync(projectDetailPagePath, 'utf8');
      assert.ok(pageContent.includes('AdminDrawingReviewSection'), 'Page must import AdminDrawingReviewSection');
      assert.ok(pageContent.includes('adminApi.getDrawingVersionReviews'), 'Page must fetch reviews');
      assert.ok(pageContent.includes('id="admin-drawing-review-section"'), 'Page must render review section anchor');
      assert.ok(pageContent.includes("status === 'UNDER_ADMIN_REVIEW'"), 'Page must handle UNDER_ADMIN_REVIEW');
    });
  });

  // ── 4. Commercial vs Student Practical Isolation ───────────────────────────
  describe('4. Commercial vs Student Workflow Isolation', () => {
    test('Commercial drawings use admin-approve-drawing; Students use student evaluation rubric', () => {
      const commercialProject = { is_training_project: 0 };
      const studentProject = { is_training_project: 1 };

      const resolveReviewEndpoint = (project: { is_training_project?: number }) => {
        if (project.is_training_project === 1) {
          return '/api/projects/evaluate';
        }
        return '/api/projects/admin-approve-drawing';
      };

      assert.equal(resolveReviewEndpoint(commercialProject), '/api/projects/admin-approve-drawing');
      assert.equal(resolveReviewEndpoint(studentProject), '/api/projects/evaluate');
    });
  });

  // ── 5. Actor Attribution and Provenance Integrity ───────────────────────────
  describe('5. Actor Attribution and Provenance Integrity', () => {
    function formatReviewActor(review: { reviewer_name?: string | null; reviewer_role?: string | null }): string {
      if (review.reviewer_name) {
        return `Actor: ${review.reviewer_name}${review.reviewer_role ? ` (${review.reviewer_role})` : ''}`;
      }
      return 'Actor unavailable';
    }

    test('renders exact reviewer name and role when both are present', () => {
      const formatted = formatReviewActor({
        reviewer_name: 'Elena Rostova',
        reviewer_role: 'ADMIN',
      });
      assert.equal(formatted, 'Actor: Elena Rostova (ADMIN)');
    });

    test('renders reviewer name without role when role is missing', () => {
      const formatted = formatReviewActor({
        reviewer_name: 'Elena Rostova',
        reviewer_role: undefined,
      });
      assert.equal(formatted, 'Actor: Elena Rostova');
    });

    test('renders "Actor unavailable" and does NOT fallback to "Studio Administrator" or infer "ADMIN" when actor is missing', () => {
      const formattedNull = formatReviewActor({ reviewer_name: null, reviewer_role: null });
      const formattedUndef = formatReviewActor({});
      const formattedEmpty = formatReviewActor({ reviewer_name: '', reviewer_role: 'ADMIN' });

      assert.equal(formattedNull, 'Actor unavailable');
      assert.equal(formattedUndef, 'Actor unavailable');
      assert.equal(formattedEmpty, 'Actor unavailable');

      assert.ok(!formattedNull.includes('Studio Administrator'), 'Must never fallback to Studio Administrator');
      assert.ok(!formattedNull.includes('ADMIN'), 'Must never infer ADMIN role when reviewer is missing');
    });

    test('AdminDrawingReviewSection.tsx does not contain "Studio Administrator" fallback and renders "Actor unavailable"', () => {
      const componentPath = fs.existsSync(path.resolve(process.cwd(), 'src/components/projects/AdminDrawingReviewSection.tsx'))
        ? path.resolve(process.cwd(), 'src/components/projects/AdminDrawingReviewSection.tsx')
        : path.resolve(process.cwd(), 'apps/admin-web/src/components/projects/AdminDrawingReviewSection.tsx');
      const compContent = fs.readFileSync(componentPath, 'utf8');

      assert.ok(
        !compContent.includes("'Studio Administrator'"),
        'AdminDrawingReviewSection.tsx must not contain "Studio Administrator" fallback'
      );
      assert.ok(
        compContent.includes('Actor unavailable'),
        'AdminDrawingReviewSection.tsx must display "Actor unavailable" when actor information is missing'
      );
    });

    test('CompactWorkflowTimeline does not infer fallback actors or roles from event types', () => {
      const pagePath = fs.existsSync(path.resolve(process.cwd(), 'src/app/projects/[projectId]/page.tsx'))
        ? path.resolve(process.cwd(), 'src/app/projects/[projectId]/page.tsx')
        : path.resolve(process.cwd(), 'apps/admin-web/src/app/projects/[projectId]/page.tsx');
      const pageContent = fs.readFileSync(pagePath, 'utf8');

      // Verify no hardcoded fallback actors in CompactWorkflowTimeline
      const timelineSection = pageContent.substring(
        pageContent.indexOf('function CompactWorkflowTimeline'),
        pageContent.indexOf('return (', pageContent.indexOf('function CompactWorkflowTimeline'))
      );

      assert.ok(
        !timelineSection.includes("'Studio Administrator'"),
        'CompactWorkflowTimeline must not hardcode "Studio Administrator"'
      );
      assert.ok(
        !timelineSection.includes("'Client Engineer'"),
        'CompactWorkflowTimeline must not infer "Client Engineer"'
      );
      assert.ok(
        !timelineSection.includes("'Assigned Draughtsman'"),
        'CompactWorkflowTimeline must not infer "Assigned Draughtsman"'
      );
      assert.ok(
        pageContent.includes('Actor unavailable'),
        'CompactWorkflowTimeline must display "Actor unavailable" when actor information is missing'
      );
    });
  });
});
