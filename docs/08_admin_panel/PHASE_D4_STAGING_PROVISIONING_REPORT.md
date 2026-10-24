# Archi Draft — Phase D.4: Isolated Staging Resources Provisioning Report

**Execution Date:** October 23, 2026  
**Integration Branch:** `COMPLETED-INTERGRATION`  
**Base Checkpoint Commit:** `90a2b3b36d83d776d1f1ee6914759df5af89deb5`  
**Execution Context:** Isolated Worktree (`scratch/completed-integration`)  
**Main Workspace Status:** `feature/admin-panel-complete` (`8ea5d4c5`) completely untouched and preserved  
**Status:** **STAGING INFRASTRUCTURE PROVISIONED & VERIFIED — PENDING MIGRATIONS & DEPLOYMENT AUTHORIZATION**  

---

## 1. Executive Summary

In accordance with owner authorization and Phase D.4 safety mandates, the dedicated, isolated staging infrastructure for **Archi Draft** has been successfully provisioned.

1. **Cloudflare D1 Staging Database:** Created dedicated database `archi-draft-db-staging` with UUID `065d76ba-eca5-4cc1-ba39-51281b79d6b4`. Production database (`af8d3312-...`) remains untouched and isolated.
2. **Cloudflare R2 Staging Bucket:** Created dedicated bucket `archi-draft-storage-staging`. Production bucket (`archi-draft-storage`) remains untouched and isolated.
3. **Local Staging Binding:** Updated `worker/wrangler.toml` under `[[env.staging.d1_databases]]` with the real staging database UUID. Production bindings were not altered.
4. **Preflight Guard Verification:** `npm run preflight:staging` and `npm run preflight:prod` executed and passed cleanly, confirming complete cryptographic and namespace isolation between staging and production.
5. **Firebase Staging Project:** Successfully created isolated Firebase project `archi-draft-staging` (Project Name: `Archi Draft Staging`) via authenticated CLI session.
6. **Strict Prohibitions Upheld:** Zero remote migrations applied, zero Worker deployments triggered, zero production configurations modified, legal drafts untouched, payments frozen (`501 FEATURE_FROZEN`), and zero git commits/pushes performed.

---

## 2. Safety & Workspace Invariants Audit

Before and after provisioning operations, the local repository and workspace invariants were strictly verified:

| Check | Expected | Actual Evidence | Status |
| :--- | :--- | :--- | :---: |
| **Git Branch** | `COMPLETED-INTERGRATION` | `On branch COMPLETED-INTERGRATION` | **PASS** |
| **Commit HEAD** | `90a2b3b3` | `90a2b3b36d83d776d1f1ee6914759df5af89deb5` | **PASS** |
| **Worktree Isolation** | `scratch/completed-integration` | Confined entirely to isolated integration directory | **PASS** |
| **Main Admin Workspace** | `feature/admin-panel-complete` | Untouched, pristine, all uncommitted changes preserved | **PASS** |
| **Remote Production DB** | `af8d3312-5f6e-46ce-bcc1-dfa91e484cc0` | Zero alterations, zero migrations applied | **PASS** |
| **Remote Production Storage** | `archi-draft-storage` | Zero alterations, production files intact | **PASS** |
| **Remote Production Firebase** | `archi-draft` | Zero alterations, production user base untouched | **PASS** |
| **Worker Deployments** | None | `wrangler deploy` was NOT run | **PASS** |
| **Remote D1 Migrations** | None | `wrangler d1 migrations apply ... --remote` was NOT run | **PASS** |
| **Financial Scope** | Frozen | `/financials` mutations return `501 FEATURE_FROZEN` | **PASS** |
| **Legal Terms Gate** | Active & Unseeded | `assertTermsAccepted` active; draft placeholders preserved | **PASS** |
| **Git Commit / Push** | None | Zero commits created, zero pushes to origin | **PASS** |

---

## 3. Cloudflare Staging Resource Provisioning (Live Verified)

### 3.1 D1 Database Provisioning
- **Target Account:** `06fbb6f8b2e1e65612347252ea10574c` (authoritative account matching `worker/wrangler.toml`).
- **Resource Name:** `archi-draft-db-staging`
- **Assigned Database UUID:** `065d76ba-eca5-4cc1-ba39-51281b79d6b4`
- **Region:** `APAC`
- **Creation Timestamp:** `2026-10-23T08:36:48.819Z`
- **Current Table Count:** `0` (clean, zero migrations applied)

