# Archi Draft — Phase D.7.2: Authenticated Staging Portal Smoke Test Report

**Execution Date:** October 23, 2026  
**Integration Branch:** `COMPLETED-INTERGRATION`  
**Execution Context:** Isolated Worktree (`scratch/completed-integration`)  
**Main Workspace Status:** `feature/admin-panel-complete` (`8ea5d4c5`) is **100% untouched and preserved**  
**Staging Worker URL:** `https://archi-draft-worker-staging.imserratex.workers.dev`  
**Staging D1 Target:** `archi-draft-db-staging` (`065d76ba-eca5-4cc1-ba39-51281b79d6b4`)  
**Staging Firebase Project:** `archi-draft-staging` (Number: `528293938258`)  
**Status:** **ALL 20 AUTHENTICATED & SECURITY SMOKE TESTS COMPLETED WITH 100% SUCCESS — AUTHENTICATION, RBAC & TENANT ISOLATION FULLY VERIFIED ON LIVE STAGING WORKER — BUSINESS MUTATIONS SAFELY GATED**

---

## 1. Executive Summary

Phase D.7.2 executed live authenticated API smoke testing across the staging environment using the deployed Cloudflare Worker (`archi-draft-worker-staging.imserratex.workers.dev`), live remote database `archi-draft-db-staging`, and the authenticated Firebase staging project `archi-draft-staging`.

Following explicit owner authorization, unified test credentials were configured for the three non-admin staging accounts (**Engineer**, **Draughtsman**, **Student**) via the authorized Google Identity Toolkit Admin API, while preserving the owner's Studio Admin account completely untouched.

All 20 smoke tests succeeded:
1. **Authentication:** All four roles were verified to authenticate via the supported Firebase Email/Password flow and successfully retrieve their canonical D1 profiles via `GET /api/users/me`.
2. **Role-Based Access Control (RBAC):** Attempts by Engineer, Draughtsman, and Student to access Admin-only endpoints (`GET /api/admin/dashboard`, `GET /api/users`) were strictly rejected with **HTTP 403 Forbidden** (`Forbidden` / `Permission denied`).
3. **Tenant Data Isolation (IDOR Protection):** Attempts by non-admin roles to read other users' private profiles (e.g. Engineer inspecting Admin or Draughtsman) were strictly blocked with **HTTP 403 Forbidden**.
4. **Unauthenticated & Malformed Request Rejection:** Live requests lacking tokens or containing invalid tokens were rejected with **HTTP 401 Unauthorized**.
5. **Fail-Closed Legal Gate:** Confirmed that `GET /api/legal/documents/TERMS_AND_CONDITIONS/current` returns HTTP 404 `NO_EFFECTIVE_VERSION`, keeping non-admin mutations fail-closed.
6. **Zero Secrets Leaked:** No passwords, ID tokens, or private keys were printed or persisted.

---

## 2. Tested Identities & Environments

| Role | Firebase UID | Controlled Test Email | Target Project | D1 Canonical Role | Account Status | Smoke Test Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :---: |
| **Studio Admin** | `QBhduHDU1mYUxvtQ89adVnwQYCg1` | `zedsuo125@gmail.com` | `archi-draft-staging` | `STUDIO_ADMIN` | `ACTIVE` | **PASS (Verified)** |
| **Engineer** | `KXAR90JgoVYLuOKzkbxpKTC8ATa2` | `zedsuo125+engineer@gmail.com` | `archi-draft-staging` | `ENGINEER` | `ACTIVE` | **PASS (Verified)** |
| **Draughtsman** | `TJjtkBm3lgRlpKtcI5u3jpYPH9s1` | `zedsuo125+draughtsman@gmail.com` | `archi-draft-staging` | `DRAUGHTSMAN` | `ACTIVE` | **PASS (Verified)** |
| **Student** | `2iypyxUntQX6djOzwjgPo5xWrGD2` | `zedsuo125+student@gmail.com` | `archi-draft-staging` | `STUDENT` | `ACTIVE` | **PASS (Verified)** |

---

## 3. Detailed Smoke Test Matrix & Observed Evidence

### 3.1 Authentication & Profile Identity Verification (`GET /api/users/me`)

