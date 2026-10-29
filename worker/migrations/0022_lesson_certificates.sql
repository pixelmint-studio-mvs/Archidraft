-- Migration 0022: Lesson Certificates Index
CREATE INDEX IF NOT EXISTS idx_student_credentials_type_ref ON student_credentials(type, reference_id);
