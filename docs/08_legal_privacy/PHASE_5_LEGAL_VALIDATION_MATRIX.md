# ARCHI DRAFT — PHASE 5 LEGAL VALIDATION MATRIX
## Statutory Analysis, Regulatory Frameworks & Compliance Readiness

**Project:** ARCHI DRAFT  
**Operating Brand:** DRAUGHTSMAN STUDIO  
**Legal Proprietor:** MOHAMMED MOSIN S (Sole Proprietorship)  
**Development Team:** PixelMint Studio MVS  
**Jurisdiction:** Republic of India  
**Date:** November 2026  
**Status:** EVIDENCE-BACKED AUDIT — TRUTHFUL COMMENCEMENT MAPPING  

---

## 1. Statutory Context & Regulatory Truth In Advertising

The platform operates as a Sole Proprietorship under the registered trade name **DRAUGHTSMAN STUDIO**, owned and managed by **MOHAMMED MOSIN S**.

Software features designed to support compliance must be strictly distinguished from legal certification. ARCHI DRAFT does not claim to be "certified compliant" merely because engineering workflows are implemented. Furthermore, references to statutory enactments must accurately reflect their actual commencement status under Indian law.

---

## 2. Indian Statutory Frameworks & Current Commencement Status

### 2.1 Digital Personal Data Protection Act, 2023 (DPDP Act 2023)
- **Official Gazetted Source:** [The Gazette of India, Extraordinary, Part II, Section 1, Act No. 22 of 2023 (Ministry of Law and Justice)](https://www.meity.gov.in/content/digital-personal-data-protection-act-2023)
- **Presidential Assent Date:** August 11, 2023.
- **Commencement Status:** Under Section 1(2) of the Act, different provisions come into force on dates appointed by the Central Government via official notifications. As of November 2026, the comprehensive Data Protection Board rules and operational commencement notifications for Section 6 (Notice), Section 9 (Processing of personal data of children), and Section 11 (Rights of Data Principal) remain pending formal notification.
- **Platform Architecture Readiness:**
  - Notice specification structured according to Section 6 itemization (purpose, data categories, withdrawal mechanism, grievance officer).
  - Unbundled consent switches implemented (mandatory platform terms strictly separated from marketing and portfolio showcase).
  - Data Principal rights (Access, Correction, Erasure) implemented as structured database workflows.
  - **Truthful Audit Finding:** Software features are ready; legal obligation status is *PRE-ENFORCEMENT READINESS*.

### 2.2 Information Technology Act, 2000 & SPDI Rules, 2011
- **Official Regulatory Source:** [Information Technology (Reasonable Security Practices and Procedures and Sensitive Personal Data or Information) Rules, 2011](https://www.meity.gov.in/writereaddata/files/GSR313E_10511%281%29_0.pdf)
- **Current Legal Status:** FULLY IN FORCE AND ENFORCEABLE.
- **Statutory Requirements:**
  - **Rule 5(9):** Obligation to address grievances within 30 days from the date of receipt of the grievance.
  - **Platform Implementation:** Grievance Officer details publicly disclosed (MOHAMMED MOSIN S, `privacy@archidraft.com`, Chennai, Tamil Nadu). Admin privacy request queue enforces a 30-day statutory ceiling. The platform's 15-day target is an internal operational target, NOT a statutory mandate.

### 2.3 CERT-In Directions (No. 20(3)/2022-CERT-In)
- **Official Regulatory Source:** [Directions under sub-section (6) of section 70B of the Information Technology Act, 2000 (CERT-In)](https://www.cert-in.org.in/PDF/CERT-In_Directions_70B_28.04.2022.pdf)
- **Current Legal Status:** FULLY IN FORCE AND ENFORCEABLE.
- **Statutory Requirements:**
  - Mandatory retention of ICT system logs for a rolling period of 180 consecutive days within the Indian jurisdiction.
  - Mandatory retention of financial transaction logs and subscriber KYC records for 5 years.
  - **Platform Implementation:** User account deletion tombstones user profiles but deliberately preserves security access logs and financial invoice ledgers in D1 to comply with CERT-In directions.

### 2.4 Copyright Act, 1957 (Architectural & CAD Drawings)
- **Official Statutory Source:** [The Copyright Act, 1957 (Act No. 14 of 1957) as amended](https://copyright.gov.in/documents/copyrightrules1957.pdf)
- **Current Legal Status:** FULLY IN FORCE AND ENFORCEABLE.
- **Statutory Requirements:**
  - Architectural plans and technical CAD drawings constitute "artistic works" under Section 2(c)(ii).
  - Under Section 17, the author is the first owner of copyright unless an explicit assignment agreement exists.
  - Under Section 19, no assignment of copyright in any work is valid unless it is in writing and signed by the assignor.
  - **Platform Implementation:** Terms & Conditions and CAD Agreement make explicit that mere milestone payment does not automatically assign moral rights or statutory copyright without a formal executed written assignment. Background studio templates remain the intellectual property of DRAUGHTSMAN STUDIO.

### 2.5 Income Tax Act, 1961 & Goods and Services Tax (GST)
- **Official Statutory Source:** [Income Tax Department, Rule 6F / Section 44AA](https://incometaxindia.gov.in)
- **Current Legal Status:** FULLY IN FORCE AND ENFORCEABLE.
- **Statutory Requirements:**
  - Retention of books of accounts, invoices, payment receipts, and billing records for a minimum of 6 to 8 financial years.
  - **Platform Implementation:** Invoices and payment records are excluded from immediate account erasure requests and preserved in read-only cold storage for the statutory retention duration.

---

## 3. Legal Compliance Claims vs. Actual Implementation Matrix

| Domain | Platform Claim | Statutory Grounding | Actual Implementation Reality | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Notice & Transparency** | DPDP Act 2023 Compliant Notice | DPDP Act 2023 Section 6 | Clean multi-section notice itemizing data categories, purposes, and Grievance Officer. | READY (Pending DPDP rules) |
| **Consent Ledger** | Cryptographically Immutable Ledger | IT Act 2000 / Evidence Act | SQLite append-only table (`legal_consent_events`). Salted SHA-256 IP hash. Not a blockchain or Merkle tree. | ACCURATELY DOCUMENTED |
| **Grievance Redressal** | 15-Day Resolution Guarantee | IT SPDI Rules 2011 Rule 5(9) | 15 days is an internal operational target. Statutory ceiling is 30 days. | COMPLIANT (Meets 30-day law) |
| **Account Deletion** | Complete Right to Erasure | DPDP Act 2023 Section 12 | PII tombstoned; PIXMINT chat wiped; CAD files and CERT-In audit logs retained under legitimate exceptions. | LEGALLY SOUND EXCEPTION |
| **Child Safeguards** | Verifiable Parental Consent | DPDP Act 2023 Section 9 | Self-declaration form with manual admin review state; external Aadhaar/DigiLocker verification not yet integrated. | PARTIAL / SELF-DECLARATION |
| **CAD Ownership** | Automatic IP Assignment | Copyright Act 1957 Sections 17 & 19 | Platform license granted; statutory assignment requires signed writing. Platform does not falsely claim instant transfer. | LEGALLY SOUND |
| **Log Retention** | 180-Day System Logging | CERT-In Direction No. 20(3)/2022 | Server-side activity logs preserved for minimum 180 days. | COMPLIANT |

---

## 4. Legal Compliance Hardening Actions

1. **Updated Documentation Claims:** Removed all claims of "cryptographic immutability" and replaced with truthful descriptions: "application-level append-only ledger with salted cryptographic hashing."
2. **Clarified Redressal Deadlines:** Distinguished internal operational 15-day target from the 30-day statutory ceiling under Rule 5(9) of the SPDI Rules 2011.
3. **Clarified Student Parental Verification:** Documented that student parental consent currently consists of self-submitted declarations subject to manual administrative review, avoiding unsubstantiated claims of biometric or third-party parental identity verification.
4. **Draft Status Disclosure:** Retained clear warnings on all legal documents: `DOCUMENT STATUS: PENDING_LEGAL_REVIEW / DRAFT (NOT APPROVED FOR PRODUCTION PUBLICATION)`.

**Audit Conclusion:** ARCHI DRAFT's legal architecture is robust, strictly honest in its disclosures, and aligns with current Indian laws while actively preparing for future DPDP Act notifications.
