# PROJECT GLOSSARY

To prevent misinterpretation, all developers and AI agents must use the following definitions.

- **Client:** The customer who requests a drawing project. They own the project but do not execute the technical work.
- **Draughtsman:** The professional technical drawer assigned to execute the project.
- **Admin:** The studio manager who oversees the platform, approves projects, and assigns draughtsmen.
- **Project:** The overarching request created by a Client. It tracks the macro status (e.g., DRAFT, IN_PROGRESS, COMPLETED).
- **Assignment:** A sub-record linking a Project to a specific Draughtsman. It tracks the micro status of that specific worker (e.g., PENDING, ACCEPTED).
- **Drawing Version:** A file uploaded by a Draughtsman during the execution phase.
- **Correction:** An explicit, tracked request by a Client asking the Draughtsman to revise a submitted drawing.
- **Correction Round:** A counter tracking how many times the Client has requested revisions. The absolute maximum is 3.
- **Activity Log:** An immutable, server-generated record of a critical event (e.g., `PROJECT_SUBMITTED`).
- **Project Status:** The current state of the main Project (see `STATE_MACHINES.md`).
- **Assignment Status:** The current state of the Draughtsman's assignment (see `STATE_MACHINES.md`).
- **Callable Function:** A Firebase Cloud Function triggered directly by the Flutter app. Used for all critical operations to ensure security.
- **Firestore:** The NoSQL database used for application data.
- **Storage Rules:** The security rules governing file uploads/downloads in Firebase Storage.
- **Idempotency:** A design principle ensuring that if a Cloud Function is accidentally run twice for the same event (e.g., due to network retry), it does not create duplicate activity logs or corrupt the state.
