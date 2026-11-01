# ARCHI DRAFT — CLOUDFLARE PAGES STAGING DEPLOYMENT GUIDE

**Application Name:** ArchiDraft App  
**Hosting Target:** Cloudflare Pages  
**Cloudflare Pages Project:** `archidraft-app`  
**Live Public Staging URL:** `https://archidraft-app.pages.dev`  
**Current Deployment Version:** `https://9ba115dd.archidraft-app.pages.dev`  
**Last Deployed:** October 31, 2026 (23:56 IST / 18:26 UTC)  
**Deployment Status:** **ACTIVE & VERIFIED**

---

## 1. Staging Infrastructure Specification

The staging application is completely decoupled from production infrastructure.

| Component | Staging Specification | Production Specification (LOCKED) |
|---|---|---|
| **Web Frontend** | Cloudflare Pages (`archidraft-app`) | Proposed apex domain (`archidraft.app`) |
| **Public Staging URL** | `https://archidraft-app.pages.dev` | Proposed `https://archidraft.app` |
| **Worker Service** | `archi-draft-worker-staging` | `archi-draft-worker` |
| **Backend API Endpoint** | `https://archi-draft-worker-staging.imserratex.workers.dev` | `https://api.archidraft.app` |
| **D1 Database** | `archi-draft-db-staging` (`065d76ba-eca5-4cc1-ba39-51281b79d6b4`) | `archi-draft-db` (`af8d3312-5f6e-46ce-bcc1-dfa91e484cc0`) |
| **R2 Storage Bucket** | `archi-draft-storage-staging` | `archi-draft-storage` |
| **Firebase Project** | `archi-draft-staging` (ID: `528293938258`) | `archi-draft` (ID: `471564030203`) |
| **Admin Portal** | Preserved on Vercel (`admin-web-eight-wine.vercel.app`) | Preserved on Vercel |

> [!IMPORTANT]
> The staging application connects strictly to staging D1 database `065d76ba-eca5-4cc1-ba39-51281b79d6b4` and staging R2 bucket `archi-draft-storage-staging`. Zero production data is referenced or mutated.

---

## 2. Web Hosting Configuration

### A. SPA Client-Side Routing Fallback (`web/_redirects`)
Cloudflare Pages serves files statically from the deployment directory. To support Flutter Web client-side GoRouter navigation on direct URLs (e.g., `/verify`, `/engineer`, `/draughtsman`, `/student`), the following rule is configured in `web/_redirects`:

```text
/*    /index.html   200
```

### B. Conservative Caching Policy (`web/_headers`)
Because Flutter Web builds generate unhashed filenames (`main.dart.js`, `flutter_bootstrap.js`, `canvaskit.wasm`), long-lived immutable caching is unsafe. The following conservative cache-control policy is enforced via `web/_headers`:

```text
# Entrypoints and Bootstrap - Never cache to guarantee instant updates
/index.html
  Cache-Control: no-cache, no-store, must-revalidate
/flutter_bootstrap.js
  Cache-Control: no-cache, no-store, must-revalidate
/flutter_service_worker.js
  Cache-Control: no-cache, no-store, must-revalidate
/version.json
  Cache-Control: no-cache, no-store, must-revalidate
/manifest.json
  Cache-Control: no-cache, no-store, must-revalidate

# Compiled application bundle - Revalidate with ETag on each request
/main.dart.js
  Cache-Control: no-cache, must-revalidate

# Static application assets, icons, fonts, models - Conservative 1 hour cache
/assets/*
  Cache-Control: public, max-age=3600, must-revalidate
/icons/*
  Cache-Control: public, max-age=3600, must-revalidate
/models/*
  Cache-Control: public, max-age=3600, must-revalidate

# CanvasKit WebAssembly engine binaries - 1 day cache (tied to Flutter engine)
/canvaskit/*
  Cache-Control: public, max-age=86400, stale-while-revalidate=86400
```

### C. Worker CORS Allowlist (`worker/wrangler.toml`)
The staging Worker permits cross-origin requests from the staging Pages application:

```toml
[env.staging.vars]
ENVIRONMENT = "staging"
FIREBASE_PROJECT_ID = "archi-draft-staging"
ALLOWED_ORIGINS = "https://www.draughtsmanstudio.com,https://draughtsmanstudio.com,https://admin-staging.draughtsmanstudio.com,https://archi-draft-staging.vercel.app,http://localhost:3000,https://archidraft-app.pages.dev"
```

