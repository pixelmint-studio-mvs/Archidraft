-- Enforce case-insensitive uniqueness of user email addresses across all roles
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_lower ON users(LOWER(email));
