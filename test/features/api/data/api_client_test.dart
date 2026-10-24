import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:archi_draft/src/features/api/data/api_client.dart';

class _FakeFirebaseAuth extends Fake implements FirebaseAuth {}

void main() {
  group('ApiClient.resolveBaseUrl', () {
    test('defaults to localhost:8787 in non-release mode when unconfigured', () {
      final url = ApiClient.resolveBaseUrl(overrideUrl: '', isRelease: false);
      expect(url, equals('http://localhost:8787'));
    });

    test('accepts custom URL in non-release mode', () {
      final url = ApiClient.resolveBaseUrl(
        overrideUrl: 'http://192.168.1.50:8787',
        isRelease: false,
      );
      expect(url, equals('http://192.168.1.50:8787'));
    });

    test('throws StateError in release mode when API_URL is empty', () {
      expect(
        () => ApiClient.resolveBaseUrl(overrideUrl: '', isRelease: true),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('API_URL must be explicitly configured for release builds'),
        )),
      );
    });

    test('throws StateError in release mode when API_URL is non-HTTPS', () {
      expect(
        () => ApiClient.resolveBaseUrl(
          overrideUrl: 'http://api.draughtsmanstudio.com',
          isRelease: true,
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('must be a valid HTTPS URL'),
        )),
      );
    });

    test('throws StateError in release mode when API_URL points to localhost', () {
      expect(
        () => ApiClient.resolveBaseUrl(
          overrideUrl: 'https://localhost:8787',
          isRelease: true,
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('cannot point to localhost/127.0.0.1'),
        )),
      );
    });

    test('throws StateError in release mode when API_URL points to 127.0.0.1', () {
      expect(
        () => ApiClient.resolveBaseUrl(
          overrideUrl: 'https://127.0.0.1:8787',
          isRelease: true,
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('cannot point to localhost/127.0.0.1'),
        )),
      );
    });

    test('accepts valid HTTPS staging or production URL in release mode', () {
      final stagingUrl = ApiClient.resolveBaseUrl(
        overrideUrl: 'https://archi-draft-worker-staging.pixelmint.workers.dev',
        isRelease: true,
      );
      expect(stagingUrl, equals('https://archi-draft-worker-staging.pixelmint.workers.dev'));

      final prodUrl = ApiClient.resolveBaseUrl(
        overrideUrl: 'https://api.draughtsmanstudio.com',
        isRelease: true,
      );
      expect(prodUrl, equals('https://api.draughtsmanstudio.com'));
    });

    test('ApiClient constructor uses resolveBaseUrl', () {
      final client = ApiClient(
        _FakeFirebaseAuth(),
        baseUrl: 'https://api.draughtsmanstudio.com',
        isRelease: true,
      );
      expect(client.baseUrl, equals('https://api.draughtsmanstudio.com'));
    });
  });
}
