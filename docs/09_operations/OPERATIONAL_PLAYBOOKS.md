# DRAUGHTSMAN STUDIO | ARCHI DRAFT
## COMPREHENSIVE COMPLIANCE & LEGAL OPERATIONAL PLAYBOOKS (17 CANONICAL PROCEDURES)

**Document Reference:** `DOC-OPS-LEGAL-2026-V1`  
**Operating Brand:** DRAUGHTSMAN STUDIO  
**Product:** ARCHI DRAFT  
**Legal Proprietor:** MOHAMMED MOSIN S (Sole Proprietorship)  
**Governance Framework:** DPDP Act 2023, IT Act 2000, IT (SPDI) Rules 2011, CERT-In Direction No. 20(3)/2022, CGST Act 2017 Sec 36, Income Tax Act 1961 Sec 44AA, Architects Act 1972 Sec 37  
**Operational Status:** Canonical Implementation Baseline  
**Assigned Roles Policy:** Roles lacking formal employment appointment or power of attorney are designated `PENDING_ASSIGNMENT` (interim coverage by Studio Administrator / Proprietor).

---

## PLAYBOOK INVENTORY OVERVIEW

| # | Playbook Title | Statutory / Contractual Basis | Primary Responsible Role | Statutory / Operational SLA |
|---|---|---|---|---|
| **01** | Legal Document Version Updates and Publication | DPDP Act Sec 5; IT Act Sec 43A | Legal Counsel (`PENDING_ASSIGNMENT`) / Admin | 5 Business Days Notice |
| **02** | Mandatory Document Modification & User Re-Consent | DPDP Act Sec 6(1); Contract Act Sec 10 | Studio Administrator | Immediate at Next Login |
| **03** | Self-Service Account Deletion Review & Execution | DPDP Act Sec 12(3); IT SPDI Rule 5(7) | Privacy Officer (`PENDING_ASSIGNMENT`) / Admin | 30 Calendar Days |
| **04** | Admin-Initiated Deletion Under Legal Compulsion | DPDP Act Sec 12(4); CrPC Sec 91; IT Act Sec 69 | Grievance Officer (`PENDING_ASSIGNMENT`) | As Ordered (Immediate/24-72h) |
| **05** | Personal Data Access & Export Processing | DPDP Act Sec 11; DPDPA Right to Summary | Studio Administrator | 72 Hours (Token 7-Day TTL) |
| **06** | Personal Data Rectification & Disputed Data Handling | DPDP Act Sec 12(1), 12(2) | Studio Administrator | 15 Calendar Days |
| **07** | Under-18 Student Registration & Guardian Verification | DPDP Act Sec 9; Contract Act Sec 11 | Compliance Officer (`PENDING_ASSIGNMENT`) | 48 Hours |
| **08** | Guardian Consent Withdrawal & Student Transition | DPDP Act Sec 9(1), 6(4) | Studio Administrator | 24 Hours |
| **09** | IP Dispute, CAD Ownership & Notice-and-Takedown | Indian Copyright Act 1957; IT Act Sec 79 | Legal Counsel (`PENDING_ASSIGNMENT`) / Admin | 36 Hours (Safe Harbor) |
| **10** | Architectural & Structural Liability Incident Response | Architects Act 1972 Sec 37; Limitation Act 1963 | Grievance Officer (`PENDING_ASSIGNMENT`) | 24 Hours Immediate Hold |
| **11** | Project Cancellation, Milestone Failure & Refunds | Consumer Protection Act 2019; Contract Act | Accounts Lead (`PENDING_ASSIGNMENT`) / Admin | 7-14 Business Days |
| **12** | Data Breach Notification & CERT-In Reporting | CERT-In Direction No. 20(3)/2022; DPDP Sec 8(6) | Security Incident Officer (`PENDING_ASSIGNMENT`) | **Strict 6-Hour Window** |
| **13** | User Grievance Escalation to Appellate / DPBI | IT SPDI Rule 5(9); DPDP Act Sec 13 | Grievance Officer (`PENDING_ASSIGNMENT`) | 24h Ack / 15-Day Redressal |
| **14** | Automated Data Retention & Deletion Ledger Audit | DPDP Act Sec 8(7); Income Tax Sec 44AA | Systems Lead (`PENDING_ASSIGNMENT`) / Admin | Quarterly Scheduled Audit |
| **15** | Cross-Border Data Transfer Assessment & Restrictions | DPDP Act Sec 16; Central Govt Notifications | Privacy Officer (`PENDING_ASSIGNMENT`) | Prior to Vendor Onboarding |
| **16** | PIXMINT BOT Content Violation & Session Purge | DPDP Act Sec 6; IT Intermediary Rules 2021 | Studio Administrator | 2 Hours (Emergency Purge) |
| **17** | Annual Legal Document Review & Entity Status Audit | Companies Act / Shops & Est. / Sole Prop | Legal Proprietor (MOHAMMED MOSIN S) | Annual (Every October) |

