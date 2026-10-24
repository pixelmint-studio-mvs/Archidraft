# Phase 3 — Student–Admin Review Workflow: Remaining Work & Production Launch Checklist

**Document Version:** 1.0.0  
**Audit Date:** October 24, 2026  
**Integration Branch:** `COMPLETED-INTERGRATION`  
**Workspace:** `scratch/completed-integration`  
**Reference Document:** Student Portal Flowchart (Interactions with Admin) & Phase 3 Implementation Report  

---

## 1. Executive Summary

With the successful completion of **Phase 3**, all engineering deliverables, user interfaces, administrative queues, interactive evaluation dialogs, and student feedback loops specified in the Student Portal Flowchart are **100% implemented, integrated, and verified**.

There are **zero outstanding code defects or missing features** within the local integration scope:
- The Dedicated Student Submissions Review Queue is fully active at `/students/submissions`.
- The Interactive Rubric Evaluation Modal is fully functional across the queue and project detail pages.
- The Student Portal correctly displays rubric scores, revision instructions, correction rounds, and rejection states.
- 662 automated tests pass with 0 static analysis errors across Worker, Admin Web, and Flutter.

This document details the remaining operational, governance, and deployment activities required prior to opening the system to public students and commercial draughtsmen in production.

---

## 2. Feature Completion Audit

| Requirement / Scope Item | Target Component | Phase 2 Baseline | Phase 3 Status | Readiness |
| :--- | :--- | :---: | :---: | :---: |
| **A. Dedicated Student Submissions Queue** | `apps/admin-web/src/app/students/submissions/` | Missing (DEF-P2-02) | **COMPLETE & VERIFIED** | **PROD-READY** |
| **B. Interactive Evaluation Modal** | `apps/admin-web/src/components/projects/` | Missing (DEF-P2-01) | **COMPLETE & VERIFIED** | **PROD-READY** |
| **C. Rubric Scoring (Accuracy, Standards)** | Next.js Form & D1 API Schema | API Only | **COMPLETE & VERIFIED** | **PROD-READY** |
| **D. Student Portal Feedback Loop** | Flutter Web (`lib/src/features/projects/`) | Partial (No Reject Enum) | **COMPLETE & VERIFIED** | **PROD-READY** |
| **E. Certificate Issuance & Verification** | Worker PDF Generator & Public Screen | Complete | **COMPLETE & VERIFIED** | **PROD-READY** |
| **F. Automated Test Suites** | Worker, Admin, Flutter | 626 Passing Tests | **662 Passing Tests** | **PROD-READY** |

---

## 3. Operational & Governance Activities Prior to Production Launch

### 1. Platform Legal Document Seeding (Mandatory Pre-Launch Gate)
- **Area:** Platform Governance & Legal Compliance
- **Requirement:** Under ArchiDraft's affirmative consent architecture, unseeded environments enforce a maintenance mode (`503 TERMS_MAINTENANCE_MODE`) redirecting all user sessions to `#/legal/onboarding`.
- **Pre-Launch Action:**
  1. Platform legal counsel must draft and finalize the official **Platform Terms and Conditions** and **Privacy Notice**.
  2. A Studio Administrator must log into the Admin Web console (`/settings/legal` or `/legal`), paste the finalized markdown documents, and set their status to `EFFECTIVE`.
  3. Once seeded, normal student, draughtsman, and engineer accounts will pass the router check without requiring the staging test seam (`X-Staging-Test-Mode`).

### 2. Business Policy Confirmation: Educational Rejection Resubmission
- **Area:** Educational Policy & Student Assessment Governance
- **Requirement:** In commercial projects, drawing rejection is terminal or results in draughtsman reassignment. In the training environment, the current implementation allows apprentices to view rejection feedback and submit a revised draft (`"YOUR REVISED DRAFT (POST-REJECTION)"`).
- **Pre-Launch Action:**
  1. The educational curriculum director must formally sign off on the pedagogical workflow allowing students to resubmit rejected assignments.
  2. If the training program desires a hard failure (terminal assignment lock), a simple conditional toggle can be added to `worker/src/index.ts` (line 850) based on program configuration.

### 3. Financial Integration & Payment Gateway (Deferred Scope)
- **Area:** Financial Engineering & Stripe/Razorpay Vendor Integration
- **Requirement:** In accordance with repository safeguards, all financial and payment processing endpoints are intentionally frozen returning `501 FEATURE_FROZEN`.
- **Pre-Launch Action:**
  1. Select and contract with the preferred payment processing vendor.
  2. Implement webhook handlers and payout pipelines in `worker/src/finance/`.
  3. Remove the `FEATURE_FROZEN` guard upon completion of security audit and penetration testing.

### 4. Cloudflare Production Infrastructure Promotion
- **Area:** DevOps & Infrastructure Provisioning
- **Requirement:** Deploying from local staging to Cloudflare production.
- **Pre-Launch Action:**
  1. Execute Cloudflare D1 migrations against the production database:
     ```bash
     npx wrangler d1 migrations apply archidraft-db --remote
     ```
  2. Verify production Cloudflare R2 bucket permissions, CORS policies, and lifecycle rules for CAD file storage.
  3. Configure production Cloudflare Worker environment secrets (`FIREBASE_PROJECT_ID`, `JWT_SECRET`, `PDF_ENCRYPTION_KEY`).
  4. Ensure Firebase Authentication production project has authorized domains configured for the production URL.

---

## 4. Production Deployment Sign-Off Checklist

| # | Sign-Off Item | Responsible Owner | Target Timeline | Status |
| :-: | :--- | :--- | :---: | :---: |
| **1** | Admin Review Queue & Evaluation Modal Code Complete | Lead Frontend Engineer | Oct 24, 2026 | **COMPLETED** |
| **2** | Cross-Portal Feedback Loop & Rejected Enum Complete | Lead Mobile/Flutter Engineer | Oct 24, 2026 | **COMPLETED** |
| **3** | Full Regression Suite Passing (662 tests green) | QA & Test Automation Lead | Oct 24, 2026 | **COMPLETED** |
| **4** | Authentic Legal Terms Document Published in D1 | Legal Counsel & Studio Admin | Pre-Launch | **PENDING OWNER ACTION** |
| **5** | Formal Policy Approval for Educational Resubmissions | Curriculum Director | Pre-Launch | **PENDING OWNER ACTION** |
| **6** | Financial Gateway Vendor Selection & Contract | Executive Leadership | Post-MVP | **FROZEN (HTTP 501)** |
| **7** | Production Cloudflare D1 & Worker Promotion | DevOps Lead | Launch Day | **PENDING RELEASE** |
