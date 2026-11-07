# ARCHI DRAFT — PHASE 5.1 ACCOUNT DELETION LIFECYCLE REPORT
## 14-Subsystem Data Inventory, Erasure Orchestration & Counterparty Rights Protection

- **Project:** ARCHI DRAFT
- **Operating Brand:** DRAUGHTSMAN STUDIO
- **Legal Proprietor:** MOHAMMED MOSIN S
- **Component:** Cloudflare D1 / Worker Backend / Flutter / Admin Web
- **Audited Files:** `worker/src/legal.ts` (lines 890–1055), `worker/migrations/0026_canonical_legal_system.sql`, `shared/legal/adapters/typescript/deletion_policy.ts`
- **Statutory Framework:** Digital Personal Data Protection Act 2023 (Section 12 — Right to Correction and Erasure of Personal Data)

---

## 1. Executive Summary

This report establishes the complete architectural and operational framework for the Account Deletion and Erasure subsystem in ARCHI DRAFT. Under Section 12 of the DPDP Act 2023, data principals have the right to request the erasure of their personal data unless retention is necessary for compliance with any law or for fulfilling contractual obligations.

In a multi-sided technical collaboration and training platform, blind database row deletion (`CASCADE DELETE`) creates catastrophic legal liability, destroying architectural audit trails, invalidating tax records, and infringing counterparty property rights. ARCHI DRAFT implements a state-machine driven, 14-subsystem erasure orchestration model classifying data into five distinct legal categories:
1. `DELETE`: Irreversible permanent purging.
2. `ANONYMIZE`: Irreversible anonymization and tombstoning.
3. `RETAIN`: Statutory retention for legal compliance.
4. `PRESERVE`: Contractual and structural liability preservation.
5. `PENDING_REVIEW`: Administrative hold for active obligations.

---

## 2. 14-Subsystem Data Inventory & Erasure Classification

| # | Subsystem / Table | Classification | Erasure Action | Legal & Operational Rationale |
| :--- | :--- | :--- | :--- | :--- |
| 1 | `users` | `ANONYMIZE` | Name replaced with `'Deleted User'`, email rewritten to `deleted_<uid>@archidraft.local`, status set to `'SUSPENDED'`. Auth tokens revoked. | Preserves foreign key integrity across historical transactions without retaining PII. |
| 2 | `user_profiles` | `ANONYMIZE` | Mobile number, address, qualification, and date of birth purged (`NULL`). | Eradicates all secondary PII under DPDP Act Sec 12. |
| 3 | `pixmint_sessions` | `DELETE` | Irreversible hard purge (`DELETE FROM pixmint_sessions WHERE user_id = ?`). | Ephemeral AI assistance sessions carry no ongoing contractual reliance. |
| 4 | `pixmint_messages` | `DELETE` | Irreversible hard purge (`DELETE FROM pixmint_messages WHERE session_id IN (...)`). | Direct user AI queries and responses permanently wiped. |
| 5 | `notifications` | `DELETE` | Irreversible hard purge (`DELETE FROM notifications WHERE user_id = ?`). | Operational notifications are ephemeral and deleted upon request. |
| 6 | `activity_logs` | `RETAIN` | Retained for 180 days with hashed user IDs, then purged by automated retention worker. | Mandatory statutory compliance with **CERT-In Direction No. 20(3)/2022** (ICT security logs). |
| 7 | `projects` | `PRESERVE` | Preserved if completed; project ownership transferred to Studio Admin. If project is in progress, deletion blocked (`PENDING_REVIEW`). | Protects client deliverables, drawing packages, and vocational training assignments. |
| 8 | `project_comments` | `ANONYMIZE` | Comment content retained; author name replaced with `'Former Member'`, email removed. | Preserves contextual engineering review feedback required for project continuity. |
| 9 | `drawing_versions` | `PRESERVE` | CAD drawing files and metadata preserved permanently. | Counterparty intellectual property and architect professional liability (**Indian Copyright Act 1957 Sec 57**). |
| 10 | `drawing_version_reviews` | `PRESERVE` | Admin and QC review verdicts, timestamps, and feedback preserved permanently. | Essential quality control audit trail proving structural drafting compliance. |
| 11 | `invoices` & `payments` | `RETAIN` | Financial records retained for 8 years from fiscal year end. | Mandatory statutory tax compliance (**Income Tax Act 1961 Section 44AA / Rule 6F**). |
| 12 | `student_lessons` | `ANONYMIZE` | Lesson completion progress retained with tombstoned user ID; personal notes purged. | Maintains institutional accreditation statistics and curriculum metrics. |
| 13 | `student_credentials` | `PRESERVE` | Issued certificate IDs, cryptographic verification hashes, and timestamps preserved. | Enables external third-party credential verification (**IT Act 2000 Section 4**). |
| 14 | `legal_consents` | `RETAIN` | Consent audit ledger, acceptance history, and deletion requests retained in audit tables. | Evidentiary defense against regulatory complaints (**DPDP Act 2023 Sec 6(10)**). |

