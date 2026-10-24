# Phase Master Verification — Defect Register

This register documents all defects, vulnerabilities, behavioral discrepancies, and technical gotchas identified, diagnosed, and resolved during the **Master Complete Verification and End-to-End Testing** of Archi Draft Studio.

---

## Defect Summary Table

| Defect ID | Severity | Component | Summary | Status | Resolution |
|-----------|----------|-----------|---------|--------|------------|
| **DEF-01** | **High** | Worker API (`worker/src/index.ts`) | Path traversal sequence in filename sanitization was not stripping leading relative directory segments (`../../`). | **RESOLVED** | Hardened basename extraction and leading dot stripping in `worker/src/index.ts`. |
| **DEF-02** | **Medium** | Database / API (`worker/src/index.ts`) | Foreign Key constraint violation during Stage 5 correction request when referencing raw file ID instead of drawing version ID. | **RESOLVED** | Bound correction target to verified `drawing_versions.id` foreign key. |
| **DEF-03** | **Medium** | Test Suite / Client (`scratch/run_master_complete_verification.mjs`) | Node.js `undici` HTTP client threw `RequestContentLengthMismatchError` on binary DWG stream upload. | **RESOLVED** | Supplied exact byte-length buffer `Buffer.from(...)` matching explicit `Content-Length` header. |
| **DEF-04** | **Low** | Test Runner / Integration | Admin assign response schema returned `{ success: true, assignmentId }`, but script expected direct ID string. | **RESOLVED** | Updated assignment extractor to unpack `assignmentId` from response body. |
| **DEF-05** | **Low** | Test Runner / API Client | User profile parsing checked nested `data.user.role` instead of top-level `data.role` on `/api/users/me`. | **RESOLVED** | Standardized response profile schema extraction to read `data.role`. |
| **DEF-06** | **Low** | Automation / Flutter Web | Headless Chrome did not dispatch keydown events for Enter key on Flutter web credentials inputs. | **RESOLVED** | Implemented explicit CDP `Input.dispatchKeyEvent` with scan codes and location URL polling. |

---

## Detailed Defect Entries

### DEF-01: Path Traversal Vulnerability in Worker Filename Sanitizer

- **Severity:** High (Security Vulnerability)
- **Component:** `worker/src/index.ts` (Lines 2124–2130)
- **Feature Area:** CAD & Attachment Uploads (Area G)
- **Reproduction Steps:**
  1. Authenticate as Draughtsman or Engineer.
  2. Send a `POST /api/files/upload` request with `fileName: "../../etc/passwd.dwg"`.
  3. Observe the generated object key and sanitized filename.
