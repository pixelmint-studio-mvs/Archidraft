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

  String get action => actionType;
  DateTime get timestamp => createdAt;

  dynamic operator [](String key) {
    switch (key) {
      case 'id': return id;
      case 'project_id': return projectId;
      case 'project_name': return projectName;
      case 'action_type': return actionType;
      case 'actor_id': return actorId;
      case 'actor_role': return actorRole;
      case 'details': return details;
      case 'timestamp': return createdAt.toIso8601String();
      case 'created_at': return createdAt.toIso8601String();
      default: return null;
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'project_id': projectId,
    'project_name': projectName,
    'action_type': actionType,
    'actor_id': actorId,
    'actor_role': actorRole,
    'details': details,
    'timestamp': createdAt.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };


  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    // D1 activity_logs table uses 'timestamp' column (not 'created_at').
    // Fall back to 'created_at' for forward compatibility, then epoch if both null.
    final rawTs = json['timestamp'] ?? json['created_at'];
    final createdAt = rawTs != null
        ? DateTime.tryParse('${rawTs}Z')?.toLocal() ?? DateTime.now()
        : DateTime.now();
    return ActivityLog(
      id: json['id']?.toString() ?? '',
      projectId: json['project_id']?.toString() ?? '',
      projectName: json['project_name']?.toString(),
      actionType: json['action_type']?.toString() ?? '',
      actorId: json['actor_id']?.toString() ?? '',
      actorRole: json['actor_role'] == 'CLIENT' ? 'ENGINEER' : (json['actor_role']?.toString() ?? ''),
      details: json['details']?.toString() ?? '',
      createdAt: createdAt,
    );
  }
}
