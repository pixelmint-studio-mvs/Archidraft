-- Migration 0024: Permanent Role-Based User Identification Numbers (ENG_, DM_, ST_)
-- Concurrency-safe, independent sequential IDs for Engineers, Draughtsmen, and Students
ALTER TABLE users ADD COLUMN identification_number TEXT;
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_identification_number ON users(identification_number);

-- Sequence counter table for role prefixes to ensure atomic, sequential ID allocation
CREATE TABLE IF NOT EXISTS role_id_sequences (
  role_prefix TEXT PRIMARY KEY,
  last_seq INTEGER NOT NULL DEFAULT 0
);

INSERT OR IGNORE INTO role_id_sequences (role_prefix, last_seq) VALUES
  ('ENG', 0),
  ('DM', 0),
  ('ST', 0);

-- Backfill existing Engineer / Client users (Prefix: ENG_)
WITH existing_max AS (
  SELECT COALESCE(MAX(CAST(SUBSTR(identification_number, 5) AS INTEGER)), 0) AS max_seq
  FROM users
  WHERE identification_number LIKE 'ENG_%'
),
numbered AS (
  SELECT u.id,
         'ENG_' || PRINTF('%02d', em.max_seq + ROW_NUMBER() OVER (ORDER BY u.created_at, u.id)) AS new_id
  FROM users u
  CROSS JOIN existing_max em
  WHERE (u.role = 'ENGINEER' OR u.role = 'CLIENT')
    AND (u.identification_number IS NULL OR u.identification_number = '')
)
UPDATE users
SET identification_number = numbered.new_id
FROM numbered
WHERE users.id = numbered.id;

UPDATE role_id_sequences
SET last_seq = (
  SELECT COALESCE(MAX(CAST(SUBSTR(identification_number, 5) AS INTEGER)), 0)
  FROM users
  WHERE identification_number LIKE 'ENG_%'
)
WHERE role_prefix = 'ENG';

-- Backfill existing Draughtsman users (Prefix: DM_)
WITH existing_max AS (
  SELECT COALESCE(MAX(CAST(SUBSTR(identification_number, 4) AS INTEGER)), 0) AS max_seq
  FROM users
  WHERE identification_number LIKE 'DM_%'
),
numbered AS (
  SELECT u.id,
         'DM_' || PRINTF('%02d', em.max_seq + ROW_NUMBER() OVER (ORDER BY u.created_at, u.id)) AS new_id
  FROM users u
  CROSS JOIN existing_max em
  WHERE u.role = 'DRAUGHTSMAN'
    AND (u.identification_number IS NULL OR u.identification_number = '')
)
UPDATE users
SET identification_number = numbered.new_id
FROM numbered
WHERE users.id = numbered.id;

UPDATE role_id_sequences
SET last_seq = (
  SELECT COALESCE(MAX(CAST(SUBSTR(identification_number, 4) AS INTEGER)), 0)
  FROM users
  WHERE identification_number LIKE 'DM_%'
)
WHERE role_prefix = 'DM';

-- Backfill existing Student users (Prefix: ST_)
WITH existing_max AS (
  SELECT COALESCE(MAX(CAST(SUBSTR(identification_number, 4) AS INTEGER)), 0) AS max_seq
  FROM users
  WHERE identification_number LIKE 'ST_%'
),
numbered AS (
  SELECT u.id,
         'ST_' || PRINTF('%02d', em.max_seq + ROW_NUMBER() OVER (ORDER BY u.created_at, u.id)) AS new_id
  FROM users u
  CROSS JOIN existing_max em
  WHERE u.role = 'STUDENT'
    AND (u.identification_number IS NULL OR u.identification_number = '')
)
UPDATE users
SET identification_number = numbered.new_id
FROM numbered
WHERE users.id = numbered.id;

UPDATE role_id_sequences
SET last_seq = (
  SELECT COALESCE(MAX(CAST(SUBSTR(identification_number, 4) AS INTEGER)), 0)
  FROM users
  WHERE identification_number LIKE 'ST_%'
)
WHERE role_prefix = 'ST';

