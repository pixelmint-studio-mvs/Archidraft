import 'dart:convert';

enum EvaluationResult {
  approved,
  needsCorrection,
}

class Evaluation {
  final String id;
  final String projectId;
  final String drawingVersionId;
  final String evaluatorId;
  final EvaluationResult overallResult;
  final String? generalFeedback;
  final Map<String, dynamic>? criteria;
  final DateTime createdAt;

  const Evaluation({
    required this.id,
    required this.projectId,
    required this.drawingVersionId,
    required this.evaluatorId,
    required this.overallResult,
    this.generalFeedback,
    this.criteria,
    required this.createdAt,
  });

  factory Evaluation.fromMap(Map<String, dynamic> map) {
    EvaluationResult result;
    switch (map['overall_result']) {
      case 'APPROVED':
        result = EvaluationResult.approved;
        break;
      case 'NEEDS_CORRECTION':
        result = EvaluationResult.needsCorrection;
        break;
      default:
        throw Exception('Unknown evaluation result: ${map['overall_result']}');
    }

    Map<String, dynamic>? parsedCriteria;
    if (map['criteria_json'] != null) {
      if (map['criteria_json'] is String) {
        try {
          parsedCriteria = jsonDecode(map['criteria_json'] as String) as Map<String, dynamic>;
        } catch (_) {
          // Fallback if not valid JSON
        }
      } else if (map['criteria_json'] is Map) {
        parsedCriteria = Map<String, dynamic>.from(map['criteria_json'] as Map);
      }
    }

    return Evaluation(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      drawingVersionId: map['drawing_version_id'] as String,
      evaluatorId: map['evaluator_id'] as String,
      overallResult: result,
      generalFeedback: map['general_feedback'] as String?,
      criteria: parsedCriteria,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }
}
