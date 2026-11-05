-- ============================================================================
-- Migration 0023: Centralized Help Desk & Incident Management System
-- PixelMint Studio MVS — ArchiDraft
-- ============================================================================

-- 1. Help Desk Tickets (Core Incidents & User Reports)
CREATE TABLE IF NOT EXISTS helpdesk_tickets (
  id TEXT PRIMARY KEY,                            -- Formatted Unique ID: PM-HELP-YYYY-XXXXXX
  fingerprint TEXT,                               -- Hash of (source + category + module + normalized error message)
  title TEXT NOT NULL,
  category TEXT NOT NULL,                         -- FRONTEND, BACKEND, API, DATABASE, AUTHENTICATION, UPLOAD, STUDENT, ENGINEER, PROJECT, SYSTEM, USER_REPORT, OTHER
  severity TEXT NOT NULL DEFAULT 'MEDIUM',        -- CRITICAL, HIGH, MEDIUM, LOW
  status TEXT NOT NULL DEFAULT 'OPEN',            -- OPEN, INVESTIGATING, IN_PROGRESS, RESOLVED, CLOSED
  source TEXT NOT NULL,                           -- MAIN_APP, ADMIN_PANEL, BACKEND, EXTERNAL_SERVICE, USER_SUBMITTED
  affected_module TEXT NOT NULL,
  error_message TEXT NOT NULL,
  error_code TEXT,
  stack_trace TEXT,
  environment TEXT NOT NULL DEFAULT 'production',
  user_id TEXT,                                   -- Non-sensitive user reference
  user_email TEXT,                                -- Contact email for user-submitted reports
  browser TEXT,
  device TEXT,
  page_route TEXT,
  request_id TEXT,
  occurrence_count INTEGER DEFAULT 1,
  assigned_to TEXT,                               -- Admin user ID
  assigned_to_name TEXT,
  resolution_notes TEXT,
  resolved_at DATETIME,
  resolved_by TEXT,
  screenshot_url TEXT,
  is_user_submitted INTEGER DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  last_occurred_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_helpdesk_tickets_status ON helpdesk_tickets(status);
CREATE INDEX IF NOT EXISTS idx_helpdesk_tickets_severity ON helpdesk_tickets(severity);
CREATE INDEX IF NOT EXISTS idx_helpdesk_tickets_category ON helpdesk_tickets(category);
CREATE INDEX IF NOT EXISTS idx_helpdesk_tickets_source ON helpdesk_tickets(source);
CREATE INDEX IF NOT EXISTS idx_helpdesk_tickets_created_at ON helpdesk_tickets(created_at);
CREATE INDEX IF NOT EXISTS idx_helpdesk_tickets_fingerprint ON helpdesk_tickets(fingerprint);
CREATE INDEX IF NOT EXISTS idx_helpdesk_tickets_user_id ON helpdesk_tickets(user_id);

-- 2. Help Desk Timeline Events (Audit Trail & Recurrence History)
CREATE TABLE IF NOT EXISTS helpdesk_events (
  id TEXT PRIMARY KEY,
  ticket_id TEXT NOT NULL,
  event_type TEXT NOT NULL,                       -- CREATED, RECURRENCE, STATUS_CHANGED, ASSIGNED, SEVERITY_CHANGED, NOTE_ADDED, EMAIL_DISPATCHED, RESOLVED, REOPENED, CLOSED
  actor_id TEXT,
  actor_name TEXT,
  actor_role TEXT,
  details TEXT,
  metadata TEXT,                                  -- JSON additional context
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ticket_id) REFERENCES helpdesk_tickets(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_helpdesk_events_ticket_id ON helpdesk_events(ticket_id);
CREATE INDEX IF NOT EXISTS idx_helpdesk_events_created_at ON helpdesk_events(created_at);

-- 3. Help Desk Internal Notes & Comments
CREATE TABLE IF NOT EXISTS helpdesk_comments (
  id TEXT PRIMARY KEY,
  ticket_id TEXT NOT NULL,
  author_id TEXT NOT NULL,
  author_name TEXT NOT NULL,
  author_role TEXT NOT NULL,
  comment TEXT NOT NULL,
  is_internal INTEGER DEFAULT 1,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ticket_id) REFERENCES helpdesk_tickets(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_helpdesk_comments_ticket_id ON helpdesk_comments(ticket_id);

-- 4. Help Desk Email Notification Delivery Logs
CREATE TABLE IF NOT EXISTS helpdesk_email_logs (
  id TEXT PRIMARY KEY,
  ticket_id TEXT,
  recipient TEXT NOT NULL DEFAULT 'pixelmintstudiomvs@gmail.com',
  subject TEXT NOT NULL,
  severity TEXT NOT NULL,
  status TEXT NOT NULL,                           -- PENDING, SENT, FAILED, SUPPRESSED_DUPLICATE
  provider TEXT,                                  -- RESEND, SENDGRID, DIRECT_RELAY, SIMULATION
  error_message TEXT,
  response_body TEXT,
  retry_count INTEGER DEFAULT 0,
  sent_at DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_helpdesk_email_logs_ticket_id ON helpdesk_email_logs(ticket_id);
CREATE INDEX IF NOT EXISTS idx_helpdesk_email_logs_status ON helpdesk_email_logs(status);
CREATE INDEX IF NOT EXISTS idx_helpdesk_email_logs_created_at ON helpdesk_email_logs(created_at);

-- 5. Help Desk System Health Diagnostic Records
CREATE TABLE IF NOT EXISTS helpdesk_health_checks (
  service_name TEXT PRIMARY KEY,                  -- WORKER_API, D1_DATABASE, R2_STORAGE, AUTH_SERVICE, EMAIL_DISPATCHER
  status TEXT NOT NULL,                           -- OPERATIONAL, DEGRADED, DOWN, UNKNOWN
  response_time_ms INTEGER,
  last_checked_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  last_success_at DATETIME,
  last_failure_at DATETIME,
  failure_count INTEGER DEFAULT 0,
  error_details TEXT
);

-- 6. Help Desk Configuration Settings
CREATE TABLE IF NOT EXISTS helpdesk_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_by TEXT
);

-- Default system settings
INSERT OR IGNORE INTO helpdesk_settings (key, value) VALUES ('notification_email', 'pixelmintstudiomvs@gmail.com');
INSERT OR IGNORE INTO helpdesk_settings (key, value) VALUES ('alert_critical_enabled', 'true');
INSERT OR IGNORE INTO helpdesk_settings (key, value) VALUES ('alert_high_enabled', 'true');
INSERT OR IGNORE INTO helpdesk_settings (key, value) VALUES ('alert_medium_enabled', 'false');
INSERT OR IGNORE INTO helpdesk_settings (key, value) VALUES ('alert_low_digest_enabled', 'false');
INSERT OR IGNORE INTO helpdesk_settings (key, value) VALUES ('suppression_window_minutes', '15');
INSERT OR IGNORE INTO helpdesk_settings (key, value) VALUES ('incident_retention_days', '90');
INSERT OR IGNORE INTO helpdesk_settings (key, value) VALUES ('monitoring_enabled', 'true');
INSERT OR IGNORE INTO helpdesk_settings (key, value) VALUES ('email_provider', 'auto');

