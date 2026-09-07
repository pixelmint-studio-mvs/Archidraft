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
**CLIENT APPROVES**
↓ 
**[ COMPLETED ]**

### Option B: Corrections (Iterative Path)
**CLIENT REQUESTS CORRECTION**
↓ 
**Correction Status: [ OPEN ]**
↓ Draughtsman Begins Work
**Correction Status: [ IN_PROGRESS ]**
↓ Draughtsman Uploads Revision & Resolves
**Correction Status: [ RESOLVED ]**
↓ Draughtsman Submits Drawing Again
**Project Status: [ UNDER_CLIENT_REVIEW ]**

*(Note: The maximum number of correction rounds allowed per project is **3**. The backend will automatically reject a 4th request).*
