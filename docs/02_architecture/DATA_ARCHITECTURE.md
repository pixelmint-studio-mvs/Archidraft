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

training_modules/
    {moduleId}

student_progress/
    {progressId}

student_assignments/
    {assignmentId}
```

## Relationships
`USER` -> `PROJECT` -> `ASSIGNMENTS` -> `DRAWING VERSIONS` -> `CORRECTIONS` -> `ACTIVITY LOGS`
`USER (STUDENT)` -> `STUDENT PROGRESS` -> `TRAINING MODULES`
`USER (STUDENT)` -> `STUDENT ASSIGNMENTS` -> `PROJECT (Sanitized/Mock)`

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
- `isTrainingProject` (Boolean flag for sanitized/mock projects)

### TRAINING MODULES
- `id`
- `category` (Architectural, Structural, Interior, Approval)
- `type` (Mock Project, Real Project)
- `level`
- `title`
- `description`
- `prerequisites`
- `isLocked`

### STUDENT PROGRESS
- `id`
- `studentId`
- `moduleId`
- `status`
- `score`
- `updatedAt`

### STUDENT ASSIGNMENTS
- `id`
- `studentId`
- `assignmentType` (Mock, Real)
- `referenceProjectId` (FK to sanitized/mock project)
- `status`
- `createdAt`
