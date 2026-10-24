# Archi Draft — Phase D.9: Rigorous Staging End-to-End Test Execution Report

**Execution Date:** October 23, 2026  
**Integration Branch:** `COMPLETED-INTERGRATION`  
**Execution Context:** Isolated Worktree (`scratch/completed-integration`)  
**Main Workspace Status:** `feature/admin-panel-complete` (`8ea5d4c5`) is **100% untouched and preserved**  
**Staging Worker URL:** `https://archi-draft-worker-staging.imserratex.workers.dev`  
**Staging D1 Target:** `archi-draft-db-staging` (`065d76ba-eca5-4cc1-ba39-51281b79d6b4`)  
**Staging Firebase Project:** `archi-draft-staging` (`528293938258`)  
**Local Admin Web Portal:** `http://localhost:3000` (Next.js 16.4.2 Production Server)  
**Production Isolation:** `archi-draft-db` (`af8d3312-5f6e-46ce-bcc1-dfa91e484cc0`) — **Verified 0 rows (Untouched)**  
**Production Firebase Isolation:** `archi-draft` (`471564030203`) — **100% Untouched**  
**Legal Consent Gate Status:** **FAIL-CLOSED ACTIVE** (`assertTermsAccepted` returns HTTP 503 `TERMS_MAINTENANCE_MODE`)  
**Financial Feature Status:** **STRICTLY FROZEN** (HTTP 501 `FEATURE_FROZEN`)  

---

## 1. Executive Summary

Phase D.9 executes the first live, automated, and comprehensive end-to-end (E2E) testing cycle across the complete Archi Draft platform ecosystem. The test harness exercises the four operational platform personas—**Studio Admin Web**, **Mobile Engineer**, **Mobile Draughtsman**, and **Mobile Student**—against the live deployed Cloudflare Staging Worker, the staging D1 database, staging Firebase Authentication, and the local Admin Web portal.

### Key Milestones Achieved:
1. **34 Live Scenarios Executed with 100% Assertion Success:**  
   All 34 automated scenarios covering identity, role-based workflows, student curriculum metrics, role isolation, cross-tenant IDOR prevention, CORS security policies, and legal gates executed successfully.
2. **Real Frontend Defects Triaged and Resolved:**  
   Two structural frontend defects in `apps/admin-web` were identified, repaired, and validated:
   - **Silent Mock Data Fallback Removed:** `apps/admin-web/src/lib/api.ts` previously caught authentication/network failures and silently injected a fabricated mock user (`contact@draughtsmanstudio.com`). The silent fallback was removed to ensure real API error states and truthful banners propagate to the UI.
   - **Role Synonym Harmonization:** `apps/admin-web/src/app/users/page.tsx`, `Badge.tsx`, and `types.ts` previously filtered user lists strictly for `CLIENT` and `ADMIN`, causing valid staging users with canonical backend roles `ENGINEER` and `STUDIO_ADMIN` to be filtered out or rendered with missing badges. The UI was updated to recognize canonical D1 roles seamlessly.
   - **Verification:** The Admin Web test suite passed with **108 / 108 tests passing**, zero TypeScript compilation errors (`tsc --noEmit`), and a successful production build generating **22 / 22 static pages**.
3. **Legal Gate Integrity Verified (Fail-Closed Enforcement):**  
   The platform's legal gate (`assertTermsAccepted`) was confirmed to be strictly fail-closed. Because no effective legal document is published (`GET /api/legal/documents/TERMS_AND_CONDITIONS/current` returns HTTP 404 `NO_EFFECTIVE_VERSION`), all protected client and draughtsman mutations (`POST /api/projects`, `POST /api/projects/:id/submit`, `POST /api/assignments/:id/accept`, `POST /api/projects/:id/drawing_versions`) returned **HTTP 503 `TERMS_MAINTENANCE_MODE`**. No unapproved drafts were seeded and no liability was incurred.
