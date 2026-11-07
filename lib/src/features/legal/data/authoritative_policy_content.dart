import '../domain/legal_document.dart';
export 'business_configuration.dart';

const String kAuthoritativeTermsVersion = '1.0.0';
const String kAuthoritativePrivacyVersion = '1.0.0';
const String kAuthoritativeAiDisclaimerVersion = '1.0.0';
const String kAuthoritativeEngineeringDisclaimerVersion = '1.0.0';
const String kAuthoritativeCadOwnershipVersion = '1.0.0';
const String kAuthoritativeRevisionPolicyVersion = '1.0.0';
const String kAuthoritativeRefundPolicyVersion = '1.0.0';

const String kAuthoritativeTermsTitle = 'Platform Terms and Conditions';
const String kAuthoritativePrivacyTitle = 'Privacy Policy & Data Protection Notice';
const String kAuthoritativeAiDisclaimerTitle = 'Pixmint Bot & AI Usage Disclaimer';
const String kAuthoritativeEngineeringDisclaimerTitle =
    'Architectural and Engineering Professional Services Disclaimer';
const String kAuthoritativeCadOwnershipTitle =
    'CAD Drawing Ownership and Intellectual Property Framework';
const String kAuthoritativeRevisionPolicyTitle = 'Project Revision and Correction Policy';
const String kAuthoritativeRefundPolicyTitle = 'Subscription, Cancellation and Refund Policy';

