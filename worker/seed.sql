INSERT OR REPLACE INTO users (id, email, name, role) VALUES ('TEST_UID_CLIENT', 'client@test.com', 'Test Client', 'CLIENT');
INSERT OR REPLACE INTO users (id, email, name, role) VALUES ('TEST_UID_DRAUGHTSMAN', 'draughtsman@test.com', 'Test Draughtsman', 'DRAUGHTSMAN');
INSERT OR REPLACE INTO users (id, email, name, role) VALUES ('TEST_UID_ADMIN', 'admin@test.com', 'Test Admin', 'STUDIO_ADMIN');

INSERT OR REPLACE INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, draughtsman_id, draughtsman_name, current_assignment_id) VALUES ('TEST_PROJ_1', 'TEST_UID_CLIENT', 'Villa Nova', '123 Test St', 'Ground Floor Plan', 'Architectural', '2000 sqft', 'WAITING_ACCEPTANCE', 'TEST_UID_DRAUGHTSMAN', 'Test Draughtsman', 'TEST_ASSIGN_1');

INSERT OR REPLACE INTO assignments (id, project_id, draughtsman_id, status) VALUES ('TEST_ASSIGN_1', 'TEST_PROJ_1', 'TEST_UID_DRAUGHTSMAN', 'PENDING');

-- USE EXISTING UNIFIED STUDENT
INSERT OR REPLACE INTO users (id, email, name, role) VALUES ('TEST_UID_STUDENT', 'student@test.com', 'Test Student', 'STUDENT');

-- TRAINING MODULES (13 modules across 4 categories)
-- ARCHITECTURAL
INSERT OR REPLACE INTO training_modules (id, category, type, level, title, description) VALUES ('MOD_ARCH_1', 'Architectural', 'Module', 'Beginner', 'Residential Floor Plan Basics', 'Learn the core principles of residential floor plans and basic space requirements.');
INSERT OR REPLACE INTO training_modules (id, category, type, level, title, description) VALUES ('MOD_ARCH_2', 'Architectural', 'Module', 'Intermediate', 'Site Planning Fundamentals', 'Understand site context, setbacks, and basic zoning requirements for residential plots.');
INSERT OR REPLACE INTO training_modules (id, category, type, level, title, description) VALUES ('MOD_ARCH_3', 'Architectural', 'Module', 'Advanced', 'Working Drawing Standards', 'Industry standards for creating complete architectural working drawings and schedules.');
INSERT OR REPLACE INTO training_modules (id, category, type, level, title, description) VALUES ('MOD_ARCH_4', 'Architectural', 'Mock Project', 'Advanced', 'Architectural Detailing', 'Apply your skills in detailing stairs, facades, and specific architectural elements.');

-- STRUCTURAL
INSERT OR REPLACE INTO training_modules (id, category, type, level, title, description) VALUES ('MOD_STRUCT_1', 'Structural', 'Module', 'Beginner', 'Structural Grid Basics', 'How to correctly place structural grids based on architectural plans.');
INSERT OR REPLACE INTO training_modules (id, category, type, level, title, description) VALUES ('MOD_STRUCT_2', 'Structural', 'Module', 'Intermediate', 'Column & Beam Layout', 'General framing principles and reading basic structural requirements.');
INSERT OR REPLACE INTO training_modules (id, category, type, level, title, description) VALUES ('MOD_STRUCT_3', 'Structural', 'Mock Project', 'Advanced', 'Foundation Drawing Basics', 'Drafting foundation layouts and footings details from engineer sketches.');

-- INTERIOR
INSERT OR REPLACE INTO training_modules (id, category, type, level, title, description) VALUES ('MOD_INT_1', 'Interior', 'Module', 'Beginner', 'Space Planning', 'Ergonomics, clearances, and optimal furniture placement strategies.');
INSERT OR REPLACE INTO training_modules (id, category, type, level, title, description) VALUES ('MOD_INT_2', 'Interior', 'Module', 'Intermediate', 'Furniture Layout', 'Drafting realistic and code-compliant furniture layouts for standard rooms.');
INSERT OR REPLACE INTO training_modules (id, category, type, level, title, description) VALUES ('MOD_INT_3', 'Interior', 'Mock Project', 'Advanced', 'Ceiling & Lighting Plan', 'Understanding RCPs, light switch routing, and ceiling details.');

