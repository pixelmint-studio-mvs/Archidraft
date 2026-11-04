import fs from 'node:fs';
import path from 'node:path';
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

  describe('Sidebar Navigation Reorganization — Overview & Workflow Elimination', () => {
    const sidebarPath = fs.existsSync(path.resolve(process.cwd(), 'src/components/layout/Sidebar.tsx'))
      ? path.resolve(process.cwd(), 'src/components/layout/Sidebar.tsx')
      : path.resolve(process.cwd(), 'apps/admin-web/src/components/layout/Sidebar.tsx');
    const content = fs.readFileSync(sidebarPath, 'utf-8');

    it('Overview category contains Dashboard, Activity Feed, and Financials in exact order', () => {
      const overviewMatch = content.match(/title:\s*'Overview'[\s\S]*?items:\s*\[([\s\S]*?)\]/);
      assert.ok(overviewMatch, 'Overview section must exist in Sidebar.tsx');

      const itemsBlock = overviewMatch[1];
      const dashboardIdx = itemsBlock.indexOf("name: 'Dashboard'");
      const activityIdx = itemsBlock.indexOf("name: 'Activity Feed'");
      const financialsIdx = itemsBlock.indexOf("name: 'Financials'");

      assert.ok(dashboardIdx !== -1, 'Dashboard must be in Overview');
      assert.ok(activityIdx !== -1, 'Activity Feed must be in Overview');
      assert.strictEqual(itemsBlock.includes("name: 'Projects Catalogue'"), false, 'Projects Catalogue must not appear in Overview');
      assert.ok(financialsIdx !== -1, 'Financials must be in Overview');

      assert.ok(dashboardIdx < activityIdx, 'Dashboard must appear before Activity Feed');
      assert.ok(activityIdx < financialsIdx, 'Financials must appear directly below Activity Feed');
    });

    it('Financials menu item is titled "Financials" without "(Frozen)" and not duplicated in Settings', () => {
      assert.match(content, /name:\s*'Financials',\s*href:\s*'\/financials',\s*icon:\s*DollarSign/);
      assert.strictEqual(content.includes("'Financials (Frozen)'"), false);
      const occurrences = (content.match(/href:\s*'\/financials'/g) || []).length;
      assert.strictEqual(occurrences, 1, 'Financials route must appear exactly once in sidebar');
    });

    it('Projects Catalogue is removed from sidebar menu items', () => {
      assert.strictEqual(
        content.includes("name: 'Projects Catalogue'"),
        false,
        'Projects Catalogue must not appear in Sidebar.tsx'
      );
    });

    it('Workflow category is completely removed with no leftover heading or empty section', () => {
      assert.strictEqual(
        content.includes("title: 'Workflow'"),
        false,
        'Workflow category must not exist in Sidebar.tsx'
      );
    });
  });
});
