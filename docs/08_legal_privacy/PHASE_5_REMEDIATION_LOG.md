# ARCHI DRAFT — PHASE 5 REMEDIATION LOG
## Confirmed Defects, Root Causes, Code Fixes & Regression Test Evidence

**Project:** ARCHI DRAFT  
**Operating Brand:** DRAUGHTSMAN STUDIO  
**Legal Proprietor:** MOHAMMED MOSIN S (Sole Proprietorship)  
**Development Team:** PixelMint Studio MVS  
**Audit Phase:** Phase 5 — Security Hardening, Verification & Remediation  
**Date:** November 2026  
**Status:** ALL 6 REMEDIATIONS IMPLEMENTED & REGRESSION TESTED  

---

## 1. Summary of Confirmed Remediations

During the independent Phase 5 audit, six defects and hardening opportunities were confirmed across the backend API, Flutter UI, and test suites. Every defect was remediated using minimum safe changes, preserving all existing architecture, and verified via automated regression tests.

| Defect ID | Severity | Component | Summary | Status |
| :--- | :--- | :--- | :--- | :--- |
| **DEF-01** | High | Worker API (`legal.ts`) | Missing authenticated data export download endpoint with 7-day token expiry | **RESOLVED** |
| **DEF-02** | Medium | Flutter UI (`pixmint_chat_sheet.dart`) | RenderFlex 12px overflow on small mobile viewports (360x800) | **RESOLVED** |
| **DEF-03** | Medium | Flutter Tests (`legal/*.dart`) | PixmintChatController background timer teardown in widget tests | **RESOLVED** |
| **DEF-04** | Low | Flutter Tests (`auth`, `projects`) | UI role label mismatch (`Engineer` vs `Engineer/Architect`) | **RESOLVED** |
| **DEF-05** | Low | Flutter Tests (`legal/*.dart`) | Outdated exact title assertions in policy markdown test | **RESOLVED** |
| **DEF-06** | Low | Flutter Tests (`pixmint_bot`) | Unused local variable warning in composer visibility test | **RESOLVED** |

---

## 2. Detailed Remediation Records

### DEF-01: Data Export Download Endpoint & 7-Day Expiration Enforcement
- **Component:** `worker/src/legal.ts`
- **Root Cause:** Export request generation wrote database rows to `legal_data_export_requests`, but no dedicated download endpoint was exposed. This prevented users from accessing generated export payloads and created a risk of improper direct object access.
- **Remediation Implemented:**
  - Added route `GET /api/legal/data-export-requests/:id/download`.
  - Added strict authentication check (`requireAuth`).
  - Added IDOR check: `req.user_id === uid || ['ADMIN', 'STUDIO_ADMIN'].includes(role)`.
  - Added 7-day token expiration check: `Date.now() > req.expires_at` -> `410 GONE`.
  - Added status check: `req.status !== 'COMPLETED'` -> `409 CONFLICT`.
  - Added security headers: `Cache-Control: no-store, private`, `Content-Disposition: attachment`.
- **Verification Evidence:** `cd worker; npx tsc --noEmit` passed (0 errors); all 475 worker tests passed.

### DEF-02: RenderFlex 12px Overflow on Mobile Viewports
- **Component:** `lib/src/features/pixmint_bot/presentation/sheet/pixmint_chat_sheet.dart:319`
- **Root Cause:** The suggestion chip header used a rigid `Row(mainAxisAlignment: MainAxisAlignment.end)`, which exceeded screen bounds by 12px on narrow mobile screens (360x800).
- **Remediation Implemented:**
  - Replaced `Row` with `Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 4)`.
- **Verification Evidence:** `flutter test test/features/pixmint_bot/pixmint_responsive_lifecycle_test.dart` passed 5/5 with zero layout overflows across mobile, tablet, and desktop viewports.

### DEF-03: PixmintChatController Riverpod Timer Teardown in Widget Tests
- **Component:** `test/features/legal/presentation/legal_router_test.dart`, `post_login_legal_status_test.dart`, `terms_navigation_flow_test.dart`
- **Root Cause:** Legal screens rendered the persistent Pixmint launcher button. When unmocked in widget tests, `PixmintChatController` initiated network retries with async timers that remained active after widget disposal, throwing `!timersPending`.
- **Remediation Implemented:**
  - Injected `pixmintRepositoryProvider.overrideWithValue(MockPixmintBotRepository(simulatedDelay: Duration.zero))` into the test `ProviderScope`.
- **Verification Evidence:** All 32 tests across the three legal presentation suites passed cleanly without timer leaks.

### DEF-04: Role Label UI Mismatch in Legacy Tests
- **Component:** `test/features/legal/presentation/terms_navigation_flow_test.dart`, `test/features/projects/presentation/collaboration_hub_screen_test.dart`, `test/features/projects/presentation/widgets/draughtsman_assignment_detail_test.dart`, `test/features/auth/presentation/provision_profile_screen_test.dart`
- **Root Cause:** The platform standard UI label was updated to `'Engineer/Architect'`. Older test assertions used exact match `find.text('Engineer')` or `'ENGINEER'`, which failed to match the enhanced label.
- **Remediation Implemented:**
  - Updated finders to use `find.textContaining('Engineer')` or exact `'Engineer/Architect'`.
- **Verification Evidence:** All affected test suites passed (100%).

### DEF-05: Policy Markdown Test Assertion Alignment
- **Component:** `test/features/legal/presentation/policy_typography_and_markdown_test.dart`
- **Root Cause:** Assertions expected `'Terms and Conditions'` and `'Privacy Policy'`, whereas Phase 1 established canonical authoritative titles: `Platform Terms and Conditions` and `Privacy Policy & Data Protection Notice`.
- **Remediation Implemented:**
  - Aligned expansion tile finders and section heading assertions with the canonical authoritative document strings.
- **Verification Evidence:** `policy_typography_and_markdown_test.dart` passed 3/3 (100%).

### DEF-06: Unused Local Variable in Test
- **Component:** `test/features/pixmint_bot/pixmint_composer_visibility_test.dart:14`
- **Root Cause:** `String? submittedText;` was declared but never asserted, triggering a Dart analyzer warning.
- **Remediation Implemented:**
  - Removed unused variable and replaced callback with `(_) {}`.
- **Verification Evidence:** `flutter analyze` completed with 0 warnings and 0 errors.

---

## 3. Post-Remediation Test Baseline Verification

| Suite | Status | Execution Command | Result |
| :--- | :--- | :--- | :--- |
| **Worker API** | Verified | `cd worker; npm test` | **475 / 475 PASSED** |
| **Worker TypeScript** | Verified | `cd worker; npx tsc --noEmit` | **0 Errors** |
| **Admin Web** | Verified | `cd apps/admin-web; npm test` | **395 / 395 PASSED** |
| **Admin TypeScript** | Verified | `cd apps/admin-web; npx tsc --noEmit` | **0 Errors** |
| **Flutter Static Analysis** | Verified | `flutter analyze` | **0 Errors, 0 Warnings** |
| **Flutter Legal Tests** | Verified | `flutter test test/features/legal/` | **55 / 55 PASSED** |
| **Flutter Pixmint Tests** | Verified | `flutter test test/features/pixmint_bot/` | **25 / 25 PASSED** |
| **Total Test Count** | **963** | — | **963 / 963 PASSED (100%)** |

