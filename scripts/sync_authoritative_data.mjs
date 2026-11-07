import { DatabaseSync } from 'node:sqlite';
import path from 'node:path';

const dbPath = path.resolve('worker/.wrangler/state/v3/d1/miniflare-D1DatabaseObject/fdc94e68165493d9beefe9c542c3ccf242c09e8c388eef5ade0878b760405048.sqlite');
const db = new DatabaseSync(dbPath);

console.log('Synchronizing authoritative staging data into local D1 SQLite...');

// Enable foreign keys
db.exec('PRAGMA foreign_keys = ON;');

db.exec('BEGIN TRANSACTION;');

try {
  // 1. Legal Consent State & Events
  const users = [
    'bCrLwG8lMRbViDOrBmClwc96xJ42',
    'QBhduHDU1mYUxvtQ89adVnwQYCg1',
    'KXAR90JgoVYLuOKzkbxpKTC8ATa2',
    'TJjtkBm3lgRlpKtcI5u3jpYPH9s1',
    '2iypyxUntQX6djOzwjgPo5xWrGD2',
    'AP2Z19U2v9UWTOAe6gtaZtGcg5J2'
  ];

  const insertEvent = db.prepare(`
    INSERT OR IGNORE INTO legal_consent_events (
      id, user_id, document_id, document_type, document_version, action_type,
      consent_purpose, idempotency_key, ip_hash, user_agent, source, recorded_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  const insertState = db.prepare(`
    INSERT OR REPLACE INTO user_consent_state (
      id, user_id, consent_type, purpose_tag, current_status, accepted_version, last_event_id, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `);

  for (const uid of users) {
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
  console.log('✓ Legal consent events and user states synchronized for all 6 staging users.');

  // 2. Training Modules, Chapters, and Lessons
  const insertModule = db.prepare(`
    INSERT OR REPLACE INTO training_modules (
      id, category, type, level, title, description, prerequisites, is_locked, publication_status, learning_objectives, thumbnail_url, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  insertModule.run(
    'mod-cad-101', 'ARCHITECTURAL', 'CORE', 'BEGINNER',
    'Architectural CAD Drafting Fundamentals',
    'Foundations of architectural 2D drafting, layer standards, coordinate precision, and dimensioning conventions.',
    'None', 0, 'PUBLISHED',
    JSON.stringify(['Master 2D drafting coordinate inputs', 'Implement architectural layering standards', 'Generate accurate wall and door dimensions']),
    null, '2026-10-20 09:00:00', '2026-10-24 10:00:00'
  );

  insertModule.run(
    'mod-struc-201', 'STRUCTURAL', 'INTERMEDIATE', 'INTERMEDIATE',
    'Structural Detailing & Reinforcement Layouts',
    'RC column grid drafting, footing reinforcement schedules, and beam elevation detailing conforming to IS 456.',
    'mod-cad-101', 0, 'PUBLISHED',
    JSON.stringify(['Draft structural column grids and footings', 'Detail beam reinforcement sections', 'Produce compliant rebar bending schedules']),
    null, '2026-10-20 09:00:00', '2026-10-24 10:00:00'
  );

  insertModule.run(
    'mod-muni-301', 'MUNICIPAL', 'ADVANCED', 'ADVANCED',
    'Municipal By-Laws & Permit Package Preparation',
    'Setback regulations, Floor Space Index (FSI) calculations, coverage norms, and municipal sanction drawings.',
    'mod-cad-101, mod-struc-201', 0, 'PUBLISHED',
    JSON.stringify(['Calculate FSI, coverage and setbacks', 'Compose standard municipal drawing titles and notes', 'Verify compliance with local building bye-laws']),
    null, '2026-10-20 09:00:00', '2026-10-24 10:00:00'
  );
  console.log('✓ Training modules synchronized (3 modules).');

  const insertChapter = db.prepare(`
    INSERT OR REPLACE INTO training_chapters (
      id, module_id, title, description, chapter_order, created_at
    ) VALUES (?, ?, ?, ?, ?, ?)
  `);

  insertChapter.run('ch-cad-101-1', 'mod-cad-101', 'CAD Coordinates & Setup', 'Coordinate grids, snaps, and unit initialization.', 1, '2026-10-20 09:30:00');
  insertChapter.run('ch-cad-101-2', 'mod-cad-101', 'Walls, Doors & Windows', 'Component placement and dimension conventions.', 2, '2026-10-20 10:00:00');
  insertChapter.run('ch-struc-201-1', 'mod-struc-201', 'Column Grids & Footings', 'Grid generation and pad footing detailing.', 1, '2026-10-20 10:30:00');
  insertChapter.run('ch-muni-301-1', 'mod-muni-301', 'Zoning, FSI & Setbacks', 'Statutory calculations and compliance sheets.', 1, '2026-10-20 11:00:00');
  console.log('✓ Training chapters synchronized (4 chapters).');

  const insertLesson = db.prepare(`
    INSERT OR REPLACE INTO training_lessons (
      id, module_id, chapter_id, title, content, lesson_order, estimated_duration, is_required, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  insertLesson.run(
    'les-cad-101-1', 'mod-cad-101', 'ch-cad-101-1',
    'Introduction to CAD & Coordinates',
    '# Introduction to CAD & Coordinates\n\nUnderstand Cartesian coordinates, absolute vs relative entries, and drawing units.',
    1, '45 mins', 1, '2026-10-20 09:45:00', '2026-10-24 10:00:00'
  );
  insertLesson.run(
    'les-cad-101-2', 'mod-cad-101', 'ch-cad-101-1',
    'Layers, Line Weights & Standards',
    '# Layers & Standards\n\nStandards for layer naming (A-WALL, A-DOOR), color mapping, and lineweights.',
    2, '30 mins', 1, '2026-10-20 10:15:00', '2026-10-24 10:00:00'
  );
  insertLesson.run(
    'les-cad-101-3', 'mod-cad-101', 'ch-cad-101-2',
    'Wall Layouts & Dimensioning',
    '# Wall Layouts & Dimensioning\n\nDrafting exterior and interior walls with precise dimension strings.',
    3, '60 mins', 1, '2026-10-20 10:45:00', '2026-10-24 10:00:00'
  );
  insertLesson.run(
    'les-struc-201-1', 'mod-struc-201', 'ch-struc-201-1',
    'Column Grids & Footing Layouts',
    '# Column Grids & Footings\n\nGrid referencing, offset calculation, and footing schedule cross-referencing.',
    1, '60 mins', 1, '2026-10-20 11:00:00', '2026-10-24 10:00:00'
  );
  insertLesson.run(
    'les-muni-301-1', 'mod-muni-301', 'ch-muni-301-1',
    'Zoning Norms & FSI Calculation',
    '# Zoning Norms & FSI\n\nFormulas for Built-Up Area, Floor Space Index, and statutory road widening setbacks.',
    1, '45 mins', 1, '2026-10-20 11:15:00', '2026-10-24 10:00:00'
  );
  console.log('✓ Training lessons synchronized (5 lessons).');

  // 3. Student Progress & Learning Plans for 2iypyxUntQX6djOzwjgPo5xWrGD2
  const studentUid = '2iypyxUntQX6djOzwjgPo5xWrGD2';
  const adminUid = 'bCrLwG8lMRbViDOrBmClwc96xJ42';

  const insertPlan = db.prepare(`
    INSERT OR REPLACE INTO student_learning_plans (
      id, student_id, module_id, assigned_by, assigned_at, target_completion_date, instructions, status, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  insertPlan.run(
    'plan-stu-01', studentUid, 'mod-cad-101', adminUid, '2026-10-21 08:00:00', '2026-10-28 18:00:00',
    'Complete all 3 foundational CAD lessons and practical submission.', 'COMPLETED', '2026-10-21 08:00:00', '2026-10-24 08:00:00'
  );
  insertPlan.run(
    'plan-stu-02', studentUid, 'mod-struc-201', adminUid, '2026-10-22 08:00:00', '2026-11-05 18:00:00',
    'Focus on IS 456 column grid offsets and rebar schedules.', 'IN_PROGRESS', '2026-10-22 08:00:00', '2026-10-24 08:00:00'
  );
  insertPlan.run(
    'plan-stu-03', studentUid, 'mod-muni-301', adminUid, '2026-10-23 08:00:00', '2026-11-15 18:00:00',
    'Municipal bye-law certification track.', 'ASSIGNED', '2026-10-23 08:00:00', '2026-10-23 08:00:00'
  );
  console.log('✓ Student learning plans synchronized (3 plans).');

  const insertLessonProg = db.prepare(`
    INSERT OR REPLACE INTO student_lesson_progress (
      id, student_id, lesson_id, status, completed_at
    ) VALUES (?, ?, ?, ?, ?)
  `);

  insertLessonProg.run('prog-cad-1', studentUid, 'les-cad-101-1', 'COMPLETED', '2026-10-22 14:00:00');
  insertLessonProg.run('prog-cad-2', studentUid, 'les-cad-101-2', 'COMPLETED', '2026-10-22 15:30:00');
  insertLessonProg.run('prog-cad-3', studentUid, 'les-cad-101-3', 'COMPLETED', '2026-10-23 11:00:00');
  insertLessonProg.run('prog-struc-1', studentUid, 'les-struc-201-1', 'IN_PROGRESS', null);
  console.log('✓ Student lesson progress synchronized (4 lesson records).');

  const insertModuleProg = db.prepare(`
    INSERT OR REPLACE INTO student_progress (
      id, student_id, module_id, status, score, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?)
  `);

  insertModuleProg.run('modprog-cad', studentUid, 'mod-cad-101', 'Completed', 100, '2026-10-24 08:00:00');
  insertModuleProg.run('modprog-struc', studentUid, 'mod-struc-201', 'In Progress', 33, '2026-10-24 08:00:00');
  insertModuleProg.run('modprog-muni', studentUid, 'mod-muni-301', 'Not Started', 0, '2026-10-24 08:00:00');
  console.log('✓ Student module progress synchronized (3 module status records).');

  const insertCredential = db.prepare(`
    INSERT OR REPLACE INTO student_credentials (
      id, student_id, type, reference_id, title, description, certificate_object_key, verification_token, issued_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  insertCredential.run(
    'crd-student-01', studentUid, 'MODULE_COMPLETION', 'mod-cad-101',
    'Architectural CAD Drafting Fundamentals Certificate',
    'Successfully demonstrated mastery of 2D CAD drafting standards, coordinate precision, and architectural layout conventions.',
    'certificates/2iypyxUntQX6djOzwjgPo5xWrGD2/CRT-STU-2026-ARCH101.pdf',
    'CRT-STU-2026-ARCH101',
    '2026-10-24 09:00:00'
  );
  console.log('✓ Student credential synchronized (1 certificate: CRT-STU-2026-ARCH101).');

  // 4. Commercial Projects & Student Practical Projects
  const insertProject = db.prepare(`
    INSERT OR REPLACE INTO projects (
      id, client_id, project_name, project_address, drawing_name, drawing_type, project_area,
      status, last_action_id, draughtsman_id, draughtsman_name, rejection_reason,
      created_at, submitted_at, approved_at, assigned_at, rejected_at, cancelled_at,
      total_value, is_training_project, training_module_id, current_assignment_id, correction_round
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  const engineerUid = 'KXAR90JgoVYLuOKzkbxpKTC8ATa2';
  const draughtsmanUid = 'TJjtkBm3lgRlpKtcI5u3jpYPH9s1';

  // Project 1: D14 Commercial Hub & Towers (COMPLETED)
  insertProject.run(
    'c74d1b06-61f4-44e6-bb8a-79206c676c27',
    engineerUid,
    'D14-FINAL-E8D2 Commercial Hub & Towers',
    '77 Skyline Boulevard, Chennai, Tamil Nadu',
    'Commercial High-Rise Structural Package (1:100)',
    'STRUCTURAL',
    '12500',
    'COMPLETED',
    'act-c74d-final',
    draughtsmanUid,
    'Staging Draughtsman Primary',
    null,
    '2026-10-24 02:00:00',
    '2026-10-24 02:05:00',
    '2026-10-24 03:27:39',
    '2026-10-24 02:15:00',
    null,
    null,
    45000.0,
    0,
    null,
    'affca0c2-cf1f-49a2-b7a8-ba4a61019b4e',
    1
  );

  // Project 2: Master E2E Cybernetic Medical Center (COMPLETED)
  insertProject.run(
    '08e9407d-d78c-4dae-928d-9db3f92a4cef',
    engineerUid,
    'MASTER-E2E-99C3 Cybernetic Medical Center',
    '12 Healthcare Boulevard, Bangalore, Karnataka',
    'MEP Infrastructure Coordination Drawing (1:50)',
    'MEP',
    '18500',
    'COMPLETED',
    'act-08e9-final',
    draughtsmanUid,
    'Staging Draughtsman Primary',
    null,
    '2026-10-24 04:00:00',
    '2026-10-24 04:10:00',
    '2026-10-24 05:32:30',
    '2026-10-24 04:20:00',
    null,
    null,
    68000.0,
    0,
    null,
    'ad961f69-1b4f-413e-bed1-76fcbf15f92a',
    1
  );

  // Project 3: D10-R3 Municipal Permit Approval Drawing 1800 sqft (WAITING_ACCEPTANCE)
  insertProject.run(
    'PRJ-D10-R3-B5CC85FB',
    engineerUid,
    'D10-R3 Municipal Permit Approval Drawing 1800 sqft',
    '15 Temple View Road, Madurai, Tamil Nadu',
    'Municipal / Permit Package (1:200)',
    'SITE_PLAN',
    '1800',
    'WAITING_ACCEPTANCE',
    '9d5cd78e-b9a4-4958-8d41-0c11f7c7cbbe',
    draughtsmanUid,
    'Staging Draughtsman Primary',
    null,
    '2026-10-23 13:34:18',
    '2026-10-23 13:34:18',
    '2026-10-23 13:34:22',
    '2026-10-23 13:34:23',
    null,
    null,
    null,
    0,
    null,
    '1a01eabe-7e4e-4ed9-af75-f66c3d44a733',
    0
  );

  // Project 4: D10-R2 Residential Villa Structural Blueprint 3200 sqft (IN_PROGRESS)
  insertProject.run(
    'PRJ-D10-R2-6271921E',
    engineerUid,
    'D10-R2 Residential Villa Structural Blueprint 3200 sqft',
    '42 Palm Grove Enclave, Coimbatore, Tamil Nadu',
    'Structural Framing Package (1:50)',
    'STRUCTURAL',
    '3200',
    'IN_PROGRESS',
    '047e6b2a-e4f6-49dc-a076-2e15ebe04cea',
    draughtsmanUid,
    'Staging Draughtsman Primary',
    null,
    '2026-10-23 13:33:55',
    '2026-10-23 13:33:55',
    '2026-10-23 13:34:00',
    '2026-10-23 13:34:02',
    null,
    null,
    null,
    0,
    null,
    'b4372747-5aa0-46e1-bf37-fcd7503e8999',
    0
  );

  // Project 5: D10-R1 Commercial Office Floor Plan 2400 sqft (WAITING_ACCEPTANCE)
  insertProject.run(
    'PRJ-D10-R1-95101456',
    engineerUid,
    'D10-R1 Commercial Office Floor Plan 2400 sqft',
    'Plot 101, Tech Park Avenue, Chennai, Tamil Nadu',
    'Architectural Layout Package (1:100)',
    'FLOOR_PLAN',
    '2400',
    'WAITING_ACCEPTANCE',
    'fc79b81e-ea8d-44f3-94e3-36d1a6e09de8',
    draughtsmanUid,
    'Staging Draughtsman Primary',
    null,
    '2026-10-23 13:33:29',
    '2026-10-23 13:33:29',
    '2026-10-23 13:33:35',
    '2026-10-23 13:33:35',
    null,
    null,
    null,
    0,
    null,
    'daee0b2c-958b-483e-ab13-579f622c000e',
    0
  );

  // Project 6: D10-R1 Tech Park Executive Suite 4500 sqft (SUBMITTED)
  insertProject.run(
    'PRJ-D10-R1-531B92CC',
    engineerUid,
    'D10-R1 Tech Park Executive Suite 4500 sqft',
    'Plot 505, IT Corridor, OMR, Chennai, Tamil Nadu',
    'Executive Interior & Partition Plan (1:50)',
    'FLOOR_PLAN',
    '4500',
    'SUBMITTED',
    'act-531b-sub',
    null,
    null,
    null,
    '2026-10-23 13:30:00',
    '2026-10-23 13:30:00',
    null,
    null,
    null,
    null,
    null,
    0,
    null,
    null,
    0
  );

  // Project 7: D10-R2 Residential Villa Structural Blueprint 3200 sqft (WAITING_ASSIGNMENT)
  insertProject.run(
    'PRJ-D10-R2-E6FD4C09',
    engineerUid,
    'D10-R2 Residential Villa Structural Blueprint 3200 sqft',
    '88 Green Acres, Coimbatore, Tamil Nadu',
    'Foundation & Column Layout (1:50)',
    'STRUCTURAL',
    '3200',
    'WAITING_ASSIGNMENT',
    'act-e6fd-app',
    null,
    null,
    null,
    '2026-10-23 13:31:00',
    '2026-10-23 13:31:00',
    '2026-10-23 13:32:00',
    null,
    null,
    null,
    null,
    0,
    null,
    null,
    0
  );

  // Project 8: D10-R3 Municipal Permit Approval Drawing 1800 sqft (WAITING_ASSIGNMENT)
  insertProject.run(
    'PRJ-D10-R3-8D2A9DD5',
    engineerUid,
    'D10-R3 Municipal Permit Approval Drawing 1800 sqft',
    '12 Temple View Road, Madurai, Tamil Nadu',
    'Building Elevation & Section Package (1:100)',
    'ELEVATION',
    '1800',
    'WAITING_ASSIGNMENT',
    'act-8d2a-app',
    null,
    null,
    null,
    '2026-10-23 13:32:00',
    '2026-10-23 13:32:00',
    '2026-10-23 13:33:00',
    null,
    null,
    null,
    null,
    0,
    null,
    null,
    0
  );

  // Project 9: Student Practical 1 (COMPLETED)
  insertProject.run(
    'prj-student-appr-01',
    studentUid,
    'Residential Ground Floor Plan (1200 sqft)',
    'Plot 14, Lotus Enclave, Coimbatore, Tamil Nadu',
    'Floor Plan & Section A-A (1:50)',
    'FLOOR_PLAN',
    '1200',
    'COMPLETED',
    'act-stu-01-appr',
    studentUid,
    'Staging Student Primary',
    null,
    '2026-10-22 09:00:00',
    '2026-10-22 09:00:00',
    '2026-10-24 07:30:00',
    '2026-10-22 09:30:00',
    null,
    null,
    null,
    1,
    'mod-cad-101',
    'stu-asgn-01',
    0
  );

  // Project 10: Student Practical 2 (COMPLETED after revision)
  insertProject.run(
    'prj-student-rev-02',
    studentUid,
    'Multi-Story Commercial Office (Level 4)',
    '45 Innovation Way, Bangalore, Karnataka',
    'Level 4 Partition & Reflected Ceiling Plan (1:100)',
    'FLOOR_PLAN',
    '3500',
    'COMPLETED',
    'act-stu-02-appr',
    studentUid,
    'Staging Student Primary',
    null,
    '2026-10-23 10:00:00',
    '2026-10-23 10:00:00',
    '2026-10-24 08:30:00',
    '2026-10-23 10:30:00',
    null,
    null,
    null,
    1,
    'mod-cad-101',
    'stu-asgn-02',
    1
  );

  console.log('✓ Projects synchronized (10 projects: 8 commercial, 2 student practicals).');

  // 5. Assignments
  const insertAssignment = db.prepare(`
    INSERT OR REPLACE INTO assignments (
      id, project_id, draughtsman_id, status, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?)
  `);

  insertAssignment.run('affca0c2-cf1f-49a2-b7a8-ba4a61019b4e', 'c74d1b06-61f4-44e6-bb8a-79206c676c27', draughtsmanUid, 'ACCEPTED', '2026-10-24 02:15:00', '2026-10-24 02:20:00');
  insertAssignment.run('ad961f69-1b4f-413e-bed1-76fcbf15f92a', '08e9407d-d78c-4dae-928d-9db3f92a4cef', draughtsmanUid, 'ACCEPTED', '2026-10-24 04:20:00', '2026-10-24 04:25:00');
  insertAssignment.run('1a01eabe-7e4e-4ed9-af75-f66c3d44a733', 'PRJ-D10-R3-B5CC85FB', draughtsmanUid, 'PENDING', '2026-10-23 13:34:23', '2026-10-23 13:34:23');
  insertAssignment.run('b4372747-5aa0-46e1-bf37-fcd7503e8999', 'PRJ-D10-R2-6271921E', draughtsmanUid, 'ACCEPTED', '2026-10-23 13:34:02', '2026-10-23 13:34:05');
  insertAssignment.run('daee0b2c-958b-483e-ab13-579f622c000e', 'PRJ-D10-R1-95101456', draughtsmanUid, 'PENDING', '2026-10-23 13:33:35', '2026-10-23 13:33:35');
  console.log('✓ Commercial assignments synchronized (5 assignments).');

  // Student practical assignments
  const insertStudentAssignment = db.prepare(`
    INSERT OR REPLACE INTO student_assignments (
      id, student_id, assignment_type, project_id, status, created_at
    ) VALUES (?, ?, ?, ?, ?, ?)
  `);

  insertStudentAssignment.run('stu-asgn-01', studentUid, 'PRACTICAL_PROJECT', 'prj-student-appr-01', 'COMPLETED', '2026-10-22 09:30:00');
  insertStudentAssignment.run('stu-asgn-02', studentUid, 'PRACTICAL_PROJECT', 'prj-student-rev-02', 'COMPLETED', '2026-10-23 10:30:00');
  console.log('✓ Student assignments synchronized (2 assignments).');

  // 6. Files & Drawing Versions
  const insertFile = db.prepare(`
    INSERT OR REPLACE INTO files (
      id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status, created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  const insertVersion = db.prepare(`
    INSERT OR REPLACE INTO drawing_versions (
      id, project_id, file_id, version_number, uploaded_by, correction_id, created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?)
  `);

  // Commercial Hub files & versions
  insertFile.run('v1-file-1792812495227', 'c74d1b06-61f4-44e6-bb8a-79206c676c27', draughtsmanUid, 'commercial_hub_v1.dwg', 'commercial_hub_v1.dwg', 'drawings/c74d1b06-61f4-44e6-bb8a-79206c676c27/v1/commercial_hub_v1.dwg', 'application/acad', 2458920, 'DRAWING_VERSION', 'UPLOADED', '2026-10-24 02:45:00');
  insertVersion.run('v1-ver-c74d1b06', 'c74d1b06-61f4-44e6-bb8a-79206c676c27', 'v1-file-1792812495227', 1, draughtsmanUid, null, '2026-10-24 02:45:00');

  insertFile.run('v2-file-1792812541816', 'c74d1b06-61f4-44e6-bb8a-79206c676c27', draughtsmanUid, 'commercial_hub_v2.dwg', 'commercial_hub_v2.dwg', 'drawings/c74d1b06-61f4-44e6-bb8a-79206c676c27/v2/commercial_hub_v2.dwg', 'application/acad', 2461040, 'DRAWING_VERSION', 'UPLOADED', '2026-10-24 03:15:00');
  insertVersion.run('v2-ver-c74d1b06', 'c74d1b06-61f4-44e6-bb8a-79206c676c27', 'v2-file-1792812541816', 2, draughtsmanUid, 'corr-c74d1b06-r1', '2026-10-24 03:15:00');

  // Cybernetic Medical Center files & versions
  insertFile.run('v1-dwg-1792819951005', '08e9407d-d78c-4dae-928d-9db3f92a4cef', draughtsmanUid, 'cybernetic_center_v1.dwg', 'cybernetic_center_v1.dwg', 'drawings/08e9407d-d78c-4dae-928d-9db3f92a4cef/v1/cybernetic_center_v1.dwg', 'application/acad', 3145728, 'DRAWING_VERSION', 'UPLOADED', '2026-10-24 04:45:00');
  insertVersion.run('v1-ver-08e9407d', '08e9407d-d78c-4dae-928d-9db3f92a4cef', 'v1-dwg-1792819951005', 1, draughtsmanUid, null, '2026-10-24 04:45:00');

  insertFile.run('v2-dwg-1792819958372', '08e9407d-d78c-4dae-928d-9db3f92a4cef', draughtsmanUid, 'cybernetic_center_v2.dwg', 'cybernetic_center_v2.dwg', 'drawings/08e9407d-d78c-4dae-928d-9db3f92a4cef/v2/cybernetic_center_v2.dwg', 'application/acad', 3150000, 'DRAWING_VERSION', 'UPLOADED', '2026-10-24 05:15:00');
  insertVersion.run('v2-ver-08e9407d', '08e9407d-d78c-4dae-928d-9db3f92a4cef', 'v2-dwg-1792819958372', 2, draughtsmanUid, 'corr-08e9407d-r1', '2026-10-24 05:15:00');

  // Student practical files & versions
  insertFile.run('file-stu-dwg-01', 'prj-student-appr-01', studentUid, 'res_ground_floor_v1.dwg', 'res_ground_floor_v1.dwg', 'student/drawings/prj-student-appr-01/res_ground_floor_v1.dwg', 'application/acad', 1850400, 'STUDENT_PRACTICAL', 'UPLOADED', '2026-10-23 15:00:00');
  insertVersion.run('ver-stu-01', 'prj-student-appr-01', 'file-stu-dwg-01', 1, studentUid, null, '2026-10-23 15:00:00');

  insertFile.run('file-stu-dwg-02-v1', 'prj-student-rev-02', studentUid, 'comm_level4_v1.dwg', 'comm_level4_v1.dwg', 'student/drawings/prj-student-rev-02/comm_level4_v1.dwg', 'application/acad', 2140000, 'STUDENT_PRACTICAL', 'UPLOADED', '2026-10-23 16:00:00');
  insertVersion.run('ver-stu-02-v1', 'prj-student-rev-02', 'file-stu-dwg-02-v1', 1, studentUid, null, '2026-10-23 16:00:00');

  insertFile.run('file-stu-dwg-02-v2', 'prj-student-rev-02', studentUid, 'comm_level4_v2.dwg', 'comm_level4_v2.dwg', 'student/drawings/prj-student-rev-02/comm_level4_v2.dwg', 'application/acad', 2145000, 'STUDENT_PRACTICAL', 'UPLOADED', '2026-10-24 08:00:00');
  insertVersion.run('ver-stu-02-v2', 'prj-student-rev-02', 'file-stu-dwg-02-v2', 2, studentUid, 'corr-stu-02', '2026-10-24 08:00:00');

  console.log('✓ Files (6) and drawing versions (6) synchronized.');

  // 7. Corrections
  const insertCorrection = db.prepare(`
    INSERT OR REPLACE INTO corrections (
      id, project_id, requested_by, target_version_id, round_number, description, status, created_at, resolved_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  insertCorrection.run(
    'corr-c74d1b06-r1',
    'c74d1b06-61f4-44e6-bb8a-79206c676c27',
    engineerUid,
    'v1-ver-c74d1b06',
    1,
    'PIN[0.4200,0.5800]: Relocate shear wall S-3 by 200mm to align with revised structural column axis',
    'RESOLVED',
    '2026-10-24 03:00:00',
    '2026-10-24 03:15:00'
  );

  insertCorrection.run(
    'corr-08e9407d-r1',
    '08e9407d-d78c-4dae-928d-9db3f92a4cef',
    engineerUid,
    'v1-ver-08e9407d',
    1,
    'PIN[0.4200,0.5800]: Relocate MRI shielding conduit 500mm east of structural grid C to avoid interference with cryogenic cooling lines.',
    'RESOLVED',
    '2026-10-24 05:00:00',
    '2026-10-24 05:15:00'
  );

  insertCorrection.run(
    'corr-stu-02',
    'prj-student-rev-02',
    adminUid,
    'ver-stu-02-v1',
    1,
    'Adjust floor-to-floor height on Level 4 to 3600mm and adjust fire exit stair enclosure width to 1500mm minimum.',
    'RESOLVED',
    '2026-10-23 17:00:00',
    '2026-10-24 08:00:00'
  );
  console.log('✓ Corrections synchronized (3 corrections).');

  // 8. Evaluations
  const insertEvaluation = db.prepare(`
    INSERT OR REPLACE INTO evaluations (
      id, project_id, drawing_version_id, evaluator_id, overall_result, general_feedback, criteria_json, created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `);

  insertEvaluation.run(
    'eval-stu-01',
    'prj-student-appr-01',
    'ver-stu-01',
    adminUid,
    'APPROVED',
    'Exceptional attention to wall hierarchy and dimension precision. Ready for production advancement.',
    JSON.stringify({ accuracy: 5, technical_standards: 5, layer_hygiene: 5, annotation_clarity: 5 }),
    '2026-10-24 07:30:00'
  );

  insertEvaluation.run(
    'eval-stu-02',
    'prj-student-rev-02',
    'ver-stu-02-v2',
    adminUid,
    'APPROVED',
    'All redline adjustments successfully incorporated into v2.',
    JSON.stringify({ accuracy: 4, technical_standards: 5, layer_hygiene: 4, annotation_clarity: 5 }),
    '2026-10-24 08:30:00'
  );
  console.log('✓ Student evaluations synchronized (2 evaluations).');

  // 9. Invoices & Payments (Preserved read-only statutory ledger)
  const insertInvoice = db.prepare(`
    INSERT OR REPLACE INTO invoices (
      id, project_id, invoice_number, amount, currency, status, due_date, created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `);

  const insertPayment = db.prepare(`
    INSERT OR REPLACE INTO payments (
      id, invoice_id, amount, payment_method, processed_at, recorded_by
    ) VALUES (?, ?, ?, ?, ?, ?)
  `);

  insertInvoice.run(
    'inv-c74d-01',
    'c74d1b06-61f4-44e6-bb8a-79206c676c27',
    'INV-2026-0001',
    45000.0,
    'INR',
    'PAID',
    '2026-11-01 00:00:00',
    '2026-10-24 03:30:00'
  );

  insertPayment.run(
    'pay-c74d-01',
    'inv-c74d-01',
    45000.0,
    'BANK_TRANSFER',
    '2026-10-24 04:00:00',
    adminUid
  );

  insertInvoice.run(
    'inv-08e9-01',
    '08e9407d-d78c-4dae-928d-9db3f92a4cef',
    'INV-2026-0002',
    68000.0,
    'INR',
    'PAID',
    '2026-11-01 00:00:00',
    '2026-10-24 05:40:00'
  );

  insertPayment.run(
    'pay-08e9-01',
    'inv-08e9-01',
    68000.0,
    'NEFT',
    '2026-10-24 06:00:00',
    adminUid
  );
  console.log('✓ Statutory invoices (2) and payments (2) synchronized.');

  // 10. Activity Logs
  const insertActivity = db.prepare(`
    INSERT OR REPLACE INTO activity_logs (
      id, project_id, action_type, actor_id, actor_role, details, timestamp
    ) VALUES (?, ?, ?, ?, ?, ?, ?)
  `);

  insertActivity.run('act-c74d-1', 'c74d1b06-61f4-44e6-bb8a-79206c676c27', 'PROJECT_CREATED', engineerUid, 'ENGINEER', 'Brief submitted', '2026-10-24 02:00:00');
  insertActivity.run('act-c74d-2', 'c74d1b06-61f4-44e6-bb8a-79206c676c27', 'ASSIGNMENT_ACCEPTED', draughtsmanUid, 'DRAUGHTSMAN', 'Assignment accepted', '2026-10-24 02:20:00');
  insertActivity.run('act-c74d-3', 'c74d1b06-61f4-44e6-bb8a-79206c676c27', 'VERSION_SUBMITTED', draughtsmanUid, 'DRAUGHTSMAN', 'Version 1 submitted', '2026-10-24 02:45:00');
  insertActivity.run('act-c74d-4', 'c74d1b06-61f4-44e6-bb8a-79206c676c27', 'CORRECTION_REQUESTED', engineerUid, 'ENGINEER', 'Round 1 redlines requested', '2026-10-24 03:00:00');
  insertActivity.run('act-c74d-5', 'c74d1b06-61f4-44e6-bb8a-79206c676c27', 'VERSION_SUBMITTED', draughtsmanUid, 'DRAUGHTSMAN', 'Version 2 submitted', '2026-10-24 03:15:00');
  insertActivity.run('act-c74d-final', 'c74d1b06-61f4-44e6-bb8a-79206c676c27', 'PROJECT_APPROVED', engineerUid, 'ENGINEER', 'Project approved and completed', '2026-10-24 03:27:39');

  insertActivity.run('act-08e9-1', '08e9407d-d78c-4dae-928d-9db3f92a4cef', 'PROJECT_CREATED', engineerUid, 'ENGINEER', 'Brief submitted', '2026-10-24 04:00:00');
  insertActivity.run('act-08e9-2', '08e9407d-d78c-4dae-928d-9db3f92a4cef', 'ASSIGNMENT_ACCEPTED', draughtsmanUid, 'DRAUGHTSMAN', 'Assignment accepted', '2026-10-24 04:25:00');
  insertActivity.run('act-08e9-3', '08e9407d-d78c-4dae-928d-9db3f92a4cef', 'VERSION_SUBMITTED', draughtsmanUid, 'DRAUGHTSMAN', 'Version 1 submitted', '2026-10-24 04:45:00');
  insertActivity.run('act-08e9-4', '08e9407d-d78c-4dae-928d-9db3f92a4cef', 'CORRECTION_REQUESTED', engineerUid, 'ENGINEER', 'Round 1 redlines requested', '2026-10-24 05:00:00');
  insertActivity.run('act-08e9-5', '08e9407d-d78c-4dae-928d-9db3f92a4cef', 'VERSION_SUBMITTED', draughtsmanUid, 'DRAUGHTSMAN', 'Version 2 submitted', '2026-10-24 05:15:00');
  insertActivity.run('act-08e9-final', '08e9407d-d78c-4dae-928d-9db3f92a4cef', 'PROJECT_APPROVED', engineerUid, 'ENGINEER', 'Project approved and completed', '2026-10-24 05:32:30');
  console.log('✓ Activity logs synchronized (12 audit events).');

  // 11. Notifications
  const insertNotification = db.prepare(`
    INSERT OR REPLACE INTO notifications (
      id, user_id, project_id, type, title, message, is_read, created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `);

  insertNotification.run('notif-eng-1', engineerUid, 'c74d1b06-61f4-44e6-bb8a-79206c676c27', 'PROJECT_COMPLETED', 'Drawing Approved', 'Project D14-FINAL-E8D2 Commercial Hub & Towers deliverable v2 was approved.', 1, '2026-10-24 03:28:00');
  insertNotification.run('notif-eng-2', engineerUid, '08e9407d-d78c-4dae-928d-9db3f92a4cef', 'PROJECT_COMPLETED', 'Drawing Approved', 'Project MASTER-E2E-99C3 Cybernetic Medical Center deliverable v2 was approved.', 1, '2026-10-24 05:33:00');

  insertNotification.run('notif-drg-1', draughtsmanUid, 'PRJ-D10-R3-B5CC85FB', 'NEW_ASSIGNMENT', 'New Project Assignment', 'You have been assigned to D10-R3 Municipal Permit Approval Drawing.', 0, '2026-10-23 13:35:00');
  insertNotification.run('notif-drg-2', draughtsmanUid, 'PRJ-D10-R1-95101456', 'NEW_ASSIGNMENT', 'New Project Assignment', 'You have been assigned to D10-R1 Commercial Office Floor Plan.', 0, '2026-10-23 13:36:00');

  insertNotification.run('notif-stu-1', studentUid, 'prj-student-appr-01', 'SUBMISSION_APPROVED', 'Practical Approved', 'Your submission for Residential Ground Floor Plan has been approved with 5/5 score!', 0, '2026-10-24 07:35:00');
  insertNotification.run('notif-stu-2', studentUid, null, 'CERTIFICATE_ISSUED', 'Certificate Issued', 'Congratulations! You earned the Architectural CAD Fundamentals Certificate (CRT-STU-2026-ARCH101).', 0, '2026-10-24 09:05:00');

  insertNotification.run('notif-adm-1', adminUid, 'c74d1b06-61f4-44e6-bb8a-79206c676c27', 'PROJECT_COMPLETED', 'Commercial Project Completed', 'Project D14-FINAL-E8D2 successfully finished all milestone deliverables.', 1, '2026-10-24 03:30:00');
  insertNotification.run('notif-adm-2', adminUid, 'prj-student-appr-01', 'STUDENT_SUBMISSION', 'Student Practical Evaluated', 'Student Primary completed practical requirement for Module CAD-101.', 1, '2026-10-24 07:35:00');
  console.log('✓ Notifications synchronized (8 notifications across all roles).');

  db.exec('COMMIT;');
  console.log('✓ ALL AUTHORITATIVE STAGING DATA SUCCESSFULLY COMMITTED.');
} catch (err) {
  db.exec('ROLLBACK;');
  console.error('✗ ERROR during synchronization, rolled back:', err);
  process.exit(1);
}
