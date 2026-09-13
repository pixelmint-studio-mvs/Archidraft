-- Assignments Table
CREATE TABLE IF NOT EXISTS assignments (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL,
  draughtsman_id TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'PENDING',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_assignments_project_id ON assignments(project_id);
CREATE INDEX IF NOT EXISTS idx_assignments_draughtsman_id ON assignments(draughtsman_id);

-- Add current_assignment_id to projects if it doesn't exist
ALTER TABLE projects ADD COLUMN current_assignment_id TEXT;
