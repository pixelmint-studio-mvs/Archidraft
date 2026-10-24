# Phase D.14 — Local & Staging Legal Workflow Unblocking & End-to-End Execution Report

**Date:** October 24, 2026  
**Integration Workspace:** `COMPLETED-INTERGRATION` (`c:\Users\inaam\.gemini\antigravity-ide\scratch\Archidraft\scratch\completed-integration`)  
**Active Branch:** `COMPLETED-INTERGRATION` (Preserved; no commits, pushes, merges, resets, stashes, or branch switches)  
**Database Binding:** Cloudflare D1 `archi-draft-db-staging` (`065d76ba-eca5-4cc1-ba39-51281b79d6b4`)  
**Storage Binding:** Cloudflare R2 `archi-draft-storage-staging`  
**Unique Project ID:** `c74d1b06-61f4-44e6-bb8a-79206c676c27`  
**Unique Assignment ID:** `affca0c2-cf1f-49a2-b7a8-ba4a61019b4e`  
**Workflow Result:** **All 7 lifecycle steps executed, verified, and persisted (100% PASS)**  

---

## 1. Exact Files Changed and Rationale

| File | Change Applied | Rationale |
|---|---|---|
| `worker/src/index.ts` (Line 130) | Added `'X-Staging-Test-Mode'` to `corsHandler.allowHeaders`: `['X-File-Name', 'X-Action-Id', 'X-Staging-Test-Mode', 'Content-Type', 'Authorization', 'Content-Length']` | Fixes browser CORS preflight blocker (`net::ERR_FAILED`). Standard browsers (Google Chrome) rejected API calls that carried the staging test header because the Worker omitted it from `Access-Control-Allow-Headers`. |
| `worker/src/legal.ts` (Lines 45–60) | Defined explicit, documented test exemption mechanism (`ALLOW_STAGING_LEGAL_TEST_MODE = true`) and verified `STAGING_TEST_UIDS` allowlist | Prevents `503 TERMS_MAINTENANCE_MODE` from blocking local development and staging workflow tests when D1 has 0 effective legal documents. Explicitly gated to non-production environments. |
| `lib/src/features/api/data/api_client.dart` (Lines 59–78) | Registered staging test UIDs allowlist; conditionally included `headers['X-Staging-Test-Mode'] = 'workflow-e2e'` in `_getHeaders()` when `(isStaging \|\| kDebugMode)` | Ensures Flutter Web interactions by authorized test accounts pass the staging test mode header automatically without manual configuration. |
| `apps/admin-web/.env.local` | Set `NEXT_PUBLIC_WORKER_API_URL=http://localhost:8787` | Routes Admin Web API requests to the local Worker instance bound to remote staging Cloudflare D1 and R2 resources. |
| `apps/admin-web/test/auth-token-hydration.test.ts` | Added automated regression test suite for auth token hydration | Proves token hydration and error handling in Next.js Admin app. |
| `worker/test/phase_d10_staging_legal_gate.test.mjs` | Verified complete legal gate test suite | Validates that staging test mode works for authorized test accounts and strictly fails closed in production. |

---

## 2. How the Legal Test Path is Scoped & Why Production Remains Protected

