# SECURITY ARCHITECTURE

## 1. SECURITY PRINCIPLES
**UI ≠ SECURITY.** A hidden button or disabled route is not security.

True security is established via:
**Firebase Authentication (Verified JWT)** + **Cloudflare Worker Middleware (`authMiddleware`)** + **D1 Database Authorization Rules (`canUserAccessProject`)**

---

## 2. BACKEND PROJECT AUTHORIZATION ENGINE (`canUserAccessProject`)

Access to any protected project-scoped endpoint (`GET /api/projects/:id`, `GET /api/projects/:id/activity`, `GET /api/projects/:id/files`, `GET /api/files/:fileId/download`, `GET/POST /api/projects/:id/messages`) is evaluated dynamically against authoritative D1 database records:

```typescript
async function canUserAccessProject(db: D1Database, project: any, user: any, uid: string): Promise<boolean>
```

### Authorization Rules by Role:

1. **ADMIN & STUDIO_ADMIN:**
   - Universal read and administrative write access across all projects, including client drafts.
2. **CLIENT:**
   - Strict resource ownership check: `project.client_id === uid`.
   - Cross-client access is rejected with `403 Forbidden`. Clients cannot access another client's project, files, activity, or messages.
3. **DRAUGHTSMAN:**
   - Active assignment verification (`verifyDraughtsmanWorkspaceAccess`):
     - Must match `assignments.draughtsman_id === uid` and `assignments.status === 'ACCEPTED'`.
     - Direct pointer check: `project.draughtsman_id === uid`.
     - If assignment is `PENDING`, `REJECTED`, `REPLACED`, or nonexistent, access is denied (`403 Forbidden`).
4. **ENGINEER:**
   - Technical review scope: Permitted to access non-draft projects (`SUBMITTED`, `WAITING_ASSIGNMENT`, `WAITING_ACCEPTANCE`, `IN_PROGRESS`, `UNDER_CLIENT_REVIEW`, `COMPLETED`).
   - Client `DRAFT` projects are completely hidden from listings and direct access (`403 Forbidden`).
   - Prohibited from final approvals (`approve-final`) and correction requests (`request-correction`).
5. **STUDENT & UNKNOWN ROLES:**
   - **Deny-by-Default:** Any unhandled, guest, or `STUDENT` role request is unconditionally rejected (`403 Forbidden`).

---

## 3. ROLE PROVISIONING SECURITY
Users cannot:
- Self-assign privileged roles (`ENGINEER`, `STUDENT`, `ADMIN`, `STUDIO_ADMIN`) during registration via `POST /api/users`.
- Change their own or another user's role via `PATCH /api/users/me` (whitelisted profile columns only).
- Access administrative endpoints without an active `ADMIN` or `STUDIO_ADMIN` database record.

**Self-Registration Policy:**
Only `CLIENT` and `DRAUGHTSMAN` are permitted in the public registration allowlist (`POST /api/users`). All other roles return `400 Bad Request`.

---

## 4. ACTIVITY LOG SECURITY
Activity logs are **SERVER-GENERATED** and **IMMUTABLE**:
- Client applications cannot insert, edit, or delete activity logs.
- Every state transition executed through the Worker API generates an immutable activity log entry with timestamp and actor UID.

---

## 5. IDENTITY & AUTHENTICATION INTEGRITY
- **Never trust client-supplied `userId` parameters.**
- The actor's identity (`uid`) is extracted exclusively from the cryptographically verified Firebase ID token (`c.get('uid')`).
- File uploads are validated server-side for allowed MIME types and file extensions.

