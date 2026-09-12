# ARCHI DRAFT — AGENT HANDOVER BRIEFING

**To:** Next AI Agent
**From:** Antigravity Architect Agent
**Date:** September 13, 2026
**Status:** Phase 7 Complete 🟢 (Ready for Phase 8 - R2 Integration)

---

## 📌 PROJECT CONTEXT
**ARCHI DRAFT** is a professional, premium application for an architectural firm (Draughtsman Studio). It manages the entire workflow of architectural drafting projects between **Clients**, **Draughtsmen**, and **Admins**. 

We have spent the latest session executing a massive **Cloudflare Backend Pivot**.

---

## 📂 CURRENT STATE OF THE PROJECT
The project has successfully pivoted away from a Firebase-heavy backend. We have completed **Phase 7 (Cloudflare Architecture Verification & Migration)**. 

### Current Status

- **Phase 1-5:** COMPLETED. (Flutter Foundation, UI Shells, Client Project Brief Submission, Multi-step forms).
- **Phase 6 (Studio Admin & Task Allocation):** COMPLETED. Implemented Cloudflare Workers backend for assignment workflows with D1 database batch transactions.
- **Phase 7 (Cloudflare Backend Pivot & Firebase Removal):** COMPLETED.
  - **Firebase Auth** remains the sole identity provider.
  - **Firestore & Cloud Functions** have been COMPLETELY REMOVED from the Flutter client (`pubspec.yaml`).
  - **Cloudflare Workers (Hono)** is now the authoritative application/backend layer.
  - **Cloudflare D1** is now the authoritative relational application database for users, projects, and assignments.
  - All profile-related logic in `AuthRepository` and `ProfileRepository` now routes through the `ApiClient` to the `/api/users` REST endpoints.
- **Next Up (Phase 8 - Cloudflare R2 Storage):** PENDING. Focus on implementing R2 for project file/drawing storage (replacing Firebase Storage).

A comprehensive documentation suite has been prepared in the `docs/` folder. This is the absolute source of truth for the project.

**Folder Structure:**
```text
ARCHI_DRAFT/
├── README.md
├── backend/ (Cloudflare Workers, Hono, D1 Schema, Wrangler config)
├── docs/
│   ├── 01_project/ (Overview, Workflows, Roles)
│   ├── 02_architecture/ (System, Data, States, Storage, Backend Actions)
│   ├── 03_security/ (Security Principles, Secrets Policy, Error Handling)
│   ├── 04_development/ (Tech Stack, Git, Environment, Roadmap, Rules)
│   ├── 05_quality/ (Testing Strategy, Consistency Audit)
│   ├── 06_design/ (Brand Direction)
│   └── 07_ai_agents/ (AI Agent Protocol, Pre-Dev Checklist)
```

---

## 🏛️ CORE ARCHITECTURAL RULES TO KNOW
As you begin development, you MUST adhere to the following locked architectural decisions:

1. **Cloudflare Authority:** The UI does not equal security. All critical state transitions (submitting a project, assigning a draughtsman) MUST be executed via the **Cloudflare Worker API**. The client app never directly alters critical states.
2. **Provider State Management:** Because D1 is not a real-time database like Firestore, the client uses `FutureProvider`. UI mutations must manually call `ref.invalidate()` on the appropriate providers after a successful API mutation to fetch fresh data.
3. **Strict State Machines:** Project states and correction states are strictly defined. **DO NOT invent new enums or silently alter workflows.**
4. **Role-Based Access Control (RBAC):** Users are securely identified via JWT token verification in the Cloudflare Worker (`auth.ts` middleware verifies Firebase ID tokens). Never trust a `userId` passed in a JSON payload for authorization.

---

## 🚀 YOUR IMMEDIATE NEXT STEPS

When you take over, **DO NOT randomly start building UI screens.** Follow the roadmap systematically:

### 1. Phase 8 (Cloudflare R2 Storage)
- Set up Cloudflare R2 for storing project blueprints and proof documents.
- Integrate R2 into the `backend` Worker (presigned URLs or direct worker streaming).
- Refactor the Flutter client to upload/download files via the API.

Good luck. The blueprint is solid, secure, and ready for you to bring to life.
