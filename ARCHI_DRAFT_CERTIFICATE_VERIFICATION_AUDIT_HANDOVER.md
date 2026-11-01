# ARCHI DRAFT — Certificate Registry & Verification API Audit & Developer Handover

**Project:** ARCHI DRAFT & Draughtsman Studio  
**Target:** Public Certificate Verification System (`https://www.draughtsmanstudio.com/verify`)  
**Audience:** Website Developer & Backend Engineering Team  
**Date:** October 29, 2026  
**Status:** Audit Completed & Verified  

---

## 1. Executive Summary & Root Cause

When visiting the public verification page on the Draughtsman Studio website:
> `https://www.draughtsmanstudio.com/verify`

The website currently displays the following warning:
> **"Authoritative certificate registry service is currently unconfigured (VITE_WORKER_API_URL missing). Please contact support."**

### Root Causes Identified
1. **Frontend Vite Build Missing Environment Variable:**
   The Draughtsman Studio website was compiled with Vite. In the compiled bundle (`assets/CertificateVerification-CxU3n4wf.js`), the frontend looks for `import.meta.env.VITE_WORKER_API_URL`. Because this variable was missing or undefined during the build, the client-side code triggers its defensive warning banner instead of attempting a network request.
2. **Backend Production Deployment Pending:**
   The verification route `GET /api/public/credentials/verify/:verificationToken` is already implemented and verified in the codebase.
   - On **Staging** (`https://archi-draft-worker-staging.imserratex.workers.dev`), the route is deployed and public (returns HTTP 404 for unknown tokens).
   - On **Production** (`https://archi-draft-worker.imserratex.workers.dev`), the worker is currently running an older deployment that requires authorization (returns HTTP 401).
3. **CORS Configuration:**
   The backend Cloudflare Worker restricts origins via `ALLOWED_ORIGINS`. Currently, `https://www.draughtsmanstudio.com` and `https://draughtsmanstudio.com` are not in the allowlist. They must be added so browser `fetch()` requests are not blocked by CORS preflight.

---

## 2. Authoritative Registry Architecture

### 2.1 Backend Issuing Worker
* **Service:** Cloudflare Worker (`archi-draft-worker` in production, `archi-draft-worker-staging` in staging).
* **Source Entrypoint:** `worker/src/index.ts`
* **Issuance Triggers:**
  - **Lesson Completion:** `POST /api/student/training/lessons/:lessonId/progress` automatically creates a `student_credentials` record with `type = 'LESSON_COMPLETION'` upon marking a required lesson as `COMPLETED`.
  - **Module Certification:** Issued automatically upon completing all required module lessons and practical submissions (`type = 'MODULE_COMPLETION'`).
  - **On-Demand PDF Issuance / Regeneration:** `POST /api/student/credentials/:credentialId/certificate`.

### 2.2 Database Storage
* **Registry Database:** Cloudflare D1 SQL Database.
  - **Staging D1 Database:** `archi-draft-db-staging` (`065d76ba-eca5-4cc1-ba39-51281b79d6b4`)
  - **Production D1 Database:** `archi-draft-db` (`af8d3312-5f6e-46ce-bcc1-dfa91e484cc0`)
* **Primary Table:** `student_credentials` (defined across migrations `0013`, `0014`, `0015`, `0022`):
  ```sql
  CREATE TABLE student_credentials (
    id TEXT PRIMARY KEY,                       -- e.g. "DS-AD-LES-6E3A899C"
    student_id TEXT NOT NULL,                  -- Foreign key -> users(id)
    type TEXT NOT NULL,                        -- "LESSON_COMPLETION" | "MODULE_COMPLETION"
    reference_id TEXT NOT NULL,                -- training_lessons(id) | training_modules(id)
    title TEXT NOT NULL,                       -- Credential Title
    description TEXT,                          -- Human-readable description
    issued_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    certificate_object_key TEXT,               -- R2 storage key path
    verification_token TEXT UNIQUE             -- 32-char hex cryptographic token
  );
  ```
* **PDF Artifact Storage:** Cloudflare R2 bucket (`STORAGE`), stored at `certificates/${student_id}/${credential_id}.pdf`.

### 2.3 Persistence & Idempotency Guarantee
* Certificate creation is written inside an atomic D1 database batch transaction before returning HTTP 200.
* Enforces `ON CONFLICT(student_id, type, reference_id) DO NOTHING`. Re-saving a completed lesson never duplicates records or changes the original issuance timestamp.
* **Self-Healing Storage:** If an R2 PDF is purged, `GET /api/student/credentials/:credentialId/certificate` regenerates the PDF with identical metadata and restores it to R2 transparently.

