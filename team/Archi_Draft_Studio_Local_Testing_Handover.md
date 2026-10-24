# Archi Draft Studio — Local Testing & Verification Handover

**Repository:** https://github.com/pixelmint-studio-mvs/Archidraft
**Active Delivery Branch:** `COMPLETED-INTERGRATION` (HEAD: `f21fb29`)
**Workspace:** `D:\PROJECT\Archidraft-integration-workspace`
**System Architecture:** Flutter Multiplatform Client (Web, Desktop, Android) + Cloudflare Worker API (Hono) + Next.js Admin Studio + Cloudflare D1 & R2 + Firebase Auth + PIXMINT BOT 2.0 Integration

---

## 1. Integrated Workspace Overview

All components of the Archi Draft platform—including the Cloudflare Worker backend, the multi-portal Flutter client (Engineer, Draughtsman, Student), the Next.js Studio Admin web portal, and the PIXMINT BOT integration—are now consolidated into the single `COMPLETED-INTERGRATION` branch.

> [!NOTE]
> **Monorepo Structure:** Testers no longer need separate checkouts for the Admin portal and Flutter/Worker portals. Everything runs from this single repository under:
> - `worker/`: Cloudflare Worker API, D1 migrations, and automated test harness
> - `apps/admin-web/`: Next.js Studio Admin portal and PIXMINT BOT Control Center
> - `lib/`: Flutter multi-persona client application
> - `scratch/pixmint-bot/`: PIXMINT BOT Flutter integration package

---

## 2. Prerequisites & Tooling

Ensure the following tools are installed before launching local services:

| Tool | Recommended Version | Verification Command | Notes |
| :--- | :--- | :--- | :--- |
| **Node.js** | `>= 18.18.0` (v20+ recommended) | `node -v` | Required for Worker runtime, Admin web, and test suites |
| **npm** | `>= 9.0.0` | `npm -v` | Package manager |
| **Flutter SDK** | `>= 3.22.0` (Dart `>= 3.4.0`) | `flutter --version` | Required for Flutter Web and mobile builds |
| **Google Chrome** | Latest stable | `chrome --version` | Primary browser for Flutter Web and Next.js Admin testing |

> [!TIP]
> **Flutter Executable Path:** If the `flutter` command is not available in your system `PATH`, use the verified local executable path:
> `C:\flutter\flutter\bin\flutter.bat`

---

## 3. Authoritative Local Startup Guide (4 PowerShell Terminals)

Open **four separate PowerShell terminals** to start the platform services locally. Do not run all services in a single terminal.

### Terminal 1: Archi Draft Cloudflare Worker (Backend API)
Run from the `worker/` directory:

```powershell
# Navigate to worker directory
Set-Location -Path "D:\PROJECT\Archidraft-integration-workspace\worker"

# Install dependencies if not already installed
npm install

# Option A: Local emulation (recommended for isolated development)
npx wrangler dev

# Option B: Staging execution with remote Cloudflare resources
# npx wrangler dev --env staging --remote --port 8787
```

- **Expected Port:** `8787`
- **Expected URL:** `http://localhost:8787`
- **Health Check Endpoint:** `http://localhost:8787/api/health`
- **Shutdown:** Press `Ctrl+C` in this terminal.

> [!WARNING]
> **Remote Resource Warning:**
> Running `npx wrangler dev --env staging --remote --port 8787` connects directly to Cloudflare's live remote staging D1 database (`archi-draft-db-staging`, ID: `065d76ba-eca5-4cc1-ba39-51281b79d6b4`) and remote R2 bucket (`archi-draft-storage-staging`).
> All project creations, assignments, status transitions, and drawing uploads will read and write to the shared staging environment.
> **Do not treat `--remote` as an offline local command.** Coordinate with your team before modifying staging data.

---

### Terminal 2: PIXMINT Service (AI Chatbot Backend)
Run from the PIXMINT service directory:

```powershell
# Expected listening port for PIXMINT service
# Default URL: http://127.0.0.1:8788
```

- **Expected Port:** `8788`
- **Expected URL:** `http://127.0.0.1:8788`
- **Purpose:** Serves AI suggestions, bot health (`/api/admin/health`), telemetry, bot configuration, knowledge base indexing, and unanswered query triage for the Admin Control Center and Flutter chatbot.
- **Boundary Note:** PIXMINT does **NOT** handle Firebase authentication or project state management.
- **Shutdown:** Press `Ctrl+C` in this terminal.

---

### Terminal 3: Studio Admin Web Portal (Next.js)
Run from the `apps/admin-web/` directory:

```powershell
# Navigate to admin-web directory
Set-Location -Path "D:\PROJECT\Archidraft-integration-workspace\apps\admin-web"

# Install dependencies if not already installed
npm install

# Start Next.js development server
npm run dev
```

- **Expected Port:** `3000`
- **Expected URL:** `http://localhost:3000`
- **Login Route:** `http://localhost:3000/login`
- **Activity Feed Route:** `http://localhost:3000/activity`
- **PIXMINT Control Center Route:** `http://localhost:3000/settings/pixmint-bot`
- **Configuration Defaults:**
  - Worker API: `NEXT_PUBLIC_WORKER_API_URL=http://localhost:8787`
  - PIXMINT API: `NEXT_PUBLIC_PIXMINT_API_URL=http://127.0.0.1:8788`
  - Firebase Project: `archi-draft-staging`
- **Shutdown:** Press `Ctrl+C` in this terminal.

---

