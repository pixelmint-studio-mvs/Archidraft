class StudentAchievement {
  final String id;
  final String title;
  final String description;
  final String category;
  final String icon;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int currentProgress;
  final int targetProgress;

  const StudentAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.isUnlocked,
    this.unlockedAt,
    required this.currentProgress,
    required this.targetProgress,
  });

  factory StudentAchievement.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawDate = json['unlockedAt'];
    if (rawDate != null && rawDate is String && rawDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawDate);
    }

    return StudentAchievement(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: parsedDate,
      currentProgress: (json['currentProgress'] as num?)?.toInt() ?? 0,
      targetProgress: (json['targetProgress'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'icon': icon,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'currentProgress': currentProgress,
      'targetProgress': targetProgress,
    };
  }
}
