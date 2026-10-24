# Phase Master Verification — Remaining Work & Staging Acceptance Plan

This document establishes the categorized roadmap of remaining work, unimplemented product features, operational prerequisites, and the formal Staging Acceptance Checklist following the **Master Complete Verification and End-to-End Testing** of Archi Draft Studio.

---

## 1. Work Categorization Matrix

| Category | Item Count | Status / Impact | Description |
|----------|------------|-----------------|-------------|
| **Must Fix Before Staging Acceptance** | **0** | **CLEARED** | All core application features, portal routes, 7-stage lifecycles, and security boundaries are fully operational and verified. |
| **Requires Owner / Business Input** | **2** | **PENDING INPUT** | Publishing formal legal documents to D1; defining commercial payment provider contracts. |
| **Requires Explicit Deployment Authorization**| **1** | **FROZEN** | Remote Cloudflare Worker deployment (`npx wrangler deploy`) remains frozen until authorized. |
| **Unimplemented Product Features** | **2** | **PLANNED** | Student training submission grading workflow; Stripe/Razorpay financial gateway unfreezing. |
| **Production-Only Hardening** | **2** | **FUTURE** | Decommissioning the staging legal test seam; setting up Cloudflare custom domains and production SSL. |

---

## 2. Detailed Breakdown of Categories

### Category A: Must Fix Before Staging Acceptance
*Status: 0 Items — ALL PRE-CONDITIONS SATISFIED.*
- All 4 user portals (Studio Admin, Engineer, Draughtsman, Student) render cleanly and authenticate with Firebase.
- Full 7-stage lifecycle completes repeatably (verified across Run A, Run B, and Run C).
- Native AutoCAD DWG and DXF file uploads persist cleanly to Cloudflare R2 staging storage.
- All 5 automated regression test suites pass with 100% green status (626 total tests, 0 failures, 0 lint/type errors).
- Path traversal vulnerability in filename sanitization (`worker/src/index.ts`) has been diagnosed, resolved, and verified.

---

### Category B: Requires Owner / Business Input (Non-Technical Blockers)

#### 1. Formal Legal Documents Publication
- **Current State:** Cloudflare D1 staging database currently contains no published, active Terms of Service or Privacy Policy rows in the `legal_documents` table. Consequently, the application enforces `HTTP 503 TERMS_MAINTENANCE_MODE` in fail-closed mode unless bypassed by authorized staging test headers.
- **Action Required by Owner:**
  1. Authorize or provide approved legal policy text (Terms of Service and Privacy Policy).
  2. Insert or seed active legal document records into D1 via:
     ```sql
     INSERT INTO legal_documents (id, type, version, content, published_at, is_active)
     VALUES ('tos-v1', 'TERMS_OF_SERVICE', '1.0.0', 'Approved Terms text...', datetime('now'), 1);
     ```
  3. Once active documents are seeded, the production legal gate will open automatically without requiring any test bypass header.

#### 2. Payment Gateway & Financial Providers
- **Current State:** Financial and invoicing endpoints (`POST /api/projects/:id/invoices`) intentionally respond with `HTTP 501 FEATURE_FROZEN` to protect business accounts.
- **Action Required by Owner:**
  1. Select target payment service provider (e.g., Stripe, LemonSqueezy, or Razorpay).
  2. Provide staging API keys and webhook secret signing keys in Cloudflare Worker environment secrets.

---

### Category C: Requires Explicit Deployment Authorization

#### 1. Cloudflare Remote Staging Worker Deployment
- **Current State:** In strict compliance with master safety instructions, `npx wrangler deploy` has been frozen. All tests were executed against the local worker runtime bound directly to remote Cloudflare D1 (`archi-draft-db-staging`) and R2 (`archi-draft-storage-staging`).
- **Prerequisites for Unfreezing:**
  - Explicit user authorization to execute `npx wrangler deploy` from `worker/`.
  - Deployment validation using live Cloudflare worker endpoint URLs.

---

### Category D: Unimplemented Product Features (Post-Staging Roadmap)

#### 1. Student Training Module Submission & Feedback Pipeline
- **Current State:** The Student Portal (`StudentStudioScreen`) renders modules via `GET /api/student/training/modules` and prevents unauthorized access to administrative routes. However, submitting student practice exercises for draughtsman/engineer review is not yet wired to a backend queue.
- **Proposed Enhancement:** Implement `POST /api/student/exercises/submit` and create a dedicated review board for senior draughtsmen to mentor students.

#### 2. Financial & Invoicing Integration
- **Current State:** Invoicing mutations return `HTTP 501 FEATURE_FROZEN`.
- **Proposed Enhancement:** Implement invoice generation, automated PDF rendering, and escrow payment settlement upon Engineer Stage 7 final sign-off.

---

### Category E: Production-Only Hardening

#### 1. Decommissioning the Staging Test Seam
- **Description:** Prior to final production cutover, remove or disable the `X-Staging-Test-Mode` header inspection in `worker/src/legal.ts` and ensure `options?.environment === 'staging'` cannot be spoofed.
- **Impact:** Ensures production legal consent verification relies 100% on active database records and cryptographically verified user consent receipts.

#### 2. Custom Domain & Production SSL Configuration
- **Description:** Bind production DNS records (`studio.archidraft.com`, `admin.archidraft.com`, `api.archidraft.com`) to Cloudflare Pages and Workers.

---

## 3. Staging Acceptance Checklist

Use this checklist during final owner review to formalize staging sign-off:

| Checkpoint | Target Environment | Verification Method | Status |
|------------|-------------------|---------------------|--------|
| **Auth & Persona Hydration** | Local / Staging D1 | Authenticate 4 personas via Firebase | **VERIFIED** |
| **Studio Admin Portal UI** | `http://localhost:3000` | Inspect projects, users, assignments | **VERIFIED** |
| **Engineer Portal UI** | `http://localhost:8080` | Create projects, submit corrections | **VERIFIED** |
| **Draughtsman Portal UI** | `http://localhost:8080` | Accept tasks, upload DWG/DXF files | **VERIFIED** |
| **Student Portal UI** | `http://localhost:8080` | Verify training modules & route fences | **VERIFIED** |
| **Full 7-Stage Project Lifecycle** | D1 / R2 Staging | Complete E2E cycle across all roles | **VERIFIED** |
| **DWG/DXF Binary Storage** | Cloudflare R2 | Upload real CAD binary files | **VERIFIED** |
| **Security & Boundary Fences** | Worker API | Non-admin 403, fail-closed legal 503 | **VERIFIED** |
| **Automated Test Suites (626/626)**| CLI CI Suites | Worker (267), Admin (111), Flutter (248) | **VERIFIED** |
| **Owner Legal Seeding** | Remote D1 Staging | Seed `legal_documents` table rows | *Awaiting Owner* |
| **Remote Staging Deploy** | Cloudflare Network | Execute `wrangler deploy` | *Awaiting Authorization* |

---

## 4. Next Steps Recommendation

1. **Owner Review:** Review the master verification report (`docs/08_admin_panel/PHASE_MASTER_COMPLETE_VERIFICATION_REPORT.md`) and screenshot evidence index.
2. **Legal Text Provision:** Provide the official Terms of Service and Privacy Policy text to seed D1 staging.
3. **Deployment Authorization:** Once approved, authorize the execution of `npx wrangler deploy` to push the hardened worker to remote Cloudflare staging infrastructure.