---

## 3. Certificate Identifiers & Mapping

The system uses specific identifiers for physical printing, internal database storage, and external public verification:

| Identifier | Format / Example | Storage Location | Role / Description |
| :--- | :--- | :--- | :--- |
| **Printed Certificate ID** | `DS-AD-LES-XXXXXXXX` (e.g. `DS-AD-LES-8A4F102B`) | `student_credentials.id` | User-facing reference displayed on the PDF and Student Panel. |
| **Internal Database Record ID** | `DS-AD-LES-XXXXXXXX` | `student_credentials.id` (PK) | Exact same identifier as the Printed Certificate ID for lesson certificates. |
| **Verification Token** | 32-character lowercase hex string (UUIDv4 without hyphens) | `student_credentials.verification_token` | High-entropy cryptographic token resistant to brute force. |
| **QR Code Destination URL** | `https://www.draughtsmanstudio.com/verify?id=${certId}&token=${verificationToken}` | Encoded inside the QR code on the certificate PDF | Deep link scanned by smartphones or clicked in the portal. |

### How the Registry Matches Requests
In `worker/src/index.ts`, the verification query is:
```sql
SELECT 
  c.id, c.type, c.title, c.issued_at as issuedAt, 
  u.name as display_name,
  tl.title as lesson_title,
  COALESCE(tm.title, tm_direct.title) as module_title
FROM student_credentials c
JOIN users u ON c.student_id = u.id
LEFT JOIN training_lessons tl ON c.type = 'LESSON_COMPLETION' AND tl.id = c.reference_id
LEFT JOIN training_modules tm ON tm.id = tl.module_id
LEFT JOIN training_modules tm_direct ON c.type = 'MODULE_CERTIFICATION' AND tm_direct.id = c.reference_id
WHERE c.verification_token = ? OR c.id = ?
```

**Dual Resolution:**
1. **QR Code Scan:** URL parameter `?token=<32_hex_chars>` is sent. The query matches on `c.verification_token = ?`.
2. **Manual Input in Website Search Box:** The user types `DS-AD-LES-XXXXXXXX`. The query matches on `c.id = ?`.

Both methods reliably resolve the exact same authentic certificate record.

---

## 4. API Contract for Website Developers

### 4.1 Endpoint Specification
* **HTTP Method:** `GET`
* **Route Path:** `/api/public/credentials/verify/:verificationToken`
* **Base URLs:**
  - **Production:** `https://archi-draft-worker.imserratex.workers.dev`
  - **Staging:** `https://archi-draft-worker-staging.imserratex.workers.dev`
* **Full URL Pattern:**  
  `${VITE_WORKER_API_URL}/api/public/credentials/verify/:verificationToken`
* **Authentication:** **None (Public Route).** Do NOT pass Authorization headers or cookies.
* **Headers:** `Accept: application/json`

---

### 4.2 Response Examples

#### A. Successful Verification (`HTTP 200 OK`)
```json
{
  "valid": true,
  "credential": {
    "id": "DS-AD-LES-8A4F102B",
    "type": "LESSON_COMPLETION",
    "title": "Isolated Footing Reinforcement Detailing",
    "lessonTitle": "Isolated Footing Reinforcement Detailing",
    "moduleTitle": "Reinforced Concrete Detailing",
    "issuedAt": "2026-10-29T12:00:00Z",
    "recipientName": "Sarah Connor",
    "issuingAuthority": "Draughtsman Studio & Archi Draft"
  }
}
```

#### B. Certificate Not Found / Unknown Token (`HTTP 404 Not Found`)
```json
{
  "valid": false,
  "error": "Certificate not found"
}
```

#### C. Revoked Certificate (`HTTP 200 OK`, Optional Status)
```json
{
  "valid": false,
  "status": "REVOKED",
  "credential": {
    "id": "DS-AD-LES-8A4F102B",
    "title": "Isolated Footing Reinforcement Detailing",
    "recipientName": "Sarah Connor",
    "issuedAt": "2026-10-29T12:00:00Z",
    "revokedAt": "2026-10-30T10:00:00Z",
    "revocationReason": "Formal revocation issued by administrative authority."
  }
}
```

#### D. Server Error / Unreachable Registry (`HTTP 500 / 503`)
```json
{
  "error": "Internal Server Error"
}
```

---

