# ARCHI DRAFT — HANDOVER & PRACTICAL SETUP GUIDE
**For Partner / Friend Local Setup & Developer Handover**  
**Repository Branch:** `COMPLETED-INTERGRATION` (Created from verified base `integration/engineer-draughtsman` @ `8f753a97315c59c33eb1b0ad1578951434ae368e`)  
**Application Architecture:** Flutter (Web/Android/Desktop) + Cloudflare Worker (Hono) + Cloudflare D1 + Cloudflare R2 + Firebase Auth

---

## 1. Prerequisites & Tooling Versions

Verify that the following development tools are installed on your machine:

| Tool | Verified Version | Verification Command | Notes |
| :--- | :--- | :--- | :--- |
| **Flutter SDK** | `>= 3.22.0` (Dart `>= 3.4.0`) | `flutter --version` | Ensure `flutter doctor` reports no critical issues for Chrome/Android. |
| **Node.js** | `>= 18.18.0` (v20+ recommended) | `node --version` | Required for Cloudflare Workers runtime and automated tests. |
| **npm** | `>= 9.0.0` | `npm --version` | Node package manager. |
| **Cloudflare Wrangler** | `^4.131.0` (bundled in `worker/`) | `npx wrangler --version` | Edge development server and D1 migration manager. |
| **Android Studio** (Optional for Android) | Hedgehog / Iguana / Ladybug | — | Required only if running the Android mobile emulator. |
| **Google Chrome** | Latest stable | `chrome --version` | Primary target for Flutter Web local development. |

---

## 2. Clone and Initial Setup

### Step 1: Clone the Repository & Check Out the Integration Branch
```bash
git clone <repository_url> Archidraft-workspace
cd Archidraft-workspace

# Check out the verified delivery branch
git checkout COMPLETED-INTERGRATION
```

### Step 2: Install Flutter Dependencies
From the repository root directory:
```bash
flutter pub get
```

### Step 3: Install Backend Worker Dependencies
```bash
cd worker
npm install
cd ..
```

---

## 3. Running the Cloudflare Worker Locally (Backend)

The backend provides the API, database operations, and file storage handlers. It runs locally using Cloudflare's `wrangler` development server with an isolated local SQLite database (simulating D1) and local object storage (simulating R2).

### Step 1: Apply Database Migrations to Local D1
From the `worker/` directory:
```bash
cd worker
npx wrangler d1 migrations apply DB --local
```
*This executes all 17 migrations in sequence (`0001_schema.sql` through `0017_users_email_unique.sql`) against your local `.wrangler/state/v3/d1` database.*

> **Important — Local vs Production Migration State:**
> - **Local Development:** The command above applies all 17 migrations to the local test SQLite environment.
> - **Remote Production D1:** Migrations `0001` through `0007` were previously applied to production. Migrations `0008` through `0017` are **pending and unapplied**. Remote production migration (`npx wrangler d1 migrations apply DB --remote`) and Worker deployment (`npx wrangler deploy`) have **not** been executed yet and require explicit operator authorization.

### Step 2: Start the Local Worker Server
```bash
npm run dev
```
By default, the worker starts at:  
👉 **`http://localhost:8787`**

*Keep this terminal window open.*

---

## 4. Running the Flutter Frontend in Google Chrome (Web)

In a **new terminal window** at the project root:

```bash
flutter run -d chrome --dart-define=API_URL=http://localhost:8787
```

### Pre-Login Terms & Conditions Onboarding Flow
The client application enforces a strict, pre-login legal onboarding sequence across all roles:
```
Landing Page (/) ──► Role Selection (/role-selection) ──► Terms & Conditions (/legal/onboarding?role=...) ──► Role Login (/engineer/login, etc.) ──► Role Dashboard
```
- **Pre-Login Gate:** Upon selecting a role, the router redirects the user to `/legal/onboarding?role=<ROLE>`. The user must review mandatory terms and check affirmative acceptance before the role login screen can be reached. Direct URL access to login screens without prior acceptance is intercepted and redirected back to the terms screen.
- **Decline & Back Navigation:** Tapping "Decline & Exit" or the browser back button clears the pending role selection and safely returns the user to `/role-selection`.
- **Role Switching:** Acceptance is transient and scoped to the active onboarding session and role (`preLoginTermsAcceptedProvider`). Switching roles requires re-accepting terms in the new role context.
- **Logout Reset:** Calling `logout()` clears authentication state, calls `resetLegalState()`, clears `preLoginTermsAcceptedProvider`, and routes back to `/`. Future role selection requires re-navigating through Terms & Conditions.

### Key Web Features & Portals:
- **Engineer Portal:** `http://localhost:<port>/#/engineer/projects`
  - Create project briefs, view project statuses, review submitted CAD drawings, approve or request revisions, and communicate via the Collaboration Hub.
