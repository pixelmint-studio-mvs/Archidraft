# ARCHI DRAFT — HANDOVER & PRACTICAL SETUP GUIDE
**For Partner / Developer Local Setup & Integration Verification**
**Repository Branch:** `COMPLETED-INTERGRATION` (HEAD: `f21fb29`)
**Workspace:** `D:\PROJECT\Archidraft-integration-workspace`
**Application Architecture:** Flutter (Web/Android/Desktop) + Next.js Admin Studio + Cloudflare Worker (Hono) + Cloudflare D1 + Cloudflare R2 + Firebase Auth + PIXMINT BOT 2.0 Integration

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

```
Archidraft-integration-workspace/
├── apps/
│   └── admin-web/              # Next.js 14 Studio Admin Portal & PIXMINT Bot Control Center (Port 3000)
├── docs/                       # Architectural specifications, security, workflows, QA reports
├── lib/                        # Flutter multi-persona client application (Port 8080)
│   ├── firebase_options.dart   # Compile-time Firebase configuration (Default: Prod, STAGING=true: Staging)
│   └── src/features/           # Feature modules: engineer, draughtsman, student, legal, api
├── scratch/
│   └── pixmint-bot/            # PIXMINT BOT Flutter integration package (UI sheets, theme, input)
├── team/                       # Team handover guides and credentials instructions
└── worker/                     # Cloudflare Worker API (Hono) + D1 migrations + Test suites (Port 8787)
```

---

## 3. Authoritative Local Startup Guide (4 Separate PowerShell Terminals)

To run the complete platform locally with all interconnected features, open **four separate PowerShell terminals**.

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

### Terminal 2: PIXMINT Service (AI Chatbot Backend)
The PIXMINT service handles AI suggestions, telemetry, bot configuration, knowledge base indexing, and unanswered query triage.

```powershell
# Launch your configured local PIXMINT service or mock service
# Ensure the service listens on port 8788
```

- **Expected Port:** `8788`
- **Expected URL:** `http://127.0.0.1:8788`
- **Endpoints Provided:**
  - Health & Telemetry: `GET /api/admin/health`
  - Analytics: `GET /api/admin/analytics`
  - Suggestions: `GET /api/chat/suggestions?role=...`
  - Config: `GET /api/admin/config`, `POST /api/admin/config`
  - Audit Logs: `GET /api/admin/audit-logs`
  - Knowledge Sources: `GET /api/admin/knowledge/sources`
- **Boundary Clarification:** PIXMINT does **NOT** manage Firebase authentication or commercial project state machines.
- **Safe Shutdown:** Press `Ctrl+C` in this terminal.

---

### Terminal 3: Studio Admin Web Portal (Next.js)
The Admin Studio provides administrative oversight, user directories, project assignment dispatch, evaluation queues, live activity feeds, and the PIXMINT Bot Control Center.

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
  - PIXMINT Bot Control Center: `http://localhost:3000/settings/pixmint-bot`
- **Environment Configuration:**
  - Worker API URL: `NEXT_PUBLIC_WORKER_API_URL` (Defaults to `http://localhost:8787`)
  - PIXMINT API URL: `NEXT_PUBLIC_PIXMINT_API_URL` (Defaults to `http://127.0.0.1:8788`)
  - Firebase Configuration: Defaults to `archi-draft-staging` in `apps/admin-web/src/lib/firebase.ts`
- **Safe Shutdown:** Press `Ctrl+C` in this terminal.

---

### Terminal 4: Flutter Web Multi-Persona Portal (Client)
The Flutter application provides the dedicated portals for Engineers, Draughtsmen, and Students.

```powershell
# Navigate to repository root
Set-Location -Path "D:\PROJECT\Archidraft-integration-workspace"

# Fetch Flutter dependencies
flutter pub get

# Launch Flutter Web server with staging Firebase configuration
& "C:\flutter\flutter\bin\flutter.bat" run -d web-server --web-port=8080 --dart-define=STAGING=true --dart-define=API_URL=http://localhost:8787
```

- **Working Directory:** `D:\PROJECT\Archidraft-integration-workspace`
- **Expected Port:** `8080`
- **Expected URL:** `http://localhost:8080`
- **Safe Shutdown:** Press `q` or `Ctrl+C` in this terminal.

