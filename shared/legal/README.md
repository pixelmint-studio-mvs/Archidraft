# ARCHI DRAFT | CANONICAL LEGAL SYSTEM ARCHITECTURE

**Operating Brand:** DRAUGHTSMAN STUDIO  
**Legal Proprietor:** MOHAMMED MOSIN S  
**Business Structure:** Sole Proprietorship  
**Product:** ARCHI DRAFT  
**Version:** 1.0.0  
**Target Jurisdiction:** Republic of India  

---

## 1. PURPOSE & OVERVIEW

The `shared/legal/` directory serves as the **single authoritative source of truth** for all business identity data, versioned legal documents, disclaimer policies, and compliance verification statuses across the Archi Draft platform ecosystem:
- **Cloudflare Workers Backend (`worker/`):** Consumes canonical legal types, mandatory terms assertions, and D1 database seeding definitions.
- **Next.js Admin Web Portal (`apps/admin-web/`):** Consumes canonical document metadata, business identity, and compliance verification status.
- **Flutter Multiplatform Application (`lib/`):** Consumes canonical Dart adapters, business configuration constants, and bundled policy text for offline resilience.

---

## 2. DIRECTORY STRUCTURE

```
shared/legal/
├── README.md                      # Architecture and policy management guide
├── validator.js                   # Automated schema, document, and publication safeguard validator
├── business/
│   ├── business_profile.json      # Confirmed business details and explicit pending fields
│   └── verification_status.json   # Granular verification registry with publication blocker tracking
├── schemas/
│   ├── business_profile.schema.json   # JSON schema for business identity
│   ├── legal_document.schema.json     # JSON schema for policy documents
│   └── document_registry.schema.json  # JSON schema for canonical document registry
├── registry/
│   ├── document_registry.json     # Registry of all 7 canonical legal documents
│   └── version_manifest.json      # Active version manifest for quick runtime lookup
├── documents/                     # Versioned policy markdown source files
│   ├── terms_and_conditions/
│   │   └── v1.0.0.md              # Platform Terms and Conditions
│   ├── privacy_policy/
│   │   └── v1.0.0.md              # Privacy Policy & Data Protection Notice
│   ├── ai_usage_disclaimer/
│   │   └── v1.0.0.md              # Pixmint Bot & AI Usage Disclaimer
│   ├── engineering_disclaimer/
│   │   └── v1.0.0.md              # Architectural & Engineering Professional Disclaimer
│   ├── cad_ownership_framework/
│   │   └── v1.0.0.md              # CAD Drawing Ownership & IP Framework
│   ├── revision_policy/
│   │   └── v1.0.0.md              # Project Revision & Correction Policy (2 rounds)
│   └── cancellation_refund_policy/
│       └── v1.0.0.md              # Subscription, Cancellation and Refund Policy
└── adapters/                      # Type-safe cross-platform consumption adapters
    ├── typescript/                # For Cloudflare Worker and Next.js Admin Web
    │   ├── index.ts
    │   ├── business_profile.ts
    │   └── legal_documents.ts
    └── flutter/                   # For Flutter Dart application
        ├── business_profile.dart
        └── legal_documents.dart
```

---

## 3. BUSINESS IDENTITY & VERIFICATION PROTOCOL

### Confirmed Information
- **Business Structure:** Sole Proprietorship
- **Legal Proprietor:** MOHAMMED MOSIN S
- **Operating Brand:** DRAUGHTSMAN STUDIO
- **Product Name:** ARCHI DRAFT
- **Websites:** `https://archidraft.draughtsmanstudio.com` | `https://draughtsmanstudio.com`
- **Grievance Contact:** `mosin@draughtsmanstudio.com`
- **Customer Support & Privacy Contact:** `support@draughtsmanstudio.com`
- **Legal Identity Representation:** `DRAUGHTSMAN STUDIO — a sole proprietorship operated by MOHAMMED MOSIN S.`

### Explicitly Unverified Fields (Marked `PENDING_VERIFICATION`)
1. **Physical Business Address:** Marked `PENDING_VERIFICATION`. Under Consumer Protection (E-Commerce) Rules, 2020 and IT Intermediary Rules, an official establishment address is required for production e-commerce. Website URLs must never be published or substituted for a physical address.
2. **Grievance Officer Formal Appointment:** Marked `PENDING_VERIFICATION`. Under IT SPDI Rules 2011 Rule 5(9) and DPDP Act 2023 Sec 13, the proprietor name must not automatically be assumed as the appointed officer without explicit business appointment.

---

## 4. DOCUMENT LIFECYCLE & STATUSES

Every document transitions through defined lifecycle states:
1. `DRAFT`: Initial authoring phase; not visible in public production APIs.
2. `PENDING_BUSINESS_APPROVAL`: Awaiting formal sign-off from proprietor on commercial thresholds (e.g. revision rounds, refund timelines).
3. `PENDING_LEGAL_REVIEW`: Awaiting formal legal review by qualified Indian legal counsel.
4. `EFFECTIVE`: Published, legally operative version enforced on active users.
5. `SUPERSEDED`: Replaced by a newer effective version; preserved for immutable audit logs.
6. `ARCHIVED`: Obsolete policy preserved for statutory record-keeping.

---

## 5. MANDATORY PUBLICATION SAFEGUARDS

The automated validation runtime (`shared/legal/validator.js`) enforces strict publication safeguards:
> **RULE:** No legal document may transition to status `EFFECTIVE` in a production environment if any critical business field (`physicalAddress`, `grievanceOfficerFormalAppointment`) remains in `PENDING_VERIFICATION` status.

Violations of this rule cause `validator.js` to exit with an error code, preventing accidental deployment of legally defective policies.

---

## 6. VALIDATION & TESTING INSTRUCTIONS

To validate the canonical legal repository:
```bash
node shared/legal/validator.js
```

To run TypeScript compilation checks:
```bash
cd apps/admin-web && npm test
cd worker && npx tsc --noEmit
```

To run Flutter static analysis:
```bash
flutter analyze --no-fatal-infos lib/src/features/legal/
```

