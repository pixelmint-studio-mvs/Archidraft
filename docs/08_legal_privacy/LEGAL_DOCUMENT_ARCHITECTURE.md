# ARCHI DRAFT | CANONICAL LEGAL DOCUMENT ARCHITECTURE

**System:** ARCHI DRAFT Legal & Compliance Infrastructure  
**Operating Brand:** DRAUGHTSMAN STUDIO  
**Legal Proprietor:** MOHAMMED MOSIN S  
**Business Structure:** Sole Proprietorship  
**Phase:** 1 of 9 — Centralized Business Configuration & Legal Document System  
**Date:** November 2026  
**Status:** Approved Architecture Implementation  

---

## 1. EXECUTIVE SUMMARY & DESIGN PHILOSOPHY

The ARCHI DRAFT platform operates across a distributed multiplatform ecosystem comprising:
1. **Flutter Web & Mobile Application (`lib/`):** Primary user client for Consulting Engineers, Professional Draughtsmen, and Vocational Students.
2. **Next.js Admin Web Portal (`apps/admin-web/`):** Studio administrative control center for project assignments, user compliance verification, and operations.
3. **Cloudflare Workers / Hono Backend (`worker/`):** Edge API and database runtime enforcing authentication, mandatory terms gate assertions, and consent recording.
4. **Cloudflare D1 Relational Database (`archi-draft-db`):** Relational storage maintaining versioned policy catalogs (`legal_documents`), immutable consent event logs (`legal_consent_events`), active user consent state (`user_consent_state`), and data privacy tickets (`privacy_requests`).
5. **Cloudflare R2 Object Storage:** Encrypted object storage for CAD drawing files (`.dwg`, `.dxf`, `.pdf`), site images, and audio notes.

Prior to Phase 1, business identification details and legal documents were fragmented across draft markdown files, hardcoded fallback strings, and provisional placeholders. Phase 1 establishes a **single canonical source of truth** in `shared/legal/` coupled with compile-time type-safe adapters and automated publication safeguards.

---

## 2. ARCHITECTURAL TOPOLOGY

```
                                +-----------------------------------+
                                |           shared/legal/           |
                                |   Canonical Single Source of Truth |
                                +-----------------+-----------------+
                                                  |
                     +----------------------------+----------------------------+
                     |                                                         |
                     v                                                         v
         +-----------------------+                                 +-----------------------+
         |   schemas/ & JSON/    |                                 |      documents/       |
         |  business_profile.json|                                 |   7 Canonical SemVer  |
         |  document_registry.js |                                 |     Markdown Files    |
         |  version_manifest.json|                                 +-----------+-----------+
         +-----------+-----------+                                             |
                     |                                                         |
         +-----------+-----------------------------+                           |
         |                                         |                           |
         v                                         v                           v
+-------------------+                     +-------------------+       +-------------------+
|    adapters/ts/   |                     |  adapters/flutter |       |   validator.js    |
| Typed TS access   |                     | Typed Dart access |       | CI/CD & Safeguard |
| for Worker & Admin|                     | for Flutter App   |       | Enforcement       |
+---------+---------+                     +---------+---------+       +-------------------+
          |                                         |
          +-------------------+                     |
          |                   |                     |
          v                   v                     v
+-------------------+ +-------------------+ +-------------------+
|      worker/      | |  apps/admin-web/  | |       lib/        |
| Cloudflare Worker | |  Next.js Admin    | |  Flutter Client   |
| Legal Gates & D1  | |  Compliance Hub   | |  Legal Center UI  |
+-------------------+ +-------------------+ +-------------------+
```

---

## 3. CANONICAL SUBSYSTEMS & REPOSITORY LAYOUT

### 3.1. Schemas (`shared/legal/schemas/`)
- `business_profile.schema.json`: Formal JSON Schema defining the structure of legal identity, confirmed contact channels, physical address status, and grievance officer appointment state.
- `legal_document.schema.json`: Schema defining individual document metadata, SemVer strings, audience roles, mandatory flags, and statutory references.
- `document_registry.schema.json`: Schema governing the canonical document manifest and version catalogs.

### 3.2. Business Identity Configuration (`shared/legal/business/`)
- `business_profile.json`: Contains authoritative business data.
  - Structure: `Sole Proprietorship`
  - Proprietor: `MOHAMMED MOSIN S`
  - Brand: `DRAUGHTSMAN STUDIO`
  - Product: `ARCHI DRAFT`
  - Contacts: `mosin@draughtsmanstudio.com` (Grievance), `support@draughtsmanstudio.com` (Support & Privacy)
  - Websites: `https://archidraft.draughtsmanstudio.com`, `https://draughtsmanstudio.com`
  - Address: `PENDING_VERIFICATION`
  - Grievance Officer: `PENDING_VERIFICATION`
- `verification_status.json`: Itemizes every individual field with verification status (`CONFIRMED` vs `PENDING_VERIFICATION`), verifying authority, last audited timestamp, and whether the field represents a blocking requirement for production publication.

### 3.3. Document Registry & Version Manifest (`shared/legal/registry/`)
- `document_registry.json`: Exhaustive metadata catalog for all seven canonical policies:
  1. `TERMS_AND_CONDITIONS`
  2. `PRIVACY_POLICY`
  3. `AI_USAGE_DISCLAIMER`
  4. `ENGINEERING_DISCLAIMER`
  5. `CAD_OWNERSHIP_FRAMEWORK`
  6. `REVISION_POLICY`
  7. `CANCELLATION_REFUND_POLICY`
