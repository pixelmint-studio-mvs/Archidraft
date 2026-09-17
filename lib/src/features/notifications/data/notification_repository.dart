import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/data/api_client.dart';
import '../../api/providers/api_providers.dart';
import '../domain/notification_model.dart';

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  Future<List<NotificationModel>> fetchNotifications() async {
    final response = await _apiClient.get('/api/notifications');
    if (response is List) {
      return response.map((json) => NotificationModel.fromJson(json)).toList();
    }
    throw Exception('Failed to fetch notifications');
  }

  Future<void> markAsRead(String id) async {
    await _apiClient.post('/api/notifications/$id/read');
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationRepository(apiClient);
});

final notificationsProvider = FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return await repository.fetchNotifications();
});
