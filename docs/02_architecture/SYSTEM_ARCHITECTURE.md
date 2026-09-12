# SYSTEM ARCHITECTURE

## CLIENT APPLICATION
- **Flutter Application:** Handles UI, user interaction, authentication state, authorized reads, and simple operations.

## BACKEND
Use a **hybrid architecture** combining direct API reads with Cloudflare Workers.

### 1. Simple Operations
*(Flutter → Cloudflare Worker API)*
Operations that involve a single entity and simple whitelist validation (e.g., saving a draft, updating a user profile).

### 2. Critical Operations
*(Flutter → Cloudflare Workers → Cloudflare D1)*
Critical actions must validate:
- Authentication (`context.auth`)
- User role
- Project Ownership / Assignment
- Current project state
- Allowed transitions

## CRITICAL ACTIONS
The following actions must NOT be implemented as uncontrolled client-side state changes. They must be executed via Cloudflare Workers running Database Transactions:

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
