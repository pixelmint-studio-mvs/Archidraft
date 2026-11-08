-- ============================================================================
-- ARCHI DRAFT — DATABASE MIGRATION 0028: CERTIFICATE STATUS & REVOCATION
-- TARGET: Cloudflare D1 Database (archi-draft-db)
-- PURPOSE: Support certificate status lifecycle (VALID, REVOKED, PENDING)
--          and administrative revocation records
-- ============================================================================

-- Add status column (default: VALID)
ALTER TABLE student_credentials ADD COLUMN status TEXT CHECK(status IN ('VALID', 'REVOKED', 'PENDING')) DEFAULT 'VALID';

-- Add revocation timestamp
ALTER TABLE student_credentials ADD COLUMN revoked_at DATETIME DEFAULT NULL;

-- Add administrative revocation reason
ALTER TABLE student_credentials ADD COLUMN revocation_reason TEXT DEFAULT NULL;

-- Add index on status for rapid filtering
CREATE INDEX IF NOT EXISTS idx_student_credentials_status ON student_credentials(status);

