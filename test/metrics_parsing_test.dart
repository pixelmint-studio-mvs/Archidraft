import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/profile/domain/student_metrics.dart';

void main() {
  test('Test parsing legacy/minimal activity metrics', () {
    final data = {
      "learning": [],
      "practical": [],
      "activity": {
        "completedProjects": 1,
        "correctionRounds": 0,
      }
    };
    final metrics = StudentMetrics.fromJson(data);
    expect(metrics.activity.completedProjects, 1);
    expect(metrics.activity.correctionRounds, 0);
    expect(metrics.readiness, isNull);
    expect(metrics.disciplines, isEmpty);
  });

  test('Test parsing complete Part 6 readiness and disciplines payload', () {
    final data = {
      "learning": [
        {
          "category": "Architectural",
          "completedLessons": 4,
          "totalLessons": 4,
          "percentage": 100
        }
      ],
      "practical": [
        {
          "name": "Accuracy",
          "score": 4.5,
          "maxScore": 5,
          "percentage": 90,
          "evaluationCount": 2
        }
      ],
      "activity": {
        "completedProjects": 2,
        "correctionRounds": 1
      },
      "readiness": {
        "curriculum": {
          "completedLessons": 12,
          "totalLessons": 16,
          "percentage": 75
        },
        "practical": {
          "completedProjects": 2,
          "approvedDeliverables": 2
        },
        "precision": {
          "averageScore": 4.6,
          "maxScore": 5.0,
          "accuracyScore": 4.5,
          "standardsScore": 4.7,
          "evaluationCount": 2
        },
        "revision": {
          "correctionsIssued": 3,
          "correctionsResolved": 3,
          "resolutionRate": 100,
          "totalRounds": 1
        }
      },
      "disciplines": [
        {
          "discipline": "Architectural",
          "state": "Practical Evidence Demonstrated",
          "completedLessons": 4,
          "totalLessons": 4,
          "completedProjects": 1,
          "evaluationScore": 4.8
        },
        {
          "discipline": "Interior",
          "state": "Foundational Study",
          "completedLessons": 2,
          "totalLessons": 3,
          "completedProjects": 0,
          "evaluationScore": null
        },
        {
          "discipline": "Structural",
          "state": "Not Started",
          "completedLessons": 0,
          "totalLessons": 3,
          "completedProjects": 0,
          "evaluationScore": null
        },
        {
          "discipline": "Municipal Approval",
          "state": "Not Started",
          "completedLessons": 0,
          "totalLessons": 2,
          "completedProjects": 0,
          "evaluationScore": null
        }
      ]
    };

    final metrics = StudentMetrics.fromJson(data);

    expect(metrics.readiness, isNotNull);
    final r = metrics.readiness!;
    expect(r.curriculum.completedLessons, 12);
    expect(r.curriculum.totalLessons, 16);
    expect(r.curriculum.percentage, 75);

    expect(r.practical.completedProjects, 2);
    expect(r.practical.approvedDeliverables, 2);

    expect(r.precision.averageScore, 4.6);
    expect(r.precision.maxScore, 5.0);
    expect(r.precision.accuracyScore, 4.5);
    expect(r.precision.standardsScore, 4.7);
    expect(r.precision.evaluationCount, 2);

    expect(r.revision.correctionsIssued, 3);
    expect(r.revision.correctionsResolved, 3);
    expect(r.revision.resolutionRate, 100);
    expect(r.revision.totalRounds, 1);

    expect(metrics.disciplines.length, 4);
    expect(metrics.disciplines[0].discipline, 'Architectural');
    expect(metrics.disciplines[0].state, 'Practical Evidence Demonstrated');
    expect(metrics.disciplines[0].evaluationScore, 4.8);
    expect(metrics.disciplines[1].discipline, 'Interior');
    expect(metrics.disciplines[1].state, 'Foundational Study');
    expect(metrics.disciplines[1].evaluationScore, isNull);
  });
}
