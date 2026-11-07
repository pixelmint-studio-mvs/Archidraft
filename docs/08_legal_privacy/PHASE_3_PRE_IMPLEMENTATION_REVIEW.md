# ARCHI DRAFT — Phase 3 Pre-Implementation Audit & Architectural Review
## Flutter Legal Center, Onboarding Consent & User Privacy Controls

**Project:** ARCHI DRAFT  
**Operating Brand:** DRAUGHTSMAN STUDIO  
**Legal Proprietor:** MOHAMMED MOSIN S  
**Development Team:** PixelMint Studio MVS  
**Phase:** 3 of 9  
**Document Reference:** `docs/08_legal_privacy/PHASE_3_PRE_IMPLEMENTATION_REVIEW.md`  
**Date:** November 7, 2026  
**Status:** AUDIT COMPLETE — PROCEEDING TO IMPLEMENTATION

---

## 1. Executive Summary

This pre-implementation review evaluates the existing Flutter client codebase (`lib/src/`) in comparison with the Phase 1 canonical legal configuration and the Phase 2 Cloudflare D1 database and Worker API endpoints.

The objective of Phase 3 is to deliver a complete, professional, production-grade legal and data rights experience within the ARCHI DRAFT Flutter application, covering:
1. Full 7-document legal library with versioning, publication status, and Markdown viewing.
2. Consent preferences and purpose-specific consent withdrawal.
3. Personal data export requests (§ 11 DPDPA) and download expiry tracking.
4. Audited profile information correction requests (§ 12 DPDPA).
5. Multi-step account deletion requests with 30-day grace period tracking and cancellation.
6. Student guardian consent management (§ 9 DPDPA) for under-18 users.
7. Seamless navigation from the Profile screen across Engineer, Draughtsman, and Student portals.
8. PIXMINT BOT AI Usage and Architectural/Engineering Disclaimers.

---

## 2. Existing Capabilities Audit

### 2.1 Existing Legal Center (`lib/src/features/legal/presentation/legal_center_screen.dart`)
- **Current State:** A 3-tab layout (`Policies & Terms`, `Consent Preferences`, `Data Rights & Requests`).
- **Limitations Identified:**
  - Only loads `effectiveDocumentsListProvider`, which defaults to 2 documents (Terms and Privacy Policy). Does not surface the full 7-document canonical suite (AI Usage, Engineering, CAD Ownership, Revisions, Refunds).
  - Consent tab only toggles local mock switches for `MARKETING_COMMUNICATIONS` and `PORTFOLIO_SHOWCASE`, without using the dedicated Phase 2 `POST /api/legal/consents/withdraw` endpoint.
  - Privacy Requests tab only supports generic `privacy_requests` table, without dedicated workflows for account deletion, data export download links, profile field correction, or student guardian consent.
  - Missing section structure specified in Section 4 of the Master Prompt (Sections A through E).

### 2.2 Profile Navigation (`lib/src/features/profile/presentation/profile_screen.dart`)
- **Current State:** Displays identity header, personal vitals form, and student credentials/achievements.
- **Limitations Identified:**
  - Missing the dedicated **LEGAL & PRIVACY** section and navigation tiles linking to `/legal/center`.

### 2.3 Routing & Navigation (`lib/src/core/router/app_router.dart`)
- **Current State:**
  - `/legal/center` is mapped to `LegalCenterScreen`.
  - `/legal/onboarding` is mapped to `LegalOnboardingScreen` and enforced for users with pending mandatory terms acceptance.
  - `/terms-and-conditions` is mapped to pre-login terms acceptance.
- **Compatibility:** GoRouter structure is robust and ready to host sub-routes or modal screens for dedicated workflows.

### 2.4 PIXMINT BOT Interface (`lib/src/features/pixmint_bot/presentation/sheet/pixmint_chat_sheet.dart`)
- **Current State:** Features chat header, suggestions, message list, living mascot, and chat input.
- **Limitations Identified:**
  - Missing the canonical AI Usage Disclaimer banner and link to the Legal Center.

---

## 3. Backend API Integration Mapping (Phase 2 Contracts)

| User Action / UI Feature | Backend Endpoint (Worker) | HTTP Method | Payload / Parameters |
| :--- | :--- | :---: | :--- |
| **Read Business Profile** | `/api/legal/business-profile` | `GET` | None (Public/Authenticated) |
| **List Effective Documents** | `/api/legal/documents/current` | `GET` | None |
| **Read Document Content** | `/api/legal/documents/:type/current` | `GET` | `locale=en-IN` |
| **Get User Consent State** | `/api/users/me/legal-status` | `GET` | Bearer Token |
| **Accept Platform Terms** | `/api/legal/accept-terms` | `POST` | `{ documentId, version, source }` |
| **Acknowledge Privacy** | `/api/legal/acknowledge-privacy` | `POST` | `{ documentId, version, source }` |
| **Withdraw Consent** | `/api/legal/consents/withdraw` | `POST` | `{ purpose, source }` |
| **Request Account Deletion** | `/api/legal/account-deletion-requests` | `POST` | `{ reason?, requestCategory? }` |
| **Get My Deletion Status** | `/api/legal/account-deletion-requests/me` | `GET` | Bearer Token |
| **Cancel Deletion Request** | `/api/legal/account-deletion-requests/:id/cancel` | `POST` | Path parameter `:id` |
| **Request Data Export** | `/api/legal/data-export-requests` | `POST` | `{ exportScope? }` |
| **Get My Data Exports** | `/api/legal/data-export-requests/me` | `GET` | Bearer Token |
| **Request Data Correction** | `/api/legal/data-correction-requests` | `POST` | `{ fieldName, proposedValue, reason? }` |
| **Get My Data Corrections** | `/api/legal/data-correction-requests/me` | `GET` | Bearer Token |
| **Submit Guardian Consent** | `/api/legal/guardian-consents` | `POST` | `{ guardianName, guardianEmail, relationship }` |
| **Get My Guardian Consents** | `/api/legal/guardian-consents/me` | `GET` | Bearer Token |

