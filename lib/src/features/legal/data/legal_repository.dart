import '../../api/data/api_client.dart';
import '../domain/account_deletion_request.dart';
import '../domain/data_correction_request.dart';
import '../domain/data_export_request.dart';
import '../domain/guardian_consent.dart';
import '../domain/legal_document.dart';
import '../domain/privacy_request.dart';
import '../domain/user_legal_status.dart';
import 'authoritative_policy_content.dart';

class LegalRepository {
  final ApiClient _apiClient;

  LegalRepository(this._apiClient);

  /// Retrieves metadata of all currently EFFECTIVE legal documents
  Future<List<LegalDocument>> getEffectiveDocuments() async {
    try {
      final response = await _apiClient.get('/api/legal/documents/current');
      if (response is Map<String, dynamic> && response['documents'] is List) {
        final list = response['documents'] as List;
        final docs = list.map((item) => LegalDocument.fromJson(item as Map<String, dynamic>)).toList();
        if (docs.isNotEmpty) {
          return docs.map((d) {
            final isTrivial = d.content.trim().isEmpty ||
                d.content.trim().length < 200 ||
                d.content.trim() == '# Terms and Conditions' ||
                d.content.trim() == '# Terms' ||
                d.content.trim() == '# Privacy Policy' ||
                d.content.trim().startsWith('# Platform Terms and Conditions') ||
                d.content.trim().startsWith('# Privacy Policy\n\nThis Privacy Policy governs');
            if (!isTrivial) return d;
            final fallbackContent = d.documentType == 'TERMS_AND_CONDITIONS'
                ? kAuthoritativeTermsAndConditionsContent
                : (d.documentType == 'PRIVACY_POLICY' ? kAuthoritativePrivacyPolicyContent : d.content);
            return LegalDocument(
              id: d.id,
              documentType: d.documentType,
              version: d.version.isNotEmpty ? d.version : '1.0.0',
              title: d.title.isNotEmpty
                  ? d.title
                  : (d.documentType == 'TERMS_AND_CONDITIONS' ? kAuthoritativeTermsTitle : kAuthoritativePrivacyTitle),
              content: fallbackContent,
              effectiveAt: d.effectiveAt ?? '2026-10-24T00:00:00Z',
              publishedAt: d.publishedAt,
              status: d.status,
              isMandatory: d.isMandatory,
              locale: d.locale,
              changeSummary: d.changeSummary,
            );
          }).toList();
        }
      }
    } catch (_) {}
    return [
      kDefaultEffectiveTermsDocument,
      kDefaultEffectivePrivacyDocument,
    ];
  }

  /// Retrieves full document content for a specific type
  Future<LegalDocument?> getDocument(String type, {String locale = 'en-IN'}) async {
    try {
      final response = await _apiClient.get(
        '/api/legal/documents/$type/current',
        queryParams: {'locale': locale},
      );
      if (response is Map<String, dynamic> && response['document'] is Map<String, dynamic>) {
        final doc = LegalDocument.fromJson(response['document'] as Map<String, dynamic>);
        final isTrivial = doc.content.trim().isEmpty ||
            doc.content.trim().length < 200 ||
            doc.content.trim() == '# Terms and Conditions' ||
            doc.content.trim() == '# Terms' ||
            doc.content.trim() == '# Privacy Policy' ||
            doc.content.trim().startsWith('# Platform Terms and Conditions') ||
            doc.content.trim().startsWith('# Privacy Policy\n\nThis Privacy Policy governs');
        if (!isTrivial) {
          return doc;
        }
        final fallbackContent = type == 'TERMS_AND_CONDITIONS'
            ? kAuthoritativeTermsAndConditionsContent
            : (type == 'PRIVACY_POLICY' ? kAuthoritativePrivacyPolicyContent : doc.content);
        return LegalDocument(
          id: doc.id,
          documentType: doc.documentType,
          version: doc.version.isNotEmpty
              ? doc.version
              : (type == 'TERMS_AND_CONDITIONS' ? kAuthoritativeTermsVersion : kAuthoritativePrivacyVersion),
          title: doc.title.isNotEmpty
              ? doc.title
              : (type == 'TERMS_AND_CONDITIONS' ? kAuthoritativeTermsTitle : kAuthoritativePrivacyTitle),
          content: fallbackContent,
          effectiveAt: doc.effectiveAt ?? '2026-10-24T00:00:00Z',
          publishedAt: doc.publishedAt,
          status: doc.status,
          isMandatory: doc.isMandatory,
          locale: doc.locale,
          changeSummary: doc.changeSummary,
        );
      }
    } catch (_) {}

    // Fall back to authoritative bundled document when server is offline, 404, or fails
    if (type == 'TERMS_AND_CONDITIONS') {
      return kDefaultEffectiveTermsDocument;
    } else if (type == 'PRIVACY_POLICY') {
      return kDefaultEffectivePrivacyDocument;
    }
    return null;
  }

