import 'package:firebase_core/firebase_core.dart';
import '../../../firebase_options.dart';

/// Manages safe, idempotent lifecycle initialization of Firebase.
class FirebaseInitializer {
  /// Ensures the default Firebase app is initialized exactly once before any
  /// Firebase-dependent services run.
  ///
  /// If the default app has already been initialized (e.g. across hot restarts
  /// or multi-engine lifecycles), this is an idempotent safe return of [Firebase.app].
  static Future<FirebaseApp> initialize({
    FirebaseOptions? options,
  }) async {
    final defaultAppAlreadyExists = Firebase.apps.any(
      (app) => app.name == defaultFirebaseAppName,
    );

    if (defaultAppAlreadyExists) {
      return Firebase.app(defaultFirebaseAppName);
    }

    return Firebase.initializeApp(
      options: options ?? DefaultFirebaseOptions.currentPlatform,
    );
  }
}
