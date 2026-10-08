class PortfolioProject {
  final String projectId;
  final String projectName;
  final String drawingType;
  final String projectArea;
  final bool isTrainingProject;
  final DateTime? approvedAt;
  final PortfolioFinalDrawing? finalDrawing;
  final PortfolioEvaluation evaluation;

  PortfolioProject({
    required this.projectId,
    required this.projectName,
    required this.drawingType,
    required this.projectArea,
    required this.isTrainingProject,
    this.approvedAt,
    this.finalDrawing,
    required this.evaluation,
  });

  factory PortfolioProject.fromJson(Map<String, dynamic> json) {
    return PortfolioProject(
      projectId: json['projectId'] as String,
      projectName: json['projectName'] as String,
      drawingType: json['drawingType'] as String,
      projectArea: json['projectArea'] as String,
      isTrainingProject: json['isTrainingProject'] as bool,
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt'] as String) : null,
      finalDrawing: json['finalDrawing'] != null
          ? PortfolioFinalDrawing.fromJson(json['finalDrawing'] as Map<String, dynamic>)
          : null,
      evaluation: PortfolioEvaluation.fromJson(json['evaluation'] as Map<String, dynamic>),
    );
  }
}

class PortfolioFinalDrawing {
  final String fileId;
  final String sanitizedName;
  final String downloadUrl;

  PortfolioFinalDrawing({
    required this.fileId,
    required this.sanitizedName,
    required this.downloadUrl,
  });

  factory PortfolioFinalDrawing.fromJson(Map<String, dynamic> json) {
    return PortfolioFinalDrawing(
      fileId: json['fileId'] as String,
      sanitizedName: json['sanitizedName'] as String,
      downloadUrl: json['downloadUrl'] as String,
    );
  }
}

class PortfolioEvaluation {
  final String result;
  final List<PortfolioCriterion> criteria;
  final int overallPercentage;
  final String? generalFeedback;

  PortfolioEvaluation({
    required this.result,
    required this.criteria,
    required this.overallPercentage,
    this.generalFeedback,
  });

  factory PortfolioEvaluation.fromJson(Map<String, dynamic> json) {
    return PortfolioEvaluation(
      result: json['result'] as String,
      criteria: (json['criteria'] as List<dynamic>?)
              ?.map((e) => PortfolioCriterion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      overallPercentage: json['overallPercentage'] as int? ?? 0,
      generalFeedback: json['generalFeedback'] as String?,
    );
  }
}

class PortfolioCriterion {
  final String name;
  final int score;
  final int maxScore;

  PortfolioCriterion({
    required this.name,
    required this.score,
    required this.maxScore,
  });

  factory PortfolioCriterion.fromJson(Map<String, dynamic> json) {
    return PortfolioCriterion(
      name: json['name'] as String,
      score: (json['score'] as num).toInt(),
      maxScore: (json['maxScore'] as num).toInt(),
    );
  }
}
