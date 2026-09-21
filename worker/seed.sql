INSERT INTO users (id, email, name, role) VALUES ('TEST_UID_CLIENT', 'client@test.com', 'Test Client', 'CLIENT');
INSERT INTO users (id, email, name, role) VALUES ('TEST_UID_DRAUGHTSMAN', 'draughtsman@test.com', 'Test Draughtsman', 'DRAUGHTSMAN');
INSERT INTO users (id, email, name, role) VALUES ('TEST_UID_ADMIN', 'admin@test.com', 'Test Admin', 'STUDIO_ADMIN');

INSERT INTO projects (id, client_id, project_name, project_address, drawing_name, drawing_type, project_area, status, draughtsman_id, draughtsman_name, current_assignment_id) VALUES ('TEST_PROJ_1', 'TEST_UID_CLIENT', 'Villa Nova', '123 Test St', 'Ground Floor Plan', 'Architectural', '2000 sqft', 'WAITING_ACCEPTANCE', 'TEST_UID_DRAUGHTSMAN', 'Test Draughtsman', 'TEST_ASSIGN_1');

INSERT INTO assignments (id, project_id, draughtsman_id, status) VALUES ('TEST_ASSIGN_1', 'TEST_PROJ_1', 'TEST_UID_DRAUGHTSMAN', 'PENDING');

INSERT INTO users (id, email, name, role) VALUES ('TEST_UID_STUDENT', 'student@test.com', 'Test Student', 'STUDENT');
INSERT INTO training_modules (id, category, type, level, title, description) VALUES ('MOD_1', 'Architectural', 'Module', 'Beginner', 'Residential Floor Plan Basics', 'Learn the basics of residential floor plans.');
INSERT INTO training_modules (id, category, type, level, title, description) VALUES ('MOD_2', 'Structural', 'Mock Project', 'Advanced', 'Advanced Elevation Detailing', 'Detailed elevation mock project.');
