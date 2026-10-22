import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:archi_draft/src/features/portfolio/domain/portfolio_project.dart';
import 'package:archi_draft/src/features/portfolio/providers/portfolio_providers.dart';
import 'package:archi_draft/src/features/portfolio/presentation/student_portfolio_screen.dart';
import 'package:archi_draft/src/features/profile/domain/student_credential.dart';
import 'package:archi_draft/src/features/profile/providers/credentials_providers.dart';
import 'package:archi_draft/src/features/profile/domain/student_achievement.dart';
import 'package:archi_draft/src/features/profile/providers/achievements_providers.dart';
import 'package:archi_draft/src/features/projects/data/file_repository.dart';

import 'package:flutter/services.dart';

class FakeFileRepository implements FileRepository {
  String? downloadedFileId;
  String? downloadedSavePath;
  bool shouldThrow = false;

  @override
  Future<void> downloadFile(
    String fileId,
    String savePath, {
    bool openInBrowser = false,
  }) async {
    if (shouldThrow) {
      throw Exception('API Error: 400 - {"error":"File upload not complete"}');
    }
    downloadedFileId = fileId;
    downloadedSavePath = savePath;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '.';
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('open_filex'),
      (MethodCall methodCall) async {
        return {'type': 0, 'message': 'done'};
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (MethodCall methodCall) async {
        return true;
      },
    );
  });
  final sampleProjects = [
    PortfolioProject(
      projectId: 'proj_1',
      projectName: 'Modern Villa Foundation Plan',
      drawingType: 'Structural / Foundation',
      projectArea: '2500 sq ft',
      isTrainingProject: true,
      approvedAt: DateTime.utc(2026, 10, 5),
      finalDrawing: PortfolioFinalDrawing(
        fileId: 'file_1',
        sanitizedName: 'foundation_plan_v2.dwg',
        downloadUrl: '/api/files/file_1/download',
      ),
      evaluation: PortfolioEvaluation(
        result: 'APPROVED',
        overallPercentage: 92,
        criteria: [
          PortfolioCriterion(name: 'Dimensional Accuracy', score: 5, maxScore: 5),
          PortfolioCriterion(name: 'CAD Layering Standards', score: 4, maxScore: 5),
        ],
      ),
    ),
  ];

  final sampleCredentials = [
    StudentCredential(
      id: 'cred_1',
      type: 'COURSE_COMPLETION',
      title: 'Architectural Drafting Certification',
      description: 'Mastery of foundational drafting practices.',
      referenceId: 'ref_1',
      issuedAt: DateTime.utc(2026, 10, 4),
      certificateObjectKey: 'certificates/user_1/cred_1.pdf',
      verificationToken: 'validtoken123',
    ),
  ];

  final sampleAchievements = [
    StudentAchievement(
      id: 'first_drawing_approved',
      title: 'Precision Master',
      description: 'Had your first drawing evaluated and approved by Admin',
      category: 'PRACTICAL',
      icon: 'verified_outlined',
      isUnlocked: true,
      unlockedAt: DateTime.utc(2026, 10, 5),
      currentProgress: 1,
      targetProgress: 1,
    ),
    StudentAchievement(
      id: 'speed_drafter',
      title: 'Speed Drafter',
      description: 'Submitted 5 drawings without revision',
      category: 'SPEED',
      icon: 'military_tech_outlined',
      isUnlocked: false,
      unlockedAt: null,
      currentProgress: 1,
      targetProgress: 5,
    ),
  ];

  Widget createTestWidget({
    List<PortfolioProject>? projects,
    List<StudentCredential>? credentials,
    List<StudentAchievement>? achievements,
    FileRepository? fileRepository,
  }) {
    return ProviderScope(
      overrides: [
        studentPortfolioProvider.overrideWith((ref) => projects ?? sampleProjects),
        studentCredentialsProvider.overrideWith((ref) => credentials ?? sampleCredentials),
        studentAchievementsProvider.overrideWith((ref) => achievements ?? sampleAchievements),
        if (fileRepository != null)
          fileRepositoryProvider.overrideWithValue(fileRepository),
      ],
      child: const MaterialApp(
        home: StudentPortfolioScreen(),
      ),
    );
  }

  testWidgets('StudentPortfolioScreen renders evidence header and metric counters', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Student Portfolio'), findsOneWidget);
    expect(find.text('Curriculum & Practical Evidence'), findsOneWidget);
    expect(find.text('Approved Projects'), findsOneWidget);
    expect(find.text('Credentials'), findsOneWidget);
    expect(find.text('Milestones'), findsOneWidget);
    expect(find.text('Avg Evaluation'), findsOneWidget);
    expect(find.text('92%'), findsAtLeastNWidgets(1));
  });

  testWidgets('StudentPortfolioScreen renders practical deliverable card with score and download', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Modern Villa Foundation Plan'), findsOneWidget);
    expect(find.text('Structural / Foundation • 2500 sq ft'), findsOneWidget);
    expect(find.text('Training Project'), findsOneWidget);
    expect(find.text('Dimensional Accuracy'), findsOneWidget);
    expect(find.text('CAD Layering Standards'), findsOneWidget);
    expect(find.textContaining('Download Final Drawing'), findsOneWidget);
  });

  testWidgets('Download Final Drawing button triggers repository.downloadFile and shows AutoCAD Viewer warning for DWG', (tester) async {
    final fakeRepo = FakeFileRepository();
    await tester.pumpWidget(createTestWidget(fileRepository: fakeRepo));
    await tester.pumpAndSettle();

    // Verify DWG viewer message is NOT shown before download
    expect(find.text('DWG downloaded. AutoCAD Viewer is required to open it.'), findsNothing);
    expect(find.text('Download AutoCAD Viewer for Android'), findsNothing);

    final downloadButton = find.textContaining('Download Final Drawing');
    expect(downloadButton, findsOneWidget);

    await tester.ensureVisible(downloadButton);
    await tester.tap(downloadButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(fakeRepo.downloadedFileId, 'file_1');
    expect(fakeRepo.downloadedSavePath, contains('foundation_plan_v2.dwg'));

    // Verify DWG viewer message and action appear ONLY after successful download
    expect(find.text('DWG downloaded. AutoCAD Viewer is required to open it.'), findsOneWidget);
    expect(find.text('Download AutoCAD Viewer for Android'), findsOneWidget);

    // Tap the action to confirm handler triggers cleanly
    await tester.tap(find.text('Download AutoCAD Viewer for Android'));
    await tester.pump();
  });

  testWidgets('Download Final Drawing surfaces error snackbar on failure and does not show DWG warning', (tester) async {
    final fakeRepo = FakeFileRepository()..shouldThrow = true;
    await tester.pumpWidget(createTestWidget(fileRepository: fakeRepo));
    await tester.pumpAndSettle();

    final downloadButton = find.textContaining('Download Final Drawing');
    await tester.ensureVisible(downloadButton);
    await tester.tap(downloadButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Failed to download drawing: API Error: 400'), findsOneWidget);
    // Crucial: Must NOT show AutoCAD viewer warning on failure
    expect(find.text('DWG downloaded. AutoCAD Viewer is required to open it.'), findsNothing);
    expect(find.text('Download AutoCAD Viewer for Android'), findsNothing);
  });

  testWidgets('Non-DWG file download does not show AutoCAD Viewer warning', (tester) async {
    final fakeRepo = FakeFileRepository();
    final nonDwgProject = PortfolioProject(
      projectId: 'proj_non_dwg',
      projectName: 'Modern Villa Specifications',
      drawingType: 'Structural / Documentation',
      projectArea: '2500 sq ft',
      isTrainingProject: true,
      approvedAt: DateTime.utc(2026, 10, 5),
      finalDrawing: PortfolioFinalDrawing(
        fileId: 'file_pdf',
        sanitizedName: 'foundation_plan_v2.pdf',
        downloadUrl: '/api/files/file_pdf/download',
      ),
      evaluation: PortfolioEvaluation(
        result: 'APPROVED',
        overallPercentage: 92,
        criteria: [],
      ),
    );
    await tester.pumpWidget(createTestWidget(
      projects: [nonDwgProject],
      fileRepository: fakeRepo,
    ));
    await tester.pumpAndSettle();

    final downloadButton = find.textContaining('Download Final Drawing');
    await tester.ensureVisible(downloadButton);
    await tester.tap(downloadButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Downloaded to foundation_plan_v2.pdf'), findsOneWidget);
    expect(find.text('DWG downloaded. AutoCAD Viewer is required to open it.'), findsNothing);
  });

  testWidgets('StudentPortfolioScreen renders credentials and milestone cards', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Architectural Drafting Certification'), findsOneWidget);
    expect(find.text('Precision Master'), findsOneWidget);
    expect(find.text('Download PDF Certificate'), findsOneWidget);
    expect(find.text('View Online Verification'), findsOneWidget);
  });

  testWidgets('StudentPortfolioScreen filter tabs switch active sections', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Tap Practical Work filter chip
    await tester.tap(find.text('Practical Work (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Modern Villa Foundation Plan'), findsOneWidget);
    // Credentials and Milestones shouldn't be rendered in Practical Work filter
    expect(find.text('Architectural Drafting Certification'), findsNothing);
    expect(find.text('Precision Master'), findsNothing);

    // Tap Credentials filter chip
    await tester.tap(find.text('Credentials (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Architectural Drafting Certification'), findsOneWidget);
    expect(find.text('Modern Villa Foundation Plan'), findsNothing);
  });

  testWidgets('StudentPortfolioScreen handles empty state gracefully', (tester) async {
    await tester.pumpWidget(createTestWidget(
      projects: [],
      credentials: [],
      achievements: [],
    ));
    await tester.pumpAndSettle();

    expect(find.text('No Practical Deliverables Yet'), findsOneWidget);
    expect(find.text('No Formal Credentials Yet'), findsOneWidget);
    expect(find.text('No Milestones Unlocked Yet'), findsOneWidget);
  });

  testWidgets('StudentPortfolioScreen renders ADMIN Mentor Feedback when present', (tester) async {
    final projectsWithFeedback = [
      PortfolioProject(
        projectId: 'proj_fb',
        projectName: 'Commercial Tower HVAC Plan',
        drawingType: 'Mechanical / HVAC',
        projectArea: '5000 sq ft',
        isTrainingProject: true,
        approvedAt: DateTime.utc(2026, 10, 5),
        finalDrawing: PortfolioFinalDrawing(
          fileId: 'file_fb',
          sanitizedName: 'hvac_final.dwg',
          downloadUrl: '/api/files/file_fb/download',
        ),
        evaluation: PortfolioEvaluation(
          result: 'APPROVED',
          overallPercentage: 94,
          generalFeedback: 'Excellent line weight and dimensioning discipline. Ready for studio submission.',
          criteria: [
            PortfolioCriterion(name: 'Dimensional Accuracy', score: 5, maxScore: 5),
          ],
        ),
      ),
    ];

    await tester.pumpWidget(createTestWidget(projects: projectsWithFeedback));
    await tester.pumpAndSettle();

    expect(find.text('ADMIN MENTOR FEEDBACK'), findsOneWidget);
    expect(find.text('Excellent line weight and dimensioning discipline. Ready for studio submission.'), findsOneWidget);
  });
}
