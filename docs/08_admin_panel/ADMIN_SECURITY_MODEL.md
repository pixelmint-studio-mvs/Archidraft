# ADMIN PANEL — SECURITY MODEL

> Last Updated: October 2026

## Principle

**UI ≠ SECURITY.** A hidden button is not security. Real security comes from:

```
Firebase Authentication → Cloudflare Worker Authorization → D1 Logic
```

The Admin Panel enforces security at THREE layers:

## Layer 1: Firebase Authentication

1. Admin users authenticate via Firebase Auth (email/password)
2. Firebase returns a signed JWT (ID token) containing:
   - `sub` → Firebase UID
   - `iss` → `https://securetoken.google.com/archi-draft`
   - `aud` → `archi-draft`
3. Token is sent with every API request as `Authorization: Bearer <token>`

### Admin Account Creation Policy
- Admin accounts are **NEVER** created through any public-facing registration flow
- The Worker's `POST /api/users` explicitly rejects `role: 'ADMIN'`
- Admin user records must be seeded via:
  - Direct D1 INSERT (during initial setup)
  - A protected admin-seeding script (not exposed via HTTP)
  - Manual Firebase Console user creation + D1 role INSERT

## Layer 2: Worker Authorization

Every Worker endpoint:
1. Extracts the Bearer token from the Authorization header
2. Verifies the JWT against Firebase JWKS (via `jose` library)
3. Extracts `uid` from `payload.sub`
4. Queries D1 `users` table for the user's role
5. Checks `user.role === 'ADMIN'` for admin-only operations

### Role Check Implementation
```typescript
// Every admin endpoint follows this pattern:
const user = await getUser(db, uid);
if (!user || user.role !== 'ADMIN') {
  return c.json({ error: 'Permission denied' }, 403);
}
```

### Identity Trust
From `SECURITY_ARCHITECTURE.md`:
> **Never trust `userId` sent by the client for critical operations.**
> The backend must natively identify the authenticated actor using the verified Firebase token.

The Worker extracts `uid` from the verified JWT payload, never from request body parameters.

## Layer 3: State Machine Enforcement

State transitions are enforced at the database level:
- The Worker checks `project.status` before allowing any transition
- Invalid transitions return `400 Bad Request`
- All state changes are wrapped in D1 batch operations for atomicity

### Allowed Admin Transitions

| From Status | Action | To Status | Additional Validations |
|---|---|---|---|
| SUBMITTED | approve | WAITING_ASSIGNMENT | Project must exist, idempotency check |
| SUBMITTED | reject | CANCELLED | Requires reason string |
| WAITING_ASSIGNMENT | assign | WAITING_ACCEPTANCE | Draughtsman must exist with role DRAUGHTSMAN |
| Any (active) | reassign | WAITING_ACCEPTANCE | Cancels previous assignment, validates new draughtsman |
| Any (not COMPLETED/CANCELLED) | cancel | CANCELLED | Cascades to active assignment |

### Idempotency
All critical operations use `actionId` for idempotency:
```typescript
if (project.last_action_id === actionId) {
  return c.json({ message: 'Action already processed (idempotent)' }, 200);
}
```

## Admin Panel Security Checklist

### Authentication
- [ ] Firebase Auth initialized with correct project config
- [ ] Login screen only accepts email/password (no social auth for admin)
- [ ] ID token refreshed automatically before expiry
- [ ] Logout clears all local state and tokens
- [ ] No admin registration flow exists in the UI

### Authorization
- [ ] Every API call includes Bearer token
- [ ] 401 responses trigger automatic logout
- [ ] 403 responses show "Access Denied" without leaking details
- [ ] No client-side role escalation is possible

### Data Protection
- [ ] No sensitive data stored in localStorage (tokens only in memory/httpOnly)
- [ ] No PII logged to browser console in production
- [ ] File downloads go through authenticated Worker endpoints (no direct R2 URLs)

### CORS
- [ ] Worker CORS restricted to admin panel domains in production
- [ ] No wildcard `*` CORS in production

### Activity Logging
- [ ] Admin Panel NEVER creates activity logs client-side
- [ ] All admin actions (approve, reject, assign, cancel) are logged server-side
- [ ] Activity logs are displayed as read-only in the Admin Panel

## Threat Model

| Threat | Mitigation |
|---|---|
| Admin self-registration | Worker rejects `role: 'ADMIN'` in `POST /api/users` |
| Token forgery | JWT verified against Google JWKS with `jose` |
| Role escalation via API | Worker reads role from D1, not from request |
| Direct D1/R2 access | Admin Panel only communicates via Worker API |
| CSRF | Bearer token auth (not cookie-based) is inherently CSRF-resistant |
| XSS token theft | Store tokens in memory, not localStorage; use CSP headers |
| Replay attacks | `actionId` idempotency prevents duplicate state changes |
| Man-in-the-middle | HTTPS enforced on Worker (*.workers.dev), Vercel, and Firebase |
