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
           ├── engineer/                (Engineer screens: projects dashboard, form, detail, activity)
           ├── profile/                 (Profile screens, UserRole, ProfileRepository)
           ├── projects/                (Project CRUD, detail screen, workflow actions, collaboration hub)
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

---

## 5. Collaboration Hub Media & File Architecture

The Collaboration Hub incorporates dedicated media handling engines:
- **WhatsApp-Style Voice Messages:**
  - Audio playback directly in-chat via `VoiceMessagePlayer`.
  - No user-facing download button or OS storage pollution.
  - Bounded in-memory byte cache (`_audioCache`) fetched through authenticated file endpoints.
  - Mutual-exclusion audio controller (`activeAudioPlayerIdProvider`) ensuring single-source playback.
- **Inline Image Previews:**
  - Raster formats (PNG, JPG, WebP, GIF, BMP, AVIF) detected via MIME and file extensions.
  - Inline chat thumbnail box with shimmer loader and retry states.
  - Tapping opens an interactive full-screen Lightbox with smooth 0.5x–5.0x zoom/pan via `InteractiveViewer`.
- **CAD File Architecture (DXF & DWG):**
  - **DXF:** Pure-Dart 2D ASCII vector parser (`DxfDrawing.parse`) rendering `LINE`, `CIRCLE`, `ARC`, `LWPOLYLINE`, `POINT`, and `TEXT` on a hardware-accelerated canvas with inverted CAD coordinate correction.
  - **DWG:** Truthful fallback handling. On Android, launches installed compatible applications (Autodesk, DWG FastView) via `open_filex`. On Web, provides authenticated file download. Private R2 drawings are never uploaded to third-party conversion APIs.

---

## 6. Mobile Responsiveness & Layout Architecture

- **Navigation Shell Isolation:**
  - `ResponsiveScaffold` monitors the active path. When inside `/collaboration-hub`, mobile shell bars (`AppBottomNav`, `AppTopBar`) are automatically suppressed.
  - Eliminates the mobile layout defect where the message composer was hidden beneath bottom navigation tabs.
- **Safe Area & Keyboard Adaptation:**
  - `Scaffold.resizeToAvoidBottomInset` ensures the message composer moves smoothly above on-screen software keyboards.
  - Composer wrapped in `SafeArea(bottom: true)` to prevent obstruction by device gesture bars or home indicators.
  - `LayoutBuilder` removes outer padding and card borders on screens `< 650px` for a native edge-to-edge chat experience.

---

## 7. Role Module Boundaries & Separation

- **Role Feature Roots:**
  - `lib/src/features/engineer/` (Engineer-owned dashboard, submissions, activity, financials)
  - `lib/src/features/draughtsman/` (Reserved root with boundary specification README)
  - `lib/src/features/student/` (Reserved root with boundary specification README)
- **Shared Cross-Portal Modules:**
  - `lib/src/features/projects/` (Domain models, file repositories, upload pipelines)
  - `lib/src/features/collaboration/` (Collaboration Hub screen, voice player, image/CAD viewers)
  - `lib/src/features/auth/` & `core/` (Authentication, theme tokens, HTTP client)
