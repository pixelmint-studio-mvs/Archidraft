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

  static String normalizeCategory(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Architectural';
    final trimmed = raw.trim();
    final lower = trimmed.toLowerCase();

    // Structural matches (including Reinforced Concrete, RCC, Civil, Steel, Rebar)
    if (lower.contains('structur') ||
        lower.contains('concrete') ||
        lower.contains('rcc') ||
        lower.contains('civil') ||
        lower.contains('steel') ||
        lower.contains('rebar') ||
        lower.contains('foundation')) {
      return 'Structural';
    }

    // Architectural matches (Floor Plan, Elevation, Section, CAD Drafting)
    if (lower.contains('architect') ||
        lower.contains('floor plan') ||
        lower.contains('elevation') ||
        lower.contains('section') ||
        lower.contains('drafting') ||
        lower.contains('layout')) {
      return 'Architectural';
    }

    // Interior matches (Space Planning, Furniture, Interior Detailing)
    if (lower.contains('interior') ||
        lower.contains('space plan') ||
        lower.contains('furniture') ||
        lower.contains('decor')) {
      return 'Interior';
    }

    // Approval matches (Bylaws, Sanctions, Building Codes, Permits)
    if (lower.contains('approval') ||
        lower.contains('sanction') ||
        lower.contains('permit') ||
        lower.contains('code') ||
        lower.contains('bylaw') ||
        lower.contains('authority')) {
      return 'Approval';
    }

    if (lower == 'architectural') return 'Architectural';
    if (lower == 'structural') return 'Structural';
    if (lower == 'interior') return 'Interior';
    if (lower == 'approval') return 'Approval';

    return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
  }

  static String normalizeType(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Module';
    final lower = raw.trim().toLowerCase();
    if (lower.contains('mock') || lower.contains('project')) {
      return 'Mock Project';
    }
    if (lower.contains('masterclass')) {
      return 'Masterclass';
    }
    return 'Module';
  }

  static String normalizeStatus(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Not Started';
    final lower = raw.trim().toLowerCase();
    if (lower == 'completed') return 'Completed';
    if (lower == 'in progress' || lower == 'in_progress') return 'In Progress';
    if (lower == 'locked') return 'Locked';
    return 'Not Started';
  }

  factory TrainingModule.fromMap(Map<String, dynamic> data) {
    return TrainingModule(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? 'Untitled',
      category: normalizeCategory(data['category'] as String?),
      type: normalizeType(data['type'] as String?),
      level: data['level'] as String? ?? 'Beginner',
      description: data['description'] as String? ?? '',
      status: normalizeStatus(data['status'] as String?),
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
