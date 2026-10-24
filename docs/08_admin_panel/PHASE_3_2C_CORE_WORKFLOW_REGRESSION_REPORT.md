# Phase 3.2C — Commercial Project Lifecycle 3-Portal Regression Report

## 1. Executive Summary

- **Phase**: Phase 3.2C — Engineer–Admin–Draughtsman Commercial Project Lifecycle 3-Portal Regression
- **Workspace**: `c:\Users\inaam\.gemini\antigravity-ide\scratch\Archidraft`
- **Branch**: `feature/admin-panel-complete`
- **Portals Verified**:
  - **Flutter Web (Engineer)**: `http://localhost:8080/#/client/projects` (`zedsuo125+engineer@gmail.com`)
  - **Flutter Web (Draughtsman)**: `http://localhost:8080/#/draughtsman/studio` (`zedsuo125+draughtsman@gmail.com`)
  - **Admin Web (Studio Admin)**: `http://localhost:3000/assignments` (`zedsuo125@gmail.com`)
  - **API Runtime**: `http://127.0.0.1:8787` (Cloudflare D1 Remote Staging Worker)
- **Target Commercial Project**: `prj-comm-e2e-01` ("Metro Tech Park Core & Shell")
- **Execution Date**: 2026-10-24T16:44:00+05:30
- **Overall Status**: **PASS (100% Verified Across All 18 Audit Checks)**

---

## 2. Verification Scope & Detailed Results Matrix

Every stage of the multi-actor commercial lifecycle was executed and verified using 3 simultaneous Chromium browser automation sessions via Chrome DevTools Protocol (CDP) against live staging data:

| Stage / Check ID | Test Description | UI Evidence / Artifact | State & Network Assertion | Result |
|---|---|---|---|---|
| **3.2C-01** | Engineer authentication in Flutter Web | `01-engineer-login-screen.png` | Injected credentials via DOM semantics; token issued for `zedsuo125+engineer@gmail.com` (`KXAR90JgoVYLuOKzkbxpKTC8ATa2`). | **PASS** |
| **3.2C-02** | Engineer projects dashboard view | `02-engineer-dashboard-projects.png` | Route `/client/projects` loaded with project filters, active commercial jobs, and turnaround SLAs. | **PASS** |
| **3.2C-03** | Commercial project intake form | `03-engineer-new-project-form.png` | Route `/client/projects/new` rendered with specifications, area, and drawing type selectors. | **PASS** |
| **3.2C-04** | Project brief creation, submission, and initial state | `04-engineer-project-submitted.png` | `POST /api/projects` returned HTTP 200; `POST /api/projects/submit` advanced project to `SUBMITTED`. | **PASS** |
| **3.2C-05** | Admin review & assignment console intake | `05-admin-assignments-console.png` | `POST /api/projects/approve` advanced project to `WAITING_ASSIGNMENT`; rendered in Admin Assignments Queue at `:3000/assignments`. | **PASS** |
| **3.2C-06** | Draughtsman capacity meter inspection (SEC-03) | `06-admin-capacity-meter-draughtsman.png` | Draughtsman dispatch card rendered workload bar displaying active allocations against strict 4 concurrent project ceiling. | **PASS** |
| **3.2C-07** | Draughtsman dispatch and assignment creation | `07-admin-assigned-confirmation.png` | `POST /api/projects/assign` returned HTTP 200 with new `assignmentId`; project status mutated to `WAITING_ACCEPTANCE`. | **PASS** |
| **3.2C-08** | Draughtsman authentication in Flutter Web | `08-draughtsman-login-screen.png` | Injected credentials via DOM semantics; token issued for `zedsuo125+draughtsman@gmail.com` (`TJjtkBm3lgRlpKtcI5u3jpYPH9s1`). | **PASS** |
| **3.2C-09** | Draughtsman Studio Dashboard assignment notice | `09-draughtsman-studio-assigned.png` | Route `/draughtsman/studio` loaded displaying pending assignment card for `prj-comm-e2e-01`. | **PASS** |
| **3.2C-10** | Assignment acceptance & workspace activation | `10-draughtsman-workspace-in-progress.png` | `POST /api/assignments/accept` returned HTTP 200; project status mutated to `IN_PROGRESS`; CAD upload container active. | **PASS** |
| **3.2C-11** | Drawing v1 CAD upload & review submission | `11-draughtsman-v1-drawing-submitted.png` | Uploaded `Commercial_HVAC_v1.dwg`; `POST /api/projects/submit-drawing` promoted draft to v1 and advanced status to `UNDER_ENGINEER_REVIEW`. | **PASS** |
| **3.2C-12** | Engineer review & correction request (Round 1) | `12-engineer-review-correction-request.png` | `POST /api/projects/request-correction` recorded beam B4 offset instructions; incremented `correction_round` to 1; status reset to `IN_PROGRESS`. | **PASS** |
| **3.2C-13** | Draughtsman workspace redline notice display | `13-draughtsman-workspace-round1-redline.png` | Draughtsman workspace refreshed displaying active Round 1 correction banner with beam B4 offset redline feedback. | **PASS** |
| **3.2C-14** | Drawing v2 revised CAD upload & resubmission | `14-draughtsman-v2-resubmitted.png` | Uploaded `Commercial_HVAC_v2_Revised.dwg`; `POST /api/projects/submit-drawing` promoted draft to v2 and returned status to `UNDER_ENGINEER_REVIEW`. | **PASS** |
| **3.2C-15** | Engineer v2 review & final completion approval | `15-engineer-v2-approved-completed.png` | `POST /api/projects/approve-final` returned HTTP 200; project status mutated to terminal `COMPLETED`. | **PASS** |
| **3.2C-16** | Admin Web global project detail oversight | `16-admin-project-detail-completed.png` | Route `/projects/prj-comm-e2e-01` in Admin Web reflects `COMPLETED` lifecycle, drawing version timeline (v1, v2), and full activity logs. | **PASS** |
| **3.2C-17** | Authoritative database state persistence | Remote Cloudflare D1 Query | Status = `COMPLETED`; `correction_round` = 1; activity logs and drawing versions properly linked in D1 Staging. | **PASS** |
| **3.2C-18** | Role-Based Access Control (RBAC) security assertion | Automated API Assertion | Draughtsman token attempting to call `POST /api/projects/approve-final` strictly denied with HTTP 403 Forbidden. | **PASS** |

