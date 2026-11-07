# ARCHI DRAFT — PHASE 4 PRE-IMPLEMENTATION AUDIT
## Next.js Admin Legal Compliance Dashboard & Audit Center

**Project:** ARCHI DRAFT  
**Operating Brand:** DRAUGHTSMAN STUDIO  
**Legal Proprietor:** MOHAMMED MOSIN S  
**Development Team:** PixelMint Studio MVS  
**Phase:** 4 of 9  
**Date:** November 2026  
**Git Branch:** `COMPLETED-INTERGRATION` (Commit: `ab4a4075`)  
**Status:** Audit Completed — Ready for Implementation

---

## 1. Executive Summary

This pre-implementation audit inspects the existing **Next.js Admin Web application** (`apps/admin-web`), the **Cloudflare Worker backend** (`worker/src/legal.ts` and `worker/src/index.ts`), the **Cloudflare D1 legal database schema** (`migrations/0016_legal_system.sql` and `migrations/0026_canonical_legal_system.sql`), and the **canonical legal document registry** (`shared/legal/`).

The purpose is to establish exact contracts, identify existing reusable UI patterns, map RBAC and authentication mechanisms, catalogue available backend endpoints, document technical gaps, and formulate an airtight, non-disruptive implementation plan for **Phase 4: Next.js Admin Legal Compliance Dashboard & Audit Center**.

---

## 2. Existing Admin Web Architecture & Navigation Structure

### 2.1 Technology Stack
- **Framework:** Next.js 16.4.2 (App Router with Turbopack)
- **UI & Styling:** React 19.3.0, Tailwind CSS v4, Lucide React icons
- **State & Data Fetching:** React Hooks, SWR (`^2.5.1`), native fetch with bearer tokens
- **Auth:** Firebase Authentication (`^13.0.0`) client SDK + Worker backend session validation
- **Testing:** Node.js built-in test runner (`node --test test/**/*.test.ts`) with 386 tests currently passing (100% pass rate)

### 2.2 Navigation Hierarchy & Sidebar Structure
The Admin Web navigation is centralized in `apps/admin-web/src/components/layout/Sidebar.tsx` and grouped under the **Stitch Architectural Precision System**:
1. **Overview:** Dashboard (`/dashboard`), Activity (`/activity`), Financials (`/financials`)
2. **Registration:** Registrations (`/registrations`) with live badge counts
3. **Quick Access:** All Users Directory (`/users`), Engineers/Architects (`/engineers`), Draughtsmen (`/draughtsmen`), Students (`/students`)
4. **Support:** Help Desk (`/helpdesk`)
5. **AI Assistant:** PIXMINT Bot 2.0 (`/bot`)
6. **Settings:** System Settings & SLA (`/settings`)

### 2.3 Proposed Integration Point
To maintain clean UX hierarchy without cluttering operational drawing queues, a dedicated top-level section will be introduced into `Sidebar.tsx`:
```tsx
{
  title: 'Governance & Compliance',
  items: [
    {
      name: 'Legal & Compliance',
      href: '/legal',
      icon: ShieldCheck,
      badgeKey: 'legalRequests', // Optional pending requests badge
    },
  ],
}
```

---

## 3. Authentication & RBAC Findings

### 3.1 Client-Side Access Control (`AdminShell.tsx` & `auth.tsx`)
- The `AdminShell` component encapsulates all admin views.
- Lines 69–90 of `AdminShell.tsx` strictly enforce:
  ```tsx
  if (!user || (user.role !== 'ADMIN' && user.role !== 'STUDIO_ADMIN')) {
    window.location.replace('/login');
    return <RedirectingView />;
  }
  ```
- Ordinary users (`CLIENT`, `ENGINEER`, `DRAUGHTSMAN`, `STUDENT`) cannot access or render admin layouts.

### 3.2 Server-Side Access Control (`worker/src/legal.ts`)
- Every admin endpoint in `worker/src/legal.ts` verifies:
  ```typescript
  const uid = c.get('uid');
  const user = await getUser(db, uid);
  if (!user || (user.role !== 'ADMIN' && user.role !== 'STUDIO_ADMIN')) {
    return c.json({ error: 'Forbidden: Admin access required' }, 403);
  }
  ```
- Route protection is reinforced at the API layer; hiding UI links is never treated as a security boundary.

---

## 4. Backend API & Database Mapping

### 4.1 Confirmed Existing Backend Endpoints in `worker/src/legal.ts`

