# ARCHI DRAFT — Portal Module Boundaries & Role Separation Architecture

## 1. Architectural Strategy & Role Ownership

ARCHI DRAFT is engineered as a unified multi-portal platform serving three primary operational roles: **Engineer**, **Draughtsman**, and **Student**, coordinated through a shared core and administration layer.

To prevent merge conflicts and unintended code mutations during parallel branch development, the application enforces strict module boundaries.

```text
lib/
  src/
    core/                  # Shared cross-cutting infrastructure
      api/                 # Authenticated HTTP client, interceptors & error handlers
      auth/                # Auth tokens, credentials & session state
      router/              # Global GoRouter navigation & auth redirects
      theme/               # Stitch design system tokens, typography & colors

    features/              # Functional domains & role-specific roots
      engineer/            # [ENGINEER PORTAL] Role-specific screens & workflows
        dashboard/         # Projects overview & metric cards
        projects/          # Project submission & detail review
        activity/          # Event timeline & audit logs
        financials/        # Milestone payments & invoice breakdown
        profile/           # Engineer credentials & organization settings

      draughtsman/         # [DRAUGHTSMAN PORTAL] Reserved root for Draughtsman branch
        README.md          # Boundary contract & migration guide

      student/             # [STUDENT PORTAL] Reserved root for Student branch
        README.md          # Boundary contract & migration guide

      collaboration/       # [SHARED PORTAL MODULE] Collaboration Hub & media engines
        data/              # Message & attachment repositories
        domain/            # Message & voice models
        providers/         # Active audio & message controllers
        presentation/      # In-chat timeline, voice player, image lightbox, DXF/DWG viewers

      projects/            # [SHARED DOMAIN MODULE] Core Project entities & file repository
        data/              # Project & file data sources
        domain/            # Project, ProjectStatus, FileMetadata
        providers/         # Project list/detail providers, upload controllers
```

---

## 2. Detailed Ownership Matrix

| Module / Component | Owning Role / Module | Reusability | Description |
| :--- | :--- | :--- | :--- |
| `engineer_projects_screen.dart` | **Engineer** | Role-Private | Client project dashboard with metrics, filter pills & submission CTA. |
| `project_form_screen.dart` | **Engineer** | Role-Private | 3-step project creation wizard with blueprint file attachment uploads. |
| `project_detail_screen.dart` | **Engineer** | Role-Private | 12-column Bento Grid detail view with draughtsman assignment status & review actions. |
| `engineer_activity_screen.dart` | **Engineer** | Role-Private | Audit log of project status transitions, assignments, and revisions. |
| `financials_screen.dart` | **Engineer** | Role-Private | Financial overview of project budgets, escrow milestones, and invoices. |
| `draughtsman_studio_screen.dart` | **Draughtsman** | Role-Private | Draughtsman workbench with active drawing assignments & SLA countdowns. |
| `draughtsman_workspace_screen.dart`| **Draughtsman** | Role-Private | Dedicated drafting interface for revision uploads and technical drawing delivery. |
| `collaboration_hub_screen.dart` | **Shared (Collaboration)** | Multi-Role | Real-time project communication hub used by both Engineer and Draughtsman. |
| `voice_message_player.dart` | **Shared (Collaboration)** | Multi-Role | In-chat WhatsApp-style voice note player with in-memory caching and speed controls. |
| `image_attachment_preview.dart` | **Shared (Collaboration)** | Multi-Role | Inline thumbnail preview and full-screen zoomable Lightbox for raster graphics. |
| `cad_attachment_card.dart` | **Shared (Collaboration)** | Multi-Role | Context-aware CAD attachment handler (DXF vector preview vs. DWG external fallback). |
| `dxf_viewer.dart` | **Shared (Collaboration)** | Multi-Role | Pure-Dart 2D ASCII DXF vector parser and interactive vector renderer. |
| `file_repository.dart` | **Shared (Projects)** | Multi-Role | Authenticated R2 file upload and streaming byte retrieval. |
| `user_role.dart` & `auth_providers` | **Shared (Core/Auth)** | Universal | Firebase auth authentication and role resolution (`engineer`, `draughtsman`, `student`, `admin`). |

---

## 3. Safe Incremental Migration Strategy

To avoid breaking active work on separate branches (`Engineer_Panels`, `Draughtsman_Panels`, `Student_Panels`):

1. **Reserved Roots Established:**
   - `lib/src/features/engineer/README.md`
   - `lib/src/features/draughtsman/README.md`
   - `lib/src/features/student/README.md`
2. **Current Screen Placement & Completed Move:**
   - Engineer-specific screens have been relocated under `lib/src/features/engineer/presentation/`:
     - `engineer_projects_screen.dart` (Dashboard & metric overview)
     - `engineer_activity_screen.dart` (Audit trail & event log)
     - `project_form_screen.dart` (Project creation & brief wizard)
     - `project_detail_screen.dart` (12-column Bento Grid detail view)
   - GoRouter registrations in `app_router.dart` import and mount these screens under `/engineer/*`.
   - Shared multi-role screens and widgets remain in `lib/src/features/projects/`:
     - `collaboration_hub_screen.dart` and media engines (`widgets/voice_message_player.dart`, `widgets/image_attachment_preview.dart`, `widgets/cad_attachment_card.dart`, `widgets/dxf_viewer.dart`, `widgets/voice_recorder_bar.dart`).
     - Core repositories (`project_repository.dart`, `file_repository.dart`, `message_repository.dart`), domain models, and Riverpod providers.
   - Draughtsman screens remain in `lib/src/features/projects/presentation/draughtsman/` mapped to `/draughtsman/*`, ready for extraction on the Draughtsman branch.
3. **Collaboration Hub Independence:**
   - `collaboration_hub_screen.dart` and its media widgets (`voice_message_player.dart`, `image_attachment_preview.dart`, `cad_attachment_card.dart`, `dxf_viewer.dart`) are strictly agnostic to the participant's role.
   - Any portal route can mount the Collaboration Hub via `GoRoute('/<role>/projects/:projectId/collaboration-hub')` without duplicating communication logic.
4. **Pre-Merge Checklist:**
   - Parallel branches must preserve the public interfaces of shared domain models (`Project`, `ProjectMessage`, `FileMetadata`).
   - When merging Draughtsman and Student features into `main`, their files will populate their respective feature roots directly without colliding with Engineer files.
