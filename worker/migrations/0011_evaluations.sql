-- Evaluations Table
CREATE TABLE IF NOT EXISTS evaluations (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL,
  drawing_version_id TEXT NOT NULL,
  evaluator_id TEXT NOT NULL,
  overall_result TEXT NOT NULL,
  general_feedback TEXT,
  criteria_json TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (project_id)
    REFERENCES projects(id)
    ON DELETE CASCADE,

  FOREIGN KEY (drawing_version_id)
    REFERENCES drawing_versions(id)
    ON DELETE CASCADE,

  FOREIGN KEY (evaluator_id)
    REFERENCES users(id)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_evaluations_project_id ON evaluations(project_id);
CREATE INDEX IF NOT EXISTS idx_evaluations_drawing_version_id ON evaluations(drawing_version_id);