- **Draughtsman Portal:** `http://localhost:<port>/#/draughtsman/assignments`
  - Accept assignments, upload workspace drafts, inspect drawings using the built-in CAD viewer, resolve corrections, submit formal drawing versions, and exchange voice notes.
- **Student Portal:** `http://localhost:<port>/#/student/training`
  - Track modular curriculum progress, complete interactive lessons, submit CAD practical projects, view instructor rubric evaluations, and access verifiable digital credentials.

---

## 5. Running on Android Emulator (Mobile)

### Step 1: Start an Android Virtual Device (AVD)
Open Android Studio, navigate to **Virtual Device Manager**, and start an emulator (e.g., Pixel 7, API Level 34).

### Step 2: Discover Active Device / Emulator IDs
List all attached emulators and physical devices to discover the exact device identifier:
`ash
flutter devices
`
*Example output:*
`	ext
Found 2 connected devices:
sdk gphone64 arm64 (mobile) • emulator-5554 • android-arm64 • Android 14 (API 34) (emulator)
Chrome (web)                • chrome        • web-javascript • Google Chrome
`

### Step 3: Run Flutter with Emulator Networking
Android emulators use the special IP address 10.0.2.2 to access localhost on the host machine. Replace <device_id> with the actual ID shown by lutter devices (for example, emulator-5554):

`ash
flutter run -d <device_id> --dart-define=API_URL=http://10.0.2.2:8787
`

---

## 6. Environment Configuration Reference

### Frontend Configuration (`--dart-define`)
| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `API_URL` | `http://localhost:8787` | Base URL of the Cloudflare Worker API. Use `http://10.0.2.2:8787` on Android emulator. |

### Backend Configuration (`worker/wrangler.toml`)
| Binding / Variable | Local Dev Value | Production Requirement |
| :--- | :--- | :--- |
| `DB` (D1 Database) | Local SQLite simulation (`--local`) | Binding: `archi-draft-db` |
| `STORAGE` (R2 Bucket) | Local R2 simulation (`--local`) | Binding: `archi-draft-storage` |
| `ENVIRONMENT` | Not required locally (`NODE_ENV=test`) | Set `[vars] ENVIRONMENT = "production"` prior to live deployment |

*Security Policy:* Never commit production API keys, service account JSON files, or private certificates to version control.

---

## 7. Running Verification & Automated Test Suites

Verify your environment by running the test suites:

### 1. Flutter Tests & Static Analysis
```bash
# Run all 320 Flutter unit, widget, and domain tests
flutter test

# Run Flutter static analysis (must report: No issues found!)
flutter analyze
```

### 2. Backend API & Authorization Tests
From the `worker/` directory:
```bash
cd worker

# 1. Core backend authorization and handler integration suite (73 tests)
npm test

# 2. Strict Cross-User Isolation & Security Remediation suite (82 tests)
node test/cross_user_isolation_f1.test.mjs

# 3. Admin-Student Training Contract suite (13 tests)
node test/admin_student_contract.test.mjs

# 4. TypeScript typecheck
npm run typecheck
```
*Verified test suite execution evidence:* **537 / 537 tests passed (100% pass rate: 217 Worker tests + 320 Flutter tests; Flutter analyze clean; TypeScript typecheck clean).**

---

## 8. Common Troubleshooting & FAQs

### Q1: `XMLHttpRequest error` or CORS issues in Chrome
- **Cause:** The Worker is not running or running on a different port than expected by the frontend.
- **Fix:** Ensure `npm run dev` in `worker/` is running on port `8787`, and that Flutter was launched with `--dart-define=API_URL=http://localhost:8787`.

### Q2: Android Emulator cannot reach the backend
- **Cause:** Using `localhost:8787` inside Android emulator references the emulator itself, not your host computer.
- **Fix:** Use `--dart-define=API_URL=http://10.0.2.2:8787`.

### Q3: CAD drawing shows thumbnail but cannot parse layers
- **Expected Behavior:** AutoCAD DWG files are binary proprietary formats. ArchiDraft extracts the embedded high-resolution DIB/BMP bitmap thumbnail from the DWG binary header for instant preview. For full layer toggling and vector entity rendering, upload standard 2D ASCII DXF files.

### Q4: Firebase Authentication in Local Offline Mode
- In local Node.js automated test runners, mock tokens (`mock-token:<uid>`) are securely recognized by the local test harness (`NODE_ENV=test`).
- When running the live UI in a browser, Firebase Authentication connects to the configured Firebase project. Ensure network connectivity to Firebase.

---

## 9. Handover Status & Staging Pre-Deployment Checklist

