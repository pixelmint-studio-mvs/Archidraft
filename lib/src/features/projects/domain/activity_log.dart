class ActivityLog {
  final String id;
  final String projectId;
  final String actionType;
  final String actorId;
  final String actorRole;
  final String details;
  final DateTime createdAt;

  ActivityLog({
    required this.id,
    required this.projectId,
    required this.actionType,
    required this.actorId,
    required this.actorRole,
    required this.details,
    required this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'],
      projectId: json['project_id'],
      actionType: json['action_type'],
      actorId: json['actor_id'],
      actorRole: json['actor_role'],
      details: json['details'],
      createdAt: DateTime.parse(json['created_at'] + 'Z').toLocal(),
    );
  }
}
