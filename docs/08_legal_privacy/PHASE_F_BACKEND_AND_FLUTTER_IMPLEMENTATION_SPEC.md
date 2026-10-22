# ARCHI DRAFT — LEGAL & PRIVACY SYSTEM: BACKEND & FLUTTER IMPLEMENTATION SPECIFICATION
**Document ID:** AD-SPEC-LEGAL-001  
**Version:** 1.0.0-PROVISIONAL  
**Date:** 2026-10-22  
**Jurisdiction:** India (Information Technology Act 2000, IT SPDI Rules 2011, Digital Personal Data Protection Act 2023)  
**Status:** IMPLEMENTED & VERIFIED LOCALLY (Pre-Production / Staging Candidate)

---

## 1. Executive Summary

This specification documents the complete, implemented, and locally tested Legal, Privacy, Consent, and User Protection subsystem across the ARCHI DRAFT Cloudflare Worker backend, D1 database schema, and Flutter application.

All changes were implemented under strict zero-regression constraints, preserving existing project structures, commercial workflows, drawing versions, and authentication middleware.

---

## 2. Database Schema (Migration 0016)

The subsystem is founded on four normalized tables executed via `worker/migrations/0016_legal_system.sql`:

### 2.1 Table Inventory

| Table Name | Purpose | Primary Key | Foreign Key Rules |
| :--- | :--- | :--- | :--- |
| `legal_documents` | Versioned store of legal policies and agreements. | `id TEXT` | None |
| `legal_consent_events` | Append-only immutable regulatory audit ledger. | `id TEXT` | `user_id` $\to$ `users(id)` `RESTRICT`<br>`document_id` $\to$ `legal_documents(id)` `RESTRICT` |
| `user_consent_state` | Materialized active consent state for runtime authorization. | `id TEXT` | `user_id` $\to$ `users(id)` `RESTRICT`<br>`last_event_id` $\to$ `legal_consent_events(id)` `RESTRICT` |
| `privacy_requests` | Statutory data rights & grievance tickets. | `id TEXT` | `user_id` $\to$ `users(id)` `RESTRICT` |

### 2.2 Key Constraints & Indexes
1. **Singular Effective Version Rule:**
   Partial unique index enforcing that exactly one document per `(document_type, locale)` can have `status = 'EFFECTIVE'`:
   ```sql
   CREATE UNIQUE INDEX idx_single_effective_doc 
   ON legal_documents(document_type, locale) 
   WHERE status = 'EFFECTIVE';
   ```
2. **Consent Event Idempotency:**
   Unique index on `idempotency_key` preventing duplicate affirmative event records:
   ```sql
   CREATE UNIQUE INDEX idx_consent_events_idempotency 
   ON legal_consent_events(idempotency_key);
   ```
3. **User State Uniqueness:**
   Enforces a single current status per `(user_id, consent_type, purpose_tag)`:
   ```sql
   CREATE UNIQUE INDEX idx_user_consent_state_unique 
   ON user_consent_state(user_id, consent_type, purpose_tag);
   ```
4. **Referential Integrity:**
   All foreign keys strictly enforce `ON DELETE RESTRICT` with `PRAGMA foreign_keys = ON;`, preventing accidental or cascading destruction of regulatory audit records.

---

## 3. Worker Backend REST API Catalog

The backend is implemented in `worker/src/legal.ts` and mounted via `worker/src/index.ts`.

### 3.1 Public Read Endpoints (No Auth Required)
- `GET /api/legal/documents/current`: Returns summary metadata of all active `EFFECTIVE` documents.
- `GET /api/legal/documents/:type/current?locale=en-IN`: Returns full markdown content and metadata of active effective document. Returns `404` with `code: 'NO_EFFECTIVE_VERSION'` if none is effective.
- `GET /api/legal/documents/:type/history?locale=en-IN`: Returns historical versions (`EFFECTIVE` and `SUPERSEDED`). DRAFT documents are strictly excluded.

### 3.2 Authenticated User Endpoints (Bearer JWT Required)
- `GET /api/users/me/legal-status`: Evaluates caller compliance against active mandatory documents.
  Returns:
  ```json
  {
    "userId": "usr-123",
    "termsAccepted": true,
    "reacceptanceRequired": false,
    "acceptedTermsVersion": "1.0.0",
    "latestTermsVersion": "1.0.0",
    "privacyNoticeAcknowledged": true,
    "optionalConsents": {
      "MARKETING_COMMUNICATIONS": false,
      "PORTFOLIO_SHOWCASE": true
    },
    "requiresAction": false,
    "hasEffectiveTerms": true,
    "missingMandatoryDocs": false
  }
  ```
