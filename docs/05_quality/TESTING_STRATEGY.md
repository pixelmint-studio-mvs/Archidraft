# TESTING STRATEGY

To ensure platform reliability and absolute security, ARCHI DRAFT follows a multi-layered verification strategy spanning frontend Dart/Flutter testing, TypeScript static analysis, and real backend handler integration testing.

---

## 1. Automated Test Execution Commands

| Scope | Command | Framework | Description |
|---|---|---|---|
| **Flutter Full Test Suite** | `flutter test` | Flutter Test Runner | Runs all 152 unit, widget, and state management tests |
| **Flutter Static Analysis** | `flutter analyze --no-fatal-infos` | Dart Analyzer | Validates type safety, dead code, linting across Flutter codebase |
| **Worker Type-Checking** | `npx tsc --noEmit` *(in `worker/`)* | TypeScript Compiler | Validates Worker API types, Hono bindings, and schema interfaces |
| **Backend Auth Integration** | `npm test` *(in `worker/`)* | Node.js v24 Test Runner | Executes 47 isolated integration tests against real Hono handlers & SQLite |

---

## 2. Real Backend Handler Integration Testing (`worker/test/`)

To prevent bugs where Dart-only mock tests pass while the backend rejects requests (or vice versa), the repository maintains a dedicated backend test harness in `worker/test/backend_authorization.test.mjs`.

### Test Architecture:
- **Engine:** Node.js v24 Native Test Runner (`node --test`)
- **Isolated Database:** In-memory SQLite (`node:sqlite` via `DatabaseSync(':memory:')`), wrapped with a Cloudflare D1 query adapter (`prepare().bind().first() / .all() / .run()`).
- **Migration Replay:** Applies real D1 migrations in chronological order (`0001` through `0007`) before running tests.
- **Handler Execution:** Dispatches HTTP requests directly to Hono's `app.request()` pipeline, exercising real authentication middleware, parameter validation, role evaluation, and SQL queries.
- **Zero Fixture Mutation:** Uses isolated in-memory instances; retained production or test fixtures are never modified.

### Verified Backend Coverage (47 Tests):
1. **Authentication Middleware:** Rejection of missing, non-Bearer, and corrupted tokens (`401 Unauthorized`).
2. **Role Provisioning Security:** Allowed `CLIENT` and `DRAUGHTSMAN` self-registration; blocked `ENGINEER`, `STUDENT`, `ADMIN`, `STUDIO_ADMIN` (`400 Bad Request`); verified role immutability in `PATCH /api/users/me`.
3. **Student & Unknown Role Isolation:** Deny-by-default on project lists, project detail, file lists, and downloads (`403 Forbidden`).
4. **Cross-Client Isolation:** Scoped project queries, denied cross-client details, activity logs, files, and file downloads (`403 Forbidden`).
5. **Draughtsman Assignment Lifecycle:** Access granted for `ACCEPTED` assignments; denied for `PENDING`, `REJECTED`, `REPLACED`, or unassigned (`403 Forbidden`).
6. **Engineer Review Scope:** Client `DRAFT` projects excluded from listings and direct access (`403 Forbidden`); access allowed to `SUBMITTED` and `IN_PROGRESS` projects (`200 OK`).
7. **Workflow Compliance:** Blocked Engineer from final approval and corrections (`403 Forbidden`); allowed Client approval and correction requests (`200 OK`); Admin override permitted (`200 OK`).
8. **Admin Operations:** Admin universal visibility, status progression, draughtsman assignment, and client non-admin denial verified.

---

## 3. Frontend Flutter Testing (`test/`)

### 1. Unit Testing
- Data models (serialization/deserialization)
- Enums (`AssignmentStatus`, `ProjectStatus`, `CorrectionStatus`)
- State controllers and business validation logic (`ProjectValidators`, `AuthErrorMapper`)

### 2. Widget & Screen Testing
- Form validation, loading states, and error dialogs
- Responsive desktop & mobile rendering across viewports (1280x800, 1366x768, 1920x1080, 400x800)
- Workspace tabs (Overview, Specs, Timeline, Drawings) and overflow prevention
- Notifications dialog, profile form, and collaboration views

---

## 4. DEFINITION OF TEST COMPLETION
A feature or security fix is **Done** only when:
`Flutter Tests (100% Pass)` + `Flutter Analysis (0 Issues)` + `Worker tsc (0 Errors)` + `Backend Auth Integration Tests (100% Pass)`

