# Archi Draft — Phase D.5: Staging Migration and Deployment Report

**Execution Date:** October 23, 2026  
**Integration Branch:** `COMPLETED-INTERGRATION`  
**Base Checkpoint Commit:** `90a2b3b36d83d776d1f1ee6914759df5af89deb5`  
**Execution Context:** Isolated Worktree (`scratch/completed-integration`)  
**Main Workspace Status:** `feature/admin-panel-complete` (`8ea5d4c5`) is **100% untouched and preserved**  
**Staging Worker URL:** `https://archi-draft-worker-staging.imserratex.workers.dev`  
**Status:** **STAGING MIGRATIONS APPLIED & WORKER DEPLOYED — READY FOR STAGING AUTH & LEGAL GATEWAY**  

---

## 1. Executive Summary

Pursuant to explicit owner authorization, Phase D.5 was executed in strict adherence to isolation and security boundaries:

1. **Preflight Guard:** `npm run preflight:staging` and `npm run preflight:prod` passed with zero errors immediately prior to remote operations.
2. **Staging D1 Database Migration:** Applied all migrations `0001_schema.sql` through `0020_project_comments_attachment_id.sql` to `archi-draft-db-staging` (`065d76ba-eca5-4cc1-ba39-51281b79d6b4`). All 25 tables and views were successfully verified.
3. **Staging Worker Deployment:** Successfully deployed `archi-draft-worker-staging` to Cloudflare Workers at `https://archi-draft-worker-staging.imserratex.workers.dev` (Version ID: `e75d1dd9-ecce-4020-887e-75bfa1d124e8`).
4. **Live Verification & Security Audits:**
   - Health endpoint responds with `HTTP 401 Unauthorized` (authenticates via Google JWKS for `archi-draft-staging`).
   - Mock tokens are strictly rejected by the deployed Worker runtime.
   - CORS allowlist permits approved staging origins (`https://admin-staging.draughtsmanstudio.com`) with credentials, and strictly drops unapproved origins.
5. **Zero Production Mutation:** Production D1 (`af8d3312-...`), production R2 (`archi-draft-storage`), production Worker (`archi-draft-worker`), and production Firebase (`archi-draft`) were 100% preserved and untouched.
6. **Zero Repository Pollution:** No git commit, push, or merge occurred; no Vercel deployment was initiated; no mobile release builds were distributed.

---

## 2. Safety Invariants & Preflight Results

The isolation safeguards executed immediately prior to remote operations produced clean passes:

| Preflight Check | Target Worker | Target D1 UUID | Target R2 | Target Firebase | Result |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **`npm run preflight:staging`** | `archi-draft-worker-staging` | `065d76ba-eca5-4cc1-ba39-51281b79d6b4` | `archi-draft-storage-staging` | `archi-draft-staging` | **PASS (Code 0)** |
| **`npm run preflight:prod`** | `archi-draft-worker` | `af8d3312-5f6e-46ce-bcc1-dfa91e484cc0` | `archi-draft-storage` | `archi-draft` | **PASS (Code 0)** |

---

## 3. Remote Staging D1 Migration Execution & Schema Verification

### 3.1 Migration Command & Target
- **Command:** `npx wrangler d1 migrations apply archi-draft-db-staging --remote --env staging`
- **Account:** `06fbb6f8b2e1e65612347252ea10574c` (`imserratex@gmail.com`)
- **Target Database:** `archi-draft-db-staging` (UUID: `065d76ba-eca5-4cc1-ba39-51281b79d6b4`)

### 3.2 Applied Migrations Log
```
┌───────────────────────────────────────────┬────────┐
│ Name                                      │ Status │
├───────────────────────────────────────────┼────────┤
│ 0001_schema.sql                           │ ✅     │
│ 0002_assignments.sql                      │ ✅     │
│ 0003_files.sql                            │ ✅     │
│ 0004_corrections.sql                      │ ✅     │
│ 0005_notifications.sql                    │ ✅     │
│ 0006_financials.sql                       │ ✅     │
│ 0007_student_profile.sql                  │ ✅     │
│ 0008_user_profile_fields.sql              │ ✅     │
│ 0009_project_messages.sql                 │ ✅     │
│ 0010_student_training.sql                 │ ✅     │
│ 0011_student_lessons.sql                  │ ✅     │
│ 0012_evaluations.sql                      │ ✅     │
│ 0013_student_credentials.sql              │ ✅     │
│ 0014_student_credentials_artifact.sql     │ ✅     │
│ 0015_student_credentials_verification.sql │ ✅     │
│ 0016_legal_system.sql                     │ ✅     │
│ 0017_user_status.sql                      │ ✅     │
│ 0018_studio_settings.sql                  │ ✅     │
│ 0019_collaboration_unification.sql        │ ✅     │
│ 0020_project_comments_attachment_id.sql   │ ✅     │
└───────────────────────────────────────────┴────────┘
```
**Total applied:** 20 migrations (100% success).

