# ENGINEER PORTAL — COMPLETE A-TO-Z IMPLEMENTATION RECORD

**Branch:** `Engineer_Panels`  
**Status:** Completed & Frozen for Engineer Scope  
**Source of Truth:** Current Working Codebase

---

## 1. Foundation
- **Flutter Framework:** Built with Flutter 3.x and Dart 3.x targeting both Mobile and Web.
- **State Management:** Riverpod (`flutter_riverpod`) with functional and class-based Notifiers (`ConsumerWidget`, `ConsumerStatefulWidget`).
- **Routing:** Declarative routing powered by `go_router` with role-based auth redirects in `AppRouter`.
- **Theme & Architecture:** Architectural design tokens (`AppColors`, `AppSpacing`, `AppTypography`), blueprint styling, and clean feature-based modularity under `lib/src/features/`.

---

## 2. Authentication
- **Firebase Authentication:** Handles user signup, login, email verification, and password resets.
- **JWT Verification:** Firebase JWT tokens passed as `Bearer <token>` to all Cloudflare Worker requests and cryptographically verified using Google's public x509 certificates.
- **Email Verification Guard:** Unverified accounts are routed to `/verify-email` before accessing dashboard routes.

---

## 3. Engineer Role Handling
- **Role Model:** The product role is **ENGINEER** (`UserRole.engineer`).
- **Self-Service Provisioning:** On registration, users provision their role via `POST /api/users`. The role is immutable once written.
- **Route Protection:** All `/engineer/**` routes verify `role == UserRole.engineer`.
- **Legacy Compatibility:** Legacy database columns (`client_id`) and status strings (`UNDER_CLIENT_REVIEW`) are mapped internally without exposing "Client" in the UI.

---

## 4. Engineer Shell & Navigation
- **App Shell:** Unified responsive navigation shell (`AppShell`) providing top app bar and drawer/rail navigation.
- **Primary Destinations:**
  - Projects: `/engineer/projects`
  - Activity Feed: `/engineer/activity`
  - Profile: `/engineer/profile`
- **Actions:** Quick access to Project Creation (`/engineer/projects/new`), Refresh, and Sign Out.

---

## 5. Engineer Profile
- **Repository:** `ProfileRepository` communicates with `GET /api/users/me` and `POST /api/users`.
- **Active Profile Fields:**
  - Name (`name`)
  - Mobile (`mobile`)
  - Date of Birth (`date_of_birth`)
  - Address (`address`)
  - Company Name (`company_name`)
  - Role (`role` — read-only display)
- **Validation:** Mobile phone validation and date formatting with Riverpod profile caching.

---

## 6. Project Creation Form
- **Route:** `/engineer/projects/new` (`ProjectFormScreen`).
- **Form Fields:**
  - Project Name (`project_name`)
  - Project Address (`project_address`)
  - Drawing Name (`drawing_name`)
  - Drawing Type (`drawing_type`: Architectural, Structural, Electrical, Plumbing, HVAC)
  - Project Area (`project_area` in sq ft)
  - Estimated Budget (`estimatedAmount`, non-billing project metadata)
  - Reference Files Uploader

---

## 7. Save Draft
- **Draft Persistence:** Unfinished forms can be saved at any time as `DRAFT` via `POST /api/projects`.
- **Idempotency:** Generates a project ID client-side or reuses the existing ID with `ON CONFLICT DO UPDATE`.
- **Editable Freedom:** In `DRAFT` status, all project fields and uploaded files remain fully editable and deletable.

---

## 8. Project Submission
- **Submission Action:** `POST /api/projects/submit` with unique `actionId`.
- **Transition:** Atomic state transition from `DRAFT` to `SUBMITTED`.
- **Audit Logging:** Server automatically logs `PROJECT_SUBMITTED` in D1 `activity_logs`.
- **Locking:** Once submitted, core project fields become immutable to the Engineer.

---

## 9. Cloudflare D1 Persistence
- **Database Engine:** Cloudflare D1 (SQLite at the edge).
- **Core Entities:** `projects`, `files`, `activity_logs`, `notifications`, `project_messages`, `users`.
- **Foreign Keys & Cascades:** Cascading deletes on project records to maintain database referential integrity.

---

## 10. File Upload Architecture
- **Worker Streaming:** Direct streaming from client to Cloudflare Worker to R2 via `TransformStream`.
- **50 MB File Protection:** Strict server-side byte limit tracking. Requests exceeding 50 MB are immediately severed.
- **Allowed Formats:** Allowlist validation: `.pdf`, `.dwg`, `.dxf`, `.png`, `.jpg`, `.jpeg`, `.zip`.
- **Idempotency:** Client passes `X-Action-Id`. Retries overwrite pending `REQUESTED` states without creating orphan records.

