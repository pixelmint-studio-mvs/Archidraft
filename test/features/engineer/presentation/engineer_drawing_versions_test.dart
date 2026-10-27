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
import 'package:archi_draft/src/features/projects/presentation/widgets/cad_drawing_viewer.dart';
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

  const projectId = '5b31d807-8295-4859-9941-ee47b9352e5c';

  final testProjectInProgress = Project(
    projectId: projectId,
    projectName: 'MVS-1',
    projectAddress: 'MVS Location',
    drawingName: 'SECOND FLOOR',
    drawingType: 'FLOOR_PLAN',
    projectArea: 2000.0,
    clientId: 'eng-01',
    assignedDraughtsmanId: 'draught-01',
    status: 'IN_PROGRESS',
    correctionRound: 1,
    createdAt: DateTime(2026, 10, 26, 14, 46),
    submittedAt: DateTime(2026, 10, 26, 14, 46),
  );

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
  final dxfBytes = Uint8List.fromList(utf8.encode(sampleDxf));

  Widget createTestWidget({
    required Project project,
    required List<DrawingVersion> versions,
    List<Correction> corrections = const [],
    List<ProjectFile> files = const [],
    List<ActivityLog> activities = const [],
  }) {
    final fakeClient = FakeEngineerApiClient({
      '/api/files/dxf-v1-file-id/download': dxfBytes,
      '/api/files/dxf-v2-file-id/download': dxfBytes,
    });

    return ProviderScope(
      overrides: [
        currentUserRoleProvider.overrideWithValue(UserRole.engineer),
        projectProvider(projectId).overrideWith((ref) => project),
        projectDrawingVersionsProvider(projectId).overrideWith((ref) => versions),
        projectCorrectionsProvider(projectId).overrideWith((ref) => corrections),
        projectFilesProvider(projectId).overrideWith((ref) => files),
        projectActivityLogsProvider(projectId).overrideWith((ref) => activities),
        apiClientProvider.overrideWithValue(fakeClient),
      ],
      child: const MaterialApp(
        home: ProjectDetailScreen(projectId: projectId),
      ),
    );
  }

  group('Engineer Project Details — Drawing Versions & Embedded CAD Viewer', () {
    testWidgets('Displays empty state message when no drawings have been submitted', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestWidget(
          project: testProjectInProgress,
          versions: const [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Drawing Versions'), findsOneWidget);
      expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
      expect(
        find.text('Drawings will appear here once submitted by the draughtsman.'),
        findsOneWidget,
      );
    });

    testWidgets('Renders real drawing version with metadata, revision notes, and embedded CAD viewer in IN_PROGRESS status', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final versions = [
        DrawingVersion(
          id: 'v1-record-id',
          projectId: projectId,
          fileId: 'dxf-v1-file-id',
          versionNumber: 1,
          uploadedBy: 'draught-01',
          uploaderName: 'Staging Draughtsman Primary',
          originalName: '01_test_drawing_v1.dxf',
          size: 1528,
          createdAt: DateTime(2026, 10, 26, 14, 51),
        ),
      ];

      final corrections = [
        Correction(
          id: 'corr-01',
          projectId: projectId,
          requestedBy: 'eng-01',
          targetVersionId: 'v1-record-id',
          roundNumber: 1,
          description: 'Adjust column spacing on grid line B.',
          status: CorrectionStatus.inProgress,
          createdAt: DateTime(2026, 10, 26, 14, 53),
        ),
      ];

      await tester.pumpWidget(
        createTestWidget(
          project: testProjectInProgress,
          versions: versions,
          corrections: corrections,
        ),
      );
      await tester.pumpAndSettle();

      // Verified Drawing Versions title & toolbar
      expect(find.text('Drawing Versions'), findsOneWidget);
      expect(find.text('Version 1 (Latest)'), findsOneWidget);
      expect(find.text('Download Original'), findsOneWidget);

      // Verified metadata strip
      expect(find.text('Staging Draughtsman Primary'), findsOneWidget);
      expect(find.text('In Revision'), findsOneWidget);
      expect(find.textContaining('DXF • 1.5 KB'), findsOneWidget);

      // Verified revision notes
      expect(find.textContaining('Round 1 Revision Notes: Adjust column spacing on grid line B.'), findsOneWidget);

      // Verified embedded CAD Drawing Viewer is mounted and renders DXF
      expect(find.byType(CadDrawingViewer), findsOneWidget);
      expect(find.text('AutoCAD DXF • 2D Vector CAD'), findsOneWidget);
    });

    testWidgets('Supports multi-version switching and previous version inspection', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final versions = [
        DrawingVersion(
          id: 'v2-record-id',
          projectId: projectId,
          fileId: 'dxf-v2-file-id',
          versionNumber: 2,
          uploadedBy: 'draught-01',
          uploaderName: 'Staging Draughtsman Primary',
          originalName: '02_test_drawing_v2.dxf',
          size: 2048,
          createdAt: DateTime(2026, 10, 26, 16, 00),
        ),
        DrawingVersion(
          id: 'v1-record-id',
          projectId: projectId,
          fileId: 'dxf-v1-file-id',
          versionNumber: 1,
          uploadedBy: 'draught-01',
          uploaderName: 'Staging Draughtsman Primary',
          originalName: '01_test_drawing_v1.dxf',
          size: 1528,
          createdAt: DateTime(2026, 10, 26, 14, 51),
        ),
      ];

      await tester.pumpWidget(
        createTestWidget(
          project: testProjectInProgress,
          versions: versions,
        ),
      );
      await tester.pumpAndSettle();

      // Default active version is Latest (Version 2)
      expect(find.text('Version 2 (Latest)'), findsWidgets);
      expect(find.text('All Revisions'), findsOneWidget);

      // Previous version (Version 1) is listed
      expect(find.text('Version 1'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);

      // Switch to previous Version 1 by tapping 'View'
      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();

      // Now active version in toolbar is Version 1
      expect(find.text('Version 1'), findsWidgets);
      expect(find.text('Previous Version'), findsOneWidget);
    });
  });
}
