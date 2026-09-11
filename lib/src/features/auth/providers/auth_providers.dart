import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/user_profile.dart';

// ──────────────────────────────────────────
// FIREBASE INSTANCE PROVIDERS
// ──────────────────────────────────────────

/// Provides the [FirebaseAuth] instance.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provides the [FirebaseFirestore] instance.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// ──────────────────────────────────────────
// REPOSITORY PROVIDER
// ──────────────────────────────────────────

/// Provides the [AuthRepository] with injected Firebase instances.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

// ──────────────────────────────────────────
// AUTH STATE STREAM
// ──────────────────────────────────────────

/// Reactive stream of authentication state.
///
/// Emits [User] when logged in, `null` when logged out.
/// Used by GoRouter redirect to determine navigation.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

// ──────────────────────────────────────────
// AUTH CONTROLLER
// ──────────────────────────────────────────

/// Controller for authentication actions (login, register, logout, etc.).
///
/// Exposes an [AsyncValue<void>] state to track loading/error/success
/// for UI feedback (loading spinners, error messages).
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AsyncData(null));

  /// Registers a new user.
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String mobile,
    required String role,
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.registerWithEmailAndPassword(
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

  /// Signs in with email and password.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.signInWithEmailAndPassword(
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

  /// Signs out the current user.
  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await _repository.signOut();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Sends a verification email to the current user.
  Future<bool> sendEmailVerification() async {
    state = const AsyncLoading();
    try {
      await _repository.sendEmailVerification();
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Reloads user data and checks email verification status.
  ///
  /// Returns `true` if the email is now verified.
  Future<bool> checkEmailVerified() async {
    try {
      return await _repository.reloadUser();
    } catch (_) {
      return false;
    }
  }

  /// Sends a password reset email.
  Future<bool> sendPasswordResetEmail({required String email}) async {
    state = const AsyncLoading();
    try {
      await _repository.sendPasswordResetEmail(email: email);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Resets the controller state to idle.
  void resetState() {
    state = const AsyncData(null);
  }
}

// ──────────────────────────────────────────
// USER PROFILE PROVIDER
// ──────────────────────────────────────────

/// Fetches the Firestore user profile for the currently authenticated user.
///
/// Automatically invalidates when auth state changes.
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.valueOrNull;
  if (user == null) return null;

  final repository = ref.watch(authRepositoryProvider);
  return repository.getUserProfile(user.uid);
});