### Terminal 4: Flutter Web Portal (Multiplatform Client)
Run from the repository root:

```powershell
# Navigate to repository root
Set-Location -Path "D:\PROJECT\Archidraft-integration-workspace"

# Fetch dependencies if needed
flutter pub get

# Launch Flutter Web server with staging Firebase configuration
& "C:\flutter\flutter\bin\flutter.bat" run -d web-server --web-port=8080 --dart-define=STAGING=true --dart-define=API_URL=http://localhost:8787
```

- **Expected Port:** `8080`
- **Expected URL:** `http://localhost:8080`
- **Shutdown:** Press `q` or `Ctrl+C` in this terminal.

#### Critical Compile-Time Environment Flags:
1. **`--dart-define=STAGING=true`**:
   - Compiles Flutter to select the staging Firebase configuration (`archi-draft-staging`) in `lib/firebase_options.dart`.
   - **Important:** Omitting this flag selects the default production Firebase configuration (`archi-draft`).
   - Enabling this flag does **not** start the Worker, does **not** guarantee a user account exists, and does **not** configure the API base URL.
2. **`--dart-define=API_URL=http://localhost:8787`**:
   - Explicitly points the Flutter API client (`lib/src/features/api/data/api_client.dart`) to your local Cloudflare Worker.
   - Note the exact variable name is `API_URL` (do not confuse with `API_BASE_URL`). In debug mode, this safely defaults to `http://localhost:8787`.

---

## 4. Test Accounts & Credential Security

The staging environment is provisioned with **eight staging test accounts** (two accounts for each persona):
- **Studio Admin:** 2 accounts
- **Engineer (Client):** 2 accounts
- **Draughtsman:** 2 accounts
- **Student:** 2 accounts

> [!CAUTION]
> **Strict Secrets Policy:**
> Passwords, API secrets, private keys, and session tokens are **NEVER committed to Git**.
> The file `team/TEAM_TESTING_CREDENTIALS.md` is excluded from public tracking.
> Contact the project owner securely to obtain current staging test credentials. Do not share passwords in public chat channels.

---

## 5. Verification Checklist by Role

### A. Studio Admin Portal (`http://localhost:3000`)
- [ ] **Login & Session:** Sign in using staging Admin credentials; verify successful session hydration and redirection to `/dashboard`.
- [ ] **Activity Feed (`/activity`):**
  - Verify live polling indicator (`LIVE`, poll counter, 15-second timer).
  - Verify display of genuine system events from D1 (submissions, assignments, reviews, redlines) in reverse chronological order.
  - Test search filtering across action type, details, project ID, and project name.
  - Verify that a network interruption displays the background sync warning banner while retaining previously fetched events.
- [ ] **User Directories & Profiles:**
  - Navigate to **Engineers** (`/engineers`), **Draughtsmen** (`/draughtsmen`), and **Students** (`/students`).
  - Open the quick-view modal (`Modal.tsx`): verify responsive `2xl` sizing, vertical scrolling for extended project lists, and unclipped role badges.
  - Click **View Full Dossier**: verify navigation to `/engineers/[id]`, `/draughtsmen/[id]`, and `/students/[id]` with canonical ID decoding, role-specific project/assignment listings, and truthful error/empty states.
- [ ] **PIXMINT BOT Control Center (`/settings/pixmint-bot`):**
  - Verify rendering of official brand logo (`/images/pixmint-bot-logo.jpeg`).
  - Inspect bot health telemetry, prompt suggestions, and knowledge source registry.

### B. Engineer Portal (`http://localhost:8080/#/engineer/projects`)
- [ ] **Legal Onboarding:** Complete pre-login Terms & Conditions acceptance.
- [ ] **Project Submission:** Create a new project brief with title, description, and CAD/PDF attachments.
- [ ] **Drawing Review & Redlines:** Inspect draughtsman draft submissions, review redlines, request corrections, or issue final approval.
- [ ] **PIXMINT Chatbot:** Open floating bot sheet; verify dark text input against white background, readable cursor, and message submission.

### C. Draughtsman Portal (`http://localhost:8080/#/draughtsman/assignments`)
- [ ] **Assignment Management:** Accept assigned projects; review client brief and reference drawings.
- [ ] **Drawing Uploads:** Upload CAD/DWG/DXF drawings; record version notes; transition state to review.
- [ ] **Correction Handling:** Inspect redline corrections requested by the client or admin; resolve revisions.

### D. Student Portal (`http://localhost:8080/#/student/training`)
- [ ] **Curriculum Progress:** Access modular CAD training lessons and track completion.
- [ ] **Practical Submissions:** Submit CAD assignments for evaluation.
- [ ] **Evaluation Feedback:** Review instructor rubric evaluations, feedback notes, and earned credentials.

---

## 6. Important Operational Boundaries

1. **Localhost-Only URLs:** Portal URLs (`localhost:3000`, `localhost:8080`, `localhost:8787`, `127.0.0.1:8788`) run on your local machine. Pushing to GitHub does not deploy or publish a website.
2. **Staging Environment Only:** Production deployment to Cloudflare Worker, production D1, or production Firebase remains strictly locked pending explicit owner sign-off.
3. **Legal-Policy Enforcement:** Do not bypass the legal onboarding gate or create synthetic consent records.
4. **Financial Features Frozen:** Invoicing, milestone payments, and financial ledger mutation remain frozen in this delivery phase.
5. **No Unauthorized Git Actions:** Do not stage, commit, push, or switch branches during testing. Report all reproducible findings with steps, role, expected behavior, and actual behavior.
