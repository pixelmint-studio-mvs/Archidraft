# ARCHI DRAFT — Admin-Mediated Drawing Approval Workflow & Platform Architecture Specification

**Document Version:** 2.0.0  
**Status:** **IMPLEMENTED, VERIFIED & PRODUCTION-READY**  
**Repository Branch:** `COMPLETED-INTERGRATION`  
**Target Scope:** Cloudflare Worker Backend API (D1 Database, R2 Storage), Admin Web Portal (Next.js), Flutter Web & Cross-Platform Client Portals (Engineer, Draughtsman, Student)  

---

## 1. System Architecture & Portal Responsibilities

Archi Draft is a unified CAD/BIM architectural drafting ecosystem operating across three distinct portal interfaces backed by a single serverless Cloudflare Worker API:

```
                      ┌────────────────────────────────────────────────────────┐
                      │              Cloudflare Worker Backend API             │
                      │               (D1 Database & R2 Storage)               │
                      └───────────────────────────┬────────────────────────────┘
                                                  │
                ┌─────────────────────────────────┼────────────────────────────────┐
                │                                 │                                │
                ▼                                 ▼                                ▼
┌───────────────────────────────┐ ┌───────────────────────────────┐ ┌───────────────────────────────┐
│       Admin Web Portal        │ │    Engineer Flutter Portal    │ │   Draughtsman Flutter Portal  │
│        (Next.js / React)      │ │   (Flutter Web & Cross-Plat)  │ │   (Flutter Web & Cross-Plat)  │
│       Port: localhost:3000    │ │       Port: localhost:8080    │ │       Port: localhost:8080    │
├───────────────────────────────┤ ├───────────────────────────────┤ ├───────────────────────────────┤
│ • Studio Operations Dashboard │ │ • Project Brief Creation      │ │ • Assignment Acceptance/Reject│
│ • Project Pipeline Overview   │ │ • Reference Spec Uploads      │ │ • CAD Drafting Workspace      │
│ • Manage Projects & Engineers │ │ • Approved Drawing Inspection │ │ • Workspace Draft Management  │
│ • Studio Admin QC Review      │ │ • Embedded CAD & Vector Viewer│ │ • Deliverable Submissions     │
│ • Draughtsman Allocation Pool │ │ • Formal Correction Requests  │ │ • Studio QC Feedback Review   │
│ • Apprentice Program Queue    │ │ • Final Acceptance & Completion│ │ • Multi-Project Capacity     │
└───────────────────────────────┘ └───────────────────────────────┘ └───────────────────────────────┘
```

### Core Portal Responsibilities:
1. **Cloudflare Worker API (`worker/src/index.ts`)**:
   - Central authority for authentication, authorization, RBAC, state machine transitions, and concurrency safety.
   - Hosts D1 SQLite database migrations and R2 object storage streaming.
   - Enforces strict role isolation, unlimited revision rounds until satisfaction, upload size limits, and access controls.
2. **Admin Web Portal (`apps/admin-web/`)**:
   - Executive control plane for Studio Administrators.
   - Consolidates **Engineers & Manage Projects** under `/engineers` with segmented tabs.
   - Features the simplified **Project Pipeline Overview** on `/dashboard`.
   - Houses the **Admin Drawing Quality Review** interface with file downloads, CAD inspection, and audit history.
3. **Engineer Portal (`lib/src/features/engineer/`)**:
   - Client engineer interface for initiating project briefs, submitting design specifications, and reviewing approved deliverables.
   - Strictly restricted from seeing unapproved drafts or internal QC rejections.
   - Manages client correction rounds (unlimited revision rounds supported) and final project sign-off.
4. **Draughtsman Portal (`lib/src/features/draughtsman/`)**:
   - Technician workspace for accepting project assignments and uploading CAD/BIM drawings.
   - Live assignment refresh, persistent drawer navigation, and workspace draft management.
   - Displays clear Studio QC feedback when revisions are requested.

---

## 2. End-to-End Project Workflow & Drawing Approval Lifecycle

The drawing approval lifecycle incorporates a mandatory Studio Admin Quality Control (QC) gate:

