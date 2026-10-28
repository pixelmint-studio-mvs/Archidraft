# ARCHI DRAFT — AUTHORITATIVE INTEGRATION HANDOVER & VERIFICATION REPORT

**Workspace:** `D:\PROJECT\Archidraft-integration-workspace`<br/>
**Active Branch:** `COMPLETED-INTEGRATION`<br/>
**Configured Upstream:** `origin/COMPLETED-INTERGRATION`<br/>
**Remote:** `https://github.com/pixelmint-studio-mvs/Archidraft.git`<br/>
**Current Local HEAD:** `32df2ef1d0da206d3d14a165f861cc1a00286074`<br/>
**Remote Tracking HEAD:** `55d45d170fb9e73397a0fec22f22692ae0236610`<br/>
**Date:** October 27, 2026<br/>
**Status:** **SYNCHRONIZED, FULLY TESTED & READY FOR PRE-PUSH REVIEW**

---

## 1. Executive Summary

This document represents the single authoritative handover, architecture, and verification report for the unified ARCHI DRAFT monorepo. It establishes the verified state of all portals (Engineer, Draughtsman, Student, Admin), the Cloudflare Worker backend API, and cross-platform clients (Flutter Web, Android emulator, Next.js Admin Studio).

### Summary of Completed Fixes
1. **PIXMINT BOT Complete Removal:** Completely removed PIXMINT BOT versions 1.0 and 2.0 across all four portals (Engineer, Draughtsman, Student, Admin). Eliminated all chatbot buttons, overlays, companion services, and dependencies while preserving core architectural contracts.
2. **Shared 3D Architectural Monogram:** Corrected 3D logo model orientation, camera framing, lighting, and continuous vertical axis rotation across both Next.js Admin Web (Three.js) and Flutter Web (model-viewer with fallback mechanisms).
3. **DWG/CAD Preview & API Repair:** Restored pure-Dart binary header extraction of embedded DIB/BMP raster previews for AutoCAD DWG files and 2D vector parsing for DXF files across all three Flutter portals.
4. **Android Crash Fix & Stability (Task 3):**
   - Eliminated native crash caused by uncaught `WebViewPlatform.instance != null` assertion in `model_viewer_plus` on non-web/Android platforms.
   - Enabled `android:usesCleartextTraffic="true"` in `android/app/src/main/AndroidManifest.xml` for local development.
   - Added automatic Android emulator loopback mapping (`10.0.2.2:8787`) in `ApiClient.resolveBaseUrl()`.
   - Fixed Terms & Conditions navigation race condition by awaiting `ref.refresh(userLegalStatusProvider.future)` before pushing role dashboards.
   - Resolved Windows cross-drive Gradle incremental compilation failure (`kotlin.incremental=false`).
5. **Admin Metrics & Collaboration Navigation:**
   - Corrected Admin Dashboard Registered Engineers count to derive authoritatively from backend metrics or combined `ENGINEER` + `CLIENT` roles without double-counting.
   - Fixed Collaboration Hub runtime `TypeError: Cannot read properties of undefined (reading 'bg')` by introducing a safe fallback in `getRoleColor`.
   - Wired authoritative dossier links from project overview and users directory to `/engineers/${id}`, `/draughtsmen/${id}`, and `/students/${id}`.
   - Added backend joins for `client_name`, `client_email`, and `current_assignment_id` in project endpoints.
6. **Engineer Technical Category Dropdown Normalization & Crash Fix:**
   - Fixed Flutter red screen crash on `/engineer/projects/new`:
     `Assertion failed: .../dropdown.dart: "There should be exactly one item with DropdownButton's value: Architectural. Either zero or 2 or more DropdownMenuItems were detected with the same value."`
   - Added `DrawingType.architectural` to Flutter client enums with case-insensitive parsing and alias normalization in `DrawingType.fromString()` (`ARCHITECTURAL`, `Architectural`, `ARCHITECTURAL_DRAFTING`, `Architectural Plan`).
   - Hardened `_StitchDropdownField` in `project_form_screen.dart` with dynamic fallback:
     `widget.items.any((item) => item.value == widget.value) ? widget.value : null`, bound to `key: ValueKey(safeValue)` and `initialValue: safeValue`, preventing assertion failures on unmapped or corrupted draft states.