---

## 11. Cloudflare R2 Storage
- **Object Key Schema:** `projects/{projectId}/{category}/{actionId}_{sanitizedName}`.
- **Separation:** Strict category isolation prevents unauthorized overwriting:
  - `client_upload`: Project Brief reference drawings.
  - `draughtsman_version`: Drawing versions submitted by drafters.
  - `correction_attachment`: Specific markup files accompanying revisions.
  - `chat_attachment`: Files shared in the Collaboration Hub.

---

## 12. D1 File Metadata Lifecycle
- **Status Lifecycle:** `REQUESTED` → `COMPLETED` (or `FAILED` on transmission interruption).
- **Attributes Stored:** `id`, `project_id`, `uploaded_by`, `original_name`, `sanitized_name`, `object_key`, `content_type`, `size`, `category`, `status`.

---

## 13. Binary File Open Bug Fix
- **Discovered Issue:** Opening binary files (e.g., JPEG, PNG, PDF) on Web previously rendered garbled UTF-8 text strings due to missing MIME headers.
- **Architectural Solution:**
  1. **Authoritative Server MIME Resolution:** Worker maps extensions to precise MIME types (e.g. `image/jpeg`, `application/pdf`, `application/acad`).
  2. **Disposition Control:** Worker supports `?disposition=inline` for preview and `attachment` for downloads.
  3. **Blob & Object URL Generation:** Web client (`api_client_web.dart`) reads bytes, constructs a typed `html.Blob(bytes, mimeType)`, and generates an Object URL.
  4. **Native Preview Handling:** Images (`image/*`) and PDFs (`application/pdf`) open in a new browser tab with delayed revocation.
  5. **Safe CAD / ZIP Fallback:** Non-previewable formats (`.dwg`, `.dxf`, `.zip`) gracefully trigger a browser download instead of attempting text display.
  6. **Mobile/Desktop:** Uses `OpenFilex` on locally streamed files.

---

## 14. File Download
- **Mobile/Desktop:** Direct streaming via `dart:io` `File.openWrite()` directly to disk, avoiding memory bloat.
- **Web:** Clean download trigger via `html.AnchorElement` with explicit download attribute.

---

## 15. File Delete
- **Worker Endpoint:** `DELETE /api/projects/:projectId/files/:fileId`.
- **Safety:** Verifies project ownership and removes file from both R2 storage and D1 metadata.
- **Activity Log:** Automatically logs `FILE_DELETED` in `activity_logs`.

---

## 16. Project Details Screen
- **Route:** `/engineer/projects/:projectId` (`ProjectDetailScreen`).
- **Layout:**
  - Header with Status Chip, Project Name, Drawing Type, and Area.
  - Primary Action Bar: Contextual actions based on project status.
  - Collaboration Hub section card and app bar shortcut.
  - Project Info & Metadata (Budget, Address, Date).
  - Reference Files card (with Upload, Open, Download, Delete).
  - Drawing Versions card (versions submitted by Draughtsman).
  - Project Activity section.

---

## 17. Workflow State Display
- Status-specific action buttons:
  - `DRAFT`: **Submit Project** / **Edit Draft**.
  - `UNDER_CLIENT_REVIEW`: **Approve Drawing** (`approve-final`) / **Request Correction** (`request-correction`).
  - Terminal states (`COMPLETED`, `CANCELLED`): Read-only view.

---

## 18. Scoped Engineer Activity Feed
- **Routes:** `/engineer/activity` (`EngineerActivityScreen`) and project-level activity in details.
- **Engineer Scoping:** The Worker endpoint `GET /api/activity` filters activity exclusively to projects where `client_id = uid`.
- **Excluded Events:** Internal administrative actions (`ASSIGNMENT_REJECTED`, `DRAUGHTSMAN_REASSIGNED`) and financial logs (`INVOICE_CREATED`, `PAYMENT_RECORDED`) are filtered out.
- **Sanitization:** UI sanitizes internal identifiers (e.g., `client_upload` → "Project Brief").

---

## 19. Notifications System
- **Persistence:** Stored in Cloudflare D1 `notifications` table.
- **Notification Types:** `CHAT_MESSAGE`, `DRAWING_SUBMITTED`, `ASSIGNMENT_ACCEPTED`, `CORRECTION_REQUESTED`, `PROJECT_COMPLETED`.
- **Read State:** Mark as read via `POST /api/notifications/:id/read`.

