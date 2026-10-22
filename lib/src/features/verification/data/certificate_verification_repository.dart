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
  })  : _httpClient = httpClient ?? http.Client();

  Future<CertificateVerificationResult> verifyCertificate(String token) async {
    try {
      final uri = Uri.parse('${apiClient.baseUrl}/api/public/credentials/verify/$token');
      final response = await _httpClient.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['valid'] == true) {
          return CertificateVerificationResult.valid(
            data['credential'] as Map<String, dynamic>?,
          );
        } else {
          return const CertificateVerificationResult.invalid('Certificate not valid');
        }
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