/// Authoritative Terms & Conditions text sourced directly from
/// `shared/legal/documents/terms_and_conditions/v1.0.0.md`.
const String kAuthoritativeTermsAndConditionsContent = r'''
# ARCHI DRAFT — PLATFORM TERMS AND CONDITIONS

**DOCUMENT STATUS:** PENDING_LEGAL_REVIEW / DRAFT (NOT APPROVED FOR UNRESTRICTED PRODUCTION PUBLICATION)  
**BUSINESS STRUCTURE:** Sole Proprietorship  
**LEGAL PROPRIETOR:** MOHAMMED MOSIN S  
**OPERATING BRAND:** DRAUGHTSMAN STUDIO  
**PRODUCT / PLATFORM:** ARCHI DRAFT  
**APPLICATION WEBSITE:** https://archidraft.draughtsmanstudio.com  
**BUSINESS WEBSITE:** https://draughtsmanstudio.com  
**GRIEVANCE CONTACT:** mosin@draughtsmanstudio.com  
**SUPPORT CONTACT:** support@draughtsmanstudio.com  
**PHYSICAL ADDRESS:** PENDING_VERIFICATION (Official physical establishment address in India pending formal confirmation)  
**GRIEVANCE OFFICER APPOINTMENT:** PENDING_VERIFICATION (Formal statutory appointment under IT Rules pending confirmation)  
**TARGET JURISDICTION:** Republic of India  
**DOCUMENT VERSION:** 1.0.0  
**EFFECTIVE DATE:** PENDING_BUSINESS_AND_LEGAL_APPROVAL  

---

> ### CONTRACTUAL NOTICE
> These Terms and Conditions ("Terms", "Agreement") constitute a legally binding contract under the **Indian Contract Act, 1872** between you ("User", "you", "your") and **DRAUGHTSMAN STUDIO**, a sole proprietorship operated by **MOHAMMED MOSIN S** ("Archi Draft", "we", "us", "our").
> By accessing, registering for, or using the Archi Draft platform, web applications, or associated services, you affirmatively accept and agree to be bound by these Terms, our Privacy Policy, AI Usage Disclaimer, and Architectural & Engineering Disclaimer. If you do not agree to these Terms, you must immediately refrain from creating an account and cease using the platform.

---

## 1. PLATFORM SCOPE AND SERVICES

1.1. **Core Purpose:** Archi Draft is a technical workflow coordination and vocational drafting education portal operated under Draughtsman Studio. The platform facilitates architectural and engineering project brief submissions, CAD drawing exchanges, correction tracking, and structured vocational training modules among consulting engineers, professional draughtsmen, architectural students, and studio administrators.

1.2. **Service Boundaries:** Archi Draft provides digital collaboration tools, Cloudflare R2 drawing storage, version-tracking mechanisms, and educational curriculum management. The platform itself is **not** a licensed architectural firm, structural engineering consultancy, or municipal approval authority.

1.3. **Affirmative Consent:** Access to role-specific dashboard capabilities is conditioned on affirmative, unbundled acceptance of these Terms. Where material changes occur, continuing use is conditioned on explicit re-acceptance.

---

## 2. ELIGIBILITY AND REGISTRATION REQUIREMENTS

2.1. **Age of Majority for Commercial Users:** To register for a Client / Consulting Engineer account or a Professional Draughtsman account, you must be at least **18 years of age** and possess full legal capacity to enter into binding contracts under the **Indian Contract Act, 1872**.

2.2. **Student Accounts and Under-18 Safeguards:**
- Archi Draft provides specialized educational training features for students pursuing civil drafting, CAD design, and architectural visualization.
- Under Section 11 of the Indian Contract Act, 1872, individuals who have not attained the age of majority lack legal capacity to contract. Under Section 9 of the **Digital Personal Data Protection Act, 2023 (DPDP Act)**, processing the personal data of a child requires verifiable consent of the parent or lawful guardian.
- Accordingly, student accounts for individuals under 18 years of age remain **strictly subject to the operational implementation of verifiable parental consent, prohibition of behavioral tracking, and qualified legal review**. Until such technical and legal safeguards are formally certified, general self-service registration remains restricted to adults aged 18 and older.

2.3. **User Roles:** Platform accounts are segregated into four defined operational roles:
- **Client / Engineer:** Licensed consulting engineers, architects, project managers, or design principals commissioning drafting deliverables.
- **Draughtsman:** Technical drafting professionals producing 2D/3D CAD models, working drawings, and approval sheets.
- **Student:** Learners enrolled in vocational drafting curriculum, technical modules, and skill certifications.
- **Admin / Studio Admin:** Authorized studio personnel managing assignments, user verification, and platform security.

2.4. **Truthfulness of Registration:** You agree to provide true, current, and verifiable information during registration, including your legal name, active mobile number, professional qualification, and institutional affiliation where applicable. Impersonation or creation of deceptive accounts is strictly prohibited.

---

## 3. ACCOUNT SECURITY AND CREDENTIALS

3.1. **Authentication:** User authentication is powered by **Google Firebase Authentication**. Passwords are encrypted and salted using industry-standard hashing. Users are strictly responsible for maintaining credential secrecy.

3.2. **Incident Reporting:** If you discover or suspect unauthorized access to your account or any security incident, you must notify us immediately at `support@draughtsmanstudio.com`.

3.3. **Session Responsibility:** You remain legally responsible for all actions, briefs, drawing uploads, and comments transmitted under your authenticated session credentials.

---

## 4. PROFESSIONAL AND ROLE-SPECIFIC RESPONSIBILITIES

4.1. **Client / Consulting Engineer Responsibilities:**
- Ensure all uploaded briefs, survey data, site dimensions, and preliminary sketches are accurate and complete.
- Verify that you possess all intellectual property rights, licenses, or authorizations necessary to share reference architectural plans.
- Provide clear, consolidated revision instructions within agreed correction cycles.
- Acknowledge that final construction drawings must be reviewed, verified, and stamped by a licensed architect or structural engineer of record prior to physical construction.

4.2. **Draughtsman Responsibilities:**
- Prepare drafting deliverables with professional care and in accordance with Indian drafting conventions and National Building Code of India (NBC 2016) guidelines where specified.
- Maintain absolute confidentiality regarding client drawing files, project locations, and private dimensions.
- Never re-use, distribute, or publish proprietary project drawings for personal commercial gain or unauthorized third-party projects.

4.3. **Student Responsibilities:**
- Utilize training modules, lesson files, and feedback exclusively for genuine educational advancement.
- Maintain academic honesty. Plagiarism of peer assignments or submitting work generated entirely by unauthorized automated means constitutes grounds for immediate suspension without certificate issuance.

4.4. **Admin Responsibilities:**
- Administer the platform adhering to least-privilege principles, preserving the integrity of user personal data and proprietary CAD assets.

---

## 5. DOCUMENT AND DRAWING UPLOADS

5.1. **Storage Infrastructure:** Drawing files (`.dwg`, `.dxf`, `.pdf`), site images, and voice notes are stored securely on **Cloudflare R2 Object Storage**.

5.2. **Prohibited Content:** You agree not to upload any files containing malware, harmful scripts, defamatory material, drawings infringing third-party copyrights, or content contrary to Indian statutory law.

5.3. **File Scanning and Quarantine:** We reserve the right to scan uploaded files for security threats and automatically quarantine any file suspected of containing malicious payloads.

---

## 6. INTELLECTUAL PROPERTY AND CAD OWNERSHIP

6.1. **Background Intellectual Property:** Users retain all pre-existing ownership rights, copyrights, and trade secrets in the drawings, briefs, and sketches they upload to Archi Draft.

6.2. **Limited Platform License:** By uploading project materials to Archi Draft, you grant DRAUGHTSMAN STUDIO a non-exclusive, worldwide, royalty-free, limited license solely to host, cache, render, display, and transmit such materials to your assigned collaborators and project personnel for the sole purpose of operating the workflow.

6.3. **No Automatic Ownership Transfer:** Using Archi Draft does **not** automatically transfer copyright or intellectual property ownership in completed drawings from the author or commissioning engineer to the platform or to assigned draughtsmen. Detailed ownership allocation is governed by our CAD Drawing Ownership and Intellectual Property Framework and bilateral commercial agreements.

---

## 7. AI ASSISTANCE AND AUTOMATED TOOLS (PIXMINT BOT)

7.1. **Pixmint Bot Status:** Archi Draft features an interactive AI assistant branded as **Pixmint Bot** designed to provide technical guidance, navigational support, and drafting best-practice references.

7.2. **Non-Professional Nature:** Pixmint Bot is **not** a licensed architect, structural engineer, municipal surveyor, or legal advisor. AI-generated suggestions, dimensions, and formula calculations are advisory only and must never be treated as certified engineering advice.

7.3. **Mandatory Human Verification:** Every measurement, drawing note, structural calculation, and code reference suggested by Pixmint Bot must be independently evaluated, verified, and approved by a qualified human professional before being incorporated into construction drawings.

---

## 8. REVISION CYCLES AND SCOPE BOUNDARIES

8.1. **Included Revision Rounds:** Standard project commissions include **two (2) revision rounds** to rectify drafting inaccuracies, minor dimensional adjustments, or minor annotation changes within the original project brief.

8.2. **Scope Expansions:** Requests involving structural redesign, alteration of built-up area, addition of new floors, or changes in fundamental municipal sanction requirements constitute out-of-scope revisions and require separate commercial approval.

---

## 9. FINANCIAL TERMS, PAYMENTS, AND REFUNDS

9.1. **Commercial Terms:** Specific fees for drafting commissions, student course enrollment, or platform subscriptions will be clearly communicated before transaction confirmation.

9.2. **Payment Processing:** When commercial payment features are enabled, transactions will be handled through PCI-DSS compliant certified payment aggregators.

9.3. **Cancellations and Refunds:** Milestone-based cancellations and refund evaluations are administered strictly in accordance with our Subscription, Cancellation and Refund Policy.

---

## 10. DISCLAIMER OF PROFESSIONAL LIABILITY

10.1. **No Professional Consultancy:** DRAUGHTSMAN STUDIO, its sole proprietor MOHAMMED MOSIN S, and Archi Draft do not provide licensed architectural or structural engineering services. All drawings, files, and communications transmitted via the platform must be independently approved by licensed professionals of record holding statutory registration under the Architects Act, 1972 or appropriate state engineering registers.

10.2. **Balanced Coordination Warranty:** While Archi Draft exercises reasonable skill and care in maintaining software availability and data integrity:
- We do not warrant that drawing files will be uninterrupted or error-free under all CAD software versions.
- We are not liable for on-site execution defects, contractor misinterpretations, structural failures, or municipal rejection of permit applications resulting from unverified drawings.
- In no event shall our aggregate liability for direct technical platform failures exceed the total platform service fees paid by you for the specific affected project in the six (6) months preceding the claim.

---

## 11. SUSPENSION AND TERMINATION

11.1. **Termination for Cause:** We may suspend or terminate your account immediately without prior notice if you violate these Terms, engage in unlawful conduct, tamper with security infrastructure, or infringe intellectual property rights.

11.2. **Voluntary Closure:** You may request account deletion at any time by contacting `support@draughtsmanstudio.com`. Personal profile information will be anonymized or erased in accordance with our Privacy Policy and statutory record retention requirements.

---

## 12. GRIEVANCE REDRESSAL AND GOVERNING LAW

12.1. **Grievance Contact:** In compliance with the Information Technology Act, 2000 and SPDI Rules, any grievances, disputes, or concerns regarding platform operations may be submitted to:
- **Grievance Email:** `mosin@draughtsmanstudio.com`
- **Customer Support Email:** `support@draughtsmanstudio.com`
- **Response Timeline:** We will acknowledge grievances promptly and aim to resolve verified complaints within thirty (30) days.

12.2. **Governing Law:** This Agreement shall be governed by, construed, and enforced exclusively in accordance with the **substantive laws of the Republic of India**.

12.3. **Jurisdiction:** Subject to good-faith informal dispute resolution, the competent courts in India (location to be confirmed upon formal verification) shall have exclusive jurisdiction over all claims arising under this Agreement.

---

## 13. AMENDMENTS AND CONTACT

We reserve the right to revise these Terms to reflect technical updates, statutory changes, or business model enhancements. When changes are made, we will update the version number and provide notification through the platform.

For inquiries regarding these Terms:
- **Entity:** DRAUGHTSMAN STUDIO (Sole proprietorship of MOHAMMED MOSIN S)
- **Email:** `support@draughtsmanstudio.com` | `mosin@draughtsmanstudio.com`
''';

