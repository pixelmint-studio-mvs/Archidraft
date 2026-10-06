## Current Position
- **Phase**: Phase 5 (Betterment)
- **Task**: Part 5C — Public Certificate Verification + QR (Deployment)
- **Status**: Paused at 2026-10-06 23:42:00 UTC

## Last Session Summary
Diagnosed the "Site Not Found" error for the Firebase Hosting deployment. Discovered that the local repository lacked `.firebaserc`, no Flutter Web build existed locally, and the live Hosting release was over a month old. Authorized and executed a fresh deployment using `firebase use archi-draft`, `flutter build web`, and `firebase deploy --only hosting`. Verified that the SPA fallback works correctly on production, and both the root URL and the `/verify/<token>` deep-link now successfully serve the compiled Flutter web app (`index.html`) rather than a Firebase 404 page.

## In-Progress Work
- Files modified: `.firebaserc` (created), `build/web/` (generated), `firebase.json` (Hosting configuration added previously).
- Tests status: Passing (62/62 verified previously).

## Blockers
None. Deployment was successful.

## Context Dump
- Firebase Hosting is now correctly routing all requests to `index.html` via the SPA rewrite rule.
- GoRouter handles the client-side parsing of `/verify/:token`.
- The live domain is `https://archi-draft.web.app`.

### Decisions Made
- Deployed only hosting using `firebase deploy --only hosting` to ensure no backend services (Worker, D1, R2, Auth) were inadvertently affected.

### Approaches Tried
- Live diagnostic using `firebase hosting:channel:list` to determine exact state of the production environment, which revealed the staleness of the live release and the lack of a local build.
- Followed up with a clean Web build and explicit deployment.

### Current Hypothesis
Part 5C is fully complete. The QR verification deep-link routes correctly to the verification screen on production.

### Files of Interest
- `firebase.json`: Contains the SPA rewrite rule.
- `.firebaserc`: Contains the CLI project target (`archi-draft`).

## Next Steps
1. Proceed with Betterment Part 5D if applicable.
2. Confirm if the live API endpoints (`/api/student/credentials/...`) are functioning correctly when queried from the deployed web app.
