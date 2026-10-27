import { describe, it } from 'node:test';
import assert from 'node:assert';

describe('Admin Web Sidebar Navigation & Role Count Contracts', () => {
  // Helper modeling the Sidebar's count resolution logic
  function resolveSidebarCounts(stats: {
    projects?: { total?: number };
    users?: {
      byRole?: Record<string, number>;
      registeredEngineers?: number;
    };
  }) {
    return {
      projects: stats.projects?.total ?? 0,
      engineers:
        stats.users?.registeredEngineers ??
        ((stats.users?.byRole?.['CLIENT'] ?? 0) + (stats.users?.byRole?.['ENGINEER'] ?? 0)),
      draughtsmen: stats.users?.byRole?.['DRAUGHTSMAN'] ?? 0,
      students: stats.users?.byRole?.['STUDENT'] ?? 0,
    };
  }

  it('uses authoritative registeredEngineers metric from backend when present', () => {
    const mockStats = {
      projects: { total: 12 },
      users: {
        registeredEngineers: 8,
        byRole: {
          CLIENT: 8,
          DRAUGHTSMAN: 5,
          STUDENT: 20,
        },
      },
    };

    const counts = resolveSidebarCounts(mockStats);
    assert.strictEqual(counts.projects, 12);
    assert.strictEqual(counts.engineers, 8);
    assert.strictEqual(counts.draughtsmen, 5);
    assert.strictEqual(counts.students, 20);
  });

  it('aggregates both CLIENT and canonical ENGINEER records without double counting when registeredEngineers is absent', () => {
    const mockStats = {
      projects: { total: 5 },
      users: {
        byRole: {
          CLIENT: 4,
          ENGINEER: 3,
          DRAUGHTSMAN: 6,
          STUDENT: 15,
        },
      },
    };

    const counts = resolveSidebarCounts(mockStats);
    assert.strictEqual(counts.engineers, 7, 'Should sum CLIENT (4) and ENGINEER (3) to 7');
    assert.strictEqual(counts.draughtsmen, 6);
    assert.strictEqual(counts.students, 15);
  });

  it('gracefully handles missing or empty stats by defaulting all counts to 0', () => {
    const emptyStats = {};
    const counts = resolveSidebarCounts(emptyStats);

    assert.strictEqual(counts.projects, 0);
    assert.strictEqual(counts.engineers, 0);
    assert.strictEqual(counts.draughtsmen, 0);
    assert.strictEqual(counts.students, 0);
  });

  it('keeps Draughtsmen and Students count badges completely isolated from Engineer counts', () => {
    const mockStats = {
      users: {
        byRole: {
          DRAUGHTSMAN: 14,
          STUDENT: 32,
        },
      },
    };

    const counts = resolveSidebarCounts(mockStats);
    assert.strictEqual(counts.engineers, 0);
    assert.strictEqual(counts.draughtsmen, 14);
    assert.strictEqual(counts.students, 32);
  });
});
