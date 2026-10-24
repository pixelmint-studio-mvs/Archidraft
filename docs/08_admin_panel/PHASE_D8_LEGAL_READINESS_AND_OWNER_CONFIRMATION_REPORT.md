# Archi Draft — Phase D.8: Legal Readiness, Owner Confirmation & Controlled E2E Preparation Report

**Execution Date:** October 23, 2026  
**Integration Branch:** `COMPLETED-INTERGRATION`  
**Execution Context:** Isolated Worktree (`scratch/completed-integration`)  
**Main Workspace Status:** `feature/admin-panel-complete` (`8ea5d4c5`) is **100% untouched and preserved**  
**Staging Worker URL:** `https://archi-draft-worker-staging.imserratex.workers.dev`  
**Staging D1 Target:** `archi-draft-db-staging` (`065d76ba-eca5-4cc1-ba39-51281b79d6b4`)  
**Production Isolation:** `archi-draft-db` (`af8d3312-5f6e-46ce-bcc1-dfa91e484cc0`) — **Verified 0 rows (Untouched)**  
**Legal Consent Gate Status:** **FAIL-CLOSED** (Endpoint `GET /api/legal/documents/TERMS_AND_CONDITIONS/current` returns HTTP 404 `NO_EFFECTIVE_VERSION`)  
**Phase Objective:** Audit existing draft legal documents, validate owner-supplied business details, identify missing statutory particulars, and establish an affirmative approval checklist prior to staging document activation.  
**Legal Document Activation Status:** **ZERO DOCUMENTS ACTIVATED OR SEEDED — GATES REMAIN 100% FAIL-CLOSED**

---

## 1. Executive Summary

Phase D.8 executes the formal legal readiness audit and owner confirmation analysis for Archi Draft. This phase is strictly **preparation and review**. In accordance with mandatory safety constraints:
- No legal documents were inserted or marked `EFFECTIVE` in `archi-draft-db-staging`.
- No acceptance records, consent timestamps, or user agreements were fabricated.
- The `assertTermsAccepted` gate remains active, unmodified, and fail-closed.
- Protected non-admin project mutations (`POST /api/projects`, `POST /api/projects/:id/submit`, etc.) remain safely blocked.
- Production Cloudflare, Firebase, D1, R2, and Vercel environments remain 100% untouched.

The owner provided six preliminary business parameters for review. While these supply essential starting points, a thorough legal audit reveals that **material business details and statutory prerequisites remain incomplete**. Specifically, the physical address is partial ("pixelmint studio"), the legal identity requires proprietor confirmation under the Indian Contract Act, 1872, the statutory Grievance Officer under IT SPDI Rules, 2011 is unappointed, and the minor student policy under the DPDP Act, 2023 requires formal legal advice.

---

## 2. Owner-Provided Business Details & Validation Assessment

The following details were supplied by the project owner for evaluation. Each field has been evaluated for completeness, statutory sufficiency under Indian law, and operational consistency:

