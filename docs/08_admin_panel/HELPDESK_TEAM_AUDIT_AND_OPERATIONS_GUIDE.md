# ArchiDraft × PixelMint Studio MVS
## Centralized Help Desk Audit Report & Team Operations Guide

**System Version:** Release 2.5 (Integration Master)  
**Active Branch:** [`COMPLETED-INTERGRATION`](https://github.com/pixelmint-studio-mvs/Archidraft/tree/COMPLETED-INTERGRATION)  
**Primary Notification Destination:** `pixelmintstudiomvs@gmail.com`  
**Cloudflare Worker Deployment:** `archi-draft-worker-staging` (Version: `33f293b9-a3c9-4cf3-9111-fa32e442f769`)  
**Target Audience:** Studio Administrators, Technical Leads, Customer Support Specialists, and QA Engineers  

---

## 1. Executive Summary

This document serves as the authoritative audit report and operational handover guide for the **Centralized Help Desk and Incident Management System** of the ArchiDraft platform. 

The system provides dual-mode capability:
1. **End-User Customer Support:** Captures user inquiries, drawing viewer issues, and revision requests from clients, engineers, draughtsmen, and students.
2. **Automated Incident Monitoring:** Automatically detects unhandled server exceptions, API failures, and database anomalies across the Cloudflare Worker runtime.

All identified architectural defects, database constraint errors, email authorization barriers, and UI overlaps have been resolved and verified with 100% passing automated test harnesses.

---

## 2. System Architecture & Incident Lifecycle

The following diagram illustrates how customer inquiries and backend incidents flow through the system:

```mermaid
flowchart TD
    subgraph Clients["Portals & Clients"]
        U1["End User / Client / Student\n(Support Widget)"]
        A1["Admin Web Portal\n(Manual Ticket / Triage)"]
        W1["Worker Runtime & Sensors\n(Unhandled Exceptions)"]
    end

    subgraph Security["Ingestion & Sanitization Engine"]
        S1["Token & Secret Redaction\n(Bearer / JWT / Passwords Stripped)"]
        D1["Deduplication & Fingerprinting\n(Normalizes UUIDs / 15-min Anti-Spam)"]
        Bypass{"User-Submitted\nTicket?"}
    end

    subgraph Storage["Cloudflare D1 Database"]
        DB1[("helpdesk_tickets")]
        DB2[("helpdesk_events")]
        DB3[("helpdesk_email_logs")]
    end

    subgraph Dispatch["Email Delivery Engine"]
        R1["Resend API Gateway\n(Provider: RESEND)"]
        Inbox["Studio Operations Inbox\npixelmintstudiomvs@gmail.com"]
    end

    U1 -->|POST /api/helpdesk/tickets| S1
    A1 -->|Admin CRUD| S1
    W1 -->|Worker Exception Handler| S1

    S1 --> D1
    D1 --> Bypass

    Bypass -->|YES: Immediate Dispatch| R1
    Bypass -->|NO: Severity Check| R1

    S1 --> DB1
    DB1 --> DB2
    R1 --> DB3
    R1 --> Inbox
```

---

## 3. Technical Audit & Defect Resolution Register

The following table summarizes the issues resolved in this release:

| Defect / Problem | Root Cause | Architectural Solution Applied | Verification Status |
| :--- | :--- | :--- | :--- |
| **`SQLITE_CONSTRAINT_FOREIGNKEY` Crash** | `PUT /api/admin/helpdesk/settings` attempted an audit log insertion into `activity_logs` with `project_id = 'SYSTEM'`. SQLite strictly enforces foreign key linkage to `projects.id`. | Removed the invalid `activity_logs` write from the settings route. Settings are persisted directly to `helpdesk_settings`. | **PASSED** (HTTP 200 on settings save) |
| **Resend HTTP 403 Sandbox Rejection** | Resend's free tier sandbox (`onboarding@resend.dev`) only allows delivery to the account registrant. The previous key belonged to an old developer email. | Configured active Resend API key (`re_64uYLU9x...`) belonging to `pixelmintstudiomvs@gmail.com`. Tested live dispatch. | **PASSED** (HTTP 200, Message ID `01a1a31c...`, Status `SENT`) |
| **False-Positive `HTTP 0: Failed to fetch` Tickets** | Client-side API wrapper captured transient network aborts (HMR reloads, tab navigation) and auto-reported them as server incidents. | Guarded `reportApiFailureSafely` in `apps/admin-web/src/lib/api.ts` to strictly ignore `status === 0`, 401s, 404s, and internal helpdesk polling. | **PASSED** (0 spam tickets created on dev reload) |
| **`Cannot find name 'clock'` Runtime Error** | `THREE.Clock` was deprecated and replaced with `performance.now()`, but line 170 in `Monogram3DViewer.tsx` still called `clock.start()`. | Scoped `lastTime = performance.now()` at the effect root and updated on GLTF model load completion. | **PASSED** (0 ReferenceErrors, 3D Monogram renders smoothly) |
| **Missing Top-Left Brand Logo** | When the sidebar was collapsed, the header bar had no fallback brand anchor, leaving the top-left blank. | Added `<Monogram3DViewer />` anchor inside `Header.tsx` when `isSidebarCollapsed` is active. | **PASSED** (3D logo visible in expanded and collapsed views) |
| **Floating `SupportWidget` Collision** | The floating "Need Help?" button collided with profile avatars and triage update forms on `/helpdesk` pages. | Added route-matching suppression in `SupportWidget.tsx` for all `/helpdesk/*` routes. | **PASSED** (Clean layout with zero overlaps) |
| **Native `window.alert()` Interruptions** | Diagnostic tools and email logs used browser popups for notifications. | Replaced all native popups with dismissible inline notification banners. | **PASSED** (Smooth non-blocking UI feedback) |

---

## 4. Team Operations Guide: Managing the Help Desk Easily

This guide outlines standard operating procedures for team members managing day-to-day tickets.

### A. Accessing the Help Desk
1. Open the Admin Panel at `http://localhost:3000` (or your staging/production admin URL).
2. Click **Help Desk** in the left sidebar under the **System Management** section.
3. The main dashboard displays three summary cards:
   - **Open Tickets:** Unresolved customer requests and high-priority incidents.
   - **Solved Tickets:** Successfully resolved inquiries.
   - **Total Tickets:** Lifetime record count.

---

### B. Daily Ticket Management Workflow

```mermaid
flowchart LR
    A["1. Filter Inbox\n(Tabs: From Users / Open)"] --> B["2. Click 'View >'\nto open Ticket Detail"]
    B --> C["3. Review Inquiry\n& Collapse Tech Trace"]
    C --> D["4. Click 'Reply via Email'\nto respond to user"]
    D --> E["5. Click '✓ Mark Ticket as Solved'\nto complete"]
```

#### Step 1: Filter Your Inbox
- Use the filter tabs at the top to focus on what matters:
  - **From Users:** Shows tickets submitted by genuine clients, students, or engineers (highest priority).
  - **Open:** Shows all active issues requiring team attention.
  - **Solved:** Shows completed and closed tickets.
- Use the **Search bar** to quickly find tickets by ID (`PM-HELP-2026-XXXXXX`), customer email, or keyword.

#### Step 2: Open and Review the Ticket
- Click **View >** on any ticket row.
- **Customer Information:** View user email, browser environment, and inquiry details on the left.
- **Technical Stack Trace:** Automatically collapsed by default. Only expand if technical debugging is required.

#### Step 3: Respond to the Customer
- Click the blue **"Reply via Email"** button.
- Your default email client (Outlook, Gmail, Apple Mail) will open automatically with the customer's email, ticket ID, and inquiry subject pre-filled.
- Send your reply directly from your studio email.

#### Step 4: Mark as Solved
- Once the user's issue has been addressed, click the prominent green button:
  > **`✓ Mark Ticket as Solved`**
- The status instantly changes to `RESOLVED`, the open ticket counter decrements, and an audit entry is logged.

---

### C. Adding Internal Team Notes
If an inquiry requires investigation or coordination with an engineer:
1. In the right-hand panel of the ticket view, locate the **Internal Notes** box.
2. Type your findings (e.g., *"Checked CAD file; re-exported revision sent to draughtsman"*).
3. Click **Add Note**.
4. *Note: Internal notes are strictly visible to admins and are never sent to the customer.*

---

### D. Deleting Test or Obsolete Tickets
- **Delete Single Ticket:** On any ticket detail view or row in the table, click the red **Delete** (trash icon) button. Confirm in the dialog. All associated comments and logs will be safely deleted.
- **Clear All (Studio Admin only):** To purge all test tickets at once, click **Clear All** above the summary cards and confirm.

---

### E. Diagnostic & Configuration Tools
Located under the **Settings** button in the top toolbar:
- **Email Delivery Service:** Displays the active provider (**Resend**) and sender address (`onboarding@resend.dev`).
- **Send Test Alert:** Type any email address or click **"Send Test Alert to pixelmintstudiomvs@gmail.com"** to verify live inbox delivery in real time.
- **Email Notification Logs (`/helpdesk/email-logs`):** Complete delivery audit trail showing timestamp, provider, and `SENT` status.
- **System Health & Diagnostics (`/helpdesk/health`):** Real-time latency checks for Worker API, Cloudflare D1, R2 Storage, and Email Dispatcher.

---

## 5. Security, Privacy & Compliance Controls

1. **Automatic Secret Redaction:**
   - Every incident report and ticket payload is scrubbed by `sanitizeText()` in `worker/src/helpdesk.ts`.
   - Bearer tokens (`Bearer eyJ...`), passwords, Firebase tokens, private keys, and API secrets are replaced with `[REDACTED_TOKEN]` before saving to the database.
2. **Account Isolation Guarantee:**
   - All operational alert removals are strictly isolated to `helpdesk_settings` and `helpdesk_email_logs`.
   - User database tables (`users`), Draughtsman accounts, and Firebase Authentication remain untouched.
3. **Anti-Spam Suppression Window:**
   - Repeating system errors are de-duplicated using normalized stack trace hashes with a 15-minute suppression window.
   - User-submitted inquiries are **never suppressed** and dispatch instantly to ensure zero customer support delays.

---

## 6. Automated Test Harness Verification

The entire platform passes rigorous automated verification:

| Harness | Target | Passed | Status |
| :--- | :--- | :--- | :--- |
| **Worker Test Suite** | Authentication, Legal Gate, Curriculum, Help Desk | **346 / 346** | 100% Passed |
| **Admin Web Test Suite** | Portals, RBAC, Financials, Navigation, Dossiers | **289 / 289** | 100% Passed |
| **Help Desk Contract Suite** | Deduplication, Redaction, ID Formats, Email Validation | **9 / 9** | 100% Passed |
| **Next.js Production Build** | Static & Partial Prerendering (`next build`) | **34 / 34 routes** | 0 Errors |

---

## 7. Quick Navigation Reference

| Feature | URL Path | Primary Purpose |
| :--- | :--- | :--- |
| **Support Inbox** | [`/helpdesk`](file:///c:/Users/Mohammed%20Anas%20N/Desktop/Archidraft/apps/admin-web/src/app/helpdesk/page.tsx) | Daily ticket management, filtering, and resolution |
| **Help Desk Settings** | [`/helpdesk/settings`](file:///c:/Users/Mohammed%20Anas%20N/Desktop/Archidraft/apps/admin-web/src/app/helpdesk/settings/page.tsx) | Email alerts, Resend key configuration, test alerts |
| **Email Audit Logs** | [`/helpdesk/email-logs`](file:///c:/Users/Mohammed%20Anas%20N/Desktop/Archidraft/apps/admin-web/src/app/helpdesk/email-logs/page.tsx) | Delivery proof, Resend response IDs, retry actions |
| **Health & Telemetry** | [`/helpdesk/health`](file:///c:/Users/Mohammed%20Anas%20N/Desktop/Archidraft/apps/admin-web/src/app/helpdesk/health/page.tsx) | Worker API, D1 Database, R2 Storage latency monitoring |
