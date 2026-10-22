# ARCHI DRAFT — FREQUENTLY ASKED QUESTIONS (FAQ)
**DOCUMENT STATUS:** DRAFT — VERIFIED APPLICATION BEHAVIOR & ROLE-AWARE FAQ  
**PROJECT:** Archi Draft  
**PARENT BRAND:** Draughtsman Studio (https://www.draughtsmanstudio.com)  
**BUSINESS STRUCTURE:** Sole Proprietorship / Individual Business (Proprietor: [PROPRIETOR FULL LEGAL NAME — TO BE CONFIRMED])  
**TARGET JURISDICTION:** India  
**DATE:** OCTOBER 2026 (QUALITY REVIEW REVISION)  
**VERSION:** 1.2.0-DRAFT  

---

> ### NOTE ON ACCURACY
> All answers in this FAQ reflect the *actual, verified technical capabilities* of the current Archi Draft application. Where a feature or policy is in active development, awaiting business-owner decision, or subject to future phased release (such as automated self-service account erasure, live online payment gateways, or student onboarding for minors), it is explicitly marked as `[PENDING DECISION / PROPOSED FUTURE CAPABILITY]`.

---

## 1. GETTING STARTED & REGISTRATION

### Q1: What is Archi Draft?
**A:** Archi Draft is a professional cloud workspace developed by an individual business / sole proprietorship operating as **Draughtsman Studio** to coordinate architectural, structural, and interior drafting workflows in India. It connects Clients, Consulting Engineers, Architects, Draughtsmen, Students, and Studio Administrators through dedicated panels, centralized CAD file storage, revision tracking, and collaboration hubs.

### Q2: How do I create an account?
**A:** Click **Get Started** or **Register** on the landing page, choose your role (Client/Engineer, Draughtsman, or Student), and enter your full name, email address, mobile number, and password. After registration, a verification email is sent to your address.

### Q3: What qualifications do I need to join as an Engineer or Draughtsman?
**A:** Clients and Consulting Engineers typically hold professional qualifications in Civil Engineering, Structural Engineering, Architecture, or Interior Design. Draughtsmen select their technical specialization (Architectural, Structural, Interior, or Municipal Approval). You can add your qualification and firm name in your profile.

### Q4: Are students under 18 allowed to register?
**A:** `[PENDING BUSINESS DECISION & LEGAL SAFEGUARDS]` The platform proposes to allow younger students under 18 years of age (such as vocational drafting, ITI, or polytechnic diploma students). However, allowing minors is an unresolved business decision subject to determining and implementing mandatory statutory safeguards under Section 9 of the DPDP Act, 2023 (including verifiable parental consent, an absolute prohibition on tracking and behavioral monitoring, and protection against detrimental processing), guardian execution of contracts under the Indian Contract Act, 1872, and qualified legal review. Parental consent alone does not resolve every legal requirement. Until these multi-layered safeguards are fully established, general registration remains restricted to adults aged 18 and older.

---

## 2. AUTHENTICATION, EMAIL VERIFICATION & PASSWORDS

### Q5: Why do I need to verify my email address?
**A:** Email verification ensures account authenticity, protects the platform from spam accounts, and confirms that project notifications and file updates reach the legitimate project owner. You must verify your email by clicking the link sent to your inbox before accessing protected dashboards.

### Q6: How do I reset my password?
**A:** On the login screen, click **Forgot Password?**, enter your registered email address, and click **Send Reset Link**. You will receive an automated secure password reset link powered by Firebase Authentication.

### Q7: Can I change my email address or user role after registration?
**A:** To maintain security and role-based data isolation, user roles (e.g., Engineer, Draughtsman, Student) cannot be self-edited after registration. If you registered under the incorrect role, contact support at **[SUPPORT EMAIL — TO BE CONFIRMED]** to request an administrative role reassignment.

---

## 3. CLIENT / ENGINEER PANEL WORKFLOWS

### Q8: How do I submit a new project for drafting?
**A:** From the Engineer Dashboard, navigate to **Projects** and click **+ New Project**. Provide the project name, physical site address, drawing type (Architectural, Structural, Interior, Approval), and estimated project area. You can then attach project briefs, reference sketches, or survey files.

### Q9: What happens after I submit a project?
**A:** Your project enters the `SUBMITTED` status and undergoes studio review. Studio administration reviews the brief and assigns a qualified Draughtsman matching your drawing specialization. Once assigned and accepted by the draughtsman, the project status advances to `IN_PROGRESS`.

### Q10: Can I cancel a submitted project?
**A:** You can cancel a project while it remains in `SUBMITTED` or `DRAFT` status directly through the project details screen. If drafting has already commenced (`IN_PROGRESS`), cancellation must be coordinated through the collaboration hub to reconcile any work already performed.

### Q11: How do I track project progress?
**A:** Open the project from your dashboard to view the **Workflow Timeline**. You will see real-time milestone indicators (`DRAFT` → `SUBMITTED` → `ASSIGNED` → `IN_PROGRESS` → `REVIEW` → `COMPLETED`).

---

## 4. DRAUGHTSMAN PANEL WORKFLOWS

### Q12: How do I receive drafting assignments?
**A:** When an administrator matches your specialization (Architectural, Structural, Interior, Approval) to an active project, you will receive an assignment notification. You can inspect the project brief and attachments from your **Studio** or **Assignments** tab.

### Q13: Can I accept or decline an assignment?
**A:** Yes. Draughtsmen have the professional right to review project requirements and either **Accept** or **Decline** an assignment based on workload and technical capability. Declining an assignment returns the project to the administrative pool for reassignment without penalty.

### Q14: Where do I upload completed drawings?
**A:** Once you accept an assignment, open the project's **Workspace**. Under the **Drawings** section, click **Upload Drawing Version** to submit your completed `.dwg`, `.dxf`, or `.pdf` files along with revision notes.

### Q15: How do I communicate with the project engineer?
**A:** Each project features an integrated **Collaboration Hub**. You can exchange text messages and record audio voice notes directly with the project engineer to clarify dimensions, beam schedules, or architectural details.

---

## 5. STUDENT PANEL WORKFLOWS

### Q16: How do I access training lessons and exercises?
**A:** Log into the **Student Portal** and navigate to the **Training** tab. You will see structured modules categorized by technical topic (CAD fundamentals, structural drafting, layer management, municipal approval layouts). Click any module to view lesson notes and download practical drawing assignments.

### Q17: How are student drafting assignments evaluated?
**A:** When you submit a completed exercise drawing, an instructor evaluates your work against a standardized 4-part rubric: **Accuracy**, **Drafting Speed**, **CAD Standards**, and **Technical Detail**. Feedback and scores are recorded in your academic profile.

### Q18: What credentials or certificates do I receive?
**A:** Upon completing designated course milestones, Archi Draft issues a verified digital credential. Each certificate includes a unique verification token and QR code that can be verified publicly by educational institutions or prospective employers without exposing your private account data.

---

## 6. FILE UPLOADS, CAD FORMATS & AUDIO NOTES

### Q19: Which CAD file formats are supported?
**A:** Archi Draft natively supports:
- **Vector & CAD Files:** `.dwg` (AutoCAD Drawing Database), `.dxf` (Drawing Exchange Format).
- **Documents & Layouts:** `.pdf` (Portable Document Format).
- **Images:** `.png`, `.jpg`, `.jpeg`.
- **Archives:** `.zip` (for multi-file bundles).

### Q20: How do audio voice notes work?
**A:** In the Collaboration Hub, click the microphone icon to record a voice note (`.webm` / `.m4a` / `.wav`). Audio notes are uploaded to secure storage and can be played back directly by project members, allowing rapid clarification of complex drawing revisions without lengthy typing.

### Q21: Are my uploaded CAD drawings private?
**A:** Yes. Drawings are stored in secure cloud object storage (Cloudflare R2). They are never publicly indexed. Only authenticated users who are direct participants in the specific project (or authorized studio administrators) can view or download the files.

---

## 7. CORRECTIONS & REVISIONS WORKFLOW

### Q22: How do I request a revision on a submitted drawing?
**A:** When a draughtsman submits a drawing for review, the Engineer can open the drawing viewer, click **Request Correction**, specify the revision round, and provide detailed markup instructions or attach sketch markups.

### Q23: How many revision rounds are permitted?
**A:** The standard number of revision rounds is governed by the project scope agreed upon at submission. Revisions addressing deviations from the original brief are included in the standard workflow. Substantial design changes may require scope adjustment.

---

## 8. FINANCIALS & INVOICING

### Q24: How does project pricing work?
**A:** Project valuations are established based on drawing type, project square footage, and complexity. In the current release, project financial totals, invoices, and milestone payment records are tracked via the **Financials** screen.

### Q25: Can I pay online through the app?
**A:** `[PROPOSED / FUTURE CAPABILITY]` In the current release, financial milestones and invoices are tracked administratively. An integrated online payment gateway (supporting UPI, Net Banking, and Cards) is planned for a future release.

---

## 9. ACCOUNT DELETION, DATA RIGHTS & PRIVACY

### Q26: How do I request deletion of my account?
**A:** Currently, account deletion is handled operationally by our data protection team. To delete your account, send an email from your registered address to **[PRIVACY / GRIEVANCE EMAIL — TO BE CONFIRMED]** with the subject `Account Deletion Request`. We will verify your identity, process the request, and confirm erasure within **30 days** in compliance with Rule 5(9) of the IT SPDI Rules. `[An automated in-app self-service deletion workflow is currently in engineering]`.

### Q27: What happens to my project files if I delete my account?
**A:** Your personal identity details are erased or permanently anonymized. However, CAD drawings uploaded to ongoing or completed projects belonging to other collaborating users are preserved in project archives so that the other party can complete construction or satisfy municipal requirements, as permitted by Section 8(7) of the DPDP Act. Specific operational retention periods for past project drawings are **currently under business-owner and qualified legal review**.

### Q28: How do I update my profile details?
**A:** You can edit your name, mobile number, postal address, company name, college name, and qualification at any time by navigating to your **Profile** and clicking **Save Changes**.

---

## 10. GRIEVANCES, SECURITY & SUPPORT

### Q29: Who do I contact if I have a complaint or grievance?
**A:** If you experience any technical defect, billing dispute, or privacy concern, contact our designated Grievance Officer:
- **Email:** `[GRIEVANCE EMAIL — TO BE CONFIRMED]`
- **Statutory Resolution SLA:** We acknowledge all complaints promptly and provide formal resolution within **30 days** in compliance with Rule 5(9) of the IT SPDI Rules.

### Q30: How do I report a security vulnerability or suspicious activity?
**A:** If you discover a potential security bug or notice suspicious activity on your account, please contact our security team immediately at **[SECURITY INCIDENT EMAIL — TO BE CONFIRMED]**. We maintain a 6-hour incident response protocol in compliance with CERT-In directions.
