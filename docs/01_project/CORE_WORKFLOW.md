# CORE WORKFLOW

This document defines the official workflow and lifecycle states of an ARCHI DRAFT project.

---

## 1. The End-to-End Linear Workflow

```text
ENGINEER
  │
  ├─► Creates Project Draft (Metadata + Reference Blueprints)
  │   State: [ DRAFT ]
  │
  └─► Submits Project Brief (POST /api/projects/submit)
      State: [ SUBMITTED ]

STUDIO ADMIN
  │
  ├─► Approves Project for Allocation (POST /api/projects/approve)
  │   State: [ WAITING_ASSIGNMENT ]
  │
  └─► Dispatches Assignment to Draughtsman (POST /api/projects/assign)
      State: [ WAITING_ACCEPTANCE ]

DRAUGHTSMAN
  │
  ├─► Accepts Assignment (POST /api/assignments/accept)
  │   State: [ IN_PROGRESS ]
  │
  ├─► Technical Q&A via Collaboration Hub (Continuous during drafting)
  │
  └─► Uploads Drawing & Submits Version (POST /api/projects/submit-drawing)
      State: [ UNDER_CLIENT_REVIEW ]
```

---

## 2. The Review Fork

Once a project reaches `UNDER_CLIENT_REVIEW`, the Engineer evaluates the submitted drawing version:

### Option A: Approval (Happy Path)
```text
ENGINEER APPROVES FINAL DRAWING (POST /api/projects/approve-final)
  │
  ▼
State: [ COMPLETED ]
(Project is permanently locked in terminal state)
```

### Option B: Corrections (Iterative Revision Path)
```text
ENGINEER REQUESTS CORRECTION (POST /api/projects/request-correction)
  │
  ▼
Correction Status: [ OPEN ]
Project Status:    [ IN_PROGRESS ] (correction_round incremented)
  │
  ├─► Draughtsman Reviews Notes & Prepares Drawing Revision
  │
  ├─► Draughtsman Uploads Revised Drawing & Resolves Correction
  │   Correction Status: [ RESOLVED ]
  │
  └─► Draughtsman Submits Revision for Review (POST /api/projects/submit-drawing)
      Project Status:    [ UNDER_CLIENT_REVIEW ]
```

> [!IMPORTANT]
> **Strict Correction Limit:** A project allows a maximum of **3 correction rounds**. If an Engineer attempts to request a 4th correction, the Cloudflare Worker rejects the request with HTTP 400 (`Maximum correction rounds (3) exceeded`).

---

## 3. Collaboration Hub Integration
Throughout the `IN_PROGRESS` and `UNDER_CLIENT_REVIEW` states, the Engineer and Draughtsman utilize the **Collaboration Hub**:
- Continuous project-scoped messaging.
- Technical clarification queries.
- Sharing file attachments (blueprints, markups, site photos).
- Sending automated `CHAT_MESSAGE` push/in-app notifications to the counterpart.
