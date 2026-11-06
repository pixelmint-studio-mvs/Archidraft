import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/api/providers/api_providers.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../data/repositories/archi_draft_pixmint_bot_repository.dart';
import '../data/repositories/mock_pixmint_bot_repository.dart';
import '../domain/models/bot_user_role.dart';
import '../domain/models/chat_suggestion.dart';
import '../domain/models/pixmint_default_suggestions.dart';
import '../domain/repositories/pixmint_bot_repository.dart';
import 'pixmint_chat_controller.dart';

/// Helper mapping an authenticated ARCHI DRAFT user role to PIXMINT BOT role.
BotUserRole mapProfileRoleToBotUserRole(String? rawRole) {
  if (rawRole == null) return BotUserRole.engineer;
  final upper = rawRole.toUpperCase();
  switch (upper) {
    case 'CLIENT':
    case 'ENGINEER':
      return BotUserRole.engineer;
    case 'DRAUGHTSMAN':
      return BotUserRole.draughtsman;
    case 'STUDENT':
      return BotUserRole.student;
    case 'ADMIN':
    case 'STUDIO_ADMIN':
      return BotUserRole.admin;
    default:
      return BotUserRole.engineer;
  }
}

/// Base URL for the integrated ARCHI DRAFT Cloudflare Worker API.
final pixmintApiBaseUrlProvider = Provider<String>((ref) {
  return ref.watch(apiClientProvider).baseUrl;
});

/// Firebase Auth Bearer token provider for authenticated requests.
final pixmintAuthTokenProvider = FutureProvider<String?>((ref) async {
  final auth = ref.watch(firebaseAuthProvider);
  final user = auth.currentUser;
  if (user == null) return null;
  return user.getIdToken();
});

/// Controls whether PIXMINT BOT connects to the remote Worker API or local verified engine.
class PixmintUseRemoteNotifier extends Notifier<bool> {
  @override
  bool build() {
    return const bool.fromEnvironment('PIXMINT_USE_REMOTE', defaultValue: true);
  }

  void setUseRemote(bool value) => state = value;
}

final pixmintUseRemoteProvider =
    NotifierProvider<PixmintUseRemoteNotifier, bool>(PixmintUseRemoteNotifier.new);

/// Optional override for testing or manual role previewing.
class PixmintOverrideRoleNotifier extends Notifier<BotUserRole?> {
  @override
  BotUserRole? build() => null;

  void setRole(BotUserRole? role) => state = role;
}

final pixmintOverrideRoleProvider =
    NotifierProvider<PixmintOverrideRoleNotifier, BotUserRole?>(PixmintOverrideRoleNotifier.new);

/// Authoritative user role driving PIXMINT BOT context and suggestions.
final pixmintRoleProvider = Provider<BotUserRole>((ref) {
  final override = ref.watch(pixmintOverrideRoleProvider);
  if (override != null) return override;

  final profileAsync = ref.watch(userProfileProvider);
  final profile = profileAsync.value;
  if (profile != null) {
    return mapProfileRoleToBotUserRole(profile.role);
  }
  return BotUserRole.engineer;
});

/// Production provider for [PixmintBotRepository].
final pixmintRepositoryProvider = Provider<PixmintBotRepository>((ref) {
  final useRemote = ref.watch(pixmintUseRemoteProvider);
  if (useRemote) {
    final baseUrl = ref.watch(pixmintApiBaseUrlProvider);
    final auth = ref.watch(firebaseAuthProvider);
    return ArchiDraftPixmintBotRepository(
      baseUrl: baseUrl,
      authTokenGetter: () async {
        final user = auth.currentUser;
        if (user == null) return null;
        return user.getIdToken();
      },
    );
  }
  return MockPixmintBotRepository();
});

/// Suggestions provider tailored to the current authenticated role.
final pixmintSuggestionsProvider = FutureProvider<List<ChatSuggestion>>((ref) async {
  final repository = ref.watch(pixmintRepositoryProvider);
  final role = ref.watch(pixmintRoleProvider);
  try {
    final suggestions = await repository.getSuggestions(role);
    if (suggestions.isNotEmpty) return suggestions;
  } catch (_) {}
  return PixmintDefaultSuggestions.getForRole(role);
});

/// Main controller managing chat conversation state and lifecycle.
final pixmintChatControllerProvider =
    NotifierProvider<PixmintChatController, PixmintChatState>(
  PixmintChatController.new,
);