---

### PLAYBOOK 01: Legal Document Version Updates and Publication
- **Objective:** Safely draft, review, validate, and publish version updates to the 7 canonical platform legal documents without breaking live user sessions or database indexes.
- **Role Assignment:** Legal Counsel (`PENDING_ASSIGNMENT`), executed by Studio Administrator.
- **Procedure:**
  1. Prepare revised policy markdown text incorporating legislative updates or business workflow modifications.
  2. Increment semantic version (e.g., `1.0.0` -> `1.1.0` for minor adjustments; `2.0.0` for material terms modification).
  3. Enter Next.js Admin Portal -> Legal Compliance -> **Document Registry** tab (`/legal?tab=documents`).
  4. Click **Draft New Version**, select `documentType`, enter new `version`, `title`, full markdown `content`, and detailed `changeSummary`.
  5. Save as `DRAFT`. Test reader rendering in preview modal.
  6. When approved, click **Publish Version**, choose `EFFECTIVE` status and specify effective timestamp.
  7. D1 partial unique index `idx_single_effective_doc` atomically retires the previous effective version to `SUPERSEDED` and activates the new version.
- **Audit Proof:** Verified in `legal_documents` table (`status = 'EFFECTIVE'`).

---

### PLAYBOOK 02: Mandatory Document Modification & User Re-Consent
- **Objective:** Enforce affirmative re-acceptance across all active platform roles when a mandatory document (e.g., Terms and Conditions or Privacy Policy) undergoes a material revision.
- **Role Assignment:** Studio Administrator.
- **Procedure:**
  1. Once Playbook 01 activates a new mandatory document version, the Worker backend `GET /api/legal/status` evaluates `hasAcceptedCurrentTerms` and `hasAcceptedCurrentPrivacy` against `user_consent_state`.
  2. If the user's accepted version is older than the current `EFFECTIVE` version, the backend marks `requiresAction = true`.
  3. Upon next authenticated API request or application launch, the Flutter client routes the user to `LegalOnboardingScreen`.
  4. The screen forces the user to review the updated policy sections and provide affirmative checkbox consent.
  5. Submission triggers `POST /api/legal/consents`, recording an immutable event into `legal_consent_events` with SHA-256 IP hash and idempotency key.
- **Audit Proof:** Verified via trigger-enforced append-only record in `legal_consent_events`.

---

### PLAYBOOK 03: Self-Service Account Deletion Review & Execution
- **Objective:** Process user-initiated account deletion requests under DPDP Act Sec 12(3) while preserving collaborative architectural records, tax invoices, and statutory security logs.
- **Role Assignment:** Privacy Officer (`PENDING_ASSIGNMENT`) / Studio Administrator.
- **Procedure:**
  1. User submits deletion request via Flutter Legal Center (`/legal/center`). Request enters `account_deletion_requests` with status `SUBMITTED`.
  2. 30-day grace period commences; user retains the right to cancel during this window.
  3. After grace period or upon explicit expedited review, Admin opens Next.js Admin Web -> **Account Erasure** tab (`/legal?tab=deletions`).
  4. Admin verifies identity and absence of active legal holds or incomplete collaborative delivery milestones.
  5. Admin clicks **Execute Deletion**. Backend PATCH triggers:
     - D1 `users`: Anonymizes `name = 'Deleted User'`, `email = deleted_<uid>@archidraft.local`, wipes `mobile`, `address`, `date_of_birth`, `qualification`, `college_name`, `company_name`, `identification_number`, sets `status = 'SUSPENDED'`.
     - D1 `notifications`: Purged for user.
     - D1 `chat_sessions` & `chat_messages`: Hard-deleted across all PIXMINT BOT records.
     - Cloudflare R2: Deletes registration verification proof files via `STORAGE.delete()`.
     - Preserves CAD drawings, drawing reviews, invoices, payments, activity logs, and immutable consent events.
     - Writes full 20-subsystems accounting array into `systems_processed`.
