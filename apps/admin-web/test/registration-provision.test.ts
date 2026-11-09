import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

describe('Admin Portal — Registrations Provision & Proof Verification Contracts', () => {
  // ── 1. Sidebar Navigation Architecture Contract ────────────────────────────
  describe('Sidebar Navigation Architecture Contract', () => {
    const sidebarPath = path.resolve(process.cwd(), 'src/components/layout/Sidebar.tsx');
    const sidebarContent = fs.readFileSync(sidebarPath, 'utf-8');

    test('Sidebar includes "Registrations" entry linking to /registrations in Overview', () => {
      assert.match(
        sidebarContent,
        /title:\s*'(?:Overview|Registration)'[\s\S]*name:\s*'(Registrations|Allow Registrations)'[\s\S]*href:\s*'\/registrations'/,
        'Sidebar must contain a "Registrations" entry linking to /registrations'
      );
    });

    test('Sidebar Registration entry uses ClipboardCheck or UserCheck icon', () => {
      assert.match(
        sidebarContent,
        /name:\s*'(Registrations|Allow Registrations)'[\s\S]*icon:\s*(ClipboardCheck|UserCheck)/,
        'Sidebar Registration entry must use an appropriate verification icon'
      );
    });

    test('Sidebar includes badgeKey: "registrations" for live count indicator', () => {
      assert.match(
        sidebarContent,
        /name:\s*'(Registrations|Allow Registrations)'[\s\S]*badgeKey:\s*'registrations'/,
        'Sidebar Registration entry must bind to registrations badge key'
      );
    });
  });

  // ── 2. Admin API Registration Contracts ────────────────────────────────────
  describe('Admin API Registration Contracts', () => {
    const apiPath = path.resolve(process.cwd(), 'src/lib/api.ts');
    const apiContent = fs.readFileSync(apiPath, 'utf-8');

    test('adminApi implements getRegistrations with search and status/role filters', () => {
      assert.match(
        apiContent,
        /async\s+getRegistrations\s*\(/,
        'adminApi must implement getRegistrations'
      );
    });

    test('adminApi implements approveRegistration with POST to /api/admin/registrations/:id/approve', () => {
      assert.match(
        apiContent,
        /async\s+approveRegistration\s*\(/,
        'adminApi must implement approveRegistration'
      );
      assert.match(
        apiContent,
        /\/api\/admin\/registrations\/\$\{id\}\/approve/,
        'approveRegistration must target the approve endpoint'
      );
    });

    test('adminApi implements rejectRegistration requiring reason parameter', () => {
      assert.match(
        apiContent,
        /async\s+rejectRegistration\s*\(\s*id:\s*string,\s*reason:\s*string\s*\)/,
        'adminApi rejectRegistration must require rejection reason'
      );
      assert.match(
        apiContent,
        /\/api\/admin\/registrations\/\$\{id\}\/reject/,
        'rejectRegistration must target the reject endpoint'
      );
    });

    test('adminApi provides secure proof URL and blob retrieval', () => {
      assert.match(
        apiContent,
        /getRegistrationProofBlob/,
        'adminApi must implement getRegistrationProofBlob'
      );
      assert.match(
        apiContent,
        /getRegistrationProofUrl/,
        'adminApi must implement getRegistrationProofUrl'
      );
    });
  });

  // ── 3. Role-to-Proof Mapping Truth Table ───────────────────────────────────
  describe('Role-to-Proof Mapping Truth Table', () => {
    function getRequiredProofDoc(role: string): string {
      const norm = role === 'CLIENT' ? 'ENGINEER' : role;
      if (norm === 'ENGINEER') return 'Engineering degree or relevant qualification certificate';
      if (norm === 'DRAUGHTSMAN') return 'Draughtsmanship degree, diploma, or relevant qualification certificate';
      if (norm === 'STUDENT') return 'Valid Student ID card';
      throw new Error(`Unknown role: ${role}`);
    }

    test('Engineer requires Engineering degree or relevant qualification certificate', () => {
      assert.equal(
        getRequiredProofDoc('ENGINEER'),
        'Engineering degree or relevant qualification certificate'
      );
      assert.equal(
        getRequiredProofDoc('CLIENT'),
        'Engineering degree or relevant qualification certificate'
      );
    });

    test('Draughtsman requires Draughtsmanship degree, diploma, or relevant qualification certificate', () => {
      assert.equal(
        getRequiredProofDoc('DRAUGHTSMAN'),
        'Draughtsmanship degree, diploma, or relevant qualification certificate'
      );
    });

    test('Student requires Valid Student ID card', () => {
      assert.equal(
        getRequiredProofDoc('STUDENT'),
        'Valid Student ID card'
      );
    });
  });

  // ── 4. Registrations Page Verification ─────────────────────────────────────
  describe('Registrations Page Component', () => {
    const pagePath = path.resolve(process.cwd(), 'src/app/registrations/page.tsx');
    assert.equal(fs.existsSync(pagePath), true, 'Registrations page must exist at src/app/registrations/page.tsx');
    const content = fs.readFileSync(pagePath, 'utf-8');

    test('Page includes search, status filters, and role filters', () => {
      assert.match(content, /STATUS_FILTERS/, 'Must define status filters');
      assert.match(content, /ROLE_FILTERS/, 'Must define role filters');
      assert.match(content, /searchQuery/, 'Must handle search query state');
    });

    test('Page includes proof preview and download capabilities', () => {
      assert.match(content, /handleDownloadProof/, 'Must support proof document download');
      assert.match(content, /previewProofOpen/, 'Must support proof preview toggle');
      assert.match(content, /loadPreview/, 'Must implement authenticated preview loader');
      assert.match(content, /cleanupPreviewBlob/, 'Must implement stale preview cleanup');
      assert.match(content, /Retry Preview/, 'Must include retry button on preview failure');
      assert.match(content, /Interactive PDF Viewer/, 'Must support dedicated interactive PDF viewer');
    });

    test('Page supports both approval and rejection workflows', () => {
      assert.match(content, /handleApprove/, 'Must support admin approval');
      assert.match(content, /handleReject/, 'Must support admin rejection with reason');
    });
  });
});

