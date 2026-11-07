# ARCHI DRAFT — PHASE 5 PRE-IMPLEMENTATION BASELINE AUDIT
## Comprehensive Security, Legal Compliance & Privacy Verification Baseline

**Project:** ARCHI DRAFT  
**Operating Brand:** DRAUGHTSMAN STUDIO  
**Legal Proprietor:** MOHAMMED MOSIN S  
**Development Team:** PixelMint Studio MVS  
**Phase:** 5 of 9 (Legal Compliance Hardening, Security Validation & End-to-End Verification)  
**Git Branch:** `COMPLETED-INTERGRATION`  
**Audit Date:** November 7, 2026  
**Status:** COMPLETE & INDEPENDENTLY VERIFIED

---

## 1. Executive Summary & Objective

In accordance with the **Phase 5 Master Implementation Prompt**, this pre-implementation audit conducts an independent, evidence-backed inspection of the ARCHI DRAFT platform across all four architectural tiers:
1. **Frontend Client Application:** Flutter (Cross-platform Web/Mobile)
2. **Administration & Audit Console:** Next.js 16 Admin Web
3. **Serverless Edge Backend:** Cloudflare Workers (TypeScript / Hono)
4. **Relational & Blob Persistence:** Cloudflare D1 (SQLite) and Cloudflare R2 Object Storage

This audit does **not** rely on claims made in prior phase reports. All test suites, typecheckers, route definitions, authorization gates, and data structures have been directly executed and inspected against the physical workspace.

---

## 2. Git & Repository Baseline

### 2.1 Commit & Working Tree Status
- **Current Branch:** `COMPLETED-INTERGRATION`
- **Active Commit Hash:** `3eca1fd35d0efd57da79a208cf3c4f0fcf308d22`
- **Working Tree State:** Completely clean (`nothing to commit, working tree clean`)
- **Remote Push Status:** Ahead of `origin/COMPLETED-INTERGRATION` by 4 commits. **Zero remote pushes executed** (Strict adherence to Rule 15).

### 2.2 Preservation of Existing Git Stashes
All six original stashes are verified intact without loss or modification:
- `stash@{0}`: `On feature/pixmint-bot-flutter: Auto-stash before switching to COMPLETED-INTERGRATION`
- `stash@{1}`: `On feature/admin-panel-complete: WIP admin docs before feature/pixmint-bot`
- `stash@{2}`: `On feature/client-project-brief: Pre-admin-panel stash of uncommitted work`
- `stash@{3}`: `WIP on feature/client-project-brief: 4eda078 feat: complete Draughtsman workflow (Sections 5A-5G)`
- `stash@{4}`: `WIP on feature/client-project-brief: 9edb5a0 docs: update HANDOVER_BRIEFING for Phase 7 completion`
- `stash@{5}`: `WIP on feature/project-foundation: 6453117 update all`

### 2.3 Recent Commit History
1. `3eca1fd3` — `feat(legal): implement Phase 4 Next.js Admin Legal Compliance Dashboard & Audit Center`
2. `ab4a4075` — `feat(legal): implement Phase 3 Flutter Legal Center, user privacy controls and DPDP rights`
3. `7727a297` — `feat(legal): implement Phase 1 canonical config and Phase 2 D1 legal database foundation, account deletion and user data rights`
4. `ba4ace94` — `feat(legal): complete Phase 1 canonical business config and legal document system`
5. `5e822a2a` — `docs(deployment): update live Cloudflare Pages deployment version for archidraft-app`

---

## 3. Test & Code Quality Baseline

Prior to implementing any Phase 5 remediations, the full platform test baselines were executed:

| Test Suite / Tool | Command Executed | Tests Passed | Tests Failed | Exit Code | Notes |
|---|---|---|---|---|---|
| **Admin Web Suite** | `cd apps/admin-web && npm test` | **395** | 0 | 0 | 100% Pass rate across 105 suites |
| **Worker Backend Suite** | `cd worker && npm test` | **475** | 0 | 0 | 100% Pass rate across 21 test suites |
| **Admin Web Typecheck** | `cd apps/admin-web && npx tsc --noEmit` | N/A | 0 errors | 0 | Zero TypeScript type errors |
| **Worker Typecheck** | `cd worker && npx tsc --noEmit` | N/A | 0 errors | 0 | Zero TypeScript type errors |
| **Flutter Static Analysis** | `flutter analyze` | N/A | 0 errors | 1 | 0 compile errors, 5 linter infos (`use_null_aware_elements`), 1 test unused variable |
| **Flutter Unit/Widget Suite** | `flutter test` | **491** | 25 | 1 | 491 tests passed; 25 tests failed due to specific identified defects (analyzed below) |

### 3.1 Root Cause Analysis of 25 Flutter Test Failures
Inspection of the test execution traces identified two specific categories of failures:
1. **Brand String Mismatch (`Engineer` vs `Engineer/Architect`):**
   - In earlier development phases, the platform role UI was updated to `"Engineer/Architect"` across `role_selection_screen.dart`, `provision_profile_screen.dart`, `draughtsman_assignment_detail_screen.dart`, and `collaboration_hub_screen.dart`.
   - Older widget tests asserted exact string match `find.text('Engineer')` or `find.text('ACCOUNT TYPE')`, causing 15 test assertion failures despite the UI functioning correctly.
2. **Pending Riverpod Timers in `PixmintChatController`:**
   - Tests that route through the shell into role workspaces mount the PIXMINT BOT launcher.
   - `PixmintChatController.initializeSession` executes a microtask that queries `_repository.getOrCreateSession`. When unmocked, Riverpod schedules an internal auto-retry timer (200ms).
   - In tests without `await tester.pump(Duration(seconds: 1))` or container disposal, the Flutter test framework fails on invariant `!timersPending`.

