class PrivacyRequest {
  final String id;
  final String userId;
  final String requestType;
  final String details;
  final String status;
  final String statutoryBasis;
  final String? statutoryDeadline;
  final String operationalTargetDate;
  final String? resolutionNotes;
  final String createdAt;
  final String? acknowledgedAt;
  final String? resolvedAt;

  const PrivacyRequest({
    required this.id,
    required this.userId,
    required this.requestType,
    required this.details,
    this.status = 'PENDING',
    required this.statutoryBasis,
    this.statutoryDeadline,
    required this.operationalTargetDate,
    this.resolutionNotes,
    required this.createdAt,
    this.acknowledgedAt,
    this.resolvedAt,
  });

  factory PrivacyRequest.fromJson(Map<String, dynamic> json) {
    return PrivacyRequest(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      requestType: json['request_type'] as String? ?? '',
      details: json['details'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      statutoryBasis: json['statutory_basis'] as String? ?? '',
      statutoryDeadline: json['statutory_deadline'] as String?,
      operationalTargetDate: json['operational_target_date'] as String? ?? '',
      resolutionNotes: json['resolution_notes'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      acknowledgedAt: json['acknowledged_at'] as String?,
      resolvedAt: json['resolved_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'request_type': requestType,
      'details': details,
      'status': status,
      'statutory_basis': statutoryBasis,
      'statutory_deadline': statutoryDeadline,
      'operational_target_date': operationalTargetDate,
      'resolution_notes': resolutionNotes,
      'created_at': createdAt,
      'acknowledged_at': acknowledgedAt,
      'resolved_at': resolvedAt,
    };
  }
}
