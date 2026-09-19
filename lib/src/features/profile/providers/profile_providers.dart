import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/user_profile.dart';
import '../../auth/providers/auth_providers.dart';
import '../../api/providers/api_providers.dart';
import '../data/profile_repository.dart';
import '../domain/user_role.dart';

// ──────────────────────────────────────────
// REPOSITORY PROVIDER
// ──────────────────────────────────────────

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(apiClientProvider));
});

// ──────────────────────────────────────────
// CURRENT ROLE PROVIDER
// ──────────────────────────────────────────

final currentUserRoleProvider = Provider<UserRole?>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  
  return profileAsync.when(
    data: (profile) => UserRole.fromString(profile?.role),
    loading: () => null,
    error: (e, _) => null,
  );
});

// ──────────────────────────────────────────
// PROFILE COMPLETENESS PROVIDER
// ──────────────────────────────────────────

final isProfileCompleteProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.maybeWhen(
    data: (profile) => profile != null && ProfileRepository.isProfileComplete(profile),
    orElse: () => false,
  );
});

// ──────────────────────────────────────────
// PROFILE EDITING CONTROLLER
// ──────────────────────────────────────────

final profileEditingControllerProvider =
    NotifierProvider<ProfileEditingController, AsyncValue<void>>(
        ProfileEditingController.new);

class ProfileEditingController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<bool> updateProfile(UserProfile updatedProfile) async {
    state = const AsyncLoading();
    try {
      await ref.read(profileRepositoryProvider).updateProfile(updatedProfile);
      
      ref.invalidate(userProfileProvider);
      
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
