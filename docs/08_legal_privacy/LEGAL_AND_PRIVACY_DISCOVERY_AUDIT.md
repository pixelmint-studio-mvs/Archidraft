# ARCHI DRAFT — MASTER LEGAL, PRIVACY, CONSENT & USER PROTECTION AUDIT
**DOCUMENT STATUS: DRAFT FOR REVIEW ONLY — PRE-MERGE READINESS AUDIT**
**TARGET MARKET: INDIA**
**PARENT BRAND: DRAUGHTSMAN STUDIO (https://www.draughtsmanstudio.com)**
**WORKSPACE: D:\PROJECT\Archidraft-integration-workspace**
**BRANCH: integration/engineer-draughtsman (HEAD: 8f753a97315c59c33eb1b0ad1578951434ae368e)**
**DATE: OCTOBER 2026**

---

## 1. EXECUTIVE SUMMARY (DELIVERABLE 1)

### 1.1 Context and Scope
Archi Draft is an architectural and engineering workflow coordination platform developed under Draughtsman Studio for the Indian market. The platform coordinates complex project workflows, architectural and structural drawings (DWG, DXF, PDF), communications, and professional training between four primary panels:
1. **Client / Engineer Panel**
2. **Draughtsman Panel**
3. **Student Panel**
4. **Admin Panel**

This discovery audit evaluates the existing codebase against the **Friend's Master Directive ("ARCHI DRAFT — MASTER LEGAL, PRIVACY, CONSENT & USER PROTECTION SYSTEM")** and establishes pre-merge readiness before integrating into `develop`.

### 1.2 Core Audit Findings
1. **Zero Legal & Privacy Frontend Elements:** Across the entire Flutter application (`lib/`), there is currently no legal center, no "Before You Get Started" onboarding screen, no Terms & Conditions acceptance checkbox, no Privacy Notice delivery mechanism, no privacy settings, and no grievance submission portal.
2. **Zero Legal & Consent Backend Models:** In the Cloudflare Worker backend (`worker/src/index.ts`) and Cloudflare D1 database (migrations `0001` through `0015`), there are no tables or endpoints for legal document versioning, terms acceptance audit trails, consent tracking, or user data rights requests.
3. **Absence of Account Lifecycle & Deletion API:** Only single-file deletion exists (`DELETE /api/projects/:projectId/files/:fileId`). No account deletion endpoint (`DELETE /api/users/me`) or automated data erasure workflow exists.
4. **Unregulated Student Registration (Child Privacy Risk):** The registration screen (`register_screen.dart`) and profile provisioning (`provision_profile_screen.dart`, `POST /api/users`) allow open self-service registration for the `STUDENT` role with no age gate, birthdate validation, or parental consent workflow. Under Section 9 of the Digital Personal Data Protection Act, 2023 (DPDP Act) and the Indian Contract Act, 1872, processing minors' personal data and accepting contractual terms without verifiable parental consent creates serious legal and regulatory non-compliance risks.
5. **Technical Data Isolation Is Strong:** Following Phase F1 and F1.1 security remediations, cross-user data isolation, server-side authorization in Cloudflare Workers, R2 file download access control, and least-privilege checks are sound and verifiable. The platform provides a secure foundation upon which to layer the required legal and consent architecture.

---

## 2. REQUIREMENT TRACEABILITY MATRIX (DELIVERABLE 2)

| Sec | Directive Requirement | Implementation Evidence & File Reference | Status | Severity | Required Next Action | Dependencies | Approval Gate |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- | :---: |
| **A** | **Shared Legal Architecture** across all 4 panels | Zero legal components in `lib/src/`. No shared legal repository or store. | **FAIL** | **HIGH** | Create unified `lib/src/features/legal/` feature with shared state, models, and UI. | Router (`app_router.dart`), Theme | Technical & Product |
| **B** | **First-Entry Onboarding** ("Before You Get Started" screen) | `app_router.dart:58-95` redirects authenticated users directly to role dashboards (`/engineer/projects`, `/draughtsman/studio`, `/student/dashboard`). Draughtsman onboarding (`draughtsman_onboarding_screen.dart:18`) only prompts for name/mobile. | **FAIL** | **HIGH** | Implement `LegalOnboardingScreen` gated in `app_router.dart` for first-time or re-acceptance users. | Router, Legal Models, User Profile | Product & Legal |
| **C** | **Consent & Acceptance Separation** (Unchecked box for Terms; Notice acknowledged; separate optional consent) | `register_screen.dart:73-290` has zero checkboxes or legal notices. Form directly submits credentials to auth controller. | **FAIL** | **HIGH** | Introduce explicit unchecked checkbox for Terms; separate notice acknowledgment and optional permissions. | Auth flow, Register UI | Legal Review |
| **D** | **Role-Specific Onboarding Responsibilities** (Engineer, Draughtsman, Student, Admin) | No role-specific legal disclosures exist in `lib/` or `worker/`. | **FAIL** | **MEDIUM** | Author role-specific clauses in shared legal repository and display conditionally by `UserRole`. | Role Provider, Legal Store | Product & Legal |
| **E.1** | **Privacy Policy** (20 mandatory Indian DPDP/IT Act clauses) | Zero Privacy Policy text or document in codebase or `docs/`. | **FAIL** | **CRITICAL** | Draft `docs/08_legal_privacy/PRIVACY_POLICY_DRAFT.md` using verified business details. | Business details | Founder & Legal Counsel |
| **E.2** | **Terms & Conditions** (21 mandatory clauses, eligibility, workflow, IP) | Zero Terms & Conditions text or document in codebase or `docs/`. | **FAIL** | **CRITICAL** | Draft `docs/08_legal_privacy/TERMS_AND_CONDITIONS_DRAFT.md`. | Business model & SLA | Founder & Legal Counsel |
| **E.3** | **Data Retention & Deletion Notice** (Categories, timelines, statutory exceptions) | No retention notice exists. `0001_schema.sql` lacks retention policies. | **FAIL** | **HIGH** | Draft `docs/08_legal_privacy/DATA_RETENTION_AND_DELETION.md`. | Retention rules | Legal Counsel |
| **E.4** | **Acceptable Use Policy** (Prohibited conduct, unauthorized extraction, security) | No acceptable use policy exists. | **FAIL** | **MEDIUM** | Draft `docs/08_legal_privacy/ACCEPTABLE_USE_POLICY.md`. | Security policy | Legal Counsel |
| **E.5** | **IP & Document Handling Policy** (Drawing ownership, license to host, moral rights) | No IP policy exists. Drawing uploads are stored in R2 without an explicit user grant/license. | **FAIL** | **HIGH** | Draft `docs/08_legal_privacy/INTELLECTUAL_PROPERTY_POLICY.md`. | Copyright Act 1957 | Founder & Legal Counsel |
| **E.6** | **Role-Aware FAQ** (Verified application behavior only) | No FAQ screens or assets exist in `lib/`. | **FAIL** | **LOW** | Draft verified FAQ in `docs/08_legal_privacy/FAQ_CONTENT.md`. | Feature audit | Product Owner |
| **E.7** | **Support & Grievance Policy** (Grievance officer details, SLA, escalation) | No grievance policy or designated contacts in the app. | **FAIL** | **CRITICAL** | Draft `docs/08_legal_privacy/GRIEVANCE_AND_SUPPORT_POLICY.md`. | Verified contact details | Founder / Operations |
| **F** | **Indian Legal Applicability Review** (DPDP 2023, IT Act 2000, CERT-In, Contract Act) | No legal compliance matrix exists. Codebase has no DPDP notice/consent structure. | **PARTIAL** | **HIGH** | Conduct formal legal assessment matrix in `docs/08_legal_privacy/LEGAL_COMPLIANCE_OVERVIEW.md`. | External statutes | Qualified Indian Counsel |
| **G** | **Privacy by Design** (Data minimization, server auth, least privilege) | Server-side auth in `worker/src/index.ts:485-520` enforces project isolation; `auth.ts` validates JWTs; zero credentials in UI (`profile_screen_test.dart:295`). However, no field minimization notice in `profile_form.dart`. | **PARTIAL** | **MEDIUM** | Add inline field explanations to `profile_form.dart` and `provision_profile_screen.dart`. | Form UI | Engineering |
| **H** | **Centralized Legal Document Model** (Versioned, auditable, immutable) | No legal tables in D1 migrations `0001`-`0015`. | **FAIL** | **HIGH** | Design D1 migration `0016_legal_system.sql` with `legal_documents` table. | Cloudflare D1 | Architecture & Engineering |
| **I** | **Acceptance & Consent Records** (Tamper-proof, server-recorded, idempotent) | No acceptance/consent audit table in D1 or routes in Worker. | **FAIL** | **HIGH** | Add `legal_consent_records` table and `POST /api/legal/accept` route in Worker. | Cloudflare D1 & Worker | Architecture & Engineering |
| **J** | **Legal Document Version Changes** (Audit trail, re-acceptance criteria) | Not implemented. | **FAIL** | **MEDIUM** | Build backend version-checking logic and client re-acceptance gate. | Migration, Worker | Architecture & Engineering |
| **K** | **Account Deletion & Privacy Rights** (Access, correction, erasure, grievance) | Profile editing exists (`PATCH /api/users/me`), but deletion (`DELETE /api/users/me`) and request tracking are absent. | **FAIL** | **HIGH** | Add `privacy_requests` table, request submission endpoint, and two-stage account deletion workflow. | D1, Worker, Storage | Product, Ops & Legal |
| **L** | **Student and Child-User Privacy** (Age verification, parental consent, no profiling) | Open registration in `register_screen.dart` with role `STUDENT`. DOB in `profile_form.dart:73` has no validation or minor guard. | **FAIL** | **CRITICAL** | Require minimum age verification during registration; block unapproved minors or implement parental consent protocol. | Auth flow | Founder & Legal Counsel |
| **M** | **Admin Legal Management** (Version publishing, audit review, compliance export) | External Admin UI is outside workspace. Worker has no legal management routes. | **NOT YET VERIFIED** | **MEDIUM** | Implement backend admin routes `GET /api/admin/legal/consents` and `POST /api/admin/legal/publish`. External UI remains unverified. | External Admin UI | Admin Integration Phase |
| **N** | **FAQ & Support Accuracy** (Verified behaviors, real contacts) | No FAQ or support links in UI. | **FAIL** | **LOW** | Connect role-aware FAQ and real support emails into client settings/help menu. | Support channels | Operations |
| **O** | **Shared Design System & Accessibility** (AppColors, Typography, Spacing, Breakpoints) | Design tokens well established (`AppColors`, `AppTypography`, `AppSpacing`, `AppBreakpoints`). | **PASS** | **LOW** | Ensure all future legal UI components strictly use established tokens and semantic labels. | Design System | Engineering |

---

## 3. DATA PROCESSING INVENTORY (DELIVERABLE 3)
*Based strictly on verified repository and database evidence.*

| 1. Data Category | 2. Actual Purpose | 3. Source | 4. Storage Location | 5. Authorized Access Roles | 6. External Recipients / Processors | 7. Retention / Deletion Behavior | 8. Relevant Security Controls | 9. Related Legal Document Req | 10. Unknowns & Business-Owner Questions |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **User Identity & Auth** | Authentication, role assignment, account security | User input via `register_screen.dart` or Firebase Auth | Firebase Auth + Cloudflare D1 `users` (`id`, `email`, `role`, `created_at`) | User (own), `ADMIN`, `STUDIO_ADMIN` | Firebase (Google Cloud), Cloudflare | Retained indefinitely while account active. No deletion workflow currently implemented. | Firebase JWT tokens, SHA-256 password hashing by Firebase, Worker JWT validation | Privacy Policy (Sec 3, 7), Terms & Conditions (Sec 2, 3) | What is the statutory retention requirement for tax/billing vs. inactive accounts? |
| **Personal Profile Details** | Professional communication, invoicing, identification | User input via `profile_form.dart`, `provision_profile_screen.dart` | Cloudflare D1 `users` (`name`, `mobile`, `date_of_birth`, `address`, `company_name`, `college_name`, `qualification`) | User (own), `ADMIN`, `STUDIO_ADMIN` | Cloudflare Workers / D1 | Retained until updated via `PATCH /api/users/me`. No erasure mechanism. | Server-side role authorization (`worker/src/index.ts:161`) | Privacy Policy (Sec 3, 6, 17), Retention Notice | Is `date_of_birth` strictly required for engineers/draughtsmen, or only students? |
| **Project Specifications** | Workflow tracking, drawing creation, drafting management | User input via `project_form_screen.dart` | Cloudflare D1 `projects` (`project_name`, `project_address`, `drawing_name`, `drawing_type`, `project_area`, `status`) | Client/Engineer (owner), Assigned Draughtsman, Assigned Student, Admin | Cloudflare D1 | Retained with project record. Cascade delete if project deleted by owner/admin. | Strict cross-user isolation (`canUserAccessProject`, `worker/src/index.ts:485`) | Terms & Conditions (Sec 5, 8), IP Policy | Can an Engineer delete a project after it has been completed and invoiced? |
| **Drawings & Attachments** | Technical drawing production, CAD review, corrections | User file uploads (`.dwg`, `.dxf`, `.pdf`, `.png`, `.jpg`, `.zip`) | Cloudflare R2 bucket (`STORAGE`) + metadata in D1 `files` table | Uploader, Project Owner, Assigned Draughtsman/Student, Admin | Cloudflare R2 | Individual files deletable via `DELETE /api/projects/:projectId/files/:fileId` subject to role/category rules. | Server-mediated download (`/api/files/:fileId/download`), R2 object keys unexposed | IP & Document Handling Policy, Acceptable Use | Who retains copyright to CAD derivative revisions under the platform agreement? |
| **Collaboration Messages & Audio** | Project coordination, correction instructions | User chat input & recorded audio notes (`.webm`, `.mp4`, `.wav`) | Cloudflare D1 `project_messages` + Cloudflare R2 for audio attachments | Project members (Owner, Assigned Draughtsman/Student, Admin) | Cloudflare D1 & R2 | Retained with project record. Cascade delete on project removal. | Role check on message post/get (`worker/src/index.ts:1860`) | Privacy Policy (Sec 8), Acceptable Use | Are audio voice notes transcribed or retained permanently as part of audit records? |
| **Financial & Invoicing Data** | Project valuation, milestone billing, payment tracking | Admin input via `financials_screen.dart` | Cloudflare D1 `project_financials`, `invoices`, `payments` | Project Client/Engineer, `STUDIO_ADMIN` | Cloudflare D1. *(Payment gateway NOT yet integrated)* | Retained for financial recordkeeping. | Admin-only mutation (`worker/src/index.ts:2236`) | Terms & Conditions (Sec 10), Privacy Policy | What payment gateway (Razorpay, Cashfree, Stripe) will be introduced in production? |
| **Student Academic & Training Data** | Curriculum progression, skill verification, certification | Training modules, lesson tests, faculty evaluation dialogs | Cloudflare D1 `student_training`, `student_lessons`, `evaluations`, `student_credentials` | Student (own), Admin/Instructor, Public (via verification token) | Cloudflare D1, R2 for public certificate artifacts | Retained for credential authenticity. | Public verification scoped to unique token (`0015_student_credentials_verification.sql`) | Student Privacy Policy, Terms & Conditions | Are student training records shared with prospective employer firms? |
| **Audit & Activity Logs** | Operational security, dispute resolution, traceability | Worker system actions (`FILE_UPLOADED`, `FILE_DELETED`, `PROJECT_SUBMITTED`, etc.) | Cloudflare D1 `activity_logs` | Admin, System internal | Cloudflare D1 | Permanent record linked to `project_id`. | Tamper-proof, written only by Worker business logic | Privacy Policy (Sec 13, 14), CERT-In Compliance | Does log retention comply with the CERT-In 180-day retention mandate? |

---

## 4. GAP ANALYSIS AND PRIORITIZED ROADMAP (DELIVERABLE 4)

### 4.1 Identified Architecture Gaps
1. **Missing D1 Tables:** Need `legal_documents`, `legal_consent_records`, and `privacy_requests`.
2. **Missing Backend Endpoints:** Need routes for fetching active legal documents, submitting affirmative terms acceptance/notice acknowledgment, creating privacy/grievance requests, and triggering account deletion.
3. **Missing Routing Gate in Flutter:** `app_router.dart` lacks an interception rule checking whether an authenticated user has accepted the latest mandatory Terms version.
4. **Missing Shared UI Components:** Need `LegalOnboardingScreen`, `LegalCenterScreen`, `MarkdownDocumentViewer`, and privacy settings in `ProfileScreen`.
5. **Child User Vulnerability:** Student registration lacks an eligibility/age gate.

### 4.2 Phased Implementation Roadmap

```
Phase B: Legal Applicability & Business Verification (Current)
   │
   ▼
Phase C: Draft Legal Documentation (7 Core Documents in docs/08_legal_privacy/)
   │
   ▼
Phase D: Shared Architecture & Database Models (D1 Migration 0016_legal_system.sql)
   │
   ▼
Phase E: Backend Worker APIs (Legal CMS, Consent Audit, Data Rights, Account Lifecycle)
   │
   ▼
Phase F: Shared Flutter UI Components (LegalOnboardingScreen, LegalCenter, Consent Widgets)
   │
   ▼
Phase G: Panel Integration (Engineer, Draughtsman, Student, Admin)
   │
   ▼
Phase H: Comprehensive Automated Testing (Flutter Widgets, Worker Authorization, Audit Tests)
   │
   ▼
Phase I: Business-Owner Verification & Qualified Indian Legal Review
   │
   ▼
Phase J: Production Release Gating (Approved Documents, Real Contacts, Zero Placeholders)
```

#### Detailed Phase Breakdown
- **Phase B — Legal & Business Requirements (Immediate):**
  - Verify business entity name, registered office address, support email, and Grievance Officer details.
  - Formulate legal applicability matrix for DPDP Act 2023, IT Act 2000, and CERT-In directions.
- **Phase C — Legal Documentation Drafting:**
  - Create markdown drafts under `docs/08_legal_privacy/` with clear `[DRAFT - REQUIRES LEGAL REVIEW]` tags and placeholders for unverified business details.
- **Phase D — Shared Architecture & Database Models:**
  - Create migration `worker/migrations/0016_legal_system.sql` defining:
    - `legal_documents`: `(id, document_type, version, title, content, effective_at, published_at, status, is_mandatory, created_at)`
    - `legal_consent_records`: `(id, user_id, document_type, document_version, action_type, ip_hash, user_agent, recorded_at)`
    - `privacy_requests`: `(id, user_id, request_type, details, status, created_at, resolved_at, resolution_notes)`
- **Phase E — Backend Worker Implementation:**
  - `GET /api/legal/documents/current`: Returns published versions and mandatory status.
  - `GET /api/legal/documents/:type`: Returns document content.
  - `POST /api/legal/accept`: Securely records affirmative user acceptance with idempotency.
  - `GET /api/users/me/legal-status`: Returns acceptance status for the authenticated user.
  - `POST /api/users/me/privacy-requests`: Submits data rights or grievance request.
  - `POST /api/users/me/delete-account`: Initiates verified two-step account deletion.
- **Phase F — Shared Flutter UI Components:**
  - Implement `LegalOnboardingScreen` ("Before You Get Started") with role-specific clauses and an active, unselected checkbox for Terms.
  - Implement `LegalCenterScreen` with tabbed reading view for all 7 documents.
  - Implement `DataRightsDialog` in `ProfileScreen`.
- **Phase G — Panel-Specific Integration:**
  - Update `app_router.dart` redirect logic to check `legalStatusProvider`. If terms not accepted, route to `/onboarding/legal`.
  - Add "Legal & Privacy" tile to `AppTopBar` or drawer across all panels.
- **Phase H — Automated Testing:**
  - Flutter widget tests for `LegalOnboardingScreen` (verifying button is disabled until checkbox is checked).
  - Worker tests verifying that acceptance records cannot be spoofed, tampered with, or created without authentication.
  - Regression verification of existing Phase F1/F1.1 cross-user data isolation tests.
- **Phase I — Business-Owner & Legal Review:**
  - Founder signs off on business policies. Qualified Indian legal counsel reviews clauses.
- **Phase J — Production Release:**
  - Deploy migration to production D1, publish finalized document records, remove all placeholders.

---

## 5. PRE-MERGE GATE FOR `develop` (DELIVERABLE 5)

### 5.1 Hard Technical Blockers (Must Be Fixed Before Merging into `develop`)
1. **Unregulated Student Registration (Minor Protection):** Self-service registration must either incorporate an age confirmation gate (18+) or restrict student access until the minor/parental consent architecture is deployed.
2. **Missing Legal Onboarding Interception:** Authenticated users currently bypass all legal acknowledgments and enter the workspace directly.

### 5.2 Business-Owner Decision Blockers (Requires Founder Input)
1. **Legal Entity Details:** Official registered entity name, registered office address, CIN/LLPIN.
2. **Designated Grievance Officer:** Name, designation, official grievance email address, and physical contact address as mandated by IT (SPDI) Rules 2011 and DPDP Act 2023.
3. **Operational Support Channels:** Dedicated support email (`support@draughtsmanstudio.com` or verified equivalent).
4. **Child-User Policy:** Decision on whether Archi Draft permits users under 18 years of age (e.g., polytechnic/ITI drafting students). If permitted, parental consent mechanism is legally mandatory before enablement.
5. **CAD Intellectual Property Terms:** Confirmation of business model regarding whether copyright in drawing derivatives remains with client/engineer or is co-held.

### 5.3 Legal Review Blockers (Pre-Production Deployment)
1. Formal legal review of draft policies by qualified Indian legal counsel.
2. Review of CERT-In incident reporting workflow (6-hour SLA).
3. Verification of DPDP Rules 2025 phased commencement timeline at the date of commercial launch.

---

## 6. EVIDENCE AND PRESERVATION REPORT (DELIVERABLE 6)

### 6.1 Git Workspace Verification
- **Workspace Path:** `D:\PROJECT\Archidraft-integration-workspace`
- **Active Branch:** `integration/engineer-draughtsman`
- **Commit HEAD:** `8f753a97315c59c33eb1b0ad1578951434ae368e` (`feat(integration): complete Chrome runtime validation for Engineer and Draughtsman workflows`)
- **Protected Workspace:** `D:\PROJECT\Archidraft-engineer-panel-source` (Verified untouched; zero modifications made).
- **Tracked Files State:** All 50 modified tracked files from Phases C, D, E, F1, F1.1, and H–K preserved without changes.
- **Untracked Files State:** All 40 existing untracked files/directories preserved, including `HANDOVER_SETUP_GUIDE.md` and `docs/FINAL_VERIFICATION_AND_HANDOVER_REPORT.md`.
- **Destructive Operations:** Zero `git reset`, `git clean`, `git checkout`, or stash operations executed.
- **Protected Accounts:** Intact and untouched (`zedsuo125@gmail.com`, `mohdanas53@gmail.com`, `ashrafbari277@gmail.com`, `mdjanis2006@gmail.com`, `pixelmintstudio01@gmail.com`).

### 6.2 Key Source Evidence Inspected
1. `lib/src/core/router/app_router.dart:58-95`: Demonstrates unconditional redirect to dashboards with zero legal checks.
2. `lib/src/features/auth/presentation/register_screen.dart:73-290`: Demonstrates registration form lacking terms acceptance checkbox, privacy policy links, or age verification.
3. `lib/src/features/profile/presentation/widgets/profile_form.dart:73-120`: Documents personal data fields collected without explicit notice of purpose or retention.
4. `worker/src/index.ts:118-185`: Validates user provisioning without terms acceptance audit logging.
5. `worker/src/index.ts:485-520`: Confirms server-side cross-user project authorization (`canUserAccessProject`).
6. `worker/src/index.ts:1985-2055`: Confirms strict server-side authorization for R2 file downloads.
7. `worker/src/index.ts:2062-2115`: Confirms single-file deletion exists, but user account deletion (`DELETE /api/users/me`) is absent.
8. `worker/migrations/0001_schema.sql` through `0015_student_credentials_verification.sql`: Confirms absence of legal document and consent audit tables.
9. `test/features/profile/presentation/widgets/profile_screen_test.dart:295`: Confirms zero technical infrastructure leakage in the profile UI.

### 6.3 Test Verification
- All existing 53 backend authorization tests (`worker/test/backend_authorization.test.mjs`, `cross_user_isolation_f1.test.mjs`, `admin_student_contract.test.mjs`) remain passing and valid.
- No application code or migrations were modified during this audit phase.

---
**REPORT COMPILED BY: ANTIGRAVITY AI AGENT**
**DATE: OCTOBER 2026**
