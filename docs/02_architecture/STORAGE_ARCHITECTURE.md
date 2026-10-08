# STORAGE ARCHITECTURE

## 1. Storage Topology & Principles

ARCHI DRAFT stores binary files in **Cloudflare R2** and metadata in **Cloudflare D1**, mediated strictly through a **Cloudflare Worker** (Hono). Direct client access to R2 buckets is forbidden.

```text
archi-draft-storage/ (R2 Bucket)
 └── projects/
      └── {projectId}/
           ├── client_upload/          (Project Brief reference files)
           │    └── {actionId}_{sanitizedName}
           ├── draughtsman_version/    (Drawing versions submitted by drafter)
           │    └── {actionId}_{sanitizedName}
           ├── correction_attachment/  (Markup accompanying revision requests)
           │    └── {actionId}_{sanitizedName}
           └── chat_attachment/        (Files shared in Collaboration Hub)
                └── {actionId}_{sanitizedName}
```

---

## 2. Server-Side Protection Rules

- **Maximum File Size (50 MB):** Strictly enforced server-side via a streaming `TransformStream` tracking byte counts. Untrusted client `Content-Length` headers cannot bypass this limit.
- **Extension Allowlist:** Only approved technical drawing and document formats: `.pdf`, `.dwg`, `.dxf`, `.png`, `.jpg`, `.jpeg`, `.zip`.
- **Authoritative Server MIME Resolution:**
  - `pdf` → `application/pdf`
  - `png` → `image/png`
  - `jpg`, `jpeg` → `image/jpeg`
  - `zip` → `application/zip`
  - `dwg` → `application/acad`
  - `dxf` → `application/dxf`
- **Idempotency via `actionId`:** The client generates a unique UUID `actionId`. Retries overwrite pending `REQUESTED` states in D1 and overwrite objects in R2, preventing duplicate or orphaned records.

---

## 3. Binary File Open & Inline Preview Architecture

### Discovered Issue
Prior implementations attempted to display binary files directly, which corrupted image/PDF renderings or displayed raw byte noise as UTF-8 text on Web.

### Implemented Resolution
1. **Worker Disposition Control:**
   `GET /api/files/:fileId/download?disposition=inline` returns:
   - `Content-Type`: Authoritative MIME type.
   - `Content-Disposition`: `inline; filename="..."`
2. **Web Client Processing (`api_client_web.dart`):**
   - Receives byte stream.
   - Creates a typed `html.Blob(bytes, mimeType)`.
   - Generates an Object URL: `html.Url.createObjectUrlFromBlob(blob)`.
   - **Previewable Formats (`image/*`, `application/pdf`):** Opens in a new tab via `html.window.open(url, '_blank')` with a 2-minute delayed revocation.
   - **CAD & Archive Formats (`dwg`, `dxf`, `zip`):** Triggers a browser download with user feedback that native preview is unavailable.
3. **Mobile/Desktop Processing (`api_client_io.dart`):**
   - Streams directly to the device documents directory via `File.openWrite()`.
   - Invokes `OpenFilex.open(filePath)`.

---

## 4. User-Facing Category Mapping

| Database Category | UI Label (Presentation) | Uploaded By | Read By |
|---|---|---|---|
| `client_upload` | **Project Brief** | Engineer | Draughtsman & Admin |
| `draughtsman_version` | **Drawing Version** | Draughtsman | Engineer & Admin |
| `correction_attachment` | **Correction Attachment** | Engineer | Draughtsman |
| `chat_attachment` | **Chat Attachment** | Engineer / Draughtsman | Both participants |
