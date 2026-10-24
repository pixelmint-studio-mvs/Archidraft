import 'dart:convert';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:archi_draft/src/features/projects/domain/evaluation.dart';

void main() {
  group('Evaluation Domain Model Tests', () {
    test('Correctly deserializes APPROVED evaluation with map criteria', () {
      final map = {
        'id': 'eval_01',
        'project_id': 'proj_01',
        'drawing_version_id': 'ver_01',
        'evaluator_id': 'admin_01',
        'overall_result': 'APPROVED',
        'general_feedback': 'Masterful drafting execution.',
        'criteria_json': {'Accuracy': 5, 'Technical Standards': 5},
        'created_at': '2026-10-24T10:00:00Z',
      };

      final eval = Evaluation.fromMap(map);
      expect(eval.id, 'eval_01');
      expect(eval.overallResult, EvaluationResult.approved);
      expect(eval.generalFeedback, 'Masterful drafting execution.');
      expect(eval.criteria?['Accuracy'], 5);
      expect(eval.criteria?['Technical Standards'], 5);
    });

    test('Correctly deserializes NEEDS_CORRECTION evaluation with string JSON criteria', () {
      final map = {
        'id': 'eval_02',
        'project_id': 'proj_01',
        'drawing_version_id': 'ver_01',
        'evaluator_id': 'admin_01',
        'overall_result': 'NEEDS_CORRECTION',
        'general_feedback': 'Wall thickness needs update to 230mm.',
        'criteria_json': jsonEncode({'Accuracy': 3, 'Technical Standards': 3}),
        'created_at': '2026-10-24T10:00:00Z',
      };

      final eval = Evaluation.fromMap(map);
      expect(eval.id, 'eval_02');
      expect(eval.overallResult, EvaluationResult.needsCorrection);
      expect(eval.criteria?['Accuracy'], 3);
      expect(eval.criteria?['Technical Standards'], 3);
    });

    test('Correctly deserializes REJECTED evaluation', () {
      final map = {
        'id': 'eval_03',
        'project_id': 'proj_01',
        'drawing_version_id': 'ver_01',
        'evaluator_id': 'admin_01',
        'overall_result': 'REJECTED',
        'general_feedback': 'Non-compliant submission violating core standards.',
        'criteria_json': jsonEncode({'Accuracy': 1, 'Technical Standards': 1}),
        'created_at': '2026-10-24T10:00:00Z',
      };

      final eval = Evaluation.fromMap(map);
      expect(eval.id, 'eval_03');
      expect(eval.overallResult, EvaluationResult.rejected);
      expect(eval.generalFeedback, 'Non-compliant submission violating core standards.');
    });

    test('Throws on unknown overall result string', () {
      final map = {
        'id': 'eval_04',
        'project_id': 'proj_01',
        'drawing_version_id': 'ver_01',
        'evaluator_id': 'admin_01',
        'overall_result': 'UNKNOWN_STATE',
        'created_at': '2026-10-24T10:00:00Z',
      };

      expect(() => Evaluation.fromMap(map), throwsA(isA<Exception>()));
    });
  });
}
