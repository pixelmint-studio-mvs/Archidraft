# ARCHI DRAFT — PHASE D LOCAL MIGRATION TEST PLAN & VERIFICATION SPECIFICATION
**DOCUMENT STATUS:** VALIDATED LOCAL TESTING SPECIFICATION (PROVISIONAL)  
**STAGE:** PHASE D — ARCHITECTURE REVIEW & TEST PLAN FINALIZATION  
**EXECUTION NOTICE:** TEST SPECIFICATION ONLY — NO MIGRATIONS CREATED OR EXECUTED IN THIS TASK  
**REQUIRES EXPLICIT APPROVAL BEFORE PROCEEDING TO IMPLEMENTATION**  
**PROJECT:** Archi Draft  
**PARENT BRAND:** Draughtsman Studio (https://www.draughtsmanstudio.com)  
**D1 DATABASE BINDING:** `DB` (Database Name: `archi-draft-db`, ID: `af8d3312-5f6e-46ce-bcc1-dfa91e484cc0`)  
**R2 STORAGE BINDING:** `STORAGE` (Bucket Name: `archi-draft-storage`)  
**TARGET JURISDICTION:** India  
**DATE:** OCTOBER 2026  
**DOCUMENT VERSION:** 1.1.0-TEST-SPEC-CORRECTED  

---

## 1. PURPOSE & TEST OBJECTIVES

This document specifies the step-by-step local testing procedure, expected results, schema verification queries, automated test specifications, and recovery protocols for Phase D (`0016_legal_system.sql`).

### Primary Objectives:
1. **Local-Only Execution:** Guarantee that all testing is executed strictly in an isolated local environment without touching remote or production Cloudflare D1 databases.
2. **Schema & Constraint Verification:** Validate proposed table creation, composite indexes, the partial unique index enforcing single effective versions, foreign key `ON DELETE RESTRICT` rules, and unique idempotency constraints.
3. **Authorization & Anti-Spoofing:** Verify public read access on effective documents, unauthenticated rejection on legal status checks, strict role gating on administrative endpoints, and rejection of client-supplied user IDs or forged timestamps.
4. **Idempotency & Concurrency:** Verify that rapid duplicate submissions with the same idempotency key return HTTP 200 without creating redundant event rows.
5. **Cross-User Isolation:** Verify that standard users can only view their own privacy requests and cannot access or manipulate other users' tickets.
6. **Zero Regression:** Guarantee that all 168 existing passing tests across `worker/test/` continue to pass without any breaking changes.

---

## 2. PRE-REQUISITES & ENVIRONMENT SETUP

### 2.1 Verified Repository Configuration
- **Worker Configuration:** [`worker/wrangler.toml`](file:///D:/PROJECT/Archidraft-integration-workspace/worker/wrangler.toml)
  - `database_name = "archi-draft-db"`
  - `binding = "DB"`
  - `bucket_name = "archi-draft-storage"`
  - `binding = "STORAGE"`
- **Migration Directory:** `worker/migrations/`
  - Existing migrations: `0001_schema.sql` through `0015_student_credentials_verification.sql`
  - Proposed Phase D migration: `0016_legal_system.sql` (Proposed design only; not created in this phase).
- **Node Test Runner:** Node.js native test runner (`node:test`) using in-memory SQLite (`node:sqlite`).

### 2.2 Standard Working Directory for Backend Commands
Unless explicitly noted otherwise, all Wrangler and migration test commands in this document assume the execution directory is:
```powershell
cd D:\PROJECT\Archidraft-integration-workspace\worker
```
*(Running Wrangler from `worker/` ensures that `wrangler.toml` and relative paths like `migrations/0016_legal_system.sql` resolve without configuration ambiguity).*

### 2.3 Baseline Test Health Verification (Freshly Verified)
To verify baseline test health before any Phase E work, run the existing test suite from `worker/`:
```powershell
# Working directory: D:\PROJECT\Archidraft-integration-workspace\worker
npm test
```
*Freshly Verified Outcome:* 73/73 tests pass in `backend_authorization.test.mjs`.

To run the complete existing test suite across all three existing test files:
```powershell
# Working directory: D:\PROJECT\Archidraft-integration-workspace\worker
node --test test/backend_authorization.test.mjs test/cross_user_isolation_f1.test.mjs test/admin_student_contract.test.mjs
```
*Freshly Verified Outcome:* All 168 existing tests pass (0 failures, 0 skipped, execution duration ~520ms).  
*Notice:* This count reflects existing pre-Phase-D tests. No Phase D legal test file has been executed or created yet.

---

## 3. PROPOSED SCHEMA & INDEX INVENTORY RECONCILIATION

The proposed schema defines four tables. An exact count reveals **11 explicit indexes** and **4 SQLite-generated autoindexes** (for primary keys), totaling **15 index records** in `sqlite_master`:

### 3.1 Inventory Table

| Table Name | Primary Key (Autoindex) | Explicit Indexes Defined | Total Indexes in `sqlite_master` |
| :--- | :--- | :--- | :--- |
| **`legal_documents`** | `sqlite_autoindex_legal_documents_1` (on `id`) | 1. `idx_legal_docs_type_version_locale` (UNIQUE)<br>2. `idx_legal_docs_status_effective` (B-tree)<br>3. `idx_single_effective_doc` (PARTIAL UNIQUE WHERE `status = 'EFFECTIVE'`) | 4 |
| **`legal_consent_events`** | `sqlite_autoindex_legal_consent_events_1` (on `id`) | 4. `idx_consent_events_idempotency` (UNIQUE)<br>5. `idx_consent_events_user` (B-tree)<br>6. `idx_consent_events_recorded` (B-tree) | 4 |
| **`user_consent_state`** | `sqlite_autoindex_user_consent_state_1` (on `id`) | 7. `idx_user_consent_state_unique` (UNIQUE)<br>8. `idx_user_consent_state_user` (B-tree) | 3 |
| **`privacy_requests`** | `sqlite_autoindex_privacy_requests_1` (on `id`) | 9. `idx_privacy_req_user` (B-tree)<br>10. `idx_privacy_req_status` (B-tree)<br>11. `idx_privacy_req_target` (B-tree) | 4 |
| **TOTALS** | **4 Autoindexes** | **11 Explicit Indexes** | **15 Total Indexes** |

---

## 4. LOCAL MIGRATION EXECUTION & SCHEMA VERIFICATION PROCEDURE

### Step 4.1: Backup Snapshot Limitations & Safe Testing
> [!WARNING]
> **EXPORT VS. RESTORATION LIMITATION:**  
> Running `npx wrangler d1 export archi-draft-db --local --output=backup.sql` outputs a stream of SQL schema definitions and insert statements. Replaying this exported file directly into an existing database that already contains tables will fail due to naming conflicts (`table ... already exists`) or primary key collisions. Replaying an export into an existing database is **UNVERIFIED & UNSAFE** as a restoration method.

**Safe Procedure for Local Testing:**
To validate migration behavior safely without risking existing local data:
1. Prefer testing against ephemeral, in-memory SQLite databases using Node's `DatabaseSync(':memory:')` (as implemented in `worker/test/`). In-memory databases are completely discarded upon process termination.
2. For testing against the local Wrangler D1 storage engine, test against an isolated disposable local database or ensure a clean state before execution.
3. **Strict Prohibition:** Never run any export, migration, or test command against remote or production Cloudflare D1 or R2.

---

### Step 4.2: Execute Local Migration (When Authorized in Phase E)
```powershell
# Working directory: D:\PROJECT\Archidraft-integration-workspace\worker
npx wrangler d1 execute archi-draft-db --local --file=migrations/0016_legal_system.sql
```
*Expected Output:*
`Executing on local database archi-draft-db...`  
`Success: 0016_legal_system.sql executed successfully.`

---

### Step 4.3: Verify Schema & Index Structure
```powershell
# Working directory: D:\PROJECT\Archidraft-integration-workspace\worker
npx wrangler d1 execute archi-draft-db --local --command="SELECT type, name, tbl_name FROM sqlite_master WHERE name LIKE 'legal_%' OR name LIKE 'privacy_%' ORDER BY type, name;"
```
*Expected Output Table (15 indexes + 4 tables):*
```
type   | name                                    | tbl_name
-------+-----------------------------------------+---------------------
index  | idx_consent_events_idempotency          | legal_consent_events
index  | idx_consent_events_recorded             | legal_consent_events
index  | idx_consent_events_user                 | legal_consent_events
index  | idx_legal_docs_status_effective         | legal_documents
index  | idx_legal_docs_type_version_locale      | legal_documents
index  | idx_privacy_req_status                  | privacy_requests
index  | idx_privacy_req_target                  | privacy_requests
index  | idx_privacy_req_user                    | privacy_requests
index  | idx_single_effective_doc                | legal_documents
index  | idx_user_consent_state_unique           | user_consent_state
index  | idx_user_consent_state_user             | user_consent_state
index  | sqlite_autoindex_legal_consent_events_1 | legal_consent_events
index  | sqlite_autoindex_legal_documents_1      | legal_documents
index  | sqlite_autoindex_privacy_requests_1     | privacy_requests
index  | sqlite_autoindex_user_consent_state_1   | user_consent_state
table  | legal_consent_events                    | legal_consent_events
table  | legal_documents                         | legal_documents
table  | privacy_requests                        | privacy_requests
table  | user_consent_state                      | user_consent_state
```

---

## 5. PLANNED AUTOMATED TEST SUITES (`legal_privacy_authorization.test.mjs`)

When Phase E implementation is approved, a new test file `worker/test/legal_privacy_authorization.test.mjs` will be created using the repository's native `node:test` framework. The planned suites are:

### Suite 1: Schema Constraints & Foreign Key Integrity
- **Test 1.1:** Verifies all 4 tables and 15 indexes exist in `sqlite_master`.
- **Test 1.2:** Verifies `ON DELETE RESTRICT`: Attempting `DELETE FROM users WHERE id = ?` when legal consent events or privacy requests exist fails with `FOREIGN KEY constraint failed`.
- **Test 1.3:** Verifies partial unique index `idx_single_effective_doc`: Inserting a second `EFFECTIVE` document for `('TERMS_AND_CONDITIONS', 'en-IN')` fails with `UNIQUE constraint failed`.

### Suite 2: Document Lifecycle & Fail-Safe Behavior
- **Test 2.1:** Atomic transition: Setting a document to `EFFECTIVE` atomically transitions the prior version to `SUPERSEDED`.
- **Test 2.2:** Fail-safe for missing mandatory Terms: When no `EFFECTIVE` version of Terms exists, `GET /api/legal/documents/TERMS_AND_CONDITIONS/current` returns HTTP 404 with `{ "document": null, "status": "NO_EFFECTIVE_VERSION", "access": "SUSPENDED_MAINTENANCE" }`. Non-admin users are placed on a maintenance hold; terms acceptance is not silently bypassed.
- **Test 2.3:** Informational notices: Missing non-mandatory notices (`is_mandatory = 0`) do not block access.

### Suite 3: Public vs. Authenticated Endpoint Authorization
- **Test 3.1:** Public read: Unauthenticated `GET /api/legal/documents/current` succeeds (HTTP 200) and returns only `EFFECTIVE` versions.
- **Test 3.2:** Protected user status: Unauthenticated `GET /api/users/me/legal-status` is rejected (HTTP 401).
- **Test 3.3:** Admin role gating: Non-admin users attempting `POST /api/admin/legal/*` are rejected (HTTP 403). Admin users succeed (HTTP 201).

### Suite 4: Consent Idempotency & Concurrency Deduplication
- **Test 4.1:** First acceptance records append-only event in `legal_consent_events` and updates `user_consent_state` (`current_status = 'ACCEPTED'`).
- **Test 4.2:** Submitting an identical payload with the same `idempotency_key` returns HTTP 200 with `{ status: 'ALREADY_RECORDED' }` without creating duplicate event rows.
- **Test 4.3:** Withdrawing optional consent appends `OPTIONAL_CONSENT_WITHDRAWN` and updates state to `WITHDRAWN`, while preserving the prior `GRANTED` event intact.

### Suite 5: Cross-User Privacy Request Isolation
- **Test 5.1:** User A querying `GET /api/users/me/privacy-requests` receives only User A's tickets.
- **Test 5.2:** User B querying `GET /api/users/me/privacy-requests` receives only User B's tickets and cannot view User A's records.
- **Test 5.3:** Admin querying `GET /api/admin/legal/privacy-requests` receives all tickets across all users.

### Suite 6: Full Regression Verification
- **Test 6.1:** Re-executes the baseline regression suite (168 tests across `backend_authorization.test.mjs`, `cross_user_isolation_f1.test.mjs`, and `admin_student_contract.test.mjs`), ensuring zero breakage of existing features.

---

## 6. MIGRATION RECOVERY & TEARDOWN CLARIFICATIONS

### 6.1 Down-Migration vs. Data Destruction
- **Disposable Testing Only:** Executing `DROP TABLE` statements is **only acceptable in disposable local development environments**.
- **Destructive Warning:** If executed on a database containing real or test data, `DROP TABLE` permanently destroys the evidentiary audit trail of consent and open statutory grievance tickets. It is **NOT** a reversible rollback.
- **Local Teardown Command (Clean-Slate Dev Only):**
  ```powershell
  # Working directory: D:\PROJECT\Archidraft-integration-workspace\worker
  npx wrangler d1 execute archi-draft-db --local --command="DROP TABLE IF EXISTS privacy_requests; DROP TABLE IF EXISTS user_consent_state; DROP TABLE IF EXISTS legal_consent_events; DROP TABLE IF EXISTS legal_documents;"
  ```

---

## 7. OUTSTANDING UNRESOLVED DEPENDENCIES & DISCLAIMERS

The following items are **explicitly unresolved** and remain provisional pending business-owner and qualified Indian legal counsel sign-off:
1. **Student Minor Policy (<18):** Unconfirmed. If minors are permitted, Section 9 of DPDP Act mandates verifiable parental consent and prohibits behavioral tracking/profiling.
2. **Drawing Intellectual Property Allocation:** Commercial terms allocating CAD copyright, moral rights, and platform operational licensing remain unconfirmed.
3. **Operational CAD Retention Schedules:** Exact calendar duration for storing historical CAD drawing files and project messages remains unconfirmed.
4. **Sole Proprietorship Details:** Sole Proprietor legal name, registered business address, GSTIN, and official contact phone number are currently maintained as placeholders (`[PROP_NAME]`, `[BUSINESS_ADDRESS]`).
5. **Grievance Officer Appointment:** Designation of an individual Grievance Officer and dedicated statutory email address (`[UNCONFIRMED PLACEHOLDER: grievance@archidraft.com]`) must be officially operationalized prior to public launch under IT SPDI Rule 5(9).
6. **DPDP Statutory Rules Gazetting:** The exact statutory timelines for Data Principal access, correction, and erasure remain pending official notification of rules by MeitY.

---
**TEST PLAN SPECIFIED BY:** ANTIGRAVITY AI AGENT  
**STATUS:** AWAITING EXPLICIT APPROVAL BEFORE IMPLEMENTATION  
