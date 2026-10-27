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

    test('resolves to 10.0.2.2:8787 in Android emulator mode when unconfigured', () {
      final url = ApiClient.resolveBaseUrl(
        overrideUrl: '',
        isRelease: false,
        isAndroidEmulator: true,
      );
      expect(url, equals('http://10.0.2.2:8787'));
    });

    test('maps localhost to 10.0.2.2 in Android emulator mode', () {
      final url = ApiClient.resolveBaseUrl(
        overrideUrl: 'http://localhost:8787',
        isRelease: false,
        isAndroidEmulator: true,
      );
      expect(url, equals('http://10.0.2.2:8787'));
    });

    test('preserves explicit custom non-localhost IP in Android emulator mode', () {
      final url = ApiClient.resolveBaseUrl(
        overrideUrl: 'http://192.168.1.100:8787',
        isRelease: false,
        isAndroidEmulator: true,
      );
      expect(url, equals('http://192.168.1.100:8787'));
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

    test('strips trailing slashes from overrideUrl in resolveBaseUrl', () {
      final url = ApiClient.resolveBaseUrl(
        overrideUrl: 'http://localhost:8787/',
        isRelease: false,
      );
      expect(url, equals('http://localhost:8787'));

      final multipleSlashes = ApiClient.resolveBaseUrl(
        overrideUrl: 'http://localhost:8787///',
        isRelease: false,
      );
      expect(multipleSlashes, equals('http://localhost:8787'));
    });
  });

  group('ApiClient.buildUri', () {
    test('constructs clean URI without double slash even if baseUrl has trailing slash', () {
      final client = ApiClient(
        _FakeFirebaseAuth(),
        baseUrl: 'http://localhost:8787/',
        isRelease: false,
      );
      final uri = client.buildUri('/api/users/me/legal-status');
      expect(uri.toString(), equals('http://localhost:8787/api/users/me/legal-status'));
    });

    test('constructs clean URI if path does not have leading slash', () {
      final client = ApiClient(
        _FakeFirebaseAuth(),
        baseUrl: 'http://localhost:8787',
        isRelease: false,
      );
      final uri = client.buildUri('api/users/me/legal-status');
      expect(uri.toString(), equals('http://localhost:8787/api/users/me/legal-status'));
    });

    test('appends query parameters correctly', () {
      final client = ApiClient(
        _FakeFirebaseAuth(),
        baseUrl: 'http://localhost:8787',
        isRelease: false,
      );
      final uri = client.buildUri('/api/legal/documents/current', {'locale': 'en-IN'});
      expect(uri.toString(), equals('http://localhost:8787/api/legal/documents/current?locale=en-IN'));
    });
  });
}
