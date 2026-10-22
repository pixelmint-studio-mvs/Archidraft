import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/providers/api_providers.dart';
import '../data/legal_repository.dart';
import '../domain/legal_document.dart';
import '../domain/privacy_request.dart';
import '../domain/user_legal_status.dart';

final legalRepositoryProvider = Provider<LegalRepository>((ref) {
  return LegalRepository(ref.watch(apiClientProvider));
});

final userLegalStatusProvider = FutureProvider<UserLegalStatus>((ref) async {
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
