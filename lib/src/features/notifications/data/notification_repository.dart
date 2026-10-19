import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/data/api_client.dart';
import '../../api/providers/api_providers.dart';
import '../domain/app_notification.dart';

export '../domain/app_notification.dart';

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await _apiClient.get('/api/notifications');
      if (response == null) return [];
      return (response as List).map((n) => AppNotification.fromMap(n as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<AppNotification>> fetchNotifications() => getNotifications();

  Future<void> markAsRead(String id) async {
    try {
      await _apiClient.patch('/api/notifications/$id/read');
    } catch (_) {
      await _apiClient.post('/api/notifications/$id/read');
    }
  }

  Future<void> markAllAsRead() async {
    await _apiClient.patch('/api/notifications/read-all');
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationRepository(apiClient);
});

final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return await repository.getNotifications();
});
