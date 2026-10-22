import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:archi_draft/src/features/projects/domain/evaluation.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/presentation/student/widgets/evaluation_card.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';
import 'package:archi_draft/src/features/training/domain/lesson.dart';
import 'package:archi_draft/src/features/training/domain/training_module.dart';
import 'package:archi_draft/src/features/training/presentation/training_module_detail_screen.dart';
import 'package:archi_draft/src/features/training/providers/training_providers.dart';

void main() {
  final sampleLessons = <Lesson>[
    const Lesson(
      id: 'les_1',
      moduleId: 'mod_pure',
      title: 'Introduction to Spatial CAD',
      content: 'Core foundations',
      lessonOrder: 1,
      status: 'COMPLETED',
      estimatedDuration: '15 mins',
    ),
    const Lesson(
      id: 'les_2',
      moduleId: 'mod_pure',
      title: 'Vector Alignment Patterns',
      content: 'Advanced lines',
      lessonOrder: 2,
      status: 'NOT_STARTED',
      estimatedDuration: '25 mins',
    ),
  ];

  final pureModule = const TrainingModule(
    id: 'mod_pure',
    title: 'Architectural Foundations',
    description: 'Master core drafting concepts',
    category: 'CAD',
    level: 'Beginner',
    progress: 50.0,
    status: 'In Progress',
    type: 'Module',
  );

  final hybridModule = const TrainingModule(
    id: 'mod_hybrid',
    title: 'HVAC Ducting & BIM Layout',
    description: 'Learn theory and execute real practical assignment',
    category: 'MEP',
    level: 'Intermediate',
    progress: 60.0,
    status: 'In Progress',
    type: 'Module',
  );

  final practicalOnlyModule = const TrainingModule(
    id: 'mod_practical',
    title: 'Commercial Complex Mock Project',
    description: 'Studio practical assignment under Admin supervision',
    category: 'COMMERCIAL',
    level: 'Advanced',
    progress: 0.0,
    status: 'Not Started',
    type: 'Mock Project',
  );

  final linkedProjectActive = const Project(
    projectId: 'prj_hybrid_01',
    projectName: 'Tokyo Commercial Complex HVAC',
    projectAddress: '1-1 Marunouchi, Chiyoda, Tokyo',
    drawingName: 'HVAC-Duct-L1',
    drawingType: 'HVAC Ducting',
    clientId: 'admin_studio',
    status: 'IN_PROGRESS',
    correctionRound: 1,
    trainingModuleId: 'mod_hybrid',
    currentAssignmentId: 'asg_hybrid_01',
  );

  final linkedProjectWaitingAcceptance = const Project(
    projectId: 'prj_practical_01',
    projectName: 'Shinjuku Tower Floor Plan',
    projectAddress: '2-8 Shinjuku, Tokyo',
    drawingName: 'FP-L12',
    drawingType: 'Floor Plan',
    clientId: 'admin_studio',
    status: 'WAITING_ACCEPTANCE',
    correctionRound: 0,
    trainingModuleId: 'mod_practical',
    currentAssignmentId: 'asg_practical_01',
  );

  final sampleEvaluation = Evaluation(
    id: 'eval_01',
    projectId: 'prj_hybrid_01',
    drawingVersionId: 'dwg_v1',
    evaluatorId: 'admin_01',
    overallResult: EvaluationResult.needsCorrection,
    generalFeedback: 'Check duct clearance along Grid Line C.',
    createdAt: DateTime.utc(2026, 10, 8),
  );

  Widget createTestWidget({
    required String moduleId,
    required TrainingModule module,
    List<Lesson>? lessons,
    List<Project>? assignments,
    List<Evaluation>? evaluations,
  }) {
    return ProviderScope(
      overrides: [
        moduleDetailProvider(moduleId).overrideWith((ref) => module),
        moduleLessonsProvider(moduleId).overrideWith((ref) => lessons ?? []),
        studentAssignmentsProvider.overrideWith((ref) => assignments ?? []),
        if (evaluations != null && assignments != null && assignments.isNotEmpty)
          projectEvaluationsProvider(assignments.first.projectId)
              .overrideWith((ref) => evaluations),
      ],
      child: MaterialApp(
        home: TrainingModuleDetailScreen(moduleId: moduleId),
      ),
    );
  }

  group('TrainingModuleDetailScreen Tests', () {
    testWidgets('Pure learning module renders lessons and no practical card', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          moduleId: 'mod_pure',
          module: pureModule,
          lessons: sampleLessons,
          assignments: [],
        ),
      );
      await tester.pumpAndSettle();

      // Check header and module details
      expect(find.text('Architectural Foundations'), findsWidgets);
      expect(find.text('MODULE LESSONS'), findsOneWidget);
      expect(find.text('Introduction to Spatial CAD'), findsOneWidget);
      expect(find.text('Vector Alignment Patterns'), findsOneWidget);

      // Verify absence of practical assignment card and workspace button
      expect(find.text('PRACTICAL ASSIGNMENT'), findsNothing);
      expect(find.text('Open Practical Workspace'), findsNothing);
      expect(find.text('Accept Practical Assignment'), findsNothing);

      // Verify absence of fabricated mock mentor content
      expect(find.textContaining('Marcus Vance'), findsNothing);
      expect(find.textContaining('AUTOMATED PRE-FLIGHT CAD LINTING'), findsNothing);
      expect(find.text('Submit Training Assignment'), findsNothing);
      expect(find.textContaining('Download Annotated Redline PDF'), findsNothing);
    });

    testWidgets('Hybrid module renders lessons AND linked practical assignment card', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          moduleId: 'mod_hybrid',
          module: hybridModule,
          lessons: sampleLessons,
          assignments: [linkedProjectActive],
        ),
      );
      await tester.pumpAndSettle();

      // Check module and lessons
      expect(find.text('HVAC Ducting & BIM Layout'), findsWidgets);
      expect(find.text('MODULE LESSONS'), findsOneWidget);
      expect(find.text('Introduction to Spatial CAD'), findsOneWidget);

      // Check practical assignment card
      expect(find.text('PRACTICAL ASSIGNMENT'), findsOneWidget);
      expect(find.text('Tokyo Commercial Complex HVAC'), findsOneWidget);
      expect(find.textContaining('HVAC DUCTING'), findsWidgets);
      expect(find.text('ROUND 1'), findsOneWidget);

      // Check action button
      expect(find.text('Open Practical Workspace'), findsOneWidget);
      expect(find.text('Accept Practical Assignment'), findsNothing);

      // Verify fake mentor items are absent
      expect(find.textContaining('Marcus Vance'), findsNothing);
      expect(find.text('Submit Training Assignment'), findsNothing);
    });

    testWidgets('Hybrid module renders EvaluationCard when evaluations exist', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          moduleId: 'mod_hybrid',
          module: hybridModule,
          lessons: sampleLessons,
          assignments: [linkedProjectActive],
          evaluations: [sampleEvaluation],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OFFICIAL EVALUATION'), findsOneWidget);
      expect(find.byType(EvaluationCard), findsOneWidget);
      expect(find.textContaining('Check duct clearance along Grid Line C.'), findsOneWidget);
    });

    testWidgets('Practical-only module renders practical assignment and workspace action', (tester) async {
      final linkedActivePractical = const Project(
        projectId: 'prj_practical_01',
        projectName: 'Shinjuku Tower Floor Plan',
        projectAddress: '2-8 Shinjuku, Tokyo',
        drawingName: 'FP-L12',
        drawingType: 'Floor Plan',
        clientId: 'admin_studio',
        status: 'IN_PROGRESS',
        correctionRound: 0,
        trainingModuleId: 'mod_practical',
      );

      await tester.pumpWidget(
        createTestWidget(
          moduleId: 'mod_practical',
          module: practicalOnlyModule,
          lessons: [],
          assignments: [linkedActivePractical],
        ),
      );
      await tester.pumpAndSettle();

      // Check real metadata in header/hero
      expect(find.text('Commercial Complex Mock Project'), findsWidgets);
      expect(find.text('MOCK PROJECT'), findsOneWidget);
      expect(find.text('MODULE LESSONS'), findsNothing);

      // Check practical assignment card
      expect(find.text('PRACTICAL ASSIGNMENT'), findsOneWidget);
      expect(find.text('Shinjuku Tower Floor Plan'), findsOneWidget);
      expect(find.text('Open Practical Workspace'), findsOneWidget);

      // Verify fake mentor/dropzone items are absent
      expect(find.textContaining('Marcus Vance'), findsNothing);
      expect(find.textContaining('v4.1 ENGINE'), findsNothing);
      expect(find.text('Submit Training Assignment'), findsNothing);
    });

    testWidgets('Practical-only module with missing assignment renders pending card with STUDIO_ADMIN', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          moduleId: 'mod_practical',
          module: practicalOnlyModule,
          lessons: [],
          assignments: [],
        ),
      );
      await tester.pumpAndSettle();

      // Check pending state
      expect(find.text('Assignment Pending Studio Admin'), findsOneWidget);
      expect(find.textContaining('STUDIO_ADMIN'), findsWidgets);
      expect(find.text('STATUS: PENDING ASSIGNMENT'), findsOneWidget);
      expect(find.text('Open Practical Workspace'), findsNothing);
      expect(find.text('Submit Training Assignment'), findsNothing);
    });

    testWidgets('Assignment in WAITING_ACCEPTANCE shows Accept Practical Assignment button', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          moduleId: 'mod_practical',
          module: practicalOnlyModule,
          lessons: [],
          assignments: [linkedProjectWaitingAcceptance],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Accept Practical Assignment'), findsOneWidget);
      expect(find.text('Open Practical Workspace'), findsNothing);
    });

    testWidgets('Back button safely falls back to /student/training when cannot pop', (tester) async {
      String? currentPath;
      final router = GoRouter(
        initialLocation: '/student/training/mod_pure',
        routes: [
          GoRoute(
            path: '/student/training',
            builder: (context, state) {
              currentPath = state.uri.toString();
              return const Scaffold(body: Text('Training Hub'));
            },
          ),
          GoRoute(
            path: '/student/training/:moduleId',
            builder: (context, state) {
              currentPath = state.uri.toString();
              return TrainingModuleDetailScreen(
                moduleId: state.pathParameters['moduleId']!,
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            moduleDetailProvider('mod_pure').overrideWith((ref) => Future.value(pureModule)),
            moduleLessonsProvider('mod_pure').overrideWith((ref) => Future.value(sampleLessons)),
            studentAssignmentsProvider.overrideWith((ref) => <Project>[]),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(currentPath, '/student/training/mod_pure');
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(currentPath, '/student/training');
      expect(find.text('Training Hub'), findsOneWidget);
    });
  });
}
