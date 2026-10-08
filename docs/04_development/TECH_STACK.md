# TECH STACK & PACKAGES

This document defines the verified, active technology stack for ARCHI DRAFT.

---

## 1. Core Stack

- **Frontend Framework:** Flutter 3.x
- **Language:** Dart 3.x
- **Platforms:** Web (Responsive Desktop/Tablet) & Mobile (Android/iOS)
- **State Management:** Flutter Riverpod 2.x
- **Navigation & Routing:** `go_router`
- **Identity & Authentication:** Firebase Authentication
- **Backend API:** Cloudflare Workers with Hono Framework (TypeScript)
- **Database:** Cloudflare D1 (Serverless SQLite)
- **Object Storage:** Cloudflare R2 (S3-compatible private object storage)
- **Local Emulation:** Wrangler 3.x (Miniflare)
- **Version Control:** Git (GitHub)

---

## 2. Key Flutter Packages (`pubspec.yaml`)

- `flutter_riverpod`: Reactive dependency injection and caching.
- `go_router`: Declarative routing with URL parameter extraction and redirect guards.
- `firebase_core` & `firebase_auth`: Identity authentication and token generation.
- `http`: Underlying HTTP client for API communication.
- `file_picker`: Native file picking for reference blueprints and chat attachments.
- `open_filex`: Native file opener for mobile and desktop environments.
- `path_provider`: Local filesystem paths for download streaming.
- `intl`: Date and time formatting (`DateFormat`).
- `uuid`: Client-side UUID v4 generation for action IDs and idempotency tokens.

---

## 3. Worker Stack (`worker/package.json`)

- `hono`: Ultrafast web framework for Cloudflare Workers.
- `@cloudflare/workers-types`: TypeScript bindings for D1 and R2.
- `wrangler`: Edge deployment and local emulation toolchain.
