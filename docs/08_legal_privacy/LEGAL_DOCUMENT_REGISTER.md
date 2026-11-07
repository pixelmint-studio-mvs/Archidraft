# ARCHI DRAFT | CANONICAL LEGAL DOCUMENT REGISTER

**Operating Brand:** DRAUGHTSMAN STUDIO  
**Legal Proprietor:** MOHAMMED MOSIN S  
**Product:** ARCHI DRAFT  
**Phase:** 1 of 9 — Legal Document Registry  
**Registry Version:** 1.0.0  
**Last Updated:** November 2026  

---

## 1. CANONICAL DOCUMENT LEDGER

The following table itemizes the seven authoritative policy documents established in Phase 1:

| # | Document Type | Document ID | Version | Status | Mandatory | Target Audience | Governing Statutes | Canonical File Path |
| :-: | :--- | :--- | :-: | :--- | :-: | :--- | :--- | :--- |
| **1** | `TERMS_AND_CONDITIONS` | `doc-terms-v1-0-0` | `1.0.0` | `PENDING_LEGAL_REVIEW` | **YES** | `ALL` | Indian Contract Act 1872, IT Act 2000 | `shared/legal/documents/terms_and_conditions/v1.0.0.md` |
| **2** | `PRIVACY_POLICY` | `doc-priv-v1-0-0` | `1.0.0` | `PENDING_LEGAL_REVIEW` | **NO** | `ALL` | DPDP Act 2023, IT SPDI Rules 2011, CERT-In | `shared/legal/documents/privacy_policy/v1.0.0.md` |
| **3** | `AI_USAGE_DISCLAIMER` | `doc-ai-v1-0-0` | `1.0.0` | `PENDING_LEGAL_REVIEW` | **YES** | `ALL` | IT Act 2000, Consumer Protection Act 2019 | `shared/legal/documents/ai_usage_disclaimer/v1.0.0.md` |
| **4** | `ENGINEERING_DISCLAIMER` | `doc-eng-v1-0-0` | `1.0.0` | `PENDING_LEGAL_REVIEW` | **YES** | `ALL` | Architects Act 1972, NBC 2016, Municipal Bye-Laws | `shared/legal/documents/engineering_disclaimer/v1.0.0.md` |
| **5** | `CAD_OWNERSHIP_FRAMEWORK` | `doc-cad-v1-0-0` | `1.0.0` | `PENDING_LEGAL_REVIEW` | **YES** | `ENGINEER`, `DRAUGHTSMAN`, `STUDENT`, `ADMIN` | Indian Copyright Act 1957, Commercial Courts Act | `shared/legal/documents/cad_ownership_framework/v1.0.0.md` |
| **6** | `REVISION_POLICY` | `doc-rev-v1-0-0` | `1.0.0` | `PENDING_BUSINESS_APPROVAL` | **NO** | `ENGINEER`, `DRAUGHTSMAN`, `ADMIN` | Indian Contract Act 1872 | `shared/legal/documents/revision_policy/v1.0.0.md` |
| **7** | `CANCELLATION_REFUND_POLICY` | `doc-ref-v1-0-0` | `1.0.0` | `PENDING_BUSINESS_APPROVAL` | **NO** | `ALL` | Consumer Protection (E-Commerce) Rules 2020 | `shared/legal/documents/cancellation_refund_policy/v1.0.0.md` |

---

## 2. DETAILED DOCUMENT SPECIFICATIONS

### 2.1. Platform Terms & Conditions (`TERMS_AND_CONDITIONS`)
- **Version:** `1.0.0`
- **Scope:** Master contract governing account eligibility, authentication, user role responsibilities (Engineer, Draughtsman, Student, Admin), acceptable use, balanced professional liability, and Indian jurisdiction.
- **Mandatory Assertion:** Checked at login and registration via Cloudflare Worker `assertTermsAccepted`. Caller cannot access protected endpoints without affirmative acceptance of this exact version.
- **Prerequisites for `EFFECTIVE` Status:** Legal counsel review, verification of physical business address.

