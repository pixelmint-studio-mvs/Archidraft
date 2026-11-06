# ARCHI DRAFT × PIXMINT — INTEGRATION & RECENT FIXES REPORT

**Workspace:** `D:\PROJECT\Archidraft-integration-workspace`
**Active Delivery Branch:** `COMPLETED-INTERGRATION` (HEAD: `f21fb29`)
**Scope:** Architectural synchronization and comprehensive documentation of recent platform fixes

---

## 1. Executive Summary

This report documents the architectural improvements, contract normalizations, and user experience fixes recently implemented across the Archi Draft Studio multi-portal platform and PIXMINT BOT integration.

All fixes have been verified against active source code, validated via automated test harnesses, and documented with strict adherence to security and confidentiality rules.

---

## 2. Comprehensive Documentation of Recent Fixes

### A. Firebase Staging Compile-Time Configuration
- **File Reference:** `lib/firebase_options.dart`
- **Implementation:**
  ```dart
  class DefaultFirebaseOptions {
    static const bool _isStaging = bool.fromEnvironment('STAGING', defaultValue: false);

    static FirebaseOptions get currentPlatform {
      if (kIsWeb) {
        return _isStaging ? webStaging : web;
      }
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return _isStaging ? androidStaging : android;
        // ...
      }
    }
  ```
- **Operational Requirement:** To build or run Flutter Web against the staging Firebase environment, compile with:
  ```bash
  --dart-define=STAGING=true
  ```
- **Architectural Rules:**
  1. Omitting the flag selects the default production Firebase configuration (`archi-draft`).
  2. Enabling the flag selects the staging Firebase configuration (`archi-draft-staging`).
  3. This flag strictly selects the Firebase configuration; it does **not** launch the Cloudflare Worker and does **not** ensure user accounts are registered.
  4. The Worker API base URL is a separate configuration concern (`--dart-define=API_URL=...`). In debug mode, `API_URL` defaults to `http://localhost:8787`.

---

### B. PIXMINT Admin Control Center Brand Logo
- **Asset Location:** `apps/admin-web/public/images/pixmint-bot-logo.jpeg`
- **Component Reference:** `apps/admin-web/src/components/admin/PixmintBotControlCenter.tsx`
- **Implementation:**
  ```tsx
  <Image
    src="/images/pixmint-bot-logo.jpeg"
    alt="PIXMINT BOT 2.0 logo"
    width={48}
    height={48}
    className="rounded-xl shadow-xs object-cover border border-slate-200"
  />
  ```
- **Asset Convention:** Public static images must be stored within `apps/admin-web/public/images/` and referenced using root-relative paths (`/images/...`) to prevent broken relative imports across deep routes such as `/settings/pixmint-bot`.

---

### C. PIXMINT Flutter Chat Input Readability Fix
- **File Reference:** `scratch/pixmint-bot/lib/src/presentation/sheet/pixmint_chat_input.dart`
- **Problem Statement:** Text entered by users into the chat input bar lacked explicit color styling, resulting in unreadable white-on-white or low-contrast text on certain browser themes.
- **Implementation:**
  ```dart
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: _focusNode.hasFocus ? PixmintBotTheme.emerald : const Color(0xFFCBD5E1),
      width: 1.2,
    ),
  ),
  child: TextField(
    controller: _textController,
    focusNode: _focusNode,
    cursorColor: Colors.black,
    style: const TextStyle(
      color: Colors.black,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    decoration: const InputDecoration(
      hintText: 'Ask a question...',
      hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
      filled: true,
      fillColor: Colors.white,
      border: InputBorder.none,
      // ...
    ),
  )
  ```
- **Verification:** User input text is dark, sharp, and readable against the white container. Cursor and focus borders provide explicit visual feedback. Message submission, keyboard shortcuts, and thinking indicators remain unchanged.

---