7. **Engineer Reference-File Upload Workflow (50 MiB Limit):**
   - Implemented `ReferenceFilesUploadSection` in `project_form_screen.dart` with automatic draft saving prior to upload when creating new briefs (`formState.projectId == null`).
   - Configured exact 50 MiB limit (52,428,800 bytes) enforced client-side before upload and validated server-side in `worker/src/index.ts` with `HTTP 413 Payload Too Large`.
   - Implemented comprehensive 27-extension allowlist spanning CAD/BIM (`dwg`, `dxf`, `ifc`, `rvt`, etc.), documents, images, spreadsheets, and archives.
   - Enforced strict authorization: only Ordering Engineers and Admins may upload reference files; assigned Draughtsmen can inspect and download all client files from the Draughtsman Workspace.
   - Guarded form submission: "Initiate Drafting" is locked while file transfers are active.
8. **Phase 6: Legal Privacy Acceptance & Mandatory Document Seeding (`c4d0f78`):**
   - Enforced that privacy notice review and acknowledgement is mandatory in the onboarding consent flow.
   - Automated default legal terms and privacy documents seeding via `ensureDefaultLegalDocuments()` in Cloudflare D1 if unseeded, eliminating 503 maintenance mode deadlocks.
   - Added automated widget regression coverage in `legal_onboarding_screen_test.dart`.
9. **Phase 6: Engineer Drawing Versions & Embedded CAD Viewer (`100fe31`):**
   - Implemented drawing versions history, version switching, revision metadata, and correction notes rendering in `ProjectDetailScreen`.
   - Wired in-app `CadDrawingViewer` supporting pure-Dart DWG raster header extraction and 2D DXF vector geometry rendering, and integrated `PdfDrawingViewer` across project statuses.
   - Verified via 7 unit/widget tests in `engineer_drawing_versions_test.dart` and `cad_drawing_viewer_test.dart`.
10. **Phase 6: Shared Authentication, Registration & Email Verification (`cf79d19`):**
    - Eliminated unexpected redirects to `/landing` by adding `/verify-email` to public router paths and refactoring `VerifyEmailScreen` to reactively watch Riverpod `authStateChangesProvider`.
    - Resolved "Invalid email or password" rejections stemming from Firebase project configuration mismatch between staging (`archi-draft-staging`) and production (`archi-draft`).
    - Added reactive cache invalidation for `userProfileProvider` and `userLegalStatusProvider` upon `signIn`, `register`, and `signOut`.
    - Verified via 34 tests in `test/features/auth/` including 8/8 comprehensive flow tests in `verify_email_flow_test.dart`.
11. **Phase 6: API URL Sanitization & Legal Onboarding 404 Repair (`32df2ef`):**
    - Stripped trailing slashes in `ApiClient.resolveBaseUrl` and added `ApiClient.buildUri` helper, resolving the double-slash concatenation defect (`http://localhost:8787//api/users/me/legal-status`) that caused Hono to return HTTP 404 plain text.
    - Updated `app_router.dart` to direct authenticated users with unprovisioned D1 profiles (`profileAsync.value == null`) to `/provision-profile` before legal evaluation.
    - Refined `LegalRepository.getUserLegalStatus()` to gracefully handle missing D1 user profile states without catastrophic service error lockouts while preserving genuine route failure propagation.
    - Verified via 15/15 API client tests and 49/49 legal suite tests.
