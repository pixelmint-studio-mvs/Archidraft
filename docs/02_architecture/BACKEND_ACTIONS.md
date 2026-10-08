# BACKEND ACTIONS & REST CONTRACTS

All critical application actions are executed through the Cloudflare Worker API. Direct client mutations on the database or storage are strictly forbidden.

---

## 1. Project Lifecycle Endpoints

| Endpoint | Method | Actor Role | Preconditions | Database Changes | Activity Log Action |
|---|---|---|---|---|---|
| `/api/projects` | `POST` | `ENGINEER` | Authenticated Engineer | Inserts/Updates project in `DRAFT` | None (Drafting) |
| `/api/projects/submit` | `POST` | `ENGINEER` | Project owner, Status=`DRAFT` | Status → `SUBMITTED`, `submitted_at` set | `PROJECT_SUBMITTED` |
| `/api/projects/approve` | `POST` | `STUDIO_ADMIN` | Status=`SUBMITTED` | Status → `WAITING_ASSIGNMENT` | `PROJECT_APPROVED` |
| `/api/projects/reject` | `POST` | `STUDIO_ADMIN` | Status=`SUBMITTED` | Status → `CANCELLED`, reason set | `PROJECT_REJECTED` |
| `/api/projects/assign` | `POST` | `STUDIO_ADMIN` | Status=`WAITING_ASSIGNMENT` | Creates Assignment (`PENDING`), Status → `WAITING_ACCEPTANCE` | `DRAUGHTSMAN_ASSIGNED` |
| `/api/assignments/accept` | `POST` | `DRAUGHTSMAN` | Assigned Drafter, Status=`WAITING_ACCEPTANCE` | Assignment → `ACCEPTED`, Status → `IN_PROGRESS` | `ASSIGNMENT_ACCEPTED` |
| `/api/assignments/reject` | `POST` | `DRAUGHTSMAN` | Assigned Drafter, Status=`WAITING_ACCEPTANCE` | Assignment → `REJECTED`, Status → `WAITING_ASSIGNMENT` | `ASSIGNMENT_REJECTED` |
| `/api/projects/submit-drawing` | `POST` | `DRAUGHTSMAN` | Assigned Drafter, Status=`IN_PROGRESS` | Status → `UNDER_CLIENT_REVIEW`, open corrections resolved | `DRAWING_SUBMITTED` |
| `/api/projects/request-correction` | `POST` | `ENGINEER` | Project owner, Status=`UNDER_CLIENT_REVIEW`, round < 3 | Creates Correction (`OPEN`), Status → `IN_PROGRESS`, `correction_round` incremented | `CORRECTION_REQUESTED` |
| `/api/projects/approve-final` | `POST` | `ENGINEER` | Project owner, Status=`UNDER_CLIENT_REVIEW` | Status → `COMPLETED` | `PROJECT_COMPLETED` |

---

## 2. File & Storage Endpoints

| Endpoint | Method | Actor Role | Purpose |
|---|---|---|---|
| `/api/projects/:projectId/files?category=...` | `POST` | `ENGINEER` / `DRAUGHTSMAN` | Streams file upload into R2 and creates D1 file record. |
| `/api/projects/:projectId/files` | `GET` | Authorized participants | Retrieves metadata list of files attached to project. |
| `/api/files/:fileId/download` | `GET` | Authorized participants | Streams binary file from R2 (`disposition=inline` or `attachment`). |
| `/api/projects/:projectId/files/:fileId` | `DELETE` | `ENGINEER` (owner) | Deletes file from R2 and removes record from D1. |

---

## 3. Collaboration Hub Endpoints

| Endpoint | Method | Actor Role | Purpose |
|---|---|---|---|
| `/api/projects/:projectId/messages` | `GET` | `ENGINEER` / `DRAUGHTSMAN` / `ADMIN` | Fetches conversation message history. |
| `/api/projects/:projectId/messages` | `POST` | `ENGINEER` / `DRAUGHTSMAN` / `ADMIN` | Posts message and optional attachment; triggers notification. |

---

## 4. Activity & Notifications Endpoints

| Endpoint | Method | Actor Role | Purpose |
|---|---|---|---|
| `/api/activity` | `GET` | Authenticated User | Retrieves activity logs scoped to the authenticated role. |
| `/api/projects/:projectId/activity` | `GET` | Authorized participants | Retrieves activity history for a specific project. |
| `/api/notifications` | `GET` | Authenticated User | Fetches user notifications. |
| `/api/notifications/:id/read` | `POST` | Notification recipient | Marks notification as read. |
