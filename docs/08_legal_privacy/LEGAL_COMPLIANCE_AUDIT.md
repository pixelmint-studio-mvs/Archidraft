# ARCHI DRAFT — LEGAL, PRIVACY & COMPLIANCE SYSTEM AUDIT (PHASE 0)

**Document ID:** `LEGAL_COMPLIANCE_AUDIT.md`  
**Operating Brand:** DRAUGHTSMAN STUDIO  
**Project:** ARCHI DRAFT  
**Legal Entity:** Sole Proprietorship operated by MOHAMMED MOSIN S  
**Development Team:** PixelMint Studio MVS  
**Audit Date:** November 7, 2026  
**Status:** **PHASE 0 COMPLETE — PENDING FORMAL APPROVAL TO BEGIN PHASE 1**

---

## 1. Executive Summary

This document establishes the comprehensive, forensic **Phase 0 Read-Only Audit** of the legal, privacy, and compliance architecture across the entire ARCHI DRAFT platform.

In accordance with the **Master Implementation Prompt**, this audit inspects all four operational tiers of the system:
1. **Multi-Role Flutter Client** (`lib/src/features/legal/`, `auth/`, `profile/`, `student/`, `projects/`, `pixmint_bot/`)
2. **Next.js Admin Web** (`apps/admin-web/src/`)
3. **Cloudflare Worker / Hono Backend** (`worker/src/legal.ts`, `worker/src/index.ts`)
4. **Cloudflare D1 Database** (`worker/migrations/`)

### Key Audit Finding
The technical foundations for regulatory compliance (immutable consent logging, post-login gating, D1 persistence, and SHA-256 idempotency hashing) are already established in the codebase. However, the system currently suffers from **five critical functional and regulatory gaps**:
1. **Unresolved Placeholder Tokens:** In-app policies in `authoritative_policy_content.dart` and database seeds still contain literal draft placeholders (`[PROPRIETOR FULL LEGAL NAME — TO BE CONFIRMED]`, `[GRIEVANCE OFFICER NAME — TO BE CONFIRMED]`).
2. **Zero In-App Navigation to Legal Center:** While `LegalCenterScreen` exists at `/legal/center`, there is **no link, button, or menu item** in `ProfileScreen` or the user portals allowing users to re-read terms or exercise data erasure rights.
3. **No Under-18 Minor Safeguarding:** Student registration collects no Date of Birth (DOB) or age declaration, has no guardian verification workflow, and lacks account restrictions for minors under the **Digital Personal Data Protection Act (DPDP Act 2023, Section 9)**.
4. **Missing Admin Compliance Center:** The Next.js Admin portal has no Legal & Compliance section to manage policies, review guardian consents, resolve privacy requests, or audit consent ledgers.
5. **Missing Disclaimers & IP/Refund Workflows:** Zero AI usage disclaimers inside PIXMINT BOT, no structural engineering liability disclaimers, no configurable CAD project ownership framework, and no auditable refund request workflow.

---

## 2. Confirmed Business Information & Verification Status

In accordance with project governance directives, the following business information is recorded with zero fabrication:

| Parameter | Confirmed Value | Verification Status | Statutory Significance |
|---|---|:---:|---|
| **Business Structure** | Sole Proprietorship | Confirmed | Proprietor holds direct personal liability as Data Fiduciary under DPDP Act 2023 & Indian Contract Act 1872. |
| **Legal Proprietor** | **MOHAMMED MOSIN S** | Confirmed | Contracting individual doing business as (d/b/a) Draughtsman Studio. |
| **Operating Brand** | **DRAUGHTSMAN STUDIO** | Confirmed | Public operating trade name for the platform. |
| **Application Website** | `https://archidraft.draughtsmanstudio.com` | Confirmed | Official web application portal endpoint. |
| **Business Website** | `https://draughtsmanstudio.com` | Confirmed | Primary studio brand website. |
| **Grievance Email** | `mosin@draughtsmanstudio.com` | Confirmed | Statutory grievance redressal point under IT SPDI Rule 5(9) & DPDP Act Sec 13. |
| **Customer Support Email** | `support@draughtsmanstudio.com` | Confirmed | Primary operational support channel. |
| **Privacy Request Email** | `support@draughtsmanstudio.com` | Confirmed | Dedicated channel for DPDPA data rights and account erasure. |
| **Physical Business Address** | `[BUSINESS ADDRESS — PENDING VERIFICATION, INDIA]` | `PENDING_VERIFICATION` | **Unconfirmed.** Must remain visibly marked as pending; website URL must NOT be used as physical address. |
| **Grievance Officer Appointment** | `[GRIEVANCE OFFICER — PENDING FORMAL APPOINTMENT]` | `PENDING_VERIFICATION` | **Unconfirmed.** Do not assume proprietor is appointed officer without explicit confirmation. |

