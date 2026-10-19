# ENVIRONMENT SETUP

This document lists the actual development environment versions installed during Phase 0. 

**Operating System:** Windows

| Tool Name | Installed Version | Purpose | Verification Command |
|---|---|---|---|
| **Git** | VERIFY BEFORE DEVELOPMENT | Source Control | `git --version` |
| **Flutter** | VERIFY BEFORE DEVELOPMENT | UI Toolkit | `flutter --version` |
| **Dart** | VERIFY BEFORE DEVELOPMENT | Programming Language | `dart --version` |
| **Android Studio** | VERIFY BEFORE DEVELOPMENT | IDE & Android Toolchain | *(Check visually)* |
| **Android SDK** | VERIFY BEFORE DEVELOPMENT | Android Compilation | `flutter doctor -v` |
| **Java/JDK** | VERIFY BEFORE DEVELOPMENT | Required by Android | `java -version` |
| **Node.js** | v24.20.0 | Runtime for Firebase CLI/Functions | `node -v` |
| **npm** | 11.19.0 | Package Manager | `npm -v` |
| **Firebase CLI** | 15.29.0 | Deploying Rules/Functions | `firebase --version` |
| **FlutterFire CLI**| VERIFY BEFORE DEVELOPMENT | Integrating Firebase into Flutter | `flutterfire --version` |

*Note: Missing tools were marked as requiring manual installation by the developer due to Windows UAC (Administrator) restrictions, GUI wizard setups, or explicit license agreements (like Android SDK).*
