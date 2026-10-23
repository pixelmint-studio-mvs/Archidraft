# Archi Draft — Studio Admin Panel

> Dedicated Next.js web application for Draughtsman Studio Administrators. Deployed independently on Vercel and connected to the Cloudflare Worker API.

---

## 🏛️ Architecture Overview

The Admin Panel operates under a **strict 3-layer security model**:

```
Client (Next.js) ──[Firebase ID Token]──> Cloudflare Worker ──[D1 Auth Check]──> SQLite Engine
```

1. **Identity Provider:** Shared Firebase Authentication project (`archi-draft`).
2. **Authoritative API:** Cloudflare Worker (`/api/admin/stats`, `/api/projects`, `/api/users`).
3. **Storage:** Cloudflare D1 (metadata & immutable audit logs) + Cloudflare R2 (CAD files & drawings).

---

## 🚀 Getting Started

### 1. Environment Setup

Copy `.env.example` to `.env.local`:

```bash
cp .env.example .env.local
```

Configure your variables:

```env
# Firebase Web Client Configuration
NEXT_PUBLIC_FIREBASE_API_KEY=<from_firebase_console>
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=archi-draft.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=archi-draft
NEXT_PUBLIC_FIREBASE_APP_ID=1:471564030203:web:bb8fc985704d4d22e4e05e

# Authoritative Cloudflare Worker API
NEXT_PUBLIC_WORKER_API_URL=https://archi-draft-worker.imserratex.workers.dev
```

### 2. Run Locally

```bash
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) to view the console.

---

## 🛡️ Administrative Security & Role Enforcement

- **No Self-Registration:** Public registration cannot create `ADMIN` users.
- **D1 Role Authorization:** Every API call verifies that `user.role === 'ADMIN'`. Non-admin accounts attempting login are immediately rejected and signed out.
- **Idempotent Operations:** All state-changing actions generate a UUID v4 `actionId` to prevent duplicate submissions or race conditions.
- **Seed Admin Account:**
  ```sql
  INSERT INTO users (id, email, name, role) 
  VALUES ('<FIREBASE_UID>', 'admin@archidraft.com', 'Studio Admin', 'ADMIN');
  ```

---

## 📦 Deployment to Vercel

1. Import the repository into [Vercel](https://vercel.com).
2. Set the **Root Directory** to `apps/admin-web`.
3. Add the environment variables from `.env.example`.
4. Deploy!
