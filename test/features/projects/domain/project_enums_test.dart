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

    test('isEditable logic', () {
      expect(ProjectStatus.draft.isEditable, true);
      expect(ProjectStatus.submitted.isEditable, false);
      expect(ProjectStatus.completed.isEditable, false);
    });
  });

  group('DrawingType', () {
    test('fromString parses correctly', () {
      expect(DrawingType.fromString('FLOOR_PLAN'), DrawingType.floorPlan);
      expect(DrawingType.fromString('ELEVATION'), DrawingType.elevation);
      expect(DrawingType.fromString('UNKNOWN'), null);
      expect(DrawingType.fromString(null), null);
    });

    test('toFirestoreString outputs correctly', () {
      expect(DrawingType.floorPlan.toFirestoreString(), 'FLOOR_PLAN');
      expect(DrawingType.elevation.toFirestoreString(), 'ELEVATION');
    });

    test('displayName is human readable', () {
      expect(DrawingType.floorPlan.displayName, 'Floor Plan');
      expect(DrawingType.sitePlan.displayName, 'Site Plan');
    });
  });
}
