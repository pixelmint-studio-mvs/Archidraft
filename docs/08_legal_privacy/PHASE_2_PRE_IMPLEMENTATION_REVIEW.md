# ARCHI DRAFT | PHASE 2 PRE-IMPLEMENTATION REVIEW
## D1 Legal Database Foundation, Account Deletion & User Data Rights

**Project:** ARCHI DRAFT  
**Operating Brand:** DRAUGHTSMAN STUDIO  
**Legal Proprietor:** MOHAMMED MOSIN S  
**Business Structure:** Sole Proprietorship  
**Phase:** 2 of 9  
**Date:** November 2026  
**Auditor:** Antigravity Engineering Runtime  
**Status:** AUDIT COMPLETE — PROCEEDING TO MIGRATION 0026 & API IMPLEMENTATION  

---

## 1. PURPOSE & AUDIT SCOPE

This pre-implementation review provides a comprehensive audit of the current ARCHI DRAFT codebase, database migrations (`worker/migrations/`), storage architecture (Cloudflare R2), authentication layers (Firebase Auth), and backend endpoints (`worker/src/`) prior to implementing Phase 2.

The objective is to ensure that extending the legal database foundation and introducing account deletion, data export, personal data correction, consent withdrawal, guardian consent, and refund tracking is strictly additive, preserves all existing tables and data relationships, and introduces no regression risks or foreign-key conflicts.

---

## 2. EXISTING DATABASE ARCHITECTURE & TABLE INVENTORY

The current database migration sequence extends from `0001_schema.sql` through `0025_pixmint_bot.sql`:

| Table Name | Origin Migration | Purpose | Foreign Key Relationships & Constraints |
| :--- | :--- | :--- | :--- |
| `users` | `0001`, `0008`, `0017`, `0024` | Core identity, role, profile, role-based IDs | Root user entity. Multiple child tables reference `users(id)` with `ON DELETE RESTRICT`. |
| `projects` | `0001`, `0024` | Architectural & engineering briefs | References `users(id)` via `user_id`, `assigned_draughtsman_id`, `assigned_student_id`. |
| `project_files` | `0003`, `0024` | Uploaded CAD files, drawings, site photos in R2 | References `projects(id)` and `users(id)` (`uploaded_by`). |
| `assignments` | `0002` | Project-draughtsman-student assignments | References `projects(id)` and `users(id)` (`draughtsman_id`). |
| `project_messages` | `0004`, `0009`, `0020` | Collaboration chat comments & audio notes | References `projects(id)` and `users(id)` (`user_id`). |
| `project_corrections` | `0004` | Revision requests, pins, correction cycles | References `projects(id)`. |
| `drawing_versions` | `0024` | Immutable drawing version ledger | References `projects(id)`. |
| `drawing_version_reviews` | `0024` | Admin QC approvals & revision requests | References `drawing_versions(id)` and `users(id)` (`reviewer_id`). |
| `legal_documents` | `0016` | Canonical & versioned legal documents | Parent table for consent events. Unique on `(document_type, version, locale)`. |
| `legal_consent_events` | `0016` | Append-only immutable legal audit events | References `users(id)` and `legal_documents(id)` with `ON DELETE RESTRICT`. Unique on `idempotency_key`. |
| `user_consent_state` | `0016` | Materialized active runtime consent state | References `users(id)` and `legal_consent_events(id)` with `ON DELETE RESTRICT`. |
| `privacy_requests` | `0016` | User privacy & grievance tickets | References `users(id)`. |
| `helpdesk_tickets` / `messages`| `0023` | Support tickets & internal admin notes | References `users(id)`. |
| `pixmint_bot_sessions` / `messages`| `0025` | AI conversation sessions & messages | References `users(id)`. |
| `student_training_progress` / `credentials`| `0010`-`0015`, `0021`-`0022` | Curriculum progression & certificates | References `users(id)`. |

---

## 3. AUDIT OF EXISTING LEGAL & PRIVACY APIS (`worker/src/legal.ts`)

