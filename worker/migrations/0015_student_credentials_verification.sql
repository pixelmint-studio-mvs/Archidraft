-- Add verification_token to student_credentials
ALTER TABLE student_credentials ADD COLUMN verification_token TEXT;
CREATE UNIQUE INDEX idx_student_credentials_verification_token ON student_credentials(verification_token);
