class DataCorrectionRequest {
  final String id;
  final String userId;
  final String fieldName;
  final String proposedValue;
  final String? reason;
  final String status;
  final String? reviewedBy;
  final String? reviewNotes;
  final String createdAt;
  final String? resolvedAt;

  const DataCorrectionRequest({
    required this.id,
    required this.userId,
    required this.fieldName,
    required this.proposedValue,
    this.reason,
    this.status = 'PENDING',
    this.reviewedBy,
    this.reviewNotes,
    required this.createdAt,
    this.resolvedAt,
  });

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';

  String get fieldLabel {
    switch (fieldName.toLowerCase()) {
      case 'name':
        return 'Full Legal Name';
      case 'mobile':
      case 'phone':
        return 'Mobile Phone Number';
      case 'address':
      case 'postal_address':
        return 'Postal Address';
      case 'qualification':
      case 'professional_qualification':
        return 'Educational / CAD Qualification';
      case 'college_name':
        return 'Institution / College';
      case 'company_name':
        return 'Studio / Firm Name';
      case 'specialization':
        return 'CAD Specialization';
      default:
        return fieldName.replaceAll('_', ' ').toUpperCase();
    }
  }

  factory DataCorrectionRequest.fromJson(Map<String, dynamic> json) {
    return DataCorrectionRequest(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      fieldName: json['field_name'] as String? ?? json['fieldName'] as String? ?? '',
      proposedValue: json['proposed_value'] as String? ?? json['proposedValue'] as String? ?? '',
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      reviewedBy: json['reviewed_by'] as String? ?? json['reviewedBy'] as String?,
      reviewNotes: json['review_notes'] as String? ?? json['reviewNotes'] as String?,
      createdAt: json['created_at'] as String? ?? json['createdAt'] as String? ?? '',
      resolvedAt: json['resolved_at'] as String? ?? json['resolvedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'field_name': fieldName,
      'proposed_value': proposedValue,
      'reason': reason,
      'status': status,
      'reviewed_by': reviewedBy,
      'review_notes': reviewNotes,
      'created_at': createdAt,
      'resolved_at': resolvedAt,
    };
  }
}

