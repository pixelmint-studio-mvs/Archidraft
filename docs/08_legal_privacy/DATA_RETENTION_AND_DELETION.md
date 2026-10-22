# ARCHI DRAFT — DATA RETENTION & DELETION NOTICE
**DOCUMENT STATUS:** DRAFT — NOT APPROVED FOR PRODUCTION  
**REQUIRES QUALIFIED INDIAN LEGAL REVIEW AND BUSINESS-OWNER APPROVAL BEFORE PUBLICATION**  
**PROJECT:** Archi Draft  
**PARENT BRAND:** Draughtsman Studio (https://www.draughtsmanstudio.com)  
**BUSINESS STRUCTURE:** Sole Proprietorship / Individual Business (Proprietor: [PROPRIETOR FULL LEGAL NAME — TO BE CONFIRMED])  
**TARGET JURISDICTION:** India  
**EFFECTIVE DATE:** [EFFECTIVE DATE — TO BE CONFIRMED UPON PRODUCTION RELEASE]  
**VERSION:** 1.2.0-DRAFT  

---

> ### NOTICE TO DATA PRINCIPALS & AUDITORS
> This Data Retention & Deletion Notice sets out the preliminary retention and deletion principles for personal information, project briefs, technical CAD drawings, and audit logs on Archi Draft. 
> 
> **CRITICAL LEGAL DISTINCTION:**
> - **Verified Statutory Obligations:** Certain retention periods (e.g., CERT-In 180-day log mandate, tax/invoice retention) are established by Indian law.
> - **Unapproved Operational Proposals:** Specific operational retention periods (e.g., how long completed CAD drawings remain in project archives, inactive account rules) are **PENDING BUSINESS-OWNER, OPERATIONAL, AND QUALIFIED LEGAL REVIEW**. They are presented below as draft proposals for evaluation only, NOT as established platform policies.

---

## 1. CORE RETENTION PRINCIPLES

In accordance with Section 8(7) of the **Digital Personal Data Protection Act, 2023 (DPDP Act)** and the **Information Technology (SPDI) Rules, 2011**, Archi Draft adheres to storage minimization:
1. Personal data shall not be retained longer than necessary to fulfill the purpose for which it was processed, unless retention is required by Indian statutory obligations.
2. Where retention is required by law (e.g., cybersecurity or financial recordkeeping), records shall be maintained strictly for the prescribed statutory duration.
3. Upon purpose fulfillment or verified erasure request, personal data shall be erased or permanently anonymized, subject to legitimate statutory exceptions.

---

## 2. RETENTION SCHEDULES AUDIT: STATUTORY VS. OPERATIONAL

### Part A: Verified Statutory Retention Mandates (Binding Under Indian Law)

| Data Category | Specific Mandate | Mandatory Retention Period | Statutory Authority | Official Citation |
| :--- | :--- | :--- | :--- | :--- |
| **System & Security Activity Logs** (`activity_logs`) | Server actions, access timestamps, authentication events, IP hashes | **180 Days Minimum** (rolling log maintained within Indian jurisdiction) | CERT-In Directions (April 28, 2022) | Direction No. 20(3)/2022-CERT-In under Sec 70B(6) IT Act, 2000 |
| **Financial Invoices & Payment Records** | Invoices, milestone billing records, payment receipts | **8 Financial Years** following completion of relevant year | Income Tax Act, 1961 & CGST Act, 2017 | Sec 44AA IT Act read with Rule 6F; Sec 36 CGST Act, 2017 |
| **Grievance Redressal Records** | Formal complaints, ticket logs, resolution notices | **3 Years Minimum** (audit trail) | IT (SPDI) Rules, 2011 & DPDP Act, 2023 | Rule 5(9) IT SPDI Rules; Sec 13 DPDP Act, 2023 |

### Part B: Proposed Operational Retention Schedules (UNAPPROVED / PENDING BUSINESS & LEGAL REVIEW)
*The following timelines are proposed working models currently undergoing review by the business owner and legal counsel. They do NOT represent finalized or binding commitments.*

| Data Category | Purpose Under Review | Proposed Operational Period *(UNAPPROVED DRAFT)* | Justification / Legal Context Under Review | Status |
| :--- | :--- | :--- | :--- | :---: |
| **User Profile & Account Identity** | Active platform access, professional role records | While account is active; erased within proposed 30 days of verified deletion request | DPDP Act Sec 8(7) purpose fulfillment standard | `NEEDS LEGAL REVIEW` |
| **Completed Project CAD Drawings** (`.dwg`, `.dxf`, `.pdf`) | Client access to delivered plans; reference for site modifications | **PROPOSED:** 3 Years post-completion archive | Corresponds to general 3-year limitation period under Limitation Act, 1963 (Arts 55, 113) for breach of contract claims. *Note: Limitation Act does not mandate hosting files; retention duration is an operational cost decision.* | `NEEDS OWNER & LEGAL REVIEW` |
| **Project Briefs, Collaboration Chat & Voice Notes** | Project coordination audit trail; resolving scope disputes | **PROPOSED:** 3 Years post-completion archive | Corresponds to contractual claim window under Limitation Act, 1963 | `NEEDS LEGAL REVIEW` |
| **Inactive Accounts** | Purging dormant data to minimize security attack surface | **PROPOSED:** 24 Months dormancy threshold prior to notice and anonymization | Operational data hygiene practice | `NEEDS OWNER INPUT` |
| **Student Academic Credentials & Certificates** | Verification of issued drafting diplomas/credentials | **PROPOSED:** Permanent verifiable credential hash | Public credential verification authenticity | `NEEDS OWNER INPUT` |

---

## 3. STATUTORY EXCEPTIONS TO IMMEDIATE ERASURE

Under Indian law, a user's request for erasure cannot supersede mandatory legal retention duties. Archi Draft will not erase records where retention is strictly necessary for:
1. **Cybersecurity Compliance (CERT-In 180-Day Rule):** Under Directions issued under Section 70B(6) of the IT Act, 2000, all server action logs and access records must be preserved for a rolling period of **180 days**.
2. **Statutory Tax & Financial Records:** Under Indian tax laws, invoices and transaction records must be retained for at least **8 financial years**.
3. **Dispute Defense & Contractual Evidence:** Under the Limitation Act, 1963, contractual claims and professional liability claims may be raised within 3 years from the date of the cause of action. Project records and delivered drawings may be preserved for this statutory limitation period to defend against legal claims.
4. **Protection of Third-Party Data Principals:** Where a project involved collaboration between an Engineer and a Draughtsman, one user's account deletion does *not* authorize deleting the collaborating user's legitimate project history or deliverables.

---

## 4. WHAT HAPPENS WHEN AN ACCOUNT DELETION IS REQUESTED (PROPOSED WORKFLOW)

When you submit a verified account deletion request:

### 4.1. Immediate Actions (Proposed: Within 72 Hours)
- Your authentication credentials in Google Firebase Authentication are disabled, terminating all active sessions.
- Your user profile status in Cloudflare D1 is marked `DELETED`.
- You are removed from active project participant lists and cannot receive new project assignments.

### 4.2. Secondary Anonymization (Proposed: Within 30 Days)
- Your personal contact details (mobile number, postal address, company name, college name, date of birth) are purged from active database tables.
- In shared project messages and activity audit logs, your name is anonymized to `Former Member` or `Deleted User`, preserving the historical integrity of project instructions without displaying personal identifiers.

### 4.3. Preservation of Shared Drawings
- Technical CAD drawings uploaded to ongoing or completed projects belonging to other users will *not* be deleted if the project owner requires them for structural execution or municipal approval. The association with your personal profile is severed.

---

## 5. PROCEDURE FOR SUBMITTING ERASURE REQUESTS

Because automated self-service account deletion is currently undergoing engineering, account deletion and data erasure requests are currently processed operationally:

1. **Submit Request:** Send an email from your registered email address to **[PRIVACY / GRIEVANCE EMAIL — TO BE CONFIRMED]** with the subject line `ACCOUNT DELETION REQUEST`.
2. **Identity Verification:** Our team will respond with a confirmation challenge to verify that you are the legitimate account holder.
3. **Review & Execution:** Once verified, operations will review any open projects, pending milestone payments, or active legal holds. If no holds exist, the deletion workflow will be executed.
4. **Confirmation:** You will receive formal written confirmation within **30 days** of your verified request.

---

## 6. INACTIVE ACCOUNTS POLICY (PROPOSED)

Accounts that remain inactive (no logins, project submissions, or active assignments) for a continuous period of **24 months** may be flagged for archival. Prior to archival, we will send an alert to your registered email address allowing you 30 days to retain your account. If no response is received, the account profile may be anonymized in accordance with our data minimization principles. *(Subject to final business-owner approval)*.

---

## 7. QUESTIONS AND GRIEVANCE CHANNEL

If you have questions regarding data retention schedules or wish to inquire about specific project archives, contact our Grievance Officer:
- **Email:** `[GRIEVANCE EMAIL — TO BE CONFIRMED]`
- **Attention:** Grievance & Data Protection Officer, Archi Draft / Draughtsman Studio
