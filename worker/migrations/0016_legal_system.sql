-- ============================================================================
-- ARCHI DRAFT — DATABASE MIGRATION 0016: LEGAL AND PRIVACY SYSTEM
-- TARGET: D1 Database (archi-draft-db)
-- JURISDICTION: India (IT Act 2000, IT SPDI Rules 2011, DPDP Act 2023)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table 1: legal_documents
-- Centralized repository of versioned legal policies, notices, and agreements
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS legal_documents (
  id TEXT PRIMARY KEY,
  document_type TEXT NOT NULL,
  version TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  effective_at DATETIME NOT NULL,
  published_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  published_by TEXT,
  status TEXT NOT NULL DEFAULT 'DRAFT',
  is_mandatory INTEGER NOT NULL DEFAULT 1,
  locale TEXT NOT NULL DEFAULT 'en-IN',
  change_summary TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_legal_docs_type_version_locale 
  ON legal_documents(document_type, version, locale);

CREATE INDEX IF NOT EXISTS idx_legal_docs_status_effective 
  ON legal_documents(status, effective_at);

-- Partial unique index: Enforces that exactly ONE document per (document_type, locale) can be EFFECTIVE
CREATE UNIQUE INDEX IF NOT EXISTS idx_single_effective_doc 
  ON legal_documents(document_type, locale) 
  WHERE status = 'EFFECTIVE';

-- ----------------------------------------------------------------------------
-- Table 2: legal_consent_events
-- Tamper-proof, append-only immutable audit log of affirmative legal actions
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS legal_consent_events (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  document_id TEXT NOT NULL,
  document_type TEXT NOT NULL,
  document_version TEXT NOT NULL,
  action_type TEXT NOT NULL,
  consent_purpose TEXT,
  idempotency_key TEXT NOT NULL,
  ip_hash TEXT NOT NULL,
  user_agent TEXT,
  source TEXT NOT NULL DEFAULT 'WEB_APP',
  recorded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
  FOREIGN KEY (document_id) REFERENCES legal_documents(id) ON DELETE RESTRICT
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_consent_events_idempotency 
  ON legal_consent_events(idempotency_key);

CREATE INDEX IF NOT EXISTS idx_consent_events_user 
  ON legal_consent_events(user_id);

CREATE INDEX IF NOT EXISTS idx_consent_events_recorded 
  ON legal_consent_events(recorded_at);

-- ----------------------------------------------------------------------------
-- Table 3: user_consent_state
-- Materialized active consent state for fast, indexed runtime authorization
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_consent_state (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  consent_type TEXT NOT NULL,
  purpose_tag TEXT NOT NULL DEFAULT 'DEFAULT',
  current_status TEXT NOT NULL,
  accepted_version TEXT NOT NULL,
  last_event_id TEXT NOT NULL,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
  FOREIGN KEY (last_event_id) REFERENCES legal_consent_events(id) ON DELETE RESTRICT
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_user_consent_state_unique 
  ON user_consent_state(user_id, consent_type, purpose_tag);

CREATE INDEX IF NOT EXISTS idx_user_consent_state_user 
  ON user_consent_state(user_id);

-- ----------------------------------------------------------------------------
-- Table 4: privacy_requests
-- Trackable statutory data rights, erasure, and grievance redressal tickets
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS privacy_requests (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  request_type TEXT NOT NULL,
  details TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'PENDING',
  statutory_basis TEXT NOT NULL,
  statutory_deadline DATETIME,
  operational_target_date DATETIME NOT NULL,
  resolution_notes TEXT,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  acknowledged_at DATETIME,
  resolved_at DATETIME,
  resolved_by TEXT,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_privacy_req_user 
  ON privacy_requests(user_id);

CREATE INDEX IF NOT EXISTS idx_privacy_req_status 
  ON privacy_requests(status);

CREATE INDEX IF NOT EXISTS idx_privacy_req_target 
  ON privacy_requests(operational_target_date);
