# ARCHI DRAFT — PHASE D ARCHITECTURE PROPOSAL & TECHNICAL SPECIFICATION
**DOCUMENT STATUS:** REVISED DESIGN SPECIFICATION (PROVISIONAL)  
**STAGE:** PHASE D — ARCHITECTURE REVIEW & FINAL CORRECTIONS COMPLETED  
**IMPLEMENTATION NOTICE:** DESIGN SPECIFICATION ONLY — NO MIGRATIONS CREATED OR APPLIED — NO APPLICATION CODE MODIFIED  
**REQUIRES EXPLICIT APPROVAL BEFORE PROCEEDING TO IMPLEMENTATION**  
**PROJECT:** Archi Draft  
**PARENT BRAND:** Draughtsman Studio (https://www.draughtsmanstudio.com)  
**BUSINESS STRUCTURE:** Sole Proprietorship / Individual Business (Proprietor details pending confirmation)  
**TARGET JURISDICTION:** India (Information Technology Act 2000, SPDI Rules 2011, DPDP Act 2023, CERT-In Directions 2022)  
**D1 DATABASE BINDING:** `DB` (Database Name: `archi-draft-db`, ID: `af8d3312-5f6e-46ce-bcc1-dfa91e484cc0`)  
**R2 STORAGE BINDING:** `STORAGE` (Bucket Name: `archi-draft-storage`)  
**DATE:** OCTOBER 2026  
**DOCUMENT VERSION:** 2.2.0-CORRECTED-PROVISIONAL  

---

## 1. PURPOSE & ARCHITECTURAL SCOPE

This document provides the revised, production-grade architectural specification for Phase D (Shared Legal Architecture, Versioning, Acceptance Records, and Privacy Workflows) of the Archi Draft platform.

This specification incorporates all verified findings from repository inspection, migration history, Wrangler configuration, and applicable Indian data protection frameworks, specifically addressing:
1. **D1 Database Binding & Local Migration Conventions:** Grounded directly in `worker/wrangler.toml` (`database_name = "archi-draft-db"`, binding `DB`) and following the established sequential migration naming convention (`0016_legal_system.sql`).
2. **Resolution of Consent-Event Retention Conflicts:** Explicitly resolving the apparent contradiction between immutable audit logging and data minimization: operational immutability guarantees zero in-place mutation or tampering, while statutory retention limits ensure personal data is not preserved indefinitely without a justified legal basis. All proposed retention durations are strictly marked as **PROVISIONAL**.
3. **Acceptance-Record Integrity & Idempotency:** Decoupling immutable action event logs from mutable active consent state, enforcing unique idempotency deduplication keys (`idempotency_key`), handling concurrent submissions gracefully, enforcing server-authoritative timestamps (`CURRENT_TIMESTAMP`), cryptographic identity extraction (`c.get('uid')`), document-version integrity checks, and atomic D1 batch transaction boundaries.
4. **Consistency Between History and Active State:** Ensuring consent-event history remains append-only, where consent withdrawal and renewed acceptance generate distinct immutable events without rewriting or mutating past records.
5. **Formal Document Lifecycle & Singularity Rule:** Defining five explicit document lifecycle states (`DRAFT`, `PUBLISHED`, `EFFECTIVE`, `SUPERSEDED`, `ARCHIVED`), enforcing the Rule of Singularity via a partial unique index, handling missing effective versions via graceful maintenance holds, and preventing simultaneous publication.
6. **Zero-Trust Server-Side Authorization:** Defining strict server-side ownership and role checks for every legal endpoint with zero trust in client-supplied identifiers or roles, keeping the external Admin UI strictly outside this workspace.
7. **Granular Request Deadlines:** Differentiating verified statutory mandates (e.g. IT SPDI Rule 5(9) 30-day grievance ceiling, CERT-In 6-hour incident reporting) from internal operational targets (e.g. 48-hour acknowledgment, 15-day access summaries) and flagging pending DPDP statutory rules for qualified Indian legal counsel.
8. **Enhanced Data Minimization:** Enforcing salted IP hashes, truncated User-Agent strings, and explicit retention limits for consent events, security logs, and tax records.
9. **Migration Recovery & Rollback Realism:** Clarifying that down-migrations (`DROP TABLE`) are destructive and restricted to clean-slate testing, while staging/production recovery must rely on unverified or disposable local snapshot strategies.
10. **Reconciled Schema & Index Counts:** Documenting the exact inventory of 4 proposed tables, 11 explicit indexes (including unique and partial unique indexes), and 4 SQLite primary key autoindexes, totaling 15 index records in `sqlite_master`.

---

## 2. DELETION, RETENTION, AND AUDIT COEXISTENCE ARCHITECTURE

### 2.1 Foreign-Key Deletion Review & The Cascade Risk
In early design sketches, child tables referencing `users(id)` commonly utilize `ON DELETE CASCADE`. In a legal and compliance system, **cascading deletion is catastrophic**:
- If an account deletion request triggers `DELETE FROM users WHERE id = ?`, an `ON DELETE CASCADE` rule will silently purge all corresponding records in `legal_consent_events`, `user_consent_state`, and `privacy_requests`.
- **Consequences of Cascade Deletion:**
  1. **Destruction of Evidentiary Audit Trail:** The platform loses historical proof that the user accepted the Terms & Conditions or acknowledged the Privacy Policy, crippling the platform's legal defense against contractual disputes under the Indian Contract Act, 1872 or claims of unauthorized processing under the DPDP Act, 2023.
  2. **Destruction of Statutory Fulfillment Proof:** The platform destroys the very ticket and timestamped resolution record proving that the user's statutory data erasure or grievance request was received and fulfilled within mandated timelines under Rule 5(9) of the IT (SPDI) Rules, 2011.
  3. **Violation of Incident Log Integrity:** Destroys forensic evidence necessary to comply with CERT-In Direction No. 20(3)/2022 (mandating log retention for 180 days).

### 2.2 Resolving the Retention Conflict: Immutability vs. Data Minimization
An apparent contradiction exists between two fundamental architectural principles:
1. **Audit Immutability:** Historical records of what terms were accepted and what notices were delivered must never be altered, backdated, or deleted to maintain legal evidentiary integrity.
2. **Data Minimization & Storage Limitation:** Data protection legislation (such as Section 8(7) of the DPDP Act 2023 and Rule 5(7) of the IT SPDI Rules 2011) prohibits data fiduciaries from preserving personal data indefinitely once the specified purpose is no longer served.

**Resolution of the Conflict:**
These two requirements are reconciled by distinguishing **Operational Immutability** from **Lifecycle Horizon**:
- **Operational Immutability (Active Lifecycle):** During the active lifecycle of an account and the subsequent dispute window, `legal_consent_events` is strictly append-only. The Cloudflare Worker API surface, application code, and standard database queries have **zero** update or delete capabilities. No user or administrator can rewrite, tamper with, or delete past events.
- **Lifecycle Horizon & Minimization (Post-Limitation):** Personal data is not kept forever. However, the exact duration of retention cannot be arbitrarily invented by software engineers. It must reflect applicable legal limitation periods (such as the default 3-year period for contract claims under the Indian Limitation Act, 1963). Therefore, any future purge or irreversible anonymization of expired audit records is an **offline compliance procedure**, not an operational application feature.
- **Provisional Status:** All proposed retention horizons (e.g. 3 years for consent records post-deletion) are strictly **PROVISIONAL / UNCONFIRMED**. They require formal review and approval by the business owner and qualified Indian legal counsel before any automated deletion routines or purge jobs are implemented.

### 2.3 Two-Phase Account Deletion, Redaction & Tombstone Lifecycle
To reconcile account deletion rights (data minimization and right to erasure) with statutory audit retention, Archi Draft adopts a **Two-Phase Pseudonymization & Redaction Architecture** using `ON DELETE RESTRICT` on all legal audit foreign keys.

```
User Requests Deletion / Admin Executes Erasure
                      │
                      ▼
   ┌──────────────────────────────────────────────┐
   │ Phase 1: Operational Redaction & Scrubbing    │
   │ - users.status = 'DELETED'                    │
   │ - users.deleted_at = CURRENT_TIMESTAMP       │
   │ - users.email = 'deleted_<uid>@redacted.local' │
   │ - users.name = 'Redacted User'               │
   │ - users.mobile/address/college/company = NULL│
   │ - Invalidate active session tokens           │
   │ - Purge R2 profile avatars & private drafts  │
   └──────────────────────────────────────────────┘
                      │
                      ▼
   ┌──────────────────────────────────────────────┐
   │ Phase 2: Audit Retention (Tombstone State)   │
   │ - users(id) preserved as bare tombstone row  │
   │ - legal_consent_events preserved intact       │
   │   (UID points to tombstone; IP hash salted)  │
   │ - privacy_requests ticket preserved intact   │
   │   (Proof of receipt & timely fulfillment)    │
   │ - Restricted access: Admin compliance audit  │
   └──────────────────────────────────────────────┘
                      │
                      ▼ (PROVISIONAL: Pending Business & Legal Sign-off)
   ┌──────────────────────────────────────────────┐
   │ Phase 3: Post-Limitation Anonymization       │
   │ - Purge/anonymize expired consent events     │
   │   (Subject to legal counsel approval)        │
   │ - Zero indefinite retention of stale PII     │
   └──────────────────────────────────────────────┘
```

### 2.4 Coexistence Matrix of Competing Legal & Operational Obligations

| Data Category | Governing Basis / Mandate | Retention Requirement (Provisional Status) | Storage State & Handling | Post-Retention Action |
| :--- | :--- | :--- | :--- | :--- |
| **Active Profile Data** (Email, Name, Mobile, College/Company, Address) | Contract Performance & Consent (DPDP Sec 4/6) | Active account lifetime only. Must be erased upon verified deletion request. | Cleartext in `users` table while active. Redacted/sanitized to NULL/placeholder on deletion. | Erased/Redacted immediately upon account deletion execution (< 30 days). |
| **Terms Acceptance History** (`legal_consent_events`) | Defense of Legal Claims (Indian Limitation Act, 1963 contract dispute window) | **PROVISIONAL:** 3 years post-account termination (requires legal counsel sign-off). | Immutable append-only event row. Contains UID, document version, server timestamp, salted IP hash, User-Agent. | Post-limitation anonymization/purge (pending counsel approval). |
| **Privacy / Grievance Requests** (`privacy_requests`) | Proof of Statutory Compliance (IT SPDI Rule 5(9), Consumer Protection Act 2019) | **PROVISIONAL:** 3 years from ticket resolution date (requires legal counsel sign-off). | Pseudonymized ticket record with creation timestamp, closure timestamp, resolution category, admin UID. | Anonymized / purged after compliance defense window. |
| **Financial & Tax Records** (Invoices, Platform Fees, TDS, GST) | Statutory Mandate (Income Tax Act 1961 Sec 44AA; CGST Act 2017 Sec 36) | **STATUTORY:** 8 years from end of relevant financial year (mandatory). | Decoupled financial ledger referencing immutable invoice ID and tax registration. Kept strictly isolated from marketing data. | Retained for full statutory 8-year period; purged thereafter. |
| **System Security & Access Logs** (Worker request logs, auth attempts) | Statutory Mandate (CERT-In Direction No. 20(3)/2022) | **STATUTORY:** Minimum 180 days within Indian jurisdiction. | Rolling Cloudflare log stream / encrypted cold storage. Contains IP, timestamp, method, path, response code. | Automatically cycled out after 180-day statutory period. |
| **Project CAD Drawings & Deliverables** | Commercial Contract / IP Agreement | **UNCONFIRMED:** Pending business owner and legal decision. | Stored in R2 with project-level access controls. Not automatically purged on designer account deletion if part of delivered client project. | Handled according to final commercial IP contract terms. |

**Data Minimization Principle:** Personal data is never retained indefinitely without a reviewed and justified legal purpose. No raw client IP addresses are persisted in application audit tables; only truncated User-Agents ($\le 128$ characters) and salted one-way SHA-256 hashes (`ip_hash`) are stored.

---

## 3. REQUEST DEADLINES & GRIEVANCE SLA ARCHITECTURE

### 3.1 Granular Mapping: Statutory Mandates vs. Operational Targets
The architecture rejects the flawed assumption that every privacy or grievance request shares an identical 30-day statutory timeline. Deadlines are mapped explicitly to verified statutory rules, operational service targets, or flagged as pending government notification:

| Request / Action Type | Applicable Legal Ground & Statutory Basis | Verified Statutory Deadline | Operational Target (Internal SLA) | Technical & Architectural Handling |
| :--- | :--- | :--- | :--- | :--- |
| **User Grievance / Discrepancy** (`GRIEVANCE`) | Information Technology (Reasonable Security Practices and Procedures and Sensitive Personal Data or Information) Rules, 2011 — **Rule 5(9)** | **30 calendar days** from date of receipt (mandatory statutory ceiling). | **Acknowledgment:** 48 business hours.<br>**Target Resolution:** 15 business days. | Ticket generated with `statutory_deadline = created_at + 30 days`. Escalation alert triggered in admin worker if unresolved at Day 20. |
| **Cybersecurity Incident / Breach** (`SECURITY_INCIDENT`) | CERT-In Direction No. 20(3)/2022 under Section 70B(6) of IT Act, 2000 | **6 hours** from noticing or being informed of incident. | **Containment:** 2 hours.<br>**Reporting to CERT-In:** Within 6 hours. | Dedicated incident escalation path. Immediate notification dispatched to Grievance / Security Officer. Automated log preservation. |
| **Right to Access / Summary** (`DATA_ACCESS`) | Digital Personal Data Protection Act, 2023 — **Section 11(1)** | **Pending Rule Notification** (No fixed calendar day deadline in parent Act; subject to rules to be prescribed by Central Government). | **Acknowledgment:** 48 hours.<br>**Target Fulfillment:** 15 business days. | System generates automated export package (JSON archive of profile, projects, consent events). `statutory_deadline` left NULL until DPDP Rules are notified. |
| **Right to Correction / Updating** (`DATA_CORRECTION`) | Digital Personal Data Protection Act, 2023 — **Section 12(1)** | **Pending Rule Notification** (Subject to Central Government rules). | **Target Fulfillment:** 15 business days. | Self-service profile editing where feasible; manual verification workflow for identity-critical credentials. |
| **Right to Erasure / Deletion** (`DATA_ERASURE` / `ACCOUNT_DELETION`) | Digital Personal Data Protection Act, 2023 — **Section 12(2)** & IT SPDI Rules 2011 **Rule 5(7)** | **Pending Rule Notification** under DPDP Act; SPDI Rule 5(7) prohibits retention beyond required purpose. | **Immediate:** Session revocation.<br>**Operational Target:** 30 calendar days for full data scrubbing. | Two-phase redaction: immediate soft-disable, 30-day grace period for reconciliation, hard redaction of profile. |
| **Withdrawal of Optional Consent** (`CONSENT_WITHDRAWAL`) | Digital Personal Data Protection Act, 2023 — **Section 6(4)** | Withdrawal must be as easy as giving consent; processing must stop within reasonable time. | **Runtime State:** Immediate (< 1 hour propagation).<br>**Confirmation Notice:** 48 hours. | Immediate atomic update in `user_consent_state`; downstream background sync stops marketing/telemetry immediately. |

### 3.2 Unresolved Legal Interpretations & Contact Disclaimers
> [!IMPORTANT]
> **LEGAL COUNSEL REVIEW REQUIRED:**
> 1. **DPDP Statutory Rules:** The precise statutory time limit (e.g. 7, 15, or 30 days) for Data Principal access, correction, and erasure requests remains pending the notification of DPDP Rules by the Ministry of Electronics and Information Technology (MeitY). The schema models `statutory_deadline` as nullable, populated with verified statutory deadlines where known (e.g. SPDI 30 days) and leaving DPDP-specific deadlines to be updated upon official rule gazetting.
> 2. **Intermediary Guidelines (Rule 3(2)):** Whether Archi Draft operates purely as a B2B SaaS workflow tool or qualifies as an intermediary under IT Rules 2021 (requiring 24-hr acknowledgement and 15-day grievance redressal) requires formal determination by qualified Indian legal counsel.
> 3. **Unconfirmed Contact Address:** Any reference to `grievance@archidraft.com` or support telephone numbers in drafts or documentation is strictly an **UNCONFIRMED PLACEHOLDER**. No such email address or operational channel is currently active. The official Grievance Officer and verified contact channels must be formally appointed by the business owner before public launch.

---

## 4. ACCEPTANCE-RECORD INTEGRITY, IDEMPOTENCY & TAMPER-PROOF DESIGN

### 4.1 Separation of Concerns: Event Ledger vs. Materialized State
A major flaw in naive consent systems is mutating a single row (e.g. updating `withdrawn_at` in place). In Archi Draft, mutable current state and immutable audit history are strictly decoupled into two dedicated tables:

1. **`legal_consent_events` (Append-Only Event Ledger):**
   - Strictly immutable: Application code and API routes have zero `UPDATE` or `DELETE` permissions on this table.
   - Every user action (`TERMS_ACCEPTED`, `PRIVACY_NOTICE_ACKNOWLEDGED`, `OPTIONAL_CONSENT_GRANTED`, `OPTIONAL_CONSENT_WITHDRAWN`) creates a discrete, permanent event record.
2. **`user_consent_state` (Current Materialized View / Table):**
   - Stores the active state for fast, indexed queries by router guards and UI screens.
   - Updated atomically alongside the append-only event inside a D1 database batch transaction.

### 4.2 Deduplication, Idempotency & Concurrency Handling
- **Idempotency Key Construction:** Every consent submission requires an `idempotency_key`, constructed as:
  $$\text{idempotency\_key} = \text{SHA-256}(\text{user\_id} \parallel ':' \parallel \text{document\_id} \parallel ':' \parallel \text{action\_type} \parallel ':' \parallel \text{purpose} \parallel ':' \parallel \text{date})$$
  or supplied directly by the client as a unique UUID v4.
- **Concurrent Submissions:** 
  If a user double-clicks an acceptance button or network retries submit identical requests simultaneously:
  1. The first request successfully inserts the record into `legal_consent_events` and upserts `user_consent_state`.
  2. The concurrent duplicate request violates the `UNIQUE(idempotency_key)` constraint.
  3. The Worker endpoint intercepts `SQLITE_CONSTRAINT_UNIQUE`, executes a lookup for the existing event by `idempotency_key`, and returns HTTP `200 OK` with `{ status: 'ALREADY_RECORDED', event_id: existing.id }`, ensuring clean idempotency without creating duplicate rows or crashing the client.
- **Server-Authoritative Timestamps:** Timestamps (`recorded_at`, `created_at`) are generated strictly by SQLite/D1 engine using `CURRENT_TIMESTAMP`. Client-supplied device clocks are discarded.
- **Cryptographic Authenticated Identity:** The user ID is extracted exclusively from the verified Firebase Auth JWT token via `c.get('uid')` in Worker middleware. No client-supplied UID in headers, query parameters, or request payloads is ever trusted.
- **Document-Version Validation:** Before recording an acceptance event, the Worker validates that the specified `document_id` and `document_version` exist in `legal_documents` with status `EFFECTIVE` (or `PUBLISHED` during advance review) and match the active version.
- **Atomic Transaction Boundaries:** The append to `legal_consent_events` and the upsert to `user_consent_state` are executed using Cloudflare D1 batching (`db.batch([insertEventStmt, upsertStateStmt])`), ensuring all-or-nothing execution.
- **Privacy-Preserving Audit Hashing:** To prove the network origin without storing cleartext IP addresses, the Worker hashes the Cloudflare connecting IP (`c.req.header('cf-connecting-ip')`) combined with a monthly rotating server salt:
  $$\text{ip\_hash} = \text{SHA-256}(\text{Client IP} \parallel \text{Monthly Salt})$$

### 4.3 Consistency Between Event History and Active State
When a user withdraws consent or re-accepts terms:
- **Withdrawal Action:** Creates a new row in `legal_consent_events` with `action_type = 'OPTIONAL_CONSENT_WITHDRAWN'`, and atomically updates `user_consent_state` with `current_status = 'WITHDRAWN'`.
- **Renewed Acceptance Action:** Creates a new row in `legal_consent_events` with `action_type = 'OPTIONAL_CONSENT_GRANTED'`, and atomically updates `user_consent_state` with `current_status = 'GRANTED'`.
- **Integrity Guarantee:** Prior historical events are **never modified or deleted**. An audit log query chronologically demonstrates the exact lifecycle of consent over time, while client route gating checks only the single current state record in $O(1)$ time.

---

## 5. SEPARATE LEGAL ACTIONS & NON-BUNDLING ARCHITECTURE

Under Section 6(1) of the Digital Personal Data Protection Act, 2023, consent must be free, specific, informed, unconditional, and unambiguous. Mandatory terms acceptance must never be bundled with optional data processing.

```
┌────────────────────────────────────────────────────────────────────────┐
│                          LEGAL ACTION TAXONOMY                         │
├─────────────────────────┬──────────────────────────┬───────────────────┤
│ Contractual Terms       │ Privacy Notice           │ Optional Consents │
│ Acceptance              │ Acknowledgment           │ (Granular & Free) │
├─────────────────────────┼──────────────────────────┼───────────────────┤
│ Document:               │ Document:                │ Purpose Tags:     │
│ TERMS_AND_CONDITIONS    │ PRIVACY_POLICY           │ - MARKETING_COMMS │
│                         │                          │ - STUDENT_SHOWCASE│
│ Legal Basis:            │ Legal Basis:             │ - AI_ASSISTED_CAD │
│ Contract Performance    │ Statutory Notice         │                   │
│ (Indian Contract Act)   │ Delivery (DPDP Sec 5)    │ Legal Basis:      │
│                         │                          │ Freely Given      │
│ Action Type:            │ Action Type:             │ Consent           │
│ TERMS_ACCEPTED          │ PRIVACY_NOTICE_          │                   │
│                         │ ACKNOWLEDGED             │ Action Types:     │
│ Nature:                 │                          │ OPTIONAL_CONSENT_ │
│ Mandatory to use the    │ Nature:                  │ GRANTED           │
│ platform services.      │ Informational delivery;  │ OPTIONAL_CONSENT_ │
│ Re-acceptance required  │ confirmed read. Does not │ WITHDRAWN         │
│ on major updates.       │ form a bilateral contract│                   │
│                         │                          │ Nature:           │
│ Access Gate:            │ Access Gate:             │ Completely        │
│ BLOCKS dashboard if not │ Informational review on  │ optional. Default │
│ accepted.               │ onboarding; unbundled.   │ OFF. Zero access  │
│                         │                          │ penalty.          │
└─────────────────────────┴──────────────────────────┴───────────────────┘
```

### 5.1 Contractual Terms Acceptance
- **Model:** `action_type = 'TERMS_ACCEPTED'`.
- **Purpose:** Forms the binding contract between the Sole Proprietorship and the user governing platform conduct, fee structures, dispute resolution, and acceptable use.
- **Blocking Nature:** Acceptance of current `EFFECTIVE` version is mandatory to provision an account or access functional dashboards.

### 5.2 Privacy Notice Acknowledgment
- **Model:** `action_type = 'PRIVACY_NOTICE_ACKNOWLEDGED'`.
- **Purpose:** Documents that the statutory privacy notice was delivered and displayed to the user prior to or at the time of data collection, fulfilling Section 5 of the DPDP Act.
- **Non-Contractual:** The notice is informational. Users acknowledge having received and reviewed the notice; they do not "contractually agree" to privacy as if it were a service agreement.

### 5.3 Granular Purpose-Specific Optional Consents
- **Model:** `action_type = 'OPTIONAL_CONSENT_GRANTED'` / `'OPTIONAL_CONSENT_WITHDRAWN'` with explicit `consent_purpose` strings:
  1. `MARKETING_COMMUNICATIONS`: Promotional updates, platform newsletters, event invitations.
  2. `STUDENT_DIRECTORY_SHOWCASE`: Inclusion of student profile and verified portfolio in publicly discoverable hiring directories.
  3. `AI_ASSISTED_DRAFTING`: Processing drawings through optional third-party or local AI analysis/annotation engines.
  4. `TELEMETRY_ANALYTICS`: Enhanced behavioral analytics beyond essential security logs.
- **Zero-Bundling Rule:** Every optional consent is displayed as a distinct toggle, defaulted to **OFF** (opt-in only), and can be toggled on or off at any time from Settings without affecting core platform functionality.

---

## 6. DOCUMENT LIFECYCLE & ADMINISTRATIVE GOVERNANCE

### 6.1 The Five Document States & Singularity Rule
To prevent unapproved drafts from reaching end-users or leaving the platform without an active legal standard, legal documents pass through five strictly enforced states:

```
    ┌──────────┐
    │  DRAFT   │ ──(Admin Draft Edit / Internal Legal Review)
    └────┬─────┘
         │ (Admin Publishes Document with Effective Date)
         ▼
    ┌──────────┐
    │PUBLISHED │ ──(Approved release; waiting for effective_at timestamp)
    └────┬─────┘
         │ (effective_at reached AND activated)
         ▼
    ┌──────────┐
    │EFFECTIVE │ ◄── Exactly ONE active version per (document_type, locale)
    └────┬─────┘     Returned by public endpoints to end-users
         │ (New version becomes EFFECTIVE)
         ▼
    ┌──────────┐
    │SUPERSEDED│ ──(Historical active record; read-only audit archive)
    └────┬─────┘
         │ (Policy decommissioned or permanently deprecated)
         ▼
    ┌──────────┐
    │ ARCHIVED │ ──(Deep archival storage for compliance defense)
    └──────────┘
```

1. **`DRAFT`:** Document is currently being drafted or revised by administrators/legal counsel. Accessible strictly to authorized Admins via authenticated admin endpoints.
2. **`PUBLISHED`:** Document has been approved by the business owner/counsel and published with an `effective_at` timestamp (which may be immediate or set in the future to provide advance notice).
3. **`EFFECTIVE`:** The currently active, legally binding version governing user interactions. Exactly one version per `(document_type, locale)` may be `EFFECTIVE` at any point in time.
4. **`SUPERSEDED`:** An older version that was previously `EFFECTIVE` but has been replaced by a newer version. Kept read-only for legal dispute verification.
5. **`ARCHIVED`:** Decommissioned policy or deprecated document type, retained strictly for compliance history.

### 6.2 Database Prevention of Simultaneous Publication
To make it physically impossible for two versions of the same document type to be `EFFECTIVE` at the same time in SQLite/D1, the schema defines a **partial unique index**:
```sql
CREATE UNIQUE INDEX IF NOT EXISTS idx_single_effective_doc 
  ON legal_documents(document_type, locale) 
  WHERE status = 'EFFECTIVE';
```
Any attempt to insert or update a second document of the same type and locale with `status = 'EFFECTIVE'` without first transitioning the prior version to `SUPERSEDED` will fail immediately with a database constraint violation.

### 6.3 Safe Behavior When a Legal Document Is Unavailable (`NO_EFFECTIVE_VERSION`)
If no `EFFECTIVE` version of a document type currently exists (e.g. system cold start or newly added policy):
1. **Mandatory Contractual Terms (`is_mandatory = 1`, e.g. `TERMS_AND_CONDITIONS`):**
   - **No Silent Bypass:** The platform must **NEVER** silently bypass terms acceptance and allow uncontracted users into the application.
   - **No Fatal Crash:** The platform must **NEVER** throw an unhandled exception or crash the Flutter client.
   - **Safe Behavior:** The endpoint returns HTTP 404 with:
     ```json
     { "document": null, "status": "NO_EFFECTIVE_VERSION", "access": "SUSPENDED_MAINTENANCE" }
     ```
     The client renders an administrative maintenance screen: *"Terms of Service are currently undergoing administrative update. Access will resume shortly. Please check back soon or contact support."* Access to commercial projects, drawings, and payments is suspended until an administrator publishes an active version. Administrators (`role IN ('ADMIN', 'STUDIO_ADMIN')`) retain access to publish or restore the document.
2. **Informational Notices (`is_mandatory = 0`, e.g. `PRIVACY_POLICY`, `ACCEPTABLE_USE_POLICY`):**
   - Access to platform workflows is **NOT blocked**.
   - The legal document viewer renders an informational placeholder: *"Notice is currently under administrative review."*
   - An administrative warning is logged, allowing operational work to proceed.
3. **Optional Consents (`OPTIONAL_PURPOSE`):**
   - Defaults strictly to **OFF / NOT GRANTED**. No optional processing occurs.
- *Status Note:* This fail-safe behavior is marked as **PENDING BUSINESS-OWNER CONFIRMATION**.

---

## 7. SERVER-SIDE AUTHORIZATION & ENDPOINT SPECIFICATION

### 7.1 Zero-Trust Security Policy
1. **No Trust in Client-Supplied Data:** The server never trusts client-supplied `user_id`, `role`, `status`, or `statutory_deadline`.
2. **Cryptographic Identity Verification:** Every authenticated request must carry a valid Firebase Auth Bearer JWT token, validated in Cloudflare Worker middleware. The `uid` and verified `role` are resolved server-side from the token and D1 database.
3. **Public Route Exemptions:** Public endpoints (`GET /api/legal/documents/*`) are explicitly exempted from the Bearer token requirement so unauthenticated visitors (e.g. on landing pages or login/registration screens) can view legal terms. All other endpoints enforce authentication.
4. **External Admin UI Boundary:** The external Admin UI is kept strictly outside this workspace. Backend endpoints provide standard RESTful JSON contracts for consumption by any authorized administration tool or client.

### 7.2 Complete Endpoint Authorization Matrix

| Method | Endpoint Path | Auth Required | Authorized Roles | Ownership / Access Control Rule | Description & Behavior |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/legal/documents/current` | No (Public) | Anyone | None (Public read) | Returns list of metadata for all currently `EFFECTIVE` documents. |
| `GET` | `/api/legal/documents/:type/current` | No (Public) | Anyone | None (Public read) | Returns full Markdown content and metadata for the currently `EFFECTIVE` version of specified type. |
| `GET` | `/api/legal/documents/:type/history` | No (Public) | Anyone | None (Public read) | Returns list of past `SUPERSEDED` versions (version string, effective dates, change summaries). |
| `GET` | `/api/users/me/legal-status` | Yes | All Authenticated | Caller UID (`c.get('uid')`) | Evaluates caller's acceptance status: returns `{ termsAccepted, acceptedVersion, effectiveVersion, reacceptanceRequired, activeConsents }`. |
| `POST` | `/api/legal/accept-terms` | Yes | All Authenticated | Caller UID (`c.get('uid')`) | Records affirmative terms acceptance. Validates that version matches `EFFECTIVE` version. Atomic event append + state upsert. |
| `POST` | `/api/legal/acknowledge-privacy` | Yes | All Authenticated | Caller UID (`c.get('uid')`) | Records privacy notice delivery/acknowledgment. Validates version. Atomic event append + state upsert. |
| `POST` | `/api/legal/consent` | Yes | All Authenticated | Caller UID (`c.get('uid')`) | Grants or withdraws a specific optional consent purpose (`consent_purpose`, `is_granted`). Atomic event append + state upsert. |
| `POST` | `/api/users/me/privacy-requests` | Yes | All Authenticated | Caller UID (`c.get('uid')`) | Creates a privacy/grievance ticket for caller. Calculates operational target and statutory deadline based on request type. |
| `GET` | `/api/users/me/privacy-requests` | Yes | All Authenticated | Caller UID (`c.get('uid')`) | Returns only tickets belonging to caller (`WHERE user_id = c.get('uid')`). Cross-user isolation enforced. |
| `GET` | `/api/admin/legal/consents` | Yes | `ADMIN`, `STUDIO_ADMIN` | Role-based check | Audit query interface. Allows filtering by user, document type, or date range. |
| `GET` | `/api/admin/legal/privacy-requests` | Yes | `ADMIN`, `STUDIO_ADMIN` | Role-based check | Lists all open and resolved privacy/grievance tickets with SLA status counters. |
| `POST` | `/api/admin/legal/privacy-requests/:id/resolve` | Yes | `ADMIN`, `STUDIO_ADMIN` | Role-based check | Updates ticket status (`RESOLVED`, `REJECTED`), records `resolved_by = admin_uid`, `resolution_notes`, and timestamp. |
| `POST` | `/api/admin/legal/documents` | Yes | `ADMIN`, `STUDIO_ADMIN` | Role-based check | Creates a new document version in `DRAFT` status. |
| `POST` | `/api/admin/legal/documents/:id/publish` | Yes | `ADMIN`, `STUDIO_ADMIN` | Role-based check | Transitions document from `DRAFT` to `PUBLISHED` or `EFFECTIVE`. Automates superseding of prior version in batch. |

---

## 8. PROPOSED DATABASE SCHEMA (D1 MIGRATION: 0016_LEGAL_SYSTEM.SQL PROPOSAL)

```sql
-- ============================================================================
-- ARCHI DRAFT — PHASE D SCHEMA DESIGN SPECIFICATION (PROPOSAL ONLY)
-- TARGET DATABASE: archi-draft-db (Binding: DB)
-- FILE: worker/migrations/0016_legal_system.sql (DO NOT EXECUTE IN THIS PHASE)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table 1: legal_documents
-- Centralized repository of versioned legal policies, notices, and agreements
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS legal_documents (
  id TEXT PRIMARY KEY,                       -- UUID v4 (Autoindex 1: sqlite_autoindex_legal_documents_1)
  document_type TEXT NOT NULL,               -- 'TERMS_AND_CONDITIONS', 'PRIVACY_POLICY', 'ACCEPTABLE_USE_POLICY', 'INTELLECTUAL_PROPERTY_POLICY', 'COMMUNICATION_CONSENT'
  version TEXT NOT NULL,                     -- Semantic version string, e.g. '1.0.0'
  title TEXT NOT NULL,                       -- Display title (e.g. 'Terms and Conditions')
  content TEXT NOT NULL,                     -- Markdown text content
  effective_at DATETIME NOT NULL,            -- Date/time the version becomes active
  published_at DATETIME DEFAULT CURRENT_TIMESTAMP, -- When published by admin
  published_by TEXT,                         -- Admin user ID who authorized publication
  status TEXT NOT NULL DEFAULT 'DRAFT',      -- 'DRAFT', 'PUBLISHED', 'EFFECTIVE', 'SUPERSEDED', 'ARCHIVED'
  is_mandatory INTEGER NOT NULL DEFAULT 1,   -- 1 = Blocking terms; 0 = Informational notice / optional consent
  locale TEXT NOT NULL DEFAULT 'en-IN',      -- Language/locale (e.g., 'en-IN')
  change_summary TEXT,                       -- Summary of material changes from previous version
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Explicit Index 1 (Unique):
CREATE UNIQUE INDEX IF NOT EXISTS idx_legal_docs_type_version_locale 
  ON legal_documents(document_type, version, locale);

-- Explicit Index 2:
CREATE INDEX IF NOT EXISTS idx_legal_docs_status_effective 
  ON legal_documents(status, effective_at);

-- Explicit Index 3 (Partial Unique): Enforces that exactly ONE document per (document_type, locale) can be EFFECTIVE
CREATE UNIQUE INDEX IF NOT EXISTS idx_single_effective_doc 
  ON legal_documents(document_type, locale) 
  WHERE status = 'EFFECTIVE';

-- ----------------------------------------------------------------------------
-- Table 2: legal_consent_events
-- Tamper-proof, append-only immutable audit log of affirmative legal actions
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS legal_consent_events (
  id TEXT PRIMARY KEY,                       -- UUID v4 (Autoindex 2: sqlite_autoindex_legal_consent_events_1)
  user_id TEXT NOT NULL,                     -- Foreign key to users(id) ON DELETE RESTRICT (Prevents cascade deletion)
  document_id TEXT NOT NULL,                 -- Foreign key to legal_documents(id) ON DELETE RESTRICT
  document_type TEXT NOT NULL,               -- 'TERMS_AND_CONDITIONS', 'PRIVACY_POLICY', 'OPTIONAL_CONSENT'
  document_version TEXT NOT NULL,            -- Exact version string accepted/acknowledged
  action_type TEXT NOT NULL,                 -- 'TERMS_ACCEPTED', 'PRIVACY_NOTICE_ACKNOWLEDGED', 'OPTIONAL_CONSENT_GRANTED', 'OPTIONAL_CONSENT_WITHDRAWN'
  consent_purpose TEXT,                      -- Nullable: Required for optional consents (e.g. 'MARKETING_COMMUNICATIONS', 'STUDENT_SHOWCASE')
  idempotency_key TEXT NOT NULL,             -- Unique deduplication key preventing duplicate event insertion
  ip_hash TEXT NOT NULL,                     -- Salted SHA-256 hash of client IP for privacy-preserving proof
  user_agent TEXT,                           -- Client browser / device user-agent string (truncated to <= 128 chars)
  source TEXT NOT NULL DEFAULT 'WEB_APP',    -- 'WEB_APP', 'MOBILE_APP', 'ADMIN_PORTAL'
  recorded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Strictly server-generated timestamp
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
  FOREIGN KEY (document_id) REFERENCES legal_documents(id) ON DELETE RESTRICT
);

-- Explicit Index 4 (Unique):
CREATE UNIQUE INDEX IF NOT EXISTS idx_consent_events_idempotency 
  ON legal_consent_events(idempotency_key);

-- Explicit Index 5:
CREATE INDEX IF NOT EXISTS idx_consent_events_user 
  ON legal_consent_events(user_id);

-- Explicit Index 6:
CREATE INDEX IF NOT EXISTS idx_consent_events_recorded 
  ON legal_consent_events(recorded_at);

-- ----------------------------------------------------------------------------
-- Table 3: user_consent_state
-- Materialized active consent state for fast, indexed runtime authorization
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_consent_state (
  id TEXT PRIMARY KEY,                       -- UUID v4 (Autoindex 3: sqlite_autoindex_user_consent_state_1)
  user_id TEXT NOT NULL,                     -- Foreign key to users(id) ON DELETE RESTRICT
  consent_type TEXT NOT NULL,                -- 'TERMS', 'PRIVACY_NOTICE', 'OPTIONAL_PURPOSE'
  purpose_tag TEXT NOT NULL DEFAULT 'DEFAULT', -- 'CORE_TERMS', 'PRIVACY_NOTICE', 'MARKETING_COMMUNICATIONS', etc.
  current_status TEXT NOT NULL,              -- 'ACCEPTED', 'ACKNOWLEDGED', 'GRANTED', 'WITHDRAWN'
  accepted_version TEXT NOT NULL,            -- Version string of last accepted/acknowledged document
  last_event_id TEXT NOT NULL,               -- References corresponding event in legal_consent_events(id)
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
  FOREIGN KEY (last_event_id) REFERENCES legal_consent_events(id) ON DELETE RESTRICT
);

-- Explicit Index 7 (Unique):
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_consent_state_unique 
  ON user_consent_state(user_id, consent_type, purpose_tag);

-- Explicit Index 8:
CREATE INDEX IF NOT EXISTS idx_user_consent_state_user 
  ON user_consent_state(user_id);

-- ----------------------------------------------------------------------------
-- Table 4: privacy_requests
-- Trackable statutory data rights, erasure, and grievance redressal tickets
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS privacy_requests (
  id TEXT PRIMARY KEY,                       -- Ticket reference, e.g., 'REQ-YYYYMMDD-XXXX' (Autoindex 4: sqlite_autoindex_privacy_requests_1)
  user_id TEXT NOT NULL,                     -- Requesting user UID (Foreign key ON DELETE RESTRICT)
  request_type TEXT NOT NULL,                -- 'GRIEVANCE', 'SECURITY_INCIDENT', 'DATA_ACCESS', 'DATA_CORRECTION', 'DATA_ERASURE', 'ACCOUNT_DELETION'
  details TEXT NOT NULL,                     -- User's request description or grievance particulars
  status TEXT NOT NULL DEFAULT 'PENDING',    -- 'PENDING', 'ACKNOWLEDGED', 'IN_REVIEW', 'RESOLVED', 'REJECTED'
  statutory_basis TEXT NOT NULL,             -- 'IT_SPDI_RULE_5_9', 'CERT_IN_DIR_2022', 'DPDP_SEC_11', 'DPDP_SEC_12'
  statutory_deadline DATETIME,               -- Populated if statutory deadline applies (e.g. 30 days for SPDI Rule 5(9); NULL for pending DPDP rules)
  operational_target_date DATETIME NOT NULL, -- Internal operational target resolution date
  resolution_notes TEXT,                     -- Notes from Grievance Officer / Admin
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  acknowledged_at DATETIME,                  -- When ticket was formally acknowledged by team
  resolved_at DATETIME,                      -- When ticket was closed
  resolved_by TEXT,                          -- Admin / Grievance Officer UID who resolved ticket
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
);

-- Explicit Index 9:
CREATE INDEX IF NOT EXISTS idx_privacy_req_user 
  ON privacy_requests(user_id);

-- Explicit Index 10:
CREATE INDEX IF NOT EXISTS idx_privacy_req_status 
  ON privacy_requests(status);

-- Explicit Index 11:
CREATE INDEX IF NOT EXISTS idx_privacy_req_target 
  ON privacy_requests(operational_target_date);
```

### 8.1 Schema & Index Inventory Summary
- **Total Tables:** 4 (`legal_documents`, `legal_consent_events`, `user_consent_state`, `privacy_requests`).
- **Total Explicit Indexes:** 11:
  - 3 Unique Indexes (`idx_legal_docs_type_version_locale`, `idx_consent_events_idempotency`, `idx_user_consent_state_unique`).
  - 1 Partial Unique Index (`idx_single_effective_doc`).
  - 7 Standard B-tree Indexes (`idx_legal_docs_status_effective`, `idx_consent_events_user`, `idx_consent_events_recorded`, `idx_user_consent_state_user`, `idx_privacy_req_user`, `idx_privacy_req_status`, `idx_privacy_req_target`).
- **Total SQLite Autoindexes (Internal Primary Key Indexes):** 4:
  - `sqlite_autoindex_legal_documents_1`
  - `sqlite_autoindex_legal_consent_events_1`
  - `sqlite_autoindex_user_consent_state_1`
  - `sqlite_autoindex_privacy_requests_1`
- **Total Index Records in `sqlite_master`:** 15.
- *Notice:* None of these tables or indexes have been created or executed in this phase.

---

## 9. MIGRATION RECOVERY, ROLLBACK LIMITATIONS & REALISTIC RESTORATION

### 9.1 Crucial Rollback Limitations (Down-Migration Warning)
> [!CAUTION]
> **DOWN-MIGRATIONS ARE DESTRUCTIVE:**  
> A down-migration script containing `DROP TABLE IF EXISTS legal_consent_events;` or `DROP TABLE IF EXISTS privacy_requests;` is **NOT a reversible rollback** in an environment containing user data.  
> Executing `DROP TABLE` permanently and irreversibly destroys the audit trail of consent, historical terms acceptances, and statutory grievance records, creating severe legal liability under the Indian Contract Act and DPDP Act.  
> Therefore, down-migration scripts are restricted strictly to clean-slate local development teardown testing.

### 9.2 Safe Recovery & Snapshot Restoration Limitations
- **Export vs. Restoration Difference:** Running `wrangler d1 export` dumps SQL statements (table creation and data inserts). Replaying this exported file into an existing database that already contains those tables or records will fail due to existing table names or duplicate primary keys. Replaying an export is **UNVERIFIED & UNSAFE** as an in-place restoration method.
- **Disposable Testing Only:** Local migration testing must be performed against disposable, ephemeral environments:
  1. In-memory SQLite instances via Node's native `DatabaseSync(':memory:')` (used by the test suite in `worker/test/`).
  2. Or an isolated, disposable local SQLite database that can be cleanly discarded without touching developer state.
- **Strict Prohibition:** Never execute backup, migration, or recovery commands against remote or production Cloudflare D1 or R2 services.

---

## 10. CLIENT INTEGRATION ARCHITECTURE (FLUTTER / RIVERPOD / GOROUTER)

### 10.1 Feature Directory Organization
The client-side implementation will reside in a dedicated, isolated feature directory: `lib/src/features/legal/`:
```
lib/src/features/legal/
├── data/
│   └── legal_repository.dart           # REST client calling /api/legal/* and /api/users/me/*
├── domain/
│   ├── legal_document.dart             # Model for policies, notices, and markdown text
│   ├── legal_consent_record.dart       # Model for consent event confirmations
│   └── user_legal_status.dart          # Model for { termsAccepted, reacceptanceRequired, activeConsents }
├── presentation/
│   ├── legal_onboarding_screen.dart    # Full-screen mandatory terms review gate
│   ├── legal_center_screen.dart        # Tabbed markdown viewer in user settings
│   └── widgets/
│       ├── privacy_request_dialog.dart # In-app data rights & grievance filing modal
│       ├── terms_acceptance_card.dart  # Checkbox + scrollable summary card
│       └── optional_consent_tile.dart  # Toggle switch for granular unbundled consents
└── providers/
    └── legal_providers.dart            # Riverpod providers managing legal state
```

### 10.2 GoRouter Interception Logic
In `lib/src/core/router/app_router.dart`, the router evaluates `userLegalStatusProvider`:
- If an authenticated user has `reacceptanceRequired == true` or `termsAccepted == false`:
  - The router redirects the user to `/onboarding/legal`.
  - The user cannot navigate to project dashboards, drawing workspaces, or payment screens until affirmative acceptance is recorded.
- **Unbundled Display:** On `/onboarding/legal`, the mandatory Terms acceptance is presented with a clear checkbox:
  - `[ ] I accept the Archi Draft Terms & Conditions (Version 1.0.0)`
  - Optional consents (marketing, public portfolio directory) are displayed below as separate toggle switches, defaulted to **OFF**. Toggling them is completely optional and does not block acceptance of the core Terms.

---

## 11. OPEN DEPENDENCIES & STATUTORY DISCLAIMERS

### 11.1 Dependencies Register (Provisional Status)

| Dependency Area | Required Input / Decision | Current Architectural Handling | Impact on Future Implementation |
| :--- | :--- | :--- | :--- |
| **Student Eligibility (<18 Minors)** | Business owner decision whether students under 18 will be permitted on the platform. | Kept unresolved. Schema and endpoints support age verification flags, but minor onboarding is not activated. | If minors are permitted, Section 9 of DPDP Act mandates verifiable parental consent and prohibits behavioral tracking/profiling. |
| **Drawing Intellectual Property** | Allocation of CAD/DWG copyright, moral rights, client ownership, and platform license. | Kept unresolved. Policy draft maintains clear placeholder terms reserving platform operational license. | Requires formal sign-off by business owner and qualified IP legal counsel before terms publication. |
| **Operational Retention Schedules** | Exact calendar duration for storing past CAD drawings, project messages, and deliverables. | Modeled with flexible purge hooks; retention schedule marked as unapproved operational policy. | Automated deletion routines for past drawing files will remain dormant until schedules are confirmed. |
| **Proprietor & Business Details** | Sole Proprietorship full legal name, registered business address, GSTIN, and official support email. | Maintained strictly as placeholders (`[PROP_NAME]`, `[BUSINESS_ADDRESS]`) across all documents. | Production database seed migrations will not be finalized until real business details are provided. |
| **Grievance Officer Appointment** | Formal designation of individual Grievance Officer and dedicated statutory email address. | Modeled with standard placeholder contact details (`[UNCONFIRMED PLACEHOLDER: grievance@archidraft.com]`). | Required to be formally appointed and published prior to public launch under IT SPDI Rule 5(9). |

### 11.2 Legal & Production Readiness Disclaimer
> [!WARNING]
> **NOT FORMAL LEGAL ADVICE & NOT PRODUCTION READY:**  
> This architectural proposal and its accompanying policy drafts are technical engineering documents designed to align software architecture with applicable Indian data protection principles (IT Act 2000, IT SPDI Rules 2011, DPDP Act 2023, and CERT-In Directions 2022).  
> They do not constitute formal legal advice or a binding legal opinion. All statutory interpretations, contractual terms, intellectual property allocations, and privacy policies must be reviewed and approved by qualified Indian legal counsel before deployment to production.  
> No application code has been modified and no database migrations have been executed in this phase.

---
**REVISED PROPOSAL COMPILED BY:** ANTIGRAVITY AI AGENT  
**STATUS:** AWAITING EXPLICIT APPROVAL BEFORE IMPLEMENTATION  
