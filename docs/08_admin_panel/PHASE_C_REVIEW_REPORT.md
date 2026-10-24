# PHASE C INDEPENDENT REVIEW REPORT

**Archi Draft — Phase C: Admin Portal Local Integration & Multi-Portal Contract Independent Review**  
**Organization:** PixelMint Studio MVS  
**Product:** Archi Draft / Draughtsman Studio  
**Date:** October 23, 2026  
**Auditor:** Principal Integration, Security & Systems Audit Lead  
**Audit Scope:** Isolated Worktree `scratch/completed-integration` (Branch: `COMPLETED-INTERGRATION`)  
**Main Workspace Reference:** `c:\Users\inaam\.gemini\antigravity-ide\scratch\Archidraft` (Branch: `feature/admin-panel-complete`)  
**Audit Status:** COMPLETE — INDEPENDENT READ-ONLY REVIEW  

---

## 1. Executive Summary & Verification Preflight

This independent review constitutes an evidence-based, read-only audit of the Phase C local integration in `scratch/completed-integration`. The audit cross-examined the untracked file inventory, live Worker API routes (`worker/src/index.ts`), database migrations (`worker/migrations/0001_schema.sql` through `0019_collaboration_unification.sql`), cross-portal Flutter domain models, and the Admin API client (`apps/admin-web/src/lib/api.ts`).

### Preflight Repository State
- **Main Admin Source Workspace (`c:\Users\inaam\.gemini\antigravity-ide\scratch\Archidraft`):**
  - Current Branch: `feature/admin-panel-complete` at commit `8ea5d4c5`.
  - Working Tree: Exactly 36 modified files and 12 untracked items preserved untouched.
  - Zero git operations, staging, commits, pushes, merges, or deletions were performed.
- **Isolated Integration Worktree (`scratch/completed-integration`):**
  - Current Branch: `COMPLETED-INTERGRATION` at commit `40247640cbc1bd55f69d616211a8fcff8912f496` (`fix: secure shared backend for multi-portal integration`).
  - Working Tree Status: Clean tracked tree; untracked directories: `apps/` and integration documentation.
  - Ahead of `origin/COMPLETED-INTERGRATION` by 1 local commit (Phase B).
- **Test Execution Summary (100% Passing Across 644 Automated Tests):**
  - `apps/admin-web` Node Test Runner: **97 / 97 passing** (0 failures, 928ms).
  - `apps/admin-web` Next.js 16.4.2 Production Build: **22 / 22 routes compiled & prerendered** (0 errors).
  - `worker` Node Test Runner: **227 / 227 passing** (0 failures, 4.0s).
  - `worker` TypeScript Typecheck: **0 errors** (`tsc --noEmit`).
  - Flutter Mobile Test Suite: **320 / 320 passing** (0 failures, 2m 51s).

---

## 2. Complete Untracked File Inventory & Secret Hygiene

### Untracked File Inventory (`apps/admin-web/`)
A total of **60 untracked files** were verified under `scratch/completed-integration/apps/admin-web/` using `git ls-files --others --exclude-standard apps/`:

