# ARCHI DRAFT — Administrative Privacy Request Workflow Guide
**Operating Brand:** DRAUGHTSMAN STUDIO  
**Legal Proprietor:** MOHAMMED MOSIN S  
**Product:** ARCHI DRAFT  
**Phase:** 4 of 9 (Next.js Admin Legal Compliance Dashboard & Audit Center)  
**Date:** November 2026  
**Status:** Completed & Tested

---

## 1. Overview of Statutory Rights Management

Under India's **Digital Personal Data Protection Act, 2023 (DPDP Act)**, Data Principals possess legally enforceable rights regarding their personal data. Studio Administrators are responsible for reviewing, auditing, and resolving these requests in an auditable manner.

The ARCHI DRAFT Admin Web portal provides specialized review workflows for:
1. **Right to Erasure / Account Deletion (§ 12(3) DPDP Act)**
2. **Right to Access & Data Portability / Export (§ 11 DPDP Act)**
3. **Right to Correction & Updating (§ 12(1) DPDP Act)**

---

## 2. Account Erasure Workflow (§ 12(3) DPDPA)

### 2.1 The 30-Day Cancellation Grace Window
When a user initiates account deletion from the Flutter Legal Center:
1. The request enters the admin queue (`/api/admin/legal/account-deletion-requests`) with status `PENDING` and a `scheduled_purge_at` timestamp set exactly 30 days into the future.
2. During this 30-day window, the user may cancel the request directly in their app. If cancelled, the status updates to `CANCELLED` and no further action is taken.

### 2.2 Administrative Review Decisions
Administrators inspect the request in `AccountDeletionsTab` and can select:
- `UNDER_REVIEW`: Review in progress.
- `IDENTITY_VERIFICATION_REQUIRED`: Additional user verification needed before proceeding.
- `VERIFIED`: User identity verified.
- `DELETION_SCHEDULED`: Confirmed for automatic or manual purge.
- `COMPLETED`: Execute tombstone and AI conversation purge.
- `REJECTED_WITH_REASON`: Request rejected (e.g., active legal dispute, unresolved fraud investigation).

### 2.3 The Tombstoning & CAD Preservation Protocol
When an administrator marks a deletion request as `COMPLETED`:
1. **PII Anonymization (Tombstone):** The user's row in the D1 `users` table is updated:
   * `name`: Set to `'Deleted User'`
   * `email`: Set to `'deleted_<UID>@archidraft.local'`
   * `mobile`: Cleared to `NULL`
   * `status`: Set to `'SUSPENDED'`
   * *Foreign Key Integrity:* The user's immutable UID is preserved to prevent orphaned foreign key references across collaborative projects.
2. **AI Chat Purge:** All private PIXMINT BOT conversation records (`chat_sessions` and `chat_messages`) associated with the user UID are permanently deleted from Cloudflare D1.
3. **Collaborative Project CAD Preservation:**
   * Completed drawings, revisions, redline annotations, and approvals authored by the user are **not** deleted.
   * Drawings commissioned by third-party clients remain intact to preserve project engineering integrity.
4. **Statutory Audit Log Preservation:**
   * Access logs and consent events are retained for a minimum of **180 days** pursuant to Direction No. 20(3)/2022-CERT-In.
   * Invoices and financial ledger entries are retained for **8 financial years** pursuant to the Income-tax Act.

---

## 3. Data Export Workflow (§ 11 DPDPA)

### 3.1 Supported Scopes
- `FULL_ARCHIVE`: Complete JSON archive including profile, projects, revisions, financials, and consent records.
- `PROJECTS_ONLY`: Metadata and R2 file pointers for all authored/commissioned CAD drawings.
- `CONSENT_AUDIT`: Immutable history of accepted policy versions and timestamps.

### 3.2 7-Day Download Expiry & Security
- Data export requests transition across: `PENDING` &rarr; `PROCESSING` &rarr; `COMPLETED` (or `FAILED`).
- Once completed, a secure cryptographic token (`download_token`) and a strict 7-day expiration timestamp (`expires_at`) are attached.
- Download tokens are protected on the backend and are not exposed in logs or telemetry.
- If the 7-day window elapses, the token is invalidated and the status is treated as `EXPIRED`.

---

## 4. Data Correction Workflow (§ 12(1) DPDPA)

### 4.1 Permitted Fields
To prevent fraudulent privilege escalation or identity spoofing, self-service profile edits are routed through administrative approval for:
- `name`: Legal Full Name
- `mobile`: Contact Mobile Number
- `address`: Work / Postal Address
- `qualification`: Professional Drafting / Engineering Qualification

### 4.2 Review & Atomic Synchronization
1. The admin reviews the current value against the user's proposed value and stated justification.
2. If approved (`RESOLVED`), checking the *"Atomically apply proposed value to user profile record in D1"* checkbox causes the Cloudflare Worker backend to immediately execute an atomic SQL update on the target column in the `users` table.
3. If rejected (`REJECTED`), the reviewer records a mandatory justification, and the user's profile remains unchanged.