#### Understanding Compile-Time Configuration Flags:
1. **`--dart-define=STAGING=true`**:
   - Defined in `lib/firebase_options.dart`:
     ```dart
     static const bool _isStaging = bool.fromEnvironment('STAGING', defaultValue: false);
     ```
   - When `STAGING=true` is supplied, Flutter Web selects the staging Firebase project (`archi-draft-staging`, App ID: `1:528293938258:web:bb7dfade95c8426c888b8b`).
   - When omitted, it defaults to `false` and selects the production Firebase project (`archi-draft`).
   - **Important:** Supplying `STAGING=true` does **not** launch the Worker backend, does **not** ensure user accounts are registered, and does **not** configure the API base URL.
2. **`--dart-define=API_URL=http://localhost:8787`**:
   - Read by `lib/src/features/api/data/api_client.dart`:
     ```dart
     final configured = (overrideUrl ?? const String.fromEnvironment('API_URL')).trim();
     ```
   - Points the Flutter HTTP client to your local Cloudflare Worker.
   - In debug/test mode, `API_URL` safely defaults to `http://localhost:8787`. In release mode, it must be explicitly specified as an HTTPS URL.
   - **Do not confuse `API_URL` with `API_BASE_URL`.**

---

## 4. Documentation of Recent Platform Fixes

### A. Firebase Staging Compile-Time Flag
- **Source:** `lib/firebase_options.dart`
- **Mechanism:** Compile-time conditional flag `bool.fromEnvironment('STAGING', defaultValue: false)`.
- **Behavior:** Passing `--dart-define=STAGING=true` selects `webStaging` (`archi-draft-staging`). Omitting it selects `web` (`archi-draft`).
- **Separation of Concerns:** Firebase authentication project selection is strictly decoupled from the Worker API endpoint (`API_URL`).

### B. PIXMINT Admin Control Center Brand Logo
- **Asset Location:** `apps/admin-web/public/images/pixmint-bot-logo.jpeg`
- **Component:** `apps/admin-web/src/components/admin/PixmintBotControlCenter.tsx`
- **Implementation:** Referenced via Next.js `<Image src="/images/pixmint-bot-logo.jpeg" alt="PIXMINT BOT 2.0 logo" width={48} height={48} />`.
- **Convention:** All public static media are served from `apps/admin-web/public/` to prevent broken relative asset links.

### C. PIXMINT Flutter Chat Input Readability
- **Component:** `scratch/pixmint-bot/lib/src/presentation/sheet/pixmint_chat_input.dart`
- **Implementation:**
  - Container: White background (`color: Colors.white`), rounded corners (`borderRadius: 16`), and focused emerald border (`width: 1.2`).
  - Text: Explicitly styled with `color: Colors.black`, `fontSize: 14`, and `cursorColor: Colors.black`.
  - Placeholder: Readable slate grey (`color: Color(0xFF64748B)`).
- **Verification:** User-entered text and cursor are crisp and legible against the light input container; message submission and thinking indicator behaviors remain intact.

### D. User Directory, Profile Modal, and Full Dossier
- **Components:**
  - `apps/admin-web/src/components/ui/Modal.tsx`
  - `apps/admin-web/src/lib/api.ts` (`getUserDetails`)
  - `apps/admin-web/src/app/engineers/[id]/page.tsx`
  - `apps/admin-web/src/app/draughtsmen/[id]/page.tsx`
  - `apps/admin-web/src/app/students/[id]/page.tsx`
- **Root Cause & Fix:**
  - Quick-view modals suffered from constrained sizing and clipped badges. Updated `Modal.tsx` to support `maxWidth="2xl"` with responsive padding, vertical scrolling (`max-h-[92vh]`), and unclipped status badges.
  - `getUserDetails(userId)` was fragile when Worker returned flat vs. nested payloads. Normalized to seamlessly accept both `{ user, projects }` and flat `{ id, ... }` payloads.
  - Role-specific queries: Populates projects for Engineers (`client_id`), Draughtsmen (`draughtsmanId` assignments falling back to project filter), and Students (`/api/admin/students/[id]` training assignments).
  - Robust Error States: Distinguishes 401/403 authorization failures, 404 not-found profiles, network connection drops, and empty project rosters without masking errors.