- `POST /api/legal/accept-terms`: Idempotently records affirmative acceptance of mandatory Platform Terms. Validates that target document is `EFFECTIVE`. Appends event to `legal_consent_events` and upserts `user_consent_state`.
- `POST /api/legal/acknowledge-privacy`: Records review and acknowledgment of Privacy Policy.
- `POST /api/legal/consent`: Grants or withdraws granular, purpose-specific optional consent (`purpose`, `granted: true|false`). Appends event to audit log and updates state.
- `POST /api/users/me/privacy-requests`: Submits a statutory data access, correction, erasure, or grievance request. Validates input and sets operational target date.
- `GET /api/users/me/privacy-requests`: Returns caller's own submitted requests. Strict user-isolation is enforced server-side.

### 3.3 Administrative Endpoints (`role IN ('ADMIN', 'STUDIO_ADMIN')`)
- `GET /api/admin/legal/documents`: Lists all documents including drafts.
- `POST /api/admin/legal/documents`: Creates new policy draft.
- `POST /api/admin/legal/documents/:id/publish`: Atomically supersedes prior effective version and promotes target document.
- `GET /api/admin/legal/privacy-requests`: Global request dashboard with status filtering.
- `POST /api/admin/legal/privacy-requests/:id/resolve`: Updates resolution notes and status (`ACKNOWLEDGED`, `RESOLVED`, `REJECTED`).
- `GET /api/admin/legal/consents`: Paginated regulatory audit log of consent events.

---

## 4. Flutter Application Integration

Implemented in `lib/src/features/legal/`:

### 4.1 Architecture Components
- **Domain:** `LegalDocument`, `UserLegalStatus`, `PrivacyRequest`.
- **Repository:** `LegalRepository` consuming `ApiClient`.
- **State Management:** Riverpod providers (`legalRepositoryProvider`, `userLegalStatusProvider`, `effectiveDocumentProvider`, `myPrivacyRequestsProvider`).
- **Routing:** GoRouter in `lib/src/core/router/app_router.dart`:
  - Listens to `userLegalStatusProvider` via `_GoRouterAuthNotifier`.
  - When `legalStatus.requiresAction == true` and `missingMandatoryDocs == false`: Redirects session to `/legal/onboarding`.
  - Unbundled optional consents default to OFF and do not block mandatory onboarding.
  - Recovers gracefully when mandatory documents are missing (`missingMandatoryDocs: true`) by presenting a maintenance notification rather than an application crash or infinite redirect loop.

### 4.2 Presentation Screens
- `LegalOnboardingScreen`: First-entry and mandatory re-acceptance flow with expandable document viewer, mandatory Terms checkbox, Privacy Notice acknowledgment, and independent optional consent switches.
- `LegalCenterScreen`: Accessible via profile screen. Tabbed interface for platform policies, real-time consent toggles, and data rights submission/tracking.
- `PrivacyRequestDialog`: Modal for submitting statutory requests with automatic target dates.

---

## 5. Verification & Test Evidence

### 5.1 Cloudflare Worker Backend Tests
- **Command:** `node --test worker/test/backend_authorization.test.mjs worker/test/admin_student_contract.test.mjs worker/test/cross_user_isolation_f1.test.mjs worker/test/legal_privacy_authorization.test.mjs`
- **Result:** **184 / 184 tests passed** (0 failed, duration ~483ms).
- **TypeScript Check:** `npm run typecheck` in `worker/` passed with 0 errors.

### 5.2 Flutter Client Tests
- **Command:** `flutter test`
- **Result:** **311 / 311 tests passed** (0 failed, duration ~19s).
- **Static Analysis:** `flutter analyze` passed with **0 issues**.

---

## 6. Launch-Readiness Limitations (Unresolved Business & Legal Items)

The local technical implementation is complete and verified. However, **the system is not legally or commercially ready for production** until the following open items are resolved by the business owner and qualified Indian legal counsel:

1. **Student Eligibility & Minors:**
   Safeguards for users under 18 and formal parental consent verification mechanisms under DPDP Act Section 9 remain subject to legal review.
2. **CAD / Drawing Intellectual Property:**
   Contractual ownership, commercial licensing, and moral rights for architectural drawings remain provisional placeholders.
3. **Sole-Proprietorship Identity:**
   Proprietor legal name, registered trade address, and verified corporate identifiers remain unconfirmed placeholders.
4. **Grievance Redressal Officer:**
   Official appointment and published email/phone contact channels under IT SPDI Rule 5(9) remain provisional.
5. **Data Retention & Destruction Schedules:**
   Specific retention periods for CAD binaries and user account records require qualified operational and legal review.
