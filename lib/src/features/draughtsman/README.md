# Draughtsman Feature Module (`lib/src/features/draughtsman/`)

## 1. Overview & Ownership Boundary

This directory reserves the role-specific feature root for the **Draughtsman** portal in ARCHI DRAFT.
It is isolated to prevent accidental file moves or modifications during Engineer portal development while parallel work occurs in the dedicated Draughtsman branch.

### Role Ownership Rules
- **Owned by Draughtsman:**
  - Draughtsman Studio Dashboard (`draughtsman_studio_screen.dart`)
  - Assignment Management & Accept/Reject Workflows (`draughtsman_assignment_detail_screen.dart`)
  - CAD Drafting Workspace (`draughtsman_workspace_screen.dart`)
  - Drawings Library & Revisions History
  - Draughtsman Analytics & Earnings Insights
- **Shared Modules (Not Owned by Draughtsman):**
  - Project Core Domain Models (`Project`, `ProjectStatus`, `Assignment`)
  - Collaboration Hub Chat, Audio Player & Media Previews (`VoiceMessagePlayer`, `ImageAttachmentPreview`, `CadAttachmentCard`)
  - Authenticated File APIs & Cloudflare R2 Upload/Download
  - Auth, Role Resolution & AppShell navigation

---

## 2. Directory Architecture Target

```text
lib/src/features/draughtsman/
├── README.md
├── studio/                  # Studio dashboard, active tasks & workload
│   ├── presentation/
│   └── providers/
├── assignments/             # Incoming requests, bidding & SLA timers
│   ├── presentation/
│   └── providers/
├── workspace/               # Drawing uploads, revisions & CAD tools
│   ├── presentation/
│   └── providers/
└── earnings/                # Payouts, completed drafting fees & reports
```

---

## 3. Integration Notice

**DO NOT** migrate Engineer code into this directory.
This root is reserved for merging the completed Draughtsman branch into `main` during multi-portal integration.