### 2.2. Privacy Policy & Data Protection Notice (`PRIVACY_POLICY`)
- **Version:** `1.0.0`
- **Scope:** Complete Data Fiduciary disclosure under DPDP Act, 2023. Explicitly details Cloudflare D1 and R2 processing, Firebase password hashing, 180-day CERT-In security logging, 8-year tax record retention, and user data rights (access, correction, erasure, grievance, nomination).
- **Under-18 Safeguards:** Details Section 9 requirements regarding verifiable parental consent and prohibition of behavioral tracking.
- **Prerequisites for `EFFECTIVE` Status:** Formal appointment of Grievance Officer, verification of physical establishment address.

### 2.3. Pixmint Bot & AI Usage Disclaimer (`AI_USAGE_DISCLAIMER`)
- **Version:** `1.0.0`
- **Scope:** Discloses that Pixmint Bot is an automated assistant, NOT a registered architect or structural engineer. Mandates human-in-the-loop professional verification of all dimensions, structural formulas, and municipal code references prior to construction or plan filing.
- **Prerequisites for `EFFECTIVE` Status:** Legal review of automated tools liability exclusions.

### 2.4. Architectural & Engineering Disclaimer (`ENGINEERING_DISCLAIMER`)
- **Version:** `1.0.0`
- **Scope:** Establishes that Archi Draft and Draughtsman Studio are a digital workflow portal and do not act as the Engineer or Architect of Record. Registered consulting engineers uploading or approving drawings retain full statutory liability under the Architects Act, 1972 and NBC 2016.
- **Prerequisites for `EFFECTIVE` Status:** Legal review of statutory professional boundaries.

### 2.5. CAD Drawing Ownership & Intellectual Property Framework (`CAD_OWNERSHIP_FRAMEWORK`)
- **Version:** `1.0.0`
- **Scope:** Explicitly preserves Background IP for clients and consulting engineers. Grants Draughtsman Studio a limited, revocable operational license on Cloudflare R2. Prohibits automatic IP transfers and requires written bilateral contracts and full payment settlement for final drawing copyright assignment under the Indian Copyright Act, 1957.
- **Prerequisites for `EFFECTIVE` Status:** Legal counsel review of copyright assignment mechanics.

### 2.6. Project Revision and Correction Policy (`REVISION_POLICY`)
- **Version:** `1.0.0`
- **Scope:** Formalizes **two (2) included revision rounds** (`included_revision_rounds = 2`) for drafting errors and minor adjustments within the brief. Establishes boundaries for out-of-scope revisions (structural changes, area increases, new storeys) that require separate commercial milestones.
- **Prerequisites for `EFFECTIVE` Status:** Business owner approval of turnaround windows and revision limits.

### 2.7. Subscription, Cancellation and Refund Policy (`CANCELLATION_REFUND_POLICY`)
- **Version:** `1.0.0`
- **Scope:** Milestone-based cancellation tiers (Pre-assignment: 100% refund; In-progress: pro-rata refund; Delivered: non-refundable). Student course 7-day grace period (under 15% curriculum completion). Standard 7-10 day refund processing SLA.
- **Prerequisites for `EFFECTIVE` Status:** Payment gateway aggregator selection and business owner commercial sign-off.

---

## 3. VERSION TRANSITION & AUDIT TRAIL RULES

1. **Immutable Historical Records:** Once a document version achieves `EFFECTIVE` status and records user consent in `legal_consent_events`, its markdown text must never be edited in-place.
2. **SemVer Cadence:**
   - **Patch (`x.x.1`):** Typographical fixes, grammatical clarifications, contact email updates that do not alter legal obligations. Does not trigger mandatory re-acceptance.
   - **Minor (`x.1.0`):** Operational adjustments, new optional feature disclosures, revision window modifications.
   - **Major (`2.0.0`):** Material alteration of commercial liability, IP ownership, arbitration terms, or fee structures. Automatically invalidates prior consent in `assertTermsAccepted` and forces an in-app blocking re-acceptance prompt.
3. **Database Ledger Synchronization:** Document metadata and markdown text must be synced into D1 table `legal_documents` with an accurate `change_summary` before status transition.
