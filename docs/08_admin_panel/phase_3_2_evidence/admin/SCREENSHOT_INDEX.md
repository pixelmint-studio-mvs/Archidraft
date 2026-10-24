# Phase 3.2A — Studio Admin Submissions Queue & Evaluation UI Screenshot Index

**Environment**: Local Staging Dev (`http://localhost:3000` against Cloudflare D1 Staging)  
**Execution Timestamp**: 2026-10-24T14:52:00+05:30  
**Browser Engine**: Headless Chromium (CDP Automation, 1440x900 viewport)  
**Authentication**: Studio Admin (`zedsuo125@gmail.com`)  

---

### Screenshot Catalog

| Index | File Name | Viewport / URL | Description & Verification Target | Status |
|---|---|---|---|---|
| 01 | `01-admin-login-screen.png` | `http://localhost:3000/login` | Initial administrative sign-in portal displaying technical badge `SYS.ADMIN.AUTH.v2.4 // PROTOCOL_SECURE`, architectural logo framing, and credential inputs. | **VERIFIED** |
| 02 | `02-admin-authenticated-dashboard.png` | `http://localhost:3000/dashboard` | Post-login authenticated state with Studio Dashboard KPIs, live project pipeline metrics, and system status indicator. | **VERIFIED** |
| 03 | `03-admin-submissions-sidebar-nav.png` | `http://localhost:3000/dashboard` | Left-hand navigation rail with active route selection showing "Student Submissions" under the "Workflow & Pipeline" operational group. | **VERIFIED** |
| 04 | `04-admin-submissions-queue-populated.png` | `http://localhost:3000/students/submissions` | Complete populated view of the Student Practical Submissions Queue with 4 operational KPIs (Total Submissions: 6, Awaiting Review: 4, In Revision: 0, Approved/Certified: 2), active table rows, apprentice details, modules, versions, and "Review & Score" action buttons. | **VERIFIED** |
| 05 | `05-admin-submissions-search-filter.png` | `http://localhost:3000/students/submissions` | Reactive search query execution (`"Floor Plan"`) filtering table rows in real-time without round-trip network reloads. | **VERIFIED** |
| 06 | `06-admin-submissions-status-filter.png` | `http://localhost:3000/students/submissions` | Status tab selection (`Awaiting Review`) isolating submissions in `UNDER_ENGINEER_REVIEW` state requiring administrative evaluation. | **VERIFIED** |
| 07 | `07-admin-evaluate-modal-rubric-validation.png` | `http://localhost:3000/students/submissions` | EvaluateModal component open displaying the 3 rubric evaluation criteria, and demonstrating strict client validation error banner (`"Please provide an Accuracy score between 1 and 5"`) when attempting premature submission. | **VERIFIED** |
| 08 | `08-admin-evaluate-approved-success.png` | `http://localhost:3000/students/submissions` | Successful evaluation submission with decision `Approved`, full 5/5 rubric scoring, qualitative commentary, and responsive post-action table refresh. | **VERIFIED** |
| 09 | `09-admin-evaluate-revision-success.png` | `http://localhost:3000/students/submissions` | EvaluateModal execution for `Needs Revision` on `prj-adm-e2e-rev`, setting score 3/3, inputting technical redline correction instructions, and updating state to `IN_PROGRESS` with incremented correction round. | **VERIFIED** |
| 10 | `10-admin-evaluate-rejection-success.png` | `http://localhost:3000/students/submissions` | EvaluateModal execution for `Rejected` on `prj-adm-e2e-rej`, recording explicit rejection reason and terminal state `CANCELLED`. | **VERIFIED** |
| 11 | `11-admin-project-detail-evaluation-card.png` | `http://localhost:3000/projects/prj-adm-e2e-appr` | Deep project detail view with integrated evaluation state card, specifications, files, and verified persistence after full browser reload. | **VERIFIED** |
| 12 | `12-admin-settings-terms-functional.png` | `http://localhost:3000/settings` | Settings & Governance screen confirming pre-login Terms & Conditions, turnaround SLA defaults, and platform governance remain intact. | **VERIFIED** |
| 13 | `13-admin-session-logout.png` | `http://localhost:3000/login` | Session termination via bottom-rail `Sign out` action, clearing session state and safely redirecting to `/login`. | **VERIFIED** |

---

### Verification Summary
- **Total Evidence Artifacts Captured**: 13
- **All Core Scenarios**: 100% PASS
- **Integrity Check**: No fabricated data; all records persisted directly to Cloudflare D1 Staging database `065d76ba-eca5-4cc1-ba39-51281b79d6b4`.
