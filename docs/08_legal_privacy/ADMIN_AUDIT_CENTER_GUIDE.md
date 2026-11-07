# ARCHI DRAFT — Admin Regulatory Consent Audit Center Guide
**Operating Brand:** DRAUGHTSMAN STUDIO  
**Legal Proprietor:** MOHAMMED MOSIN S  
**Product:** ARCHI DRAFT  
**Phase:** 4 of 9 (Next.js Admin Legal Compliance Dashboard & Audit Center)  
**Date:** November 2026  
**Status:** Completed & Tested

---

## 1. Statutory Context & Principles

Under Section 6 of India's **Digital Personal Data Protection Act, 2023 (DPDP Act)**, consent must be:
- **Free, specific, informed, unconditional, and unambiguous.**
- Signified through a clear affirmative action.
- Capable of being withdrawn with ease comparable to granting consent.

Furthermore, under **Direction No. 20(3)/2022-CERT-In**, system logs, access events, and consent transaction records must be maintained within Indian jurisdiction for a rolling minimum of **180 days**.

The **Consent Audit Tab** in the Admin Legal Compliance Dashboard provides an immutable, transparent inspection ledger of all user consent transactions.

---

## 2. Event Ledger Schema (`legal_consent_events`)

Every consent event is stored with comprehensive provenance metadata in Cloudflare D1:

| Column | Description | Example / Domain Values |
| :--- | :--- | :--- |
| `id` | Unique UUID event identifier | `evt-c8b912-4f81-9b12` |
| `user_id` | Authenticated user UID | `bCrLwG8lMRbViDOrBmClwc96xJ42` |
| `document_id` | Foreign key referencing `legal_documents.id` | `doc-terms-v1-0-0` |
| `document_type` | Canonical policy category | `TERMS_AND_CONDITIONS`, `PRIVACY_POLICY` |
| `document_version`| Semantic version accepted | `1.0.0` |
| `action_type` | Specific consent transition | `TERMS_ACCEPTED`, `PRIVACY_ACKNOWLEDGED`, `OPTIONAL_MARKETING_CONSENTED`, `OPTIONAL_TELEMETRY_CONSENTED`, `OPTIONAL_CONSENT_WITHDRAWN` |
| `consent_purpose` | Plain-English purpose disclosure | `Access to Archi Draft technical workflow tools` |
| `ip_hash` | SHA-256 hashed IP address (PII protected) | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4...` |
| `user_agent` | Browser / Mobile client user-agent string | `Mozilla/5.0 (Windows NT 10.0; Win64; x64)...` |
| `source` | Interface channel where consent was collected | `FLUTTER_MOBILE`, `WEB_CLIENT`, `ONBOARDING_MODAL` |
| `recorded_at` | Immutable UTC ISO-8601 timestamp | `2026-11-07 10:15:30` |

---

## 3. Unbundled Consent & Withdrawal Safeguards

### 3.1 Strict Separation of Mandatory vs. Optional Consents
The Consent Audit Center strictly segregates:
- **Mandatory Service Consents:** `TERMS_ACCEPTED` and `PRIVACY_ACKNOWLEDGED`. Required to provide the contracted CAD collaboration and drafting workflow services.
- **Optional Voluntary Consents:** `OPTIONAL_MARKETING_CONSENTED` and `OPTIONAL_TELEMETRY_CONSENTED`. Users can opt out or withdraw at any time without forfeiting access to primary drafting services.

### 3.2 Withdrawal Logging
When a user toggles off an optional preference in the Flutter Legal Center:
1. An explicit event with `action_type = 'OPTIONAL_CONSENT_WITHDRAWN'` is atomically appended to `legal_consent_events`.
2. Historical acceptance records are **never** silently deleted; they are preserved as immutable historical proof that consent was granted during the preceding period and subsequently withdrawn.

---

## 4. Administrative Inspection & Regulatory Inquiries

During an audit by regulatory authorities (such as the Data Protection Board of India or CERT-In):
1. Navigate to `/legal?tab=consents`.
2. Filter by user UID or date range.
3. Review the complete chronological history of document versions accepted, IP hashes, and withdrawal events.
4. Verify that no administrative action can silently overwrite or tamper with logged consent events.
