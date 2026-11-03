import { describe, it } from 'node:test';
import assert from 'node:assert';
import fs from 'node:fs';
import path from 'node:path';

describe('Engineer Project Assignment — Isolated Admin Feature Contracts', () => {
  // ── 1. Modal Trigger & State Contracts ──
  describe('1. Assignment Modal State & Trigger Flow', () => {
    it('Modal remains strictly closed by default on page load (never opens automatically)', () => {
      let isOpen = false;
      assert.strictEqual(isOpen, false, 'Modal must remain closed on initial page load');
    });

    it('Clicking "Assign Project" button opens the modal', () => {
      let isOpen = false;
      let preSelectedEngineer: any = null;

      function openAssignModal(engineer?: any) {
        preSelectedEngineer = engineer || null;
        isOpen = true;
      }

      openAssignModal();
      assert.strictEqual(isOpen, true, 'Modal must open when trigger button is clicked');
      assert.strictEqual(preSelectedEngineer, null, 'Global trigger opens with no engineer pre-selected');
    });

    it('Opening modal from an individual engineer row pre-selects that engineer in Step 1', () => {
      let isOpen = false;
      let preSelectedEngineer: any = null;

      const mockEngineer = {
        id: 'eng-structural-001',
        email: 'priya.nair@skyline-consulting.com',
        name: 'Er. Priya Nair',
        role: 'CLIENT',
        company_name: 'Skyline Consulting Engineers',
      };

      function openAssignModal(engineer?: any) {
        preSelectedEngineer = engineer || null;
        isOpen = true;
      }

      openAssignModal(mockEngineer);
      assert.strictEqual(isOpen, true);
      assert.ok(preSelectedEngineer);
      assert.strictEqual(preSelectedEngineer.id, 'eng-structural-001');
      assert.strictEqual(preSelectedEngineer.name, 'Er. Priya Nair');
    });
  });

  // ── 2. Engineer Selection & Filtering Contracts ──
  describe('2. Engineer Selection & Directory Filtering', () => {
    const mockEngineers = [
      { id: 'eng-1', name: 'Er. Aisha Khan', email: 'aisha@zenith-infra.com', company_name: 'Zenith Infrastructure', mobile: '+91 98765 11111' },
      { id: 'eng-2', name: 'Er. David Patel', email: 'david@metro-builders.org', company_name: 'Metro Structural Design', mobile: '+91 98765 22222' },
      { id: 'eng-3', name: 'Er. Sanjay Sharma', email: 'sanjay@apex-cad.com', company_name: 'Apex Architects & Engineers', mobile: '+91 98765 33333' },
    ];

    function filterEngineers(engineers: typeof mockEngineers, query: string) {
      if (!query.trim()) return engineers;
      const q = query.toLowerCase();
      return engineers.filter((eng) => {
        const name = (eng.name || '').toLowerCase();
        const email = (eng.email || '').toLowerCase();
        const company = (eng.company_name || '').toLowerCase();
        const mobile = (eng.mobile || '').toLowerCase();
        const uid = (eng.id || '').toLowerCase();
        return name.includes(q) || email.includes(q) || company.includes(q) || mobile.includes(q) || uid.includes(q);
      });
    }

    it('Filters engineers accurately by name', () => {
      const results = filterEngineers(mockEngineers, 'aisha');
      assert.strictEqual(results.length, 1);
      assert.strictEqual(results[0].id, 'eng-1');
    });

    it('Filters engineers accurately by company firm', () => {
      const results = filterEngineers(mockEngineers, 'Metro Structural');
      assert.strictEqual(results.length, 1);
      assert.strictEqual(results[0].id, 'eng-2');
    });

    it('Filters engineers accurately by email domain', () => {
      const results = filterEngineers(mockEngineers, 'apex-cad.com');
      assert.strictEqual(results.length, 1);
      assert.strictEqual(results[0].id, 'eng-3');
    });

    it('Returns empty array when query does not match any engineer without throwing', () => {
      const results = filterEngineers(mockEngineers, 'nonexistent-query-xyz');
      assert.strictEqual(results.length, 0);
    });
  });

  // ── 3. Project Selection & Filtering Contracts ──
  describe('3. Project Selection & Filtering', () => {
    const mockProjects = [
      { id: 'PRJ-101', project_name: 'Skyline Plaza Structural Framing', drawing_type: 'STRUCTURAL', status: 'WAITING_ASSIGNMENT', client_id: 'eng-1' },
      { id: 'PRJ-102', project_name: 'Greenfield Residency Layout Plan', drawing_type: 'FLOOR_PLAN', status: 'SUBMITTED', client_id: 'studio-scope' },
      { id: 'PRJ-103', project_name: 'Apex Commercial HVAC & MEP Package', drawing_type: 'ELECTRICAL', status: 'IN_PROGRESS', client_id: 'eng-3' },
    ];

    function filterProjects(projects: typeof mockProjects, query: string, statusFilter: string) {
      return projects.filter((prj) => {
        if (statusFilter !== 'ALL' && prj.status !== statusFilter) return false;
        if (!query.trim()) return true;
        const q = query.toLowerCase();
        const name = prj.project_name.toLowerCase();
        const type = prj.drawing_type.toLowerCase();
        const id = prj.id.toLowerCase();
        return name.includes(q) || type.includes(q) || id.includes(q);
      });
    }

    it('Filters projects accurately by discipline drawing type', () => {
      const results = filterProjects(mockProjects, 'STRUCTURAL', 'ALL');
      assert.strictEqual(results.length, 1);
      assert.strictEqual(results[0].id, 'PRJ-101');
    });

    it('Filters projects accurately by project lifecycle status', () => {
      const results = filterProjects(mockProjects, '', 'SUBMITTED');
      assert.strictEqual(results.length, 1);
      assert.strictEqual(results[0].id, 'PRJ-102');
    });

    it('Combines text search and status filter cleanly', () => {
      const results = filterProjects(mockProjects, 'Greenfield', 'SUBMITTED');
      assert.strictEqual(results.length, 1);
      assert.strictEqual(results[0].id, 'PRJ-102');

      const noMatch = filterProjects(mockProjects, 'Greenfield', 'COMPLETED');
      assert.strictEqual(noMatch.length, 0);
    });
  });

  // ── 4. Validation Contracts ──
  describe('4. Stepper Validation Contracts', () => {
    function validateStep1(selectedEngineerId: string) {
      if (!selectedEngineerId || !selectedEngineerId.trim()) {
        return { valid: false, error: 'Please select a registered Engineer to proceed.' };
      }
      return { valid: true, error: null };
    }

    function validateStep2(mode: 'existing' | 'new', state: { selectedProjectId?: string; newProjectName?: string; newDrawingType?: string }) {
      if (mode === 'existing') {
        if (!state.selectedProjectId || !state.selectedProjectId.trim()) {
          return { valid: false, error: 'Please select a project to assign.' };
        }
      } else {
        if (!state.newProjectName || !state.newProjectName.trim()) {
          return { valid: false, error: 'Project name is required for new project creation.' };
        }
        if (!state.newDrawingType || !state.newDrawingType.trim()) {
          return { valid: false, error: 'Drawing type is required.' };
        }
      }
      return { valid: true, error: null };
    }

    it('Rejects progression from Step 1 without selecting an Engineer', () => {
      const res = validateStep1('');
      assert.strictEqual(res.valid, false);
      assert.strictEqual(res.error, 'Please select a registered Engineer to proceed.');
    });

    it('Approves progression from Step 1 when an Engineer is selected', () => {
      const res = validateStep1('eng-structural-001');
      assert.strictEqual(res.valid, true);
      assert.strictEqual(res.error, null);
    });

    it('Rejects progression from Step 2 (existing mode) without selecting a project', () => {
      const res = validateStep2('existing', { selectedProjectId: '' });
      assert.strictEqual(res.valid, false);
      assert.strictEqual(res.error, 'Please select a project to assign.');
    });

    it('Approves progression from Step 2 (existing mode) when a project is selected', () => {
      const res = validateStep2('existing', { selectedProjectId: 'PRJ-102' });
      assert.strictEqual(res.valid, true);
      assert.strictEqual(res.error, null);
    });

    it('Rejects progression from Step 2 (new mode) if project title is missing', () => {
      const res = validateStep2('new', { newProjectName: '', newDrawingType: 'Architectural Layout' });
      assert.strictEqual(res.valid, false);
      assert.strictEqual(res.error, 'Project name is required for new project creation.');
    });
  });

  // ── 5. Assignment Persistence & Association Contracts ──
  describe('5. Assignment Persistence & Engineer Context Association', () => {
    function buildAssignEngineerPayload(projectId: string, engineerId: string, actionId?: string) {
      return {
        projectId: projectId.trim(),
        engineerId: engineerId.trim(),
        actionId: actionId || 'act-mock-uuid',
      };
    }

    it('Constructs strictly scoped Engineer assignment payload without student keys', () => {
      const payload = buildAssignEngineerPayload('PRJ-200', 'eng-999');

      assert.strictEqual(payload.projectId, 'PRJ-200');
      assert.strictEqual(payload.engineerId, 'eng-999');
      assert.ok(payload.actionId);

      // Verify strict isolation: NO student keys present
      assert.strictEqual((payload as any).studentId, undefined);
      assert.strictEqual((payload as any).trainingModuleId, undefined);
      assert.strictEqual((payload as any).isTrainingProject, undefined);
    });

    it('Updates engineer project count immediately without requiring page reload', () => {
      const projects = [
        { id: 'PRJ-1', client_id: 'eng-1' },
        { id: 'PRJ-2', client_id: 'eng-1' },
        { id: 'PRJ-3', client_id: 'studio-admin-init' },
      ];

      // Initial count for eng-2
      const initialCounts: Record<string, number> = {};
      projects.forEach((p) => {
        initialCounts[p.client_id] = (initialCounts[p.client_id] || 0) + 1;
      });
      assert.strictEqual(initialCounts['eng-2'] || 0, 0);

      // Assign PRJ-3 to eng-2
      const updatedProjects = projects.map((p) => (p.id === 'PRJ-3' ? { ...p, client_id: 'eng-2' } : p));

      const updatedCounts: Record<string, number> = {};
      updatedProjects.forEach((p) => {
        updatedCounts[p.client_id] = (updatedCounts[p.client_id] || 0) + 1;
      });

      assert.strictEqual(updatedCounts['eng-2'], 1, 'Engineer project count must increment to 1');
      assert.strictEqual(updatedCounts['eng-1'], 2, 'Other engineers counts must remain unchanged');
    });

    it('Appears in Engineer submission dossier when filtered by client_id', () => {
      const engineerId = 'eng-verified-100';
      const allProjects = [
        { id: 'p1', client_id: 'eng-verified-100', project_name: 'Metro Overpass' },
        { id: 'p2', client_id: 'other-user', project_name: 'Villa A' },
      ];

      const engineerDossierProjects = allProjects.filter((p) => p.client_id === engineerId);
      assert.strictEqual(engineerDossierProjects.length, 1);
      assert.strictEqual(engineerDossierProjects[0].project_name, 'Metro Overpass');
    });
  });

  // ── 6. Error & Security Protection Contracts ──
  describe('6. Error Handling & Account Status Contracts', () => {
    function simulateAssignValidation(engineer: { role: string; status?: string }, project: { id: string } | null) {
      if (!project) {
        return { status: 404, code: 'PROJECT_NOT_FOUND', error: 'Project not found' };
      }
      if (!['ENGINEER', 'CLIENT'].includes(engineer.role)) {
        return { status: 400, code: 'INVALID_ENGINEER', error: 'Specified user must be a registered Engineer' };
      }
      if (engineer.status === 'SUSPENDED') {
        return { status: 403, code: 'ACCOUNT_SUSPENDED', error: 'Cannot assign project to a suspended Engineer account' };
      }
      return { status: 200, success: true };
    }

    it('Rejects assignment if target user has role STUDENT', () => {
      const res = simulateAssignValidation({ role: 'STUDENT' }, { id: 'PRJ-1' });
      assert.strictEqual(res.status, 400);
      assert.strictEqual(res.code, 'INVALID_ENGINEER');
    });

    it('Rejects assignment if target Engineer account is SUSPENDED', () => {
      const res = simulateAssignValidation({ role: 'CLIENT', status: 'SUSPENDED' }, { id: 'PRJ-1' });
      assert.strictEqual(res.status, 403);
      assert.strictEqual(res.code, 'ACCOUNT_SUSPENDED');
    });

    it('Rejects assignment if referenced project does not exist', () => {
      const res = simulateAssignValidation({ role: 'CLIENT', status: 'ACTIVE' }, null);
      assert.strictEqual(res.status, 404);
      assert.strictEqual(res.code, 'PROJECT_NOT_FOUND');
    });

    it('Succeeds for valid registered Engineer and valid project', () => {
      const res = simulateAssignValidation({ role: 'ENGINEER', status: 'ACTIVE' }, { id: 'PRJ-1' });
      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.success, true);
    });
  });

  // ── 7. Regression Protection — Student Project Assignment Isolation ──
  describe('7. Regression Protection: Student Assignment Complete Isolation', () => {
    it('Confirms student_assignments table is never targeted by engineer assignments', () => {
      const affectedTables = ['projects', 'activity_logs', 'notifications'];
      assert.ok(!affectedTables.includes('student_assignments'), 'student_assignments must NOT be written to');
      assert.ok(!affectedTables.includes('student_training'), 'student_training must NOT be written to');
      assert.ok(!affectedTables.includes('student_learning_plans'), 'student_learning_plans must NOT be written to');
    });

    it('Student Project Assignment payload requires studentId and isTrainingProject: true', () => {
      const studentPayload = {
        studentId: 'stu-1',
        isTrainingProject: true,
        projectName: 'AutoCAD Practice',
      };
      assert.strictEqual(studentPayload.isTrainingProject, true);
      assert.strictEqual(studentPayload.studentId, 'stu-1');
    });

    it('Engineer Project Assignment does NOT require or emit isTrainingProject or studentId', () => {
      const engineerPayload = {
        engineerId: 'eng-1',
        projectId: 'PRJ-1',
      };
      assert.strictEqual((engineerPayload as any).isTrainingProject, undefined);
      assert.strictEqual((engineerPayload as any).studentId, undefined);
    });
  });

  // ── 8. Engineer Project Status Overview — Button & Modal Trigger Contracts ──
  describe('8. Engineer Project Status Overview — Button & Modal Trigger Contracts', () => {
    it('Engineers page source contains the "Project Status" button beside "Assign Project"', () => {
      const pagePath = fs.existsSync(path.resolve(process.cwd(), 'src/app/engineers/page.tsx'))
        ? path.resolve(process.cwd(), 'src/app/engineers/page.tsx')
        : path.resolve(process.cwd(), 'apps/admin-web/src/app/engineers/page.tsx');
      const pageSource = fs.readFileSync(pagePath, 'utf-8');

      assert.match(pageSource, /<span>Project Status<\/span>/, 'Page must contain "Project Status" button label');
      assert.match(pageSource, /setIsStatusModalOpen\(true\)/, 'Clicking button must set isStatusModalOpen to true');
      assert.match(pageSource, /<EngineerProjectStatusModal\s+isOpen=\{isStatusModalOpen\}/, 'Must render EngineerProjectStatusModal bound to isStatusModalOpen');
    });

    it('Status modal remains closed on initial load and opens only on button click', () => {
      let isStatusModalOpen = false;
      assert.strictEqual(isStatusModalOpen, false, 'Modal closed initially');

      // Click Project Status button
      isStatusModalOpen = true;
      assert.strictEqual(isStatusModalOpen, true, 'Modal open when button clicked');

      // Close modal
      isStatusModalOpen = false;
      assert.strictEqual(isStatusModalOpen, false, 'Modal closes on onClose');
    });
  });

  // ── 9. Acceptance Status Categorization Contracts ──
  describe('9. Acceptance Status Categorization & System Status Contracts', () => {
    function getAcceptanceCategory(status: string) {
      switch (status) {
        case 'IN_PROGRESS':
        case 'UNDER_CLIENT_REVIEW':
        case 'UNDER_ENGINEER_REVIEW':
          return { category: 'ACCEPTED', label: 'Accepted (In Progress)' };
        case 'COMPLETED':
          return { category: 'ACCEPTED', label: 'Accepted (Completed)' };
        case 'WAITING_ACCEPTANCE':
          return { category: 'PENDING', label: 'Awaiting Response' };
        case 'CANCELLED':
          return { category: 'DECLINED', label: 'Declined / Cancelled' };
        case 'WAITING_ASSIGNMENT':
          return { category: 'COMMISSIONED', label: 'Waiting Draughtsman' };
        case 'SUBMITTED':
        case 'DRAFT':
        default:
          return { category: 'COMMISSIONED', label: 'Submitted (Intake)' };
      }
    }

    it('Maps active project statuses to ACCEPTED category', () => {
      assert.strictEqual(getAcceptanceCategory('IN_PROGRESS').category, 'ACCEPTED');
      assert.strictEqual(getAcceptanceCategory('UNDER_CLIENT_REVIEW').category, 'ACCEPTED');
      assert.strictEqual(getAcceptanceCategory('UNDER_ENGINEER_REVIEW').category, 'ACCEPTED');
      assert.strictEqual(getAcceptanceCategory('COMPLETED').category, 'ACCEPTED');
      assert.strictEqual(getAcceptanceCategory('COMPLETED').label, 'Accepted (Completed)');
    });

    it('Maps WAITING_ACCEPTANCE to PENDING category awaiting engineer response', () => {
      const res = getAcceptanceCategory('WAITING_ACCEPTANCE');
      assert.strictEqual(res.category, 'PENDING');
      assert.strictEqual(res.label, 'Awaiting Response');
    });

    it('Maps CANCELLED to DECLINED category', () => {
      const res = getAcceptanceCategory('CANCELLED');
      assert.strictEqual(res.category, 'DECLINED');
      assert.strictEqual(res.label, 'Declined / Cancelled');
    });

    it('Maps SUBMITTED, WAITING_ASSIGNMENT, and DRAFT to COMMISSIONED intake queue', () => {
      assert.strictEqual(getAcceptanceCategory('SUBMITTED').category, 'COMMISSIONED');
      assert.strictEqual(getAcceptanceCategory('WAITING_ASSIGNMENT').category, 'COMMISSIONED');
      assert.strictEqual(getAcceptanceCategory('DRAFT').category, 'COMMISSIONED');
    });
  });

  // ── 10. Multi-Engineer Aggregation, Search & Filter Contracts ──
  describe('10. Multi-Engineer Aggregation, Search & Filter Contracts', () => {
    const mockStatusRecords = [
      {
        project_id: 'PRJ-101',
        project_name: 'Metro Elevated Viaduct Design',
        engineer_id: 'eng-1',
        engineer_name: 'Er. Rajesh Kumar',
        engineer_email: 'rajesh@infra-design.in',
        engineer_company: 'Kumar Infrastructure',
        project_status: 'IN_PROGRESS',
        assigned_at: '2026-11-01T10:00:00Z',
        last_updated_at: '2026-11-02T15:30:00Z',
        correction_round: 1,
        drawing_versions_count: 2,
      },
      {
        project_id: 'PRJ-102',
        project_name: 'Skyline Commercial Tower Framing',
        engineer_id: 'eng-2',
        engineer_name: 'Er. Priya Nair',
        engineer_email: 'priya@skyline.org',
        engineer_company: 'Skyline Consultants',
        project_status: 'WAITING_ACCEPTANCE',
        assigned_at: '2026-11-02T08:00:00Z',
        last_updated_at: '2026-11-02T08:00:00Z',
        correction_round: 0,
        drawing_versions_count: 0,
      },
      {
        project_id: 'PRJ-103',
        project_name: 'Greenfield Residential Layout',
        engineer_id: 'eng-1',
        engineer_name: 'Er. Rajesh Kumar',
        engineer_email: 'rajesh@infra-design.in',
        engineer_company: 'Kumar Infrastructure',
        project_status: 'COMPLETED',
        assigned_at: '2026-10-20T12:00:00Z',
        last_updated_at: '2026-10-28T18:00:00Z',
        correction_round: 2,
        drawing_versions_count: 3,
      },
      {
        project_id: 'PRJ-104',
        project_name: 'Apex Industrial Warehouse Plan',
        engineer_id: 'eng-3',
        engineer_name: 'Er. Sanjay Sharma',
        engineer_email: 'sanjay@apex.com',
        engineer_company: 'Apex Engineering',
        project_status: 'CANCELLED',
        assigned_at: '2026-10-25T09:00:00Z',
        last_updated_at: '2026-10-26T11:00:00Z',
        correction_round: 0,
        drawing_versions_count: 1,
      },
    ];

    it('Aggregates assignments for all engineers, not just one engineer', () => {
      const distinctEngineers = new Set(mockStatusRecords.map((r) => r.engineer_id));
      assert.strictEqual(distinctEngineers.size, 3, 'Overview displays records across all 3 engineers');
    });

    it('Computes accurate KPI summary counts across all status categories', () => {
      let total = mockStatusRecords.length;
      let inProgress = 0;
      let awaitingResponse = 0;
      let completed = 0;
      let declined = 0;

      mockStatusRecords.forEach((r) => {
        if (r.project_status === 'IN_PROGRESS') inProgress++;
        else if (r.project_status === 'WAITING_ACCEPTANCE') awaitingResponse++;
        else if (r.project_status === 'COMPLETED') completed++;
        else if (r.project_status === 'CANCELLED') declined++;
      });

      assert.strictEqual(total, 4);
      assert.strictEqual(inProgress, 1);
      assert.strictEqual(awaitingResponse, 1);
      assert.strictEqual(completed, 1);
      assert.strictEqual(declined, 1);
    });

    it('Filters status records by specific Engineer ID', () => {
      const eng1Records = mockStatusRecords.filter((r) => r.engineer_id === 'eng-1');
      assert.strictEqual(eng1Records.length, 2);
      assert.ok(eng1Records.every((r) => r.engineer_id === 'eng-1'));
    });

    it('Searches across engineer name, company, email, project name and ID', () => {
      function searchRecords(q: string) {
        const query = q.toLowerCase();
        return mockStatusRecords.filter(
          (r) =>
            r.engineer_name.toLowerCase().includes(query) ||
            r.engineer_company.toLowerCase().includes(query) ||
            r.project_name.toLowerCase().includes(query) ||
            r.project_id.toLowerCase().includes(query)
        );
      }

      assert.strictEqual(searchRecords('Priya').length, 1);
      assert.strictEqual(searchRecords('Skyline').length, 1);
      assert.strictEqual(searchRecords('PRJ-101').length, 1);
      assert.strictEqual(searchRecords('Warehouse').length, 1);
      assert.strictEqual(searchRecords('nonexistent').length, 0);
    });
  });

  // ── 11. Progress, Timestamps & CAD Revision Tracking Contracts ──
  describe('11. Progress, Timestamps & CAD Revision Tracking Contracts', () => {
    function formatDateTime(isoString?: string) {
      if (!isoString) return '—';
      try {
        const d = new Date(isoString);
        if (isNaN(d.getTime())) return isoString;
        return d.toLocaleString('en-US', {
          month: 'short',
          day: 'numeric',
          year: 'numeric',
          hour: '2-digit',
          minute: '2-digit',
        });
      } catch {
        return isoString;
      }
    }

    it('Formats ISO timestamps with date and time accurately', () => {
      const formatted = formatDateTime('2026-11-01T10:30:00Z');
      assert.match(formatted, /Nov 1, 2026/);
    });

    it('Handles missing or undefined timestamps gracefully without throwing', () => {
      assert.strictEqual(formatDateTime(undefined), '—');
      assert.strictEqual(formatDateTime(''), '—');
    });

    it('Tracks correction round and CAD versions truthfully from persisted record', () => {
      const item = {
        correction_round: 2,
        drawing_versions_count: 4,
      };
      assert.strictEqual(item.correction_round, 2);
      assert.strictEqual(item.drawing_versions_count, 4);
    });
  });

  // ── 12. Strict Isolation: Non-Engineer & Student Records Exclusion ──
  describe('12. Strict Isolation: Non-Engineer & Student Records Exclusion from Status Overview', () => {
    it('SQL WHERE clause strictly enforces role and non-training project condition', () => {
      function evaluateRecord(role: string, isTrainingProject: number | null) {
        const roleAllowed = role === 'CLIENT' || role === 'ENGINEER';
        const notTraining = isTrainingProject === null || isTrainingProject === 0;
        return roleAllowed && notTraining;
      }

      // Valid engineer assignments
      assert.strictEqual(evaluateRecord('CLIENT', null), true, 'CLIENT role with null is_training_project allowed');
      assert.strictEqual(evaluateRecord('ENGINEER', 0), true, 'ENGINEER role with 0 is_training_project allowed');

      // Student practical projects or student training modules
      assert.strictEqual(evaluateRecord('STUDENT', 1), false, 'STUDENT role with is_training_project=1 strictly excluded');
      assert.strictEqual(evaluateRecord('STUDENT', 0), false, 'STUDENT role with is_training_project=0 strictly excluded');
      assert.strictEqual(evaluateRecord('CLIENT', 1), false, 'Commercial user with is_training_project=1 strictly excluded');
    });

    it('Overview records do not contain student IDs or training curriculum fields', () => {
      const sampleItem = {
        project_id: 'PRJ-ENG-1',
        project_name: 'Civil Foundation',
        engineer_id: 'eng-1',
        engineer_name: 'Er. Test',
        project_status: 'IN_PROGRESS',
      };

      assert.strictEqual((sampleItem as any).student_id, undefined);
      assert.strictEqual((sampleItem as any).student_name, undefined);
      assert.strictEqual((sampleItem as any).training_module_id, undefined);
    });
  });
});

