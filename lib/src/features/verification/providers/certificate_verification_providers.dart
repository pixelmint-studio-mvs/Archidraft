import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../api/providers/api_providers.dart';
import '../data/certificate_verification_repository.dart';
import '../domain/certificate_verification_result.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(() => client.close());
  return client;
});

final certificateVerificationRepositoryProvider = Provider<CertificateVerificationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final httpClient = ref.watch(httpClientProvider);
  return CertificateVerificationRepository(
    apiClient: apiClient,
    httpClient: httpClient,
  );
});

final certificateVerificationProvider =
    FutureProvider.autoDispose.family<CertificateVerificationResult, String>(
        (ref, token) async {
  final repository = ref.watch(certificateVerificationRepositoryProvider);
  return repository.verifyCertificate(token);
});
