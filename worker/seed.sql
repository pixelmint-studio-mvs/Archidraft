INSERT OR REPLACE INTO users (id, email, name, role) VALUES ('TEST_UID_CLIENT', 'client@test.com', 'Test Client', 'CLIENT');
INSERT OR REPLACE INTO users (id, email, name, role) VALUES ('TEST_UID_DRAUGHTSMAN', 'draughtsman@test.com', 'Test Draughtsman', 'DRAUGHTSMAN');
INSERT OR REPLACE INTO users (id, email, name, role) VALUES ('TEST_UID_ADMIN', 'admin@test.com', 'Test Admin', 'STUDIO_ADMIN');

INSERT OR REPLACE INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, draughtsman_id, draughtsman_name, current_assignment_id) VALUES ('TEST_PROJ_1', 'TEST_UID_CLIENT', 'Villa Nova', '123 Test St', 'Ground Floor Plan', 'Architectural', '2000 sqft', 'WAITING_ACCEPTANCE', 'TEST_UID_DRAUGHTSMAN', 'Test Draughtsman', 'TEST_ASSIGN_1');

INSERT OR REPLACE INTO assignments (id, project_id, draughtsman_id, status) VALUES ('TEST_ASSIGN_1', 'TEST_PROJ_1', 'TEST_UID_DRAUGHTSMAN', 'PENDING');

-- USE EXISTING UNIFIED STUDENT
INSERT OR REPLACE INTO users (id, email, name, role) VALUES ('VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'ashrafbari277@gmail.com', 'Test Student', 'STUDENT');

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
DELETE FROM student_progress WHERE student_id = 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1';

-- STUDENT PROGRESS (Realistic mix)
-- Arch: 2 completed, 1 in-progress, 1 not started
INSERT OR REPLACE INTO student_progress (id, student_id, module_id, status, score) VALUES ('PROG_1', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'MOD_ARCH_1', 'Completed', 100);
INSERT OR REPLACE INTO student_progress (id, student_id, module_id, status, score) VALUES ('PROG_2', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'MOD_ARCH_2', 'Completed', 95);
INSERT OR REPLACE INTO student_progress (id, student_id, module_id, status, score) VALUES ('PROG_3', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'MOD_ARCH_3', 'In Progress', 50);

-- Struct: 1 completed, 1 in-progress, 1 not started
INSERT OR REPLACE INTO student_progress (id, student_id, module_id, status, score) VALUES ('PROG_4', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'MOD_STRUCT_1', 'Completed', 90);
INSERT OR REPLACE INTO student_progress (id, student_id, module_id, status, score) VALUES ('PROG_5', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'MOD_STRUCT_2', 'In Progress', 30);

-- Int: 1 in-progress, 2 not started
INSERT OR REPLACE INTO student_progress (id, student_id, module_id, status, score) VALUES ('PROG_6', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'MOD_INT_1', 'In Progress', 10);

-- App: 1 completed, 1 not started
INSERT OR REPLACE INTO student_progress (id, student_id, module_id, status, score) VALUES ('PROG_7', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'MOD_APP_1', 'Completed', 100);


-- TRAINING PROJECTS (is_training_project = 1)
INSERT OR REPLACE INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, is_training_project, training_module_id, correction_round) 
VALUES ('PROJ_TRAIN_1', 'TEST_UID_CLIENT', 'Residential Ground Floor Plan', 'Plot 12, Phase 1', 'Ground Floor Plan', 'Architectural', '1500 sqft', 'IN_PROGRESS', 1, 'MOD_ARCH_4', 1);

INSERT OR REPLACE INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, is_training_project, training_module_id, correction_round) 
VALUES ('PROJ_TRAIN_2', 'TEST_UID_CLIENT', '2BHK Working Drawing', 'Plot 45, Sector B', 'Working Drawing', 'Architectural', '1200 sqft', 'UNDER_CLIENT_REVIEW', 1, 'MOD_ARCH_3', 1);

INSERT OR REPLACE INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, is_training_project, training_module_id, correction_round) 
VALUES ('PROJ_TRAIN_3', 'TEST_UID_CLIENT', 'Small Office Interior', 'Suite 201', 'Ceiling & Lighting Plan', 'Interior', '800 sqft', 'WAITING_ACCEPTANCE', 1, 'MOD_INT_3', 0);

INSERT OR REPLACE INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, is_training_project, training_module_id, correction_round) 
VALUES ('PROJ_TRAIN_4', 'TEST_UID_CLIENT', 'Municipal Approval Drawing', 'Plot 88, Zone C', 'Approval Set', 'Approval', '2400 sqft', 'COMPLETED', 1, 'MOD_APP_2', 1);

