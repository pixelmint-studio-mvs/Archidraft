# ARCHI DRAFT | BUSINESS INFORMATION & VERIFICATION REGISTER

**Operating Brand:** DRAUGHTSMAN STUDIO  
**Legal Proprietor:** MOHAMMED MOSIN S  
**Business Structure:** Sole Proprietorship  
**Product Name:** ARCHI DRAFT  
**Phase:** 1 of 9 — Canonical Business Register  
**Audited & Maintained by:** Antigravity Engineering Runtime & Legal Operations  
**Last Updated:** November 2026  

---

## 1. OFFICIAL BUSINESS PROFILE

| Configuration Parameter | Confirmed Value | Verification Status | Source / Authority |
| :--- | :--- | :--- | :--- |
| **Business Structure** | Sole Proprietorship | **CONFIRMED** | Master Implementation Prompt Sec. 2 |
| **Legal Proprietor** | MOHAMMED MOSIN S | **CONFIRMED** | Master Implementation Prompt Sec. 2 |
| **Operating Brand** | DRAUGHTSMAN STUDIO | **CONFIRMED** | Master Implementation Prompt Sec. 2 |
| **Product / App Name** | ARCHI DRAFT | **CONFIRMED** | Master Implementation Prompt Sec. 2 |
| **Application Website** | `https://archidraft.draughtsmanstudio.com` | **CONFIRMED** | Production Host Record |
| **Business Website** | `https://draughtsmanstudio.com` | **CONFIRMED** | Domain Registrar Record |
| **Grievance Contact Email** | `mosin@draughtsmanstudio.com` | **CONFIRMED** | Mail Domain Administration |
| **Customer Support Email** | `support@draughtsmanstudio.com` | **CONFIRMED** | Helpdesk Routing Config |
| **Privacy Request Email** | `support@draughtsmanstudio.com` | **CONFIRMED** | Data Fiduciary Contact |
| **Physical Establishment Address** | `[PENDING VERIFICATION]` | **PENDING_VERIFICATION** | Physical location confirmation required |
| **Grievance Officer Appointment** | `[PENDING VERIFICATION]` | **PENDING_VERIFICATION** | Formal appointment letter required |
| **Grievance Officer Name** | `[PENDING VERIFICATION]` | **PENDING_VERIFICATION** | Appointment confirmation required |
| **Grievance Officer Designation** | `[PENDING VERIFICATION]` | **PENDING_VERIFICATION** | Appointment confirmation required |

---

## 2. MANDATORY REPRESENTATION & LEGAL IDENTITY RULES

### 2.1. Sole Proprietorship Representation
In all legal notices, terms, disclaimers, invoices, and application footers, the business identity must be represented strictly as:
> **DRAUGHTSMAN STUDIO — a sole proprietorship operated by MOHAMMED MOSIN S.**

### 2.2. Negative Constraints & Prohibited Representations
- **NEVER** represent DRAUGHTSMAN STUDIO as a "Private Limited Company", "LLP", "Partnership", "Corporation", or "Public Limited Company".
- **NEVER** invent fictitious Corporate Identification Numbers (CIN), GSTIN numbers, MSME registration numbers, or registered addresses.
- **NEVER** publish website URLs or domain names as a substitute for a physical postal address.

---

## 3. UNVERIFIED INFORMATION & PUBLICATION BLOCKERS

The following two fields are classified as **Critical Publication Blockers** (`blockingPublication: true` in `verification_status.json`):

### 3.1. Physical Business Address (`PENDING_VERIFICATION`)
- **Statutory Necessity:** Under Rule 4(1) of the **Consumer Protection (E-Commerce) Rules, 2020** and Rule 3(1) of the **Information Technology (Intermediary Guidelines and Digital Media Ethics Code) Rules, 2021**, every e-commerce entity and digital intermediary operating in India must prominently publish the physical address of its establishment.
- **Current State:** A formal establishment address within India has not yet been designated.
- **Enforcement:** The system validator blocks any legal document from assuming `EFFECTIVE` status in a production environment until an official physical address is verified and entered into `business_profile.json`.

### 3.2. Grievance Officer Formal Appointment (`PENDING_VERIFICATION`)
- **Statutory Necessity:** Under Rule 5(9) of the **Information Technology (Reasonable Security Practices and Procedures and Sensitive Personal Data or Information) Rules, 2011** and Section 13 of the **Digital Personal Data Protection Act, 2023**, a designated Grievance Officer must be appointed to receive and resolve consumer complaints within 30 days.
- **Non-Assumption Rule:** The proprietor name (`MOHAMMED MOSIN S`) must **not** automatically be published as the appointed Grievance Officer without an explicit business resolution confirming the appointment.
- **Enforcement:** Until formally appointed and documented, the Grievance Officer identity remains `PENDING_VERIFICATION` in all public-facing notices.

---

## 4. VERIFICATION ACTION PLAN PRIOR TO PRODUCTION RELEASE

Before authorizing production deployment of the platform or publishing documents as `EFFECTIVE`:

1. **Step 1: Physical Address Documentation**
   - Provide the registered commercial postal address in India (Building name/number, street, locality, city, state, postal code).
   - Verify that postal delivery can be received at this location.
2. **Step 2: Formal Grievance Officer Designation**
   - Execute a written business resolution designating the appointed Grievance & Data Protection Officer.
   - Record officer legal name, designation, and appointment date.
3. **Step 3: Update Canonical JSON**
   - Update `shared/legal/business/business_profile.json` and change status to `VERIFIED` and `APPOINTED`.
   - Update `shared/legal/business/verification_status.json`.
4. **Step 4: Execute Automated Validation Runtime**
   - Run `node shared/legal/validator.js` to ensure that all blocking flags are resolved.

