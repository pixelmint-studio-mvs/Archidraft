# ARCHI DRAFT — Legal Document Lifecycle & Publication Safeguards Guide
**Operating Brand:** DRAUGHTSMAN STUDIO  
**Legal Proprietor:** MOHAMMED MOSIN S  
**Product:** ARCHI DRAFT  
**Phase:** 4 of 9 (Next.js Admin Legal Compliance Dashboard & Audit Center)  
**Date:** November 2026  
**Status:** Completed & Tested

---

## 1. Overview & Policy Governance Principles

To prevent unauthorized, impulsive, or erroneous changes to contractual agreements and statutory data privacy notices, ARCHI DRAFT enforces a strict, auditable document lifecycle across all legal instruments.

Under no circumstances may an administrator silently overwrite an active legal policy. Every amendment requires creating an isolated version draft, conducting review, and executing an explicit, atomic publication promotion.

---

## 2. The Seven Canonical Platform Instruments

The platform architecture governs seven (7) authoritative legal documents registered in `shared/legal/registry/document_registry.json`:

| Identifier | Instrument Name | Requirement | Governing Legal Framework |
| :--- | :--- | :--- | :--- |
| `TERMS_AND_CONDITIONS` | Platform Terms and Conditions | Mandatory | Indian Contract Act 1872, IT Act 2000 |
| `PRIVACY_POLICY` | Privacy Policy & Data Protection Notice | Mandatory | Digital Personal Data Protection Act 2023, SPDI Rules 2011, CERT-In |
| `AI_USAGE_DISCLAIMER` | Pixmint Bot & AI Usage Disclaimer | Mandatory | IT Act 2000, Consumer Protection Act 2019 |
| `ENGINEERING_DISCLAIMER`| Professional Engineering Services Disclaimer | Mandatory | Architects Act 1972, NBC 2016, Municipal Bye-Laws |
| `CAD_OWNERSHIP_FRAMEWORK`| CAD Drawing Ownership & IP Framework | Mandatory | Indian Copyright Act 1957, Patents Act 1970 |
| `REVISION_POLICY` | Project Revision & Correction Policy | Optional / Operational | Indian Contract Act 1872 |
| `CANCELLATION_REFUND_POLICY`| Subscription, Cancellation & Refund Policy | Optional / Operational | Consumer Protection (E-Commerce) Rules 2020 |

---

## 3. The Lifecycle State Machine

```
   [Create Draft]
         │
         ▼
     ┌───────┐        Review & Legal
     │ DRAFT │ ───────────────────────────► ┌──────────────┐
     └───────┘                              │ UNDER_REVIEW │
         │                                  └──────────────┘
         │ (Passes Audit)                           │
         ▼                                          │
    ┌──────────┐                                    │
    │ APPROVED │ ◄──────────────────────────────────┘
    └──────────┘
         │
         │ Explicit Admin Confirmation
         │ POST /api/admin/legal/documents/:id/publish
         ▼
   ┌───────────┐ (Atomic Batch Promotion)
   │ EFFECTIVE │ ◄────────────────── Target Document Promoted
   └───────────┘
         ▲
         │ (Simultaneous Atomic Demotion)
         ▼
   ┌────────────┐
   │ SUPERSEDED │ ◄────────────────── Prior Effective Document Demoted
   └────────────┘
         │
         ▼ (Optional Long-Term Storage)
   ┌──────────┐
   │ ARCHIVED │
   └──────────┘
```

### 3.1 State Definitions
1. `DRAFT`: A newly created version draft. Invisible to end-users and unbundled consent prompts.
2. `UNDER_REVIEW` / `PENDING_LEGAL_REVIEW`: Draft submitted for qualified legal and business review.
3. `APPROVED`: Draft reviewed and cleared for potential publication.
4. `EFFECTIVE` / `PUBLISHED`: The currently active, legally binding document version served to users across the Flutter app and web portals.
5. `SUPERSEDED`: A previously effective document version that has been replaced by a newer effective version. Preserved permanently in D1 for historical dispute resolution and consent audit.
6. `ARCHIVED`: Obsolete policy documents retired from operational referencing.

---

## 4. Publication Safeguards & Atomic Promotion

### 4.1 Safeguard Requirements
- **No Automatic Publication:** Document drafts are never automatically promoted upon creation.
- **No In-Place Edits:** An existing `EFFECTIVE` document cannot be edited. A new version must be drafted.
- **Explicit Modal Confirmation:** The admin must review the document category, version, and confirmation warning in `PublishDocumentModal`.

### 4.2 Backend Atomic Transaction (`worker/src/legal.ts`)
When an administrator publishes a document via `POST /api/admin/legal/documents/:id/publish`, the Cloudflare Worker executes an atomic D1 batch transaction:
```typescript
const batch = [
  // 1. Supersede current effective version of same type and locale
  db.prepare(`
    UPDATE legal_documents 
    SET status = 'SUPERSEDED', updated_at = CURRENT_TIMESTAMP 
    WHERE document_type = ? AND locale = ? AND status = 'EFFECTIVE' AND id != ?
  `).bind(targetDoc.document_type, targetDoc.locale, docId),

  // 2. Promote target document to EFFECTIVE
  db.prepare(`
    UPDATE legal_documents 
    SET status = 'EFFECTIVE', published_at = CURRENT_TIMESTAMP, published_by = ?, updated_at = CURRENT_TIMESTAMP 
    WHERE id = ?
  `).bind(uid, docId)
];

await db.batch(batch);
```
This guarantees that at any given moment, exactly **one** document per `(document_type, locale)` pair is `EFFECTIVE`.

---

## 5. Versioning Rules (Semantic Versioning)

- **MAJOR (X.0.0):** Material changes altering legal rights, liability limits, dispute resolution jurisdiction, or introduction of new mandatory consents. Requires prompt re-acceptance from users upon login.
- **MINOR (1.X.0):** Workflow refinements, addition of new operational roles or features (e.g., student studio enhancements).
- **PATCH (1.0.X):** Typographical fixes, formatting corrections, or contact email updates without substantive legal impact.
