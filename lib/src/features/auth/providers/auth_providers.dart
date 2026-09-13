import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/user_profile.dart';
import '../../api/providers/api_providers.dart';

// ──────────────────────────────────────────
// FIREBASE INSTANCE PROVIDERS
// ──────────────────────────────────────────

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// ──────────────────────────────────────────
// REPOSITORY PROVIDER
// ──────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(apiClientProvider),
  );
});

// ──────────────────────────────────────────
// AUTH STATE STREAM
// ──────────────────────────────────────────

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

// ──────────────────────────────────────────
// AUTH CONTROLLER
// ──────────────────────────────────────────

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String mobile,
    required String role,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).registerWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        mobile: mobile,
        role: role,
      );
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signOut();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<bool> sendEmailVerification() async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> checkEmailVerified() async {
    try {
      return await ref.read(authRepositoryProvider).reloadUser();
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail({required String email}) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email: email);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  void resetState() {
    state = const AsyncData(null);
  }
}

// ──────────────────────────────────────────
// USER PROFILE PROVIDER
// ──────────────────────────────────────────

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;
  if (user == null) return null;

  final repository = ref.watch(authRepositoryProvider);
  return repository.getUserProfile(user.uid);
});
