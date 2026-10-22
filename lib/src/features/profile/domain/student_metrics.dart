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
  final StudentReadiness? readiness;
  final List<DisciplineCompetency> disciplines;

  StudentMetrics({
    required this.learning,
    required this.practical,
    required this.activity,
    this.readiness,
    this.disciplines = const [],
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
      activity: json['activity'] != null
          ? ActivityMetric.fromJson(json['activity'] as Map<String, dynamic>)
          : ActivityMetric(completedProjects: 0, correctionRounds: 0),
      readiness: json['readiness'] != null
          ? StudentReadiness.fromJson(json['readiness'] as Map<String, dynamic>)
          : null,
      disciplines: (json['disciplines'] as List<dynamic>?)
              ?.map((e) => DisciplineCompetency.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ReadinessCurriculum {
  final int completedLessons;
  final int totalLessons;
  final int percentage;

  ReadinessCurriculum({
    required this.completedLessons,
    required this.totalLessons,
    required this.percentage,
  });

  factory ReadinessCurriculum.fromJson(Map<String, dynamic> json) {
    return ReadinessCurriculum(
      completedLessons: (json['completedLessons'] as num?)?.toInt() ?? 0,
      totalLessons: (json['totalLessons'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toInt() ?? 0,
    );
  }
}

class ReadinessPractical {
  final int completedProjects;
  final int approvedDeliverables;

  ReadinessPractical({
    required this.completedProjects,
    required this.approvedDeliverables,
  });

  factory ReadinessPractical.fromJson(Map<String, dynamic> json) {
    return ReadinessPractical(
      completedProjects: (json['completedProjects'] as num?)?.toInt() ?? 0,
      approvedDeliverables: (json['approvedDeliverables'] as num?)?.toInt() ?? 0,
    );
  }
}

class ReadinessPrecision {
  final double? averageScore;
  final double maxScore;
  final double? accuracyScore;
  final double? standardsScore;
  final int evaluationCount;

  ReadinessPrecision({
    this.averageScore,
    required this.maxScore,
    this.accuracyScore,
    this.standardsScore,
    required this.evaluationCount,
  });

  factory ReadinessPrecision.fromJson(Map<String, dynamic> json) {
    return ReadinessPrecision(
      averageScore: (json['averageScore'] as num?)?.toDouble(),
      maxScore: (json['maxScore'] as num?)?.toDouble() ?? 5.0,
      accuracyScore: (json['accuracyScore'] as num?)?.toDouble(),
      standardsScore: (json['standardsScore'] as num?)?.toDouble(),
      evaluationCount: (json['evaluationCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class ReadinessRevision {
  final int correctionsIssued;
  final int correctionsResolved;
  final int resolutionRate;
  final int totalRounds;

  ReadinessRevision({
    required this.correctionsIssued,
    required this.correctionsResolved,
    required this.resolutionRate,
    required this.totalRounds,
  });

  factory ReadinessRevision.fromJson(Map<String, dynamic> json) {
    return ReadinessRevision(
      correctionsIssued: (json['correctionsIssued'] as num?)?.toInt() ?? 0,
      correctionsResolved: (json['correctionsResolved'] as num?)?.toInt() ?? 0,
      resolutionRate: (json['resolutionRate'] as num?)?.toInt() ?? 0,
      totalRounds: (json['totalRounds'] as num?)?.toInt() ?? 0,
    );
  }
}

class StudentReadiness {
  final ReadinessCurriculum curriculum;
  final ReadinessPractical practical;
  final ReadinessPrecision precision;
  final ReadinessRevision revision;

  StudentReadiness({
    required this.curriculum,
    required this.practical,
    required this.precision,
    required this.revision,
  });

  factory StudentReadiness.fromJson(Map<String, dynamic> json) {
    return StudentReadiness(
      curriculum: ReadinessCurriculum.fromJson(
        (json['curriculum'] as Map<String, dynamic>?) ?? {},
      ),
      practical: ReadinessPractical.fromJson(
        (json['practical'] as Map<String, dynamic>?) ?? {},
      ),
      precision: ReadinessPrecision.fromJson(
        (json['precision'] as Map<String, dynamic>?) ?? {},
      ),
      revision: ReadinessRevision.fromJson(
        (json['revision'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }
}

class DisciplineCompetency {
  final String discipline;
  final String state; // 'Not Started' | 'Foundational Study' | 'Practical Evidence Demonstrated'
  final int completedLessons;
  final int totalLessons;
  final int completedProjects;
  final double? evaluationScore;

  DisciplineCompetency({
    required this.discipline,
    required this.state,
    required this.completedLessons,
    required this.totalLessons,
    required this.completedProjects,
    this.evaluationScore,
  });

  factory DisciplineCompetency.fromJson(Map<String, dynamic> json) {
    return DisciplineCompetency(
      discipline: json['discipline'] as String? ?? '',
      state: json['state'] as String? ?? 'Not Started',
      completedLessons: (json['completedLessons'] as num?)?.toInt() ?? 0,
      totalLessons: (json['totalLessons'] as num?)?.toInt() ?? 0,
      completedProjects: (json['completedProjects'] as num?)?.toInt() ?? 0,
      evaluationScore: (json['evaluationScore'] as num?)?.toDouble(),
    );
  }
}