-- APPROVAL
INSERT OR REPLACE INTO training_modules (id, category, type, level, title, description) VALUES ('MOD_APP_1', 'Approval', 'Module', 'Beginner', 'Building Approval Basics', 'Introduction to municipal regulations and approval drawing requirements.');
INSERT OR REPLACE INTO training_modules (id, category, type, level, title, description) VALUES ('MOD_APP_2', 'Approval', 'Mock Project', 'Advanced', 'Municipal Drawing Standards', 'Preparing a complete sheet ready for municipal submission.');

-- DELETE existing progress for student so we don't have dupes if logic fails, though replace is fine
DELETE FROM student_progress WHERE student_id = 'TEST_UID_STUDENT';

-- STUDENT PROGRESS (Realistic mix)
-- Arch: 2 completed, 1 in-progress, 1 not started
INSERT OR REPLACE INTO student_progress (id, student_id, module_id, status, score) VALUES ('PROG_1', 'TEST_UID_STUDENT', 'MOD_ARCH_1', 'Completed', 100);
INSERT OR REPLACE INTO student_progress (id, student_id, module_id, status, score) VALUES ('PROG_2', 'TEST_UID_STUDENT', 'MOD_ARCH_2', 'Completed', 95);
INSERT OR REPLACE INTO student_progress (id, student_id, module_id, status, score) VALUES ('PROG_3', 'TEST_UID_STUDENT', 'MOD_ARCH_3', 'In Progress', 50);

-- Struct: 1 completed, 1 in-progress, 1 not started
INSERT OR REPLACE INTO student_progress (id, student_id, module_id, status, score) VALUES ('PROG_4', 'TEST_UID_STUDENT', 'MOD_STRUCT_1', 'Completed', 90);
INSERT OR REPLACE INTO student_progress (id, student_id, module_id, status, score) VALUES ('PROG_5', 'TEST_UID_STUDENT', 'MOD_STRUCT_2', 'In Progress', 30);

-- Int: 1 in-progress, 2 not started
INSERT OR REPLACE INTO student_progress (id, student_id, module_id, status, score) VALUES ('PROG_6', 'TEST_UID_STUDENT', 'MOD_INT_1', 'In Progress', 10);

-- App: 1 completed, 1 not started
INSERT OR REPLACE INTO student_progress (id, student_id, module_id, status, score) VALUES ('PROG_7', 'TEST_UID_STUDENT', 'MOD_APP_1', 'Completed', 100);


-- TRAINING PROJECTS (is_training_project = 1)
INSERT OR REPLACE INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, is_training_project, training_module_id, correction_round) 
VALUES ('PROJ_TRAIN_1', 'TEST_UID_CLIENT', 'Residential Ground Floor Plan', 'Plot 12, Phase 1', 'Ground Floor Plan', 'Architectural', '1500 sqft', 'IN_PROGRESS', 1, 'MOD_ARCH_4', 1);

INSERT OR REPLACE INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, is_training_project, training_module_id, correction_round) 
VALUES ('PROJ_TRAIN_2', 'TEST_UID_CLIENT', '2BHK Working Drawing', 'Plot 45, Sector B', 'Working Drawing', 'Architectural', '1200 sqft', 'UNDER_CLIENT_REVIEW', 1, 'MOD_ARCH_3', 1);

INSERT OR REPLACE INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, is_training_project, training_module_id, correction_round) 
VALUES ('PROJ_TRAIN_3', 'TEST_UID_CLIENT', 'Small Office Interior', 'Suite 201', 'Furniture Layout', 'Interior', '800 sqft', 'WAITING_ACCEPTANCE', 1, 'MOD_INT_2', 0);

