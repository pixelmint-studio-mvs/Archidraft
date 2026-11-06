# DATA ARCHITECTURE

This document defines the conceptual Cloudflare D1 structure. Do not invent fields without documentation.

## Conceptual Structure

```text
users/
    {userId}

projects/
    {projectId}

projects/{projectId}/
    assignments/
        {assignmentId}

    versions/
        {versionId}

    corrections/
        {correctionId}

    activityLogs/
        {logId}
```

## Relationships
`USER` → `PROJECT` → `ASSIGNMENTS` → `DRAWING VERSIONS` → `CORRECTIONS` → `ACTIVITY LOGS`

## Conceptual Fields

### USERS
- `id`
- `identification_number` (Permanent role-based unique identifier: `ENG_XX` for Engineers/Architects, `DM_XX` for Draughtsman, `STU_XX` for Student, where `XX` are numbers scaling infinitely)
- `name`
- `email`
- `mobile`
- `role`
- `qualification` (Optional, based on role)
- `dateOfBirth` (Optional, based on role)
- `address` (Optional, based on role)
- `companyName` (Optional, based on role)
- `collegeName` (Optional, based on role)
- `proofDocument` (Optional, based on role)
- `createdAt`

### ROLE ID SEQUENCES (`role_id_sequences`)
Table managing infinite, atomic sequential generation of user unique identifiers:
- `role_prefix` (TEXT PRIMARY KEY — `'ENG'`, `'DM'`, `'STU'`)
- `last_seq` (INTEGER NOT NULL DEFAULT 0)
- `updated_at` (DATETIME)

*(Do not force irrelevant fields for every role).*

### PROJECTS
- `projectId`
- `projectName`
- `projectAddress`
- `drawingName`
- `drawingType`
- `projectArea`
- `estimatedAmount`
- `clientId`
- `assignedDraughtsmanId`
- `currentAssignmentId`
- `status`
- `correctionRound`
- `createdAt`
- `submittedAt`
- `completedAt`
