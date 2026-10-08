import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:archi_draft/src/features/api/providers/api_providers.dart';
import '../data/credentials_repository.dart';
import '../domain/student_credential.dart';

final credentialsRepositoryProvider = Provider<CredentialsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CredentialsRepository(apiClient);
});

final studentCredentialsProvider = FutureProvider.autoDispose<List<StudentCredential>>((ref) {
  final repository = ref.watch(credentialsRepositoryProvider);
  return repository.getStudentCredentials();
});
