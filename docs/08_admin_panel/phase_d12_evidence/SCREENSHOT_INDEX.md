# Phase D.12 Visual Evidence & Screenshot Index

**Environment:** Staging Live Environment
- Flutter Web Client: `http://localhost:8080` (Release build with `--dart-define=STAGING=true --dart-define=API_URL=https://archi-draft-worker-staging.imserratex.workers.dev`)
- Studio Admin Web Client: `http://localhost:3000` (Next.js 14 App Router)
- Staging Cloudflare Worker: `https://archi-draft-worker-staging.imserratex.workers.dev`
- Firebase Staging Project: `archi-draft-staging` (`528293938258`)

---

## 1. Portal A: Engineer (Mobile / Flutter Web)

| # | Artifact | Description | Verified Route | Status |
|---|---|---|---|---|
| 1 | [01-engineer-login.png](./portal_a_engineer/01-engineer-login.png) | Responsive SYS.LOGIN card shell with email/password input | `#/login` | PASS |
| 2 | [02-engineer-projects-feed.png](./portal_a_engineer/02-engineer-projects-feed.png) | Projects & CAD Review dashboard with active deliverables, metrics, filter pills | `#/engineer/projects` | PASS |
| 3 | [03-engineer-project-form.png](./portal_a_engineer/03-engineer-project-form.png) | Project Brief Creation Form (Project Name, Area, Drawing Type, Address) | `#/engineer/projects/new` | PASS |
| 4 | [04-engineer-project-detail.png](./portal_a_engineer/04-engineer-project-detail.png) | Project Detail CAD Review Workspace (PRJ-D6301C8C, Floor Plan, Status Badge) | `#/engineer/projects/PRJ-D6301C8C` | PASS |
| 5 | [05-engineer-activity.png](./portal_a_engineer/05-engineer-activity.png) | Engineer Audit Stream & Activity Log Ledger | `#/engineer/activity` | PASS |
| 6 | [06-engineer-profile.png](./portal_a_engineer/06-engineer-profile.png) | Engineer Account Credentials, Professional Role, and Settings | `#/profile` | PASS |

---

## 2. Portal B: Draughtsman (Studio / Flutter Web)

| # | Artifact | Description | Verified Route | Status |
|---|---|---|---|---|
| 7 | [01-draughtsman-studio.png](./portal_b_draughtsman/01-draughtsman-studio.png) | Draughtsman Studio Dashboard showing assigned project PRJ-0DD322BE, Start Drafting CTA | `#/draughtsman/studio` | PASS |
| 8 | [02-draughtsman-drawings.png](./portal_b_draughtsman/02-draughtsman-drawings.png) | Drawings Library & Deliverables Workspace | `#/draughtsman/drawings` | PASS |
| 9 | [03-draughtsman-insights.png](./portal_b_draughtsman/03-draughtsman-insights.png) | Productivity Insights, Completed Drawing Metric, Turnaround Time | `#/draughtsman/insights` | PASS |
| 10 | [04-draughtsman-profile.png](./portal_b_draughtsman/04-draughtsman-profile.png) | Draughtsman Professional Profile, Mobile Verification, Experience | `#/profile` | PASS |

---

## 3. Portal C: Student (Training / Flutter Web)

| # | Artifact | Description | Verified Route | Status |
|---|---|---|---|---|
| 11 | [01-student-dashboard.png](./portal_c_student/01-student-dashboard.png) | Student Studio Dashboard with "Welcome back, Staging", Module Cards, Progress | `#/student/dashboard` | PASS |
| 12 | [02-student-portfolio.png](./portal_c_student/02-student-portfolio.png) | Certified Student Portfolio, Completed Practical Work, Certificate Badges | `#/student/portfolio` | PASS |
| 13 | [03-student-drawings.png](./portal_c_student/03-student-drawings.png) | Training Drawings Workspace & Practice Exercises | `#/student/drawings` | PASS |
| 14 | [04-student-rbac-enforcement.png](./portal_c_student/04-student-rbac-enforcement.png) | RBAC Security Interception: Attempting to access Engineer/Admin routes redirects safely | `#/student/dashboard` | PASS |

---

## 4. Portal D: Studio Admin (Next.js Admin Web)

| # | Artifact | Description | Verified Route | Status |
|---|---|---|---|---|
| 15 | [01-admin-login.png](./portal_d_admin/01-admin-login.png) | Studio Admin Web Login Interface | `/login` | PASS |
| 16 | [02-admin-overview.png](./portal_d_admin/02-admin-overview.png) | Admin Overview Dashboard: Live KPI cards, System Health, Activity Feed | `/overview` | PASS |
| 17 | [03-admin-projects.png](./portal_d_admin/03-admin-projects.png) | Projects Management Queue with search, status filters, and live projects | `/projects` | PASS |
| 18 | [04-admin-project-detail.png](./portal_d_admin/04-admin-project-detail.png) | Admin Project Detail: CAD file inspection, assignment controls, revision rounds | `/projects/PRJ-D6301C8C` | PASS |
| 19 | [05-admin-users.png](./portal_d_admin/05-admin-users.png) | User Governance Directory with suspension/reactivation actions | `/users` | PASS |
| 20 | [06-admin-assignments.png](./portal_d_admin/06-admin-assignments.png) | Global Cross-Project Assignment History Ledger | `/assignments` | PASS |
| 21 | [07-admin-audit-log.png](./portal_d_admin/07-admin-audit-log.png) | Immutable Security Audit Log Ledger | `/audit` | PASS |
| 22 | [08-admin-financials-frozen.png](./portal_d_admin/08-admin-financials-frozen.png) | Financials Panel Safety Freeze Gate (Strict HTTP 501 / FEATURE_FROZEN) | `/financials` | PASS |
| 23 | [09-admin-settings.png](./portal_d_admin/09-admin-settings.png) | Studio Operational Configuration & Global Upload Caps | `/settings` | PASS |

---

## 5. Cross-Portal Consistency & Synchronization

| # | Artifact | Description | Verified Portals | Status |
|---|---|---|---|---|
| 24 | [01-cross-portal-project-sync.png](./cross_portal_workflow/01-cross-portal-project-sync.png) | Bi-directional consistency: Project created in Admin Web reflects in Draughtsman & Engineer feeds | Admin <-> Draughtsman <-> Engineer | PASS |

---

**Summary:** 24 key visual evidence captures spanning all 4 portals, authentic authenticated sessions, and cross-portal synchronizations verified.
