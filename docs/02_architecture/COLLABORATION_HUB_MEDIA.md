# ARCHI DRAFT — Collaboration Hub Media, CAD Viewing & Mobile Responsiveness

## 1. Overview

The **Collaboration Hub** (`CollaborationHubScreen`) provides a secure, role-agnostic workspace communication channel between Engineers and Draughtsmen.
This document details the media architecture, in-chat playback engines, CAD viewing pipelines, and mobile layout adaptations.

---

## 2. Voice Messages (WhatsApp-Style Architecture)

### Core User Experience
- **In-Chat Playback Only:** Voice messages render as specialized audio bubbles featuring a play/pause circular toggle, real-time waveform progress scrubber, elapsed/total duration label, and playback speed toggle pill (`1x`, `1.5x`, `2x`).
- **No User-Facing Download Button:** The user-facing download action has been removed from voice message bubbles. Users never need to manually download audio files to listen, and audio is never dumped into the device's visible Downloads folder merely for playback.
- **Bounded Session Memory Cache:** Audio bytes are retrieved on-demand via the authenticated file API (`/api/projects/:id/files/:fileId/download`) and held in an in-memory session cache (`_audioCache`).
- **Resource Management:** Temporary browser object URLs and audio source references are safely disposed when messages leave memory or playback stops.
- **Mutual Exclusivity:** An active audio provider (`activeAudioPlayerIdProvider`) guarantees only one voice message or preview plays at any time.

---

## 3. Image Attachments (Inline Preview & Lightbox)

### Supported Raster Formats
- **Formats:** PNG, JPG/JPEG, WebP, GIF, BMP, AVIF.
- **Detection:** MIME type inspection (`image/*`) with robust fallback to filename extension matching (e.g., handling `.jpeg` stored as `application/octet-stream`).

### Presentation Lifecycle
1. **Authenticated Byte Fetching:** The image widget fetches bytes directly through `ApiClient.downloadBinary` with `Authorization: Bearer <token>`. Cloudflare R2 bucket objects remain private and are never exposed publicly.
2. **Inline Chat Preview:** Displays a bounded thumbnail box (max width: 320px, max height: 240px) preserving native aspect ratio with smooth shimmer loading and retry states.
3. **Interactive Lightbox Dialog:** Tapping the preview opens a dark overlay modal dialog containing:
   - Full-resolution rendering.
   - `InteractiveViewer` supporting smooth zoom (0.5x to 5.0x) and panning.
   - Close (`X`) button and explicit authenticated download button.

---

## 4. Ordinary Document Attachments

Formats that cannot be rendered natively as inline media (e.g., PDF, DOCX, XLSX, TXT, ZIP) continue to render with the proven, reliable document attachment card:
- Monospace filename and human-readable file size indicator.
- File-type icon.
- Direct download button streaming authenticated bytes from Cloudflare R2 via Worker.

---

## 5. CAD Viewing Architecture (DXF vs. DWG)

| Format | Capability | Pipeline | Platform Support |
| :--- | :--- | :--- | :--- |
| **DXF** (ASCII) | **Native In-App 2D Vector Viewer** | Pure-Dart ASCII entity parser (`DxfDrawing.parse`) extracting `LWPOLYLINE`, `LINE`, `CIRCLE`, `ARC`, `POINT`, and `TEXT`/`MTEXT` entities into a `CustomPainter` canvas with inverted CAD coordinate correction, clean text code stripping, and zoom/pan. | **Web, Android, iOS, Desktop** — renders natively with pan/zoom (0.1x to 20x) and fit-to-drawing bounds reset. |
| **DWG** (Binary) | **Truthful External App Fallback** | Proprietary binary format. ARCHI DRAFT never sends drawings to third-party converters. On Web, offers authenticated download. On Native Android, triggers Android OS app chooser (`open_filex`) for installed viewers (Autodesk AutoCAD, DWG FastView). | **Android:** Open with compatible viewer.<br>**Web:** Authenticated secure download. |

### Verified DXF Entity Types
Validated against real architectural drawing `sample_floor_plan.dxf`:
- `LWPOLYLINE`: Outer rectangular boundary (`6000 x 4000 mm`) with closed polygon rendering.
- `LINE`: Internal partition and wall divider lines.
- `CIRCLE`: Structural column or round furniture element.
- `ARC`: Door swing quadrant arc with counterclockwise angle sweep.
- `TEXT`: Primary annotations (`SAMPLE FLOOR PLAN` at 250mm height, `6000 x 4000 mm` at 160mm height) positioned at accurate baseline coordinates with blueprint cyan styling (`#64FFDA`).

### Security & Privacy Guarantee
Drawings uploaded by clients are never transmitted to unauthorized external conversion services. Private R2 objects are accessible only by authenticated and authorized project participants.

---

## 6. Mobile Responsiveness & Bottom Navigation Isolation

### The Defect
On mobile screen widths (320px – 412px), the bottom message composer was obscured or pushed behind the Engineer navigation bar (`AppBottomNav` with Projects, Activity, Profile tabs) due to `extendBody: true` on `ResponsiveScaffold` and persistent shell bars.

### The Solution
1. **Shell Navigation Auto-Hiding:**
   `ResponsiveScaffold` monitors the active route location. When inside `/collaboration-hub`, `hideNavigation` is automatically engaged on mobile viewports:
   - `AppBottomNav` and `AppTopBar` are hidden.
   - `extendBody` is disabled.
   - The Collaboration Hub receives full screen viewport height.
2. **Safe Area & Keyboard Avoidance:**
   - `Scaffold.resizeToAvoidBottomInset` set to `true`.
   - Composer wrapped in `SafeArea(top: false, bottom: true)` so home indicators / gesture pills never overlap input buttons.
   - Outer padding and borders adapt dynamically via `LayoutBuilder`: edge-to-edge on mobile (`< 650px`) and elegant Bento container on desktop.
3. **Verified Breakpoints:**
   - 320px (ultra-compact mobile)
   - 360px (standard compact Android)
   - 390px (iPhone standard)
   - 412px (Android standard)
   - Desktop / Tablet widescreen
