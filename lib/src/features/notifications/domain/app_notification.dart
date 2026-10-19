import '../../../shared/utils/date_parser.dart';

class AppNotification {
  final String id;
  final String userId;
  final String? projectId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    this.projectId,
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
      projectId: map['project_id'] ?? map['projectId'],
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      isRead: map['is_read'] == 1 || map['is_read'] == true,
      createdAt: DateParser.parse(map['created_at']) ?? DateTime.now(),
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification.fromMap(json);

  AppNotification copyWith({
    String? id,
    String? userId,
    String? projectId,
    String? type,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      projectId: projectId ?? this.projectId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'project_id': projectId,
      'type': type,
      'title': title,
      'message': message,
      'is_read': isRead ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
