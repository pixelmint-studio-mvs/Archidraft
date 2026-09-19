class AdminDashboardMetrics {
  final int totalProjects;
  final int activeProjects;
  final int projectsAwaitingAssignment;
  final int projectsUnderClientReview;
  final int completedProjects;
  final int activeDraughtsmen;
  final int pendingAssignments;

  const AdminDashboardMetrics({
    required this.totalProjects,
    required this.activeProjects,
    required this.projectsAwaitingAssignment,
    required this.projectsUnderClientReview,
    required this.completedProjects,
    required this.activeDraughtsmen,
    required this.pendingAssignments,
  });

  factory AdminDashboardMetrics.fromMap(Map<String, dynamic> map) {
    return AdminDashboardMetrics(
      totalProjects: map['totalProjects'] as int? ?? 0,
      activeProjects: map['activeProjects'] as int? ?? 0,
      projectsAwaitingAssignment:
          map['projectsAwaitingAssignment'] as int? ?? 0,
      projectsUnderClientReview: map['projectsUnderClientReview'] as int? ?? 0,
      completedProjects: map['completedProjects'] as int? ?? 0,
      activeDraughtsmen: map['activeDraughtsmen'] as int? ?? 0,
      pendingAssignments: map['pendingAssignments'] as int? ?? 0,
    );
  }
}