### D. Firebase Staging Authorized Domains
In the Firebase Console under **Authentication > Settings > Authorized Domains** for project `archi-draft-staging`:
- `archidraft-app.pages.dev`

---

## 3. Step-by-Step Staging Build & Redeployment Procedure

When redeploying the staging application after making frontend or backend updates, follow these exact steps:

### Step 1: Run Preflight Isolation Checks
```powershell
Set-Location -Path "D:\PROJECT\Archidraft-integration-workspace\worker"
npm run preflight:staging
Set-Location -Path "D:\PROJECT\Archidraft-integration-workspace"
```

### Step 2: Validate Static Analysis and Tests
```powershell
& "C:\flutter\flutter\bin\flutter.bat" analyze lib/
& "C:\flutter\flutter\bin\flutter.bat" test test/features/engineer/presentation/engineer_activity_screen_test.dart test/unit/activity_log_test.dart
```

### Step 3: Compile Optimized Flutter Web Release
```powershell
& "C:\flutter\flutter\bin\flutter.bat" build web --release `
  --dart-define=STAGING=true `
  --dart-define=API_URL=https://archi-draft-worker-staging.imserratex.workers.dev
```

### Step 4: Ensure Hosting Configuration Files are in `build/web/`
```powershell
Copy-Item -Force web\_redirects build\web\_redirects
Copy-Item -Force web\_headers build\web\_headers
```

### Step 5: Deploy to Cloudflare Pages
```powershell
$env:CLOUDFLARE_ACCOUNT_ID = "06fbb6f8b2e1e65612347252ea10574c"
npx --prefix worker wrangler pages deploy build/web --project-name=archidraft-app --branch=staging
```

### Step 6: Deploy Staging Worker (if Worker routes or CORS changed)
```powershell
npx --prefix worker wrangler deploy --config worker/wrangler.toml --env staging
```

---

## 4. Post-Deployment Verification & Smoke Testing

### A. Automatic CLI Checks
```powershell
# 1. Verify root returns HTTP 200 and custom headers
curl.exe -s -I "https://archidraft-app.pages.dev"

# 2. Verify SPA deep-link routing on /verify returns HTTP 200
curl.exe -s -I "https://archidraft-app.pages.dev/verify"

# 3. Verify conservative caching on bootstrap JS
curl.exe -s -I "https://archidraft-app.pages.dev/flutter_bootstrap.js"

# 4. Verify staging Worker CORS preflight
curl.exe -s -I -H "Origin: https://archidraft-app.pages.dev" "https://archi-draft-worker-staging.imserratex.workers.dev/api/public/credentials/verify/test-token"
```

### B. Manual Role Verification
Test all three primary roles using the authorized staging seed accounts (available in `team/TEAM_TESTING_CREDENTIALS.md`):

1. **Engineer (`zedsuo125+engineer@gmail.com`):**
   - Log in via `https://archidraft-app.pages.dev`.
   - Access Engineer Dashboard, project creation, DWG/PDF file attachments, and Activity Feed.
   - Verify distinct timestamps on activity log entries.
2. **Draughtsman (`zedsuo125+draughtsman@gmail.com`):**
   - Access assigned studio projects, workspace drafts, and file downloads.
3. **Student (`zedsuo125+student@gmail.com`):**
   - Access CAD curriculum modules, practical drafting tasks, and digital portfolio.
4. **Public Certificate Verification:**
   - Navigate to `https://archidraft-app.pages.dev/verify`.
   - Query a valid qualification token; verify badge rendering.
5. **Admin Portal Safety:**
   - Verify `https://admin-web-eight-wine.vercel.app/` remains fully operational on Vercel without interference.

---

## 5. Instant Rollback Procedure

If a deployed staging build contains regressions or issues:

### Method 1: Via Wrangler CLI
```powershell
$env:CLOUDFLARE_ACCOUNT_ID = "06fbb6f8b2e1e65612347252ea10574c"
npx --prefix worker wrangler pages deployment list --project-name=archidraft-app
```
Identify the previous working deployment and redeploy its assets.

### Method 2: Via Cloudflare Dashboard (< 2 seconds)
1. Navigate to Cloudflare Dashboard > **Workers & Pages** > `archidraft-app`.
2. Under **Deployments**, locate the previous successful deployment.
3. Click the three dots (`...`) next to that deployment and select **Rollback to this deployment**.
4. Cloudflare immediately switches the `archidraft-app.pages.dev` anycast routing to the prior build.