### D. User Directory, Profile Modal, and Full Dossier
- **File References:**
  - `apps/admin-web/src/components/ui/Modal.tsx`
  - `apps/admin-web/src/lib/api.ts` (`getUserDetails`)
  - `apps/admin-web/src/app/engineers/[id]/page.tsx`
  - `apps/admin-web/src/app/draughtsmen/[id]/page.tsx`
  - `apps/admin-web/src/app/students/[id]/page.tsx`
- **Root Cause & Fix:**
  1. **Quick-View Modal Sizing:** Previous modal constraints (`max-w-md`, `max-w-lg`) caused horizontal cramping and clipped role badges. Updated `Modal.tsx` to support `maxWidth="2xl"` with responsive padding, vertical height clamping (`max-h-[92vh]`), and internal scrolling.
  2. **API Contract Normalization:** The Worker endpoint `/api/users/[id]` returned varying response structures across roles and legacy endpoints. `getUserDetails(userId)` now normalizes both nested payloads (`{ user, projects }`) and flat payloads (`{ id, email, role, ... }`).
  3. **Role-Specific Lookups:**
     - Engineers: Scoped by `projects.filter(p => p.client_id === userId)`.
     - Draughtsmen: Fetches assignments via `getAdminAssignments({ draughtsmanId: userId })`, falling back to project filter.
     - Students: Fetches training assignments from `/api/admin/students/[id]`.
  4. **State Handling:** Implements dedicated, unmasked UI states for loading, 401/403 authorization errors, 404 missing user profiles, network connection drops, and empty project rosters.
- **Automated Test Validation:** Verified by `apps/admin-web/test/user-dossier-contracts.test.ts` (5/5 tests passed).

---

### E. Admin Activity Feed Architecture & Fix
- **File References:**
  - Route: `/activity` (`apps/admin-web/src/app/activity/page.tsx`)
  - Endpoint: `GET /api/activity` (`worker/src/index.ts`)
  - Table: `activity_logs`
- **Root Cause & Fix:**
  1. **Inner Join Dropped Events:** The Worker query previously joined `JOIN projects p ON a.project_id = p.id`. Any activity record with a null `project_id` (system events, user logins, status updates) was silently excluded from the result set. Changed to `LEFT JOIN projects p ON a.project_id = p.id`.
  2. **Query Validation:** Added `limit` query parameter clamping (`Math.min(Math.max(parseInt(limitParam || '100', 10), 1), 500)`).
  3. **Role Authorization:**
     - `ADMIN` & `STUDIO_ADMIN`: Global audit stream.
     - `CLIENT` & `ENGINEER`: Scoped to projects owned by the user.
     - `DRAUGHTSMAN`: Scoped to projects assigned to the draughtsman.
     - Other roles / unauthenticated: Rejected with 403 / 401.
  4. **Background Polling Resiliency:**
     - Live poll interval: 15 seconds.
     - Network Sync Retries: If background polling fails, previously retrieved records remain rendered on screen while an ambient warning banner alerts the user.
     - Dedicated Error Cards: Distinguishes between authorization failure (401/403), server error (500), and a truthful empty D1 table (0 genuine events recorded).
- **Automated Test Validation:**
  - Verified by `apps/admin-web/test/activity-feed.test.ts` (6/6 tests passed).
  - Verified by `worker/test/backend_authorization.test.mjs` (8/8 activity tests passed).

---


---

### F. 3D Brand Monogram Viewer & Top-Left Admin Panel Branding
- **File References:**
  - `apps/admin-web/src/components/ui/Monogram3DViewer.tsx`
  - `apps/admin-web/src/components/layout/Header.tsx`
  - `apps/admin-web/src/components/layout/Sidebar.tsx`
- **Problem Statement:**
  1. The 3D architectural monogram logo in the top-left corner was throwing `ReferenceError: clock is not defined` (`Cannot find name 'clock'`) upon loading the GLTF model at line 170 (`clock.start()`), following deprecation of `THREE.Clock`.
  2. When the sidebar was collapsed or viewing responsive viewports, no brand monogram was rendered in the top-left header bar, leaving the brand header blank.
