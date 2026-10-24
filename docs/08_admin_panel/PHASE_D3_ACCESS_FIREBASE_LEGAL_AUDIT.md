# Archi Draft — Phase D.3: Cloudflare Access, Firebase Staging, and Legal Audit Report

**Audit Date:** October 23, 2026  
**Integration Branch:** `COMPLETED-INTERGRATION`  
**Base Checkpoint Commit:** `90a2b3b36d83d776d1f1ee6914759df5af89deb5`  
**Execution Context:** Isolated Worktree (`scratch/completed-integration`)  
**Main Workspace Status:** `feature/admin-panel-complete` (`8ea5d4c5`) completely untouched and preserved  
**Status:** **READY FOR STAGING PROVISIONING AFTER OWNER CONFIRMATION**  

---

## 1. Git and Workspace Safety Confirmation

All safety checks were verified prior to and during this audit:

| Check | Expected | Actual Evidence | Status |
| :--- | :--- | :--- | :---: |
| **Git Branch** | `COMPLETED-INTERGRATION` | `On branch COMPLETED-INTERGRATION` | **PASS** |
| **Commit HEAD** | `90a2b3b3` | `90a2b3b36d83d776d1f1ee6914759df5af89deb5` | **PASS** |
| **Remote Status** | Ahead 2 commits, zero pushes | `Your branch is ahead of 'origin/COMPLETED-INTERGRATION' by 2 commits` | **PASS** |
| **Isolated Worktree** | `scratch/completed-integration` | Path verified; all Phase D.1/D.2/D.3 changes confined to worktree | **PASS** |
| **Main Workspace** | `feature/admin-panel-complete` | Verified completely untouched; uncommitted files intact | **PASS** |
| **Secret Protection** | Zero credentials exposed | No tokens, keys, passwords, or `.env` files output or committed | **PASS** |
| **Financial Scope** | Frozen | `/financials` read-only, mutations return `501 FEATURE_FROZEN` | **PASS** |
| **Legal Gate** | Active | `assertTermsAccepted` and onboarding checks active | **PASS** |

---

## 2. Cloudflare Access & Permissions Matrix (Live Verified)

Live CLI inspection was conducted using `npx wrangler whoami`, `npx wrangler d1 list`, and `npx wrangler r2 bucket list` in read-only mode:

### Live Evidence Summary
- **Wrangler Version:** `4.131.1` (installed and operational in `worker/node_modules`).
- **Authenticated User:** `zedsuo125@gmail.com` (authenticated via active OAuth Token in local config store `C:\Users\inaam\AppData\Roaming\xdg.config\.wrangler\config\default.toml`).
- **Account Access:** The token has verified access to **two** accounts:
  1. `Imserratex@gmail.com's Account` — Account ID: `06fbb6f8b2e1e65612347252ea10574c` (**Authoritative Project Account** matching `worker/wrangler.toml`).
  2. `Zedsuo125@gmail.com's Account` — Account ID: `6d3e9f84583cd219bbc209c552e98a92`.
- **Token Permissions:**
  - `d1 (write)` — verified capable of creating databases and executing migrations.
  - `workers (write)`, `workers_scripts (write)`, `workers_routes (write)` — verified capable of deploying Workers.
  - `pages (write)`, `zone (read)`, `ssl_certs (write)`, `secrets_store (write)`.
- **Live Database Inspection:**
  - `npx wrangler d1 list` succeeded:
    - Found: `af8d3312-5f6e-46ce-bcc1-dfa91e484cc0` | `archi-draft-db` | Created: `2026-09-16T15:59:01.158Z` (Production).
    - Staging D1 database `archi-draft-db-staging` **does not exist yet**.
- **Live R2 Storage Inspection:**
  - `npx wrangler r2 bucket list` succeeded:
    - Found: `archi-draft-storage` | Created: `2026-09-16T16:28:03.611Z` (Production).
    - Staging bucket `archi-draft-storage-staging` **does not exist yet**.

