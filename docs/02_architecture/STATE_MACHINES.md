# STATE MACHINES

This document defines the strict, locked state enums and transitions for Projects, Assignments, and Corrections.

---

## 1. PROJECT STATUS (`ProjectStatus`)

The backend enum values in Cloudflare D1 (`projects.status`) and Flutter are:
- `DRAFT`: Initial draft state editable by the Engineer.
- `SUBMITTED`: Formally submitted by the Engineer, awaiting Studio Admin review.
- `WAITING_ASSIGNMENT`: Approved by Studio Admin, awaiting draughtsman selection.
- `WAITING_ACCEPTANCE`: Assigned to a Draughtsman, awaiting acceptance.
- `IN_PROGRESS`: Actively being drafted by the assigned Draughtsman.
- `UNDER_CLIENT_REVIEW`: Drawing version submitted by Draughtsman, awaiting Engineer review.
- `COMPLETED`: Terminal state; drawing approved by Engineer.
- `CANCELLED`: Terminal state; rejected by Admin or cancelled by Engineer in draft.

### Valid Project Transitions

```text
[ DRAFT ]
    ├── submitProject() ────────► [ SUBMITTED ]
    └── cancelProject() ────────► [ CANCELLED ]

[ SUBMITTED ]
    ├── approveProject() ───────► [ WAITING_ASSIGNMENT ]
    └── rejectProject() ────────► [ CANCELLED ]

[ WAITING_ASSIGNMENT ]
    └── assignDraughtsman() ────► [ WAITING_ACCEPTANCE ]

[ WAITING_ACCEPTANCE ]
    ├── acceptAssignment() ─────► [ IN_PROGRESS ]
    └── rejectAssignment() ─────► [ WAITING_ASSIGNMENT ]

[ IN_PROGRESS ]
    └── submitDrawing() ────────► [ UNDER_CLIENT_REVIEW ]

[ UNDER_CLIENT_REVIEW ]
    ├── approveFinal() ─────────► [ COMPLETED ]
    └── requestCorrection() ────► [ IN_PROGRESS ] (correction_round += 1)
```

---

## 2. ASSIGNMENT STATUS (`AssignmentStatus`)

The state of a draughtsman allocation in `assignments.status`:
- `PENDING`: Draughtsman has been invited but has not accepted or rejected.
- `ACCEPTED`: Draughtsman accepted and is actively assigned.
- `REJECTED`: Draughtsman declined the assignment.
- `REPLACED`: Studio Admin reassigned the project to another drafter.
- `COMPLETED`: Project finalized while this drafter was assigned.

---

## 3. CORRECTION STATUS (`CorrectionStatus`)

The state of an Engineer-requested revision round in `corrections.status`:
- `OPEN`: Engineer requested a correction; notes and markup attached.
- `RESOLVED`: Draughtsman uploaded a revised drawing addressing the feedback.

> [!CAUTION]
> **Hard Limit:** Maximum correction rounds = 3. Any additional attempt returns HTTP 400.
