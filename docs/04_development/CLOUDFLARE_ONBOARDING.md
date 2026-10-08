# CLOUDFLARE BACKEND ONBOARDING & SAFETY GUIDE

This project uses Cloudflare Workers, Cloudflare D1 (SQL), and Cloudflare R2 (Object Storage) for its edge backend.

---

## 1. Actual Worker Project Structure

The Cloudflare Worker backend is located inside the dedicated `worker/` subdirectory:

```text
Archidraft-engineer-panel-source/
 ├── lib/                    (Flutter Client Source)
 └── worker/                 (Cloudflare Worker Backend)
      ├── wrangler.toml      (Worker, D1, and R2 bindings)
      ├── package.json       (Hono & Worker dependencies)
      ├── tsconfig.json      (TypeScript configuration)
      ├── src/
      │    ├── index.ts      (Hono API routes & business logic)
      │    └── auth.ts       (Firebase JWT verification)
      └── migrations/        (SQL schema migrations 0001 - 0008)
```

> [!CAUTION]
> **DO NOT USE ROOT-LEVEL WRANGLER WORKAROUNDS:**
> Do NOT create `wrangler.jsonc`, `src/index.ts`, or a `migrations/` folder at the workspace root. The backend belongs exclusively in `worker/`.

---

## 2. Running the Backend Locally

To execute the local backend emulator:

```bash
# 1. Navigate to the worker directory
cd D:\PROJECT\Archidraft-engineer-panel-source\worker

# 2. Run the local emulator
npx wrangler dev --local
```

### Local Emulation Behavior
- Wrangler uses Miniflare to emulate Cloudflare Workers, local D1 SQLite database, and local R2 storage bucket.
- The local emulator runs on `http://localhost:8787` (or `http://127.0.0.1:8787`).
- The Flutter client is configured to connect to `http://localhost:8787` in development mode.

---

## 3. Strict Rules for AI Agents & Developers

1. **NEVER run `npx wrangler deploy`:**
   Deploying to production is strictly restricted to the project owner. Running deploy without authorization will overwrite live edge code.
2. **NEVER run `npx wrangler d1 migrations apply --remote`:**
   Applying remote migrations executes schema changes on the live production database and can cause irreversible data loss.
3. **NEVER modify production IDs:**
   Do not alter `database_id` or `bucket_name` in `worker/wrangler.toml`.
4. **Local Migration Testing Only:**
   To apply migrations locally for testing:
   ```bash
   cd worker
   npx wrangler d1 migrations apply archi-draft-db --local
   ```
