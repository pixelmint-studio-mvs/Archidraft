# ARCHI DRAFT STUDIO — WORKSPACE AGENT RULES

## Custom Command: `/run-portals`

Whenever the user inputs `/run-portals` (or asks to run, start, or verify the local portals), immediately execute the **Archi Draft Local Portals** workflow:

### 1. Scope & Services
Verify or start the three development services:
- **Cloudflare Worker API**: `http://localhost:8787` (Health check: `http://localhost:8787/api/health`)
- **Admin Web Portal**: `http://localhost:3000/login` (Login page: `http://localhost:3000/login`)
- **Flutter Web Portal**: `http://localhost:8080` (Root: `http://localhost:8080`)

> Note: Do **not** start the Pixmint companion service on port `8788`.

### 2. Verification & Startup Procedure
1. **Branch & Workspace Safety Check**:
   - Verify workspace is `scratch/completed-integration` on branch `COMPLETED-INTERGRATION`.
   - Never switch branches, reset, clean, stash, discard, commit, push, or merge.
   - Preserve all local and uncommitted work.
2. **Port Detection**:
   - Check if ports `8787`, `3000`, and `8080` are listening (e.g. `netstat -ano | findstr ":8787 :3000 :8080"` or `Get-NetTCPConnection`).
   - Reuse healthy running services. Do not start duplicate processes.
3. **Start Missing Services (as persistent daemons)**:
   - Worker API (port 8787):
     ```powershell
     cd worker
     npx wrangler dev --env staging --remote --port 8787
     ```
   - Admin Web (port 3000):
     ```powershell
     cd apps/admin-web
     npm run dev
     ```
   - Flutter Web (port 8080):
     ```powershell
     flutter run -d web-server --web-port=8080 --dart-define=STAGING=true --dart-define=API_URL=http://localhost:8787
     ```
4. **Health Verification**:
   - Test each endpoint with a real HTTP request (`Invoke-WebRequest` / `curl`):
     - `http://localhost:8787/api/health`
     - `http://localhost:3000/login`
     - `http://localhost:8080`
   - If a service fails to respond or crashes, report the exact error and log snippet.
5. **Configuration Integrity**:
   - Verify Admin portal uses `NEXT_PUBLIC_WORKER_API_URL=http://localhost:8787` and staging Firebase.
   - Verify Flutter portal uses `--dart-define=STAGING=true` and `--dart-define=API_URL=http://localhost:8787`.

### 3. Required Response Dashboard Format
Always print the exact status dashboard:

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

### 4. Mandatory Safety Rules
- **NEVER** run `wrangler deploy`.
- **NEVER** apply remote database migrations (`wrangler d1 migrations apply --remote`).
- **NEVER** modify or touch production Cloudflare, Firebase, or infrastructure resources.
- **NEVER** switch branches, stash, discard, reset, clean, commit, push, or merge during portal checks.
- **NEVER** expose credentials, tokens, API keys, or `.env` file contents.
- **NEVER** modify or start Pixmint Bot code or its companion service (port 8788).
- **NEVER** disable authentication, legal gates, CORS, or security controls to make a service appear healthy.