| Test ID | Role | Endpoint | Expected Result | Observed Status & Response Payload | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **SMOKE-AUTH-01** | Engineer | `GET /api/users/me` | HTTP 200; returns Engineer profile | **HTTP 200 OK**<br>`{"id":"KXAR90JgoVYLuOKzkbxpKTC8ATa2","email":"zedsuo125+engineer@gmail.com","name":"Staging Engineer","role":"ENGINEER","status":"ACTIVE"}` | **PASS** |
| **SMOKE-AUTH-02** | Draughtsman | `GET /api/users/me` | HTTP 200; returns Draughtsman profile | **HTTP 200 OK**<br>`{"id":"TJjtkBm3lgRlpKtcI5u3jpYPH9s1","email":"zedsuo125+draughtsman@gmail.com","name":"Staging Draughtsman","role":"DRAUGHTSMAN","status":"ACTIVE"}` | **PASS** |
| **SMOKE-AUTH-03** | Student | `GET /api/users/me` | HTTP 200; returns Student profile | **HTTP 200 OK**<br>`{"id":"2iypyxUntQX6djOzwjgPo5xWrGD2","email":"zedsuo125+student@gmail.com","name":"Staging Student","role":"STUDENT","status":"ACTIVE"}` | **PASS** |
| **SMOKE-AUTH-04** | Studio Admin | `GET /api/users/me` | HTTP 200; returns Studio Admin profile | **HTTP 200 OK**<br>`{"id":"QBhduHDU1mYUxvtQ89adVnwQYCg1","email":"zedsuo125@gmail.com","name":"Studio Administrator","role":"STUDIO_ADMIN","status":"ACTIVE"}` | **PASS** |

### 3.2 Role-Based Access Control Rejection (Admin Endpoints)

| Test ID | Role | Attempted Endpoint | Expected Result | Observed Status & Response Payload | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **SMOKE-RBAC-01** | Engineer | `GET /api/admin/dashboard` | HTTP 403 Forbidden | **HTTP 403 Forbidden**<br>`{"error":"Forbidden"}` | **PASS** |
| **SMOKE-RBAC-02** | Engineer | `GET /api/users` | HTTP 403 Forbidden | **HTTP 403 Forbidden**<br>`{"error":"Permission denied"}` | **PASS** |
| **SMOKE-RBAC-03** | Draughtsman | `GET /api/admin/dashboard` | HTTP 403 Forbidden | **HTTP 403 Forbidden**<br>`{"error":"Forbidden"}` | **PASS** |
| **SMOKE-RBAC-04** | Draughtsman | `GET /api/users` | HTTP 403 Forbidden | **HTTP 403 Forbidden**<br>`{"error":"Permission denied"}` | **PASS** |
| **SMOKE-RBAC-05** | Student | `GET /api/admin/dashboard` | HTTP 403 Forbidden | **HTTP 403 Forbidden**<br>`{"error":"Forbidden"}` | **PASS** |
| **SMOKE-RBAC-06** | Student | `GET /api/users` | HTTP 403 Forbidden | **HTTP 403 Forbidden**<br>`{"error":"Permission denied"}` | **PASS** |

### 3.3 Tenant Isolation & Private Profile Protection (IDOR Prevention)

| Test ID | Requesting Role | Target Profile Requested | Expected Result | Observed Status & Response Payload | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **SMOKE-IDOR-01** | Engineer | `GET /api/users/QBhduHDU1mYUxvtQ89adVnwQYCg1` (Admin) | HTTP 403 Forbidden | **HTTP 403 Forbidden**<br>`{"error":"Permission denied"}` | **PASS** |
| **SMOKE-IDOR-02** | Engineer | `GET /api/users/TJjtkBm3lgRlpKtcI5u3jpYPH9s1` (Draughtsman) | HTTP 403 Forbidden | **HTTP 403 Forbidden**<br>`{"error":"Permission denied"}` | **PASS** |
| **SMOKE-IDOR-03** | Draughtsman | `GET /api/users/QBhduHDU1mYUxvtQ89adVnwQYCg1` (Admin) | HTTP 403 Forbidden | **HTTP 403 Forbidden**<br>`{"error":"Permission denied"}` | **PASS** |
| **SMOKE-IDOR-04** | Draughtsman | `GET /api/users/KXAR90JgoVYLuOKzkbxpKTC8ATa2` (Engineer) | HTTP 403 Forbidden | **HTTP 403 Forbidden**<br>`{"error":"Permission denied"}` | **PASS** |
| **SMOKE-IDOR-05** | Student | `GET /api/users/QBhduHDU1mYUxvtQ89adVnwQYCg1` (Admin) | HTTP 403 Forbidden | **HTTP 403 Forbidden**<br>`{"error":"Permission denied"}` | **PASS** |
| **SMOKE-IDOR-06** | Student | `GET /api/users/KXAR90JgoVYLuOKzkbxpKTC8ATa2` (Engineer) | HTTP 403 Forbidden | **HTTP 403 Forbidden**<br>`{"error":"Permission denied"}` | **PASS** |

