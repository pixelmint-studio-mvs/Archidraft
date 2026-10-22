# ARCHI DRAFT — EXTERNAL ADMIN INTEGRATION CONTRACT: LEGAL & PRIVACY SYSTEM
**Document ID:** AD-ADMIN-CONTRACT-001  
**Version:** 1.0.0-PROVISIONAL  
**Target:** External Administrator Portal / Integration Partner  
**Backend:** Cloudflare Workers (Hono REST API) + Cloudflare D1 (SQLite)  
**Authentication:** Firebase Auth ID Token (Bearer JWT) with `role IN ('ADMIN', 'STUDIO_ADMIN')`

---

## 1. Scope & Security Boundaries

This document defines the server-authoritative API contract for the administrative management of legal policies, version publishing, privacy request redressal, and regulatory consent audit logs.

### Protection Rules
1. **Zero Client Authority:** The external Admin UI does NOT manage database state directly. All database mutations, foreign keys, timestamps, and audit ledgers are enforced server-side.
2. **Role Verification:** All endpoints in this contract strictly require a valid Firebase ID token belonging to an account with `role: 'ADMIN'` or `role: 'STUDIO_ADMIN'`. Non-admin requests receive HTTP `403 Forbidden`.
3. **No Direct Admin UI Changes:** In compliance with project boundaries, this contract documents the interface for external consumption; no code changes were made to the external Admin UI repository.

---

## 2. API Authentication Header

Every request to an `/api/admin/legal/*` endpoint must include:
```http
Authorization: Bearer <FIREBASE_ID_TOKEN>
Content-Type: application/json
```

---

## 3. Legal Document Lifecycle Management

The system enforces the reviewed lifecycle:
$$\text{DRAFT} \longrightarrow \text{PUBLISHED} \longrightarrow \text{EFFECTIVE} \longrightarrow \text{SUPERSEDED} \longrightarrow \text{ARCHIVED}$$

### 3.1 List All Documents
**Endpoint:** `GET /api/admin/legal/documents`  
**Purpose:** Retrieves complete inventory of documents across all lifecycle states (including DRAFT).

**Response (200 OK):**
```json
{
  "documents": [
    {
      "id": "doc-terms-v2",
      "document_type": "TERMS_AND_CONDITIONS",
      "version": "2.0.0",
      "title": "Platform Terms of Service v2",
      "status": "EFFECTIVE",
      "is_mandatory": 1,
      "locale": "en-IN",
      "change_summary": "Updated data licensing section",
      "effective_at": "2026-10-22 00:00:00",
      "published_at": "2026-10-22 01:15:00",
      "published_by": "usr-admin-01",
      "created_at": "2026-10-22 00:30:00",
      "updated_at": "2026-10-22 01:15:00"
    },
    {
      "id": "doc-terms-v1",
      "document_type": "TERMS_AND_CONDITIONS",
      "version": "1.0.0",
      "title": "Platform Terms of Service v1",
      "status": "SUPERSEDED",
      "is_mandatory": 1,
      "locale": "en-IN",
      "change_summary": "Initial baseline",
      "effective_at": "2026-10-20 00:00:00",
      "published_at": "2026-10-20 00:00:00",
      "published_by": "usr-admin-01",
      "created_at": "2026-10-20 00:00:00",
      "updated_at": "2026-10-22 01:15:00"
    }
  ]
}
```

---

### 3.2 Create New Document Draft
**Endpoint:** `POST /api/admin/legal/documents`  
**Purpose:** Prepares a new policy version in `DRAFT` status.

**Request Payload:**
```json
{
  "documentType": "TERMS_AND_CONDITIONS",
  "version": "2.1.0",
  "title": "Platform Terms of Service v2.1",
  "content": "# ARCHI DRAFT Platform Terms of Service\n\nFull markdown text...",
  "isMandatory": true,
  "locale": "en-IN",
  "changeSummary": "Clarified CAD licensing terms",
  "effectiveAt": "2026-11-01 00:00:00"
}
```

**Field Specifications:**
- `documentType` *(string, required)*: `TERMS_AND_CONDITIONS` | `PRIVACY_POLICY` | `STUDENT_ELIGIBILITY` | `ACCEPTABLE_USE`
- `version` *(string, required)*: Semantic version string (e.g., `2.1.0`). Unique per `(documentType, locale)`.
- `title` *(string, required)*: Display title.
- `content` *(string, required)*: Full markdown document body.
- `isMandatory` *(boolean, optional)*: Default `true`. Mandatory documents block portal access until accepted.
- `locale` *(string, optional)*: Default `'en-IN'`.
- `changeSummary` *(string, optional)*: Human-readable changelog.

**Response (201 Created):**
```json
{
  "success": true,
  "documentId": "doc-b1c4e7f2-...",
  "status": "DRAFT"
}
```

