# SYSTEM ARCHITECTURE

## 1. Architectural Topology

```text
┌────────────────────────────────────────────────────────┐
│               FLUTTER APPLICATION CLIENT               │
│          (Web & Mobile, Dart, Flutter Riverpod)        │
└───────────┬────────────────────────────────┬───────────┘
            │ Firebase Auth Tokens           │ REST API & Streams
            ▼                                ▼
┌──────────────────────┐         ┌───────────────────────┐
│ FIREBASE AUTH        │         │ CLOUDFLARE WORKER     │
│ (Identity & JWT)     │         │ (Hono API at Edge)    │
└──────────────────────┘         └───────────┬───────────┘
                                             │
                       ┌─────────────────────┴─────────────────────┐
                       ▼                                           ▼
         ┌───────────────────────────┐               ┌───────────────────────────┐
         │ CLOUDFLARE D1 (SQL)       │               │ CLOUDFLARE R2             │
         │ Relational Metadata & DB  │               │ Binary Object Storage     │
         └───────────────────────────┘               └───────────────────────────┘
```

> [!NOTE]
> **Architecture Evolution Note:** The early baseline architecture referenced Firebase Cloud Firestore, Firebase Storage, and Firebase Cloud Functions. The active application is built entirely on the **Cloudflare Workers edge stack** with Cloudflare D1 and Cloudflare R2, using Firebase Authentication solely for identity management.

---

## 2. Core Layers

### A. Client Layer (Flutter)
- **Framework:** Flutter 3.x with Dart 3.x.
- **State & DI:** Flutter Riverpod (`Provider`, `StateNotifierProvider`, `AsyncValue`).
- **Routing:** `go_router` with declarative routing and auth redirect guards.
- **HTTP Client:** `ApiClient` handling authentication headers, query parameters, multipart streaming, and cross-platform download resolution (`api_client_web.dart` and `api_client_io.dart`).

### B. API Gateway & Logic Layer (Cloudflare Worker)
- **Framework:** Hono running on Cloudflare Workers.
- **Authentication Middleware:** Validates Firebase ID tokens (`Bearer <token>`) using Google public keys and attaches `c.set('uid', sub)`.
- **Authorization & RBAC:** Enforces permissions per role (`ENGINEER`, `DRAUGHTSMAN`, `STUDENT`, `STUDIO_ADMIN`) and verifies project ownership (`client_id == uid`).
- **Streaming Pipeline:** Streams files directly to Cloudflare R2 with in-flight byte counting and strict 50 MB limits.

### C. Data Persistence Layer (Cloudflare D1)
- **Engine:** Serverless relational SQLite at the edge.
- **Schema Management:** 8 versioned SQL migrations (`worker/migrations/`).
- **Transactional Batches:** Uses `db.batch()` for atomic multi-table updates (e.g. updating project status, logging activity, creating notifications in a single transaction).

### D. Binary Storage Layer (Cloudflare R2)
- **Engine:** Cloudflare R2 S3-compatible object storage.
- **Access Model:** Completely private bucket (`archi-draft-storage`). Direct client access is forbidden; all uploads, downloads, previews, and deletions are mediated and authorized by the Worker API.

---

## 3. Critical State Transitions
All critical state mutations are mediated exclusively by the Cloudflare Worker API:
- `POST /api/projects` (Save Draft)
- `POST /api/projects/submit` (Submit Project)
- `POST /api/projects/approve` (Admin Approve)
- `POST /api/projects/assign` (Admin Assign)
- `POST /api/assignments/accept` (Draughtsman Accept)
- `POST /api/projects/submit-drawing` (Draughtsman Submit Drawing)
- `POST /api/projects/request-correction` (Engineer Request Revision)
- `POST /api/projects/approve-final` (Engineer Final Approval)
