-- ============================================================================
-- ARCHI DRAFT — DATABASE MIGRATION 0026: CANONICAL LEGAL SYSTEM FOUNDATION
-- TARGET: Cloudflare D1 Database (archi-draft-db)
-- JURISDICTION: India (DPDP Act 2023, IT Act 2000, IT SPDI Rules 2011, CERT-In)
-- PRESERVES: All existing migrations 0001 through 0025 without modification
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. legal_business_profile
-- Canonical centralized persistence for Draughtsman Studio / Archi Draft identity
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS legal_business_profile (
  id TEXT PRIMARY KEY DEFAULT 'current',
  legal_proprietor TEXT NOT NULL,
  business_structure TEXT NOT NULL,
  operating_brand TEXT NOT NULL,
  product_name TEXT NOT NULL,
  application_website TEXT NOT NULL,
  business_website TEXT NOT NULL,
  support_email TEXT NOT NULL,
  privacy_email TEXT NOT NULL,
  grievance_email TEXT NOT NULL,
  physical_address_status TEXT NOT NULL DEFAULT 'PENDING_VERIFICATION',
  physical_address_line1 TEXT,
  physical_address_city TEXT,
  physical_address_state TEXT,
  physical_address_postal_code TEXT,
  physical_address_country TEXT DEFAULT 'India',
  grievance_officer_name TEXT DEFAULT 'PENDING_VERIFICATION',
  grievance_officer_designation TEXT DEFAULT 'PENDING_VERIFICATION',
  grievance_officer_appointment_status TEXT NOT NULL DEFAULT 'PENDING_VERIFICATION',
  grievance_officer_appointment_date TEXT,
  configuration_version TEXT NOT NULL DEFAULT '1.0.0',
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Seed authoritative baseline profile
INSERT OR REPLACE INTO legal_business_profile (
  id, legal_proprietor, business_structure, operating_brand, product_name,
  application_website, business_website, support_email, privacy_email, grievance_email,
  physical_address_status, grievance_officer_appointment_status, configuration_version
) VALUES (
  'current', 'MOHAMMED MOSIN S', 'Sole Proprietorship', 'DRAUGHTSMAN STUDIO', 'ARCHI DRAFT',
  'https://archidraft.draughtsmanstudio.com', 'https://draughtsmanstudio.com',
  'support@draughtsmanstudio.com', 'support@draughtsmanstudio.com', 'mosin@draughtsmanstudio.com',
  'PENDING_VERIFICATION', 'PENDING_VERIFICATION', '1.0.0'
);

-- ----------------------------------------------------------------------------
-- 2. account_deletion_requests
-- State-machine driven, auditable personal data erasure request ledger
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS account_deletion_requests (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  request_category TEXT NOT NULL DEFAULT 'SELF_SERVICE',
  status TEXT NOT NULL DEFAULT 'SUBMITTED',
  identity_verification_status TEXT NOT NULL DEFAULT 'VERIFIED',
  reason TEXT,
  review_notes TEXT,
  assigned_admin_id TEXT,
  resolution_status TEXT,
  submitted_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  scheduled_for DATETIME,
  processed_at DATETIME,
  completed_at DATETIME,
  cancelled_at DATETIME,
  failure_details TEXT,
  retention_hold_reason TEXT,
  systems_processed TEXT,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_del_req_user ON account_deletion_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_del_req_status ON account_deletion_requests(status);
CREATE INDEX IF NOT EXISTS idx_del_req_submitted ON account_deletion_requests(submitted_at);

-- ----------------------------------------------------------------------------
-- 3. data_export_requests
-- Personal data access and export request workflow (DPDP Act Sec 11)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS data_export_requests (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  verification_status TEXT NOT NULL DEFAULT 'VERIFIED',
  export_scope TEXT NOT NULL DEFAULT 'FULL_PERSONAL_DATA',
  status TEXT NOT NULL DEFAULT 'PENDING',
  download_r2_key TEXT,
  download_url_expires_at DATETIME,
  requested_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  completed_at DATETIME,
  failure_details TEXT,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_export_req_user ON data_export_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_export_req_status ON data_export_requests(status);

-- ----------------------------------------------------------------------------
-- 4. data_correction_requests
-- Structured personal data correction tracking (DPDP Act Sec 12)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS data_correction_requests (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  field_name TEXT NOT NULL,
  proposed_value TEXT NOT NULL,
  reason TEXT,
  status TEXT NOT NULL DEFAULT 'PENDING',
  reviewed_by TEXT,
  review_notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  resolved_at DATETIME,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_corr_req_user ON data_correction_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_corr_req_status ON data_correction_requests(status);

-- ----------------------------------------------------------------------------
-- 5. data_retention_policies
-- Configurable statutory and operational data retention rules
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS data_retention_policies (
  id TEXT PRIMARY KEY,
  data_category TEXT NOT NULL UNIQUE,
  retention_purpose TEXT NOT NULL,
  retention_duration_days INTEGER,
  retention_duration_display TEXT NOT NULL,
  retention_trigger TEXT NOT NULL,
  legal_basis TEXT NOT NULL,
  deletion_method TEXT NOT NULL,
  anonymization_method TEXT,
  policy_approval_status TEXT NOT NULL DEFAULT 'PENDING_LEGAL_REVIEW',
  last_reviewed_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Seed initial statutory and pending retention policies
INSERT OR REPLACE INTO data_retention_policies (
  id, data_category, retention_purpose, retention_duration_days, retention_duration_display,
  retention_trigger, legal_basis, deletion_method, anonymization_method, policy_approval_status
) VALUES
  ('ret-certin-logs', 'SYSTEM_SECURITY_LOGS', 'CERT-In cybersecurity directions audit logs', 180, '180 Days', 'EVENT_RECORDED', 'CERT-In Direction No. 20(3)/2022', 'AUTOMATED_PURGE', 'SHA256_HASH', 'APPROVED'),
  ('ret-tax-invoices', 'TAX_AND_INVOICE_RECORDS', 'Statutory tax accounting and invoice preservation', 2920, '8 Financial Years', 'FINANCIAL_YEAR_END', 'Income Tax Act 1961 Sec 44AA / CGST Act Sec 36', 'SECURE_DESTRUCTION', NULL, 'APPROVED'),
  ('ret-active-cad', 'ACTIVE_PROJECT_CAD_ARCHIVES', 'Collaborative CAD drawing deliverables retention', NULL, 'PENDING_LEGAL_REVIEW', 'PROJECT_COMPLETED', 'Indian Contract Act 1872 & Commercial Limitation', 'RESTRICTED_ACCESS', 'DE_IDENTIFY_COLLABORATORS', 'PENDING_LEGAL_REVIEW'),
  ('ret-pixmint-bot', 'PIXMINT_BOT_CONVERSATIONS', 'AI assistant query logs and technical chats', NULL, 'PENDING_LEGAL_REVIEW', 'SESSION_INACTIVITY', 'DPDP Act 2023 Data Minimization', 'CASCADE_HARD_DELETE', NULL, 'PENDING_LEGAL_REVIEW'),
  ('ret-inactive-users', 'INACTIVE_USER_PROFILES', 'Dormant user accounts retention and cleanup', NULL, 'PENDING_LEGAL_REVIEW', 'LAST_LOGIN_TIMESTAMP', 'DPDP Act 2023 Purpose Limitation', 'TOMBSTONE_ANONYMIZE', 'SCRUB_PII', 'PENDING_LEGAL_REVIEW'),
  ('ret-deletion-audit', 'ACCOUNT_DELETION_RECORDS', 'Audit proof of compliance with user erasure requests', 180, '180 Days', 'REQUEST_COMPLETED', 'DPDP Act 2023 Accountability', 'PURGE_AFTER_LIMITATION', NULL, 'PENDING_LEGAL_REVIEW');

-- ----------------------------------------------------------------------------
-- 6. guardian_consents
-- Under-18 Student parental/guardian consent records (DPDP Act Sec 9)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS guardian_consents (
  id TEXT PRIMARY KEY,
  student_user_id TEXT NOT NULL,
  guardian_name TEXT NOT NULL,
  guardian_email TEXT NOT NULL,
  guardian_phone TEXT,
  relationship TEXT NOT NULL,
  consent_policy_version TEXT NOT NULL,
  verification_method TEXT NOT NULL DEFAULT 'MANUAL_OFFICIAL_REVIEW',
  verification_status TEXT NOT NULL DEFAULT 'PENDING_VERIFICATION',
  verified_by TEXT,
  verified_at DATETIME,
  withdrawn_at DATETIME,
  notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (student_user_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_guard_student ON guardian_consents(student_user_id);
CREATE INDEX IF NOT EXISTS idx_guard_status ON guardian_consents(verification_status);

-- ----------------------------------------------------------------------------
-- 7. cancellation_refund_requests
-- Milestone-based project and tuition refund request workflow
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cancellation_refund_requests (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  request_type TEXT NOT NULL,
  reference_id TEXT,
  amount_requested REAL,
  amount_approved REAL,
  currency TEXT DEFAULT 'INR',
  reason TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'PENDING',
  reviewed_by TEXT,
  review_decision TEXT,
  resolution_notes TEXT,
  refund_transaction_ref TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  resolved_at DATETIME,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_refund_user ON cancellation_refund_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_refund_status ON cancellation_refund_requests(status);