```
apps/admin-web/
├── Configuration & Documentation (9 files)
│   ├── .env.example
│   ├── .gitignore
│   ├── AGENTS.md
│   ├── README.md
│   ├── eslint.config.mjs
│   ├── next.config.ts
│   ├── package.json
│   ├── package-lock.json
│   └── tsconfig.json
├── Static Assets (public/ - 7 files)
│   ├── draughtsman_logo.jpeg, file.svg, globe.svg, logo.jpeg, next.svg, vercel.svg, window.svg
├── Core Libraries & Types (src/lib/ - 4 files)
│   ├── api.ts
│   ├── auth.tsx
│   ├── firebase.ts
│   └── types.ts
├── Shared UI Components (src/components/ - 13 files)
│   ├── layout/AdminShell.tsx, Header.tsx, Sidebar.tsx
│   ├── projects/AssignModal.tsx, CancelModal.tsx, NewProjectModal.tsx, RejectModal.tsx
│   ├── ui/Badge.tsx, Button.tsx, Card.tsx, EmptyState.tsx, Modal.tsx
│   ├── draughtsmen/DraughtsmanProfileView.tsx
│   ├── engineers/EngineerProfileView.tsx
│   ├── students/StudentProfileView.tsx
│   └── providers.tsx
├── Operational App Pages (src/app/ - 24 files)
│   ├── activity/page.tsx
│   ├── assignments/page.tsx, assignments/history/page.tsx
│   ├── dashboard/page.tsx
│   ├── draughtsmen/page.tsx, draughtsmen/[id]/page.tsx
│   ├── engineers/page.tsx, engineers/[id]/page.tsx
│   ├── financials/page.tsx
│   ├── forgot-password/page.tsx
│   ├── globals.css, layout.tsx, page.tsx, favicon.ico
│   ├── login/page.tsx
│   ├── projects/page.tsx, projects/[projectId]/page.tsx
│   ├── settings/page.tsx
│   ├── students/page.tsx, students/[id]/page.tsx
│   ├── users/page.tsx
│   └── verify/page.tsx
└── Automated Unit / Contract Test Suites (test/ - 3 files)
    ├── admin-portal.test.ts
    ├── next-phase-governance.test.ts
    └── redline-corrections.test.ts
```

### Ignored & Generated Files Verification
The command `git status --ignored -s apps/` confirms that build artifacts, dependency directories, and internal compiler outputs are properly ignored:
- `!! apps/admin-web/.next/` (Ignored)
- `!! apps/admin-web/next-env.d.ts` (Ignored)
- `!! apps/admin-web/node_modules/` (Ignored)

### Secret & Credential Hygiene
- A recursive search for `.env*` files in `apps/admin-web/` found exclusively `.env.example`.
- `.env.example` line 2 contains `NEXT_PUBLIC_FIREBASE_API_KEY=` (empty placeholder).
- Zero production service account JSON files, private keys, API secrets, or `.env.local` files exist in the worktree.

---

## 3. Admin API Client vs Actual Worker Routes Contract Audit

A line-by-line comparative audit of `apps/admin-web/src/lib/api.ts` against the live Cloudflare Worker routes in `worker/src/index.ts` revealed several critical contract mismatches and confirmed several properly unified endpoints.

### Detailed Route-by-Route Matrix