## 5. Security & Privacy Audit

1. **Unauthenticated Public Route:** The endpoint is explicitly exempted from the Firebase token middleware (`worker/src/index.ts:83-90`). Anyone can verify a credential without logging in.
2. **Zero Technical & Sensitive Data Disclosure:**
   - Does **NOT** expose student email addresses, phone numbers, student database UIDs, passwords, or course progress scores.
   - Falls back safely to `'Verified Student'` if a student's display name is blank, preventing email leakage.
   - Never exposes database connection strings, R2 service credentials, or internal system keys.
3. **Protected Admin/Student Routes:** Issuance, modification, and student certificate downloads remain strictly gated behind Bearer authentication and role-based access control.

---

## 6. Live Test & Verification Results

### Automated Test Suite
* Ran full test suite in `worker/`: **337 tests passed across 10 test suites (0 failures).**
* End-to-end lifecycle verified in `worker/test/student_lesson_certificates.test.mjs`:
  - Automatic issuance on lesson completion: **PASS**
  - Persistence in D1 database: **PASS**
  - R2 PDF generation and self-healing reconstruction: **PASS**
  - Dual lookup via token and Certificate ID: **PASS**
  - Isolation between students: **PASS**
  - Idempotent repeated progress submissions: **PASS**

### Live Network Probes

| URL Tested | Result | Analysis |
| :--- | :--- | :--- |
| `https://archi-draft-worker-staging.imserratex.workers.dev/api/public/credentials/verify/test-probe` | **HTTP 404** `{"valid":false,"error":"Certificate not found"}` | **Functional:** Staging Worker correctly exposes the public route without authentication. |
| `https://archi-draft-worker.imserratex.workers.dev/api/public/credentials/verify/test-probe` | **HTTP 401** `{"error":"Unauthorized..."}` | **Action Needed:** Production Worker is running an earlier deployment that lacks the public route bypass. |
| Staging CORS Preflight (`Origin: https://www.draughtsmanstudio.com`) | `access-control-allow-origin: null` | **Action Needed:** Public domain needs to be added to Worker's `ALLOWED_ORIGINS`. |

---

## 7. Step-by-Step Action Plan for Website Developer & Deployment

To make the public verification page work immediately:

### Step 1: Add Environment Variable to the Draughtsman Studio Website
In the Draughtsman Studio website project (Vercel / hosting environment variables):

```env
# For Production:
VITE_WORKER_API_URL=https://archi-draft-worker.imserratex.workers.dev

# For Staging / Preview:
VITE_WORKER_API_URL=https://archi-draft-worker-staging.imserratex.workers.dev
```

Rebuild and redeploy the website. This will immediately eliminate the:
`"Authoritative certificate registry service is currently unconfigured (VITE_WORKER_API_URL missing)"` banner.

---

### Step 2: Update Worker CORS Configuration (`worker/wrangler.toml`)
In the backend repository, update `worker/wrangler.toml` to allow requests from the public verification domain:

```toml
# Staging Environment
[env.staging.vars]
ALLOWED_ORIGINS = "https://www.draughtsmanstudio.com,https://draughtsmanstudio.com,https://admin-staging.draughtsmanstudio.com,https://archi-draft-staging.vercel.app,http://localhost:3000"

# Production Environment
[env.production.vars]
ALLOWED_ORIGINS = "https://www.draughtsmanstudio.com,https://draughtsmanstudio.com,https://admin.draughtsmanstudio.com,https://archi-draft.vercel.app"
```

Also add `'https://www.draughtsmanstudio.com'` and `'https://draughtsmanstudio.com'` to `BASELINE_PRODUCTION_ORIGINS` in `worker/src/index.ts:34-37`.

---

### Step 3: Deploy Backend Worker to Production
Deploy the latest code to Cloudflare Workers so production includes the public verification bypass:

```bash
cd worker
npx wrangler deploy --env production
```

---

## 8. Summary Checklist

- [x] Authoritative registry identified (Cloudflare D1 `student_credentials` table).
- [x] Dual lookup mechanism verified (QR token & printed Certificate ID `DS-AD-LES-XXXXXXXX`).
- [x] Security and PII exposure audited (0 secrets or student private data exposed).
- [x] 337 automated tests passing in worker test suite.
- [ ] Website environment variable `VITE_WORKER_API_URL` added and site redeployed.
- [ ] `https://www.draughtsmanstudio.com` added to Worker `ALLOWED_ORIGINS`.
- [ ] Worker deployed to production with latest changes.
