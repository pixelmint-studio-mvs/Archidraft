# ARCHI DRAFT — HANDOVER & PRACTICAL SETUP GUIDE
**For Partner / Developer Local Setup & Integration Verification**  
**Repository Branch:** `COMPLETED-INTERGRATION` (HEAD: `4e3b8710dccd122db2090524987c7b103de078bd`)  
**Workspace:** `D:\PROJECT\Archidraft-integration-workspace`  
**Application Architecture:** Flutter (Web/Android/Desktop) + Next.js Admin Studio + Cloudflare Worker (Hono) + Cloudflare D1 + Cloudflare R2 + Firebase Auth

---

## 1. Prerequisites & Tooling Versions

Verify that the following development tools are installed on your machine:

| Tool | Verified Version | Verification Command | Notes |
| :--- | :--- | :--- | :--- |
| **Node.js** | `>= 18.18.0` (v20+ recommended) | `node -v` | Required for Cloudflare Workers runtime, Next.js Admin Web, and automated test runners. |
| **npm** | `>= 9.0.0` | `npm -v` | Node package manager. |
| **Flutter SDK** | `>= 3.22.0` (Dart `>= 3.4.0`) | `flutter --version` | Required for multi-persona client application (Web, Android, Desktop). |
| **Cloudflare Wrangler** | `^4.131.0` (bundled in `worker/`) | `npx wrangler --version` | Edge development server and D1 migration manager. |
| **Google Chrome** | Latest stable | `chrome --version` | Primary browser for Flutter Web and Next.js Admin Studio local development. |
| **Android Studio** (Optional) | Hedgehog / Iguana / Ladybug | — | Required only if running the Android mobile emulator. |

> [!TIP]
> **Flutter Executable Fallback:** If `flutter` is not recognized globally in PowerShell, use the full executable path:
> `C:\flutter\flutter\bin\flutter.bat`

---

## 2. Workspace Architecture & Directory Layout

The platform is integrated into a single monorepo on branch `COMPLETED-INTERGRATION`:

```text
Archidraft-integration-workspace/
├── apps/
│   └── admin-web/              # Next.js 14 Studio Admin Portal (Port 3000)
├── assets/                     # 3D models and image assets for Flutter
├── docs/                       # Architectural specifications, security, workflows, QA reports
│   └── FINAL_VERIFICATION_AND_HANDOVER_REPORT.md  # Authoritative handover & verification report
├── lib/                        # Flutter multi-persona client application (Port 8080)
│   ├── firebase_options.dart   # Compile-time Firebase configuration (Default: Prod, STAGING=true: Staging)
│   └── src/features/           # Feature modules: engineer, draughtsman, student, legal, api
├── team/                       # Team handover guides and confidential testing credentials
└── worker/                     # Cloudflare Worker API (Hono) + D1 migrations + Test suites (Port 8787)
```

---

## 3. Authoritative Local Startup Guide (3 Separate PowerShell Terminals)

To run the complete platform locally with all interconnected features, open **three separate PowerShell terminals**.

### Terminal 1: Archi Draft Cloudflare Worker (Backend API)
The Worker provides the core REST API, relational D1 database operations, R2 storage handlers, and activity logging.

```powershell
# Navigate to worker directory
Set-Location -Path "D:\PROJECT\Archidraft-integration-workspace\worker"

# Install dependencies if not already installed
npm install

# Option A: Local SQLite & Local R2 Emulation (Recommended for offline development)
npx wrangler dev

# Option B: Staging Execution with Remote Cloudflare Resources
# npx wrangler dev --env staging --remote --port 8787
```

- **Working Directory:** `D:\PROJECT\Archidraft-integration-workspace\worker`
- **Expected Port:** `8787`
- **Expected URL:** `http://localhost:8787`
- **Health Check Endpoint:** `http://localhost:8787/api/health`
- **Safe Shutdown:** Press `Ctrl+C` in this terminal.

