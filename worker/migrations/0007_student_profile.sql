-- Migration 0007: Add student profile field
ALTER TABLE users ADD COLUMN college_name TEXT;
