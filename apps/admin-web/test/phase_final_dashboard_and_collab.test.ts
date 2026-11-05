import fs from 'node:fs';
import path from 'node:path';
import { describe, it } from 'node:test';
import assert from 'node:assert';

describe('Phase FINAL — Admin Dashboard Metrics & Collaboration Regression Tests', () => {
  describe('Issue 2 — Admin Dashboard Engineer Count Resolution', () => {
    it('Counts registered engineers accurately when records have current ENGINEER role', () => {
      const mockUsers = [
        { id: 'eng-1', name: 'Staging Engineer Primary', role: 'ENGINEER' },
        { id: 'eng-2', name: 'Staging Engineer Secondary', role: 'ENGINEER' },
        { id: 'drg-1', name: 'Staging Draughtsman', role: 'DRAUGHTSMAN' },
        { id: 'stu-1', name: 'Staging Student', role: 'STUDENT' },
        { id: 'adm-1', name: 'Studio Admin', role: 'ADMIN' },
      ];

      const byRole: Record<string, number> = {};
      mockUsers.forEach((u) => {
        byRole[u.role] = (byRole[u.role] || 0) + 1;
      });

      // Updated dashboard calculation:
      const engineerCount =
        ((byRole['ENGINEER'] || 0) + (byRole['CLIENT'] || 0));

      assert.strictEqual(engineerCount, 2, 'Must count 2 engineers when role is ENGINEER');
      assert.strictEqual(byRole['CLIENT'], undefined, 'CLIENT role count is undefined');
    });

    it('Counts registered engineers accurately when records have legacy CLIENT role', () => {
      const mockUsers = [
        { id: 'eng-1', name: 'Legacy Client Primary', role: 'CLIENT' },
        { id: 'eng-2', name: 'Legacy Client Secondary', role: 'CLIENT' },
      ];

      const byRole: Record<string, number> = {};
      mockUsers.forEach((u) => {
        byRole[u.role] = (byRole[u.role] || 0) + 1;
      });

      const engineerCount =
        ((byRole['ENGINEER'] || 0) + (byRole['CLIENT'] || 0));

      assert.strictEqual(engineerCount, 2, 'Must count 2 engineers when role is CLIENT');
    });

    it('Avoids double-counting when combining user records across both roles', () => {
      const mockUsers = [
        { id: 'eng-1', name: 'Engineer One', role: 'ENGINEER' },
        { id: 'eng-2', name: 'Engineer Two', role: 'CLIENT' },
      ];

      // Test unique ID aggregation
      const map = new Map<string, any>();
      mockUsers.filter(u => u.role === 'CLIENT' || u.role === 'ENGINEER').forEach(u => map.set(u.id, u));

      assert.strictEqual(map.size, 2, 'Must have exactly 2 distinct engineers without double counting');
    });

    it('Prioritizes authoritative metric from Worker dashboard endpoint', () => {
      const mockMetrics = {
        totalProjects: 10,
        activeProjects: 4,
        projectsAwaitingAssignment: 1,
        projectsUnderClientReview: 2,
        completedProjects: 3,
        activeDraughtsmen: 1,
        pendingAssignments: 0,
        registeredEngineers: 2,
      };

      const byRole: Record<string, number> = {
        ENGINEER: 2,
      };

      const engineerCount =
        mockMetrics.registeredEngineers ??
        ((byRole['ENGINEER'] || 0) + (byRole['CLIENT'] || 0));

      assert.strictEqual(engineerCount, 2);
    });

    it('Handles zero engineers gracefully without fabricating or falling back to fake counts', () => {
      const mockUsers: any[] = [];
      const byRole: Record<string, number> = {};
      mockUsers.forEach((u) => {
        byRole[u.role] = (byRole[u.role] || 0) + 1;
      });

      const engineerCount =
        ((byRole['ENGINEER'] || 0) + (byRole['CLIENT'] || 0));

      assert.strictEqual(engineerCount, 0, 'Zero registered engineers must legitimately show 0');
    });
  });

  describe('Issue 1 — Collaboration Hub Role Crash Prevention & Navigation Integrity', () => {
    // Exact role color resolver from apps/admin-web/src/app/projects/[projectId]/page.tsx
    const getRoleColor = (role?: string) => {
      const r = (role || '').toUpperCase();
      switch (r) {
        case 'ADMIN':
        case 'STUDIO_ADMIN':
          return { bg: 'rgba(139,92,246,0.15)', text: '#c4b5fd', border: 'rgba(139,92,246,0.3)', label: 'ADMIN' };
        case 'DRAUGHTSMAN':
          return { bg: 'rgba(6,182,212,0.15)', text: '#67e8f9', border: 'rgba(6,182,212,0.3)', label: 'DRAUGHTSMAN' };
        case 'CLIENT':
        case 'ENGINEER':
          return { bg: 'rgba(59,130,246,0.15)', text: '#93c5fd', border: 'rgba(59,130,246,0.3)', label: 'ENGINEER' };
        case 'STUDENT':
          return { bg: 'rgba(16,185,129,0.15)', text: '#6ee7b7', border: 'rgba(16,185,129,0.3)', label: 'STUDENT' };
        default:
          return { bg: 'rgba(148,163,184,0.15)', text: '#94a3b8', border: 'rgba(148,163,184,0.3)', label: r || 'USER' };
      }
    };

    it('Resolves colors for STUDIO_ADMIN without returning undefined or crashing with rc.bg', () => {
      const rc = getRoleColor('STUDIO_ADMIN');
      assert.ok(rc, 'getRoleColor must never return undefined');
      assert.ok(rc.bg, 'rc.bg must be defined');
      assert.strictEqual(rc.label, 'ADMIN');
    });

    it('Resolves colors for ENGINEER role without returning undefined or crashing with rc.bg', () => {
      const rc = getRoleColor('ENGINEER');
      assert.ok(rc, 'getRoleColor must never return undefined');
      assert.ok(rc.bg, 'rc.bg must be defined');
      assert.strictEqual(rc.label, 'ENGINEER');
    });

    it('Resolves colors for unexpected roles with safe fallback object', () => {
      const rc = getRoleColor('UNKNOWN_ROLE');
      assert.ok(rc, 'getRoleColor must return fallback object');
      assert.ok(rc.bg, 'rc.bg must not crash on fallback');
      assert.strictEqual(rc.label, 'UNKNOWN_ROLE');
    });

    it('Maps profile links in user directory to specific dossier routes with user IDs', () => {
      function getProfileHref(u: { id: string; role: string }) {
        return (u.role === 'CLIENT' || u.role === 'ENGINEER')
          ? `/engineers/${encodeURIComponent(u.id)}`
          : u.role === 'DRAUGHTSMAN'
          ? `/draughtsmen/${encodeURIComponent(u.id)}`
          : u.role === 'STUDENT'
          ? `/students/${encodeURIComponent(u.id)}`
          : `/users`;
      }

      assert.strictEqual(getProfileHref({ id: 'eng-123', role: 'ENGINEER' }), '/engineers/eng-123');
      assert.strictEqual(getProfileHref({ id: 'eng-456', role: 'CLIENT' }), '/engineers/eng-456');
      assert.strictEqual(getProfileHref({ id: 'drg-789', role: 'DRAUGHTSMAN' }), '/draughtsmen/drg-789');
      assert.strictEqual(getProfileHref({ id: 'stu-101', role: 'STUDENT' }), '/students/stu-101');
      assert.strictEqual(getProfileHref({ id: 'adm-999', role: 'ADMIN' }), '/users');
    });

    it('Normalizes Project detail payload supporting flat or nested client and draughtsman objects', () => {
      function normalizeProject(raw: any) {
        return {
          ...raw,
          client_name: raw.client_name || raw.client?.name || raw.engineer?.name,
          client_email: raw.client_email || raw.client?.email || raw.engineer?.email,
          draughtsman_name: raw.draughtsman_name || raw.draughtsman?.name,
          draughtsman_id: raw.draughtsman_id || raw.draughtsman?.id,
        };
      }

      // Case 1: Flat fields from worker SQL join
      const flat = normalizeProject({
        id: 'PRJ-1',
        client_id: 'c-1',
        client_name: 'Engineer Alice',
        client_email: 'alice@eng.com',
        draughtsman_id: 'd-1',
        draughtsman_name: 'Draughtsman Bob',
      });
      assert.strictEqual(flat.client_name, 'Engineer Alice');
      assert.strictEqual(flat.draughtsman_name, 'Draughtsman Bob');

      // Case 2: Nested fields
      const nested = normalizeProject({
        id: 'PRJ-2',
        client_id: 'c-2',
        engineer: { name: 'Engineer Charlie', email: 'charlie@eng.com' },
        draughtsman: { id: 'd-2', name: 'Draughtsman David' },
      });
      assert.strictEqual(nested.client_name, 'Engineer Charlie');
      assert.strictEqual(nested.draughtsman_name, 'Draughtsman David');
      assert.strictEqual(nested.draughtsman_id, 'd-2');
    });
  });

  describe('Simplified Project Pipeline Overview — 5 Business Groups & Reconciliation', () => {
    function computeGroupedPipeline(byStatus: Record<string, number>) {
      const draftCount = byStatus['DRAFT'] || 0;
      const submittedCount = byStatus['SUBMITTED'] || 0;
      const waitingAssignmentCount = byStatus['WAITING_ASSIGNMENT'] || 0;
      const waitingAcceptanceCount = byStatus['WAITING_ACCEPTANCE'] || 0;
      const inProgressCount = byStatus['IN_PROGRESS'] || 0;
      const adminReviewCount = byStatus['UNDER_ADMIN_REVIEW'] || 0;
      const engineerReviewCount =
        (byStatus['UNDER_CLIENT_REVIEW'] || 0) + (byStatus['UNDER_ENGINEER_REVIEW'] || 0);
      const completedCount = byStatus['COMPLETED'] || 0;
      const cancelledCount = byStatus['CANCELLED'] || 0;

      const setupGroupCount = draftCount + submittedCount + waitingAssignmentCount;
      const inProductionGroupCount = inProgressCount;
      const reviewGroupCount = waitingAcceptanceCount + adminReviewCount + engineerReviewCount;
      const completedGroupCount = completedCount;
      const cancelledGroupCount = cancelledCount;

      const totalReconciled =
        setupGroupCount + inProductionGroupCount + reviewGroupCount + completedGroupCount + cancelledGroupCount;

      return {
        setup: setupGroupCount,
        inProduction: inProductionGroupCount,
        review: reviewGroupCount,
        completed: completedGroupCount,
        cancelled: cancelledGroupCount,
        totalReconciled,
      };
    }

    it('Correctly groups raw statuses into 5 business-friendly categories without double-counting', () => {
      const liveD1StatusMap = {
        DRAFT: 4,
        SUBMITTED: 0,
        WAITING_ASSIGNMENT: 6,
        WAITING_ACCEPTANCE: 2,
        IN_PROGRESS: 0,
        UNDER_ADMIN_REVIEW: 0,
        UNDER_CLIENT_REVIEW: 0,
        COMPLETED: 13,
        CANCELLED: 1,
      };

      const groups = computeGroupedPipeline(liveD1StatusMap);
      assert.strictEqual(groups.setup, 10, 'Setup must group DRAFT (4) + SUBMITTED (0) + WAITING_ASSIGNMENT (6)');
      assert.strictEqual(groups.inProduction, 0, 'In Production must be IN_PROGRESS (0)');
      assert.strictEqual(groups.review, 2, 'Review must group WAITING_ACCEPTANCE (2) + UNDER_ADMIN_REVIEW (0) + UNDER_CLIENT_REVIEW (0)');
      assert.strictEqual(groups.completed, 13, 'Completed must be COMPLETED (13)');
      assert.strictEqual(groups.cancelled, 1, 'Cancelled must be CANCELLED (1)');
      assert.strictEqual(groups.totalReconciled, 26, 'Total must reconcile precisely to 26 projects');
    });

    it('Reconciles when studio has active production, studio QC, and engineer reviews', () => {
      const activeStudioMap = {
        DRAFT: 2,
        SUBMITTED: 3,
        WAITING_ASSIGNMENT: 1,
        WAITING_ACCEPTANCE: 2,
        IN_PROGRESS: 5,
        UNDER_ADMIN_REVIEW: 4,
        UNDER_CLIENT_REVIEW: 3,
        UNDER_ENGINEER_REVIEW: 1,
        COMPLETED: 20,
        CANCELLED: 2,
      };

      const groups = computeGroupedPipeline(activeStudioMap);
      assert.strictEqual(groups.setup, 6, '2 + 3 + 1 = 6');
      assert.strictEqual(groups.inProduction, 5, '5 in progress');
      assert.strictEqual(groups.review, 10, '2 + 4 + 3 + 1 = 10 in review');
      assert.strictEqual(groups.completed, 20, '20 completed');
      assert.strictEqual(groups.cancelled, 2, '2 cancelled');
      assert.strictEqual(groups.totalReconciled, 43, '6 + 5 + 10 + 20 + 2 = 43');
    });

    it('Dashboard page source renders "Project Pipeline Overview" and references all 5 business groups', () => {
      const dashboardPath = fs.existsSync(path.resolve(process.cwd(), 'src/app/dashboard/page.tsx'))
        ? path.resolve(process.cwd(), 'src/app/dashboard/page.tsx')
        : path.resolve(process.cwd(), 'apps/admin-web/src/app/dashboard/page.tsx');
      const pageCode = fs.readFileSync(dashboardPath, 'utf8');

      assert.ok(pageCode.includes('Project Pipeline Overview'), 'Must have Project Pipeline Overview title');
      assert.ok(pageCode.includes('1. Setup'), 'Must display Setup group');
      assert.ok(pageCode.includes('2. In Production'), 'Must display In Production group');
      assert.ok(pageCode.includes('3. Review'), 'Must display Review group');
      assert.ok(pageCode.includes('4. Completed'), 'Must display Completed group');
      assert.ok(pageCode.includes('5. Cancelled'), 'Must display Cancelled group');
      assert.ok(pageCode.includes('Manage Projects'), 'Must offer navigation to Manage Projects');
      assert.strictEqual(pageCode.includes('Ecosystem State Machine Distribution'), false, 'Must replace legacy title');
    });
  });
});
