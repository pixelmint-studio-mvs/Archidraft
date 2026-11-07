# ARCHI DRAFT — Privacy Request and Legal Compliance API Reference

**Operating Brand:** DRAUGHTSMAN STUDIO  
**Legal Proprietor:** MOHAMMED MOSIN S  
**Product:** ARCHI DRAFT  
**Engineering Phase:** Phase 2 (D1 Legal Database Foundation, Account Deletion & User Data Rights)  
**Document Reference:** `docs/08_legal_privacy/PRIVACY_REQUEST_API_REFERENCE.md`  
**Base URL:** `https://api.archidraft.com` (Production) / `http://localhost:8787` (Local Staging)

---

## 1. Authentication & Common Headers

All endpoints except `GET /api/legal/business-profile` require an authenticated Firebase ID token passed in the `Authorization` header:

```http
Authorization: Bearer <firebase_id_token>
Content-Type: application/json
```

Admin endpoints require the authenticated user's database role to be `ADMIN`.

---

## 2. Public & Business Profile Endpoints

### 2.1 Get Canonical Business Profile
Retrieves the authoritative legal business identity, proprietor details, and verification status.

- **URL:** `GET /api/legal/business-profile`
- **Auth:** Optional / Public
- **Response:** `200 OK`
```json
{
  "success": true,
  "business_profile": {
    "business_structure": "Sole Proprietorship",
    "legal_proprietor": "MOHAMMED MOSIN S",
    "operating_brand": "DRAUGHTSMAN STUDIO",
    "product_name": "ARCHI DRAFT",
    "application_website": "https://archidraft.draughtsmanstudio.com",
    "business_website": "https://draughtsmanstudio.com",
    "support_email": "support@draughtsmanstudio.com",
    "privacy_email": "privacy@draughtsmanstudio.com",
    "grievance_email": "grievance@draughtsmanstudio.com",
    "address_status": "PENDING_VERIFICATION",
    "grievance_officer_status": "PENDING_VERIFICATION",
    "provisional_notice": "DRAUGHTSMAN STUDIO is a provisional sole proprietorship operated by MOHAMMED MOSIN S."
  }
}
```

---

## 3. Account Deletion & Erasure Endpoints

### 3.1 Request Account Deletion
Initiates a statutory account deletion and right-to-erasure request with a 30-day grace period.

- **URL:** `POST /api/legal/account-deletion-requests`
- **Auth:** Required (User)
- **Request Body:**
```json
{
  "reason": "Personal decision to close architectural practice",
  "feedback": "Great service, no complaints"
}
```
- **Response:** `201 Created`
```json
{
  "success": true,
  "message": "Account deletion request submitted. You have a 30-day grace period to cancel.",
  "request": {
    "id": "del_1731000000_abc123",
    "status": "SUBMITTED",
    "grace_period_expires_at": "2026-12-07T10:00:00.000Z"
  }
}
```
- **Errors:**
  - `409 Conflict`: User already has an active deletion request in progress.

### 3.2 Get Current User Deletion Requests
Returns all historical and pending deletion requests for the authenticated user.

- **URL:** `GET /api/legal/account-deletion-requests/me`
- **Auth:** Required (User)
- **Response:** `200 OK`
```json
{
  "success": true,
  "requests": [
    {
      "id": "del_1731000000_abc123",
      "status": "SUBMITTED",
      "reason": "Personal decision to close architectural practice",
      "grace_period_expires_at": "2026-12-07T10:00:00.000Z",
      "created_at": "2026-11-07T10:00:00.000Z"
    }
  ]
}
```

### 3.3 Cancel Pending Deletion Request
Cancels an active deletion request before processing, restoring full active status.

- **URL:** `POST /api/legal/account-deletion-requests/:id/cancel`
- **Auth:** Required (User)
- **Response:** `200 OK`
```json
{
  "success": true,
  "message": "Account deletion request successfully cancelled."
}
```
- **Errors:**
  - `400 Bad Request`: Cannot cancel a request that has already been `COMPLETED`.

---

## 4. Personal Data Export Endpoints

### 4.1 Request Personal Data Export
Submits a request to compile and package all user personal data into a machine-readable export archive.

- **URL:** `POST /api/legal/data-export-requests`
- **Auth:** Required (User)
- **Request Body:**
```json
{
  "format": "JSON",
  "export_scope": "FULL_PROFILE"
}
```
- **Response:** `201 Created`
```json
{
  "success": true,
  "message": "Data export request queued. Archive will be generated shortly.",
  "request": {
    "id": "exp_1731000000_def456",
    "status": "SUBMITTED",
    "format": "JSON",
    "export_scope": "FULL_PROFILE"
  }
}
```
- **Errors:**
  - `409 Conflict`: An active export request is already in progress.

### 4.2 Get User Data Export Requests
- **URL:** `GET /api/legal/data-export-requests/me`
- **Auth:** Required (User)
- **Response:** `200 OK`
```json
{
  "success": true,
  "requests": [
    {
      "id": "exp_1731000000_def456",
      "request_status": "COMPLETED",
      "format": "JSON",
      "download_url": "https://api.archidraft.com/api/legal/exports/download/xyz...",
      "download_expires_at": "2026-11-14T10:00:00.000Z"
    }
  ]
}
```

---

## 5. Personal Data Correction Endpoints

### 5.1 Submit Profile Correction Request
Submits a formal request to correct sensitive profile fields (name, mobile, address, qualification).

