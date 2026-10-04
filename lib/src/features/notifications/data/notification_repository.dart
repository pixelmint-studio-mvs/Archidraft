import '../../api/data/api_client.dart';
import '../domain/app_notification.dart';

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await _apiClient.get('/api/notifications');
      if (response == null) return [];
      return (response as List).map((n) => AppNotification.fromMap(n)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAsRead(String id) async {
    await _apiClient.patch('/api/notifications/$id/read');
  }
}
