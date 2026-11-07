# ARCHI DRAFT — Admin Legal Compliance Dashboard & Audit Center Guide
**Operating Brand:** DRAUGHTSMAN STUDIO  
**Legal Proprietor:** MOHAMMED MOSIN S  
**Product:** ARCHI DRAFT  
**Phase:** 4 of 9 (Next.js Admin Legal Compliance Dashboard & Audit Center)  
**Date:** November 2026  
**Status:** Completed & Tested

---

## 1. Overview & Purpose

The **Admin Legal Compliance Dashboard & Audit Center** is an enterprise-grade administration hub embedded directly within the ARCHI DRAFT Next.js Admin Web portal (`apps/admin-web`).

Accessible via the route `/legal` or the **"Governance & Compliance"** section in the main sidebar, it empowers Studio Administrators to:
- Monitor holistic compliance KPIs across legal policy instruments, pending privacy requests, and regulatory consent events.
- Manage canonical policy documents through a guarded lifecycle (`DRAFT`, `UNDER_REVIEW`, `APPROVED`, `PUBLISHED` / `EFFECTIVE`, `SUPERSEDED`, `ARCHIVED`).
- Review and process Data Principal rights under India's **Digital Personal Data Protection Act, 2023 (DPDP Act)** (Account Erasures, Data Exports, Profile Rectifications, Grievance Redressals).
- Verify student guardian declarations for minors under 18 years of age pursuant to Section 9 of the DPDP Act.
- Inspect the immutable regulatory consent ledger (`legal_consent_events`).
- Review milestone-based drafting cancellations and refunds.
- Monitor statutory data retention schedules (CERT-In 180-day security logging and Income-tax 8-year accounting).

---

## 2. Navigation & Access Control Architecture

### 2.1 Role-Based Access Control (RBAC)
Access to `/legal` and its backend APIs is strictly limited to authorized administrative roles:
- `ADMIN`: Platform Super Administrator
- `STUDIO_ADMIN`: Draughtsman Studio Operational Administrator

**Client-Side Route Guard (`AdminShell.tsx`):**
Any non-admin role attempting direct URL navigation to `/legal` is immediately redirected to `/login`.

**Server-Side Endpoint Protection (`worker/src/legal.ts`):**
Every API route under `/api/admin/legal/*` validates the authenticated user's session token and verifies `role IN ('ADMIN', 'STUDIO_ADMIN')`. Unauthorized callers receive HTTP `403 FORBIDDEN`.

### 2.2 Main Navigation Integration (`Sidebar.tsx`)
A dedicated top-level category has been added to the Stitch Architectural Precision System sidebar:
```
┌──────────────────────────────────────────────┐
│  GOVERNANCE & COMPLIANCE                     │
│  ├── Legal & Compliance [ShieldCheck]  (12)  │
└──────────────────────────────────────────────┘
```
The badge indicator dynamically fetches `adminApi.getLegalStats()` every 30 seconds and reflects the live total of pending actionable requests.

---

## 3. The 11 Modular Tabs

The Legal Compliance Dashboard is organized into 11 tabbed operational views:

### 3.1 Overview Tab (`LegalOverviewTab.tsx`)
- **Executive Advisory Banner:** Discloses provisional Sole Proprietorship status of MOHAMMED MOSIN S, highlights pending physical address and Grievance Officer appointment verification, and disclaims automatic legal certification.
- **Top KPI Cards:**
  1. *Canonical Instruments:* Total registered documents vs published effective count.
  2. *Action Required:* Real-time sum of pending deletions, exports, corrections, guardians, refunds, and grievances.
  3. *Consent Audit Ledger:* Total logged regulatory consent events.
  4. *Retention Schedules:* Active statutory data retention categories.
- **Interactive Queue Review Tiles:** One-click shortcuts to each operational review queue.

### 3.2 Business Profile Tab (`BusinessProfileTab.tsx`)
- Displays confirmed business identity:
  * Operating Brand: **DRAUGHTSMAN STUDIO**
  * Legal Proprietor: **MOHAMMED MOSIN S**
  * Structure: **Sole Proprietorship**
  * Product: **ARCHI DRAFT**
  * Digital Properties: `https://archidraft.draughtsmanstudio.com` & `https://draughtsmanstudio.com`
  * Contact Vectors: `mosin@draughtsmanstudio.com` & `support@draughtsmanstudio.com`
