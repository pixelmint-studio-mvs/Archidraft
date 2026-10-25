import 'package:archi_draft/src/features/projects/domain/drawing_type.dart';
import 'package:archi_draft/src/features/projects/domain/project_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProjectStatus', () {
    test('fromString parses correctly', () {
      expect(ProjectStatus.fromString('DRAFT'), ProjectStatus.draft);
      expect(ProjectStatus.fromString('SUBMITTED'), ProjectStatus.submitted);
      expect(ProjectStatus.fromString('CANCELLED'), ProjectStatus.cancelled);
      expect(ProjectStatus.fromString('UNKNOWN'), null);
      expect(ProjectStatus.fromString(null), null);
    });

    test('toFirestoreString outputs correctly', () {
      expect(ProjectStatus.draft.toFirestoreString(), 'DRAFT');
      expect(ProjectStatus.submitted.toFirestoreString(), 'SUBMITTED');
    });

    test('canonical and legacy review status mapping', () {
      expect(ProjectStatus.fromString('UNDER_ENGINEER_REVIEW'), ProjectStatus.underEngineerReview);
      expect(ProjectStatus.fromString('UNDER_CLIENT_REVIEW'), ProjectStatus.underEngineerReview);
      expect(ProjectStatus.underEngineerReview.toFirestoreString(), 'UNDER_ENGINEER_REVIEW');
      expect(ProjectStatus.underEngineerReview.displayName, 'Under Engineer Review');
    });

    test('isEditable logic', () {
      expect(ProjectStatus.draft.isEditable, true);
      expect(ProjectStatus.submitted.isEditable, false);
      expect(ProjectStatus.completed.isEditable, false);
    });
  });

  group('DrawingType', () {
    test('fromString parses correctly including canonical and alias values', () {
      expect(DrawingType.fromString('FLOOR_PLAN'), DrawingType.floorPlan);
      expect(DrawingType.fromString('Floor Plan'), DrawingType.floorPlan);
      expect(DrawingType.fromString('floorPlan'), DrawingType.floorPlan);
      expect(DrawingType.fromString('ELEVATION'), DrawingType.elevation);
      expect(DrawingType.fromString('Elevation'), DrawingType.elevation);
      expect(DrawingType.fromString('SECTION'), DrawingType.section);
      expect(DrawingType.fromString('SITE_PLAN'), DrawingType.sitePlan);
      expect(DrawingType.fromString('STRUCTURAL'), DrawingType.structural);
      expect(DrawingType.fromString('ELECTRICAL'), DrawingType.electrical);
      expect(DrawingType.fromString('PLUMBING'), DrawingType.plumbing);
      expect(DrawingType.fromString('ARCHITECTURAL'), DrawingType.architectural);
      expect(DrawingType.fromString('Architectural'), DrawingType.architectural);
      expect(DrawingType.fromString('architectural'), DrawingType.architectural);
      expect(DrawingType.fromString('ARCHITECTURAL_DRAFTING'), DrawingType.architectural);
      expect(DrawingType.fromString('Architectural Drafting'), DrawingType.architectural);
      expect(DrawingType.fromString('Architectural Plan'), DrawingType.architectural);
      expect(DrawingType.fromString('UNKNOWN'), null);
      expect(DrawingType.fromString(''), null);
      expect(DrawingType.fromString('   '), null);
      expect(DrawingType.fromString(null), null);
    });

    test('toFirestoreString outputs correctly', () {
      expect(DrawingType.architectural.toFirestoreString(), 'ARCHITECTURAL');
      expect(DrawingType.floorPlan.toFirestoreString(), 'FLOOR_PLAN');
      expect(DrawingType.elevation.toFirestoreString(), 'ELEVATION');
      expect(DrawingType.section.toFirestoreString(), 'SECTION');
      expect(DrawingType.sitePlan.toFirestoreString(), 'SITE_PLAN');
      expect(DrawingType.structural.toFirestoreString(), 'STRUCTURAL');
      expect(DrawingType.electrical.toFirestoreString(), 'ELECTRICAL');
      expect(DrawingType.plumbing.toFirestoreString(), 'PLUMBING');
    });

    test('displayName is human readable', () {
      expect(DrawingType.architectural.displayName, 'Architectural');
      expect(DrawingType.floorPlan.displayName, 'Floor Plan');
      expect(DrawingType.sitePlan.displayName, 'Site Plan');
    });

    test('every DrawingType item and firestore value is strictly unique (no duplicates)', () {
      final firestoreStrings = DrawingType.values.map((t) => t.toFirestoreString()).toList();
      final displayNames = DrawingType.values.map((t) => t.displayName).toList();

      expect(firestoreStrings.toSet().length, firestoreStrings.length,
          reason: 'Every DrawingType must have a unique toFirestoreString value');
      expect(displayNames.toSet().length, displayNames.length,
          reason: 'Every DrawingType must have a unique displayName');
    });

    test('Architectural appears exactly once in the supported DrawingType list', () {
      final architecturalMatches = DrawingType.values
          .where((t) => t == DrawingType.architectural || t.displayName == 'Architectural')
          .toList();
      expect(architecturalMatches.length, 1);

      final firestoreMatches = DrawingType.values
          .where((t) => t.toFirestoreString() == 'ARCHITECTURAL')
          .toList();
      expect(firestoreMatches.length, 1);
    });
  });
}
