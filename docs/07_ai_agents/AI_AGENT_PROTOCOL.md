# AI AGENT PROTOCOL & OPERATIONAL RULES

This document defines the mandatory, permanent operating protocol for all AI agents working in the ARCHI DRAFT codebase.

---

## 1. Prime Directive: Codebase is the Source of Truth

> [!IMPORTANT]
> **THE CURRENT WORKING CODEBASE IS THE SOURCE OF TRUTH.**
> The `docs/` folder contains descriptive architectural documentation, **NOT** automatic development orders.

Future AI agents must strictly follow these rules:
1. **Read the documentation** to understand project structure and conventions.
2. **Inspect the active implementation** in Flutter, Cloudflare Workers, and D1 migrations.
3. **Compare documentation against active code** before taking any action.
4. **Never rebuild completed functionality** simply because an older document describes it as planned or incomplete.
5. **Never create duplicate models, parallel repositories, or duplicate backend systems.**
6. **Never invent new user roles or unapproved project statuses.**
7. **Never silently alter architecture, storage buckets, or database schemas.**
8. **Never modify unrelated completed features.**
9. **Respect the active branch scope** (e.g. do not develop Draughtsman or Admin features on `Engineer_Panels`).
10. **Respect owner-controlled Git operations** (never commit or push automatically).
11. **Ask the user for clarification** whenever documentation and code appear to conflict.

---

## 2. Absolute Git Work Control

AI agents must **NEVER** run Git write commands automatically:
- ❌ `git commit`
- ❌ `git push`
- ❌ `git merge`
- ❌ `git rebase`
- ❌ `git reset`
- ❌ `git checkout` / `git switch`
- ❌ `git restore` / `git clean`

All Git write operations are performed manually by the human project owner.

---

## 3. Working With Edge Resources

- **Worker Backend Path:** `D:\PROJECT\Archidraft-engineer-panel-source\worker`
- **Local Emulator Command:** `cd worker && npx wrangler dev --local`
- **DO NOT create root-level wrangler files** (`wrangler.jsonc`, root `src/`, root `migrations/`).
- **DO NOT run remote deployments** (`npx wrangler deploy`) or remote migrations (`--remote`) without explicit authorization from the project owner.

---

## 4. Reporting Requirements
Every AI agent must provide a clear, factual report at the end of each task detailing:
- Files modified and created.
- Architecture rules followed.
- Static analysis results (`flutter analyze`).
- Test execution results (`flutter test`).
- Explicit confirmation that Git operations were left to the owner.