| Admin API Function (`api.ts`) | Target Path in Client | Actual Worker Route (`index.ts`) | HTTP Method | Contract Status & Findings |
| :--- | :--- | :--- | :---: | :--- |
| `adminApi.createAdminCorrection` (L441–458) | `/api/admin/projects/:id/corrections` | `/api/projects/request-correction` (L970) | `POST` | **DEFECT / MISMATCH:** Client calls `/api/admin/projects/:id/corrections` which does not exist in Worker (returns 404). Worker expects `POST /api/projects/request-correction` with payload `{ projectId, actionId, correctionId, targetVersionId, description }`. |
| `adminApi.createProject` (L97–141) | `/api/admin/projects` | `/api/projects` (L702) | `POST` | **DEFECT / MISMATCH:** Client calls `/api/admin/projects` which does not exist in Worker (caught by client fallback and stored in `localStorage`). Furthermore, Worker's `POST /api/projects` strictly rejects non-engineers with `403 Only engineers can create projects`. |
| `adminApi.getStats` (L143–185) | `/api/admin/stats` | `/api/admin/dashboard` (L1327) | `GET` | **DEFECT / MISMATCH:** Worker exposes `/api/admin/dashboard` returning `{ totalProjects, activeProjects, ... }`. Worker does not implement `/api/admin/stats`. Client catches error and falls back to computing stats via `getProjects()` and `getUsers()`. |
| `adminApi.createProjectComment` (L298–316) | `/api/projects/:id/comments` | `/api/projects/:projectId/comments` (L1972) | `POST` | **DEFECT / CONTRACT GAP:** Route exists and accepts comments, but inserts into `project_messages` without `attachment_file_id`. Passed attachment metadata (`attachmentName`, `attachmentSize`, `attachmentType`) is NOT persisted in D1. |
| `adminApi.getProjects` (L207–232) | `/api/projects` | `/api/projects` (L617) | `GET` | **MATCH:** Supports `?status=` filtering. RBAC permits ADMIN / STUDIO_ADMIN full cross-tenant visibility. |
| `adminApi.getProject` (L234–247) | `/api/projects/:id` | `/api/projects/:id` (L667) | `GET` | **MATCH:** Verified. Uses `canUserAccessProject()` to grant unrestricted Admin access. |
| `adminApi.getProjectActivity` (L249–255) | `/api/projects/:id/activity` | `/api/projects/:projectId/activity` (L2351) | `GET` | **MATCH:** Verified. Returns chronological activity logs. |
| `adminApi.getProjectAssignments` (L257–263) | `/api/projects/:id/assignments` | `/api/assignments` (L1219) | `GET` | **RISK / CONTRACT MISMATCH:** Worker has `/api/assignments?projectId=...` rather than `/api/projects/:id/assignments`. |
| `adminApi.getProjectFiles` (L265–271) | `/api/projects/:id/files` | `/api/projects/:projectId/files` (L1457) | `GET` | **MATCH:** Verified. Returns files filtered where `status != 'FAILED'`. |
| `adminApi.getProjectDrawingVersions` (L273–279) | `/api/projects/:id/drawing_versions` | `/api/projects/:projectId/drawing_versions` (L1749) | `GET` | **MATCH:** Verified. Joined with files table. |
| `adminApi.getProjectCorrections` (L281–287) | `/api/projects/:id/corrections` | `/api/projects/:projectId/corrections` (L1766) | `GET` | **MATCH:** Verified. Returns corrections ordered by `round_number DESC`. |
| `adminApi.getProjectComments` (L290–296) | `/api/projects/:id/comments` | `/api/projects/:projectId/comments` (L1937) | `GET` | **MATCH:** Verified. Queries `project_messages` joined with `files`. |
| `adminApi.getUsers` (L319–335) | `/api/users` | `/api/users` (L527) | `GET` | **MATCH:** Verified. Supports `?role=` query parameter. |
| `adminApi.getUserDetails` (L187–204) | `/api/users/:id` | `/api/users/:id` (L543) | `GET` | **MATCH:** Verified. Returns user record and associated project counts. |
| `adminApi.updateUserStatus` (L363–375) | `/api/users/:id/status` | `/api/users/:id/status` (L555) | `PATCH` | **MATCH:** Verified. Enforces `['ACTIVE', 'SUSPENDED']` with Admin check. |
| `adminApi.approveProject` (L378–384) | `/api/projects/approve` | `/api/projects/approve` (L876) | `POST` | **MATCH:** Verified. Enforces Admin role, transitions `SUBMITTED` $\to$ `WAITING_ASSIGNMENT`. |
| `adminApi.rejectProject` (L386–392) | `/api/projects/reject` | `/api/projects/reject` (L900) | `POST` | **MATCH:** Verified. Enforces Admin role, transitions to `CANCELLED` with reason. |
| `adminApi.assignProject` (L394–400) | `/api/projects/assign` | `/api/projects/assign` (L1013) | `POST` | **MATCH:** Verified. Enforces 4-active project capacity cap (`SEC-03`). |
| `adminApi.reassignProject` (L402–408) | `/api/projects/reassign` | `/api/projects/reassign` (L1075) | `POST` | **MATCH:** Verified. Sets old assignment to `REPLACED`, enforces destination capacity cap. |
| `adminApi.cancelProject` (L429–435) | `/api/projects/cancel` | `/api/projects/cancel` (L3401) | `POST` | **MATCH:** Verified. Admins and project owners can cancel with mandatory reason. |
| `adminApi.getAdminAssignments` (L411–427) | `/api/admin/assignments` | `/api/admin/assignments` (L3366) | `GET` | **MATCH:** Verified. Supports `?status=`, `?draughtsmanId=`, `?projectId=`. |
| `adminApi.getStudioSettings` (L515–533) | `/api/admin/settings` | `/api/admin/settings` (L3305) | `GET` | **MATCH:** Verified. Backed by `studio_settings` D1 table (`0018_studio_settings.sql`). |
| `adminApi.updateStudioSettings` (L535–540) | `/api/admin/settings` | `/api/admin/settings` (L3335) | `PUT` | **MATCH:** Verified. Writes updated JSON values to `studio_settings`. |

