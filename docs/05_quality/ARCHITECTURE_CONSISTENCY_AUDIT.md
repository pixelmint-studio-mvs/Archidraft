# ARCHITECTURE CONSISTENCY AUDIT

## Issue 1: Project Status Naming Conflict
- **Affected Documents:** `STATE_MACHINES.md`, `BACKEND_ACTIONS.md`
- **Current Information:** Previous documents used `UNDER_REVIEW` loosely, but the official enum is `UNDER_CLIENT_REVIEW`.
- **Conflict:** Using both interchangeably will cause state machine failures in Dart.
- **Resolution:** All documentation has been updated to strictly use the official enum `UNDER_CLIENT_REVIEW`.
- **Team Decision Required:** No (✅ VERIFIED CONSISTENT).

## Issue 2: Assignment Statuses (`COMPLETED`)
- **Affected Documents:** `STATE_MACHINES.md`
- **Current Information:** The `COMPLETED` assignment status is documented.
- **Ambiguity:** Does `COMPLETED` apply to the project or the assignment?
- **Resolution:** Clarified in `STATE_MACHINES.md` that a Draughtsman's assignment status becomes `COMPLETED` when the overarching project is finalized while they are actively assigned.
- **Team Decision Required:** No (✅ VERIFIED CONSISTENT).

## Issue 3: Correction Workflow Transitions
- **Affected Documents:** `CORE_WORKFLOW.md`, `STATE_MACHINES.md`
- **Current Information:** Correction `RESOLVED` requires returning the project to `UNDER_CLIENT_REVIEW`.
- **Resolution:** It is confirmed that when a Draughtsman submits the revised drawing, the Correction becomes `RESOLVED`, and the Project Status transitions back to `UNDER_CLIENT_REVIEW`.
- **Team Decision Required:** No (✅ VERIFIED CONSISTENT).

## Issue 4: `startWork()` Action
- **Affected Documents:** `BACKEND_ACTIONS.md`, `STATE_MACHINES.md`
- **Current Information:** Used to transition a Correction from `OPEN` to `IN_PROGRESS`.
- **Ambiguity:** Is it redundant if the Draughtsman just uploads a file?
- **Resolution:** It is NOT redundant. It explicitly signals to the Client that the Draughtsman has acknowledged the correction and started working, updating the Correction state to `IN_PROGRESS` and keeping the Project state as `IN_PROGRESS`.
- **Team Decision Required:** No (✅ VERIFIED CONSISTENT).

## Issue 5: `uploadVersion()` Action
- **Affected Documents:** `BACKEND_ACTIONS.md`, `SYSTEM_ARCHITECTURE.md`
- **Current Information:** Is this a Client SDK write or a Backend Action?
- **Conflict:** Allowing direct Client SDK writes for versions bypasses activity logging.
- **Resolution:** It is a Critical Backend Action (Callable Function). The Client app uploads the physical file to Storage (validated by Storage Rules), then calls `uploadVersion()` to create the database metadata and generate the `VERSION_UPLOADED` activity log securely.
- **Team Decision Required:** No (✅ VERIFIED CONSISTENT).

## Issue 6: Correction Counter Increment Timing
- **Affected Documents:** `BACKEND_ACTIONS.md`
- **Current Information:** Maximum corrections = 3.
- **Resolution:** The counter increments inside the `requestCorrection()` Callable Function Transaction before creating the new Correction sub-document. If the counter is already 3, the transaction fails.
- **Team Decision Required:** No (✅ VERIFIED CONSISTENT).

## Issue 7: Final Drawing Workflow
- **Affected Documents:** `CORE_WORKFLOW.md`
- **Resolution:** Draughtsman uploads version → Submits drawing → Status becomes `UNDER_CLIENT_REVIEW` → Client Approves → Status becomes `COMPLETED`. 
- **Team Decision Required:** No (✅ VERIFIED CONSISTENT).

## Issue 8: Cancel Project Allowed States
- **Affected Documents:** `STATE_MACHINES.md`, `BACKEND_ACTIONS.md`
- **Current Information:** Allowed in DRAFT and SUBMITTED.
- **Resolution:** `cancelProject()` precondition strictly limits this to `DRAFT` and `SUBMITTED`. Once assigned to an Admin or Draughtsman (`WAITING_ASSIGNMENT` or later), the Client cannot unilaterally cancel it without Admin intervention.
- **Team Decision Required:** No (✅ VERIFIED CONSISTENT).

## Issue 9: Replaced Draughtsman Access
- **Affected Documents:** `USER_ROLES.md`, `STATE_MACHINES.md`
- **Current Information:** Old draughtsman loses access.
- **Resolution:** Security rules dynamically check `project.currentAssignmentId` and `project.assignedDraughtsmanId`. When an Admin assigns a new Draughtsman, these pointers update, instantly revoking Firestore and Storage read/write access for the replaced Draughtsman.
- **Team Decision Required:** No (✅ VERIFIED CONSISTENT).
