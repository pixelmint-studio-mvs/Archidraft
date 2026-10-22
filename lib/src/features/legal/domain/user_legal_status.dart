class UserLegalStatus {
  final String userId;
  final bool termsAccepted;
  final bool reacceptanceRequired;
  final String? acceptedTermsVersion;
  final String? latestTermsVersion;
  final bool privacyNoticeAcknowledged;
  final String? acknowledgedPrivacyVersion;
  final String? latestPrivacyVersion;
  final Map<String, bool> optionalConsents;
  final bool requiresAction;
  final bool hasEffectiveTerms;
  final bool missingMandatoryDocs;

  const UserLegalStatus({
    required this.userId,
    required this.termsAccepted,
    required this.reacceptanceRequired,
    this.acceptedTermsVersion,
    this.latestTermsVersion,
    required this.privacyNoticeAcknowledged,
    this.acknowledgedPrivacyVersion,
    this.latestPrivacyVersion,
    required this.optionalConsents,
    required this.requiresAction,
    this.hasEffectiveTerms = true,
    this.missingMandatoryDocs = false,
  });

  factory UserLegalStatus.fromJson(Map<String, dynamic> json) {
    final rawConsents = json['optionalConsents'] as Map?;
    final parsedConsents = <String, bool>{};
    if (rawConsents != null) {
      for (final entry in rawConsents.entries) {
        parsedConsents[entry.key.toString()] = entry.value == true;
      }
    }

    return UserLegalStatus(
      userId: json['userId'] as String? ?? '',
      termsAccepted: json['termsAccepted'] == true,
      reacceptanceRequired: json['reacceptanceRequired'] == true,
      acceptedTermsVersion: json['acceptedTermsVersion'] as String?,
      latestTermsVersion: json['latestTermsVersion'] as String?,
      privacyNoticeAcknowledged: json['privacyNoticeAcknowledged'] == true,
      acknowledgedPrivacyVersion: json['acknowledgedPrivacyVersion'] as String?,
      latestPrivacyVersion: json['latestPrivacyVersion'] as String?,
      optionalConsents: parsedConsents,
      requiresAction: json['requiresAction'] == true,
      hasEffectiveTerms: json['hasEffectiveTerms'] != false,
      missingMandatoryDocs: json['missingMandatoryDocs'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'termsAccepted': termsAccepted,
      'reacceptanceRequired': reacceptanceRequired,
      'acceptedTermsVersion': acceptedTermsVersion,
      'latestTermsVersion': latestTermsVersion,
      'privacyNoticeAcknowledged': privacyNoticeAcknowledged,
      'acknowledgedPrivacyVersion': acknowledgedPrivacyVersion,
      'latestPrivacyVersion': latestPrivacyVersion,
      'optionalConsents': optionalConsents,
      'requiresAction': requiresAction,
      'hasEffectiveTerms': hasEffectiveTerms,
      'missingMandatoryDocs': missingMandatoryDocs,
    };
  }
}