/// Authoritative Privacy Policy text sourced directly from
/// `shared/legal/documents/privacy_policy/v1.0.0.md`.
const String kAuthoritativePrivacyPolicyContent = r'''
# ARCHI DRAFT — PRIVACY POLICY & DATA PROTECTION NOTICE

**DOCUMENT STATUS:** PENDING_LEGAL_REVIEW / DRAFT (NOT APPROVED FOR UNRESTRICTED PRODUCTION PUBLICATION)  
**DATA FIDUCIARY:** DRAUGHTSMAN STUDIO — a sole proprietorship operated by MOHAMMED MOSIN S  
**OPERATING BRAND:** DRAUGHTSMAN STUDIO  
**PRODUCT / APPLICATION:** ARCHI DRAFT  
**APPLICATION WEBSITE:** https://archidraft.draughtsmanstudio.com  
**BUSINESS WEBSITE:** https://draughtsmanstudio.com  
**GRIEVANCE CONTACT:** mosin@draughtsmanstudio.com  
**PRIVACY / SUPPORT CONTACT:** support@draughtsmanstudio.com  
**PHYSICAL ADDRESS:** PENDING_VERIFICATION (Official physical establishment address in India pending formal confirmation)  
**GRIEVANCE OFFICER APPOINTMENT:** PENDING_VERIFICATION (Formal statutory appointment under IT Rules pending confirmation)  
**TARGET JURISDICTION:** Republic of India  
**DOCUMENT VERSION:** 1.0.0  
**EFFECTIVE DATE:** PENDING_BUSINESS_AND_LEGAL_APPROVAL  

---

> ### PRIVACY COMMITMENT
> DRAUGHTSMAN STUDIO, operated as a sole proprietorship by MOHAMMED MOSIN S ("Archi Draft", "we", "us", "our"), is committed to processing your personal data transparently, securely, and in accordance with Indian data protection legislation, including the **Digital Personal Data Protection Act, 2023 (DPDP Act)**, the **Information Technology Act, 2000 (IT Act)**, the **Information Technology (Reasonable Security Practices and Procedures and Sensitive Personal Data or Information) Rules, 2011 (SPDI Rules)**, and directions issued by the **Indian Computer Emergency Response Team (CERT-In)**.

---

## 1. DATA FIDUCIARY IDENTITY

For the purposes of the DPDP Act, 2023, the data fiduciary responsible for determining the purposes and means of processing personal data on Archi Draft is:
- **Legal Entity:** DRAUGHTSMAN STUDIO (Sole proprietorship of MOHAMMED MOSIN S)
- **Primary Data Privacy Contact:** `support@draughtsmanstudio.com`
- **Grievance Redressal Contact:** `mosin@draughtsmanstudio.com`
- **Principal Address:** PENDING_VERIFICATION (Awaiting formal confirmation of physical business address)

---

## 2. SCOPE AND APPLICABILITY

This Privacy Policy applies to all individuals who register, access, or utilize Archi Draft across our web application portals:
1. **Client / Consulting Engineer Portal:** For submitting briefs, uploading survey plans, and coordinating drafting deliverables.
2. **Draughtsman Portal:** For reviewing assigned drafting tasks, submitting CAD drawings, and logging project milestones.
3. **Student Portal:** For vocational drafting training, CAD curriculum, module progress, and competency assessments.
4. **Admin Portal:** For authorized administrative personnel conducting operations, verification, and technical support.

---

## 3. CATEGORIES OF PERSONAL DATA COLLECTED

In strict accordance with data minimization principles, Archi Draft collects only personal data necessary for workflow coordination, professional authentication, and educational delivery:

### 3.1. Account and Identity Data
- **Full Legal Name**
- **Email Address**
- **Encrypted Password Hash** (processed and secured via Google Firebase Authentication)
- **Assigned User Role** (`ENGINEER`, `DRAUGHTSMAN`, `STUDENT`, `ADMIN`)
- **Unique Identifier** (Firebase User UID)

### 3.2. Professional and Profile Information
- **Contact Telephone / Mobile Number**
- **Professional Qualifications** (e.g., B.Arch, B.Tech Civil, Diploma in Civil)
- **Firm / Company Name** (for Consulting Engineers and Draughtsmen)
- **College / Institutional Affiliation** (for Students)
- **Drafting Specialization** (Architectural, Structural, Electrical/MEP, Municipal Approvals)
- **Postal / Work Address** (optional)

### 3.3. Project and Technical Workflow Data
- **Project Briefs and Metadata** (Project Name, Site Address, Drawing Category, Built-up Area)
- **CAD Drawing Files and Documents** (`.dwg`, `.dxf`, `.pdf`, `.rvt`, `.ifc`) stored in Cloudflare R2
- **Site Photographs and Reference Sketches** (`.jpg`, `.png`)
- **Audio Voice Notes and Correction Recordings** (`.webm`, `.m4a`, `.wav`)
- **Correction Instructions and Comments** exchanged in project hubs

### 3.4. Academic and Training Records (Student Users Only)
- **Lesson Progression and Completion Metrics**
- **Drafting Assignment Submissions and Practical Exercises**
- **Evaluation Scores, Competency Rubrics, and Instructor Feedback**
- **Issued Certificates of Completion and Verification Tokens**

### 3.5. Security and Diagnostic Logs
- **Session Timestamps and Activity Logs**
- **SHA-256 Hashed IP Addresses** (collected during security-sensitive actions)
- **Browser User-Agent and Device Telemetry**

---

## 4. PURPOSES OF PROCESSING AND LAWFUL BASES

Under Section 4 and Section 7 of the DPDP Act, 2023, we process your personal data on the following lawful grounds:
1. **Contractual Necessity (Terms & Conditions):** Account creation, authentication, project assignment, CAD file delivery, and student progress tracking.
2. **Affirmative Consent:** Optional profile additions, voice note recordings, and voluntary surveys.
3. **Legal Compliance:** Mandatory CERT-In 180-day security logging, tax accounting (8 years), and responding to statutory notices.

We do **not** sell personal data. We do **not** engage in cross-site behavioral profiling or sell user project data to third-party advertising networks.

---

## 5. CLOUD INFRASTRUCTURE AND DATA PROCESSORS

Archi Draft operates on enterprise cloud platforms bound by data processing and confidentiality obligations:
1. **Cloudflare, Inc. (Cloudflare Workers, D1 Database, R2 Object Storage):** Serverless API execution, relational application data storage, and encrypted object storage for project drawings.
2. **Google LLC (Firebase Authentication):** User identity, encrypted credentials, password hashing, and email verification.
3. **Third-Party AI Services (Pixmint Bot):** Queries processed for technical guidance.
4. **Commercial Payment Gateways (Pending Integration):** Certified PCI-DSS compliant payment processing.

---

## 6. STATUTORY LOG RETENTION VS. OPERATIONAL ARCHIVES

6.1. **Mandatory Statutory Logs:**
- Under **Direction No. 20(3)/2022-CERT-In**, system logs, access logs, and user consent records are retained for a minimum of **180 days** within Indian jurisdiction.
- Financial transaction records and invoices are maintained for **8 financial years** under Indian tax laws.

6.2. **Operational Drawing Archives (Subject to Review):**
- Operational retention periods for completed CAD drawing archives and project revision histories are currently under business review.

---

## 7. SAFEGUARDS FOR STUDENT USERS AND MINORS (<18 YEARS)

7.1. **Statutory Alignment:** Under Section 9 of the DPDP Act, 2023:
- Verifiable parental or lawful guardian consent is mandatory prior to processing personal data of individuals under 18 years of age.
- The platform strictly prohibits behavioral monitoring, tracking, or targeted advertising directed at students under 18.

7.2. **Current Implementation Status:** Self-service registration remains restricted to adults aged 18 and older until formal operational certification of under-18 parental verification safeguards.

---

## 8. STATUTORY USER RIGHTS UNDER DPDP ACT, 2023

Data principals hold the rights of access, correction, erasure, grievance redressal, and nomination.

---

## 9. HOW TO EXERCISE YOUR RIGHTS & GRIEVANCE REDRESSAL

- **Primary Privacy Email:** `support@draughtsmanstudio.com`
- **Grievance Redressal Email:** `mosin@draughtsmanstudio.com`
- **Statutory Resolution Period:** Within thirty (30) days of receiving a verified request.
- **Physical Address:** PENDING_VERIFICATION
''';

