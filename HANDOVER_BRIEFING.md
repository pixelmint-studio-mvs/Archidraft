# ARCHI DRAFT — AGENT HANDOVER BRIEFING

**To:** Next AI Agent (Claude / Assistant)
**From:** Antigravity Architect Agent
**Date:** September 6, 2026
**Status:** Pre-Development Planning Complete 🟢 (Ready for Phase 1)

---

## 📌 PROJECT CONTEXT
**ARCHI DRAFT** is a professional, premium application for an architectural firm (Draughtsman Studio). It manages the entire workflow of architectural drafting projects between **Clients**, **Draughtsmen**, and **Admins**. 

We have spent the entire session strictly analyzing and planning the architecture. **Zero production code has been written.** The goal was to create a flawless, secure, and highly scalable blueprint before a single line of Flutter or Firebase code is written.

---

## 📂 CURRENT STATE OF THE PROJECT
The project is currently at **Phase 0 (Pre-Implementation)**. 
A comprehensive 23-file documentation suite has been meticulously prepared and organized into the `docs/` folder. This is the absolute source of truth for the project.

**Folder Structure:**
```text
ARCHI_DRAFT/
├── README.md
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

1. **Strict State Machines:** Project states (e.g., `DRAFT`, `WAITING_ASSIGNMENT`, `UNDER_CLIENT_REVIEW`, `COMPLETED`) and Correction states (`OPEN`, `IN_PROGRESS`, `RESOLVED`) are strictly defined. **DO NOT invent new enums or silently alter workflows.** See `STATE_MACHINES.md`.
2. **Backend Authority:** UI does not equal security. All critical state transitions (submitting a project, assigning a draughtsman, requesting a correction) MUST be executed via **Callable Cloud Functions (Node.js)** using the Admin SDK. The client app never directly alters critical states. See `BACKEND_ACTIONS.md`.
3. **Immutable Activity Logs:** Every state change generates an Activity Log via the backend. The client CANNOT write to the activity logs collection.
4. **Storage Compartmentalization:** Firebase Storage is strictly divided at the folder level (`client_uploads/`, `draughtsman_versions/`, `correction_attachments/`). Users can only write to their designated folders to prevent malicious overwrites. See `STORAGE_ARCHITECTURE.md`.
5. **Role-Based Access Control (RBAC):** Users are securely identified via `context.auth.uid` in Cloud Functions. Never trust a `userId` passed in a payload.

---

## 🚀 YOUR IMMEDIATE NEXT STEPS

When you take over, **DO NOT randomly start building UI screens.** Follow the roadmap systematically:

### 1. Verify Environment Setup
Check with the human developer that the local environment (Git, Flutter SDK, Android Studio, Java) is fully installed and ready as per `ENVIRONMENT_SETUP.md`. 
*(Note: A minor team decision regarding the State Management package — Provider vs. Riverpod vs. Bloc — needs to be finalized).*

### 2. Execute Phase 1 (Project Foundation)
Refer to `DEVELOPMENT_ROADMAP.md`. Your first technical tasks will be:
- Initializing the Flutter project (`flutter create`).
- Setting up the Git repository based on `GIT_WORKFLOW.md`.
- Configuring the base routing (e.g., `go_router`) and the premium, architectural theme defined in `BRAND_AND_DESIGN_DIRECTION.md`.

### 3. Follow the AI Protocol
Before modifying any files, read `docs/07_ai_agents/AI_AGENT_PROTOCOL.md`. Ensure your outputs include the mandatory summary format (Files Modified, What Changed, Why, Testing Performed).

Good luck. The blueprint is solid, secure, and ready for you to bring to life.
