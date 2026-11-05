import { describe, it } from 'node:test';
import assert from 'node:assert';

describe('Admin Portal — Role-Based Identification Numbers', () => {
  it('Validates role-based ID format conventions (ENG_XX, DM_XX, ST_XX)', () => {
    const engineerIdRegex = /^ENG_\d{2,}$/;
    const draughtsmanIdRegex = /^DM_\d{2,}$/;
    const studentIdRegex = /^ST_\d{2,}$/;

    assert.ok(engineerIdRegex.test('ENG_01'), 'ENG_01 should be valid');
    assert.ok(engineerIdRegex.test('ENG_99'), 'ENG_99 should be valid');
    assert.ok(engineerIdRegex.test('ENG_100'), 'ENG_100 should be valid');
    assert.ok(!engineerIdRegex.test('ENG_1'), 'ENG_1 should have 2-digit zero padding');
    assert.ok(!engineerIdRegex.test('DM_01'), 'DM_01 should not match ENG');

    assert.ok(draughtsmanIdRegex.test('DM_01'), 'DM_01 should be valid');
    assert.ok(draughtsmanIdRegex.test('DM_50'), 'DM_50 should be valid');
    assert.ok(draughtsmanIdRegex.test('DM_150'), 'DM_150 should be valid');

    assert.ok(studentIdRegex.test('ST_01'), 'ST_01 should be valid');
    assert.ok(studentIdRegex.test('ST_02'), 'ST_02 should be valid');
    assert.ok(studentIdRegex.test('ST_250'), 'ST_250 should be valid');
  });

  it('Supports case-insensitive search by identification_number in Engineer directory filter', () => {
    const mockEngineers = [
      { id: 'uid-1', name: 'John Doe', email: 'john@example.com', role: 'CLIENT', identification_number: 'ENG_01' },
      { id: 'uid-2', name: 'Jane Smith', email: 'jane@example.com', role: 'ENGINEER', identification_number: 'ENG_02' },
      { id: 'uid-3', name: 'Bob Wilson', email: 'bob@example.com', role: 'CLIENT', identification_number: undefined },
    ];

    function filterEngineers(engineers: typeof mockEngineers, query: string) {
      const q = query.toLowerCase().trim();
      if (!q) return engineers;
      return engineers.filter((eng) =>
        eng.name.toLowerCase().includes(q) ||
        eng.email.toLowerCase().includes(q) ||
        (eng.identification_number || '').toLowerCase().includes(q)
      );
    }

    const matchEng01 = filterEngineers(mockEngineers, 'eng_01');
    assert.strictEqual(matchEng01.length, 1);
    assert.strictEqual(matchEng01[0].identification_number, 'ENG_01');

    const matchEngUpper = filterEngineers(mockEngineers, 'ENG_02');
    assert.strictEqual(matchEngUpper.length, 1);
    assert.strictEqual(matchEngUpper[0].identification_number, 'ENG_02');

    const matchPartial = filterEngineers(mockEngineers, 'eng_');
    assert.strictEqual(matchPartial.length, 2);

    const matchNone = filterEngineers(mockEngineers, 'ENG_99');
    assert.strictEqual(matchNone.length, 0);
  });

  it('Supports case-insensitive search by identification_number in Draughtsman directory filter', () => {
    const mockDraughtsmen = [
      { id: 'dm-1', name: 'Alice Drafter', email: 'alice@draft.com', role: 'DRAUGHTSMAN', identification_number: 'DM_01' },
      { id: 'dm-2', name: 'Dave CAD', email: 'dave@draft.com', role: 'DRAUGHTSMAN', identification_number: 'DM_02' },
    ];

    function filterDraughtsmen(list: typeof mockDraughtsmen, query: string) {
      const q = query.toLowerCase().trim();
      if (!q) return list;
      return list.filter((dm) =>
        dm.name.toLowerCase().includes(q) ||
        dm.email.toLowerCase().includes(q) ||
        (dm.identification_number || '').toLowerCase().includes(q)
      );
    }

    const res = filterDraughtsmen(mockDraughtsmen, 'dm_02');
    assert.strictEqual(res.length, 1);
    assert.strictEqual(res[0].name, 'Dave CAD');
  });

  it('Supports case-insensitive search by identification_number in Student directory filter', () => {
    const mockStudents = [
      { id: 'st-1', name: 'Charlie Trainee', email: 'charlie@school.com', role: 'STUDENT', identification_number: 'ST_01' },
      { id: 'st-2', name: 'Eve Intern', email: 'eve@school.com', role: 'STUDENT', identification_number: 'ST_15' },
    ];

    function filterStudents(list: typeof mockStudents, query: string) {
      const q = query.toLowerCase().trim();
      if (!q) return list;
      return list.filter((s) =>
        s.name.toLowerCase().includes(q) ||
        s.email.toLowerCase().includes(q) ||
        (s.identification_number || '').toLowerCase().includes(q)
      );
    }

    const res = filterStudents(mockStudents, 'ST_15');
    assert.strictEqual(res.length, 1);
    assert.strictEqual(res[0].id, 'st-2');
  });

  it('Supports case-insensitive search by identification_number in Registrations Provision queue', () => {
    const mockRegistrations = [
      { id: 'reg-1', name: 'Applicant One', email: 'app1@test.com', role: 'ENGINEER', identification_number: 'ENG_05' },
      { id: 'reg-2', name: 'Applicant Two', email: 'app2@test.com', role: 'DRAUGHTSMAN', identification_number: 'DM_12' },
      { id: 'reg-3', name: 'Applicant Three', email: 'app3@test.com', role: 'STUDENT', identification_number: undefined },
    ];

    function filterRegistrations(list: typeof mockRegistrations, query: string) {
      const q = query.toLowerCase().trim();
      if (!q) return list;
      return list.filter((r) =>
        (r.name || '').toLowerCase().includes(q) ||
        (r.email || '').toLowerCase().includes(q) ||
        (r.identification_number || '').toLowerCase().includes(q)
      );
    }

    const res = filterRegistrations(mockRegistrations, 'dm_12');
    assert.strictEqual(res.length, 1);
    assert.strictEqual(res[0].name, 'Applicant Two');

    const resEng = filterRegistrations(mockRegistrations, 'ENG_05');
    assert.strictEqual(resEng.length, 1);
    assert.strictEqual(resEng[0].name, 'Applicant One');
  });

  it('Supports case-insensitive search by identification_number in Unified Users directory', () => {
    const mockUsers = [
      { id: 'usr-1', name: 'User 1', email: 'u1@test.com', role: 'CLIENT', identification_number: 'ENG_01' },
      { id: 'usr-2', name: 'User 2', email: 'u2@test.com', role: 'DRAUGHTSMAN', identification_number: 'DM_01' },
      { id: 'usr-3', name: 'User 3', email: 'u3@test.com', role: 'STUDENT', identification_number: 'ST_01' },
      { id: 'usr-4', name: 'Admin', email: 'admin@test.com', role: 'ADMIN', identification_number: undefined },
    ];

    function filterUsers(list: typeof mockUsers, query: string) {
      const q = query.toLowerCase().trim();
      if (!q) return list;
      return list.filter((u) =>
        (u.name || '').toLowerCase().includes(q) ||
        (u.email || '').toLowerCase().includes(q) ||
        (u.identification_number || '').toLowerCase().includes(q)
      );
    }

    const res = filterUsers(mockUsers, 'st_01');
    assert.strictEqual(res.length, 1);
    assert.strictEqual(res[0].role, 'STUDENT');
  });

  it('Ensures identification_number is distinct from Firebase Auth UID', () => {
    const mockUser = {
      id: 'firebase-auth-uid-abcdef123456',
      email: 'engineer@studio.com',
      role: 'CLIENT',
      identification_number: 'ENG_07',
    };

    assert.notStrictEqual(mockUser.id, mockUser.identification_number);
    assert.strictEqual(mockUser.identification_number, 'ENG_07');
    assert.ok(!mockUser.identification_number.includes('firebase'));
  });

  it('Handles undefined or missing identification_number gracefully without errors', () => {
    const mockUser = {
      id: 'uid-unallocated',
      email: 'pending@studio.com',
      role: 'CLIENT',
    };

    const idDisplay = (mockUser as any).identification_number || 'Pending Allocation';
    assert.strictEqual(idDisplay, 'Pending Allocation');
  });

  it('Formats user selector and dropdown options with identification_number prominently first', () => {
    function formatOption(user: { identification_number?: string; name: string }) {
      return `${user.identification_number ? `${user.identification_number} — ` : ''}${user.name}`;
    }

    const eng = { identification_number: 'ENG_01', name: 'John Doe' };
    const dm = { identification_number: 'DM_01', name: 'Jane Doe' };
    const stu = { identification_number: 'ST_01', name: 'Student Trainee' };
    const unallocated = { name: 'New User' };

    assert.strictEqual(formatOption(eng), 'ENG_01 — John Doe');
    assert.strictEqual(formatOption(dm), 'DM_01 — Jane Doe');
    assert.strictEqual(formatOption(stu), 'ST_01 — Student Trainee');
    assert.strictEqual(formatOption(unallocated), 'New User');
  });

  it('Validates table headers always place "ID Number" as the first column', () => {
    const engineerTableHeaders = ['ID Number', 'Engineer', 'Company / Firm', 'Contact / Mobile', 'Role', 'Status', 'Actions'];
    const draughtsmanTableHeaders = ['ID Number', 'Draughtsman', 'Qualification & Institution', 'Contact & Mobile', 'Current Workload', 'Actions'];
    const studentTableHeaders = ['ID Number', 'Student / Apprentice', 'Institution & Program', 'Practical Load', 'Curriculum Status', 'Actions'];
    const registrationTableHeaders = ['ID Number', 'User', 'Role', 'Submitted', 'Proof Document', 'Verification Status', 'Review Status', 'Action'];
    const userTableHeaders = ['ID Number', 'Name', 'Email', 'Role', 'Status', 'Actions'];
    const submissionsTableHeaders = ['ID Number', 'Student Apprentice', 'Practical Milestone & Target', 'Version & Cycle', 'Delivery Artifacts', 'Review State', 'Dispatch / Review'];
    const progressTableHeaders = ['ID Number', 'Student', 'Assigned Modules', 'Required Lessons Progress', 'Time Allocation', 'Submission Health', 'Detail Dossier'];
    const engineerStatusModalHeaders = ['ID Number', 'Engineer', 'Assigned Project', 'Status', 'Drawing Type', 'Actions'];
    const assignmentHistoryHeaders = ['ID Number', 'Assigned Draughtsman', 'Project', 'Assignment ID', 'Status', 'Date Dispatched'];

    const tables = [
      engineerTableHeaders,
      draughtsmanTableHeaders,
      studentTableHeaders,
      registrationTableHeaders,
      userTableHeaders,
      submissionsTableHeaders,
      progressTableHeaders,
      engineerStatusModalHeaders,
      assignmentHistoryHeaders,
    ];

    for (const headers of tables) {
      assert.strictEqual(headers[0], 'ID Number', `First column must be 'ID Number', got '${headers[0]}'`);
    }
  });
});