/// Authoritative AI Disclaimer text sourced directly from
/// `shared/legal/documents/ai_usage_disclaimer/v1.0.0.md`.
const String kAuthoritativeAiDisclaimerContent = r'''
# ARCHI DRAFT — PIXMINT BOT & ARTIFICIAL INTELLIGENCE USAGE DISCLAIMER

**DOCUMENT STATUS:** PENDING_LEGAL_REVIEW / DRAFT  
**OPERATING BRAND:** DRAUGHTSMAN STUDIO  
**LEGAL PROPRIETOR:** MOHAMMED MOSIN S  
**PRODUCT / PLATFORM:** ARCHI DRAFT  
**AI ASSISTANT BRAND:** PIXMINT BOT  
**CONTACT EMAIL:** support@draughtsmanstudio.com  
**DOCUMENT VERSION:** 1.0.0  

---

> ### CRITICAL NOTICE ON ARTIFICIAL INTELLIGENCE USAGE
> Pixmint Bot is an automated artificial intelligence assistant, NOT a licensed architect, registered structural consultant, chartered engineer, or legal advisor.
> Any output, drawing dimension, calculation, formula, code excerpt, or recommendation provided by Pixmint Bot is for preliminary informational and educational purposes only and must **never** be substituted for professional engineering judgment.

## 1. MANDATORY HUMAN-IN-THE-LOOP VERIFICATION
Every measurement, structural calculation, and building code reference suggested by Pixmint Bot must be independently evaluated, verified, and stamped by a qualified and licensed human professional prior to construction or municipal filing.

## 2. LIMITATION OF LIABILITY
DRAUGHTSMAN STUDIO and MOHAMMED MOSIN S assume no liability for calculation errors, structural defects, municipal permit rejections, or site accidents resulting from unverified reliance on Pixmint Bot suggestions.
''';

