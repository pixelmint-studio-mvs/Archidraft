# ARCHI DRAFT — Flutter Legal Center Implementation & Navigation Guide
**Operating Brand:** DRAUGHTSMAN STUDIO  
**Legal Proprietor:** MOHAMMED MOSIN S  
**Product:** ARCHI DRAFT  
**Phase:** 3 of 9 (Flutter Legal Center, Onboarding Consent & User Privacy Controls)  
**Date:** November 2026  
**Status:** Completed & Tested

---

## 1. Overview & Purpose

The **Legal Center** in the ARCHI DRAFT Flutter client provides a centralized, native, and transparent interface for all user legal documents, consent preferences, personal data rights (under India's DPDP Act 2023), account deletion requests, and grievance/statutory contact points.

It lives within the Flutter app codebase at `lib/src/features/legal/presentation/legal_center_screen.dart` and is accessible via the direct named route `/legal/center` or via the Profile screen's dedicated **"LEGAL & PRIVACY"** card.

---

## 2. Navigation Architecture & Entry Points

### 2.1 Route Mapping
- **Named Route:** `/legal/center`
- **GoRouter Configuration:** `lib/src/core/routing/app_router.dart`
- **Profile Navigation:** `lib/src/features/profile/presentation/profile_screen.dart`

### 2.2 Entry Points
1. **Profile Screen ("LEGAL & PRIVACY" Card):**
   - **Legal Center:** Direct link to `/legal/center`.
   - **Terms & Conditions:** Opens Document Reader directly with the canonical Terms & Conditions.
   - **Privacy Policy:** Opens Document Reader directly with the canonical Privacy Policy.
   - **My Personal Data & Exports:** Navigates directly to Legal Center with auto-scroll to the Data Rights tab/section.
   - **Account Deletion:** Navigates directly to Legal Center with auto-scroll to the Account Deletion tab/section.
2. **PIXMINT BOT Disclaimer Banner:**
   - Present above the conversation input sheet in `lib/src/features/pixmint_bot/presentation/sheet/pixmint_chat_sheet.dart`.
   - Displays clear statutory advisory: *"PIXMINT BOT is an AI conversational assistant and does not provide licensed architectural or structural engineering services..."*
   - Actions: **"Read Full Disclaimer"** (opens AI & Engineering Disclaimer directly) and **"Legal Center"** (routes to `/legal/center`).
3. **Student Studio Guardian Verification Banner:**
   - Located at the top of `lib/src/features/training/presentation/student_studio_screen.dart`.
   - Displays § 9 DPDPA under-18 guardian consent status: *Pending*, *Verified*, *Rejected*, or *Missing*.
   - Action: **"Submit Guardian Consent"** opens `GuardianConsentDialog` directly.

---

## 3. Screen Structure (The 5 Sections)

The Legal Center screen is architected into 5 distinct, responsive sections:

```
┌─────────────────────────────────────────────────────────────┐
│                   ARCHI DRAFT Legal Center                  │
├─────────────────────────────────────────────────────────────┤
│ 1. Documents Library                                        │
│    - Platform Terms & Conditions (v1.0.0, Mandatory)        │
│    - Privacy Policy & Data Protection (v1.0.0, Mandatory)   │
│    - AI & Engineering Disclaimer (v1.0.0, Mandatory)        │
│    - CAD Ownership & IP Agreement (v1.0.0, Mandatory)       │
│    - Project Revision & Cancellation (v1.0.0, Mandatory)    │
│    - Student Verification & Safeguards (v1.0.0, Mandatory)  │
├─────────────────────────────────────────────────────────────┤
│ 2. Consent Preferences                                      │
│    - Mandatory Platform Consents (Locked, Active)           │
│    - Optional Marketing Communications (Toggleable)         │
│    - Optional AI Model Improvements / Telemetry (Toggleable)│
│    - Instant Withdrawal with Warning Confirmation           │
├─────────────────────────────────────────────────────────────┤
│ 3. My Personal Data & Rights (§ 11 & § 12 DPDPA)            │
│    - Request Data Export (Full archive / Projects / Audit)  │
│    - Active & Historic Exports (Download Links, Expire 7d)  │
│    - Request Data Correction (Name, Mobile, Address, etc.)  │
│    - Active & Historic Correction Requests                  │
├─────────────────────────────────────────────────────────────┤
│ 4. Account Deletion (§ 12(3) DPDPA)                         │
│    - Active Grace Period Banner (if deletion pending)       │
│      * Shows Scheduled Purge Date (30-day grace window)     │
│      * "Cancel Deletion Request" button                     │
│    - Multi-Step Request Account Deletion Flow               │
│      * Explains consequence to personal data                │
│      * Explains collaborative CAD & financial retention     │
│      * Requires typing "DELETE" to confirm                  │
├─────────────────────────────────────────────────────────────┤
│ 5. Help, Grievance & Statutory Compliance                   │
│    - Data Fiduciary: DRAUGHTSMAN STUDIO                     │
│    - Legal Proprietor: MOHAMMED MOSIN S                     │
│    - Grievance Officer: mosin@draughtsmanstudio.com         │
│    - Support Email: support@draughtsmanstudio.com           │
│    - Response Timeline: Acknowledged within 48h, resolved   │
│      within 30 calendar days (§ 13 DPDPA)                   │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. State Management & Riverpod Providers

All legal state is managed predictably via Riverpod providers located in `lib/src/features/legal/providers/legal_providers.dart`:

| Provider Name | Type | Description |
| :--- | :--- | :--- |
| `allCanonicalDocumentsProvider` | `FutureProvider<List<LegalDocument>>` | Merges server documents with local authoritative offline fallbacks. |
| `legalConsentStateProvider` | `FutureProvider<LegalConsentState>` | Tracks current active vs withdrawn user consents. |
| `myAccountDeletionRequestsProvider` | `FutureProvider<List<AccountDeletionRequest>>` | Fetches user's deletion requests from backend API. |
| `activeAccountDeletionRequestProvider` | `Provider<AccountDeletionRequest?>` | Identifies currently pending deletion request (within 30-day grace period). |
| `myDataExportRequestsProvider` | `FutureProvider<List<DataExportRequest>>` | Fetches active and expired export archives with download tokens. |
| `myDataCorrectionRequestsProvider` | `FutureProvider<List<DataCorrectionRequest>>` | Fetches field correction submissions and review statuses. |
| `myGuardianConsentsProvider` | `FutureProvider<List<GuardianConsent>>` | Fetches under-18 student guardian declarations. |

---

## 5. Offline Resiliency & Fallback Strategy

The Legal Center is designed to be fully functional even in complete offline scenarios or when network connectivity to the Cloudflare Worker API is interrupted:

1. **Authoritative Local Policy Documents:**
   - Pre-bundled in `lib/src/features/legal/data/authoritative_policy_content.dart`.
   - Full legal text matches the canonical Markdown files in `shared/legal/`.
   - If the backend is unreachable or returns placeholder content, `LegalRepository.getAllCanonicalDocuments()` transparently serves the authoritative offline documents.
2. **Business Configuration Invariants:**
   - Centralized in `lib/src/features/legal/data/business_configuration.dart`.
   - Legal proprietor (MOHAMMED MOSIN S), brand (DRAUGHTSMAN STUDIO), and grievance email (`mosin@draughtsmanstudio.com`) are hardcoded constants that cannot be corrupted by external network failures.

