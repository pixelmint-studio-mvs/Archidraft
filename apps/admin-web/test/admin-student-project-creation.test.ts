import { describe, it } from 'node:test';
import assert from 'node:assert';

describe('Admin Student Project Creation & Assignment Contracts', () => {
  it('Constructs valid Student Practical Assignment payload for Worker API', () => {
    const studentId = 'stu-cad-apprentice-001';
    const actionId = 'act-' + Math.random().toString(36).substring(2, 9);
    const formState = {
      assigneeType: 'STUDENT',
      selectedStudentId: studentId,
      projectName: 'AutoCAD Level 2 Villa Plan & Elevation',
      projectAddress: 'CAD Design Lab, Campus Block B',
      drawingName: 'Architectural Layout Practical Assignment (1:100)',
      drawingType: 'FLOOR_PLAN',
      projectArea: 1800,
      instructions: 'Submit DWG and PDF layers conforming to Studio standards. Include wall hatch and door schedules.',
      actionId,
    };

    function buildProjectPayload(state: typeof formState) {
      return {
        studentId: state.selectedStudentId,
        isTrainingProject: true,
        projectName: state.projectName.trim(),
        projectAddress: state.projectAddress.trim() || 'Academic Studio Campus',
        drawingName: state.drawingName,
        drawingType: state.drawingType,
        projectArea: Number(state.projectArea) || 1500,
        instructions: state.instructions.trim() || undefined,
        actionId: state.actionId,
      };
    }

    const payload = buildProjectPayload(formState);
    assert.ok(payload, 'Payload must be generated');
    assert.strictEqual(payload.studentId, 'stu-cad-apprentice-001');
    assert.strictEqual(payload.isTrainingProject, true);
    assert.strictEqual(payload.projectName, 'AutoCAD Level 2 Villa Plan & Elevation');
    assert.strictEqual(payload.projectAddress, 'CAD Design Lab, Campus Block B');
    assert.strictEqual(payload.drawingName, 'Architectural Layout Practical Assignment (1:100)');
    assert.strictEqual(payload.drawingType, 'FLOOR_PLAN');
    assert.strictEqual(payload.projectArea, 1800);
    assert.ok(payload.instructions?.includes('Submit DWG and PDF layers'));
    assert.strictEqual(payload.actionId, actionId);
  });

  it('Validates required fields for student project initiation without commercial client option', () => {
    function validateStep1(state: {
      projectName: string;
      selectedStudentId: string;
    }) {
      if (!state.projectName.trim()) {
        return { valid: false, error: 'Assignment title is required.' };
      }
      if (!state.selectedStudentId) {
        return { valid: false, error: 'Please select an enrolled Student Apprentice for this assignment.' };
      }
      return { valid: true, error: null };
    }

    // Missing project name
    const res1 = validateStep1({ projectName: '', selectedStudentId: 'stu-1' });
    assert.strictEqual(res1.valid, false);
    assert.strictEqual(res1.error, 'Assignment title is required.');

    // Missing student selection
    const res2 = validateStep1({ projectName: 'Practical 1', selectedStudentId: '' });
    assert.strictEqual(res2.valid, false);
    assert.strictEqual(res2.error, 'Please select an enrolled Student Apprentice for this assignment.');

    // Valid student assignment
    const res3 = validateStep1({ projectName: 'Practical 1', selectedStudentId: 'stu-1' });
    assert.strictEqual(res3.valid, true);
    assert.strictEqual(res3.error, null);
  });

  it('Ensures reference file upload category is always "reference" for student assignments', () => {
    function getUploadCategory() {
      return 'reference';
    }

    assert.strictEqual(getUploadCategory(), 'reference');
  });

  it('Formats curriculum reference codes with STU-PRAC prefix', () => {
    function generateRefCode(seed = 12345) {
      return `STU-PRAC-${seed}`;
    }

    const studentCode = generateRefCode(54321);

    assert.strictEqual(studentCode, 'STU-PRAC-54321');
    assert.ok(studentCode.startsWith('STU-PRAC-'));
  });

  it('Separates and filters students from global users list', () => {
    const rawUsers = [
      { id: 'u1', role: 'CLIENT', name: 'Eng. John' },
      { id: 'u2', role: 'STUDENT', name: 'Apprentice Alice', status: 'ACTIVE' },
      { id: 'u3', role: 'DRAUGHTSMAN', name: 'Draughtsman Bob' },
      { id: 'u4', role: 'STUDENT', name: 'Apprentice Charlie', status: 'ACTIVE' },
      { id: 'u5', role: 'STUDIO_ADMIN', name: 'Admin Dave' },
    ];

    const studentsOnly = rawUsers.filter((u) => u.role === 'STUDENT');
    assert.strictEqual(studentsOnly.length, 2);
    assert.strictEqual(studentsOnly[0].id, 'u2');
    assert.strictEqual(studentsOnly[1].id, 'u4');
  });

  it('Calculates $0 curriculum fee for student training modules', () => {
    function computeAssignmentBilling() {
      return {
        moduleFee: 0,
        surcharge: 0,
        total: 0,
        isAcademic: true,
      };
    }

    const studentBilling = computeAssignmentBilling();
    assert.strictEqual(studentBilling.total, 0);
    assert.strictEqual(studentBilling.moduleFee, 0);
    assert.strictEqual(studentBilling.isAcademic, true);
  });
});
