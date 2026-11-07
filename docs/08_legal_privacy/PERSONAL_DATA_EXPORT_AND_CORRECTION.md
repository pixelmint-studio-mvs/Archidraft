# ARCHI DRAFT — Personal Data Export and Correction Architecture

**Operating Brand:** DRAUGHTSMAN STUDIO  
**Legal Proprietor:** MOHAMMED MOSIN S  
**Product:** ARCHI DRAFT  
**Engineering Phase:** Phase 2 (D1 Legal Database Foundation, Account Deletion & User Data Rights)  
**Document Reference:** `docs/08_legal_privacy/PERSONAL_DATA_EXPORT_AND_CORRECTION.md`  
**Statutory Framework:** Digital Personal Data Protection Act, 2023 (DPDPA §§ 11, 12); Information Technology Act, 2000 & SPDI Rules 2011

---

## 1. Executive Summary

Under Section 11 (Right to Access Information about Personal Data) and Section 12 (Right to Correction and Erasure of Personal Data) of the Digital Personal Data Protection Act, 2023 (DPDPA), Data Principals (users of ARCHI DRAFT) possess statutory rights to:
1. Obtain a summary of personal data processed by the Data Fiduciary (DRAUGHTSMAN STUDIO).
2. Obtain identities of all other Data Fiduciaries and Data Processors with whom personal data has been shared.
3. Request correction of inaccurate, misleading, or outdated personal data.
4. Request completion of incomplete personal data.
5. Request updating of existing profile records.

This document formalizes the backend architecture, database schema, data packaging format, rate limiting, and review workflows implemented in Cloudflare D1 and Cloudflare Workers for ARCHI DRAFT.

---

## 2. Personal Data Export Workflow (§ 11 DPDPA)

### 2.1 Objectives and Export Scope
When an authenticated user requests a copy of their personal data (`POST /api/legal/data-export-requests`), the platform generates a structured, machine-readable JSON archive containing all user-attributed personal data:
- **Account Identity & Profile:** User UID, legal name, email, mobile phone number, postal address, role (`client`, `engineer`, `draughtsman`, `student`), qualification, created timestamp, updated timestamp.
- **Consent History:** All historical consent events (`legal_consent_events`), document keys, versions, acceptance types, IP addresses (hashed/truncated for compliance), and user agents.
- **Active Consent State:** Current opt-in and acceptance records from `user_consent_state`.
- **Project Metadatas:** All projects initiated, assigned to, or reviewed by the user (titles, categories, budgets, states, and milestones). Note: Proprietary multi-party CAD binaries belonging to other collaborators are not exported as personal data.
- **Transactions & Invoices:** Payment transaction IDs, amounts, currencies, payment methods, and timestamps.
- **Support & AI Chat Records:** Chat sessions, message history, and support queries attributed to the user.
- **Privacy & Statutory Requests:** History of past deletion, export, correction, or consent withdrawal requests.

### 2.2 Lifecycle State Machine

```
      +---------------+
      |  SUBMITTED    | <--- User calls POST /api/legal/data-export-requests
      +-------+-------+
              |
              | (Worker processes or Admin reviews)
              v
      +---------------+
      |  PROCESSING   | <--- Data compilation & archive generation
      +-------+-------+
              |
      +-------+-------+
      |               |
      v               v
+-----------+   +-----------+
| COMPLETED |   |  FAILED   |
+-----------+   +-----------+
      |
      | (Secure time-limited download URL generated: valid for 7 days)
      v
+-----------+
|  EXPIRED  | (Archive purged from temporary cache after 7 days)
+-----------+
```

### 2.3 Rate Limiting and Anti-Abuse
- **Concurrency Limit:** A user cannot have more than **one active request** (`SUBMITTED` or `PROCESSING`) at any time. Attempting to create a duplicate returns HTTP `409 Conflict`.
- **Frequency Throttling:** Users are limited to **one completed data export per 7-day period** to prevent server compute exhaustion and unauthorized data exfiltration.
- **Download Token Expiry:** Pre-signed download tokens expire strictly after **168 hours (7 calendar days)**.

### 2.4 D1 Table Representation (`data_export_requests`)

