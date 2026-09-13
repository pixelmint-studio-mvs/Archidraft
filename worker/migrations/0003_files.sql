-- Files Table
CREATE TABLE IF NOT EXISTS files (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL,
  uploaded_by TEXT NOT NULL,
  original_name TEXT NOT NULL,
  sanitized_name TEXT NOT NULL,
  object_key TEXT NOT NULL,
  content_type TEXT NOT NULL,
  size INTEGER NOT NULL,
  category TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'REQUESTED',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_files_project_id ON files(project_id);
CREATE INDEX IF NOT EXISTS idx_files_uploaded_by ON files(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_files_category ON files(category);
