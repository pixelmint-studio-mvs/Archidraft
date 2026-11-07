# ARCHI DRAFT — User Account Deletion & Right to Erasure Guide
**Operating Brand:** DRAUGHTSMAN STUDIO  
**Legal Proprietor:** MOHAMMED MOSIN S  
**Product:** ARCHI DRAFT  
**Phase:** 3 of 9 (Flutter Legal Center, Onboarding Consent & User Privacy Controls)  
**Date:** November 2026  
**Status:** Completed & Tested

---

## 1. Statutory Context & Principles

Under Section 12(3) of India's **Digital Personal Data Protection Act, 2023 (DPDP Act)**, a Data Principal has the right to the erasure of their personal data unless retention is necessary for the specified purpose or for compliance with any law.

In an architectural, civil drafting, and engineering platform, balancing this right requires reconciling three competing considerations:
1. **The User's Right to be Forgotten:** Removal of personally identifiable information (PII), profile metadata, authentication credentials, and personal contact vectors.
2. **Collaborative Project Integrity & Multi-Party CAD Assets:** Drawings produced for third-party clients or consulting engineers cannot be unilaterally obliterated without breaching contractual commitments and the intellectual property rights of collaborative project partners.
3. **Statutory Audit & Tax Obligations:**
   - **CERT-In Direction No. 20(3)/2022:** Minimum **180 days** retention of access and security audit logs within Indian jurisdiction.
   - **Section 44AA of the Income-tax Act, 1961:** **8 financial years** retention for financial invoices, transaction records, and tax-relevant documentation.

---

## 2. The 30-Day Grace Period Architecture

To prevent accidental, impulsive, or malicious account deletion:
- When a user submits an account deletion request, the backend assigns the request a status of `PENDING` and calculates a scheduled purge timestamp exactly **30 calendar days** into the future (`scheduled_purge_at`).
- During this 30-day window, the user retains the statutory right to **cancel** the deletion request at any time directly through the Flutter Legal Center.
- If cancelled, the request transitions to `CANCELLED`, the pending purge job is aborted, and normal account access is restored.

```
[User Submits Request]
         │
         ▼
[Status: PENDING] ─── (Within 30 Days) ───► [User Clicks "Cancel Deletion"]
         │                                                │
         │                                                ▼
         │ (30 Days Elapse)                      [Status: CANCELLED]
         ▼                                        (Account Restored)
[Scheduled Purge Execution]
         │
         ├── Anonymize User Profile (Name, Phone, Address -> Redacted)
         ├── Revoke Firebase Authentication Token / Disable Auth UID
         ├── Archive Financial Records (Retain 8 yrs per IT Act)
         ├── Preserve Collaborative CAD Drawings with Author Hash
         └── [Status: PROCESSED]
```

---

## 3. Flutter Presentation & User Confirmation Flow

The deletion flow is encapsulated in `lib/src/features/legal/presentation/widgets/account_deletion_dialog.dart` and integrated into Section 4 of `LegalCenterScreen`:

### 3.1 Consequence Disclosure
The dialog first presents an explicit, transparent explanation:
- **Personal Profile Data:** Name, phone number, address, and login credentials will be permanently erased or anonymized upon expiration of the grace period.
- **Project & CAD Assets:** Completed CAD drawings submitted to collaborative projects will be preserved to maintain project structural integrity, with your personal identification detached.
- **Financial & Tax Records:** Invoices and payment logs will be retained for 8 financial years as mandated by Indian tax law.
- **30-Day Cancellation Grace Period:** The account can be reinstated anytime within 30 calendar days.

### 3.2 Affirmative Safeguards
- **Reason Selection / Input:** User may optionally provide feedback or reason for departure.
- **Explicit Typing Confirmation:** The user must explicitly type the uppercase word **`DELETE`** into a verification text field before the final deletion button activates.

### 3.3 Active Deletion Banner & Instant Cancellation
When an account deletion request is active:
- A prominent alert banner appears in the Legal Center's **Account Deletion** section:
  > **Account Deletion Scheduled**  
  > *Your deletion request is currently pending. Scheduled purge date: [Date]. You may cancel this request anytime before the scheduled date.*
- Clicking the **"Cancel Deletion Request"** button invokes `LegalRepository.cancelAccountDeletion()`, invalidates the active request, shows a success notification, and refreshes the Legal Center state.
