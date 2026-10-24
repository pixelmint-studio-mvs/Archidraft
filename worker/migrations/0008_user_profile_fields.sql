-- Migration 0008: Add remaining profile fields
-- Safe table reconstruction ensures compatibility across environments where 'mobile' was already present
PRAGMA foreign_keys = OFF;

DROP TABLE IF EXISTS _users_schema_helper;
CREATE TABLE _users_schema_helper (
  id TEXT PRIMARY KEY,
  mobile TEXT
);

DROP TABLE IF EXISTS users_new;
CREATE TABLE users_new (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'CLIENT',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  college_name TEXT,
  mobile TEXT,
  qualification TEXT,
  date_of_birth TEXT,
  address TEXT,
  company_name TEXT,
  updated_at DATETIME
);

INSERT INTO users_new (id, email, name, role, created_at, college_name, mobile)
SELECT id, email, name, role, created_at, college_name, mobile
FROM (SELECT * FROM users NATURAL LEFT JOIN _users_schema_helper);

DROP TABLE _users_schema_helper;
DROP TABLE users;
ALTER TABLE users_new RENAME TO users;

PRAGMA foreign_keys = ON;