### Cloudflare Readiness Matrix
| Check | Result | Evidence | Remaining Operator Action |
| :--- | :---: | :--- | :--- |
| **Wrangler CLI Available** | **PASS** | Version `4.131.1` | None |
| **Authentication Status** | **PASS** | OAuth Token valid for `zedsuo125@gmail.com` | None |
| **Account Matching** | **PASS** | Account `06fbb6f8b2e1e65612347252ea10574c` present in account list | None (`wrangler.toml` targets this exact account) |
| **D1 Permissions** | **PASS** | `d1 (write)` present; `d1 list` returned production database | Ready to create `archi-draft-db-staging` |
| **R2 Permissions** | **PASS** | Bucket listing succeeded; returned production bucket | Ready to create `archi-draft-storage-staging` |
| **Worker Deploy Perms** | **PASS** | `workers (write)`, `workers_scripts (write)` present | Ready to deploy `archi-draft-worker-staging` |
| **Staging Isolation** | **PASS** | Staging D1 and R2 resources do not exist yet; no risk of collision | Operator runs creation commands |

---

## 3. Firebase Staging Readiness Matrix (Live Verified)

Live inspection was conducted using `firebase --version` and `firebase projects:list`:

### Live Evidence Summary
- **Firebase CLI Version:** `15.30.0` (installed and authenticated).
- **Available Projects:**
  1. `archi-draft` (Project ID: `archi-draft`, Number: `471564030203`) — **Production Project**.
  2. `vocixit` (Project ID: `vocixit`, Number: `970483078120`) — Unrelated project.
- **Dedicated Staging Project:** `archi-draft-staging` **does NOT exist in Firebase**.
- **Classification:** **`PRODUCTION ONLY`**

### Repository Firebase Configuration Audit
1. **Worker Backend (`worker/src/auth.ts`):**
   - Successfully enhanced in Phase D.2 to dynamically accept `c.env.FIREBASE_PROJECT_ID`.
   - Defaults safely to `'archi-draft'`, but dynamically verifies against `c.env.FIREBASE_PROJECT_ID` (`archi-draft-staging`) when running in staging.
2. **Flutter Mobile Portals (`lib/firebase_options.dart`):**
   - Configured solely for production project `archi-draft` (Android: `1:471564030203:android:80a988e5a6c0be41e4e05e`, Web: `1:471564030203:web:bb8fc985704d4d22e4e05e`).
3. **Admin Web Portal (`apps/admin-web/src/lib/firebase.ts`):**
   - Reads environment variables `NEXT_PUBLIC_FIREBASE_PROJECT_ID`, `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN`, `NEXT_PUBLIC_FIREBASE_API_KEY`, defaulting to `archi-draft`.

### Firebase Staging Assessment & Options
Because `archi-draft-staging` does not yet exist in Firebase, two paths are available:
- **Option A (Recommended for Strict Isolation):** Operator creates a dedicated Firebase project `archi-draft-staging` in Firebase Console, adds Android/Web apps, and configures email/password authentication.
- **Option B (Staging via Shared Project with Dedicated Test Domain):** Use the existing `archi-draft` project with a dedicated staging user namespace (e.g. `test-staging-*@draughtsmanstudio.com`) and custom user claims.

---

## 4. Legal Content Investigation & Inventory

A comprehensive search of the entire integration branch was conducted across `docs/`, `worker/`, `lib/`, and database migrations.

