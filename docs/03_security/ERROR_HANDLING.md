# ERROR HANDLING STANDARD

## RULE
Users must **never** see raw technical errors such as `FirebaseException`, `permission-denied`, `internal-error`, or stack traces in the UI.

Technical Error → Application Error Handling → User-Friendly Message

## ERROR CATEGORIES

### 1. Network Error
- **User Message:** "No internet connection. Please check your network and try again."
- **Retry Allowed?** Yes.
- **Logging Required?** No.
- **Recommended UI Behavior:** Snackbar or retry button.

### 2. Authentication Error
- **User Message:** "Invalid email or password. Please try again."
- **Retry Allowed?** Yes.
- **Logging Required?** No (Firebase Auth handles this).
- **Recommended UI Behavior:** Inline form error.

### 3. Authorization Error
- **User Message:** "You don't have permission to perform this action."
- **Retry Allowed?** No.
- **Logging Required?** Yes (Potential security attempt).
- **Recommended UI Behavior:** Dialog or redirect to dashboard.

### 4. Validation Error
- **User Message:** "Please check the highlighted fields and try again."
- **Retry Allowed?** Yes.
- **Logging Required?** No.
- **Recommended UI Behavior:** Inline form error.

### 5. File Upload Error
- **User Message:** "Failed to upload file. Please ensure it is a supported format and under 50 MB."
- **Retry Allowed?** Yes.
- **Logging Required?** Yes (if backend rejected).
- **Recommended UI Behavior:** Snackbar.

### 6. Server/Unknown Error
- **User Message:** "An unexpected error occurred. Please try again later."
- **Retry Allowed?** Yes (after a delay).
- **Logging Required?** Yes (Send to crashlytics/logging service).
- **Recommended UI Behavior:** Dialog or Snackbar.

## EXAMPLES
**DO NOT SHOW:** `HttpException: [403 Forbidden] The caller does not have permission to execute the specified operation.`
**SHOW:** "You don't have permission to perform this action."

Do not expose internal system details.
