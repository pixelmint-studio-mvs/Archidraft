# PROJECT OVERVIEW

## What is ARCHI DRAFT?
ARCHI DRAFT is a professional architectural drafting and collaboration platform developed for the Draughtsman Studio ecosystem. It serves as a secure, managed technical bridge between licensed Engineers who create technical project briefs, review drawings, and coordinate drafting revisions, and professional Draughtsmen who execute the technical drafting work under administrative supervision.

---

## Current Architecture & Scope (Active State)

> [!NOTE]
> **Historical Baseline Note:** Early project documentation referred to the primary client-facing role as "CLIENT", assumed Google Cloud Firestore and Firebase Storage, and anticipated Firebase Cloud Functions. The platform has since evolved into a production-grade edge architecture powered by **Cloudflare Workers (Hono)**, **Cloudflare D1 (SQL)**, **Cloudflare R2 (Object Storage)**, and **Firebase Authentication**.

### Core Product Capabilities (Engineer Portal)
1. **Engineered Project Creation & Briefing:** Engineers create structured project briefs (Project Name, Address, Drawing Name, Drawing Type, Project Area, and Estimated Budget).
2. **Draft Persistence & Submission:** Full offline/online draft saving and formal idempotent project submission to Cloudflare D1.
3. **Secure File Management:** Upload, view, inline preview, download, and delete technical reference files (PDF, CAD DWG/DXF, PNG, JPEG, ZIP) stored in Cloudflare R2 with strict 50 MB limits.
4. **Project Collaboration Hub:** Real-time, project-scoped messaging and technical query resolution between the Engineer and assigned Draughtsman with file attachments.
5. **Scoped Activity Feed:** Real-time lifecycle audit log filtered exclusively to the authenticated Engineer's owned projects.
6. **Preliminary Estimates:** Standardized preliminary estimation display (`EST. COST: --`, `TIMELINE: --`) without fake or unverified financial logic.
7. **Complete Financials Removal:** All billing, payments, checkout, invoicing, transaction history, and financial dashboards have been **completely excised** from the Engineer-facing product.

---

## Main Roles in ARCHI DRAFT

- **ENGINEER:** Licensed architectural/civil engineer requesting technical drawings. They create project drafts, upload reference blueprints, review draughtsman submissions, request revisions (up to 3 rounds), communicate via the Collaboration Hub, and approve final drawings.
- **DRAUGHTSMAN:** Technical drafting professional assigned to projects. They inspect technical briefs, execute CAD drawings, upload revisions, and coordinate directly with engineers.
- **STUDENT:** Educational user participating in architectural drafting learning workflows.
- **ADMIN:** Studio management role overseeing assignments, draughtsman allocations, and ecosystem governance.

*(Note: In legacy database tables and status enums, internal tokens such as `client_id` and `UNDER_CLIENT_REVIEW` are preserved strictly for backend compatibility. In the product UI, the role is exclusively **ENGINEER**).*

---

## Core Purpose & Lifecycle

```text
[ ENGINEER ]
    │
    ▼ (Save Draft / Submit Project)
[ DRAFT ] ──► [ SUBMITTED ]
                  │
                  ▼ (Studio Admin Approves & Assigns)
              [ WAITING_ASSIGNMENT ] ──► [ WAITING_ACCEPTANCE ]
                                              │
                                              ▼ (Draughtsman Accepts)
                                         [ IN_PROGRESS ] ◄─────────────────┐
                                              │                            │
                                              ▼ (Draughtsman Submits)      │ (Correction
                                         [ UNDER_CLIENT_REVIEW ]           │  Requested,
                                              │                            │  Max 3 rounds)
                       ┌──────────────────────┴──────────────────────┐     │
                       ▼ (Approve Drawing)                           ▼     │
                 [ COMPLETED ]                             [ CORRECTION_REQUESTED ]
```

1. **Submission:** The Engineer creates a project draft and submits it once reference blueprints are attached.
2. **Review & Assignment:** Studio Admin approves the project and assigns an available Draughtsman.
3. **Execution:** The Draughtsman accepts the assignment, reviews references, and prepares drawings in `IN_PROGRESS`.
4. **Collaboration:** The Engineer and Draughtsman coordinate drafting nuances and revisions via the **Collaboration Hub**.
5. **Review & Corrections:** The Engineer reviews submitted drawing versions. Up to **3 correction rounds** are supported.
6. **Final Approval:** The Engineer approves the drawing, transitioning the project to `COMPLETED`.
