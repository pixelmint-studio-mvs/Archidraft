/// CANONICAL LEGAL DOCUMENT MANIFEST — FLUTTER DART ADAPTER
/// Source: shared/legal/registry/version_manifest.json
library;

enum CanonicalDocumentType {
  termsAndConditions,
  privacyPolicy,
  aiUsageDisclaimer,
  engineeringDisclaimer,
  cadOwnershipFramework,
  revisionPolicy,
  cancellationRefundPolicy,
}

class CanonicalDocumentMetadata {
  final String id;
  final String documentType;
  final String version;
  final String title;
  final String summary;
  final String status;
  final bool isMandatory;
  final String locale;
  final List<String> targetAudience;
  final String? effectiveAt;
  final String contentPath;

  const CanonicalDocumentMetadata({
    required this.id,
    required this.documentType,
    required this.version,
    required this.title,
    required this.summary,
    required this.status,
    required this.isMandatory,
    this.locale = 'en-IN',
    required this.targetAudience,
    this.effectiveAt,
    required this.contentPath,
  });
}

class CanonicalLegalRegistry {
  static const String manifestVersion = '1.0.0';

  static const CanonicalDocumentMetadata termsAndConditions =
      CanonicalDocumentMetadata(
    id: 'doc-terms-v1-0-0',
    documentType: 'TERMS_AND_CONDITIONS',
    version: '1.0.0',
    title: 'Platform Terms and Conditions',
    summary:
        'Master contractual terms governing access, user role responsibilities, acceptable use, liability, and dispute resolution.',
    status: 'PENDING_LEGAL_REVIEW',
    isMandatory: true,
    targetAudience: ['ENGINEER', 'DRAUGHTSMAN', 'STUDENT', 'ADMIN', 'ALL'],
    contentPath: 'documents/terms_and_conditions/v1.0.0.md',
  );

  static const CanonicalDocumentMetadata privacyPolicy =
      CanonicalDocumentMetadata(
    id: 'doc-priv-v1-0-0',
    documentType: 'PRIVACY_POLICY',
    version: '1.0.0',
    title: 'Privacy Policy & Personal Data Protection Notice',
    summary:
        'Comprehensive data fiduciary disclosure detailing personal data processing, Firebase authentication, Cloudflare storage, and user data rights.',
    status: 'PENDING_LEGAL_REVIEW',
    isMandatory: false,
    targetAudience: ['ENGINEER', 'DRAUGHTSMAN', 'STUDENT', 'ADMIN', 'ALL'],
    contentPath: 'documents/privacy_policy/v1.0.0.md',
  );

  static const CanonicalDocumentMetadata aiUsageDisclaimer =
      CanonicalDocumentMetadata(
    id: 'doc-ai-v1-0-0',
    documentType: 'AI_USAGE_DISCLAIMER',
    version: '1.0.0',
    title: 'Pixmint Bot & AI Usage Disclaimer',
    summary:
        'Explicit disclosure on Pixmint Bot AI capabilities, non-certification of architectural/engineering outputs, and mandatory human professional verification.',
    status: 'PENDING_LEGAL_REVIEW',
    isMandatory: true,
    targetAudience: ['ENGINEER', 'DRAUGHTSMAN', 'STUDENT', 'ADMIN', 'ALL'],
    contentPath: 'documents/ai_usage_disclaimer/v1.0.0.md',
  );

  static const CanonicalDocumentMetadata engineeringDisclaimer =
      CanonicalDocumentMetadata(
    id: 'doc-eng-v1-0-0',
    documentType: 'ENGINEERING_DISCLAIMER',
    version: '1.0.0',
    title: 'Architectural and Engineering Professional Services Disclaimer',
    summary:
        'Clarification that Archi Draft is a technical workflow and educational collaboration portal, not a licensed engineering firm or architect of record.',
    status: 'PENDING_LEGAL_REVIEW',
    isMandatory: true,
    targetAudience: ['ENGINEER', 'DRAUGHTSMAN', 'STUDENT', 'ADMIN', 'ALL'],
    contentPath: 'documents/engineering_disclaimer/v1.0.0.md',
  );

  static const CanonicalDocumentMetadata cadOwnershipFramework =
      CanonicalDocumentMetadata(
    id: 'doc-cad-v1-0-0',
    documentType: 'CAD_OWNERSHIP_FRAMEWORK',
    version: '1.0.0',
    title: 'CAD Drawing Ownership and Intellectual Property Framework',
    summary:
        'Framework defining background IP, project deliverable rights, limited platform hosting license, and non-automatic IP transfer rules.',
    status: 'PENDING_LEGAL_REVIEW',
    isMandatory: true,
    targetAudience: ['ENGINEER', 'DRAUGHTSMAN', 'STUDENT', 'ADMIN'],
    contentPath: 'documents/cad_ownership_framework/v1.0.0.md',
  );

  static const CanonicalDocumentMetadata revisionPolicy =
      CanonicalDocumentMetadata(
    id: 'doc-rev-v1-0-0',
    documentType: 'REVISION_POLICY',
    version: '1.0.0',
    title: 'Project Revision and Correction Policy',
    summary:
        'Rules governing included revision rounds (2 cycles), correction scope vs new scope, turnaround windows, and additional billable drafting cycles.',
    status: 'PENDING_BUSINESS_APPROVAL',
    isMandatory: false,
    targetAudience: ['ENGINEER', 'DRAUGHTSMAN', 'ADMIN'],
    contentPath: 'documents/revision_policy/v1.0.0.md',
  );

  static const CanonicalDocumentMetadata cancellationRefundPolicy =
      CanonicalDocumentMetadata(
    id: 'doc-ref-v1-0-0',
    documentType: 'CANCELLATION_REFUND_POLICY',
    version: '1.0.0',
    title: 'Subscription, Cancellation and Refund Policy',
    summary:
        'Policy governing project cancellation milestones, drafting service dispute resolution, student course enrollment refunds, and grievance escalation.',
    status: 'PENDING_BUSINESS_APPROVAL',
    isMandatory: false,
    targetAudience: ['ENGINEER', 'DRAUGHTSMAN', 'STUDENT', 'ADMIN', 'ALL'],
    contentPath: 'documents/cancellation_refund_policy/v1.0.0.md',
  );

  static const List<CanonicalDocumentMetadata> allDocuments = [
    termsAndConditions,
    privacyPolicy,
    aiUsageDisclaimer,
    engineeringDisclaimer,
    cadOwnershipFramework,
    revisionPolicy,
    cancellationRefundPolicy,
  ];
}