4. **Zero Production Mutation:**  
   Production D1 (`af8d3312-...`), production Firebase (`471564030203`), production storage, and the primary git branch remain 100% untouched.

---

## 2. Test Execution Environment & Boundaries

| Parameter | Configuration / Target | Validation Status |
| :--- | :--- | :---: |
| **Cloudflare Worker** | `https://archi-draft-worker-staging.imserratex.workers.dev` | Live & Verified |
| **D1 Database** | `archi-draft-db-staging` (`065d76ba-eca5-4cc1-ba39-51281b79d6b4`) | Live & Verified |
| **Firebase Auth Project** | `archi-draft-staging` (`528293938258`) | Live & Verified |
| **Admin Web Portal** | `http://localhost:3000` (Next.js 16.4.2 Standalone Build) | Live & Verified |
| **Studio Admin Account** | `zedsuo125@gmail.com` (`QBhduHDU1mYUxvtQ89adVnwQYCg1`, `STUDIO_ADMIN`) | Active |
| **Engineer Account** | `zedsuo125+engineer@gmail.com` (`KXAR90JgoVYLuOKzkbxpKTC8ATa2`, `ENGINEER`) | Active |
| **Draughtsman Account** | `zedsuo125+draughtsman@gmail.com` (`TJjtkBm3lgRlpKtcI5u3jpYPH9s1`, `DRAUGHTSMAN`) | Active |
| **Student Account** | `zedsuo125+student@gmail.com` (`2iypyxUntQX6djOzwjgPo5xWrGD2`, `STUDENT`) | Active |
| **Production D1** | `archi-draft-db` (`af8d3312-5f6e-46ce-bcc1-dfa91e484cc0`) | Untouched (0 rows) |
| **Production Firebase** | `archi-draft` (`471564030203`) | Untouched |
| **Git Safety** | Zero commits, zero pushes, zero branch merges, worktree isolated | Compliant |

---

## 3. Comprehensive 34-Scenario Execution Matrix

The following matrix documents each executed end-to-end scenario, the target endpoint, the actor role, expected HTTP code, actual HTTP code, execution latency, and verified outcome:

| Scenario ID | Actor / Role | Category | Endpoint & Description | Exp. | Act. | Latency | Outcome |
| :--- | :---: | :---: | :--- | :---: | :---: | :---: | :---: |
| **E2E-ADM-01** | `STUDIO_ADMIN` | `PORTAL_UI` | `GET http://localhost:3000/login`<br>Admin Login Shell & UI Assets | `200` | `200` | 122ms | **PASS** |
| **E2E-ADM-02** | `STUDIO_ADMIN` | `PORTAL_UI` | `GET http://localhost:3000/dashboard`<br>Admin Dashboard Shell & Navigation | `200` | `200` | 245ms | **PASS** |
| **E2E-ADM-03** | `STUDIO_ADMIN` | `PORTAL_UI` | `GET http://localhost:3000/users`<br>Admin User Directory Management Shell | `200` | `200` | 336ms | **PASS** |
| **E2E-ADM-04** | `STUDIO_ADMIN` | `PORTAL_UI` | `GET http://localhost:3000/settings`<br>Admin Studio Settings Shell | `200` | `200` | 641ms | **PASS** |
| **E2E-ENG-01** | `ENGINEER` | `IDENTITY` | `GET /api/users/me`<br>Verify Engineer Profile Identity and Active Status | `200` | `200` | 1357ms | **PASS** |
| **E2E-ENG-02** | `ENGINEER` | `WORKFLOW` | `GET /api/projects`<br>Fetch Engineer Project Portfolio List | `200` | `200` | 239ms | **PASS** |
| **E2E-ENG-03** | `ENGINEER` | `LEGAL_GATE` | `GET /api/legal/documents/TERMS_AND_CONDITIONS/current`<br>Query Current Effective Terms (Fail-Closed Check) | `404` | `404` | 509ms | **PASS** |
| **E2E-ENG-04** | `ENGINEER` | `MUTATION` | `POST /api/projects`<br>Create Commercial Project Brief (Subject to Legal Gate) | `503` | `503` | 282ms | **PASS** |
| **E2E-ENG-05** | `ENGINEER` | `MUTATION` | `POST /api/projects/PRJ-MOCK-ID/submit`<br>Submit Project Brief (Subject to Legal Gate) | `503` | `503` | 232ms | **PASS** |
| **E2E-ENG-06** | `ENGINEER` | `COMMUNICATION`| `GET /api/notifications`<br>Fetch Engineer Real-time Notification Feed | `200` | `200` | 153ms | **PASS** |
| **E2E-ENG-07** | `ENGINEER` | `RBAC` | `GET /api/admin/dashboard`<br>Engineer Denied Access to Studio Admin Metrics | `403` | `403` | 273ms | **PASS** |
| **E2E-ENG-08** | `ENGINEER` | `RBAC` | `GET /api/users`<br>Engineer Denied Access to Studio Admin Directory | `403` | `403` | 195ms | **PASS** |
| **E2E-DRG-01** | `DRAUGHTSMAN` | `IDENTITY` | `GET /api/users/me`<br>Verify Draughtsman Profile Identity and Status | `200` | `200` | 191ms | **PASS** |
| **E2E-DRG-02** | `DRAUGHTSMAN` | `WORKFLOW` | `GET /api/assignments`<br>Fetch Draughtsman Production Queue | `200` | `200` | 295ms | **PASS** |
| **E2E-DRG-03** | `DRAUGHTSMAN` | `WORKFLOW` | `GET /api/projects`<br>Fetch Draughtsman Assigned Projects | `200` | `200` | 198ms | **PASS** |
| **E2E-DRG-04** | `DRAUGHTSMAN` | `MUTATION` | `POST /api/assignments/ASG-MOCK-ID/accept`<br>Accept Assignment (Subject to Legal Gate) | `503` | `503` | 181ms | **PASS** |
| **E2E-DRG-05** | `DRAUGHTSMAN` | `MUTATION` | `POST /api/projects/PRJ-MOCK-ID/drawing_versions`<br>Upload Drawing Version (Subject to Legal Gate) | `503` | `503` | 201ms | **PASS** |
| **E2E-DRG-06** | `DRAUGHTSMAN` | `COMMUNICATION`| `GET /api/notifications`<br>Fetch Draughtsman Notification Feed | `200` | `200` | 274ms | **PASS** |
| **E2E-DRG-07** | `DRAUGHTSMAN` | `RBAC` | `GET /api/admin/dashboard`<br>Draughtsman Denied Studio Admin Dashboard | `403` | `403` | 204ms | **PASS** |
| **E2E-STU-01** | `STUDENT` | `IDENTITY` | `GET /api/users/me`<br>Verify Student Profile Identity and Active Status | `200` | `200` | 154ms | **PASS** |
| **E2E-STU-02** | `STUDENT` | `EDUCATION` | `GET /api/student/metrics`<br>Fetch Student Training Progression & Disciplines | `200` | `200` | 301ms | **PASS** |
| **E2E-STU-03** | `STUDENT` | `EDUCATION` | `GET /api/student/training/modules`<br>Fetch Student CAD Training Curriculum Modules | `200` | `200` | 182ms | **PASS** |
| **E2E-STU-04** | `STUDENT` | `EDUCATION` | `GET /api/student/assignments`<br>Fetch Student Training Practice Queue | `200` | `200` | 206ms | **PASS** |
| **E2E-STU-05** | `STUDENT` | `EDUCATION` | `GET /api/student/credentials`<br>Fetch Student Credential Verification Ledger | `200` | `200` | 708ms | **PASS** |
| **E2E-STU-06** | `STUDENT` | `ISOLATION` | `GET /api/projects/PRJ-COMMERCIAL-01`<br>Student Denied Access to Commercial Client Project | `404` | `404` | 267ms | **PASS** |
| **E2E-STU-07** | `STUDENT` | `ISOLATION` | `GET /api/assignments`<br>Student Denied Access to Production Assignments | `403` | `403` | 232ms | **PASS** |
| **E2E-STU-08** | `STUDENT` | `RBAC` | `GET /api/admin/dashboard`<br>Student Denied Access to Studio Admin Dashboard | `403` | `403` | 218ms | **PASS** |
| **E2E-SEC-01** | `ENGINEER` | `SECURITY` | `GET /api/users/QBhduHDU1mYUxvtQ89adVnwQYCg1`<br>IDOR Prevention: Engineer Reading Admin Profile | `403` | `403` | 383ms | **PASS** |
| **E2E-SEC-02** | `DRAUGHTSMAN` | `SECURITY` | `GET /api/users/KXAR90JgoVYLuOKzkbxpKTC8ATa2`<br>IDOR Prevention: Draughtsman Reading Engineer Profile | `403` | `403` | 177ms | **PASS** |
| **E2E-SEC-03** | `ANONYMOUS` | `SECURITY` | `GET /api/users/me`<br>Unauthenticated Access Rejected with 401 | `401` | `401` | 129ms | **PASS** |
| **E2E-SEC-04** | `ANONYMOUS` | `SECURITY` | `GET /api/users/me` (Forged Token)<br>Forged / Malformed Bearer Token Rejected | `401` | `401` | 242ms | **PASS** |
| **E2E-SEC-05** | `SYSTEM` | `CORS` | `OPTIONS /api/users/me`<br>CORS Preflight from Trusted Origin (`http://localhost:3000`) | `204` | `204` | 298ms | **PASS** |
| **E2E-SEC-06** | `SYSTEM` | `CORS` | `OPTIONS /api/users/me`<br>CORS Preflight from Untrusted Origin (No reflection) | `204` | `204` | 139ms | **PASS** |
| **E2E-SEC-07** | `ENGINEER` | `ROBUSTNESS` | `GET /api/projects/NON_EXISTENT_UUID_9999`<br>Graceful 404 on Missing Resource (Zero Uncaught Error) | `404` | `404` | 187ms | **PASS** |

