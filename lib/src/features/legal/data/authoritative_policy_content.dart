import '../domain/legal_document.dart';

const String kAuthoritativeTermsVersion = '1.0.0';
const String kAuthoritativePrivacyVersion = '1.0.0';

const String kAuthoritativeTermsTitle = 'Terms and Conditions';
const String kAuthoritativePrivacyTitle = 'Privacy Policy';

/// Authoritative Terms & Conditions text sourced directly from
/// `docs/08_legal_privacy/TERMS_AND_CONDITIONS_DRAFT.md`.
const String kAuthoritativeTermsAndConditionsContent = r'''
# ARCHI DRAFT — TERMS & CONDITIONS
**DOCUMENT STATUS:** DRAFT — NOT APPROVED FOR PRODUCTION
**REQUIRES QUALIFIED INDIAN LEGAL REVIEW AND BUSINESS-OWNER APPROVAL BEFORE PUBLICATION**
**PROJECT:** Archi Draft
**PARENT BRAND:** Draughtsman Studio (https://www.draughtsmanstudio.com)
**BUSINESS STRUCTURE:** Sole Proprietorship / Individual Business (Proprietor: [PROPRIETOR FULL LEGAL NAME — TO BE CONFIRMED])
**TARGET JURISDICTION:** India
**EFFECTIVE DATE:** [EFFECTIVE DATE — TO BE CONFIRMED UPON PRODUCTION RELEASE]
**VERSION:** 1.2.0-DRAFT

---

> ### CONTRACTUAL NOTICE
> These Terms & Conditions constitute a legally binding agreement between you ("User", "you") and **[PROPRIETOR FULL LEGAL NAME — TO BE CONFIRMED]**, an individual carrying on business as a **Sole Proprietorship** in India under the trade name **Draughtsman Studio** ("Archi Draft", "we", "us"). By affirmatively selecting the "I agree to the Terms & Conditions" checkbox and accessing the platform, you agree to be bound by these terms. If you do not agree, you must not access or use Archi Draft.

---

## 1. INTRODUCTION AND ACCEPTANCE

1.1. **Platform Scope:** Archi Draft is a professional architecture and engineering workflow coordination platform developed under Draughtsman Studio. The platform facilitates project brief submission, CAD drawing coordination, revision cycles, communications, and technical drafting training among clients, engineers, architects, draughtsmen, students, and studio administrators.

1.2. **Affirmative Acceptance:** You must actively accept these Terms by selecting an unselected checkbox at registration or upon the introduction of material changes. Continued use of the platform after receiving notice of updated terms shall constitute acceptance in accordance with Section 20.

---

## 2. ELIGIBILITY AND ACCOUNT REGISTRATION

2.1. **Age of Majority & General Commercial Accounts:** For Client/Engineer and Draughtsman accounts, you must be at least **18 years of age** and possess full legal capacity to contract under the **Indian Contract Act, 1872**.

2.2. **Student Portal & Younger Students (<18 Years):**
- Archi Draft may allow younger students under 18 years of age to access the Student Portal for vocational drafting and educational coursework, **subject to business-owner decisions, applicable legal requirements, and appropriate safeguards**.
- Under Section 11 of the Indian Contract Act, 1872, minors lack the capacity to enter into binding contracts, and agreements entered into directly by minors are void ab initio.
- Therefore, allowing minors is an **unresolved business decision subject to establishing comprehensive technical, operational, and legal safeguards**. When activated for users under 18, access will be contingent upon:
  1. A parent or lawful guardian executing these Terms on behalf of the minor student;
  2. The parent or guardian providing verifiable consent under Section 9 of the DPDP Act, 2023;
  3. Adherence to strict statutory bans on behavioral monitoring, tracking, or detrimental processing of children;
  4. Fulfilling any institutional educational onboarding requirements.
- Parental consent alone does not resolve every legal requirement under Indian law. Until this multi-layered framework and qualified legal review are finalized, general registration remains restricted to adults aged 18 and older.

2.3. **Account Types:** Users may register under one of four primary roles:
- **Client / Engineer:** Qualified civil engineers, structural consultants, architects, interior designers, or project clients.
- **Draughtsman:** Qualified architectural, structural, interior, or approval drafting technicians.
- **Student:** Individuals enrolled in professional drafting and architectural CAD educational courses.
- **Admin:** Authorized studio operations and administrative personnel.

2.4. **One Account Per Identity:** You may not maintain multiple fraudulent accounts or register using false contact information.

---

## 3. ACCOUNT ACCURACY AND SECURITY

3.1. **Accuracy of Information:** You agree to provide true, accurate, current, and complete information during registration and in your user profile, and to promptly update your information as needed.

3.2. **Credential Confidentiality:** You are solely responsible for maintaining the confidentiality of your login credentials (email and password). You must not share your account or authentication tokens with any unauthorized third party.

3.3. **Unauthorized Access:** You agree to immediately notify Archi Draft at **[SECURITY INCIDENT EMAIL — TO BE CONFIRMED]** upon becoming aware of any unauthorized use of your account or security breach.

---

## 4. ROLE-SPECIFIC RESPONSIBILITIES

### 4.1. Client / Engineer Responsibilities
- Provide clear, accurate, and complete project briefs, dimensions, site locations, and design specifications.
- Ensure you have all necessary rights, licenses, and authorizations to upload and share referenced architectural or structural drawings.
- Review submitted drawings diligently and provide clear, consolidated revision instructions during correction cycles.
- Settle agreed milestone fees in accordance with project financial terms.

### 4.2. Draughtsman Responsibilities
- Handle all assigned project specifications, site details, and drawings with the highest standards of professional care and strict confidentiality.
- Adhere to Indian architectural, structural, and municipal drafting standards (including National Building Code of India requirements where specified).
- Complete assigned drafting deliverables within agreed timelines.
- Never reuse, re-share, or repurpose client drawing files for third-party projects or unapproved personal portfolios.

### 4.3. Student Responsibilities
- Use the Student Portal and training exercises strictly for legitimate educational and skills-development purposes.
- Maintain academic integrity in all submitted lesson drawings, tests, and module assignments.
- Never upload plagiarized drawings or represent another technician's work as your own.
- Respect intellectual property rights in all training resources provided by Draughtsman Studio.

### 4.4. Admin Responsibilities
- Exercise administrative authorities strictly in accordance with least-privilege security principles and written studio procedures.
- Maintain strict confidentiality of user personal data and proprietary project drawings.
- Never export or disclose platform data without explicit authorization.

---

## 5. PROJECT SUBMISSION AND REVIEW

5.1. **Submission Requirements:** Projects submitted through the Engineer Panel must include required project metadata (project name, site address, drawing type, project area).

5.2. **Review and Verification:** Submitted projects may undergo administrative and technical review before being assigned to a draughtsman. Archi Draft reserves the right to decline project submissions that violate acceptable use standards, contain incomplete briefs, or propose unlawful construction activities.

---

## 6. PROJECT ASSIGNMENT WORKFLOW

6.1. **Assignment Criteria:** Projects are assigned to draughtsmen based on specialization (Architectural, Structural, Interior, Approval), workload availability, and technical competency.

6.2. **No Guaranteed Assignment:** Project submission does not guarantee immediate assignment if technical specifications require clarification or if studio capacity is constrained.

---

## 7. ASSIGNMENT ACCEPTANCE AND REJECTION

7.1. **Draughtsman Right to Decline:** An assigned draughtsman may accept or decline a proposed assignment based on technical assessment and availability within the prescribed acceptance window.

7.2. **Reassignment:** If an assignment is declined or unacknowledged within the required timeframe, the platform administrators may reassign the project to an alternative qualified draughtsman.

---

## 8. PROJECT STATUS AND COMPLETION

8.1. **Workflow Statuses:** Projects progress through defined workflow milestones: `DRAFT`, `SUBMITTED`, `ASSIGNED`, `IN_PROGRESS`, `REVIEW`, `CORRECTION_REQUESTED`, and `COMPLETED`.

8.2. **Formal Completion:** A project is marked `COMPLETED` when the client/engineer approves the final drawing deliverables, or after the expiration of the defined review window following delivery, provided no outstanding correction requests exist.

---

## 9. CORRECTIONS AND REVISION CONDITIONS

9.1. **Revision Rounds:** Projects include the number of revision rounds agreed upon in the initial project quotation or scope agreement.

9.2. **Scope of Revisions:** Corrections must pertain to the original project brief. Fundamental design changes, substantial additions to project area, or new drawing categories requested after drafting commencement may be treated as out-of-scope variations subject to additional fees and adjusted timelines.

---

## 10. SERVICE AVAILABILITY AND LIMITATIONS

10.1. **Availability:** We strive to maintain continuous platform availability, but Archi Draft is provided on an "as is" and "as available" basis. We do not warrant that platform operations will be entirely uninterrupted, error-free, or resilient against third-party network outages.

10.2. **Maintenance:** Scheduled maintenance windows will be communicated in advance where practicable. Emergency security patching may be deployed without prior notice.

---

## 11. ACCEPTABLE USE

You agree to access Archi Draft strictly for lawful professional and educational workflow management. You must comply with all applicable local, state, and national laws of India while using the service.

---

## 12. PROHIBITED CONDUCT

You expressly agree that you will **NOT**:
1. Upload any file, drawing, or content that infringes upon the copyright, patent, trademark, trade secret, or proprietary rights of any third party.
2. Upload malicious code, viruses, corrupted CAD files, or malware intended to compromise server infrastructure.
3. Attempt to bypass, circumvent, or disable server-side authorization controls or cross-user data isolation boundaries.
4. Impersonate another user, professional engineer, or studio administrator.
5. Scrape, crawl, harvest, or extract data in bulk from Archi Draft without explicit written authorization.
6. Harass, threaten, defame, or abuse other users in collaboration hub messaging or voice notes.
7. Use the platform for any fraudulent, unauthorized, or unlawful purpose.

Violations of prohibited conduct will result in immediate account suspension, project termination, and potential reporting to law enforcement authorities.

---

## 13. INTELLECTUAL PROPERTY IN THE PLATFORM

All rights, title, and interest in and to the Archi Draft platform, including its software code, interface design, brand identity, "Draughtsman Studio" trademarks, logos, typography, visual layouts, training curricula, and instructional materials are the exclusive intellectual property of the sole proprietor operating as Draughtsman Studio. You may not copy, reproduce, decompile, or create derivative works of the platform software.

---

## 14. OWNERSHIP OF UPLOADED DRAWINGS & DERIVATIVE WORKS

14.1. **User Ownership:** You retain your preexisting copyrights and title in architectural designs, structural calculations, briefs, and CAD drawings that you upload to Archi Draft.

14.2. **Pending IP Policy Determination:** The formal contractual allocation of intellectual property rights in derivative drawing revisions produced by draughtsmen, as well as the platform's portfolio display rules, is **currently undecided and subject to business-owner and qualified legal review**. Neither the platform nor any draughtsman acquires ownership of your underlying project design.

14.3. **Limited Platform License:** By uploading files to Archi Draft, you grant us a worldwide, non-exclusive, royalty-free, revocable license strictly to host, store, transfer, format, and display the files as necessary to operate the platform and deliver the requested workflow services to you and your assigned project collaborators.

14.4. **Third-Party Infringement:** You warrant that you possess all requisite authorizations to upload any third-party plans, survey maps, or engineering drawings. You agree to indemnify and hold Archi Draft harmless from any third-party copyright claims arising from materials you upload.

---

## 15. CONFIDENTIALITY OBLIGATIONS

15.1. **Confidential Information:** All non-public architectural drawings, site coordinates, structural details, engineering calculations, and project communications shared on Archi Draft constitute **Confidential Information**.

15.2. **Non-Disclosure:** Users agree to maintain the confidentiality of all project information they access. Draughtsmen and students agree that they will not disclose, publish, reproduce, or distribute confidential client drawings to any third party without explicit prior written authorization from the project owner.

---

## 16. THIRD-PARTY SERVICES

Archi Draft relies on enterprise third-party services, including Google Firebase Authentication and Cloudflare infrastructure. We are not liable for outages, delays, or service degradations directly resulting from failures of these third-party infrastructure providers.

---

## 17. SUSPENSION AND TERMINATION

17.1. **Termination by User:** You may stop using the platform at any time and request account closure in accordance with Section 18.

17.2. **Termination by Archi Draft:** We reserve the right to suspend or terminate your account immediately upon notice if:
- You commit a material breach of these Terms or our Acceptable Use Policy.
- Required by law enforcement or statutory directives.
- Your conduct threatens the security, integrity, or legal compliance of the platform or other users.

---

## 18. ACCOUNT DELETION & RETENTION OF PROJECT RECORDS

You may request account deletion by submitting a formal request to **[PRIVACY / GRIEVANCE EMAIL — TO BE CONFIRMED]**. Account deletion will result in the erasure or anonymization of your personal profile data, subject to lawful retention exceptions (e.g., preservation of completed project drawings belonging to collaborating users and statutory audit logs). Specific operational retention schedules for completed project archives are currently subject to operational and legal review.

---

## 19. DISPUTE AND GRIEVANCE PROCEDURES

19.1. **Grievance Redressal:** If you have any dispute, concern, or complaint regarding the platform or data handling, you should first contact our designated Grievance Officer:
- **Email:** `[GRIEVANCE EMAIL — TO BE CONFIRMED]`
- **Response SLA:** Within 30 days of receiving your written communication in compliance with Rule 5(9) of the IT SPDI Rules.

19.2. **Amicable Settlement:** The parties agree to use good-faith efforts to resolve any dispute through informal discussions prior to initiating formal legal proceedings.

---

## 20. CHANGES TO TERMS

We reserve the right to modify these Terms & Conditions to reflect technical updates, service modifications, or legislative amendments. In the event of material changes, we will provide at least 15 days' notice via email or an in-app banner. Your continued use following the effective date of updated terms signifies your agreement to the revised Terms.

---

## 21. GOVERNING LAW AND JURISDICTION

These Terms & Conditions shall be governed by, construed, and enforced in accordance with the **laws of the Republic of India**. Subject to the dispute resolution provisions herein, the courts located in **[CITY / STATE, INDIA — TO BE CONFIRMED BY PROPRIETOR]** shall have exclusive jurisdiction over any legal proceeding arising out of or relating to these Terms.
''';

/// Authoritative Privacy Policy text sourced directly from
/// `docs/08_legal_privacy/PRIVACY_POLICY_DRAFT.md`.
const String kAuthoritativePrivacyPolicyContent = r'''
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
''';

const LegalDocument kDefaultEffectiveTermsDocument = LegalDocument(
  id: 'doc-terms-v1',
  documentType: 'TERMS_AND_CONDITIONS',
  version: kAuthoritativeTermsVersion,
  title: kAuthoritativeTermsTitle,
  content: kAuthoritativeTermsAndConditionsContent,
  status: 'EFFECTIVE',
  isMandatory: true,
  locale: 'en-IN',
  effectiveAt: '2026-10-24T00:00:00Z',
);

const LegalDocument kDefaultEffectivePrivacyDocument = LegalDocument(
  id: 'doc-priv-v1',
  documentType: 'PRIVACY_POLICY',
  version: kAuthoritativePrivacyVersion,
  title: kAuthoritativePrivacyTitle,
  content: kAuthoritativePrivacyPolicyContent,
  status: 'EFFECTIVE',
  isMandatory: false,
  locale: 'en-IN',
  effectiveAt: '2026-10-24T00:00:00Z',
);
