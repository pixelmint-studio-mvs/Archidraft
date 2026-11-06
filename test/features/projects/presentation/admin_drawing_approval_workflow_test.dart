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
import 'package:archi_draft/src/features/projects/domain/drawing_version.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/domain/project_status.dart';
import 'package:archi_draft/src/features/projects/presentation/widgets/project_status_chip.dart';
import 'package:archi_draft/src/features/projects/providers/file_providers.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';

class _FakeApiClient extends Fake implements ApiClient {
  @override
  Future<Uint8List> downloadBinary(String path) async {
    return Uint8List.fromList(utf8.encode('0\nSECTION\n2\nENTITIES\n0\nENDSEC\n0\nEOF'));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const projectId = 'test-prj-approval-001';

  group('Admin Drawing Approval Workflow — Flutter Integration Contracts', () {
    test('ProjectStatus domain enum supports underAdminReview', () {
      expect(ProjectStatus.fromString('UNDER_ADMIN_REVIEW'), ProjectStatus.underAdminReview);
      expect(ProjectStatus.underAdminReview.toFirestoreString(), 'UNDER_ADMIN_REVIEW');
      expect(ProjectStatus.underAdminReview.displayName, 'Under Studio Review');
      expect(ProjectStatus.underAdminReview.isEditable, false);
      expect(ProjectStatus.underAdminReview.isTerminal, false);
    });

    test('DrawingVersion model parses approval metadata and helper flags', () {
      final json = {
        'id': 'dv-101',
        'project_id': projectId,
        'file_id': 'file-101',
        'version_number': 2,
        'uploaded_by': 'draughtsman-1',
        'approval_status': 'PENDING',
        'approval_source': 'ADMIN_REVIEW',
        'reviewed_by': 'admin-1',
        'reviewed_at': '2026-11-04T00:00:00Z',
        'review_feedback': 'Check dimension grid',
      };

      final dv = DrawingVersion.fromMap(json);
      expect(dv.approvalStatus, 'PENDING');
      expect(dv.approvalSource, 'ADMIN_REVIEW');
      expect(dv.isPending, true);
      expect(dv.isApproved, false);
      expect(dv.isRejected, false);
      expect(dv.reviewFeedback, 'Check dimension grid');

      final approvedDv = DrawingVersion.fromMap({...json, 'approval_status': 'APPROVED'});
      expect(approvedDv.isApproved, true);
      expect(approvedDv.isPending, false);

      final rejectedDv = DrawingVersion.fromMap({...json, 'approval_status': 'REJECTED'});
      expect(rejectedDv.isRejected, true);
      expect(rejectedDv.isPending, false);
    });

    testWidgets('ProjectStatusChip renders UNDER_ADMIN_REVIEW faithfully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectStatusChip(status: ProjectStatus.underAdminReview),
          ),
        ),
      );

      expect(find.text('UNDER_ADMIN_REVIEW'), findsOneWidget);
    });

    testWidgets('Engineer Screen: Hides pending/rejected versions and displays QC review placeholder', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final project = Project(
        projectId: projectId,
        projectName: 'Villa Azure',
        projectAddress: '123 Palm Way',
        drawingName: 'GROUND FLOOR PLAN',
        drawingType: 'FLOOR_PLAN',
        clientId: 'eng-01',
        assignedDraughtsmanId: 'draught-01',
        status: 'UNDER_ADMIN_REVIEW',
        correctionRound: 0,
      );

      // Pending version submitted by Draughtsman
      final pendingVersion = DrawingVersion(
        id: 'dv-pending',
        projectId: projectId,
        fileId: 'file-pending',
        versionNumber: 1,
        uploadedBy: 'draught-01',
        approvalStatus: 'PENDING',
        originalName: 'ground_floor_v1.dwg',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserRoleProvider.overrideWithValue(UserRole.engineer),
            projectProvider(projectId).overrideWith((ref) => project),
            projectDrawingVersionsProvider(projectId).overrideWith((ref) => [pendingVersion]),
            projectCorrectionsProvider(projectId).overrideWith((ref) => []),
            projectFilesProvider(projectId).overrideWith((ref) => []),
            projectActivityLogsProvider(projectId).overrideWith((ref) => []),
            apiClientProvider.overrideWithValue(_FakeApiClient()),
          ],
          child: const MaterialApp(
            home: ProjectDetailScreen(projectId: projectId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Engineer must NOT see the unapproved drawing version
      expect(find.text('Version 1 (Latest)'), findsNothing);
      expect(find.text('Draughtsman deliverable is undergoing Studio QC review. Approved drawings will appear here.'), findsOneWidget);

      // Engineer must NOT see "Request Revision" or "Approve Final" action buttons while under admin review
      expect(find.text('Request Revision'), findsNothing);
      expect(find.text('Approve Final'), findsNothing);
    });

    testWidgets('Engineer Screen: Reveals approved version once Studio Admin approves', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final project = Project(
        projectId: projectId,
        projectName: 'Villa Azure',
        projectAddress: '123 Palm Way',
        drawingName: 'GROUND FLOOR PLAN',
        drawingType: 'FLOOR_PLAN',
        clientId: 'eng-01',
        assignedDraughtsmanId: 'draught-01',
        status: 'UNDER_ENGINEER_REVIEW',
        correctionRound: 0,
      );

      final approvedVersion = DrawingVersion(
        id: 'dv-approved',
        projectId: projectId,
        fileId: 'file-approved',
        versionNumber: 1,
        uploadedBy: 'draught-01',
        approvalStatus: 'APPROVED',
        originalName: 'ground_floor_v1.dxf',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserRoleProvider.overrideWithValue(UserRole.engineer),
            projectProvider(projectId).overrideWith((ref) => project),
            projectDrawingVersionsProvider(projectId).overrideWith((ref) => [approvedVersion]),
            projectCorrectionsProvider(projectId).overrideWith((ref) => []),
            projectFilesProvider(projectId).overrideWith((ref) => []),
            projectActivityLogsProvider(projectId).overrideWith((ref) => []),
            apiClientProvider.overrideWithValue(_FakeApiClient()),
          ],
          child: const MaterialApp(
            home: ProjectDetailScreen(projectId: projectId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Engineer now sees the approved drawing version and action controls
      expect(find.text('Drawing Versions'), findsOneWidget);
      expect(find.textContaining('Request Revision'), findsOneWidget);
      expect(find.text('Approve Final'), findsOneWidget);
    });

    testWidgets('Engineer Screen: Strictly fails closed when version approvalStatus is null or REJECTED', (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final project = Project(
        projectId: projectId,
        projectName: 'Villa Azure',
        projectAddress: '123 Palm Way',
        drawingName: 'GROUND FLOOR PLAN',
        drawingType: 'FLOOR_PLAN',
        clientId: 'eng-01',
        assignedDraughtsmanId: 'draught-01',
        status: 'IN_PROGRESS',
        correctionRound: 0,
      );

      final unannotatedVersion = DrawingVersion(
        id: 'dv-null-status',
        projectId: projectId,
        fileId: 'file-unannotated',
        versionNumber: 1,
        uploadedBy: 'draught-01',
        approvalStatus: null, // Legacy unannotated or missing approval
        originalName: 'ground_floor_v1.dxf',
      );

      final rejectedVersion = DrawingVersion(
        id: 'dv-rejected',
        projectId: projectId,
        fileId: 'file-rejected',
        versionNumber: 2,
        uploadedBy: 'draught-01',
        approvalStatus: 'REJECTED',
        originalName: 'ground_floor_v2.dxf',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserRoleProvider.overrideWithValue(UserRole.engineer),
            projectProvider(projectId).overrideWith((ref) => project),
            projectDrawingVersionsProvider(projectId).overrideWith((ref) => [rejectedVersion, unannotatedVersion]),
            projectCorrectionsProvider(projectId).overrideWith((ref) => []),
            projectFilesProvider(projectId).overrideWith((ref) => []),
            projectActivityLogsProvider(projectId).overrideWith((ref) => []),
            apiClientProvider.overrideWithValue(_FakeApiClient()),
          ],
          child: const MaterialApp(
            home: ProjectDetailScreen(projectId: projectId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both null and REJECTED versions must be blocked from Engineer view
      expect(find.text('Version 1 (Latest)'), findsNothing);
      expect(find.text('Version 2 (Latest)'), findsNothing);
      expect(find.text('Drawings will appear here once submitted by the draughtsman.'), findsOneWidget);
    });
  });
}
