---
name: run-portals
description: Starts or verifies the local Archi Draft development portals (Cloudflare Worker API on port 8787, Next.js Admin Web on port 3000, Flutter Web on port 8080) and outputs a status dashboard whenever the user invokes /run-portals or asks to run/verify development portals.
---

# Run Portals Skill (`/run-portals`)

Use this skill when the user types `/run-portals` or asks to start, run, or verify the local development services for Archi Draft Studio.

## Target Services and Endpoints

| Service | Port | Endpoint URL | Health Check / Test Route | Purpose |
|---|---|---|---|---|
| **Cloudflare Worker API** | `8787` | `http://localhost:8787` | `http://localhost:8787/api/health` | Backend API (Hono, D1 staging, R2 staging) |
| **Admin Web Portal** | `3000` | `http://localhost:3000/login` | `http://localhost:3000/login` | Studio Admin Web Application |
| **Flutter Web Portal** | `8080` | `http://localhost:8080` | `http://localhost:8080` | Engineer, Draughtsman, Student portals |

> [!WARNING]
> Do **NOT** start the Pixmint companion service on port `8788`. That service is owned by a different contributor.

## Step-by-Step Execution Runbook

### Step 1: Pre-flight Verification
1. Ensure the workspace is `scratch/completed-integration` on branch `COMPLETED-INTERGRATION`.
2. Inspect `git status --short`. Do not switch branches, reset, clean, stash, discard, commit, push, or merge.
3. Preserve all uncommitted files.

### Step 2: Port & Process Detection
Check if ports `8787`, `3000`, and `8080` are listening:
```powershell
netstat -ano | findstr ":8787 :3000 :8080"
```
- If a service is already listening and returns HTTP 200, reuse it.
- Do not spawn duplicate processes for already running healthy services.

### Step 3: Start Inactive Services
Launch any missing service in a persistent background task (`IsDaemon: true`):

1. **Worker API (Port 8787)**:
   ```powershell
   cd worker
   npx wrangler dev --env staging --remote --port 8787
   ```
2. **Admin Web Portal (Port 3000)**:
   ```powershell
   cd apps/admin-web
   npm run dev
   ```
3. **Flutter Web Portal (Port 8080)**:
   ```powershell
   flutter run -d web-server --web-port=8080 --dart-define=STAGING=true --dart-define=API_URL=http://localhost:8787
   ```

### Step 4: Health Verification
Verify that each service responds to HTTP requests:
```powershell
# Worker health
Invoke-WebRequest -Uri "http://localhost:8787/api/health" -UseBasicParsing -TimeoutSec 5

# Admin Web portal
Invoke-WebRequest -Uri "http://localhost:3000/login" -UseBasicParsing -TimeoutSec 5

# Flutter Web portal
Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing -TimeoutSec 5
```

### Step 5: Configuration Check
- Confirm `apps/admin-web/.env.local` sets `NEXT_PUBLIC_WORKER_API_URL=http://localhost:8787`.
- Confirm Flutter is invoked with `--dart-define=STAGING=true` (which binds Firebase to `archi-draft-staging`).
- Never expose API keys or secrets in output.

### Step 6: Output Dashboard
Display the concise status dashboard required by `/run-portals`:

```markdown
**Archi Draft Studio — Local Portals**

- Worker API: [http://localhost:8787](http://localhost:8787) — <RUNNING|STOPPED|ERROR>
- Admin portal: [http://localhost:3000/login](http://localhost:3000/login) — <RUNNING|STOPPED|ERROR>
- Flutter portal: [http://localhost:8080](http://localhost:8080) — <RUNNING|STOPPED|ERROR>
- Current Git branch: `<branch>` (<clean|dirty> working tree)
- Services already running: `<none | list>`
- Services started: `<none | list>`
- Errors / warnings: `<none | details>`
- Manual startup commands:
  - Worker: `cd worker && npx wrangler dev --env staging --remote --port 8787`
  - Admin: `cd apps/admin-web && npm run dev`
  - Flutter: `flutter run -d web-server --web-port=8080 --dart-define=STAGING=true --dart-define=API_URL=http://localhost:8787`
```

## Strict Safety Guardrails
- **NO** `wrangler deploy` under any circumstances.
- **NO** remote database migrations (`wrangler d1 migrations apply --remote`).
- **NO** changes to production infrastructure or production variables.
- **NO** branch switching, stashing, resetting, cleaning, committing, pushing, or merging.
- **NO** printing or leaking API keys, tokens, or raw `.env` contents.
- **NO** starting port 8788 (Pixmint companion service).
- **NO** disabling authentication, legal gates, CORS, or security controls.
