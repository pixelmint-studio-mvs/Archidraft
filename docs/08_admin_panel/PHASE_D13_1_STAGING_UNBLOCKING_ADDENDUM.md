# Phase D.13.1 — Staging UI Workflow Unblocking Addendum Report

**Date:** October 24, 2026  
**Parent Report:** [PHASE_D13_TRACEABLE_CROSS_PORTAL_WORKFLOW_REPORT.md](file:///c:/Users/inaam/.gemini/antigravity-ide/scratch/Archidraft/scratch/completed-integration/docs/08_admin_panel/PHASE_D13_TRACEABLE_CROSS_PORTAL_WORKFLOW_REPORT.md)  
**Workspace:** `c:\Users\inaam\.gemini\antigravity-ide\scratch\Archidraft\scratch\completed-integration`  
**Git Branch:** `COMPLETED-INTERGRATION` (Preserving `feature/admin-panel-complete` completely untouched)  
**Environment Targets:**  
- Cloudflare Worker Staging: `https://archi-draft-worker-staging.imserratex.workers.dev`  
- Cloudflare D1 Staging DB: `archi-draft-db-staging` (`065d76ba-eca5-4cc1-ba39-51281b79d6b4`)  
- Cloudflare R2 Staging Bucket: `archi-draft-drawings-staging`  
- Firebase Staging Project: `archi-draft-staging` (`528293938258`)  
**Final Verdict:** **CONDITIONAL — STAGE 1 REAL UI MUTATION BLOCKED BY SERVER LEGAL GATE (HTTP 503 TERMS_MAINTENANCE_MODE)**

---

## 1. Executive Summary & Scope Attestation

Phase D.13.1 conducted a targeted, rigorous investigation into the server-side blocker preventing the full cross-portal end-to-end UI lifecycle on staging, followed by a live, minimal reproducible execution of the real Flutter Engineer UI workflow with a newly identified project (`D13-1-E2E-20261024-B8F2`).

### Key Findings:
1. **Server-Side Blocker Verified:** In the staging Cloudflare Worker, `assertTermsAccepted()` strictly intercepts all non-admin mutations (`POST /api/projects`, `POST /api/assignments/accept`, drawing uploads, corrections, approvals). Because staging D1 table `legal_documents` contains 0 published effective rows, the server immediately halts mutations with `HTTP 503 Service Unavailable` (`TERMS_MAINTENANCE_MODE`).
2. **Staging Test Seam Code Audited:** A staging test seam exists in `worker/src/legal.ts` (lines 48–60) and `worker/src/index.ts` (lines 205–209) designed to exempt 4 specific staging test UIDs when `ENVIRONMENT === 'staging'` and header `X-Staging-Test-Mode: workflow-e2e` is passed.
3. **CORS Preflight Barrier Confirmed on Live Worker:** A live preflight `OPTIONS` probe against the deployed staging Worker confirmed that `X-Staging-Test-Mode` is **omitted** from `Access-Control-Allow-Headers`. Consequently, standard web browsers running Flutter Web (`localhost:8080`) abort requests with `net::ERR_FAILED` if the client sends this header. Omitting the header allows the request to reach the server, where `assertTermsAccepted()` fails closed with HTTP 503.
4. **Real UI Workflow Attempt Executed:** The real Flutter Engineer UI was driven to create project `D13-1-E2E-20261024-B8F2 High-Rise Mixed-Use CAD`. Upon confirming submission, the browser dispatched `POST /api/projects`, which received `HTTP 503 TERMS_MAINTENANCE_MODE`.
5. **Database State Verified (Read-Only):** Direct read-only SQL queries to staging D1 confirmed `D13-1-E2E-20261024-B8F2` was **not persisted** (0 rows). Per protocol, the lifecycle was stopped at Stage 1 and downstream stages were not marked PASS.
6. **Zero Degradation & High Health:** All automated regression test suites across Worker (267/267), Admin Web (111/111), and Flutter (248/248) are 100% green with 0 lints and 0 TypeScript errors.

### Strict Scope & Protection Attestation:
- **No Git Modifications:** Zero git commits, pushes, merges, resets, stashes, or branch switches were executed.
- **Source Workspace Untouched:** `feature/admin-panel-complete` remains strictly untouched.
- **Zero Production Access:** No production Worker, database (`af8d3312-...`), Firebase (`471564030203`), or R2 resources were accessed.
- **Zero Deployments:** No Cloudflare Workers, web apps, or database migrations were deployed.
- **Financials Frozen:** `/financials` remains completely frozen (`HTTP 501 FEATURE_FROZEN`).
- **Zero Fabricated Consent:** No synthetic consent rows were inserted into D1, and no draft documents were seeded as effective.

---

## 2. Server-Side Blocker Trace & Source Inspection

### 2.1 Trace of `assertTermsAccepted()`
The server-side legal gate is defined in [worker/src/legal.ts](file:///c:/Users/inaam/.gemini/antigravity-ide/scratch/Archidraft/scratch/completed-integration/worker/src/legal.ts#L31-L98) and executed via middleware in [worker/src/index.ts](file:///c:/Users/inaam/.gemini/antigravity-ide/scratch/Archidraft/scratch/completed-integration/worker/src/index.ts#L186-L217):

```typescript
// worker/src/legal.ts:31-60
export async function assertTermsAccepted(
  db: D1Database,
  uid: string,
  userRole?: string,
  options?: {
    environment?: string;
    testModeHeader?: string | null;
  }
): Promise<{ ok: boolean; errorResponse?: any }> {
  // Administrative staff are exempt to ensure recovery and management access
  if (userRole === 'ADMIN' || userRole === 'STUDIO_ADMIN') {
    return { ok: true };
  }

  // STAGING-ONLY TEST-ACCEPTANCE SEAM (Phase D.10.3)
  // Strictly impossible to activate in production:
  // Must fail closed if environment is missing, ambiguous, or not explicitly 'staging'
  const isStaging = options?.environment === 'staging';
  const hasTestHeader = options?.testModeHeader === 'workflow-e2e';
  const STAGING_TEST_UIDS = new Set([
    'KXAR90JgoVYLuOKzkbxpKTC8ATa2', // Staging Engineer (zedsuo125+engineer@gmail.com)
    'TJjtkBm3lgRlpKtcI5u3jpYPH9s1', // Staging Draughtsman (zedsuo125+draughtsman@gmail.com)
    '2iypyxUntQX6djOzwjgPo5xWrGD2', // Staging Student (zedsuo125+student@gmail.com)
    'QBhduHDU1mYUxvtQ89adVnwQYCg1', // Staging Studio Admin (zedsuo125@gmail.com)
  ]);

  if (isStaging && hasTestHeader && STAGING_TEST_UIDS.has(uid)) {
    console.log(`[STAGING_TEST_MODE_ACTIVE] Legal gate test-exemption active for staging test UID: ${uid}`);
    return { ok: true };
  }

  // 1. Fetch currently EFFECTIVE mandatory Terms document from trusted database
  const termsDoc = await db.prepare(
    "SELECT id, version, is_mandatory FROM legal_documents WHERE document_type = 'TERMS_AND_CONDITIONS' AND status = 'EFFECTIVE' AND is_mandatory = 1"
  ).first();

  if (!termsDoc) {
    return {
      ok: false,
      errorResponse: {
        error: 'Service temporarily in maintenance mode: terms document unavailable',
        code: 'TERMS_MAINTENANCE_MODE',
        status: 503,
      },
    };
  }
  // ... verifies user_consents table
}
```

### 2.2 Middleware Request Flow & Route Coverage
In [worker/src/index.ts](file:///c:/Users/inaam/.gemini/antigravity-ide/scratch/Archidraft/scratch/completed-integration/worker/src/index.ts#L186-L217), the legal gate intercepts every mutation defined by `isBusinessMutation`:

```typescript
const isBusinessMutation =
  ['POST', 'PUT', 'DELETE', 'PATCH'].includes(c.req.method) &&
  (
    path === '/api/projects' ||
    path.startsWith('/api/projects/') ||
    path === '/api/assignments' ||
    path.startsWith('/api/assignments/') ||
    path.startsWith('/api/student/training/')
  );

if (isBusinessMutation) {
  const uid = c.get('uid');
  if (uid) {
    const user = await getUser(c.env.DB, uid);
    const testModeHeader = c.req.header('X-Staging-Test-Mode') || null;
    const check = await assertTermsAccepted(c.env.DB, uid, user?.role as string | undefined, {
      environment: c.env?.ENVIRONMENT,
      testModeHeader,
    });
    if (!check.ok) {
      return c.json(check.errorResponse, check.errorResponse.status || 403);
    }
  }
}
```

### 2.3 Exact Lifecycle Routes Covered
Every business mutation in the 7-stage lifecycle is intercepted:
1. **Project Creation:** `POST /api/projects` -> Intercepted. Returns 503.
2. **Assignment Acceptance:** `POST /api/assignments/accept` (or `/api/projects/accept`) -> Intercepted. Returns 503.
3. **Drawing Uploads (v1 & v2):** `POST /api/projects/:id/drawings` -> Intercepted. Returns 503.
4. **Correction Requests:** `POST /api/projects/request-correction` -> Intercepted. Returns 503.
5. **Final Approval:** `POST /api/projects/approve-final` -> Intercepted. Returns 503.
6. **Exemptions:**
   - `GET` queries (`GET /api/projects`, `GET /api/users/me`, `GET /api/assignments`) are not business mutations and succeed.
   - Roles `ADMIN` and `STUDIO_ADMIN` are inherently exempt from `assertTermsAccepted()` (`userRole === 'STUDIO_ADMIN' => return { ok: true }`), allowing Admin reviews and assignment dispatch to succeed unconditionally.

### 2.4 Production Isolation Guarantees
The staging test seam requires three concurrent conditions to evaluate to `true`:
1. `c.env?.ENVIRONMENT === 'staging'`: In production, the environment variable is `'production'`. Missing, null, or undefined environments fail closed.
2. `c.req.header('X-Staging-Test-Mode') === 'workflow-e2e'`: Requires an exact, dedicated test header.
3. `STAGING_TEST_UIDS.has(uid)`: Requires a valid Firebase JWT signed by the staging Firebase project matching one of the 4 hardcoded staging test account UIDs.

**Proof of Production Impossibility:** Even if a production client injects `X-Staging-Test-Mode: workflow-e2e`, the server-side check `options?.environment === 'staging'` evaluates to `false`, causing the seam to immediately fall through to the production database check.

---

## 3. Staging-Only Test Path & CORS Barrier Analysis

### 3.1 Live Preflight CORS Probe
To verify whether the test seam can be reached from a real web browser UI, a live HTTP `OPTIONS` probe was dispatched to the staging Cloudflare Worker:

```bash
curl.exe -i -X OPTIONS https://archi-draft-worker-staging.imserratex.workers.dev/api/projects \
  -H "Origin: http://localhost:8080" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Authorization,Content-Type,X-Staging-Test-Mode"
```

**Actual Server Response:**
```http
HTTP/1.1 204 No Content
Date: Sat, 24 Oct 2026 02:11:41 GMT
Connection: keep-alive
Access-Control-Allow-Origin: http://localhost:8080
Access-Control-Allow-Methods: POST,GET,OPTIONS,PUT,DELETE,PATCH
Access-Control-Allow-Headers: X-File-Name,X-Action-Id,Content-Type,Authorization,Content-Length
Access-Control-Max-Age: 86400
Access-Control-Allow-Credentials: true
```

### 3.2 Finding & Architectural Implication
`Access-Control-Allow-Headers` on the deployed staging Worker contains only:
`X-File-Name, X-Action-Id, Content-Type, Authorization, Content-Length`.

**`X-Staging-Test-Mode` is omitted from `Access-Control-Allow-Headers`.**

Under the W3C / WHATWG Fetch specification, web browsers (Chrome, Firefox, Safari) strictly reject requests if a custom header sent by the client is not enumerated in `Access-Control-Allow-Headers` during CORS preflight. The browser terminates the fetch with `net::ERR_FAILED` before any payload reaches the worker.

### 3.3 Why Client-Side Bypasses Are Ineffective
Modifying client-side code (e.g. `legal_repository.dart` returning fake accepted status) only changes whether the Flutter app navigates to `/legal/onboarding`. When the client attempts the actual business mutation (`POST /api/projects`), the backend Cloudflare Worker independently calls `assertTermsAccepted()`. Because no effective terms exist in staging D1, the backend returns HTTP 503 regardless of client-side routing.

### 3.4 The Smallest Safe Code Change Needed (For Future Deployment)
When a staging deployment is authorized by the user, the minimal safe change requires exactly two modifications:

1. **In [worker/src/index.ts](file:///c:/Users/inaam/.gemini/antigravity-ide/scratch/Archidraft/scratch/completed-integration/worker/src/index.ts#L130):** Add `'X-Staging-Test-Mode'` to `allowHeaders`:
   ```typescript
   allowHeaders: ['X-File-Name', 'X-Action-Id', 'X-Staging-Test-Mode', 'Content-Type', 'Authorization', 'Content-Length'],
   ```
2. **In [lib/src/features/api/data/api_client.dart](file:///c:/Users/inaam/.gemini/antigravity-ide/scratch/Archidraft/scratch/completed-integration/lib/src/features/api/data/api_client.dart):** Conditionally transmit `'X-Staging-Test-Mode': 'workflow-e2e'` only when running against staging for authenticated staging test UIDs:
   ```dart
   if (isStaging && stagingTestUids.contains(_firebaseAuth.currentUser?.uid)) {
     headers['X-Staging-Test-Mode'] = 'workflow-e2e';
   }
   ```

**Production-Isolation Guarantee:** Permitting `'X-Staging-Test-Mode'` in CORS `allowHeaders` introduces zero vulnerability in production because `assertTermsAccepted()` verifies `ENVIRONMENT === 'staging'` on the server. In production (`ENVIRONMENT === 'production'`), the header is completely ignored.

---

## 4. Real UI Workflow Execution & Verifications

A new, unique project was targeted through the real Flutter Engineer UI on `http://localhost:8080`:

- **Project ID / Identifier:** `D13-1-E2E-20261024-B8F2`
- **Project Title:** `D13-1-E2E-20261024-B8F2 High-Rise Mixed-Use CAD`
- **Project Address:** `Tower B, Tech Boulevard, Whitefield, Bangalore`
- **Drawing Name:** `Architectural Working Set`
- **Project Area:** `4200` sq ft
- **Technical Category:** `Architectural`

### 4.1 Step-by-Step UI Execution & Evidence
The workflow was driven using DevTools Protocol automation executing real user interactions in headless Chrome:

| Step | Action | UI Result | Network Event | Screenshot Evidence |
|---|---|---|---|---|
| **1** | Authenticate as Engineer (`zedsuo125+engineer@gmail.com`) | Successfully logged in, redirected through auth state | `200` Firebase lookup, `200 GET /api/users/me` | [01-engineer-projects-initial.png](file:///c:/Users/inaam/.gemini/antigravity-ide/scratch/Archidraft/scratch/completed-integration/docs/08_admin_panel/phase_d13_evidence/phase_d13_1/01-engineer-projects-initial.png) |
| **2** | Navigate to `#/engineer/projects/new` | Blank project creation form loaded | `200 GET /api/projects` | [02-engineer-project-form-empty.png](file:///c:/Users/inaam/.gemini/antigravity-ide/scratch/Archidraft/scratch/completed-integration/docs/08_admin_panel/phase_d13_evidence/phase_d13_1/02-engineer-project-form-empty.png) |
| **3** | Input Title, Address, Drawing Name, Area via coordinate clicks | Form fully populated with `D13-1-E2E-20261024-B8F2` data | None (Client Form State) | [03-engineer-project-form-populated.png](file:///c:/Users/inaam/.gemini/antigravity-ide/scratch/Archidraft/scratch/completed-integration/docs/08_admin_panel/phase_d13_evidence/phase_d13_1/03-engineer-project-form-populated.png) |
| **4** | Click `INITIATE DRAFTING` | Confirmation modal dialog opened | Pre-submission checks | [04-engineer-submit-dialog.png](file:///c:/Users/inaam/.gemini/antigravity-ide/scratch/Archidraft/scratch/completed-integration/docs/08_admin_panel/phase_d13_evidence/phase_d13_1/04-engineer-submit-dialog.png) |
| **5** | Click `Confirm Submit` in dialog | Client dispatches `POST /api/projects`, SnackBar appears | `HTTP 503 POST /api/projects` (`TERMS_MAINTENANCE_MODE`) | [05-engineer-submit-result.png](file:///c:/Users/inaam/.gemini/antigravity-ide/scratch/Archidraft/scratch/completed-integration/docs/08_admin_panel/phase_d13_evidence/phase_d13_1/05-engineer-submit-result.png) |

### 4.2 Read-Only Backend State Verification
A read-only SQL query was executed against remote staging D1 database `archi-draft-db-staging` (`065d76ba-eca5-4cc1-ba39-51281b79d6b4`):

```bash
npx wrangler d1 execute DB --env staging --remote --command \
  "SELECT id, project_name, status, client_id, created_at FROM projects WHERE project_name LIKE '%D13-1%' OR id LIKE '%D13-1%';"
```

**Query Result:**
```json
[
  {
    "results": [],
    "success": true,
    "meta": {
      "served_by": "v3-prod",
      "rows_read": 8,
      "rows_written": 0
    }
  }
]
```

**Persistence Finding:** Exactly `0` rows returned. Project `D13-1-E2E-20261024-B8F2` was **not persisted** in Cloudflare D1.

### 4.3 Lifecycle Gate Status
Per the task protocol:
> *"If any step is blocked, stop that lifecycle at the blocker and continue only independent safe checks. Do not mark downstream stages PASS."*

The lifecycle was cleanly halted at Stage 1. Stages 2 through 7 for `D13-1-E2E-20261024-B8F2` remain unexecuted and are **NOT** marked PASS.

---

## 5. Independent Safe Portal Verifications

While Stage 1 mutations remain blocked by the legal gate, all independent read and administrative actions across the portals were verified:

### 5.1 Admin Web Portal (Portal D) — Next.js (`http://localhost:3000`)
- **Identity:** Studio Admin (`zedsuo125@gmail.com` / UID: `QBhduHDU1mYUxvtQ89adVnwQYCg1`).
- **Legal Gate Status:** Inherently exempt (`userRole === 'STUDIO_ADMIN'`).
- **Actions Verified:**
  - Login at `/login` succeeded with Firebase session tokens.
  - Project review table at `/projects` populated with staging projects (`PRJ-D10-R1-531B92CC`, `PRJ-D10-R3-8D2A9DD5`).
  - Assign Draughtsman modal opens and displays Draughtsman capacity (`2/4 active`).
  - Assignment dispatch operational (`assignments` row creation verified).
- **Status:** **`PASS`**

### 5.2 Draughtsman Portal (Portal B) — Flutter Web (`http://localhost:8080/#/draughtsman`)
- **Identity:** Staging Draughtsman (`zedsuo125+draughtsman@gmail.com` / UID: `TJjtkBm3lgRlpKtcI5u3jpYPH9s1`).
- **Actions Verified:**
  - Authenticated and accessed Draughtsman Studio view.
  - Displayed assigned projects in `WAITING_ACCEPTANCE`.
  - Displayed 2/4 active workload indicator.
  - Inspected assignment details and CAD review interface.
  - Mutation `POST /api/assignments/accept` requires terms acceptance; fails with 503 without the test header.
- **Status:** **`READ_PASS / MUTATION_BLOCKED`**

### 5.3 Student Portal (Portal C) — Flutter Web (`http://localhost:8080/#/student`)
- **Identity:** Staging Student (`zedsuo125+student@gmail.com` / UID: `2iypyxUntQX6djOzwjgPo5xWrGD2`).
- **Actions Verified:**
  - Authenticated and accessed training dashboard.
  - Loaded curriculum state.
  - Navigation guards strictly prevented unauthorized routing to `/engineer` or `/draughtsman`, redirecting to `/student/dashboard`.
- **Status:** **`PASS`**

---

## 6. Automated Regression Test Suite Results

All unit, integration, and analysis test suites across the repository were executed and confirmed completely green:

| Component | Test Suite / Command | Total Tests | Passed | Failed | Status |
|---|---|---|---|---|---|
| **Worker Backend** | `npm test` in `worker/` | 267 | 267 | 0 | **PASS** |
| **Admin Web Next.js** | `npm test` in `apps/admin-web/` | 111 | 111 | 0 | **PASS** |
| **Flutter Features** | `flutter test test/features/` | 248 | 248 | 0 | **PASS** |
| **Flutter Analysis** | `flutter analyze` | — | — | 0 issues | **PASS** (55.2s) |
| **Admin TypeScript** | `npx tsc --noEmit` in `apps/admin-web/` | — | — | 0 errors | **PASS** (exit code 0) |

**Total passing test assertions across repository:** **626 tests passing, 0 failing**.

---

## 7. Evidence Artifact Index

All screenshots and logs captured during Phase D.13.1 are persisted in the workspace:

| Artifact Name | Path | Description |
|---|---|---|
| `01-engineer-projects-initial.png` | [docs/08_admin_panel/phase_d13_evidence/phase_d13_1/01-engineer-projects-initial.png](file:///c:/Users/inaam/.gemini/antigravity-ide/scratch/Archidraft/scratch/completed-integration/docs/08_admin_panel/phase_d13_evidence/phase_d13_1/01-engineer-projects-initial.png) | Engineer portal post-login dashboard |
| `02-engineer-project-form-empty.png` | [docs/08_admin_panel/phase_d13_evidence/phase_d13_1/02-engineer-project-form-empty.png](file:///c:/Users/inaam/.gemini/antigravity-ide/scratch/Archidraft/scratch/completed-integration/docs/08_admin_panel/phase_d13_evidence/phase_d13_1/02-engineer-project-form-empty.png) | Empty project creation form (`#/engineer/projects/new`) |
| `03-engineer-project-form-populated.png` | [docs/08_admin_panel/phase_d13_evidence/phase_d13_1/03-engineer-project-form-populated.png](file:///c:/Users/inaam/.gemini/antigravity-ide/scratch/Archidraft/scratch/completed-integration/docs/08_admin_panel/phase_d13_evidence/phase_d13_1/03-engineer-project-form-populated.png) | Populated form with `D13-1-E2E-20261024-B8F2` brief |
| `04-engineer-submit-dialog.png` | [docs/08_admin_panel/phase_d13_evidence/phase_d13_1/04-engineer-submit-dialog.png](file:///c:/Users/inaam/.gemini/antigravity-ide/scratch/Archidraft/scratch/completed-integration/docs/08_admin_panel/phase_d13_evidence/phase_d13_1/04-engineer-submit-dialog.png) | Confirmation modal dialog before submission |
| `05-engineer-submit-result.png` | [docs/08_admin_panel/phase_d13_evidence/phase_d13_1/05-engineer-submit-result.png](file:///c:/Users/inaam/.gemini/antigravity-ide/scratch/Archidraft/scratch/completed-integration/docs/08_admin_panel/phase_d13_evidence/phase_d13_1/05-engineer-submit-result.png) | Post-submission result showing HTTP 503 error SnackBar |
| Execution Script | [scratch/execute_phase_d13_1_engineer.mjs](file:///c:/Users/inaam/.gemini/antigravity-ide/scratch/Archidraft/scratch/completed-integration/scratch/execute_phase_d13_1_engineer.mjs) | Standalone CDP automation script reproducing the UI submission |

---

## 8. Path to Unblocking & Recommendations

To unblock the complete 7-stage real browser UI workflow without violating security invariants or legal compliance:

### Path A: Seed Effective Legal Terms in Staging D1 (Recommended / True Production Parity)
- Seed table `legal_documents` in staging D1 (`065d76ba-eca5-4cc1-ba39-51281b79d6b4`) with approved staging draft terms:
  - `document_type = 'TERMS_AND_CONDITIONS'`, `status = 'EFFECTIVE'`, `version = '1.0.0'`
  - `document_type = 'PRIVACY_POLICY'`, `status = 'EFFECTIVE'`, `version = '1.0.0'`
- **Advantage:** Enables the authentic Flutter onboarding UI (`#/legal/onboarding`) to load legal documents and allows test users to genuinely consent via the UI. The workflow completes exactly as a real user would in production, with zero custom headers and zero test seams.

### Path B: Deploy Staging Worker with `X-Staging-Test-Mode` in CORS Whitelist
- When staging deployment is approved, apply the minimal code change to [worker/src/index.ts](file:///c:/Users/inaam/.gemini/antigravity-ide/scratch/Archidraft/scratch/completed-integration/worker/src/index.ts#L130):
  ```typescript
  allowHeaders: ['X-File-Name', 'X-Action-Id', 'X-Staging-Test-Mode', 'Content-Type', 'Authorization', 'Content-Length']
  ```
- Deploy to staging Worker (`wrangler deploy --env staging`).
- Configure staging Flutter builds with `X-Staging-Test-Mode: workflow-e2e`.
- **Advantage:** Allows automated browser E2E suites to run cleanly against staging even if legal documents are cleared or in maintenance mode.
- **Production Isolation:** Guaranteed safe because `assertTermsAccepted()` strictly ignores `X-Staging-Test-Mode` unless `ENVIRONMENT === 'staging'`.
