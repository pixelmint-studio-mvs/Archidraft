# ARCHI DRAFT — Public Certificate Verification API Guide

**Target Audience:** Website Developer & Coding Agents working on Draughtsman Studio (`https://www.draughtsmanstudio.com/verify`)  
**Backend Status:** **LIVE & PRODUCTION-READY**  
**Cloudflare Worker:** `archi-draft-worker`  
**Last Updated:** October 31, 2026

---

## 1. Quick Start: The Only Action Needed on the Website

The backend Cloudflare Worker is already deployed and actively serving unauthenticated public certificate verification requests with full CORS support for your website domain.

On the website (`https://www.draughtsmanstudio.com`), the warning:
> *"Authoritative certificate registry service is currently unconfigured (VITE_WORKER_API_URL missing)"*

is caused because `VITE_WORKER_API_URL` is not defined in the frontend environment during the build.

### Action Required: Set Frontend Environment Variable

In your hosting dashboard (Vercel, Cloudflare Pages, Netlify, or your local `.env`):

```bash
# Production (.env.production or Vercel Production Environment Variables):
VITE_WORKER_API_URL=https://archi-draft-worker.imserratex.workers.dev

# Staging / Preview (.env.staging or Vercel Preview Environment Variables):
VITE_WORKER_API_URL=https://archi-draft-worker-staging.imserratex.workers.dev
```

Rebuild and deploy the website. The warning will clear, and the site will query the live registry.

---

## 2. API Endpoint Specification

### Base URLs
* **Production API Base:** `https://archi-draft-worker.imserratex.workers.dev`
* **Staging API Base:** `https://archi-draft-worker-staging.imserratex.workers.dev`

### Endpoint
* **Path:** `/api/public/credentials/verify/:verificationToken`
* **HTTP Method:** `GET`
* **Full URL Pattern:**  
  `${VITE_WORKER_API_URL}/api/public/credentials/verify/:verificationToken`
* **Authentication:** **NONE (Public Endpoint).** Do **not** send an `Authorization` header.
* **Credentials:** Supported (`credentials: 'include'` or `'same-origin'`).

---

## 3. Dual Lookup Support

The verification route natively supports lookup by **either**:
1. **Verification Token (QR Code Scan):** 32-character hexadecimal token (e.g., `bd2856f096b047d0932ddaf7be4026d7`).
2. **Printed Certificate ID (Manual Search Box):** Formatted certificate identifier (e.g., `DS-AD-LES-F87EFDDB`).

When a user scans a QR code with URL `https://www.draughtsmanstudio.com/verify?id=DS-AD-LES-F87EFDDB&token=bd2856f096b047d0932ddaf7be4026d7`, you can pass either `token` or `id` as `:verificationToken` to the API.

---

## 4. Response Schemas

### A. Valid Certificate (`HTTP 200 OK`)
When the token or certificate ID exists in the authoritative registry:

```json
{
  "valid": true,
  "credential": {
    "id": "DS-AD-LES-F87EFDDB",
    "type": "LESSON_COMPLETION",
    "title": "Understanding Drawing Dimensions",
    "lessonTitle": "Understanding Drawing Dimensions",
    "moduleTitle": "Reinforced Concrete Detailing",
    "issuedAt": "2026-10-29 16:24:19",
    "recipientName": "Jane Doe",
    "issuingAuthority": "Draughtsman Studio & Archi Draft"
  }
}
```

#### Field Reference:
| Field | Type | Description |
| :--- | :--- | :--- |
| `valid` | `boolean` | `true` if certificate is genuine and active. |
| `credential.id` | `string` | Unique Certificate ID printed on the physical/PDF certificate. |
| `credential.type` | `string` | `"LESSON_COMPLETION"` or `"MODULE_COMPLETION"`. |
| `credential.title` | `string` | Credential title. |
| `credential.lessonTitle`| `string` | Exact lesson title associated with the credential. |
| `credential.moduleTitle`| `string \| null` | Curriculum module name. |
| `credential.issuedAt` | `string` | Issuance timestamp. |
| `credential.recipientName` | `string` | Verified student name. Defaults to `"Verified Student"` if anonymized. |
| `credential.issuingAuthority` | `string` | Authoritative issuing entity (`"Draughtsman Studio & Archi Draft"`). |

---

### B. Certificate Not Found / Invalid (`HTTP 404 Not Found`)
When an unknown token or non-existent certificate ID is queried:

