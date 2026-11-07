# ARCHI DRAFT — Admin Student Guardian Verification Guide
**Operating Brand:** DRAUGHTSMAN STUDIO  
**Legal Proprietor:** MOHAMMED MOSIN S  
**Product:** ARCHI DRAFT  
**Phase:** 4 of 9 (Next.js Admin Legal Compliance Dashboard & Audit Center)  
**Date:** November 2026  
**Status:** Completed & Tested

---

## 1. Statutory Context & Principles (§ 9 DPDP Act 2023)

Section 9 of India's **Digital Personal Data Protection Act, 2023 (DPDP Act)** establishes strict statutory mandates governing the processing of personal data belonging to children (defined as individuals under 18 years of age):

1. **Mandatory Verifiable Consent:** A Data Fiduciary must obtain verifiable consent of the parent or lawful guardian before processing any personal data of a child.
2. **Prohibition of Behavioral Monitoring:** Platforms must not undertake tracking, behavioral monitoring, or targeted advertising directed at children.
3. **No Detrimental Processing:** Processing that is likely to cause any detrimental effect on the well-being of a child is strictly prohibited.

---

## 2. Platform Safeguards & Core Operational Rule

> [!IMPORTANT]
> **A declaration submitted by a student is NOT automatically verified parental consent.**  
> Self-submitted guardian details represent an intake declaration only. The account must remain in a restricted status until an authorized Studio Administrator independently verifies the parental details and records an auditable verification decision.

---

## 3. Student Guardian Intake & Data Schema

When an under-18 student registers or opens the Student Studio in Flutter, they are presented with the **Guardian Consent Declaration Modal**, which captures:
- `student_user_id`: Authenticated Student UID
- `guardian_name`: Full legal name of parent or lawful guardian
- `guardian_email`: Active email address of parent/guardian
- `guardian_phone`: Primary mobile telephone number of parent/guardian
- `relationship`: Familial relationship (`Father`, `Mother`, `Legal Guardian`)
- `consent_declaration`: Explicit statutory acknowledgment under Section 9 of the DPDP Act 2023
- `verification_status`: Initialized to `PENDING`

---

## 4. Administrative Verification Workflow

Studio Administrators review incoming declarations in the **Guardian Consents Tab** (`/legal?tab=guardians`):

```
[Student Submits Declaration]
             │
             ▼
    [Status: PENDING]
             │
             ├── Administrator reviews guardian contact validity
             ├── Confirms relationship and institutional enrollment
             │
             ├── [Approve] ────────► Status: VERIFIED
             │                        - Attaches reviewer UID & timestamp
             │                        - Unlocks certified student credentials
             │
             └── [Reject]  ────────► Status: REJECTED
                                      - Attaches rejection reason
                                      - Student account remains restricted
```

### 4.1 Verification Statuses
- `PENDING`: Intake received. Awaiting admin contact check or institutional verification.
- `VERIFIED`: Formally approved. The student is authorized for full vocational curriculum modules.
- `REJECTED`: Declined due to invalid contact details, non-responsive guardian, or falsified information.
- `WITHDRAWN`: Parent or guardian has formally requested revocation of consent. Student data processing is immediately ceased.
- `EXPIRED`: The declaration period has lapsed without verification.

### 4.2 Audit Trail & Evidence Preservation
Every verification or rejection action records:
- `verified_by`: Administrator UID who performed the audit.
- `verified_at`: Timestamp of decision.
- `notes`: Specific verification notes (e.g., *"Phone confirmation completed with father on 2026-11-07; college enrollment verified"*).
