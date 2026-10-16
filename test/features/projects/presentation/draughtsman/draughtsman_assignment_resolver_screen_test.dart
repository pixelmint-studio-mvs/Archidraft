import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:archi_draft/src/features/projects/domain/assignment.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/domain/project_status.dart';
import 'package:archi_draft/src/features/projects/providers/assignment_providers.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';
import 'package:archi_draft/src/features/projects/presentation/draughtsman/draughtsman_assignment_resolver_screen.dart';
import 'package:archi_draft/src/features/projects/presentation/draughtsman/draughtsman_assignment_detail_screen.dart';
import 'package:archi_draft/src/shared/widgets/app_state_widgets.dart';

void main() {
  const testProjectId = 'prj_commercial_01';
  const testAssignmentId = 'asgn_dman_99';
  const testDraughtsmanId = 'dman_user_1';

  final testAssignment = Assignment(
    id: testAssignmentId,
    projectId: testProjectId,
    draughtsmanId: testDraughtsmanId,
    status: 'PENDING',
    projectName: 'Commercial Office Block',
    projectAddress: '100 Business Boulevard',
    drawingType: 'Structural Layout',
  );

  final testProject = Project(
    projectId: testProjectId,
    projectName: 'Commercial Office Block',
    projectAddress: '100 Business Boulevard',
    drawingName: 'Structural Layout Drawing',
    drawingType: 'Structural',
    clientId: 'client_corp_1',
    currentAssignmentId: testAssignmentId,
    status: ProjectStatus.waitingAcceptance.toFirestoreString(),
    isTrainingProject: 0,
  );

  Widget createTestApp({
    required String assignmentId,
    Assignment? initialAssignment,
    List<Assignment>? assignments,
    Project? projectData,
  }) {
    return ProviderScope(
      overrides: [
        draughtsmanAssignmentsProvider.overrideWith(
          (ref) => assignments ?? [testAssignment],
        ),
        projectProvider(testProjectId).overrideWith(
          (ref) => projectData ?? testProject,
        ),
      ],
      child: MaterialApp(
        home: DraughtsmanAssignmentResolverScreen(
          assignmentId: assignmentId,
          initialAssignment: initialAssignment,
        ),
      ),
    );
  }

  group('DraughtsmanAssignmentResolverScreen Tests', () {
    testWidgets(
      'Deep-link without state.extra resolves assignment by assignment ID and renders DraughtsmanAssignmentDetailScreen',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            assignmentId: testAssignmentId,
            initialAssignment: null,
            assignments: [testAssignment],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DraughtsmanAssignmentDetailScreen), findsOneWidget);
        expect(find.text('Assignment Details'), findsOneWidget);
        expect(find.text('Commercial Office Block'), findsOneWidget);
        expect(find.text('Accept'), findsOneWidget);
        expect(find.text('Reject'), findsOneWidget);
      },
    );

    testWidgets(
      'Deep-link without state.extra resolves assignment by projectId and renders DraughtsmanAssignmentDetailScreen',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            assignmentId: testProjectId,
            initialAssignment: null,
            assignments: [testAssignment],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DraughtsmanAssignmentDetailScreen), findsOneWidget);
        expect(find.text('Commercial Office Block'), findsOneWidget);
        expect(find.text('Accept'), findsOneWidget);
      },
    );

    testWidgets(
      'Navigation with valid state.extra renders DraughtsmanAssignmentDetailScreen directly',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            assignmentId: testAssignmentId,
            initialAssignment: testAssignment,
            assignments: [], // Not queried when initialAssignment is provided
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DraughtsmanAssignmentDetailScreen), findsOneWidget);
        expect(find.text('Commercial Office Block'), findsOneWidget);
      },
    );

    testWidgets(
      'Deep-link with unknown assignment renders Draughtsman-safe unavailable state',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            assignmentId: 'unknown_asgn_404',
            initialAssignment: null,
            assignments: [],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Assignment Unavailable'), findsOneWidget);
        expect(find.text('View Draughtsman Studio'), findsOneWidget);
        expect(find.byType(DraughtsmanAssignmentDetailScreen), findsNothing);
      },
    );

    testWidgets(
      'Displays loading indicator while assignments are loading',
      (tester) async {
        final completer = Completer<List<Assignment>>();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              draughtsmanAssignmentsProvider.overrideWith(
                (ref) => completer.future,
              ),
              projectProvider(testProjectId).overrideWith(
                (ref) => testProject,
              ),
            ],
            child: const MaterialApp(
              home: DraughtsmanAssignmentResolverScreen(
                assignmentId: testAssignmentId,
                initialAssignment: null,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(AppLoadingIndicator), findsOneWidget);
        expect(find.text('Locating draughtsman assignment...'), findsOneWidget);

        completer.complete([testAssignment]);
        await tester.pumpAndSettle();

        expect(find.byType(DraughtsmanAssignmentDetailScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Displays error widget with retry when provider fails',
      (tester) async {
        int callCount = 0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              draughtsmanAssignmentsProvider.overrideWith((ref) {
                callCount++;
                if (callCount == 1) {
                  return Future<List<Assignment>>.error(
                    Exception('Network connection lost'),
                  );
                }
                return Future.value([testAssignment]);
              }),
              projectProvider(testProjectId).overrideWith(
                (ref) => testProject,
              ),
            ],
            child: const MaterialApp(
              home: DraughtsmanAssignmentResolverScreen(
                assignmentId: testAssignmentId,
                initialAssignment: null,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byType(AppErrorWidget), findsOneWidget);
        expect(find.text('Failed to load assignment.'), findsOneWidget);

        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        expect(find.byType(DraughtsmanAssignmentDetailScreen), findsOneWidget);
      },
    );
  });
}
