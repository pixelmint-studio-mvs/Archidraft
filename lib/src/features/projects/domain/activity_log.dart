class ActivityLog {
  final String id;
  final String projectId;
  final String? projectName;
  final String actionType;
  final String actorId;
  final String actorRole;
  final String details;
  final DateTime createdAt;

  ActivityLog({
    required this.id,
    required this.projectId,
    this.projectName,
    required this.actionType,
    required this.actorId,
    required this.actorRole,
    required this.details,
    required this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    // D1 activity_logs table uses 'timestamp' column (not 'created_at').
    // Fall back to 'created_at' for forward compatibility, then epoch if both null.
    final rawTs = json['timestamp'] ?? json['created_at'];
    final createdAt = rawTs != null
        ? DateTime.tryParse('${rawTs}Z')?.toLocal() ?? DateTime.now()
        : DateTime.now();
    return ActivityLog(
      id: json['id'],
      projectId: json['project_id'],
      projectName: json['project_name'],
      actionType: json['action_type'],
      actorId: json['actor_id'],
      actorRole: json['actor_role'] == 'CLIENT' ? 'ENGINEER' : (json['actor_role'] ?? ''),
      details: json['details'] ?? '',
      createdAt: createdAt,
    );
  }
}