**Error Responses:**
- `400 Bad Request`: Missing required fields.
- `409 Conflict`: `{"error": "Document version already exists for this type and locale", "code": "DUPLICATE_VERSION"}`.

---

### 3.3 Atomically Publish Document Version
**Endpoint:** `POST /api/admin/legal/documents/:id/publish`  
**Purpose:** Promotes target document to `EFFECTIVE`. The server executes an atomic D1 transaction:
1. Locates existing `EFFECTIVE` document for target's `(document_type, locale)`.
2. Updates prior version to `SUPERSEDED`.
3. Updates target document to `EFFECTIVE` with server-authoritative `published_at = CURRENT_TIMESTAMP` and `published_by = <adminUid>`.

**Request:** No body required (URL parameter `:id`).

**Response (200 OK):**
```json
{
  "success": true,
  "documentId": "doc-terms-v2",
  "status": "EFFECTIVE"
}
```

**Runtime Impact on Connected Users:**
- Existing users who previously accepted version 1.0.0 will have `termsAccepted: false` and `reacceptanceRequired: true` on their next session evaluation.
- The Flutter application router will intercept their session and present the updated terms for re-acceptance.

---

## 4. Privacy & Grievance Request Administration

### 4.1 List Privacy Requests
**Endpoint:** `GET /api/admin/legal/privacy-requests`  
**Query Parameters:**
- `status` *(optional)*: `PENDING` | `ACKNOWLEDGED` | `RESOLVED` | `REJECTED`

**Response (200 OK):**
```json
{
  "requests": [
    {
      "id": "REQ-20261022-8492",
      "user_id": "usr-engineer-01",
      "user_email": "eng@example.com",
      "user_name": "Engineer One",
      "user_role": "CLIENT",
      "request_type": "DATA_ACCESS",
      "details": "Export of complete drawing logs and messages",
      "status": "PENDING",
      "statutory_basis": "DPDP_SEC_11",
      "statutory_deadline": null,
      "operational_target_date": "2026-11-06 01:22:00",
      "resolution_notes": null,
      "created_at": "2026-10-22 01:22:00",
      "acknowledged_at": null,
      "resolved_at": null
    }
  ]
}
```

---

### 4.2 Acknowledge or Resolve Request
**Endpoint:** `POST /api/admin/legal/privacy-requests/:id/resolve`  
**Purpose:** Updates the workflow state of a user's privacy or grievance request.

**Request Payload:**
```json
{
  "status": "RESOLVED",
  "resolutionNotes": "Personal data package compiled and delivered via secure encrypted archive."
}
```

**Allowed Status Values:**
- `ACKNOWLEDGED`: Marks receipt and updates `acknowledged_at`.
- `RESOLVED`: Finalizes request and sets `resolved_at = CURRENT_TIMESTAMP`, `resolved_by = <adminUid>`.
- `REJECTED`: Declines request with statutory justification documented in `resolutionNotes`.

**Response (200 OK):**
```json
{
  "success": true,
  "requestId": "REQ-20261022-8492",
  "status": "RESOLVED"
}
```

---

## 5. Regulatory Consent Event Audit Ledger

**Endpoint:** `GET /api/admin/legal/consents`  
**Query Parameters:**
- `limit` *(optional, default 50, max 100)*
- `offset` *(optional, default 0)*

**Response (200 OK):**
```json
{
  "events": [
    {
      "id": "evt-77a8b9c1-...",
      "user_id": "usr-engineer-01",
      "document_id": "doc-terms-v2",
      "document_type": "TERMS_AND_CONDITIONS",
      "document_version": "2.0.0",
      "action_type": "TERMS_ACCEPTED",
      "consent_purpose": "PLATFORM_TERMS",
      "idempotency_key": "terms_usr-engineer-01_doc-terms-v2_2.0.0",
      "ip_hash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
      "user_agent": "Mozilla/5.0 ...",
      "source": "FLUTTER_APP",
      "recorded_at": "2026-10-22 01:25:34"
    }
  ],
  "count": 1
}
```

---

## 6. Action Items for Admin Portal Developer

1. **Add Legal Document Screen:**
   - Render table of documents from `GET /api/admin/legal/documents`.
   - Provide "New Draft" modal posting to `POST /api/admin/legal/documents`.
   - Provide "Publish Version" button calling `POST /api/admin/legal/documents/:id/publish`.
2. **Add Privacy Request Redressal Screen:**
   - Render requests from `GET /api/admin/legal/privacy-requests`.
   - Highlight pending requests approaching `operational_target_date`.
   - Provide action modal to acknowledge or resolve requests calling `POST /api/admin/legal/privacy-requests/:id/resolve`.
3. **Add Consent Audit Log Viewer:**
   - Paginated table consuming `GET /api/admin/legal/consents` for compliance evidence exports.
