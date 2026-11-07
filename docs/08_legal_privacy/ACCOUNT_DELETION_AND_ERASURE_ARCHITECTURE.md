# ARCHI DRAFT | ACCOUNT DELETION & PERSONAL DATA ERASURE ARCHITECTURE
## Statutory Compliance Architecture under Section 12, Digital Personal Data Protection Act, 2023

**Project:** ARCHI DRAFT  
**Operating Brand:** DRAUGHTSMAN STUDIO  
**Legal Proprietor:** MOHAMMED MOSIN S  
**Business Structure:** Sole Proprietorship  
**Phase:** 2 of 9 — D1 Database & Backend Foundation  
**Date:** November 2026  
**Status:** Approved Technical Architecture  

---

## 1. REGULATORY FOUNDATION & CORE OBJECTIVE

Under **Section 12 of the Digital Personal Data Protection Act, 2023 (DPDP Act)**, a Data Principal has the right to erasure of personal data that is no longer necessary for the purpose for which it was processed, unless retention is mandated by law.

In a collaborative architectural coordination environment (where consulting engineers, draughtsmen, and students collaborate on building plans and municipal submissions), "deleting an account" cannot be a destructive cascade deletion (`ON DELETE CASCADE`). An uncontrolled delete would:
1. Break relational database integrity across foreign keys (`ON DELETE RESTRICT`).
2. Destroy legitimate drawing deliverables and revision histories belonging to co-collaborating engineers or clients.
3. Violate statutory 180-day cybersecurity log retention mandates under **Direction No. 20(3)/2022-CERT-In**.
4. Violate statutory 8-year tax accounting requirements under Section 44AA of the **Income Tax Act, 1961**.

This architecture establishes a state-machine driven, auditable, and resilient erasure engine that **anonymizes personal identity** while **preserving collaborative project deliverables and statutory audit trails**.

---

## 2. STATE MACHINE & REQUEST STATUSES

Every account deletion request is managed through the `account_deletion_requests` ledger and transitions through strict, deterministic states:

```
                  +---------------------------+
                  |         SUBMITTED         |  <--- User calls POST /api/legal/account-deletion-requests
                  +-------------+-------------+
                                |
             +------------------+------------------+
             |                                     |
             v                                     v
+---------------------------+         +---------------------------+
| IDENTITY_VERIFICATION_REQ |         |         CANCELLED         |  <--- User calls POST .../cancel
+-------------+-------------+         +---------------------------+
             |
             v
+---------------------------+
|         VERIFIED          |
+-------------+-------------+
             |
             v
+---------------------------+
|       UNDER_REVIEW        |  <--- Admin evaluates project dependencies & active contracts
+-------------+-------------+
             |
     +-------+-------------------------+
     |                                 |
     v                                 v
+---------------------------+     +---------------------------+
|    DELETION_SCHEDULED     |     |   REJECTED_WITH_REASON    |  <--- e.g., active legal dispute
+-------------+-------------+     +---------------------------+
             |
             v
+---------------------------+
|        PROCESSING         |  <--- Anonymization & AI chat purge executing
+-------------+-------------+
             |
     +-------+-------------------------+
     |                                 |
     v                                 v
+---------------------------+     +---------------------------+
|         COMPLETED         |     |          FAILED           |  <--- Network/DB failure; retryable
+---------------------------+     +---------------------------+
```

### Status Definitions:
- `SUBMITTED`: Request successfully registered by an authenticated user; awaiting verification check.
- `IDENTITY_VERIFICATION_REQUIRED`: Step-up re-authentication required if token age exceeds policy.
- `VERIFIED`: Caller identity cryptographically verified.
- `UNDER_REVIEW`: Studio operations reviewing whether user is sole owner of active uncompleted projects.
- `DELETION_SCHEDULED`: Approved for execution with a configured grace window.
- `PROCESSING`: Automated erasure and anonymization jobs actively running.
- `COMPLETED`: Deletion and tombstoning fully verified; completion timestamp recorded.
- `REJECTED_WITH_REASON`: Request rejected (e.g. active litigation, pending fraudulent chargeback, open municipal permit filing).
- `CANCELLED`: Voluntarily cancelled by user before processing began.
- `FAILED`: Execution exception encountered; logged in `failure_details` for retry.

---

## 3. SUBSYSTEM-BY-SUBSYSTEM ERASURE & ANONYMIZATION MATRIX

| Subsystem | Storage Engine | Personal Data Category | Treatment on `COMPLETED` | Relational & Legal Justification |
| :--- | :--- | :--- | :--- | :--- |
| **Authentication** | Firebase Auth | Email, Password Hash, UID | **Revoked & Queued for Deletion** from Firebase Identity. | Prevents subsequent logins. |
| **User Profile** | Cloudflare D1 (`users`) | Legal Name, Mobile, Address, College | **Tombstoned & Anonymized**: `name = 'Deleted User'`, `email = 'deleted_<uid>@archidraft.local'`, `mobile = NULL`, `status = 'SUSPENDED'`. | Retains immutable primary key `id` so collaborating users' project foreign keys do not fail. |
| **AI Assistant** | Cloudflare D1 (`chat_*`)| AI conversations & chat messages | **Hard Deleted**: `DELETE FROM chat_messages` and `DELETE FROM chat_sessions WHERE user_id = ?`. | AI queries have no collaborative dependencies; purged for privacy. |
| **Personal Files** | Cloudflare R2 | Profile avatars, resume, personal drafts | **Hard Deleted** from R2 storage. | Personal assets with no project claim. |
| **Collaborative CAD**| Cloudflare R2 & D1 (`drawing_versions`) | Completed DWG plans, PDFs, approval sheets | **PRESERVED**: Retained in project hub. | Commissioned deliverables belong to the project/client under commercial contract. |
| **Project Chat** | Cloudflare D1 (`project_messages`) | Revision notes, comments, voice notes | **Preserved with Anonymized Author**: Displayed as `[Deleted User]`. | Technical project thread continuity required for engineering liability. |
| **Legal Consents** | Cloudflare D1 (`legal_consent_*`)| Historical consent events, IP hash, user agent | **RESTRICTED RETENTION**: Preserved in immutable table. | **Statutory Mandate**: Direction No. 20(3)/2022-CERT-In requires 180-day log preservation. |
| **Financials** | Cloudflare D1 (`financials`) | Milestone fee records, invoices | **RESTRICTED RETENTION**: Preserved in financial ledger. | **Statutory Mandate**: Income Tax Act Sec 44AA & CGST Act Sec 36 require 8-year tax preservation. |

---

## 4. FAILURE RECOVERY & AUDIT PROVENANCE

To guard against partial execution failures (e.g. D1 updates succeeding while R2 or external identity calls timeout), `account_deletion_requests` maintains a JSON tracking array in `systems_processed`:

```json
[
  "D1_PROFILE_ANONYMIZED",
  "PIXMINT_BOT_CONVERSATIONS_PURGED",
  "COLLABORATIVE_PROJECT_CAD_PRESERVED",
  "STATUTORY_CERTIN_LOGS_PRESERVED"
]
```

- If an error occurs, the request status is set to `FAILED`, the stack trace is written to `failure_details`, and already-processed systems remain recorded.
- Administrative tools can safely retry failed jobs without duplicate operations or corrupted state.

