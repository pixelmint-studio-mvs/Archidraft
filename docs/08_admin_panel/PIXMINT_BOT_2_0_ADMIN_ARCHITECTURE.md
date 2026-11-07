# PIXMINT BOT 2.0 — ARCHITECTURAL AI ASSISTANT PLATFORM & ADMIN CONTROL CENTER

**Product:** ARCHI DRAFT Studio  
**Component:** PIXMINT BOT 2.0 Integration & Next.js Admin Web Control Center (`/bot`)  
**Target Environment:** Staging & Production Ready  
**Git Branch:** `COMPLETED-INTERGRATION`  
**Date:** November 7, 2026  

---

## 1. System Overview

PIXMINT BOT 2.0 is an intelligent, grounded architectural AI assistant platform natively integrated across ARCHI DRAFT user portals (Engineer, Draughtsman, Student) and managed centrally through the Next.js Admin Web Portal (`/bot`).

The platform consists of:
1. **Flutter Client Integration (`lib/src/features/pixmint_bot/`):**
   - Floating responsive assistant mascot and expandable chat sheet.
   - High-contrast chat composer: White `#FFFFFF` background, dark charcoal `#17212B` text, and emerald green `#00D6A0` cursor.
   - Concurrency guard lock preventing multiple initialization calls.
   - Active session preservation across screen navigation and window minimizes.
2. **Cloudflare Worker Backend (`worker/src/pixmint/`):**
   - Grounded RAG retrieval engine over approved architectural documentation and CAD standards.
   - Session reuse on `POST /api/pixmint/chat/sessions` (returns existing active session by default).
   - Domain-aware title generation on first message turn (`handleSendMessage`).
   - Self-healing legacy conversation titles in `handleGetConversations`.
   - Comprehensive Question Analytics and Knowledge Gap audit clustering.
3. **Next.js Admin Control Center (`apps/admin-web/src/app/bot/page.tsx`):**
   - Consolidated 5-tab simplified management interface for Studio Admins.
   - User-Grouped Conversation Management table with expandable history sub-tables.
   - Full continuous WhatsApp-style chat inspection modal with source citations, feedback ratings, and technical identifiers.

---

## 2. Admin Control Center 5-Tab Architecture

The Admin Control Center simplifies 7 technical tabs down to 5 operational sections:

```
+-----------------------------------------------------------------------------------+
|  [1. Dashboard]  [2. Settings]  [3. Knowledge]  [4. Conversations]  [5. Insights] |
+-----------------------------------------------------------------------------------+
```

### Tab 1 — Dashboard
- **Performance KPIs:** Conversations Today, Messages Today, Average Response Latency, and User Satisfaction Rate.
- **System Status Bar:** Real-time badges for Bot Status (Active/Disabled), Maintenance Mode (On/Off), D1 Connection, and RAG Engine.
- **Quick Controls:** 1-click bot enable/disable toggle and navigation shortcuts.
- **Recent Administrative Activity:** Live audit stream of configuration changes and document actions.

### Tab 2 — Bot Settings
Organized into 4 clean cards:
- **A. General Settings:** Bot Display Name, Welcome Greeting, System Status toggle, Maintenance Mode toggle.
- **B. Portal Access:** Independent active toggles for Engineer, Draughtsman, and Student portals.
- **C. AI Configuration:** Model selection (Cloudflare Workers AI / grounded local fallback), Temperature slider, Max tokens.
- **D. Suggested Questions:** Role-scoped starter prompts with inline add, edit, delete, and active toggles.

### Tab 3 — Knowledge Base
- Search and filter by category (General, CAD Standards, Drawing Revisions, Redline, Submission, Curriculum).
- Document status toggles (Active / Inactive) for immediate grounding exclusion.
- Document upload modal with category assignment.
- Document deletion modal with confirmation.

### Tab 4 — Conversations (Hierarchical User-Grouped View)
- **User-Grouped Table:** Aggregates sessions by user to prevent visual duplication.
  - Columns: User (Email / ID), Role badge, Total Sessions badge, Last Active timestamp, and "View History" toggle action.
- **Collapsible Conversation History View:**
  - Shows all individual sessions for the expanded user (`updatedAt DESC`).
  - Columns: Conversation Title (domain-generated), Created, Last Active, Message Count, and "Inspect Chat" action.
- **WhatsApp-Style Continuous Chat Inspector:**
  - Chronological chat thread with distinct user and bot message bubbles.
  - Official PIXMINT BOT avatar, source citations, helpful/unhelpful feedback badges, and expandable technical metadata.

### Tab 5 — Feedback & Insights (Question Analytics & Knowledge Gap Audit)
- **Summary Metrics (6 KPIs):** Questions Analyzed, Question Groups, Most Repeated Topic, Unanswered Queries, Negative Feedback, and Topics To Review.
- **Most Frequently Asked Questions:** Semantic clustering table showing topic ranks, occurrence counts, portal distribution, and last asked date.
- **Question Group Audit Modal:** Detailed view of question variations, portal breakdown, resolution rate, and sample responses.
- **Knowledge Gaps & Action Items:** Auto-detected topics receiving negative feedback or falling below grounding confidence thresholds, with direct links to upload knowledge documents.
- **CSV Audit Report Export:** 1-click export of structured question analytics.

---

## 3. Strict Role Governance & Invariants

ARCHI DRAFT strictly enforces role boundaries:
- **Supported Roles:** `ENGINEER`, `DRAUGHTSMAN`, `STUDENT`, `STUDIO_ADMIN` / `ADMIN`.
- **Prohibited Roles:** `CLIENT` and `GUEST` are completely prohibited from PIXMINT BOT access.
- **No Client/Guest Artifacts:** Zero client or guest options appear in portal toggles, suggestions, conversation filters, or analytics.

---

## 4. Global Floating Chatbot Widget (`PixmintChatWidget`)

In addition to the governance control center at `/bot`, a dedicated, interactive floating PIXMINT BOT widget is mounted globally across the Admin Web portal (`apps/admin-web/src/components/bot/PixmintChatWidget.tsx`):
- **Placement:** Anchored at `bottom-6 right-6` with higher precedence, neatly positioned below the `SupportWidget` at `bottom-20 right-6`.
- **Mascot & State:** Features the official PIXMINT BOT mascot avatar (`/images/pixmint_bot_avatar.png`), pulsing emerald green online status indicator, and version badge (`v2.0.0`).
- **Interactive Capabilities:**
  - Active admin session reuse via `POST /api/pixmint/chat/sessions` (persists conversation across navigation).
  - Quick-start starter suggestions tailored for Studio Admin queries (`GET /api/pixmint/chat/suggestions?role=admin`).
  - High-contrast composer with pure white `#FFFFFF` background, `#17212B` dark charcoal text, `#8A98A8` hint, and `#00D6A0` emerald cursor.
  - Grounded source citation inspection accordion.
  - In-chat thumbs up/down message feedback submission (`POST /api/pixmint/chat/feedback`).
  - Custom DOM event hook (`open-pixmint-bot`) enabling 1-click launch from the `/bot` dashboard header.

---

## 5. Test & Verification Coverage

| Component | Test Suite | Tests Passed | Status |
|---|---|---|---|
| Cloudflare Worker | `worker/test/` | **463 / 463** | 100% Passed |
| Flutter App | `test/features/pixmint_bot/` | **25 / 25** | 100% Passed |
| Admin Web Portal | `apps/admin-web/test/pixmint-bot-admin.test.ts` | **32 / 32** | 100% Passed |
| Next.js Production Build | `apps/admin-web/` (`npm run build`) | **37 / 37 Routes** | Prerendered & Verified |