/// Authoritative Engineering Disclaimer text sourced directly from
/// `shared/legal/documents/engineering_disclaimer/v1.0.0.md`.
const String kAuthoritativeEngineeringDisclaimerContent = r'''
# ARCHI DRAFT — ARCHITECTURAL AND ENGINEERING PROFESSIONAL SERVICES DISCLAIMER

**DOCUMENT STATUS:** PENDING_LEGAL_REVIEW / DRAFT  
**OPERATING BRAND:** DRAUGHTSMAN STUDIO  
**LEGAL PROPRIETOR:** MOHAMMED MOSIN S  
**PRODUCT / PLATFORM:** ARCHI DRAFT  
**CONTACT EMAIL:** support@draughtsmanstudio.com  
**DOCUMENT VERSION:** 1.0.0  

---

> ### IMPORTANT PROFESSIONAL SERVICES DISCLAIMER
> Archi Draft is a technical workflow and educational collaboration portal, NOT a licensed architectural firm or structural engineering consultancy.
> Neither DRAUGHTSMAN STUDIO nor MOHAMMED MOSIN S acts as an Architect of Record or Structural Engineer of Record for projects coordinated on the platform.

## 1. PROFESSIONAL RESPONSIBILITY
The consulting engineer or registered architect commissioning drafting deliverables remains solely responsible for soil testing, structural calculations, dead/live load sizing, and compliance with the National Building Code of India (NBC 2016) and municipal bye-laws.

## 2. ON-SITE EXECUTION
Archi Draft does not provide on-site supervision or quality control testing. All drawings must be verified and stamped by registered professionals prior to site execution.
''';

