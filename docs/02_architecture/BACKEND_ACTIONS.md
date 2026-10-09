# BACKEND ACTIONS

This table documents the contract for all critical backend actions executed via the Cloudflare Worker API.

## 1. Project Lifecycle & State Transitions

| Action | Endpoint | Actor | Preconditions (State Validation) | Database Changes | Activity Logging | Idempotency |
|---|---|---|---|---|---|:---:|
| `createProject` | `POST /api/projects` | Client | Role=CLIENT | Insert project in `DRAFT` | (Client-side init) | N/A |
| `submitProject` | `POST /api/projects/submit` | Client | Project Owner, `DRAFT` | Status -> `SUBMITTED`, `submitted_at` set | `PROJECT_SUBMITTED` | Yes |
| `approveProject` | `POST /api/projects/approve` | Admin, Studio Admin | `SUBMITTED` | Status -> `WAITING_ASSIGNMENT` | `PROJECT_APPROVED` | Yes |
| `rejectProject` | `POST /api/projects/reject` | Admin, Studio Admin | `SUBMITTED` | Status -> `CANCELLED`, `reject_reason` | `PROJECT_REJECTED` | Yes |
| `assignDraughtsman`| `POST /api/projects/assign` | Admin, Studio Admin | `WAITING_ASSIGNMENT` | Status -> `WAITING_ACCEPTANCE`, assignment created | `DRAUGHTSMAN_ASSIGNED` | Yes |
| `acceptAssignment` | `POST /api/projects/accept` | Draughtsman | Assigned Draughtsman, `WAITING_ACCEPTANCE` | Assignment -> `ACCEPTED`, Status -> `IN_PROGRESS` | `ASSIGNMENT_ACCEPTED` | Yes |
| `rejectAssignment` | `POST /api/projects/reject-assignment` | Draughtsman | Assigned Draughtsman, `WAITING_ACCEPTANCE` | Assignment -> `REJECTED`, Status -> `WAITING_ASSIGNMENT` | `ASSIGNMENT_REJECTED` | Yes |
| `uploadVersion` | `POST /api/projects/:id/files?category=draughtsman_version` | Draughtsman | Assigned Draughtsman, `IN_PROGRESS` | Insert file & `drawing_versions` record | `VERSION_UPLOADED` | Yes |
| `submitDrawing` | `POST /api/projects/submit-drawing` | Draughtsman | Assigned Draughtsman, `IN_PROGRESS` | Status -> `UNDER_CLIENT_REVIEW` | `DRAWING_SUBMITTED` | Yes |
| `requestCorrection`| `POST /api/projects/request-correction` | Client, Admin | Project Owner / Admin, `UNDER_CLIENT_REVIEW`, round < 3 | Status -> `IN_PROGRESS`, Correction created (`OPEN`) | `CORRECTION_REQUESTED` | Yes |
| `resolveCorrection`| `POST /api/projects/resolve-correction` | Draughtsman | Assigned Draughtsman, `IN_PROGRESS`, Correction=`OPEN` | Correction -> `RESOLVED` | `CORRECTION_RESOLVED` | Yes |
| `approveFinal` | `POST /api/projects/approve-final` | Client, Admin | Project Owner / Admin, `UNDER_CLIENT_REVIEW` | Status -> `COMPLETED`, `completed_at` set | `PROJECT_COMPLETED` | Yes |
| `cancelProject` | `POST /api/projects/cancel` | Client, Admin | Project Owner / Admin, `DRAFT` or `SUBMITTED` | Status -> `CANCELLED` | `PROJECT_CANCELLED` | Yes |

*(Note: Idempotency is enforced by verifying `project.last_action_id === actionId` before executing mutations, preventing duplicate transitions on network retries).*

---

## 2. Collaboration Hub Messaging API

| Action | Endpoint | Actor | Authorization Check | Description |
|---|---|---|---|---|
| `listMessages` | `GET /api/projects/:projectId/messages` | Client, Draughtsman, Engineer, Admin | `canUserAccessProject` | Lists chronologically ordered project chat messages and attachments |
| `postMessage` | `POST /api/projects/:projectId/messages` | Client, Draughtsman, Engineer, Admin | `canUserAccessProject` | Posts message and optional file attachment; creates notification for counterpart |

---

## 3. Notifications API

| Action | Endpoint | Actor | Authorization Check | Description |
|---|---|---|---|---|
| `listNotifications` | `GET /api/notifications` | Any Authenticated | `user_id = uid` | Returns notifications scoped strictly to the authenticated user |
| `markAllRead` | `PATCH /api/notifications/read-all` | Any Authenticated | `user_id = uid` | Marks all notifications for user as read |
| `markRead` | `PATCH /api/notifications/:id/read` | Any Authenticated | `user_id = uid` | Marks specific notification as read |

---

## 4. User Profile & Account Provisioning API

| Action | Endpoint | Actor | Authorization Check | Description |
|---|---|---|---|---|
| `registerUser` | `POST /api/users` | Public / New User | `allowedRoles = ['CLIENT', 'DRAUGHTSMAN']` | Provisions user in D1 database; rejects privileged roles (400) |
| `getProfile` | `GET /api/users/me` | Any Authenticated | Self (`uid`) | Returns current user profile |
| `updateProfile` | `PATCH /api/users/me` | Any Authenticated | Self (`uid`) | Updates whitelisted profile fields; `role` is strictly immutable |

---

## 5. Storage & File Management API

| Category | Endpoint | Allowed Roles | Extensions Permitted |
|---|---|---|---|
| `client_upload` | `POST /api/projects/:id/files?category=client_upload` | Owning Client, Admin | `pdf, dwg, dxf, png, jpg, jpeg, zip` |
| `draughtsman_version`| `POST /api/projects/:id/files?category=draughtsman_version`| Assigned Draughtsman | `pdf, dwg, dxf, png, jpg, jpeg, zip` |
| `correction_attachment`| `POST /api/projects/:id/files?category=correction_attachment`| Owning Client, Admin | `pdf, dwg, dxf, png, jpg, jpeg, zip` |
| `message_attachment` | `POST /api/projects/:id/files?category=message_attachment`| Any Project Participant | `pdf, dwg, dxf, png, jpg, jpeg, zip, webm, m4a, mp3, wav, ogg, aac` |
| `download` | `GET /api/files/:fileId/download` | Authorized Project Participant (`canUserAccessProject`) | Returns R2 storage object with content-disposition |

