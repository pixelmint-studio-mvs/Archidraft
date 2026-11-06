# USER ROLES

ARCHI DRAFT enforces strict Role-Based Access Control (RBAC) at both the Flutter client routing level and the Cloudflare Worker backend API.

## Role Provisioning Policy

| Role | Self-Registration via `POST /api/users` | Provisioning Method | Portal Route Scope |
|---|:---:|---|---|
| **CLIENT** | Allowed | Public self-registration (Email/Password) | `/client/*` |
| **DRAUGHTSMAN** | Allowed | Public self-registration (Email/Password) | `/draughtsman/*` |
| **ADMIN** | Blocked (400) | Administrative database insertion / system provisioning | `/admin/*` |
| **STUDIO_ADMIN** | Blocked (400) | Administrative database insertion / system provisioning | `/admin/*` |
| **ENGINEER** | Blocked (400) | Administrative directory provisioning / system invitation | `/admin/*` (Technical Review) |
| **STUDENT** | Blocked (400) | Academic institution provisioning (Deferred) | *(Portal Deferred)* |

> **Security Rule:** Users cannot self-assign privileged or broad-access roles (`ENGINEER`, `STUDENT`, `ADMIN`, `STUDIO_ADMIN`) during registration. Profile updates via `PATCH /api/users/me` strictly whitelist profile metadata fields and never permit mutating the user's `role`.

---

## Unique User Identification System (Role-Based Unique IDs)

Every single user registered across the platform is assigned an immutable, unique sequential identification number (`identification_number`):

- **For Engineers/Architects:** Use `ENG_XX` (e.g., `ENG_01`, `ENG_02`, `ENG_03`, scaling infinitely to `ENG_100`, `ENG_1000`, etc.)
- **For Draughtsman:** Use `DM_XX` (e.g., `DM_01`, `DM_02`, `DM_03`, scaling infinitely to `DM_100`, `DM_1000`, etc.)
- **For Student:** Use `STU_XX` (e.g., `STU_01`, `STU_02`, `STU_03`, scaling infinitely to `STU_100`, `STU_1000`, etc.)

*Where `XX` are numbers and these can be added infinitely.*

### Characteristics & Guarantees:
1. **Permanent & Sequential:** Allocated atomically from `role_id_sequences` in Cloudflare D1 during registration or user profile creation.
2. **Infinite Scaling:** The numeric sequence (`XX`) starts at zero-padded two digits (`01`, `02`, ...) and expands infinitely (`100`, `1000`, `10000`+) without any upper bound.
3. **Primary Identifier Throughout App:** Displayed across Admin tables, dropdown selectors, dossier views, and Flutter profile screens as `<ID> — <Name>` (e.g., `ENG_01 — John Doe`).

---

## 1. CLIENT
The Client is the project owner.

**Can:**
- Register and Login via public portal
- Create projects and save drafts
- Submit projects for review
- Upload client reference files
- View own project progress
- Review submitted drawings
- Request corrections (unlimited rounds until satisfaction)
- Approve final drawings
- Cancel eligible projects (in `DRAFT` or `SUBMITTED` state)
- View activity logs and project messages for own projects

**Cannot:**
- Assign Draughtsmen
- Modify another user's projects or download other clients' files
- Modify user roles
- Access `/draughtsman/*` or `/admin/*` portal routes

---

## 2. DRAUGHTSMAN
The Draughtsman is the technical professional executing the drawing work.

**Can:**
- Register and Login via public portal
- Complete Draughtsman profile (qualifications, address, contact)
- View pending assignments directed to them
- Accept or reject assignments
- View project details and reference files for **accepted** assignments
- Upload drawing versions and revisions
- Submit completed drawings for client review (`UNDER_CLIENT_REVIEW`)
- Resolve assigned corrections
- Send project messages and audio voice notes in Collaboration Hub
- View completed assigned projects (historical access)

**Cannot:**
- Access unassigned projects or projects where assignment is `PENDING`, `REJECTED`, or `REPLACED`
- Self-assign to projects
- Approve final drawings or request client corrections
- Modify client personal information or project ownership
- Modify user roles

---

## 3. ADMIN & STUDIO_ADMIN
The Admin / Studio Admin manages platform operations, project approvals, and assignments.

**Can:**
- Review submitted projects (`SUBMITTED`)
- Approve projects (`WAITING_ASSIGNMENT`)
- Reject submitted projects (`CANCELLED`)
- Assign Draughtsmen to approved projects (`WAITING_ACCEPTANCE`)
- Monitor assignment statuses and project timelines across all projects
- Access any project directly, including draft projects
- Manage authorized users
- Approve final drawings or request corrections on behalf of clients when necessary
- View system-wide activity logs

**Cannot:**
- Normal users can never self-promote to Admin. Admin provisioning is strictly controlled.

---

## 4. ENGINEER
The Engineer conducts technical intake and feasibility reviews on active projects.

**Can:**
- Review non-draft projects (`SUBMITTED`, `WAITING_ASSIGNMENT`, `WAITING_ACCEPTANCE`, `IN_PROGRESS`, `UNDER_CLIENT_REVIEW`, `COMPLETED`)
- Post project messages and technical remarks in the Collaboration Hub
- Upload message attachments

**Cannot:**
- Self-register via public registration (blocked at backend)
- View or list client `DRAFT` projects
- Approve final drawings (`approve-final` is Client/Admin only)
- Request client corrections (`request-correction` is Client/Admin only)
- Assign draughtsmen (Admin only)
- Modify project status directly

---

## 5. STUDENT (Deferred / Placeholder)
The Student role represents academic learners in future educational modules.

**Can:**
- Authenticate if provisioned

**Cannot:**
- Self-register via public registration (blocked at backend)
- Access any protected client or draughtsman project (returns `403 Forbidden` on all project, file, and download routes)
- View internal activity logs or files
- The Student Portal implementation is intentionally deferred until multi-portal integration.