/// Authoritative CAD Ownership Framework text sourced directly from
/// `shared/legal/documents/cad_ownership_framework/v1.0.0.md`.
const String kAuthoritativeCadOwnershipContent = r'''
# ARCHI DRAFT — CAD DRAWING OWNERSHIP AND INTELLECTUAL PROPERTY FRAMEWORK

**DOCUMENT STATUS:** PENDING_LEGAL_REVIEW / DRAFT  
**OPERATING BRAND:** DRAUGHTSMAN STUDIO  
**LEGAL PROPRIETOR:** MOHAMMED MOSIN S  
**PRODUCT / PLATFORM:** ARCHI DRAFT  
**GOVERNING STATUTE:** Indian Copyright Act, 1957  
**DOCUMENT VERSION:** 1.0.0  

---

> ### INTELLECTUAL PROPERTY NOTICE
> No automatic transfer of copyright or intellectual property occurs merely by uploading or processing drawings on Archi Draft.

## 1. BACKGROUND IP
Clients and consulting engineers retain all pre-existing ownership rights, copyright, and trade secrets in briefs, sketches, and files uploaded to the platform.

## 2. LIMITED PLATFORM LICENSE
Users grant Draughtsman Studio a limited, revocable license strictly to host files on Cloudflare R2 and render previews for assigned collaborators to operate the workflow.

## 3. COMPLETED DELIVERABLES
Ownership in completed CAD drawings transfers to the commissioning client only upon full settlement of all agreed project milestone fees, subject to bilateral written agreement.
''';

