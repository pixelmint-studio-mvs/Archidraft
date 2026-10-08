# DATA ARCHITECTURE

This document defines the relational database schema of Cloudflare D1 (`archi-draft-db`).

> [!NOTE]
> **Evolution Note:** Early documentation described a NoSQL Firestore collection hierarchy (`users/{userId}`, `projects/{projectId}`). Cloudflare D1 uses standard SQL tables with foreign key relationships, indexes, and transactional batches.

---

## 1. Entity Relationship Overview

```text
┌──────────────┐         ┌──────────────┐         ┌──────────────────────┐
│    users     │1       *│   projects   │1       *│   drawing_versions   │
└──────┬───────┘─────────└──────┬───────┘─────────└──────────┬───────────┘
       │                        │                            │
       │                        ├─────────────────┐          │
       │                        │1                │1         │1
       │                        ▼*                ▼*         ▼*
       │                 ┌──────────────┐  ┌──────────────┐┌──────────────┐
       │                 │    files     │  │ corrections  ││project_msges │
       │                 └──────────────┘  └──────────────┘└──────────────┘
       │                        │1
       │                        ▼*
       │                 ┌──────────────┐
       └────────────────►│activity_logs │
                         └──────────────┘
```

---

## 2. Table Schemas

### `users` (Migration 0001, 0007)
Stores user accounts synchronized from Firebase Auth upon first login or profile update.
- `id` (TEXT PRIMARY KEY): Firebase UID.
- `email` (TEXT NOT NULL): User email address.
- `name` (TEXT NOT NULL): Display name.
- `role` (TEXT NOT NULL): User role (`ENGINEER`, `DRAUGHTSMAN`, `STUDENT`, `STUDIO_ADMIN`, or legacy `CLIENT`).
- `mobile` (TEXT): Mobile phone number.
- `date_of_birth` (TEXT): ISO date string.
- `address` (TEXT): Mailing or business address.
- `company_name` (TEXT): Optional company name (primarily Engineer).
- `college_name` (TEXT): Optional institution name.
- `qualification` (TEXT): Optional educational or technical qualification.
- `created_at` (DATETIME): Timestamp of registration.

### `projects` (Migration 0001, 0002, 0004, 0006)
Central project brief and lifecycle record.
- `id` (TEXT PRIMARY KEY): UUID.
- `client_id` (TEXT NOT NULL): FK to `users(id)` representing the owning Engineer.
- `project_name` (TEXT NOT NULL): Project title.
- `project_address` (TEXT NOT NULL): Site location.
- `drawing_name` (TEXT NOT NULL): Target drawing identifier.
- `drawing_type` (TEXT NOT NULL): Discipline (e.g. Architectural, Structural).
- `project_area` (TEXT NOT NULL): Area in square feet.
- `status` (TEXT NOT NULL DEFAULT 'DRAFT'): Project lifecycle status.
- `current_assignment_id` (TEXT): FK to `assignments(id)`.
- `draughtsman_id` (TEXT): FK to `users(id)` for assigned drafter.
- `draughtsman_name` (TEXT): Cached name of assigned drafter.
- `correction_round` (INTEGER DEFAULT 0): Revision counter (0–3).
- `last_action_id` (TEXT): Idempotency tracker.
- `rejection_reason` (TEXT): Rejection note if cancelled by admin.
- `created_at`, `submitted_at`, `approved_at`, `assigned_at`, `rejected_at`, `cancelled_at` (DATETIME).
- `total_value` (REAL NULL): Internal admin valuation (Admin use only).

### `files` (Migration 0003)
Metadata for all binary files stored in Cloudflare R2.
- `id` (TEXT PRIMARY KEY): Action UUID.
- `project_id` (TEXT NOT NULL): FK to `projects(id)`.
- `uploaded_by` (TEXT NOT NULL): FK to `users(id)`.
- `original_name` (TEXT NOT NULL): Original filename as picked by user.
- `sanitized_name` (TEXT NOT NULL): Safe filesystem-compliant filename.
- `object_key` (TEXT NOT NULL): Key in R2 bucket (`projects/...`).
- `content_type` (TEXT NOT NULL): Authoritative MIME type.
- `size` (INTEGER NOT NULL): File size in bytes.
- `category` (TEXT NOT NULL): `client_upload`, `draughtsman_version`, `correction_attachment`, `chat_attachment`.
- `status` (TEXT NOT NULL DEFAULT 'REQUESTED'): `REQUESTED`, `COMPLETED`, `FAILED`.
- `created_at` (DATETIME).

