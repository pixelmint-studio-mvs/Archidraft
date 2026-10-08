class StudentCredential {
  final String id;
  final String type;
  final String title;
  final String description;
  final String referenceId;
  final DateTime issuedAt;
  final String? certificateObjectKey;
  final String? verificationToken;

  StudentCredential({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.referenceId,
    required this.issuedAt,
    this.certificateObjectKey,
    this.verificationToken,
  });

  factory StudentCredential.fromJson(Map<String, dynamic> json) {
    return StudentCredential(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      referenceId: json['referenceId'] as String,
      issuedAt: DateTime.parse(json['issuedAt'] as String),
      certificateObjectKey: json['certificateObjectKey'] as String?,
      verificationToken: json['verificationToken'] as String?,
    );
  }
}