INSERT OR REPLACE INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, is_training_project, training_module_id, correction_round) 
VALUES ('PROJ_TRAIN_4', 'TEST_UID_CLIENT', 'Municipal Approval Drawing', 'Plot 88, Zone C', 'Approval Set', 'Approval', '2400 sqft', 'COMPLETED', 1, 'MOD_APP_2', 1);


-- STUDENT ASSIGNMENTS
INSERT OR REPLACE INTO student_assignments (id, student_id, assignment_type, project_id, status) VALUES ('S_ASSIGN_1', 'TEST_UID_STUDENT', 'MOCK_PROJECT', 'PROJ_TRAIN_1', 'IN_PROGRESS');
INSERT OR REPLACE INTO student_assignments (id, student_id, assignment_type, project_id, status) VALUES ('S_ASSIGN_2', 'TEST_UID_STUDENT', 'MOCK_PROJECT', 'PROJ_TRAIN_2', 'IN_PROGRESS');
INSERT OR REPLACE INTO student_assignments (id, student_id, assignment_type, project_id, status) VALUES ('S_ASSIGN_3', 'TEST_UID_STUDENT', 'MOCK_PROJECT', 'PROJ_TRAIN_3', 'PENDING');
INSERT OR REPLACE INTO student_assignments (id, student_id, assignment_type, project_id, status) VALUES ('S_ASSIGN_4', 'TEST_UID_STUDENT', 'MOCK_PROJECT', 'PROJ_TRAIN_4', 'COMPLETED');


-- DUMMY FILES (to attach to versions) - keeping it minimal just so corrections can work (since version requires a file)
INSERT OR REPLACE INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status) 
VALUES ('FILE_TRAIN_1', 'PROJ_TRAIN_1', 'TEST_UID_STUDENT', 'v1_plan.dwg', 'v1_plan.dwg', 'train/1', 'application/acad', 1024, 'DRAWING', 'READY');

INSERT OR REPLACE INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status) 
VALUES ('FILE_TRAIN_2', 'PROJ_TRAIN_2', 'TEST_UID_STUDENT', 'v1_working.dwg', 'v1_working.dwg', 'train/2', 'application/acad', 1024, 'DRAWING', 'READY');

INSERT OR REPLACE INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status) 
VALUES ('FILE_TRAIN_4', 'PROJ_TRAIN_4', 'TEST_UID_STUDENT', 'v1_approval.dwg', 'v1_approval.dwg', 'train/4', 'application/acad', 1024, 'DRAWING', 'READY');


-- DRAWING VERSIONS
INSERT OR REPLACE INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by) VALUES ('VER_TRAIN_1', 'PROJ_TRAIN_1', 'FILE_TRAIN_1', 1, 'TEST_UID_STUDENT');
INSERT OR REPLACE INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by) VALUES ('VER_TRAIN_2', 'PROJ_TRAIN_2', 'FILE_TRAIN_2', 1, 'TEST_UID_STUDENT');
INSERT OR REPLACE INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by) VALUES ('VER_TRAIN_4', 'PROJ_TRAIN_4', 'FILE_TRAIN_4', 1, 'TEST_UID_STUDENT');


-- CORRECTIONS
INSERT OR REPLACE INTO corrections (id, project_id, requested_by, target_version_id, round_number, description, status) 
VALUES ('CORR_1', 'PROJ_TRAIN_1', 'TEST_UID_ADMIN', 'VER_TRAIN_1', 1, 'Revise staircase dimensions and update the section reference.', 'OPEN');

INSERT OR REPLACE INTO corrections (id, project_id, requested_by, target_version_id, round_number, description, status) 
VALUES ('CORR_2', 'PROJ_TRAIN_2', 'TEST_UID_ADMIN', 'VER_TRAIN_2', 1, 'Door schedule is missing D03 and D04. Add both references.', 'IN_PROGRESS');

INSERT OR REPLACE INTO corrections (id, project_id, requested_by, target_version_id, round_number, description, status) 
VALUES ('CORR_3', 'PROJ_TRAIN_4', 'TEST_UID_ADMIN', 'VER_TRAIN_4', 1, 'Update the north arrow and drawing title block.', 'RESOLVED');
