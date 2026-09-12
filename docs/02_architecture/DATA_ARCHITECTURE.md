# DATA ARCHITECTURE

This document defines the conceptual Cloudflare D1 (SQLite) structure. Do not invent fields without documentation.

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

## Relationships (Relational DB)
`USER` (1:N) `PROJECT` (1:N) `ASSIGNMENTS`
`PROJECT` (1:N) `DRAWING VERSIONS`
`DRAWING VERSIONS` (1:N) `CORRECTIONS`
`PROJECT` (1:N) `ACTIVITY LOGS`

## Conceptual Fields

### USERS
- `id`
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
