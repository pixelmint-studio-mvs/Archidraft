# STORAGE ARCHITECTURE

## Approved Architecture
The application uses Cloudflare R2 for binary file storage and Cloudflare D1 for file metadata, mediated strictly by a Cloudflare Worker (Hono).

```text
projects/
 └── {projectId}/
      │
      ├── client_upload/
      │    └── {actionId}_{sanitizedName}
      │
      ├── draughtsman_version/
      │    └── {actionId}_{sanitizedName}
      │
      └── correction_attachment/
           └── {actionId}_{sanitizedName}
```

**Why separate folders and metadata tracking?**
Separation guarantees that a Client cannot overwrite Draughtsman files, and Draughtsmen cannot tamper with original Client reference files. The file metadata (`files` table in D1) tracks the upload lifecycle (`REQUESTED`, `COMPLETED`, `FAILED`) to ensure idempotency and handle partial uploads.

## STORAGE ACCESS PRINCIPLE
Broad, unrestricted project-level storage access is strictly prohibited.
Direct R2 access from the client is strictly prohibited.
All uploads and downloads are streamed through the Cloudflare Worker API to enforce authentication and authorization.

- **Client Uploads (`client_upload`):** Clients upload here. Draughtsmen read here.
- **Draughtsman Drawing Files (`draughtsman_version`):** Draughtsmen upload here. Clients read here.
- **Correction Attachments (`correction_attachment`):** Clients upload here during a correction request. Draughtsmen read here.

## FILE RULES

- **Maximum File Size:** 50 MB (strictly enforced server-side via `TransformStream` tracking actual byte counts. The client `Content-Length` header is intentionally untrusted).
- **File Validation Limitations:** Extensions are strictly validated against an allowlist and mapped to authoritative server-side MIME types. However, cryptographic magic-byte content validation is not performed (as it is not practical for large CAD formats and ZIP files within edge worker memory constraints). The system does not claim cryptographically secure content authenticity.
- **Idempotency (ActionId Lifecycle):** A client generates a single random `uuid.v4()` `actionId` when initiating a file pick. If the upload fails, retrying the **exact same logical upload** reuses this cached `actionId`. The Worker enforces this ID across D1: conflicting reuses safely overwrite `REQUESTED` uploads, preventing duplicates. A completed upload locks the `actionId`.
- **D1/R2 Consistency Model:** D1 registration and R2 streams cannot be perfectly atomic on the edge. 
   - If D1 succeeds but R2 fails, the Worker catches the error and marks D1 as `FAILED`.
   - If R2 succeeds but D1 completion update fails, the file exists in R2 but remains `REQUESTED` in D1. 
   - Recovery: In all failure states, a client retry using the identical `actionId` triggers a safe `ON CONFLICT DO UPDATE` in D1 and simply overwrites the R2 object, eventually reaching the `COMPLETED` state.
- **Supported Download Platforms:** Downloads are supported universally on Mobile and Web. Mobile clients pipe HTTP streams directly to the local filesystem using `dart:io` `File.openWrite()` to prevent memory bloat. Web clients fallback gracefully to memory buffering and HTML Anchor blob downloads to respect browser sandboxing without breaking compilation.
- **Test / Verification Status:** API validation, Idempotency tracking, and Platform compilations (Web/Mobile) have passed static analysis successfully (`dart analyze` confirmed 0 errors).
