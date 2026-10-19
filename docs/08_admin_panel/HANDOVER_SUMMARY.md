# ARCHI DRAFT — STUDIO ADMIN PANEL HANDOVER SUMMARY

**Project:** Archi Draft  
**Parent Brand:** Draughtsman Studio ([www.draughtsmanstudio.com](https://www.draughtsmanstudio.com/))  
**Development Studio:** PixelMint Studio MVS  
**Active Remote Branches:** `feature/admin-panel-complete`, `feature/admin-panel-foundation`  
**Latest Git Commit:** `48e3c12` (pushed to origin)  
**Date of Handover:** October 20, 2026  

---

## 1. Project & Role Architecture

ARCHI DRAFT is an architectural and engineering drawing management platform. It features exactly **three primary user portals** and one overarching studio administrative console:

1. **Engineer Portal**: Project owners (structural, civil, architectural engineers) who submit drawing requirements, review versions, and request corrections.
2. **Draughtsman Portal**: Technical drawers who accept assignments, prepare CAD/BIM drawings, and upload revisions.
3. **Student Portal**: Trainees and apprentices enrolled in architectural and drafting curriculums.
4. **Studio Admin**: The platform administrator who reviews submissions, approves/rejects projects, assigns draughtsmen, and monitors all three portals.

> **CRITICAL TERMINOLOGY RULE:**
> - There is **NO "Client" role or portal** in the product UI.
> - Every user-facing label is **Engineer** (Engineers, Engineer Management, Engineer Details, Engineer Projects).
> - Internal database fields (e.g., `client_id`, `UNDER_CLIENT_REVIEW`, and D1 role value `'CLIENT'`) are preserved for backend compatibility.

---

## 2. Admin Web Application Overview

- **Location**: [`apps/admin-web/`](file:///c:/Users/Mohammed%20Anas%20N/Desktop/Archidraft/apps/admin-web)
- **Framework**: Next.js 16.4.2 (App Router with Turbopack)
- **Styling**: Tailwind CSS, Vanilla CSS, Lucide React icons
- **Identity Provider**: Firebase Auth (email/password)
- **Backend API**: Cloudflare Worker (`https://archi-draft-worker.imserratex.workers.dev`)
- **Database**: Cloudflare D1 (SQLite-compatible relational database)
- **Object Storage**: Cloudflare R2 (CAD files, PDFs, site sketches)

### Quick Start
To launch the Admin Web application locally:
```powershell
# From root repository directory:
npm run dev
# The dev server starts on http://localhost:3000
```
*(A root `package.json` proxy script was created so `npm run dev` can be invoked from the repository root).*

---

## 3. Provisioned Admin Credentials

| Parameter | Value |
| :--- | :--- |
| **Email** | `contact@draughtsmanstudio.com` |
| **Password** | `AAAJ@PMS` |
| **Firebase UID** | `qS2HlE3sw4hdCWjoZwCCfnC8UxT2` |
| **Role** | `ADMIN` |
| **Fallback Handling** | Configured in `apps/admin-web/src/lib/api.ts` and `auth.tsx` to ensure resilience even if local D1 is unseeded. |

---

## 4. Implemented Pages & Route Structure

| Route | Page Component | Purpose |
| :--- | :--- | :--- |
| **`/dashboard`** | [`DashboardPage`](file:///c:/Users/Mohammed%20Anas%20N/Desktop/Archidraft/apps/admin-web/src/app/dashboard/page.tsx) | Three-Portal Executive Overview (Engineers, Draughtsmen, Students), project lifecycle status counters, high-priority action queue, and live telemetry. |
| **`/engineers`** | [`EngineersPage`](file:///c:/Users/Mohammed%20Anas%20N/Desktop/Archidraft/apps/admin-web/src/app/engineers/page.tsx) | Dedicated Engineer management, search, company/firm info, contact numbers, and project history dossier modal. |
| **`/draughtsmen`** | [`DraughtsmenPage`](file:///c:/Users/Mohammed%20Anas%20N/Desktop/Archidraft/apps/admin-web/src/app/draughtsmen/page.tsx) | Technical draughtsman talent pool, CAD/BIM qualifications, workload status (Active vs Available), and assignment history. |
| **`/students`** | [`StudentsPage`](file:///c:/Users/Mohammed%20Anas%20N/Desktop/Archidraft/apps/admin-web/src/app/students/page.tsx) | Student management with truthful D1 empty state and toggleable development preview fixtures (`[DEMO]` badges). |
| **`/projects`** | [`ProjectsPage`](file:///c:/Users/Mohammed%20Anas%20N/Desktop/Archidraft/apps/admin-web/src/app/projects/page.tsx) | Complete project workflow list with filters (`SUBMITTED`, `WAITING_ASSIGNMENT`, `IN_PROGRESS`, `UNDER_CLIENT_REVIEW`, `COMPLETED`, `CANCELLED`). |
| **`/projects/[projectId]`** | [`ProjectDetailPage`](file:///c:/Users/Mohammed%20Anas%20N/Desktop/Archidraft/apps/admin-web/src/app/projects/[projectId]/page.tsx) | Granular workspace: Drawing versions, Engineer reference materials, Correction rounds (capped at 3), action buttons (Approve, Reject, Assign, Reassign, Cancel). |
| **`/activity`** | [`ActivityPage`](file:///c:/Users/Mohammed%20Anas%20N/Desktop/Archidraft/apps/admin-web/src/app/activity/page.tsx) | Immutable audit log trail showing all operations across engineers, draughtsmen, and admins with action IDs. |
| **`/settings`** | [`SettingsPage`](file:///c:/Users/Mohammed%20Anas%20N/Desktop/Archidraft/apps/admin-web/src/app/settings/page.tsx) | Cloudflare Worker health check, Firebase JWKS configuration, and security model verification. |
| **`/login`** | [`LoginPage`](file:///c:/Users/Mohammed%20Anas%20N/Desktop/Archidraft/apps/admin-web/src/app/login/page.tsx) | Secure Studio Admin authentication portal featuring official Draughtsman Studio branding. |
| **`/users`** | [`UsersPage`](file:///c:/Users/Mohammed%20Anas%20N/Desktop/Archidraft/apps/admin-web/src/app/users/page.tsx) | Composite user directory with tabs for Engineers, Draughtsmen, Students, and Admins. |

---

## 5. Backend Worker Scaffolding

*File Modified:* [`worker/src/index.ts`](file:///c:/Users/Mohammed%20Anas%20N/Desktop/Archidraft/worker/src/index.ts)

1. **Role Allowlist**: Updated `POST /api/users` allowlist to `['CLIENT', 'DRAUGHTSMAN', 'STUDENT']` to allow student portal onboarding.
2. **User Details Endpoint**: Added `GET /api/users/:id` (Admin-only) which retrieves user profile and joins their associated projects (for Engineers) or assignments (for Draughtsmen).
3. **Unified Admin Stats**: Added `GET /api/admin/stats` (Admin-only) returning project counts by status, user counts by role, and recent activity logs.
4. **Client Resilient Computation**: In `apps/admin-web/src/lib/api.ts`, `adminApi.getStats()` automatically computes live statistics from `getProjects()` and `getUsers()` if the remote live Worker has not yet deployed the new stats endpoint.

---

## 6. Official Branding Assets

- **Official Logo Asset**: [`apps/admin-web/public/draughtsman_logo.jpeg`](file:///c:/Users/Mohammed%20Anas%20N/Desktop/Archidraft/apps/admin-web/public/draughtsman_logo.jpeg) (reused from `assets/images/draughtsman_logo.jpeg`).
- **Sidebar & Header**: Integrated logo thumbnail alongside "Archi Draft" and "Draughtsman Studio".
- **Credits**: PixelMint Studio MVS credited in footer and login metadata as the development studio.

---

## 7. Recommended Next Steps for the Incoming Agent

1. **Vercel Deployment**:
   - The application in `apps/admin-web/` is production-ready (`npm run build` generates 14/14 static and partially prerendered pages with 0 errors).
   - Configure environment variables on Vercel:
     - `NEXT_PUBLIC_WORKER_API_URL` = `https://archi-draft-worker.imserratex.workers.dev`
     - `NEXT_PUBLIC_FIREBASE_API_KEY`, `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN`, `NEXT_PUBLIC_FIREBASE_PROJECT_ID`, etc. (from `.env.local`).
2. **Student Portal Integration**:
   - Once the Student Portal Flutter app is tested, student registrations will automatically appear in `/students` via `role = 'STUDENT'`.
3. **Pull Request**:
   - Both `feature/admin-panel-complete` and `feature/admin-panel-foundation` are pushed to GitHub `origin`. Create a PR against `develop` or `main`.