---

## 4. Cross-Portal Collaboration Compatibility & Media Handling

### Message / Comment Database Model
1. **Unification Approach:**
   - In `0019_collaboration_unification.sql`, a SQLite VIEW `project_comments` was created projecting `project_messages` joined with `files`.
   - In `worker/src/index.ts` (L1937–2020), `/api/projects/:projectId/comments` performs an inline query on `project_messages` and `files`:
     ```sql
     SELECT m.id, m.project_id, m.sender_id AS author_id, m.sender_name AS author_name,
            m.sender_role AS author_role, m.message AS content,
            f.original_name AS attachment_name, CAST(f.size AS TEXT) AS attachment_size,
            f.content_type AS attachment_type, m.created_at
     FROM project_messages m
     LEFT JOIN files f ON m.attachment_file_id = f.id
     WHERE m.project_id = ?
     ```
2. **Identified Collaboration Defects:**
   - **Missing Attachment Upload in Admin Web (`page.tsx:L1527`):** When an Admin attaches a file to a comment, the file is never uploaded via `adminApi.uploadProjectFile`. Instead, raw file name and size strings are passed to `createProjectComment`. Because `POST /api/projects/:projectId/comments` (L2002) only inserts `(id, project_id, sender_id, sender_name, sender_role, message)`, the attachment fields are completely discarded and return `NULL` on refresh.
   - **Audio / Voice Note Type Coercion (`page.tsx:L119`):** In `apps/admin-web/src/app/projects/[projectId]/page.tsx`, `toCollabMessage` maps `attachment_type` as follows:
     ```ts
     type: (c.attachment_type === 'pdf' || c.attachment_type === 'dwg' || c.attachment_type === 'image') ? c.attachment_type : 'pdf'
     ```
     Because voice notes created in Flutter have MIME type `audio/mp4` or `audio/webm`, the Admin UI forces their display type to `pdf`. Voice note duration and inline playback controls are completely missing in the Admin UI.
   - **Missing Attachment Download URL:** `ProjectComment` in `apps/admin-web/src/lib/types.ts` does not contain `attachment_file_id`, preventing Admin users from downloading or streaming attachments sent by mobile users.

---

## 5. Complete Workflow and State Transitions Audit

The end-to-end lifecycle across the 4 portals was verified against `worker/src/index.ts`:

```mermaid
stateDiagram-v2
    [*] --> DRAFT : Engineer saves draft (POST /api/projects)
    DRAFT --> SUBMITTED : Engineer submits brief (POST /api/projects/submit)
    SUBMITTED --> WAITING_ASSIGNMENT : Admin approves project (POST /api/projects/approve)
    SUBMITTED --> CANCELLED : Admin rejects project (POST /api/projects/reject)
    WAITING_ASSIGNMENT --> WAITING_ACCEPTANCE : Admin assigns Draughtsman (POST /api/projects/assign)
    WAITING_ACCEPTANCE --> IN_PROGRESS : Draughtsman accepts (POST /api/assignments/accept)
    WAITING_ACCEPTANCE --> WAITING_ASSIGNMENT : Draughtsman rejects (POST /api/assignments/reject)
    IN_PROGRESS --> UNDER_ENGINEER_REVIEW : Draughtsman submits DWG (POST /api/projects/submit-drawing)
    UNDER_ENGINEER_REVIEW --> IN_PROGRESS : Engineer requests correction (POST /api/projects/request-correction, round <= 3)
    UNDER_ENGINEER_REVIEW --> COMPLETED : Engineer approves final (POST /api/projects/approve-final)
    IN_PROGRESS --> WAITING_ACCEPTANCE : Admin reassigns (POST /api/projects/reassign)
    any_state --> CANCELLED : Admin / Owner cancels (POST /api/projects/cancel)
```