---

## 4. Architectural Design & Proposed Structure

### 4.1 Legal Center Five-Section Architecture
To fulfill Section 4 of the prompt, `LegalCenterScreen` will be structured into five clear sections:
- **Section A: Legal Documents Library**
  - Displays all 7 canonical documents: Terms, Privacy Policy, AI Disclaimer, Engineering Disclaimer, CAD Ownership, Revision Policy, Cancellation/Refund Policy.
  - Clear chips for Version (`v1.0.0`), Status (`EFFECTIVE`, `DRAFT`, `PENDING_LEGAL_REVIEW`), and Action to read in `LegalMarkdownViewer`.
- **Section B: Consent Preferences**
  - Mandatory platform agreements (Terms & Privacy) visually distinguished with checkmarks.
  - Optional consents (`MARKETING_COMMUNICATIONS`, `PORTFOLIO_SHOWCASE`) with interactive switches that invoke `POST /api/legal/consents/withdraw` upon withdrawal.
- **Section C: My Personal Data (§ 11 & § 12 DPDPA)**
  - Dedicated interactive dialogs / sheets for "Download My Personal Data" and "Correct My Information".
  - Live listing of export archives with 7-day expiry warnings and secure download tokens.
  - Live listing of correction requests with status (`PENDING`, `APPROVED`, `REJECTED`) and reviewer notes.
- **Section D: Account Management & Deletion**
  - Multi-step confirmation dialog with 30-day grace period explanation, collaborative CAD asset protection notice, and statutory retention disclosure.
  - Active deletion banner showing remaining grace period, status badge, and "Cancel Deletion Request" button.
- **Section E: Help & Grievance Contact**
  - Authoritative contact card populated from `BusinessConfiguration` (`support@draughtsmanstudio.com`, `mosin@draughtsmanstudio.com`).
  - Explicit pending physical address and grievance officer notices.

### 4.2 Profile Integration
Add a prominent `Card` in `ProfileScreen` titled **LEGAL & PRIVACY** with subtitle *"Manage your legal agreements, personal information and privacy preferences."* containing navigation items to:
1. Legal & Privacy Center (`/legal/center`)
2. Platform Terms and Conditions
3. Privacy Policy & Data Protection Notice
4. My Data & Privacy Requests
5. Account Deletion Request

### 4.3 Student Portal Guardian Safeguards
In the Student Portal and Legal Center:
- For student accounts under 18, check `guardian-consents/me`.
- Display a dedicated Guardian Verification banner with current status (`PENDING_VERIFICATION`, `VERIFIED`, `REJECTED`).
- Provide an intuitive submission sheet for parent/guardian legal details.

### 4.4 PIXMINT BOT Disclaimer Integration
In `PixmintChatSheet`:
- Add a discrete, non-intrusive AI Disclaimer pill banner above the input bar or below the header:
  *"PIXMINT BOT provides AI-assisted information. Responses may contain errors and are not certified architectural or engineering advice. Verify technical and safety-critical information with an appropriately qualified professional."*
- Provide one-click actions: "Read Full Disclaimer" and "Legal Center".

---

## 5. Security, State Management & UX Safeguards

1. **Strict Client-Side Validation:** Data correction inputs are validated for non-empty text, valid field names, and format.
2. **Double Confirmation for Deletion:** Account deletion requires explicit multi-step confirmation and typed verification.
3. **Grace Period Visibility:** Clear countdown and cancellation buttons when status is `SUBMITTED`, `IDENTITY_VERIFICATION_REQUIRED`, or `UNDER_REVIEW`.
4. **Session Cleanup upon Deletion:** When status is `COMPLETED`, profile data is purged from Riverpod cache and the user is routed to logout.
5. **Safe Fallback to Authoritative Assets:** If offline or during network dropouts, fallback to bundled `authoritative_policy_content.dart` ensures users can always read platform legal terms.

---

## 6. Implementation Readiness Confirmation

All required Phase 2 backend endpoints are verified running and tested on the local Cloudflare Worker (`http://localhost:8787`). No backend blockers exist. Implementation of Phase 3 Flutter components is authorized to proceed.
