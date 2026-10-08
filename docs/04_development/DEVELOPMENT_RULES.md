# DEVELOPMENT RULES

Strict rules for all developers and AI agents working on ARCHI DRAFT:

---

## 1. Source of Truth
**The current working application codebase is the absolute source of truth.**
Documentation is descriptive, not prescriptive. If documentation conflicts with active code, update the documentation. Never change working application code to match outdated documentation.

---

## 2. Absolute Git Work Control
- **NO Automatic Commits or Pushes:** Developers and AI agents must never automatically run `git commit`, `git push`, `git merge`, `git rebase`, or `git reset`.
- All Git write operations are strictly controlled and performed manually by the project owner.
- Always inspect `git status` and `git diff` before proposing changes.

---

## 3. Branch Scoping
- Respect branch boundaries. On branch `Engineer_Panels`, do not build Admin, Draughtsman, or Student features.
- Do not refactor unrelated completed features.

---

## 4. No Duplicate Systems
- Do not create duplicate data models.
- Do not create parallel backend systems or duplicate endpoints.
- Do not invent new roles or unapproved project statuses.

---

## 5. Security & Validation
- UI hiding is not security; enforce all permissions in the Cloudflare Worker.
- Critical workflow transitions require transactional backend execution.
- Maintain server-side file protections (50 MB streaming limits, extension allowlists).

---

## 6. Negative & Edge Case Testing
Always test failure and boundary states:
- Unauthorized access attempts.
- Inactive or replaced assignment tokens.
- Fourth correction attempt rejection (max 3 rounds).
- Oversized file uploads (> 50 MB).
