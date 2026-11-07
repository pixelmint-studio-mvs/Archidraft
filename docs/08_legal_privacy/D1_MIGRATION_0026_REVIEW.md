# ARCHI DRAFT — D1 Migration 0026 Architectural Review

**Operating Brand:** DRAUGHTSMAN STUDIO  
**Legal Proprietor:** MOHAMMED MOSIN S  
**Product:** ARCHI DRAFT  
**Engineering Phase:** Phase 2 (D1 Legal Database Foundation, Account Deletion & User Data Rights)  
**File Under Review:** `worker/migrations/0026_canonical_legal_system.sql`  
**Document Reference:** `docs/08_legal_privacy/D1_MIGRATION_0026_REVIEW.md`

---

## 1. Executive Summary

Migration `0026_canonical_legal_system.sql` was engineered to provide the definitive database schema required for the ARCHI DRAFT Legal, Privacy, and Compliance subsystem. It is strictly **additive and non-destructive**, ensuring complete backward compatibility with all prior migrations (`0001` through `0025`).

This review documents the structural design, schema definitions, indexing strategies, referential integrity rules, and safe execution guarantees verified during Phase 2.

---

## 2. Migration Schema Breakdown

### 2.1 Table: `legal_business_profile`
Stores the single authoritative source of business identity, legal ownership, and contact points.
- **Primary Key:** `id TEXT PRIMARY KEY` (Default: `'PRIMARY_BUSINESS_PROFILE'`).
- **Enforcement:** Enforces single-row singleton pattern.
- **Fields:**
  - `business_structure`: Sole Proprietorship.
  - `legal_proprietor`: Confirmed as `MOHAMMED MOSIN S`.
  - `operating_brand`: Confirmed as `DRAUGHTSMAN STUDIO`.
  - `product_name`: Confirmed as `ARCHI DRAFT`.
  - `address_status`: Marked `PENDING_VERIFICATION` (physical address pending formal business confirmation).
  - `grievance_officer_status`: Marked `PENDING_VERIFICATION` (formal appointment pending).
  - `provisional_notice`: Explicit provisional status notice.

### 2.2 Table: `account_deletion_requests`
Manages the lifecycle of user account deletion and right-to-erasure requests.
- **Foreign Key:** `user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE`.
- **Status State Machine:** `CHECK (status IN ('SUBMITTED', 'CONFIRMED', 'UNDER_REVIEW', 'APPROVED', 'PROCESSING', 'COMPLETED', 'REJECTED', 'CANCELLED'))`.
- **Grace Period Tracking:** `grace_period_expires_at TEXT` (calculates 30-day grace period).
- **Execution Tracking:** `data_erased_at TEXT`, `collaborative_assets_preserved INTEGER`, `anonymized_user_identifier TEXT`.

### 2.3 Table: `data_export_requests`
Implements personal data access and export tracking under Section 11 of DPDPA.
- **Status State Machine:** `CHECK (request_status IN ('SUBMITTED', 'PROCESSING', 'COMPLETED', 'FAILED', 'EXPIRED'))`.
- **Supported Formats:** `JSON`, `CSV`, `ZIP`.
- **Scope Control:** `FULL_PROFILE`, `CONSENTS_ONLY`, `ACTIVITY_ONLY`.
- **Download Expiry:** `download_expires_at TEXT` (strictly 7 days from generation).

### 2.4 Table: `data_correction_requests`
Implements structured personal data correction requests under Section 12 of DPDPA.
- **Target Fields:** `CHECK (field_name IN ('name', 'mobile', 'address', 'qualification'))`.
- **Status Machine:** `CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED'))`.
- **Audit Columns:** `reviewed_by TEXT`, `reviewed_at TEXT`, `review_notes TEXT`.

### 2.5 Table: `data_retention_policies`
Maintains statutory and operational data retention rules.
- **Unique Constraint:** `category TEXT NOT NULL UNIQUE`.
- **Baseline Seeds:**
  - `CERT_IN_SYSTEM_LOGS` (180 days)
  - `FINANCIAL_TRANSACTIONS` (2920 days)
  - `USER_PROFILE_DATA` (30 days)
  - `AI_CHAT_TRANSCRIPTS` (90 days)

### 2.6 Table: `guardian_consents`
Provides statutory under-18 parental consent infrastructure under Section 9 of DPDPA.
- **Foreign Key:** `user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE`.
- **Verification Status:** `CHECK (verification_status IN ('PENDING_VERIFICATION', 'VERIFIED', 'REVOKED', 'REJECTED'))`.
- **Parent Attributes:** `parent_name`, `parent_email`, `parent_phone`, `relationship`, `verification_method`, `parent_proof_document_id`.