- **Audit Proof:** Immutable record in `account_deletion_requests` with `status = 'COMPLETED'` and 20 subsystems logged.

---

### PLAYBOOK 04: Admin-Initiated Deletion Under Legal Compulsion
- **Objective:** Execute an immediate court-ordered, statutory law enforcement, or regulatory account erasure under IT Act Sec 69 or DPDP Act Sec 12(4).
- **Role Assignment:** Grievance Officer (`PENDING_ASSIGNMENT`) & Studio Administrator.
- **Procedure:**
  1. Receive verified legal notice or court order from an authorized Indian jurisdictional authority.
  2. Verify credentials and official domain of the issuing authority.
  3. Navigate to Admin Legal Center -> **Account Erasure** tab -> Click **New Administrative Erasure**.
  4. Select target `user_id`, set category `LEGAL_COMPULSION`, input court order reference and official dossier ID in `reason`.
  5. Bypass the 30-day cooling-off period by directly executing `UNDER_REVIEW` -> `COMPLETED`.
  6. Backend immediately scrubs PII, revokes Firebase session by marking `SUSPENDED`, and purges personal telemetry.
  7. Maintain encrypted record of the judicial directive in offline legal custody.
- **Audit Proof:** `account_deletion_requests` record with category `LEGAL_COMPULSION` and judicial reference.

---

### PLAYBOOK 05: Personal Data Access & Export Processing
- **Objective:** Provide a structured, machine-readable personal data export archive to an eligible data principal under DPDP Act Sec 11 within 72 hours.
- **Role Assignment:** Studio Administrator.
- **Procedure:**
  1. User submits data export request via Flutter Legal Center or Admin initiates on behalf of user.
  2. Record created in `data_export_requests` with `status = 'PENDING'`.
  3. Worker compiles profile data, verified attributes, consent events history, support tickets, and metadata into JSON archive.
  4. If Cloudflare R2 is configured, archive is written to `exports/<userId>/<exportId>.json` with a 7-day cryptographic download token; otherwise fallback dynamic streaming is used.
  5. Admin or automated worker updates status to `COMPLETED` and sets `download_url_expires_at = NOW() + 7 days`.
  6. User downloads archive in Flutter Legal Center or Admin downloads via Admin Web (`/legal?tab=exports`).
  7. After 7 days, download token strictly returns HTTP `410 EXPORT_TOKEN_EXPIRED`.
- **Audit Proof:** Logged in `data_export_requests` with timestamps and expiration verification.

---

### PLAYBOOK 06: Personal Data Rectification & Disputed Data Handling
- **Objective:** Review, verify, and resolve requests to correct inaccurate or outdated personal data under DPDP Act Sec 12(1).
- **Role Assignment:** Studio Administrator.
- **Procedure:**
  1. User submits request via Flutter Legal Center indicating `field_name` (e.g., Mobile, Address, Qualification, College Name, Company Name), `proposed_value`, and justification.
  2. Request logged in `data_correction_requests` with `status = 'PENDING'`.
  3. Admin opens Next.js Admin Portal -> **Data Corrections** tab (`/legal?tab=corrections`).
  4. Admin verifies documentation provided (e.g., educational proof, updated registration certificate).
  5. Admin clicks **Approve Correction** or **Reject Correction** (with mandatory justification notes).
  6. If approved, backend updates the target column in `users` and marks ticket `RESOLVED`.
  7. Notification sent to user with resolution details.
- **Audit Proof:** Audit record in `data_correction_requests` linking admin ID, decision, and resolution timestamp.

---

### PLAYBOOK 07: Under-18 Student Registration & Guardian Verification
- **Objective:** Fulfill Section 9 of the DPDP Act 2023 for student users under 18 years of age through verifiable parental/guardian consent without making false claims of third-party automated identity bridges.
- **Role Assignment:** Compliance Officer (`PENDING_ASSIGNMENT`) / Studio Administrator.
- **Procedure:**
  1. When a Student registers and indicates age under 18 or uploads academic documentation showing minor status, parental declaration is required.
  2. Student submits guardian declaration in Flutter Legal Center providing: Guardian Full Name, Guardian Email, Guardian Phone, Relationship (Parent / Legal Guardian).
  3. Record inserted into `guardian_consents` with `verification_status = 'PENDING_VERIFICATION'` and `verification_method = 'MANUAL_OFFICIAL_REVIEW'`.
  4. System dispatches verification notice to Guardian Email containing policy terms and consent confirmation link.
  5. Admin opens Next.js Admin Portal -> **Minors & Safeguards** tab (`/legal?tab=guardians`).
  6. Admin reviews guardian contact and confirmation. Clicks **Verify Guardian Consent**.
  7. Verification status transitions to `VERIFIED` with `verified_by = admin_id` and timestamp.
  8. Student receives unrestricted access to assigned training curriculum and practical drafting modules.