- **Implementation & Fix:**
  1. **High-Resolution Frame Timing:** Replaced deprecated `THREE.Clock` with high-precision `performance.now()` delta calculations (`Math.min((now - lastTime) / 1000, 0.1)`). Initialized `lastTime` in component effect scope and updated on GLTF model load completion, eliminating the ReferenceError and all Three.js deprecation warnings.
  2. **Top-Left Persistent Branding:** Integrated `<Monogram3DViewer />` into `Header.tsx`. When the sidebar is collapsed, a 32×32px graphite 3D monogram viewer automatically anchors into the top-left corner of the header next to the toggle button, guaranteeing continuous brand presence.
  3. **Verification:** Both expanded sidebar and collapsed header render the smooth, ambiently rotating 3D monogram with zero console errors or TypeScript compile issues.

---

### G. Help Desk & Incident Dispatch System
- **File References:**
  - `worker/src/helpdesk.ts`
  - `worker/src/index.ts`
  - `apps/admin-web/src/app/helpdesk/page.tsx`
  - `apps/admin-web/src/lib/api.ts`
- **Implementation & Fix:**
  1. **Elimination of Foreign Key Constraint Crash:** Resolved SQLite foreign key failure on `PUT /api/admin/helpdesk/settings` caused by audit logging referencing `'SYSTEM'` instead of a valid project ID.
  2. **Client Network Error Suppression:** Guarded `reportApiFailureSafely` in `api.ts` so that transient client-side network abortions (`HTTP 0 / Failed to fetch`), 401 token refreshes, and internal helpdesk polling requests never flood the inbox with false incident tickets.
  3. **High-Clarity Summary Dashboard:** Redesigned the 3 summary metric cards (Open Tickets, Solved Tickets, Total Tickets) with explicit typography, badges, and status icons (`Clock`, `CheckCircle2`, `LifeBuoy`), and enforced a `min-w-[760px]` table width to prevent column clipping.
  4. **Direct Ticket Deletion:** Implemented `DELETE /api/admin/helpdesk/tickets/:id` and bulk delete (`POST /api/admin/helpdesk/tickets/bulk-delete`) with modal confirmations.
  5. **Notification Delivery:** Verified real-time email dispatch to `pixelmintstudiomvs@gmail.com` via Resend API key (`re_64uYLU9x...`), logging delivery with status `SENT`.

---

### H. Role-Based Unique User Identification System (`ENG_XX`, `DM_XX`, `STU_XX`)
- **File References:**
  - `worker/migrations/0024_role_based_user_ids.sql`
  - `worker/scripts/migrate_user_ids.mjs`
  - `worker/src/index.ts`
  - `apps/admin-web/src/app/engineers/page.tsx`
  - `apps/admin-web/src/app/draughtsmen/page.tsx`
  - `apps/admin-web/src/app/students/page.tsx`
  - `apps/admin-web/src/app/users/page.tsx`
  - `apps/admin-web/src/app/registrations/page.tsx`
  - `apps/admin-web/src/app/teaching/progress/page.tsx`
  - `apps/admin-web/src/app/students/submissions/page.tsx`
  - `apps/admin-web/src/app/teaching/assignments/page.tsx`
  - `apps/admin-web/src/app/teaching/learning-plans/page.tsx`
  - `apps/admin-web/src/components/engineers/EngineerProfileView.tsx`
  - `apps/admin-web/src/components/draughtsmen/DraughtsmanProfileView.tsx`
  - `apps/admin-web/src/components/students/StudentProfileView.tsx`
  - `apps/admin-web/src/components/engineers/AssignEngineerProjectModal.tsx`
  - `apps/admin-web/src/components/engineers/EngineerProjectStatusModal.tsx`
  - `lib/src/features/auth/domain/user_profile.dart`
  - `lib/src/features/profile/presentation/widgets/profile_form.dart`
  - `lib/src/features/profile/presentation/widgets/profile_header.dart`
  - `worker/test/role_based_user_id.test.mjs`
  - `apps/admin-web/test/role-based-user-id.test.ts`
