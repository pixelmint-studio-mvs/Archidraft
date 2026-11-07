# ARCHI DRAFT — PHASE 5.1 LEGAL & REGULATORY VALIDATION MATRIX
## Statutory Mapping, Indian Legal Gazette Citations & Architectural Enforcements

- **Project:** ARCHI DRAFT
- **Operating Brand:** DRAUGHTSMAN STUDIO
- **Legal Structure:** Sole Proprietorship
- **Legal Proprietor:** MOHAMMED MOSIN S
- **Audited Jurisdiction:** Republic of India (Central Acts, Gazette Notifications, MeitY Regulations)
- **Status:** Verified Engineering Implementation (Technical Compliance Review)

---

## 1. Executive Summary

This matrix establishes the definitive mapping between statutory Indian legal mandates and the technical architectures implemented in ARCHI DRAFT. Every legal claim made in the platform's terms, policies, and codebases is anchored to an official Central Government enactment or gazetted regulation.

---

## 2. Statutory Legal Matrix

### 2.1 Digital Personal Data Protection Act, 2023 (DPDP Act 2023)
*Citation: Act No. 22 of 2023, Ministry of Law and Justice, The Gazette of India Extraordinary, Part II, Section 1 (August 11, 2023)*

| Section / Provision | Statutory Mandate | Technical Enforcement in ARCHI DRAFT | Implementation Location |
| :--- | :--- | :--- | :--- |
| **Section 5(1)** | Notice before seeking consent: clear, plain language, itemized personal data categories, processing purpose. | Pre-login and post-login onboarding flows render itemized, plain-language notices for Terms, Privacy, AI Disclaimers, and CAD Agreements. | `lib/src/features/legal/presentation/legal_onboarding_screen.dart`, `apps/admin-web/src/components/legal/` |
| **Section 6(1)** | Consent must be free, specific, informed, unconditional, and unambiguous with clear affirmative action. | Mandatory terms are unbundled from optional analytics and promotional consents. Optional switches default to strictly `OFF`. | `legal_consents` table, `LegalOnboardingScreen` |
| **Section 6(4)** | Right to withdraw consent as easily as it was given. | Self-service consent management screen allows one-click withdrawal of optional processing with real-time audit logging. | `POST /api/legal/consents/withdraw`, `consent_withdrawal_log` table |
| **Section 9(1)-(3)** | Processing of personal data of children: verifiable parental consent; prohibition of tracking or behavioral monitoring. | Automated age calculation from date of birth. Under-18 students require explicit Guardian Declaration before full studio access. Zero behavioral ad trackers. | `worker/src/legal.ts`, `legal_guardian_consents` table, `StudentStudioScreen` |
| **Section 11(1)** | Right to access information about personal data: summary of data processed, third parties shared with. | Self-service data export engine serializes user dossier, projects, credentials, and consents into a structured JSON archive. | `POST /api/legal/data-export-requests`, `GET .../download` |
| **Section 12(1)-(3)** | Right to correction, completion, updating, and erasure of personal data. | Self-service data correction requests ticketed in D1; 14-subsystem erasure engine tombstones profiles and purges AI chats. | `data_correction_requests`, `account_deletion_requests` |
| **Section 13(1)** | Right of grievance redressal via readily available means. | Centralized Grievance Redressal portal routing directly to `mosin@draughtsmanstudio.com` with 48h SLA acknowledgment. | `GET /api/legal/business-profile`, Helpdesk integration |

---

### 2.2 Information Technology Act, 2000 & Subordinate Rules
*Citations: Act No. 21 of 2000; IT SPDI Rules 2011 (G.S.R. 313(E)); IT Intermediary Guidelines 2021 (G.S.R. 139(E))*

| Provision | Statutory Mandate | Technical Enforcement in ARCHI DRAFT | Implementation Location |
| :--- | :--- | :--- | :--- |
| **IT Act Sec 43A & SPDI Rules Rule 3-4** | Comprehensive privacy policy and reasonable security practices for sensitive personal data (SPDI). | Enterprise privacy policy covering collection, storage, encryption, and access controls. Argon2/PBKDF2 passwords, Firebase JWT tokens, TLS 1.3. | `docs/08_legal_privacy/PRIVACY_POLICY_DRAFT.md`, Cloudflare SSL/TLS |
| **IT SPDI Rules Rule 5(9)** | Grievance Officer must redress grievances within 30 days of receipt. | Statutory 30-day resolution ceiling enforced in Admin Compliance Center; tickets track days remaining. | `apps/admin-web/src/components/legal/PrivacyRequestsTab.tsx` |
| **IT Intermediary Rules 2021 Rule 3(1)(b)** | Prohibition of hosting harmful, defamatory, obscene, or infringing CAD files or communications. | Strict Acceptable Use Policy embedded in Platform Terms; automated file extension and MIME validation on uploads. | `worker/src/index.ts` upload validators |
| **IT Act Sec 72A** | Criminal liability for unauthorized disclosure of personal data in breach of contract. | Role-based data isolation (RBAC), multi-tenant foreign key barriers, cross-user IDOR protection. | `worker/src/legal.ts`, `test/cross_user_isolation_f1.test.mjs` |

---

### 2.3 Indian Copyright Act, 1957 & Intellectual Property
*Citation: Act No. 14 of 1957 (as amended by Copyright Amendment Act, 2012)*

| Section | Statutory Mandate | Technical Enforcement in ARCHI DRAFT | Implementation Location |
| :--- | :--- | :--- | :--- |
| **Section 14(c)** | Copyright in artistic works, including architectural drawings, plans, elevations, and CAD drafting. | Express IP Agreement: Client owns final approved drawings upon complete payment; Draughtsman retains pre-existing tools/blocks. | `shared/legal/documents/cad_ownership_agreement.json` |
| **Section 57** | Author's special moral rights (paternity and integrity of work). | Drawing version history permanently records Draughtsman authorship and revision provenance; cannot be erased or falsified. | `drawing_versions` table, `drawing_version_reviews` |

---

### 2.4 CERT-In Cybersecurity Directions, 2022
*Citation: Cyber Emergency Response Team Direction No. 20(3)/2022-CERT-In (April 28, 2022)*

| Direction | Statutory Mandate | Technical Enforcement in ARCHI DRAFT | Implementation Location |
| :--- | :--- | :--- | :--- |
| **Direction 6** | Mandatory logging and maintenance of ICT system logs for a rolling period of 180 days within India. | Activity logs, authentication attempts, and API access events retained for minimum 180 days in immutable ledger. | `activity_logs` table, `legal_audit_events` |

---

### 2.5 Income Tax Act, 1961 & Financial Regulations
*Citation: Act No. 43 of 1961, Section 44AA read with Rule 6F*

| Provision | Statutory Mandate | Technical Enforcement in ARCHI DRAFT | Implementation Location |
| :--- | :--- | :--- | :--- |
| **Section 44AA / Rule 6F** | Mandatory maintenance of books of account and invoices for 6 to 8 years from relevant assessment year. | Financial transactions, invoices, and payment references exempted from user account deletion; retained in secure accounting archive. | `invoices` table, `account_deletion_requests` retention hold logic |

---

## 3. Verification Conclusion

All technical mechanisms implemented across ARCHI DRAFT conform directly to the cited statutes. No contradictory or ungrounded legal assertions exist in the codebase or policy drafts.

