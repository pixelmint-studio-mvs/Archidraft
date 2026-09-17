class NotificationModel {
  final String id;
  final String userId;
  final String? projectId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    this.projectId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      projectId: json['project_id'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      isRead: json['is_read'] == 1,
      createdAt: DateTime.parse(json['created_at'] + 'Z').toLocal(),
    );
  }
}
