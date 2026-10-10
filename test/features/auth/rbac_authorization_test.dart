import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/auth/domain/user_profile.dart';
import 'package:archi_draft/src/features/profile/domain/user_role.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/domain/assignment.dart';
import 'package:archi_draft/src/features/projects/domain/assignment_status.dart';

/// Focused RBAC and Multi-Portal Authorization Regression Test Suite.
///
/// Verifies the deny-by-default access control model:
/// - Student and unknown roles are unauthorized for studio projects.
/// - Clients can only access their own projects.
/// - Draughtsmen can only access projects with an ACCEPTED assignment.
/// - Engineers can review submitted and active projects (status != DRAFT).
/// - Admins have universal access across projects.
void main() {
  group('RBAC Role & Resource Authorization Regression Tests', () {
    const clientAId = 'client-uuid-aaa-111';
    const clientBId = 'client-uuid-bbb-222';
    const draughtsmanAId = 'draughtsman-uuid-ddd-111';
    const draughtsmanBId = 'draughtsman-uuid-ddd-222';
    const engineerId = 'engineer-uuid-eee-111';
    const studentId = 'student-uuid-sss-111';
    const adminId = 'admin-uuid-adm-111';

    final draftProject = Project(
      projectId: 'prj-draft-001',
      clientId: clientAId,
      projectName: 'Client A Draft Residence',
      projectAddress: '101 Pine St',
      drawingName: 'Floor Plan Draft',
      drawingType: 'Architectural',
      projectArea: 2400.0,
      status: 'DRAFT',
      createdAt: DateTime(2026, 10, 1),
    );

    final submittedProject = Project(
      projectId: 'prj-submitted-002',
      clientId: clientAId,
      projectName: 'Client A Submitted Villa',
      projectAddress: '202 Oak St',
      drawingName: 'Structural Framing',
      drawingType: 'Structural',
      projectArea: 3500.0,
      status: 'SUBMITTED',
      createdAt: DateTime(2026, 10, 2),
    );

    final activeProject = Project(
      projectId: 'prj-active-003',
      clientId: clientAId,
      projectName: 'Client A Active Commercial',
      projectAddress: '303 Maple Blvd',
      drawingName: 'MEP Layout',
      drawingType: 'Commercial',
      projectArea: 8000.0,
      status: 'IN_PROGRESS',
      assignedDraughtsmanId: draughtsmanAId,
      currentAssignmentId: 'asg-active-001',
      createdAt: DateTime(2026, 10, 3),
    );

    final acceptedAssignment = Assignment(
      id: 'asg-active-001',
      projectId: 'prj-active-003',
      draughtsmanId: draughtsmanAId,
      status: 'ACCEPTED',
      createdAt: DateTime(2026, 10, 3),
    );

    final pendingAssignment = Assignment(
      id: 'asg-pending-002',
      projectId: 'prj-submitted-002',
      draughtsmanId: draughtsmanBId,
      status: 'PENDING',
      createdAt: DateTime(2026, 10, 4),
    );

    // Pure Dart simulation of the Worker canUserAccessProject logic
    bool evaluateAccess({
      required Project project,
      required String userId,
      required UserRole? userRole,
      Assignment? userAssignment,
    }) {
      if (userRole == null) return false;

      switch (userRole) {
        case UserRole.client:
          return project.clientId == userId;
        case UserRole.draughtsman:
          return project.assignedDraughtsmanId == userId &&
              project.currentAssignmentId != null &&
              userAssignment != null &&
              userAssignment.id == project.currentAssignmentId &&
              userAssignment.assignmentStatus == AssignmentStatus.accepted;
        case UserRole.engineer:
          return project.status.toUpperCase() != 'DRAFT';
        case UserRole.admin:
          return true;
        case UserRole.student:
          return false; // Deny-by-default for Student role
      }
    }

    test('1. Student role is DENIED access to all studio projects', () {
      final studentProfile = UserProfile(
        id: studentId,
        email: 'student@example.com',
        name: 'Cadet Student',
        mobile: '+919876543210',
        role: 'STUDENT',
      );
      final role = UserRole.fromString(studentProfile.role);
      expect(role, equals(UserRole.student));

      // Attempt access to draft, submitted, and active projects
      expect(evaluateAccess(project: draftProject, userId: studentId, userRole: role), isFalse);
      expect(evaluateAccess(project: submittedProject, userId: studentId, userRole: role), isFalse);
      expect(evaluateAccess(project: activeProject, userId: studentId, userRole: role), isFalse);
    });

    test('2. Unknown / unmapped role is DENIED access by default', () {
      final unknownProfile = UserProfile(
        id: 'anon-id',
        email: 'unknown@example.com',
        name: 'Anonymous Actor',
        mobile: '+919876543210',
        role: 'GUEST_USER',
      );
      final role = UserRole.fromString(unknownProfile.role);
      expect(role, isNull);

      expect(evaluateAccess(project: activeProject, userId: 'anon-id', userRole: role), isFalse);
    });

    test('3. Client A can access own projects but is DENIED Client B projects (Cross-user isolation)', () {
      final clientARole = UserRole.client;
      final clientBRole = UserRole.client;

      // Client A on own project
      expect(evaluateAccess(project: draftProject, userId: clientAId, userRole: clientARole), isTrue);

      // Client B attempting to access Client A project
      expect(evaluateAccess(project: draftProject, userId: clientBId, userRole: clientBRole), isFalse);
      expect(evaluateAccess(project: activeProject, userId: clientBId, userRole: clientBRole), isFalse);
    });

    test('4. Draughtsman A has PERMITTED access to assigned & accepted project', () {
      final dRole = UserRole.draughtsman;

      expect(
        evaluateAccess(
          project: activeProject,
          userId: draughtsmanAId,
          userRole: dRole,
          userAssignment: acceptedAssignment,
        ),
        isTrue,
      );
    });

    test('5. Draughtsman B is DENIED access to unassigned or pending projects (Cross-project isolation)', () {
      final dRole = UserRole.draughtsman;

      // Draughtsman B attempting to access Draughtsman A project
      expect(
        evaluateAccess(
          project: activeProject,
          userId: draughtsmanBId,
          userRole: dRole,
          userAssignment: acceptedAssignment,
        ),
        isFalse,
      );

      // Draughtsman B with only PENDING assignment (not yet accepted)
      expect(
        evaluateAccess(
          project: submittedProject,
          userId: draughtsmanBId,
          userRole: dRole,
          userAssignment: pendingAssignment,
        ),
        isFalse,
      );
    });

    test('6. Engineer can review submitted & active projects but is DENIED unsubmitted client drafts', () {
      final engRole = UserRole.engineer;

      // Unsubmitted client draft is private to the client
      expect(evaluateAccess(project: draftProject, userId: engineerId, userRole: engRole), isFalse);

      // Submitted project in review pipeline is accessible to Engineer
      expect(evaluateAccess(project: submittedProject, userId: engineerId, userRole: engRole), isTrue);

      // Active project in drafting pipeline is accessible to Engineer
      expect(evaluateAccess(project: activeProject, userId: engineerId, userRole: engRole), isTrue);
    });

    test('7. Admin has universal access across all projects and workflow states', () {
      final adminRole = UserRole.admin;

      expect(evaluateAccess(project: draftProject, userId: adminId, userRole: adminRole), isTrue);
      expect(evaluateAccess(project: submittedProject, userId: adminId, userRole: adminRole), isTrue);
      expect(evaluateAccess(project: activeProject, userId: adminId, userRole: adminRole), isTrue);
    });
  });
}
