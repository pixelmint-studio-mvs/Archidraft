class LearningMetric {
  final String category;
  final int completedLessons;
  final int totalLessons;
  final int percentage;

  LearningMetric({
    required this.category,
    required this.completedLessons,
    required this.totalLessons,
    required this.percentage,
  });

  factory LearningMetric.fromJson(Map<String, dynamic> json) {
    return LearningMetric(
      category: json['category'] as String,
      completedLessons: json['completedLessons'] as int,
      totalLessons: json['totalLessons'] as int,
      percentage: json['percentage'] as int,
    );
  }
}

class PracticalMetric {
  final String name;
  final double score;
  final int maxScore;
  final int percentage;
  final int evaluationCount;

  PracticalMetric({
    required this.name,
    required this.score,
    required this.maxScore,
    required this.percentage,
    required this.evaluationCount,
  });

  factory PracticalMetric.fromJson(Map<String, dynamic> json) {
    return PracticalMetric(
      name: json['name'] as String,
      score: (json['score'] as num).toDouble(),
      maxScore: json['maxScore'] as int,
      percentage: json['percentage'] as int,
      evaluationCount: json['evaluationCount'] as int,
    );
  }
}

class ActivityMetric {
  final int completedProjects;
  final int correctionRounds;

  ActivityMetric({
    required this.completedProjects,
    required this.correctionRounds,
  });

  factory ActivityMetric.fromJson(Map<String, dynamic> json) {
    return ActivityMetric(
      completedProjects: json['completedProjects'] as int,
      correctionRounds: json['correctionRounds'] as int,
    );
  }
}

class StudentMetrics {
  final List<LearningMetric> learning;
  final List<PracticalMetric> practical;
  final ActivityMetric activity;

  StudentMetrics({
    required this.learning,
    required this.practical,
    required this.activity,
  });

  factory StudentMetrics.fromJson(Map<String, dynamic> json) {
    return StudentMetrics(
      learning: (json['learning'] as List<dynamic>?)
              ?.map((e) => LearningMetric.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      practical: (json['practical'] as List<dynamic>?)
              ?.map((e) => PracticalMetric.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      activity: ActivityMetric.fromJson(json['activity'] as Map<String, dynamic>),
    );
  }
}
