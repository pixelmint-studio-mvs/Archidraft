import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:archi_draft/src/features/projects/domain/assignment.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/domain/project_status.dart';
import 'package:archi_draft/src/features/projects/domain/project_file.dart';
import 'package:archi_draft/src/features/projects/domain/drawing_version.dart';
import 'package:archi_draft/src/features/projects/domain/correction.dart';
import 'package:archi_draft/src/features/projects/domain/evaluation.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';
import 'package:archi_draft/src/features/projects/providers/file_providers.dart';
import 'package:archi_draft/src/features/training/providers/training_providers.dart';
import 'package:archi_draft/src/features/projects/presentation/student/student_assignment_resolver_screen.dart';
import 'package:archi_draft/src/features/projects/presentation/student/student_project_workspace_screen.dart';

void main() {
  const testProjectId = 'prj_assigned_01';
  const testAssignmentId = 'asgn_student_99';

  final testProject = Project(
    projectId: testProjectId,
    projectName: 'Residential Villa Floor Plan',
    projectAddress: '42 Orchid Way',
    drawingName: 'Ground Floor Plan',
    drawingType: 'Architectural Plan',
    clientId: 'client_101',
    currentAssignmentId: testAssignmentId,
    status: ProjectStatus.inProgress.toFirestoreString(),
    correctionRound: 0,
    isTrainingProject: 1,
  );

  Widget createTestApp({
    required String assignmentId,
    Assignment? initialAssignment,
    List<Project>? studentAssignments,
    Project? projectData,
  }) {
    return ProviderScope(
      overrides: [
        studentAssignmentsProvider.overrideWith((ref) => studentAssignments ?? [testProject]),
        projectProvider(testProjectId).overrideWith((ref) => projectData ?? testProject),
        projectFilesProvider(testProjectId).overrideWith((ref) => <ProjectFile>[]),
        projectDrawingVersionsProvider(testProjectId).overrideWith((ref) => <DrawingVersion>[]),
        projectCorrectionsProvider(testProjectId).overrideWith((ref) => <Correction>[]),
        projectEvaluationsProvider(testProjectId).overrideWith((ref) => <Evaluation>[]),
        if (assignmentId != testProjectId)
          projectProvider(assignmentId).overrideWith((ref) => null),
      ],
      child: MaterialApp(
        home: StudentAssignmentResolverScreen(
          assignmentId: assignmentId,
          initialAssignment: initialAssignment,
        ),
      ),
    );
  }

  group('StudentAssignmentResolverScreen Tests', () {
    testWidgets('Deep-link without state.extra resolves project and renders StudentProjectWorkspaceScreen', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          assignmentId: testAssignmentId,
          initialAssignment: null, // Simulates direct URL / refresh without extra
          studentAssignments: [testProject],
        ),
      );
      await tester.pumpAndSettle();

      // Verifies no null-cast exception occurs
      expect(find.byType(StudentProjectWorkspaceScreen), findsOneWidget);
      expect(find.text('Residential Villa Floor Plan'), findsOneWidget);
      expect(find.text('YOUR WORKSPACE DRAFT'), findsOneWidget);
    });

    testWidgets('Deep-link with non-existent assignment renders student-safe unavailable state', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          assignmentId: 'unknown_assignment_xyz',
          initialAssignment: null,
          studentAssignments: [], // Empty list
        ),
      );
      await tester.pumpAndSettle();

      // Verifies clean student fallback
      expect(find.text('Assignment Unavailable'), findsOneWidget);
      expect(find.text('View My Projects'), findsOneWidget);
      expect(find.byType(StudentProjectWorkspaceScreen), findsNothing);

      // Verifies no draughtsman UI or draughtsman back buttons are present
      expect(find.text('Draughtsman Assignment Details'), findsNothing);
    });

    testWidgets('Navigation with state.extra as Assignment extracts projectId and renders workspace', (tester) async {
      final extraAssignment = Assignment(
        id: testAssignmentId,
        projectId: testProjectId,
        draughtsmanId: 'student_user_1',
        status: 'IN_PROGRESS',
        createdAt: DateTime.utc(2026, 10, 5),
      );

      await tester.pumpWidget(
        createTestApp(
          assignmentId: testAssignmentId,
          initialAssignment: extraAssignment,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StudentProjectWorkspaceScreen), findsOneWidget);
      expect(find.text('Residential Villa Floor Plan'), findsOneWidget);
    });
  });
}