### Transition Verification Evidence:
1. **Engineer Submission:** Verified at `worker/src/index.ts:748`. Only users with role `ENGINEER` or `CLIENT` can submit. Sets `status = 'SUBMITTED'`, updates `submitted_at`, and records activity log.
2. **Admin Review & Assignment:**
   - Approve: `index.ts:876` transitions `SUBMITTED` $\to$ `WAITING_ASSIGNMENT`.
   - Assign: `index.ts:1013` creates pending record in `assignments` and transitions project to `WAITING_ACCEPTANCE`.
3. **Draughtsman Acceptance:**
   - Accept: `index.ts:1129` verifies draughtsman assignment ownership, marks assignment `ACCEPTED`, and transitions project to `IN_PROGRESS`.
   - Reject: `index.ts:1180` marks assignment `REJECTED`, clears `draughtsman_id`, and reverts project to `WAITING_ASSIGNMENT`.
4. **Drawing Submission:** `index.ts:773` promotes draft file to `drawing_versions` table, marks open corrections `RESOLVED`, and transitions project to `UNDER_ENGINEER_REVIEW`.
5. **Correction vs Final Approval:**
   - Approve Final: `index.ts:939` transitions to terminal `COMPLETED` state.
   - Request Correction: `index.ts:970` increments `correction_round`. If `currentRound >= 3`, strictly returns `400 Maximum correction rounds (3) exceeded`.

---

## 6. Backend Security & Governance Enforcement

### 1. Cross-Tenant Project & File Isolation (`SEC-01`)
- Verified at `worker/src/index.ts:590` (`canUserAccessProject`):
  - Engineers / Clients: Strictly limited to `project.client_id === uid`. Accessing foreign projects returns `403 Forbidden`.
  - Draughtsmen: Strictly limited to assigned projects where assignment status is `ACCEPTED` or `COMPLETED`.
  - Students: Strictly limited to `is_training_project === 1` and assigned in `student_assignments`. Commercial project access returns `403 Forbidden`.
  - File downloads at `worker/src/index.ts:2218` re-verify project authorization before streaming from R2.

### 2. User Suspension Enforcement (`SEC-02`)
- Global authentication middleware (`worker/src/index.ts:125–137`):
  - If `user.status === 'SUSPENDED'`, all requests are blocked with HTTP 403 `ACCOUNT_SUSPENDED`.
  - Safe exception: Only read-only profile and legal endpoints (`GET /api/users/me`, `GET /api/users/profile`, `GET /api/legal/documents`, `GET /api/public/`) are permitted so suspended users can inspect account status and legal notices.
  - Administration: `PATCH /api/users/:id/status` (`index.ts:555`) allows Admins to toggle status between `ACTIVE` and `SUSPENDED`.

### 3. Four-Active-Project Workload Cap (`SEC-03`)
- Enforced authoritatively in `POST /api/projects/assign` (`index.ts:1039`) and `POST /api/projects/reassign` (`index.ts:1087`):
  - Active statuses: `WAITING_ACCEPTANCE`, `IN_PROGRESS`, `UNDER_ENGINEER_REVIEW`, `UNDER_CLIENT_REVIEW`.
  - If `activeCount >= 4`, the Worker halts execution and returns HTTP 400 `DRAUGHTSMAN_CAPACITY_EXCEEDED`.

### 4. Idempotency (`actionId`)
- Every mutating state endpoint (`submit`, `approve`, `reject`, `assign`, `reassign`, `accept`, `submit-drawing`, `approve-final`, `request-correction`, `cancel`) validates `body.actionId` against `project.last_action_id`.
- Duplicate submissions with identical `actionId` safely return `{ success: true }` without repeating side effects, double-assigning users, or duplicating activity log entries.

