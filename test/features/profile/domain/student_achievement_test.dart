import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/profile/domain/student_achievement.dart';

void main() {
  group('StudentAchievement Domain Model Tests', () {
    test('Correctly parses unlocked achievement JSON with date and progress', () {
      final json = {
        'id': 'first_lesson_completed',
        'title': 'First Blueprint Step',
        'description': 'Completed your first training lesson',
        'category': 'LEARNING',
        'icon': 'school_outlined',
        'isUnlocked': true,
        'unlockedAt': '2026-10-06T15:30:00.000Z',
        'currentProgress': 1,
        'targetProgress': 1,
      };

      final achievement = StudentAchievement.fromJson(json);

      expect(achievement.id, 'first_lesson_completed');
      expect(achievement.title, 'First Blueprint Step');
      expect(achievement.description, 'Completed your first training lesson');
      expect(achievement.category, 'LEARNING');
      expect(achievement.icon, 'school_outlined');
      expect(achievement.isUnlocked, isTrue);
      expect(achievement.unlockedAt, isNotNull);
      expect(achievement.unlockedAt!.toUtc().year, 2026);
      expect(achievement.unlockedAt!.toUtc().month, 10);
      expect(achievement.unlockedAt!.toUtc().day, 6);
      expect(achievement.currentProgress, 1);
      expect(achievement.targetProgress, 1);
    });

    test('Correctly parses locked achievement JSON where unlockedAt is null', () {
      final json = {
        'id': 'studio_ready',
        'title': 'Studio Ready',
        'description': 'Completed your first practical project assignment',
        'category': 'PRACTICAL',
        'icon': 'assignment_turned_in_outlined',
        'isUnlocked': false,
        'unlockedAt': null,
        'currentProgress': 0,
        'targetProgress': 1,
      };

      final achievement = StudentAchievement.fromJson(json);

      expect(achievement.id, 'studio_ready');
      expect(achievement.title, 'Studio Ready');
      expect(achievement.isUnlocked, isFalse);
      expect(achievement.unlockedAt, isNull);
      expect(achievement.currentProgress, 0);
      expect(achievement.targetProgress, 1);
    });

    test('Gracefully handles missing or null optional fields', () {
      final json = <String, dynamic>{
        'id': 'partial_badge',
      };

      final achievement = StudentAchievement.fromJson(json);

      expect(achievement.id, 'partial_badge');
      expect(achievement.title, '');
      expect(achievement.description, '');
      expect(achievement.category, '');
      expect(achievement.icon, '');
      expect(achievement.isUnlocked, isFalse);
      expect(achievement.unlockedAt, isNull);
      expect(achievement.currentProgress, 0);
      expect(achievement.targetProgress, 1);
    });

    test('toJson serializes correctly', () {
      final date = DateTime.utc(2026, 10, 8, 12, 0, 0);
      final achievement = StudentAchievement(
        id: 'first_credential_earned',
        title: 'Certified Draughtsman',
        description: 'Earned your first official course or project credential',
        category: 'ACHIEVEMENT',
        icon: 'military_tech_outlined',
        isUnlocked: true,
        unlockedAt: date,
        currentProgress: 1,
        targetProgress: 1,
      );

      final map = achievement.toJson();

      expect(map['id'], 'first_credential_earned');
      expect(map['title'], 'Certified Draughtsman');
      expect(map['isUnlocked'], true);
      expect(map['unlockedAt'], date.toIso8601String());
      expect(map['currentProgress'], 1);
      expect(map['targetProgress'], 1);
    });
  });
}
