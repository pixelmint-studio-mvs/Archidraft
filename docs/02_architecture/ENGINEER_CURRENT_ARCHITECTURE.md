# ENGINEER CURRENT ARCHITECTURE (TECHNICAL SPECIFICATION)

This document details the internal technical architecture of the Engineer Portal as implemented on branch `Engineer_Panels`.

---

## 1. Flutter Client Architecture

The Flutter application follows a clean, layered feature-first architecture:

```text
lib/
 ├── main.dart                          (Entry point, Firebase init, Riverpod scope)
 └── src/
      ├── core/
      │    ├── constants/               (API endpoints, environment constants)
      │    ├── router/app_router.dart   (GoRouter routes, auth guards, redirects)
      │    ├── theme/                   (AppColors, AppSpacing, AppTypography, AppTheme)
      │    └── utils/                   (Auth error mapper, file labels, validators)
      ├── shared/widgets/               (GlassCard, BlueprintBackground, AppStateWidgets)
      └── features/
           ├── api/                     (ApiClient, cross-platform streaming)
           ├── auth/                    (Firebase Auth controllers, login, registration)
           ├── profile/                 (Profile screens, UserRole, ProfileRepository)
           ├── projects/                (Project CRUD, detail screen, workflow actions)
           └── notifications/           (Notifications list, read states)
```

---

## 2. State Management Architecture (Riverpod)

The application utilizes Riverpod 2.x for dependency injection and state management:

### Key Providers
- `authStateChangesProvider`: Streams current Firebase Auth user state.
- `currentUserRoleProvider`: Resolves authenticated `UserRole` from `userProfileProvider`.
- `userProfileProvider`: `AsyncNotifier` fetching and caching the user profile from `/api/users/me`.
- `engineerProjectsProvider`: `FutureProvider` fetching all projects owned by the authenticated Engineer.
- `projectDetailProvider(projectId)`: Family provider fetching specific project metadata.
- `projectFilesProvider(projectId)`: Family provider fetching attached project files.
- `projectMessagesProvider(projectId)`: Family provider managing Collaboration Hub messages.
- `engineerActivityLogsProvider`: Provider streaming scoped activity logs.

---

## 3. API Client & Streaming Architecture

The `ApiClient` abstracts HTTP communication and platform differences:

- **Authentication Header Injection:** Automatically retrieves the Firebase ID token and injects `Authorization: Bearer <token>`.
- **Streaming Uploads (`postFileStream`):** Binds file streams to HTTP POST requests with custom headers (`X-File-Name`, `X-Action-Id`).
- **Cross-Platform Download Resolution (`downloadFileStream`):**
  - Uses conditional imports: `api_client_io.dart` on Mobile/Desktop vs `api_client_web.dart` on Web.
  - On Web: Creates `html.Blob` with authoritative MIME type, generating an Object URL for either native browser preview or anchor download.
  - On Mobile: Streams bytes directly to local app storage using `dart:io` `File.openWrite()`.

---

## 4. Cloudflare Worker Edge Layer

Located in `worker/src/index.ts`:

- **Hono Framework:** Lightweight, high-performance routing framework running on Cloudflare Workers.
- **Middleware:** CORS and Bearer token JWT authentication middleware on all routes.
- **D1 Prepared Statements:** All queries use parameterized bindings to prevent SQL injection:
  ```typescript
  const project = await db.prepare('SELECT * FROM projects WHERE id = ?').bind(projectId).first();
  ```
- **R2 Streaming with TransformStream:** Validates file size in flight to prevent memory exhaustion and buffer overflow attacks.
- **Idempotent Batches:** Uses `db.batch()` to commit multi-record mutations atomically.
