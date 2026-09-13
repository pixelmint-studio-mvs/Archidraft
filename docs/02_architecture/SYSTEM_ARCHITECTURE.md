# SYSTEM ARCHITECTURE

## CLIENT APPLICATION
- **Flutter Application:** Handles UI, user interaction, authentication state, authorized reads, and simple operations.

## BACKEND
Use a **hybrid architecture** combining direct D1 metadata operations via the Cloudflare Worker API.

### 1. Operations
*(Flutter → Cloudflare Worker API → D1 / R2)*
All state changes and file storage operations are mediated by the Worker API.

### 2. Critical Operations
*(Flutter → Cloudflare Worker API)*
Critical actions must validate:
- Authentication (`context.auth`)
- User role
- Project Ownership / Assignment
- Current project state
- Allowed transitions

## CRITICAL ACTIONS
The following actions must NOT be implemented as uncontrolled client-side state changes. They must be executed via Callable Cloud Functions running Transactions:

- `submitProject()`
- `approveProject()`
- `rejectProject()`
- `assignDraughtsman()`
- `acceptAssignment()`
- `rejectAssignment()`
- `requestCorrection()`
- `resolveCorrection()`
- `submitDrawing()`
- `approveFinal()`
- `cancelProject()`
