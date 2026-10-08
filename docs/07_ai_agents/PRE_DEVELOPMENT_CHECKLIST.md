# PRE-DEVELOPMENT & READINESS CHECKLIST

This checklist records the implementation readiness and architectural status of the ARCHI DRAFT platform.

---

## 1. Engineer Portal Scope (`Engineer_Panels`)

- [x] **Roles Locked:** `ENGINEER`, `DRAUGHTSMAN`, `STUDENT`, `STUDIO_ADMIN` verified and active.
- [x] **Authentication & RBAC:** Firebase Auth + Cloudflare Worker JWT validation locked.
- [x] **Project Status Machine:** 8 verified enums in D1 and Flutter locked.
- [x] **Correction Workflow:** 3-round limit strictly enforced by Worker backend.
- [x] **R2 Storage & 50 MB Limits:** Streaming byte counters and extension allowlists active.
- [x] **Binary File Open:** Authoritative MIME mapping and Object URL preview implemented and verified.
- [x] **Collaboration Hub:** Real-time messages, D1 persistence (`project_messages`), and attachments active.
- [x] **Financials Excision:** Zero payment/billing UI in Engineer portal; Worker route locked to Admin.
- [x] **Quality Gate:** 0 Flutter analyze issues, 0 Worker typecheck issues, 63 passing unit/widget tests.

---

## 2. Branch Status: `Engineer_Panels` COMPLETED & FROZEN

The Engineer Portal is **COMPLETED and FROZEN**. No additional features or refactoring should be introduced on this branch.

---

## 3. Checklist for Future Cross-Branch Integration
When merging `Engineer_Panels`, `Draughtsman_Panels`, and other feature branches into the main integration branch:
1. Verify database migration alignment in `worker/migrations/` (migrations 0001 through 0008).
2. Execute end-to-end multi-role test: Engineer submits brief → Admin approves & assigns → Draughtsman accepts → Draughtsman uploads drawing → Engineer reviews in Collaboration Hub and approves.
3. Validate cross-role push notifications between Engineer and Draughtsman.
4. Execute `flutter analyze --no-fatal-infos` and full test suite across all portals.
