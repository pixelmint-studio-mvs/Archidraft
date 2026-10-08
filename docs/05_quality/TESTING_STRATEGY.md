# TESTING & QUALITY ASSURANCE STRATEGY

ARCHI DRAFT enforces rigorous multi-layered validation across both the Flutter client and the Cloudflare Worker backend.

---

## 1. Static Analysis & Type Checking

### Flutter Client
```bash
flutter analyze --no-fatal-infos
```
- **Standard:** Must run with 0 errors and 0 warnings.
- Enforces strict lint rules, parameter types, null safety, and clean unused imports.

### Cloudflare Worker
```bash
cd worker
npm run typecheck
```
- **Standard:** Must complete with 0 TypeScript compilation errors.
- Validates D1 database bindings, R2 streaming types, and Hono route signatures.

---

## 2. Unit Testing
Tests business logic, entity serialization, and utility validation in isolation:
- `ProjectMessage` JSON parsing, ISO8601 date handling, role normalization (`test/unit/project_message_test.dart`).
- Form input validators for required fields, numeric constraints, and file sizes (`test/unit/validators_test.dart`).
- Category label presentation mappers (`fileCategoryLabel`, `sanitiseActivityDetails`).

---

## 3. Widget Testing
Verifies UI component rendering, state transitions, and user interactions:
- `CollaborationHubScreen` message list rendering, sender badges, empty states, and message composer (`test/features/projects/presentation/collaboration_hub_screen_test.dart`).
- `ProjectStatusChip` visual state mapping, background colors, and labels across all 8 statuses (`test/features/projects/presentation/widgets/project_status_chip_test.dart`).

---

## 4. Negative & Security Testing
Verifies that failure boundaries and security rules cannot be breached:
- **Unauthorized Project Access:** Verifying HTTP 403 when an Engineer attempts to query or alter another user's project.
- **Role Enforcement:** Verifying that Engineers are blocked from calling Admin endpoints (e.g. `/api/projects/approve`, `/api/projects/:projectId/financials`).
- **File Limit Enforcement:** Uploading files exceeding 50 MB; verifying immediate termination with HTTP 400.
- **Workflow State Violations:** Attempting to transition non-draft projects with `submitProject()`.
- **Correction Round Limits:** Attempting a 4th correction request; verifying rejection with HTTP 400.
- **File Preview Fallbacks:** Attempting to preview non-renderable CAD files (`.dwg`, `.dxf`); verifying automatic fallback to browser download without text corruption.
