# Engineer Feature Module (`lib/src/features/engineer/`)

## 1. Overview & Ownership Boundary

This module represents the role-specific feature root for the **Engineer** portal in ARCHI DRAFT.
It encapsulates all user interfaces, submission workflows, financial overviews, and role-specific controllers belonging strictly to the Engineer persona.

### Role Ownership Rules
- **Owned by Engineer:**
  - Engineer Projects Dashboard (`engineer_projects_screen.dart`)
  - Project Submission Workflow (`project_form_screen.dart`, stepper, requirement forms)
  - Engineer Project Detail View & Review Actions (`project_detail_screen.dart`, correction dialogs)
  - Engineer Activity Timeline (`engineer_activity_screen.dart`)
  - Engineer Financials & Invoices (`financials_screen.dart`)
- **Shared Modules (Not Owned by Engineer):**
  - Project Data, Models & Repositories (`lib/src/features/projects/domain/`, `lib/src/features/projects/data/`)
  - File Upload & Storage Repository (`lib/src/features/projects/providers/file_providers.dart`)
  - Collaboration Hub Chat, Audio Player & Media Previews (`lib/src/features/projects/presentation/collaboration_hub_screen.dart` & widgets)
  - Authentication & Session State (`lib/src/features/auth/`)
  - Common API Client & Error Handling (`lib/src/features/api/`)
  - Navigation Shell & Responsive Layout (`lib/src/features/shell/`)

---

## 2. Directory Architecture Target

```text
lib/src/features/engineer/
├── README.md
├── dashboard/               # Engineer project overview & metrics
├── projects/                # Project submission, review & detail screens
│   ├── presentation/
│   └── providers/
├── activity/                # Engineer-specific event timeline & audit trail
│   └── presentation/
├── financials/              # Milestone payments, invoices & fee breakdown
│   └── presentation/
└── profile/                 # Engineer credentials & firm metadata
```

---

## 3. Migration Roadmap & Branch Safety

1. **Phase 1 (Completed):** Reserved `lib/src/features/engineer/`, `lib/src/features/draughtsman/`, and `lib/src/features/student/` roots. Documented module boundaries in `docs/02_architecture/PORTAL_MODULE_BOUNDARIES.md`.
2. **Phase 2 (Completed):** Relocated Engineer-owned UI screens to `lib/src/features/engineer/presentation/`:
   - `engineer_projects_screen.dart`
   - `engineer_activity_screen.dart`
   - `project_form_screen.dart`
   - `project_detail_screen.dart`
   Updated `app_router.dart` and package imports. All 91 automated tests passing.
3. **Phase 3 (Post-Integration):** Reusable Collaboration Hub and CAD/Media components remain in shared `lib/src/features/projects/` (or future `collaboration/`) for multi-role access across Engineer, Draughtsman, and Student personas.

---

## 4. Key Workflows & Recent Enhancements

### A. Project Submission & Technical Category Normalization
- **Screen:** `lib/src/features/engineer/presentation/project_form_screen.dart`
- **Category Normalization:** `DrawingType` supports `architectural` with canonical Firestore token `'ARCHITECTURAL'`.
- **Dropdown Resilience:** Dropdown values are mapped through `DrawingType.fromString(formState.drawingType)?.toFirestoreString()`. The dropdown field dynamically validates that the bound value exists in its `items` list; unmapped or legacy values fall back gracefully to `null` with `key: ValueKey(safeValue)` and `initialValue: safeValue`, eliminating Flutter dropdown assertion crashes.

### B. Reference-File Upload Implementation (50 MiB Limit)
- **Widget:** `lib/src/features/engineer/presentation/widgets/reference_files_upload_section.dart`
- **Workflow:** Embedded directly in `ProjectFormScreen`. Allows ordering engineers to attach project reference files prior to initiating drafting.
- **Auto Draft Saving:** If the project draft has not been saved yet (`projectId == null`), picking files automatically triggers `controller.saveDraft()` so that uploads are securely attached to an active project record.
- **Size Limit:** Exact 50 MiB per file (52,428,800 bytes). Validated on the client before network dispatch and enforced on Cloudflare Worker (`HTTP 413 Payload Too Large`).
- **Format Allowlist:** 27 extensions spanning CAD (`dwg`, `dxf`, `ifc`, `rvt`, etc.), documents (`pdf`, `doc`, `docx`, etc.), images (`png`, `jpg`, etc.), spreadsheets (`xls`, `xlsx`, `csv`), and archives (`zip`).
- **Authorization:** Owned by the ordering engineer (`client_upload`). Read/download access is granted to assigned Draughtsmen in their workspace view.
- **In-Flight Protection:** Submission button is disabled while background file uploads are in progress.
