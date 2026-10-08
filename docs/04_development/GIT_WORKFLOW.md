# GIT WORKFLOW & ABSOLUTE WORK CONTROL

ARCHI DRAFT is maintained across isolated feature and role branches to guarantee zero regressions.

---

## 1. Active Branch Strategy

- **`Engineer_Panels` (CURRENT BRANCH):** Dedicated to the Engineer Portal. Fully completed and frozen.
- **`Draughtsman_Panels`:** Dedicated to the Draughtsman Studio OS and workspace.
- **`Student_panels`:** Dedicated to student learning workflows.
- **Eventual Integration:** All role-specific panels will be integrated into the main application branch once individual portals reach audited completion.

---

## 2. Absolute Work Control Rules

> [!CAUTION]
> **AI AGENTS MUST NEVER COMMIT OR PUSH AUTOMATICALLY:**
> All Git write operations are strictly controlled and performed manually by the project owner.

Developers and AI agents working on this repository must strictly adhere to the following:
1. **DO NOT commit** automatically.
2. **DO NOT push** automatically.
3. **DO NOT merge** branches automatically.
4. **DO NOT rebase**.
5. **DO NOT reset** (`git reset`).
6. **DO NOT switch branches** without explicit instruction.
7. **DO NOT run `git restore` or `git clean`**; never discard working directory modifications.
8. **DO NOT overwrite another developer's work.**

---

## 3. Pre-Commit Review Procedure
Before proposing any code for manual commit by the owner:
1. Run read-only commands:
   ```bash
   git status
   git diff
   ```
2. Verify that only files strictly within the task scope are modified.
3. Verify that zero unrelated files or generated artifacts are left unreviewed.
