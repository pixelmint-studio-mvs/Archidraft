class TrainingModule {
  final String id;
  final String title;
  final String category; // 'Architectural', 'Structural', 'Interior', 'Approval'
  final String type; // 'Mock Project', 'Masterclass', 'Module'
  final String level; // 'Beginner', 'Intermediate', 'Advanced', 'Pro'
  final String description;
  final String status; // 'Completed', 'In Progress', 'Locked', 'Not Started'
  final int? score; // e.g., 94 for Distinction
  final double progress; // 0.0 to 1.0
  final bool isLocked;
  final String? prerequisites;
  final String? imageUrl;
  final String? durationOrFormat; // e.g., "12 mins • Video"

  const TrainingModule({
    required this.id,
    required this.title,
    required this.category,
    required this.type,
    required this.level,
    required this.description,
    required this.status,
    this.score,
    this.progress = 0.0,
    this.isLocked = false,
    this.prerequisites,
    this.imageUrl,
    this.durationOrFormat,
  });

  factory TrainingModule.fromMap(Map<String, dynamic> data) {
    return TrainingModule(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? 'Untitled',
      category: data['category'] as String? ?? 'General',
      type: data['type'] as String? ?? 'Module',
      level: data['level'] as String? ?? 'Beginner',
      description: data['description'] as String? ?? '',
      status: data['status'] as String? ?? 'Not Started',
      score: data['score'] as int?,
      progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
      isLocked: data['is_locked'] == 1 || data['is_locked'] == true,
      prerequisites: data['prerequisites'] as String?,
      imageUrl: data['image_url'] as String?,
      durationOrFormat: data['duration_or_format'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'type': type,
      'level': level,
      'description': description,
      'status': status,
      'score': score,
      'progress': progress,
      'is_locked': isLocked,
      'prerequisites': prerequisites,
      'image_url': imageUrl,
      'duration_or_format': durationOrFormat,
    };
  }
}

class TrainingCategoryProgress {
  final String category;
  final double overallProgress;

  const TrainingCategoryProgress({
    required this.category,
    required this.overallProgress,
  });
}