- Highlights **Unresolved Verification Gates**:
  * Physical Business Address: `PENDING_VERIFICATION` (Warning: website URLs must never be published as physical addresses).
  * Formal Grievance Officer Appointment: `PENDING_VERIFICATION` (Formal statutory order under IT Rules pending execution).

### 3.3 Documents Registry Tab (`DocumentRegistryTab.tsx`)
- Centralized inventory of all 7 canonical platform instruments.
- Search and category filter (`TERMS_AND_CONDITIONS`, `PRIVACY_POLICY`, `AI_USAGE_DISCLAIMER`, `ENGINEERING_DISCLAIMER`, `CAD_OWNERSHIP_FRAMEWORK`, `REVISION_POLICY`, `CANCELLATION_REFUND_POLICY`).
- Version, status badge, requirement badge (MANDATORY vs OPTIONAL), effective date.
- Actions:
  * **View:** Opens `DocumentReaderModal` with full Markdown text.
  * **Draft New Policy Version:** Opens `DocumentDraftModal`.
  * **Publish:** Opens `PublishDocumentModal` with atomic promotion safeguard.

### 3.4 Consent Audit Tab (`ConsentAuditTab.tsx`)
- Connects to `GET /api/admin/legal/consents`.
- Displays user ID, action type, document type & version, purpose, SHA-256 hashed IP address, user agent, and timestamp.
- Action filter: `TERMS_ACCEPTED`, `PRIVACY_ACKNOWLEDGED`, `OPTIONAL_MARKETING_CONSENTED`, `OPTIONAL_TELEMETRY_CONSENTED`, `OPTIONAL_CONSENT_WITHDRAWN`.
- Built-in pagination and search engine.

### 3.5 Account Erasures Tab (`AccountDeletionsTab.tsx`)
- Connects to `GET /api/admin/legal/account-deletion-requests`.
- Tracks 30-day grace period requests, scheduled purge dates, and cancellation statuses.
- Review Modal supports decisions: `UNDER_REVIEW`, `IDENTITY_VERIFICATION_REQUIRED`, `VERIFIED`, `DELETION_SCHEDULED`, `PROCESSING`, `PARTIALLY_COMPLETED`, `COMPLETED`, `REJECTED_WITH_REASON`.
- Highlights tombstoning protocol and collaborative CAD preservation safeguards.

### 3.6 Data Exports Tab (`DataExportsTab.tsx`)
- Connects to `GET /api/admin/legal/data-export-requests`.
- Tracks export scopes (`FULL_ARCHIVE`, `PROJECTS_ONLY`, `CONSENT_AUDIT`), completion timestamps, and 7-day token expiration dates.
- Status updates (`PROCESSING`, `COMPLETED`, `FAILED`).
- Download tokens are protected from unauthorized view.

### 3.7 Data Corrections Tab (`DataCorrectionsTab.tsx`)
- Connects to `GET /api/admin/legal/data-correction-requests`.
- Displays field (`name`, `mobile`, `address`, `qualification`), current value, proposed value, and user justification.
- Review Modal allows approving (`RESOLVED`) or rejecting (`REJECTED`).
- Approval atomically updates the user's authoritative record in the D1 `users` table.

### 3.8 Guardian Consents Tab (`GuardianConsentsTab.tsx`)
- Connects to `GET /api/admin/legal/guardian-consents`.
- Reviews student under-18 parental declarations under Section 9 DPDP Act.
- Statuses: `PENDING`, `VERIFIED`, `REJECTED`, `WITHDRAWN`, `EXPIRED`.
- Auditable review notes and reviewer attribution.

### 3.9 Cancellations & Refunds Tab (`CancellationRefundsTab.tsx`)
- Connects to `GET /api/admin/legal/cancellation-refund-requests`.
- Reviews project milestone cancellations and drafting dispute refund claims.
- Records approved refund amounts, review decisions, resolution notes, and transaction references.

### 3.10 Retention Policies Tab (`RetentionPoliciesTab.tsx`)
- Connects to `GET /api/admin/legal/retention-policies`.
- Displays statutory schedules: CERT-In 180-day security logging, Income-tax 8-year accounting, and operational CAD revision archives.

### 3.11 Privacy & Grievances Tab (`PrivacyGrievancesTab.tsx`)
- Connects to `GET /api/admin/legal/privacy-requests`.
- Statutory complaint intake, 48-hour acknowledgment tracking, and 30-day resolution tracking under Section 13 DPDP Act.
