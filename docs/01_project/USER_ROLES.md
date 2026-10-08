# USER ROLES & ACCESS CONTROL

ARCHI DRAFT enforces strict Role-Based Access Control (RBAC) across the Flutter client application and Cloudflare Worker API.

---

## 1. Active Product Roles

### 1. ENGINEER
The Engineer is the primary client-facing technical user who creates and manages project briefs.

> [!NOTE]
> **Compatibility Note:** In early baseline documentation, this role was labeled "CLIENT". While internal database columns (`client_id`) and enum strings (`UNDER_CLIENT_REVIEW`) retain this naming for backward compatibility, the user-facing role, UI copy, and domain models represent this user exclusively as **ENGINEER**.

**Engineer Capabilities:**
- Register and authenticate via Firebase Auth.
- Select role during registration (`ENGINEER`, `DRAUGHTSMAN`, `STUDENT`).
- Complete personal and professional profile details (Name, Mobile, Date of Birth, Address, Company Name).
- Create architectural projects and save them as `DRAFT`.
- Upload and manage Project Brief technical reference files (PDF, DWG, DXF, PNG, JPEG, ZIP up to 50 MB).
- Formally submit projects (`DRAFT` → `SUBMITTED`).
- Access the **Collaboration Hub** to chat with the assigned Draughtsman and share file attachments.
- Review submitted drawing versions (`UNDER_CLIENT_REVIEW`).
- Request structured corrections with descriptive feedback (Maximum 3 rounds).
- Approve final drawings (`COMPLETED`).
- View a personal, scoped Activity Feed reflecting events from their owned projects.
- Receive project notifications (e.g. `CHAT_MESSAGE`, `DRAWING_SUBMITTED`, `ASSIGNMENT_ACCEPTED`).

**Engineer Strict Boundaries:**
- **NO Financials / Payments:** Engineers cannot view billing, make payments, request invoices, view financial cards, or access financial dashboards.
- Cannot assign Draughtsmen or approve submitted projects for assignment (Admin responsibility).
- Cannot access projects owned by other Engineers.
- Cannot modify their user role post-registration.

---

### 2. DRAUGHTSMAN
The Draughtsman is the drafting professional executing architectural and CAD work.

**Draughtsman Capabilities:**
- Register, authenticate, and manage drafter profile (including qualification and college).
- View pending project assignments directed to them (`WAITING_ACCEPTANCE`).
- Accept (`IN_PROGRESS`) or reject assignments.
- View assigned project briefs and download authorized reference files.
- Communicate with the Engineer via the project **Collaboration Hub**.
- Upload drawing versions and submit them for review (`UNDER_CLIENT_REVIEW`).
- Resolve correction requests across rounds.

**Draughtsman Strict Boundaries:**
- Cannot access unassigned projects or projects where their assignment was replaced.
- Cannot modify Engineer project metadata or reassign projects.
- Cannot access other Draughtsmen's private workspaces.

---

### 3. STUDENT
The Student role is designed for educational access and training within the Draughtsman Studio ecosystem.
- Self-service registration available during signup.
- Structured learning and observation workflows (managed under `Student_panels`).

---

### 4. STUDIO ADMIN
The Administrator manages studio operations and assignment dispatching.

**Admin Capabilities:**
- Review submitted projects (`SUBMITTED`).
- Approve projects for assignment (`WAITING_ASSIGNMENT`) or reject them (`CANCELLED`).
- Assign and reassign Draughtsmen to projects (`WAITING_ACCEPTANCE`).
- Monitor system-wide project metrics, assignment queues, and user directories.
- Manage internal studio financial records and invoicing (Admin-only backend capabilities).

**Admin Strict Boundaries:**
- Normal self-service registration can never grant Admin privileges. Admin roles are strictly provisioned by database administrators.

---

## 2. Legacy / Compatibility Terminology Mapping

| Context | Internal / Database Token | Product / User-Facing Name | Purpose / Rationale |
|---|---|---|---|
| Projects Table | `client_id` | Engineer ID | Foreign key in D1 linking projects to the owning user. |
| Files Category | `client_upload` | Project Brief | Files uploaded by the Engineer as reference material. |
| Project Status | `UNDER_CLIENT_REVIEW` | Under Review | State where the drawing is awaiting the Engineer's review. |
| Users Table | `role = 'CLIENT'` | Engineer | Historical role string normalized to `ENGINEER` in the app. |
