-- Migration 0008: Persistent Studio Governance Settings Table
CREATE TABLE IF NOT EXISTS studio_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_by TEXT
);