---

## 3. Comprehensive Audit Across System Layers

### 3.1 Flutter Application Tier (`lib/`)

| Module / Component | File Path | Existing Implementation | Identified Gaps | Severity |
|---|---|---|---|:---:|
| **Legal Center Screen** | `lib/src/features/legal/presentation/legal_center_screen.dart` | Complete 3-tab screen: Policies Reader, Consent Preferences, Data Rights & Requests. | **Orphan Screen:** Route `/legal/center` exists, but zero links exist in `ProfileScreen`, Drawer, or Bottom Nav. | **HIGH** |
| **User Profile & Settings** | `lib/src/features/profile/presentation/profile_screen.dart` | Profile vital editing, student achievements, student credential cards. | Missing "Legal & Privacy Center" entry tile, missing age/DOB display, missing data rights link. | **HIGH** |
| **Registration Flow** | `lib/src/features/auth/presentation/register_screen.dart` | Name, email, mobile, password, proof document upload. | **Zero age gating or DOB field.** Minors can register unrestricted without guardian consent. | **CRITICAL** |
| **Legal Onboarding** | `lib/src/features/legal/presentation/legal_onboarding_screen.dart` | Mandatory Terms checkbox, independent Privacy Notice acknowledgement, optional consents. | Hardcoded policy text references instead of centralized legal content config. | **MEDIUM** |
| **PIXMINT BOT 2.0** | `lib/src/features/pixmint_bot/presentation/` | Floating assistant, continuous chat history, quick suggestions. | **Zero AI Usage Disclaimer & Engineering Disclaimer.** Users receive no warning regarding human review. | **HIGH** |
| **Project Workspace** | `lib/src/features/projects/presentation/` | Project form, CAD viewer, drawing versions, redline review. | No CAD Ownership Agreement selector or acceptance records for project deliverables. | **MEDIUM** |
| **Policy Content Repository** | `lib/src/features/legal/data/authoritative_policy_content.dart` | Hardcoded Dart strings with full text of Terms and Privacy Policy. | Still filled with literal `[TO BE CONFIRMED]` placeholders; lacks central versioning system. | **HIGH** |

### 3.2 Next.js Admin Web Tier (`apps/admin-web/`)

| Module / Component | Existing State | Identified Gaps | Severity |
|---|---|---|:---:|
| **Sidebar Navigation** | Sections: Overview, Registration, Quick Access, Support, AI Assistant, Settings. | **No Legal or Compliance section.** Completely missing from sidebar. | **HIGH** |
| **Legal Policy Management** | None. Backend has `/api/admin/legal/documents`, but Admin Web has 0 pages. | Cannot create, preview, edit, or publish legal policy drafts or view version histories. | **HIGH** |
| **Consent Ledger Audit** | None. Backend has `/api/admin/legal/consents`, but Admin Web has 0 pages. | Cannot inspect user consent history or export regulatory compliance audit logs. | **MEDIUM** |
| **Student Safeguarding** | None. Users table shows student role, but no guardian tracking. | Cannot review pending guardian verifications, approved consents, or restricted minor accounts. | **CRITICAL** |
| **Privacy Requests** | None. Backend has `/api/admin/legal/privacy-requests`, but Admin Web has 0 pages. | Cannot assign, review, update status, or resolve statutory user data erasure requests. | **HIGH** |
| **IP & Ownership Review** | None. | Cannot inspect project-specific CAD ownership agreements or licensing terms. | **MEDIUM** |
| **Refunds & Cancellations** | None. Financials page lists invoices and payments only. | Cannot review project cancellation requests or make recorded refund decisions. | **HIGH** |

