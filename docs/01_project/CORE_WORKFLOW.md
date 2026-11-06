# CORE WORKFLOW

This document defines the verified main workflow of an ARCHI DRAFT commercial drafting project.

## The Linear Workflow

**ENGINEER / CLIENT**
↓ Creates Project Brief
**[ DRAFT ]**
↓ Submits Project
**[ SUBMITTED ]**

**STUDIO ADMIN REVIEW**
↓ Approves Project Brief
**[ WAITING_ASSIGNMENT ]**
↓ Assigns Draughtsman
**[ WAITING_ACCEPTANCE ]**

**DRAUGHTSMAN ACTION**
↓ Accepts Assignment
**[ IN_PROGRESS ]**
↓ Uploads CAD Deliverable & Submits (`POST /api/projects/submit-drawing`)
**[ WAITING_FOR_STUDIO_REVIEW ]**

**STUDIO ADMIN QUALITY CONTROL (QC) GATE**
Studio Admin inspects the deliverable prior to Engineer release:
- **QC Approved** (`POST /api/admin/drawing-approvals/approve`):
  Deliverable released to client.
  ↓
  **[ UNDER_ENGINEER_REVIEW ]** (or `UNDER_CLIENT_REVIEW`)
- **QC Revision Requested** (`POST /api/admin/drawing-approvals/request-revision`):
  Returned to draughtsman for internal rework with feedback.
  ↓
  **[ IN_PROGRESS ]** *(Note: QC rework does NOT consume or increment client revision rounds).*

---

## The Client Review Fork

Once in **[ UNDER_ENGINEER_REVIEW ]** (or `UNDER_CLIENT_REVIEW`), the Client/Engineer has two actions:

### Option A: Approval (Happy Path)
**CLIENT / ENGINEER APPROVES** (`POST /api/projects/approve-final`)
↓ 
**[ COMPLETED ]**

*Authorization:* Strictly the owning **Client / Engineer** or platform **Studio Admin**. Draughtsmen are prohibited from approving final deliverables (`403 Forbidden`). All active corrections are marked `RESOLVED`.

### Option B: Corrections (Iterative Path)
**CLIENT / ENGINEER REQUESTS CORRECTION** (`POST /api/projects/request-correction`)
↓ 
**Correction Status: [ OPEN ]** (Correction round increments: 1, 2, 3, 4, ... indefinitely)
↓ Draughtsman Begins Work
**Correction Status: [ IN_PROGRESS ]**
↓ Draughtsman Uploads Revision & Submits (`POST /api/projects/submit-drawing`)
**[ WAITING_FOR_STUDIO_REVIEW ]** (Quality gate re-applies)
↓ Studio Admin QC Approves
**[ UNDER_ENGINEER_REVIEW ]**

*(Note: Unlimited revision rounds are supported. The correction round increments accurately with every Client/Engineer correction request until final satisfaction and approval).*

*Authorization:* Owning **Client**, **Engineer**, or platform **Studio Admin**. Only the assigned Draughtsman may submit corrected deliverables.
