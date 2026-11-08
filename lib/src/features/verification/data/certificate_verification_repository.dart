import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../api/data/api_client.dart';
import '../domain/certificate_verification_result.dart';

class CertificateVerificationRepository {
  final ApiClient apiClient;
  final http.Client _httpClient;

  CertificateVerificationRepository({
    required this.apiClient,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  Future<CertificateVerificationResult> verifyCertificate(String token) async {
    final cleanToken = token.trim();
    if (cleanToken.isEmpty) {
      return const CertificateVerificationResult.invalid('Please enter a certificate ID or cryptographic token');
    }

    try {
      final uri = Uri.parse(
        '${apiClient.baseUrl}/api/public/credentials/verify/${Uri.encodeComponent(cleanToken)}',
      );
      final response = await _httpClient.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final status = (data['status'] as String? ?? (data['valid'] == true ? 'VALID' : 'INVALID')).toUpperCase();
          final cred = data['credential'] as Map<String, dynamic>?;

          if (status == 'REVOKED' || cred?['status'] == 'REVOKED' || cred?['revokedAt'] != null) {
            return CertificateVerificationResult.revoked(
              credentialData: cred,
              error: data['error'] as String? ?? 'This certificate has been formally revoked by administrative authority.',
            );
          } else if (status == 'PENDING') {
            return CertificateVerificationResult.pending(
              data['error'] as String? ?? 'Certificate issuance is currently pending verification.',
            );
          } else if (data['valid'] == true && cred != null) {
            return CertificateVerificationResult.valid(cred);
          } else {
            return const CertificateVerificationResult.invalid('Certificate not valid');
          }
        }
        return const CertificateVerificationResult.invalid('Certificate not valid');
      } else if (response.statusCode == 404) {
        return const CertificateVerificationResult.invalid('Certificate not found');
      } else {
        return const CertificateVerificationResult.error('Failed to verify certificate');
      }
    } catch (_) {
      return const CertificateVerificationResult.error('Network error during verification');
    }
  }
}
