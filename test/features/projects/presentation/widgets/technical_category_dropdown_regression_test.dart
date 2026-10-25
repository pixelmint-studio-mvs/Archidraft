import 'package:archi_draft/src/features/engineer/presentation/project_form_screen.dart';
import 'package:archi_draft/src/features/engineer/presentation/widgets/reference_files_upload_section.dart';
import 'package:archi_draft/src/features/profile/domain/user_role.dart';
import 'package:archi_draft/src/features/profile/providers/profile_providers.dart';
import 'package:archi_draft/src/features/projects/domain/drawing_type.dart';
import 'package:archi_draft/src/features/projects/domain/project.dart';
import 'package:archi_draft/src/features/projects/domain/project_file.dart';
import 'package:archi_draft/src/features/projects/providers/file_providers.dart';
import 'package:archi_draft/src/features/projects/providers/project_form_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Technical Category Dropdown - Domain & Integrity Checks', () {
    test('The technical category list contains no duplicate values', () {
      final firestoreValues = DrawingType.values.map((t) => t.toFirestoreString()).toList();
      final displayNames = DrawingType.values.map((t) => t.displayName).toList();

      expect(
        firestoreValues.toSet().length,
        equals(firestoreValues.length),
        reason: 'Duplicate firestore values found in DrawingType.values: $firestoreValues',
      );

      expect(
        displayNames.toSet().length,
        equals(displayNames.length),
        reason: 'Duplicate display names found in DrawingType.values: $displayNames',
      );
    });

    test('Architectural appears exactly once when it is a supported category', () {
      final matchingEnums = DrawingType.values.where((t) => t == DrawingType.architectural).toList();
      final matchingDisplays = DrawingType.values.where((t) => t.displayName == 'Architectural').toList();
      final matchingFirestore = DrawingType.values.where((t) => t.toFirestoreString() == 'ARCHITECTURAL').toList();

      expect(matchingEnums.length, equals(1), reason: 'DrawingType.architectural must appear exactly once');
      expect(matchingDisplays.length, equals(1), reason: "'Architectural' display name must appear exactly once");
      expect(matchingFirestore.length, equals(1), reason: "'ARCHITECTURAL' firestore string must appear exactly once");
    });
  });

  group('Technical Category Dropdown - Widget Assertion Safety & Draft Restoration', () {
    void setLargeSurface(WidgetTester tester) {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    Widget buildTestHarness({
      required ProviderContainer container,
      String? projectId,
    }) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: ProjectFormScreen(projectId: projectId),
        ),
      );
    }

    testWidgets('The project creation screen renders without a dropdown assertion (new project flow)', (tester) async {
      setLargeSurface(tester);

      final container = ProviderContainer(
        overrides: [
          currentUserRoleProvider.overrideWithValue(UserRole.client),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestHarness(container: container));
      await tester.pumpAndSettle();

      // Ensure no red error screen / assertion error occurred
      expect(tester.takeException(), isNull);

      // Verify screen title and dropdown presence
      expect(find.text('Initiate Project'), findsOneWidget);
      expect(find.text('PROJECT_TITLE'), findsOneWidget);
      expect(find.text('TECHNICAL_CATEGORY'), findsOneWidget);
      expect(find.text('Select category'), findsOneWidget);

      // Verify reference file upload section is present
      expect(find.byType(ReferenceFilesUploadSection), findsOneWidget);
      expect(find.text('REFERENCE_FILES (CAD / PDF / DOCS)'), findsOneWidget);
      expect(find.text('Max 50 MiB / file'), findsOneWidget);
    });

    testWidgets('Existing drafts with Architectural load correctly without dropdown assertion', (tester) async {
      setLargeSurface(tester);

      const draftId = 'draft-arch-1';
      final container = ProviderContainer(
        overrides: [
          currentUserRoleProvider.overrideWithValue(UserRole.client),
          projectFilesProvider(draftId).overrideWith((ref) => Future.value(<ProjectFile>[])),
        ],
      );
      addTearDown(container.dispose);

      const draftWithArchitectural = Project(
        projectId: draftId,
        projectName: 'Residential Modern Villa',
        projectAddress: '101 Palm Boulevard',
        drawingName: 'Ground Floor Blueprint',
        drawingType: 'Architectural',
        clientId: 'eng-client-1',
        status: 'DRAFT',
      );

      // Pre-load draft into controller
      container.read(projectFormControllerProvider.notifier).loadDraft(draftWithArchitectural);

      await tester.pumpWidget(buildTestHarness(container: container));
      await tester.pumpAndSettle();

      // Critical: verify no assertion was thrown
      expect(tester.takeException(), isNull);

      // Dropdown should be populated with 'Architectural'
      expect(find.text('Architectural'), findsWidgets);
      expect(container.read(projectFormControllerProvider).drawingType, equals('ARCHITECTURAL'));
    });

    testWidgets('Existing drafts with canonical ARCHITECTURAL load correctly without dropdown assertion', (tester) async {
      setLargeSurface(tester);

      const draftId = 'draft-arch-2';
      final container = ProviderContainer(
        overrides: [
          currentUserRoleProvider.overrideWithValue(UserRole.client),
          projectFilesProvider(draftId).overrideWith((ref) => Future.value(<ProjectFile>[])),
        ],
      );
      addTearDown(container.dispose);

      const draftWithCanonical = Project(
        projectId: draftId,
        projectName: 'Commercial Tower A',
        projectAddress: '500 Tech Park Way',
        drawingName: 'Tower Floor Layout',
        drawingType: 'ARCHITECTURAL',
        clientId: 'eng-client-1',
        status: 'DRAFT',
      );

      container.read(projectFormControllerProvider.notifier).loadDraft(draftWithCanonical);

      await tester.pumpWidget(buildTestHarness(container: container));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Architectural'), findsWidgets);
      expect(container.read(projectFormControllerProvider).drawingType, equals('ARCHITECTURAL'));
    });

    testWidgets('Missing, invalid, or legacy category values do not crash the screen', (tester) async {
      setLargeSurface(tester);

      const draftId = 'draft-legacy-corrupted';
      final container = ProviderContainer(
        overrides: [
          currentUserRoleProvider.overrideWithValue(UserRole.client),
          projectFilesProvider(draftId).overrideWith((ref) => Future.value(<ProjectFile>[])),
        ],
      );
      addTearDown(container.dispose);

      const draftWithCorruptCategory = Project(
        projectId: draftId,
        projectName: 'Historic Restorations',
        projectAddress: 'Old Quarters No. 7',
        drawingName: 'Façade Detailing',
        drawingType: 'UNKNOWN_LEGACY_CATEGORY_XYZ',
        clientId: 'eng-client-1',
        status: 'DRAFT',
      );

      container.read(projectFormControllerProvider.notifier).loadDraft(draftWithCorruptCategory);

      await tester.pumpWidget(buildTestHarness(container: container));
      await tester.pumpAndSettle();

      // MUST NOT crash with assertion error
      expect(tester.takeException(), isNull);

      // The unmapped category gracefully falls back to prompt selection
      expect(find.text('Select category'), findsOneWidget);
    });

    testWidgets('The user can select a category and update form state', (tester) async {
      setLargeSurface(tester);

      final container = ProviderContainer(
        overrides: [
          currentUserRoleProvider.overrideWithValue(UserRole.client),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestHarness(container: container));
      await tester.pumpAndSettle();

      expect(container.read(projectFormControllerProvider).drawingType, isEmpty);

      // Tap the dropdown to open selection items
      final dropdownFinder = find.byType(DropdownButtonFormField<String>);
      expect(dropdownFinder, findsOneWidget);

      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Tap the 'Architectural' option in the open menu
      final architecturalItem = find.text('Architectural').last;
      await tester.tap(architecturalItem);
      await tester.pumpAndSettle();

      // Verify controller state updated to normalized canonical value
      expect(container.read(projectFormControllerProvider).drawingType, equals('ARCHITECTURAL'));
    });

    testWidgets('The reference-file upload section still renders and behaves correctly', (tester) async {
      setLargeSurface(tester);

      final container = ProviderContainer(
        overrides: [
          currentUserRoleProvider.overrideWithValue(UserRole.client),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestHarness(container: container));
      await tester.pumpAndSettle();

      // Check upload section features
      expect(find.byType(ReferenceFilesUploadSection), findsOneWidget);
      expect(find.text('REFERENCE_FILES (CAD / PDF / DOCS)'), findsOneWidget);
      expect(find.text('Max 50 MiB / file'), findsOneWidget);
      expect(find.text('Click to Select Reference Files'), findsOneWidget);
      expect(find.textContaining('.dwg, .dxf, .ifc'), findsOneWidget);
    });
  });
}
