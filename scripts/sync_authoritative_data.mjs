import { DatabaseSync } from 'node:sqlite';
import path from 'node:path';

const dbPath = path.resolve('worker/.wrangler/state/v3/d1/miniflare-D1DatabaseObject/fdc94e68165493d9beefe9c542c3ccf242c09e8c388eef5ade0878b760405048.sqlite');
const db = new DatabaseSync(dbPath);

console.log('Synchronizing authoritative staging data (33 projects, 17 users) into local D1 SQLite...');

// Enable foreign keys
db.exec('PRAGMA foreign_keys = ON;');

db.exec('BEGIN TRANSACTION;');

try {
  // 1. Synchronize Users (17 authoritative accounts: 3 Admins, 4 Engineers, 3 Draughtsmen, 7 Students)
  const insertUser = db.prepare(`
    INSERT INTO users (
      id, email, name, role, created_at, college_name, mobile, qualification, date_of_birth, address, company_name, updated_at, status, verification_status, rejection_reason, identification_number
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      email = excluded.email,
      name = excluded.name,
      role = excluded.role,
      status = excluded.status,
      verification_status = excluded.verification_status,
      identification_number = excluded.identification_number
  `);

  // Admins (3)
  insertUser.run('bCrLwG8lMRbViDOrBmClwc96xJ42', 'contact@draughtsmanstudio.com', 'Studio Administrator Primary', 'STUDIO_ADMIN', '2026-10-20 00:00:00', null, '9876543200', null, null, 'Chennai, Tamil Nadu', 'DRAUGHTSMAN STUDIO', '2026-10-24 00:00:00', 'ACTIVE', 'APPROVED', null, 'ADM-001');
  insertUser.run('QBhduHDU1mYUxvtQ89adVnwQYCg1', 'zedsuo125@gmail.com', 'Studio Administrator Secondary', 'STUDIO_ADMIN', '2026-10-20 00:00:00', null, '9876543201', null, null, 'Madurai, Tamil Nadu', 'DRAUGHTSMAN STUDIO', '2026-10-24 00:00:00', 'ACTIVE', 'APPROVED', null, 'ADM-002');
  insertUser.run('AP2Z19U2v9UWTOAe6gtaZtGcg5J2', 'mdjanis2006@gmail.com', 'P Mohammed Janis', 'STUDIO_ADMIN', '2026-10-20 00:00:00', null, '9876543202', null, null, 'Chennai, Tamil Nadu', 'DRAUGHTSMAN STUDIO', '2026-10-24 00:00:00', 'ACTIVE', 'APPROVED', null, 'ADM-003');

  // Engineers (4)
  insertUser.run('KXAR90JgoVYLuOKzkbxpKTC8ATa2', 'zedsuo125+engineer@gmail.com', 'Staging Engineer Primary', 'ENGINEER', '2026-10-21 00:00:00', null, '9876543211', 'B.E. Civil', '1988-04-12', 'Coimbatore, Tamil Nadu', 'Apex Engineering Ltd', '2026-10-24 00:00:00', 'ACTIVE', 'APPROVED', null, 'ENG-001');
  insertUser.run('usr-eng-02-alpha', 'alok.architect@firm.com', 'Alok Nath (Principal Architect)', 'ENGINEER', '2026-10-21 01:00:00', null, '9876543212', 'B.Arch', '1985-09-20', 'Bangalore, Karnataka', 'Design Praxis Studios', '2026-10-24 00:00:00', 'ACTIVE', 'APPROVED', null, 'ENG-002');
  insertUser.run('usr-eng-03-beta', 'rajesh.kumar@engineerfirm.com', 'Rajesh Kumar (Structural Consultant)', 'ENGINEER', '2026-10-21 02:00:00', null, '9876543213', 'M.Tech Structural', '1982-11-05', 'Chennai, Tamil Nadu', 'Kumar Structural Dynamics', '2026-10-24 00:00:00', 'ACTIVE', 'APPROVED', null, 'ENG-003');
  insertUser.run('usr-eng-04-gamma', 'arvind.sharma@engineerfirm.com', 'Arvind Sharma (Civil Engineer)', 'ENGINEER', '2026-10-21 03:00:00', null, '9876543214', 'B.Tech Civil', '1990-07-18', 'Hyderabad, Telangana', 'Sharma Infra Solutions', '2026-10-24 00:00:00', 'ACTIVE', 'APPROVED', null, 'ENG-004');

  // Draughtsmen (3)
  insertUser.run('TJjtkBm3lgRlpKtcI5u3jpYPH9s1', 'zedsuo125+draughtsman@gmail.com', 'Staging Draughtsman Primary', 'DRAUGHTSMAN', '2026-10-21 00:00:00', null, '9876543221', 'Diploma Civil & CAD', '1995-02-14', 'Chennai, Tamil Nadu', 'DRAUGHTSMAN STUDIO', '2026-10-24 00:00:00', 'ACTIVE', 'APPROVED', null, 'DRG-001');
  insertUser.run('usr-dm-02-kavita', 'kavita.patel@draughtsman.studio', 'Kavita Patel (Senior CAD Specialist)', 'DRAUGHTSMAN', '2026-10-21 01:00:00', null, '9876543222', 'AutoCAD Certified Pro', '1993-06-25', 'Pune, Maharashtra', 'DRAUGHTSMAN STUDIO', '2026-10-24 00:00:00', 'ACTIVE', 'APPROVED', null, 'DRG-002');
  insertUser.run('usr-dm-03-suresh', 'suresh.patel@draughtsman.studio', 'Suresh Patel (BIM Modeler)', 'DRAUGHTSMAN', '2026-10-21 02:00:00', null, '9876543223', 'Revit & Civil 3D Specialist', '1996-10-30', 'Ahmedabad, Gujarat', 'DRAUGHTSMAN STUDIO', '2026-10-24 00:00:00', 'ACTIVE', 'APPROVED', null, 'DRG-003');

  // Students (7)
  insertUser.run('2iypyxUntQX6djOzwjgPo5xWrGD2', 'zedsuo125+student@gmail.com', 'Staging Student Primary', 'STUDENT', '2026-10-21 00:00:00', 'Government College of Technology', '9876543231', 'B.E. Civil (Final Year)', '2004-03-15', 'Coimbatore, Tamil Nadu', null, '2026-10-24 00:00:00', 'ACTIVE', 'APPROVED', null, 'STU-001');
  insertUser.run('usr-stu-02-rohan', 'rohan.mehra@engineeringcollege.edu', 'Rohan Mehra', 'STUDENT', '2026-10-21 01:00:00', 'PSG College of Technology', '9876543232', 'B.Arch (4th Year)', '2003-08-22', 'Coimbatore, Tamil Nadu', null, '2026-10-24 00:00:00', 'ACTIVE', 'APPROVED', null, 'STU-002');
  insertUser.run('usr-stu-03-anita', 'anita.desai@architecture.edu', 'Anita Desai', 'STUDENT', '2026-10-21 02:00:00', 'School of Planning and Architecture', '9876543233', 'B.Arch (Final Year)', '2003-12-05', 'Chennai, Tamil Nadu', null, '2026-10-24 00:00:00', 'ACTIVE', 'APPROVED', null, 'STU-003');
  insertUser.run('usr-stu-04-a', 'student.a@college.edu', 'Pooja Sundaram', 'STUDENT', '2026-10-21 03:00:00', 'Thiagarajar College of Engineering', '9876543234', 'B.E. Civil', '2004-05-18', 'Madurai, Tamil Nadu', null, '2026-10-24 00:00:00', 'ACTIVE', 'APPROVED', null, 'STU-004');
  insertUser.run('usr-stu-05-b', 'student.b@college.edu', 'Vikas Narang', 'STUDENT', '2026-10-21 04:00:00', 'National Institute of Technology', '9876543235', 'B.Tech Civil', '2003-01-28', 'Trichy, Tamil Nadu', null, '2026-10-24 00:00:00', 'ACTIVE', 'APPROVED', null, 'STU-005');
  insertUser.run('usr-stu-06-c', 'student.c@college.edu', 'Meenakshi Iyer', 'STUDENT', '2026-10-21 05:00:00', 'Coimbatore Institute of Technology', '9876543236', 'Diploma in Architecture', '2004-09-10', 'Coimbatore, Tamil Nadu', null, '2026-10-24 00:00:00', 'ACTIVE', 'APPROVED', null, 'STU-006');
  insertUser.run('usr-stu-07-d', 'student.d@college.edu', 'Karthik Raja', 'STUDENT', '2026-10-21 06:00:00', 'SRM Institute of Science and Technology', '9876543237', 'B.Tech Civil', '2003-11-14', 'Chennai, Tamil Nadu', null, '2026-10-24 00:00:00', 'ACTIVE', 'APPROVED', null, 'STU-007');

  console.log('✓ Users synchronized (17 accounts: 3 Admins, 4 Engineers, 3 Draughtsmen, 7 Students).');

  // 2. Legal Consent State & Events for all 17 users
  const allUsers = [
    'bCrLwG8lMRbViDOrBmClwc96xJ42', 'QBhduHDU1mYUxvtQ89adVnwQYCg1', 'AP2Z19U2v9UWTOAe6gtaZtGcg5J2',
    'KXAR90JgoVYLuOKzkbxpKTC8ATa2', 'usr-eng-02-alpha', 'usr-eng-03-beta', 'usr-eng-04-gamma',
    'TJjtkBm3lgRlpKtcI5u3jpYPH9s1', 'usr-dm-02-kavita', 'usr-dm-03-suresh',
    '2iypyxUntQX6djOzwjgPo5xWrGD2', 'usr-stu-02-rohan', 'usr-stu-03-anita', 'usr-stu-04-a', 'usr-stu-05-b', 'usr-stu-06-c', 'usr-stu-07-d'
  ];

  const insertEvent = db.prepare(`
    INSERT OR IGNORE INTO legal_consent_events (
      id, user_id, document_id, document_type, document_version, action_type,
      consent_purpose, idempotency_key, ip_hash, user_agent, source, recorded_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  const insertState = db.prepare(`
    INSERT INTO user_consent_state (
      id, user_id, consent_type, purpose_tag, current_status, accepted_version, last_event_id, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      current_status = excluded.current_status,
      accepted_version = excluded.accepted_version,
      updated_at = excluded.updated_at
  `);

  for (const uid of allUsers) {
    const termsEventId = `lce-${uid}-terms`;
    const privEventId = `lce-${uid}-priv`;

    insertEvent.run(
      termsEventId, uid, 'doc-terms-v1', 'TERMS_AND_CONDITIONS', '1.0.0', 'ACCEPTED',
      'CORE_PLATFORM', `idemp-${uid}-terms`, 'hash-127-0-0-1', 'ArchiDraft-Client/1.0', 'WEB_APP', '2026-10-24 00:00:00'
    );
    insertEvent.run(
      privEventId, uid, 'doc-priv-v1', 'PRIVACY_POLICY', '1.0.0', 'ACCEPTED',
      'CORE_PLATFORM', `idemp-${uid}-priv`, 'hash-127-0-0-1', 'ArchiDraft-Client/1.0', 'WEB_APP', '2026-10-24 00:00:00'
    );

    insertState.run(
      `ucs-${uid}-terms`, uid, 'TERMS_AND_CONDITIONS', 'CORE_PLATFORM', 'ACCEPTED', '1.0.0', termsEventId, '2026-10-24 00:00:00'
    );
    insertState.run(
      `ucs-${uid}-priv`, uid, 'PRIVACY_POLICY', 'CORE_PLATFORM', 'ACCEPTED', '1.0.0', privEventId, '2026-10-24 00:00:00'
    );
  }
  console.log('✓ Legal consent recorded for all 17 users.');

  // 3. Training Curriculum (Modules, Chapters, Lessons, Plans)
  const insertModule = db.prepare(`
    INSERT INTO training_modules (
      id, category, type, level, title, description, prerequisites, is_locked, publication_status, learning_objectives, thumbnail_url, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      title = excluded.title,
      publication_status = excluded.publication_status
  `);

  insertModule.run('mod-cad-101', 'ARCHITECTURAL', 'CORE', 'BEGINNER', 'Architectural CAD Drafting Fundamentals', 'Foundations of architectural 2D drafting, layer standards, coordinate precision, and dimensioning conventions.', 'None', 0, 'PUBLISHED', JSON.stringify(['Master 2D drafting coordinate inputs', 'Implement architectural layering standards', 'Generate accurate wall and door dimensions']), null, '2026-10-20 09:00:00', '2026-10-24 10:00:00');
  insertModule.run('mod-struc-201', 'STRUCTURAL', 'INTERMEDIATE', 'INTERMEDIATE', 'Structural Detailing & Reinforcement Layouts', 'RC column grid drafting, footing reinforcement schedules, and beam elevation detailing conforming to IS 456.', 'mod-cad-101', 0, 'PUBLISHED', JSON.stringify(['Draft structural column grids and footings', 'Detail beam reinforcement sections', 'Produce compliant rebar bending schedules']), null, '2026-10-20 09:00:00', '2026-10-24 10:00:00');
  insertModule.run('mod-muni-301', 'MUNICIPAL', 'ADVANCED', 'ADVANCED', 'Municipal By-Laws & Permit Package Preparation', 'Setback regulations, Floor Space Index (FSI) calculations, coverage norms, and municipal sanction drawings.', 'mod-cad-101, mod-struc-201', 0, 'PUBLISHED', JSON.stringify(['Calculate FSI, coverage and setbacks', 'Compose standard municipal drawing titles and notes', 'Verify compliance with local building bye-laws']), null, '2026-10-20 09:00:00', '2026-10-24 10:00:00');

  const insertChapter = db.prepare(`
    INSERT INTO training_chapters (
      id, module_id, title, description, chapter_order, created_at
    ) VALUES (?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      title = excluded.title
  `);
  insertChapter.run('ch-cad-101-1', 'mod-cad-101', 'CAD Coordinates & Setup', 'Coordinate grids, snaps, and unit initialization.', 1, '2026-10-20 09:30:00');
  insertChapter.run('ch-cad-101-2', 'mod-cad-101', 'Walls, Doors & Windows', 'Component placement and dimension conventions.', 2, '2026-10-20 10:00:00');
  insertChapter.run('ch-struc-201-1', 'mod-struc-201', 'Column Grids & Footings', 'Grid generation and pad footing detailing.', 1, '2026-10-20 10:30:00');
  insertChapter.run('ch-muni-301-1', 'mod-muni-301', 'Zoning, FSI & Setbacks', 'Statutory calculations and compliance sheets.', 1, '2026-10-20 11:00:00');

  const insertLesson = db.prepare(`
    INSERT INTO training_lessons (
      id, module_id, chapter_id, title, content, lesson_order, estimated_duration, is_required, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      title = excluded.title
  `);
  insertLesson.run('les-cad-101-1', 'mod-cad-101', 'ch-cad-101-1', 'Introduction to CAD & Coordinates', '# Intro\nCartesian coordinates, absolute vs relative entries.', 1, '45 mins', 1, '2026-10-20 09:45:00', '2026-10-24 10:00:00');
  insertLesson.run('les-cad-101-2', 'mod-cad-101', 'ch-cad-101-1', 'Layers, Line Weights & Standards', '# Layers\nLayer standards and color mapping.', 2, '30 mins', 1, '2026-10-20 10:15:00', '2026-10-24 10:00:00');
  insertLesson.run('les-cad-101-3', 'mod-cad-101', 'ch-cad-101-2', 'Wall Layouts & Dimensioning', '# Walls\nExterior and interior walls.', 3, '60 mins', 1, '2026-10-20 10:45:00', '2026-10-24 10:00:00');
  insertLesson.run('les-struc-201-1', 'mod-struc-201', 'ch-struc-201-1', 'Column Grids & Footing Layouts', '# Column Grids\nGrid referencing and offsets.', 1, '60 mins', 1, '2026-10-20 11:00:00', '2026-10-24 10:00:00');
  insertLesson.run('les-muni-301-1', 'mod-muni-301', 'ch-muni-301-1', 'Zoning Norms & FSI Calculation', '# Zoning\nFormulas for Built-Up Area and FSI.', 1, '45 mins', 1, '2026-10-20 11:15:00', '2026-10-24 10:00:00');

  // Student 1 Learning Plans & Credentials
  const studentUid = '2iypyxUntQX6djOzwjgPo5xWrGD2';
  const adminUid = 'bCrLwG8lMRbViDOrBmClwc96xJ42';
  const insertPlan = db.prepare(`
    INSERT INTO student_learning_plans (
      id, student_id, module_id, assigned_by, assigned_at, target_completion_date, instructions, status, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      status = excluded.status
  `);
  insertPlan.run('plan-stu-01', studentUid, 'mod-cad-101', adminUid, '2026-10-21 08:00:00', '2026-10-28 18:00:00', 'Complete all 3 foundational CAD lessons.', 'COMPLETED', '2026-10-21 08:00:00', '2026-10-24 08:00:00');
  insertPlan.run('plan-stu-02', studentUid, 'mod-struc-201', adminUid, '2026-10-22 08:00:00', '2026-11-05 18:00:00', 'Focus on IS 456 column grids.', 'IN_PROGRESS', '2026-10-22 08:00:00', '2026-10-24 08:00:00');
  insertPlan.run('plan-stu-03', studentUid, 'mod-muni-301', adminUid, '2026-10-23 08:00:00', '2026-11-15 18:00:00', 'Municipal bye-law track.', 'ASSIGNED', '2026-10-23 08:00:00', '2026-10-23 08:00:00');

  const insertLessonProg = db.prepare(`
    INSERT INTO student_lesson_progress (
      id, student_id, lesson_id, status, completed_at
    ) VALUES (?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      status = excluded.status
  `);
  insertLessonProg.run('prog-cad-1', studentUid, 'les-cad-101-1', 'COMPLETED', '2026-10-22 14:00:00');
  insertLessonProg.run('prog-cad-2', studentUid, 'les-cad-101-2', 'COMPLETED', '2026-10-22 15:30:00');
  insertLessonProg.run('prog-cad-3', studentUid, 'les-cad-101-3', 'COMPLETED', '2026-10-23 11:00:00');
  insertLessonProg.run('prog-struc-1', studentUid, 'les-struc-201-1', 'IN_PROGRESS', null);

  const insertModuleProg = db.prepare(`
    INSERT INTO student_progress (
      id, student_id, module_id, status, score, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      status = excluded.status,
      score = excluded.score
  `);
  insertModuleProg.run('modprog-cad', studentUid, 'mod-cad-101', 'Completed', 100, '2026-10-24 08:00:00');
  insertModuleProg.run('modprog-struc', studentUid, 'mod-struc-201', 'In Progress', 33, '2026-10-24 08:00:00');
  insertModuleProg.run('modprog-muni', studentUid, 'mod-muni-301', 'Not Started', 0, '2026-10-24 08:00:00');

  const insertCredential = db.prepare(`
    INSERT INTO student_credentials (
      id, student_id, type, reference_id, title, description, certificate_object_key, verification_token, issued_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      title = excluded.title
  `);
  insertCredential.run('crd-student-01', studentUid, 'MODULE_COMPLETION', 'mod-cad-101', 'Architectural CAD Drafting Fundamentals Certificate', 'Mastery of 2D CAD drafting standards.', 'certificates/2iypyxUntQX6djOzwjgPo5xWrGD2/CRT-STU-2026-ARCH101.pdf', 'CRT-STU-2026-ARCH101', '2026-10-24 09:00:00');

  console.log('✓ Training curriculum synchronized.');

  // 4. Projects (Exact 33 projects matching Live Vercel dashboard)
  // Breakdown:
  // - 19 COMPLETED (17 commercial + 2 student)
  // - 1 CANCELLED
  // - 0 SUBMITTED (Requires Review = 0)
  // - 4 WAITING_ASSIGNMENT (Needs Draughtsman = 4)
  // - 5 ACTIVE IN DRAFTING (3 IN_PROGRESS + 2 WAITING_ACCEPTANCE)
  // - 4 IN REVIEW (2 UNDER_ENGINEER_REVIEW + 2 UNDER_CLIENT_REVIEW)
  // Total = 33 projects!

  const insertProject = db.prepare(`
    INSERT INTO projects (
      id, client_id, project_name, project_address, drawing_name, drawing_type, project_area,
      status, last_action_id, draughtsman_id, draughtsman_name, rejection_reason,
      created_at, submitted_at, approved_at, assigned_at, rejected_at, cancelled_at,
      total_value, is_training_project, training_module_id, current_assignment_id, correction_round
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      client_id = excluded.client_id,
      project_name = excluded.project_name,
      project_address = excluded.project_address,
      drawing_name = excluded.drawing_name,
      drawing_type = excluded.drawing_type,
      project_area = excluded.project_area,
      status = excluded.status,
      last_action_id = excluded.last_action_id,
      draughtsman_id = excluded.draughtsman_id,
      draughtsman_name = excluded.draughtsman_name,
      rejection_reason = excluded.rejection_reason,
      created_at = excluded.created_at,
      submitted_at = excluded.submitted_at,
      approved_at = excluded.approved_at,
      assigned_at = excluded.assigned_at,
      cancelled_at = excluded.cancelled_at,
      total_value = excluded.total_value,
      is_training_project = excluded.is_training_project,
      current_assignment_id = excluded.current_assignment_id,
      correction_round = excluded.correction_round
  `);

  const eng1 = 'KXAR90JgoVYLuOKzkbxpKTC8ATa2';
  const eng2 = 'usr-eng-02-alpha';
  const eng3 = 'usr-eng-03-beta';
  const eng4 = 'usr-eng-04-gamma';

  const dm1 = 'TJjtkBm3lgRlpKtcI5u3jpYPH9s1';
  const dm2 = 'usr-dm-02-kavita';
  const dm3 = 'usr-dm-03-suresh';

  // --- Category A: 19 COMPLETED PROJECTS (17 commercial + 2 student) ---
  // Commercial 1-4 (Verified historical test suites)
  insertProject.run('08e9407d-d78c-4dae-928d-9db3f92a4cef', eng1, 'MASTER-E2E-99C3 Cybernetic Medical Center', '12 Healthcare Boulevard, Bangalore', 'MEP Coordination Drawing (1:50)', 'MEP', '18500', 'COMPLETED', 'act-08e9-final', dm1, 'Staging Draughtsman Primary', null, '2026-10-24 04:00:00', '2026-10-24 04:10:00', '2026-10-24 05:32:30', '2026-10-24 04:20:00', null, null, 68000.0, 0, null, 'ad961f69-1b4f-413e-bed1-76fcbf15f92a', 1);
  insertProject.run('c74d1b06-61f4-44e6-bb8a-79206c676c27', eng1, 'D14-FINAL-E8D2 Commercial Hub & Towers', '77 Skyline Boulevard, Chennai', 'High-Rise Structural Package (1:100)', 'STRUCTURAL', '12500', 'COMPLETED', 'act-c74d-final', dm1, 'Staging Draughtsman Primary', null, '2026-10-24 02:00:00', '2026-10-24 02:05:00', '2026-10-24 03:27:39', '2026-10-24 02:15:00', null, null, 45000.0, 0, null, 'affca0c2-cf1f-49a2-b7a8-ba4a61019b4e', 1);
  insertProject.run('2019ec54-456e-49dd-991f-85d945401e4c', eng2, 'D15-RUNA Ecotech Campus Phase 1', '40 Technology Drive, Coimbatore', 'Architectural Site Plan (1:200)', 'SITE_PLAN', '22000', 'COMPLETED', 'act-2019-final', dm2, 'Kavita Patel (Senior CAD Specialist)', null, '2026-10-23 10:00:00', '2026-10-23 10:15:00', '2026-10-23 14:30:00', '2026-10-23 10:30:00', null, null, 85000.0, 0, null, 'asgn-2019-ecotech', 1);
  insertProject.run('67bd0615-d835-48a2-ba3c-d60381f40389', eng2, 'D15-RUNB Skyline Residences Tower B', '88 Marina Beach Road, Chennai', 'Structural Column Layout (1:50)', 'STRUCTURAL', '16000', 'COMPLETED', 'act-67bd-final', dm3, 'Suresh Patel (BIM Modeler)', null, '2026-10-23 11:00:00', '2026-10-23 11:15:00', '2026-10-23 16:00:00', '2026-10-23 11:30:00', null, null, 52000.0, 0, null, 'asgn-67bd-skyline', 1);

  // Commercial 5-17
  insertProject.run('PRJ-COMP-005', eng2, 'Horizon Tech Park Block A', 'Plot 12, OMR IT Highway, Chennai', 'HVAC Routing Blueprint (1:100)', 'MEP', '14000', 'COMPLETED', 'act-c005', dm2, 'Kavita Patel', null, '2026-10-20 08:00:00', '2026-10-20 08:30:00', '2026-10-22 17:00:00', '2026-10-20 09:00:00', null, null, 42000.0, 0, null, 'asgn-c005', 0);
  insertProject.run('PRJ-COMP-006', eng2, 'Metro Rail Station South Concourse', 'Anna Salai Junction, Chennai', 'Concourse Floor Tiling Plan (1:50)', 'FLOOR_PLAN', '9500', 'COMPLETED', 'act-c006', dm2, 'Kavita Patel', null, '2026-10-20 09:00:00', '2026-10-20 09:30:00', '2026-10-22 18:00:00', '2026-10-20 10:00:00', null, null, 38000.0, 0, null, 'asgn-c006', 0);
  insertProject.run('PRJ-COMP-007', eng3, 'Grand Central Retail Mall Elevation', 'Opposite Clock Tower, Madurai', 'Main Facade Glass Elevation (1:100)', 'ELEVATION', '28000', 'COMPLETED', 'act-c007', dm3, 'Suresh Patel', null, '2026-10-21 08:00:00', '2026-10-21 08:30:00', '2026-10-23 12:00:00', '2026-10-21 09:00:00', null, null, 95000.0, 0, null, 'asgn-c007', 0);
  insertProject.run('PRJ-COMP-008', eng3, 'Riverside Luxury Villas Cluster', 'Old Boat Club Road, Coimbatore', 'Master Foundation Grid (1:200)', 'STRUCTURAL', '34000', 'COMPLETED', 'act-c008', dm3, 'Suresh Patel', null, '2026-10-21 09:00:00', '2026-10-21 09:30:00', '2026-10-23 14:00:00', '2026-10-21 10:00:00', null, null, 110000.0, 0, null, 'asgn-c008', 0);
  insertProject.run('PRJ-COMP-009', eng3, 'Apex Tower Corporate Headquarters', 'Avinashi Road, Coimbatore', 'Executive Penthouse Layout (1:50)', 'FLOOR_PLAN', '8200', 'COMPLETED', 'act-c009', dm3, 'Suresh Patel', null, '2026-10-21 10:00:00', '2026-10-21 10:30:00', '2026-10-23 15:30:00', '2026-10-21 11:00:00', null, null, 48000.0, 0, null, 'asgn-c009', 0);
  insertProject.run('PRJ-COMP-010', eng4, 'Sunrise Hospital ICU Wing Structural Plan', 'Trichy Main Road, Thanjavur', 'Critical Care Unit MEP Blueprint (1:50)', 'MEP', '11500', 'COMPLETED', 'act-c010', dm1, 'Staging Draughtsman Primary', null, '2026-10-22 08:00:00', '2026-10-22 08:30:00', '2026-10-23 17:00:00', '2026-10-22 09:00:00', null, null, 62000.0, 0, null, 'asgn-c010', 0);
  insertProject.run('PRJ-COMP-011', eng4, 'Greenfield Sports Arena Layout', 'Ring Road Bypass, Salem', 'Bleacher Foundation Details (1:100)', 'STRUCTURAL', '45000', 'COMPLETED', 'act-c011', dm2, 'Kavita Patel', null, '2026-10-22 09:00:00', '2026-10-22 09:30:00', '2026-10-23 18:00:00', '2026-10-22 10:00:00', null, null, 135000.0, 0, null, 'asgn-c011', 0);
  insertProject.run('PRJ-COMP-012', eng4, 'Silver Springs Residential Tower 4', 'Vandalur Outer Ring Road, Chennai', 'Reinforced Concrete Beam Schedule', 'STRUCTURAL', '19000', 'COMPLETED', 'act-c012', dm3, 'Suresh Patel', null, '2026-10-22 10:00:00', '2026-10-22 10:30:00', '2026-10-23 19:00:00', '2026-10-22 11:00:00', null, null, 72000.0, 0, null, 'asgn-c012', 0);
  insertProject.run('PRJ-COMP-013', eng2, 'Cyber Gateway Data Center Civil Brief', 'Electronic City Phase II, Bangalore', 'Server Hall Raised Flooring Plan (1:50)', 'FLOOR_PLAN', '15000', 'COMPLETED', 'act-c013', dm1, 'Staging Draughtsman Primary', null, '2026-10-22 11:00:00', '2026-10-22 11:30:00', '2026-10-24 01:00:00', '2026-10-22 12:00:00', null, null, 55000.0, 0, null, 'asgn-c013', 0);
  insertProject.run('PRJ-COMP-014', eng3, 'Royal Orchid Banquet Hall', 'Race Course Road, Coimbatore', 'Acoustic Ceiling & Lighting Plan (1:50)', 'MEP', '7500', 'COMPLETED', 'act-c014', dm2, 'Kavita Patel', null, '2026-10-22 12:00:00', '2026-10-22 12:30:00', '2026-10-24 01:30:00', '2026-10-22 13:00:00', null, null, 36000.0, 0, null, 'asgn-c014', 0);
  insertProject.run('PRJ-COMP-015', eng4, 'West End Community Center', 'Cross Cut Road, Coimbatore', 'Auditorium Seating & Sightlines (1:100)', 'SITE_PLAN', '13000', 'COMPLETED', 'act-c015', dm3, 'Suresh Patel', null, '2026-10-22 13:00:00', '2026-10-22 13:30:00', '2026-10-24 02:00:00', '2026-10-22 14:00:00', null, null, 48000.0, 0, null, 'asgn-c015', 0);
  insertProject.run('PRJ-COMP-016', eng2, 'Blue Ridge Hillside Resort Plan', 'Kotagiri Road, Ooty', 'Contour Grading & Retaining Wall Detail', 'STRUCTURAL', '21000', 'COMPLETED', 'act-c016', dm1, 'Staging Draughtsman Primary', null, '2026-10-22 14:00:00', '2026-10-22 14:30:00', '2026-10-24 02:30:00', '2026-10-22 15:00:00', null, null, 88000.0, 0, null, 'asgn-c016', 0);
  insertProject.run('PRJ-COMP-017', eng3, 'Golden Palm Warehouse Logistics Depot', 'NH-44 Highway, Hosur', 'Portal Frame Steel Detailing (1:100)', 'STRUCTURAL', '32000', 'COMPLETED', 'act-c017', dm2, 'Kavita Patel', null, '2026-10-22 15:00:00', '2026-10-22 15:30:00', '2026-10-24 03:00:00', '2026-10-22 16:00:00', null, null, 98000.0, 0, null, 'asgn-c017', 0);

  // Student practical projects (2 completed)
  insertProject.run('prj-student-appr-01', studentUid, 'Residential Ground Floor Plan (1200 sqft)', 'Plot 14, Lotus Enclave, Coimbatore', 'Floor Plan & Section A-A (1:50)', 'FLOOR_PLAN', '1200', 'COMPLETED', 'act-stu-01-appr', studentUid, 'Staging Student Primary', null, '2026-10-22 09:00:00', '2026-10-22 09:00:00', '2026-10-24 07:30:00', '2026-10-22 09:30:00', null, null, null, 1, 'mod-cad-101', 'stu-asgn-01', 0);
  insertProject.run('prj-student-rev-02', studentUid, 'Multi-Story Commercial Office (Level 4)', '45 Innovation Way, Bangalore', 'Level 4 Partition Plan (1:100)', 'FLOOR_PLAN', '3500', 'COMPLETED', 'act-stu-02-appr', studentUid, 'Staging Student Primary', null, '2026-10-23 10:00:00', '2026-10-23 10:00:00', '2026-10-24 08:30:00', '2026-10-23 10:30:00', null, null, null, 1, 'mod-cad-101', 'stu-asgn-02', 1);

  // --- Category B: 1 CANCELLED PROJECT ---
  insertProject.run('PRJ-CANC-001', eng4, 'Old Industrial Estate Warehouse Redevelopment', 'Plot 5, Guindy Industrial Estate, Chennai', 'Demolition & Site Clearance Plan (1:500)', 'SITE_PLAN', '16500', 'CANCELLED', 'act-canc-001', null, null, 'Zoning classification updated by local municipal board', '2026-10-20 11:00:00', '2026-10-20 11:30:00', null, null, null, '2026-10-21 16:00:00', 35000.0, 0, null, null, 0);

  // --- Category C: 4 WAITING_ASSIGNMENT (Needs Draughtsman = 4) ---
  insertProject.run('PRJ-D10-R1-531B92CC', eng1, 'D10-R1 Tech Park Executive Suite 4500 sqft', 'Plot 505, IT Corridor, OMR, Chennai', 'Executive Interior & Partition Plan (1:50)', 'FLOOR_PLAN', '4500', 'WAITING_ASSIGNMENT', 'act-531b-app', null, null, null, '2026-10-23 13:30:00', '2026-10-23 13:30:00', '2026-10-23 13:31:00', null, null, null, null, 0, null, null, 0);
  insertProject.run('PRJ-D10-R2-E6FD4C09', eng1, 'D10-R2 Residential Villa Structural Blueprint 3200 sqft', '88 Green Acres, Coimbatore', 'Foundation & Column Layout (1:50)', 'STRUCTURAL', '3200', 'WAITING_ASSIGNMENT', 'act-e6fd-app', null, null, null, '2026-10-23 13:31:00', '2026-10-23 13:31:00', '2026-10-23 13:32:00', null, null, null, null, 0, null, null, 0);
  insertProject.run('PRJ-D10-R3-8D2A9DD5', eng1, 'D10-R3 Municipal Permit Approval Drawing 1800 sqft', '12 Temple View Road, Madurai', 'Building Elevation & Section Package (1:100)', 'ELEVATION', '1800', 'WAITING_ASSIGNMENT', 'act-8d2a-app', null, null, null, '2026-10-23 13:32:00', '2026-10-23 13:32:00', '2026-10-23 13:33:00', null, null, null, null, 0, null, null, 0);
  insertProject.run('PRJ-WAIT-004', eng4, 'Ocean View Penthouse HVAC Routing Plan', '44 East Coast Road, Chennai', 'Chilled Water & Ductwork Schematic (1:50)', 'MEP', '6200', 'WAITING_ASSIGNMENT', 'act-wait-004', null, null, null, '2026-10-23 14:00:00', '2026-10-23 14:10:00', '2026-10-23 14:30:00', null, null, null, 42000.0, 0, null, null, 0);

  // --- Category D: 5 ACTIVE IN DRAFTING (3 IN_PROGRESS + 2 WAITING_ACCEPTANCE) ---
  // In Progress (3)
  insertProject.run('PRJ-D10-R2-6271921E', eng1, 'D10-R2 Residential Villa Structural Blueprint 3200 sqft', '42 Palm Grove Enclave, Coimbatore', 'Structural Framing Package (1:50)', 'STRUCTURAL', '3200', 'IN_PROGRESS', '047e6b2a-e4f6-49dc-a076-2e15ebe04cea', dm1, 'Staging Draughtsman Primary', null, '2026-10-23 13:33:55', '2026-10-23 13:33:55', '2026-10-23 13:34:00', '2026-10-23 13:34:02', null, null, null, 0, null, 'b4372747-5aa0-46e1-bf37-fcd7503e8999', 0);
  insertProject.run('PRJ-ACT-002', eng2, 'Emerald Heights Floor Plan 2800 sqft', 'Plot 9, Saravanampatti, Coimbatore', 'Architectural Layout Package (1:100)', 'FLOOR_PLAN', '2800', 'IN_PROGRESS', 'act-act-002', dm2, 'Kavita Patel (Senior CAD Specialist)', null, '2026-10-23 15:00:00', '2026-10-23 15:15:00', '2026-10-23 15:30:00', '2026-10-23 15:45:00', null, null, 32000.0, 0, null, 'asgn-act-002', 0);
  insertProject.run('PRJ-ACT-003', eng3, 'Central Library Basement Foundation', 'Town Hall Circle, Madurai', 'Retaining Wall & Raft Foundation (1:100)', 'STRUCTURAL', '11000', 'IN_PROGRESS', 'act-act-003', dm3, 'Suresh Patel (BIM Modeler)', null, '2026-10-23 16:00:00', '2026-10-23 16:15:00', '2026-10-23 16:30:00', '2026-10-23 16:45:00', null, null, 58000.0, 0, null, 'asgn-act-003', 0);

  // Waiting Acceptance (2)
  insertProject.run('PRJ-D10-R3-B5CC85FB', eng1, 'D10-R3 Municipal Permit Approval Drawing 1800 sqft', '15 Temple View Road, Madurai', 'Municipal / Permit Package (1:200)', 'SITE_PLAN', '1800', 'WAITING_ACCEPTANCE', '9d5cd78e-b9a4-4958-8d41-0c11f7c7cbbe', dm1, 'Staging Draughtsman Primary', null, '2026-10-23 13:34:18', '2026-10-23 13:34:18', '2026-10-23 13:34:22', '2026-10-23 13:34:23', null, null, null, 0, null, '1a01eabe-7e4e-4ed9-af75-f66c3d44a733', 0);
  insertProject.run('PRJ-D10-R1-95101456', eng1, 'D10-R1 Commercial Office Floor Plan 2400 sqft', 'Plot 101, Tech Park Avenue, Chennai', 'Architectural Layout Package (1:100)', 'FLOOR_PLAN', '2400', 'WAITING_ACCEPTANCE', 'fc79b81e-ea8d-44f3-94e3-36d1a6e09de8', dm1, 'Staging Draughtsman Primary', null, '2026-10-23 13:33:29', '2026-10-23 13:33:29', '2026-10-23 13:33:35', '2026-10-23 13:33:35', null, null, null, 0, null, 'daee0b2c-958b-483e-ab13-579f622c000e', 0);

  // --- Category E: 4 IN REVIEW (2 UNDER_ENGINEER_REVIEW + 2 UNDER_CLIENT_REVIEW) ---
  // Under Engineer Review (2)
  insertProject.run('PRJ-REV-001', eng2, 'Primrose Commercial Complex Exterior Elevations', 'GST Road, Tambaram, Chennai', 'North & West Elevations (1:100)', 'ELEVATION', '17500', 'UNDER_ENGINEER_REVIEW', 'act-rev-001', dm2, 'Kavita Patel (Senior CAD Specialist)', null, '2026-10-23 11:00:00', '2026-10-23 11:20:00', '2026-10-23 11:40:00', '2026-10-23 12:00:00', null, null, 48000.0, 0, null, 'asgn-rev-001', 0);
  insertProject.run('PRJ-REV-002', eng3, 'Lotus Plaza Structural Beam Framing', 'KK Nagar 80 Feet Road, Madurai', 'Level 2 & 3 Floor Beam Schedules', 'STRUCTURAL', '12800', 'UNDER_ENGINEER_REVIEW', 'act-rev-002', dm3, 'Suresh Patel (BIM Modeler)', null, '2026-10-23 12:00:00', '2026-10-23 12:20:00', '2026-10-23 12:40:00', '2026-10-23 13:00:00', null, null, 41000.0, 0, null, 'asgn-rev-002', 0);

  // Under Client Review (2)
  insertProject.run('PRJ-REV-003', eng4, 'Green Valley School Electrical Layout', 'Kovaipudur, Coimbatore', 'Power Distribution & Conduit Layout', 'MEP', '14200', 'UNDER_CLIENT_REVIEW', 'act-rev-003', dm1, 'Staging Draughtsman Primary', null, '2026-10-23 13:00:00', '2026-10-23 13:20:00', '2026-10-23 13:40:00', '2026-10-23 14:00:00', null, null, 39000.0, 0, null, 'asgn-rev-003', 0);
  insertProject.run('PRJ-REV-004', eng4, 'Silicon Bay Office Fire Safety Blueprint', 'OMR Navalur, Chennai', 'Sprinkler & Fire Exit Evacuation Plan', 'MEP', '23000', 'UNDER_CLIENT_REVIEW', 'act-rev-004', dm2, 'Kavita Patel (Senior CAD Specialist)', null, '2026-10-23 14:00:00', '2026-10-23 14:20:00', '2026-10-23 14:40:00', '2026-10-23 15:00:00', null, null, 64000.0, 0, null, 'asgn-rev-004', 0);

  console.log('✓ Projects synchronized: exactly 33 projects (19 completed, 1 cancelled, 0 submitted, 4 waiting assignment, 3 in progress, 2 waiting acceptance, 2 under engineer review, 2 under client review).');

  // 5. Assignments Table
  const insertAssignment = db.prepare(`
    INSERT INTO assignments (
      id, project_id, draughtsman_id, status, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      status = excluded.status,
      updated_at = excluded.updated_at
  `);

  // Draughtsman 1 assignments (5 assignments, preserved)
  insertAssignment.run('affca0c2-cf1f-49a2-b7a8-ba4a61019b4e', 'c74d1b06-61f4-44e6-bb8a-79206c676c27', dm1, 'ACCEPTED', '2026-10-24 02:15:00', '2026-10-24 02:20:00');
  insertAssignment.run('ad961f69-1b4f-413e-bed1-76fcbf15f92a', '08e9407d-d78c-4dae-928d-9db3f92a4cef', dm1, 'ACCEPTED', '2026-10-24 04:20:00', '2026-10-24 04:25:00');
  insertAssignment.run('1a01eabe-7e4e-4ed9-af75-f66c3d44a733', 'PRJ-D10-R3-B5CC85FB', dm1, 'PENDING', '2026-10-23 13:34:23', '2026-10-23 13:34:23');
  insertAssignment.run('b4372747-5aa0-46e1-bf37-fcd7503e8999', 'PRJ-D10-R2-6271921E', dm1, 'ACCEPTED', '2026-10-23 13:34:02', '2026-10-23 13:34:05');
  insertAssignment.run('daee0b2c-958b-483e-ab13-579f622c000e', 'PRJ-D10-R1-95101456', dm1, 'PENDING', '2026-10-23 13:33:35', '2026-10-23 13:33:35');

  // Draughtsman 2 assignments
  insertAssignment.run('asgn-2019-ecotech', '2019ec54-456e-49dd-991f-85d945401e4c', dm2, 'ACCEPTED', '2026-10-23 10:30:00', '2026-10-23 10:35:00');
  insertAssignment.run('asgn-act-002', 'PRJ-ACT-002', dm2, 'ACCEPTED', '2026-10-23 15:45:00', '2026-10-23 15:50:00');
  insertAssignment.run('asgn-rev-001', 'PRJ-REV-001', dm2, 'ACCEPTED', '2026-10-23 12:00:00', '2026-10-23 12:05:00');
  insertAssignment.run('asgn-rev-004', 'PRJ-REV-004', dm2, 'ACCEPTED', '2026-10-23 15:00:00', '2026-10-23 15:05:00');

  // Draughtsman 3 assignments
  insertAssignment.run('asgn-67bd-skyline', '67bd0615-d835-48a2-ba3c-d60381f40389', dm3, 'ACCEPTED', '2026-10-23 11:30:00', '2026-10-23 11:35:00');
  insertAssignment.run('asgn-act-003', 'PRJ-ACT-003', dm3, 'ACCEPTED', '2026-10-23 16:45:00', '2026-10-23 16:50:00');
  insertAssignment.run('asgn-rev-002', 'PRJ-REV-002', dm3, 'ACCEPTED', '2026-10-23 13:00:00', '2026-10-23 13:05:00');

  console.log('✓ Assignments synchronized.');

  // 6. Student practical assignments
  const insertStudentAssignment = db.prepare(`
    INSERT INTO student_assignments (
      id, student_id, assignment_type, project_id, status, created_at
    ) VALUES (?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      status = excluded.status
  `);
  insertStudentAssignment.run('stu-asgn-01', studentUid, 'PRACTICAL_PROJECT', 'prj-student-appr-01', 'COMPLETED', '2026-10-22 09:30:00');
  insertStudentAssignment.run('stu-asgn-02', studentUid, 'PRACTICAL_PROJECT', 'prj-student-rev-02', 'COMPLETED', '2026-10-23 10:30:00');

  // 7. Preserved Files (7 files in files table, ensuring R2 telemetry consistency)
  const insertFile = db.prepare(`
    INSERT INTO files (
      id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status, created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      status = excluded.status
  `);
  insertFile.run('v1-file-1792812495227', 'c74d1b06-61f4-44e6-bb8a-79206c676c27', dm1, 'commercial_hub_v1.dwg', 'commercial_hub_v1.dwg', 'projects/c74d1b06-61f4-44e6-bb8a-79206c676c27/v1/commercial_hub_v1.dwg', 'application/acad', 2845120, 'DRAWING_VERSION', 'ACTIVE', '2026-10-24 02:45:00');
  insertFile.run('v2-file-1792812541816', 'c74d1b06-61f4-44e6-bb8a-79206c676c27', dm1, 'commercial_hub_v2.dwg', 'commercial_hub_v2.dwg', 'projects/c74d1b06-61f4-44e6-bb8a-79206c676c27/v2/commercial_hub_v2.dwg', 'application/acad', 2850400, 'DRAWING_VERSION', 'ACTIVE', '2026-10-24 03:15:00');
  insertFile.run('v1-dwg-1792819951005', '08e9407d-d78c-4dae-928d-9db3f92a4cef', dm1, 'cybernetic_center_v1.dwg', 'cybernetic_center_v1.dwg', 'projects/08e9407d-d78c-4dae-928d-9db3f92a4cef/v1/cybernetic_center_v1.dwg', 'application/acad', 2758920, 'DRAWING_VERSION', 'ACTIVE', '2026-10-24 04:45:00');
  insertFile.run('v2-dwg-1792819958372', '08e9407d-d78c-4dae-928d-9db3f92a4cef', dm1, 'cybernetic_center_v2.dwg', 'cybernetic_center_v2.dwg', 'projects/08e9407d-d78c-4dae-928d-9db3f92a4cef/v2/cybernetic_center_v2.dwg', 'application/acad', 2761248, 'DRAWING_VERSION', 'ACTIVE', '2026-10-24 05:15:00');
  insertFile.run('file-stu-dwg-01', 'prj-student-appr-01', studentUid, 'res_ground_floor_v1.dwg', 'res_ground_floor_v1.dwg', 'students/2iypyxUntQX6djOzwjgPo5xWrGD2/practicals/prj-student-appr-01/v1.dwg', 'application/acad', 2048000, 'STUDENT_PRACTICAL', 'ACTIVE', '2026-10-22 14:00:00');
  insertFile.run('file-stu-dwg-02-v1', 'prj-student-rev-02', studentUid, 'comm_level4_v1.dwg', 'comm_level4_v1.dwg', 'students/2iypyxUntQX6djOzwjgPo5xWrGD2/practicals/prj-student-rev-02/v1.dwg', 'application/acad', 2043600, 'STUDENT_PRACTICAL', 'ACTIVE', '2026-10-23 11:00:00');
  insertFile.run('file-stu-dwg-02-v2', 'prj-student-rev-02', studentUid, 'comm_level4_v2.dwg', 'comm_level4_v2.dwg', 'students/2iypyxUntQX6djOzwjgPo5xWrGD2/practicals/prj-student-rev-02/v2.dwg', 'application/acad', 2043800, 'STUDENT_PRACTICAL', 'ACTIVE', '2026-10-24 08:00:00');

  // 8. Drawing Versions (7 records)
  const insertVersion = db.prepare(`
    INSERT INTO drawing_versions (
      id, project_id, file_id, version_number, uploaded_by, correction_id, created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      version_number = excluded.version_number
  `);
  insertVersion.run('v1-ver-c74d1b06', 'c74d1b06-61f4-44e6-bb8a-79206c676c27', 'v1-file-1792812495227', 1, dm1, null, '2026-10-24 02:45:00');
  insertVersion.run('v2-ver-c74d1b06', 'c74d1b06-61f4-44e6-bb8a-79206c676c27', 'v2-file-1792812541816', 2, dm1, 'corr-c74d1b06-r1', '2026-10-24 03:15:00');
  insertVersion.run('v1-ver-08e9407d', '08e9407d-d78c-4dae-928d-9db3f92a4cef', 'v1-dwg-1792819951005', 1, dm1, null, '2026-10-24 04:45:00');
  insertVersion.run('v2-ver-08e9407d', '08e9407d-d78c-4dae-928d-9db3f92a4cef', 'v2-dwg-1792819958372', 2, dm1, 'corr-08e9407d-r1', '2026-10-24 05:15:00');
  insertVersion.run('ver-stu-01', 'prj-student-appr-01', 'file-stu-dwg-01', 1, studentUid, null, '2026-10-22 14:00:00');
  insertVersion.run('ver-stu-02-v1', 'prj-student-rev-02', 'file-stu-dwg-02-v1', 1, studentUid, null, '2026-10-23 11:00:00');
  insertVersion.run('ver-stu-02-v2', 'prj-student-rev-02', 'file-stu-dwg-02-v2', 2, studentUid, 'corr-stu-02', '2026-10-24 08:00:00');

  // 9. Corrections (3 records)
  const insertCorrection = db.prepare(`
    INSERT INTO corrections (
      id, project_id, target_version_id, round_number, requested_by, description, status, created_at, resolved_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      status = excluded.status,
      resolved_at = excluded.resolved_at
  `);
  insertCorrection.run('corr-c74d1b06-r1', 'c74d1b06-61f4-44e6-bb8a-79206c676c27', 'v1-ver-c74d1b06', 1, eng1, 'Shift shear wall SW-4 150mm north to align with architectural lift core.', 'RESOLVED', '2026-10-24 03:00:00', '2026-10-24 03:27:39');
  insertCorrection.run('corr-08e9407d-r1', '08e9407d-d78c-4dae-928d-9db3f92a4cef', 'v1-ver-08e9407d', 1, eng1, 'PIN[0.4200,0.5800]: Relocate MRI shielding conduit 500mm east of structural grid C.', 'RESOLVED', '2026-10-24 05:00:00', '2026-10-24 05:32:30');
  insertCorrection.run('corr-stu-02', 'prj-student-rev-02', 'ver-stu-02-v1', 1, adminUid, 'Adjust fire exit stair door swing outward per NBC Part 4 norms.', 'RESOLVED', '2026-10-23 14:00:00', '2026-10-24 08:30:00');

  // 10. Student Evaluations (2 records)
  const insertEvaluation = db.prepare(`
    INSERT INTO evaluations (
      id, project_id, drawing_version_id, evaluator_id, overall_result, general_feedback, criteria_json, created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      overall_result = excluded.overall_result,
      general_feedback = excluded.general_feedback
  `);
  insertEvaluation.run('eval-stu-01', 'prj-student-appr-01', 'ver-stu-01', adminUid, 'APPROVED', 'Exceptional attention to wall hierarchy and dimension precision.', JSON.stringify({ accuracy: 5, technical_standards: 5, layer_hygiene: 5, annotation_clarity: 5 }), '2026-10-24 07:30:00');
  insertEvaluation.run('eval-stu-02', 'prj-student-rev-02', 'ver-stu-02-v2', adminUid, 'APPROVED', 'All redline adjustments successfully incorporated into v2.', JSON.stringify({ accuracy: 4, technical_standards: 5, layer_hygiene: 4, annotation_clarity: 5 }), '2026-10-24 08:30:00');

  // 11. Invoices & Payments (2 records)
  const insertInvoice = db.prepare(`
    INSERT INTO invoices (
      id, project_id, invoice_number, amount, currency, status, due_date, created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      status = excluded.status
  `);
  const insertPayment = db.prepare(`
    INSERT INTO payments (
      id, invoice_id, amount, payment_method, processed_at, recorded_by
    ) VALUES (?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      amount = excluded.amount
  `);
  insertInvoice.run('inv-c74d-01', 'c74d1b06-61f4-44e6-bb8a-79206c676c27', 'INV-2026-0001', 45000.0, 'INR', 'PAID', '2026-11-01 00:00:00', '2026-10-24 03:30:00');
  insertPayment.run('pay-c74d-01', 'inv-c74d-01', 45000.0, 'BANK_TRANSFER', '2026-10-24 04:00:00', adminUid);
  insertInvoice.run('inv-08e9-01', '08e9407d-d78c-4dae-928d-9db3f92a4cef', 'INV-2026-0002', 68000.0, 'INR', 'PAID', '2026-11-01 00:00:00', '2026-10-24 05:40:00');
  insertPayment.run('pay-08e9-01', 'inv-08e9-01', 68000.0, 'NEFT', '2026-10-24 06:00:00', adminUid);

  db.exec('COMMIT;');
  console.log('✓ ALL 33 AUTHORITATIVE PROJECTS AND 17 USERS SUCCESSFULLY COMMITTED.');
} catch (err) {
  db.exec('ROLLBACK;');
  console.error('✗ ERROR during synchronization, rolled back:', err);
  process.exit(1);
}
