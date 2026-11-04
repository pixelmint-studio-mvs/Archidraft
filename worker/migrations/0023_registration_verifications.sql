-- Migration 0023: Registration Verifications, Proof Storage, and Email Notification Audit Logs
PRAGMA foreign_keys = ON;

-- Add verification_status and rejection_reason to users table
ALTER TABLE users ADD COLUMN verification_status TEXT CHECK (verification_status IN ('PENDING', 'APPROVED', 'REJECTED')) DEFAULT 'APPROVED';
ALTER TABLE users ADD COLUMN rejection_reason TEXT;

-- Dedicated Registration Verifications Table
CREATE TABLE IF NOT EXISTS registration_verifications (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  role TEXT NOT NULL,
  mobile TEXT,
  document_type TEXT NOT NULL,
  file_id TEXT,
  file_name TEXT,
  file_size INTEGER,
  content_type TEXT,
  object_key TEXT,
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
  reviewed_by TEXT,
  reviewer_name TEXT,
  reviewed_at DATETIME,
  rejection_reason TEXT,
  submitted_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_reg_verif_user_id ON registration_verifications(user_id);
CREATE INDEX IF NOT EXISTS idx_reg_verif_status ON registration_verifications(status);
CREATE INDEX IF NOT EXISTS idx_reg_verif_role ON registration_verifications(role);
CREATE INDEX IF NOT EXISTS idx_reg_verif_created_at ON registration_verifications(created_at);

-- Email Logs Table for Dispatch Audit and Deduplication
CREATE TABLE IF NOT EXISTS email_logs (
  id TEXT PRIMARY KEY,
  recipient_email TEXT NOT NULL,
  recipient_name TEXT,
  subject TEXT NOT NULL,
  template_type TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'SENT',
  details TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_email_logs_recipient_template ON email_logs(recipient_email, template_type);

