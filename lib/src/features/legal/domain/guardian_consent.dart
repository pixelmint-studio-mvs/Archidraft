class GuardianConsent {
  final String id;
  final String studentUserId;
  final String guardianName;
  final String guardianEmail;
  final String? guardianPhone;
  final String relationship;
  final String consentPolicyVersion;
  final String verificationMethod;
  final String verificationStatus;
  final String? verifiedAt;
  final String? withdrawnAt;
  final String? notes;
  final String createdAt;

  const GuardianConsent({
    required this.id,
    required this.studentUserId,
    required this.guardianName,
    required this.guardianEmail,
    this.guardianPhone,
    required this.relationship,
    this.consentPolicyVersion = '1.0.0',
    this.verificationMethod = 'MANUAL_OFFICIAL_REVIEW',
    this.verificationStatus = 'PENDING_VERIFICATION',
    this.verifiedAt,
    this.withdrawnAt,
    this.notes,
    required this.createdAt,
  });

  bool get isVerified => verificationStatus == 'VERIFIED';
  bool get isPending => verificationStatus == 'PENDING_VERIFICATION';
  bool get isRejected => verificationStatus == 'REJECTED';
  bool get isWithdrawn => verificationStatus == 'WITHDRAWN';

  factory GuardianConsent.fromJson(Map<String, dynamic> json) {
    return GuardianConsent(
      id: json['id'] as String? ?? '',
      studentUserId: json['student_user_id'] as String? ?? json['studentUserId'] as String? ?? '',
      guardianName: json['guardian_name'] as String? ?? json['guardianName'] as String? ?? '',
      guardianEmail: json['guardian_email'] as String? ?? json['guardianEmail'] as String? ?? '',
      guardianPhone: json['guardian_phone'] as String? ?? json['guardianPhone'] as String?,
      relationship: json['relationship'] as String? ?? '',
      consentPolicyVersion: json['consent_policy_version'] as String? ?? json['consentPolicyVersion'] as String? ?? '1.0.0',
      verificationMethod: json['verification_method'] as String? ?? json['verificationMethod'] as String? ?? 'MANUAL_OFFICIAL_REVIEW',
      verificationStatus: json['verification_status'] as String? ?? json['verificationStatus'] as String? ?? 'PENDING_VERIFICATION',
      verifiedAt: json['verified_at'] as String? ?? json['verifiedAt'] as String?,
      withdrawnAt: json['withdrawn_at'] as String? ?? json['withdrawnAt'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String? ?? json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_user_id': studentUserId,
      'guardian_name': guardianName,
      'guardian_email': guardianEmail,
      'guardian_phone': guardianPhone,
      'relationship': relationship,
      'consent_policy_version': consentPolicyVersion,
      'verification_method': verificationMethod,
      'verification_status': verificationStatus,
      'verified_at': verifiedAt,
      'withdrawn_at': withdrawnAt,
      'notes': notes,
      'created_at': createdAt,
    };
  }
}
