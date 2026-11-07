# ARCHI DRAFT — User Data Rights & Privacy Controls Guide
**Operating Brand:** DRAUGHTSMAN STUDIO  
**Legal Proprietor:** MOHAMMED MOSIN S  
**Product:** ARCHI DRAFT  
**Phase:** 3 of 9 (Flutter Legal Center, Onboarding Consent & User Privacy Controls)  
**Date:** November 2026  
**Status:** Completed & Tested

---

## 1. Overview of Statutory User Data Rights

In adherence to India's **Digital Personal Data Protection Act, 2023 (DPDP Act)** and the **Information Technology (Reasonable Security Practices and Procedures and Sensitive Personal Data or Information) Rules, 2011 (SPDI Rules)**, ARCHI DRAFT provides self-service mechanisms for users to exercise their statutory data protection rights directly inside the Flutter application.

Specifically:
- **Right to Information & Access (§ 11 DPDP Act):** Right to obtain a summary of personal data being processed, identities of all third parties with whom personal data is shared, and an export of data.
- **Right to Correction & Completion (§ 12(1) DPDP Act):** Right to request correction of inaccurate or misleading personal data, completion of incomplete data, and updating of profile details.
- **Right of Grievance Redressal (§ 13 DPDP Act):** Readily available contact vectors to the Grievance Officer and Data Fiduciary.
- **Safeguards for Minors & Under-18 Students (§ 9 DPDP Act):** Verifiable parental/lawful guardian consent requirements.

---

## 2. Personal Data Export Infrastructure (§ 11 DPDPA)

### 2.1 Export Scopes Available to the User
Through the `DataExportDialog` in the Legal Center, users can choose between three machine-readable export scopes:
1. **Full Archive (`FULL_ARCHIVE`):** Complete snapshot including user profile, active and historic projects, drawings metadata, revision timelines, financial logs, and legal consent history.
2. **Projects & CAD Data (`PROJECTS_ONLY`):** Metadata, drawing briefs, revision history, and Cloudflare R2 file pointers for all authored or commissioned CAD drawings.
3. **Audit & Consent History (`CONSENT_AUDIT`):** Complete immutable record of document versions accepted, timestamps, IP hashes, and consent status events.

### 2.2 Security Architecture & 7-Day Download Expiry
- When requested via `LegalRepository.requestDataExport()`, the Cloudflare Worker backend generates an export job.
- When processed, an encrypted download URL with a cryptographic authorization token (`download_token`) is issued.
- **7-Day Expiry:** In accordance with security minimization practices, the download token automatically expires **7 calendar days** after generation (`expires_at`).
- If expired, the status displays as **Expired** with an indicator prompting the user to generate a fresh export if needed.

---

## 3. Personal Data Correction Workflow (§ 12(1) DPDPA)

### 3.1 Field-Specific Submission
Through `DataCorrectionDialog`, users can submit formal rectification requests across key profile attributes:
- **Legal Full Name (`name`)**
- **Contact Mobile Number (`mobile`)**
- **Postal / Work Address (`address`)**
- **Professional Qualifications (`qualification`)**

### 3.2 Verification & Review Lifecycle
To safeguard against identity fraud, account takeovers, and fraudulent credential changes in professional roles:
1. The user selects the field, inputs the proposed correction value, and provides a clear reason.
2. The submission is persisted in Cloudflare D1 with status `PENDING`.
3. Studio administrators review the correction request in the Admin Legal Dashboard.
4. Upon approval, the field is atomically updated in the user's primary profile and the request is marked `APPROVED`. If rejected, administrative feedback is displayed to the user with status `REJECTED`.

---

## 4. Under-18 Student Safeguards & Guardian Declarations (§ 9 DPDPA)

### 4.1 Statutory Child Protection Principles
Section 9 of the DPDP Act, 2023 sets strict obligations on data fiduciaries regarding children under 18 years of age:
- Processing is unlawful without verifiable consent of the child's parent or lawful guardian.
- Data fiduciaries are prohibited from undertaking tracking, behavioral monitoring, or targeted advertising directed at children.

### 4.2 ARCHI DRAFT Implementation
1. **Student Studio Guardian Status Banner:**
   - Displayed prominently at the top of the Student Studio screen (`lib/src/features/training/presentation/student_studio_screen.dart`).
   - If no guardian consent is on record, a warning card alerts the student: *"Under Section 9 of the DPDP Act 2023, student accounts require verifiable parent/guardian consent. Please submit your guardian details."*
2. **Guardian Consent Submission Flow:**
   - `GuardianConsentDialog` collects:
     * Parent / Legal Guardian Full Legal Name
     * Parent Email Address
     * Parent Contact Phone Number
     * Relationship (Father, Mother, Legal Guardian)
     * Explicit statutory acknowledgment checkbox under Section 9 of the DPDP Act.
3. **Verification Tracking:**
   - The status is tracked across `PENDING`, `VERIFIED`, and `REJECTED`.
   - Verification links and notices are sent to the verified parental contact before full student account privileges are unlocked.

---

## 5. Contact & Grievance Redressal

Every user can view the authoritative contact vectors in Section 5 of the Legal Center:
- **Data Fiduciary:** DRAUGHTSMAN STUDIO (Sole proprietorship of MOHAMMED MOSIN S)
- **Primary Privacy Support:** `support@draughtsmanstudio.com`
- **Statutory Grievance Redressal:** `mosin@draughtsmanstudio.com`
- **Statutory Timelines:**
  - Acknowledgment within **48 hours**.
  - Final resolution within **30 calendar days** (§ 13 DPDP Act).

