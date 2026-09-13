# TESTING STRATEGY

To ensure platform reliability, ARCHI DRAFT follows a comprehensive testing strategy. A feature is not complete just because the UI works on a happy path.

## 1. Unit Testing
Test core logic in isolation:
- Data Models (JSON Serialization/Deserialization)
- Validation Logic
- State Transition Logic (Verifying correct enums)
- Utility Functions

## 2. Widget Testing
Test important UI behavior:
- Forms and Input Validation
- Buttons and Interactions
- Loading States (Spinners/Skeletons)
- Error States (Snackbars/Dialogs)

## 3. Integration Testing
Test complete user workflows from start to finish.
**Example Workflow:**
`Client Creates Project` → `Client Submits Project` → `Admin Approves Project` → `Admin Assigns Draughtsman` → `Draughtsman Accepts` → `Draughtsman Submits Drawing` → `Client Reviews` → `Client Approves` → `Project Completed`

## 4. NEGATIVE TESTING
This is extremely important. We must rigorously test failure states:
- **Unauthorized User:** Cannot perform actions.
- **Invalid Role:** A Client cannot approve a project.
- **Invalid Project State:** Cannot transition a `DRAFT` directly to `COMPLETED`.
- **Invalid State Transition:** Cannot `submitDrawing()` if not `IN_PROGRESS`.
- **Rejected Assignment:** Ensure the Draughtsman cannot act.
- **Replaced Draughtsman:** Ensure the replaced Draughtsman loses all access immediately.
- **Fourth Correction Attempt:** Ensure the 4th request is rejected by the backend.
- **Duplicate Request:** Ensure Cloudflare Worker Idempotency logic prevents double logging.
- **Network Retry:** Ensure duplicate actions are handled safely.
- **Unauthorized File Upload:** Client uploading to Draughtsman folders.
- **Unauthorized File Download:** Attempting to fetch files from unassigned projects.

## 5. SECURITY TESTING
Verify backend rule enforcement:
- Cloudflare Worker Authorization Logic
- Project Ownership Enforcement
- Assignment Authorization Checks
- Activity Log Immutability

## DEFINITION OF TEST COMPLETION
A feature is **Done** when it passes:
`Happy Path` + `Negative Cases` + `Authorization Cases` + `Error Cases`
