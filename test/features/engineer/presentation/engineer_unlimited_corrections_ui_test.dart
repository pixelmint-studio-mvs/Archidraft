import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archi_draft/src/features/api/data/api_client.dart';
import 'package:archi_draft/src/features/api/providers/api_providers.dart';
import 'package:archi_draft/src/features/engineer/presentation/project_detail_screen.dart';
import 'package:archi_draft/src/features/profile/domain/user_role.dart';
import 'package:archi_draft/src/features/profile/providers/profile_providers.dart';
import 'package:archi_draft/src/features/projects/domain/activity_log.dart';
import 'package:archi_draft/src/features/projects/domain/correction.dart';
import 'package:archi_draft/src/features/projects/domain/drawing_version.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/domain/project_file.dart';
import 'package:archi_draft/src/features/projects/providers/file_providers.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';

class FakeEngineerApiClient extends Fake implements ApiClient {
  final Map<String, Uint8List> mockResponses;
  FakeEngineerApiClient(this.mockResponses);

  @override
  Future<Uint8List> downloadBinary(String path) async {
    if (mockResponses.containsKey(path)) {
      return mockResponses[path]!;
    }
    throw Exception('404 Not Found: $path');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const projectId = 'prj-unlimited-test';

  const sampleDxf = '''0
SECTION
2
ENTITIES
0
LINE
10
0.0
20
0.0
11
100.0
21
100.0
0
ENDSEC
0
EOF''';

  final fakeClient = FakeEngineerApiClient({
    '/api/projects/$projectId/files/file-v1/download': Uint8List.fromList(utf8.encode(sampleDxf)),
  });

  Widget createTestWidget({
    required Project project,
    required List<DrawingVersion> versions,
    required List<Correction> corrections,
  }) {
    return ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(fakeClient),
        currentUserRoleProvider.overrideWithValue(UserRole.engineer),
        projectProvider(projectId).overrideWith((ref) => Future.value(project)),
        projectDrawingVersionsProvider(projectId).overrideWith((ref) => Future.value(versions)),
        projectCorrectionsProvider(projectId).overrideWith((ref) => Future.value(corrections)),
        projectFilesProvider(projectId).overrideWith((ref) => Future.value(<ProjectFile>[])),
        projectActivityLogsProvider(projectId).overrideWith((ref) => Future.value(<ActivityLog>[])),
      ],
      child: const MaterialApp(
        home: ProjectDetailScreen(projectId: projectId),
      ),
    );
  }

  group('Engineer Portal Unlimited Correction Rounds UI Verification', () {
    testWidgets('Round 1: Displays exact unlimited labels and NO "OF 3" or "REMAINING"', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projectRound1 = Project(
        projectId: projectId,
        projectName: 'Skyline Commercial',
        projectAddress: '100 Main St',
        drawingName: 'GROUND FLOOR',
        drawingType: 'FLOOR_PLAN',
        projectArea: 3000.0,
        clientId: 'eng-01',
        assignedDraughtsmanId: 'drg-01',
        status: 'IN_PROGRESS',
        correctionRound: 1,
        createdAt: DateTime(2026, 11, 1),
      );

      final version1 = DrawingVersion(
        id: 'ver-1',
        projectId: projectId,
        fileId: 'file-v1',
        versionNumber: 1,
        uploadedBy: 'drg-01',
        uploaderName: 'Bob Draughtsman',
        approvalStatus: 'APPROVED',
        originalName: 'ground_floor_v1.dxf',
        sanitizedName: 'ground_floor_v1.dxf',
        size: 1024,
        createdAt: DateTime(2026, 11, 2),
      );

      final correction1 = Correction(
        id: 'corr-1',
        projectId: projectId,
        requestedBy: 'eng-01',
        targetVersionId: 'ver-1',
        roundNumber: 1,
        description: 'Expand column offsets along axis A.',
        status: CorrectionStatus.open,
        createdAt: DateTime(2026, 11, 3),
      );

      await tester.pumpWidget(
        createTestWidget(
          project: projectRound1,
          versions: [version1],
          corrections: [correction1],
        ),
      );
      await tester.pumpAndSettle();

      // 1. Header status badge
      expect(find.text('STATUS: CORRECTION ROUND 1'), findsOneWidget);
      expect(find.text('STATUS: CORRECTION 1 OF 3'), findsNothing);

      // 2. Correction stage card header
      expect(find.text('CORRECTION ROUND 1 REQUESTED'), findsOneWidget);
      expect(find.text('CORRECTION 1 OF 3 REQUESTED'), findsNothing);

      // 3. Correction stage card badge
      expect(find.text('ROUND 1 IN PROGRESS'), findsOneWidget);
      expect(find.text('2 ROUNDS REMAINING'), findsNothing);
      expect(find.textContaining('ROUNDS REMAINING'), findsNothing);

      // 4. Drawing version metadata
      expect(find.text('Correction Round 1'), findsOneWidget);
      expect(find.text('Correction 1 of 3'), findsNothing);

      // 5. Verify no occurrences of "of 3" anywhere
      expect(find.textContaining('of 3'), findsNothing);
      expect(find.textContaining('OF 3'), findsNothing);
      expect(find.textContaining('/3'), findsNothing);
    });

    testWidgets('Round 4 (Beyond 3): Displays exact unlimited labels without restriction', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projectRound4 = Project(
        projectId: projectId,
        projectName: 'Skyline Commercial',
        projectAddress: '100 Main St',
        drawingName: 'GROUND FLOOR',
        drawingType: 'FLOOR_PLAN',
        projectArea: 3000.0,
        clientId: 'eng-01',
        assignedDraughtsmanId: 'drg-01',
        status: 'IN_PROGRESS',
        correctionRound: 4,
        createdAt: DateTime(2026, 11, 1),
      );

      final version4 = DrawingVersion(
        id: 'ver-4',
        projectId: projectId,
        fileId: 'file-v1',
        versionNumber: 4,
        uploadedBy: 'drg-01',
        uploaderName: 'Bob Draughtsman',
        approvalStatus: 'APPROVED',
        originalName: 'ground_floor_v4.dxf',
        sanitizedName: 'ground_floor_v4.dxf',
        size: 1024,
        createdAt: DateTime(2026, 11, 4),
      );

      final correction4 = Correction(
        id: 'corr-4',
        projectId: projectId,
        requestedBy: 'eng-01',
        targetVersionId: 'ver-4',
        roundNumber: 4,
        description: 'Refine staircase riser dimensions.',
        status: CorrectionStatus.open,
        createdAt: DateTime(2026, 11, 5),
      );

      await tester.pumpWidget(
        createTestWidget(
          project: projectRound4,
          versions: [version4],
          corrections: [correction4],
        ),
      );
      await tester.pumpAndSettle();

      // 1. Header status badge
      expect(find.text('STATUS: CORRECTION ROUND 4'), findsOneWidget);

      // 2. Correction stage card header
      expect(find.text('CORRECTION ROUND 4 REQUESTED'), findsOneWidget);

      // 3. Correction stage card badge
      expect(find.text('ROUND 4 IN PROGRESS'), findsOneWidget);

      // 4. Drawing version metadata
      expect(find.text('Correction Round 4'), findsOneWidget);

      // 5. Zero occurrences of limits
      expect(find.textContaining('of 3'), findsNothing);
      expect(find.textContaining('OF 3'), findsNothing);
      expect(find.textContaining('REMAINING'), findsNothing);
    });

    testWidgets('Round 12 (Large round count): Correctly formats and allows requesting round 13', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final projectRound12 = Project(
        projectId: projectId,
        projectName: 'Skyline Commercial',
        projectAddress: '100 Main St',
        drawingName: 'GROUND FLOOR',
        drawingType: 'FLOOR_PLAN',
        projectArea: 3000.0,
        clientId: 'eng-01',
        assignedDraughtsmanId: 'drg-01',
        status: 'UNDER_ENGINEER_REVIEW',
        correctionRound: 12,
        createdAt: DateTime(2026, 11, 1),
      );

      final version12 = DrawingVersion(
        id: 'ver-12',
        projectId: projectId,
        fileId: 'file-v1',
        versionNumber: 12,
        uploadedBy: 'drg-01',
        uploaderName: 'Bob Draughtsman',
        approvalStatus: 'APPROVED',
        originalName: 'ground_floor_v12.dxf',
        sanitizedName: 'ground_floor_v12.dxf',
        size: 1024,
        createdAt: DateTime(2026, 11, 5),
      );

      await tester.pumpWidget(
        createTestWidget(
          project: projectRound12,
          versions: [version12],
          corrections: [],
        ),
      );
      await tester.pumpAndSettle();

      // In UNDER_ENGINEER_REVIEW:
      expect(find.text('STATUS: WAITING FOR YOUR REVIEW'), findsOneWidget);

      // Request Correction button displays dynamic next round: (Round 13)
      expect(find.text('Request Correction (Round 13)'), findsOneWidget);

      // Zero limits or remaining badges
      expect(find.textContaining('of 3'), findsNothing);
      expect(find.textContaining('OF 3'), findsNothing);
    });
  });
}