- **Implementation & Architectural Rules:**
  1. **Deterministic Role ID Sequences:**
     - **For Engineers/Architects:** `ENG_XX` (e.g., `ENG_01`, `ENG_02`, `ENG_03`, scaling infinitely to `ENG_100`, `ENG_1000`, etc.).
     - **For Draughtsman:** `DM_XX` (e.g., `DM_01`, `DM_02`, `DM_03`, scaling infinitely to `DM_100`, `DM_1000`, etc.).
     - **For Student:** `STU_XX` (e.g., `STU_01`, `STU_02`, `STU_03`, scaling infinitely to `STU_100`, `STU_1000`, etc.).
     - *Where `XX` are numbers and these can be added infinitely.*
     - Admins: Excluded from end-user sequence generation; identified by administrative roles (`ADMIN`, `STUDIO_ADMIN`).
  2. **Database Sequence Engine:**
     - Created relational tracking table `role_id_sequences` (`prefix TEXT PRIMARY KEY, last_seq INTEGER NOT NULL DEFAULT 0, updated_at TIMESTAMP`).
     - Implemented atomic sequence generation via `allocateRoleId(db, prefix)` using `INSERT INTO role_id_sequences ... ON CONFLICT(prefix) DO UPDATE SET last_seq = last_seq + 1`.
     - Includes automatic collision loop recovery to ensure uniqueness even if IDs were previously backfilled.
  3. **Idempotent Data Backfill:**
     - Created migration `0024_role_based_user_ids.sql` and standalone runner `worker/scripts/migrate_user_ids.mjs`.
     - Applied safely to both local D1 emulation and remote production/staging D1 database (`archi-draft-db-staging`).
     - Safely backfilled all existing accounts chronologically by `created_at ASC, id ASC` while preserving existing user data, roles, project assignments, and training progress.
  4. **Primary Identifier Throughout Admin Portal:**
     - Re-architected all user tables so that the **very first column** is always `ID Number` before Name, Email, Role, Status, or Actions.
     - Displays formatted monospace badges (e.g., `ENG_01`).
     - User dropdown selectors and assignment modals show the composite identifier: `ENG_01 — John Doe`.
     - Search bars across `/engineers`, `/draughtsmen`, `/students`, `/users`, and `/registrations` support instant filtering by Unique ID.
  5. **Self-Healing API Guarantee:**
     - Updated `worker/src/index.ts` (`/api/users`) to wrap returned records in `ensureUserIdentificationNumber(db, u)`. Any user lacking an ID will have one automatically allocated and committed to D1 on retrieval.
  6. **Client Profile Integration:**
     - Updated Flutter client `UserProfile` model and profile widgets (`profile_form.dart`, `profile_header.dart`) to surface the read-only permanent ID.

---

### I. Registration Proof Document Preview & Approval Flow
- **File References:**
  - `apps/admin-web/src/app/registrations/page.tsx`
  - `apps/admin-web/src/lib/api.ts` (`getRegistrationProofBlob`, `getRegistrationProofUrl`)
  - `worker/src/index.ts` (`/api/admin/registrations/:id/proof`)
  - `apps/admin-web/test/registration-provision.test.ts`
- **Root Cause & Fix:**
  1. **Authentication Gate Blocked Browser Media Tags:** Standard HTML `<img>` and `<iframe>` tags do not transmit custom `Authorization: Bearer <token>` headers. Direct URL binding resulted in HTTP 401 Unauthorized responses and broken image icons.
  2. **Authenticated Client Blob Fetching:** Implemented `adminApi.getRegistrationProofBlob(regId)` which fetches the protected object via authenticated `fetchApi` and instantiates an ephemeral client URL with `URL.createObjectURL(blob)`.
  3. **Interactive PDF vs. Image Viewer:**
     - PDFs: Renders dedicated interactive `<object data={blobUrl} type="application/pdf">` (with fallback iframe) and an "Open Fullscreen" action.
     - Images (JPG/JPEG/PNG): Renders high-resolution responsive `<img>` preview with "Open Original" action.
  4. **Lifecycle & Memory Management:** Implemented `cleanupPreviewBlob()` utilizing `URL.revokeObjectURL` upon modal close, modal switching between different registrants, and component unmount.
  5. **Resilient Feedback States:** Added loading spinner (`Loading proof document preview…`) and error card with a direct "Retry Preview" button.

