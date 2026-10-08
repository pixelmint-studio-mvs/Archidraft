# SECURITY ARCHITECTURE

## 1. Core Principle
**UI Hiding is NOT Security.** Disabling a button or hiding a navigation tab provides zero protection against unauthorized requests.

True application security is established through defense-in-depth across the platform:
```text
Firebase Authentication (Identity Verification)
  + Cloudflare Worker Middleware (JWT Cryptographic Validation)
  + Cloudflare Worker Role & Ownership Checks (RBAC)
  + Cloudflare D1 Parameterized Bindings (Data Isolation)
  + Cloudflare R2 Protected Object Streaming (Storage Isolation)
```

---

## 2. Authentication & Identity Security
- **Token Verification:** Every request to `/api/*` requires a valid Firebase Auth ID token in the `Authorization: Bearer <token>` header.
- **Worker Verification:** The Worker decodes and validates the token signature against Google's public JSON Web Key Sets (JWKS).
- **No Client-Supplied User IDs:** The backend never trusts client-supplied user identifiers in the request payload. The authenticated user ID is strictly derived from the verified token (`c.get('uid')`).

---

## 3. Role-Based Access Control (RBAC)
- **Role Assignment:** Users select their role (`ENGINEER`, `DRAUGHTSMAN`, `STUDENT`) on registration. Once provisioned in D1, the role cannot be modified by the user.
- **Admin Privilege Protection:** The `STUDIO_ADMIN` role cannot be self-assigned under any circumstances.
- **Endpoint Authorization:**
  - Engineers can only query and mutate projects where `client_id == uid`.
  - Draughtsmen can only access projects where `draughtsman_id == uid`.
  - Only Studio Admins can invoke administrative routes (`/api/projects/approve`, `/api/projects/assign`, `/api/admin/dashboard`, `/api/projects/:projectId/financials`).

---

## 4. File Storage Security
- **No Public R2 Access:** The R2 storage bucket has no public URL or CORS exposure.
- **Mediated Access:** Every upload, download, and delete request passes through the Worker API, which verifies that the requesting user owns or is assigned to the project.
- **50 MB Hard Limit:** Server-side streaming byte counters terminate requests exceeding 50 MB before R2 buffers overflow.

---

## 5. Audit Trail & Log Security
- **Server-Generated & Immutable:** Activity logs (`activity_logs`) are created exclusively by the Cloudflare Worker during transactional operations.
- **No Client Modification:** Clients cannot create, alter, or delete activity log entries.
- **Role Scoping:** Engineers are restricted to viewing activity logs from their owned projects; internal assignment rejections or financial actions are not leaked to Engineer feeds.