- **Expected Behavior:**
  Relative path separators (`/`, `\`) and traversal tokens (`..`) must be fully stripped, ensuring files are stored exclusively within their designated R2 object prefixes without escaping directory bounds.
- **Actual Behavior (Prior to Fix):**
  The original regex `fileName.replace(/[^a-zA-Z0-9.-]/g, '_')` converted slashes to underscores but preserved the periods, producing `.._.._etc_passwd.dwg`. While R2 does not execute files as a local filesystem, retaining leading directory traversal tokens poses security risks when generating download headers or syncing files to local disk.
- **Root Cause:**
  Filename sanitization did not isolate the file basename prior to character filtering and did not strip leading periods.
- **Resolution Applied:**
  Updated `worker/src/index.ts` to first extract the basename using path separator delimiters and then strip all leading dots:
  ```typescript
  const baseName = fileName.split(/[/\\]/).pop() || fileName;
  const sanitizedName = baseName.replace(/[^a-zA-Z0-9.-]/g, '_').replace(/^\.+/, '');
  ```
- **Verification & Regression Test:**
  Tested with `../../etc/passwd.dwg`. The resulting filename was authoritatively sanitized to `passwd.dwg`. Verified across all 267 worker unit/integration tests with zero regressions.

---

### DEF-02: Foreign Key Constraint on Stage 5 Correction Request

- **Severity:** Medium
- **Component:** Worker D1 Schema / Correction Handler (`worker/src/index.ts`)
- **Feature Area:** Project Lifecycle Stage 5 (Area H)
- **Reproduction Steps:**
  1. Complete Stages 1 through 4 of project lifecycle.
  2. Engineer initiates `POST /api/projects/:id/request-correction` passing `drawing_version_id: file_id` (e.g. `v1-dwg-1792819951005`).
  3. D1 returns SQLite foreign key constraint violation.
- **Expected Behavior:**
  The correction record must successfully bind to the architectural drawing version submitted in Stage 4.
- **Actual Behavior (Prior to Fix):**
  Request failed because `corrections.drawing_version_id` strictly enforces a foreign key reference to `drawing_versions.id` (an internal integer or UUID primary key in D1), rather than the R2 storage `file_id`.
- **Root Cause:**
  The test script passed the storage `file_id` directly rather than querying the newly inserted `drawing_versions` record for its table primary key.
- **Resolution Applied:**
  Updated the lifecycle coordinator in `scratch/run_master_complete_verification.mjs` to fetch `GET /api/projects/:id/versions` (or query D1 `drawing_versions` directly) and bind `versions[0].id` to the `request-correction` payload.
- **Verification & Regression Test:**
  Stage 5 executed cleanly; D1 recorded `corrections` row with `round_number: 1`, `status: 'RESOLVED'`, and valid foreign key reference.

---

### DEF-03: Binary Upload Content-Length Header Mismatch in Node.js Client

- **Severity:** Medium
- **Component:** Test Automation Script (`scratch/run_master_complete_verification.mjs`)
- **Feature Area:** Native CAD DWG Upload (Area G)
- **Reproduction Steps:**
  1. Construct a dummy binary DWG payload via string interpolation.
  2. Call Node.js `fetch('http://127.0.0.1:8787/api/files/upload', { ... })` with an explicit `Content-Length` header calculated from string length.
  3. Node.js `undici` engine throws `RequestContentLengthMismatchError`.
- **Expected Behavior:**
  Binary CAD files should stream cleanly to the Worker endpoint with accurate byte counts.
- **Actual Behavior (Prior to Fix):**
  Character count diverged from multi-byte binary representation, causing the HTTP client to abort the connection before transmission.
- **Root Cause:**
  Using string length instead of `Buffer.byteLength` or typed `Buffer.from(...)` when generating synthetic AutoCAD DWG/DXF test headers.
- **Resolution Applied:**
  Converted all binary CAD test payloads into explicit `Buffer` objects and computed `Content-Length` strictly via `payloadBuffer.length`.
- **Verification & Regression Test:**
  Both Version 1 DWG, Version 2 DWG, and DXF uploads completed with HTTP 200 and persisted into Cloudflare R2 staging buckets.

---

### DEF-04: Admin Assignment ID Return Shape Mismatch

- **Severity:** Low
- **Component:** Test Automation Script (`scratch/run_master_complete_verification.mjs`)
- **Feature Area:** Project Lifecycle Stage 2 (Area H)
- **Reproduction Steps:**
  1. Studio Admin assigns draughtsman via `POST /api/projects/:id/assign`.
  2. Inspect response JSON structure.
- **Expected Behavior:**
  Assignment ID extracted cleanly for downstream Draughtsman acceptance in Stage 3.
- **Actual Behavior (Prior to Fix):**
  Assignment ID evaluated to `undefined` because script inspected `res.id` instead of `res.assignmentId`.
- **Root Cause:**
  Worker endpoint returns `{ success: true, assignmentId: "..." }`.
- **Resolution Applied:**
  Updated response unpacker to read `assignData.assignmentId`.
- **Verification & Regression Test:**
  Assignment ID `ad961f69-1b4f-413e-bed1-76fcbf15f92a` successfully captured and passed to Stage 3.

---

### DEF-05: User Profile Response Parsing Discrepancy

- **Severity:** Low
- **Component:** Test Automation Script (`scratch/run_master_complete_verification.mjs`)
- **Feature Area:** Authentication & Profile Loading (Area B)
- **Reproduction Steps:**
  1. Call `GET /api/users/me` with authenticated Bearer token.
  2. Verify returned profile role matches authenticated persona.
- **Expected Behavior:**
  Script verifies user role cleanly across all 4 personas (Studio Admin, Engineer, Draughtsman, Student).
- **Actual Behavior (Prior to Fix):**
  Script asserted `profileData.user.role`, which was `undefined`, causing premature test failure.
- **Root Cause:**
  The Worker endpoint serializes profile fields flatly onto the root object: `{ id, email, role, ... }` rather than nesting inside a `user` property.
- **Resolution Applied:**
  Updated assertions to check `profileData.role === expectedRole`.
- **Verification & Regression Test:**
  All 4 personas verified with 100% pass rate.

---

### DEF-06: Flutter Web Headless Authentication Keypress Dispatch

- **Severity:** Low
- **Component:** Test Automation Script (`scratch/run_master_complete_verification.mjs`)
- **Feature Area:** Student UI Automation (Area F)
- **Reproduction Steps:**
  1. Launch headless Chrome via Chrome DevTools Protocol (CDP).
  2. Navigate to `http://localhost:8080/#/login`.
  3. Enter student credentials into Flutter HTML/CanvasKit DOM elements.
- **Expected Behavior:**
  Form submits and navigates to `#/student/dashboard`.
- **Actual Behavior (Prior to Fix):**
  Standard HTML DOM form submission did not trigger Flutter's internal framework listeners, leaving the page in an un-submitted state.
- **Root Cause:**
  Flutter Web abstracts text inputs inside an invisible `<flt-glass-pane>` and listens for raw browser keyboard events (`keydown`/`keyup`) rather than HTML form `submit` events.
- **Resolution Applied:**
  Dispatched raw keyboard events via CDP `Input.dispatchKeyEvent` simulating Enter (Windows Virtual Key `0x0D`, code `Enter`) and polled window location hash until `#/student/dashboard` resolved.
- **Verification & Regression Test:**
  Successfully captured high-fidelity screenshot of the authenticated Student Studio Screen (`student/01_student_dashboard.png`).