---

## 20. Responsive Layouts
- Responsive breakpoints adapting seamlessly between Desktop Web, Tablet, and Mobile.
- Sized bounds, adaptive side drawer / navigation rail, and scrollable containers.

---

## 21. UX States
- **Loading:** Uniform `AppLoadingIndicator` with blueprint spinner.
- **Empty:** Contextual empty states for projects, files, activities, and messages.
- **Error:** User-friendly error banners and retry buttons via `AppErrorWidget`.
- **Success:** Floating feedback snackbars for saved drafts, submissions, and downloads.

---

## 22. Preliminary Estimates
- **Location:** Project Creation Form (`_buildEstimateCard`) and Project Details metadata.
- **Content:**
  - `EST. COST: --`
  - `TIMELINE: --`
  - Notice: `*Automated estimates are not currently available. Estimates will be shown here when calculation data is available.`
- **No Payment Logic:** Preserved strictly as preliminary draft metadata with no billing mechanics.

---

## 23. Complete Financials Removal
- **No Engineer Financials:** The Engineer Portal contains zero payment buttons, checkout flows, invoices, billing sections, transaction logs, or financial dashboards.
- **Routes Removed:** `/engineer/projects/:projectId/financials` excised from `AppRouter`.
- **UI Elements Removed:** Financials icon removed from Project Details AppBar.
- **Worker Lockdown:** `GET /api/projects/:projectId/financials` restricted strictly to `STUDIO_ADMIN` (returns 403 Forbidden to Engineers).

---

## 24. Collaboration Hub
- **Route:** `/engineer/projects/:projectId/collaboration-hub` (`CollaborationHubScreen`).
- **Concept:** Shared real-time project discussion hub connecting the Engineer and Draughtsman.
- **Features:**
  - Message bubble list with role badges (`Engineer`, `Draughtsman`).
  - Auto-scrolling to bottom on new messages.
  - Multi-line text composer with send button.
  - File picker button supporting attachments up to 50 MB.
  - Loading, empty, and error state handling.

---

## 25. Chat Persistence
- **Table:** Cloudflare D1 `project_messages` (Migration `0008_project_messages.sql`).
- **Columns:** `id`, `project_id`, `sender_id`, `sender_name`, `sender_role`, `message`, `attachment_file_id`, `created_at`.
- **Endpoints:** `GET /api/projects/:projectId/messages` and `POST /api/projects/:projectId/messages`.

---

## 26. Chat Attachments
- **Flow:** User selects file → Streamed to Worker as category `chat_attachment` → Stored in R2 → Linked to message via `attachment_file_id`.
- **Rendering:** Messages display attachment preview cards with file name, size, and one-click download/open.

---

## 27. CHAT_MESSAGE Notifications
- When an Engineer sends a message, a `CHAT_MESSAGE` notification is automatically generated in D1 for the assigned Draughtsman (`targetUserId = project.draughtsman_id`).

---

## 28. Security & RBAC
- **Token Verification:** Every request validated against Firebase Auth public keys.
- **Ownership Verification:** Engineers can only access projects where `client_id == uid`.
- **Server-Side Enforcement:** Direct access to D1 and R2 is blocked; all traffic flows through Worker middleware.

---

## 29. Testing & Quality
- **Flutter Analyze:** 0 errors, 0 warnings (`flutter analyze --no-fatal-infos`).
- **Flutter Tests:** 63 passing unit and widget tests covering `CollaborationHubScreen`, `ProjectMessage`, `ProjectStatusChip`, and `Validators`.
- **Worker Typecheck:** 0 TypeScript compilation errors (`npm run typecheck`).

---

## 30. Current Engineer Completion Status
- The Engineer Portal feature set is **COMPLETED and FROZEN** on branch `Engineer_Panels`.
- All Engineer-facing flows (Auth, Projects, Files, Workflow, Hub, Activity, Profile) are operational.

---

## 31. Deferred Cross-Role Integration
- **Cross-Portal Verification:** End-to-end verification between the Engineer Portal and Draughtsman Portal running simultaneously is deferred until the respective branches (`Engineer_Panels` and `Draughtsman_Panels`) are merged.
- **Admin Assignment Flow:** Admin project approval and assignment testing deferred until integration.

---

## 32. Future Admin Integration
- Admin dashboard metrics, user directory controls, and administrative financials remain isolated on backend endpoints for future administrative panel development.