---

### J. Admin Portal Navigation & Language Simplification
- **File References:**
  - `apps/admin-web/src/components/layout/Sidebar.tsx`
  - `apps/admin-web/src/app/registrations/page.tsx`
  - `apps/admin-web/test/sidebar-navigation.test.ts`
  - `apps/admin-web/test/registration-provision.test.ts`
- **Implementation & Clarifications:**
  1. **Activity Navigation Item:** Renamed from **"Activity Feed"** to **"Activity"** in `Sidebar.tsx` under the `Overview` section.
  2. **Registrations Navigation Item:** Renamed from **"Allow Registrations"** to **"Registrations"** in `Sidebar.tsx` under the `Registration` section.
  3. **Approve Registration Page Header:** Renamed page card heading from **"Registrations Provision"** to **"Approve Registration"** in `apps/admin-web/src/app/registrations/page.tsx`.
  4. **High-Contrast Header Typography:** Corrected page title styling from `text-white` to `text-black font-bold font-heading`, ensuring crystal-clear readability against the architectural grid canvas.

---

### K. PIXMINT BOT 2.0 Integration & Admin Control Center Simplification
- **File References:**
  - `apps/admin-web/src/app/bot/page.tsx`
  - `apps/admin-web/src/components/layout/Sidebar.tsx`
  - `apps/admin-web/src/lib/api.ts`
  - `apps/admin-web/src/lib/types.ts`
  - `apps/admin-web/test/pixmint-bot-admin.test.ts`
  - `worker/src/pixmint/`
  - `lib/src/features/pixmint_bot/`
- **Implementation & Clarifications:**
  1. **5 Consolidated Admin Tabs:** Simplified navigation into Dashboard, Bot Settings, Knowledge Base, Conversations, and Feedback & Insights.
  2. **Session Lifecycle Deduplication:** Resolved multiple "New Conversation" rows by reusing active unarchived sessions on launcher open and app reload. Added concurrency guard in Flutter controller.
  3. **Architectural Title Generation:** Implemented automatic intent-based title generation from first user questions with zero-loss self-healing backfill for legacy sessions.
  4. **User-Grouped Conversation Management:** Redesigned Tab 4 from flat session dump to a clean User-Grouped table with expandable session history and WhatsApp-style continuous chat inspector modal.
  5. **Question Analytics & Gap Audit:** Integrated semantic clustering of repeated user queries, negative rating detection, and knowledge gap action items.
  6. **Chat Composer Visibility Fix:** Applied explicit dark charcoal `#17212B` text and `#00D6A0` emerald cursor on white `#FFFFFF` input background across all user portals.
  7. **Strict Role Governance:** Enforced strictly `ENGINEER`, `DRAUGHTSMAN`, `STUDENT`, and `ADMIN`. Prohibited Client/Guest portal access.

---

## 3. Test & Verification Evidence Summary

| Test Harness | Total Suites | Tests Passed | Status |
| :--- | :--- | :--- | :--- |
| **Cloudflare Worker** | 16 | **463 / 463** | Verified |
| **Admin Web Portal** | 83 | **340 / 340** | Verified |
| **Flutter Test Suite** | 3 | **25 / 25** | Verified |
| **Admin Web Build** | 37 routes | **0 errors** | Verified |

---

## 4. Outstanding Manual Runtime Checklist

1. [ ] Start all 4 services locally per the authoritative startup guide.
2. [ ] Visit `http://localhost:3000/activity` and verify live 15-second countdown polling.
3. [ ] Open Flutter Web (`http://localhost:8080`) and verify dark readable text in the PIXMINT chatbot input.
4. [ ] Navigate to `/engineers`, open a quick-view modal, and confirm `2xl` responsive width and unclipped badges.
5. [ ] Navigate to `/engineers/[id]` and verify truthful dossier rendering.
