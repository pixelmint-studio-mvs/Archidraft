# ARCHI DRAFT — PHASE 5.1 GUARDIAN VERIFICATION REPORT
## Under-18 Minor Safeguards, Age Determination & Parental Declaration Architecture

- **Project:** ARCHI DRAFT
- **Operating Brand:** DRAUGHTSMAN STUDIO
- **Legal Proprietor:** MOHAMMED MOSIN S
- **Component:** Cloudflare D1 / Worker Backend / Flutter Student Portal / Admin Web
- **Audited Files:** `worker/src/legal.ts` (lines 1420–1580), `lib/src/features/training/presentation/student_studio_screen.dart`, `apps/admin-web/src/components/legal/GuardianVerificationTab.tsx`
- **Statutory Framework:** Digital Personal Data Protection Act 2023 (Section 9 — Processing of Personal Data of Children)

---

## 1. Executive Summary

This report inspects the technical safeguards implemented for underage students (vocational drafting learners) within ARCHI DRAFT. Section 9 of the DPDP Act 2023 establishes specialized protections for data principals who are children (defined as individuals under eighteen years of age), requiring verifiable consent of the parent or lawful guardian and strictly prohibiting tracking, behavioral monitoring, and targeted advertising directed at children.

ARCHI DRAFT implements a deterministic age calculation engine based on registered date of birth, an affirmative Guardian Consent Declaration workflow, state-machine driven administrative verification, and strict architectural isolation ensuring that under-18 learners are protected from unauthorized commercial project exposure and intrusive data tracking.

---

## 2. Age Determination & Boundary Mathematics

1. **Deterministic Date-of-Birth Calculation:**
   - Age is calculated dynamically on the server from `users.date_of_birth` using standard UTC calendar arithmetic:
     $$\text{Age} = \text{Current Year} - \text{Birth Year} - \left(\text{if } \text{Current Month/Day} < \text{Birth Month/Day} \text{ then } 1 \text{ else } 0\right)$$
2. **Boundary Conditions & Transitions:**
   - **User Age $< 18.0$ Years:** System classifies user as `MINOR`. Protected student safeguards are automatically triggered. Full commercial project creation is blocked.
   - **Exact 18th Birthday:** On the exact date of majority, the student transitions to adult status; guardian consent requirements cease to block operational workflows.
   - **Missing Date of Birth:** If a student account lacks a verified DOB, the system defaults to safe mode (`AGE_UNVERIFIED`), enforcing conservative safeguard boundaries.

---

## 3. Guardian Consent Lifecycle & State Machine

Minor students cannot independently consent to platform processing without guardian declaration. The declaration progresses through six defined states in `legal_guardian_consents`:

```
[DECLARATION_SUBMITTED]
          │
          ▼
[PENDING_VERIFICATION] (Assigned to Studio Admin queue)
     │            │
     ▼            ▼
[VERIFIED]    [REJECTED] (Invalid contact info or unconfirmed guardian)
     │
     ├──▶ [WITHDRAWN] (Guardian exercises right to withdraw consent)
     │
     ▼
[EXPIRED] (Annual re-affirmation required if student remains under 18)
```

### 3.1 Declaration Submission Fields
- Guardian Full Legal Name
- Guardian Relationship (`PARENT` or `LEGAL_GUARDIAN`)
- Guardian Primary Mobile Number
- Guardian Monitored Email Address
- Affirmative Statutory Declaration Checkbox under DPDP Act 2023 Sec 9

---

## 4. Regulatory Realism & Truth in Verification Capabilities

1. **Absence of Central Government DPDP Rules:**
   - As of the audit date, the Central Government has not finalized or notified the subordinate rules under Section 9(1) of the DPDP Act prescribing specific digital verification mechanisms (such as Aadhaar tokenization or DigiLocker integration).
2. **Transparent Operational Truth:**
   - **Truthful Finding:** ARCHI DRAFT operates an **affirmative parental declaration** workflow coupled with manual administrative review and out-of-band communication (email/phone verification).
   - The platform **does not** falsely claim automated government-backed biometric or DigiLocker verification, ensuring truth in advertising and regulatory transparency.

---

## 5. Prohibited Activities Enforcement (DPDP Sec 9(2)-(3))

ARCHI DRAFT's codebase was audited to verify compliance with statutory prohibitions on children's data:

| Statutory Prohibition | Codebase Verification | Audit Finding |
| :--- | :--- | :--- |
| **No Tracking or Behavioral Monitoring** | Codebase contains zero commercial ad trackers, zero third-party marketing SDKs, and zero behavioral telemetry scripts. | **STRICTLY ENFORCED** |
| **No Targeted Advertising** | The application delivers vocational training curriculum without displaying any advertisements. | **STRICTLY ENFORCED** |
| **No Detrimental Processing** | Processing is limited to lesson delivery, practical drafting assignments, and academic evaluation. | **STRICTLY ENFORCED** |

---

## 6. Automated Test Evidence

Automated suites in `test/canonical_legal_system_phase2.test.mjs`, `apps/admin-web/test/`, and `test/features/legal/`:

- `✔ GuardianConsent model correctly parses under-18 parental declaration` (Passed)
- `✔ Under-18 student dashboard renders Guardian Verification status banner` (Passed)
- `✔ Admin can approve or reject guardian consent in Compliance Center` (Passed)
- `✔ Student age calculation accurately handles leap years and birthday boundaries` (Passed)