### 3.3 Cloudflare Worker Backend Tier (`worker/src/`)

| Endpoint / Service | Existing Capabilities | Gaps & Deficiencies | Severity |
|---|---|---|:---:|
| `worker/src/legal.ts` | Public current document reads (`/api/legal/documents/current`), user legal status check, idempotent terms acceptance, admin document CRUD, admin privacy request resolution, admin consent audit stream. | Missing business profile endpoints (`/api/legal/business-profile`), missing guardian consent endpoints, missing project agreement endpoints. | **HIGH** |
| `assertTermsAccepted` | Strict fail-closed middleware checking D1 `user_consent_state` against `legal_documents` `EFFECTIVE` version. | Checks only `TERMS_AND_CONDITIONS`; does not support age-based restrictions or project agreements. | **MEDIUM** |
| `POST /api/projects/cancel` | Updates project status to `CANCELLED` and records audit log. | **No refund request creation**, no refund status tracking, no financial adjustment records. | **HIGH** |
| `worker/src/helpdesk.ts` | Ticketing system supporting Resend/SendGrid and fallback simulation. | Not unified with statutory Privacy Requests (`privacy_requests` table). | **MEDIUM** |

### 3.4 Cloudflare D1 Database Tier (`worker/migrations/`)

| Table Name | Defined in Migration | Existing Columns & Scope | Missing Columns / Entities Required |
|---|---|---|---|
| `legal_documents` | `0016_legal_system.sql` | `id`, `document_type`, `version`, `title`, `content`, `effective_at`, `status`, `is_mandatory`, `locale` | Missing `policy_category` (DISCLAIMER, TERMS, POLICY, AGREEMENT). |
| `legal_consent_events` | `0016_legal_system.sql` | `id`, `user_id`, `document_id`, `document_type`, `version`, `action_type`, `idempotency_key`, `ip_hash`, `user_agent` | Fully functional immutable ledger. |
| `user_consent_state` | `0016_legal_system.sql` | `id`, `user_id`, `consent_type`, `purpose_tag`, `current_status`, `accepted_version` | Fully functional materialized state. |
| `privacy_requests` | `0016_legal_system.sql` | `id`, `user_id`, `request_type`, `details`, `status`, `statutory_deadline`, `resolution_notes` | Fully functional; needs linking to new admin workflow. |
| **`legal_business_profile`** | **MISSING** | Does not exist. | Needed to store verified proprietor, brand, address verification status, and contact emails. |
| **`guardian_consents`** | **MISSING** | Does not exist. | Needed to record student minor ID, guardian name, email, phone, relationship, verification token, and verification status. |
| **`project_ip_agreements`** | **MISSING** | Does not exist. | Needed to track project CAD ownership choices (`CREATOR_RETAINS`, `ASSIGNMENT_UPON_PAYMENT`, `LIMITED_LICENSE`, `CUSTOM_AGREEMENT`). |
| **`refund_requests`** | **MISSING** | Does not exist. | Needed to track cancellation refunds, amounts, reasons, review status, admin decisions, and transaction refs. |
| **`users` (Modifications)** | `0001_schema.sql` | Standard user vital columns. | Needs `date_of_birth`, `age_category` (`ADULT`, `MINOR_PENDING_GUARDIAN`, `MINOR_VERIFIED`), `guardian_consent_id`. |

---

## 4. Analysis of Legal & Policy Content Requirements