| # | Field Name | Owner-Supplied Value | Completeness & Statutory Validation Assessment | Actionable Status |
| :-: | :--- | :--- | :--- | :---: |
| **1** | **Business / Proprietor Name** | `Archi Draft Studio` | **Incomplete / Ambiguous.**<br>Under Indian law, a Sole Proprietorship is not an incorporated body or separate legal entity. A trade name ("Archi Draft Studio") cannot sue, be sued, or enter into binding contracts in its own name. The legal agreement must be executed by the individual proprietor (e.g., *"Mr. [Full Legal Name], carrying on business as a Sole Proprietor under the trade name Archi Draft Studio"*). If registered under MSME/Udyam, GST, or Shops & Establishments, registration numbers must be documented. | **OWNER INPUT REQUIRED** |
| **2** | **Official Physical Address** | `pixelmint studio` | **Severely Incomplete.**<br>"pixelmint studio" is an informal brand/studio name, not a physical postal address. Rule 5(9) of the IT SPDI Rules 2011, Rule 4 of the Consumer Protection (E-Commerce) Rules 2020, and the DPDP Act 2023 require a verifiable physical address for service of legal notices, customer disputes, and regulatory correspondence. Requires: Door/Building No., Street, Locality, City, District, State, PIN Code, and Country. | **BLOCKED — OWNER INPUT REQUIRED** |
| **3** | **Official Support Email** | `zedsuo125@gmail.com` | **Supplied (Personal Domain).**<br>The email address is active and controlled by the owner. However, using a personal `@gmail.com` address for statutory data protection filings, formal legal grievance redressal, and user trust presents operational and professional limitations. The owner must confirm whether this is the intended permanent public contact or if a branded domain email (e.g., `support@draughtsmanstudio.com` / `grievance@...`) will be deployed. | **OWNER CONFIRMATION REQUIRED** |
| **4** | **Official Contact Phone** | `6382096551` | **Supplied (10 Digits).**<br>Valid Indian 10-digit mobile number. Must be formally formatted with country code (`+91 6382096551`). The owner must confirm whether this number is a private personal telephone or an official business support line authorized to be published openly on legal notices and terms. | **OWNER CONFIRMATION REQUIRED** |
| **5** | **Governing Jurisdiction** | `Tamil Nadu, India` | **State-Level Supplied; Court Venue Unspecified.**<br>Establishes governing state law. However, under standard Indian civil litigation practice and Section 28 of the Indian Contract Act, 1872, forum-selection clauses must designate the specific City / District Court of competent jurisdiction (e.g., *"Courts of competent jurisdiction in Chennai, Tamil Nadu, India"*). Requires qualified Indian legal counsel review. | **LEGAL REVIEW REQUIRED** |
| **6** | **Maximum Correction Rounds** | `3` | **Supplied (Integer 3).**<br>Workflow-consistent with D1 schema and Worker route `POST /api/projects/:id/correction` (`newRound = (existing.round || 0) + 1`). However, legal terms must explicitly define: (1) what constitutes a valid "round" (consolidated drawing markups vs. piecemeal comments), (2) clear exclusion of fundamental design brief changes as out-of-scope variations, and (3) commercial remedies once 3 rounds are exhausted. | **OWNER CONFIRMATION & POLICY ALIGNMENT REQUIRED** |

---

## 3. Document-by-Document Audit of Existing Legal Drafts

An exhaustive audit of the six draft documents in `docs/08_legal_privacy/` was conducted to identify unresolved placeholders, missing statutory information, workflow inconsistencies, and unverified legal assertions:

### 3.1. `TERMS_AND_CONDITIONS_DRAFT.md` (Version: 1.2.0-DRAFT, 224 lines)
- **Unresolved Placeholders Identified:**
  - `[PROPRIETOR FULL LEGAL NAME — TO BE CONFIRMED]` (Lines 6, 14, 158)
  - `[EFFECTIVE DATE — TO BE CONFIRMED UPON PRODUCTION RELEASE]` (Line 8)
  - `[SECURITY INCIDENT EMAIL — TO BE CONFIRMED]` (Line 56)
  - `[PRIVACY / GRIEVANCE EMAIL — TO BE CONFIRMED]` (Line 201)
  - `[GRIEVANCE EMAIL — TO BE CONFIRMED]` (Line 208)
  - `[CITY / STATE, INDIA — TO BE CONFIRMED BY PROPRIETOR]` (Line 223)
- **Substantive Inconsistencies & Review Requirements:**
  1. **Contracting Party Definition:** Currently names "Draughtsman Studio" as the trade name under an unconfirmed sole proprietor. Must be updated to harmonize with "Archi Draft Studio" or specify the exact parent/child relationship between Draughtsman Studio and Archi Draft Studio.
  2. **Minors / Student Portal (Section 2.2):** Explicitly states that minors under 18 lack contractual capacity under Section 11 of the Indian Contract Act, 1872 (*Mohori Bibee v. Dharmodas Ghose*). It correctly notes that parental consent under DPDP Act Section 9 does not cure contractual voidness. This item remains an open legal decision: until a multi-layered guardian-execution framework is established, registration must remain 18+.
  3. **Correction Policy Harmonization (Section 9.1):** Currently states revision rounds are "agreed upon in the initial project quotation". Must be amended to state the default platform threshold of **three (3) consolidated revision rounds**, explicitly defining out-of-scope variations.
  4. **Derivative Drawing Copyright (Section 14.2):** Explicitly flags the allocation of copyright in derivative revisions created by draughtsmen as "currently undecided and subject to business-owner and qualified legal review".
  5. **Dispute Resolution (Section 21):** Needs specific court district designation in Tamil Nadu.

