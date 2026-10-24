# ARCHI DRAFT — POST-FINALIZATION ACCEPTANCE & CROSS-PORTAL READINESS AUDIT

**Parent Brand:** Draughtsman Studio ([www.draughtsmanstudio.com](https://www.draughtsmanstudio.com/))  
**Studio Development:** PixelMint Studio MVS  
**Audit Checkpoint:** Post-Admin Finalization Gate & Cross-Portal Mobile Compatibility Audit  
**Target Systems:** Admin Web Portal (`apps/admin-web/`), Shared Worker API (`worker/src/index.ts`), Mobile Portals (`lib/`: Engineer, Draughtsman, Student)  
**Date of Audit:** October 23, 2026  
**Auditor:** Senior Full-Stack, Security, & Mobile QA Architect  

---

## 1. EXECUTIVE SUMMARY & VERDICT

### Readiness Verdict: **FAIL (Cross-Portal Integration Readiness)**
*(Admin Portal Phase 1 Acceptance: **PASS**)*

| Area | Status | Critical Findings |
| :--- | :---: | :--- |
| **Admin Web Portal** | **PASS** | 97/97 tests pass; 22/22 Next.js routes compile clean; devIndicator repositioned to bottom-right; sidebar scrolling verified. |
| **Shared Worker RBAC & Scoping** | **FAIL** | **CRITICAL CVE-level Defect:** 7 project endpoints fail to restrict `STUDENT` role, granting students complete visibility and download access to all projects, files, drawings, and audit logs studio-wide. |
| **Student Mobile Portal (Active Branch)** | **FAIL** | `UserRole` enum actively excludes `STUDENT` (`fromString` returns `null`). Student logins crash router into blank shell with `"Invalid user role configuration"`. Student UI only exists on unmerged `Student_panels` branch. |
| **Draughtsman & Engineer Mobile Portals** | **PASS WITH BLOCKERS** | Core workflows aligned, but `AccountSuspendedException` lacks UI routing/interception; `ProjectRepository.getProject` inefficiently polls all projects client-side; 1 Flutter unit test failing due to UI label mismatch. |
| **Financials Boundary** | **PASS** | Completely frozen. No Stripe, Razorpay, or payment schemas present. Internal role `CLIENT` preserved. |

### Decision Rationale:
While the **Admin Portal** is thoroughly hardened, verified, and ready for production operations, cross-portal mobile integration cannot proceed to live testing or deployment until the **Worker RBAC security bypass** is patched, the **Student mobile implementation** is unified from its feature branch, and **mobile suspension handling** is wired to a dedicated barrier. Proceeding without resolving these blockers would compromise intellectual property (CAD blueprints) and lock out student apprentices.

---

## 2. REPOSITORY & ENVIRONMENT STATE VERIFICATION

1. **Active Branch:** `feature/admin-panel-complete` (commit `8ea5d4c5`).
2. **Git Working Tree:** Preserved without reset, discard, or overwrite. Uncommitted modifications in `apps/admin-web/` (final styling, Next.js config, test suite), `lib/` (domain models and suspension exceptions), and `worker/` (dynamic upload ceiling and redlines) are tracked and stable.
3. **Admin Web Verification:**
   - **Unit Tests:** 97/97 passing (`node --test test/*.test.ts`).
   - **TypeScript Typecheck:** `npx tsc --noEmit` exited 0 (zero errors).
   - **Production Hybrid Build:** 22/22 routes successfully generated (SSG/SSR).
   - **Development Indicator:** Official Next.js indicator configured to `position: "bottom-right"` in `next.config.ts`, validated in headless browser without overlapping navigation or footer.
   - **Sidebar Architecture:** Dual-pane layout (`AdminShell`) with independent container scrolling (`overflow-y-auto`) verified across all 11 panels.
4. **Mobile Test Suite Execution:**
   - **Command:** `flutter test`
   - **Results:** 77 Passed, 1 Failed (78 total).
   - **Failure Analysis:** `test/features/auth/presentation/login_screen_test.dart` failed line 20 (`expect(find.text('Sign In'), findsWidgets)`). In `lib/src/features/auth/presentation/login_screen.dart` line 165, the button text was updated to `'AUTHENTICATE'`, causing a cosmetic widget test failure.
5. **Branch Fragmentation Status:**
   - Core student screens and models exist on branch `Student_panels` (commit `c1344942`) and have NOT been merged into `feature/admin-panel-complete`.
   - Advanced Draughtsman workspace enhancements exist on branch `Draughtsman_Panels` (commit `4afaff19`).

---

## 3. SHARED API CONTRACT MATRIX & COMPATIBILITY AUDIT

| Domain / Endpoint | Shared Worker API (`worker/`) | Mobile Implementation (`lib/`) | Admin Web (`apps/admin-web/`) | Contract Status & Defect Classification |
| :--- | :--- | :--- | :--- | :--- |
| **Authentication & Profile**<br>`GET /api/users/me`<br>`POST /api/users` | Validates Firebase JWT. Returns `role`, `status`, `name`, `email`. Excludes suspended users from mutations. | `ApiClient` parses Bearer token. `UserProfile.fromMap` maps `status`. | Prefills admin credentials; validates token against Worker. | **Confirmed Defect (Mobile):** `UserRole.fromString('STUDENT')` returns `null` on active branch. |
| **Account Suspension**<br>`PATCH /api/users/:id/status` | Middleware emits `403` with `code: 'ACCOUNT_SUSPENDED'` for all routes except `/api/users/me`. | `ApiClient` parses `ACCOUNT_SUSPENDED` and throws `AccountSuspendedException`. | Toggle switch in Users panel calls `PATCH /status`. | **Confirmed Defect (Mobile):** No screen or router catches `AccountSuspendedException`. Suspended users crash with unhandled exception banner. |
| **Role-Based Scoping**<br>`GET /api/projects`<br>`GET /api/projects/:id` | Scopes `CLIENT` to `client_id` and `DRAUGHTSMAN` to assigned projects. | `ProjectRepository` reads project list. Filters client-side for detail. | Studio Admin accesses all projects with SLA enrichment. | **CRITICAL DEFECT (Security):** Missing `STUDENT` check allows students to access ALL projects and audit logs studio-wide. |
| **Assignments & Capacity**<br>`POST /api/projects/assign`<br>`POST /api/projects/reassign` | Enforces 4-active-project ceiling per Draughtsman. Idempotent on `actionId`. | `AssignmentRepository` dispatches assignment payload with `actionId`. | AssignModal & ReassignModal display live load counters (e.g. `2/4 ACTIVE`). | **COMPATIBLE:** Fully aligned. |
| **Redline Corrections**<br>`POST /api/projects/request-correction` | Supports `PIN[0.xxxx,0.yyyy]: text`. Enforces 3-round cap. Duplicate route at line 548 shadows line 691. | `ProjectRepository.requestCorrection` takes `actionId`, `targetVersionId`. | Pinned canvas captures normalized coordinates. | **Confirmed Defect (Worker):** Duplicate route registration at line 548 makes line 691 dead code. |
| **File Storage & Uploads**<br>`POST /api/projects/:id/files`<br>`GET /api/files/:id/download` | R2 bucket storage. Dynamic upload ceiling from D1. MIME validation. | `FileRepository` streams files with `X-Action-Id` and `X-File-Name`. | Uploads reference drawings and final sheets. | **CRITICAL DEFECT (Security):** `GET /api/files/:id/download` and `/files` do not restrict `STUDENT`, allowing unauthorized CAD downloads. |
| **Project Comments**<br>`GET /api/projects/:id/comments`<br>`POST /api/projects/:id/comments` | D1 table `project_comments`. Strict RBAC: Admin, assigned Draughtsman, or Client. | `ProjectRepository.getProjectComments` and `postProjectComment`. | Real-time / polling collaboration hub in project detail drawer. | **COMPATIBLE:** Endpoint enforces strict RBAC; student access properly rejected with 403. |
| **Financials Scope**<br>`/api/financials` / `/financials` | Frozen. No payment gateways or live schema. | Frozen. No payment gateways. | Frozen. Displays read-only billing ledger view. | **COMPATIBLE (FROZEN):** Invariants strictly preserved. |

---

## 4. DETAILED FINDINGS & VULNERABILITY REGISTER

### A. CONFIRMED DEFECTS (Blockers)

#### Finding 1: Critical RBAC Bypass on Project & Blueprint Endpoints (Worker)
- **Severity:** `CRITICAL (Security / Data Leakage)`
- **File & Lines:** `worker/src/index.ts` lines 446–452, 1083–1088, 1104–1108, 1124–1128, 1298–1302, 1380–1386, 1414–1420.
- **Root Cause:**
  ```typescript
  // worker/src/index.ts (e.g., lines 1380-1386)
  if (user.role === 'CLIENT' && project.client_id !== uid) return c.json({ error: 'Forbidden' }, 403);
  if (user.role === 'DRAUGHTSMAN' && project.draughtsman_id !== uid) return c.json({ error: 'Forbidden' }, 403);
  // ADMIN can view any project
  ```
  The logic assumes only `CLIENT`, `DRAUGHTSMAN`, and `ADMIN` exist. It omits a default non-admin rejection (`else if (user.role !== 'ADMIN') return c.json({ error: 'Forbidden' }, 403);`). Consequently, any authenticated `STUDENT` bypasses authorization checks and is granted full access to:
  1. `GET /api/projects` (lists all client projects studio-wide)
  2. `GET /api/projects/:projectId` (inspects any project's metadata and engineer info)
  3. `GET /api/projects/:projectId/activity` (inspects all administrative and audit logs)
  4. `GET /api/projects/:projectId/files` & `drawing_versions` (lists proprietary DWG/DXF/PDF files)
  5. `GET /api/files/:fileId/download` (downloads any client architectural drawing from R2)
- **Impact:** Massive intellectual property and confidentiality leak across client drawings.

#### Finding 2: Student Role and Portal Exclusion in Active Mobile Branch (Flutter)
- **Severity:** `CRITICAL (Functional Blocker)`
- **File & Lines:**
  - `lib/src/features/profile/domain/user_role.dart` lines 8–12, 17–28
  - `lib/src/core/router/app_router.dart` lines 84–92, 105–115
  - `lib/src/features/shell/presentation/app_shell.dart` lines 103–116
- **Root Cause:**
  `user_role.dart` defines `enum UserRole { client, draughtsman, admin; }` and states `/// STUDENT is POST-MVP and not included here.` `UserRole.fromString('STUDENT')` returns `null`. In `app_router.dart`, a null role redirects to `/`. In `app_shell.dart`, `case null:` displays `AppErrorWidget(message: 'Invalid user role configuration.')`.
- **Branch Divergence:** The Student Portal was implemented on a separate git branch (`Student_panels` commit `c1344942`) with `StudentShell`, `student_training_screen.dart`, `student_drawings_screen.dart`, etc., but has never been merged into the active branch.

#### Finding 3: Unhandled `AccountSuspendedException` in Mobile Application (Flutter)
- **Severity:** `HIGH (User Experience & Security UX)`
- **File & Lines:** `lib/src/features/api/data/api_client.dart` lines 145–165; `lib/src/core/router/app_router.dart`.
- **Root Cause:**
  While `ApiClient` correctly identifies `403 ACCOUNT_SUSPENDED` and throws `AccountSuspendedException`, zero providers, repositories, or UI screens catch this exception. `AppShell` only checks `profile.isSuspended` on initial load. If an active session is suspended by the Admin, subsequent API calls throw an unhandled exception, causing red error banners rather than redirecting to the suspension barrier.

#### Finding 4: Shadowed Duplicate Route in Worker API (Worker)
- **Severity:** `MEDIUM (Backend Hygiene & Reliability)`
- **File & Lines:** `worker/src/index.ts` line 548 vs line 691 (`POST /api/projects/request-correction`).
- **Root Cause:**
  Line 548 registers `app.post('/api/projects/request-correction')` (generating `correctionId` server-side and returning `{ success: true, correctionId }`). Line 691 registers the identical path expecting `correctionId` from the client body and returning `{ success: true, newRound }`. Because Hono matches routes sequentially, Line 548 always intercepts requests, making Line 691 dead code.

#### Finding 5: Mobile Login Screen Test Regression (Flutter)
- **Severity:** `LOW (Test Suite Drift)`
- **File & Lines:** `lib/src/features/auth/presentation/login_screen.dart` line 165; `test/features/auth/presentation/login_screen_test.dart` line 20.
- **Root Cause:**
  The login button text was styled to `'AUTHENTICATE'` to match Stitch branding, but `login_screen_test.dart` expects `'Sign In'`.

---

### B. RUNTIME RISKS (Requiring Non-Production Verification)

1. **Client-Side Project Filtering Inefficiency:**
   `lib/src/features/projects/data/project_repository.dart` line 32 still calls `GET /api/projects` and filters locally (`projects.firstWhere(...)`). Under high project volume, this increases mobile memory footprint and network transfer. Should be migrated to `GET /api/projects/:projectId`.
2. **Missing Dynamic Upload Ceiling Handling on Mobile:**
   When an upload exceeds the dynamic studio ceiling, the Worker returns `413 UPLOAD_SIZE_EXCEEDED`. Mobile `FileRepository` throws a generic `Exception: 413` instead of presenting a user-friendly dialogue indicating the studio ceiling limit.
3. **Training Module D1 Table Migration:**
   The student endpoints in `Student_panels` require D1 tables (`training_modules`, `student_progress`, `student_assignments`). Verification is needed to ensure local D1 fixtures contain these tables before activating student routes.

---

## 5. PROPOSED CROSS-PORTAL INTEGRATION TEST PLAN

### Test Suite 1: Worker RBAC & Multi-Role Isolation Matrix
Automated HTTP tests using Cloudflare Miniflare/Vitest simulating each role:
- [ ] **CLIENT Isolation:** Verify Engineer A cannot access Engineer B's projects, files, or comments (Expect `403 Forbidden`).
- [ ] **DRAUGHTSMAN Workspace Boundary:** Verify Draughtsman X cannot view unassigned projects (Expect `403 Forbidden`).
- [ ] **STUDENT Sandbox Guard:** Verify Student cannot access client projects, activity logs, or download production files (Expect `403 Forbidden`).
- [ ] **STUDENT Training Access:** Verify Student can view assigned training modules and submit training progress.
- [ ] **ADMIN Global Access:** Verify Admin can access all projects, reassign draughtsmen, and view audit logs.

### Test Suite 2: Account Suspension & Real-Time Ejection Flow
- [ ] **Worker Barrier:** Verify any mutation by a suspended token returns `403 { code: "ACCOUNT_SUSPENDED" }`.
- [ ] **Mobile Exception Handling:** Verify `AccountSuspendedException` triggers a state change in `authNotifier` and redirects immediately to the Account Suspended barrier.
- [ ] **Sign-Out Ejection:** Verify the suspended user can cleanly sign out from the barrier.

### Test Suite 3: End-to-End Project Lifecycle Across 3 Portals
- [ ] **Step 1 (Engineer Mobile / Admin Web):** Project brief created with attachments.
- [ ] **Step 2 (Admin Web):** Studio Admin assigns draughtsman (enforcing the 4-project capacity limit).
- [ ] **Step 3 (Draughtsman Mobile):** Draughtsman accepts assignment, uploads drawing version V1 (enforcing dynamic ceiling).
- [ ] **Step 4 (Admin Web):** Studio Admin creates redline pin correction `PIN[0.5230,0.4120]: Relocate door opening`.
- [ ] **Step 5 (Draughtsman Mobile):** Draughtsman reviews pinned correction, uploads V2, and marks correction complete.
- [ ] **Step 6 (Engineer Mobile):** Engineer approves final drawing.

---

## 6. EXACT NEXT STEPS & EXECUTION ROADMAP

Before entering the multi-portal integration phase:

1. **Step 1: Patch Worker Security Vulnerability (RBAC)**
   Add strict role checks in `worker/src/index.ts` so that only `ADMIN`, assigned `DRAUGHTSMAN`, and project `CLIENT` can access project details, activity, files, and downloads. Reject `STUDENT` with 403 on production project endpoints.
2. **Step 2: Clean Up Worker Duplicate Routes**
   Remove the shadowed duplicate `POST /api/projects/request-correction` at line 691 and unify correction payload handling.
3. **Step 3: Branch Integration Strategy (Student & Draughtsman Portals)**
   Execute a clean, controlled merge of `origin/Student_panels` and `origin/Draughtsman_Panels` into the integration branch, resolving `user_role.dart` and `app_router.dart` conflict points.
4. **Step 4: Harden Mobile Suspension & Error Handling**
   Catch `AccountSuspendedException` in Riverpod base providers, invalidate session state, and route to `AppShell`'s suspension view.
5. **Step 5: Fix Mobile Widget Test Drift**
   Align `login_screen_test.dart` with the approved `'AUTHENTICATE'` button text.
6. **Step 6: Live Non-Production Verification**
   Run the 3-portal lifecycle test against a shared local Miniflare/D1 worker instance before promoting to staging.
