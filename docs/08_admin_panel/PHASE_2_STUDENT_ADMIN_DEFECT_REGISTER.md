# Phase 2 — Student Portal and Admin Evaluation Workflow: Defect Register

**Document Version:** 1.0.0  
**Audit Date:** October 24, 2026  
**Integration Branch:** `COMPLETED-INTERGRATION`  
**Workspace:** `scratch/completed-integration`  
**Reference Specification:** Student Portal Flowchart (Interactions with Admin)  

---

## 1. Summary of Identified Defects & Implementation Gaps

| Defect ID | Severity | Flowchart Node | Portal / Component | Classification | Current Status |
| :--- | :---: | :--- | :--- | :--- | :---: |
| **DEF-P2-01** | **Medium** | Admin Evaluates Drawing & Submits Decision | Admin Web (`apps/admin-web/`) | `NOT_IMPLEMENTED_IN_UI` | **OPEN (Requires UI Form)** |
| **DEF-P2-02** | **Low** | Admin Views Submissions Queue | Admin Web (`apps/admin-web/`) | `NOT_IMPLEMENTED_IN_UI` | **OPEN (Requires UI View)** |
| **DEF-P2-03** | **Low** | Student Rejected State & Closure | Worker API & Flutter UI | `SPECIFICATION_AMBIGUITY` | **DOCUMENTED (Working as Implemented)** |
| **DEF-P2-04** | **Medium** | Student Initial Sign-In & Dashboard | Flutter Web & Legal Gate | `CONFIGURATION_GATE` | **WORKAROUND_VERIFIED** |

---

## 2. Itemized Defect Details

### DEF-P2-01: Admin Web Lacks Interactive Rubric Evaluation Modal / Form

- **Flowchart Node:** "Admin Evaluates Drawing" → Decisions: "Approve" / "Request Revision" / "Reject"
- **Affected Area:** Admin Web UI (`apps/admin-web/src/app/projects/[projectId]/page.tsx` & `/students/[id]/page.tsx`)
- **Severity:** Medium
- **Symptom:** The Next.js Admin portal does not display an interactive modal or form allowing an administrator to enter the rubric criteria (Accuracy: 1–5, Technical Standards: 1–5), select an outcome (`APPROVED`, `NEEDS_CORRECTION`, `REJECTED`), and enter general feedback calling `POST /api/projects/evaluate`.
- **Authoritative Root Cause:** While the Cloudflare Worker API (`POST /api/projects/evaluate`) is 100% implemented, and the Flutter Student UI renders the resulting `EvaluationCard` with Accuracy and Technical Standards scores and quotes, the corresponding frontend UI form was not constructed in `apps/admin-web`.
- **Current Mitigation:** Evaluation decisions are submitted via authenticated administrative API calls, and their downstream consequences in D1, R2, and Flutter UI are fully functional and verified.
- **Recommended Remediation:** Add an "Evaluate Student Submission" button and modal dialog in `apps/admin-web/src/app/projects/[projectId]/page.tsx` when `project.is_training_project === 1 && project.status === 'UNDER_ENGINEER_REVIEW'`.

---

### DEF-P2-02: Missing Dedicated Admin Student Submissions Review Queue

- **Flowchart Node:** "Student Submits Drawing" → "Submission Appears in Admin Submissions Queue"
- **Affected Area:** Admin Web UI (`apps/admin-web/`)
- **Severity:** Low
- **Symptom:** Admin Web UI has `/students` (student directory) and `/students/[id]` (student dossier), but lacks a dedicated `/admin/student-submissions` page listing all pending practical project submissions across all enrolled students.
- **Authoritative Root Cause:** The backend Worker API endpoint `GET /api/admin/student-submissions` is implemented and verified, returning submissions awaiting review, but `apps/admin-web` has not mapped a dedicated page route to this endpoint.
- **Current Mitigation:** Administrators can view student submissions by navigating to `/students/[id]` or `/projects/[projectId]`.
- **Recommended Remediation:** Add a "Student Submissions" tab or subview under `/students` in Admin Web that consumes `GET /api/admin/student-submissions`.

---

### DEF-P2-03: Post-Rejection Resubmission Permissibility vs Flowchart Terminal Expectation

- **Flowchart Node:** "Reject Decision" → "Reassignment / Closure Process"
- **Affected Area:** Cloudflare Worker API (`worker/src/index.ts`) & Flutter Student Workspace (`student_project_workspace_screen.dart`)
- **Severity:** Low (Business Logic Behavior)
- **Symptom:** When an Admin rejects a student drawing (`overallResult: 'REJECTED'`), the project enters `CANCELLED` status and displays the rejection banner. However, the student workspace still provides an active upload section titled `"YOUR REVISED DRAFT (POST-REJECTION)"`, and `POST /api/projects/submit-drawing` allows resubmission from `CANCELLED` status (line 850 in `worker/src/index.ts`).
- **Authoritative Root Cause:** In commercial architectural projects, rejection is terminal or triggers draughtsman reassignment. In the student training context, the authors intentionally permitted educational resubmission after rejection (`isFirstAttempt || isRevisionRequired || isRejected`).
- **Status:** **DOCUMENTED**. The system behaves consistently across both Flutter frontend and Worker backend. Product owner sign-off is required to confirm whether educational practical assignments should permit post-rejection revised resubmission or enforce terminal closure.

---

### DEF-P2-04: Student Initial Sign-In Redirects to Legal Onboarding When Unseeded

- **Flowchart Node:** "Student Logs In" → "Student Dashboard"
- **Affected Area:** Flutter Web Client (`lib/src/core/router/app_router.dart`)
- **Severity:** Medium
- **Symptom:** When a student logs into Flutter Web on a staging environment where no effective legal terms document is published in D1, the client router intercepts the session and redirects to `#/legal/onboarding` (HTTP 503 `TERMS_MAINTENANCE_MODE`).
- **Authoritative Root Cause:** The platform's security and legal compliance architecture enforces affirmative consent before granting application access. In staging, `legal_documents` contains zero effective records.
- **Current Mitigation:** The staging test harness safely exercises the staging test seam (`X-Staging-Test-Mode: workflow-e2e` for authorized test UIDs), and router redirection to `#/student/dashboard` was verified.
- **Recommended Remediation:** Before staging user acceptance testing and production launch, an administrator must formally publish an `EFFECTIVE` Terms and Conditions document via the Admin Legal Panel (`/settings` or `/legal`).

---

## 3. Regression Test Verification Matrix

| Defect ID | Description | Automated Regression Test | Verification Status |
| :--- | :--- | :--- | :---: |
| **DEF-P2-01** | Evaluation API Endpoint Security & Schema | `test/evaluations.test.mjs` & Phase 2 Runner | **PASS (Backend Validated)** |
| **DEF-P2-02** | Student Submissions Directory Query | `test/student_submissions.test.mjs` & Phase 2 Runner | **PASS (Backend Validated)** |
| **DEF-P2-03** | Resubmission State Machine Enforcement | Phase 2 Test Group 7 (`TG7-3`) | **PASS (Working as Designed)** |
| **DEF-P2-04** | Staging Legal Gate Exemption Seam | `phase_d10_staging_legal_gate.test.mjs` | **PASS (8/8 Tests Green)** |