### 3.4 Unauthenticated & Malformed Request Security Rejection

| Test ID | Scenario | Tested Endpoint | Expected Result | Observed Status & Response Payload | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **SMOKE-SEC-01** | Unauthenticated | `GET /api/users/me` | HTTP 401 Unauthorized | **HTTP 401 Unauthorized**<br>`{"error":"Unauthorized: Missing or invalid Authorization header"}` | **PASS** |
| **SMOKE-SEC-02** | Unauthenticated | `GET /api/admin/dashboard` | HTTP 401 Unauthorized | **HTTP 401 Unauthorized**<br>`{"error":"Unauthorized: Missing or invalid Authorization header"}` | **PASS** |
| **SMOKE-SEC-03** | Unauthenticated | `GET /api/users` | HTTP 401 Unauthorized | **HTTP 401 Unauthorized**<br>`{"error":"Unauthorized: Missing or invalid Authorization header"}` | **PASS** |
| **SMOKE-SEC-04** | Invalid JWT Token | `GET /api/users/me` (Bearer invalid) | HTTP 401 Unauthorized | **HTTP 401 Unauthorized**<br>`{"error":"Unauthorized: Invalid Firebase token"}` | **PASS** |
| **SMOKE-SEC-05** | Invalid JWT Token | `GET /api/admin/dashboard` (Bearer invalid) | HTTP 401 Unauthorized | **HTTP 401 Unauthorized**<br>`{"error":"Unauthorized: Invalid Firebase token"}` | **PASS** |
| **SMOKE-SEC-06** | Malformed Auth Header | `GET /api/users/me` (`Basic ...`) | HTTP 401 Unauthorized | **HTTP 401 Unauthorized**<br>`{"error":"Unauthorized: Missing or invalid Authorization header"}` | **PASS** |
| **SMOKE-SEC-07** | Fail-Closed Legal Gate | `GET /api/legal/documents/TERMS_AND_CONDITIONS/current` | HTTP 404 (No effective draft) | **HTTP 404 Not Found**<br>`{"error":"No effective document found for type: TERMS_AND_CONDITIONS","code":"NO_EFFECTIVE_VERSION"}` | **PASS** |

---

## 4. Distinction Between API Smoke Tests and Full E2E Tests

In strict adherence to the project's reporting integrity standards:
- **What Was Completed in Phase D.7.2:**
  - Live API smoke tests directly against the staging Cloudflare Worker and Firebase Authentication.
  - Verification that the authentication pipeline, Google JWKS token verification, and D1 database queries work synchronously in production-like conditions.
  - Verification that non-admin tokens cannot escalate privileges or read unauthorized tenant records.
- **What Is Explicitly NOT Claimed as Complete:**
  - **Full multi-actor business lifecycle:** Engineer creating a project, Admin approving/assigning it, Draughtsman submitting drawings, and Engineer approving.
  - **Mobile Client UI Automation:** Running the compiled Flutter application against the staging Worker.
  - **Reason for Boundary:** Non-admin project lifecycle actions require legal terms acceptance (`assertTermsAccepted`), which remains fail-closed until legal drafts are approved and made effective.

---

## 5. Remaining Blockers & Exact Owner Decisions for Next Phase

To advance from API smoke tests to full business lifecycle E2E execution, the following two gates must be resolved:

### 1. Legal Consent Gate Resolution
The Worker enforces `assertTermsAccepted(db, uid, role)` on `POST /api/projects`, `POST /api/projects/:id/submit`, and drawing acceptance.
- **Owner Action Required:** Confirm the 6 business parameters so the legal documents can be populated, approved, and marked `EFFECTIVE`:
  1. **Registered Business Name:** (e.g., *Archi Draft Studio / Inam Ullah Khan Sole Proprietorship*)
  2. **Official Business Address:** (e.g., *Full physical studio address*)
  3. **Official Contact Email:** (e.g., *imserratex@gmail.com*)
  4. **Official Contact Phone:** (e.g., *Studio support telephone number*)
  5. **Governing Jurisdiction:** (e.g., *State / Union Territory, India*)
  6. **Max Free Correction Rounds:** (e.g., *2 rounds before supplementary billing*)

### 2. Full Multi-Actor Workflow Execution (Phase D.8)
Once the legal documents are marked `EFFECTIVE`, the automated E2E test harness will execute the complete 4-portal lifecycle in sequence:
1. Engineer creates and submits project brief.
2. Studio Admin approves and assigns project to Draughtsman.
3. Draughtsman uploads and submits initial drawing version.
4. Engineer reviews and approves drawing / requests correction.
5. All actions verified in D1 activity logs and notification tables.
