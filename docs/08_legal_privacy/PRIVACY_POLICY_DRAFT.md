# ARCHI DRAFT — PRIVACY POLICY
**DOCUMENT STATUS:** DRAFT — NOT APPROVED FOR PRODUCTION  
**REQUIRES QUALIFIED INDIAN LEGAL REVIEW AND BUSINESS-OWNER APPROVAL BEFORE PUBLICATION**  
**PROJECT:** Archi Draft  
**PARENT BRAND:** Draughtsman Studio (https://www.draughtsmanstudio.com)  
**BUSINESS STRUCTURE:** Sole Proprietorship / Individual Business (Proprietor: [PROPRIETOR FULL LEGAL NAME — TO BE CONFIRMED])  
**TARGET JURISDICTION:** India  
**EFFECTIVE DATE:** [EFFECTIVE DATE — TO BE CONFIRMED UPON PRODUCTION RELEASE]  
**VERSION:** 1.2.0-DRAFT  

---

> ### IMPORTANT NOTICE TO USERS
> This document is a draft privacy policy prepared for Archi Draft. It explains how personal data is collected, used, stored, shared, and protected across the platform. All business identification and contact fields are marked with explicit bracketed placeholders (`[...]`) pending formal confirmation by the business owner and legal counsel.

---

## 1. INTRODUCTION AND ORGANIZATION IDENTITY

This Privacy Policy governs the processing of personal data on the **Archi Draft** platform, developed and operated under the brand **Draughtsman Studio** by **[PROPRIETOR FULL LEGAL NAME — TO BE CONFIRMED]**, an individual carrying on business as a **Sole Proprietorship** in India ("Archi Draft", "we", "us", or "our"), having its principal place of business at **[BUSINESS ADDRESS — TO BE CONFIRMED, INDIA]**.

We are committed to processing your personal data transparently, securely, and in accordance with applicable Indian laws, including the **Digital Personal Data Protection Act, 2023 (DPDP Act)**, the **Information Technology Act, 2000 (IT Act)**, and the **Information Technology (Reasonable Security Practices and Procedures and Sensitive Personal Data or Information) Rules, 2011 (SPDI Rules)**.

For the purposes of the DPDP Act, the sole proprietor operating as Draughtsman Studio acts as a **Data Fiduciary** with respect to personal data collected directly from users of Archi Draft.

---

## 2. SCOPE OF THIS POLICY

This Privacy Policy applies to all individuals who access, register, or use the Archi Draft web application, mobile applications, services, and associated panels:
1. **Client / Engineer Panel:** For project creators, consulting engineers, architects, and interior designers.
2. **Draughtsman Panel:** For architectural, structural, and interior drafting professionals.
3. **Student Panel:** For drafting and engineering students enrolled in training modules. *(See Section 15 regarding students under 18).*
4. **Admin Panel:** For authorized platform administrators and studio management personnel.

This Policy does *not* apply to third-party websites, software, or external services that you may access through external links provided on our platform.

---

## 3. CATEGORIES OF PERSONAL DATA ACTUALLY COLLECTED

We collect only the categories of personal data necessary to provide our architectural workflow, project coordination, and training services. In accordance with our data minimization principle, we do not collect data categories unless actively utilized by our features:

1. **Identity & Authentication Information:**
   - Full Name.
   - Email Address.
   - Encrypted Password (managed via Google Firebase Authentication; we never store plain-text passwords).
   - User Role (Client/Engineer, Draughtsman, Student, Admin).
   - Unique User Identifier (Firebase UID).
2. **Profile & Contact Details:**
   - Mobile / Telephone Number.
   - Postal Address (optional).
   - Date of Birth (optional, for age verification / student eligibility).
   - Professional Qualification / Degree (e.g., B.Tech, B.Arch, Diploma in Civil/Architecture).
   - Company or Firm Name (for Engineers/Draughtsmen).
   - College or Educational Institution Name (for Students).
   - Drafting Specialization (Architectural, Structural, Interior, Approval).
3. **Project & Workflow Data:**
   - Project Name and Project Site Address.
   - Drawing Type and Project Area (square footage or dimensions).
   - Project Assignment Records, Workflow Statuses, and Approval/Rejection Timestamps.
4. **Drawings, Files & Media Attachments:**
   - Uploaded CAD and technical drawing files (`.dwg`, `.dxf`, `.pdf`).
   - Image attachments and site reference photos (`.png`, `.jpg`, `.jpeg`).
   - Audio voice notes recorded in collaboration threads (`.webm`, `.m4a`, `.wav`).
5. **Collaboration Messages:**
   - Project messages, review comments, and correction instructions exchanged within project hubs.
6. **Academic & Performance Records (Student Panel Only):**
   - Training module progression and lesson completion records.
   - Practical drafting submission evaluations and rubric scores.
   - Issued credentials, course certificates, and unique verification tokens.
7. **Security & Technical Activity Logs:**
   - Action logs (file upload/deletion timestamps, submission events).
   - IP address hashes and browser/device user-agent strings recorded during critical security actions.

---

## 4. PURPOSES OF PROCESSING

We process your personal data strictly for the following defined purposes:
1. **Account Creation and Authentication:** To verify identity, maintain account security, and control role-based access.
2. **Project Workflow Coordination:** To facilitate project creation, assign draughtsmen, enable review rounds, and deliver completed drawings.
3. **Communication & Collaboration:** To transmit project messages, correction requests, and voice notes between assigned project collaborators.
4. **Educational Tracking & Credential Verification:** To evaluate student drafting assignments, record competency progression, and provide verifiable credentials.
5. **Billing and Accounting:** To generate project fee summaries and milestone invoices.
6. **Security & Regulatory Compliance:** To maintain audit logs, prevent unauthorized access, detect security incidents, and comply with applicable Indian statutory requirements (including CERT-In directions).

We do *not* sell your personal data. We do *not* use project drawings or personal information for unsolicited commercial advertising or behavioral profiling.

---

## 5. APPLICABLE GROUNDS FOR PROCESSING

Under the DPDP Act, 2023 and applicable Indian law, we process your personal data on the following lawful bases:
1. **Contractual Necessity (Fulfillment of Terms):** Processing necessary to perform our contractual commitments under the Terms & Conditions.
2. **Affirmative Consent:** Where required by law, we request your explicit, informed, and unambiguous affirmative consent for specific optional activities.
3. **Legitimate Uses / Legal Compliance:** Processing necessary to comply with legal obligations, enforce our legal rights, maintain 180-day security logs under CERT-In directions, or respond to valid statutory notices from law enforcement.

---

## 6. INFORMATION SUPPLIED BY USERS

Users are responsible for ensuring that all personal data and project details supplied to Archi Draft are accurate, complete, and up to date. You must not submit personal data of third parties unless you are lawfully authorized to do so.

---

## 7. AUTHENTICATION AND ACCOUNT CREDENTIALS

Authentication on Archi Draft is powered by **Google Firebase Authentication**:
- Your password is cryptographically hashed and salted by Firebase Authentication. Plain-text passwords never touch our application database or application logs.
- Session authentication utilizes industry-standard JSON Web Tokens (JWT) verified cryptographically on our serverless backend.
- You are responsible for safeguarding your login credentials. You must immediately notify us at **[SECURITY INCIDENT EMAIL — TO BE CONFIRMED]** if you suspect unauthorized access to your account.

---

## 8. PROJECT DATA AND UPLOADED DRAWINGS

Architectural drawings, structural calculations, and project specifications uploaded to Archi Draft are treated as strictly confidential business information:
- Drawings are stored securely in **Cloudflare R2 Object Storage**. Object keys are never exposed directly to public URLs.
- Access to download or view a drawing is strictly restricted on our backend to verified project members (the project owner, the assigned draughtsman, the assigned student, or authorized administrators).
- Allocation of intellectual property and derivative drawing rights is currently undergoing business-owner and qualified legal review. Archi Draft does not claim automatic ownership over drawings you upload.

---

## 9. DATA SHARING WITH SERVICE PROVIDERS

We engage trusted enterprise third-party service providers ("Data Processors") to support platform operations under binding confidentiality and data protection terms:
1. **Cloudflare, Inc. (Cloudflare Workers, D1 Database, R2 Storage):** Authoritative backend API execution, application database hosting, and secure object storage.
2. **Google LLC (Firebase Authentication):** User identity authentication, password encryption, and email verification services.
3. **[PAYMENT GATEWAY PROCESSOR — TO BE CONFIRMED]:** When commercial billing is activated, payment processing will be handled directly by a certified, PCI-DSS compliant payment aggregator.
4. **[TRANSACTIONAL EMAIL SERVICE — TO BE CONFIRMED]:** For delivering account verification, password resets, and critical workflow notifications.

We do *not* authorize our service providers to use your personal data for their own independent marketing or commercial purposes.

---

## 10. CLOUD INFRASTRUCTURE AND STORAGE

Archi Draft runs entirely on modern enterprise cloud infrastructure designed for high availability and data resilience. Application data is stored in Cloudflare D1 distributed databases and Cloudflare R2 object storage with end-to-end encryption in transit (TLS 1.3) and encryption at rest (AES-256).

---

## 11. CROSS-BORDER PROCESSING CONSIDERATIONS

While our primary market is India and our primary database configurations prioritize Indian and regional data centers, our cloud infrastructure providers (Cloudflare, Google Cloud) maintain distributed global networks for latency reduction, DDoS mitigation, and edge caching. Any cross-border data transfer complies with applicable transfer restrictions and notifications issued under the DPDP Act.

---

## 12. DATA RETENTION: STATUTORY OBLIGATIONS VS. OPERATIONAL SCHEDULES

We distinguish verified statutory obligations from proposed operational retention schedules:
- **Verified Statutory Log Mandate:** Under **CERT-In Directions (April 2022)**, system logs, security audit logs (`activity_logs`), and authentication events are maintained for a mandatory minimum period of **180 days** within Indian jurisdiction.
- **Verified Statutory Tax Records:** Invoices and payment records are preserved for **8 financial years** under Indian tax statutes (Income Tax Act Sec 44AA / CGST Act Sec 36).
- **Proposed Operational Schedules (Under Review):** Operational retention periods for completed CAD drawing archives and dormant account cleanup are **currently under business-owner and qualified legal review**. They do not constitute final platform policy.
- **Account Deletion:** When an account deletion is requested and verified, personal identifiers are erased or anonymized from active user databases, subject to retention of completed project records belonging to other users and mandatory statutory exceptions.

For full details, please review our separate **[Data Retention & Deletion Notice](file:///D:/PROJECT/Archidraft-integration-workspace/docs/08_legal_privacy/DATA_RETENTION_AND_DELETION.md)**.

---

## 13. SECURITY SAFEGUARDS

We implement rigorous technical, operational, and organizational security controls:
1. **Server-Side Authorization:** Every API request verifies user identity and role server-side in Cloudflare Workers. Flutter client-side logic is never treated as a security boundary.
2. **Cross-User Data Isolation:** Enforced access controls ensure Engineer A cannot view or access Engineer B's private projects; Draughtsmen can only access projects formally assigned to them.
3. **Encrypted Transport:** All communication between user devices and Archi Draft servers is encrypted using modern Transport Layer Security (TLS 1.2 / TLS 1.3).
4. **Least Privilege:** Administrative functions are segregated and restricted strictly to authorized studio management personnel.
5. **No Credential Logging:** Passwords, private session keys, and sensitive credentials are never written to server console logs.

---

## 14. PERSONAL-DATA BREACH RESPONSE

In the event of a confirmed personal data breach affecting Archi Draft systems:
1. We will take immediate containment, mitigation, and forensic investigation measures.
2. We will report the incident to the **Indian Computer Emergency Response Team (CERT-In)** within **6 hours** of noticing or being notified, in compliance with Direction No. 20(3)/2022-CERT-In under Section 70B(6) of the IT Act, 2000.
3. We will notify the **Data Protection Board of India** and affected users in accordance with Section 8(6) of the DPDP Act.

---

## 15. SPECIAL PROVISIONS FOR STUDENT USERS & MINORS (<18 YEARS)

The business owner has determined that Archi Draft **may allow younger students under 18 years of age** to access the Student Portal for vocational and academic drafting education. 

However, allowing minors is a **pending business decision subject to determining and implementing mandatory statutory safeguards and obtaining qualified legal review**. 

When activated for minors:
1. **Verifiable Parental Consent (Section 9(1) DPDP Act):** The platform will require verifiable consent from a parent or legal guardian prior to processing personal data of any user under 18. Parental consent alone does not resolve all requirements.
2. **Prohibition of Detrimental Processing (Section 9(2) DPDP Act):** Personal data of minors will never be processed in any manner likely to cause detrimental effects on their physical, mental, or moral well-being.
3. **Zero Tracking & Behavioral Monitoring (Section 9(3) DPDP Act):** The platform strictly prohibits behavioral monitoring, tracking, or targeted advertising directed at students under 18.
4. **Contractual Protections (Indian Contract Act, 1872):** Because contracts entered into directly by minors are void ab initio under Indian law, contractual terms must be formally acknowledged and agreed to by the parent or legal guardian on the minor's behalf.
5. **Data Minimization:** Student profiles will collect strictly necessary academic information, avoiding personal phone numbers, physical residential addresses, or unnecessary identity documents.

Until these multi-layered safeguards and legal reviews are finalized, general registration remains restricted to adults aged 18 and older.

---

## 16. APPLICABLE USER RIGHTS

Under Indian data protection laws, you have specific statutory rights regarding your personal data:
1. **Right to Access:** You may request a summary of personal data being processed about you and the identities of data fiduciaries or processors with whom it has been shared.
2. **Right to Correction and Updating:** You have the right to correct inaccurate or misleading personal data.
3. **Right to Erasure:** You may request the erasure of your personal data where it is no longer necessary, subject to lawful retention exceptions.
4. **Right to Grievance Redressal:** You have the right to have your grievances addressed by our designated Grievance Officer within statutory timeframes.
5. **Right to Nominate:** In accordance with the DPDP Act, you may nominate another individual to exercise your data rights in the event of death or incapacity.

---

## 17. WITHDRAWAL OF CONSENT & ERASURE PROCEDURES

To exercise your statutory data protection rights:
1. **Self-Service:** You can review and update your profile details directly in the **Profile** section of the app.
2. **Formal Requests:** To request account deletion, data summaries, or erasure of specific records, submit a written request to **[PRIVACY / GRIEVANCE EMAIL — TO BE CONFIRMED]**.
3. **Verification & Timeline:** We will verify your identity before processing sensitive requests and respond within the statutory timeframe (maximum **30 days** under Rule 5(9) of the IT SPDI Rules).

---

## 18. GRIEVANCE AND PRIVACY CONTACT DETAILS

In compliance with Rule 5(9) of the IT (SPDI) Rules, 2011 and Section 13 of the DPDP Act, 2023, Archi Draft has designated a **Grievance Officer**:

- **Name:** [GRIEVANCE OFFICER NAME — TO BE CONFIRMED]
- **Designation:** Grievance & Data Protection Officer
- **Entity:** [PROPRIETOR FULL LEGAL NAME — TO BE CONFIRMED] doing business as Draughtsman Studio (Sole Proprietorship)
- **Grievance Email:** `[GRIEVANCE EMAIL — TO BE CONFIRMED]`
- **General Support Email:** `[SUPPORT EMAIL — TO BE CONFIRMED]`
- **Security Incident Email:** `[SECURITY INCIDENT EMAIL — TO BE CONFIRMED]`
- **Postal Address:** [OFFICIAL POSTAL ADDRESS — TO BE CONFIRMED, ATTN: GRIEVANCE OFFICER, INDIA]
- **Statutory Resolution Period:** Within 30 days of receiving a verified complaint.

---

## 19. POLICY CHANGES AND VERSION HISTORY

We may update this Privacy Policy periodically. In the event of material changes, we will notify you through an in-app notice, email, or a revised version prompt upon your next login.

- **Version 1.0.0-DRAFT (October 2026):** Initial unified privacy policy drafted for pre-merge compliance review.
- **Version 1.1.0-DRAFT (October 2026):** Updated to reflect Sole Proprietorship business structure, pending minor student policy and safeguards under DPDP Section 9, and ongoing review of drawing IP and retention schedules.
- **Version 1.2.0-DRAFT (October 2026):** Quality review revision: removed all unverified email domain examples, distinguished statutory retention from unapproved operational proposals, and refined legal placeholders.

---

## 20. EFFECTIVE DATE

This policy shall become effective upon formal approval by business management and publication at production commercial launch.
