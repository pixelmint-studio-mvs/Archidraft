# ARCHI DRAFT

## Project Introduction
ARCHI DRAFT is a professional platform being developed for the Draughtsman Studio ecosystem. It manages architectural and technical drawing projects by seamlessly connecting Clients, Admins, and Draughtsmen in a secure, scalable, and mobile-first environment. 

## Quick Start for Developers
Welcome to ARCHI DRAFT. Before writing any code, follow these mandatory steps:

1. **Step 1:** Read `PROJECT_OVERVIEW.md` to understand the business logic.
2. **Step 2:** Read `SYSTEM_ARCHITECTURE.md` to understand the tech stack (Flutter + Firebase).
3. **Step 3:** Read `DEVELOPMENT_RULES.md` to understand the strict rules of this repository.
4. **Step 4:** Check `DEVELOPMENT_ROADMAP.md` to see the current development phase.
5. **Step 5:** Understand existing files and models before modifying anything.

## 🚨 Critical Rule
**Every AI agent and developer must understand:**
Never modify architecture, states, roles, security principles, or workflows without explicit approval. The system relies on strict Backend Callable Functions and Firestore Security Rules.

## Verification & Testing Commands

To run all automated checks locally before committing or integrating:

```bash
# 1. Run full Flutter test suite (152 tests)
flutter test

# 2. Run Flutter static analysis (must report no issues)
flutter analyze --no-fatal-infos

# 3. Check Cloudflare Worker TypeScript types
cd worker && npx tsc --noEmit

# 4. Run real backend authorization & handler integration tests (47 tests)
cd worker && npm test
```

## Document Map
- `README.md` - Start here.
- `docs/01_project/PROJECT_OVERVIEW.md` - Business problem and core purpose.
- `docs/01_project/CORE_WORKFLOW.md` - Step-by-step lifecycle of a project.
- `docs/01_project/USER_ROLES.md` - Exact permissions and provisioning rules for all user roles.
- `docs/02_architecture/STATE_MACHINES.md` - Immutable project, assignment, and correction enums.
- `docs/02_architecture/SYSTEM_ARCHITECTURE.md` - Hybrid client/server setup.
- `docs/02_architecture/BACKEND_ACTIONS.md` - Complete Cloudflare Worker API contracts & collaboration endpoints.
- `docs/02_architecture/DATA_ARCHITECTURE.md` - D1 SQL schema and relations.
- `docs/02_architecture/STORAGE_ARCHITECTURE.md` - Cloudflare R2 file storage categories and permissions.
- `docs/03_security/SECURITY_ARCHITECTURE.md` - Project authorization engine (`canUserAccessProject`) and RBAC.
- `docs/04_development/DEVELOPMENT_RULES.md` - General coding rules.
- `docs/04_development/DEVELOPMENT_ROADMAP.md` - Phase-by-phase execution plan.
- `docs/04_development/ENVIRONMENT_SETUP.md` - Prerequisites and installed SDK versions.
- `docs/05_quality/TESTING_STRATEGY.md` - Test commands, backend test harness architecture, and coverage.
- `docs/01_project/PROJECT_GLOSSARY.md` - Shared definitions to prevent confusion.