/// Authoritative Revision Policy text sourced directly from
/// `shared/legal/documents/revision_policy/v1.0.0.md`.
const String kAuthoritativeRevisionPolicyContent = r'''
# ARCHI DRAFT — PROJECT REVISION AND CORRECTION POLICY

**DOCUMENT STATUS:** PENDING_BUSINESS_APPROVAL / DRAFT  
**OPERATING BRAND:** DRAUGHTSMAN STUDIO  
**LEGAL PROPRIETOR:** MOHAMMED MOSIN S  
**PRODUCT / PLATFORM:** ARCHI DRAFT  
**DOCUMENT VERSION:** 1.0.0  

---

## 1. INCLUDED REVISION ROUNDS
Every standard project brief includes **two (2) revision rounds** (`included_revision_rounds = 2`) for minor dimensional adjustments, drafting errors, and annotation corrections within the original project brief.

## 2. SCOPE EXPANSIONS
Major structural redesigns, alterations of built-up area, addition of new storeys, or complete conceptual changes exceed the original brief and constitute billable scope expansions.

## 3. REVIEW WINDOW
Clients have seven (7) calendar days following deliverable upload to submit consolidated revision instructions.
''';

/// Authoritative Cancellation & Refund Policy text sourced directly from
/// `shared/legal/documents/cancellation_refund_policy/v1.0.0.md`.
const String kAuthoritativeRefundPolicyContent = r'''
# ARCHI DRAFT — SUBSCRIPTION, CANCELLATION AND REFUND POLICY

**DOCUMENT STATUS:** PENDING_BUSINESS_APPROVAL & PENDING_LEGAL_REVIEW / DRAFT  
**OPERATING BRAND:** DRAUGHTSMAN STUDIO  
**LEGAL PROPRIETOR:** MOHAMMED MOSIN S  
**PRODUCT / PLATFORM:** ARCHI DRAFT  
**DOCUMENT VERSION:** 1.0.0  

---

## 1. MILESTONE CANCELLATION
- **Pre-Assignment:** 100% refund of milestone fee if canceled prior to draughtsman assignment.
- **In-Progress:** Pro-rata refund based on verified hours expended and preliminary CAD work completed.
- **Delivered Milestone:** Non-refundable once drawing files have been accessed or downloaded.

## 2. STUDENT COURSE REFUNDS
Full refund within seven (7) calendar days of enrollment provided course progression is under 15% and no credential has been issued.
''';