```sql
CREATE TABLE IF NOT EXISTS data_export_requests (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  request_status TEXT NOT NULL DEFAULT 'SUBMITTED' 
    CHECK (request_status IN ('SUBMITTED', 'PROCESSING', 'COMPLETED', 'FAILED', 'EXPIRED')),
  format TEXT NOT NULL DEFAULT 'JSON' 
    CHECK (format IN ('JSON', 'CSV', 'ZIP')),
  export_scope TEXT NOT NULL DEFAULT 'FULL_PROFILE' 
    CHECK (export_scope IN ('FULL_PROFILE', 'CONSENTS_ONLY', 'ACTIVITY_ONLY')),
  download_url TEXT,
  file_size_bytes INTEGER,
  download_expires_at TEXT,
  admin_notes TEXT,
  failure_reason TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

---

## 3. Personal Data Correction Workflow (§ 12 DPDPA)

### 3.1 Statutory Obligation
A Data Principal has the right to require correction, completion, or updating of personal data that is inaccurate or incomplete. However, to maintain platform integrity, prevent identity spoofing, and preserve legal contract enforceability, profile field updates are partitioned into:
1. **Self-Service Updates:** Non-legal, non-credential fields (e.g., UI display preferences).
2. **Audited Correction Requests:** Sensitive identity fields (Legal Name, Registered Mobile Number, Primary Postal Address, Professional Qualifications).

### 3.2 Supported Correction Fields
In `worker/migrations/0026_canonical_legal_system.sql`, the `field_name` is validated with strict CHECK constraints:
- `name`: User legal full name. Requires documentary proof if changing identity.
- `mobile`: Registered mobile telephone number.
- `address`: Official billing and communication postal address.
- `qualification`: Professional architectural or draughting license/degree credential.

### 3.3 State Machine and Admin Audit

```
      +---------------+
      |   PENDING     | <--- User submits POST /api/legal/data-correction-requests
      +-------+-------+
              |
              | (Admin review via POST /api/admin/legal/data-correction-requests/:id/review)
              +-----------------------+
              |                       |
              v                       v
      +---------------+       +---------------+
      |   APPROVED    |       |   REJECTED    |
      +-------+-------+       +---------------+
              |
              | (Atomic SQL update applied to `users` table)
              v
      +---------------+
      | USER PROFILE  |
      |   UPDATED     |
      +---------------+
```

### 3.4 Automated Profile Synchronization Upon Approval
When an administrator approves a data correction request (`action = 'APPROVE'`), the Worker backend executes an atomic database transaction:
1. Updates `data_correction_requests.status = 'APPROVED'`.
2. Sets `reviewed_by` (Admin UID), `reviewed_at` (timestamp), and stores `review_notes`.
3. Synchronizes the approved `requested_value` directly into the corresponding column of the `users` table:
   ```typescript
   if (action === 'APPROVE') {
     const col = reqRecord.field_name === 'mobile' ? 'mobile' :
                 reqRecord.field_name === 'address' ? 'address' :
                 reqRecord.field_name === 'qualification' ? 'qualification' : 'name';
     await env.DB.prepare(`UPDATE users SET ${col} = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?`)
       .bind(reqRecord.requested_value, reqRecord.user_id)
       .run();
   }
   ```
4. Emits an audit event for forensic traceability.

### 3.5 D1 Table Representation (`data_correction_requests`)

```sql
CREATE TABLE IF NOT EXISTS data_correction_requests (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  field_name TEXT NOT NULL CHECK (field_name IN ('name', 'mobile', 'address', 'qualification')),
  current_value TEXT,
  requested_value TEXT NOT NULL,
  correction_reason TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
  reviewed_by TEXT,
  reviewed_at TEXT,
  review_notes TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

---

## 4. Verification and Enforcement Safeguards

| Feature | Technical Safeguard | Statutory Rule |
| :--- | :--- | :--- |
| **Authentication Enforcement** | Requests require valid Firebase Bearer JWT matching `user_id`. | DPDPA § 11 |
| **Tamper Prevention** | `current_value` is automatically populated from the live `users` table, not user-supplied. | IT Act § 43A |
| **Strict Value Validation** | `requested_value` is validated for length, syntax, and SQL injection sanitization. | DPDPA § 12 |
| **Admin Authorization** | Only users with role `ADMIN` or authorized compliance staff can approve corrections. | IT Rules 2011 |
| **Rejection Reason Logging** | Rejections must supply mandatory `review_notes` explaining why the correction was rejected. | DPDPA § 12(3) |

---

## 5. Integration Status

- **Database:** Fully provisioned in `worker/migrations/0026_canonical_legal_system.sql`.
- **API Implementation:** Fully deployed in `worker/src/legal.ts` and routed in `worker/src/index.ts`.
- **Automated Tests:** Verified via `worker/test/canonical_legal_system_phase2.test.mjs` (Tests 6 & 7 passing with 100% assertions).
- **Client Interfaces:** Flutter mobile screens and Admin Web compliance dashboard will interface with these endpoints in Phase 3 and Phase 4.