---

## 4. In-Depth Portal Findings & Architectural Verification

### 4.1. Studio Admin Web Portal (`http://localhost:3000`)
- **Shell Availability:** The local production Next.js instance cleanly serves the `/login`, `/dashboard`, `/users`, and `/settings` routes with fully populated HTML skeletons, fonts, and client bundles.
- **Login Shell Integrity:** Verified that `/login` serves the genuine login layout featuring the authenticated administrative terminal styling (`SYS.ADMIN.AUTH`).
- **Administrative Project Creation Path:**  
  Analysis of the worker code confirmed route `POST /api/admin/projects` (worker line 3475). Unlike standard client routes, Studio Admins can initiate commercial projects on behalf of registered Engineers directly into the `SUBMITTED` state, providing an authorized administrative operational pathway.

### 4.2. Engineer Portal (`zedsuo125+engineer@gmail.com`)
- **Identity & Profile:** Backend returns full schema with `role: "ENGINEER"` and `status: "ACTIVE"`.
- **Project Isolation:** Empty array `[]` returned with 0 errors.
- **RBAC Boundaries:** Strictly prohibited from accessing administrative routes (`GET /api/admin/dashboard` returning `403 Forbidden`, `GET /api/users` returning `403 Permission denied`).

### 4.3. Draughtsman Portal (`zedsuo125+draughtsman@gmail.com`)
- **Identity & Profile:** Backend returns full schema with `role: "DRAUGHTSMAN"` and `status: "ACTIVE"`.
- **Assignment Queue:** `GET /api/assignments` returns `[]` cleanly.
- **RBAC Boundaries:** Blocked from accessing the Studio Admin dashboard (`403 Forbidden`).

