import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/providers/api_providers.dart';
import '../data/notification_repository.dart';
import '../domain/app_notification.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(apiClientProvider));
});

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotifications();
});

final markNotificationReadProvider = FutureProvider.family<void, String>((ref, id) async {
  final repository = ref.watch(notificationRepositoryProvider);
  await repository.markAsRead(id);
  ref.invalidate(notificationsProvider);
});