| Module | Method & Route | Backend Implementation Status | D1 Table Target |
| :--- | :--- | :--- | :--- |
| **Documents** | `GET /api/admin/legal/documents` | Fully Implemented (Line 664) | `legal_documents` |
| **Documents** | `POST /api/admin/legal/documents` | Fully Implemented (Line 685) | `legal_documents` |
| **Documents** | `POST /api/admin/legal/documents/:id/publish` | Fully Implemented (Line 724) | `legal_documents` |
| **Grievance / Privacy** | `GET /api/admin/legal/privacy-requests` | Fully Implemented (Line 760) | `privacy_requests` |
| **Grievance / Privacy** | `POST /api/admin/legal/privacy-requests/:id/resolve`| Fully Implemented (Line 788) | `privacy_requests` |
| **Consent Ledger** | `GET /api/admin/legal/consents` | Fully Implemented (Line 830) | `legal_consent_events` |
| **Business Profile** | `GET /api/legal/business-profile` | Fully Implemented (Line 858) | `legal_business_profile` |
| **Account Deletion** | `GET /api/admin/legal/account-deletion-requests` | Fully Implemented (Line 1326)| `account_deletion_requests` |
| **Account Deletion** | `PATCH /api/admin/legal/account-deletion-requests/:id`| Fully Implemented (Line 1353)| `account_deletion_requests` |
| **Data Export** | `GET /api/admin/legal/data-export-requests` | Fully Implemented (Line 1417)| `data_export_requests` |
| **Data Export** | `PATCH /api/admin/legal/data-export-requests/:id` | Fully Implemented (Line 1437)| `data_export_requests` |
| **Data Correction** | `GET /api/admin/legal/data-correction-requests` | Fully Implemented (Line 1470)| `data_correction_requests` |
| **Data Correction** | `PATCH /api/admin/legal/data-correction-requests/:id`| Fully Implemented (Line 1490)| `data_correction_requests` |
| **Guardian Consent** | `GET /api/admin/legal/guardian-consents` | Fully Implemented (Line 1541)| `guardian_consents` |
| **Guardian Consent** | `PATCH /api/admin/legal/guardian-consents/:id` | Fully Implemented (Line 1561)| `guardian_consents` |
| **Cancellation/Refund**| `GET /api/admin/legal/cancellation-refund-requests` | Fully Implemented (Line 1599)| `cancellation_refund_requests`|
| **Cancellation/Refund**| `PATCH /api/admin/legal/cancellation-refund-requests/:id`| Fully Implemented (Line 1619)| `cancellation_refund_requests`|
| **Retention Policies**| `GET /api/admin/legal/retention-policies` | Fully Implemented (Line 1649)| `data_retention_policies` |

### 4.2 Identified Technical Gap: Aggregated Compliance Stats Endpoint
- While all individual list endpoints exist and return full rows, an admin overview dashboard requires rapid KPI summary numbers (pending deletions, pending exports, pending corrections, pending guardians, pending refunds, published vs draft documents).
- Calling 8 separate list endpoints sequentially on initial dashboard mount introduces redundant network traffic.
- **Proposed Safe Backend Extension:** Add `GET /api/admin/legal/stats` to `worker/src/legal.ts` executing light, indexed `COUNT(*)` queries on D1 to return instant metrics without modifying existing table schemas.

---

## 5. Canonical Legal Document Registry Reconciliation

The prompt noted that Phase 3 referred to both 6 and 7 documents:
- **Audit Verification:** Inspection of `shared/legal/registry/document_registry.json` confirms exactly **seven (7)** canonical policy instruments:
  1. `TERMS_AND_CONDITIONS`: Platform Terms and Conditions (v1.0.0, Mandatory)
  2. `PRIVACY_POLICY`: Privacy Policy & Data Protection Notice (v1.0.0, Mandatory)
  3. `AI_USAGE_DISCLAIMER`: Pixmint Bot & AI Usage Disclaimer (v1.0.0, Mandatory)
  4. `ENGINEERING_DISCLAIMER`: Architectural and Engineering Professional Services Disclaimer (v1.0.0, Mandatory)
  5. `CAD_OWNERSHIP_FRAMEWORK`: CAD Drawing Ownership and Intellectual Property Framework (v1.0.0, Mandatory)
  6. `REVISION_POLICY`: Project Revision and Correction Policy (v1.0.0, Mandatory)
  7. `CANCELLATION_REFUND_POLICY`: Subscription, Cancellation and Refund Policy (v1.0.0, Mandatory)
- All 7 instruments exist as canonical Markdown files in `shared/legal/documents/` and are tracked in `version_manifest.json`. The Admin Legal Registry will support all 7 documents.

---

## 6. Reusable Components & UI Design Conventions

The existing Admin Web codebase has well-established UI primitives that will be reused:
- **Shell & Layout:** `AdminShell` (supports title, subtitle, refresh button, sync status, and responsive sidebar).
- **Cards:** `Card`, `CardHeader` (clean borders, rounded-xl/2xl, shadow-sm).
- **Buttons:** `Button` (primary corporate navy `#0d1c32`, secondary architectural cobalt `#0453cd`, danger, outline, ghost).
- **Badges:** `Badge` (supports role, status, custom variants, font-mono typography).
- **Modals & Drawers:** `Modal` (backdrop transition, responsive max widths, keyboard ESC dismiss).
- **Empty States:** `EmptyState` (title, description, icon, action button).
- **Brand Signature:** `DraughtsmanBrandSignature` (consistent footer attribution).