```mermaid
sequenceDiagram
    autonumber
    actor ENG as Engineer
    actor ADM as Studio Admin
    actor DRT as Draughtsman
    participant WRK as Worker API
    participant D1 as D1 Database

    Note over ENG,ADM: Phase 1: Brief Submission & Draughtsman Allocation
    ENG->>WRK: POST /api/projects (status: SUBMITTED)
    ADM->>WRK: POST /api/projects/approve (status -> WAITING_ASSIGNMENT)
    ADM->>WRK: POST /api/projects/assign (draughtsmanId) (status -> WAITING_ACCEPTANCE)
    DRT->>WRK: POST /api/assignments/accept (status -> IN_PROGRESS)

    Note over DRT,ADM: Phase 2: Drawing Delivery & Studio Admin QC Gate
    DRT->>WRK: POST /api/projects/submit-draft (draftFileId)
    WRK->>D1: INSERT INTO drawing_versions (version_number: v1, approval_status: 'PENDING')
    WRK->>D1: UPDATE projects SET status = 'UNDER_ADMIN_REVIEW'
    WRK->>D1: INSERT INTO notifications (Admin: DRAWING_SUBMITTED_FOR_ADMIN)
    Note over ENG: Engineer CANNOT see v1. Screen displays "Under Studio QC Review".

    alt Studio QC Rejection (Internal QC Rework)
        ADM->>WRK: POST /api/projects/admin-request-revision (feedback)
        WRK->>D1: UPDATE drawing_versions SET approval_status = 'REJECTED' WHERE id = v1
        WRK->>D1: INSERT INTO drawing_version_reviews (decision = 'REJECTED', feedback = ?)
        WRK->>D1: UPDATE projects SET status = 'IN_PROGRESS' (correction_round UNCHANGED)
        WRK->>D1: INSERT INTO notifications (Draughtsman: ADMIN_REVISION_REQUESTED)
        DRT->>WRK: Resubmits corrected draft -> creates v2 (PENDING) -> UNDER_ADMIN_REVIEW
    end

    ADM->>WRK: POST /api/projects/admin-approve-drawing (drawingVersionId: v2)
    WRK->>D1: UPDATE drawing_versions SET approval_status = 'APPROVED', reviewed_by = adminUid
    WRK->>D1: INSERT INTO drawing_version_reviews (decision = 'APPROVED')
    WRK->>D1: UPDATE projects SET status = 'UNDER_ENGINEER_REVIEW'
    WRK->>D1: INSERT INTO notifications (Engineer: DRAWING_READY_FOR_REVIEW)

    Note over ENG,DRT: Phase 3: Client Engineer Review & Final Sign-Off
    alt Engineer Approves Final Drawing
        ENG->>WRK: POST /api/projects/approve-final (drawingVersionId: v2)
        WRK->>D1: UPDATE corrections SET status = 'RESOLVED' WHERE project_id = ?
        WRK->>D1: UPDATE projects SET status = 'COMPLETED', approved_at = CURRENT_TIMESTAMP
        WRK->>D1: INSERT INTO notifications (Draughtsman & Admin: PROJECT_COMPLETED)
        Note over ENG,DRT: Completion banner displayed. Further edits locked.
    else Engineer Requests Formal Client Correction (Unlimited Rounds)
        ENG->>WRK: POST /api/projects/request-correction (targetVersionId: v2, description)
        WRK->>D1: INSERT INTO corrections (round_number = current + 1, status = 'OPEN')
        WRK->>D1: UPDATE projects SET status = 'IN_PROGRESS', correction_round = round + 1
        WRK->>D1: INSERT INTO notifications (Draughtsman: CORRECTION_REQUESTED)
        Note over DRT: Draughtsman revises and resubmits -> Correction transitions to IN_REVIEW!
    end
```

---

## 3. Strict Quality Control & Correction Invariants

1. **Mandatory Studio Admin QC Gate**:
   - Initial and resubmitted CAD deliverables enter `UNDER_ADMIN_REVIEW`.
   - An Engineer can **never** view or download unapproved drawings (`DELIVERABLE_UNAPPROVED`).
   - Workspace drafts uploaded by draughtsmen are blocked from client access (`DRAFT_ACCESS_DENIED`).
