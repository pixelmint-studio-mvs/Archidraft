# Archi Draft — Phase D.1 Remediation, Staging Readiness & Cross-Portal E2E Report

**Audit & Remediation Date:** October 23, 2026  
**Integration Branch:** `COMPLETED-INTERGRATION`  
**Base Checkpoint Commit:** `90a2b3b36d83d776d1f1ee6914759df5af89deb5`  
**Execution Context:** Isolated Integration Worktree (`scratch/completed-integration`)  
**Main Workspace Status:** `feature/admin-panel-complete` completely untouched and preserved  

---

## 1. Executive Summary & Release Readiness Decision

| Verification Dimension | Status | Summary & Evidence |
| :--- | :---: | :--- |
| **Phase A Verified Blockers** | **REMEDIATED** | All 4 verified blockers resolved and tested: (A) Staging isolation in Wrangler + fail-closed guard; (B) CORS allowlist with credentials & origin validation; (C) Flutter dead assignment routes updated + Worker backwards-compatibility aliases; (D) Flutter release build API URL enforcement (`--dart-define=API_URL=https://...`). |
| **Phase B Staging Readiness** | **PROVISIONING BLUEPRINT READY (STAGING BLOCKED)** | Staging configuration is structurally isolated in `wrangler.toml` and protected by `scripts/preflight_guard.mjs`. Remote staging environment cannot be considered operational until operator provisions staging D1/R2 and replaces `STAGING_D1_DATABASE_ID_PLACEHOLDER`. |
| **Phase C Cross-Portal E2E** | **PASSED (LOCAL EMULATED BACKEND)** | Full cross-portal lifecycle verified via 22 automated integration scenarios: Engineer submission → Admin approval/assignment → Draughtsman acceptance/deliverable → Engineer final approval; plus 3-round correction cap, student isolation, suspension enforcement, and 4-assignment capacity. |
| **Legal Consent Gate** | **ACTIVE / BLOCKED ON OFFICIAL CONTENT** | Mandatory `assertTermsAccepted` gate is active and verified in backend and mobile. Production deployment remains blocked on authoritative legal text ingestion. |
| **Financial Scope** | **FROZEN & VERIFIED** | `/financials` panel preserved read-only; mutation endpoints return HTTP 501 `FEATURE_FROZEN`; zero third-party payment gateways present. |
| **Production Decision** | **NO-GO** | Blocked on operator remote staging resource provisioning, legal content signoff, and live remote staging validation. Local codebase is clean, fully verified, and ready for staging deployment. |

---

## 2. Phase A: Blocker Remediation Summary

