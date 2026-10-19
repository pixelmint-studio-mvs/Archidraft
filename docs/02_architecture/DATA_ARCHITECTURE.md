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