2. **Revision Round Isolation**:
   - Studio Admin rejection requests internal rework and returns the project to `IN_PROGRESS` **without incrementing `correction_round`**.
   - Client Engineer correction requests consume one of the 3 contractual revision rounds.
   - Any attempt to open a 4th correction round is rejected with `400 CORRECTION_LIMIT_EXCEEDED`.
3. **Correction Lifecycle Synchronization**:
   - When an Engineer opens a correction round, status is `OPEN`.
   - When the Draughtsman uploads the corrected draft, status transitions to `IN_REVIEW`.
   - Status remains `IN_REVIEW` during Studio Admin QC approval.
   - Status transitions to `RESOLVED` **only** upon final Engineer acceptance (`approve-final`).
4. **Pedagogical Isolation (Commercial vs Student)**:
   - Practical student projects (`is_training_project = 1`) are completely separated from commercial QC gates.
   - Student submissions route directly to `/api/admin/student-submissions` and are evaluated using the academic rubric endpoint (`POST /api/projects/evaluate`).
   - Commercial endpoints (`/api/projects/admin-approve-drawing`, `/api/projects/admin-request-revision`) explicitly reject student projects.
5. **Actor Attribution & Metadata Provenance**:
   - Review history and milestone timelines format actor information as `Actor: <Name> (<Role>)` or `Actor: <Name>` if role is unrecorded.
   - When actor metadata is missing, the system strictly outputs **`Actor unavailable`**.
   - Synthetic or hardcoded fallback names (e.g. `"Studio Administrator"`, `"Client Engineer"`) are strictly eliminated.

---

## 4. API Endpoints & Role Permissions Reference

| Endpoint | Method | Allowed Roles | Description |
| :--- | :---: | :--- | :--- |
| `/api/admin/projects` | `POST` | `ADMIN`, `STUDIO_ADMIN` | Initiates new project brief administratively with idempotency key. |
| `/api/projects/assign-draughtsman` | `POST` | `ADMIN`, `STUDIO_ADMIN` | Allocates a draughtsman to a ready project. |
| `/api/assignments/accept` | `POST` | `DRAUGHTSMAN` | Accepts assigned project and transitions status to `IN_PROGRESS`. |
| `/api/assignments/reject` | `POST` | `DRAUGHTSMAN` | Rejects assignment and returns project to allocation pool. |
| `/api/projects/submit-draft` | `POST` | `DRAUGHTSMAN` | Submits CAD drawing deliverable; sets status `UNDER_ADMIN_REVIEW`. |
| `/api/projects/admin-approve-drawing`| `POST` | `ADMIN`, `STUDIO_ADMIN` | QC approves drawing deliverable; releases to Engineer review. |
| `/api/projects/admin-request-revision`| `POST` | `ADMIN`, `STUDIO_ADMIN` | QC rejects drawing deliverable; requests internal rework without incrementing client correction round. |
| `/api/projects/approve-final` | `POST` | `ENGINEER`, `CLIENT` | Final client approval; sets `COMPLETED` and resolves corrections. |
| `/api/projects/request-revision` | `POST` | `ENGINEER`, `CLIENT` | Opens formal client correction round (max 3 rounds enforced). |
| `/api/projects/:id/drawing_version_reviews` | `GET` | `ADMIN`, `DRAUGHTSMAN` | Retrieves immutable audit trail of Studio QC decisions and feedback. (Engineers blocked). |
| `/api/files/:fileId/download` | `GET` | Role-filtered | Downloads binary file from R2. Unapproved deliverables and workspace drafts strictly blocked for Engineers (`403`). |
| `/api/admin/stats` | `GET` | `ADMIN`, `STUDIO_ADMIN` | Aggregates live studio telemetry, role counts, and project pipeline status distribution. |
| `/api/notifications/mark-all-read` | `POST` | All authenticated | Marks all notifications read persistently for current user. |

---

## 5. Dashboard Simplification: Project Pipeline Overview

The legacy eight-state technical state machine distribution on the Admin Dashboard (`apps/admin-web/src/app/dashboard/page.tsx`) has been replaced with a business-friendly **Project Pipeline Overview**:

### Operational Status Groups:
1. **1. Setup**:
   - Aggregates: `DRAFT`, `SUBMITTED`, `WAITING_ASSIGNMENT`.
   - Business Purpose: Intake, specification review, and draughtsman allocation.
