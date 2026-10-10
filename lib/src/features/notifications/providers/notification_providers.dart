import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/providers/api_providers.dart';
import '../data/notification_repository.dart';
import '../domain/app_notification.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(apiClientProvider));
});

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  
  // Simple production-appropriate live-refresh via polling
  final timer = Timer.periodic(const Duration(seconds: 30), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  return repository.getNotifications();
});

final markNotificationReadProvider = FutureProvider.family<void, String>((ref, id) async {
  final repository = ref.watch(notificationRepositoryProvider);
  await repository.markAsRead(id);
  ref.invalidate(notificationsProvider);
});

final markAllNotificationsReadProvider = FutureProvider<void>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  await repository.markAllAsRead();
  ref.invalidate(notificationsProvider);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final async = ref.watch(notificationsProvider);
  return async.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

