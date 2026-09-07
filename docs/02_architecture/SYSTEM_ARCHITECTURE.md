# SYSTEM ARCHITECTURE

## CLIENT APPLICATION
- **Flutter Application:** Handles UI, user interaction, authentication state, authorized reads, and simple operations.

## BACKEND
Use a **hybrid architecture** combining direct Firestore operations with Callable Cloud Functions.

### 1. Simple Operations
*(Flutter → Direct Firestore SDK)*
Operations that involve a single document and simple whitelist validation (e.g., saving a draft, updating a user profile).

### 2. Critical Operations
*(Flutter → Callable Cloud Functions → Firebase Admin SDK → Firestore)*
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
