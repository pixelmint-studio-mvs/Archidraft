import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../domain/project.dart';

/// Repository for project CRUD operations.
///
/// Simple operations (createDraft, updateDraft, read) use direct Firestore SDK.
/// Critical operations (submitProject) use Callable Cloud Functions.
///
/// Ref: docs/02_architecture/SYSTEM_ARCHITECTURE.md — Hybrid Architecture
/// Ref: docs/02_architecture/BACKEND_ACTIONS.md — Action contracts
class ProjectRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  ProjectRepository(this._firestore, this._functions);

  CollectionReference<Map<String, dynamic>> get _projectsRef =>
      _firestore.collection('projects');

  // ──────────────────────────────────────────
  // SIMPLE OPERATIONS (Direct Firestore)
  // ──────────────────────────────────────────

  /// Creates a new project draft in Firestore.
  ///
  /// The `clientId` on the [project] must be the authenticated user's UID.
  /// Sets status=DRAFT, correctionRound=0, createdAt=server timestamp.
  ///
  /// Returns the auto-generated project ID.
  Future<String> createDraft(Project project) async {
    final docRef = _projectsRef.doc();
    await docRef.set(project.copyWith().toFirestoreCreate());
    return docRef.id;
  }

  /// Updates only the client-editable fields of a draft project.
  ///
  /// Preconditions (validated locally, enforced by Security Rules):
  /// - Project must exist
  /// - Caller must be the owner
  /// - Status must be DRAFT
  Future<void> updateDraft(Project project) async {
    await _projectsRef.doc(project.projectId).update(
      project.toEditableFieldsMap(),
    );
  }

  /// Fetches a single project by its ID.
  ///
  /// Returns `null` if the document does not exist.
  Future<Project?> getProject(String projectId) async {
    final doc = await _projectsRef.doc(projectId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Project.fromFirestore(doc);
  }

  /// Returns a real-time stream of the client's projects.
  ///
  /// Query: `clientId == clientId`, ordered by `createdAt` descending.
  /// This query is compatible with Firestore Security Rules (ownership filter).
  Stream<List<Project>> watchClientProjects(String clientId) {
    return _projectsRef
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Project.fromFirestore(doc))
            .toList());
  }

  // ──────────────────────────────────────────
  // CRITICAL OPERATIONS (Cloud Functions)
  // ──────────────────────────────────────────

  /// Submits a project via the `submitProject` Callable Cloud Function.
  ///
  /// The Cloud Function validates:
  /// - Authentication (context.auth.uid)
  /// - Role = CLIENT
  /// - Ownership (project.clientId == auth.uid)
  /// - Status = DRAFT
  /// - Required fields are complete
  ///
  /// The [actionId] ensures idempotency on retry.
  ///
  /// Ref: docs/02_architecture/BACKEND_ACTIONS.md — submitProject contract
  Future<void> submitProject({
    required String projectId,
    required String actionId,
  }) async {
    final callable = _functions.httpsCallable('submitProject');
    await callable.call<dynamic>({
      'projectId': projectId,
      'actionId': actionId,
    });
  }
}
