import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(FirebaseAuth.instance);
});

final authHeadersProvider = FutureProvider<Map<String, String>>((ref) async {
  return ref.watch(apiClientProvider).getAuthHeaders();
});
