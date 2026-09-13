# BACKEND ACTIONS

This table documents the contract for all critical backend actions. Critical actions are executed via the Cloudflare Worker API.

| Action | Actor | Preconditions (State Validation) | Database Changes | Activity Logging | Idempotency Requirement |
|---|---|---|---|---|---|
| `createProject` | Client | Role=CLIENT | Create Project Doc in `DRAFT` | (Client-side initially) | N/A |
| `updateDraft` | Client | Owner, Project=DRAFT | Update Whitelisted Fields | (Client-side initially) | N/A |
| `submitProject` | Client | Owner, Project=DRAFT | Update status to SUBMITTED, set `submittedAt` | PROJECT_SUBMITTED | Yes (actionId) |
| `approveProject` | Admin | Role=ADMIN, Project=SUBMITTED | Update status to WAITING_ASSIGNMENT | PROJECT_APPROVED | Yes (actionId) |
| `rejectProject` | Admin | Role=ADMIN, Project=SUBMITTED | Update status to CANCELLED, set `rejectReason` | PROJECT_REJECTED | Yes (actionId) |
| `assignDraughtsman`| Admin | Role=ADMIN, Project in WAITING | Create Assignment, Update Project pointers | DRAUGHTSMAN_ASSIGNED | Yes (actionId) |
| `acceptAssignment` | Drght. | Assgn. Status=PENDING, matches Project| Update Assignment to ACCEPTED, Update Project | ASSIGNMENT_ACCEPTED | Yes (actionId) |
| `rejectAssignment` | Drght. | Assgn. Status=PENDING, matches Project| Update Assignment to REJECTED, Update Project | ASSIGNMENT_REJECTED | Yes (actionId) |
| `uploadVersion` | Drght. | Assigned Drght., Project=IN_PROGRESS | Create Version Doc | VERSION_UPLOADED | Yes (actionId) |
| `submitDrawing` | Drght. | Assigned Drght., Project=IN_PROGRESS | Update Project status to UNDER_CLIENT_REVIEW | DRAWING_SUBMITTED | Yes (actionId) |
| `requestCorrection`| Client | Owner, Project=UNDER_REVIEW, round < 3| Create Correction (OPEN), Increment round, Update Proj | CORRECTION_REQUESTED | Yes (actionId) |
| `resolveCorrection`| Drght. | Assigned Drght., Correction=IN_PROGRESS| Update Correction status to RESOLVED | CORRECTION_RESOLVED | Yes (actionId) |
| `approveFinal` | Client | Owner, Project=UNDER_REVIEW | Update Project status to COMPLETED, set `completedAt` | PROJECT_COMPLETED | Yes (actionId) |
| `cancelProject` | Client | Owner, Project in DRAFT/SUBMITTED | Update Project status to CANCELLED | PROJECT_CANCELLED | Yes (actionId) |

*(Note: Idempotency is achieved by hashing the `projectId`, `actionType`, and client-provided `actionId` to prevent duplicate log creation during network retries).*