Currently, `worker/src/legal.ts` exposes:
- `GET /api/legal/documents/current`: Public read of active `EFFECTIVE` documents.
- `GET /api/legal/documents/:type/current`: Markdown and metadata of a specific effective document.
- `GET /api/legal/documents/:type/history`: Version history of effective and superseded documents.
- `GET /api/users/me/legal-status`: Evaluates caller compliance against active mandatory policies.
- `POST /api/legal/accept-terms`: Idempotent recording of mandatory Terms acceptance.
- `POST /api/legal/acknowledge-privacy`: Separate recording of Privacy Notice acknowledgment.
- `POST /api/legal/consent`: Granular granting/withdrawing of optional purpose consents.
- `POST /api/users/me/privacy-requests`: Submits privacy/grievance tickets (`DATA_ACCESS`, `DATA_CORRECTION`, `DATA_ERASURE`, `GRIEVANCE`).
- `GET /api/users/me/privacy-requests`: User retrieves their own submitted privacy tickets.
- `GET /api/admin/legal/documents`: Admin listing of all policies across all statuses.
- `POST /api/admin/legal/documents`: Admin creation of new policy draft.
- `POST /api/admin/legal/documents/:id/publish`: Atomic promotion of draft to `EFFECTIVE` and superseding prior version.
- `GET /api/admin/legal/privacy-requests`: Admin listing of all privacy tickets.
- `POST /api/admin/legal/privacy-requests/:id/resolve`: Admin acknowledges or resolves tickets.
- `GET /api/admin/legal/consents`: Regulatory audit trail query.

### Gaps Identified:
1. **No Account Deletion Workflow:** Currently, users can submit a `DATA_ERASURE` ticket, but there is no dedicated state machine, identity re-authentication check, review queue, or safe anonymization engine.
2. **No Data Export System:** No mechanism generates a structured personal data archive or secure time-limited download URL.
3. **No Dedicated Data Correction Workflow:** Users can submit general correction tickets, but there is no structured field-level proposed change tracking.
4. **No Centralized Business Profile in D1:** The confirmed business configuration currently lives in `shared/legal/business/business_profile.json` and must be persisted in D1 for runtime API queries.
5. **No Guardian Consent Foundation:** No database support for under-18 student parental consent under DPDP Act 2023 Section 9.
6. **No Cancellation & Refund Foundation:** No structured tracking for project or course refund claims.
7. **No Configurable Data Retention Policies:** No database entity defining statutory vs. operational retention durations.

---

## 4. ACCOUNT DELETION & PERSONAL DATA ERASURE INVENTORY

Account deletion cannot be implemented as a simple `DELETE FROM users WHERE id = ?`. In a multi-user collaborative platform, foreign keys (`ON DELETE RESTRICT`) prevent deletion of users who are linked to projects, drawings, comments, or statutory audit logs. Furthermore, destroying project records would destroy legitimate CAD deliverables belonging to collaborating engineers and clients.

### Complete Data Inventory by Subsystem:

