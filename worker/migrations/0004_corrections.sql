-- Drawing Versions Table
CREATE TABLE IF NOT EXISTS drawing_versions (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL,
  file_id TEXT NOT NULL,
  version_number INTEGER NOT NULL,
  uploaded_by TEXT NOT NULL,
  correction_id TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (file_id) REFERENCES files(id) ON DELETE CASCADE,
  FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_drawing_versions_project_id ON drawing_versions(project_id);
CREATE INDEX IF NOT EXISTS idx_drawing_versions_correction_id ON drawing_versions(correction_id);

-- Corrections Table
CREATE TABLE IF NOT EXISTS corrections (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL,
  requested_by TEXT NOT NULL,
  target_version_id TEXT NOT NULL,
  round_number INTEGER NOT NULL,
  description TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'OPEN',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  resolved_at DATETIME,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (requested_by) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (target_version_id) REFERENCES drawing_versions(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_corrections_project_id ON corrections(project_id);
CREATE INDEX IF NOT EXISTS idx_corrections_status ON corrections(status);

-- Add correction_round to projects table to track easily
ALTER TABLE projects ADD COLUMN correction_round INTEGER DEFAULT 0;
