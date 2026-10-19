# Draughtsman Feature Module (`lib/src/features/draughtsman/`)

## 1. Overview & Ownership Boundary

This directory provides the role-specific feature root for the **Draughtsman** portal in ARCHI DRAFT.
It is organized into dedicated presentation and workflow subdirectories, while relying on shared project infrastructure.

### Role Ownership Rules
- **Owned by Draughtsman (`lib/src/features/draughtsman/`):**
  - Draughtsman Studio Dashboard (`presentation/studio/draughtsman_studio_screen.dart`)
  - Assignment Management & Workflow (`presentation/assignments/draughtsman_assignment_detail_screen.dart`)
  - CAD Drafting Workspace (`presentation/workspace/draughtsman_workspace_screen.dart`)
  - Drawings Library & Revisions History (`presentation/drawings/draughtsman_drawings_screen.dart`)
  - Draughtsman Analytics & Performance Insights (`presentation/insights/draughtsman_insights_screen.dart`)
  - Draughtsman Collaboration Hub & Views (`presentation/collaboration/`)
- **Shared Modules (Not Owned Exclusively by Draughtsman):**
  - Project Core Domain Models (`Project`, `ProjectStatus`, `Assignment`, `DrawingVersion`, `Correction`) under `lib/src/features/projects/domain/`
  - Collaboration, Audio & File Repositories under `lib/src/features/projects/data/`
  - Cross-role Providers under `lib/src/features/projects/providers/`
  - Authenticated File APIs & Cloudflare R2 Upload/Download under `lib/src/features/api/`
  - Auth, Role Resolution & AppShell navigation under `lib/src/core/` and `lib/src/features/auth/`

---

## 2. Directory Architecture

```text
lib/src/features/draughtsman/
├── README.md
├── presentation/
│   ├── studio/                  # Studio dashboard, active tasks & workload
│   ├── assignments/             # Incoming requests, status & assignment details
│   ├── workspace/               # Drawing uploads, revisions & CAD tools
│   ├── drawings/                # Drawings library & drawing version history
│   ├── insights/                # Draughtsman analytics & performance insights
│   └── collaboration/           # Collaboration hub view & voice note widgets
├── providers/                   # Draughtsman-specific state providers (future)
├── data/                        # Draughtsman-specific data sources (future)
└── domain/                      # Draughtsman-specific domain logic (future)
```

---

## 3. Integration Notice

This module contains role-specific presentation and workflow logic for the Draughtsman portal.
Shared project, assignment, file, and message domain models remain centralized under `lib/src/features/projects/`.
