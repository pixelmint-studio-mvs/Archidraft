# Phase 3.2B — Student–Admin Lifecycle Cross-Portal E2E Screenshot Index

**Environment**: Dual Portal Staging Integration:
- **Flutter Web (Port 8080)**: Apprentice Student Experience (`zedsuo125+student@gmail.com`)
- **Admin Web (Port 3000)**: Studio Admin Review Experience (`zedsuo125@gmail.com`)
- **API Runtime (Port 8787)**: Remote Cloudflare D1 Staging Worker (`065d76ba-eca5-4cc1-ba39-51281b79d6b4`)

**Execution Timestamp**: 2026-10-24T16:34:00+05:30  
**Browser Engine**: Headless Chromium (Dual CDP Automation Sessions, 1440x900 viewport)  
**Authentication**: Student Apprentice & Studio Administrator  

---

### Screenshot Catalog

| Index | File Name | Portal / URL | Description & Verification Target | Status |
|---|---|---|---|---|
| 01 | `01-student-login-screen.png` | Flutter Web (`:8080/#/login`) | Student apprentice sign-in interface in Flutter Web with rendered DOM semantics and input readiness. | **VERIFIED** |
| 02 | `02-student-dashboard-assignments.png` | Flutter Web (`:8080/#/student/dashboard`) | Authenticated Student Dashboard displaying training practical assignments, current metrics, and module progress. | **VERIFIED** |
| 03 | `03-student-appr-workspace-pending.png` | Flutter Web (`:8080/#/student/workspace/prj-student-appr-01`) | Architectural Villa practical test workspace in initial `WAITING_ACCEPTANCE` state with "Accept Assignment" CTA. | **VERIFIED** |
| 04 | `04-student-appr-accepted-draft.png` | Flutter Web (`:8080/#/student/workspace/prj-student-appr-01`) | Post-acceptance workspace state showing `IN_PROGRESS` transition, CAD upload interface, and draft file staging. | **VERIFIED** |
| 05 | `05-student-appr-submitted-awaiting.png` | Flutter Web (`:8080/#/student/workspace/prj-student-appr-01`) | Post-submission state displaying `UNDER_ENGINEER_REVIEW` badge, locking workspace edits while awaiting evaluation. | **VERIFIED** |
| 06 | `06-admin-appr-submissions-queue.png` | Admin Web (`:3000/students/submissions`) | Admin Submissions Queue displaying the newly submitted practical test `prj-student-appr-01` ready for administrative scoring. | **VERIFIED** |
| 07 | `07-admin-appr-evaluate-modal-approved.png` | Admin Web (`:3000/students/submissions`) | EvaluateModal displaying rubric scoring (Accuracy: 5/5, Standards: 5/5), qualitative feedback, and "Approved" decision. | **VERIFIED** |
| 08 | `08-student-appr-completed-card.png` | Flutter Web (`:8080/#/student/workspace/prj-student-appr-01`) | Student workspace reactive refresh showing `COMPLETED` banner, passed evaluation scores, and earned credit acknowledgment. | **VERIFIED** |
| 09 | `09-student-rev-submitted-v1.png` | Flutter Web (`:8080/#/student/workspace/prj-student-rev-02`) | Commercial Complex practical v1 drawing submitted and placed in `UNDER_ENGINEER_REVIEW` awaiting admin review. | **VERIFIED** |
| 10 | `10-admin-rev-evaluate-revision-request.png` | Admin Web (`:3000/students/submissions`) | Admin evaluation recording "Needs Revision" with egress redline feedback and correction instructions. | **VERIFIED** |
| 11 | `11-student-rev-feedback-banner.png` | Flutter Web (`:8080/#/student/workspace/prj-student-rev-02`) | Student workspace reflecting returned correction round 1 with active feedback banner and redline instructions. | **VERIFIED** |
| 12 | `12-student-rev-v2-submitted.png` | Flutter Web (`:8080/#/student/workspace/prj-student-rev-02`) | Student v2 revised drawing uploaded and resubmitted, placing project back in `UNDER_ENGINEER_REVIEW`. | **VERIFIED** |
| 13 | `13-admin-rev-v2-approved.png` | Admin Web (`:3000/students/submissions`) | Admin Submissions Queue after admin approves v2 resubmission, successfully advancing project to `COMPLETED`. | **VERIFIED** |
| 14 | `14-student-rej-submitted-v1.png` | Flutter Web (`:8080/#/student/workspace/prj-student-rej-03`) | Structural Layout practical v1 drawing submitted for administrative evaluation. | **VERIFIED** |
| 15 | `15-admin-rej-evaluate-rejection.png` | Admin Web (`:3000/students/submissions`) | Admin EvaluateModal recording explicit rejection decision for zoning setback non-compliance. | **VERIFIED** |
| 16 | `16-student-rej-cancelled-reason.png` | Flutter Web (`:8080/#/student/workspace/prj-student-rej-03`) | Student workspace showing `CANCELLED` terminal state with displayed administrative rejection reason. | **VERIFIED** |
| 17 | `17-student-credentials-portfolio.png` | Flutter Web (`:8080/#/student/portfolio`) | Student Portfolio & Credentials screen reflecting earned certificates, completed practicals, and evaluation badges. | **VERIFIED** |

---

### Verification Summary
- **Total Evidence Artifacts Captured**: 17
- **Cross-Portal Interoperability**: 100% PASS across Flutter Web and Admin Web
- **Authoritative Database Persistence**: Verified in remote Cloudflare D1 Staging database `065d76ba-eca5-4cc1-ba39-51281b79d6b4`
- **Role Isolation & RBAC**: Confirmed student token receives HTTP 403 Forbidden on administrative evaluation endpoints.
