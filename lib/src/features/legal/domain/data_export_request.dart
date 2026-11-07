class DataExportRequest {
  final String id;
  final String userId;
  final String verificationStatus;
  final String exportScope;
  final String status;
  final String? downloadR2Key;
  final String? downloadUrlExpiresAt;
  final String requestedAt;
  final String? completedAt;
  final String? failureDetails;

  const DataExportRequest({
    required this.id,
    required this.userId,
    this.verificationStatus = 'VERIFIED',
    this.exportScope = 'FULL_PERSONAL_DATA',
    required this.status,
    this.downloadR2Key,
    this.downloadUrlExpiresAt,
    required this.requestedAt,
    this.completedAt,
    this.failureDetails,
  });

  bool get isCompleted => status == 'COMPLETED';
  bool get isPending => status == 'PENDING' || status == 'PROCESSING';
  bool get isFailed => status == 'FAILED';

  factory DataExportRequest.fromJson(Map<String, dynamic> json) {
    return DataExportRequest(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      verificationStatus: json['verification_status'] as String? ?? json['verificationStatus'] as String? ?? 'VERIFIED',
      exportScope: json['export_scope'] as String? ?? json['exportScope'] as String? ?? 'FULL_PERSONAL_DATA',
      status: json['status'] as String? ?? 'PENDING',
      downloadR2Key: json['download_r2_key'] as String? ?? json['downloadR2Key'] as String?,
      downloadUrlExpiresAt: json['download_url_expires_at'] as String? ?? json['downloadUrlExpiresAt'] as String? ?? json['expiresAt'] as String?,
      requestedAt: json['requested_at'] as String? ?? json['requestedAt'] as String? ?? '',
      completedAt: json['completed_at'] as String? ?? json['completedAt'] as String?,
      failureDetails: json['failure_details'] as String? ?? json['failureDetails'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'verification_status': verificationStatus,
      'export_scope': exportScope,
      'status': status,
      'download_r2_key': downloadR2Key,
      'download_url_expires_at': downloadUrlExpiresAt,
      'requested_at': requestedAt,
      'completed_at': completedAt,
      'failure_details': failureDetails,
    };
  }
}

