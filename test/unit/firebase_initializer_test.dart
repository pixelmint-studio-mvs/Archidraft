// ignore_for_file: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:archi_draft/firebase_options.dart';
import 'package:archi_draft/src/core/bootstrap/firebase_initializer.dart';

class _TestFirebaseAppPlatform extends FirebaseAppPlatform {
  _TestFirebaseAppPlatform(super.name, super.options);
}

class _TestFirebasePlatform extends FirebasePlatform {
  final Map<String, FirebaseAppPlatform> _apps = {};
  int initializeCallCount = 0;

  @override
  List<FirebaseAppPlatform> get apps => _apps.values.toList();

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    initializeCallCount++;
    final appName = name ?? defaultFirebaseAppName;
    final opts = options ?? DefaultFirebaseOptions.androidStaging;
    final app = _TestFirebaseAppPlatform(appName, opts);
    _apps[appName] = app;
    return app;
  }

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    if (_apps.containsKey(name)) {
      return _apps[name]!;
    }
    throw FirebaseException(plugin: 'core', message: 'No app found');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _TestFirebasePlatform testPlatform;

  setUp(() {
    testPlatform = _TestFirebasePlatform();
    FirebasePlatform.instance = testPlatform;
    Firebase.delegatePackingProperty = testPlatform;
  });

  group('FirebaseInitializer', () {
    test('initializes default Firebase app when none exists', () async {
      final app = await FirebaseInitializer.initialize(
        options: DefaultFirebaseOptions.androidStaging,
      );

      expect(app.name, equals(defaultFirebaseAppName));
      expect(testPlatform.initializeCallCount, equals(1));
      expect(testPlatform.apps.length, equals(1));
    });

    test('is idempotent and does not re-initialize if default app already exists', () async {
      // First initialization
      final firstApp = await FirebaseInitializer.initialize(
        options: DefaultFirebaseOptions.androidStaging,
      );
      expect(testPlatform.initializeCallCount, equals(1));

      // Second initialization attempt (e.g. hot restart or redundant lifecycle call)
      final secondApp = await FirebaseInitializer.initialize(
        options: DefaultFirebaseOptions.androidStaging,
      );

      expect(secondApp.name, equals(firstApp.name));
      // Call count should NOT have increased
      expect(testPlatform.initializeCallCount, equals(1));
    });
  });

  group('DefaultFirebaseOptions configuration integrity', () {
    test('android staging configuration targets staging project', () {
      expect(DefaultFirebaseOptions.androidStaging.projectId, equals('archi-draft-staging'));
      expect(DefaultFirebaseOptions.androidStaging.apiKey, isNotEmpty);
      expect(DefaultFirebaseOptions.androidStaging.storageBucket, contains('archi-draft-staging'));
    });

    test('android production configuration targets production project', () {
      expect(DefaultFirebaseOptions.android.projectId, equals('archi-draft'));
      expect(DefaultFirebaseOptions.android.apiKey, isNotEmpty);
      expect(DefaultFirebaseOptions.android.storageBucket, contains('archi-draft'));
    });

    test('web configurations have correct project targets', () {
      expect(DefaultFirebaseOptions.webStaging.projectId, equals('archi-draft-staging'));
      expect(DefaultFirebaseOptions.web.projectId, equals('archi-draft'));
    });
  });
}