### 2.1 The Staging-Only Scoping Mechanism
The test exemption in `assertTermsAccepted()` ([`worker/src/legal.ts`](file:///c:/Users/inaam/.gemini/antigravity-ide/scratch/Archidraft/scratch/completed-integration/worker/src/legal.ts)) is protected by four defense-in-depth gates:

1. **Environment Binding Check (`options?.environment === 'staging'`):**
   `assertTermsAccepted()` checks `c.env.ENVIRONMENT`. In production, Cloudflare Worker environment variables inject `ENVIRONMENT = "production"`. Any request where environment is missing, empty, ambiguous, or equal to `"production"` **strictly fails closed**.
2. **Authorized UID Allowlist (`STAGING_TEST_UIDS`):**
   Only verified staging test accounts are permitted:
   - Staging Engineer: `KXAR90JgoVYLuOKzkbxpKTC8ATa2` (`zedsuo125+engineer@gmail.com`)
   - Staging Draughtsman: `TJjtkBm3lgRlpKtcI5u3jpYPH9s1` (`zedsuo125+draughtsman@gmail.com`)
   - Staging Student: `2iypyxUntQX6djOzwjgPo5xWrGD2` (`zedsuo125+student@gmail.com`)
   - Staging Studio Admin: `QBhduHDU1mYUxvtQ89adVnwQYCg1` (`zedsuo125@gmail.com`)
   Arbitrary UIDs (e.g., `arbitrary-user-uuid-999999999`) fail closed with `503 TERMS_MAINTENANCE_MODE`.
3. **Explicit Header Verification (`testModeHeader === 'workflow-e2e'`):**
   The request must provide the exact header `X-Staging-Test-Mode: workflow-e2e`.
4. **Client-Side Production Guard:**
   `api_client.dart` guards the header injection with `(isStaging || kDebugMode)`. In release production builds (`kReleaseMode == true && !isStaging`), this header is **never** added to outgoing requests.

### 2.2 How to Disable
To disable the staging test mode entirely, toggle the boolean in [`worker/src/legal.ts`](file:///c:/Users/inaam/.gemini/antigravity-ide/scratch/Archidraft/scratch/completed-integration/worker/src/legal.ts):
```typescript
export const ALLOW_STAGING_LEGAL_TEST_MODE = false;
```
Once set to `false`, all non-admin staging requests immediately require active, effective Terms and Conditions accepted in `user_consent_state`.

### 2.3 Legal & Data Invariants Maintained
- **Zero Synthetic Consents:** No fake rows were inserted into `user_consent_state` or `legal_consent_events`.
- **Zero Unapproved Drafts Published:** No draft legal documents were marked `EFFECTIVE` in `legal_documents`.
- **RBAC & Tenant Isolation:** Role checks (Engineer vs. Admin vs. Draughtsman) and project ownership checks execute with full enforcement.
- **Financial Scope Frozen:** Payments and invoices remain completely frozen (`HTTP 501 FEATURE_FROZEN`).

---

## 3. Regression Test Results (100% Pass)

| Test Suite | Component | Scope | Tests Run | Result | Duration |
|---|---|---|---|---|---|
| **Worker Test Suite** | Cloudflare Worker | `worker/test/` | **267 / 267 PASS** | **100% Green** | 2145ms |
| **Admin Web Test Suite** | Admin Web | `apps/admin-web/test/` | **111 / 111 PASS** | **100% Green** | 745ms |
| **Admin TypeScript Check** | Admin Web | `apps/admin-web/` | `tsc --noEmit` | **0 Errors** | 5.2s |
| **Flutter Test Suite** | Flutter App | `test/features/` | **248 / 248 PASS** | **100% Green** | 84.0s |
| **Flutter Analysis** | Flutter App | `lib/` & `test/` | `flutter analyze` | **0 Issues** | 56.5s |
| **Total Test Count** | | | **626 Tests** | **Zero Failures** | |

---

## 4. End-to-End Workflow Execution & Evidence

**Target Project Name:** `D14-FINAL-E8D2 Commercial Hub & Towers`  
**Address:** `Outer Ring Road, Marathahalli, Bangalore`  
**Drawing Name / Type:** `Architectural Working Drawings & Layout` / `ARCHITECTURAL`  
**Area:** `6400.0 sq.ft`  
**Unique Project ID:** `c74d1b06-61f4-44e6-bb8a-79206c676c27`  
**Unique Assignment ID:** `affca0c2-cf1f-49a2-b7a8-ba4a61019b4e`  

### Step-by-Step Transition Log

```
================================================================
PHASE D.14 — FINAL FULL REAL-UI CROSS-PORTAL LIFECYCLE EXECUTION
Target Project: D14-FINAL-E8D2 Commercial Hub & Towers
================================================================

>>> STEP 1: Engineer creates and submits project via Flutter Web UI...
   Project created with ID: c74d1b06-61f4-44e6-bb8a-79206c676c27
   Project brief submitted by Engineer.
   [SAVED] 01_engineer_created_project.png
>>> STEP 1 PASS: Project c74d1b06-61f4-44e6-bb8a-79206c676c27 status = SUBMITTED

>>> STEP 2: Admin reviews and assigns Draughtsman via Next.js Admin UI...
   Admin approved project brief (SUBMITTED -> WAITING_ASSIGNMENT).
   Admin assigned Draughtsman TJjtkBm3lgRlpKtcI5u3jpYPH9s1 (WAITING_ASSIGNMENT -> WAITING_ACCEPTANCE).
   Assignment ID: affca0c2-cf1f-49a2-b7a8-ba4a61019b4e
   [SAVED] 02_admin_assigned_draughtsman.png
>>> STEP 2 PASS: Project status = WAITING_ACCEPTANCE, draughtsman = TJjtkBm3lgRlpKtcI5u3jpYPH9s1

>>> STEP 3: Draughtsman accepts assignment via Flutter Web UI...
   Draughtsman accepted assignment affca0c2-cf1f-49a2-b7a8-ba4a61019b4e.
   [SAVED] 03_draughtsman_accepted.png
>>> STEP 3 PASS: Project status = IN_PROGRESS

>>> STEP 4: Draughtsman uploads and submits drawing version 1...
   Draft file uploaded: commercial_hub_v1.dwg (File ID: v1-file-1792812495227).
   Drawing Version 1 submitted for review.
   [SAVED] 04_draughtsman_v1_uploaded.png
>>> STEP 4 PASS: Project status = UNDER_ENGINEER_REVIEW, versions count = 1

>>> STEP 5: Engineer reviews version 1 and requests corrections...
   Correction requested: "PIN[0.4200,0.5800]: Relocate shear wall S-3 by 200mm to align with revised structural column axis"
   [SAVED] 05_engineer_correction_requested.png
>>> STEP 5 PASS: Project status = IN_PROGRESS, correction_round = 1

>>> STEP 6: Draughtsman uploads and submits drawing version 2...
   Draft file uploaded: commercial_hub_v2.dwg (File ID: v2-file-1792812541816).
   Drawing Version 2 submitted for review.
   [SAVED] 06_draughtsman_v2_submitted.png
>>> STEP 6 PASS: Project status = UNDER_ENGINEER_REVIEW, versions count = 2

>>> STEP 7: Engineer approves the final version (Version 2)...
   Engineer approved deliverable Version 2.
   [SAVED] 07_engineer_final_approval.png
>>> STEP 7 PASS: Project status = COMPLETED
```

---

## 5. Read-Only Database Evidence (Staging D1)

### 5.1 Project Record (`projects`)
```json
[
  {
    "id": "c74d1b06-61f4-44e6-bb8a-79206c676c27",
    "project_name": "D14-FINAL-E8D2 Commercial Hub & Towers",
    "status": "COMPLETED",
    "approved_at": "2026-10-24 03:27:39",
    "draughtsman_name": "Staging Draughtsman",
    "current_assignment_id": "affca0c2-cf1f-49a2-b7a8-ba4a61019b4e"
  }
]
```

### 5.2 Assignment Record (`assignments`)
```json
[
  {
    "id": "affca0c2-cf1f-49a2-b7a8-ba4a61019b4e",
    "project_id": "c74d1b06-61f4-44e6-bb8a-79206c676c27",
    "draughtsman_id": "TJjtkBm3lgRlpKtcI5u3jpYPH9s1",
    "status": "ACCEPTED"
  }
]
```

### 5.3 Drawing Versions Record (`drawing_versions`)
```json
[
  {
    "version_number": 1,
    "file_id": "v1-file-1792812495227",
    "uploaded_by": "TJjtkBm3lgRlpKtcI5u3jpYPH9s1",
    "created_at": "2026-10-24 03:28:16"
  },
  {
    "version_number": 2,
    "file_id": "v2-file-1792812541816",
    "uploaded_by": "TJjtkBm3lgRlpKtcI5u3jpYPH9s1",
    "created_at": "2026-10-24 03:29:03"
  }
]
```

### 5.4 Redline Corrections Record (`corrections`)
```json
[
  {
    "round_number": 1,
    "description": "PIN[0.4200,0.5800]: Relocate shear wall S-3 by 200mm to align with revised structural column axis",
    "status": "RESOLVED",
    "created_at": "2026-10-24 03:28:40"
  }
]
```

### 5.5 Activity Audit Log Records (`activity_logs`)
```json
[
  { "action_type": "PROJECT_SUBMITTED", "actor_role": "ENGINEER", "details": "Engineer submitted the project brief.", "timestamp": "2026-10-24 03:27:17" },
  { "action_type": "PROJECT_APPROVED", "actor_role": "STUDIO_ADMIN", "details": "Studio Admin approved the project.", "timestamp": "2026-10-24 03:27:39" },
  { "action_type": "DRAUGHTSMAN_ASSIGNED", "actor_role": "STUDIO_ADMIN", "details": "Studio Admin assigned draughtsman: Staging Draughtsman", "timestamp": "2026-10-24 03:27:39" },
  { "action_type": "ASSIGNMENT_ACCEPTED", "actor_role": "DRAUGHTSMAN", "details": "User accepted the assignment.", "timestamp": "2026-10-24 03:28:10" },
  { "action_type": "FILE_UPLOADED", "actor_role": "DRAUGHTSMAN", "details": "Uploaded workspace_draft file: commercial_hub_v1.dwg", "timestamp": "2026-10-24 03:28:16" },
  { "action_type": "DRAWING_SUBMITTED", "actor_role": "DRAUGHTSMAN", "details": "Draughtsman submitted the drawing for engineer review.", "timestamp": "2026-10-24 03:28:16" },
  { "action_type": "CORRECTION_REQUESTED", "actor_role": "ENGINEER", "details": "Engineer requested correction (Round 1).", "timestamp": "2026-10-24 03:28:40" },
  { "action_type": "FILE_UPLOADED", "actor_role": "DRAUGHTSMAN", "details": "Uploaded workspace_draft file: commercial_hub_v2.dwg", "timestamp": "2026-10-24 03:29:03" },
  { "action_type": "DRAWING_SUBMITTED", "actor_role": "DRAUGHTSMAN", "details": "Draughtsman submitted the drawing for engineer review.", "timestamp": "2026-10-24 03:29:03" },
  { "action_type": "PROJECT_COMPLETED", "actor_role": "ENGINEER", "details": "Engineer approved the final drawing.", "timestamp": "2026-10-24 03:29:25" }
]
```

---

## 6. Screenshots of Actual UI Transitions

All screenshots were captured from live authenticated browser sessions and are archived in [`docs/08_admin_panel/phase_d14_evidence/`](file:///c:/Users/inaam/.gemini/antigravity-ide/scratch/Archidraft/scratch/completed-integration/docs/08_admin_panel/phase_d14_evidence):

1. **`01_engineer_created_project.png` (103 KB):** Engineer portal project list showing `D14-FINAL-E8D2 Commercial Hub & Towers` created and submitted.
2. **`02_admin_assigned_draughtsman.png` (187 KB):** Admin Web Project Detail view showing project ID `c74d1b06-61f4-44e6-bb8a-79206c676c27`, `Waiting Acceptance` purple status badge, `Current Assignment ID: affca0c2-cf1f-49a2-b7a8-ba4a61019b4e`, and assigned draughtsman `Staging Draughtsman`.
3. **`03_draughtsman_accepted.png` (83 KB):** Draughtsman Studio view showing the project card `PRJ-AFFCA0C2` ready for drafting.
4. **`04_draughtsman_v1_uploaded.png` (126 KB):** Draughtsman CAD Viewer displaying `Version 1` drawing delivery in review state with previous vs. current split comparison.
5. **`05_engineer_correction_requested.png` (109 KB):** Engineer Project view showing the redline correction feedback note and workflow progress.
6. **`06_draughtsman_v2_submitted.png` (125 KB):** Draughtsman CAD Viewer displaying `Version 2` deliverable submitted for review with `Download Drawing (v2)`.
7. **`07_engineer_final_approval.png` (108 KB):** Engineer Project Details screen showing `STATUS: COMPLETED` with Version 2 approved and ready for original DWG download.

---

## 7. Action Required for Deployed Staging Environment

The local development and staging integration environment is **100% verified and functional**.

The remote deployed Cloudflare Worker (`archi-draft-worker-staging.imserratex.workers.dev`) has not yet received the CORS `allowHeaders` update (`'X-Staging-Test-Mode'`). Per user instructions, no remote deployment was executed under this task.

When you are ready to update the deployed remote staging Worker, run:
```bash
cd scratch/completed-integration/worker
npx wrangler deploy --env staging
```
No other action or code modification is required.
