# Student Feature Module (`lib/src/features/student/`)

## 1. Overview & Ownership Boundary

This directory reserves the role-specific feature root for the **Student** portal in ARCHI DRAFT.
It is isolated to prevent accidental feature collisions during Engineer portal development while parallel work occurs in the dedicated Student branch.

### Role Ownership Rules
- **Owned by Student:**
  - Student Learning Hub & Drafting Exercises
  - Mentorship Workflows & Feedback Submissions
  - Portfolio Building & Practice Project Reviews
  - Student Badges & Skill Progression Analytics
- **Shared Modules (Not Owned by Student):**
  - Authentication, Role Verification & Student Profile
  - Shared Project & File Models
  - Collaboration Hub In-Chat Audio, Image & CAD Viewers
  - Network Layer, Cloudflare D1/R2 APIs & Riverpod Infrastructure

---

## 2. Directory Architecture Target

```text
lib/src/features/student/
├── README.md
├── learning/                # Tutorials, CAD drafting exercises & guidelines
│   ├── presentation/
│   └── providers/
├── mentorship/              # Senior draughtsman reviews & feedback
│   ├── presentation/
│   └── providers/
├── portfolio/               # Completed practice sheets & skill showcase
│   └── presentation/
└── progression/             # Skill verification, level badges & milestones
```

---

## 3. Integration Notice

**DO NOT** migrate Engineer code into this directory.
This root is reserved for merging the completed Student branch into `main` during multi-portal integration.
