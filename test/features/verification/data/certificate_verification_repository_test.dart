import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:archi_draft/src/features/api/data/api_client.dart';
import 'package:archi_draft/src/features/verification/data/certificate_verification_repository.dart';

class _FakeFirebaseAuth extends Fake implements FirebaseAuth {}

void main() {
  late ApiClient apiClient;

  setUp(() {
    apiClient = ApiClient(_FakeFirebaseAuth());
  });

  test('verifyCertificate returns valid result when server returns valid: true', () async {
    final mockHttpClient = MockClient((request) async {
      expect(request.url.path, '/api/public/credentials/verify/token_valid');
      expect(request.headers.containsKey('Authorization'), isFalse);
      return http.Response(
        jsonEncode({
          'valid': true,
          'credential': {
            'id': 'cred_1',
            'title': 'Master of Architectural Drafting',
            'recipientName': 'John Doe',
            'issuedAt': '2026-10-10T00:00:00.000Z',
            'type': 'DIPLOMA',
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final repository = CertificateVerificationRepository(
      apiClient: apiClient,
      httpClient: mockHttpClient,
    );

    final result = await repository.verifyCertificate('token_valid');

    expect(result.isValid, isTrue);
    expect(result.error, isNull);
    expect(result.credentialData, isNotNull);
    expect(result.credentialData!['title'], equals('Master of Architectural Drafting'));
    expect(result.credentialData!['recipientName'], equals('John Doe'));
  });

  test('verifyCertificate returns invalid result when server returns valid: false', () async {
    final mockHttpClient = MockClient((request) async {
      return http.Response(
        jsonEncode({'valid': false, 'error': 'Certificate revoked'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final repository = CertificateVerificationRepository(
      apiClient: apiClient,
      httpClient: mockHttpClient,
    );

    final result = await repository.verifyCertificate('token_revoked');

    expect(result.isValid, isFalse);
    expect(result.error, equals('Certificate not valid'));
  });

  test('verifyCertificate returns invalid result when server returns 404', () async {
    final mockHttpClient = MockClient((request) async {
      return http.Response(
        jsonEncode({'valid': false, 'error': 'Certificate not found'}),
        404,
        headers: {'content-type': 'application/json'},
      );
    });

    final repository = CertificateVerificationRepository(
      apiClient: apiClient,
      httpClient: mockHttpClient,
    );

    final result = await repository.verifyCertificate('token_unknown');

    expect(result.isValid, isFalse);
    expect(result.error, equals('Certificate not found'));
  });

  test('verifyCertificate returns error result on 500 server response', () async {
    final mockHttpClient = MockClient((request) async {
      return http.Response('Internal Server Error', 500);
    });

    final repository = CertificateVerificationRepository(
      apiClient: apiClient,
      httpClient: mockHttpClient,
    );

    final result = await repository.verifyCertificate('token_err');

    expect(result.isValid, isFalse);
    expect(result.error, equals('Failed to verify certificate'));
  });

  test('verifyCertificate returns error result on network exception', () async {
    final mockHttpClient = MockClient((request) async {
      throw http.ClientException('Connection failed');
    });

    final repository = CertificateVerificationRepository(
      apiClient: apiClient,
      httpClient: mockHttpClient,
    );

    final result = await repository.verifyCertificate('token_network_fail');

    expect(result.isValid, isFalse);
    expect(result.error, equals('Network error during verification'));
  });
}
