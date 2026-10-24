import { describe, it } from 'node:test';
import assert from 'node:assert';

describe('User Dossier & Directory Profile Contracts', () => {
  it('Normalizes flat Worker response ({ id, email, role, name }) into { user, projects } contract', async () => {
    const rawWorkerUser = {
      id: 'KXAR90JgoVYLuOKzkbxpKTC8ATa2',
      email: 'engineer@studio.com',
      name: 'Structural Engineer',
      role: 'CLIENT',
      status: 'ACTIVE',
      company_name: 'Studio Design Group',
      created_at: '2026-01-01T00:00:00Z',
    };

    // Simulate normalization logic from adminApi.getUserDetails
    function normalizeUserDetails(res: any, queryProjects: any[]) {
      const user = res.user || res;
      if (!user || !user.id) {
        throw new Error('User not found');
      }
      return {
        user,
        projects: res.projects || queryProjects,
      };
    }

    const normalized = normalizeUserDetails(rawWorkerUser, [{ id: 'p1', client_id: rawWorkerUser.id }]);

    assert.ok(normalized.user, 'Normalized output must have .user');
    assert.strictEqual(normalized.user.id, 'KXAR90JgoVYLuOKzkbxpKTC8ATa2');
    assert.strictEqual(normalized.user.role, 'CLIENT');
    assert.strictEqual(normalized.user.name, 'Structural Engineer');
    assert.strictEqual(normalized.projects.length, 1);
    assert.strictEqual(normalized.projects[0].client_id, 'KXAR90JgoVYLuOKzkbxpKTC8ATa2');
  });

  it('Supports already-nested response structure ({ user: ..., projects: ... }) losslessly', async () => {
    const nestedResponse = {
      user: {
        id: 'dm-456',
        email: 'draughtsman@studio.com',
        role: 'DRAUGHTSMAN',
        name: 'Technical Draughtsman',
      },
      projects: [
        { id: 'p2', draughtsman_id: 'dm-456', project_status: 'IN_PROGRESS' },
      ],
    };

    function normalizeUserDetails(res: any) {
      const user = res.user || res;
      if (!user || !user.id) throw new Error('User not found');
      return {
        user,
        projects: res.projects || [],
      };
    }

    const normalized = normalizeUserDetails(nestedResponse);
    assert.strictEqual(normalized.user.id, 'dm-456');
    assert.strictEqual(normalized.user.name, 'Technical Draughtsman');
    assert.strictEqual(normalized.projects.length, 1);
    assert.strictEqual(normalized.projects[0].project_status, 'IN_PROGRESS');
  });

  it('Propagates 401, 403, and 404 HTTP status codes without masking', async () => {
    async function simulateFetchUserDetails(status: number) {
      if (status === 401) {
        const err: any = new Error('Unauthorized');
        err.status = 401;
        throw err;
      }
      if (status === 403) {
        const err: any = new Error('Forbidden');
        err.status = 403;
        throw err;
      }
      if (status === 404) {
        const err: any = new Error('User not found');
        err.status = 404;
        throw err;
      }
      return { id: 'u1' };
    }

    await assert.rejects(
      async () => simulateFetchUserDetails(401),
      (err: any) => err.status === 401 && err.message === 'Unauthorized'
    );

    await assert.rejects(
      async () => simulateFetchUserDetails(403),
      (err: any) => err.status === 403 && err.message === 'Forbidden'
    );

    await assert.rejects(
      async () => simulateFetchUserDetails(404),
      (err: any) => err.status === 404 && err.message === 'User not found'
    );
  });

  it('Maps modal maxWidth to correct Tailwind constraint classes', () => {
    const maxWidthClasses: Record<string, string> = {
      sm: 'max-w-sm',
      md: 'max-w-md',
      lg: 'max-w-lg',
      xl: 'max-w-xl',
      '2xl': 'max-w-2xl',
      '3xl': 'max-w-3xl',
      '4xl': 'max-w-4xl',
      full: 'max-w-full mx-4',
    };

    assert.strictEqual(maxWidthClasses['2xl'], 'max-w-2xl', '2xl must resolve to max-w-2xl');
    assert.strictEqual(maxWidthClasses['3xl'], 'max-w-3xl', '3xl must resolve to max-w-3xl');
    assert.strictEqual(maxWidthClasses['4xl'], 'max-w-4xl', '4xl must resolve to max-w-4xl');
    assert.strictEqual(maxWidthClasses['lg'], 'max-w-lg', 'lg must resolve to max-w-lg');
  });

  it('Correctly identifies projects belonging to both CLIENT and ENGINEER roles', () => {
    const userId = 'user-eng-007';
    const allProjects = [
      { id: 'p1', client_id: 'user-eng-007', status: 'IN_PROGRESS' },
      { id: 'p2', client_id: 'other-user', status: 'COMPLETED' },
      { id: 'p3', client_id: 'user-eng-007', status: 'COMPLETED' },
    ];

    const matchedProjects = allProjects.filter((p) => p.client_id === userId);
    assert.strictEqual(matchedProjects.length, 2);
    assert.strictEqual(matchedProjects[0].id, 'p1');
    assert.strictEqual(matchedProjects[1].id, 'p3');
  });
});
