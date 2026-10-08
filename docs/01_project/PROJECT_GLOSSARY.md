# PROJECT GLOSSARY

To ensure consistent communication across developers and AI agents, all terms must follow these authoritative definitions:

---

## 1. Actor & Organization Terms

- **Engineer:** The professional architectural or civil engineer who requests technical drawings. They own the project, upload references, review drawing versions, request revisions, and grant final approval.
- **Draughtsman:** The technical CAD/drafting professional assigned to execute technical drawings for a project.
- **Student:** An educational user participating in studio learning workflows.
- **Studio Admin:** The studio manager who approves submitted projects and manages draughtsman assignments.
- **Client (Legacy):** Internal terminology used in early project documentation and preserved in legacy database tokens (`client_id`, `role='CLIENT'`). In all user-facing contexts, this is **Engineer**.

---

## 2. Project & Workflow Entities

- **Project:** The central project record in Cloudflare D1 (`projects` table). It tracks macro lifecycle state, project metadata, and ownership.
- **Assignment:** A dispatch record (`assignments` table) linking a Project to a specific Draughtsman (`PENDING`, `ACCEPTED`, `REJECTED`, `REPLACED`).
- **Drawing Version:** A drawing submitted by a Draughtsman (`drawing_versions` table), linked to an R2 object and tracking version numbers.
- **Correction:** A formal, tracked revision request by an Engineer (`corrections` table) detailing required adjustments.
- **Correction Round:** Counter incremented on each correction request. Capped at a hard maximum of **3 rounds**.
- **Activity Log:** An immutable, server-generated audit record (`activity_logs` table) created upon critical state changes.
- **Collaboration Hub:** The project-scoped real-time messaging interface enabling technical discussion between the Engineer and Draughtsman.
- **Project Message:** A message persisted in Cloudflare D1 (`project_messages` table), with optional file attachment metadata.
- **Preliminary Estimate:** Preliminary project timeline and cost indicators displayed during project creation (`EST. COST: --`, `TIMELINE: --`) with no billing logic.

---

## 3. Storage & Infrastructure Terms

- **Cloudflare Worker:** The serverless Hono TypeScript backend running at the edge. Handles all authentication, validation, state transitions, and file streaming.
- **Cloudflare D1:** The serverless SQLite-compatible relational database storing all structured application entities.
- **Cloudflare R2:** S3-compatible object storage for binary files (PDF, DWG, DXF, images, ZIP), accessible exclusively via streaming through the Worker API.
- **Firebase Authentication:** Managed authentication provider issuing JWT tokens, verified by the Cloudflare Worker via public keys.
- **Action ID (`actionId`):** A client-generated UUID used as an idempotency token to ensure network retries do not duplicate operations or audit logs.
- **File Category:** Sub-bucket classification for files:
  - `client_upload`: Project Brief reference files (User-facing: "Project Brief").
  - `draughtsman_version`: Drawing versions uploaded by draughtsmen (User-facing: "Drawing Version").
  - `correction_attachment`: Files accompanying a correction request (User-facing: "Correction Attachment").
  - `chat_attachment`: Files shared within the Collaboration Hub.