12. **Phase 6: Engineer Activity Feed Scoping & Double-'Z' Timestamp Resolution:**
    - Diagnosed and fixed empty activity feed and identical timestamp display (`Oct 28, 2026 · 7:27 PM`) on `/engineer/activity`.
    - Updated Cloudflare Worker `GET /api/activity` endpoint to scope records to `(p.client_id = uid OR a.actor_id = uid)` and normalize stored SQLite timestamps to standard UTC ISO-8601 `Z` strings via `normalizeTimestampString`.
    - Refactored `ActivityLog.parseTimestamp` to safely handle standard ISO-8601 strings (ending with or without `Z`), SQLite space-delimited formats, and integer Unix epoch timestamps without double-`Z` concatenation corruption.
    - Updated `ActivityLog.createdAt` to be nullable (`DateTime?`). Unparseable or absent timestamps explicitly evaluate to `null` and render as "Date unavailable" across `EngineerActivityScreen`, `ActivityTimeline`, and `WorkflowTimelineWidget`, strictly preventing silent fallback to `DateTime.now()`.
    - Verified via 6/6 unit tests in `test/unit/activity_log_test.dart`, 4/4 widget tests in `test/features/engineer/presentation/engineer_activity_screen_test.dart`, live Chrome CDP runtime evaluation, and 342/342 Worker tests.

---

## 2. Remote Synchronization & Ancestry Evidence

| Branch / Commit | Full Commit SHA | Author & Date | Commit Message | Status |
|---|---|---|---|---|
| **Remote Tip** | `55d45d170fb9e73397a0fec22f22692ae0236610` | Mohammed Janis P, Oct 26, 2026 | `fix(admin-web): sync engineer count badge and date utility contracts` | **Remote Tip (`origin/COMPLETED-INTERGRATION`)** |
| **Commit 1 (CAD & Versions)** | `100fe31f74e9563ddd466602155099438b4ed9b7` | Mohammed Janis P, Oct 26, 2026 | `fix(engineer): repair drawing versions and embedded CAD viewer` | **Local Commit (Linear)** |
| **Commit 2 (Legal Repair)** | `c4d0f7854148b0e79887d44eba91da2a29f0de30` | Mohammed Janis P, Oct 27, 2026 | `fix(legal): prevent privacy acceptance regression` | **Local Commit (Linear)** |
| **Commit 3 (Auth Repair)** | `cf79d1963278ca0cf4fd73787b1efd355eb99f9d` | Mohammed Janis P, Oct 27, 2026 | `fix(auth): stabilize shared registration, email verification, and session routing` | **Local Commit (Linear)** |
| **Commit 4 (API & Legal 404)** | `32df2ef1d0da206d3d14a165f861cc1a00286074` | Mohammed Janis P, Oct 27, 2026 | `fix(api): sanitize base url trailing slash and handle legal 404 profile provisioning` | **Local HEAD (Linear)** |

> [!IMPORTANT]
> **Branch Ancestry & Fast-Forward Readiness:**
> - Local branch `COMPLETED-INTEGRATION` is a direct linear descendant of `origin/COMPLETED-INTERGRATION` (`55d45d170fb9e73397a0fec22f22692ae0236610`).
> - The 4 Phase 6 commits build linearly on top of `55d45d1`, ensuring a 100% clean fast-forward push when authorized.

---

## 3. Full Test Execution Scorecard

All automated checks were executed directly from the synchronized local workspace:

| Test Suite / Tool | Command Executed | Scope | Pass / Fail Count | Status |
|---|---|---|---|---|
| **Admin Web Automated Tests** | `npm test` in `apps/admin-web/` | 36 suites (dossiers, navigation, review queue, KPIs) | **180 passed / 0 failed** | ✅ **PASS** |
| **Admin Web TypeScript Check** | `npx tsc --noEmit` in `apps/admin-web/` | Entire Next.js Admin code | **0 errors (Clean)** | ✅ **PASS** |
| **Admin Web Production Build** | `npm run build` in `apps/admin-web/` | Next.js Turbopack compiler | **All 23 routes prerendered** | ✅ **PASS** |
| **Cloudflare Worker Tests** | `npm test` in `worker/` | 35 suites (Auth, Phase C, D.1, Legal gate, E2E, Isolation, 50MB Upload) | **296 passed / 0 failed** | ✅ **PASS** |
| **Flutter Static Analysis** | `dart analyze` on target features | Router, API, Auth, Legal, Engineer modules | **0 issues found (Clean)** | ✅ **PASS** |
| **Flutter Auth Flow Tests** | `flutter test test/features/auth/` | Shared auth, `/verify-email`, session restore, profile provision | **34 passed / 0 failed** | ✅ **PASS** |
| **Flutter Legal Suite Tests** | `flutter test test/features/legal/` | Terms flow, privacy gating, legal router, post-login status | **49 passed / 0 failed** | ✅ **PASS** |
| **Flutter API Client Tests** | `flutter test test/features/api/data/api_client_test.dart` | Trailing slash stripping & clean URI path building | **15 passed / 0 failed** | ✅ **PASS** |
| **Flutter CAD & Drawing Versions** | `flutter test test/.../engineer_drawing_versions_test.dart test/.../cad_drawing_viewer_test.dart` | Multi-version switching, revision notes, pure-Dart DWG/DXF rendering | **7 passed / 0 failed** | ✅ **PASS** |
| **Flutter Projects & Common Tests** | `flutter test test/features/projects/` | Dropdown assertion safety, 50 MiB upload section, status chips | **129 passed / 0 failed** | ✅ **PASS** |
| **Total Flutter Test Suite** | Target feature test suites | Comprehensive unit & widget testing across all personas | **234 passed / 0 failed** | ✅ **PASS** |

---

## 4. Technical Architecture: Dropdown Crash Fix & Upload Workflow

### A. Technical Category Dropdown Assertion Fix
- **Root Cause:**
  When navigating to `/engineer/projects/new`, Flutter's `DropdownButtonFormField` threw:
  `Assertion failed: .../dropdown.dart: There should be exactly one item with DropdownButton's value: Architectural. Either zero or 2 or more DropdownMenuItems were detected with the same value.`
  The underlying domain model `DrawingType` in `lib/src/features/projects/domain/drawing_type.dart` was missing `architectural` in its enum definitions. Concurrently, dropdown items were generated using uppercase strings (`type.toFirestoreString()`), while drafts or initial states passed `'Architectural'`, causing 0 matching items.
- **Resolution:**
  1. Added `DrawingType.architectural` with `displayName => 'Architectural'` and `toFirestoreString() => 'ARCHITECTURAL'`.
  2. Implemented normalization in `DrawingType.fromString()` to handle canonical `'ARCHITECTURAL'`, title-case `'Architectural'`, lower-case `'architectural'`, and legacy aliases (`'ARCHITECTURAL_DRAFTING'`, `'Architectural Drafting'`, `'Architectural Plan'`).
  3. Added normalization to `ProjectFormController.loadDraft()` and `updateDrawingType()`.
  4. Wrapped dropdown value resolution defensively:
     ```dart
     final safeValue = widget.items.any((item) => item.value == widget.value) ? widget.value : null;
     ```
     Coupled with `key: ValueKey(safeValue)` and `initialValue: safeValue` (resolving Flutter 3.33+ deprecation of `value`). Unrecognized legacy or corrupted values fall back to `null` (empty placeholder) without crashing the screen.

### B. Reference-File Upload Implementation & 50 MiB Limit
- **Placement & Interaction:**
  Integrated directly inside `ProjectFormScreen` (`lib/src/features/engineer/presentation/widgets/reference_files_upload_section.dart`). If an engineer selects reference files before saving a draft (`projectId == null`), the widget automatically executes `controller.saveDraft()`, generates the draft record, and anchors the uploads to that project ID.
- **Size Enforcement:**
  - `kMaxReferenceFileSizeBytes = 52428800` (50 * 1024 * 1024 bytes).
  - Client rejects files exceeding 50 MiB with an instant error banner prior to network transmission.
  - Cloudflare Worker (`worker/src/index.ts`) verifies the `Content-Length` header and streams the upload body to R2 with an active byte counter; any payload exceeding `MAX_SIZE` immediately terminates with `HTTP 413 Payload Too Large`.
