# ADMIN PANEL ARCHITECTURE

> Last Updated: October 2026

## Overview

The Archi Draft Admin Panel is a **separate web application** that provides Studio Administrators with a comprehensive view of the platform's operations. It is deployed independently on **Vercel** and communicates with the same **Cloudflare Worker API** used by the Flutter mobile application.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     ARCHI DRAFT ECOSYSTEM                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐       ┌──────────────┐                       │
│  │ Flutter App   │       │ Admin Panel   │                       │
│  │ (Mobile/Web)  │       │ (Next.js)     │                       │
│  │               │       │               │                       │
│  │ • Client      │       │ • Dashboard   │                       │
│  │ • Draughtsman │       │ • Projects    │                       │
│  │ • (Admin*)    │       │ • Users       │                       │
│  └──────┬───────┘       │ • Activity    │                       │
│         │                │ • Settings    │                       │
│         │                └──────┬───────┘                       │
│         │                       │                                │
│         │    Firebase Auth      │    Firebase Auth               │
│         │    (ID Token)         │    (ID Token)                  │
│         │                       │                                │
│         ▼                       ▼                                │
│  ┌──────────────────────────────────────┐                       │
│  │       Cloudflare Worker (Hono)       │                       │
│  │  • verifyFirebaseToken() middleware  │                       │
│  │  • Role-based authorization          │                       │
│  │  • State machine enforcement         │                       │
│  │  • Idempotent actions (actionId)     │                       │
│  │  • Immutable activity logging        │                       │
│  ├──────────────┬───────────────────────┤                       │
│  │ D1 (SQLite)  │    R2 (Object Store)  │                       │
│  │ • users      │    • CAD files        │                       │
│  │ • projects   │    • PDFs             │                       │
│  │ • assignments│    • References       │                       │
│  │ • files      │    • Drawings         │                       │
│  │ • corrections│                       │                       │
│  │ • activity   │                       │                       │
│  │   _logs      │                       │                       │
│  └──────────────┴───────────────────────┘                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

*Admin panel in Flutter is a minimal embedded view. The web Admin Panel is the **primary** admin interface.

## Non-Negotiable Architectural Constraints

1. **Single Source of Truth:** The Cloudflare Worker API is the ONLY data access layer. The Admin Panel must NEVER directly access D1 or R2.

2. **Firebase Auth Identity:** The Admin Panel uses the same Firebase Auth project (`archi-draft`) and verifies tokens via the same JWKS chain. Admin users must already exist in D1 with `role = 'ADMIN'`.

3. **Backend Authority:** All state transitions (approve, reject, assign, reassign, cancel) are enforced by the Worker. The Admin Panel sends requests; the Worker decides validity.

4. **Immutable Activity Logs:** Activity logs are server-generated. The Admin Panel displays them read-only.

5. **No Duplicate Business Logic:** Business rules (state machine transitions, correction limits, role validation) live exclusively in the Worker. The Admin Panel must NEVER re-implement them.

6. **Security ≠ UI:** Hiding a button is not security. All authorization happens at the Worker API level.

## Tech Stack

| Layer | Technology | Rationale |
|---|---|---|
| Framework | Next.js 14+ (App Router) | SSR/SSG support, Vercel-native deployment |
| Language | TypeScript | Type safety for API contracts |
| Auth | Firebase Auth (Web SDK) | Same identity provider as Flutter app |
| HTTP Client | Fetch API / SWR | Server-side and client-side data fetching |
| Styling | Tailwind CSS | Rapid development, consistent design |
| State | React Context + SWR | Lightweight, no Redux needed for admin CRUD |
| Deployment | Vercel | Zero-config, automatic preview deploys |
| Testing | Vitest + Playwright | Unit + E2E testing |

## Directory Structure

