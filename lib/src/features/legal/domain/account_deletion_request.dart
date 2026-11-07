class AccountDeletionRequest {
  final String id;
  final String userId;
  final String requestCategory;
  final String status;
  final String identityVerificationStatus;
  final String? reason;
  final String? reviewNotes;
  final String? resolutionStatus;
  final String submittedAt;
  final String? scheduledFor;
  final String? processedAt;
  final String? completedAt;
  final String? cancelledAt;
  final String? failureDetails;
  final String? retentionHoldReason;

  const AccountDeletionRequest({
    required this.id,
    required this.userId,
    this.requestCategory = 'SELF_SERVICE',
    required this.status,
    this.identityVerificationStatus = 'VERIFIED',
    this.reason,
    this.reviewNotes,
    this.resolutionStatus,
    required this.submittedAt,
    this.scheduledFor,
    this.processedAt,
    this.completedAt,
    this.cancelledAt,
    this.failureDetails,
    this.retentionHoldReason,
  });

  bool get isCancellable =>
      ['SUBMITTED', 'IDENTITY_VERIFICATION_REQUIRED', 'VERIFIED', 'UNDER_REVIEW', 'DELETION_SCHEDULED'].contains(status);

  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isUnderReview => status == 'UNDER_REVIEW';

  factory AccountDeletionRequest.fromJson(Map<String, dynamic> json) {
    return AccountDeletionRequest(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      requestCategory: json['request_category'] as String? ?? json['requestCategory'] as String? ?? 'SELF_SERVICE',
      status: json['status'] as String? ?? 'SUBMITTED',
      identityVerificationStatus: json['identity_verification_status'] as String? ?? json['identityVerificationStatus'] as String? ?? 'VERIFIED',
      reason: json['reason'] as String?,
      reviewNotes: json['review_notes'] as String? ?? json['reviewNotes'] as String?,
      resolutionStatus: json['resolution_status'] as String? ?? json['resolutionStatus'] as String?,
      submittedAt: json['submitted_at'] as String? ?? json['submittedAt'] as String? ?? '',
      scheduledFor: json['scheduled_for'] as String? ?? json['scheduledFor'] as String?,
      processedAt: json['processed_at'] as String? ?? json['processedAt'] as String?,
      completedAt: json['completed_at'] as String? ?? json['completedAt'] as String?,
      cancelledAt: json['cancelled_at'] as String? ?? json['cancelledAt'] as String?,
      failureDetails: json['failure_details'] as String? ?? json['failureDetails'] as String?,
      retentionHoldReason: json['retention_hold_reason'] as String? ?? json['retentionHoldReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'request_category': requestCategory,
      'status': status,
      'identity_verification_status': identityVerificationStatus,
      'reason': reason,
      'review_notes': reviewNotes,
      'resolution_status': resolutionStatus,
      'submitted_at': submittedAt,
      'scheduled_for': scheduledFor,
      'processed_at': processedAt,
      'completed_at': completedAt,
      'cancelled_at': cancelledAt,
      'failure_details': failureDetails,
      'retention_hold_reason': retentionHoldReason,
    };
  }
}