---

## 3. Core Architectural Confirmations

1. **Capacity Enforcement (SEC-03)**:
   The backend strictly queries active projects (`WAITING_ACCEPTANCE`, `IN_PROGRESS`, `UNDER_ENGINEER_REVIEW`, `UNDER_CLIENT_REVIEW`) and enforces that no Draughtsman can exceed 4 concurrent active assignments (`DRAUGHTSMAN_CAPACITY_EXCEEDED` HTTP 400).

2. **Drawing Version Promotion Mechanics**:
   Draft CAD uploads (`category=workspace_draft`) are promoted to immutable `drawing_versions` with monotonic version numbers upon `POST /api/projects/submit-drawing`.

3. **Correction Round Tracking**:
   Correction rounds are bound to individual `corrections` records and the parent `projects.correction_round` counter, capped at 3 rounds before administrative escalation is required.

---

## 4. Persisted Database Evidence (Cloudflare D1 Staging)

Direct verification query against database `065d76ba-eca5-4cc1-ba39-51281b79d6b4`:
```json
{
  "id": "prj-comm-e2e-01",
  "project_name": "Metro Tech Park Core & Shell",
  "drawing_name": "TECH-PARK-HVAC-01",
  "status": "COMPLETED",
  "correction_round": 1,
  "draughtsman_id": "TJjtkBm3lgRlpKtcI5u3jpYPH9s1",
  "client_id": "KXAR90JgoVYLuOKzkbxpKTC8ATa2",
  "drawing_versions_count": 2,
  "last_activity": "PROJECT_COMPLETED"
}
```

---

## 5. Certification of Completion

Phase 3.2C is **100% complete and verified**. All 16 screenshot artifacts are cataloged in `docs/08_admin_panel/phase_3_2_evidence/core_workflow/SCREENSHOT_INDEX.md`. The 3-portal commercial workflow operates in total harmony without cross-portal regression.