```
apps/admin-web/
├── .env.local                    # Firebase config, Worker URL
├── .env.example                  # Template for required env vars
├── next.config.js
├── tailwind.config.ts
├── tsconfig.json
├── package.json
├── public/
│   └── favicon.ico
├── src/
│   ├── app/                      # Next.js App Router pages
│   │   ├── layout.tsx            # Root layout with AuthProvider
│   │   ├── page.tsx              # Root redirect → /dashboard
│   │   ├── login/
│   │   │   └── page.tsx          # Admin login screen
│   │   ├── dashboard/
│   │   │   └── page.tsx          # Dashboard with aggregate stats
│   │   ├── projects/
│   │   │   ├── page.tsx          # Project list with filters
│   │   │   └── [projectId]/
│   │   │       └── page.tsx      # Project detail with actions
│   │   ├── users/
│   │   │   ├── page.tsx          # User directory
│   │   │   └── [userId]/
│   │   │       └── page.tsx      # User profile view
│   │   ├── activity/
│   │   │   └── page.tsx          # Global activity feed
│   │   └── settings/
│   │       └── page.tsx          # System settings
│   ├── components/               # Reusable UI components
│   │   ├── layout/
│   │   │   ├── Sidebar.tsx
│   │   │   ├── Header.tsx
│   │   │   └── AdminShell.tsx
│   │   ├── ui/
│   │   │   ├── Button.tsx
│   │   │   ├── Card.tsx
│   │   │   ├── Badge.tsx
│   │   │   ├── Table.tsx
│   │   │   ├── Modal.tsx
│   │   │   └── ...
│   │   ├── projects/
│   │   │   ├── ProjectCard.tsx
│   │   │   ├── ProjectTable.tsx
│   │   │   ├── AssignModal.tsx
│   │   │   └── ...
│   │   └── dashboard/
│   │       ├── StatCard.tsx
│   │       ├── StatusChart.tsx
│   │       └── ActivityFeed.tsx
│   ├── lib/                      # Core libraries
│   │   ├── firebase.ts           # Firebase init (client-side only)
│   │   ├── api.ts                # Typed API client for Worker
│   │   ├── auth.ts               # Auth context + hooks
│   │   └── types.ts              # Shared TypeScript types
│   ├── hooks/                    # Custom React hooks
│   │   ├── useAuth.ts
│   │   ├── useProjects.ts
│   │   ├── useUsers.ts
│   │   └── useActivity.ts
│   └── styles/
│       └── globals.css           # Tailwind imports + custom styles
└── tests/
    ├── unit/
    └── e2e/
```

## API Contract (Admin Panel → Worker)

The Admin Panel consumes these Worker endpoints:

### Read Operations
| Endpoint | Method | Purpose |
|---|---|---|
| `/api/admin/stats` | GET | Dashboard aggregate statistics |
| `/api/projects` | GET | List all projects (ADMIN sees all) |
| `/api/projects/:projectId` | GET | Single project detail |
| `/api/projects/:projectId/activity` | GET | Project activity logs |
| `/api/projects/:projectId/assignments` | GET | Assignment history |
| `/api/projects/:projectId/files` | GET | Project file list |
| `/api/projects/:projectId/drawing_versions` | GET | Drawing version history |
| `/api/projects/:projectId/corrections` | GET | Correction records |
| `/api/users` | GET | User directory (filterable by role) |
| `/api/users/me` | GET | Current admin profile |
| `/api/files/:fileId/download` | GET | Download file from R2 |

### Write Operations
| Endpoint | Method | Purpose |
|---|---|---|
| `/api/projects/approve` | POST | Approve submitted project |
| `/api/projects/reject` | POST | Reject submitted project |
| `/api/projects/assign` | POST | Assign draughtsman |
| `/api/projects/reassign` | POST | Reassign draughtsman |
| `/api/projects/cancel` | POST | Cancel a project |

## Security Model

1. **Authentication Flow:**
   - Admin logs in via Firebase Auth (email/password)
   - Firebase returns an ID token
   - Every API request includes `Authorization: Bearer <token>`
   - Worker verifies token via JWKS, extracts `uid`
   - Worker checks D1 `users` table: `role = 'ADMIN'`

2. **Admin Account Creation:**
   - Admin accounts are NEVER created through the web UI registration flow
   - They must be seeded directly in D1 or through a protected CLI/script
   - The Worker's `POST /api/users` explicitly blocks admin self-creation

3. **CORS Policy:**
   - Worker must allow the Vercel deployment domain as an origin
   - Current implementation uses permissive CORS (`*`), which should be tightened for production
