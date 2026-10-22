class LegalDocument {
  final String id;
  final String documentType;
  final String version;
  final String title;
  final String content;
  final String? effectiveAt;
  final String? publishedAt;
  final String status;
  final bool isMandatory;
  final String locale;
  final String? changeSummary;

  const LegalDocument({
    required this.id,
    required this.documentType,
    required this.version,
    required this.title,
    this.content = '',
    this.effectiveAt,
    this.publishedAt,
    this.status = 'DRAFT',
    this.isMandatory = true,
    this.locale = 'en-IN',
    this.changeSummary,
  });

  factory LegalDocument.fromJson(Map<String, dynamic> json) {
    return LegalDocument(
      id: json['id'] as String? ?? '',
      documentType: json['document_type'] as String? ?? '',
      version: json['version'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      effectiveAt: json['effective_at'] as String?,
      publishedAt: json['published_at'] as String?,
      status: json['status'] as String? ?? 'DRAFT',
      isMandatory: (json['is_mandatory'] == 1 || json['is_mandatory'] == true),
      locale: json['locale'] as String? ?? 'en-IN',
      changeSummary: json['change_summary'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_type': documentType,
      'version': version,
      'title': title,
      'content': content,
      'effective_at': effectiveAt,
      'published_at': publishedAt,
      'status': status,
      'is_mandatory': isMandatory ? 1 : 0,
      'locale': locale,
      'change_summary': changeSummary,
    };
  }
}