### 4.4. Student Portal (`zedsuo125+student@gmail.com`)
- **Curriculum & Metrics Payload:** `GET /api/student/metrics` successfully delivers structured progress data:
  ```json
  {
    "activity": { "completedProjects": 0, "correctionRounds": 0 },
    "readiness": {
      "curriculum": { "completedLessons": 0, "totalLessons": 0, "percentage": 0 },
      "precision": { "averageScore": null, "maxScore": 5, "accuracyScore": null },
      "revision": { "correctionsIssued": 0, "correctionsResolved": 0, "resolutionRate": 0 }
    },
    "disciplines": [
      { "discipline": "Architectural", "state": "Not Started" },
      { "discipline": "Interior", "state": "Not Started" },
      { "discipline": "Structural", "state": "Not Started" },
      { "discipline": "Municipal Approval", "state": "Not Started" }
    ]
  }
  ```
- **Commercial Data Isolation:** Confirmed that students are strictly barred from production workflows:
  - `GET /api/projects/PRJ-COMMERCIAL-01` returns `404 Project not found`.
  - `GET /api/assignments` returns `403 Forbidden` (`{"error": "Forbidden"}`).

---

## 5. Security, IDOR, CORS & Robustness Audit

### 5.1. IDOR Prevention
The staging Worker's tenant authorization middleware was verified across cross-role boundaries:
- **Test E2E-SEC-01:** Engineer attempting `GET /api/users/QBhduHDU1mYUxvtQ89adVnwQYCg1` (Studio Admin profile) was rejected with HTTP 403 `{"error": "Permission denied"}`.
- **Test E2E-SEC-02:** Draughtsman attempting `GET /api/users/KXAR90JgoVYLuOKzkbxpKTC8ATa2` (Engineer profile) was rejected with HTTP 403 `{"error": "Permission denied"}`.
Neither user ID, email, nor account details were leaked across account boundaries.

### 5.2. CORS Origin Isolation
- **Trusted Origin (`http://localhost:3000`):** An `OPTIONS` preflight request with `Origin: http://localhost:3000` returns HTTP 204 No Content with `Access-Control-Allow-Origin: http://localhost:3000`.
- **Untrusted Origin (`http://malicious-attacker.com`):** An `OPTIONS` preflight request returns HTTP 204 without reflecting the untrusted origin in `Access-Control-Allow-Origin`, preventing cross-origin browser credential sharing.

### 5.3. Authentication Failures
- **Missing Header:** Rejected with HTTP 401 `{"error": "Unauthorized: Missing or invalid Authorization header"}`.
- **Forged Bearer Token:** Rejected with HTTP 401 `{"error": "Unauthorized: Invalid Firebase token"}`.

---

## 6. Frontend Defects Triaged and Repaired

During Phase D.9 execution, two defects in `apps/admin-web` were identified and resolved:

### Defect 1: Silent Mock Data Injection in `adminApi.getUsers()`
- **File:** `apps/admin-web/src/lib/api.ts`
- **Issue:** The `getUsers()` method had a fallback `catch` block that caught network/auth errors and silently injected a hardcoded mock record (`contact@draughtsmanstudio.com`). This prevented genuine backend 401/403/500 errors from bubbling up to the user interface.
- **Fix:** Removed the silent fallback catch block. Genuine errors now propagate directly to `users/page.tsx`, allowing the UI to present authentic retry states or error alerts.

### Defect 2: Role Filtering and Badge Incompatibility with Canonical D1 Roles
- **Files:** `apps/admin-web/src/app/users/page.tsx`, `apps/admin-web/src/components/ui/Badge.tsx`, `apps/admin-web/src/types/index.ts`
- **Issue:** 
  - `types/index.ts` omitted `ENGINEER` from the `UserRole` union.
  - `Badge.tsx` lacked CSS badge variants for `ENGINEER`.
  - `users/page.tsx` strictly filtered users with `role === 'CLIENT'` and `role === 'ADMIN'`. Because D1 canonical roles are `ENGINEER` and `STUDIO_ADMIN`, legitimate accounts were invisible in role-filtered tabs.