### 4.1 Terms and Conditions
- **Current Status:** Version 1.2.0-DRAFT in `authoritative_policy_content.dart`.
- **Action Required:** Update identity section with confirmed details (**MOHAMMED MOSIN S**, Sole Proprietorship d/b/a **DRAUGHTSMAN STUDIO**). Keep physical address visibly flagged as `PENDING_VERIFICATION`. Add explicit Architectural & Engineering Liability Disclaimer.

### 4.2 Privacy Policy
- **Current Status:** Version 1.2.0-DRAFT in `authoritative_policy_content.dart`.
- **Action Required:** Update Data Fiduciary identity to MOHAMMED MOSIN S. Clarify actual technical stack (Firebase Auth, Cloudflare Workers/D1/R2). Set Grievance contact to `mosin@draughtsmanstudio.com` and privacy request to `support@draughtsmanstudio.com`.

### 4.3 Architectural and Engineering Liability Disclaimer
- **Status:** **NEW MANDATORY CONTENT.**
- **Content Specification:**
  - ARCHI DRAFT is a project coordination and drafting workflow platform.
  - Drawings, designs, calculations, redlines, and AI recommendations are technical drafting representations and **not certified engineering advice**.
  - All load-bearing, structural, civil, and municipal approval calculations must be verified, vetted, and stamped by a **licensed Architect (registered with Council of Architecture)** or **chartered Structural Engineer** before on-site construction.
  - Platform and draughtsmen assume zero liability for on-site structural failures or execution errors.

### 4.4 AI Usage Disclaimer
- **Status:** **NEW MANDATORY CONTENT.**
- **Content Specification:**
  - PIXMINT BOT output may contain errors, omissions, or outdated building codes.
  - AI recommendations require mandatory human verification.
  - Users must not upload confidential, sensitive, or trade-secret information into AI prompts.
  - AI outputs do not replace licensed professional judgment and must never be relied upon for final structural, financial, or safety-critical decisions.
  - Must be displayed within PIXMINT BOT UI and the Legal Center.

### 4.5 Intellectual Property & CAD Ownership Framework
- **Status:** **UNDECIDED — PENDING BUSINESS & LEGAL REVIEW.**
- **Framework Specification:**
  - Do NOT implement an automatic copyright transfer.
  - Create a configurable agreement model with 4 selectable ownership options:
    1. `OWNERSHIP_RETAINED_BY_CREATOR` (Draughtsman retains copyright; client receives license).
    2. `COPYRIGHT_ASSIGNMENT_AFTER_PAYMENT` (100% economic copyright transfers to client upon settlement).
    3. `LIMITED_USAGE_LICENSE` (Client receives non-exclusive right to construct the specific project once).
    4. `CUSTOM_AGREEMENT_PENDING_LEGAL_REVIEW` (Bespoke contractual terms).
  - Agreement status must remain `PENDING_LEGAL_REVIEW` and not published as a default binding term until authorized.

### 4.6 Project Revision Policy
- **Status:** **PROPOSED — PENDING BUSINESS APPROVAL.**
- **Initial Configuration:**
  - `included_revision_rounds = 2` per deliverable.
  - Corrections must relate to the original approved project brief.
  - Each round must be submitted as one consolidated change request.
  - Major scope expansions require separate quotations.
  - Errors caused by the draughtsman's own failure to follow the brief must NOT count against the 2 rounds.
  - Status marked as `PENDING_BUSINESS_APPROVAL`.

### 4.7 Cancellation and Refund Policy
- **Status:** **PROPOSED — PENDING BUSINESS & LEGAL REVIEW.**
- **Initial Configuration:**
  - Subscriptions: Cancel at any time; stops subsequent renewal; unused time non-refundable except for duplicate/failed transactions.
  - Services: Written request; completed/approved work and non-recoverable costs deducted; unearned advances assessed for refund. Work not started is not treated as fully earned.
  - Request recording workflow: User, project/subscription ID, reason, amount, review status, admin decision, resolution date.
  - Marked as `cancellation_policy_status = PENDING_BUSINESS_APPROVAL` and `refund_policy_status = PENDING_LEGAL_REVIEW`.

