# SYSTEM ARCHITECTURE

## CLIENT APPLICATION
- **Flutter Application:** Handles UI, user interaction, authentication state, authorized reads, and simple operations.

## BACKEND
Use a **hybrid architecture** combining direct D1 metadata operations via the Cloudflare Worker API.

### 1. Operations
*(Flutter → Cloudflare Worker API → D1 / R2)*
All state changes and file storage operations are mediated by the Worker API.

### 2. Critical Operations
*(Flutter → Cloudflare Worker API)*
Critical actions must validate:
- Authentication (`context.auth`)
- User role
- Project Ownership / Assignment
- Current project state
- Allowed transitions

## CRITICAL ACTIONS
The following actions must NOT be implemented as uncontrolled client-side state changes. They must be executed via Callable Cloud Functions running Transactions:

- `submitProject()`
- `approveProject()`
- `rejectProject()`
- `assignDraughtsman()`
- `acceptAssignment()`
- `rejectAssignment()`
- `requestCorrection()`
- `resolveCorrection()`
- `submitDrawing()`
- `approveFinal()`
- `cancelProject()`
- `assignStudentTrainingProject()`
- `updateStudentProgress()`

## STUDENT AUTHORIZATION MODEL
Flutter controls presentation; the Worker controls authorization.

The Worker MUST derive the authenticated user and role from the verified Firebase token. The backend must **never trust** `studentId`, `role`, `project ownership`, or `assignment ownership` sent from the Flutter client.

Student endpoints must explicitly verify:
1. Authenticated user validity
2. The user has the `STUDENT` role in the database/token
3. Resource ownership/assignment (e.g., student can only read their own progress and assignments)

## REAL PROJECT PRIVACY & SANITIZATION (CRITICAL)
While Student Training may include "Real Projects," active Client projects must never be exposed directly. The architecture strictly distinguishes:

1. **ACTIVE CLIENT PROJECT:** Live drafting project. Private to Client, Draughtsman, and Admin.
2. **SANITIZED TRAINING PROJECT:** A cloned project stripped of Client personal information, private contact details, confidential project documents, unrelated project files, internal Admin information, and private Draughtsman information.
3. **MOCK TRAINING PROJECT:** A completely artificial project created for training.

**Privacy Boundary Workflow:**
`ACTIVE CLIENT PROJECT -> SANITIZATION / APPROVAL -> SANITIZED TRAINING PROJECT -> STUDENT`

Any exposure of a sanitized real project requires explicit Client consent. This must be an authorization requirement managed by the Admin.

## TRAINING CONTENT OWNERSHIP
The existing **ADMIN** role holds the responsibility for:
- Creating/Managing training categories, modules, descriptions, and prerequisites.
- Managing training content and project templates.
- Assigning training projects to students.
- Monitoring student progress.
