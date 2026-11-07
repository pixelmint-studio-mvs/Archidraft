# ARCHI DRAFT — PHASE 5 GUARDIAN SAFEGUARDS REPORT
## Under-18 Student Protection, Guardian Consent Workflows & Section 9 DPDP Analysis

**Project:** ARCHI DRAFT  
**Operating Brand:** DRAUGHTSMAN STUDIO  
**Legal Proprietor:** MOHAMMED MOSIN S (Sole Proprietorship)  
**Development Team:** PixelMint Studio MVS  
**Audit Focus:** Minor Protection, Guardian Declarations & DPDP Section 9 Readiness  
**Date:** November 2026  
**Status:** IMPLEMENTED — TRUTHFULLY SCOPED  

---

## 1. Executive Summary

This report evaluates ARCHI DRAFT's safeguards for students and minor users under Section 9 of the Digital Personal Data Protection Act, 2023 (DPDP Act 2023). It assesses the student onboarding gate, guardian declaration capture, behavioral advertising prohibitions, and the administrative review console.

---

## 2. Statutory Framework: Section 9, DPDP Act 2023

1. **Definition of Child (Section 2(f)):** An individual who has not completed 18 years of age.
2. **Verifiable Parental Consent (Section 9(1)):** A Data Fiduciary shall, before processing any personal data of a child, obtain verifiable consent of the parent of such child or lawful guardian in such manner as may be prescribed.
3. **Harm Prevention (Section 9(2)):** A Data Fiduciary shall not undertake any processing of personal data that is likely to cause any detrimental effect on the well-being of a child.
4. **Tracking & Targeted Advertising Prohibited (Section 9(3)):** A Data Fiduciary shall not undertake tracking or behavioral monitoring of children or targeted advertising directed at children.

---

## 3. Platform Architectural Safeguards

### 3.1 Age Detection & Onboarding Gate
When a user registers or provisions a profile under the `STUDENT` role:
1. Date of birth is validated.
2. If the user is identified as under 18 years of age, the platform transitions their legal status to require a Guardian Consent declaration.
3. The student is presented with the Guardian Declaration workflow, capturing:
   - Full Name of Parent or Legal Guardian
   - Relationship (`FATHER`, `MOTHER`, `LEGAL_GUARDIAN`)
   - Guardian Email Address
   - Guardian Phone Number
   - Explicit declaration authorizing CAD educational participation

### 3.2 Database Schema (`legal_guardian_consents`)
```sql
CREATE TABLE IF NOT EXISTS legal_guardian_consents (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  guardian_name TEXT NOT NULL,
  guardian_email TEXT NOT NULL,
  guardian_phone TEXT,
  guardian_relationship TEXT NOT NULL,
  verification_status TEXT NOT NULL DEFAULT 'PENDING_REVIEW'
    CHECK(verification_status IN ('PENDING_REVIEW', 'VERIFIED', 'REJECTED')),
  verified_at INTEGER,
  verified_by TEXT,
  notes TEXT,
  created_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_guardian_consent_user ON legal_guardian_consents(user_id);
CREATE INDEX IF NOT EXISTS idx_guardian_consent_status ON legal_guardian_consents(verification_status);
```

### 3.3 Strict Behavioral Protection for Students
- **Zero Targeted Advertising:** The platform does not run third-party advertising networks, pixels, or trackers.
- **Marketing Disabled by Default:** Optional marketing switches default to `false` (OFF).
- **Safe CAD Learning Sandbox:** Students access practical modules and exercises in an isolated environment without exposure to commercial client negotiations or public liability.

---

## 4. Truthful Assessment of Parental Verification

- **Current Implementation:** Self-submitted parental declaration with mandatory administrative review (`PENDING_REVIEW` -> `VERIFIED` by Admin).
- **Statutory Commencement Reality:** The Central Government has not yet notified the specific rules defining the exact technical standards for "verifiable parental consent" (e.g., DigiLocker, Aadhaar e-Sign, or Virtual ID verification).
- **Truthful Documentation Policy:** ARCHI DRAFT explicitly discloses that its student guardian system is a **parental declaration with studio administrator oversight**, not an automated biometric or identity-verified digital signature.

---

## 5. Verification Test Evidence

1. **Flutter Domain Model:**
   - Verified via `test/features/legal/domain/canonical_legal_system_phase3_test.dart` (Test: `GuardianConsent parses student parental declaration under Section 9 DPDPA`).
2. **Worker API Contracts:**
   - Verified via `worker/test/canonical_legal_system_phase2.test.mjs` (Test: `Guardian consent recording for student minority status`).
3. **Admin Web Compliance Console:**
   - Verified via `apps/admin-web/test/admin-legal-compliance.test.ts` (Test: `Guardian consent queue renders student parental declarations and supports review status updates`).

**Audit Status:** Student minority safeguards are operational, compliant with existing frameworks, and positioned for seamless compliance with future DPDP rule notifications.