### 3.2 R2 Storage Bucket Provisioning
- **Target Account:** `06fbb6f8b2e1e65612347252ea10574c`
- **Bucket Name:** `archi-draft-storage-staging`
- **Creation Timestamp:** `2026-10-23T08:37:02.203Z`
- **Storage Class:** `Standard`

### 3.3 Live Read-Only Verification Output
Commands executed:
```bash
$env:CLOUDFLARE_ACCOUNT_ID="06fbb6f8b2e1e65612347252ea10574c"
npx wrangler d1 list
npx wrangler r2 bucket list
```

**Live D1 Verification Table:**
```
┌──────────────────────────────────────┬────────────────────────┬──────────────────────────┬────────────┬────────────┬───────────┬──────────────┐
│ uuid                                 │ name                   │ created_at               │ version    │ num_tables │ file_size │ jurisdiction │
├──────────────────────────────────────┼────────────────────────┼──────────────────────────┼────────────┼────────────┼───────────┼──────────────┤
│ 065d76ba-eca5-4cc1-ba39-51281b79d6b4 │ archi-draft-db-staging │ 2026-10-23T08:36:48.819Z │ production │ 0          │ 8192      │              │
├──────────────────────────────────────┼────────────────────────┼──────────────────────────┼────────────┼────────────┼───────────┼──────────────┤
│ af8d3312-5f6e-46ce-bcc1-dfa91e484cc0 │ archi-draft-db         │ 2026-09-16T15:59:01.158Z │ production │ 0          │ 184320    │              │
└──────────────────────────────────────┴────────────────────────┴──────────────────────────┴────────────┴────────────┴───────────┴──────────────┘
```

**Live R2 Verification Output:**
```
Listing buckets...
name:           archi-draft-storage
creation_date:  2026-09-16T16:28:03.611Z

name:           archi-draft-storage-staging
creation_date:  2026-10-23T08:37:02.203Z
```

Both resources were successfully provisioned and verified.

---

## 4. Production vs. Staging Separation Matrix

Cryptographic, storage, and identity isolation between production and staging is strictly enforced:

| Dimension | Production Environment | Staging Environment | Separation Status |
| :--- | :--- | :--- | :---: |
| **Worker Script Name** | `archi-draft-worker-production` | `archi-draft-worker-staging` | **ISOLATED** |
| **Cloudflare Account ID** | `06fbb6f8b2e1e65612347252ea10574c` | `06fbb6f8b2e1e65612347252ea10574c` | **SAME TENANT** |
| **D1 Database Name** | `archi-draft-db` | `archi-draft-db-staging` | **ISOLATED** |
| **D1 Database UUID** | `af8d3312-5f6e-46ce-bcc1-dfa91e484cc0` | `065d76ba-eca5-4cc1-ba39-51281b79d6b4` | **DISTINCT UUIDs** |
| **R2 Storage Bucket** | `archi-draft-storage` | `archi-draft-storage-staging` | **DISTINCT BUCKETS** |
| **Firebase Project ID** | `archi-draft` | `archi-draft-staging` | **DISTINCT PROJECTS** |
| **Runtime Environment Var** | `ENVIRONMENT = "production"` | `ENVIRONMENT = "staging"` | **ISOLATED** |
| **Allowed CORS Origins** | Production domain + Vercel prod | Preview Vercel + custom staging + localhost | **SEPARATED** |

---

## 5. Local Configuration Updates

Only `worker/wrangler.toml` was modified to bind the real staging D1 database UUID.

### Exact Diff (`git diff worker/wrangler.toml`):
```diff
@@ -32,7 +32,7 @@ ALLOWED_ORIGINS = "https://admin-staging.draughtsmanstudio.com,https://archi-dra
 [[env.staging.d1_databases]]
 binding = "DB"
 database_name = "archi-draft-db-staging"
-database_id = "STAGING_D1_DATABASE_ID_PLACEHOLDER"
+database_id = "065d76ba-eca5-4cc1-ba39-51281b79d6b4"
 
 [[env.staging.r2_buckets]]
 binding = "STORAGE"
```