### 3.2. `PRIVACY_POLICY_DRAFT.md` (Version: 1.2.0-DRAFT, 246 lines)
- **Unresolved Placeholders Identified:**
  - `[PROPRIETOR FULL LEGAL NAME — TO BE CONFIRMED]` (Lines 6, 20, 224)
  - `[BUSINESS ADDRESS — TO BE CONFIRMED, INDIA]` (Line 20)
  - `[SECURITY INCIDENT EMAIL — TO BE CONFIRMED]` (Lines 112, 227)
  - `[PAYMENT GATEWAY PROCESSOR — TO BE CONFIRMED]` (Line 130)
  - `[TRANSACTIONAL EMAIL SERVICE — TO BE CONFIRMED]` (Line 131)
  - `[PRIVACY / GRIEVANCE EMAIL — TO BE CONFIRMED]` (Line 213)
  - `[GRIEVANCE OFFICER NAME — TO BE CONFIRMED]` (Line 222)
  - `[GRIEVANCE EMAIL — TO BE CONFIRMED]`, `[SUPPORT EMAIL — TO BE CONFIRMED]` (Lines 225, 226)
  - `[OFFICIAL POSTAL ADDRESS — TO BE CONFIRMED, ATTN: GRIEVANCE OFFICER, INDIA]` (Line 228)
- **Substantive Inconsistencies & Review Requirements:**
  1. **Data Fiduciary Identification:** Section 1 requires full legal proprietor details and registered postal address to comply with DPDP Act Section 2(i).
  2. **Third-Party Data Processors:** Section 9 lists Cloudflare (API, D1, R2) and Google (Firebase), but retains placeholders for payment gateway (frozen in backend) and transactional email providers.
  3. **Statutory vs. Operational Distinction:** Section 12 properly distinguishes the mandatory 180-day CERT-In log mandate (verified) from proposed operational CAD retention (3-year archive, unapproved).
  4. **Grievance Officer Particulars:** Section 18 lacks the statutory name, physical address, and dedicated grievance email required under Rule 5(9) of the IT SPDI Rules, 2011.

### 3.3. `ACCEPTABLE_USE_POLICY.md` (Version: 1.1.0-DRAFT, 83 lines)
- **Unresolved Placeholders Identified:**
  - `[PROPRIETOR FULL LEGAL NAME — TO BE CONFIRMED]` (Line 6)
  - `[EFFECTIVE DATE — TO BE CONFIRMED UPON PRODUCTION RELEASE]` (Line 8)
  - `[SECURITY INCIDENT EMAIL — TO BE CONFIRMED]` (Line 68)
  - `[GRIEVANCE EMAIL — TO BE CONFIRMED]` (Line 68)
- **Substantive Points & Statutory References:**
  - Accurately details prohibited technical circumvention, IDOR tampering, unauthorized drawing downloads, harassment, and bulk scraping.
  - Section 4.4 correctly references modern statutory enforcement under the **Information Technology Act, 2000 (Sections 43, 66, 72A)** and the **Bharatiya Nyaya Sanhita (BNS)** (replacing the Indian Penal Code). Legal counsel must review the specific statutory citations.

### 3.4. `GRIEVANCE_AND_SUPPORT_POLICY.md` (Version: 1.2.0-DRAFT, 95 lines)
- **Unresolved Placeholders Identified:**
  - `[PROPRIETOR FULL LEGAL NAME — TO BE CONFIRMED]` (Lines 6, 24)
  - `[EFFECTIVE DATE — TO BE CONFIRMED UPON PRODUCTION RELEASE]` (Line 8)
  - `[GRIEVANCE OFFICER NAME — TO BE CONFIRMED]` (Line 22)
  - `[GRIEVANCE EMAIL — TO BE CONFIRMED]` (Lines 25, 42, 43, 84)
  - `[SECURITY INCIDENT EMAIL — TO BE CONFIRMED]` (Lines 26, 44)
  - `[SUPPORT EMAIL — TO BE CONFIRMED]` (Lines 27, 41, 83)
  - `[OFFICIAL BUSINESS ADDRESS — TO BE CONFIRMED]`, `[CITY, STATE, PIN CODE, INDIA]` (Lines 29, 30)