- `version_manifest.json`: Lightweight active version registry optimized for runtime API lookups and caching headers.

### 3.4. Versioned Policy Documents (`shared/legal/documents/`)
Each document is authored in standard Markdown with explicit document status, SemVer headers, statutory citations, and business identification.
- `terms_and_conditions/v1.0.0.md`
- `privacy_policy/v1.0.0.md`
- `ai_usage_disclaimer/v1.0.0.md`
- `engineering_disclaimer/v1.0.0.md`
- `cad_ownership_framework/v1.0.0.md`
- `revision_policy/v1.0.0.md`
- `cancellation_refund_policy/v1.0.0.md`

---

## 4. CROSS-PLATFORM CONSUMPTION PATTERNS

Because the repository employs different programming runtimes (TypeScript on Node/Cloudflare and Dart on Flutter), canonical legal data is exposed through type-safe language adapters:

### 4.1. TypeScript Consumption (`shared/legal/adapters/typescript/`)
- `business_profile.ts`: Exports typed interfaces (`BusinessProfile`, `PhysicalAddress`, `GrievanceOfficer`) and the constant `CANONICAL_BUSINESS_PROFILE`.
- `legal_documents.ts`: Exports `CanonicalLegalDocument`, `VersionManifest`, helper lookup functions (`getCanonicalDocument`, `getMandatoryDocuments`), and the active registry.
- Consumed directly by Cloudflare Worker services and Next.js Admin Web pages via TypeScript module imports.

### 4.2. Flutter Dart Consumption (`shared/legal/adapters/flutter/` & `lib/src/features/legal/data/`)
- `CanonicalBusinessProfile`: Type-safe class exposing canonical business details and verification constants.
- `CanonicalLegalRegistry`: Exposes strongly-typed metadata for all seven canonical documents.
- `AuthoritativePolicyContent`: Provides bundled compile-time markdown content constants (`kAuthoritativeTermsAndConditionsContent`, `kAuthoritativePrivacyPolicyContent`, etc.) ensuring that Flutter clients can render policies offline, in airplane mode, or during server maintenance without broken screens.

---

## 5. AUTOMATED PUBLICATION SAFEGUARDS

A core vulnerability in legal systems is the accidental publication of draft or unverified policies to live users. Phase 1 introduces `shared/legal/validator.js`, which enforces mandatory publication gates:

```
[VALIDATION CHECK: STATUS == 'EFFECTIVE']
                 |
                 v
   Is physicalAddress.status == 'VERIFIED'?
                 |
        +--------+--------+
        | NO              | YES
        v                 v
[THROW HARD ERROR]   Is grievanceOfficer.status == 'APPOINTED'?
Publication Blocked              |
                         +-------+-------+
                         | NO            | YES
                         v               v
                [THROW HARD ERROR]  [ALLOW PUBLICATION]
                Publication Blocked
```

1. **Address Requirement:** Under the Consumer Protection (E-Commerce) Rules, 2020 and Information Technology Intermediary Rules, commercial platforms must publish a physical establishment address. Website URLs cannot serve as addresses.
2. **Grievance Officer Requirement:** The proprietor name cannot automatically be assumed as the appointed Grievance Officer without an explicit business resolution.
3. **Automated Blocking:** If any document in `document_registry.json` is set to `status: "EFFECTIVE"` while either prerequisite is in `PENDING_VERIFICATION`, `validator.js` exits with error code 1 and aborts the CI/CD build.

---

## 6. AUDIT & CONSENT RE-ACCEPTANCE MECHANICS

When a document version is updated (e.g. from `1.0.0` to `1.1.0`):
1. A new markdown file is authored in `shared/legal/documents/<type>/v1.1.0.md`.
2. `document_registry.json` and `version_manifest.json` are updated with the new version and change summary.
3. Upon approval and database synchronization in D1, the backend legal gate (`assertTermsAccepted` in `worker/src/legal.ts`) detects that caller's `user_consent_state.accepted_version` differs from the effective version.
4. The worker automatically responds with HTTP 403 `TERMS_ACCEPTANCE_REQUIRED` and supplies the new version string.
5. The Flutter client intercepts this response and presents the Legal Onboarding / Re-acceptance modal to the user.
6. Upon affirmative acceptance, an immutable event is written to `legal_consent_events` with the client's SHA-256 hashed IP address, user agent, and timestamp, and `user_consent_state` is updated in a single atomic transaction.

---

## 7. SUMMARY OF PHASE 1 DELIVERABLES

| Deliverable | Location | Status |
| :--- | :--- | :--- |
| **Business Schemas & JSON** | `shared/legal/schemas/`, `shared/legal/business/` | Completed & Verified |
| **Document Registry & Manifest** | `shared/legal/registry/` | Completed (7 Documents) |
| **7 Canonical Markdown Policies** | `shared/legal/documents/*/` | Completed & Sourced |
| **TypeScript Adapters** | `shared/legal/adapters/typescript/` | Completed & Type-checked |
| **Flutter Dart Adapters & Config** | `shared/legal/adapters/flutter/`, `lib/src/features/legal/data/` | Completed & Analyzed |
| **Automated Validator Script** | `shared/legal/validator.js` | Completed (0 Errors, 0 Warnings) |
| **Architecture Specification** | `docs/08_legal_privacy/LEGAL_DOCUMENT_ARCHITECTURE.md` | Completed |