---

## 7. Security, Privacy & Safeguard Considerations

1. **No Simulated Compliance:** The dashboard will not display an arbitrary "100% Legally Compliant" score. Instead, it will display factual system states (e.g., "7 Documents Registered", "4 Published", "2 Pending Review", "12 Pending Requests").
2. **Download Token Protection:** In the Data Export queue, temporary download tokens are never logged or exposed to unauthenticated viewers.
3. **Collaborative CAD Protection During Deletion:** The backend deletion handler tombstones user PII in D1 and purges personal PIXMINT BOT chats while strictly preserving collaborative CAD drawing revisions and CERT-In 180-day audit logs.
4. **Student Guardian Safeguards (§ 9 DPDPA):** A student's self-submitted guardian details are explicitly marked `PENDING` until administrative review.
5. **No Production Migrations or Deployments:** Local and staging development only.

---

## 8. Proposed Phase 4 Implementation Plan

### Step 1: Backend Client Extension (`apps/admin-web/src/lib/api.ts` & `types.ts`)
- Add TypeScript interfaces for:
  - `LegalDocumentAdmin`
  - `LegalComplianceStats`
  - `AdminAccountDeletionRequest`
  - `AdminDataExportRequest`
  - `AdminDataCorrectionRequest`
  - `AdminGuardianConsent`
  - `AdminCancellationRefundRequest`
  - `AdminConsentEvent`
  - `AdminPrivacyRequest`
  - `DataRetentionPolicy`
- Add API client methods under `adminApi.legal.*` in `apps/admin-web/src/lib/api.ts`.
- Add minimal `GET /api/admin/legal/stats` in `worker/src/legal.ts` with unit tests.

### Step 2: Sidebar Navigation Integration (`Sidebar.tsx`)
- Add `Governance & Compliance` section with `Legal & Compliance` item linking to `/legal`.

### Step 3: Admin Legal Center Hub (`apps/admin-web/src/app/legal/page.tsx`)
Create a comprehensive, responsive dashboard supporting 10 tabbed modules:
1. **Overview:** Executive KPIs, pending review queues, and system status.
2. **Business Profile:** Business identity, proprietor, contacts, and verification badges (with unverified physical address and grievance officer notices).
3. **Document Registry:** Lifecycle view (DRAFT, UNDER_REVIEW, APPROVED, PUBLISHED, ARCHIVED) of all 7 canonical documents with document preview and publication modal.
4. **Consent Audit:** Immutable regulatory consent event ledger with search and category filters.
5. **Account Deletions:** Deletion request queue, 30-day grace period status, review modal, and tombstone safeguards.
6. **Data Exports:** Export queue, requested scopes, and 7-day expiry status.
7. **Data Corrections:** Rectification queue with current vs proposed values, and atomic user profile update on approval.
8. **Guardian Consents:** Under-18 student guardian declarations review queue (§ 9 DPDPA).
9. **Cancellations & Refunds:** Milestone-based cancellation and refund review queue.
10. **Retention Policies:** Statutory retention rules (CERT-In 180d, Tax 8yr, CAD archives).
11. **Grievance Redressal:** Formal privacy and statutory grievance ticket queue.

### Step 4: Verification & Automated Tests
- Create `apps/admin-web/test/admin-legal-compliance.test.ts` covering:
  - Role-based access control (ADMIN/STUDIO_ADMIN vs unauthorized).
  - KPI calculation and empty state handling.
  - Tab routing and module rendering.
  - Deletion review status transitions.
  - Data correction approval field mapping.
  - Guardian verification state handling.
  - Business profile verification invariants.
- Run `npm test` to ensure all existing and new tests pass.

---

## 9. Risks and Unresolved Decisions

| Risk / Unresolved Item | Impact | Mitigation Strategy |
| :--- | :--- | :--- |
| **Physical Business Address** | Missing physical street address in India | Explicitly rendered as `PENDING_VERIFICATION` with informational warning; website URLs are never substituted. |
| **Formal Grievance Officer Appointment** | Proprietor email is used as contact, but formal appointment order is pending | Grievance Officer appointment is clearly badged as `PENDING_VERIFICATION`. |
| **Commercial Payment Gateway** | Real refunds cannot be disbursed electronically | Status transitions are recorded as administrative decisions without initiating payment gateway API calls. |
| **Automated Deletion vs Tombstoning** | Real user erasure risks data loss in active projects | Backend strictly implements tombstoning and collaborative CAD preservation; UI explicitly discloses this architecture. |