- **Audit Proof:** Persisted in `guardian_consents` with verification method `MANUAL_OFFICIAL_REVIEW`.

---

### PLAYBOOK 08: Guardian Consent Withdrawal & Student Transition
- **Objective:** Safely handle parental/guardian withdrawal of minor consent or student transition upon attaining the age of 18 (majority).
- **Role Assignment:** Studio Administrator.
- **Procedure:**
  1. Guardian submits written consent withdrawal or clicks withdrawal link in guardian email.
  2. Record in `guardian_consents` updated with `withdrawn_at = CURRENT_TIMESTAMP` and `verification_status = 'REVOKED'`.
  3. Student account training access is immediately gated; active practical assignments are paused.
  4. If student has attained 18 years of age, student submits self-declaration of majority with government birth certificate/Aadhaar/PAN proof.
  5. Admin verifies age documentation and updates user record to adult Student status, releasing guardian dependency.
- **Audit Proof:** Timestamped `withdrawn_at` in `guardian_consents` and activity log audit entry.

---

### PLAYBOOK 09: Intellectual Property Dispute & Notice-and-Takedown
- **Objective:** Respond to third-party copyright, design infringement, or CAD ownership claims under the Indian Copyright Act 1957 and IT Act 2000 Section 79 intermediary safe harbor.
- **Role Assignment:** Legal Counsel (`PENDING_ASSIGNMENT`) & Studio Administrator.
- **Procedure:**
  1. Receive formal IP infringement notice with proof of ownership, exact CAD drawing file ID, and prima facie infringement details at `support@draughtsmanstudio.com`.
  2. Acknowledge receipt within 24 hours.
  3. Locate disputed project and deliverable in Next.js Admin Panel -> Projects.
  4. Place administrative lock on deliverable download (`status = 'UNDER_INVESTIGATION'`).
  5. Issue formal notice to uploading Engineer/Draughtsman with 48-hour response window for counter-declaration.
  6. If counter-declaration establishes legitimate ownership or valid architectural license, forward to complainant.
  7. If no response or infringement is verified, permanently restrict deliverable, preserving file record in storage for legal discovery.
- **Audit Proof:** Maintained in project activity logs and legal correspondence archive.

---

### PLAYBOOK 10: Architectural & Structural Liability Incident Response
- **Objective:** Address structural defect notifications, drawing errors, or safety incident claims while enforcing the statutory disclaimer that DRAUGHTSMAN STUDIO does not practice engineering.
- **Role Assignment:** Grievance Officer (`PENDING_ASSIGNMENT`) & Legal Proprietor (MOHAMMED MOSIN S).
- **Procedure:**
  1. Receive incident report alleging drawing defect or structural variance.
  2. Immediately issue formal notice re-affirming Section 4 of Terms and Conditions and Section 2 of Architectural & Engineering Disclaimer: ARCHI DRAFT operates solely as a digital drafting facilitation portal; the licensed Engineer of Record bears sole legal and structural certification responsibility under the Architects Act 1972 and State Building Bye-laws.
  3. Freeze all version revisions for the affected project using project lock mechanism.
  4. Export complete drawing version audit trail (`drawing_versions`, `drawing_version_reviews`, activity logs).
  5. Assemble dossier containing:
     - Engineer identity, registration credentials, and IP address of final drawing approval.
     - Complete version reviews and timestamped approvals.
     - Acceptance records of Architectural Disclaimer from Engineer and Draughtsman.
  6. Deliver dossier to legal counsel (`PENDING_ASSIGNMENT`) for formal response.
- **Audit Proof:** Complete immutable version review history preserved in D1.

---