INSERT OR REPLACE INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, is_training_project, training_module_id, correction_round) 
VALUES ('PROJ_TRAIN_5', 'TEST_UID_CLIENT', 'Foundation & Footing Layout', 'Plot 102, Industrial Estate', 'Foundation & Footing Plan', 'Structural', '3200 sqft', 'WAITING_ACCEPTANCE', 1, 'MOD_STRUCT_3', 0);


-- STUDENT ASSIGNMENTS
INSERT OR REPLACE INTO student_assignments (id, student_id, assignment_type, project_id, status) VALUES ('S_ASSIGN_1', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'MOCK_PROJECT', 'PROJ_TRAIN_1', 'IN_PROGRESS');
INSERT OR REPLACE INTO student_assignments (id, student_id, assignment_type, project_id, status) VALUES ('S_ASSIGN_2', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'MOCK_PROJECT', 'PROJ_TRAIN_2', 'IN_PROGRESS');
INSERT OR REPLACE INTO student_assignments (id, student_id, assignment_type, project_id, status) VALUES ('S_ASSIGN_3', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'MOCK_PROJECT', 'PROJ_TRAIN_3', 'PENDING');
INSERT OR REPLACE INTO student_assignments (id, student_id, assignment_type, project_id, status) VALUES ('S_ASSIGN_4', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'MOCK_PROJECT', 'PROJ_TRAIN_4', 'COMPLETED');
INSERT OR REPLACE INTO student_assignments (id, student_id, assignment_type, project_id, status) VALUES ('S_ASSIGN_5', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'MOCK_PROJECT', 'PROJ_TRAIN_5', 'PENDING');


-- DUMMY FILES (to attach to versions) - keeping it minimal just so corrections can work (since version requires a file)
INSERT OR REPLACE INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status) 
VALUES ('FILE_TRAIN_1', 'PROJ_TRAIN_1', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'v1_plan.dwg', 'v1_plan.dwg', 'train/1', 'application/acad', 1024, 'DRAWING', 'COMPLETED');

INSERT OR REPLACE INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status) 
VALUES ('FILE_TRAIN_2', 'PROJ_TRAIN_2', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'v1_working.dwg', 'v1_working.dwg', 'train/2', 'application/acad', 1024, 'DRAWING', 'COMPLETED');

INSERT OR REPLACE INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status) 
VALUES ('FILE_TRAIN_4', 'PROJ_TRAIN_4', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'v1_approval.dwg', 'v1_approval.dwg', 'train/4', 'application/acad', 1024, 'DRAWING', 'COMPLETED');


