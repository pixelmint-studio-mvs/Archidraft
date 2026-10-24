# ARCHI DRAFT — STITCH-DRIVEN STUDIO ADMIN PORTAL AUDIT & PANEL INVENTORY

**Project:** Archi Draft  
**Parent Brand:** Draughtsman Studio ([www.draughtsmanstudio.com](https://www.draughtsmanstudio.com/))  
**Development Studio:** PixelMint Studio MVS  
**Stitch Project URL:** [https://stitch.withgoogle.com/projects/13419289002152150404](https://stitch.withgoogle.com/projects/13419289002152150404)  
**Stitch Project Name:** `projects/13419289002152150404` (*Draughtsman Studio OS*)  
**Design System:** `Architectural Precision System` (FIDELITY / Corporate Modern + Glassmorphism)  
**Date of Audit:** October 21, 2026  
**Auditor:** Senior UI/UX Engineer, Frontend Architect & QA Specialist (PixelMint Studio MVS)  
**Target Repository Path:** `apps/admin-web`  
**Active Git Branch:** `feature/admin-panel-complete`  

---

## Executive Summary

This document presents the authoritative discovery, audit, and panel inventory for the comprehensive redesign of the **Archi Draft Studio Admin Portal**. Antigravity's configured **Google Stitch MCP integration** was used directly to inspect project `13419289002152150404` (*Draughtsman Studio OS*), its 35 registered screen entries, design tokens, color models, typography scales, layout rules, and component specifications.

Concurrently, the current working-tree implementation in `apps/admin-web` (17 App Router routes, shared components, Firebase Auth context, and Cloudflare Worker API client) was audited line by line.

### Key Audit Highlights:
1. **Stitch Project Composition:** Exactly **35 entries** were enumerated via Stitch MCP. This comprises **24 unique screen designs** (3 of which have linked/duplicate variants, making 27 total visual screens), **3 non-screen assets** (2 brand images and 1 product strategy brief), and **5 empty prototype slots**.
2. **Design System Source of Truth:** The active design system in Stitch is the **Architectural Precision System** (`#fbf9fb` canvas, `#ffffff` pure white cards with 1px `#e2e8f0` technical borders, `#0d1c32` Deep Midnight Blue primary anchor, `#0453cd` Royal Blue interactive accents, Inter for headings/body, and JetBrains Mono for blueprint metadata, chips, and tabular data).
3. **Product Terminology Adherence:** The product features three user populations: **Engineer**, **Draughtsman**, and **Student**, overseen by the **Studio Admin**. User-facing UI strictly replaces every legacy "Client" reference with **Engineer**, while preserving internal backend/database keys (`client_id`, `CLIENT`, `UNDER_CLIENT_REVIEW`) for API and D1 compatibility.
4. **Existing Code Capabilities:** The admin portal already possesses mature, verified backend integration (Firebase Auth, Cloudflare Worker REST API, D1 SQLite database, R2 object storage, 30s sidebar badge polling, 15s live activity feed polling, and client-side jsPDF invoice generation). **All core administrative workflows are working in code and require visual restyling rather than backend reimplementation.**
5. **Major Gap Identified:** The root path `/` is currently a stub (`return null`) that immediately redirects unauthenticated users to `/login`. Stitch defines a complete **Landing Experience** (`7ec75634815f4259adae789437f52ea7`) with an architectural showcase, which will be built out.

---

## Section A — Stitch Screen Inventory

The following table catalogs every accessible screen and asset in Stitch Project `13419289002152150404` (*Draughtsman Studio OS*), evaluated for Admin Portal scope:

| # | Stitch Screen Name | Screen ID | Scope Status | Dimensions & Type | Intended Purpose & Key Layout | Related Workflow |
|:---|:---|:---|:---|:---|:---|:---|
| **01** | **Landing Experience** | `7ec75634815f4259adae789437f52ea7` | **In-Scope (Admin Entry)** | 780 × 2324 (Mobile Comp) | Brand showcase, architectural drafting hero, blueprint grid features, entry buttons to portals | Landing page (`/`) |
| **02** | **Landing Experience (Linked)** | `a9c19153c49c461ebb1c844a1360d9ff` | In-Scope (Variant) | 780 × 2388 (Mobile Comp) | Linked prototype duplicate of Landing Experience | Landing page (`/`) |
| **03** | **Unified Auth Login** | `f7f092239b55459f94392e8afe5ab526` | **In-Scope (Admin Auth)** | 780 × 1768 (Mobile Comp) | Single-point secure authentication, credential inputs, studio logo, error state | Admin Login (`/login`) |
| **04** | **Restore Access** | `baaf7b1e8ac64c8482ad78f5b28fdba0` | **In-Scope (Admin Auth)** | 780 × 1768 (Mobile Comp) | Password reset request with email validation and success state | Forgot Password (`/forgot-password`) |
| **05** | **Secure Verification** | `fe2dc34875f34bdfad0807d8f77f4ce4` | **In-Scope (Admin Auth)** | 780 × 1768 (Mobile Comp) | 6-digit OTP code entry, session ID tag, resend timer | Verify Gate (`/verify`) |
| **06** | **Role Selection Panel** | `0b99e1d2c200447c8b0ace6600a7d375` | In-Scope (Auxiliary) | 780 × 1930 (Mobile Comp) | Role onboarding selector (Engineer, Draughtsman, Student) | Post-auth onboarding / simulation |
| **07** | **Executive Dashboard** | `88593f310c8140bd9930b00748b9eabf` | **In-Scope (Admin Core)** | 780 × 3694 (Mobile Comp) | Primary admin overview, multi-portal telemetry, project pipeline metrics, priority queue | Admin Dashboard (`/dashboard`) |
| **08** | **Executive Dashboard (Linked)** | `87dc51d90776444c84a943a9672d411d` | In-Scope (Variant) | 780 × 3694 (Mobile Comp) | Linked duplicate of Executive Dashboard with active filter states | Admin Dashboard (`/dashboard`) |
| **09** | **Admin Management Portal** | `e36e8361fb854d4dbdf108d5982f4839` | **In-Scope (Admin Core)** | 780 × 3200 (Mobile Comp) | Studio governance overview, action items, assign/reassign queue, ecosystem metrics | Dashboard / Action Queue |
| **10** | **Client Projects Dashboard** | `07f71e1e54eb4a7aa39ccd2434a06c97` | **In-Scope (Admin Core)** | 780 × 2624 (Mobile Comp) | Projects queue, status filters, search toolbar, quick action links (*"Client" = Engineer*) | Projects List (`/projects`) |
| **11** | **Project Details & Versioning** | `e572bcf6ed714f66abf4ad3ed9e76f59` | **In-Scope (Admin Core)** | 780 × 3612 (Mobile Comp) | Detailed workspace: Project specs, drawing version history, review controls, action bar | Project Detail (`/projects/[id]`) |
| **12** | **Project Workflow Timeline** | `38e7888db7244b7eae26165dc53d29b6` | **In-Scope (Admin Core)** | 780 × 2458 (Mobile Comp) | Visual 6-stage lifecycle progression bar with node status and stage detail cards | Project Detail Tab (`/projects/[id]`) |
| **13** | **Interactive CAD & Blueprint Viewer** | `e77723e954e7467facd412a9dcf77475` | **In-Scope (Admin Core)** | 780 × 2992 (Mobile Comp) | Split/Overlay drawing inspection, zoom/pan controls, revision comparison, layers | Project Detail Tab (`/projects/[id]`) |
| **14** | **Redline Correction Markup & Review** | `7c9582819a094ab8b303c9a128484e99` | **In-Scope (Admin Core)** | 780 × 3784 (Mobile Comp) | Revision cycle review, correction rounds (capped at 3), redline notes, feedback tags | Project Detail Tab (`/projects/[id]`) |
| **15** | **Collaboration Hub** | `c0e3b73a402a4297bff9ae5ab3910060` | **In-Scope (Admin Core)** | 780 × 2286 (Mobile Comp) | Project discussion trail, role badges, file attachments, audio notes | Project Detail Tab & Activity |
| **16** | **Drawings Library** | `c0d70c614fb14084911dfb38bf0aa9fa` | **In-Scope (Admin Core)** | 780 × 3136 (Mobile Comp) | CAD drawing file repository, version cards, file size/date metadata, download actions | Project Detail Tab (`/projects/[id]`) |
| **17** | **Financials & Invoicing** | `717b101899da4596bb83470749065e36` | **In-Scope (Admin Core)** | 780 × 4044 (Mobile Comp) | Studio revenue ledger, collection progress bar, invoice line items, PDF downloads | Financials (`/financials`) |
| **18** | **System Settings Panel** | `c8bc2e94fc1e44d0af06862f7283493c` | **In-Scope (Admin Core)** | 780 × 2500 (Mobile Comp) | Platform settings, Worker gateway status, Firebase JWKS parameters, security compliance | Settings (`/settings`) |
| **19** | **User Profile & Account Settings** | `4ee871db6a7e49d3b29a16dae5f38f9c` | **In-Scope (Admin Core)** | 780 × 6124 (Mobile Comp) | Admin profile details, account security, notification preferences, session controls | Profile / Settings (`/settings`) |
| **20** | **Empty State & Blueprint Vault** | `c9281f147ee849519d8cb489db7c15ec` | **In-Scope (Admin Core)** | 780 × 3372 (Mobile Comp) | Architectural zero-data state: technical compass illustration, empty queue guidelines | Shared UI Primitive (`EmptyState`) |
| **21** | **New Project Form Wizard** | `51b2be05d6024f93923908fc09b1d4a8` | In-Scope (Auxiliary) | 780 × 3306 (Mobile Comp) | Step-by-step project intake wizard: scope, location, drawing type, area, reference files | Admin Project Creation Modal |
| **22** | **Register & Onboarding Wizard** | `88ddbef0f53c4ebda434e92042716496` | Reference Only | 780 × 1820 (Mobile Comp) | Multi-step registration flow (Admin registration is prohibited server-side by policy) | Reference / Client Onboarding |
| **23** | **Engineer Submission Portal** | `2cc556cbc5044054a49aae10624d0dd4` | Admin Representation | 780 × 2404 (Mobile Comp) | Engineer portal intake view (represented in Admin Web as Engineer dossier modal) | Engineers Dossier (`/engineers`) |
| **24** | **Draughtsman Workspace** | `f06203f554ef48629cd3b2dd71808e04` | Admin Representation | 780 × 3962 (Mobile Comp) | Draughtsman assignment queue (represented in Admin Web as Draughtsman preview modal) | Draughtsmen (`/draughtsmen`) |
| **25** | **Draughtsman Workspace (Linked)** | `d530df1697f44255a9236fd1d8d77c32` | Admin Representation | 780 × 3962 (Mobile Comp) | Linked variant of Draughtsman Workspace | Draughtsmen (`/draughtsmen`) |
| **26** | **Student Portal** | `8939aba231854f01b8c907b5cfc22f81` | Admin Representation | 780 × 5162 (Mobile Comp) | Student curriculum hub (represented in Admin Web as Student learning dossier modal) | Students (`/students`) |
| **27** | **Student Submission & Feedback** | `d18ce0876bb046998302130948289fd2` | Admin Representation | 780 × 4758 (Mobile Comp) | Coursework grading & reviews (represented in Admin Web as Student training preview) | Students (`/students`) |
| **28** | **DS logo big.jpeg** | `2232973319021507438` | Brand Asset | 1280 × 714 (Image) | Official Draughtsman Studio high-resolution brand asset | Brand / Assets |
| **29** | **WhatsApp Image 2026-09-05...** | `17609984347497415496` | Asset / Evidence | 1536 × 1024 (Image) | Architectural reference photograph | Evidence / Mockup |
| **30** | **Product Strategy** | `6b258218fab34da595421147f28e0187` | Strategy Doc | Text Document (0 × 0) | Draughtsman Studio product strategy notes and positioning | Architectural Brief |
| **31** | **Untitled Prototype (Slot 1)** | `b01ce9aaf60c47fb88cc87121576a841` | Empty Slot | 390 × 884 (No Visuals) | Unpopulated prototype slot in Stitch canvas | N/A |
| **32** | **Untitled Prototype (Slot 2)** | `fcd006c058bf4b389f919732b230a9f2` | Empty Slot | 390 × 884 (No Visuals) | Unpopulated prototype slot in Stitch canvas | N/A |
| **33** | **Untitled Prototype (Slot 3)** | `c37b995992d04cd7b1b81770cf026afe` | Empty Slot | 390 × 884 (No Visuals) | Unpopulated prototype slot in Stitch canvas | N/A |
| **34** | **Untitled Prototype (Slot 4)** | `737a5b8508bc4b7d8f640cd1a3dd40b2` | Empty Slot | 390 × 884 (No Visuals) | Unpopulated prototype slot in Stitch canvas | N/A |
| **35** | **Draughtsman App Workflow** | `8e2aabcc559141778f2f96006a0ff7b6` | Empty Slot | 390 × 884 (No Visuals) | Empty workflow slot in Stitch canvas | N/A |

### Total Stitch Items Summary:
- **Total Registered Stitch Entries:** 35
- **Empty Prototype Slots (Zero Visual Data):** 5 (`#31`–`#35`)
- **Non-Screen Design Assets:** 3 (`#28` Logo, `#29` Image, `#30` Text Strategy)
- **Active Visual Screens Reviewed:** 27
- **Unique Screen Designs (Excluding 3 Linked Duplicates):** 24
- **Directly In-Scope for Admin Portal Presentation:** 20 unique screens

---

## Section B — Existing Implementation Inventory

The following table summarizes all existing routes, components, and backend connection points under `apps/admin-web`:

### 1. Landing & Authentication Entry Points (Unauthenticated / Public)

| Route | Page File Path | Current Capabilities | Verification Status | Backend Contracts Used |
|:---|:---|:---|:---|:---|
| **`/`** | `src/app/page.tsx` | Stub returning `null`; immediately redirects to `/login` via `useAuth` router push. | **Needs Full Implementation** (Must match Stitch Landing Experience) | Client router redirect only |
| **`/login`** | `src/app/login/page.tsx` | Firebase Email/Password login, resilient dev fallback session, error messages, links to `/forgot-password` and `/verify`. | **Fully Functional** (Needs visual restyle to Stitch) | Firebase Web SDK `signInWithEmailAndPassword`, `adminApi.getMe()` |
| **`/forgot-password`** | `src/app/forgot-password/page.tsx` | Firebase `sendPasswordResetEmail`, valid email checks, recovery confirmation, error messages, return to login. | **Fully Functional** (Needs minor visual polish to Stitch) | Firebase Web SDK `sendPasswordResetEmail` |
| **`/verify`** | `src/app/verify/page.tsx` | 6-digit numeric OTP input with auto-advance, paste support, 60s cooldown timer, session ID display. | **Fully Functional** (Needs visual restyle to Stitch) | Simulated verify & Firebase email verification gate |

### 2. Authenticated Studio Admin Console

| Route | Page File Path | Current Capabilities | Verification Status | Backend Contracts Used |
|:---|:---|:---|:---|:---|
| **`/dashboard`** | `src/app/dashboard/page.tsx` | Three-portal metrics (Engineers, Draughtsmen, Students), 8-stage state machine counters, high-priority action queue, live recent activity feed, manual sync. | **Fully Functional** (Needs visual restyle to Stitch Executive Dashboard) | `GET /api/admin/stats`, `GET /api/projects`, `GET /api/users` |
| **`/projects`** | `src/app/projects/page.tsx` | Full project catalog, 9 status filter tabs (`ALL`, `SUBMITTED`, `WAITING_ASSIGNMENT`, `IN_PROGRESS`, etc.), text search, inline quick actions (Approve, Reject, Assign, Reassign, Cancel). | **Fully Functional** (Needs visual restyle to Stitch Projects Dashboard) | `GET /api/projects`, `POST /api/projects/approve`, `POST /api/projects/reject`, `POST /api/projects/assign`, `POST /api/projects/cancel` |
| **`/projects/[projectId]`** | `src/app/projects/[projectId]/page.tsx` | Comprehensive project console with 9 tabs: Specs & Info, Workflow Timeline, CAD Comparison (Split/Overlay), Collaboration Hub, Reference Files, Drawing Versions, Corrections, Assignments, and Audit Trail. | **Fully Functional** (Needs visual restyle to Stitch Project Details & CAD Viewer) | `GET /api/projects/:id`, `GET /api/projects/:id/files`, `GET /api/projects/:id/drawing_versions`, `GET /api/projects/:id/corrections`, `GET /api/projects/:id/assignments`, `GET /api/projects/:id/activity`, `POST /api/projects/approve`, `POST /api/projects/reject`, `POST /api/projects/assign`, `POST /api/projects/reassign`, `POST /api/projects/cancel` |
| **`/engineers`** | `src/app/engineers/page.tsx` | Directory of structural, civil, and architectural engineers, project count badges, search by firm/contact, detailed Engineer dossier modal with submission portfolio history. | **Fully Functional** (Needs visual restyle to Stitch) | `GET /api/users?role=CLIENT`, `GET /api/users/:id`, `GET /api/projects` |
| **`/draughtsmen`** | `src/app/draughtsmen/page.tsx` | CAD/BIM talent pool, workload classification (Active vs Available), qualification and college tracking, Draughtsman Workspace preview modal with assignment cards and version histories. | **Fully Functional** (Needs visual restyle to Stitch) | `GET /api/users?role=DRAUGHTSMAN`, `GET /api/users/:id`, `GET /api/projects` |
| **`/students`** | `src/app/students/page.tsx` | Student directory with truthful D1 empty state, toggleable development preview fixtures with explicit `[DEMO]` badges, Student Learning Portal preview modal (curriculum progress, mock projects, rankings). | **Fully Functional** (Needs visual restyle to Stitch) | `GET /api/users?role=STUDENT` |
| **`/users`** | `src/app/users/page.tsx` | Unified multi-role directory with color-coded tabs (Engineers, Draughtsmen, Students, Admins, All), search, full pagination (10/page with ellipsis controls), revenue yield mini-chart, productivity index. | **Fully Functional** (Needs visual restyle to Stitch) | `GET /api/users`, `GET /api/admin/stats` |
| **`/activity`** | `src/app/activity/page.tsx` | Real-time audit trail with automated 15-second polling, LIVE/PAUSED toggle button, countdown timer, fade-in animations for new incoming entries, action-type color coding, and project links. | **Fully Functional** (Needs visual restyle to Stitch Collaboration Hub) | `GET /api/admin/stats` (recentActivity) |
| **`/financials`** | `src/app/financials/page.tsx` | Revenue ledger derived from project pipeline, KPI cards (Revenue Collected, Outstanding, Pipeline, Collection Rate), collection progress bar, filter tabs, client-side jsPDF invoice generator with branded A4 layout. | **Fully Functional** (Needs visual restyle to Stitch Financials) | `GET /api/projects`, `jsPDF` client-side PDF synthesis |
| **`/settings`** | `src/app/settings/page.tsx` | Infrastructure health check, Cloudflare Worker API gateway verification, Firebase JWKS configuration check, Master Architectural Compliance checklist, D1 admin provisioning protocol. | **Fully Functional** (Needs visual restyle to Stitch System Settings Panel) | `useAuth`, `process.env` configuration inspection |

### 3. Shared Components & Shell Architecture

| Component | Path | Current Capabilities | Verification Status |
|:---|:---|:---|:---|
| **`Sidebar`** | `src/components/layout/Sidebar.tsx` | Primary navigation, live badges for Projects, Engineers, Draughtsmen, and Students (30s background polling), user footer with logout. | **Fully Functional** (Needs restyle to Stitch drawer/rail) |
| **`Header`** | `src/components/layout/Header.tsx` | Page titles, Worker API live status indicator, security role pill, global sync button. | **Fully Functional** (Needs restyle to Stitch top bar) |
| **`AdminShell`** | `src/components/layout/AdminShell.tsx` | Auth guard wrapper, unauthenticated redirect, layout scaffolding. | **Fully Functional** (Preserve logic, update container styling) |
| **`AssignModal`** | `src/components/projects/AssignModal.tsx` | Draughtsman talent picker, qualification filter, `assignProject` / `reassignProject` with `actionId`. | **Fully Functional** (Restyle modal backdrop & card) |
| **`RejectModal`** | `src/components/projects/RejectModal.tsx` | Rejection reason form input, `rejectProject` with `actionId`. | **Fully Functional** (Restyle modal backdrop & card) |
| **`CancelModal`** | `src/components/projects/CancelModal.tsx` | Destructive project cancellation modal, reason input, `cancelProject` with `actionId`. | **Fully Functional** (Restyle modal backdrop & card) |
| **`Badge`** | `src/components/ui/Badge.tsx` | Status badges and role badges (converts DB role `CLIENT` to "Engineer"). | **Fully Functional** (Update font to JetBrains Mono per Stitch) |
| **`Button`** | `src/components/ui/Button.tsx` | Primary, outline, ghost, danger, and success button variants with loading spinner. | **Fully Functional** (Update radius and colors to Stitch tokens) |
| **`Card`** | `src/components/ui/Card.tsx` | Card container with header and subtle borders. | **Fully Functional** (Update border and background to Stitch tokens) |
| **`Modal`** | `src/components/ui/Modal.tsx` | Backdrop modal wrapper with close controls and title header. | **Fully Functional** (Update to Stitch glassmorphism overlays) |

---

## Section C — Screen-by-Screen Comparison Matrix

The following table pairs every Stitch design with the existing repository implementation, classifies the required effort, and defines the exact architectural strategy:

| Stitch Screen & ID | Current Route | Existing Files | Functionality Status | UI Alignment | Classification | Recommended Action |
|:---|:---|:---|:---|:---|:---|:---|
| **Landing Experience** (`7ec75634815f4259adae789437f52ea7`) | `/` | `src/app/page.tsx` | Missing (Currently stub returning `null`) | 0% (Blank redirect) | **D. MISSING — BUILD IT** | Implement full landing experience using Stitch layout: blueprint hero, studio introduction, interactive CAD showcase preview, and portal entry cards. |
| **Unified Auth Login** (`f7f092239b55459f94392e8afe5ab526`) | `/login` | `src/app/login/page.tsx`, `src/lib/auth.tsx` | 100% Functional (Firebase + Dev fallback) | 65% (Dark container vs Stitch refined layout) | **A. EXISTS AND CAN BE RESTYLED** | Restyle login card with Stitch Architectural Precision tokens (`#fbf9fb` background, pure white `#ffffff` elevated card, `#0d1c32` brand block, Inter typography). Preserve all auth logic. |
| **Restore Access** (`baaf7b1e8ac64c8482ad78f5b28fdba0`) | `/forgot-password` | `src/app/forgot-password/page.tsx` | 100% Functional (Firebase reset email) | 90% (Already closely aligns with Stitch) | **A. EXISTS AND CAN BE RESTYLED** | Refine input borders, button states, and PixelMint signature to match Stitch design precision. |
| **Secure Verification** (`fe2dc34875f34bdfad0807d8f77f4ce4`) | `/verify` | `src/app/verify/page.tsx` | 100% Functional (6-digit OTP shell) | 88% (Already closely aligns with Stitch) | **A. EXISTS AND CAN BE RESTYLED** | Polish digit box focus states (`#0453cd` Royal Blue glow) and resend countdown timer. |
| **Role Selection Panel** (`0b99e1d2c200447c8b0ace6600a7d375`) | `/login` / Modal | Flutter `role_selection_screen.dart` | Exists in Flutter, not in Admin Web | 20% (Not present in admin web) | **C. PARTIALLY EXISTS — EXTEND IT** | Create an auxiliary role switcher/simulation preview component for testing and demonstrations. |
| **Executive Dashboard** (`88593f310c8140bd9930b00748b9eabf`) | `/dashboard` | `src/app/dashboard/page.tsx` | 100% Functional (All stats, queues & activity) | 70% (Dark mode vs Stitch Architectural Precision) | **A. EXISTS AND CAN BE RESTYLED** | Restyle KPI stat cards, state machine breakdown, and high-priority queue into Stitch cards with `#ffffff` surfaces, `#0d1c32` header, and JetBrains Mono metric labels. |
| **Admin Management Portal** (`e36e8361fb854d4dbdf108d5982f4839`) | `/dashboard` | `src/app/dashboard/page.tsx` | 100% Functional | 75% | **A. EXISTS AND CAN BE RESTYLED** | Incorporate Stitch management widgets (action cards, priority pills, and live sync bar) into `/dashboard`. |
| **Client Projects Dashboard** (`07f71e1e54eb4a7aa39ccd2434a06c97`) | `/projects` | `src/app/projects/page.tsx` | 100% Functional (Search, filters, actions) | 70% (Dark table vs Stitch precision table) | **A. EXISTS AND CAN BE RESTYLED** | Redesign projects data table to match Stitch: hairline borders (`0.5px`), JetBrains Mono headers, status badges, and action menus. Ensure label is "Engineer". |
| **Project Details & Versioning** (`e572bcf6ed714f66abf4ad3ed9e76f59`) | `/projects/[projectId]` | `src/app/projects/[projectId]/page.tsx` | 100% Functional (9 tabs, state machine actions) | 72% | **A. EXISTS AND CAN BE RESTYLED** | Restyle header card, tab navigation bar, drawing version lists, and metadata blocks using Stitch Architectural Precision layout. |
| **Project Workflow Timeline** (`38e7888db7244b7eae26165dc53d29b6`) | `/projects/[projectId]` (Timeline tab) | `src/app/projects/[projectId]/page.tsx` | 100% Functional (6 stages, progress %) | 85% | **A. EXISTS AND CAN BE RESTYLED** | Restyle vertical/horizontal timeline progression nodes, active pulsing indicators, and stage detail cards to match Stitch. |
| **Interactive CAD & Blueprint Viewer** (`e77723e954e7467facd412a9dcf77475`) | `/projects/[projectId]` (CAD tab) | `src/app/projects/[projectId]/page.tsx` | 100% Functional (Split/Overlay, SVG blueprint) | 80% | **A. EXISTS AND CAN BE RESTYLED** | Restyle CAD viewport toolbar, zoom controls (`25%`–`300%`), version selector dropdowns, and blueprint grid frame. |
| **Redline Correction Markup & Review** (`7c9582819a094ab8b303c9a128484e99`) | `/projects/[projectId]` (Corrections tab) | `src/app/projects/[projectId]/page.tsx` | 90% Functional (3 rounds cap, notes) | 65% | **B. EXISTS BUT NEEDS FUNCTIONAL WORK** | Enhance correction review presentation with visual markup indicator cards and round-by-round status tracking (capping at round 3). |
| **Collaboration Hub** (`c0e3b73a402a4297bff9ae5ab3910060`) | `/projects/[projectId]` (Collab tab) | `src/app/projects/[projectId]/page.tsx` | 100% Functional (Chat thread, roles, voice note) | 80% | **A. EXISTS AND CAN BE RESTYLED** | Restyle message bubbles, role tags (Engineer, Draughtsman, Admin), attachment cards, and voice note player to match Stitch. |
| **Drawings Library** (`c0d70c614fb14084911dfb38bf0aa9fa`) | `/projects/[projectId]` (Drawings tab) | `src/app/projects/[projectId]/page.tsx` | 100% Functional (Files, versions, R2 download) | 75% | **A. EXISTS AND CAN BE RESTYLED** | Restyle drawing asset cards, CAD thumbnail placeholders, revision chips, and download buttons to match Stitch. |
| **Financials & Invoicing** (`717b101899da4596bb83470749065e36`) | `/financials` | `src/app/financials/page.tsx` | 100% Functional (KPIs, ledger, jsPDF) | 75% | **A. EXISTS AND CAN BE RESTYLED** | Restyle KPI stat blocks, collection progress bar, and invoice ledger table with Stitch tokens while preserving exact jsPDF synthesis logic. |
| **System Settings Panel** (`c8bc2e94fc1e44d0af06862f7283493c`) | `/settings` | `src/app/settings/page.tsx` | 100% Functional (Worker, Firebase, D1 SQL) | 70% | **A. EXISTS AND CAN BE RESTYLED** | Restyle system health cards, connectivity monitors, and compliance cards into Stitch modular panels. |
| **User Profile & Account Settings** (`4ee871db6a7e49d3b29a16dae5f38f9c`) | `/settings` / Profile | `src/app/settings/page.tsx`, `Sidebar.tsx` | 80% Functional (Me endpoint, auth context) | 50% | **C. PARTIALLY EXISTS — EXTEND IT** | Create dedicated Admin Profile view/modal with editable non-privileged fields (`PATCH /api/users/me`), session logs, and notification toggles. |
| **Empty State & Blueprint Vault** (`c9281f147ee849519d8cb489db7c15ec`) | Shared component | Inlined across pages | 70% Functional | 40% (Ad-hoc icons vs Stitch blueprint vault) | **C. PARTIALLY EXISTS — EXTEND IT** | Build reusable `BlueprintEmptyState` component featuring technical compass icon, hairline grid container, and instructional copy. |
| **New Project Form Wizard** (`51b2be05d6024f93923908fc09b1d4a8`) | `/projects` (Modal) | `src/app/projects/page.tsx`, `worker/index.ts` | 60% (Worker has `POST /api/projects`) | 30% | **C. PARTIALLY EXISTS — EXTEND IT** | Implement admin-side New Project Form Wizard modal allowing admins to create drawing projects on behalf of engineers. |
| **Register & Onboarding Wizard** (`88ddbef0f53c4ebda434e92042716496`) | N/A (Admin blocked) | `worker/src/index.ts` (Rejects ADMIN) | Intentionally blocked for ADMIN | N/A | **E. STITCH DESIGN NEEDS CLARIFICATION** | Admin self-registration is rejected by security policy (`ADMIN_SECURITY_MODEL.md`). Keep registration disabled; use this design to inform client onboarding previews only. |
| **Engineer Submission Portal** (`2cc556cbc5044054a49aae10624d0dd4`) | `/engineers` | `src/app/engineers/page.tsx` | 100% Functional (Directory + Dossier modal) | 75% | **A. EXISTS AND CAN BE RESTYLED** | Restyle Engineer directory table and Engineer Submission dossier modal to match Stitch design. |
| **Draughtsman Workspace** (`f06203f554ef48629cd3b2dd71808e04`) | `/draughtsmen` | `src/app/draughtsmen/page.tsx` | 100% Functional (Pool + Workspace modal) | 75% | **A. EXISTS AND CAN BE RESTYLED** | Restyle Draughtsman directory table and Draughtsman Workspace preview modal to match Stitch design. |
| **Student Portal** (`8939aba231854f01b8c907b5cfc22f81`) | `/students` | `src/app/students/page.tsx` | 100% Functional (Truthful D1 + Demo fixtures) | 75% | **A. EXISTS AND CAN BE RESTYLED** | Restyle Student directory table, empty state, and Student Learning Portal preview modal to match Stitch design. |

---

## Section D — Already Completed & Reusable Assets

The audit confirms that substantial, production-ready engineering work is already in place. **None of this working business logic should be discarded:**

1. **Authentication & Session Resilience (`src/lib/auth.tsx`):**
   - Firebase Auth client initialization with auto-token refresh.
   - Fallback local admin session for development (`contact@draughtsmanstudio.com`).
   - Route protection redirecting unauthenticated traffic to `/login` and authenticated admins to `/dashboard`.
   - Automatic Bearer token injection on every outgoing API request.
2. **Authoritative Cloudflare Worker API Client (`src/lib/api.ts`):**
   - Endpoints for `getStats()`, `getProjects()`, `getProject()`, `getUsers()`, `getUserDetails()`, `getProjectFiles()`, `getProjectDrawingVersions()`, `getProjectCorrections()`, `getProjectAssignments()`, and `getProjectActivity()`.
   - Cryptographically random `actionId` generation on all state mutations (`approveProject`, `rejectProject`, `assignProject`, `reassignProject`, `cancelProject`) to guarantee backend idempotency.
   - Client-side fallback aggregation in `getStats()` if the remote Worker has unseeded endpoints.
3. **Sidebar Live Polling Badges (`src/components/layout/Sidebar.tsx`):**
   - Background 30-second polling against `adminApi.getStats()`.
   - Dynamic badges on Projects, Engineers, Draughtsmen, and Students with smart `99+` truncation.
   - Pulsing emerald live status indicator for studio operations.
4. **Users Table Pagination (`src/app/users/page.tsx`):**
   - `PAGE_SIZE = 10` rows per page with smart ellipsis page navigation (max 7 slots).
   - First, Previous, Page Number, Next, and Last buttons.
   - Dynamic role-based accent coloring and auto-reset to page 1 on search/tab filter changes.
5. **Live Polling Activity Feed (`src/app/activity/page.tsx`):**
   - Automated 15-second polling loop with active countdown timer.
   - LIVE / PAUSED toggle button with Radio icon.
   - Diff-based new event detection with fade-in CSS animations and incoming event banner.
   - Color-coded badges for 9 distinct action types.
6. **Client-Side PDF Invoice Generation (`src/app/financials/page.tsx`):**
   - Dynamic `jsPDF` import (SSR-safe).
   - High-precision A4 portrait layout with studio blueprint-grid header, Bill-To section, line-item table, totals block, colored payment status pill, and studio analytics footer.
   - Row-level loading spinner during PDF compilation.
7. **Three-Portal Terminology Engine (`src/components/ui/Badge.tsx`):**
   - Automatic translation of database role `CLIENT` to user-facing label **"Engineer"**.
   - Preserves backend data contracts while enforcing brand rules.

---

## Section E — Missing or Incomplete Work

To guide the upcoming implementation without ambiguity, incomplete items are categorized below:

### 1. Entirely Missing Screens
- **Landing Experience (`/`):** `src/app/page.tsx` is currently an empty stub returning `null`. It must be implemented with the full Stitch Landing Experience layout (`7ec75634815f4259adae789437f52ea7`): blueprint hero, platform value proposition, CAD viewer preview, feature breakdown, and quick portal links.

### 2. Partially Implemented Screens & Modals
- **Admin New Project Wizard Modal (`51b2be05d6024f93923908fc09b1d4a8`):** A modal workflow on `/projects` allowing Studio Admins to commission or record new projects directly with area, drawing type, and reference file attachments.
- **Dedicated Admin Profile View (`4ee871db6a7e49d3b29a16dae5f38f9c`):** An expanded profile and account management view allowing admin password changes, notification preference management, and session log inspection.
- **Standardized Blueprint Vault Empty State (`c9281f147ee849519d8cb489db7c15ec`):** A reusable component with blueprint grid styling, technical icon, and contextual action buttons.

### 3. Existing Screens Requiring Visual Redesign Only
- **`/login`:** Realign card elevation, typography, and colors to Stitch `#fbf9fb` canvas and `#ffffff` container.
- **`/dashboard`:** Convert cards to Stitch Architectural Precision tokens with JetBrains Mono numbers, hairline borders, and executive action queues.
- **`/projects`:** Restyle table, search bar, and filter pills to match Stitch client projects dashboard.
- **`/projects/[projectId]`:** Update tab styling, CAD split/overlay comparison frame, timeline tree, and discussion bubbles.
- **`/engineers`:** Restyle directory table and dossier modal.
- **`/draughtsmen`:** Restyle directory table and workspace preview modal.
- **`/students`:** Restyle directory table, empty state, and apprentice curriculum modal.
- **`/users`:** Restyle table and stats panel.
- **`/activity`:** Restyle live stream controls and event cards.
- **`/financials`:** Restyle KPI cards and invoice ledger table.
- **`/settings`:** Restyle infrastructure health and compliance cards.

### 4. Missing API / Backend Capabilities
- **None for Core Admin Functionality.** All required endpoints for projects, users, assignments, drawing versions, corrections, activity logs, and stats are already implemented in `worker/src/index.ts`.
- **Future Enhancement (Out of Scope for UI Revamp):** WebSocket or Server-Sent Events (SSE) for instant pushing of activity logs (currently handled via resilient 15s client polling).

### 5. Stitch Designs Requiring Product Decisions
- **Admin Registration (`88ddbef0f53c4ebda434e92042716496`):** Must remain disabled in the admin UI because admin account creation is restricted to direct D1 provisioning.
- **Mobile vs Desktop Comp Translation:** Stitch screens are structured as mobile-width viewports (`780px` width), whereas the Studio Admin Portal is an enterprise desktop web application (`1440px+` primary viewport). The Stitch Design System guidelines explicitly provide desktop grid metrics (fixed 260px sidebar, 64px outer margins, fluid workspace). All mobile Stitch comps will be faithfully translated into responsive desktop grid layouts following the Design System specification.

---

## Section F — Recommended Implementation Batches

The overhaul should be executed in **6 structured, manageable batches** to maintain continuous build health (`npm run build` exit code 0) and zero regression of working business logic:

```
┌────────────────────────────────────────────────────────────────────────┐
│               STUDIO ADMIN UI REVAMP IMPLEMENTATION ROADMAP             │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│   BATCH 1: Design Tokens, Typography, Layout Shell & Landing / Auth    │
│   ├── globals.css tokens & Tailwind variables (Architectural Precision)│
│   ├── Sidebar & Header redesign (260px fixed, Stitch visual style)     │
│   ├── Full Landing Experience implementation on `/`                    │
│   └── Restyled `/login`, `/forgot-password`, `/verify`                 │
│                                   │                                    │
│   BATCH 2: Executive Dashboard & Central Management Queue             │
│   ├── `/dashboard` restyle to Stitch Executive Dashboard               │
│   ├── High-Priority Queue & 8-stage state machine cards               │
│   └── Ecosystem roster telemetry (Engineers, Draughtsmen, Students)    │
│                                   │                                    │
│   BATCH 3: Project Pipeline & Granular Workspace                       │
│   ├── `/projects` catalog table, status filter tabs & search           │
│   ├── `/projects/[id]` header, specifications, and action buttons      │
│   ├── Workflow Timeline tab (6-stage milestone tracker)                │
│   ├── CAD Comparison Viewer tab (Split/Overlay, SVG blueprint diff)   │
│   ├── Collaboration Hub & Discussion tab                               │
│   └── Reference Files, Drawings Library, and Corrections tabs         │
│                                   │                                    │
│   BATCH 4: People & Ecosystem Management                               │
│   ├── `/engineers` directory & Engineer Submission dossier modal       │
│   ├── `/draughtsmen` talent pool & Draughtsman Workspace preview modal │
│   ├── `/students` directory with truthful empty state & demo toggle    │
│   └── `/users` unified directory with role tabs & pagination           │
│                                   │                                    │
│   BATCH 5: Activity Audit, Financials & Infrastructure Settings        │
│   ├── `/activity` live stream with polling controls                    │
│   ├── `/financials` revenue ledger, collection bar & jsPDF invoice     │
│   └── `/settings` Worker health, Firebase JWKS, and compliance cards   │
│                                   │                                    │
│   BATCH 6: Accessibility, Cross-Device Polish & Regression Testing     │
│   ├── Shared `BlueprintEmptyState` and `NewProjectModal` components    │
│   ├── Responsive testing (Mobile 390px, Tablet 1024px, Desktop 1440px) │
│   └── Full TypeScript compilation and production build verification    │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

### Detailed Batch Breakdown:

#### Batch 1 — Design Tokens, Layout Shell, Landing & Auth
- **Scope:** `globals.css`, `Sidebar.tsx`, `Header.tsx`, `AdminShell.tsx`, `src/app/page.tsx`, `src/app/login/page.tsx`, `src/app/forgot-password/page.tsx`, `src/app/verify/page.tsx`.
- **Stitch References:** `Architectural Precision System` theme tokens, `Landing Experience` (`7ec75634815f4259adae789437f52ea7`), `Unified Auth Login` (`f7f092239b55459f94392e8afe5ab526`), `Restore Access` (`baaf7b1e8ac64c8482ad78f5b28fdba0`), `Secure Verification` (`fe2dc34875f34bdfad0807d8f77f4ce4`).
- **Dependencies:** Firebase Auth context.
- **Validation:** Unauthenticated root `/` displays rich landing page; `/login` authenticates into `/dashboard`; build passes.

#### Batch 2 — Executive Dashboard & Priority Queue
- **Scope:** `src/app/dashboard/page.tsx`, `src/components/ui/Card.tsx`, `src/components/ui/Badge.tsx`.
- **Stitch References:** `Executive Dashboard` (`88593f310c8140bd9930b00748b9eabf`), `Admin Management Portal` (`e36e8361fb854d4dbdf108d5982f4839`).
- **Dependencies:** `adminApi.getStats()`, `adminApi.getProjects()`.
- **Validation:** Live metric cards display real D1 counts; High Priority Queue allows one-click navigation to project actions.

#### Batch 3 — Project Pipeline & Granular Workspace
- **Scope:** `src/app/projects/page.tsx`, `src/app/projects/[projectId]/page.tsx`, `AssignModal.tsx`, `RejectModal.tsx`, `CancelModal.tsx`.
- **Stitch References:** `Client Projects Dashboard` (`07f71e1e54eb4a7aa39ccd2434a06c97`), `Project Details & Versioning` (`e572bcf6ed714f66abf4ad3ed9e76f59`), `Project Workflow Timeline` (`38e7888db7244b7eae26165dc53d29b6`), `Interactive CAD & Blueprint Viewer` (`e77723e954e7467facd412a9dcf77475`), `Collaboration Hub` (`c0e3b73a402a4297bff9ae5ab3910060`), `Drawings Library` (`c0d70c614fb14084911dfb38bf0aa9fa`).
- **Dependencies:** Worker state machine endpoints with `actionId`.
- **Validation:** Project approval, rejection, assignment, and cancellation work; CAD viewer toggles Split/Overlay; timeline reflects real status.

#### Batch 4 — Ecosystem & Talent Management
- **Scope:** `src/app/engineers/page.tsx`, `src/app/draughtsmen/page.tsx`, `src/app/students/page.tsx`, `src/app/users/page.tsx`.
- **Stitch References:** `Engineer Submission Portal` (`2cc556cbc5044054a49aae10624d0dd4`), `Draughtsman Workspace` (`f06203f554ef48629cd3b2dd71808e04`), `Student Portal` (`8939aba231854f01b8c907b5cfc22f81`), `User Profile` (`4ee871db6a7e49d3b29a16dae5f38f9c`).
- **Dependencies:** `adminApi.getUsers()`, `adminApi.getUserDetails()`.
- **Validation:** Engineer firm dossiers open; Draughtsman active assignments display; Student empty state and demo fixture toggle work; pagination operates with 10 rows/page.

#### Batch 5 — Activity Audit, Financials & Infrastructure Settings
- **Scope:** `src/app/activity/page.tsx`, `src/app/financials/page.tsx`, `src/app/settings/page.tsx`.
- **Stitch References:** `Financials & Invoicing` (`717b101899da4596bb83470749065e36`), `System Settings Panel` (`c8bc2e94fc1e44d0af06862f7283493c`).
- **Dependencies:** `jsPDF`, polling timers.
- **Validation:** 15s activity polling functions; PDF invoice downloads successfully with branded A4 layout; health check reports live status.

#### Batch 6 — Polish, Reusable Components & Final Quality Assurance
- **Scope:** Reusable `BlueprintEmptyState` (`c9281f147ee849519d8cb489db7c15ec`), `NewProjectModal` (`51b2be05d6024f93923908fc09b1d4a8`), responsive audits on mobile/tablet/desktop, accessibility tags, final `npm run build`.
- **Validation:** Zero build errors, zero broken links, all 17 routes match Stitch visual direction.

---

## Section G — Risks, Constraints & Decisions

| Area | Risk / Observed Fact | Architectural Decision / Mitigation |
|:---|:---|:---|
| **Viewport Mismatch** | Stitch project screens are predominantly composed at mobile dimensions (`780px` or `390px` width), whereas the Studio Admin Portal is an enterprise desktop console. | Follow the **Stitch Architectural Precision System** desktop layout guidelines: fixed 260px sidebar, 64px outer margins, and fluid multi-column workspace grids that collapse gracefully on mobile. |
| **Admin Self-Registration** | Stitch includes `Register & Onboarding Wizard` (`88ddbef0f53c4ebda434e92042716496`), but `ADMIN_SECURITY_MODEL.md` explicitly forbids admin self-registration (`POST /api/users` rejects `ADMIN`). | Keep registration closed on admin web. Use the onboarding design only to preview client onboarding flows or configure existing admin preferences. |
| **Legacy Database Fields** | D1 database and Worker API use `CLIENT`, `client_id`, and `UNDER_CLIENT_REVIEW`. Renaming them would break the mobile Flutter app and Cloudflare Worker. | Enforce strict separation: UI layer displays **"Engineer"** everywhere (headings, tables, badges, dialogs), while internal API payloads retain backend keys (`client_id`, etc.). |
| **Correction Rounds Cap** | Stitch Redline Correction review shows feedback loops, which could suggest unlimited iterations. | Maintain strict backend enforcement: correction rounds are capped at **3 rounds maximum** as enforced by D1 state machine. |
| **Preserving PDF Synthesis** | The existing client-side `jsPDF` engine in `financials/page.tsx` was carefully calibrated for A4 portrait printing. | Retain the exact jsPDF generation code and data calculation while updating the on-screen ledger presentation to match Stitch. |
| **Live Polling Overhead** | Activity stream polls every 15s and sidebar polls every 30s. | Ensure polling timers are cleanly cleared on component unmount to prevent memory leaks or redundant Cloudflare Worker invocations. |

---

*Report prepared by PixelMint Studio MVS for Draughtsman Studio · Archi Draft Platform*
