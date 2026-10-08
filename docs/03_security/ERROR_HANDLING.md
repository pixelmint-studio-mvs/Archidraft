# ERROR HANDLING STANDARD

## 1. Core Rule
**Raw Technical Errors Must Never Reach the UI.**
Users must never see database exceptions, stack traces, HTTP status codes, or unhandled exceptions in the application interface.

```text
Backend / Network Exception
  │
  ▼
ApiClient Exception Mapper / Riverpod Error State
  │
  ▼
User-Friendly Explanatory Message & Visual State
```

---

## 2. Standardized Error Categories & Behaviors

### 1. Network & Connectivity Errors
- **Cause:** Socket exceptions, network dropouts, unreachable local emulator.
- **User Message:** "Unable to connect to server. Please check your internet connection."
- **UI Behavior:** Non-blocking floating snackbar or retry button in `AppErrorWidget`.

### 2. Authentication Errors (`AuthErrorMapper`)
- **Cause:** Invalid password, user not found, account disabled.
- **User Message:** Clean human-readable translation (e.g. "Invalid email or password").
- **UI Behavior:** Inline form error text below credentials inputs.

### 3. Authorization & Permissions Errors (HTTP 403)
- **Cause:** Attempting to access another user's project, or accessing Admin-only routes.
- **User Message:** "You do not have permission to view or edit this project."
- **UI Behavior:** Clear warning message and automatic redirect to `/engineer/projects`.

### 4. File Size & Format Validation Errors (HTTP 400)
- **Cause:** File exceeds 50 MB or extension not in allowlist.
- **User Message:** "File must be under 50 MB and in an approved technical format (PDF, CAD, Images, ZIP)."
- **UI Behavior:** Rejection banner in file picker with immediate upload cancellation.

### 5. Workflow State Conflict Errors (HTTP 400)
- **Cause:** Submitting an already submitted project, or requesting a 4th correction round.
- **User Message:** "This action cannot be completed for the current project status." (or "Maximum correction rounds (3) exceeded").
- **UI Behavior:** Informational dialog with state refresh.

---

## 3. UI Error Widgets
- **`AppErrorWidget`:** Centered card with error icon, friendly message, and an explicit **Retry** button wired to invalidate the corresponding Riverpod provider.
- **Snackbars:** Floating contextual banners (`AppColors.error`) with short, actionable messaging.