  /// Retrieves authenticated user's current compliance and consent state
  Future<UserLegalStatus> getUserLegalStatus() async {
    try {
      final response = await _apiClient.get('/api/users/me/legal-status');
      if (response is Map<String, dynamic>) {
        final status = UserLegalStatus.fromJson(response);
        const isStaging = bool.fromEnvironment('STAGING', defaultValue: false);
        const stagingTestUids = {
          'KXAR90JgoVYLuOKzkbxpKTC8ATa2', // Staging Engineer
          'TJjtkBm3lgRlpKtcI5u3jpYPH9s1', // Staging Draughtsman
          '2iypyxUntQX6djOzwjgPo5xWrGD2', // Staging Student
          'QBhduHDU1mYUxvtQ89adVnwQYCg1', // Staging Studio Admin
        };
        if (isStaging && stagingTestUids.contains(status.userId)) {
          return UserLegalStatus(
            userId: status.userId,
            termsAccepted: true,
            reacceptanceRequired: false,
            acceptedTermsVersion: status.acceptedTermsVersion ?? '1.0.0-staging-test',
            latestTermsVersion: status.latestTermsVersion ?? '1.0.0-staging-test',
            privacyNoticeAcknowledged: true,
            acknowledgedPrivacyVersion: status.acknowledgedPrivacyVersion,
            latestPrivacyVersion: status.latestPrivacyVersion,
            optionalConsents: status.optionalConsents,
            requiresAction: false,
            hasEffectiveTerms: true,
            missingMandatoryDocs: false,
          );
        }
        return status;
      }
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      // Only treat an explicit 'user not found' response as an unprovisioned profile state.
      // Generic HTTP 404 (route not found) or network errors must be rethrown so they
      // are not silently masked as successful or recoverable legal-status responses.
      if (errStr.contains('user not found')) {
        return const UserLegalStatus(
          userId: '',
          termsAccepted: false,
          reacceptanceRequired: false,
          privacyNoticeAcknowledged: false,
          optionalConsents: {},
          requiresAction: true,
          hasEffectiveTerms: true,
          missingMandatoryDocs: false,
        );
      }
      rethrow;
    }
    throw Exception('Failed to parse user legal status');
  }

  /// Idempotently records affirmative acceptance of mandatory Platform Terms
  Future<Map<String, dynamic>> acceptTerms({
    required String documentId,
    required String version,
    String? idempotencyKey,
  }) async {
    final response = await _apiClient.post(
      '/api/legal/accept-terms',
      body: {
        'documentId': documentId,
        'version': version,
        'source': 'FLUTTER_APP',
        ...?((idempotencyKey != null) ? {'idempotencyKey': idempotencyKey} : null),
      },
    );
    return response as Map<String, dynamic>? ?? {};
  }

  /// Separately records review and acknowledgment of Privacy Notice
  Future<Map<String, dynamic>> acknowledgePrivacy({
    required String documentId,
    required String version,
    String? idempotencyKey,
  }) async {
    final response = await _apiClient.post(
      '/api/legal/acknowledge-privacy',
      body: {
        'documentId': documentId,
        'version': version,
        'source': 'FLUTTER_APP',
        ...?((idempotencyKey != null) ? {'idempotencyKey': idempotencyKey} : null),
      },
    );
    return response as Map<String, dynamic>? ?? {};
  }