### 2.7 Table: `cancellation_refund_requests`
Tracks milestone-based contract cancellations and refund claims.
- **Foreign Keys:**
  - `project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE`
  - `user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE`
- **Status Machine:** `CHECK (status IN ('SUBMITTED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED', 'PROCESSED'))`.
- **Financial Controls:** `requested_amount REAL NOT NULL`, `approved_amount REAL`, `currency TEXT DEFAULT 'INR'`.

---

## 3. Indexing Strategy

To guarantee rapid queries in high-volume production operations, the following indexes are created:

```sql
CREATE INDEX IF NOT EXISTS idx_account_deletion_user ON account_deletion_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_account_deletion_status ON account_deletion_requests(status);
CREATE INDEX IF NOT EXISTS idx_data_export_user ON data_export_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_data_export_status ON data_export_requests(request_status);
CREATE INDEX IF NOT EXISTS idx_data_correction_user ON data_correction_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_data_correction_status ON data_correction_requests(status);
CREATE INDEX IF NOT EXISTS idx_guardian_consents_user ON guardian_consents(user_id);
CREATE INDEX IF NOT EXISTS idx_guardian_consents_email ON guardian_consents(parent_email);
CREATE INDEX IF NOT EXISTS idx_cancellation_refund_project ON cancellation_refund_requests(project_id);
CREATE INDEX IF NOT EXISTS idx_cancellation_refund_user ON cancellation_refund_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_cancellation_refund_status ON cancellation_refund_requests(status);
```

---

## 4. Foreign Key Constraints and Collaborative Asset Safety

A critical architectural finding during pre-implementation was that existing tables (`projects`, `milestones`, `drawing_versions`, `payments`) maintain foreign key constraints against `users(id)`:
```sql
FOREIGN KEY (client_id) REFERENCES users(id)
```
If an account deletion were executed using a crude `DELETE FROM users WHERE id = ?`, the database would either:
1. Fail with `FOREIGN KEY constraint failed` (due to `ON DELETE RESTRICT`), or
2. Cascade-delete multi-party projects and drawing versions, destroying the CAD deliverables owned by other clients, engineers, or draughtsmen.

### The Tombstone Solution
Migration 0026 and Worker backend handle account deletion via **Profile Tombstoning**:
1. `account_deletion_requests` is marked `COMPLETED`.
2. The user row in `users` is modified:
   - `name = 'Deleted User'`
   - `email = 'deleted_<uid>@archidraft.local'`
   - `mobile = NULL`
   - `status = 'SUSPENDED'`
3. Private transient data (`chat_sessions`, `chat_messages`) is purged.
4. All collaborative project rows, drawings, and CAD binaries remain structurally intact, with the deleted collaborator's identity anonymized.

---

## 5. Rollback and Disaster Recovery Plan

Because Migration 0026 is purely additive, should a rollback be required during pre-production testing:
```sql
DROP INDEX IF EXISTS idx_cancellation_refund_status;
DROP INDEX IF EXISTS idx_cancellation_refund_user;
DROP INDEX IF EXISTS idx_cancellation_refund_project;
DROP INDEX IF EXISTS idx_guardian_consents_email;
DROP INDEX IF EXISTS idx_guardian_consents_user;
DROP INDEX IF EXISTS idx_data_correction_status;
DROP INDEX IF EXISTS idx_data_correction_user;
DROP INDEX IF EXISTS idx_data_export_status;
DROP INDEX IF EXISTS idx_data_export_user;
DROP INDEX IF EXISTS idx_account_deletion_status;
DROP INDEX IF EXISTS idx_account_deletion_user;

DROP TABLE IF EXISTS cancellation_refund_requests;
DROP TABLE IF EXISTS guardian_consents;
DROP TABLE IF EXISTS data_retention_policies;
DROP TABLE IF EXISTS data_correction_requests;
DROP TABLE IF EXISTS data_export_requests;
DROP TABLE IF EXISTS account_deletion_requests;
DROP TABLE IF EXISTS legal_business_profile;
```
Executing this rollback restores the database schema to the exact state of Migration 0025 without affecting any user, project, drawing, or payment data.

---

## 6. Verification Status

Migration `0026_canonical_legal_system.sql` was verified using an isolated local SQLite/D1 engine in `worker/test/canonical_legal_system_phase2.test.mjs`:
- Migration application: **PASSED (Exit code 0)**
- Table creation and constraint validation: **PASSED (100%)**
- Seed records presence: **PASSED (100%)**
- Rollback execution and re-application: **PASSED (100%)**