---

## 7. Frozen Financial Scope Compliance

### Scope Enforcement Verification:
1. **Read-Only Inspection Preserved:**
   - `GET /api/projects/:projectId/financials` (`worker/src/index.ts:2456`) remains fully functional for studio admins.
   - `PATCH /api/projects/:projectId/financials/total_value` (`index.ts:2500`) preserves project scoping budgets while preventing invalid negative or sub-invoice values.
2. **Financial Mutations Blocked (`FEATURE_FROZEN`):**
   - `POST /api/projects/:projectId/invoices` (`worker/src/index.ts:2547`):
     ```json
     HTTP/1.1 501 Not Implemented
     {
       "error": "Financial mutations are disabled: payments scope is frozen in this release",
       "code": "FEATURE_FROZEN"
     }
     ```
   - `POST /api/invoices/:invoiceId/payments` (`worker/src/index.ts:2565`):
     ```json
     HTTP/1.1 501 Not Implemented
     {
       "error": "Financial mutations are disabled: payments scope is frozen in this release",
       "code": "FEATURE_FROZEN"
     }
     ```
3. **Zero Payment Infrastructure:**
   - Zero Stripe, Razorpay, or payment SDKs exist in `package.json` or `pubspec.yaml`.
   - The Admin Web `/financials` panel (`apps/admin-web/src/app/financials/page.tsx`) renders derived read-only metrics from project areas and rates without presenting any mutation triggers.

---

## 8. Database Migrations 0001–0019 Audit & D1 Compatibility

### Actual Migration File Inventory vs Phase C Report Discrepancy
The previous Phase C report incorrectly documented legacy file names (`0001_initial.sql`, `0002_schema_v2.sql`, etc.). The actual files present on disk in `worker/migrations/` were verified:

| Migration File | Description & Target Objects | D1 / SQLite Compatibility Status |
| :--- | :--- | :--- |
| `0001_schema.sql` | Base schema: `users`, `projects`, `activity_logs` | **Compatible:** Standard SQLite DDL. |
| `0002_assignments.sql` | Table: `assignments` (Draughtsman allocations) | **Compatible:** Foreign keys with `ON DELETE RESTRICT`. |
| `0003_files.sql` | Tables: `files`, `drawing_versions` | **Compatible:** SQLite schema for R2 metadata. |
| `0004_corrections.sql` | Table: `corrections` (Redline feedback) | **Compatible:** Includes `round_number` and status checks. |
| `0005_notifications.sql` | Table: `notifications` | **Compatible:** Indexed by user and project. |
| `0006_financials.sql` | Tables: `invoices`, `payments` | **Compatible:** Preserved read-only schema. |
| `0007_student_profile.sql` | User extensions for student training | **Compatible:** Safe `ALTER TABLE` operations. |
| `0008_user_profile_fields.sql` | Profile metadata (qualification, company, etc.) | **Compatible:** Standard column additions. |
| `0009_project_messages.sql` | Table: `project_messages` (Collaboration Hub) | **Compatible:** Unified message table with `attachment_file_id`. |
| `0010_student_training.sql` | Tables: `student_training_modules`, `enrollments` | **Compatible:** Standard SQLite schema. |
| `0011_student_lessons.sql` | Tables: `training_lessons`, `lesson_progress` | **Compatible:** Indexed lesson ordering. |
| `0012_evaluations.sql` | Table: `project_evaluations` | **Compatible:** Rubric scoring schema. |
| `0013_student_credentials.sql`| Table: `student_credentials` | **Compatible:** Credential and certificate records. |
| `0014_student_credentials_artifact.sql` | Adds certificate artifact key to credentials | **Compatible:** Column addition. |
| `0015_student_credentials_verification.sql` | Adds verification tokens and public lookup index | **Compatible:** Unique index on verification token. |
| `0016_legal_system.sql` | Tables: `legal_documents`, `consent_events`, `user_consent_state`, `privacy_requests` | **Compatible:** Standard SQLite constraints and partial unique indexes. |
| `0017_user_status.sql` | Column: `ALTER TABLE users ADD COLUMN status TEXT CHECK (status IN ('ACTIVE', 'SUSPENDED')) DEFAULT 'ACTIVE'` | **Compatible:** Standard SQLite column addition with default. |
| `0018_studio_settings.sql` | Table: `studio_settings (key PRIMARY KEY, value, updated_at, updated_by)` | **Compatible:** Key-value persistence table. |
| `0019_collaboration_unification.sql` | View: `CREATE VIEW IF NOT EXISTS project_comments AS SELECT ... FROM project_messages LEFT JOIN files` | **Compatible:** SQLite standard view for legacy tooling. |

