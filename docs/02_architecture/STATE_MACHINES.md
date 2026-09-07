# STATE MACHINES

This document defines the strict, unchangeable state enums and transitions for Projects, Assignments, and Corrections.

## PROJECT STATUS
The exact backend enum values are:
- `DRAFT`
- `SUBMITTED`
- `WAITING_ASSIGNMENT`
- `WAITING_ACCEPTANCE`
- `IN_PROGRESS`
- `UNDER_CLIENT_REVIEW`
- `COMPLETED`
- `CANCELLED`

*(Note: These names must not be changed without explicit approval).*

### PROJECT TRANSITIONS
```text
DRAFT
 ├── submitProject()
 │       ↓
 │    SUBMITTED
 │
 └── cancelProject()
         ↓
      CANCELLED

SUBMITTED
 ├── approveProject()
 │       ↓
 │ WAITING_ASSIGNMENT
 │
 └── rejectProject()
         ↓
      CANCELLED

WAITING_ASSIGNMENT
 ↓ assignDraughtsman()
WAITING_ACCEPTANCE

WAITING_ACCEPTANCE
 ├── acceptAssignment()
 │       ↓
 │   IN_PROGRESS
 │
 └── rejectAssignment()
         ↓
 WAITING_ASSIGNMENT

IN_PROGRESS
 ↓ submitDrawing()
UNDER_CLIENT_REVIEW

UNDER_CLIENT_REVIEW
 ├── approveFinal()
 │       ↓
 │   COMPLETED
 │
 └── requestCorrection()
         ↓
   Correction Workflow
```
*Invalid transitions (e.g., `DRAFT` directly to `COMPLETED`) must be rejected by backend rules.*

## ASSIGNMENT STATUS
The approved assignment statuses are:
- `PENDING`: Draughtsman has been invited but hasn't responded.
- `ACCEPTED`: Draughtsman is actively working.
- `REJECTED`: Draughtsman declined the work.
- `REPLACED`: Admin manually removed the Draughtsman and assigned another.
- `COMPLETED`: The project finished while this Draughtsman was assigned.

**Important:** If a Draughtsman is `REPLACED`, the system must immediately remove their project read/write access.

## CORRECTION STATUS
- `OPEN`: Client requested a correction.
- `IN_PROGRESS`: Draughtsman is actively working on the correction.
- `RESOLVED`: Draughtsman completed the correction and re-uploaded drawings.

**Maximum corrections:** 3