- **URL:** `POST /api/legal/data-correction-requests`
- **Auth:** Required (User)
- **Request Body:**
```json
{
  "field_name": "name",
  "requested_value": "MOHAMMED MOSIN S",
  "correction_reason": "Typographical error in legal registration surname"
}
```
- **Response:** `201 Created`
```json
{
  "success": true,
  "message": "Correction request submitted for administrative verification.",
  "request": {
    "id": "cor_1731000000_ghi789",
    "field_name": "name",
    "current_value": "Mohammed Mosin",
    "requested_value": "MOHAMMED MOSIN S",
    "status": "PENDING"
  }
}
```
- **Errors:**
  - `400 Bad Request`: Invalid field name or empty correction reason.

### 5.2 Get User Correction Requests
- **URL:** `GET /api/legal/data-correction-requests/me`
- **Auth:** Required (User)
- **Response:** `200 OK`

---

## 6. Consent Management Endpoints

### 6.1 Withdraw Consent
Allows a user to withdraw consent from specific optional data processing activities without deleting their account.

- **URL:** `POST /api/legal/consents/withdraw`
- **Auth:** Required (User)
- **Request Body:**
```json
{
  "document_key": "ai_usage_disclaimer",
  "reason": "Prefer not to use generative AI features"
}
```
- **Response:** `200 OK`
```json
{
  "success": true,
  "message": "Consent successfully withdrawn for document: ai_usage_disclaimer",
  "document_key": "ai_usage_disclaimer",
  "consent_status": "WITHDRAWN"
}
```

---

## 7. Guardian Consent Endpoints (Under-18 Students)

### 7.1 Submit Guardian Consent
Submits verifiable parental or legal guardian consent for students under the age of 18 pursuant to Section 9 of the DPDPA.

- **URL:** `POST /api/legal/guardian-consents`
- **Auth:** Required (Student User)
- **Request Body:**
```json
{
  "parent_name": "Parent Full Legal Name",
  "parent_email": "guardian@example.com",
  "parent_phone": "+919876543210",
  "relationship": "Father",
  "verification_method": "EMAIL_DECLARATION"
}
```
- **Response:** `201 Created`
```json
{
  "success": true,
  "message": "Guardian consent recorded. Verification pending.",
  "consent": {
    "id": "grd_1731000000_jkl012",
    "verification_status": "PENDING_VERIFICATION"
  }
}
```

### 7.2 Get User Guardian Consents
- **URL:** `GET /api/legal/guardian-consents/me`
- **Auth:** Required (User)
- **Response:** `200 OK`

---

## 8. Cancellation and Refund Endpoints

### 8.1 Submit Cancellation & Refund Request
Submits a formal request to cancel a project milestone and claim an authorized refund.

- **URL:** `POST /api/legal/cancellation-refund-requests`
- **Auth:** Required (Client User)
- **Request Body:**
```json
{
  "project_id": "proj_12345",
  "milestone_id": "ms_drafting_01",
  "requested_amount": 15000.00,
  "cancellation_reason": "Project delayed past agreed delivery milestone window"
}
```
- **Response:** `201 Created`
```json
{
  "success": true,
  "message": "Cancellation and refund request submitted.",
  "request": {
    "id": "ref_1731000000_mno345",
    "status": "SUBMITTED",
    "requested_amount": 15000.00
  }
}
```

### 8.2 Get User Refund Requests
- **URL:** `GET /api/legal/cancellation-refund-requests/me`
- **Auth:** Required (User)
- **Response:** `200 OK`

---

## 9. Administrative Review & Compliance Endpoints

### 9.1 Review Account Deletion Request
Allows compliance administrators to review, approve, or execute account deletion requests with automatic profile tombstoning and AI message purging.

- **URL:** `POST /api/admin/legal/account-deletion-requests/:id/review`
- **Auth:** Required (`ADMIN` role)
- **Request Body:**
```json
{
  "action": "APPROVE",
  "admin_notes": "All pending project liabilities settled. Proceeding with tombstoning."
}
```
- **Supported Actions:** `APPROVE`, `REJECT`, `EXECUTE_TOMBSTONE`
- **Response:** `200 OK`

### 9.2 Review Profile Correction Request
Approving automatically updates the corresponding column in the `users` table.

- **URL:** `POST /api/admin/legal/data-correction-requests/:id/review`
- **Auth:** Required (`ADMIN` role)
- **Request Body:**
```json
{
  "action": "APPROVE",
  "review_notes": "Verified government ID proof matches requested legal name."
}
```
- **Supported Actions:** `APPROVE`, `REJECT`
- **Response:** `200 OK`

### 9.3 Verify Guardian Consent
- **URL:** `POST /api/admin/legal/guardian-consents/:id/verify`
- **Auth:** Required (`ADMIN` role)
- **Request Body:**
```json
{
  "status": "VERIFIED",
  "admin_notes": "Signed parental declaration received via email."
}
```
- **Response:** `200 OK`

### 9.4 Review Cancellation & Refund Request
- **URL:** `POST /api/admin/legal/cancellation-refund-requests/:id/review`
- **Auth:** Required (`ADMIN` role)
- **Request Body:**
```json
{
  "status": "APPROVED",
  "approved_amount": 12000.00,
  "review_notes": "Milestone partially complete; deducting 20% CAD drafting time."
}
```
- **Response:** `200 OK`

### 9.5 Get / Update Data Retention Policies
- **URL:** `GET /api/admin/legal/data-retention-policies`
- **URL:** `POST /api/admin/legal/data-retention-policies`
- **Auth:** Required (`ADMIN` role)
- **Request Body (POST):**
```json
{
  "category": "AI_CHAT_TRANSCRIPTS",
  "retention_days": 60,
  "description": "Retain AI chat transcripts for 60 days before purge",
  "statutory_basis": "Operational Policy",
  "auto_purge_enabled": 1
}
```
- **Response:** `200 OK`
