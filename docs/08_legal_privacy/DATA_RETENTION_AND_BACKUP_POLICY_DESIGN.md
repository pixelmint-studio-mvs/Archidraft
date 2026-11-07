# ARCHI DRAFT — Data Retention, Statutory Compliance and Backup Policy Design

**Operating Brand:** DRAUGHTSMAN STUDIO  
**Legal Proprietor:** MOHAMMED MOSIN S  
**Product:** ARCHI DRAFT  
**Engineering Phase:** Phase 2 (D1 Legal Database Foundation, Account Deletion & User Data Rights)  
**Document Reference:** `docs/08_legal_privacy/DATA_RETENTION_AND_BACKUP_POLICY_DESIGN.md`  
**Statutory Framework:** Digital Personal Data Protection Act, 2023; CERT-In Cyber Security Directions (2022); IT Act 2000; Income Tax Act, 1961

---

## 1. Overview and Purpose

Under the principle of **Storage Limitation** (DPDPA 2023 § 8(7)), a Data Fiduciary must erase personal data upon withdrawal of consent or as soon as the specified purpose for which personal data was collected has been served, unless retention is necessary for compliance with any law for the time being in force.

At the same time, conflicting statutory regulations mandate minimum retention periods for financial integrity and cyber incident response. This document sets out the comprehensive data retention schedules, backup lifecycle management, and disaster recovery reconciliation procedures for ARCHI DRAFT.

---

## 2. Retention Schedules by Data Category

In Cloudflare D1, data retention rules are formally stored in the `data_retention_policies` table, allowing programmatic audit and automated policy enforcement.

| Data Category | Retention Period | Statutory / Legal Justification | Enforcement Mechanism |
| :--- | :--- | :--- | :--- |
| **System & Access Logs** | **180 Days** | CERT-In Directions under Section 70B(6) of IT Act, 2000 (Mandatory 180-day retention of ICT logs). | Automated rolling purge of records older than 180 days in Cloudflare log drains. |
| **Financial & Invoicing** | **8 Years (2920 Days)** | Section 44AA of Income Tax Act, 1961; GST Rules (Maintenance of books of account and invoices). | Read-only archive in D1/Stripe records; exempt from user erasure requests. |
| **User Account & Profile** | **Active Duration + 30 Days** | DPDPA 2023 § 8(7) (Purpose limitation and timely erasure). | 30-day grace period upon deletion request; permanent tombstoning upon approval. |
| **AI Chat & Support Logs** | **90 Days** | Operational optimization and quality assurance; ephemeral communication logs. | Auto-purged upon account deletion or 90 days from session creation. |
| **Architectural Drawings** | **3 Years Post-Completion** | Indian Contract Act & Professional Liability (Limitation Act period for contract claims). | Retained for collaborative clients/engineers; user association anonymized upon deletion. |
| **Consent Event Ledger** | **Statutory Duration (8 Years)** | Evidentiary requirement to prove consent under DPDPA § 6(10). | Append-only immutable log in `legal_consent_events`. |

---

## 3. D1 Data Retention Policies Table

```sql
CREATE TABLE IF NOT EXISTS data_retention_policies (
  id TEXT PRIMARY KEY,
  category TEXT NOT NULL UNIQUE,
  retention_days INTEGER NOT NULL,
  description TEXT NOT NULL,
  statutory_basis TEXT NOT NULL,
  auto_purge_enabled INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

### Seeded Baseline Policies
The canonical migration `0026_canonical_legal_system.sql` seeds the mandatory baseline policies:
1. `CERT_IN_SYSTEM_LOGS`: 180 days (CERT-In Cyber Security Directions 2022).
2. `FINANCIAL_TRANSACTIONS`: 2920 days (Income Tax Act 1961 / GST).
3. `USER_PROFILE_DATA`: 30 days (DPDPA 2023 § 8(7)).
4. `AI_CHAT_TRANSCRIPTS`: 90 days (Operational limitation).

---

## 4. The Backup Reconciliation Challenge & Architecture

### 4.1 Technical Realities of Point-in-Time Backups
Cloudflare D1 automated backups and Cloudflare R2 bucket snapshots represent immutable, point-in-time images. When a user exercises their Right to Erasure, it is technically impossible and cryptographically destructive to rewrite immutable compressed historical database backups without compromising backup chain integrity and disaster recovery guarantees.

### 4.2 Backup-Expiry Reconciliation Protocol
To resolve the tension between immutability of backups and the Right to Erasure, ARCHI DRAFT implements the **Post-Restore Deletion Re-Play Protocol**:

```
                       [Disaster Recovery Event]
                                  │
                                  ▼
                ┌───────────────────────────────────┐
                │ Restore D1 Database from Snapshot │
                └─────────────────┬─────────────────┘
                                  │
                                  ▼
                ┌───────────────────────────────────┐
                │   Execute Post-Restore Script:    │
                │ Re-apply COMPLETED Erasure Queue  │
                └─────────────────┬─────────────────┘
                                  │
        ┌─────────────────────────┴─────────────────────────┐
        ▼                                                   ▼
┌───────────────────────────────┐           ┌───────────────────────────────┐
│ Re-tombstone User Profile:    │           │ Purge Restored AI Messages    │
│ name = 'Deleted User'         │           │ & Private Transient Files     │
│ email = 'deleted_*@...'       │           └───────────────────────────────┘
│ status = 'SUSPENDED'          │
└───────────────────────────────┘
```

1. **Deletion Ledger Durability:** All completed erasure requests (`account_deletion_requests` where `status = 'COMPLETED'`) are maintained as permanent tombstone records.
2. **Post-Restore Hook:** Whenever a disaster recovery restore is initiated, the system executes an automated migration replay script that queries `account_deletion_requests` and immediately re-tombstones any user accounts that were restored to an active state by an older snapshot.
3. **Backup Retention Horizon:** Automated D1 backup snapshots are purged after **30 days**. Therefore, any restored snapshot older than 30 days cannot exist, ensuring that no permanently erased user data persists in backup storage longer than 30 days post-erasure.

---

## 5. Security & Isolation Controls

1. **Access Restriction:** Retention rules can only be modified via authenticated admin APIs (`POST /api/admin/legal/data-retention-policies`).
2. **Statutory Override Protection:** The backend rejects any administrative attempt to lower `FINANCIAL_TRANSACTIONS` retention below 2920 days or `CERT_IN_SYSTEM_LOGS` below 180 days, preventing inadvertent compliance violations.
3. **Audit Trail:** Every change to retention policy parameters emits an audit event recording the administrator ID, previous value, new value, and justification.

---

## 6. Implementation Verification

- **Migration:** `0026_canonical_legal_system.sql` provisions table and seed rows.
- **Backend APIs:**
  - `GET /api/admin/legal/data-retention-policies`
  - `POST /api/admin/legal/data-retention-policies`
- **Automated Tests:** Covered by `worker/test/canonical_legal_system_phase2.test.mjs` (Test 4 confirms queryability, integrity, and category uniqueness).