---

## 3. Account Deletion State Machine & Lifecycle

The account deletion process transitions through a deterministic state machine:

```
[SUBMITTED] 
    │
    ▼
[IDENTITY_VERIFICATION_REQUIRED]
    │
    ▼
[VERIFIED]
    │
    ▼
[UNDER_REVIEW] (Admin evaluation of active projects / financial holds)
    │
    ├──▶ [HOLD_REJECTED] (Active commercial project or unsettled liability)
    │
    ▼
[DELETION_SCHEDULED] (Enters 30-day grace period)
    │
    ├──▶ [CANCELLED] (User initiates self-service cancellation during grace period)
    │
    ▼
[PROCESSING] (Automated batch deletion engine runs)
    │
    ▼
[COMPLETED] (Tombstoning and purging finalized; irreversible)
```

---

## 4. 30-Day Statutory Grace Period & Self-Service Cancellation

1. **Grace Period Policy:**
   - To prevent accidental loss of vocational credentials or malicious account destruction, requests enter a 30-day cooling-off window upon submission.
   - During this window, user access is restricted, but data remains restorable.
2. **Cancellation Eligibility (`worker/src/legal.ts`):**
   - The user or an authorized Studio Admin may cancel a pending deletion request if its status is in:
     `['SUBMITTED', 'IDENTITY_VERIFICATION_REQUIRED', 'VERIFIED', 'UNDER_REVIEW', 'DELETION_SCHEDULED']`.
   - Once the request transitions to `PROCESSING` or `COMPLETED`, cancellation is rejected with HTTP `400 DELETION_ALREADY_EXECUTED`.
   - Cancellation restores user status to `ACTIVE` and records a permanent entry in `legal_audit_events`.

---

## 5. Cold Backup Handling & Suppression Registers

1. **Backup Retention Reality:**
   - Database backups (Cloudflare D1 snapshots and cold cloud archives) are immutable and cannot be surgically modified on a row-by-row basis.
   - Cold backups expire and rotate out on a rolling 30-day lifecycle.
2. **Restoration Suppression Protocol:**
   - In the event of a disaster recovery database restoration, an automated `post-restore-suppression` migration cross-references the external `account_deletion_requests` ledger and re-applies tombstoning and purging across any revived accounts.

---

## 6. Automated Test Evidence

The account deletion lifecycle is thoroughly verified across Worker, Admin Web, and Flutter test suites:

- `✔ POST /api/legal/account-deletion-requests creates SUBMITTED ticket` (Passed in 21ms)
- `✔ Duplicate active deletion request returns 409 CONFLICT` (Passed in 6ms)
- `✔ User can cancel pending deletion during grace period` (Passed in 14ms)
- `✔ Cancellation fails once deletion status is COMPLETED` (Passed in 7ms)
- `✔ PIXMINT BOT sessions and messages are completely purged on execution` (Passed in 19ms)
- `✔ User profile is tombstoned to 'Deleted User'` (Passed in 15ms)
- `✔ Completed CAD drawings and invoice records remain intact` (Passed in 18ms)

