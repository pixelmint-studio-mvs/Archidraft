# ARCHI DRAFT — BUSINESS DECISIONS AND OPEN QUESTIONS REGISTER
**DOCUMENT STATUS:** DRAFT — INTERNAL REQUIREMENTS REGISTER  
**PROJECT:** Archi Draft  
**PARENT BRAND:** Draughtsman Studio (https://www.draughtsmanstudio.com)  
**BUSINESS STRUCTURE:** Sole Proprietorship / Individual Business  
**TARGET MARKET:** India  
**DATE:** OCTOBER 2026 (QUALITY REVIEW REVISION)  
**DOCUMENT VERSION:** 1.2.0-DRAFT  

---

## 1. PURPOSE AND PRINCIPLES

This register formally records the business decisions, policy choices, operational unknowns, and legal-review requirements for Archi Draft.

In accordance with team directives:
1. **Zero Fabrication:** Unknown business details, company identifiers, addresses, and statutory deadlines must remain explicit placeholders.
2. **Explicit Labeling:** Every decision is categorized by its status: `CONFIRMED PENDING DETAILS`, `OPEN / PENDING SAFEGUARDS`, `NEEDS OWNER INPUT`, or `NEEDS LEGAL REVIEW`.
3. **Traceability:** Each item identifies its impact, dependencies, risk if unresolved, and responsible party.
4. **Statutory vs. Operational Distinction:** Clearly separates verified statutory obligations under Indian law from proposed, unapproved operational policies.

---

## 2. BUSINESS DECISIONS REGISTER

### ITEM-01: Legal Business Identity & Entity Structure
- **Decision:** **Confirmed as a Sole Proprietorship / Individual Business.**
- **Details:** The business operates as an individual proprietorship under the trade name/brand **Draughtsman Studio**, operating the application **Archi Draft**.
- **Why It Matters:** Under Indian law, a sole proprietorship has no separate legal personality distinct from its proprietor. Contracts, terms of service, and statutory filings are entered into by the individual proprietor doing business as (d/b/a) Draughtsman Studio. The proprietor ([PROPRIETOR FULL LEGAL NAME — TO BE CONFIRMED]) holds personal liability for business obligations and acts as the **Data Fiduciary** under the Digital Personal Data Protection Act, 2023 (DPDP Act).
- **Unconfirmed Information Required (Explicit Placeholders):**
  - Full Legal Name of the Sole Proprietor: `[PROPRIETOR FULL LEGAL NAME — TO BE CONFIRMED]`.
  - Registered / Principal Business Address in India: `[BUSINESS ADDRESS — TO BE CONFIRMED, INDIA]`.
  - Business Registration / Tax Identifiers (e.g., Udyam Registration Number, GSTIN, PAN-based trade registration): `[REGISTRATION / TAX DETAILS — TO BE CONFIRMED]`.
- **Responsible Party:** Business Owner / Founder.
- **Dependencies:** Required before publishing `PRIVACY_POLICY_DRAFT.md`, `TERMS_AND_CONDITIONS_DRAFT.md`, and `GRIEVANCE_AND_SUPPORT_POLICY.md`.
- **Risk If Unresolved:** Incomplete identification of the contracting party in Terms & Conditions and Privacy Policy.
- **Legal Review Required:** Yes.
- **Status:** `CONFIRMED PENDING DETAILS`

---

### ITEM-02: Designated Grievance Officer & Official Contact Channels
- **Decision:** **Not decided yet; awaiting confirmation.**
- **Why It Matters:** Rule 5(9) of the IT (SPDI) Rules, 2011 and Section 13 of the DPDP Act, 2023 mandate publishing the name, designation, and contact details of the Grievance Officer on the website/application.
- **Information Required (Pure Placeholders):**
  - Name of Grievance Officer: `[GRIEVANCE OFFICER NAME — TO BE CONFIRMED]`.
  - Official Designation / Title: `[OFFICIAL DESIGNATION — TO BE CONFIRMED]`.
  - Dedicated Grievance Email Address: `[GRIEVANCE EMAIL — TO BE CONFIRMED]`.
  - Physical Office / Postal Address for legal notices: `[POSTAL ADDRESS — TO BE CONFIRMED]`.
  - Dedicated General Support Email: `[SUPPORT EMAIL — TO BE CONFIRMED]`.
  - Dedicated Security Incident Reporting Email: `[SECURITY INCIDENT EMAIL — TO BE CONFIRMED]`.
- **Responsible Party:** Business Owner / Operations.
- **Dependencies:** Required for `GRIEVANCE_AND_SUPPORT_POLICY.md`, `PRIVACY_POLICY_DRAFT.md`, and in-app support links.
- **Risk If Unresolved:** Statutory non-compliance under IT Act Section 43A / SPDI Rules and DPDP Act penalties.
- **Legal Review Required:** Yes.
- **Status:** `NEEDS OWNER INPUT`

---

### ITEM-03: Student Age Policy & Child Privacy Safeguards
- **Decision:** **Younger students under 18 may be allowed, subject to business-owner decisions, applicable legal requirements, and appropriate safeguards.**
- **Context:** The founder has indicated that Archi Draft aims to accommodate vocational drafting, ITI, polytechnic, and junior drafting students who may be under the age of 18. However, allowing minors is an **unresolved business decision subject to establishing comprehensive technical, operational, and legal safeguards**.
- **Critical Legal Principle: Parental Consent Alone Does NOT Resolve Every Requirement:**
  Allowing minors introduces complex legal obligations under Indian law that go far beyond a simple parental consent checkbox:
  1. **Section 9(1) of DPDP Act (Verifiable Parental Consent):** The Data Fiduciary must obtain *verifiable* consent of the parent or lawful guardian. The mechanism must be reliable, auditable, and compliant with rules prescribed by the Central Government.
  2. **Section 9(2) of DPDP Act (Prohibition of Detrimental Processing):** Processing must not be undertaken if it is likely to cause any detrimental effect on the physical, mental, or moral well-being of a child.
  3. **Section 9(3) of DPDP Act (Prohibition of Tracking and Behavioral Monitoring):** The platform is strictly prohibited from tracking, profiling, or undertaking behavioral monitoring of children, or directing targeted advertising to children. Application telemetry, performance scoring algorithms, and session tracking must be audited to ensure zero unlawful profiling.
  4. **Indian Contract Act, 1872 (Incapacity of Minors):** Under Section 11 of the Indian Contract Act, minors are legally incompetent to contract. Contracts entered into by minors are *void ab initio* (*Mohori Bibee v. Dharmodas Ghose*). Therefore, the Terms & Conditions cannot be enforced directly against a minor; a parent or legal guardian must execute the agreement on behalf of the minor.
  5. **Guardianship Laws:** Identification of lawful guardians under the Hindu Minority and Guardianship Act, 1956 and the Guardians and Wards Act, 1890.
  6. **Data Minimization:** Extreme minimization of personal data collected from students under 18 (avoiding collecting personal residential addresses, personal phone numbers, or unnecessary identity documents).
- **Pending Actions Required Before Enabling Minor Registration:**
  - Formulate a formal child data protection specification.
  - Implement a reliable age-gate mechanism at registration.
  - Design a verifiable parental/guardian notification and consent workflow.
  - Obtain formal legal opinion from qualified Indian legal counsel confirming the child onboarding architecture complies with DPDP Act Section 9 and Contract Act requirements.
- **Responsible Party:** Business Owner + Qualified Indian Legal Counsel + Engineering Lead.
- **Dependencies:** Affects `register_screen.dart`, `provision_profile_screen.dart`, `app_router.dart`, and `TERMS_AND_CONDITIONS_DRAFT.md`.
- **Risk If Unresolved:** Severe statutory penalties under Section 33 of the DPDP Act (up to ₹200 Crores for breach of Section 9 obligations) and legally void contractual arrangements.
- **Legal Review Required:** **MANDATORY.**
- **Status:** `OPEN / PENDING SAFEGUARDS & LEGAL REVIEW`

---

### ITEM-04: Drawing Ownership, Derivative Revisions & Licensing
- **Decision:** **Not decided yet; requires business-owner and qualified legal review.**
- **Why It Matters:** Architectural and engineering drawings are artistic and technical works under the Indian Copyright Act, 1957. The allocation of rights between the client (who provides the brief), the platform, and the draughtsman (who produces CAD revisions) must be clearly determined.
- **Information / Decision Required:**
  - Confirmation of business model: Does client acquire 100% exclusive copyright upon payment?
  - Does the platform receive only a limited, non-exclusive hosting license?
  - Are draughtsmen treated as independent contractors executing work-for-hire, with all derivative rights assigned to the client?
  - Portfolio policy: Are draughtsmen and students strictly barred from displaying client drawings, or will a formal client-waiver process exist?
- **Responsible Party:** Business Owner + Qualified Indian Legal Counsel.
- **Dependencies:** Required for `INTELLECTUAL_PROPERTY_POLICY.md` and `TERMS_AND_CONDITIONS_DRAFT.md`.
- **Risk If Unresolved:** Commercial disputes over drawing ownership, unauthorized public leaks of client construction plans, copyright infringement claims.
- **Legal Review Required:** Yes.
- **Status:** `NEEDS LEGAL REVIEW`

---

### ITEM-05: Data Retention Periods & Deletion Exceptions
- **Decision:** **Not decided yet; require operational and legal review.**
- **Distinction Between Statutory Mandates and Unapproved Operational Proposals:**
  - **Verified Statutory Obligations:**
    - System Activity Logs (`activity_logs` in D1): Mandatory minimum **180 days** under CERT-In Directions (April 28, 2022).
    - Financial Invoices & Tax Records: Mandatory minimum **8 financial years** under Income Tax Act, 1961 (Section 44AA) and CGST Act, 2017 (Section 36).
    - Grievance Redressal Records: Maintained for statutory audit under IT SPDI Rule 5(9) (30-day resolution timeline).
  - **Proposed Operational Policies (UNAPPROVED / PENDING BUSINESS-OWNER & LEGAL REVIEW):**
    - Account profile erasure execution timeframe (e.g., 30 days proposed, but pending operational confirmation).
    - Project drawings archive retention (e.g., 3-year post-completion archive is a PROPOSAL based on Limitation Act claim periods, but NOT an established policy; subject to storage costs and legal sign-off).
    - Inactive account archival threshold (e.g., 24-month rule is a PROPOSAL, pending business decision).
- **Information / Decision Required:**
  - Determination of project archive retention periods (how long completed drawing versions remain accessible to clients).
  - Determination of inactive user account retention schedules.
  - Scope and mechanics of user deletion (erasure of profile identity vs. preservation of completed drawing records belonging to other users).
- **Responsible Party:** Operations Lead + Legal Counsel.
- **Dependencies:** Required for `DATA_RETENTION_AND_DELETION.md` and Phase E backend deletion workflow.
- **Risk If Unresolved:** Indefinite data retention (DPDP non-compliance) or premature deletion of records required for dispute defense.
- **Legal Review Required:** Yes.
- **Status:** `NEEDS LEGAL REVIEW`

---

### ITEM-06: Third-Party Service Providers & Cloud Data Location
- **Decision:** **Open; pending formal confirmation of production data centers and agreements.**
- **Verified Current Architecture:**
  - **Firebase Authentication (Google Cloud):** User authentication, credential encryption.
  - **Cloudflare Workers, D1 Database, R2 Storage:** Application compute, relational database, object storage.
- **Information Required:**
  - Confirmation of data center location pinning for India jurisdiction.
  - Future payment gateway aggregator selection (Razorpay, Cashfree, etc.).
- **Responsible Party:** Engineering Lead + Business Owner.
- **Dependencies:** Required for `PRIVACY_POLICY_DRAFT.md` (Sections 9, 10, 11).
- **Legal Review Required:** Yes.
- **Status:** `OPEN / NEEDS OWNER INPUT`

---

### ITEM-07: Privacy Rights & Self-Service vs. Operational Handling
- **Decision:** **Open; pending operational process establishment.**
- **Current State:** Profile editing is operational via `PATCH /api/users/me`. Account deletion and formal data rights requests are currently handled manually/operationally via email.
- **Information Required:**
  - Approval of manual email-based handling workflow with 30-day statutory resolution SLA for initial release.
  - Roadmap for automated in-app deletion in subsequent phases.
- **Responsible Party:** Operations Lead + Engineering Lead.
- **Dependencies:** Required for `PRIVACY_POLICY_DRAFT.md` and `GRIEVANCE_AND_SUPPORT_POLICY.md`.
- **Legal Review Required:** No (operational SLA requires legal review).
- **Status:** `OPEN / NEEDS OWNER INPUT`

---

### ITEM-08: Cybersecurity Incident Response & CERT-In Reporting SLA
- **Decision:** **Pending formalization of incident response standard operating procedure (SOP).**
- **Why It Matters:** Under CERT-In Directions dated April 28, 2022, cybersecurity incidents must be reported to CERT-In within **6 hours** of noticing or being brought to notice via `incident@cert-in.org.in`.
- **Information Required:**
  - Designating the technical incident response lead.
  - Operational SOP for 6-hour CERT-In escalation.
- **Responsible Party:** Engineering Lead + Legal Counsel.
- **Dependencies:** Required for `PRIVACY_POLICY_DRAFT.md` (Sec 14) and `LEGAL_COMPLIANCE_OVERVIEW.md`.
- **Legal Review Required:** Yes.
- **Status:** `NEEDS LEGAL REVIEW`

---

### ITEM-09: Financial Terms, Invoicing & Project Revision Scope
- **Decision:** **Open; pending commercial terms confirmation.**
- **Information Required:**
  - Commercial terms regarding included revision rounds vs. out-of-scope variations.
  - Project cancellation fee schedule.
- **Responsible Party:** Business Owner.
- **Dependencies:** Required for `TERMS_AND_CONDITIONS_DRAFT.md` (Sec 5–10).
- **Legal Review Required:** Yes.
- **Status:** `NEEDS OWNER INPUT`

---

## 3. SUMMARY STATUS MATRIX

| Item ID | Subject | Priority | Assigned Role | Current Status |
| :--- | :--- | :---: | :--- | :---: |
| **ITEM-01** | Legal Business Identity (Sole Proprietorship) | P0 | Business Owner | `CONFIRMED PENDING DETAILS` |
| **ITEM-02** | Designated Grievance Officer & Contacts | P0 | Business Owner / Ops | `NEEDS OWNER INPUT` |
| **ITEM-03** | Student Age Policy & Minor Safeguards | P0 | Business Owner / Legal | `OPEN / PENDING SAFEGUARDS & LEGAL REVIEW` |
| **ITEM-04** | Drawing IP, Derivative Ownership & Licenses | P1 | Business Owner / Legal | `NEEDS LEGAL REVIEW` |
| **ITEM-05** | Retention Schedules & Deletion Exceptions | P1 | Operations / Legal | `NEEDS LEGAL REVIEW` |
| **ITEM-06** | Third-Party Processors & Data Center Pinning | P2 | Engineering Lead | `OPEN / NEEDS OWNER INPUT` |
| **ITEM-07** | Privacy Rights Request Handling Workflow | P1 | Operations / Engineering | `OPEN / NEEDS OWNER INPUT` |
| **ITEM-08** | CERT-In 6-Hour Incident Notification Protocol | P1 | Engineering / Legal | `NEEDS LEGAL REVIEW` |
| **ITEM-09** | Financial Pricing, Revisions & Cancellation SLA | P2 | Business Owner | `NEEDS OWNER INPUT` |

---
**REGISTER PREPARED FOR:** ARCHI DRAFT PROJECT MANAGEMENT  
**DATE:** OCTOBER 2026 (QUALITY REVIEW REVISION)  
