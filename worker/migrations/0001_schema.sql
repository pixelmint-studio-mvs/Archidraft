-- Users Table
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'CLIENT',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Projects Table
CREATE TABLE IF NOT EXISTS projects (
  id TEXT PRIMARY KEY,
  client_id TEXT NOT NULL,
  project_name TEXT NOT NULL,
  project_address TEXT NOT NULL,
  drawing_name TEXT NOT NULL,
  drawing_type TEXT NOT NULL,
  project_area TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'DRAFT',
  last_action_id TEXT,
  draughtsman_id TEXT,
  draughtsman_name TEXT,
  rejection_reason TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  submitted_at DATETIME,
  approved_at DATETIME,
  assigned_at DATETIME,
  rejected_at DATETIME,
  cancelled_at DATETIME,
  FOREIGN KEY (client_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_projects_status ON projects(status);
CREATE INDEX IF NOT EXISTS idx_projects_client_id ON projects(client_id);
CREATE INDEX IF NOT EXISTS idx_projects_draughtsman_id ON projects(draughtsman_id);

-- Activity Logs Table
CREATE TABLE IF NOT EXISTS activity_logs (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL,
  action_type TEXT NOT NULL,
  actor_id TEXT NOT NULL,
  actor_role TEXT NOT NULL,
  details TEXT,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_activity_logs_project_id ON activity_logs(project_id);
