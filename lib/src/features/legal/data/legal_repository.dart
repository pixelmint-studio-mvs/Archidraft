import '../../api/data/api_client.dart';
import '../domain/legal_document.dart';
import '../domain/privacy_request.dart';
import '../domain/user_legal_status.dart';

class LegalRepository {
  final ApiClient _apiClient;

  LegalRepository(this._apiClient);

  /// Retrieves metadata of all currently EFFECTIVE legal documents
  Future<List<LegalDocument>> getEffectiveDocuments() async {
    final response = await _apiClient.get('/api/legal/documents/current');
    if (response is Map<String, dynamic> && response['documents'] is List) {
      final list = response['documents'] as List;
      return list.map((item) => LegalDocument.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Retrieves full document content for a specific type
  Future<LegalDocument?> getDocument(String type, {String locale = 'en-IN'}) async {
    try {
      final response = await _apiClient.get(
        '/api/legal/documents/$type/current',
        queryParams: {'locale': locale},
      );
      if (response is Map<String, dynamic> && response['document'] is Map<String, dynamic>) {
        return LegalDocument.fromJson(response['document'] as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Retrieves authenticated user's current compliance and consent state
  Future<UserLegalStatus> getUserLegalStatus() async {
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
}