The production block in `worker/wrangler.toml` was completely untouched:
```toml
[[env.production.d1_databases]]
binding = "DB"
database_name = "archi-draft-db"
database_id = "af8d3312-5f6e-46ce-bcc1-dfa91e484cc0"

[[env.production.r2_buckets]]
binding = "STORAGE"
bucket_name = "archi-draft-storage"
```

---

## 6. Preflight Guard & Local Validation Results

### 6.1 Preflight Guard Verification
Both preflight checks were executed in `worker/`:

1. **Staging Preflight Check:**
   ```bash
   $ npm run preflight:staging
   
   ====================================================
   ARCHIDRAFT WORKER PREFLIGHT GUARD: [STAGING]
   ====================================================
   Target Environment : staging
   Worker Name        : archi-draft-worker-staging
   D1 Database Name   : archi-draft-db-staging
   D1 Database ID     : 065d76ba-eca5-4cc1-ba39-51281b79d6b4
   R2 Bucket Name     : archi-draft-storage-staging
   Runtime Env Var    : staging
   Firebase Project   : archi-draft-staging
   Allowed Origins    : https://admin-staging.draughtsmanstudio.com,https://archi-draft-staging.vercel.app,http://localhost:3000
   ----------------------------------------------------
   [PREFLIGHT PASSED] Target environment verified and isolated.
   ====================================================
   ```
   **Exit Code:** `0` (SUCCESS)

2. **Production Preflight Check:**
   ```bash
   $ npm run preflight:prod
   
   ====================================================
   ARCHIDRAFT WORKER PREFLIGHT GUARD: [PRODUCTION]
   ====================================================
   Target Environment : production
   Worker Name        : archi-draft-worker-production
   D1 Database Name   : archi-draft-db
   D1 Database ID     : af8d3312-5f6e-46ce-bcc1-dfa91e484cc0
   R2 Bucket Name     : archi-draft-storage
   Runtime Env Var    : production
   Firebase Project   : archi-draft
   Allowed Origins    : https://admin.draughtsmanstudio.com,https://archi-draft.vercel.app
   ----------------------------------------------------
   [PREFLIGHT PASSED] Target environment verified and isolated.
   ====================================================
   ```
   **Exit Code:** `0` (SUCCESS)

### 6.2 Worker Unit & Integration Test Suite
```bash
$ npm test
...
ℹ tests 259
ℹ pass 259
ℹ fail 0
```
All 259 tests pass cleanly.

### 6.3 TypeScript Typecheck
```bash
$ npm run typecheck
> tsc --noEmit
```
0 errors detected.

---

## 7. Firebase Staging Project Status & Required Manual Steps

### 7.1 Staging Project Creation
- **Project ID:** `archi-draft-staging`
- **Project Display Name:** `Archi Draft Staging`
- **Creation Status:** Created successfully via `firebase projects:create archi-draft-staging --display-name "Archi Draft Staging" --non-interactive`.
- **Firebase Console URL:** `https://console.firebase.google.com/project/archi-draft-staging/overview`
- **Live Verification:** `firebase apps:list --project archi-draft-staging` succeeded and returned clean app table (`No apps found`).

### 7.2 Outstanding Manual Configuration Checklist (Firebase Console)
Before staging application traffic can be routed through `archi-draft-staging`, the following configurations must be completed by the project administrator in the Firebase Console:

1. **Authentication Provider Activation:**
   - Navigate to: `https://console.firebase.google.com/project/archi-draft-staging/authentication/providers`
   - Enable **Email/Password** sign-in method.
   - (Optional) Enable Google sign-in if needed for cross-portal OAuth.

2. **Application Registration:**
   - Navigate to: `Project Overview -> Project settings -> General -> Your apps`
   - Register **Web App** (for `apps/admin-web/` staging deployment). Record `apiKey`, `authDomain`, `projectId`, `appId`.
   - Register **Android App(s)** (for Engineer, Draughtsman, and Student Flutter portals). Use appropriate package names:
     - `com.archidraft.engineer`
     - `com.archidraft.draughtsman`
     - `com.archidraft.student`
   - Download the generated `google-services.json` and keep it staged only for staging build variants (never commit production Firebase secrets).

