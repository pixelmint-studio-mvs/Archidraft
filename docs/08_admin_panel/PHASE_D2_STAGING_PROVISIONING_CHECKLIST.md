# Archi Draft — Phase D.2: Staging Provisioning Preflight & Operator Checklist

**Document Version:** 1.0.0  
**Audit & Preflight Date:** October 23, 2026  
**Integration Branch:** `COMPLETED-INTERGRATION`  
**Base Checkpoint Commit:** `90a2b3b36d83d776d1f1ee6914759df5af89deb5`  
**Audit Context:** Isolated Integration Worktree (`scratch/completed-integration`)  
**Main Workspace Status:** `feature/admin-panel-complete` (`8ea5d4c5`) is completely untouched and preserved  
**Status:** **READY FOR OPERATOR PROVISIONING** (Local code, guardrails, and configuration audited; remote cloud execution blocked awaiting operator input)

---

## 1. Safety and Workspace Boundary Verification

Prior to conducting this Phase D.2 preflight audit, all safety boundaries were verified:

1. **Git Branch & HEAD:**
   - Active branch: `COMPLETED-INTERGRATION`
   - Active commit: `90a2b3b36d83d776d1f1ee6914759df5af89deb5`
   - Remote tracking: `origin/COMPLETED-INTERGRATION` (2 commits ahead, no unapproved pushes)
2. **Workspace Isolation:**
   - Main workspace at `c:\Users\inaam\.gemini\antigravity-ide\scratch\Archidraft` (`feature/admin-panel-complete`) has **zero** modifications from this task.
   - All Phase D.1 remediation changes and Phase D.2 preflight updates reside strictly within `scratch/completed-integration`.
3. **Execution Guardrails:**
   - **Zero** git commits created.
   - **Zero** git pushes or merges performed.
   - **Zero** remote Cloudflare Workers deployed.
   - **Zero** remote Cloudflare D1 migrations applied.
   - **Zero** remote Cloudflare resources created or deleted.
   - **Zero** credentials, secret keys, or `.env` contents exposed or committed.
   - **Zero** modifications to the frozen financial scope (`/financials` remains read-only, mutations return `501 FEATURE_FROZEN`).
   - **Zero** bypassing of the mandatory legal consent gate (`assertTermsAccepted` remains active).

---

## 2. Verified Facts versus Assumptions

A strict audit boundary requires separating what is proven from existing repository evidence from what is an assumption or placeholder:

### A. Verified Facts (Backed by Code and Configuration)
1. **Cloudflare Account ID:** `06fbb6f8b2e1e65612347252ea10574c` is the authoritative Cloudflare account declared in `worker/wrangler.toml`.
2. **Production D1 Database:** The production D1 database is `archi-draft-db` with real UUID `af8d3312-5f6e-46ce-bcc1-dfa91e484cc0`.
3. **Production R2 Bucket:** The production R2 bucket is `archi-draft-storage`.
4. **Production Firebase Project:** The production Firebase project is `archi-draft` (Web App ID: `1:471564030203:web:bb8fc985704d4d22e4e05e`, Android App ID: `1:471564030203:android:80a988e5a6c0be41e4e05e`).
5. **Workers.dev Subdomain:** Production Worker URL reference in `apps/admin-web/.env.example` points to `https://archi-draft-worker.imserratex.workers.dev`.
6. **Production Web Deployment:** Production Admin Web URL is `https://archi-draft.vercel.app` (and custom domain `https://admin.draughtsmanstudio.com`).
7. **Production CORS Allowlist:** Statically locks allowed origins to `https://admin.draughtsmanstudio.com` and `https://archi-draft.vercel.app`. Localhost is strictly rejected in production.
8. **Mobile Release API URL:** `ApiClient.resolveBaseUrl()` strictly requires `--dart-define=API_URL=https://...`, failing fast at application boot (`lib/main.dart`) if missing, non-HTTPS, or pointing to localhost.
9. **D1 Migration Sequence:** 20 migrations (`0001` through `0020`) verified forward-only, tested sequentially on disposable SQLite/D1 emulation with 100% pass rate.
10. **Preflight Guard:** `worker/scripts/preflight_guard.mjs` is verified to fail closed with exit code 1 if `STAGING_D1_DATABASE_ID_PLACEHOLDER` is present or if staging and production resource IDs collide.