### PLAYBOOK 11: Project Cancellation, Milestone Failure & Refunds
- **Objective:** Evaluate and process project cancellation and refund requests under the Milestone Cancellation & Revision Policy.
- **Role Assignment:** Accounts Lead (`PENDING_ASSIGNMENT`) / Studio Administrator.
- **Procedure:**
  1. User submits refund request via Support/Helpdesk or Admin creates record in Next.js Admin Portal -> **Policies & Redressal: Cancellation & Refunds** tab (`/legal?tab=refunds`).
  2. Identify project stage:
     - Milestone 0 (Pre-assignment / Draft): 100% refund eligible.
     - Milestone 1 (Draughtsman assigned, initial draft underway): 50% pro-rata drafting fee refund.
     - Milestone 2 (Drawing approved by Engineer or delivered): 0% drafting fee refund (unlimited revisions policy applies).
  3. Admin enters `amount_approved`, `review_decision`, and `resolution_notes`.
  4. Note: Production payment refund gateway execution is disabled in development; approved records generate manual accounts clearance voucher.
  5. Update status to `APPROVED` or `REJECTED_WITH_REASON`.
- **Audit Proof:** Recorded in `cancellation_refund_requests` with financial audit metadata.

---

### PLAYBOOK 12: Data Breach Notification & CERT-In Reporting (6-Hour Window)
- **Objective:** Detect, contain, report, and remediate cybersecurity incidents and personal data breaches within the mandatory 6-hour statutory window under CERT-In Direction No. 20(3)/2022 and DPDP Act Sec 8(6).
- **Role Assignment:** Security Incident Officer (`PENDING_ASSIGNMENT`) & Studio Administrator.
- **Procedure:**
  1. **T+0 to T+1 Hour (Detection & Containment):**
     - Security alert received or unauthorized D1/R2 access detected.
     - Immediately isolate affected Worker routes or revoke compromised Cloudflare API tokens.
     - Activate immutable incident log.
  2. **T+1 to T+4 Hours (Assessment & Triage):**
     - Determine scope: number of user profiles, credential hashes, or CAD drawings exposed.
     - Query `activity_logs` for actor footprint and IP ranges.
  3. **T+4 to T+6 Hours (Statutory CERT-In Notification):**
     - Draft incident report using CERT-In Incident Reporting Form.
     - Send notification email to `incident@cert-in.org.in` within **strict 6-hour statutory window**.
     - Form includes: nature of incident, date/time of detection, systems affected, suspected cause, and remedial action taken.
  4. **Post-T+6 Hours (Data Principal Notification):**
     - If personal data was compromised, notify affected Data Principals and the Data Protection Board of India (DPBI) pursuant to Section 8(6) of DPDP Act 2023.
- **Audit Proof:** CERT-In dispatch receipt and security incident record preserved in 180-day audit log.

---

### PLAYBOOK 13: User Privacy Grievance Escalation to Appellate / DPBI
- **Objective:** Resolve user privacy complaints and statutory data rights grievances within mandatory timeframes under IT (SPDI) Rules 2011 and DPDP Act Sec 13.
- **Role Assignment:** Grievance Officer (`PENDING_ASSIGNMENT`, interim: MOHAMMED MOSIN S).
- **Procedure:**
  1. Grievance received at `mosin@draughtsmanstudio.com` or submitted via Admin Helpdesk.
  2. Acknowledge grievance within **24 hours** with unique ticket tracking number.
  3. Investigate issue with relevant engineering and administrative leads.
  4. Render formal written resolution within **15 calendar days** of receipt.
  5. If complainant is dissatisfied with resolution, furnish formal notice of their statutory right to file an appellate complaint before the **Data Protection Board of India (DPBI)** under Section 13(3) of DPDP Act 2023.
- **Audit Proof:** Logged in `privacy_requests` and Next.js Admin Portal -> **Privacy Grievances** tab (`/legal?tab=grievances`).

---