3. **Authorized Domains:**
   - In `Authentication -> Settings -> Authorized domains`, ensure the following domains are authorized:
     - `localhost`
     - `archi-draft-staging.vercel.app`
     - `admin-staging.draughtsmanstudio.com`

4. **Service Account / Admin SDK Credentials:**
   - In `Project settings -> Service accounts`, generate a staging service account key if backend custom-claims seeding or automated user generation is required.
   - **CRITICAL:** Never reuse the production service account private key or credentials in staging.

5. **Staging Test Accounts & Role Claims:**
   - In accordance with Phase D safety rules, **no users were created in this phase**.
   - A dedicated provisioning script or Firebase Admin SDK script must be used to create isolated test accounts:
     - `admin-staging@draughtsmanstudio.com` (role: `admin` or `studio_admin`)
     - `engineer-staging@archidraft.com` (role: `engineer`)
     - `draughtsman-staging@archidraft.com` (role: `draughtsman`)
     - `student-staging@archidraft.com` (role: `student`)

---

## 8. Legal Content & Terms Gate Status

The legal audit conducted in Phase D.3 and upheld in Phase D.4 confirms:
- **Files Inspected:**
  - `docs/08_legal_privacy/TERMS_AND_CONDITIONS.md`
  - `docs/08_legal_privacy/PRIVACY_POLICY.md`
- **Current State:** Both documents remain unapproved legal drafts containing unresolved bracketed business placeholders (`[Platform / Company Name]`, `[Operating Jurisdiction / State, Country]`, `[Registered Office / Physical Address]`, `[Email Address]`).
- **Enforcement:** In accordance with instructions, **no placeholders have been fabricated, modified, or seeded**.
- **Application Gate:** The backend `assertTermsAccepted` middleware and user onboarding verification remain strictly active and fail-closed.
- **Rollout Impact:** Official legal sign-off and document finalization remain a prerequisite before running full end-to-end legal consent flows in staging.

---

## 9. Explicitly Prohibited Actions Audit

The following actions were confirmed **NOT** to have taken place:

- [x] **NO** Worker deployment (`wrangler deploy` was not executed).
- [x] **NO** remote D1 migrations applied (`wrangler d1 migrations apply ... --remote` was not executed).
- [x] **NO** Vercel deployment executed.
- [x] **NO** release mobile apps built or distributed.
- [x] **NO** production Firebase, Cloudflare, or Vercel settings modified.
- [x] **NO** legal documents published or seeded into D1.
- [x] **NO** `assertTermsAccepted` checks bypassed or removed.
- [x] **NO** draft legal content marked as approved.
- [x] **NO** changes made to the financial panel or payment activations (`501 FEATURE_FROZEN` remains active).
- [x] **NO** git commits created or pushes sent to origin.

---

## 10. Summary of Files Changed in Worktree

| File | Status | Description |
| :--- | :---: | :--- |
| `worker/wrangler.toml` | **Modified** | Updated `[[env.staging.d1_databases]]` with real staging UUID `065d76ba-eca5-4cc1-ba39-51281b79d6b4`. Production bindings completely unchanged. |
| `docs/08_admin_panel/PHASE_D4_STAGING_PROVISIONING_REPORT.md` | **Created** | Comprehensive audit and provisioning report. |

---

## 11. Staging Readiness Gate & Next Steps

The staging cloud resources (Cloudflare D1, Cloudflare R2, Firebase project) are now provisioned, verified, and mapped in local configuration. 

However, **the staging environment is NOT YET READY for application traffic or cross-portal E2E execution** until the operator authorizes and performs the following sequential gates:

1. **Authorization Gate 1:** Explicit authorization to apply D1 database migrations (`0001` through `0020`) to the remote staging database `archi-draft-db-staging`:
   ```bash
   npx wrangler d1 migrations apply archi-draft-db-staging --remote
   ```
2. **Authorization Gate 2:** Explicit authorization to deploy the Worker script to the staging environment:
   ```bash
   npm run deploy:staging
   ```
3. **Configuration Gate 3:** Operator configuration of Firebase staging authentication, apps, and authorized domains.
4. **Legal Approval Gate 4:** Formal resolution of legal placeholders before seeding terms into staging.

**Current Phase D.4 is COMPLETE. Standing by for operator review and instructions.**
