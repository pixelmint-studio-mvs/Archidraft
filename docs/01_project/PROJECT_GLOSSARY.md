# PROJECT GLOSSARY

To prevent misinterpretation, all developers and AI agents must use the following definitions.

- **Client:** The customer who requests a drawing project. They own the project but do not execute the technical work.
- **Draughtsman:** The professional technical drawer assigned to execute the project.
- **Admin:** The studio manager who oversees the platform, approves projects, and assigns draughtsmen.
- **Project:** The overarching request created by a Client. It tracks the macro status (e.g., DRAFT, IN_PROGRESS, COMPLETED).
- **Assignment:** A sub-record linking a Project to a specific Draughtsman. It tracks the micro status of that specific worker (e.g., PENDING, ACCEPTED).
- **Drawing Version:** A file uploaded by a Draughtsman during the execution phase.
- **Correction:** An explicit, tracked request by a Client asking the Draughtsman to revise a submitted drawing.
- **Correction Round:** A counter tracking how many times the Client or Engineer has requested revisions. Increments indefinitely without an arbitrary limit until final drawing approval.
- **Activity Log:** An immutable, server-generated record of a critical event (e.g., `PROJECT_SUBMITTED`).
- **Project Status:** The current state of the main Project (see `STATE_MACHINES.md`).
- **Assignment Status:** The current state of the Draughtsman's assignment (see `STATE_MACHINES.md`).
- **Callable Function:** A Firebase Cloud Function triggered directly by the Flutter app. Used for all critical operations to ensure security.
- **Firestore:** The NoSQL database used for application data.
- **Storage Rules:** The security rules governing file uploads/downloads in Firebase Storage.
- **Idempotency:** A design principle ensuring that if a Cloud Function is accidentally run twice for the same event (e.g., due to network retry), it does not create duplicate activity logs or corrupt the state.
- **Unique User ID (`identification_number`):** A permanent, sequential identifier assigned to each and every user upon account creation:
  - **For Engineers/Architects:** `ENG_XX`
  - **For Draughtsman:** `DM_XX`
  - **For Student:** `STU_XX`
  *(Where `XX` are numbers and can be incremented and added infinitely).*
- **PIXMINT BOT 2.0:** The contextual, grounded architectural AI assistant platform embedded across ARCHI DRAFT client portals (Engineer, Draughtsman, Student) and governed by Studio Admins via the Next.js Admin Web Control Center (`/bot`).
- **Grounded Architectural Retrieval:** The RAG retrieval engine used by PIXMINT BOT that searches studio knowledge documents, CAD standards, and learning modules before generating assistant answers, citing source references and metadata.
- **Session Lifecycle & Deduplication:** The architecture guaranteeing that a user's active conversation session is preserved across app reloads, page navigation, and launcher minimizes without creating duplicate "New Conversation" entries in Cloudflare D1.
- **Question Analytics & Knowledge Gap Audit:** The studio administrative audit engine that analyzes conversational queries across portals, clusters semantic question variations, and identifies topics with negative feedback or documentation gaps.