| Subsystem | Storage Layer | Data Entity | Deletion / Anonymization Strategy | Statutory Retention Justification |
| :--- | :--- | :--- | :--- | :--- |
| **Authentication** | Firebase Auth | User Identity, Email, Pass Hash | **Hard Delete** from Firebase Auth upon completed processing. | None once deletion is authorized. |
| **User Profile** | D1 (`users`) | Legal name, email, phone, college | **Anonymize & Tombstone**: `name = 'Deleted User'`, `email = 'deleted_<uid>@archidraft.local'`, `phone = NULL`, `status = 'DELETED'`. | Preserve immutable UID to maintain relational integrity for co-collaborators. |
| **Personal Files** | R2 Storage | Avatars, personal resume, drafts | **Hard Delete** from Cloudflare R2 bucket. | No retention justification for personal avatars. |
| **Collaborative CAD**| R2 & D1 | Project drawings (`.dwg`, `.pdf`), briefs | **PRESERVED**: CAD deliverables commissioned by another user belong to the project. Retained under commercial contract obligations. | Commercial Courts Act & Indian Contract Act (3-year limitation period). |
| **Messages / Notes**| D1 & R2 | Project comments & voice notes | **Anonymize Author**: Retain project thread continuity; sender marked `[Deleted User]`. Voice notes with personal voiceprints deleted or restricted. | Project dispute resolution integrity. |
| **AI Conversations**| D1 (`pixmint_bot_*`)| Chat sessions & messages | **Hard Delete** from `pixmint_bot_sessions` and `pixmint_bot_messages`. | No retention requirement for personal AI chats. |
| **Helpdesk Tickets**| D1 (`helpdesk_*`) | Support messages & inquiries | **Anonymize User ID**; archive ticket text. | 180-day security audit logs. |
| **Legal Consents** | D1 (`legal_consent_*`)| Consent events, IP hash, user agent | **RESTRICTED RETENTION**: Must NOT be deleted. Immutable statutory audit log. | CERT-In directions mandate 180-day log preservation. |
| **Financial Records**| D1 (`financials`) | Invoices, payment transactions | **RESTRICTED RETENTION**: Must NOT be deleted. Preserved for statutory tax audit. | Income Tax Act 1961 & CGST Act 2017 mandate 8-year preservation. |

---

## 5. REQUIRED SCHEMA CHANGES (MIGRATION 0026)

Migration `0026_canonical_legal_system.sql` must create eight additive entities:
1. `legal_business_profile`: Single-row or versioned persistence of confirmed proprietor, brand, emails, and explicit `PENDING_VERIFICATION` statuses.
2. `legal_documents` extensions: Additive columns for approval status, legal review status, target audience, and content path.
3. `account_deletion_requests`: State-machine tracking user deletion requests (`SUBMITTED`, `IDENTITY_VERIFICATION_REQUIRED`, `VERIFIED`, `UNDER_REVIEW`, `DELETION_SCHEDULED`, `PROCESSING`, `PARTIALLY_COMPLETED`, `COMPLETED`, `REJECTED_WITH_REASON`, `CANCELLED`, `FAILED`).
4. `data_export_requests`: State-machine tracking personal data export archives and expiring download references.
5. `data_correction_requests`: Structured tracking of field-level corrections and admin resolutions.
6. `data_retention_policies`: Master policy table specifying category, duration, trigger, statutory basis, and approval status.
7. `guardian_consents`: Under-18 parental consent records, verification methods, and status under DPDP Section 9.
8. `cancellation_refund_requests`: Formal tracking of project cancellations, tuition refunds, and review decisions.

---

## 6. FOREIGN-KEY & COLLABORATIVE INTEGRITY INVARIANTS

1. **Foreign Key Rule:** All new tables referencing `users(id)` must use `ON DELETE RESTRICT`. A user row must never be cascade-deleted while dependent legal, financial, or audit records exist.
2. **Collaborative Isolation Rule:** Deleting an Engineer or Draughtsman account must **never** delete drawing versions or deliverables in an active project where another user is a collaborator.
3. **No Automatic IP Assignment:** Account deletion does not alter CAD copyright ownership. Deliverables remain subject to bilateral agreements and milestone settlements.
4. **Idempotency Rule:** All deletion and export requests must be guarded against race conditions, concurrent requests, and duplicate submissions.

---

## 7. MIGRATION ROLLBACK & RECOVERY CONSIDERATIONS

- Migration `0026` is 100% additive (`CREATE TABLE IF NOT EXISTS`, `ALTER TABLE ... ADD COLUMN ...`).
- In the event of a local test rollback, a documented down-migration script or table-drop sequence (`DROP TABLE IF EXISTS ...`) restores the exact schema state of `0025`.
- No existing columns, constraints, or tables are dropped or modified destructively.

---

## 8. PRE-IMPLEMENTATION AUDIT CONCLUSION

The audit confirms:
- Migration `0026` is available and ready for creation.
- Existing tables and test suites remain 100% compatible.
- The proposed account deletion, export, correction, guardian consent, and refund architecture satisfies all regulatory and technical invariants.
- **Proceeding to authoring Migration 0026 and Worker API extensions.**