> [!WARNING]
> **Remote Resource Warning:**
> Running `npx wrangler dev --env staging --remote --port 8787` executes the Worker locally while proxying database and storage bindings directly to **live remote Cloudflare staging resources**:
> - D1 Database: `archi-draft-db-staging` (UUID: `065d76ba-eca5-4cc1-ba39-51281b79d6b4`)
> - R2 Storage Bucket: `archi-draft-storage-staging`
>
> Any project submissions, status changes, assignments, and uploaded files will immediately affect the shared staging database. **Do not use `--remote` as an ordinary offline command.** Always coordinate with the team before modifying staging data.

---

### Terminal 2: Studio Admin Web Portal (Next.js)
The Admin Studio provides administrative oversight, user directories, project assignment dispatch, evaluation queues, and live activity feeds.

```powershell
# Navigate to admin-web directory
Set-Location -Path "D:\PROJECT\Archidraft-integration-workspace\apps\admin-web"

# Install dependencies if not already installed
npm install

# Start Next.js development server
npm run dev
```

- **Working Directory:** `D:\PROJECT\Archidraft-integration-workspace\apps\admin-web`
- **Expected Port:** `3000`
- **Expected URL:** `http://localhost:3000`
- **Key Routes:**
  - Login: `http://localhost:3000/login`
  - Dashboard: `http://localhost:3000/dashboard`
  - Engineer Directory: `http://localhost:3000/engineers`
  - Draughtsman Directory: `http://localhost:3000/draughtsmen`
  - Student Directory: `http://localhost:3000/students`
  - Live Activity Feed: `http://localhost:3000/activity`
- **Environment Configuration:**
  - Worker API URL: `NEXT_PUBLIC_WORKER_API_URL` (Defaults to `http://localhost:8787`)
  - Firebase Configuration: Defaults to `archi-draft-staging` in `apps/admin-web/src/lib/firebase.ts`
- **Safe Shutdown:** Press `Ctrl+C` in this terminal.

---

### Terminal 3: Flutter Multi-Persona Portal (Client)
The Flutter application provides the dedicated portals for Engineers, Draughtsmen, and Students.

#### Option A: Running in Google Chrome (Flutter Web)
```powershell
# Navigate to repository root
Set-Location -Path "D:\PROJECT\Archidraft-integration-workspace"

# Fetch Flutter dependencies
& "C:\flutter\flutter\bin\flutter.bat" pub get

# Launch Flutter Web server with staging Firebase configuration
& "C:\flutter\flutter\bin\flutter.bat" run -d chrome --web-port=8080 --dart-define=STAGING=true --dart-define=API_URL=http://localhost:8787
```

- **Expected Port:** `8080`
- **Expected URL:** `http://localhost:8080`
- **Safe Shutdown:** Press `q` or `Ctrl+C` in this terminal.

#### Option B: Running on Android Emulator
```powershell
# Navigate to repository root
Set-Location -Path "D:\PROJECT\Archidraft-integration-workspace"

# Launch on running Android emulator
& "C:\flutter\flutter\bin\flutter.bat" run -d android --dart-define=STAGING=true
```

- **Automatic Host Loopback:** The `ApiClient` detects the Android emulator environment and automatically resolves `http://localhost:8787` to the host machine loopback `http://10.0.2.2:8787`.
- **Cleartext HTTP:** Configured via `android:usesCleartextTraffic="true"` in `android/app/src/main/AndroidManifest.xml` for debug testing with local Worker.

#### Understanding Compile-Time Configuration Flags:
1. **`--dart-define=STAGING=true`**:
   - Defined in `lib/firebase_options.dart`:
     ```dart
     static const bool _isStaging = bool.fromEnvironment('STAGING', defaultValue: false);
     ```
   - When `STAGING=true` is supplied, Flutter Web selects the staging Firebase project (`archi-draft-staging`, App ID: `1:528293938258:web:bb7dfade95c8426c888b8b`).
   - When omitted, it defaults to `false` and selects the production Firebase project (`archi-draft`).
