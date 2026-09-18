# CLOUDFLARE BACKEND SUMMARY & ONBOARDING

**To:** All Collaborating Developers & AI Agents
**Subject:** Backend Workflow and Local Development Rules

This project uses Cloudflare Workers, D1 (SQL Database), and R2 (Object Storage) for its backend. 

We maintain a strict separation between **Local Development** and **Production**. Read these instructions carefully to ensure you do not break the live production database.

---

## 💻 1. How to Run the Backend Locally

When you pull this repository to work on a new feature, you must run your own isolated local backend emulator. You **do not** need Cloudflare login credentials for this.

**Steps for the AI Agent / Developer:**
1. Open a terminal and navigate to the worker directory:
   ```bash
   cd worker
   ```
2. Install dependencies (first time only):
   ```bash
   npm install
   ```
3. Start the local backend emulator (Miniflare):
   ```bash
   npx wrangler dev
   ```
4. *Result:* Wrangler will automatically create local, dummy versions of the D1 database and R2 bucket on your machine. 

Leave this terminal running in the background. The Flutter app is hardcoded (via `lib/src/core/constants/api_constants.dart`) to communicate with `http://localhost:8787` during development.

---

## 🚫 2. Strict Rules for AI Agents (DO NOT DO THESE)

The `wrangler.toml` file contains the real `database_id` for the production database (`af8d3312-5f6e-46ce-bcc1-dfa91e484cc0`). Because of this, you must follow these rules:

1. **NEVER run `npx wrangler deploy`**
   Only the lead project owner handles deployments. Running this will push your local, experimental backend code to the live internet.
   
2. **NEVER run `npx wrangler d1 migrations apply --remote`**
   This will execute SQL schema changes on the live production database, potentially dropping tables or corrupting real user data. (Running `npx wrangler d1 migrations apply` *without* the `--remote` flag to update your local dummy DB is fine).

3. **NEVER modify the `database_id` or `bucket_name` in `wrangler.toml`**
   These point to the live production resources.

---

## 🗄️ 3. Modifying the Database Schema

If your feature requires a new database table or altering an existing one:

1. Create a new SQL migration file in `worker/migrations/`:
   ```bash
   npx wrangler d1 migrations create archi-draft-db <migration_name>
   ```
2. Write your SQL in the generated file.
3. Apply it to your **local** emulator to test your feature:
   ```bash
   npx wrangler d1 migrations apply archi-draft-db --local
   ```
4. Commit the migration file to Git. The project owner will apply it to production later.

---

## 🚀 4. How the Project Owner Deploys to Production (For Reference Only)

When features are merged and ready for live users, the project owner (who is logged into the Cloudflare account) will execute:

1. Apply new migrations to the live database:
   ```bash
   npx wrangler d1 migrations apply archi-draft-db --remote
   ```
2. Push the updated Worker code:
   ```bash
   npx wrangler deploy
   ```
3. When building the final Flutter App release, the API URL is injected via Dart defines:
   ```bash
   flutter build apk --dart-define=API_URL=https://archi-draft-worker.imserratex.workers.dev
   ```