### 3.3 Remote Schema Verification
Querying `sqlite_master` on `archi-draft-db-staging` confirmed all tables and views are active:
- **Tables (26):** `_cf_KV`, `activity_logs`, `assignments`, `corrections`, `d1_migrations`, `drawing_versions`, `evaluations`, `files`, `invoices`, `legal_consent_events`, `legal_documents`, `notifications`, `payments`, `privacy_requests`, `project_messages`, `projects`, `sqlite_sequence`, `student_assignments`, `student_credentials`, `student_lesson_progress`, `student_progress`, `studio_settings`, `training_lessons`, `training_modules`, `user_consent_state`, `users`.
- **Views (1):** `project_comments` (unified adapter exposing `attachment_file_id` via migration 0020).

### 3.4 Unapproved Terms Check
```sql
SELECT count(*) as count FROM legal_documents;
-- Result: [{"count": 0}]
```
Confirmed: No draft legal documents were seeded into D1.

### 3.5 Production Database Integrity
A read-only migration check on production `archi-draft-db` (`af8d3312-...`) confirmed:
- Migrations `0001` through `0007` remain applied.
- Migrations `0008` through `0020` remain unapplied.
- **Production database was completely untouched.**

---

## 4. Staging Worker Deployment & Live Verification

### 4.1 Deployment Execution
- **Command:** `npx wrangler deploy --env staging`
- **Target Script:** `archi-draft-worker-staging`
- **Deployed Version ID:** `e75d1dd9-ecce-4020-887e-75bfa1d124e8`
- **Assigned Worker URL:** `https://archi-draft-worker-staging.imserratex.workers.dev`
- **Active Bindings:**
  - `env.DB`: `archi-draft-db-staging` (UUID: `065d76ba-eca5-4cc1-ba39-51281b79d6b4`)
  - `env.STORAGE`: `archi-draft-storage-staging`
  - `env.ENVIRONMENT`: `"staging"`
  - `env.FIREBASE_PROJECT_ID`: `"archi-draft-staging"`
  - `env.ALLOWED_ORIGINS`: `"https://admin-staging.draughtsmanstudio.com,https://archi-draft-staging.vercel.app,http://localhost:3000"`

### 4.2 Live HTTP & Security Verification Evidence

1. **Unauthenticated Endpoint Check:**
   ```bash
   curl.exe -i -m 10 https://archi-draft-worker-staging.imserratex.workers.dev/api/health
   # HTTP/1.1 401 Unauthorized
   # {"error":"Unauthorized: Missing or invalid Authorization header"}
   ```

2. **CORS Preflight Check — Approved Staging Origin:**
   ```bash
   curl.exe -i -m 10 -H "Origin: https://admin-staging.draughtsmanstudio.com" -H "Access-Control-Request-Method: GET" -X OPTIONS https://archi-draft-worker-staging.imserratex.workers.dev/api/health
   # HTTP/1.1 204 No Content
   # Access-Control-Allow-Origin: https://admin-staging.draughtsmanstudio.com
   # Access-Control-Allow-Credentials: true
   ```

3. **CORS Preflight Check — Unapproved Origin:**
   ```bash
   curl.exe -i -m 10 -H "Origin: https://malicious-site.com" -H "Access-Control-Request-Method: GET" -X OPTIONS https://archi-draft-worker-staging.imserratex.workers.dev/api/health
   # HTTP/1.1 204 No Content
   # Access-Control-Allow-Origin header is NOT present (origin is rejected).
   ```

