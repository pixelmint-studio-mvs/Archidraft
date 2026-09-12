const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * submitProject Callable Function
 * 
 * Preconditions:
 * - Caller is authenticated.
 * - Caller has CLIENT role.
 * - Project belongs to caller (`clientId == auth.uid`).
 * - Project status is `DRAFT`.
 * 
 * Writes:
 * - Updates project status to `SUBMITTED`, sets `submittedAt`.
 * - Creates an activity log in `projects/{projectId}/activityLogs`.
 * 
 * Idempotency: Uses `actionId` to prevent duplicate submissions.
 */
exports.submitProject = functions.https.onCall(async (data, context) => {
  // 1. Authentication check
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be signed in to submit a project."
    );
  }
  const uid = context.auth.uid;

  const { projectId, actionId } = data;
  if (!projectId || !actionId) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing projectId or actionId."
    );
  }

  // 2. Role check
  const userDoc = await db.collection("users").doc(uid).get();
  if (!userDoc.exists || userDoc.data().role !== "CLIENT") {
    throw new functions.https.HttpsError(
        "permission-denied",
        "Only clients can submit projects."
    );
  }

  const projectRef = db.collection("projects").doc(projectId);

  // Use a transaction for safe concurrent reads/writes
  return db.runTransaction(async (transaction) => {
    const projectDoc = await transaction.get(projectRef);

    // 3. Project existence and ownership
    if (!projectDoc.exists) {
      throw new functions.https.HttpsError(
          "not-found",
          "Project not found."
      );
    }
    
    const projectData = projectDoc.data();
    if (projectData.clientId !== uid) {
      throw new functions.https.HttpsError(
          "permission-denied",
          "You do not have permission to submit this project."
      );
    }

    // 4. Idempotency and State check
    if (projectData.status === "SUBMITTED" && projectData.lastActionId === actionId) {
      // Silently succeed if this exact action was already processed
      return { success: true, message: "Project already submitted." };
    }

    if (projectData.status !== "DRAFT") {
      throw new functions.https.HttpsError(
          "failed-precondition",
          "Only DRAFT projects can be submitted."
      );
    }

    // Optional: Validate required fields are present
    const requiredFields = ["projectName", "projectAddress", "drawingName", "drawingType", "projectArea"];
    for (const field of requiredFields) {
      if (!projectData[field]) {
        throw new functions.https.HttpsError(
            "failed-precondition",
            `Project is missing required field: ${field}`
        );
      }
    }

    // 5. Update Project Document
    const updateData = {
      status: "SUBMITTED",
      submittedAt: admin.firestore.FieldValue.serverTimestamp(),
      lastActionId: actionId,
    };
    transaction.update(projectRef, updateData);

    // 6. Create Activity Log
    const logRef = projectRef.collection("activityLogs").doc(actionId);
    transaction.set(logRef, {
      actionType: "PROJECT_SUBMITTED",
      actorId: uid,
      actorRole: "CLIENT",
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      details: "Client submitted the project brief.",
    });

    return { success: true, projectId: projectId };
  });
});

/**
 * cancelProject Callable Function
 * 
 * Preconditions:
 * - Caller is authenticated.
 * - Caller has CLIENT role.
 * - Project belongs to caller.
 * - Project status is `DRAFT` or `SUBMITTED`.
 */
exports.cancelProject = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "You must be signed in.");
  }
  const uid = context.auth.uid;

  const { projectId, actionId } = data;
  if (!projectId || !actionId) {
    throw new functions.https.HttpsError("invalid-argument", "Missing arguments.");
  }

  const projectRef = db.collection("projects").doc(projectId);

  return db.runTransaction(async (transaction) => {
    const projectDoc = await transaction.get(projectRef);

    if (!projectDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Project not found.");
    }
    
    const projectData = projectDoc.data();
    if (projectData.clientId !== uid) {
      throw new functions.https.HttpsError("permission-denied", "Permission denied.");
    }

    if (projectData.status === "CANCELLED" && projectData.lastActionId === actionId) {
      return { success: true };
    }

    if (projectData.status !== "DRAFT" && projectData.status !== "SUBMITTED") {
      throw new functions.https.HttpsError(
          "failed-precondition",
          "Project cannot be cancelled in its current state."
      );
    }

    transaction.update(projectRef, {
      status: "CANCELLED",
      lastActionId: actionId,
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const logRef = projectRef.collection("activityLogs").doc(actionId);
    transaction.set(logRef, {
      actionType: "PROJECT_CANCELLED",
      actorId: uid,
      actorRole: "CLIENT",
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      details: "Client cancelled the project.",
    });

    return { success: true };
  });
});

/**
 * approveProject Callable Function
 * 
 * Preconditions:
 * - Caller is authenticated.
 * - Caller has STUDIO_ADMIN role.
 * - Project status is `SUBMITTED`.
 */
