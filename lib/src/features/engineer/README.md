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