4. **Token Verification Runtime Security Check:**
   ```bash
   curl.exe -i -m 10 -H "Authorization: Bearer mock-token:engineer-1" https://archi-draft-worker-staging.imserratex.workers.dev/api/health
   # HTTP/1.1 401 Unauthorized
   # {"error":"Unauthorized: Invalid Firebase token"}
   ```
   *Verification:* Mock tokens used in local offline test harnesses are completely ignored by the Cloudflare Worker runtime; real tokens validated against Google's JWKS for `archi-draft-staging` are strictly required.

---

## 5. Firebase Staging Project & App Status

The staging Firebase project configuration remains isolated:
- **Project ID:** `archi-draft-staging`
- **Project Number:** `528293938258`
- **Console URL:** `https://console.firebase.google.com/project/archi-draft-staging/overview`
- **Registered Staging Apps:**
  - **Android App:** `archi_draft_staging (android)` | App ID: `1:528293938258:android:c780f25ff1a3c1b9888b8b` | Package: `com.draughtsmanstudio.archi_draft`
  - **Web App:** `archi_draft_staging (web)` | App ID: `1:528293938258:web:bb7dfade95c8426c888b8b`

---

## 6. Local Test Suite & Flutter Verification

- **Worker Unit & Integration Tests (`npm test`):**
  - **259 / 259 tests passed** (including Phase B security, Phase C admin creation/comments, Phase D CORS, route aliasing, and workflow simulation).
- **Worker Typecheck (`npm run typecheck`):**
  - **0 errors**.
- **Flutter API Client & Repository Tests (`flutter test`):**
  - **10 / 10 tests passed** (including base URL resolution, release mode HTTPS enforcement, rejection of localhost, and assignment route compatibility).

---

## 7. Cross-Portal Readiness & Testing Prerequisites

| Test / Gate | Current Readiness Status | Details & Blockers |
| :--- | :---: | :--- |
| **Worker API & D1 Staging Backend** | **READY** | Deployed at `https://archi-draft-worker-staging.imserratex.workers.dev`, fully migrated. |
| **R2 Staging File Storage** | **READY** | Provisioned and bound as `archi-draft-storage-staging`. |
| **Admin Web Staging Config** | **READY** | Environment targets: `NEXT_PUBLIC_WORKER_API_URL=https://archi-draft-worker-staging.imserratex.workers.dev` and Firebase `archi-draft-staging`. |
| **Flutter Mobile Config** | **READY** | `--dart-define=API_URL=https://archi-draft-worker-staging.imserratex.workers.dev`. |
| **Firebase Staging Auth & Accounts** | **ACTION REQUIRED** | Email/Password provider must be enabled in Firebase Console; test accounts with custom role claims (`admin`, `engineer`, `draughtsman`, `student`) must be provisioned. |
| **Legal Terms & Consent Gate** | **GATE ACTIVE / BLOCKED** | Terms and Privacy drafts contain bracketed placeholders (`[Company Name]`, `[Address]`, `[Email]`). `assertTermsAccepted` will fail closed until official terms are approved and seeded. |
| **Payments Integration** | **FROZEN** | Returns `501 FEATURE_FROZEN` by design. |

---

## 8. Summary of Files Changed in Worktree

| File | Status | Description |
| :--- | :---: | :--- |
| `worker/wrangler.toml` | **Modified** | Staging D1 UUID bound; production worker name set to `archi-draft-worker`. |
| `docs/08_admin_panel/PHASE_D5_STAGING_DEPLOYMENT_REPORT.md` | **Created** | Comprehensive deployment and verification report. |

*Zero changes staged. Zero commits created. Zero pushes sent.*

---

## 9. Next Steps (Pending Owner Direction)

1. **Firebase Console Action:** In `https://console.firebase.google.com/project/archi-draft-staging/authentication/providers`, enable Email/Password.
2. **Staging Test Accounts Provisioning:** Run a dedicated Admin SDK script to create test accounts in `archi-draft-staging` with custom claims:
   - `admin@staging.archidraft.com` (`role: studio_admin`)
   - `engineer@staging.archidraft.com` (`role: engineer`)
   - `draughtsman@staging.archidraft.com` (`role: draughtsman`)
   - `student@staging.archidraft.com` (`role: student`)
3. **Legal Content Sign-off:** Provide approved business details for `TERMS_AND_CONDITIONS.md` and `PRIVACY_POLICY.md` to seed effective legal versions into `archi-draft-db-staging`.
4. **Live Cross-Portal E2E Run:** Execute live cross-portal tests once test tokens are generated.

*Phase D.5 complete. Standing by for further instructions.*
