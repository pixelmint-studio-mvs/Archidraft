# ARCHI DRAFT — AUTHORITATIVE INTEGRATION HANDOVER & VERIFICATION REPORT

**Workspace:** `D:\PROJECT\Archidraft-integration-workspace`<br/>
**Active Branch:** `COMPLETED-INTERGRATION`<br/>
**Remote:** `https://github.com/pixelmint-studio-mvs/Archidraft.git`<br/>
**Current Synchronized Base HEAD:** `1665c2c7f93ee28aebfae489852ab5363ad68f66` (`docs: update integration handover and remove obsolete scratch notes`)<br/>
**Date:** October 26, 2026<br/>
**Status:** **SYNCHRONIZED, VERIFIED, CLEAN & READY FOR PRE-COMMIT REVIEW**

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

---

## 2. Remote Synchronization & Ancestry Evidence

| Branch / Commit | Full Commit SHA | Author & Date | Commit Message | Status |
|---|---|---|---|---|
| **Base Synchronized Commit** | `4e3b8710dccd122db2090524987c7b103de078bd` | A.Ajmal Basheer, Oct 25, 2026 18:47:15 +0530 | `fix(admin): correct engineer metrics and collaboration navigation` | Linear Ancestor |
| **Previous Remote Tip** | `1665c2c7f93ee28aebfae489852ab5363ad68f66` | Mohammed Janis P, Oct 25, 2026 20:23:56 +0530 | `docs: update integration handover and remove obsolete scratch notes` | **Remote Reference (`origin/COMPLETED-INTERGRATION`)** |
| **Commit A (Dropdown Fix)** | `f84a1c863266205cf9f5d3419fcda9a97fbc9a13` | Mohammed Janis P, Oct 26, 2026 | `fix(engineer): normalize technical category dropdown values` | **Local Commit (Ready for push)** |
| **Commit B (Docs Handover)** | Pending SHA | Mohammed Janis P, Oct 26, 2026 | `docs: update engineer upload and dropdown fix handover` | Staging in progress |

> [!IMPORTANT]
> **Branch Ancestry & Fast-Forward Readiness:**
> - Local branch `COMPLETED-INTEGRATION` is a direct linear descendant of `origin/COMPLETED-INTERGRATION` (`1665c2c7f93ee28aebfae489852ab5363ad68f66`).
> - The new commits build linearly on top of `1665c2c`, ensuring a 100% clean fast-forward push when authorized.

---

## 3. Full Test Execution Scorecard

All automated checks were executed directly from the synchronized local workspace:

| Test Suite / Tool | Command Executed | Scope | Pass / Fail Count | Status |
|---|---|---|---|---|
| **Admin Web Automated Tests** | `npm test` in `apps/admin-web/` | 39 suites (includes `phase_final_dashboard_and_collab.test.ts`) | **161 passed / 0 failed** | ✅ **PASS** |
| **Admin Web TypeScript Check** | `npx tsc --noEmit` in `apps/admin-web/` | Entire Next.js Admin code | **0 errors (Clean)** | ✅ **PASS** |
| **Admin Web Production Build** | `npm run build` in `apps/admin-web/` | Next.js Turbopack compiler | **All 23 routes prerendered** | ✅ **PASS** |
| **Cloudflare Worker Tests** | `npm test` in `worker/` | 35 suites (Auth, Phase C, D.1, E2E, Isolation, 50MB Upload) | **296 passed / 0 failed** | ✅ **PASS** |
| **Flutter Code Analysis** | `flutter analyze` on changed files | Project domain, controller, screen & test suites | **No issues found (0 errors/warnings)** | ✅ **PASS** |
| **Technical Category Dropdown Regression** | `flutter test test/.../technical_category_dropdown_regression_test.dart` | Uniqueness, assertion prevention, draft restore, legacy fallback | **8 passed / 0 failed** | ✅ **PASS** |
| **Reference Files Upload Section Tests** | `flutter test test/.../reference_files_upload_section_test.dart` | 50 MiB limit, file rendering, auto draft save, upload states | **5 passed / 0 failed** | ✅ **PASS** |
| **Project Enums & Validators Tests** | `flutter test test/.../project_enums_test.dart test/.../project_validators_test.dart` | DrawingType parsing, firestore serialization, form validation | **14 passed / 0 failed** | ✅ **PASS** |
| **Project Form Controller Tests** | `flutter test test/.../project_form_controller_test.dart` | Draft load normalization, state mutation, category updates | **7 passed / 0 failed** | ✅ **PASS** |
| **Flutter API Client Tests** | `flutter test test/features/api/data/api_client_test.dart` | Emulator host loopback & staging security | **11 passed / 0 failed** | ✅ **PASS** |
| **Flutter Terms Navigation Tests** | `flutter test test/features/legal/presentation/terms_navigation_flow_test.dart` | Terms acceptance & role login routing | **14 passed / 0 failed** | ✅ **PASS** |

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
& "C:\flutter\flutter\bin\flutter.bat" run -d chrome --web-port=8080 --dart-define=STAGING=true
```
- **Listening URL:** `http://localhost:8080`
- **Login Route:** `http://localhost:8080/#/login`

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
> - Recommend adding `team/` to `.gitignore` or keeping it strictly uncommitted.
> - Never print plaintext passwords or secrets in pull requests or public commit messages.

---

## 7. Pre-Commit Review & Change Set Status

- **Branch:** `COMPLETED-INTEGRATION` (tracking `origin/COMPLETED-INTERGRATION`)
- **Remote Base HEAD:** `1665c2c7f93ee28aebfae489852ab5363ad68f66`
- **Working Tree:** All changes verified. Two logical commits:
  1. `f84a1c863266205cf9f5d3419fcda9a97fbc9a13`: `fix(engineer): normalize technical category dropdown values` (Committed)
  2. Pending SHA: `docs: update engineer upload and dropdown fix handover` (Staging in progress)
- **Zero remote push executed:** Local verification complete; awaiting explicit user authorization prior to GitHub push.
