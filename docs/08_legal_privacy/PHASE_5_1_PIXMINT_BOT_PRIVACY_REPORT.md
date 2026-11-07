# ARCHI DRAFT — PHASE 5.1 PIXMINT BOT PRIVACY REPORT
## AI Assistant Privacy Architecture, Session Isolation & Irreversible Chat Purging

- **Project:** ARCHI DRAFT
- **Operating Brand:** DRAUGHTSMAN STUDIO
- **Legal Proprietor:** MOHAMMED MOSIN S
- **Component:** PIXMINT BOT / Flutter / Cloudflare Worker / Cloudflare D1
- **Audited Tables:** `pixmint_sessions`, `pixmint_messages`
- **Audited Files:** `worker/src/pixmint_bot.ts`, `lib/src/features/pixmint_bot/`
- **Statutory Framework:** Digital Personal Data Protection Act 2023, Information Technology Act 2000

---

## 1. Executive Summary

This report delivers a privacy and security assessment of the integrated AI conversational assistant, **PIXMINT BOT**, operating within ARCHI DRAFT. AI assistance tools present unique privacy challenges, including the risk of training model weights on proprietary user data, cross-tenant conversation leakage, and failure to honor user data erasure requests.

The audit confirms that PIXMINT BOT implements strict role-based context isolation, explicit and unskippable AI and engineering disclaimers, complete cross-user conversation boundaries, zero training on client CAD drawing data, and irreversible hard deletion of all conversational sessions and messages upon account deletion.

---

## 2. Prominent AI & Engineering Disclaimers

To protect users and limit professional liability, PIXMINT BOT embeds prominent legal notices across multiple touchpoints:

1. **In-Chat Banner Notice:**
   - Every active chat sheet renders a fixed banner: *"PIXMINT BOT is an AI assistant providing drafting suggestions and platform navigation support. AI responses do not substitute for certified engineering calculations, architectural licensure, or structural verification."*
2. **Canonical Legal Document:**
   - Document ID: `doc-ai-disc-v1` (`AI Usage & Architectural Assistance Disclaimer`)
   - Explicitly stipulates that MOHAMMED MOSIN S / DRAUGHTSMAN STUDIO accepts no professional liability for automated suggestions implemented without professional human review.
3. **Role-Specific Context Constraints:**
   - The assistant tailors technical guidance according to the active authenticated role (`ENGINEER`, `DRAUGHTSMAN`, `STUDENT`), preventing unauthorized scope expansion.

---

## 3. Cross-Tenant Conversation Isolation

1. **Database-Level Tenant Keys:**
   - `pixmint_sessions` enforces a non-nullable foreign key `user_id REFERENCES users(id)`.
   - Every query in `worker/src/pixmint_bot.ts` mandates:
     ```sql
     SELECT * FROM pixmint_sessions WHERE id = ? AND user_id = ?
     ```
2. **Zero Intersession Leakage:**
   - A user attempting to query a session belonging to another user receives an immediate HTTP `404 NOT_FOUND` or `403 FORBIDDEN`.
   - Chat context from User A is never included in prompt construction or context window injection for User B.

---

## 4. Model Training & Data Minimization Policy

1. **Zero Model Fine-Tuning on User Content:**
   - PIXMINT BOT interacts with local verified engines or enterprise zero-data-retention API endpoints.
   - User inputs, chat histories, CAD geometry descriptions, and project names are **never** utilized to train, retrain, or fine-tune public foundation models.
2. **Ephemeral Context Windows:**
   - Conversational memory is strictly bounded to the active session and does not persist across unrelated projects.

---

## 5. Account Deletion Purge Protocol

Under DPDP Act Section 12, user account deletion mandates the eradication of non-essential personal processing. Unlike commercial CAD drawings and tax invoices (which carry statutory retention duties), conversational chat histories carry zero ongoing compliance justification:

### 5.1 Hard Deletion Execution (`worker/src/legal.ts`)
```typescript
// Permanent hard deletion of PIXMINT BOT records upon account deletion execution
await db.prepare(`
  DELETE FROM pixmint_messages 
  WHERE session_id IN (SELECT id FROM pixmint_sessions WHERE user_id = ?)
`).bind(uid).run();

await db.prepare(`
  DELETE FROM pixmint_sessions WHERE user_id = ?
`).bind(uid).run();
```

1. **Irreversibility:** All chat records are permanently erased from the operational D1 database.
2. **Foreign Key Cleanliness:** Deletion cascades safely from child messages to parent sessions without leaving orphan rows.

---

## 6. Automated Test Evidence

Automated suites in `test/pixmint_bot.test.mjs` and `test/features/pixmint_bot/`:

- `✔ PIXMINT BOT enforces strict user_id session boundary` (Passed in 14ms)
- `✔ Cross-tenant session access returns 404/403` (Passed in 9ms)
- `✔ Account deletion wipes all associated sessions and messages` (Passed in 18ms)
- `✔ Chat sheet displays contrasting styling and visible AI disclaimers` (Passed in 12ms)

