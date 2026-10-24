# Archi Draft — Phase D.7.1: Authorized Firebase Staging Test-Account Provisioning Audit Report

**Execution Date:** October 23, 2026  
**Integration Branch:** `COMPLETED-INTERGRATION`  
**Execution Context:** Isolated Worktree (`scratch/completed-integration`)  
**Main Workspace Status:** `feature/admin-panel-complete` (`8ea5d4c5`) is **100% untouched and preserved**  
**Staging Worker URL:** `https://archi-draft-worker-staging.imserratex.workers.dev`  
**Staging D1 Target:** `archi-draft-db-staging` (`065d76ba-eca5-4cc1-ba39-51281b79d6b4`)  
**Production D1 Isolation:** `archi-draft-db` (`af8d3312-5f6e-46ce-bcc1-dfa91e484cc0`) — **Verified 0 rows (Untouched)**  
**Staging Firebase Project:** `archi-draft-staging` (Number: `528293938258`)  
**Status:** **ALL 3 MISSING STAGING TEST IDENTITIES SAFELY & SUCCESSFULLY PROVISIONED VIA SUPPORTED APPLICATION REGISTRATION PATH — FULL PRODUCTION ISOLATION MAINTAINED — ZERO CREDENTIALS EXPOSED**

---

## 1. Executive Summary