### `assignments` (Migration 0002)
Tracks project allocations to draughtsmen.
- `id` (TEXT PRIMARY KEY): UUID.
- `project_id` (TEXT NOT NULL): FK to `projects(id)`.
- `draughtsman_id` (TEXT NOT NULL): FK to `users(id)`.
- `status` (TEXT NOT NULL DEFAULT 'PENDING'): `PENDING`, `ACCEPTED`, `REJECTED`, `REPLACED`.
- `created_at`, `updated_at` (DATETIME).

### `drawing_versions` (Migration 0004)
Drawing submissions prepared by drafters.
- `id` (TEXT PRIMARY KEY): UUID.
- `project_id` (TEXT NOT NULL): FK to `projects(id)`.
- `file_id` (TEXT NOT NULL): FK to `files(id)`.
- `version_number` (INTEGER NOT NULL): 1, 2, 3...
- `uploaded_by` (TEXT NOT NULL): FK to `users(id)`.
- `correction_id` (TEXT NULL): FK to `corrections(id)`.
- `created_at` (DATETIME).

### `corrections` (Migration 0004)
Correction/revision requests issued by Engineers.
- `id` (TEXT PRIMARY KEY): UUID.
- `project_id` (TEXT NOT NULL): FK to `projects(id)`.
- `requested_by` (TEXT NOT NULL): FK to `users(id)`.
- `target_version_id` (TEXT NOT NULL): FK to `drawing_versions(id)`.
- `round_number` (INTEGER NOT NULL): 1, 2, or 3.
- `description` (TEXT NOT NULL): Revision feedback.
- `status` (TEXT NOT NULL DEFAULT 'OPEN'): `OPEN`, `RESOLVED`.
- `created_at`, `resolved_at` (DATETIME).

### `activity_logs` (Migration 0001)
Server-generated immutable audit trail.
- `id` (TEXT PRIMARY KEY): Action UUID.
- `project_id` (TEXT NOT NULL): FK to `projects(id)`.
- `action_type` (TEXT NOT NULL): e.g. `PROJECT_SUBMITTED`, `DRAWING_SUBMITTED`.
- `actor_id` (TEXT NOT NULL): FK to `users(id)`.
- `actor_role` (TEXT NOT NULL): e.g. `ENGINEER`, `DRAUGHTSMAN`, `STUDIO_ADMIN`.
- `details` (TEXT): Description text.
- `timestamp` (DATETIME).

### `notifications` (Migration 0005)
In-app notification records.
- `id` (TEXT PRIMARY KEY): UUID.
- `user_id` (TEXT NOT NULL): Recipient FK to `users(id)`.
- `project_id` (TEXT NULL): Associated project FK.
- `type` (TEXT NOT NULL): `CHAT_MESSAGE`, `DRAWING_SUBMITTED`, `ASSIGNMENT_ACCEPTED`, etc.
- `title` (TEXT NOT NULL).
- `message` (TEXT NOT NULL).
- `is_read` (INTEGER DEFAULT 0): 0 = unread, 1 = read.
- `created_at` (DATETIME).

### `project_messages` (Migration 0008)
Shared project discussion messages in the Collaboration Hub.
- `id` (TEXT PRIMARY KEY): UUID.
- `project_id` (TEXT NOT NULL): FK to `projects(id)`.
- `sender_id` (TEXT NOT NULL): FK to `users(id)`.
- `sender_name` (TEXT NOT NULL): Display name of sender.
- `sender_role` (TEXT NOT NULL): `ENGINEER` or `DRAUGHTSMAN`.
- `message` (TEXT NOT NULL): Text content.
- `attachment_file_id` (TEXT NULL): FK to `files(id)`.
- `created_at` (DATETIME).

### `invoices` & `payments` (Migration 0006 — Admin-Only)
Retained strictly for Studio Admin financial management and completely inaccessible to Engineers.