### B. Assumptions & Unconfirmed Items (Require Operator Provisioning)
1. **Staging D1 Database:** `archi-draft-db-staging` has **not** been created yet on Cloudflare. The database ID in `wrangler.toml` is currently `STAGING_D1_DATABASE_ID_PLACEHOLDER`.
2. **Staging R2 Storage Bucket:** `archi-draft-storage-staging` has **not** been created yet on Cloudflare.
3. **Staging Worker Deployment:** `archi-draft-worker-staging` has **not** been deployed yet.
4. **Staging Custom Domain:** `https://admin-staging.draughtsmanstudio.com` is a proposed domain and has **not** been verified in DNS or Vercel.
5. **Staging Firebase Project:** `archi-draft-staging` is declared in `wrangler.toml` but has **not** been registered in the Firebase Console yet.
6. **Staging Test Accounts:** No dedicated staging test accounts exist yet in Firebase.
7. **Official Legal Text:** Official, legally approved Terms & Conditions and Privacy Policy markdown content has **not** been provided.

---

## 3. Environment & Resource Matrix

| Component | Local Development / Emulation | Isolated Staging Environment | Locked Production Environment |
| :--- | :--- | :--- | :--- |
| **Worker Environment** | Default (unnamed / local) | `[env.staging]` | `[env.production]` |
| **Worker Service Name** | `archi-draft-worker` | `archi-draft-worker-staging` | `archi-draft-worker-production` |
| **Worker API URL** | `http://localhost:8787` | `https://archi-draft-worker-staging.<account>.workers.dev` *(Unconfirmed)* | `https://archi-draft-worker.imserratex.workers.dev` |
| **D1 Database Name** | `archi-draft-db-local` | `archi-draft-db-staging` | `archi-draft-db` |
| **D1 Database ID** | `local-d1-emulation-id` | `STAGING_D1_DATABASE_ID_PLACEHOLDER` *(Must be provisioned)* | `af8d3312-5f6e-46ce-bcc1-dfa91e484cc0` |
| **R2 Bucket Name** | `archi-draft-storage-local` | `archi-draft-storage-staging` *(Must be provisioned)* | `archi-draft-storage` |
| **Runtime Env Var** | `ENVIRONMENT = "development"` | `ENVIRONMENT = "staging"` | `ENVIRONMENT = "production"` |
| **Firebase Project ID** | `archi-draft` (Mocked in tests) | `archi-draft-staging` *(Must be created)* | `archi-draft` |
| **Admin Web Base URL** | `http://localhost:3000` | `https://archi-draft-staging.vercel.app` *(Unconfirmed)* | `https://archi-draft.vercel.app` / `https://admin.draughtsmanstudio.com` |
| **Allowed CORS Origins** | `http://localhost:3000`<br>`http://localhost:8787` | Dynamic via `ALLOWED_ORIGINS` + Localhost permitted | `https://admin.draughtsmanstudio.com`<br>`https://archi-draft.vercel.app` (Localhost blocked) |
| **Mobile API Config** | Defaults to `http://localhost:8787` | `--dart-define=API_URL=https://archi-draft-worker-staging...` | `--dart-define=API_URL=https://api.draughtsmanstudio.com` |
| **Secrets Storage** | Local environment / test runner | Cloudflare Dashboard & Wrangler Secrets | Cloudflare Dashboard & Wrangler Secrets |

---

## 4. Required Operator Input Checklist

The authorized operator must supply and verify the following values before remote provisioning:

| # | Required Input Item | Purpose | Current Status | Responsible Owner | Secure Entry Location |
| :-: | :--- | :--- | :-: | :--- | :--- |
| **1** | **Cloudflare Account Access** | Permission to create D1, R2, and deploy Workers | Verified (`06fbb6f8...`) | Cloudflare Operator | Cloudflare Dashboard / Wrangler CLI |
| **2** | **Staging D1 Database UUID** | Real D1 ID for `archi-draft-db-staging` | **MISSING** (`STAGING_D1_DATABASE_ID_PLACEHOLDER`) | Cloudflare Operator | `worker/wrangler.toml` under `[[env.staging.d1_databases]]` |
| **3** | **Staging R2 Bucket** | Isolated storage bucket for CAD files | **MISSING** (`archi-draft-storage-staging` uncreated) | Cloudflare Operator | Cloudflare Dashboard / Wrangler CLI |
| **4** | **Staging Firebase Project** | Distinct auth realm for staging test accounts | **MISSING** (`archi-draft-staging` uncreated) | Firebase Admin | Firebase Console (`console.firebase.google.com`) |
| **5** | **Vercel Staging Deployment** | Admin Web staging preview URL | **MISSING** (Unlinked) | Vercel Admin | Vercel Project Settings → Environment Variables |
| **6** | **Staging CORS Allowlist** | Permitted origins for Staging Admin | Template provided | Cloudflare Operator | `worker/wrangler.toml` under `[env.staging.vars].ALLOWED_ORIGINS` |
| **7** | **Official Legal Documents** | Legally binding Terms & Conditions and Privacy Policy | **MISSING** (Blocked on content owner) | Legal / Authorized Product Owner | Secure storage / Authorized D1 ingestion script |
| **8** | **Staging Test Accounts** | Dedicated test credentials for 4 roles | **MISSING** | QA / Lead Engineer | Staging Firebase Authentication |

> [!CAUTION]
> **CRITICAL SECURITY RULE:** Never paste passwords, private keys, Firebase service account keys, or `.env` files into chat or commit them to Git. Enter all sensitive secrets directly into the Cloudflare Dashboard, Wrangler secrets store (`wrangler secret put`), or Vercel Environment Variables console.

---

## 5. Exact Staging Provisioning Instructions (NOT EXECUTED)

The following sequence details the exact commands the authorized operator must execute.

> [!WARNING]
> **READ-ONLY AUDIT NOTICE:** The remote-mutating commands below have **NOT** been executed during this audit. They are documented here for the authorized operator.

### Phase 1: Local Pre-flight Verification (Safe / Read-Only)
```powershell
# In scratch/completed-integration:
# 1. Verify working branch and clean safety status
git status
git log -n 1

# 2. Run Worker test suite (validates CORS, route contracts, E2E logic)
npm --prefix worker test

# 3. Verify fail-closed preflight guard (MUST exit 1 on placeholder)
npm --prefix worker run preflight:staging

# 4. Verify Admin Web production build
npm --prefix apps/admin-web run build

# 5. Verify Flutter release build validation
flutter test test/features/api/data/api_client_test.dart --no-pub
```

### Phase 2: Remote Staging Resource Creation (OPERATOR ACTION — NOT EXECUTED)
```powershell
# In worker/:
# 1. Authenticate with Cloudflare
npx wrangler whoami

# 2. Create the dedicated Staging D1 Database
npx wrangler d1 create archi-draft-db-staging
# Output will display:
# database_id = "<NEW_STAGING_UUID>"

# 3. Create the dedicated Staging R2 Storage Bucket
npx wrangler r2 bucket create archi-draft-storage-staging
```

### Phase 3: Configuration Update (OPERATOR ACTION — NOT EXECUTED)
1. Open `worker/wrangler.toml`.
2. Locate line 34:
   ```toml
   database_id = "STAGING_D1_DATABASE_ID_PLACEHOLDER"
   ```
3. Replace `STAGING_D1_DATABASE_ID_PLACEHOLDER` with the `<NEW_STAGING_UUID>` returned from step 2.
4. If a custom staging domain is assigned (e.g. `https://admin-staging.draughtsmanstudio.com`), update `ALLOWED_ORIGINS` under `[env.staging.vars]`.

### Phase 4: Re-run Preflight Guard (Safe / Read-Only)
```powershell
# In worker/:
# The guard should now print [PREFLIGHT PASSED] because the real UUID is present and distinct from production
npm run preflight:staging
```

### Phase 5: Remote Staging Migration (OPERATOR ACTION — NOT EXECUTED)
```powershell
# In worker/:
# Apply migrations 0001 through 0020 to REMOTE STAGING ONLY
# The --env staging flag guarantees production is never targeted
npx wrangler d1 migrations apply archi-draft-db-staging --env staging --remote
```

### Phase 6: Remote Staging Worker Deployment (OPERATOR ACTION — NOT EXECUTED)
```powershell
# In worker/:
# Deploy worker to staging environment
npx wrangler deploy --env staging
```

### Phase 7: Staging Health Verification (Safe / Read-Only)
```powershell
# Check health of deployed staging worker
curl -I https://archi-draft-worker-staging.<account>.workers.dev/api/health
```

