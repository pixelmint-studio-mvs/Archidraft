# ARCHITECTURE CONSISTENCY AUDIT

This audit records the resolution of architectural contradictions and feature scopes across the ARCHI DRAFT codebase.

---

## Issue 1: Role Naming (CLIENT vs ENGINEER)
- **Previous State:** Legacy documentation referred to the user as "CLIENT".
- **Resolution:** The product role is officially **ENGINEER**. The Flutter UI, domain models, navigation, and user-facing text represent the user exclusively as Engineer. Internal database columns (`client_id`) and enum values (`UNDER_CLIENT_REVIEW`) are preserved strictly for backend schema compatibility.
- **Status:** ✅ RESOLVED & CONSISTENT.

---

## Issue 2: Edge Architecture Pivot
- **Previous State:** Early documentation assumed Firebase Firestore, Firebase Storage, and Cloud Functions.
- **Resolution:** The architecture is standardized on **Cloudflare Workers (Hono)**, **Cloudflare D1 (SQL)**, and **Cloudflare R2 (Object Storage)**, retaining Firebase solely for authentication. All documentation has been aligned.
- **Status:** ✅ RESOLVED & CONSISTENT.

---

## Issue 3: Binary File Open Resolution
- **Previous State:** Opening binary files on Web attempted raw byte decoding, corrupting JPEG, PNG, and PDF displays.
- **Resolution:** Implemented authoritative MIME mapping in the Worker and client, supporting `?disposition=inline`, creating typed `html.Blob` instances, generating Object URLs for previewable files, and falling back gracefully to browser download for CAD formats (`.dwg`, `.dxf`, `.zip`).
- **Status:** ✅ RESOLVED & CONSISTENT.

---

## Issue 4: Financials & Payment Out-of-Scope Excision
- **Previous State:** Financial navigation buttons and routes existed in the Engineer Portal.
- **Resolution:** All Engineer-facing Financials, billing, invoicing, payments, checkout, and transaction elements were completely removed. Worker endpoints for financials were locked to `STUDIO_ADMIN` only. Preliminary estimates (`EST. COST: --`, `TIMELINE: --`) remain strictly non-billing metadata.
- **Status:** ✅ RESOLVED & CONSISTENT.

---

## Issue 5: Engineer Activity Feed Scoping
- **Previous State:** Activity queries returned global or internal studio actions.
- **Resolution:** Worker queries for `user.role === 'ENGINEER'` now strictly filter logs to projects owned by the Engineer (`WHERE client_id = ?`) and explicitly exclude internal studio reassignments and financial records.
- **Status:** ✅ RESOLVED & CONSISTENT.

---

## Issue 6: Collaboration Hub Cross-Portal Integration Boundary
- **Previous State:** Collaboration Hub was not yet documented as a shared cross-portal entity.
- **Resolution:** Created D1 migration `0008_project_messages.sql` and implemented `CollaborationHubScreen` with chat persistence and file attachments. Verified locally on `Engineer_Panels`; end-to-end verification across portals is documented as deferred until branch merge.
- **Status:** ✅ RESOLVED & CONSISTENT.
