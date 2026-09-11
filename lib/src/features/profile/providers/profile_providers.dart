import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/user_profile.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/profile_repository.dart';
import '../domain/user_role.dart';

// ──────────────────────────────────────────
// REPOSITORY PROVIDER
// ──────────────────────────────────────────

/// Provides the [ProfileRepository] with injected Firestore instance.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(firestoreProvider));
});

// ──────────────────────────────────────────
// CURRENT ROLE PROVIDER
// ──────────────────────────────────────────

/// Derives the [UserRole] enum from the currently authenticated user's profile.
///
/// Returns `null` if the user is not logged in, profile is not loaded,
/// or the role string is invalid.
final currentUserRoleProvider = Provider<UserRole?>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  
  return profileAsync.when(
    data: (profile) => UserRole.fromString(profile?.role),
    loading: () => null,
    error: (_, __) => null,
  );
});

// ──────────────────────────────────────────
// PROFILE EDITING CONTROLLER
// ──────────────────────────────────────────

/// Controller for updating user profile fields.
///
/// Exposes an [AsyncValue<void>] to track loading/error/success states.
final profileEditingControllerProvider =
    NotifierProvider<ProfileEditingController, AsyncValue<void>>(
        ProfileEditingController.new);

class ProfileEditingController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  /// Updates the user profile using the given [updatedProfile].
  ///
  /// Automatically invalidates the `userProfileProvider` upon success
  /// so that the UI reflects the latest changes.
  Future<bool> updateProfile(UserProfile updatedProfile) async {
    state = const AsyncLoading();
    try {
      await ref.read(profileRepositoryProvider).updateProfile(updatedProfile);
      
      // Invalidate the future provider to refetch the updated data
      ref.invalidate(userProfileProvider);
      
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
