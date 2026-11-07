# ARCHI DRAFT — PHASE 5.1 UNIFIED DATA RETENTION SCHEDULE
## Comprehensive 16-Category Data Retention Matrix & Legal Justification Register

- **Project:** ARCHI DRAFT
- **Operating Brand:** DRAUGHTSMAN STUDIO
- **Legal Proprietor:** MOHAMMED MOSIN S
- **Audited Systems:** Cloudflare D1 / Cloudflare R2 / Firebase Auth
- **Statutory Framework:** Income Tax Act 1961, CERT-In Directions 2022, DPDP Act 2023, Indian Copyright Act 1957, Indian Contract Act 1872

---

## 1. Executive Summary

This Unified Data Retention Schedule defines the statutory, contractual, and operational retention lifecycles for all sixteen data categories processed within ARCHI DRAFT. In strict adherence to the data minimization principle under Section 8(7) of the DPDP Act 2023, personal data must be erased as soon as the purpose for which it was processed is no longer being served or retention is no longer necessary for legal or business purposes.

This schedule documents the exact retention period, statutory basis, storage tier, and end-of-life disposal action for each category.

---

## 2. Comprehensive 16-Category Data Retention Matrix

| # | Data Category | Processing Purpose | Active Lifecycle | Mandatory Retention Period | Statutory / Contractual Authority | End-of-Life Disposal Action |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | **User Identity & Profile** (`name`, `email`, `role`, `mobile`) | Account authentication, role routing, and communication. | Duration of active account. | Up to account deletion or 3 years of dormancy. | DPDP Act 2023 Sec 8(7) | **ANONYMIZE:** Tombstoned to `'Deleted User'`; PII erased. |
| **2** | **Registration Proofs** (Degrees, Student IDs) | Professional qualification and student status verification. | Verification review cycle (1–7 days). | Retained while account active; archived upon approval. | IT Act 2000 Sec 79 Due Diligence | **DELETE:** Purged from R2 storage upon verified account deletion. |
| **3** | **Authentication Credentials** (JWTs, session tokens) | Session security and access control. | 1 hour (JWT) to 30 days (refresh token). | Revoked immediately upon logout or deletion. | IT SPDI Rules 2011 Rule 3 | **DELETE:** Cryptographically invalidated and purged. |
| **4** | **Consent Audit Ledger** (`legal_consents`) | Legal proof of terms acceptance and compliance. | Duration of account. | **Permanent** in legal audit archive. | DPDP Act 2023 Sec 6(10) (Burden of proof) | **PRESERVE:** Retained as immutable legal evidence. |
| **5** | **Consent Withdrawals** (`consent_withdrawal_log`) | Record of opt-out actions. | Duration of account. | **Permanent** in legal audit archive. | DPDP Act 2023 Sec 6(4) | **PRESERVE:** Retained as immutable legal evidence. |
| **6** | **Privacy & Deletion Requests** | Auditable tracking of data subject rights exercises. | Processing window (1–30 days). | **7 years** from resolution date. | IT SPDI Rules 2011 Rule 5(9) | **ANONYMIZE:** User identity tombstoned; request log preserved. |
| **7** | **Client Briefs & Scope Specs** | Contractual instructions for drafting assignments. | Project execution duration. | **3 years** post project completion. | Indian Contract Act 1872 Sec 37 | **PRESERVE:** Retained for dispute defense under Limitation Act 1963. |
| **8** | **Reference Attachments** (DWG, DXF, PDF uploads) | Drafting references provided by Engineer/Client. | Project execution duration. | **3 years** post project completion. | Indian Contract Act 1872 Sec 37 | **DELETE:** Erased from R2 storage unless part of deliverable package. |
| **9** | **Workspace Drafts** (Interim Draughtsman files) | Drafting iterations and internal work-in-progress. | Active assignment cycle. | **30 days** post project completion. | Operational necessity | **DELETE:** Automatically cleaned by storage optimization worker. |
| **10**| **Final CAD Deliverables** (`drawing_versions`) | Completed architectural drawings, plans, elevations. | Lifetime of platform. | **Permanent** (or minimum 12 years). | Indian Copyright Act 1957 Sec 57; Professional Structural Liability | **PRESERVE:** Permanently retained for client ownership and architect liability. |
| **11**| **Quality Control Reviews** (`drawing_version_reviews`) | Admin and QC approvals, rejections, correction notes. | Project execution duration. | **Permanent** with project records. | Quality assurance & structural indemnity | **PRESERVE:** Retained alongside drawing versions. |
| **12**| **Collaboration Messages** (`project_messages`) | Project-related communication between participants. | Active project cycle. | **3 years** post project completion. | Limitation Act 1963 (Contractual claims) | **ANONYMIZE:** Author name converted to `'Former Member'`; text retained. |
| **13**| **Invoices & Payments** | Financial accounting and tax records. | Active fiscal year. | **8 years** from end of relevant financial year. | Income Tax Act 1961 Sec 44AA; CGST Act 2017 Sec 36 | **RETAIN:** Strictly preserved in accounting archive. |
| **14**| **Vocational Training Progress** | Curriculum completions, quiz scores, lessons. | Enrollment duration. | **5 years** post course completion. | Academic accreditation standards | **ANONYMIZE:** Tombstoned user ID; module metrics preserved. |
| **15**| **Issued Credentials** (Certificates, Badges) | Formal vocational drafting certifications. | Indefinite. | **Permanent** public verification. | IT Act 2000 Sec 4 (Legal recognition of electronic records) | **PRESERVE:** Certificate ID, verification hash, and date preserved. |
| **16**| **ICT Security Activity Logs** (`activity_logs`) | System access, administrative audits, security telemetry. | Rolling 180 days. | **180 days mandatory** within Indian jurisdiction. | CERT-In Direction No. 20(3)/2022 Direction 6 | **DELETE:** Automated rolling daily purge of logs older than 180 days. |

---

## 3. Storage Hierarchy & Cryptographic Disposal

1. **Hot Tier (Cloudflare D1 SQLite):** Operational tables for real-time application workflows. Data marked for deletion is purged immediately via SQL transactions.
2. **Warm Tier (Cloudflare R2 Object Storage):** CAD drawings and PDF certificates. Deletion applies R2 API object eradication (`deleteObject`).
3. **Cold Tier (Encrypted Automated Backups):** Immutable daily snapshots. Expire on a strict rolling 30-day lifecycle. Post-restore suppression lists prevent resurrection of deleted users.

---

## 4. Verification Conclusion

The 16-category retention schedule resolves all competing statutory obligations, balancing user erasure rights under the DPDP Act against mandatory tax, cybersecurity, and contract preservation duties under Indian law.