2. **`--dart-define=API_URL=http://localhost:8787`**:
   - Points the Flutter HTTP client to your local Cloudflare Worker.
   - In debug/test mode, `API_URL` safely defaults to `http://localhost:8787` (or `10.0.2.2:8787` on Android emulator).
   - In release mode, it must be explicitly specified as an HTTPS URL.

---

## 4. Documentation of Recent Platform Fixes

### A. Complete PIXMINT BOT Removal & Cleanup (Task 1)
- **Scope:** Completely removed PIXMINT BOT versions 1.0 and 2.0 across all four portals.
- **Changes:**
  - Removed bot floating mascot and chat sheet triggers from Flutter `ResponsiveScaffold` and `StudentStudioScreen`.
  - Removed `PixmintBotControlCenter`, `PixmintChatInput`, and `/settings/pixmint-bot` route in Next.js Admin Studio.
  - Removed unused bot routes and companion service scripts.
  - Preserved friend's original `packages/pixmint_bot` package structure.

### B. Shared 3D Architectural Monogram Integration
- **Components:**
  - Admin Web: `apps/admin-web/src/components/ui/Monogram3DViewer.tsx` (Three.js with OrbitControls, continuous vertical rotation, orthographic framing).
  - Flutter: `lib/src/shared/widgets/hexagonal_monogram_3d_viewer.dart` with platform-specific conditional imports (`monogram_viewer_web.dart` and `monogram_viewer_stub.dart`).
- **Safety:** Built-in error boundary and null check against `WebViewPlatform.instance` ensures that if WebGL or native WebView is unavailable, it renders the static 2D monogram cleanly without throwing exceptions.

### C. DWG/CAD Preview & API Repair (Task 2)
- **Component:** `lib/src/features/projects/presentation/widgets/cad_drawing_viewer.dart`
- **Capabilities:**
  - Pure-Dart binary header extraction of embedded DIB/BMP raster preview images from AutoCAD DWG files (AC1012 through AC1032).
  - 2D vector geometry rendering for DXF files (`DxfLine`, `DxfPolyline`, `DxfCircle`, `DxfArc`, `DxfTextEntity`).
  - Seamless fallback to metadata details and safe file download triggers.

### D. Android Crash Fix & Legal Status Stability (Task 3)
- **Root Cause 1 (WebView Assertion):** `model_viewer_plus` on native mobile wraps `webview_flutter`. Under non-web platforms without initialized platform view, it asserted `WebViewPlatform.instance != null`. Fixed with safe null guard and fallback image.
- **Root Cause 2 (Cleartext HTTP):** Android 9+ default network policy blocks cleartext HTTP to port 8787. Fixed by setting `android:usesCleartextTraffic="true"` in `android/app/src/main/AndroidManifest.xml`.
- **Root Cause 3 (Emulator Loopback):** `localhost:8787` refers to the Android device itself. Fixed by auto-mapping `localhost` to `10.0.2.2` in `ApiClient.resolveBaseUrl()`.
- **Root Cause 4 (Router Desync Loop):** Unawaited `ref.invalidate(userLegalStatusProvider)` in `_handleAcceptance` caused GoRouter to redirect back to `/legal/onboarding`. Fixed by awaiting `ref.refresh(userLegalStatusProvider.future)` before pushing role dashboards.

### E. Admin Dashboard Metrics & Collaboration Navigation Fixes
- **Dashboard Metrics:** `apps/admin-web/src/app/dashboard/page.tsx` now derives Registered Engineers authoritatively from backend metrics or combines `ENGINEER` + `CLIENT` roles without double-counting.
- **Role Crash Prevention:** `getRoleColor` in `apps/admin-web/src/app/projects/[projectId]/page.tsx` now safely supports `STUDIO_ADMIN`, `ENGINEER`, and `STUDENT` with an infallible fallback object.
- **Authoritative Dossier Routing:** `users/page.tsx` links user rows to `/engineers/${id}`, `/draughtsmen/${id}`, and `/students/${id}`. Project detail overview links directly to the Ordering Engineer and Assigned Draughtsman dossiers.
- **Backend Joins:** `worker/src/index.ts` joins `users u ON p.client_id = u.id` for `client_name` and `client_email`, and returns `current_assignment_id`.

