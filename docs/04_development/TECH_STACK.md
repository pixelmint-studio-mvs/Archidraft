# TECH STACK & PACKAGES

This document defines the approved technology stack for ARCHI DRAFT.

## Core Stack
- **Frontend Framework:** Flutter (Dart 3.4+ / Flutter 3.22+)
- **Programming Language:** Dart
- **Supported Platforms:** Web (Chrome, Edge, Android Mobile/Tablet) and Android Native

- **Authentication:** Firebase Authentication
- **Database:** Cloudflare D1 (Relational SQLite)
- **File Storage:** Cloudflare R2 (Object Storage)
- **Backend API:** Cloudflare Workers (Hono runtime)
- **Web Hosting:** Cloudflare Pages (`archidraft-app` at `https://archidraft-app.pages.dev`)
- **Admin Studio:** Next.js 14 / React (hosted on Vercel at `https://admin-web-eight-wine.vercel.app/`)
- **Version Control:** Git
- **Repository Hosting:** GitHub/GitLab/Bitbucket (To be decided by the team)

## PACKAGE SELECTION POLICY
Before adding ANY third-party package to `pubspec.yaml`, developers and AI agents must follow this strict policy:

1. **Check Native Capabilities:** Verify whether Flutter or Dart natively provides the required capability.
2. **Avoid Duplicates:** Do not add a package if a similar one is already in the project.
3. **Verify Maintenance:** Only use packages that are actively maintained and popular on `pub.dev`.
4. **Check Compatibility:** Ensure the package is compatible with the installed Flutter/Dart versions and other Firebase dependencies.
5. **Minimize Dependencies:** Avoid packages that pull in large dependency trees unnecessarily.
6. **Document Reason:** Every package addition must have a documented technical reason in the PR or commit message.
7. **No AI Preference:** Do not add a package merely because an AI agent prefers it; always validate technical necessity.

### Recommended Package Categories
- **State Management:** `provider`, `riverpod`, or `bloc` (⚠️ TEAM DECISION REQUIRED)
- **Routing:** `go_router`
- **Firebase Integration:** `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `cloud_functions`
- **File Picking:** `file_picker`
- **UUID Generation:** `uuid`
- **Formatting:** `intl` (for dates/currency)
- **Logging:** `logger`