### Finding: Complete Draft Legal Content Discovered in Repository
The integration branch **already contains complete, highly detailed draft legal documents** specifically authored for Archi Draft under Indian law (IT Act 2000, IT SPDI Rules 2011, DPDP Act 2023) in [`docs/08_legal_privacy/`](file:///docs/08_legal_privacy):

| Document | Exact Repository Path | Version & Effective Date | Content Completeness | Approval Status |
| :--- | :--- | :---: | :--- | :---: |
| **Terms & Conditions** | [`docs/08_legal_privacy/TERMS_AND_CONDITIONS_DRAFT.md`](file:///docs/08_legal_privacy/TERMS_AND_CONDITIONS_DRAFT.md) | `1.2.0-DRAFT`<br>`[EFFECTIVE DATE — PENDING RELEASE]` | **Complete text** (224 lines, 20 sections covering accounts, roles, submissions, assignments, revision cap, IP, liability, dispute resolution). | **FOUND — APPROVAL UNVERIFIED**<br>Marked `DRAFT — NOT APPROVED FOR PRODUCTION`<br>Contains bracketed owner placeholders. |
| **Privacy Policy** | [`docs/08_legal_privacy/PRIVACY_POLICY_DRAFT.md`](file:///docs/08_legal_privacy/PRIVACY_POLICY_DRAFT.md) | `1.2.0-DRAFT`<br>`[EFFECTIVE DATE — PENDING RELEASE]` | **Complete text** (246 lines, 16 sections detailing data categories, legal basis, consent, child privacy, DPDP rights, retention, security, grievance redressal). | **FOUND — APPROVAL UNVERIFIED**<br>Marked `DRAFT — NOT APPROVED FOR PRODUCTION`<br>Contains bracketed owner placeholders. |
| **Acceptable Use Policy** | [`docs/08_legal_privacy/ACCEPTABLE_USE_POLICY.md`](file:///docs/08_legal_privacy/ACCEPTABLE_USE_POLICY.md) | `1.0.0-DRAFT` | Complete rules on prohibited drawing content, system abuse, and academic honesty. | **FOUND — APPROVAL UNVERIFIED** |
| **Grievance Policy** | [`docs/08_legal_privacy/GRIEVANCE_AND_SUPPORT_POLICY.md`](file:///docs/08_legal_privacy/GRIEVANCE_AND_SUPPORT_POLICY.md) | `1.0.0-DRAFT` | Complete statutory DPDP/IT Act grievance escalation matrix with operational turnaround targets. | **FOUND — APPROVAL UNVERIFIED** |
| **IP Policy** | [`docs/08_legal_privacy/INTELLECTUAL_PROPERTY_POLICY.md`](file:///docs/08_legal_privacy/INTELLECTUAL_PROPERTY_POLICY.md) | `1.0.0-DRAFT` | Complete IP ownership allocation (Client owns brief & drawings; Studio owns training assets). | **FOUND — APPROVAL UNVERIFIED** |
| **Data Retention Policy** | [`docs/08_legal_privacy/DATA_RETENTION_AND_DELETION.md`](file:///docs/08_legal_privacy/DATA_RETENTION_AND_DELETION.md) | `1.0.0-DRAFT` | Retention schedules for DWG files, CAD drafts, invoices, and logs. | **FOUND — APPROVAL UNVERIFIED** |
| **Open Questions Register** | [`docs/08_legal_privacy/BUSINESS_DECISIONS_AND_OPEN_QUESTIONS.md`](file:///docs/08_legal_privacy/BUSINESS_DECISIONS_AND_OPEN_QUESTIONS.md) | `1.2.0-DRAFT` | Comprehensive audit register of unresolved owner inputs (Item-01: Proprietor Name, Item-02: Grievance Officer, Item-03: Minor Students). | **VERIFIED AUDIT LOG** |

### Runtime Legal Gate & Ingestion Assessment
1. **Schema & Database State:**
   - Migration `0016_legal_system.sql` creates tables `legal_documents`, `legal_consent_events`, `user_consent_state`, and `privacy_requests`.
   - Migration `0016` creates **zero** default rows. The table `legal_documents` is completely empty upon initial migration.
2. **Runtime Enforcement (`worker/src/legal.ts`):**
   - `assertTermsAccepted()` queries:
     `SELECT id, version, is_mandatory FROM legal_documents WHERE document_type = 'TERMS_AND_CONDITIONS' AND status = 'EFFECTIVE' AND is_mandatory = 1`
   - If no `EFFECTIVE` document exists in D1, the API returns HTTP 503 `TERMS_MAINTENANCE_MODE`.
   - If an `EFFECTIVE` document exists, any authenticated non-admin user who has not affirmatively accepted that exact version receives HTTP 403 `TERMS_ACCEPTANCE_REQUIRED`.
3. **Publication Mechanism:**
   - The Worker exposes administrative endpoints:
     - `POST /api/admin/legal/documents` (creates draft document).
     - `POST /api/admin/legal/documents/:id/publish` (atomically promotes draft to `EFFECTIVE` and supersedes previous versions).
4. **Owner Input Required to Resolve Approval:**
   The draft documents are substantially complete and professional. To transition from `APPROVAL UNVERIFIED` to `APPROVED FOR STAGING`:
   - Owner confirms the Sole Proprietorship details: `[PROPRIETOR FULL LEGAL NAME]` and `[BUSINESS ADDRESS, INDIA]`.
   - Owner designates contact emails: `[GRIEVANCE EMAIL]`, `[SUPPORT EMAIL]`, and `[SECURITY INCIDENT EMAIL]`.
   - Once confirmed, the document can be seeded into staging D1 with `status = 'EFFECTIVE'`.

---

## 5. Staging Resource and URL Matrix

| Resource | Target Staging Value | Verification Status |
| :--- | :--- | :---: |
| **Cloudflare Account ID** | `06fbb6f8b2e1e65612347252ea10574c` | **VERIFIED** (Present in active OAuth session) |
| **Worker Environment** | `archi-draft-worker-staging` | **CONFIGURED** in `wrangler.toml` (Awaiting deploy) |
| **D1 Database** | `archi-draft-db-staging` | **UNCREATED** (`STAGING_D1_DATABASE_ID_PLACEHOLDER`) |
| **R2 Bucket** | `archi-draft-storage-staging` | **UNCREATED** |
| **Firebase Project** | `archi-draft-staging` | **UNCREATED** (CLI shows production `archi-draft` only) |
| **Admin Web Base URL** | Vercel Staging Deployment / Preview | **AWAITING VERCEL LINK** |
| **CORS Allowed Origins** | `https://admin-staging.draughtsmanstudio.com`<br>`https://archi-draft-staging.vercel.app`<br>`http://localhost:3000` | **CONFIGURED** in `wrangler.toml` |
| **Mobile API URL** | `https://archi-draft-worker-staging.<account>.workers.dev` | **ENFORCED** via `--dart-define=API_URL=...` |

---

## 6. Safe Local Validation Evidence

All preflight checks, compiler checks, and automated integration tests were re-executed:

```text
========================================================================================
LOCAL PREFLIGHT & INTEGRATION TEST VERIFICATION
========================================================================================

1. Preflight Guard: Staging
   Command: npm run preflight:staging (in worker/)
   Result:  EXIT 1 [BLOCKED AS DESIGNED]
   Reason:  D1 database_id is still placeholder STAGING_D1_DATABASE_ID_PLACEHOLDER.
            Collision check active. Proves fail-closed protection works.

2. Preflight Guard: Production
   Command: npm run preflight:prod (in worker/)
   Result:  EXIT 0 [PASSED]
   Reason:  Verified production configuration af8d3312-5f6e-46ce-bcc1-dfa91e484cc0
            is isolated, locked, and untouched.

3. Worker Integration Suite:
   Command: npm test (in worker/)
   Result:  259 passed / 0 failed / 0 skipped across 7 test files.
   Covers:  CORS allowlist, assignment aliases, cross-portal E2E lifecycle,
            correction caps, student isolation, suspension, and frozen financials.

4. Worker TypeScript Check:
   Command: npm run typecheck (in worker/)
   Result:  tsc --noEmit exited 0 (clean compilation, zero errors).

5. Admin Web Integration Suite:
   Command: npm test (in apps/admin-web/)
   Result:  108 passed / 0 failed / 0 skipped across 27 test suites.

6. Admin Web Production Build:
   Command: npm run build (in apps/admin-web/)
   Result:  Next.js 16.4.2 Turbopack optimized build succeeded (22/22 routes prerendered).

7. Flutter API Client & Security Tests:
   Command: flutter test test/features/api/data/api_client_test.dart --no-pub
   Result:  8 passed / 0 failed (Release mode validation verified).

8. Flutter Project Repository Tests:
   Command: flutter test test/features/projects/data/project_repository_test.dart --no-pub
   Result:  2 passed / 0 failed (Active assignment route contracts verified).

========================================================================================
```

---

## 7. Remaining Operator Actions (Grouped by Owner)

### A. Cloudflare Operator Actions
1. Execute `npx wrangler d1 create archi-draft-db-staging`.
2. Update `worker/wrangler.toml` with the returned database UUID.
3. Execute `$env:CLOUDFLARE_ACCOUNT_ID="06fbb6f8b2e1e65612347252ea10574c"; npx wrangler r2 bucket create archi-draft-storage-staging`.
4. Run `npm run preflight:staging` to verify preflight passes.
5. Apply migrations: `npx wrangler d1 migrations apply archi-draft-db-staging --env staging --remote`.
6. Deploy Worker: `npx wrangler deploy --env staging`.

### B. Firebase Admin Actions
1. In Firebase Console (`console.firebase.google.com`), create project `archi-draft-staging` (or authorize dedicated staging test accounts in existing project).
2. Enable Email/Password authentication provider.
3. Register Web App and Android App (`com.draughtsmanstudio.archidraft`).
4. Generate `google-services.json` and web configuration for staging.

### C. Legal / Product Owner Actions
1. Review `docs/08_legal_privacy/TERMS_AND_CONDITIONS_DRAFT.md` and `PRIVACY_POLICY_DRAFT.md`.
2. Supply real values for:
   - Sole Proprietor Full Legal Name.
   - Business Address in India.
   - Grievance Officer Name and Contact Email.
3. Formally approve the text for staging database seeding (`status = 'EFFECTIVE'`).

### D. Vercel Admin Actions
1. Configure Staging Preview Environment Variables:
   - `NEXT_PUBLIC_WORKER_API_URL = https://archi-draft-worker-staging.imserratex.workers.dev`
   - `NEXT_PUBLIC_FIREBASE_PROJECT_ID = archi-draft-staging`
   - `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN = archi-draft-staging.firebaseapp.com`
   - `NEXT_PUBLIC_FIREBASE_API_KEY = <staging_api_key>`
   - `NEXT_PUBLIC_FIREBASE_APP_ID = <staging_app_id>`

### E. QA / Lead Engineer Actions
1. Create 4 dedicated staging test accounts:
   - Studio Admin (`admin-staging@draughtsmanstudio.com`)
   - Engineer (`engineer-staging@example.com`)
   - Draughtsman (`draughtsman-staging@example.com`)
   - Student (`student-staging@example.com`)
2. Execute live cross-portal smoke test against the deployed staging backend.

---

## 8. Final Decision

### Decision: **READY FOR STAGING PROVISIONING AFTER OWNER CONFIRMATION**

**Rationale:**
1. **Cloudflare CLI access is verified and authenticated:** The active environment is authenticated to `zedsuo125@gmail.com` with confirmed write permissions to the authoritative account `06fbb6f8b2e1e65612347252ea10574c`. D1 and R2 read inspections passed.
2. **Local codebase and guardrails are 100% verified:** All 259 backend tests, 108 admin tests, 22 Next.js pages build, and Flutter security tests pass.
3. **Comprehensive draft legal content exists in the repository:** Complete draft Terms & Conditions and Privacy Policy were discovered in `docs/08_legal_privacy/`, but require owner confirmation of 3 business placeholders before ingestion into staging D1.
4. **Staging Firebase project requires creation:** Firebase CLI confirmed that only production `archi-draft` currently exists.
5. **No remote mutations occurred:** The repository remains strictly protected awaiting operator execution.