---

## 5. Verification & Test Execution Commands

Run automated test suites to verify system integrity:

### 1. Studio Admin Web Test Harness
```powershell
Set-Location -Path "D:\PROJECT\Archidraft-integration-workspace\apps\admin-web"

# Run complete admin test suite (39 suites, 161 tests)
npm test

# Run TypeScript type check (must report 0 errors)
npx tsc --noEmit

# Run production build check (must prerender all 23 routes)
npm run build
```
- **Verified Metrics:** **161 / 161 tests passed**, **0 type errors**, **23/23 routes compiled**.

### 2. Cloudflare Worker Test Harness
```powershell
Set-Location -Path "D:\PROJECT\Archidraft-integration-workspace\worker"

# Run complete backend test suite (34 suites, 283 tests)
npm test
```
- **Verified Metrics:** **283 / 283 tests passed** (covering authorization, cross-user isolation, legal gates, dashboard KPIs, and normalized assignment lookup).

### 3. Flutter Client Verification
```powershell
Set-Location -Path "D:\PROJECT\Archidraft-integration-workspace"

# Run static analysis (must report no issues)
& "C:\flutter\flutter\bin\flutter.bat" analyze lib

# Run API Client URL & emulator resolution tests
& "C:\flutter\flutter\bin\flutter.bat" test test/features/api/data/api_client_test.dart

# Run Terms & Conditions pre-login navigation flow suite
& "C:\flutter\flutter\bin\flutter.bat" test test/features/legal/presentation/terms_navigation_flow_test.dart
```
- **Verified Metrics:** **0 issues found** in analyzer, **11 / 11 tests passed** in API client suite, **14 / 14 tests passed** in Terms navigation suite.

---

## 6. Common Troubleshooting & FAQs

### Q1: Flutter Web displays `XMLHttpRequest error` when logging in or loading data
- **Cause:** Cloudflare Worker is not running or running on an unexpected port.
- **Fix:** Ensure Terminal 1 is running `npx wrangler dev` on port `8787`. Ensure Flutter Web was launched with `--dart-define=API_URL=http://localhost:8787`.

### Q2: Android emulator cannot connect to local Worker (`SocketException` or timeout)
- **Cause:** `localhost` from inside an Android emulator refers to the emulator itself, not the host machine.
- **Fix:** The updated `ApiClient` automatically maps `localhost` to `10.0.2.2`. Verify that Terminal 1 Worker is running on port 8787 and `android:usesCleartextTraffic="true"` is set.

### Q3: Admin Web displays "Administrative Access Required" or "Unable to Connect"
- **Cause:** Session token missing or signed in with an unauthorized role.
- **Fix:** Sign out and log in with an authorized Studio Admin staging account. Verify that the Worker is running on `http://localhost:8787`.

### Q4: How do I obtain staging test account credentials?
- **Policy:** Credentials are confidential and excluded from version control. Request the local testing credentials document from the project owner. See `team/TEAM_TESTING_CREDENTIALS.md` locally (keep untracked).

---

## 7. Delivery Governance & Protected Workspace Rules

1. **Active Delivery Branch:** All integration work resides on `COMPLETED-INTERGRATION`.
2. **Zero Unauthorized Git Actions:** Do not stage files, commit, push, switch branches, reset, or stash.
3. **Preserve Protected Work:** Untracked test suites, image assets, and `team/` documents must remain untouched for manual staging and review.
4. **Deployments Prohibited:** Deployments to production Cloudflare Workers or production Firebase are strictly locked pending owner approval.
5. **Authoritative Handover Report:** Detailed technical evidence and verification logs are maintained in [docs/FINAL_VERIFICATION_AND_HANDOVER_REPORT.md](docs/FINAL_VERIFICATION_AND_HANDOVER_REPORT.md).
