# DEVELOPMENT ROADMAP & BRANCH PROGRESSION

ARCHI DRAFT is developed across dedicated, role-scoped Git branches to ensure clean separation of concerns and avoid cross-portal regressions.

---

## 1. Branch Architecture

- **`Engineer_Panels` (CURRENT BRANCH):** Complete implementation and hardening of the Engineer Portal. **(COMPLETED & FROZEN)**
- **`Draughtsman_Panels`:** Implementation of the Draughtsman Studio OS, drawing workspace, and draughtsman-side collaboration hub.
- **`Student_panels`:** Implementation of educational learning portals.
- **`main` / `develop`:** Production integration target where portal branches will merge.

---

## 2. Engineer Portal Progression (`Engineer_Panels`)

### ✅ COMPLETED NOW (FROZEN ON `Engineer_Panels`)
1. **Foundation & Architecture:** Clean Riverpod state architecture, GoRouter routing, responsive AppShell, theme tokens.
2. **Authentication & Identity:** Firebase Auth integration, email verification barrier, role-based routing guards.
3. **Engineer Profile:** Profile management in D1 (`mobile`, `date_of_birth`, `address`, `company_name`) with immutable role.
4. **Project Brief Form:** Draft intake form with technical drawing types, area calculation, budget metadata, and preliminary estimate.
5. **Draft Persistence & Submission:** `DRAFT` saving and idempotent submission to Cloudflare D1 with `PROJECT_SUBMITTED` audit logging.
6. **R2 File Storage & Management:** Direct streaming uploads via Worker with 50 MB limits, D1 file status lifecycle (`REQUESTED` → `COMPLETED`), download streaming.
7. **Binary File Open Resolution:** Authoritative MIME resolution, inline headers, and Blob-based Object URL rendering for native PDF/image preview on Web and desktop/mobile viewers.
8. **Project Details & Workflow UI:** Comprehensive project details screen with status chips, technical metadata, and contextual workflow action buttons.
9. **Scoped Engineer Activity:** Real-time activity feed filtered strictly to the authenticated Engineer's owned projects, excluding internal studio and financial events.
10. **In-App Notifications:** Persisted D1 notification queue supporting `CHAT_MESSAGE`, `DRAWING_SUBMITTED`, etc.
11. **Collaboration Hub:** Fully implemented project-level discussion screen with real-time messages, sender badges, message composer, and file attachments up to 50 MB.
12. **Financials / Payment Removal:** Complete excision of all billing, invoices, payments, checkout, and financial dashboards from the Engineer Portal.
13. **Preliminary Estimates:** Standardized display of preliminary estimation (`EST. COST: --`, `TIMELINE: --`) with zero artificial billing calculations.
14. **Validation & Quality:** 0 Flutter analyze errors, 0 Worker typecheck errors, 63 passing unit/widget tests.

---

## 3. DEFERRED / FUTURE INTEGRATION (OUT OF SCOPE FOR `Engineer_Panels`)
- **End-to-End Cross-Portal Verification:** Live, simultaneous messaging between an Engineer session on `Engineer_Panels` and a Draughtsman session on `Draughtsman_Panels` is deferred until branch integration.
- **Admin Assignment Flow:** Studio Admin project approval and drafter assignment UI (deferred to Admin branch).
- **Automated Pricing / Cost Calculations:** If real architectural calculation algorithms are approved in the future, they will be specified separately.