- **Substantive Points & Statutory Timelines:**
  - Correctly anchors the **statutory 30-day maximum resolution mandate** under Rule 5(9) of the IT SPDI Rules, 2011.
  - Distinguishes internal operational targets (48h acknowledgment, 15-day investigation) from the legal obligation.
  - Outlines escalation levels up to the **Data Protection Board of India (DPBI)** under DPDP Act 2023.

### 3.5. `INTELLECTUAL_PROPERTY_POLICY.md` (Version: 1.2.0-DRAFT, 103 lines)
- **Unresolved Placeholders Identified:**
  - `[PROPRIETOR FULL LEGAL NAME — TO BE CONFIRMED]` (Line 6)
  - `[EFFECTIVE DATE — TO BE CONFIRMED UPON PRODUCTION RELEASE]` (Line 8)
  - `[GRIEVANCE / COPYRIGHT EMAIL — TO BE CONFIRMED]` (Line 94)
- **Substantive Points & Open Decisions:**
  - Recognizes architectural plans as artistic works (Sec 2(c)(ii)) and technical drawings as literary works (Sec 2(o)) under the Indian Copyright Act, 1957.
  - Confirms clients retain 100% preexisting copyright in uploaded briefs.
  - Flags Section 2.2 as **undecided**: Does the client receive full exclusive copyright in derivative CAD revisions upon milestone settlement, or an exclusive perpetual license? Draughtsmen must execute written assignment deeds conforming to Section 19 of the Copyright Act.

### 3.6. `DATA_RETENTION_AND_DELETION.md` (Version: 1.2.0-DRAFT, 104 lines)
- **Unresolved Placeholders Identified:**
  - `[PROPRIETOR FULL LEGAL NAME — TO BE CONFIRMED]` (Line 6)
  - `[EFFECTIVE DATE — TO BE CONFIRMED UPON PRODUCTION RELEASE]` (Line 8)
  - `[PRIVACY / GRIEVANCE EMAIL — TO BE CONFIRMED]` (Line 86)
- **Substantive Points:**
  - Confirms mandatory 180-day log preservation under CERT-In Directions (April 2022) and 8-year tax/invoice records under Section 44AA of Income Tax Act / CGST Act.
  - Correctly marks the proposed 3-year CAD drawing retention and 24-month inactive account archival as unapproved operational proposals requiring business-owner decision.

---

## 4. Statutory Particulars & Legal Claim Scrutiny

The following statutory claims across the documents have been analyzed against current Indian jurisprudence:

1. **Indian Contract Act, 1872 (Section 11 — Minors' Incapacity):**
   - *Status:* **Legally Verified.** Agreements with minors are void ab initio (*Mohori Bibee v. Dharmodas Ghose (1903) 30 IA 114*). A minor cannot contractually agree to terms or disclaimers.
   - *Requirement:* The platform must either restrict registration strictly to adults 18+ or institute a legal guardian co-signing framework.
2. **Digital Personal Data Protection Act, 2023 (Section 9 — Processing of Children's Data):**
   - *Status:* **Legally Verified.** Mandates verifiable parental consent, strictly prohibits behavioral monitoring or targeted advertising, and bars any processing detrimental to child well-being.
   - *Requirement:* Operational telemetry, scoring rubrics, and automated evaluations must be legally audited prior to enrolling students under 18.
3. **Information Technology Act, 2000 & IT (SPDI) Rules, 2011 (Rule 5(9)):**
   - *Status:* **Legally Verified.** Every body corporate or individual data fiduciary collecting personal information must appoint a Grievance Officer and publish their name, address, and contact email.
   - *Requirement:* A real natural person must be designated as Grievance Officer.
4. **CERT-In Direction No. 20(3)/2022 (April 28, 2022):**
   - *Status:* **Legally Verified.** Requires ICT providers to maintain system logs for a rolling period of 180 days within Indian jurisdiction and report cybersecurity incidents within 6 hours.
   - *Requirement:* Staging and production audit logs (`activity_logs` in D1) must be preserved in accordance with this rule.
5. **Bharatiya Nyaya Sanhita, 2023 (BNS):**
   - *Status:* **Legally Verified.** The BNS replaced the Indian Penal Code effective July 1, 2024. References to criminal law remedies in the Acceptable Use Policy properly cite the BNS alongside IT Act Sections 43 and 66.

---

## 5. Explicit Questions Required for Owner & Qualified Legal Counsel

The following specific questions must be affirmatively answered before legal documents can be populated or approved:

### 5.1. Owner Clarifications Required
1. **Proprietor Identity & Trading Structure:**
   - What is the full legal name of the sole proprietor?
   - Is "Archi Draft Studio" an informal trade name, or is it registered under an MSME Udyam Certificate, Shop & Establishment Act, or GST?
   - What is the exact relationship between "Archi Draft Studio" and "Draughtsman Studio" (https://www.draughtsmanstudio.com)?
2. **Complete Postal Address:**
   - Please provide the complete official postal address for "pixelmint studio", including:
     - Building / Office / Door Number: `[ ]`
     - Street / Road / Complex Name: `[ ]`
     - Locality / Area: `[ ]`
     - City: `[ ]`
     - District: `[ ]`
     - State: `[ Tamil Nadu ]`
     - Postal PIN Code: `[ ]`
3. **Official Business Contacts & Publication Consent:**
   - Do you authorize `zedsuo125@gmail.com` and `+91-6382096551` to be published openly on public legal documents, terms of service, and privacy policies?
   - Will a dedicated domain email (e.g., `support@draughtsmanstudio.com`) be established before commercial launch?
4. **Designation of Grievance Officer:**
   - Who will serve as the statutory Grievance Officer under Indian law?
     - Full Name of Officer: `[ ]`
     - Designation / Title: `[ e.g., Grievance Officer & Operations Lead ]`
     - Dedicated Grievance Email Address: `[ ]`
5. **Three-Correction-Round Rule & Exceptions:**
   - Please confirm the definition of a "correction round": Does it require the Engineer to consolidate all drawing feedback into a single revision request?
   - Are fundamental alterations to project dimensions, layout redesigns, or site changes explicitly classified as billable scope variations outside the 3 rounds?
   - What occurs if a project exceeds 3 rounds: Is further drafting halted until an extra revision fee is agreed, or does the Admin intervene?
6. **Student Age Boundary Decision:**
   - Does Archi Draft restrict registration strictly to individuals **18 years of age and older** for the initial staging launch? *(Recommended until DPDP Section 9 parental consent mechanisms are coded and audited).*

### 5.2. Qualified Legal Counsel Review Questions
1. Does the limitation of liability clause in Section 10 of the Terms & Conditions sufficiently protect an individual sole proprietor under the Indian Contract Act, 1872 and Consumer Protection Act, 2019?
2. Does the drawing ownership clause in Section 14 satisfy Section 19 of the Copyright Act, 1957 regarding assignment deeds and territorial extent of derivative works?
3. Does the forum-selection clause designating courts in Tamil Nadu satisfy the jurisdictional requirements of Section 20 of the Code of Civil Procedure, 1908?

---

## 6. Affirmative Authorization & Approval Checklist

To ensure no legal documents are activated prematurely, the following affirmative gates must be satisfied:

```
[ ] GATE 1: Owner confirms full legal proprietor name and registered trading structure.
[ ] GATE 2: Owner provides complete, verifiable postal address including PIN code.
[ ] GATE 3: Owner confirms official public email and telephone contact channels.
[ ] GATE 4: Owner designates a named Grievance Officer with dedicated contact channel.
[ ] GATE 5: Owner confirms 3-correction-round operational policy and scope variation rules.
[ ] GATE 6: Owner resolves Student age policy (confirming adult-only 18+ for staging).
[ ] GATE 7: Qualified Indian legal counsel reviews and approves document drafts.
[ ] GATE 8: Affirmative written authorization issued by Owner to seed staging database.
```

> [!IMPORTANT]
> **Enforcement Principle:** Until Gates 1 through 8 are affirmatively satisfied and signed off, **zero legal documents will be seeded as EFFECTIVE** in `archi-draft-db-staging`. The legal gate will remain strictly fail-closed.

---

## 7. Staging-Only Legal Gate Testing Plan (Post-Approval)

Once the owner and legal counsel complete the approval checklist, the following staging-only test sequence will be executed in a controlled manner:

| Step | Action | Method & Target | Expected Verification Evidence |
| :-: | :--- | :--- | :--- |
| **T-LEG-01** | Seed Legal Drafts as DRAFT | Direct D1 insert into `legal_documents` with status `DRAFT` | Query `SELECT id, document_type, status FROM legal_documents WHERE status = 'DRAFT'`. Verify 6 documents inserted. |
| **T-LEG-02** | Verify Public Gate Rejection | `GET /api/legal/documents/TERMS_AND_CONDITIONS/current` | Must return **HTTP 404** `NO_EFFECTIVE_VERSION`. DRAFT versions must NEVER be exposed publicly. |
| **T-LEG-03** | Verify Non-Admin Mutation Block | Engineer attempts `POST /api/projects` | Must return **HTTP 403** `TERMS_ACCEPTANCE_REQUIRED`. Fail-closed gate confirmed active. |
| **T-LEG-04** | Mark Approved Document EFFECTIVE | D1 update setting `status = 'EFFECTIVE'`, `effective_at = CURRENT_TIMESTAMP` | Query `SELECT document_type, version, status FROM legal_documents WHERE status = 'EFFECTIVE'`. |
| **T-LEG-05** | Verify Public Version Retrieval | `GET /api/legal/documents/TERMS_AND_CONDITIONS/current` | Returns **HTTP 200 OK** with sanitized document markdown, version number, and effective date. |
| **T-LEG-06** | Test Consent Acceptance Flow | Authenticated Engineer calls `POST /api/legal/accept` | Returns **HTTP 200 OK**; row inserted into `legal_consents` in D1 with UID, version, and timestamp. |
| **T-LEG-07** | Verify Mutation Unlocked | Authenticated Engineer calls `POST /api/projects` | Returns **HTTP 201 Created**; project draft created in D1. Legal consent verification succeeded. |

---

## 8. Business Workflow E2E Tests Currently Blocked

In accordance with reporting integrity standards, the following live multi-actor E2E workflows remain **BLOCKED** behind the fail-closed legal consent gate:

| Test ID | Workflow Description | Actor | Blocked Route | Exact Reason for Blocked Status |
| :--- | :--- | :--- | :--- | :--- |
| **E2E-LIFE-01** | Create Project Brief | Engineer | `POST /api/projects` | Blocked by `assertTermsAccepted` (No effective terms in D1) |
| **E2E-LIFE-02** | Submit Project Brief | Engineer | `POST /api/projects/:id/submit` | Blocked by `assertTermsAccepted` |
| **E2E-LIFE-03** | Admin Approve Project | Studio Admin | `POST /api/projects/:id/approve` | Requires project in `SUBMITTED` state (Blocked by E2E-LIFE-02) |
| **E2E-LIFE-04** | Admin Assign Draughtsman | Studio Admin | `POST /api/assignments` | Requires approved project (Blocked by E2E-LIFE-03) |
| **E2E-LIFE-05** | Draughtsman Accept Project | Draughtsman | `POST /api/assignments/:id/accept` | Blocked by `assertTermsAccepted` for Draughtsman |
| **E2E-LIFE-06** | Draughtsman Upload Drawing | Draughtsman | `POST /api/projects/:id/drawing_versions` | Blocked by `assertTermsAccepted` for Draughtsman |
| **E2E-LIFE-07** | Engineer Review & Correction | Engineer | `POST /api/projects/:id/correction` | Blocked by `assertTermsAccepted` for Engineer |
| **E2E-LIFE-08** | Engineer Approve Final Drawing| Engineer | `POST /api/projects/:id/approve_drawing`| Blocked by `assertTermsAccepted` for Engineer |

---

## 9. Readiness Decision

```
========================================================================================
FINAL READINESS OUTCOME:
  [X] BLOCKED — OWNER INPUT REQUIRED
  [X] BLOCKED — LEGAL REVIEW REQUIRED

REASON FOR DETERMINATION:
  1. Material business identity particulars (Sole Proprietor full legal name, complete
     postal address with PIN code, and Grievance Officer appointment) remain unresolved.
  2. The physical address supplied ("pixelmint studio") is incomplete and cannot satisfy
     statutory service of process or E-Commerce / SPDI rule requirements under Indian law.
  3. The Student age policy (DPDP Section 9 vs. Contract Act Section 11) requires formal
     legal advice before student workflows can be legitimized.
  4. The legal-consent gate (assertTermsAccepted) remains strictly FAIL-CLOSED.
  5. Zero legal documents have been published or activated in staging or production.
========================================================================================
```