### Blocker 1: Staging/Production Isolation
- **Files Changed:** [`worker/wrangler.toml`](file:///worker/wrangler.toml), [`worker/scripts/preflight_guard.mjs`](file:///worker/scripts/preflight_guard.mjs), [`worker/package.json`](file:///worker/package.json).
- **Remediation Details:**
  - Added dedicated `[env.staging]` and `[env.production]` sections in `wrangler.toml`.
  - Staging targets `archi-draft-worker-staging`, D1 database `archi-draft-db-staging`, and R2 bucket `archi-draft-storage-staging`.
  - Production targets `archi-draft-worker-production`, D1 database `archi-draft-db` (`af8d3312-5f6e-46ce-bcc1-dfa91e484cc0`), and R2 bucket `archi-draft-storage`.
  - Implemented fail-closed guard script `node worker/scripts/preflight_guard.mjs --env <staging|production>`. It parses environment blocks, prevents collision between staging and production resource IDs, and blocks any deployment or migration if placeholder strings are detected.
  - Added npm scripts: `npm run preflight:staging` and `npm run preflight:prod`.

### Blocker 2: CORS Allowlist & Credentials
- **Files Changed:** [`worker/src/index.ts`](file:///worker/src/index.ts).
- **Remediation Details:**
  - Replaced wildcard `origin: '*'` with an explicit environment-aware origin validator.
  - Baseline production allowlist strictly contains `https://admin.draughtsmanstudio.com` and `https://archi-draft.vercel.app`.
  - Staging and preview domains are dynamically supplied via `c.env.ALLOWED_ORIGINS` (comma-separated list).
  - Credentials support enabled (`credentials: true`).
  - Localhost (`localhost`, `127.0.0.1`) is permitted **only** in non-production environments (`c.env.ENVIRONMENT !== 'production'`). In production, localhost requests are rejected.
  - Arbitrary origins receive no allow-origin header (`null`) and are never reflected.

### Blocker 3: Flutter Dead API Routes
- **Files Changed:** [`lib/src/features/projects/data/project_repository.dart`](file:///lib/src/features/projects/data/project_repository.dart), [`worker/src/index.ts`](file:///worker/src/index.ts).
- **Remediation Details:**
  - Replaced obsolete `/api/projects/accept` with `/api/assignments/accept` in `ProjectRepository.acceptAssignment`.
  - Replaced obsolete `/api/projects/reject-assignment` with `/api/assignments/reject` in `ProjectRepository.rejectAssignment`.
  - Updated backend handlers `handleAcceptAssignment` and `handleRejectAssignment` to support resolution by either `assignmentId` or `projectId` (using `current_assignment_id`).
  - Registered backward-compatibility route aliases `POST /api/projects/accept` and `POST /api/projects/reject-assignment` in Worker so legacy mobile app versions do not break during transition.

### Blocker 4: Flutter Release API URL Configuration
- **Files Changed:** [`lib/src/features/api/data/api_client.dart`](file:///lib/src/features/api/data/api_client.dart), [`lib/main.dart`](file:///lib/main.dart).
- **Remediation Details:**
  - Implemented `ApiClient.resolveBaseUrl()`.
  - In release mode (`kReleaseMode`):
    - Fails fast (`StateError`) if `API_URL` is unconfigured (`--dart-define=API_URL=...` missing or empty).
    - Fails fast (`StateError`) if `API_URL` is not a valid `https://` URL.
    - Fails fast (`StateError`) if `API_URL` points to `localhost`, `127.0.0.1`, or `::1`.
  - In debug/development mode:
    - Defaults safely to `http://localhost:8787` for local emulation.
  - Added startup validation call in `main()` in `lib/main.dart` to fail early at application boot before network activity occurs.

---

## 3. Phase B: Staging Readiness & Provisioning Blueprint

### Staging Resource Checklist
| Component | Status | Configured Value / Target | Action Required by Operator |
| :--- | :---: | :--- | :--- |
| **Cloudflare Account** | Verified | Account `06fbb6f8b2e1e65612347252ea10574c` | Authorized operator credentials active |
| **Staging Worker** | Configured | `archi-draft-worker-staging` | Ready for deploy once D1 is created |
| **Staging D1 Database** | **Pending Operator Provisioning** | `archi-draft-db-staging`<br>ID: `STAGING_D1_DATABASE_ID_PLACEHOLDER` | Operator must run: `npx wrangler d1 create archi-draft-db-staging` |
| **Staging R2 Bucket** | **Pending Operator Provisioning** | `archi-draft-storage-staging` | Operator must run: `npx wrangler r2 bucket create archi-draft-storage-staging` |
| **Staging Firebase** | Template Ready | Isolated Staging Firebase Project | Operator must register staging bundle IDs and configure auth domains |
| **Admin Web Staging** | Ready | Vercel Environment variables | Set `NEXT_PUBLIC_API_URL=https://archi-draft-worker-staging...` |
| **Staging D1 Migrations** | Validated Locally | Migrations `0001` through `0020` | Run against remote staging only after D1 ID is supplied |

### Exact Operator Provisioning Commands
```bash
# 1. Create Staging D1 Database
npx wrangler d1 create archi-draft-db-staging

# 2. Update worker/wrangler.toml
# Replace STAGING_D1_DATABASE_ID_PLACEHOLDER under [[env.staging.d1_databases]] with returned UUID

# 3. Create Staging R2 Bucket
npx wrangler r2 bucket create archi-draft-storage-staging

# 4. Verify Staging Isolation Preflight Guard
npm run preflight:staging

# 5. Apply Migrations to Remote Staging (ONLY AFTER EXPLICIT APPROVAL)
npx wrangler d1 migrations apply archi-draft-db-staging --env staging --remote

# 6. Deploy Worker to Staging (ONLY AFTER EXPLICIT APPROVAL)
npx wrangler deploy --env staging
```

---

## 4. Phase C: Cross-Portal E2E Verification Matrix

All 9 lifecycle steps were verified using the comprehensive automated suite in [`worker/test/phase_d_remediation.test.mjs`](file:///worker/test/phase_d_remediation.test.mjs):

| Step | Portal & Role | Action & Endpoint | State Transition | Result |
| :---: | :--- | :--- | :--- | :---: |
| **1** | Engineer (`eng-1`) | `POST /api/projects`<br>`POST /api/projects/submit` | `DRAFT` → `SUBMITTED`<br>Client ID bound to `eng-1` | **PASS** |
| **2** | Studio Admin (`admin-1`) | `GET /api/projects`<br>`POST /api/projects/approve`<br>`POST /api/projects/assign` | `SUBMITTED` → `WAITING_ASSIGNMENT`<br>`WAITING_ASSIGNMENT` → `WAITING_ACCEPTANCE`<br>`current_assignment_id` and `draughtsman_id` bound to `drg-1` | **PASS** |
| **3** | Draughtsman (`drg-1`) | `GET /api/assignments`<br>`POST /api/assignments/accept`<br>`POST /api/projects/submit-drawing` | `WAITING_ACCEPTANCE` → `IN_PROGRESS`<br>`IN_PROGRESS` → `UNDER_ENGINEER_REVIEW` | **PASS** |
| **4** | Engineer (`eng-1`) | `POST /api/projects/approve-final` | `UNDER_ENGINEER_REVIEW` → `COMPLETED` | **PASS** |
| **5** | Engineer & Draughtsman | `POST /api/projects/request-correction`<br>(Rounds 1, 2, 3)<br>`POST /api/projects/submit-drawing` | Revisions 1, 2, 3 permitted.<br>4th correction rejected with HTTP 400 `Maximum correction rounds (3) exceeded` | **PASS** |
| **6** | Student (`student-1`) | `GET /api/projects`<br>`GET /api/projects/:id` | Attempting to access commercial project or admin list strictly rejected with HTTP 403 `Forbidden` | **PASS** |
| **7** | Suspended Engineer (`eng-suspended`) | `POST /api/projects` | Account suspended check triggered; rejected with HTTP 403 `Account suspended. Contact administrator.` | **PASS** |
| **8** | Studio Admin (`admin-1`) | `POST /api/projects/:id/invoices`<br>`POST /api/invoices/:id/payments` | Financial mutations blocked with HTTP 501 `code: 'FEATURE_FROZEN'` | **PASS** |
| **9** | Studio Admin (`admin-1`) | `POST /api/projects/assign` | Assigning 5th concurrent project to `drg-2` rejected with HTTP 400 `DRAUGHTSMAN_CAPACITY_EXCEEDED` | **PASS** |

---

## 5. Test Evidence Summary

```text
========================================================================================
TEST SUITE RUNNER SUMMARY (OCTOBER 23, 2026)
========================================================================================

1. Worker Backend Integration Suite:
   Command: npm test (in worker/)
   Results: 259 passing / 0 failing / 0 skipped (Duration: 5.3s)
   Coverage:
     - test/backend_authorization.test.mjs
     - test/cross_user_isolation_f1.test.mjs
     - test/admin_student_contract.test.mjs
     - test/legal_privacy_authorization.test.mjs
     - test/phase_b_security_remediation.test.mjs
     - test/phase_c_remediation.test.mjs
     - test/phase_d_remediation.test.mjs (22/22 pass: CORS, assignment aliases, E2E lifecycle)

2. Worker TypeScript Compilation:
   Command: npm run typecheck (in worker/)
   Results: tsc --noEmit exited 0 (clean compilation, 0 errors)

3. Admin Web Integration Suite:
   Command: npm test (in apps/admin-web/)
   Results: 108 passing / 0 failing / 0 skipped (Duration: 1.0s)
   Coverage: Redline coordinates, user governance, SLA turnaround, upload ceilings, capacity caps

4. Admin Web Production Build:
   Command: npm run build (in apps/admin-web/)
   Results: Next.js 16.4.2 Turbopack optimized build succeeded.
            22/22 routes prerendered / partial-prerendered. 0 TypeScript errors.

5. Flutter Unit & Contract Tests:
   Commands:
     - flutter test test/features/api/data/api_client_test.dart --no-pub (8/8 pass)
     - flutter test test/features/projects/data/project_repository_test.dart --no-pub (2/2 pass)
     - flutter test test/unit/ --no-pub (58/58 pass)
   Total Flutter Tests Passing: 68 passing / 0 failing

6. Preflight Guard Isolation Verification:
   - Staging (Placeholder active): Exits 1 [BLOCKED] as expected.
   - Production (Configured active): Exits 0 [PASSED] as expected.
========================================================================================
```

---

## 6. Risk Register & Remaining Blockers

| Blocker ID | Description | Severity | Owner | Required Next Action |
| :---: | :--- | :---: | :---: | :--- |
| **BLK-01** | Staging D1 database & R2 bucket not provisioned on Cloudflare | **High** | Cloudflare Operator | Run `wrangler d1 create` and `wrangler r2 bucket create` with staging names. |
| **BLK-02** | Official legal content not ingested | **High** | Legal / Content Owner | Provide approved Terms & Conditions and Privacy Policy markdown text. |
| **BLK-03** | Staging Firebase project credentials & custom claims | **Medium** | Firebase Admin | Register staging mobile apps and set up staging test user claims. |
| **BLK-04** | Live cross-portal staging smoke test | **Medium** | QA / Lead Engineer | Execute smoke test against deployed staging URL once BLK-01 is complete. |

---

## 7. Production Readiness Recommendation

### Decision: **NO-GO FOR PRODUCTION**

**Rationale:**
1. Staging infrastructure must be provisioned and verified before any production rollout.
2. Official legal documents must be formally signed off and ingested into D1.
3. Live cross-portal E2E tests must be run against the deployed staging Worker and D1 database before production authorization.

### Staging Deployment Readiness: **READY FOR PROVISIONING**
The local codebase is clean, backwards-compatible, robustly tested, and fully prepared for deployment to an isolated staging environment once remote Cloudflare resources are created.

---

## 8. Git Safety & Workspace Integrity Log

- **Current Branch:** `COMPLETED-INTERGRATION`
- **Current HEAD:** `90a2b3b36d83d776d1f1ee6914759df5af89deb5`
- **Worktree Path:** `c:\Users\inaam\.gemini\antigravity-ide\scratch\Archidraft\scratch\completed-integration`
- **Main Workspace Status:** `c:\Users\inaam\.gemini\antigravity-ide\scratch\Archidraft` (`feature/admin-panel-complete` at `8ea5d4c5`) is completely untouched and preserved.
- **Unstaged Changes in Worktree:**
  - Modified:
    - `lib/main.dart`
    - `lib/src/features/api/data/api_client.dart`
    - `lib/src/features/projects/data/project_repository.dart`
    - `worker/package.json`
    - `worker/src/index.ts`
    - `worker/wrangler.toml`
  - Untracked:
    - `docs/08_admin_panel/PHASE_D1_REMEDIATION_E2E_REPORT.md`
    - `test/features/api/data/api_client_test.dart`
    - `test/features/projects/data/project_repository_test.dart`
    - `worker/scripts/preflight_guard.mjs`
    - `worker/test/phase_d_remediation.test.mjs`
- **Boundary Compliance:**
  - Zero git commits created.
  - Zero branches pushed or merged.
  - Zero remote deployments executed.
  - Zero remote D1 migrations executed.
  - Zero production configuration or data modified.