exports.approveProject = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "You must be signed in.");
  
  const uid = context.auth.uid;
  const { projectId, actionId } = data;
  if (!projectId || !actionId) throw new functions.https.HttpsError("invalid-argument", "Missing arguments.");

  // Check Role
  const userDoc = await db.collection("users").doc(uid).get();
  if (!userDoc.exists || userDoc.data().role !== "ADMIN") {
    throw new functions.https.HttpsError("permission-denied", "Only Studio Admins can approve projects.");
  }

  const projectRef = db.collection("projects").doc(projectId);

  return db.runTransaction(async (transaction) => {
    const projectDoc = await transaction.get(projectRef);
    if (!projectDoc.exists) throw new functions.https.HttpsError("not-found", "Project not found.");
    
    const projectData = projectDoc.data();

    if (projectData.status === "WAITING_ASSIGNMENT" && projectData.lastActionId === actionId) {
      return { success: true };
    }

    if (projectData.status !== "SUBMITTED") {
      throw new functions.https.HttpsError("failed-precondition", "Project is not in SUBMITTED state.");
    }

    transaction.update(projectRef, {
      status: "WAITING_ASSIGNMENT",
      lastActionId: actionId,
      approvedAt: admin.firestore.FieldValue.serverTimestamp(),
      approvedBy: uid,
    });

    const logRef = projectRef.collection("activityLogs").doc(actionId);
    transaction.set(logRef, {
      actionType: "PROJECT_APPROVED",
      actorId: uid,
      actorRole: "ADMIN",
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      details: "Studio Admin approved the project.",
    });

    return { success: true };
  });
});

/**
 * rejectProject Callable Function
 * 
 * Preconditions:
 * - Caller is authenticated.
 * - Caller has STUDIO_ADMIN role.
 * - Project status is `SUBMITTED`.
 */
exports.rejectProject = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "You must be signed in.");
  
  const uid = context.auth.uid;
  const { projectId, actionId, reason } = data;
  if (!projectId || !actionId || !reason) throw new functions.https.HttpsError("invalid-argument", "Missing arguments or reason.");

  // Check Role
  const userDoc = await db.collection("users").doc(uid).get();
  if (!userDoc.exists || userDoc.data().role !== "ADMIN") {
    throw new functions.https.HttpsError("permission-denied", "Only Studio Admins can reject projects.");
  }

  const projectRef = db.collection("projects").doc(projectId);

  return db.runTransaction(async (transaction) => {
    const projectDoc = await transaction.get(projectRef);
    if (!projectDoc.exists) throw new functions.https.HttpsError("not-found", "Project not found.");
    
    const projectData = projectDoc.data();

    if (projectData.status === "CANCELLED" && projectData.lastActionId === actionId) {
      return { success: true };
    }

    if (projectData.status !== "SUBMITTED") {
      throw new functions.https.HttpsError("failed-precondition", "Project is not in SUBMITTED state.");
    }

    transaction.update(projectRef, {
      status: "CANCELLED",
      lastActionId: actionId,
      rejectionReason: reason,
      rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
      rejectedBy: uid,
    });

    const logRef = projectRef.collection("activityLogs").doc(actionId);
    transaction.set(logRef, {
      actionType: "PROJECT_REJECTED",
      actorId: uid,
      actorRole: "ADMIN",
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      details: "Studio Admin rejected the project. Reason: " + reason,
    });

    return { success: true };
  });
});

/**
 * assignDraughtsman Callable Function
 * 
 * Preconditions:
 * - Caller is authenticated.
 * - Caller has STUDIO_ADMIN role.
 * - Project status is `WAITING_ASSIGNMENT`.
 */
exports.assignDraughtsman = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "You must be signed in.");
  
  const uid = context.auth.uid;
  const { projectId, actionId, draughtsmanId } = data;
  if (!projectId || !actionId || !draughtsmanId) throw new functions.https.HttpsError("invalid-argument", "Missing arguments.");

  // Check Role
  const userDoc = await db.collection("users").doc(uid).get();
  if (!userDoc.exists || userDoc.data().role !== "ADMIN") {
    throw new functions.https.HttpsError("permission-denied", "Only Studio Admins can assign draughtsmen.");
  }

  // Validate draughtsman
  const draughtsmanDoc = await db.collection("users").doc(draughtsmanId).get();
  if (!draughtsmanDoc.exists || draughtsmanDoc.data().role !== "DRAUGHTSMAN") {
    throw new functions.https.HttpsError("invalid-argument", "Invalid draughtsman ID.");
  }

  const projectRef = db.collection("projects").doc(projectId);

  return db.runTransaction(async (transaction) => {
    const projectDoc = await transaction.get(projectRef);
    if (!projectDoc.exists) throw new functions.https.HttpsError("not-found", "Project not found.");
    
    const projectData = projectDoc.data();

    if (projectData.status === "WAITING_ACCEPTANCE" && projectData.lastActionId === actionId) {
      return { success: true };
    }

    if (projectData.status !== "WAITING_ASSIGNMENT") {
      throw new functions.https.HttpsError("failed-precondition", "Project is not waiting for assignment.");
    }

    transaction.update(projectRef, {
      status: "WAITING_ACCEPTANCE",
      lastActionId: actionId,
      draughtsmanId: draughtsmanId,
      draughtsmanName: draughtsmanDoc.data().name,
      assignedAt: admin.firestore.FieldValue.serverTimestamp(),
      assignedBy: uid,
    });

    const logRef = projectRef.collection("activityLogs").doc(actionId);
    transaction.set(logRef, {
      actionType: "DRAUGHTSMAN_ASSIGNED",
      actorId: uid,
      actorRole: "ADMIN",
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      details: "Studio Admin assigned draughtsman: " + draughtsmanDoc.data().name,
    });

    return { success: true };
  });
});

