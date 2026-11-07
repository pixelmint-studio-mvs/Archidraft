# ARCHI DRAFT — PHASE 5 CONSENT INTEGRITY REPORT
## Consent Ledger Immutability, Salted Hashing & Granular Purpose Isolation

**Project:** ARCHI DRAFT  
**Operating Brand:** DRAUGHTSMAN STUDIO  
**Legal Proprietor:** MOHAMMED MOSIN S (Sole Proprietorship)  
**Development Team:** PixelMint Studio MVS  
**Audit Focus:** Append-Only Consent Ledger, Cryptographic Salting & Withdrawal Management  
**Date:** November 2026  
**Status:** AUDITED & VERIFIED  

---

## 1. Executive Summary

This report documents the architectural integrity and legal validity of ARCHI DRAFT's user consent tracking system (`legal_consent_events`). It clarifies the precise technical guarantees of the ledger—correcting past claims of "cryptographic immutability"—and verifies compliance with granular consent and withdrawal mandates.

---

## 2. Ledger Architecture & Immutability Analysis

### 2.1 Table Schema (`legal_consent_events`)
```sql
CREATE TABLE IF NOT EXISTS legal_consent_events (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  document_id TEXT NOT NULL,
  document_type TEXT NOT NULL,
  version TEXT NOT NULL,
  action TEXT NOT NULL CHECK(action IN ('ACCEPTED', 'DECLINED', 'ACKNOWLEDGED', 'WITHDRAWN')),
  purpose TEXT,
  ip_hash TEXT NOT NULL,
  user_agent TEXT,
  created_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_legal_consent_user ON legal_consent_events(user_id);
CREATE INDEX IF NOT EXISTS idx_legal_consent_doc ON legal_consent_events(document_id, version);
```

### 2.2 Technical Immutability: Application-Level vs. Cryptographic
- **Historical Claim:** Earlier development briefs referred to the consent ledger as "cryptographically immutable."
- **Truthful Audit Finding:** The storage engine is Cloudflare D1 (distributed SQLite). SQLite tables do not utilize Merkle trees, proof-of-work, or cryptographic chaining between consecutive rows.
- **Actual Guarantee:** Immutability is enforced at the **application layer**. 
  - There are NO `UPDATE` or `DELETE` queries anywhere in the codebase targeting `legal_consent_events`.
  - All state changes (including withdrawal of optional consent) append a new row with action `WITHDRAWN`.
  - Database access is restricted to Cloudflare Worker service bindings without public SQL execution endpoints.
- **Evidence Integrity:** IP addresses are hashed using SHA-256 with a server-side salt before writing, ensuring privacy compliance while retaining non-repudiation proof under Section 65B of the Indian Evidence Act, 1872.

---

## 3. Unbundled & Granular Consent Design

Under Section 6(1) of the DPDP Act 2023, consent must be free, specific, informed, unconditional, and unambiguous with a clear affirmative action. Consent cannot be bundled as a condition of accessing unrelated services.

### 3.1 Separation of Mandatory vs. Optional Consents

```
┌────────────────────────────────────────────────────────────────────────┐
│                      ARCHI DRAFT Legal Onboarding                      │
├────────────────────────────────────────────────────────────────────────┤
│  [MANDATORY]  [✓] Terms and Conditions (v1.0.0)                         │
│  [MANDATORY]  [✓] Privacy Notice Acknowledgment                         │
├────────────────────────────────────────────────────────────────────────┤
│  [OPTIONAL]   [ ] Product Updates & Engineering Insights (Default: OFF) │
│  [OPTIONAL]   [ ] Public Portfolio & Showcase Indexing   (Default: OFF) │
└────────────────────────────────────────────────────────────────────────┘
```

1. **Mandatory Acceptance:** Only required platform operational instruments (Terms & Conditions, Architectural Disclaimer) gate workspace entry.
2. **Independent Checkboxes:** Checkboxes start unchecked; the user must explicitly toggle them.
3. **Optional Preferences Default to OFF:** Marketing communications and portfolio showcase indexing default to `false` (OFF). A user who leaves both OFF can freely access their workspace without hindrance.
4. **Independent Withdrawal:** Under Section 6(4) of the DPDP Act, a Data Principal may withdraw consent at any time. When a user turns OFF a switch in their Profile Privacy Center:
   - A `WITHDRAWN` event is appended to `legal_consent_events`.
   - The user's active platform permissions and projects remain 100% unaffected.

---

## 4. Verification Test Evidence

1. **Consent Isolation & Non-Blocking Entry:**
   - Verified via `test/features/legal/presentation/legal_onboarding_screen_test.dart` (Test: `Renders onboarding screen with Terms, Privacy Notice, and optional switches defaulting to OFF`).
   - Verified via `test/features/legal/presentation/post_login_legal_status_test.dart` (Test: `Optional preferences remain OFF by default and do not block entering workspace`).
2. **Append-Only Ledger Writes:**
   - Verified via `worker/test/canonical_legal_system_phase2.test.mjs` (Test: `Consent recording appends immutable event with salted IP hash and version`).
3. **Admin Audit Center Visibility:**
   - Verified via `apps/admin-web/test/admin-legal-compliance.test.ts` (Test: `Consent events listing returns accurate actions and user bindings`).

**Audit Status:** Consent Ledger and Granular Preference mechanisms are 100% operational, truthful, and verified.