In accordance with Phase D.7.1 instructions, an administrative provisioning capability audit was conducted for the Firebase staging environment (`archi-draft-staging`, Project #`528293938258`).

Following explicit owner approval of controlled test email addresses (`zedsuo125+...`), the three missing test identities (**Engineer**, **Draughtsman**, and **Student**) were provisioned strictly in the staging Firebase project and registered in `archi-draft-db-staging` using the genuine, supported backend registration pathway (`POST /api/users`) with Google-signed ID tokens.

### Summary of Platform Test Accounts (Staging Only)

| Role | Firebase UID | Controlled Test Email | Project Association | D1 Role | D1 Status | Registration Path |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Studio Admin** | `QBhduHDU1mYUxvtQ89adVnwQYCg1` | `zedsuo125@gmail.com` | `archi-draft-staging` | `STUDIO_ADMIN` | `ACTIVE` | Phase D.6.2 (Direct D1 privileged grant) |
| **Engineer** | `KXAR90JgoVYLuOKzkbxpKTC8ATa2` | `zedsuo125+engineer@gmail.com` | `archi-draft-staging` | `ENGINEER` | `ACTIVE` | Supported `POST /api/users` with Firebase JWT |
| **Draughtsman** | `TJjtkBm3lgRlpKtcI5u3jpYPH9s1` | `zedsuo125+draughtsman@gmail.com` | `archi-draft-staging` | `DRAUGHTSMAN` | `ACTIVE` | Supported `POST /api/users` with Firebase JWT |
| **Student** | `2iypyxUntQX6djOzwjgPo5xWrGD2` | `zedsuo125+student@gmail.com` | `archi-draft-staging` | `STUDENT` | `ACTIVE` | Supported `POST /api/users` with Firebase JWT |

---

## 2. Step 1: Provisioning Capability Audit

### 2.1 Tooling & Permission Analysis
- **Firebase CLI Session:** The local CLI session in `~/.config/configstore/firebase-tools.json` holds OAuth credentials for `zedsuo125@gmail.com` with scopes `openid`, `https://www.googleapis.com/auth/cloud-platform`, `https://www.googleapis.com/auth/firebase`.
- **Google Identity Toolkit Admin API:** Identity Toolkit administrative endpoints (`https://identitytoolkit.googleapis.com/v1/projects/archi-draft-staging/accounts:...`) are authorized and responsive.
- **Client Auth Endpoint:** Standard client auth API (`https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=...`) is active on `archi-draft-staging` using the staging Web API key.
- **Supported Application Registration Path:** Inspecting `worker/src/index.ts` lines 220–254 confirmed that:
  - `POST /api/users` requires a valid Firebase Bearer token validated via Google JWKS (`https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com`).
  - Roles `CLIENT`, `ENGINEER`, `DRAUGHTSMAN`, and `STUDENT` are authorized for self-service onboarding.
  - Privileged roles (`ADMIN`, `STUDIO_ADMIN`) are strictly forbidden from self-service registration (enforcing HTTP 403 at line 228).
  - Therefore, non-admin accounts do not require manual SQL inserts or privileged bypasses.

---

## 3. Step 2: Read-Only Identity Audit (Pre-Provisioning State)

Prior to creating any identities, read-only queries were executed:
1. **Firebase Authentication (`archi-draft-staging`):**
   - Query: `projects/archi-draft-staging/accounts:batchGet`
   - Pre-existing users: Exactly 1 account (`QBhduHDU1mYUxvtQ89adVnwQYCg1`, `zedsuo125@gmail.com`).
   - Missing roles: Zero accounts existed for Engineer, Draughtsman, or Student.
2. **Staging D1 Database (`archi-draft-db-staging`):**
   - Query: `SELECT id, email, role, status FROM users;`
   - Pre-existing rows: Exactly 1 row (`QBhduHDU1mYUxvtQ89adVnwQYCg1`, `STUDIO_ADMIN`, `ACTIVE`).
3. **Production D1 Database (`archi-draft-db`):**
   - Query: `SELECT count(*) as count FROM users;`
   - Result: `0` rows.
4. **Conclusion:** Zero duplicate accounts existed. Staging was clean; production was completely unpopulated.

---

## 4. Step 3: Owner Approval & Controlled Addresses

To comply with the rule against inventing arbitrary personal identities or using unverified email addresses, the project owner was consulted and confirmed the following plus-aliased addresses:
- **Engineer:** `zedsuo125+engineer@gmail.com`
- **Draughtsman:** `zedsuo125+draughtsman@gmail.com`
- **Student:** `zedsuo125+student@gmail.com`

---

## 5. Step 4: Execution via Supported Application Registration Path

For each target account:
1. **Firebase Identity Creation:**
   - Account provisioned in `archi-draft-staging` with a cryptographically strong random password generated in-memory.
   - No passwords or ID tokens were logged, printed, or persisted to disk.
   - Account association with project #`528293938258` verified.
2. **Live Backend Registration (`POST /api/users`):**
   - Acquired valid Google-issued Firebase ID token for the newly created user.
   - Sent `POST https://archi-draft-worker-staging.imserratex.workers.dev/api/users` with payload:
     - Engineer: `{ name: "Staging Engineer", email: "zedsuo125+engineer@gmail.com", role: "ENGINEER" }`
     - Draughtsman: `{ name: "Staging Draughtsman", email: "zedsuo125+draughtsman@gmail.com", role: "DRAUGHTSMAN" }`
     - Student: `{ name: "Staging Student", email: "zedsuo125+student@gmail.com", role: "STUDENT" }`
   - Staging Worker validated each token against Google public certs and inserted canonical user records into `archi-draft-db-staging`.
   - Each registration request succeeded with **HTTP 200 OK**.

---

## 6. Step 5: Multi-Point Validation & Verification Evidence

### 6.1 Live Firebase Authentication Verification
A read-only lookup via Google Identity Toolkit API confirmed all accounts in `archi-draft-staging`:
```
UID: QBhduHDU1mYUxvtQ89adVnwQYCg1 | Email: zedsuo125@gmail.com             | Disabled: false | EmailVerified: false
UID: KXAR90JgoVYLuOKzkbxpKTC8ATa2 | Email: zedsuo125+engineer@gmail.com    | Disabled: false | EmailVerified: false
UID: TJjtkBm3lgRlpKtcI5u3jpYPH9s1 | Email: zedsuo125+draughtsman@gmail.com | Disabled: false | EmailVerified: false
UID: 2iypyxUntQX6djOzwjgPo5xWrGD2 | Email: zedsuo125+student@gmail.com     | Disabled: false | EmailVerified: false
```

### 6.2 Live Staging D1 Row Verification (`archi-draft-db-staging`)
Executing `SELECT id, email, name, role, status, created_at FROM users;` against remote database `065d76ba-eca5-4cc1-ba39-51281b79d6b4`:
```json
[
  {
    "id": "QBhduHDU1mYUxvtQ89adVnwQYCg1",
    "email": "zedsuo125@gmail.com",
    "name": "Studio Administrator",
    "role": "STUDIO_ADMIN",
    "status": "ACTIVE",
    "created_at": "2026-10-23 10:08:47"
  },
  {
    "id": "KXAR90JgoVYLuOKzkbxpKTC8ATa2",
    "email": "zedsuo125+engineer@gmail.com",
    "name": "Staging Engineer",
    "role": "ENGINEER",
    "status": "ACTIVE",
    "created_at": "2026-10-23 11:35:49"
  },
  {
    "id": "TJjtkBm3lgRlpKtcI5u3jpYPH9s1",
    "email": "zedsuo125+draughtsman@gmail.com",
    "name": "Staging Draughtsman",
    "role": "DRAUGHTSMAN",
    "status": "ACTIVE",
    "created_at": "2026-10-23 11:35:51"
  },
  {
    "id": "2iypyxUntQX6djOzwjgPo5xWrGD2",
    "email": "zedsuo125+student@gmail.com",
    "name": "Staging Student",
    "role": "STUDENT",
    "status": "ACTIVE",
    "created_at": "2026-10-23 11:35:52"
  }
]
```

### 6.3 Production Isolation Proof
Executing `SELECT count(*) as count FROM users;` against production database `archi-draft-db` (`af8d3312-5f6e-46ce-bcc1-dfa91e484cc0`):
```json
[
  {
    "count": 0
  }
]
```
**Conclusion:** Production database remains completely isolated and pristine with zero rows.

---

## 7. Categorized Execution Accounting

### 7.1 Actions Actually Completed
1. Provisioned 3 test accounts (`zedsuo125+engineer@gmail.com`, `zedsuo125+draughtsman@gmail.com`, `zedsuo125+student@gmail.com`) in `archi-draft-staging` Firebase project.
2. Verified genuine Google ID tokens issued for each account.
3. Registered all 3 accounts through the live staging Worker endpoint `POST /api/users` with zero manual SQL insertions.
4. Verified that canonical D1 rows match the required roles (`ENGINEER`, `DRAUGHTSMAN`, `STUDENT`) with status `ACTIVE`.
5. Confirmed that Studio Admin login on `http://localhost:3000` remains active and unaffected.

### 7.2 Read-Only Checks Performed
1. Queried Google Identity Toolkit accounts list and lookup endpoints.
2. Queried remote staging D1 database `archi-draft-db-staging`.
3. Queried remote production D1 database `archi-draft-db`.
4. Inspected Worker source code to confirm role synonymity (`['ENGINEER', 'CLIENT']`) across assignment, review, drawing submission, and activity logging routes.

### 7.3 Blockers & Owner Decisions Still Required
1. **Legal Gate (`assertTermsAccepted`):**
   - Non-admin client/engineer operations (`POST /api/projects`, `POST /api/projects/:id/submit`, etc.) are protected by `assertTermsAccepted`.
   - Currently, `GET /api/legal/documents/TERMS_AND_CONDITIONS/current` returns HTTP 404 (`NO_EFFECTIVE_VERSION`).
   - The legal gate remains strictly fail-closed.
   - To unblock the live 4-portal workflow test, the owner must approve the legal terms and provide the 6 business parameters:
     1. Registered Business / Sole Proprietor Name
     2. Official Business / Studio Physical Address
     3. Official Contact Email
     4. Official Contact Phone Number
     5. Governing State & Country Jurisdiction
     6. Maximum Correction Rounds Allowed
2. **Financial Operations Frozen:**
   - Financial operations remain strictly frozen (`501 FEATURE_FROZEN`). No payments will be triggered during E2E testing.
