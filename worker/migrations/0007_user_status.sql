-- Migration 0007: Add status column to users table for account governance
ALTER TABLE users ADD COLUMN status TEXT NOT NULL DEFAULT 'ACTIVE';
