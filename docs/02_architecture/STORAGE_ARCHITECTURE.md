# STORAGE ARCHITECTURE

## Approved Firebase Storage Architecture

```text
projects/
 └── {projectId}/
      │
      ├── client_uploads/
      │    └── {fileId}_{originalName}
      │
      ├── draughtsman_versions/
      │    └── {versionId}_{originalName}
      │
      └── correction_attachments/
           └── {correctionId}_{fileId}_{originalName}
```

**Why separate folders?**
Separation guarantees that a Client cannot overwrite Draughtsman files, and Draughtsmen cannot tamper with original Client reference files.

## STORAGE ACCESS PRINCIPLE
Broad, unrestricted project-level storage access is strictly prohibited.

- **Client Uploads (`client_uploads/`):** Clients write here. Draughtsmen read here.
- **Draughtsman Drawing Files (`draughtsman_versions/`):** Draughtsmen write here. Clients read here.
- **Correction Attachments (`correction_attachments/`):** Clients write here during a correction request. Draughtsmen read here.

## FILE RULES

- **Maximum File Size:** 50 MB
- **Expected File Types:** PDF, DWG, DXF, PNG, JPG/JPEG, ZIP

*Note: MIME type validation may require careful handling for CAD formats (e.g., DWG/DXF often have varied or generic octet-stream MIME types depending on the uploading OS). Do not assume MIME detection alone is perfect.*