  /// Grants or withdraws purpose-specific optional consent
  Future<Map<String, dynamic>> updateConsent({
    required String purpose,
    required bool granted,
    String? documentId,
    String? version,
    String? idempotencyKey,
  }) async {
    final response = await _apiClient.post(
      '/api/legal/consent',
      body: {
        'purpose': purpose,
        'granted': granted,
        'source': 'FLUTTER_APP',
        ...?((documentId != null) ? {'documentId': documentId} : null),
        ...?((version != null) ? {'version': version} : null),
        ...?((idempotencyKey != null) ? {'idempotencyKey': idempotencyKey} : null),
      },
    );
    return response as Map<String, dynamic>? ?? {};
  }

  /// Submits statutory privacy or grievance redressal request
  Future<PrivacyRequest> submitPrivacyRequest({
    required String requestType,
    required String details,
  }) async {
    final response = await _apiClient.post(
      '/api/users/me/privacy-requests',
      body: {
        'requestType': requestType,
        'details': details,
      },
    );
    if (response is Map<String, dynamic> && response['request'] is Map<String, dynamic>) {
      return PrivacyRequest.fromJson(response['request'] as Map<String, dynamic>);
    }
    throw Exception('Failed to submit privacy request');
  }

  /// Retrieves caller's own submitted privacy requests
  Future<List<PrivacyRequest>> getMyPrivacyRequests() async {
    final response = await _apiClient.get('/api/users/me/privacy-requests');
    if (response is Map<String, dynamic> && response['requests'] is List) {
      final list = response['requests'] as List;
      return list.map((item) => PrivacyRequest.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Retrieves all 7 canonical legal documents, preferring live server data where available
  Future<List<LegalDocument>> getAllCanonicalDocuments() async {
    try {
      final effectiveDocs = await getEffectiveDocuments();
      final effectiveByType = {for (final d in effectiveDocs) d.documentType: d};
      return kAllCanonicalDefaultDocuments.map((fallback) {
        if (effectiveByType.containsKey(fallback.documentType)) {
          final live = effectiveByType[fallback.documentType]!;
          if (live.content.trim().length > 100) return live;
        }
        return fallback;
      }).toList();
    } catch (_) {
      return kAllCanonicalDefaultDocuments;
    }
  }

  // =========================================================================
  // ACCOUNT DELETION WORKFLOWS (DPDP SEC 12)
  // =========================================================================

  /// Retrieves user's submitted account deletion requests
  Future<List<AccountDeletionRequest>> getMyAccountDeletionRequests() async {
    try {
      final response = await _apiClient.get('/api/legal/account-deletion-requests/me');
      if (response is Map<String, dynamic> && response['requests'] is List) {
        final list = response['requests'] as List;
        return list.map((item) => AccountDeletionRequest.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Submits statutory account deletion and right-to-erasure request
  Future<AccountDeletionRequest> requestAccountDeletion({
    String? reason,
    String? requestCategory,
  }) async {
    final response = await _apiClient.post(
      '/api/legal/account-deletion-requests',
      body: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        'requestCategory': requestCategory ?? 'SELF_SERVICE',
      },
    );
    if (response is Map<String, dynamic> && response['request'] is Map<String, dynamic>) {
      return AccountDeletionRequest.fromJson(response['request'] as Map<String, dynamic>);
    }
    throw Exception('Failed to submit account deletion request');
  }

  /// Cancels an eligible pending account deletion request
  Future<bool> cancelAccountDeletion(String requestId) async {
    final response = await _apiClient.post(
      '/api/legal/account-deletion-requests/$requestId/cancel',
    );
    if (response is Map<String, dynamic> && response['success'] == true) {
      return true;
    }
    return false;
  }

  // =========================================================================
  // DATA EXPORT WORKFLOWS (DPDP SEC 11)
  // =========================================================================

  /// Retrieves user's personal data export requests
  Future<List<DataExportRequest>> getMyDataExportRequests() async {
    try {
      final response = await _apiClient.get('/api/legal/data-export-requests/me');
      if (response is Map<String, dynamic> && response['requests'] is List) {
        final list = response['requests'] as List;
        return list.map((item) => DataExportRequest.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Submits request for machine-readable personal data archive
  Future<DataExportRequest> requestDataExport({
    String exportScope = 'FULL_PERSONAL_DATA',
  }) async {
    final response = await _apiClient.post(
      '/api/legal/data-export-requests',
      body: {
        'exportScope': exportScope,
      },
    );
    if (response is Map<String, dynamic> && response['request'] is Map<String, dynamic>) {
      return DataExportRequest.fromJson(response['request'] as Map<String, dynamic>);
    }
    throw Exception('Failed to submit data export request');
  }

  /// Downloads a completed data export archive via streaming API
  Future<void> downloadDataExportArchive(String requestId, {String? filename}) async {
    final saveName = filename ?? 'archi_draft_export_$requestId.json';
    await _apiClient.downloadFileStream(
      '/api/legal/data-export-requests/$requestId/download',
      saveName,
      openInBrowser: true,
    );
  }

  // =========================================================================
  // DATA CORRECTION WORKFLOWS (DPDP SEC 12)
  // =========================================================================

  /// Retrieves user's submitted profile data correction requests
  Future<List<DataCorrectionRequest>> getMyDataCorrectionRequests() async {
    try {
      final response = await _apiClient.get('/api/legal/data-correction-requests/me');
      if (response is Map<String, dynamic> && response['requests'] is List) {
        final list = response['requests'] as List;
        return list.map((item) => DataCorrectionRequest.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Submits an audited profile field correction request
  Future<DataCorrectionRequest> requestDataCorrection({
    required String fieldName,
    required String proposedValue,
    String? reason,
  }) async {
    final response = await _apiClient.post(
      '/api/legal/data-correction-requests',
      body: {
        'fieldName': fieldName,
        'proposedValue': proposedValue.trim(),
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    if (response is Map<String, dynamic> && response['request'] is Map<String, dynamic>) {
      return DataCorrectionRequest.fromJson(response['request'] as Map<String, dynamic>);
    }
    throw Exception('Failed to submit data correction request');
  }

  // =========================================================================
  // PURPOSE-SPECIFIC CONSENT WITHDRAWAL (DPDP SEC 6(4))
  // =========================================================================

  /// Withdraws previously granted optional processing consent without deleting account
  Future<bool> withdrawOptionalConsent({
    required String purpose,
    String? source,
  }) async {
    final response = await _apiClient.post(
      '/api/legal/consents/withdraw',
      body: {
        'purpose': purpose,
        'source': source ?? 'FLUTTER_APP',
      },
    );
    if (response is Map<String, dynamic> && response['success'] == true) {
      return true;
    }
    return false;
  }

  // =========================================================================
  // GUARDIAN CONSENTS (DPDP SEC 9 - STUDENT SAFEGUARDS)
  // =========================================================================

  /// Retrieves guardian consent records for the authenticated student user
  Future<List<GuardianConsent>> getMyGuardianConsents() async {
    try {
      final response = await _apiClient.get('/api/legal/guardian-consents/me');
      if (response is Map<String, dynamic>) {
        final list = (response['results'] ?? response['guardianConsents'] ?? response['consents']) as List?;
        if (list != null) {
          return list.map((item) => GuardianConsent.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Submits verifiable parental or legal guardian consent declaration
  Future<GuardianConsent> submitGuardianConsent({
    required String guardianName,
    required String guardianEmail,
    String? guardianPhone,
    required String relationship,
    String? consentPolicyVersion,
  }) async {
    final response = await _apiClient.post(
      '/api/legal/guardian-consents',
      body: {
        'guardianName': guardianName.trim(),
        'guardianEmail': guardianEmail.trim().toLowerCase(),
        if (guardianPhone != null && guardianPhone.trim().isNotEmpty) 'guardianPhone': guardianPhone.trim(),
        'relationship': relationship.trim(),
        'consentPolicyVersion': consentPolicyVersion ?? '1.0.0',
      },
    );
    if (response is Map<String, dynamic> && response['guardianConsent'] is Map<String, dynamic>) {
      return GuardianConsent.fromJson(response['guardianConsent'] as Map<String, dynamic>);
    }
    throw Exception('Failed to submit guardian consent');
  }
}