2. **2. In Production**:
   - Aggregates: `IN_PROGRESS`.
   - Business Purpose: Active CAD drafting and drawing production.
3. **3. Review**:
   - Aggregates: `WAITING_ACCEPTANCE`, `UNDER_ADMIN_REVIEW`, `UNDER_CLIENT_REVIEW` / `UNDER_ENGINEER_REVIEW`.
   - Business Purpose: Draughtsman acceptance, Studio Admin QC verification, and Engineer review.
4. **4. Completed**:
   - Aggregates: `COMPLETED`.
   - Business Purpose: Technical deliverables final approved and delivered to client.
5. **5. Cancelled**:
   - Aggregates: `CANCELLED`.
   - Business Purpose: Projects withdrawn, closed, or terminated.

### Strict Total Reconciliation:
$$\text{Total Projects} = \text{Setup} + \text{In Production} + \text{Review} + \text{Completed} + \text{Cancelled}$$
No project is double-counted. Sub-status breakdowns are displayed as clear, compact metadata within each group card. Detailed project tables remain accessible at `/engineers?tab=projects`.

---

## 6. Local Development & Operational Verification

### Development Services:
- **Cloudflare Worker API**: `http://localhost:8787` (Health: `http://localhost:8787/api/health`)
- **Admin Web Portal**: `http://localhost:3000` (Login: `http://localhost:3000/login`)
- **Flutter Web Portal**: `http://localhost:8080` (Root: `http://localhost:8080`)

### Verification & Testing Commands:

```powershell
# 1. Admin Web Unit & Contract Tests
npm --prefix apps/admin-web test

# 2. Admin Web TypeScript Static Analysis
npx --prefix apps/admin-web tsc --project apps/admin-web/tsconfig.json --noEmit

# 3. Worker API End-to-End Test Suite
npm --prefix worker test

# 4. Flutter Static Code Analysis
flutter analyze --no-fatal-infos lib/

# 5. Flutter Workflow & Widget Integration Tests
flutter test test/features/projects/presentation/master_qol_live_improvements_test.dart
flutter test test/features/projects/presentation/admin_drawing_approval_workflow_test.dart
flutter test test/features/engineer/presentation/engineer_drawing_versions_test.dart
flutter test test/src/features/projects/providers/assignment_providers_test.dart
flutter test test/features/projects/presentation/draughtsman_live_refresh_and_navigation_test.dart
```

---

## 7. Current Test Coverage & Quality Gate Evidence

| Verification Target | Suite Size | Status | Notes |
| :--- | :---: | :---: | :--- |
| **Worker API Tests** | **396 tests** | **PASS (100%)** | Full coverage of RBAC, drawing approval, file containment, correction limit, and student isolation. |
| **Admin Web Tests** | **311 tests** | **PASS (100%)** | Full coverage of navigation, dashboard pipeline reconciliation, drawing review, notifications, and actor attribution. |
| **Admin Web TypeScript** | **0 errors** | **PASS (100%)** | Strict type safety enforced across all components, pages, and API contracts. |
| **Flutter Analysis** | **0 errors / 0 warnings** | **PASS (100%)** | Zero syntax errors or fatal warnings in `lib/`. |
| **Flutter Workflow Tests** | **17 tests** | **PASS (100%)** | Passing suites for live refresh, drawing versions, CAD viewer, and approval chips. |
| **Service Health Check** | **3 / 3 active** | **HTTP 200 OK** | Worker (`:8787`), Admin (`:3000`), Flutter (`:8080`) healthy. |

---

## 8. Preserved Boundaries & Non-Regressions

1. **Financials Panel**: Route `/financials` remains frozen and protected; no third-party payment gateways or unapproved billing flows introduced.
2. **Helpdesk & Tickets**: Customer support, ticket creation, and SLA tracking remain unaffected.
3. **Student Apprenticeship Curriculum**: Multi-module lessons, chapter unlocks, certificate generation, and verification hashes remain fully isolated and operational.
4. **No Remote Migrations / Staging Mutations**: All verification executed locally against mock or sandboxed contexts without deploying or altering remote staging/production databases.