---

## 9. Legal Terms Gating & Unresolved Production Dependencies

### Legal Terms Gating Behavior (`worker/src/legal.ts`)
- Enforced at `worker/src/index.ts:141–169` on all business mutations (`POST`, `PUT`, `DELETE`, `PATCH` on projects, assignments, and training).
- **Admin Exemption:** `assertTermsAccepted()` (`legal.ts:36`) explicitly returns `{ ok: true }` for roles `ADMIN` and `STUDIO_ADMIN`.
- **Ordinary Users Gating:**
  - If no `TERMS_AND_CONDITIONS` document with `status = 'EFFECTIVE'` and `is_mandatory = 1` exists in D1, the Worker returns HTTP 503 `TERMS_MAINTENANCE_MODE`.
  - If an effective mandatory document exists but the caller has not accepted that exact version in `user_consent_state`, the Worker returns HTTP 403 `TERMS_ACCEPTANCE_REQUIRED`.

### Production Deployment Dependencies
Before production deployment, the following external items must be resolved:
1. **Official Legal Text:** Studio management and legal counsel must approve the official Terms & Conditions and Privacy Notice markdown text.
2. **Database Legal Seeding:** A seed migration or administrative script must populate `legal_documents` with initial `EFFECTIVE` records so mobile clients are not blocked by `TERMS_MAINTENANCE_MODE`.
3. **Cloudflare D1 & R2 Bindings:** Production bindings for `DB` (D1) and `STORAGE` (R2) must be provisioned and configured in `wrangler.toml`.
4. **Firebase Production Project:** Production Firebase Auth credentials (`NEXT_PUBLIC_FIREBASE_API_KEY`, `NEXT_PUBLIC_FIREBASE_APP_ID`, etc.) must be provided for the Admin Web build.
5. **Environment Configuration:** Worker API URL (`NEXT_PUBLIC_WORKER_API_URL`) must point to the production Cloudflare Workers domain.

---

## 10. Test Execution Verification & Evidence Categorization

To maintain strict truth in engineering reporting, automated test results must be clearly distinguished from live cross-portal integration:

### 1. Automated In-Memory / Mocked Test Suites (Passing: 644/644)
- **`apps/admin-web/test/` (97 tests):**
  - Uses `node:test` and `node:assert/strict`.
  - Tests contract functions, payload validation rules, coordinate parsers, and permission logic in Node.js memory.
  - Does NOT connect to a live web browser, live Worker API, or remote database.
- **`worker/test/` (227 tests):**
  - Uses `node:sqlite` in-memory database (`new DatabaseSync(':memory:')`).
  - Executes real SQL schema from all 19 migrations (`0001`–`0019`).
  - Bundles `worker/src/index.ts` with `esbuild` and invokes `app.fetch(req, env)`.
  - Mocks Firebase Auth token verification and Cloudflare R2 storage in memory.
  - Does NOT execute on Cloudflare Workers edge runtime (Miniflare or production).
- **Flutter Test Suite (320 tests):**
  - Uses Flutter test runner (`flutter test`).
  - Tests UI widgets, state notifiers, domain models, and mock repository responses.
  - Does NOT communicate with a live HTTP backend.