```json
{
  "valid": false,
  "error": "Certificate not found"
}
```

---

### C. Server Error (`HTTP 500`)
```json
{
  "error": "Internal Server Error"
}
```

---

## 5. CORS Allowlist & Browser Security

The Worker backend enforces strict origin allowlisting. The following origins are approved and active in production:
* `https://www.draughtsmanstudio.com`
* `https://draughtsmanstudio.com`
* `https://admin.draughtsmanstudio.com`
* `https://archi-draft.vercel.app`

### CORS Preflight Support
* Handled automatically via `OPTIONS` requests.
* Allowed headers: `Content-Type`, `Authorization`, `X-File-Name`, `X-Action-Id`.
* Allowed methods: `GET`, `OPTIONS`, `POST`, `PUT`, `DELETE`, `PATCH`.
* The response sets `Access-Control-Allow-Origin: <requesting_origin>` and `Access-Control-Allow-Credentials: true`.
* Wildcard origins (`*`) are **never** used with credentials.

---

## 6. Frontend Code Examples

### Standard Fetch (Vanilla JS / TypeScript)

```typescript
interface VerificationResponse {
  valid: boolean;
  error?: string;
  credential?: {
    id: string;
    type: string;
    title: string;
    lessonTitle: string;
    moduleTitle: string | null;
    issuedAt: string;
    recipientName: string;
    issuingAuthority: string;
  };
}

export async function verifyCertificate(tokenOrId: string): Promise<VerificationResponse> {
  const baseUrl = import.meta.env.VITE_WORKER_API_URL || 'https://archi-draft-worker.imserratex.workers.dev';
  const cleanIdentifier = encodeURIComponent(tokenOrId.trim());

  const response = await fetch(`${baseUrl}/api/public/credentials/verify/${cleanIdentifier}`, {
    method: 'GET',
    headers: {
      'Accept': 'application/json'
    }
  });

  if (response.status === 404) {
    return { valid: false, error: 'Certificate not found in authoritative registry.' };
  }

  if (!response.ok) {
    throw new Error(`Verification service returned error (HTTP ${response.status})`);
  }

  return await response.json();
}
```

### React / Next.js Component Hook Example

```tsx
import { useState, useEffect } from 'react';

export function useCertificateVerification(tokenOrId: string | null) {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!tokenOrId) return;

    let isMounted = true;
    setLoading(true);
    setError(null);

    const apiBase = import.meta.env.VITE_WORKER_API_URL;
    if (!apiBase) {
      setError('Authoritative certificate registry service is currently unconfigured (VITE_WORKER_API_URL missing).');
      setLoading(false);
      return;
    }

    fetch(`${apiBase}/api/public/credentials/verify/${encodeURIComponent(tokenOrId)}`)
      .then(async (res) => {
        const body = await res.json();
        if (isMounted) {
          if (res.status === 404) {
            setData({ valid: false });
          } else if (res.ok) {
            setData(body);
          } else {
            setError(body.error || 'Verification failed');
          }
        }
      })
      .catch((err) => {
        if (isMounted) setError(err.message || 'Network error reaching registry');
      })
      .finally(() => {
        if (isMounted) setLoading(false);
      });

    return () => {
      isMounted = false;
    };
  }, [tokenOrId]);

  return { data, loading, error };
}
```

---

## 7. How to Test & Verify

You or your coding agent can run these curl commands in terminal to verify the live API anytime:

### 1. Test Unknown Token (Expected: HTTP 404)
```bash
curl -i "https://archi-draft-worker.imserratex.workers.dev/api/public/credentials/verify/unknown-token-12345"
```
**Expected Response:** `HTTP/1.1 404 Not Found` with `{"valid":false,"error":"Certificate not found"}`.

### 2. Test CORS from Website Origin (Expected: 200 or 404 with Access-Control-Allow-Origin)
```bash
curl -i "https://archi-draft-worker.imserratex.workers.dev/api/public/credentials/verify/test-token" \
  -H "Origin: https://www.draughtsmanstudio.com"
```
**Expected Response Header:** `Access-Control-Allow-Origin: https://www.draughtsmanstudio.com`.

### 3. Test Staging with Known Verified Token (Expected: HTTP 200)
```bash
curl -i "https://archi-draft-worker-staging.imserratex.workers.dev/api/public/credentials/verify/bd2856f096b047d0932ddaf7be4026d7"
```
**Expected Response:** `HTTP/1.1 200 OK` with `valid: true` and complete certificate details.

