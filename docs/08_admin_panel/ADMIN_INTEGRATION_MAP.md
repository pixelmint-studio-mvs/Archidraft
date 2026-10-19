# ADMIN PANEL — INTEGRATION MAP

> Last Updated: October 2026

This document maps every Admin Panel feature to its corresponding backend endpoint, database table, state machine rule, and security constraint.

## Feature → Backend Integration Matrix

### 1. Dashboard

| Feature | Endpoint | D1 Tables | Notes |
|---|---|---|---|
| Total project count | `GET /api/admin/stats` | `projects` | COUNT(*) |
| Projects by status | `GET /api/admin/stats` | `projects` | GROUP BY status |
| Total user count | `GET /api/admin/stats` | `users` | COUNT(*) |
| Users by role | `GET /api/admin/stats` | `users` | GROUP BY role |
| Recent activity feed | `GET /api/admin/stats` | `activity_logs` | LIMIT 20, ORDER BY timestamp DESC |

### 2. Project Management

| Feature | Endpoint | D1 Tables | State Machine Rule | Security |
|---|---|---|---|---|
| List all projects | `GET /api/projects` | `projects` | — | ADMIN sees all projects |
| View project detail | `GET /api/projects/:id` | `projects` | — | ADMIN can view any |
| Approve project | `POST /api/projects/approve` | `projects`, `activity_logs` | SUBMITTED → WAITING_ASSIGNMENT | ADMIN only, idempotent |
| Reject project | `POST /api/projects/reject` | `projects`, `activity_logs` | SUBMITTED → CANCELLED | ADMIN only, requires reason |
| Assign draughtsman | `POST /api/projects/assign` | `projects`, `assignments`, `activity_logs` | WAITING_ASSIGNMENT → WAITING_ACCEPTANCE | ADMIN only, validates draughtsman exists |
| Reassign draughtsman | `POST /api/projects/reassign` | `projects`, `assignments`, `activity_logs` | Any active → WAITING_ACCEPTANCE | ADMIN only, cancels previous assignment |
| Cancel project | `POST /api/projects/cancel` | `projects`, `assignments`, `activity_logs` | Any (except COMPLETED/CANCELLED) → CANCELLED | ADMIN only, cascades to assignment |
| View project files | `GET /api/projects/:id/files` | `files` | — | Role-scoped |
| Download file | `GET /api/files/:id/download` | `files`, R2 | — | Role-scoped, streams from R2 |
| View drawing versions | `GET /api/projects/:id/drawing_versions` | `drawing_versions` JOIN `files` | — | Role-scoped |
| View corrections | `GET /api/projects/:id/corrections` | `corrections` | — | Role-scoped |
| View activity log | `GET /api/projects/:id/activity` | `activity_logs` | — | Role-scoped, read-only |
| View assignment history | `GET /api/projects/:id/assignments` | `assignments` JOIN `users` | — | ADMIN only |

### 3. User Management

| Feature | Endpoint | D1 Tables | Notes |
|---|---|---|---|
| List all users | `GET /api/users` | `users` | ADMIN only |
| Filter by role | `GET /api/users?role=DRAUGHTSMAN` | `users` | Query param filter |
| View user profile | `GET /api/users` (client-side filter) | `users` | No single-user endpoint yet |

### 4. Activity Monitoring

| Feature | Endpoint | D1 Tables | Notes |
|---|---|---|---|
| Global activity feed | `GET /api/admin/stats` (recentActivity) | `activity_logs` | Limited to 20 most recent |
| Project activity | `GET /api/projects/:id/activity` | `activity_logs` | Full history for specific project |

## State Machine Reference (Admin-Relevant Transitions)

```
SUBMITTED ──── approveProject() ───→ WAITING_ASSIGNMENT
    │
    └──── rejectProject() ──────→ CANCELLED

WAITING_ASSIGNMENT ── assignDraughtsman() ──→ WAITING_ACCEPTANCE

WAITING_ACCEPTANCE ── (Admin can reassign) ──→ WAITING_ACCEPTANCE

Any (except COMPLETED/CANCELLED) ── cancelProject() ──→ CANCELLED
```

### Admin CANNOT Perform These Actions
- Create projects (CLIENT only)
- Submit projects (CLIENT only)
- Accept/reject assignments (DRAUGHTSMAN only)
- Upload drawings (DRAUGHTSMAN only)
- Request corrections (CLIENT only)
- Final approval (CLIENT only)
- Modify activity logs (server-generated, immutable)
- Change user roles (no endpoint exists)
- Delete users (no endpoint exists)

## Environment Configuration

### Required Environment Variables (`.env.local`)

```env
# Firebase Configuration
NEXT_PUBLIC_FIREBASE_API_KEY=<from-firebase-console>
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=archi-draft.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=archi-draft
NEXT_PUBLIC_FIREBASE_APP_ID=1:471564030203:web:bb8fc985704d4d22e4e05e

# Worker API
NEXT_PUBLIC_WORKER_API_URL=https://archi-draft-worker.imserratex.workers.dev

# Local Development
# NEXT_PUBLIC_WORKER_API_URL=http://localhost:8787
```

## CORS Requirements

The Cloudflare Worker currently uses permissive CORS (`app.use('*', cors())`). For production, restrict to:

```typescript
app.use('*', cors({
  origin: [
    'https://admin.archidraft.com',     // Production
    'https://*.vercel.app',             // Preview deploys
    'http://localhost:3000',            // Local dev
  ],
}));
```