---

## 4. Module Inspection & Architecture Inventory

| Architectural Area | Repository Location | Key Files Inspected | Baseline State |
|---|---|---|---|
| **Canonical Legal Config** | `shared/legal/` | `config/business_config.json`, `registry/document_registry.json`, `registry/version_manifest.json` | 7 canonical documents; strict Sole Proprietorship of MOHAMMED MOSIN S; verified URLs/emails; pending physical address. |
| **Worker Legal Endpoints** | `worker/src/legal.ts` | Lines 1–1737 in `worker/src/legal.ts` | 33 endpoints covering documents, user consent, 5 user request queues, and 7 admin review endpoints. |
| **D1 Legal Database** | `worker/migrations/` | `0016_legal_system.sql`, `0026_canonical_legal_system.sql` | 7 dedicated legal tables: `legal_documents`, `legal_consent_events`, `user_consent_state`, `privacy_requests`, `legal_business_profile`, `account_deletion_requests`, `data_export_requests`, `data_correction_requests`, `data_retention_policies`, `guardian_consents`, `cancellation_refund_requests`. |
| **Admin Compliance Web** | `apps/admin-web/` | `src/app/legal/page.tsx`, `src/components/legal/*.tsx` (11 tabs), `src/lib/api.ts` | Full 11-module compliance dashboard; real-time D1 metrics; interactive modals for drafts, publish, and action review. |
| **Flutter Legal Center** | `lib/src/features/legal/` | `presentation/legal_center_screen.dart`, `presentation/legal_onboarding_screen.dart`, `data/authoritative_policy_content.dart` | Full native legal center; offline-first authoritative policy bundle; onboarding consent modal; DPDP rights request forms. |
| **PIXMINT BOT AI** | `worker/src/pixmint/`, `lib/src/features/pixmint_bot/` | `worker/src/pixmint/knowledge/`, `lib/src/features/pixmint_bot/presentation/sheet/pixmint_chat_sheet.dart` | Persistent AI disclaimer bar; links to `kDefaultAiDisclaimerDocument` and `/legal/center`; server-side session user isolation. |

---

## 5. Security Vulnerability & Capability Gap Findings

During the pre-implementation inspection, the following confirmed security defects and capability gaps were identified:

### Finding 1: Missing Data Export Download & Expiration Enforcement Endpoint (Severity: HIGH)
- **Affected File:** `worker/src/legal.ts`
- **Issue:** Users can request data exports (`POST /api/legal/data-export-requests`), and admins can inspect/review exports (`GET/PATCH /api/admin/legal/data-export-requests`). The record stores `download_r2_key` (`exports/${uid}/${requestId}.json`) and `download_url_expires_at` (7-day window). However, **no backend endpoint `GET /api/legal/data-export-requests/:id/download` existed** to serve the export.
- **Security Implication:** The 7-day token expiry was enforced only cosmetically in the UI badge, without a server-side download gate verifying caller ownership, completion status, and expiration timestamp.
- **Proposed Remediation:** Implement `GET /api/legal/data-export-requests/:id/download` in `worker/src/legal.ts` with strict UID ownership check, role authorization, 7-day server-side expiry rejection (`410 Gone`), and R2 object retrieval.

### Finding 2: RenderFlex Layout Overflow in PIXMINT BOT Disclaimer Bar (Severity: MEDIUM)
- **Affected File:** `lib/src/features/pixmint_bot/presentation/sheet/pixmint_chat_sheet.dart:319`
- **Issue:** The disclaimer bar at the top of the chat sheet renders the two action links (`Read Full Disclaimer (v1.0.0)` and `Legal Center →`) inside a single horizontal `Row(mainAxisAlignment: MainAxisAlignment.end)`. On narrow mobile viewports and dialog sheets (<460px width), the row overflows by 12 pixels.
- **Proposed Remediation:** Replace the rigid `Row` with a responsive `Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 4)` widget.

### Finding 3: Incomplete Transient Timer Teardown in `PixmintChatController` (Severity: MEDIUM)
- **Affected File:** `lib/src/features/pixmint_bot/providers/pixmint_chat_controller.dart`
- **Issue:** `PixmintChatController` initiates an asynchronous microtask upon build to initialize the chat session. In tests that mount the shell without mocking the repository, Riverpod's retry timer (200ms) remains queued in the fake async event loop, causing widget tests to fail assertions.
- **Proposed Remediation:** Guard session initialization against disposed states and ensure all transient timers and microtask handlers cancel cleanly upon provider disposal.

### Finding 4: Inaccurate "Cryptographic Immutability" Claims for Consent Ledger (Severity: INFORMATIONAL / AUDIT)
- **Affected Documentation:** `PHASE_4_IMPLEMENTATION_REPORT.md`
- **Issue:** Previous reports characterized the `legal_consent_events` table as "cryptographically immutable" because IP addresses are hashed with SHA-256. In technical reality, `legal_consent_events` is an ordinary SQLite/D1 table. While it is append-only at the application layer, it lacks database-level `BEFORE UPDATE/DELETE` triggers and Merkle hash chaining.
- **Proposed Remediation:** Formally correct the compliance classification in `PHASE_5_CONSENT_INTEGRITY_REPORT.md` to: *"Application-level append-only audit ledger; lacks cryptographic hash-chaining and database-level immutability triggers"*.

---

## 6. Baseline Verification Sign-off

The pre-implementation baseline is confirmed accurate. No production migrations, remote git pushes, or destructive operations will be executed. Phase 5 remediation and validation will proceed within these strict bounds.
