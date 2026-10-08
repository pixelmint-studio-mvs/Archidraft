import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:archi_draft/src/features/auth/domain/user_profile.dart';
import 'package:archi_draft/src/features/auth/providers/auth_providers.dart';
import 'package:archi_draft/src/features/portfolio/domain/portfolio_project.dart';
import 'package:archi_draft/src/features/portfolio/providers/portfolio_providers.dart';
import 'package:archi_draft/src/features/profile/domain/student_credential.dart';
import 'package:archi_draft/src/features/profile/providers/credentials_providers.dart';
import 'package:archi_draft/src/features/profile/domain/student_achievement.dart';
import 'package:archi_draft/src/features/profile/providers/achievements_providers.dart';
import 'package:archi_draft/src/features/training/domain/training_module.dart';
import 'package:archi_draft/src/features/training/providers/training_providers.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/training/presentation/student_studio_screen.dart';
import 'package:archi_draft/src/features/profile/domain/student_metrics.dart';
import 'package:archi_draft/src/features/profile/providers/metrics_providers.dart';
import 'package:archi_draft/src/features/profile/presentation/widgets/student_skill_matrix.dart';

void main() {
  final sampleProfile = UserProfile(
    id: 'student_123',
    email: 'student@example.com',
    name: 'Alex Drafter',
    mobile: '9876543210',
    role: 'STUDENT',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  final sampleProjects = [
    PortfolioProject(
      projectId: 'proj_alpha',
      projectName: 'Commercial Complex HVAC Plan',
      drawingType: 'HVAC Ducting',
      projectArea: '5000 sq ft',
      isTrainingProject: true,
      approvedAt: DateTime.utc(2026, 10, 6),
      finalDrawing: PortfolioFinalDrawing(
        fileId: 'file_hvac',
        sanitizedName: 'hvac_final.dwg',
        downloadUrl: '/api/files/file_hvac/download',
      ),
      evaluation: PortfolioEvaluation(
        result: 'APPROVED',
        overallPercentage: 95,
        criteria: [],
      ),
    ),
  ];

  final sampleCredentials = [
    StudentCredential(
      id: 'cred_hvac',
      type: 'MODULE_COMPLETION',
      title: 'HVAC Drafting Specialist',
      description: 'Advanced HVAC system layout.',
      referenceId: 'mod_hvac',
      issuedAt: DateTime.utc(2026, 10, 6),
      certificateObjectKey: 'cert.pdf',
      verificationToken: 'token_hvac',
    ),
  ];

  final sampleAchievements = [
    StudentAchievement(
      id: 'first_drawing_approved',
      title: 'First Approval',
      description: 'First drawing approved',
      category: 'PRACTICAL',
      icon: 'verified_outlined',
      isUnlocked: true,
      unlockedAt: DateTime.utc(2026, 10, 6),
      currentProgress: 1,
      targetProgress: 1,
    ),
  ];

  Widget createStudioTestWidget({
    List<PortfolioProject>? portfolio,
    List<StudentCredential>? credentials,
    List<StudentAchievement>? achievements,
    StudentMetrics? metrics,
  }) {
    return ProviderScope(
      overrides: [
        userProfileProvider.overrideWith((ref) => sampleProfile),
        categoryProgressProvider.overrideWith((ref) => <TrainingCategoryProgress>[]),
        studentModulesProvider.overrideWith((ref) => <TrainingModule>[]),
        studentAssignmentsProvider.overrideWith((ref) => <Project>[]),
        studentCorrectionsProvider.overrideWith((ref) => []),
        studentActivityProvider.overrideWith((ref) => []),
        studentPortfolioProvider.overrideWith((ref) => portfolio ?? sampleProjects),
        studentCredentialsProvider.overrideWith((ref) => credentials ?? sampleCredentials),
        studentAchievementsProvider.overrideWith((ref) => achievements ?? sampleAchievements),
        if (metrics != null)
          studentMetricsProvider.overrideWith((ref) => metrics),
      ],
      child: const MaterialApp(
        home: StudentStudioScreen(),
      ),
    );
  }

  testWidgets('StudentStudioScreen renders Portfolio Highlights section with counters and deliverable', (tester) async {
    await tester.pumpWidget(createStudioTestWidget());
    await tester.pumpAndSettle();

    // Verify Highlights section title
    expect(find.text('PORTFOLIO & EVIDENCE'), findsOneWidget);
    expect(find.text('Approved Works'), findsOneWidget);
    expect(find.text('Credentials'), findsOneWidget);
    expect(find.text('Milestones'), findsOneWidget);

    // Verify Latest Approved Deliverable
    expect(find.text('LATEST APPROVED DELIVERABLE'), findsOneWidget);
    expect(find.text('Commercial Complex HVAC Plan'), findsOneWidget);
    expect(find.text('95% Score'), findsOneWidget);

    // Verify navigation button
    expect(find.text('View Full Portfolio \u2192'), findsOneWidget);
  });

  testWidgets('StudentStudioScreen renders empty note when student has no portfolio items', (tester) async {
    await tester.pumpWidget(createStudioTestWidget(
      portfolio: [],
      credentials: [],
      achievements: [],
    ));
    await tester.pumpAndSettle();

    expect(find.text('PORTFOLIO & EVIDENCE'), findsOneWidget);
    expect(find.text('Complete practical assignments to build your verified portfolio.'), findsOneWidget);
    expect(find.text('View Full Portfolio \u2192'), findsOneWidget);
  });

  testWidgets('StudentStudioScreen renders Professional Readiness Evidence section when available', (tester) async {
    final sampleMetrics = StudentMetrics(
      learning: [],
      practical: [],
      activity: ActivityMetric(completedProjects: 1, correctionRounds: 0),
      readiness: StudentReadiness(
        curriculum: ReadinessCurriculum(completedLessons: 10, totalLessons: 12, percentage: 83),
        practical: ReadinessPractical(completedProjects: 1, approvedDeliverables: 1),
        precision: ReadinessPrecision(averageScore: 4.5, maxScore: 5.0, accuracyScore: 4.5, standardsScore: 4.5, evaluationCount: 1),
        revision: ReadinessRevision(correctionsIssued: 1, correctionsResolved: 1, resolutionRate: 100, totalRounds: 1),
      ),
      disciplines: [
        DisciplineCompetency(
          discipline: 'Architectural',
          state: 'Practical Evidence Demonstrated',
          completedLessons: 4,
          totalLessons: 4,
          completedProjects: 1,
          evaluationScore: 4.5,
        ),
      ],
    );

    await tester.pumpWidget(createStudioTestWidget(metrics: sampleMetrics));
    await tester.pumpAndSettle();

    expect(find.text('PROFESSIONAL READINESS EVIDENCE'), findsOneWidget);
    expect(find.text('Curriculum Mastery'), findsOneWidget);
    expect(find.text('83%'), findsOneWidget);
    expect(find.text('Practical Execution'), findsOneWidget);
    expect(find.text('1 Project'), findsOneWidget);
    expect(find.text('Technical Precision'), findsOneWidget);
    expect(find.text('4.5 / 5.0'), findsNWidgets(2));
    expect(find.text('Revision Discipline'), findsOneWidget);
    expect(find.text('100% Resolved'), findsOneWidget);
    expect(find.text('DISCIPLINE COMPETENCY'), findsOneWidget);
    expect(find.text('Practical Evidence Demonstrated'), findsOneWidget);
  });

  testWidgets('Discipline Competency card renders Municipal Approval with Practical Evidence Demonstrated without overflow on narrow viewport', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final metricsWithMunicipalApproval = StudentMetrics(
      learning: [],
      practical: [],
      activity: ActivityMetric(completedProjects: 1, correctionRounds: 0),
      disciplines: [
        DisciplineCompetency(
          discipline: 'Municipal Approval',
          state: 'Practical Evidence Demonstrated',
          completedLessons: 2,
          totalLessons: 2,
          completedProjects: 1,
          evaluationScore: 4.8,
        ),
      ],
    );

    await tester.pumpWidget(createStudioTestWidget(metrics: metricsWithMunicipalApproval));
    await tester.pumpAndSettle();

    expect(find.text('DISCIPLINE COMPETENCY'), findsOneWidget);
    expect(find.text('Municipal Approval'), findsOneWidget);
    expect(find.text('Practical Evidence Demonstrated'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Discipline Competency card renders on ultra-narrow 320px and wide 1024px viewports without error', (tester) async {
    final sampleMetrics = StudentMetrics(
      learning: [],
      practical: [],
      activity: ActivityMetric(completedProjects: 1, correctionRounds: 0),
      disciplines: [
        DisciplineCompetency(
          discipline: 'Municipal Approval',
          state: 'Practical Evidence Demonstrated',
          completedLessons: 2,
          totalLessons: 2,
          completedProjects: 1,
          evaluationScore: 4.8,
        ),
      ],
    );

    // Ultra-narrow 320px viewport
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentMetricsProvider.overrideWith((ref) => sampleMetrics),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: StudentSkillMatrix()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Municipal Approval'), findsOneWidget);
    expect(find.text('Practical Evidence Demonstrated'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Wide 1024px viewport
    tester.view.physicalSize = const Size(1024, 768);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentMetricsProvider.overrideWith((ref) => sampleMetrics),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: StudentSkillMatrix()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Municipal Approval'), findsOneWidget);
    expect(find.text('Practical Evidence Demonstrated'), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
