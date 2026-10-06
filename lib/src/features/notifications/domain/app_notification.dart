import '../../../shared/utils/date_parser.dart';

class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      isRead: map['is_read'] == 1 || map['is_read'] == true,
      createdAt: DateParser.parse(map['created_at']) ?? DateTime.now(),
    );
  }
}