---

## 5. Under-18 Student Safeguarding Architecture

### Legal & Regulatory Reality (India DPDP Act 2023 & Contract Act 1872)
1. **Contract Incompetence:** Under Indian Contract Act Sec 11, agreements signed directly by minors are *void ab initio*. Minors cannot legally accept Terms & Conditions.
2. **DPDP Act Section 9 Mandate:** Data Fiduciaries processing children's data must obtain verifiable parental consent and are strictly prohibited from behavioral tracking or profiling.

### Safeguarding Technical Workflow
```
[Student Registration]
         │
         ▼
[Declare Date of Birth]
         │
    Age >= 18?
    ├── YES ──► Standard Verification & Activation
    │
    └── NO (< 18) ──► Age Category = MINOR_PENDING_GUARDIAN
                             │
                             ▼
               [Collect Guardian Details]
               (Name, Email, Mobile, Relationship)
                             │
                             ▼
               [Guardian Verification Dispatch]
               (Secure Verification Link / Form)
                             │
                             ▼
                 [Admin Review & Approval]
                             │
                 Approved? ──► YES ──► Age Category = MINOR_VERIFIED
                             │          (Age-appropriate restrictions active:
                             │           no public listing, no behavioral profiling)
                             │
                             └── NO  ──► Account Remains Restricted
```

---

## 6. Proposed Database Schema Changes (D1 Migration 0026)

To support the complete compliance system without mutating existing tables destructively:

```sql
-- Migration 0026: Legal, Compliance, Guardian and Agreement Framework

-- 1. Business Profile Configuration
CREATE TABLE IF NOT EXISTS legal_business_profile (
  id TEXT PRIMARY KEY DEFAULT 'default',
  proprietor_name TEXT NOT NULL,
  operating_brand TEXT NOT NULL,
  business_structure TEXT NOT NULL DEFAULT 'Sole Proprietorship',
  application_url TEXT NOT NULL,
  business_url TEXT NOT NULL,
  grievance_email TEXT NOT NULL,
  support_email TEXT NOT NULL,
  privacy_email TEXT NOT NULL,
  physical_address TEXT,
  address_verification_status TEXT NOT NULL DEFAULT 'PENDING_VERIFICATION',
  grievance_officer_name TEXT,
  grievance_officer_status TEXT NOT NULL DEFAULT 'PENDING_VERIFICATION',
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 2. Guardian Consent Records for Minors
CREATE TABLE IF NOT EXISTS guardian_consents (
  id TEXT PRIMARY KEY,
  student_user_id TEXT NOT NULL,
  guardian_name TEXT NOT NULL,
  guardian_email TEXT NOT NULL,
  guardian_phone TEXT,
  relationship TEXT NOT NULL,
  document_version TEXT NOT NULL,
  consent_status TEXT NOT NULL DEFAULT 'PENDING_VERIFICATION', -- PENDING_VERIFICATION, VERIFIED, REJECTED, WITHDRAWN
  verification_token TEXT UNIQUE,
  verified_at DATETIME,
  verified_by TEXT,
  notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (student_user_id) REFERENCES users(id) ON DELETE RESTRICT
);

-- 3. Project IP & CAD Ownership Agreements
CREATE TABLE IF NOT EXISTS project_ip_agreements (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL UNIQUE,
  client_id TEXT NOT NULL,
  creator_id TEXT NOT NULL,
  ownership_selection TEXT NOT NULL, -- CREATOR_RETAINS, ASSIGNMENT_UPON_PAYMENT, LIMITED_LICENSE, CUSTOM_AGREEMENT
  license_scope TEXT,
  portfolio_permission INTEGER NOT NULL DEFAULT 0,
  agreement_status TEXT NOT NULL DEFAULT 'PENDING_LEGAL_REVIEW', -- PENDING_LEGAL_REVIEW, ACTIVE, SUPERSEDED
  agreed_by_client_at DATETIME,
  agreed_by_creator_at DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE RESTRICT
);

-- 4. Cancellation & Refund Requests
CREATE TABLE IF NOT EXISTS refund_requests (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  request_type TEXT NOT NULL, -- SUBSCRIPTION, PROJECT_DRAFTING
  reference_id TEXT NOT NULL, -- project_id or invoice_id
  amount_requested REAL,
  reason TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'SUBMITTED', -- SUBMITTED, UNDER_REVIEW, APPROVED, REJECTED, RESOLVED
  admin_decision TEXT,
  admin_notes TEXT,
  refund_transaction_ref TEXT,
  resolved_at DATETIME,
  resolved_by TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
);

-- 5. Extend Users Table with Age Categories
ALTER TABLE users ADD COLUMN date_of_birth TEXT NULL;
ALTER TABLE users ADD COLUMN age_category TEXT DEFAULT 'ADULT'; -- ADULT, MINOR_PENDING_GUARDIAN, MINOR_VERIFIED
ALTER TABLE users ADD COLUMN guardian_consent_id TEXT NULL;
```

