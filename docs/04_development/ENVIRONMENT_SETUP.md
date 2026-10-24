# ENVIRONMENT SETUP & CONFIGURATION GUIDE

This document defines the verified development environment configuration, tooling matrix, port mappings, and environment flags across the consolidated Archi Draft × PIXMINT workspace on branch `COMPLETED-INTERGRATION` (HEAD: `f21fb29`).

**Operating System:** Windows
**Repository Root:** `D:\PROJECT\Archidraft-integration-workspace`
**Target Branch:** `COMPLETED-INTERGRATION`

---

## 1. Verified Tooling Matrix

| Tool Name | Recommended / Verified Version | Purpose | Verification Command | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Node.js** | `v20.x` / `v22.x` / `v24.20.0` | Worker runtime & Next.js runtime | `node -v` | Minimum requirement is Node.js >= 18.18.0 |
| **npm** | `11.19.0` / `>= 9.0.0` | Package management | `npm -v` | Manages dependencies in `worker/` and `apps/admin-web/` |
| **Flutter SDK** | `>= 3.22.0` (Dart `>= 3.4.0`) | Multi-persona UI framework | `flutter --version` | Powers Engineer, Draughtsman, and Student web/mobile portals |
| **Cloudflare Wrangler** | `^4.131.0` | Worker runtime & D1 migrations | `npx wrangler --version` | Bundled in `worker/node_modules/.bin` |
| **Git** | `>= 2.40.0` | Version control | `git --version` | Active branch: `COMPLETED-INTERGRATION` |
| **Google Chrome** | Latest stable | Primary web runtime | `chrome --version` | Primary development target for Flutter Web & Next.js |

> [!TIP]
> **Flutter Executable Path:** When invoking Flutter from PowerShell, if `flutter` is not registered in your system `PATH`, use the verified local binary:
> `C:\flutter\flutter\bin\flutter.bat`

---

## 2. Port Allocation & Local Architecture Matrix

The Archi Draft ecosystem connects four discrete services running on distinct local ports:

| Service | Port | Default URL | Working Directory | Runtime Engine |
| :--- | :--- | :--- | :--- | :--- |
| **Admin Web Portal** | `3000` | `http://localhost:3000` | `apps/admin-web/` | Next.js 14 / React / Tailwind |
| **Flutter Web Client** | `8080` | `http://localhost:8080` | Project root (`lib/`) | Flutter Web Server |
| **Archi Draft Worker API** | `8787` | `http://localhost:8787` | `worker/` | Cloudflare Wrangler / Miniflare |
| **PIXMINT Service** | `8788` | `http://127.0.0.1:8788` | PIXMINT service dir | Hono / Node.js AI Service |

---

## 3. Environment Variables & Compile-Time Flags

### A. Flutter Multiplatform Client (`lib/`)

The client consumes compile-time flags supplied via `--dart-define`:

| Flag | Expected Value | Default (when omitted) | File Reference | Description |
| :--- | :--- | :--- | :--- | :--- |
| `STAGING` | `true` | `false` | `false` | `lib/firebase_options.dart` | When `true`, selects `archi-draft-staging` Firebase configuration. When `false`, selects production `archi-draft`. |
| `API_URL` | Valid URL | `http://localhost:8787` (debug mode) | `lib/src/features/api/data/api_client.dart` | Base URL for Cloudflare Worker API. In release mode, must be an explicit HTTPS endpoint. |

> [!IMPORTANT]
> **Configuration Separation:**
> - `STAGING=true` strictly controls Firebase project selection for identity verification. It does **not** launch the Worker or verify user registration.
> - `API_URL` controls the HTTP API endpoint. **Do not confuse `API_URL` with `API_BASE_URL`.**

### B. Studio Admin Web Portal (`apps/admin-web/`)

Configured via environment variables and fallback defaults:

| Variable | Default Value | File Reference | Description |
| :--- | :--- | :--- | :--- |
| `NEXT_PUBLIC_WORKER_API_URL` | `http://localhost:8787` | `apps/admin-web/src/lib/api.ts` | Endpoint for Archi Draft Worker API |
| `NEXT_PUBLIC_PIXMINT_API_URL` | `http://127.0.0.1:8788` | `apps/admin-web/src/components/admin/api.ts` | Endpoint for PIXMINT AI Chatbot service |
| `NEXT_PUBLIC_FIREBASE_PROJECT_ID` | `archi-draft-staging` | `apps/admin-web/src/lib/firebase.ts` | Staging Firebase project ID |
| `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN` | `archi-draft-staging.firebaseapp.com` | `apps/admin-web/src/lib/firebase.ts` | Staging Firebase auth domain |

### C. Cloudflare Worker (`worker/wrangler.toml`)

| Environment | Environment Variable | D1 Binding (`DB`) | R2 Storage Binding (`STORAGE`) | Allowed Origins |
| :--- | :--- | :--- | :--- | :--- |
| **Local (Default)** | `ENVIRONMENT="development"` | `archi-draft-db-local` (Local SQLite) | `archi-draft-storage-local` | `http://localhost:3000,http://localhost:8787` |
| **Staging (`env.staging`)** | `ENVIRONMENT="staging"` | `archi-draft-db-staging` (Remote D1) | `archi-draft-storage-staging` | `https://admin-staging.draughtsmanstudio.com,http://localhost:3000` |
| **Production (`env.production`)** | `ENVIRONMENT="production"` | `archi-draft-db` (LOCKED) | `archi-draft-storage` (LOCKED) | Strictly locked; deployment prohibited |

---

## 4. Authoritative Startup Instructions (PowerShell)

Open separate terminals for each running service:

```powershell
# ── Terminal 1: Cloudflare Worker ───────────────────────────────────────────
Set-Location -Path "D:\PROJECT\Archidraft-integration-workspace\worker"
npm install
npx wrangler dev
# Starts on http://localhost:8787

# ── Terminal 2: PIXMINT Service ─────────────────────────────────────────────
# Start configured AI bot service listening on http://127.0.0.1:8788

# ── Terminal 3: Admin Web Portal ────────────────────────────────────────────
Set-Location -Path "D:\PROJECT\Archidraft-integration-workspace\apps\admin-web"
npm install
npm run dev
# Starts on http://localhost:3000

# ── Terminal 4: Flutter Web Multi-Persona Client ─────────────────────────────
Set-Location -Path "D:\PROJECT\Archidraft-integration-workspace"
flutter pub get
& "C:\flutter\flutter\bin\flutter.bat" run -d web-server --web-port=8080 --dart-define=STAGING=true --dart-define=API_URL=http://localhost:8787
# Starts on http://localhost:8080
```

> [!WARNING]
> **Remote Staging Warning:**
> Running `npx wrangler dev --env staging --remote --port 8787` accesses live Cloudflare remote D1 and R2 resources. Never run `--remote` as an offline command without coordination.

---

## 5. Security & Credentials Protection

- **No Secrets in Version Control:** Never commit `.env`, `.env.local`, service account keys, Firebase private credentials, or live test passwords into Git.
- **Test Credentials:** Staging credentials for the 8 test personas (2 Admin, 2 Engineer, 2 Draughtsman, 2 Student) are held in the private owner reference file and must be requested securely from the project owner.
