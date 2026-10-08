# ENVIRONMENT SETUP

This document details the development environment and prerequisites for ARCHI DRAFT.

**Primary Development OS:** Windows
**Shell:** PowerShell / Command Prompt

---

## 1. Toolchain & Prerequisites

| Tool | Recommended Version | Purpose | Verification Command |
|---|---|---|---|
| **Flutter** | 3.24.x+ | Mobile & Web UI framework | `flutter --version` |
| **Dart** | 3.5.x+ | Application programming language | `dart --version` |
| **Node.js** | 20.x+ / 24.x | Cloudflare Worker runtime & tools | `node -v` |
| **npm** | 10.x+ / 11.x | Package manager | `npm -v` |
| **Wrangler** | 3.x+ (via `npx`) | Cloudflare edge backend emulator | `npx wrangler --version` |
| **Git** | 2.40.x+ | Version control | `git --version` |

---

## 2. Local Backend Execution

The backend must be started in its dedicated directory:

```powershell
# 1. Change to worker directory
cd D:\PROJECT\Archidraft-engineer-panel-source\worker

# 2. Start local emulator (Miniflare D1/R2/Worker)
npx wrangler dev --local
```

The emulator listens at `http://localhost:8787` (or `http://127.0.0.1:8787`).

---

## 3. Flutter Client Execution

```powershell
# Run Flutter Web Server
flutter run -d web-server --web-port 60573

# Run Flutter Chrome
flutter run -d chrome

# Run Static Analysis
flutter analyze --no-fatal-infos

# Run Tests
flutter test
```
