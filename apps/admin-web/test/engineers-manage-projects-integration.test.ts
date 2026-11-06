import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

function resolveAppPath(relPath: string): string {
  const insideApp = path.resolve(process.cwd(), relPath);
  if (fs.existsSync(insideApp)) return insideApp;
  return path.resolve(process.cwd(), 'apps/admin-web', relPath);
}

describe('Engineer Management & Manage Projects Integration Contracts', () => {
  const catalogueViewPath = resolveAppPath('src/components/projects/ProjectsCatalogueView.tsx');
  const engineersPagePath = resolveAppPath('src/app/engineers/page.tsx');
  const projectsPagePath = resolveAppPath('src/app/projects/page.tsx');
  const sidebarPath = resolveAppPath('src/components/layout/Sidebar.tsx');

  const catalogueContent = fs.readFileSync(catalogueViewPath, 'utf-8');
  const engineersContent = fs.readFileSync(engineersPagePath, 'utf-8');
  const projectsContent = fs.readFileSync(projectsPagePath, 'utf-8');
  const sidebarContent = fs.readFileSync(sidebarPath, 'utf-8');

  // ── 1. Sidebar Architecture Contract ──────────────────────────────────────────
  describe('1. Sidebar Architecture Contracts', () => {
    it('Projects Catalogue is eliminated as a standalone item from Overview', () => {
      const overviewMatch = sidebarContent.match(/title:\s*'Overview'[\s\S]*?items:\s*\[([\s\S]*?)\]/);
      assert.ok(overviewMatch, 'Overview section must exist in Sidebar');
      assert.strictEqual(
        overviewMatch[1].includes('Projects Catalogue'),
        false,
        'Projects Catalogue must NOT exist in Overview navigation'
      );
    });

    it('Engineers item maps to /engineers with badgeKey engineers', () => {
      assert.match(
        sidebarContent,
        /name:\s*'Engineers',\s*href:\s*'\/engineers'/
      );
    });

    it('Engineers navigation item remains active when navigating to /projects routes', () => {
      assert.ok(
        sidebarContent.includes("(item.href === '/engineers' && pathname.startsWith('/projects'))"),
        'Sidebar must highlight Engineers when accessing /projects or /projects/[id]'
      );
    });
  });

  // ── 2. Segmented Tab Navigation on Engineers Page ───────────────────────────
  describe('2. Segmented Tab Navigation Contracts', () => {
    it('Defines segmented tabs for [Engineers] and [Manage Projects]', () => {
      assert.ok(engineersContent.includes("handleTabChange('engineers')"));
      assert.ok(engineersContent.includes("handleTabChange('projects')"));
      assert.ok(engineersContent.includes("Manage Projects"));
    });

    it('Synchronizes tab state with URL query parameter ?tab=', () => {
      assert.ok(engineersContent.includes("searchParams.get('tab') === 'projects'"));
      assert.ok(engineersContent.includes("params.set('tab', newTab)"));
      assert.ok(engineersContent.includes("router.replace"));
    });

    it('Renders ProjectsCatalogueView when tab=projects is active', () => {
      assert.ok(engineersContent.includes('<ProjectsCatalogueView'));
      assert.ok(engineersContent.includes('isEmbedded={true}'));
    });

    it('Wraps EngineersPage in Suspense for Next.js searchParams compliance', () => {
      assert.ok(engineersContent.includes('<Suspense'));
      assert.ok(engineersContent.includes('<EngineersContent />'));
    });
  });

  // ── 3. Backward Compatible Route Redirection ─────────────────────────────────
  describe('3. Route Backward Compatibility Contracts', () => {
    it('/projects route redirects gracefully to /engineers?tab=projects', () => {
      assert.ok(projectsContent.includes("params.set('tab', 'projects')"));
      assert.ok(projectsContent.includes("router.replace(`/engineers?${params.toString()}`)"));
    });

    it('/projects route preserves query parameters such as status filters during redirect', () => {
      assert.ok(projectsContent.includes('new URLSearchParams(searchParams.toString())'));
    });
  });

  // ── 4. Contextual Administrative Actions Contract ────────────────────────────
  describe('4. Contextual Administrative Actions Contracts', () => {
    it('Provides canonical STATUS_FILTERS covering all 10 lifecycle states', () => {
      assert.ok(catalogueContent.includes("value: 'ALL'"));
      assert.ok(catalogueContent.includes("value: 'SUBMITTED'"));
      assert.ok(catalogueContent.includes("value: 'WAITING_ASSIGNMENT'"));
      assert.ok(catalogueContent.includes("value: 'WAITING_ACCEPTANCE'"));
      assert.ok(catalogueContent.includes("value: 'IN_PROGRESS'"));
      assert.ok(catalogueContent.includes("value: 'UNDER_ADMIN_REVIEW'"));
      assert.ok(catalogueContent.includes("value: 'UNDER_CLIENT_REVIEW'"));
      assert.ok(catalogueContent.includes("value: 'COMPLETED'"));
      assert.ok(catalogueContent.includes("value: 'CANCELLED'"));
      assert.ok(catalogueContent.includes("value: 'DRAFT'"));
    });

    it('Implements status-specific Primary Action buttons', () => {
      // SUBMITTED -> Approve & Prepare Assignment
      assert.ok(catalogueContent.includes('Approve & Prepare Assignment'));
      // WAITING_ASSIGNMENT -> Assign Draughtsman
      assert.ok(catalogueContent.includes('Assign Draughtsman'));
      // WAITING_ACCEPTANCE -> Reassign
      assert.ok(catalogueContent.includes('Reassign'));
      // IN_PROGRESS -> View Workspace
      assert.ok(catalogueContent.includes('View Workspace'));
      // UNDER_ADMIN_REVIEW -> Review Drawing
      assert.ok(catalogueContent.includes('Review Drawing'));
      // UNDER_CLIENT_REVIEW / UNDER_ENGINEER_REVIEW -> View Review Status
      assert.ok(catalogueContent.includes('View Review Status'));
      // COMPLETED -> Download Approved Package
      assert.ok(catalogueContent.includes('Download Approved Package'));
      // CANCELLED -> View Cancellation Details
      assert.ok(catalogueContent.includes('View Cancellation Details'));
    });

    it('Implements compact 3-dot dropdown menu for secondary administrative actions', () => {
      assert.ok(catalogueContent.includes('MoreHorizontal'));
      assert.ok(catalogueContent.includes('ActionDropdown'));
      assert.ok(catalogueContent.includes('View Project Details'));
      assert.ok(catalogueContent.includes('View Activity History'));
      assert.ok(catalogueContent.includes('Reject Submission'));
      assert.ok(catalogueContent.includes('Cancel Project'));
      assert.ok(catalogueContent.includes('Remove Project'));
    });

    it('Includes Cancellation Details modal displaying audit trail and rationale', () => {
      assert.ok(catalogueContent.includes('CancellationDetailsModal'));
      assert.ok(catalogueContent.includes('Project Cancellation Dossier'));
      assert.ok(catalogueContent.includes('project.rejection_reason'));
    });
  });
});
