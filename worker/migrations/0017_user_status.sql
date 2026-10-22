-- Migration 0017: User Status for Account Governance & Suspension
ALTER TABLE users ADD COLUMN status TEXT CHECK (status IN ('ACTIVE', 'SUSPENDED')) DEFAULT 'ACTIVE';
