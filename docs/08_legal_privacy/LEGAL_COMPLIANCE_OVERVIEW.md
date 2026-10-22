# ARCHI DRAFT — LEGAL APPLICABILITY & COMPLIANCE OVERVIEW
**DOCUMENT STATUS:** DRAFT — PRELIMINARY TECHNICAL & STATUTORY APPLICABILITY REVIEW  
**TARGET MARKET:** India  
**PARENT BRAND:** Draughtsman Studio (https://www.draughtsmanstudio.com)  
**BUSINESS STRUCTURE:** Sole Proprietorship / Individual Business (Proprietor: [PROPRIETOR FULL LEGAL NAME — TO BE CONFIRMED])  
**DATE OF STATUTORY VERIFICATION:** OCTOBER 2026 (QUALITY REVIEW REVISION)  
**DISCLAIMER:** *This document provides a preliminary technical assessment of applicable Indian statutory frameworks based on verified application architecture and updated business decisions. It does NOT constitute formal legal advice. A qualified Indian legal practitioner must formally review and approve all legal documents before commercial launch.*

---

## 1. EXECUTIVE SUMMARY & BUSINESS CONTEXT

Archi Draft is a professional workflow application coordinating architectural and engineering projects, technical drawings, communications, and drafting training in India.

### Confirmed Business Structure
- **Entity Type:** **Sole Proprietorship / Individual Business.**
- **Trading Name:** Draughtsman Studio.
- **Platform:** Archi Draft.
- **Legal Implication under Indian Law:** In a sole proprietorship, the business has no separate legal personality distinct from the individual proprietor. The individual proprietor ([PROPRIETOR FULL LEGAL NAME — TO BE CONFIRMED]) is the contracting party under the Indian Contract Act, 1872 and operates as the **Data Fiduciary** under the Digital Personal Data Protection Act, 2023 (DPDP Act), bearing direct personal liability for platform operations, contractual obligations, and statutory data protection compliance.

---

## 2. STATUTORY APPLICABILITY MATRIX

| Statute / Regulation | Statutory Provision / Rule | Application to Archi Draft Architecture | Current Implementation Status | Action Required Before Production |
| :--- | :--- | :--- | :---: | :--- |
| **DPDP Act, 2023** | **Sec 5 (Notice):** Mandatory notice before/at collection specifying data categories, purposes, rights, grievance mechanism. | **High:** Applied to user registration and profile forms. | **NON-COMPLIANT** | Implement `LegalOnboardingScreen` and link Privacy Notice at registration. |
| **DPDP Act, 2023** | **Sec 6 (Consent):** Consent must be free, specific, informed, unconditional, with clear affirmative action; easily withdrawable. | **High:** Required for optional processing (e.g. promotional communications). | **PARTIAL** | Contractual terms separated from optional consent; unselected checkboxes mandated. |
| **DPDP Act, 2023** | **Sec 8(5) (Security):** Reasonable security safeguards to prevent personal data breach. | **High:** Server-side auth, password hashing, least privilege. | **COMPLIANT** | Verified via Phase F1/F1.1 cross-user data isolation and Cloudflare Worker auth. |
| **DPDP Act, 2023** | **Sec 8(6) (Breach Notification):** Notify Data Protection Board and affected users upon breach. | **High:** Security incident management protocol. | **DRAFT** | Establish formal breach escalation workflow in `PRIVACY_POLICY_DRAFT.md`. |
| **DPDP Act, 2023** | **Sec 8(7) (Erasure):** Erase data upon purpose fulfillment or consent withdrawal, unless retention required by law. | **High:** Account deletion and retention schedules. | **NON-COMPLIANT** | Operational/legal retention review required; backend deletion workflow required. |
| **DPDP Act, 2023** | **Sec 9 (Child Data):** Verifiable parental consent before processing data of child (<18); zero profiling/tracking; zero detrimental processing. | **High:** Student Portal proposes allowing younger students under 18. | **CRITICAL RISK / PENDING SAFEGUARDS** | Multi-faceted child protection architecture and qualified legal review mandatory before enabling minors. |
| **DPDP Act, 2023** | **Sec 11–14 (Rights):** Rights of access, correction, erasure, grievance redressal, nomination. | **High:** User profile and settings management. | **PARTIAL** | Profile editing exists; self-service erasure and grievance tracking endpoints required. |
| **IT Act, 2000** | **Sec 43A & SPDI Rules:** Maintain reasonable security practices; published Privacy Policy; designated Grievance Officer. | **High:** Active law until corresponding DPDP provisions fully take effect. | **PARTIAL** | Publish draft Privacy Policy and designate Grievance Officer with 30-day resolution SLA. |
| **CERT-In Directions** | **Sec 70B(6) IT Act:** Mandatory 6-hour incident reporting to CERT-In; NTP time sync; 180-day log maintenance. | **High:** Cloudflare Worker activity logging and server clocks. | **PARTIAL** | Verify D1 `activity_logs` 180-day retention policy and document 6-hour CERT-In reporting SOP. |
| **Consumer Protection** | **E-Commerce Rules 2020:** Transparent pricing, invoice generation, disclosure of terms of sale, grievance officer details. | **Medium:** Project valuation and invoicing in `financials_screen.dart`. | **PARTIAL** | Ensure invoices display full tax breakdowns, terms of cancellation, and grievance contacts. |
| **Indian Contract Act** | **Sec 10 & 11:** Competency to contract. Minors (<18) lack capacity to contract; agreements by minors are void ab initio. | **High:** Terms acceptance and proposed minor registration. | **CRITICAL RISK** | Contract terms cannot be executed directly by minors. Guardian execution framework required. |
| **Copyright Act, 1957** | **Sec 2(c), 13, 17, 19:** Ownership of architectural drawings; moral rights; assignment requires written deed. | **High:** CAD files (`.dwg`, `.dxf`, `.pdf`) uploaded and revised. | **DRAFT / PENDING REVIEW** | Drawing IP policy is currently undecided; requires formal business-owner and legal review. |

---

## 3. IN-DEPTH ANALYSIS: CHILD PRIVACY & MINOR STUDENT SAFEGUARDS

### 3.1 The Proposed Business Decision: Permitting Younger Students Under 18
The business owner has determined that Archi Draft **may allow younger students under 18 years of age** to access the Student Portal for vocational drafting, ITI coursework, or polytechnic engineering training, **subject to business-owner decisions, applicable legal requirements, and appropriate safeguards**.

### 3.2 Why Verifiable Parental Consent Alone Does NOT Resolve Every Legal Requirement
A critical finding of this legal review is that **obtaining parental consent is merely one requirement among several distinct statutory barriers** under Indian law. Permitting minors requires addressing the following full legal spectrum:

1. **Section 9(1) of DPDP Act (Verifiable Parental Consent):**
   - The platform must obtain verifiable consent from the parent or lawful guardian.
   - The method of verification must withstand regulatory scrutiny (e.g., SMS/email OTP challenge to a confirmed adult guardian, government ID verification token, or authorized institutional delegation via schools/colleges).
2. **Section 9(2) of DPDP Act (Prohibition of Detrimental Processing):**
   - The platform must not undertake any processing of personal data that is likely to cause any detrimental effect on the physical, mental, or moral well-being of a child.
   - Rigorous moderation of collaboration hub messaging and voice notes is required to prevent bullying, exploitation, or harassment of underage students.
3. **Section 9(3) of DPDP Act (Absolute Ban on Behavioral Monitoring & Tracking):**
   - The statute states: *"A Data Fiduciary shall not undertake tracking or behavioural monitoring of children or targeted advertising directed at children."*
   - This creates an absolute statutory prohibition. Standard analytics, automated student performance profiling, behavioral engagement tracking, or automated ranking algorithms must be audited to ensure they do not constitute unlawful "behavioral monitoring."
4. **Indian Contract Act, 1872 (Incapacity to Contract):**
   - Under Section 11 of the Indian Contract Act, minors are legally incompetent to contract. Contracts entered into by minors are **void ab initio** (*Mohori Bibee v. Dharmodas Ghose [1903] ILR 30 Cal 539*).
   - A minor cannot legally accept the Terms & Conditions. Any clickwrap agreement signed directly by a 16- or 17-year-old student is legally unenforceable against them.
   - To create binding terms regarding intellectual property, platform acceptable use, or liability, the agreement must be executed by the parent or legal guardian on behalf of the minor.
5. **Guardianship Laws:**
   - Determination of who constitutes a lawful guardian under the Hindu Minority and Guardianship Act, 1956 and the Guardians and Wards Act, 1890, particularly in institutional educational settings.
6. **Data Minimization for Minors:**
   - Under principles of data minimization, profiles of minor students must strictly avoid collecting home addresses, personal mobile numbers, or unnecessary personal identifiers.

### 3.3 Preliminary Technical & Legal Recommendation for Minors
- **Phase B/C Status:** Student eligibility for minors remains documented as a **pending business decision subject to establishing safeguards**.
- **Action Required Before Implementation:** Do *not* activate student onboarding for minors in code until:
  1. A formal Minor Data Protection & Parental Consent Specification is authored.
  2. Qualified Indian legal counsel reviews the proposed consent and contractual model.
  3. Technical controls ensuring zero tracking/profiling of child accounts are validated.

---

## 4. IN-DEPTH ANALYSIS: INTELLECTUAL PROPERTY & RETENTION UNKNOWNS

### 4.1 Drawing Intellectual Property (Copyright Act, 1957)
- **Status:** **Pending Business-Owner & Legal Review.**
- **Key Consideration:** Under Section 17 of the Copyright Act, 1957, the author of an architectural plan or drawing is the first owner of copyright. Where an engineer uploads a baseline design and a draughtsman produces derivative CAD layers or revisions:
  - If the draughtsman is an independent contractor, derivative copyright might reside with the draughtsman unless explicitly assigned in writing under Section 19.
  - The final legal terms must explicitly clarify whether the draughtsman executes a complete assignment of derivative copyright to the client/engineer upon payment, or whether the client receives an irrevocable exclusive license.
  - The platform policy on personal portfolio display by draughtsmen must be finalized.

### 4.2 Data Retention: Statutory Mandates vs. Proposed Operational Policies
- **Status:** **Pending Operational & Legal Review.**
- **Statutory Mandates (Verified):**
  - **180 Days:** Server action logs (`activity_logs`) under CERT-In Directions (April 28, 2022).
  - **8 Financial Years:** Financial invoices and payment receipts under Income Tax Act Sec 44AA / CGST Act Sec 36.
  - **30 Days:** Grievance resolution timeline under IT (SPDI) Rules Rule 5(9).
- **Proposed Operational Policies (Unapproved Drafts):**
  - **Proposed 3 Years:** Project CAD drawing archive post-completion. *(Justified by general 3-year limitation period under Limitation Act, 1963 for contract claims, but NOT an approved policy; subject to storage economics and legal sign-off).*
  - **Proposed 30 Days:** Account profile erasure following verified request.
  - **Proposed 24 Months:** Dormancy threshold for inactive accounts.

---

## 5. REVISED COMPLIANCE GATES BEFORE PRODUCTION

1. **Proprietor Details:** Complete personal legal name, business address, and tax registration of the sole proprietor.
2. **Support & Grievance Appointments:** Formally appoint the Grievance Officer and establish verified email routing.
3. **Minor Safeguards Blueprint:** Prior to opening the Student Portal to minors, draft and review the child data protection architecture.
4. **Drawing IP Resolution:** Finalize copyright assignment and portfolio terms with legal counsel.
5. **Qualified Legal Review:** Obtain formal legal sign-off from an advocate enrolled with the Bar Council of India prior to public deployment.

---

## 6. OFFICIAL STATUTORY SOURCES & CITATIONS (CHECKED OCTOBER 2026)

The legal assessments in this document have been cross-referenced against the following official statutory sources:

1. **Digital Personal Data Protection Act, 2023 (Act No. 22 of 2023):**  
   - Enacted by the Parliament of India; published in The Gazette of India, Extraordinary, Part II, Section 1, dated August 11, 2023.  
   - *Status Checked:* October 2026. Phased commencement provisions under Section 1(2).  
   - *Matters Requiring Legal Counsel:* Verification of Data Protection Board of India operational status, notifying dates for Section 9 child consent rules, and validation of consent notice formats.
2. **Information Technology Act, 2000 (Act No. 21 of 2000):**  
   - Sections 43A (compensation for failure to protect data), 66, 70B, and 72A.  
   - *Status Checked:* October 2026. Active law.
3. **Information Technology (Reasonable Security Practices and Procedures and Sensitive Personal Data or Information) Rules, 2011:**  
   - Notification No. G.S.R. 313(E), Ministry of Communications and Information Technology, dated April 11, 2011.  
   - *Status Checked:* October 2026. Active law until formally repealed/superseded by DPDP commencement. Mandatory Rule 5(9) grievance officer requirement.
4. **CERT-In Cyber Security Directions (Direction No. 20(3)/2022-CERT-In):**  
   - Issued by Indian Computer Emergency Response Team under Section 70B(6) of IT Act, dated April 28, 2022.  
   - *Status Checked:* October 2026. Mandatory 6-hour cybersecurity incident reporting window to `incident@cert-in.org.in` and 180-day log maintenance within Indian jurisdiction.
5. **Indian Contract Act, 1872 (Act No. 9 of 1872):**  
   - Sections 10, 11 (Capacity to contract), 13–19 (Free consent). Judicial precedent: *Mohori Bibee v. Dharmodas Ghose* (1903) 30 IA 114 (Privy Council).  
   - *Matters Requiring Legal Counsel:* Structuring enforceable electronic clickwrap agreements and minor student onboarding contracts executed by lawful guardians.
6. **Copyright Act, 1957 (Act No. 14 of 1957):**  
   - Sections 2(c)(ii) (architectural drawings as artistic works), 13, 17 (authorship/first ownership), 19 (statutory requirements for assignment of copyright), 57 (moral rights).  
   - *Matters Requiring Legal Counsel:* Drafting copyright assignment vs. licensing clauses between Clients, Draughtsmen, and the Sole Proprietor.
7. **Limitation Act, 1963 (Act No. 36 of 1963):**  
   - Articles 55 and 113 (3-year statutory limitation period for breach of contract and tort claims).  
   - *Matters Requiring Legal Counsel:* Determining whether platform should retain drawings for 3 years to defend against third-party claims.
8. **Income Tax Act, 1961 (Act No. 43 of 1961) & Central Goods and Services Tax Act, 2017 (Act No. 12 of 2017):**  
   - Section 44AA read with Rule 6F of Income-tax Rules, 1962 (6 financial years); Section 36 of CGST Act (72 months / 6 years from annual return due date).
