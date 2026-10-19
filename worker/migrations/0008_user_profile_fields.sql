-- Migration 0008: Add remaining profile fields
ALTER TABLE users ADD COLUMN mobile TEXT;
ALTER TABLE users ADD COLUMN qualification TEXT;
ALTER TABLE users ADD COLUMN date_of_birth TEXT;
ALTER TABLE users ADD COLUMN address TEXT;
ALTER TABLE users ADD COLUMN company_name TEXT;
ALTER TABLE users ADD COLUMN updated_at DATETIME;