### PLAYBOOK 14: Automated Data Retention & Deletion Ledger Audit
- **Objective:** Audit and enforce statutory and operational data retention rules defined in `data_retention_policies`.
- **Role Assignment:** Systems Lead (`PENDING_ASSIGNMENT`) / Studio Administrator.
- **Procedure:**
  1. Open Next.js Admin Portal -> **Policies & Redressal: Retention Policies** tab (`/legal?tab=retention`).
  2. Review baseline retention matrix:
     - `SYSTEM_SECURITY_LOGS`: 180 days (Statutory CERT-In mandate). Purge records older than 180 days after verifying backup integrity.
     - `TAX_AND_INVOICE_RECORDS`: 8 Financial Years (2,920 days under Income Tax Act Sec 44AA / CGST Act Sec 36). Never purge prior to statutory expiry.
     - `ACTIVE_PROJECT_CAD_ARCHIVES`: Project completion + commercial limitation period.
     - `PIXMINT_BOT_CONVERSATIONS`: Data minimization cleanup for inactive sessions.
     - `ACCOUNT_DELETION_RECORDS`: 180 days proof of compliance.
  3. Run scheduled audit script verifying that tombstones have been scrubbed and no orphan PII remains in storage.
- **Audit Proof:** Retention ledger audit report signed off by Studio Administrator.

---

### PLAYBOOK 15: Cross-Border Data Transfer Assessment & Restrictions
- **Objective:** Ensure all cloud database, object storage, and serverless compute regions comply with Indian data residency mandates and DPDP Act Sec 16 cross-border transfer restrictions.
- **Role Assignment:** Privacy Officer (`PENDING_ASSIGNMENT`) / Cloudflare Architect.
- **Procedure:**
  1. Verify Cloudflare D1 database location: Cloudflare Indian data centers (Mumbai, Chennai, Hyderabad, New Delhi).
  2. Verify Cloudflare R2 bucket configuration: Primary storage configured with jurisdictional data residency controls.
  3. When integrating third-party APIs (e.g., AI inference, payment gateways), verify that vendor does not store PII in restricted foreign jurisdictions prohibited by Central Government notifications.
  4. Maintain Data Transfer Assessment dossier documenting technical encryption in transit (TLS 1.3) and encryption at rest (AES-256).
- **Audit Proof:** Annual Infrastructure Regional Architecture Verification Certificate.

---

### PLAYBOOK 16: PIXMINT BOT Content Violation & Session Purge
- **Objective:** Immediately purge harmful, hallucinated, defamatory, or copyright-infringing AI outputs from PIXMINT BOT while preserving robot mascot identity.
- **Role Assignment:** Studio Administrator.
- **Procedure:**
  1. User or Administrator flags inappropriate response generated by PIXMINT BOT via chat interface or feedback mechanism.
  2. Admin navigates to Next.js Admin Portal -> PIXMINT BOT Management (`/pixmint`).
  3. Search conversation session by `sessionId` or user email.
  4. Click **Purge Message** or **Delete Session**.
  5. D1 executes cascading hard-delete across `chat_messages` and `chat_sessions`.
  6. If model generated dangerous architectural advice, add rule to system prompt guardrails in `worker/src/pixmint/` reiterating: "You are PIXMINT, a drafting assistant robot mascot. You never certify structural engineering designs or provide stamped architectural advice."
- **Audit Proof:** Activity log entry recording administrative purge and updated guardrail version.

---

### PLAYBOOK 17: Annual Legal Document Review & Entity Status Audit
- **Objective:** Conduct annual comprehensive audit of Draughtsman Studio legal identity, operational brand, physical address, and statutory designations.
- **Role Assignment:** Legal Proprietor (MOHAMMED MOSIN S) & External Legal Counsel.
- **Procedure:**
  1. Every October, review the authoritative legal business register:
     - Proprietor Name: MOHAMMED MOSIN S.
     - Business Structure: Sole Proprietorship.
     - Operating Brand: DRAUGHTSMAN STUDIO.
     - Product Name: ARCHI DRAFT.
     - Verified Domains: `archidraft.draughtsmanstudio.com`, `draughtsmanstudio.com`.
     - Support Email: `support@draughtsmanstudio.com`.
     - Privacy Email: `support@draughtsmanstudio.com`.
     - Grievance Email: `mosin@draughtsmanstudio.com`.
  2. Audit status of pending verifications:
     - Physical registered address status (`PENDING_VERIFICATION` until commercial lease / utility bill is formally vetted).
     - Formal Grievance Officer appointment status (`PENDING_VERIFICATION` until formal appointment order executed).
  3. Review all 7 canonical legal documents against amendments in DPDP Act rules, IT Act regulations, and Consumer Protection directives.
  4. Commit signed Annual Audit Declaration to repository docs.
- **Audit Proof:** Published in `docs/08_legal_privacy/` with updated configuration version.

---
**End of Operational Playbooks Document.**