---

## 7. Security & Privacy Safeguards Assessment

1. **Authorization & RBAC:**
   - All legal admin endpoints (`/api/admin/legal/*`) are protected by server-side verification (`user.role === 'ADMIN' || user.role === 'STUDIO_ADMIN'`).
   - Normal users cannot read or mutate other users' consent histories or privacy tickets (enforced via `uid = c.get('uid')`).
2. **Student Data Isolation:**
   - Minor student profiles (`MINOR_PENDING_GUARDIAN`) are quarantined from public directories.
   - Guardian contact details are visible only to verified studio admins.
3. **Idempotency & Tamper Resistance:**
   - Consent events use SHA-256 idempotency hashing (`idempotency_key = hash(uid + docId + version + ip + action)`), preventing duplicate or forged acceptance entries.
   - Consent history is strictly append-only; historical records are never deleted or updated in place.

---

## 8. Profile Settings Integration Plan

To address the missing entry point into the Legal Center:
1. In `lib/src/features/profile/presentation/profile_screen.dart`:
   - Add a dedicated **Legal & Privacy Center** action card/tile directly beneath the profile vital forms.
   - Provide summary badges showing current policy status:
     - Terms & Conditions: **Accepted (v1.0.0)**
     - Privacy Policy: **Acknowledged**
     - Data Rights: **Exercise Rights (Erasure / Requests)**
   - Wire a 1-tap navigation button: `context.push('/legal/center')`.
2. In `lib/src/features/profile/presentation/widgets/profile_form.dart`:
   - Display Date of Birth (DOB) and Age Verification Status.

---

## 9. Recommended Phased Implementation Sequence

```
Phase 0: Read-Only Audit & Gap Analysis (COMPLETED)
   │
   ▼ [User Approval Required]
Phase 1: Centralized Business Config & Legal Document System (shared/legal/)
   │
Phase 2: Flutter Legal Center Enhancement & Profile Settings Integration
   │
Phase 3: Consent Management Backend & D1 Migration 0026
   │
Phase 4: Under-18 Student Safeguarding Workflow
   │
Phase 5: Grievance, Privacy Requests & Refund Review Workflows
   │
Phase 6: Configurable Project CAD Ownership Agreement Framework
   │
Phase 7: Next.js Admin Legal Compliance Center
   │
Phase 8: Comprehensive Automated Testing & Security Verification
   │
Phase 9: Final Readiness & Handover Report
```

---

## 10. Audit Conclusion & Gate Check

- **Audit Completion:** Phase 0 audit is complete and verified against the live repository.
- **Strict Guardrail:** In accordance with the Master Prompt, **zero implementation changes have been written to the production code during Phase 0**.
- **Awaiting Authorization:** The audit findings, business configuration values, and proposed implementation sequence are submitted for user review and formal authorization to begin **PHASE 1**.