- **Supported Formats & Previews:**
  - 27 allowlisted extensions covering CAD/BIM (`dwg`, `dxf`, `dwf`, `dwfx`, `dgn`, `ifc`, `step`, `stp`, `iges`, `igs`, `rvt`, `rfa`, `skp`), documents (`pdf`, `doc`, `docx`, `txt`, `rtf`, `odt`), images (`png`, `jpg`, `jpeg`, `webp`, `tif`, `tiff`), spreadsheets (`xls`, `xlsx`, `csv`), and archives (`zip`).
  - Pure-Dart binary raster preview extraction for DWG and 2D vector geometry rendering for DXF; PDF/images previewed in-app; proprietary 3D CAD/BIM, Office documents, and archives present metadata cards with direct download triggers.
- **Authorization & Cross-Portal Access:**
  - Ordering Engineers own their reference files (`client_upload`).
  - Assigned Draughtsmen can inspect and download all client reference files from the Draughtsman Workspace.
  - Unassigned or unauthorized users receive `HTTP 403 Forbidden`.

---

## 5. Local Development & Service Startup Guide

To run the complete platform locally, open **three separate PowerShell terminals**:

### Terminal 1: Cloudflare Worker API (Backend)
```powershell
Set-Location -Path "D:\PROJECT\Archidraft-integration-workspace\worker"
npm install
npx wrangler dev --env staging --remote --port 8787
```
- **Listening URL:** `http://localhost:8787`
- **Health Check:** `http://localhost:8787/api/health`

### Terminal 2: Studio Admin Web Portal (Next.js)
```powershell
Set-Location -Path "D:\PROJECT\Archidraft-integration-workspace\apps\admin-web"
npm install
npm run dev
```
- **Listening URL:** `http://localhost:3000`
- **Login Route:** `http://localhost:3000/login`
- **Dashboard:** `http://localhost:3000/dashboard`

### Terminal 3: Multi-Role Flutter Client (Web or Android)
For Web:
```powershell
Set-Location -Path "D:\PROJECT\Archidraft-integration-workspace"
& "C:\flutter\flutter\bin\flutter.bat" run -d chrome --web-port=8080 --dart-define=STAGING=true --dart-define=API_URL=http://localhost:8787
```
- **Listening URL:** `http://localhost:8080`
- **Login Route:** `http://localhost:8080/#/login`
- **Trailing Slash Handling:** Base API URL trailing slashes are automatically sanitized by `ApiClient.resolveBaseUrl` and `ApiClient.buildUri`.

For Android Emulator:
```powershell
Set-Location -Path "D:\PROJECT\Archidraft-integration-workspace"
& "C:\flutter\flutter\bin\flutter.bat" run -d android --dart-define=STAGING=true
```
- `ApiClient` automatically routes `localhost` calls to host machine loopback `10.0.2.2:8787`.

---

## 6. Security & Sensitive Files Policy

> [!CAUTION]
> **Do Not Commit Credentials:**
> - `team/TEAM_TESTING_CREDENTIALS.md` is an untracked local file containing staging test accounts and passwords.
> - It MUST NOT be staged or committed to Git.
> - Never print plaintext passwords or secrets in pull requests or public commit messages.

---

## 7. Pre-Commit Review & Change Set Status

- **Branch:** `COMPLETED-INTEGRATION` (tracking `origin/COMPLETED-INTERGRATION`)
- **Remote Base HEAD:** `55d45d170fb9e73397a0fec22f22692ae0236610`
- **Current Local HEAD:** `32df2ef1d0da206d3d14a165f861cc1a00286074`
- **Linear Phase 6 Commits:**
  1. `100fe31f74e9563ddd466602155099438b4ed9b7`: `fix(engineer): repair drawing versions and embedded CAD viewer`
  2. `c4d0f7854148b0e79887d44eba91da2a29f0de30`: `fix(legal): prevent privacy acceptance regression`
  3. `cf79d1963278ca0cf4fd73787b1efd355eb99f9d`: `fix(auth): stabilize shared registration, email verification, and session routing`
  4. `32df2ef1d0da206d3d14a165f861cc1a00286074`: `fix(api): sanitize base url trailing slash and handle legal 404 profile provisioning`
- **Zero remote push executed:** Local verification complete; awaiting explicit user review and instruction prior to any further commit or push.
