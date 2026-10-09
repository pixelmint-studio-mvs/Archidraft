# CORE WORKFLOW

This document defines the exact, unchangeable main workflow of an ARCHI DRAFT project. 

## The Linear Workflow

**CLIENT**
↓ Creates Project
**[ DRAFT ]**
↓ Submits Project
**[ SUBMITTED ]**

**ADMIN REVIEW**
↓ Approves Project
**[ WAITING_ASSIGNMENT ]**
↓ Assigns Draughtsman
**[ WAITING_ACCEPTANCE ]**

**DRAUGHTSMAN ACTION**
↓ Accepts Assignment
**[ IN_PROGRESS ]**
↓ Uploads Drawing & Submits
**[ UNDER_CLIENT_REVIEW ]**

## The Review Fork

Once `UNDER_CLIENT_REVIEW`, the Client has two options:

### Option A: Approval (Happy Path)
**CLIENT APPROVES** (`POST /api/projects/approve-final`)
↓ 
**[ COMPLETED ]**

*Authorization:* Strictly the owning **Client** or platform **Admin/Studio Admin**. Engineers and Draughtsmen are prohibited from approving final drawings (`403 Forbidden`).

### Option B: Corrections (Iterative Path)
**CLIENT REQUESTS CORRECTION** (`POST /api/projects/request-correction`)
↓ 
**Correction Status: [ OPEN ]**
↓ Draughtsman Begins Work
**Correction Status: [ IN_PROGRESS ]**
↓ Draughtsman Uploads Revision & Resolves (`POST /api/projects/resolve-correction`)
**Correction Status: [ RESOLVED ]**
↓ Draughtsman Submits Drawing Again (`POST /api/projects/submit-drawing`)
**Project Status: [ UNDER_CLIENT_REVIEW ]**

*(Note: The maximum number of correction rounds allowed per project is **3**. The backend will automatically reject a 4th request).*

*Authorization:* Strictly the owning **Client** or platform **Admin/Studio Admin**. Engineers and Draughtsmen are prohibited from initiating correction requests (`403 Forbidden`). Only the assigned Draughtsman may resolve corrections.