-- DRAWING VERSIONS
INSERT OR REPLACE INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by) VALUES ('VER_TRAIN_1', 'PROJ_TRAIN_1', 'FILE_TRAIN_1', 1, 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1');
INSERT OR REPLACE INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by) VALUES ('VER_TRAIN_2', 'PROJ_TRAIN_2', 'FILE_TRAIN_2', 1, 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1');
INSERT OR REPLACE INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by) VALUES ('VER_TRAIN_4', 'PROJ_TRAIN_4', 'FILE_TRAIN_4', 1, 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1');


-- CORRECTIONS
INSERT OR REPLACE INTO corrections (id, project_id, requested_by, target_version_id, round_number, description, status) 
VALUES ('CORR_1', 'PROJ_TRAIN_1', 'TEST_UID_ADMIN', 'VER_TRAIN_1', 1, 'Revise staircase dimensions and update the section reference.', 'OPEN');

INSERT OR REPLACE INTO corrections (id, project_id, requested_by, target_version_id, round_number, description, status) 
VALUES ('CORR_2', 'PROJ_TRAIN_2', 'TEST_UID_ADMIN', 'VER_TRAIN_2', 1, 'Door schedule is missing D03 and D04. Add both references.', 'IN_PROGRESS');

INSERT OR REPLACE INTO corrections (id, project_id, requested_by, target_version_id, round_number, description, status) 
VALUES ('CORR_3', 'PROJ_TRAIN_4', 'TEST_UID_ADMIN', 'VER_TRAIN_4', 1, 'Update the north arrow and drawing title block.', 'RESOLVED');

-- LESSONS for MOD_ARCH_1
INSERT OR REPLACE INTO training_lessons (id, module_id, title, content, lesson_order, estimated_duration) VALUES ('LES_1', 'MOD_ARCH_1', 'Introduction to Floor Plans', 'A floor plan is a scaled diagram of a room or building viewed from above. The floor plan may depict an entire building, one floor of a building, or a single room. It may also include measurements, furniture, appliances, or anything else necessary to the purpose of the plan.', 1, '5 mins');
INSERT OR REPLACE INTO training_lessons (id, module_id, title, content, lesson_order, estimated_duration) VALUES ('LES_2', 'MOD_ARCH_1', 'Understanding the Brief', 'Before drawing, you must understand the client brief. This includes requirements like number of bedrooms, bathrooms, and specific constraints like Vastu or local building codes.', 2, '10 mins');
INSERT OR REPLACE INTO training_lessons (id, module_id, title, content, lesson_order, estimated_duration) VALUES ('LES_3', 'MOD_ARCH_1', 'Drawing Standards', 'Use standard line weights. Walls are typically 0.5mm. Windows are 0.2mm. Use proper hatching for materials like brick, concrete, etc.', 3, '15 mins');
INSERT OR REPLACE INTO training_lessons (id, module_id, title, content, lesson_order, estimated_duration) VALUES ('LES_4', 'MOD_ARCH_1', 'Practical Application', 'Now open AutoCAD and start with the site boundaries. Then construct the outer walls, followed by interior partitions.', 4, '20 mins');

-- LESSONS for MOD_ARCH_2
INSERT OR REPLACE INTO training_lessons (id, module_id, title, content, lesson_order, estimated_duration) VALUES ('LES_7', 'MOD_ARCH_2', 'Site Analysis & Solar Orientation', 'Learn how to analyze site contours, wind direction, and solar paths to optimize building placement on residential plots.', 1, '10 mins');
INSERT OR REPLACE INTO training_lessons (id, module_id, title, content, lesson_order, estimated_duration) VALUES ('LES_8', 'MOD_ARCH_2', 'Setbacks & Zoning Bylaws', 'Understand statutory front, rear, and side setback requirements, maximum ground coverage, and floor area ratio (FAR).', 2, '15 mins');
INSERT OR REPLACE INTO training_lessons (id, module_id, title, content, lesson_order, estimated_duration) VALUES ('LES_9', 'MOD_ARCH_2', 'Access, Circulation & Plot Layout', 'Draft vehicular entry points, pedestrian walkways, parking bays, and drainage slopes conforming to local development regulations.', 3, '20 mins');

-- LESSONS for MOD_ARCH_3
INSERT OR REPLACE INTO training_lessons (id, module_id, title, content, lesson_order, estimated_duration) VALUES ('LES_5', 'MOD_ARCH_3', 'Line Weights & Layers', 'Proper layer management is essential in professional drawings. Keep annotations on separate layers from geometry.', 1, '10 mins');
INSERT OR REPLACE INTO training_lessons (id, module_id, title, content, lesson_order, estimated_duration) VALUES ('LES_6', 'MOD_ARCH_3', 'Schedules & Legends', 'Always include door and window schedules, along with a comprehensive material legend.', 2, '15 mins');

-- LESSONS for MOD_STRUCT_1
INSERT OR REPLACE INTO training_lessons (id, module_id, title, content, lesson_order, estimated_duration) VALUES ('LES_10', 'MOD_STRUCT_1', 'Understanding Column Grids', 'Grid lines define the structural skeleton. Learn standard alphanumeric labeling with numbers on horizontal axis and letters on vertical axis.', 1, '10 mins');
INSERT OR REPLACE INTO training_lessons (id, module_id, title, content, lesson_order, estimated_duration) VALUES ('LES_11', 'MOD_STRUCT_1', 'Aligning Grids with Architectural Walls', 'Coordinate structural column locations with wall intersections, plumbing shafts, and setbacks to avoid structural clashes.', 2, '15 mins');

-- LESSONS for MOD_STRUCT_2
INSERT OR REPLACE INTO training_lessons (id, module_id, title, content, lesson_order, estimated_duration) VALUES ('LES_12', 'MOD_STRUCT_2', 'Column Sizing & Placement Principles', 'Determine preliminary column sizes, orientation along the minor axis, and spacing constraints for residential spans.', 1, '15 mins');
INSERT OR REPLACE INTO training_lessons (id, module_id, title, content, lesson_order, estimated_duration) VALUES ('LES_13', 'MOD_STRUCT_2', 'Primary & Secondary Beam Layout', 'Draft primary framing beams transferring slab loads to columns and secondary beams framing floor openings and stairs.', 2, '20 mins');

-- LESSONS for MOD_INT_1
INSERT OR REPLACE INTO training_lessons (id, module_id, title, content, lesson_order, estimated_duration) VALUES ('LES_14', 'MOD_INT_1', 'Anthropometrics & Human Dimensions', 'Explore standard clearance zones, passage widths, and ergonomic dimensions required for residential interior spaces.', 1, '10 mins');
INSERT OR REPLACE INTO training_lessons (id, module_id, title, content, lesson_order, estimated_duration) VALUES ('LES_15', 'MOD_INT_1', 'Zone Division & Circulation Pathways', 'Establish active vs quiet zones and direct traffic paths between doors, windows, and primary furniture groupings.', 2, '15 mins');

-- LESSONS for MOD_INT_2
INSERT OR REPLACE INTO training_lessons (id, module_id, title, content, lesson_order, estimated_duration) VALUES ('LES_16', 'MOD_INT_2', 'Standard Furniture Blocks & Symbol Libraries', 'Utilize standard 2D CAD blocks for living, dining, and bedroom elements to ensure true-to-scale representations.', 1, '10 mins');
INSERT OR REPLACE INTO training_lessons (id, module_id, title, content, lesson_order, estimated_duration) VALUES ('LES_17', 'MOD_INT_2', 'Dimensioning Living & Kitchen Layouts', 'Draft detailed dimension strings for custom cabinetry, kitchen countertops, and required appliance clearances.', 2, '15 mins');

-- LESSONS for MOD_APP_1
INSERT OR REPLACE INTO training_lessons (id, module_id, title, content, lesson_order, estimated_duration) VALUES ('LES_18', 'MOD_APP_1', 'Overview of Municipal Building Bylaws', 'Study statutory requirements including Floor Area Ratio (FAR), permissible ground coverage, and height restrictions.', 1, '10 mins');
INSERT OR REPLACE INTO training_lessons (id, module_id, title, content, lesson_order, estimated_duration) VALUES ('LES_19', 'MOD_APP_1', 'Submission Drawing Sheet Structure', 'Format key plans, site plans, service plans, and calculation tables according to local municipal submission checklists.', 2, '15 mins');

-- LESSON PROGRESS for student
INSERT OR REPLACE INTO student_lesson_progress (id, student_id, lesson_id, status, completed_at) VALUES ('SLP_1', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'LES_1', 'COMPLETED', CURRENT_TIMESTAMP);
INSERT OR REPLACE INTO student_lesson_progress (id, student_id, lesson_id, status, completed_at) VALUES ('SLP_2', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'LES_2', 'COMPLETED', CURRENT_TIMESTAMP);
INSERT OR REPLACE INTO student_lesson_progress (id, student_id, lesson_id, status, completed_at) VALUES ('SLP_3', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'LES_3', 'COMPLETED', CURRENT_TIMESTAMP);
INSERT OR REPLACE INTO student_lesson_progress (id, student_id, lesson_id, status, completed_at) VALUES ('SLP_4', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'LES_4', 'COMPLETED', CURRENT_TIMESTAMP);

INSERT OR REPLACE INTO student_lesson_progress (id, student_id, lesson_id, status, completed_at) VALUES ('SLP_7', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'LES_7', 'COMPLETED', CURRENT_TIMESTAMP);
INSERT OR REPLACE INTO student_lesson_progress (id, student_id, lesson_id, status, completed_at) VALUES ('SLP_8', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'LES_8', 'COMPLETED', CURRENT_TIMESTAMP);
INSERT OR REPLACE INTO student_lesson_progress (id, student_id, lesson_id, status, completed_at) VALUES ('SLP_9', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'LES_9', 'COMPLETED', CURRENT_TIMESTAMP);

INSERT OR REPLACE INTO student_lesson_progress (id, student_id, lesson_id, status, completed_at) VALUES ('SLP_5', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'LES_5', 'COMPLETED', CURRENT_TIMESTAMP);

INSERT OR REPLACE INTO student_lesson_progress (id, student_id, lesson_id, status, completed_at) VALUES ('SLP_10', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'LES_10', 'COMPLETED', CURRENT_TIMESTAMP);
INSERT OR REPLACE INTO student_lesson_progress (id, student_id, lesson_id, status, completed_at) VALUES ('SLP_11', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'LES_11', 'COMPLETED', CURRENT_TIMESTAMP);

INSERT OR REPLACE INTO student_lesson_progress (id, student_id, lesson_id, status, completed_at) VALUES ('SLP_12', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'LES_12', 'COMPLETED', CURRENT_TIMESTAMP);

INSERT OR REPLACE INTO student_lesson_progress (id, student_id, lesson_id, status, completed_at) VALUES ('SLP_18', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'LES_18', 'COMPLETED', CURRENT_TIMESTAMP);
INSERT OR REPLACE INTO student_lesson_progress (id, student_id, lesson_id, status, completed_at) VALUES ('SLP_19', 'VI6KEwP4rxaEEEvX3KfQjIhOGrp1', 'LES_19', 'COMPLETED', CURRENT_TIMESTAMP);

