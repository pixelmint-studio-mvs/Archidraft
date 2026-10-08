-- Migration 0012: Student Credentials
CREATE TABLE IF NOT EXISTS student_credentials (
  id TEXT PRIMARY KEY,
  student_id TEXT NOT NULL,
  type TEXT NOT NULL,
  reference_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  issued_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_student_credentials_unique ON student_credentials(student_id, type, reference_id);
CREATE INDEX IF NOT EXISTS idx_student_credentials_student_id ON student_credentials(student_id);