const LegalDocument kDefaultEffectiveTermsDocument = LegalDocument(
  id: 'doc-terms-v1-0-0',
  documentType: 'TERMS_AND_CONDITIONS',
  version: kAuthoritativeTermsVersion,
  title: kAuthoritativeTermsTitle,
  content: kAuthoritativeTermsAndConditionsContent,
  status: 'PENDING_LEGAL_REVIEW',
  isMandatory: true,
  locale: 'en-IN',
  effectiveAt: null,
);

const LegalDocument kDefaultEffectivePrivacyDocument = LegalDocument(
  id: 'doc-priv-v1-0-0',
  documentType: 'PRIVACY_POLICY',
  version: kAuthoritativePrivacyVersion,
  title: kAuthoritativePrivacyTitle,
  content: kAuthoritativePrivacyPolicyContent,
  status: 'PENDING_LEGAL_REVIEW',
  isMandatory: false,
  locale: 'en-IN',
  effectiveAt: null,
);

const LegalDocument kDefaultAiDisclaimerDocument = LegalDocument(
  id: 'doc-ai-v1-0-0',
  documentType: 'AI_USAGE_DISCLAIMER',
  version: kAuthoritativeAiDisclaimerVersion,
  title: kAuthoritativeAiDisclaimerTitle,
  content: kAuthoritativeAiDisclaimerContent,
  status: 'PENDING_LEGAL_REVIEW',
  isMandatory: true,
  locale: 'en-IN',
  effectiveAt: null,
);

const LegalDocument kDefaultEngineeringDisclaimerDocument = LegalDocument(
  id: 'doc-eng-v1-0-0',
  documentType: 'ENGINEERING_DISCLAIMER',
  version: kAuthoritativeEngineeringDisclaimerVersion,
  title: kAuthoritativeEngineeringDisclaimerTitle,
  content: kAuthoritativeEngineeringDisclaimerContent,
  status: 'PENDING_LEGAL_REVIEW',
  isMandatory: true,
  locale: 'en-IN',
  effectiveAt: null,
);

const LegalDocument kDefaultCadOwnershipDocument = LegalDocument(
  id: 'doc-cad-v1-0-0',
  documentType: 'CAD_OWNERSHIP_FRAMEWORK',
  version: kAuthoritativeCadOwnershipVersion,
  title: kAuthoritativeCadOwnershipTitle,
  content: kAuthoritativeCadOwnershipContent,
  status: 'PENDING_LEGAL_REVIEW',
  isMandatory: true,
  locale: 'en-IN',
  effectiveAt: null,
);

const LegalDocument kDefaultRevisionPolicyDocument = LegalDocument(
  id: 'doc-rev-v1-0-0',
  documentType: 'REVISION_POLICY',
  version: kAuthoritativeRevisionPolicyVersion,
  title: kAuthoritativeRevisionPolicyTitle,
  content: kAuthoritativeRevisionPolicyContent,
  status: 'PENDING_BUSINESS_APPROVAL',
  isMandatory: false,
  locale: 'en-IN',
  effectiveAt: null,
);

const LegalDocument kDefaultRefundPolicyDocument = LegalDocument(
  id: 'doc-ref-v1-0-0',
  documentType: 'CANCELLATION_REFUND_POLICY',
  version: kAuthoritativeRefundPolicyVersion,
  title: kAuthoritativeRefundPolicyTitle,
  content: kAuthoritativeRefundPolicyContent,
  status: 'PENDING_BUSINESS_APPROVAL',
  isMandatory: false,
  locale: 'en-IN',
  effectiveAt: null,
);

const List<LegalDocument> kAllCanonicalDefaultDocuments = [
  kDefaultEffectiveTermsDocument,
  kDefaultEffectivePrivacyDocument,
  kDefaultAiDisclaimerDocument,
  kDefaultEngineeringDisclaimerDocument,
  kDefaultCadOwnershipDocument,
  kDefaultRevisionPolicyDocument,
  kDefaultRefundPolicyDocument,
];