### Phase 8: Vercel Staging Environment Setup (OPERATOR ACTION — NOT EXECUTED)
In the Vercel Dashboard for the Admin Web project, set the following environment variables for **Preview / Staging** environments:
- `NEXT_PUBLIC_WORKER_API_URL`: `https://archi-draft-worker-staging.<account>.workers.dev`
- `NEXT_PUBLIC_FIREBASE_PROJECT_ID`: `archi-draft-staging`
- `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN`: `archi-draft-staging.firebaseapp.com`
- `NEXT_PUBLIC_FIREBASE_API_KEY`: *(Staging Web API Key from Firebase Console)*
- `NEXT_PUBLIC_FIREBASE_APP_ID`: *(Staging Web App ID from Firebase Console)*

### Phase 9: Mobile Staging Builds (OPERATOR ACTION — NOT EXECUTED)
Build mobile portals using the staging API URL:
```powershell
# Engineer Portal
flutter build apk --release --dart-define=API_URL=https://archi-draft-worker-staging.<account>.workers.dev

# Draughtsman Portal
flutter build apk --release --dart-define=API_URL=https://archi-draft-worker-staging.<account>.workers.dev

# Student Portal
flutter build apk --release --dart-define=API_URL=https://archi-draft-worker-staging.<account>.workers.dev
```

---

## 6. Preflight Guard & Rollback Strategy

### Preflight Guardrail Rules
1. **Target Identification:** `worker/scripts/preflight_guard.mjs` must inspect `[env.<target>]` before every deployment or migration.
2. **Fail-Closed on Placeholders:** Any string matching `*PLACEHOLDER*` immediately terminates execution.
3. **Collision Detection:** If `staging.database_id == production.database_id` or `staging.bucket_name == production.bucket_name`, execution aborts with a critical safety violation.

### Disaster Recovery & Rollback Plan
- **Staging D1 Rollback:** Because staging D1 is completely disposable and contains zero customer data, if a staging migration fails:
  ```powershell
  npx wrangler d1 delete archi-draft-db-staging
  npx wrangler d1 create archi-draft-db-staging
  ```
- **Staging Worker Rollback:** If a staging Worker build exhibits errors, rollback to the previous deployment via Cloudflare Dashboard or re-deploy the known checkpoint.
- **Production Isolation:** Under no circumstances does a failure or rollback in staging impact the production database `af8d3312-5f6e-46ce-bcc1-dfa91e484cc0` or production Worker `archi-draft-worker`.

---

## 7. Legal Gate and Content Dependency

- **Legal Gate Status:** `assertTermsAccepted` and `assertTermsAcceptedOnboarding` remain active and non-negotiable.
- **Staging Test Isolation:** In automated test runs (`worker/test/`), synthetic legal documents (`doc-terms-v1`) are used on disposable in-memory SQLite tables.
- **Live Staging Block:** For live cross-portal testing with real Firebase authentication, an authorized content owner must supply official or explicitly approved staging Terms & Conditions text.
- **Production Block:** Production release is strictly **BLOCKED** until official, legally vetted terms are approved and deployed.

---

## 8. Remaining Risks and Blockers

| Risk ID | Risk / Blocker Summary | Severity | Mitigation / Next Step |
| :---: | :--- | :---: | :--- |
| **RSK-01** | Cloudflare staging D1 and R2 not yet created | **High** | Operator must run Phase 2 commands and update `wrangler.toml`. |
| **RSK-02** | Staging Firebase project not yet registered | **Medium** | Operator creates Firebase staging project to avoid user pollution in production. |
| **RSK-03** | Staging custom domain DNS unverified | **Low** | Use default Vercel preview domain (`*.vercel.app`) and Workers.dev subdomain until custom domain DNS is mapped. |
| **RSK-04** | Official legal text signoff pending | **High** | Product/Legal owner supplies approved markdown content. |

---

## 9. Final Decision

### Decision: **READY FOR OPERATOR PROVISIONING**

**Summary of Decision:**
- All local code remediation (Phase A) is complete, tested, and verified.
- The preflight guardrail (Phase B) successfully protects against accidental production pollution and blocks deployment until real staging resources are provisioned.
- The cross-portal E2E integration test suite (Phase C) passes 100% (259/259 tests).
- All safety constraints (frozen financials, legal gate, git safety) have been strictly preserved.
- The repository is in an optimal, safe state for an authorized operator to execute the remote Cloudflare provisioning steps detailed in Section 5.
