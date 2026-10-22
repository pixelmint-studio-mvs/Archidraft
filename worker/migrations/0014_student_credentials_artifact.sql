-- Migration 0013: Student Credentials Certificate Artifact
ALTER TABLE student_credentials ADD COLUMN certificate_object_key TEXT;
