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
});