### 2. Live Cross-Portal End-to-End Integration Status (NOT YET RUN)
- A live multi-portal end-to-end test—where a real Engineer Flutter app submits a project, a real Next.js browser app reviews and assigns it, a real Draughtsman Flutter app accepts and submits a drawing, and a real Engineer approves it against a live Cloudflare Worker and D1 database—has **NOT yet been performed**.
- Claiming that the complete workflow is "end-to-end verified" is accurate strictly at the **contract specification and schema level**, not at the live runtime integration level.

---

## 11. Prioritized Remediation Action Items

The following discrete remediation tasks are recommended for user authorization:

### Task 1: Fix Admin Redline Correction Endpoint Mapping
- **File:** `apps/admin-web/src/lib/api.ts:L452`
- **Issue:** Client calls non-existent `POST /api/admin/projects/${projectId}/corrections`.
- **Recommended Fix:** Change endpoint to `POST /api/projects/request-correction`, passing `{ projectId, actionId, correctionId, targetVersionId, description }`.

### Task 2: Align Admin Project Creation Backend Route & RBAC
- **Files:** `apps/admin-web/src/lib/api.ts:L124` & `worker/src/index.ts:L706`
- **Issue:** Client calls `/api/admin/projects` (404), while Worker's `POST /api/projects` strictly forbids Admins (`Only engineers can create projects`).
- **Recommended Fix:** Update Worker `POST /api/projects` to allow `['ENGINEER', 'CLIENT', 'ADMIN', 'STUDIO_ADMIN']`, and update `api.ts` to call `POST /api/projects`.

### Task 3: Unify Admin Stats / Dashboard Contract
- **Files:** `apps/admin-web/src/lib/api.ts:L145` & `worker/src/index.ts:L1327`
- **Issue:** Client calls non-existent `/api/admin/stats` and falls back to client-side aggregation. Worker exposes `/api/admin/dashboard`.
- **Recommended Fix:** Add route alias `GET /api/admin/stats` in Worker returning the unified stats schema, or align `api.ts` to consume `/api/admin/dashboard`.

### Task 4: Complete Admin Comment Attachment Upload & Persistence
- **Files:** `apps/admin-web/src/app/projects/[projectId]/page.tsx:L1527`, `apps/admin-web/src/lib/api.ts:L298`, `worker/src/index.ts:L2002`
- **Issue:** Admin attachments are neither uploaded nor persisted with `attachment_file_id` in D1. Voice notes are coerced to 'pdf' in the UI.
- **Recommended Fix:** Upload attached files via `uploadProjectFile` before creating comments; pass `attachment_file_id` to `POST /api/projects/:projectId/comments`; persist `attachment_file_id` in `project_messages`; add audio preview support in Admin UI.

### Task 5: Seed Mandatory Legal Documents for Development & Staging
- **Files:** `worker/migrations/` or seed script
- **Issue:** Ordinary mobile users receive 503 `TERMS_MAINTENANCE_MODE` on business mutations if `legal_documents` is empty.
- **Recommended Fix:** Provide initial baseline terms and privacy seed migration for local/staging environments.

---

## 12. Audit Recommendation: CONDITIONAL GO FOR CHECKPOINT

### Final Assessment:
- **Core Architecture & Isolation:** **PASS (STRONG)** — Tenant isolation, suspension, capacity caps, and frozen financials are strictly enforced on the backend.
- **Static Integrity & Type Safety:** **PASS** — Next.js build clean (22/22 routes), Worker typecheck clean (0 errors), 644/644 automated tests passing.
- **Workspace Hygiene:** **PASS** — Main Admin workspace remains 100% untouched; isolated worktree has clean file inventory without secrets.
- **Direct Live Endpoint Alignment:** **CONDITIONAL** — Four client-to-backend endpoint mismatches (Redline corrections, Admin project creation, Admin stats, Comment attachments) must be remediated before live cross-portal staging.

### Recommendation:
**CONDITIONAL GO** — Proceed to authorize the discrete remediation fixes (Tasks 1–5) in `scratch/completed-integration` before executing live multi-portal end-to-end integration testing.
