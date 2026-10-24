import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../api/providers/api_providers.dart';
import '../data/legal_repository.dart';
import '../domain/legal_document.dart';
import '../domain/privacy_request.dart';
import '../domain/user_legal_status.dart';

final legalRepositoryProvider = Provider<LegalRepository>((ref) {
  return LegalRepository(ref.watch(apiClientProvider));
});

final userLegalStatusProvider = FutureProvider<UserLegalStatus>((ref) async {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;
  if (user == null) {
    return const UserLegalStatus(
      userId: '',
      termsAccepted: false,
      reacceptanceRequired: false,
      privacyNoticeAcknowledged: false,
      optionalConsents: {},
      requiresAction: false,
      hasEffectiveTerms: true,
      missingMandatoryDocs: false,
    );
  }
  return ref.watch(legalRepositoryProvider).getUserLegalStatus();
});

final effectiveDocumentProvider = FutureProvider.family<LegalDocument?, String>((ref, type) async {
  return ref.watch(legalRepositoryProvider).getDocument(type);
});

final effectiveDocumentsListProvider = FutureProvider<List<LegalDocument>>((ref) async {
  return ref.watch(legalRepositoryProvider).getEffectiveDocuments();
});

final myPrivacyRequestsProvider = FutureProvider<List<PrivacyRequest>>((ref) async {
  return ref.watch(legalRepositoryProvider).getMyPrivacyRequests();
});

/// Ephemeral in-memory state tracking Terms & Conditions acceptance per role-selection flow
class PreLoginTermsState {
  final String? role;
  final bool accepted;
  final DateTime? acceptedAt;
  final bool marketingConsent;
  final bool portfolioConsent;

  const PreLoginTermsState({
    this.role,
    this.accepted = false,
    this.acceptedAt,
    this.marketingConsent = false,
    this.portfolioConsent = false,
  });

  PreLoginTermsState copyWith({
    String? role,
    bool? accepted,
    DateTime? acceptedAt,
    bool? marketingConsent,
    bool? portfolioConsent,
  }) {
    return PreLoginTermsState(
      role: role ?? this.role,
      accepted: accepted ?? this.accepted,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      marketingConsent: marketingConsent ?? this.marketingConsent,
      portfolioConsent: portfolioConsent ?? this.portfolioConsent,
    );
  }
}

class PreLoginTermsNotifier extends Notifier<PreLoginTermsState> {
  @override
  PreLoginTermsState build() {
    return const PreLoginTermsState();
  }

  void selectRole(String role) {
    state = PreLoginTermsState(
      role: role.toUpperCase(),
      accepted: false,
    );
  }

  void acceptTerms({
    required String role,
    bool marketingConsent = false,
    bool portfolioConsent = false,
  }) {
    state = PreLoginTermsState(
      role: role.toUpperCase(),
      accepted: true,
      acceptedAt: DateTime.now(),
      marketingConsent: marketingConsent,
      portfolioConsent: portfolioConsent,
    );
  }

  void reset() {
    state = const PreLoginTermsState();
  }
}

final preLoginTermsProvider =
    NotifierProvider<PreLoginTermsNotifier, PreLoginTermsState>(
  PreLoginTermsNotifier.new,
);
