enum CorrectionStatus {
  open('OPEN', 'Open', 'Correction requested by client'),
  inProgress('IN_PROGRESS', 'In Progress', 'Draughtsman is working on it'),
  resolved('RESOLVED', 'Resolved', 'Correction completed');

  final String value;
  final String label;
  final String description;

  const CorrectionStatus(this.value, this.label, this.description);

  factory CorrectionStatus.fromString(String value) {
    return CorrectionStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => CorrectionStatus.open,
    );
  }
}

class Correction {
  final String id;
  final String projectId;
  final String requestedBy;
  final String targetVersionId;
  final int roundNumber;
  final String description;
  final CorrectionStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const Correction({
    required this.id,
    required this.projectId,
    required this.requestedBy,
    required this.targetVersionId,
    required this.roundNumber,
    required this.description,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
  });

  factory Correction.fromJson(Map<String, dynamic> json) {
    return Correction(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      requestedBy: json['requested_by'] as String,
      targetVersionId: json['target_version_id'] as String,
      roundNumber: json['round_number'] as int,
      description: json['description'] as String,
      status: CorrectionStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
    );
  }
}
