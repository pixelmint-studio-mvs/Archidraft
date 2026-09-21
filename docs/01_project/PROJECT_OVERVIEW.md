# PROJECT OVERVIEW

## What is ARCHI DRAFT?
ARCHI DRAFT is a professional architectural drafting platform developed for the Draughtsman Studio ecosystem. It serves as a secure, managed bridge between clients who need technical drawings and professional draughtsmen who execute the work, overseen by an Admin.

## Problem Being Solved
Architectural drafting involves large files (CAD, DWG, PDF), multiple correction rounds, and critical accountability. Email or generic file-sharing lacks structure, leading to overwritten files, unrecorded communication, and scope creep. ARCHI DRAFT solves this by enforcing a strict workflow, managing file versions, and tracking all activity via immutable server logs.

## Main Users

- **CLIENT:** Individuals or companies requesting architectural drawings. They upload reference files, review progress, and approve final deliverables.
- **DRAUGHTSMAN:** Professional drafters assigned to projects. They download references, execute the work, and upload drawing versions.
- **ADMIN:** Studio managers who oversee the ecosystem. They approve new projects, assign draughtsmen, and monitor workflow integrity.
- **STUDENT:** Learners using the platform's training environment. They view training modules, complete mock/sanitized projects assigned by an Admin, and track their progress without accessing live client data.

## Core Purpose & Lifecycle

1. **Submission:** The system allows Clients to create and submit drawing projects securely.
2. **Review & Assignment:** The Admin reviews submitted projects for feasibility and assigns them to an available Draughtsman.
3. **Execution:** The Draughtsman accepts the assignment and completes the drawing work iteratively.
4. **Review & Corrections:** The Client reviews the uploaded drawing. If changes are needed, the Client can request corrections.
5. **Correction Limits:** To prevent scope creep, projects have a strict maximum of **3 correction rounds**.
6. **Completion:** Once approved by the Client, the project is officially marked as COMPLETED.