### E. Admin Activity Feed Architecture & Fix
- **Components & Endpoints:**
  - Route: `/activity` (`apps/admin-web/src/app/activity/page.tsx`)
  - Endpoint: `GET /api/activity?limit=100` (`worker/src/index.ts`)
  - Table: `activity_logs`
- **Root Cause & Fix:**
  - Earlier worker SQL query used `JOIN projects p ON a.project_id = p.id`, which dropped all activity logs that had a null or unlinked `project_id`.
  - Changed to `LEFT JOIN projects p ON a.project_id = p.id`, preserving all platform audit events.
  - Added query validation: `limit` parameter clamped between 1 and 500 (default 100).
  - Role authorization: Permits `ADMIN` and `STUDIO_ADMIN` to inspect global events, and permits `CLIENT` / `ENGINEER` and `DRAUGHTSMAN` to inspect their relevant project events.
  - Background Polling Retention: Activity page polls every 15 seconds. If a background sync fails, previously retrieved records are retained while displaying an ambient warning banner.
  - Dedicated Error Cards: Distinguishes authentication errors (401/403), service outages (500), and truthful empty D1 states (no events recorded yet).

---

## 5. Verification & Test Execution Commands

Run non-service-starting automated test suites to verify system integrity:

### 1. Cloudflare Worker Test Harness
From the `worker/` directory:

```powershell
Set-Location -Path "D:\PROJECT\Archidraft-integration-workspace\worker"

# Run complete backend test suite (34 suites, 281 tests)
npm test

# Run TypeScript typecheck (must report 0 errors)
npm run typecheck
```

- **Verified Metric:** **281 / 281 tests passed** (covering authorization, cross-user isolation, legal gates, and `/api/activity`).

### 2. Studio Admin Web Test Harness
From the `apps/admin-web/` directory:

```powershell
Set-Location -Path "D:\PROJECT\Archidraft-integration-workspace\apps\admin-web"

# Run complete admin test suite (36 suites, 151 tests)
npm test
```

- **Verified Metric:** **151 / 151 tests passed** (including 6 new tests in `test/activity-feed.test.ts` and 5 in `test/user-dossier-contracts.test.ts`).

### 3. Flutter Client Verification
From the repository root:

```powershell
Set-Location -Path "D:\PROJECT\Archidraft-integration-workspace"

# Run static analysis
& "C:\flutter\flutter\bin\flutter.bat" analyze
```

- **Verified Metric:** **0 issues found** across the codebase and PIXMINT package.

---

## 6. Common Troubleshooting & FAQs

### Q1: Flutter Web displays `XMLHttpRequest error` when logging in or loading data
- **Cause:** Cloudflare Worker is not running or running on an unexpected port.
- **Fix:** Ensure Terminal 1 is running `npx wrangler dev` on port `8787`. Ensure Flutter Web was launched with `--dart-define=API_URL=http://localhost:8787`.

### Q2: Admin Web displays "Administrative Access Required" or "Unable to Connect" on `/activity`
- **Cause:** Session token missing or signed in with an unauthorized role.
- **Fix:** Sign out and log in with an authorized Studio Admin staging account. Verify that the Worker is running on `http://localhost:8787`.

### Q3: How do I obtain staging test account credentials?
- **Policy:** Credentials are intentionally excluded from version control to prevent credential leakage. Request the staging credentials file from the project owner.

### Q4: Can I run Flutter Web against the remote staging Worker while keeping the database untouched?
- **Policy:** The remote staging Worker connects to the real shared staging D1 database and R2 bucket. Any state mutation in the UI is live. Use local Worker emulation (`npx wrangler dev`) for isolated testing.

---

## 7. Delivery Governance & Protected Workspace Rules

1. **Active Delivery Branch:** All integration work resides on `COMPLETED-INTERGRATION`.
2. **Zero Unauthorized Git Actions:** Do not stage files, commit, push, switch branches, reset, or stash.
3. **Preserve Protected Work:** Untracked test suites, image assets, and `team/` documents must remain untouched for manual staging and review.
4. **Deployments Prohibited:** Deployments to production Cloudflare Workers or production Firebase are strictly locked pending owner approval.