- **Fix:** 
  - Added `ENGINEER` to `UserRole`.
  - Added badge styling for `ENGINEER` (slate/sky styling).
  - Updated tab filters and count calculations in `users/page.tsx` to treat `ENGINEER` and `CLIENT` synonymously, and `STUDIO_ADMIN` and `ADMIN` synonymously.
- **Regression Verification:**
  - `npm test`: **108 / 108 tests passing** across 8 test suites.
  - `npx tsc --noEmit`: **0 type errors**.
  - `npm run build`: **22 static pages generated in 2.5s** with zero errors.

---

## 7. Legal Gate Status & Fail-Closed Analysis

The platform enforceability check in `worker/src/index.ts` (`assertTermsAccepted`) queries `legal_documents` for an `EFFECTIVE` version of `TERMS_AND_CONDITIONS`.

Because the Phase D.8 legal audit determined that owner business details and statutory prerequisites remain pending, **zero draft documents have been activated or seeded into D1 staging**. As an intentional safeguard:
- `GET /api/legal/documents/TERMS_AND_CONDITIONS/current` returns **HTTP 404 `NO_EFFECTIVE_VERSION`**.
- When any non-admin client attempts `POST /api/projects`, `POST /api/projects/:id/submit`, `POST /api/assignments/:id/accept`, or `POST /api/projects/:id/drawing_versions`, `assertTermsAccepted` executes:
  ```json
  {
    "error": "Mandatory platform terms are currently unavailable in maintenance mode",
    "code": "TERMS_MAINTENANCE_MODE",
    "status": 503
  }
  ```
This confirms that the platform fail-closed mechanism functions exactly as designed: **no commercial work or contractual liability can be initiated without approved, effective legal terms**.

---

## 8. Mobile Client (Flutter) Staging Assessment

An audit of the mobile codebase in `lib/` identified why automated mobile test execution was decoupled from this phase:
1. **Production Firebase Configuration Hardcoded:**  
   `lib/firebase_options.dart` currently hardcodes production Firebase credentials (`projectId: 'archi-draft'`, project number `471564030203`). Running the Flutter application directly against these settings would connect mobile clients to the production Firebase instance, violating the mandatory safety constraint: *"Keep production entirely untouched."*
2. **Desktop Platform Unsupported:**  
   `lib/firebase_options.dart` explicitly throws an `UnsupportedError` when executed on Windows desktop (`DefaultFirebaseOptions.currentPlatform` supports only Android, iOS, and Web).
3. **Recommendation for Mobile Staging:**  
   To safely test the Flutter application on Android/iOS emulators, the project requires staging flavor configuration (e.g., using `--dart-define` or generating `lib/firebase_options_staging.dart` via `flutterfire configure --project=archi-draft-staging`).

---

## 9. Prioritized Next-Action Roadmap

```mermaid
flowchart TD
    A[Phase D.9 E2E Testing Complete] --> B[Owner Decision on Legal Particulars]
    B -->|Supply Address & Sole Proprietor Name| C[Finalize Staging Legal Documents]
    B -->|Keep Maintenance Gate Active| D[Administrative Staging Workflow Tests]
    C --> E[Seed Approved Terms in D1 Staging with Version 1.0.0]
    E --> F[Full Commercial Lifecycle E2E: Brief -> Assignment -> Drawing -> Approval]
    D --> G[Admin-Initiated Project Workflows via POST /api/admin/projects]
```

1. **Immediate Step — Owner Business Input:**  
   Review the Phase D.8 checklist and provide the missing statutory items: (1) Sole Proprietorship legal name, (2) complete physical postal address, (3) confirmation of phone and email publication policies.
2. **Controlled Legal Terms Activation (Staging Only):**  
   Once finalized, seed version `1.0.0` into `archi-draft-db-staging` to open the `assertTermsAccepted` gate in staging for commercial lifecycle verification.
3. **Configure Mobile Staging Flavor:**  
   Generate `firebase_options_staging.dart` pointing to `archi-draft-staging` to permit mobile client integration testing on Android/iOS emulators without production risk.
