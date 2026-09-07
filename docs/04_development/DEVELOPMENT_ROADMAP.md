# DEVELOPMENT ROADMAP

This document outlines the implementation sequence for ARCHI DRAFT. Do not skip phases.

## PHASE 0: Pre-Implementation Verification
- **Goal:** Ensure all documentation and environments are ready.
- **Dependencies:** None.
- **Deliverables:** Architecture docs, environment setup.
- **Completion Criteria:** All tools installed and verified.

## PHASE 1: Project Foundation
- **Goal:** Initialize Flutter app and folder structure.
- **Dependencies:** Phase 0.
- **Deliverables:** Base Flutter project, theme, routing, state management setup.
- **Completion Criteria:** App builds and runs on a simulator/device.

## PHASE 2: Firebase Integration
- **Goal:** Connect app to Firebase.
- **Dependencies:** Phase 1.
- **Deliverables:** Firebase project, `google-services.json`, FlutterFire init.
- **Completion Criteria:** Firebase initializes successfully on app start.

## PHASE 3: Authentication
- **Goal:** Implement secure login/registration.
- **Dependencies:** Phase 2.
- **Deliverables:** UI for Auth, Firebase Auth integration.
- **Completion Criteria:** Users can sign up and log in.

## PHASE 4: User Profiles
- **Goal:** Save user data to Firestore.
- **Dependencies:** Phase 3.
- **Deliverables:** `users/` collection integration, profile screens.
- **Completion Criteria:** Users can edit their details based on role.

## PHASE 5: Firestore Data Models
- **Goal:** Define Dart models for Firestore data.
- **Dependencies:** Phase 4.
- **Deliverables:** Dart classes for Project, Assignment, Version, Correction, Log.
- **Completion Criteria:** Models serialize/deserialize correctly.

## PHASE 6: Security Rules
- **Goal:** Secure the database.
- **Dependencies:** Phase 5.
- **Deliverables:** `firestore.rules` and `storage.rules`.
- **Completion Criteria:** Unit tests pass for authorized and unauthorized access.

## PHASE 7: Client Workflow
- **Goal:** Client UI for creating and managing projects.
- **Dependencies:** Phase 6.
- **Deliverables:** Dashboard, project submission flow.
- **Completion Criteria:** Client can submit a project successfully.

## PHASE 8: Admin Workflow
- **Goal:** Admin UI for reviewing and assigning projects.
- **Dependencies:** Phase 7.
- **Deliverables:** Admin dashboard, assignment UI.
- **Completion Criteria:** Admin can approve and assign a Draughtsman.

## PHASE 9: Draughtsman Workflow
- **Goal:** Draughtsman UI for accepting work and uploading.
- **Dependencies:** Phase 8.
- **Deliverables:** Draughtsman dashboard, assignment acceptance.
- **Completion Criteria:** Draughtsman can accept and start work.

## PHASE 10: File Storage
- **Goal:** Implement secure file uploads/downloads.
- **Dependencies:** Phase 9.
- **Deliverables:** Firebase Storage integration.
- **Completion Criteria:** Files upload correctly based on role folders.

## PHASE 11: Corrections
- **Goal:** Implement the iterative correction loop.
- **Dependencies:** Phase 10.
- **Deliverables:** Client correction request UI, Draughtsman resolution UI.
- **Completion Criteria:** 3-round limit works, statuses update correctly.

## PHASE 12: Cloud Functions
- **Goal:** Move critical actions and activity logs to backend.
- **Dependencies:** Phase 11.
- **Deliverables:** Callable functions for all critical state changes.
- **Completion Criteria:** Client SDK no longer performs direct state mutations for critical paths.

## PHASE 13: Testing & Security Audit
- **Goal:** Ensure system is robust.
- **Dependencies:** Phase 12.
- **Deliverables:** Test reports, final security rule audit.
- **Completion Criteria:** Zero critical vulnerabilities.

## PHASE 14: Production Preparation
- **Goal:** Get ready for launch.
- **Dependencies:** Phase 13.
- **Deliverables:** App store assets, production Firebase config.
- **Completion Criteria:** Successful staging deployment.