Before deploying this workspace to live Cloudflare production:
1. **Admin Panel Validation:** Connect the partner's actual external Admin panel to verify the /api/admin/* endpoints end-to-end (see [./docs/FINAL_VERIFICATION_AND_HANDOVER_REPORT.md](./docs/FINAL_VERIFICATION_AND_HANDOVER_REPORT.md) for complete Admin contract specifications).
2. **Production Flag:** In `worker/wrangler.toml`, add `[vars] ENVIRONMENT = "production"`.
3. **Live Cloudflare Smoke Test:** Execute an end-to-end test against staging D1 and R2 buckets to confirm live IAM permissions.


---

## 10. Branch Policy & Delivery Governance

### Strict Owner Approval Gate
- **Active Delivery Branch:** `COMPLETED-INTERGRATION` already exists and is the current active branch (created from verified base HEAD `8f753a97315c59c33eb1b0ad1578951434ae368e`).
- **Staged Snapshot:** The current approved 152-file integration snapshot is staged in the Git index for project owner review.
- **MANDATORY GOVERNANCE RULES:**
  1. **Active Branch Delivery:** `COMPLETED-INTERGRATION` is the designated delivery branch for this multi-portal integration.
  2. **No Commit or Push Authorized Yet:** No commit or push has been authorized yet. A separate, explicit project owner approval is strictly required before creating any commit or pushing to remote origin.
  3. **Strict Prohibition on `develop` and `main`:** This multi-portal integration must NOT be merged or pushed into `develop` or `main`.
  4. **Deployment Prohibited:** Deployments to production Cloudflare Workers, D1 database, or R2 storage remain strictly prohibited without separate explicit project owner authorization.
  5. **Branch & History Preservation:** Do not rebase, cherry-pick, or switch branches; maintain the repository at HEAD `8f753a97315c59c33eb1b0ad1578951434ae368e` on `COMPLETED-INTERGRATION`.

---

## 11. Admin Integration Handover Notes

For the teammate developing the administrative portal and management features:

### 11.1 Global Case-Insensitive Email Uniqueness
- **Rule:** A single email address is globally unique across the entire system regardless of user role (`CLIENT`/`ENGINEER`, `DRAUGHTSMAN`, `STUDENT`, `ADMIN`, `STUDIO_ADMIN`).
- **Enforcement Layers:**
  1. *Worker API Pre-Check (`worker/src/index.ts`):* Registration checks `SELECT id FROM users WHERE LOWER(email) = LOWER(?)`. If an account already exists with that email under any role, the API rejects registration with:
     ```json
     HTTP 409 Conflict
     { "error": "An account with this email address already exists. Please sign in or use a different email." }
     ```
  2. *Database Index (`worker/migrations/0017_users_email_unique.sql`):* Enforces SQLite unique expression index `CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_lower ON users(LOWER(email));`.
- **Impact on Admin Account Management:**
  - The admin portal **cannot** provision or invite an existing email under a different role.
  - Multi-role capabilities cannot be achieved by creating duplicate accounts with identical emails. Permissions must be assigned via role attributes on the existing user account.

### 11.2 Legal & Administrative API Contracts
The backend exposes administrative endpoints under `/api/admin/legal/*` documented in [`docs/08_legal_privacy/EXTERNAL_ADMIN_CONTRACT.md`](./docs/08_legal_privacy/EXTERNAL_ADMIN_CONTRACT.md):
- `GET /api/admin/legal/documents`: Retrieve all draft and effective documents.
- `POST /api/admin/legal/documents`: Create a new legal policy draft.
- `POST /api/admin/legal/documents/:id/publish`: Atomically publish a new effective policy version (triggers mandatory re-acceptance for users on their next session).
- `GET /api/admin/legal/privacy-requests`: List statutory DPDP privacy and grievance tickets.
- `POST /api/admin/legal/privacy-requests/:id/resolve`: Acknowledge or resolve user privacy requests.
- `GET /api/admin/legal/consents`: Query regulatory consent audit logs.

### 11.3 Authorization Boundaries
- All `/api/admin/*` endpoints strictly require a Firebase ID token with `role IN ('ADMIN', 'STUDIO_ADMIN')`. Non-admin requests receive `403 Forbidden`.
- The external Admin UI must not attempt direct database mutations; all operations must pass through authenticated Worker API endpoints.

### 11.4 Integration Verification Test Suites
Refer to existing automated backend suites for contract validation:
- `worker/test/admin_student_contract.test.mjs`: Admin training module & evaluation contracts.
- `worker/test/legal_privacy_authorization.test.mjs`: Admin legal publishing, re-acceptance enforcement, and privacy redressal contracts.
- `worker/test/backend_authorization.test.mjs`: Core authorization, cross-role isolation, and email collision tests.

### 11.5 Pending Production Operations
- Migrations `0008` through `0017` have **not** been applied to remote production D1.
- Cloudflare Worker updates have **not** been deployed to production.
- Production deployment will be executed only after formal operator authorization.

