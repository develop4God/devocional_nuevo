// test/critical_coverage/spiritual_stats_model_test.dart
// High-value tests for SpiritualStats model - achievements and streaks

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/models/spiritual_stats_model.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

@Tags(['slow'])
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    ServiceLocator().reset();
    SharedPreferences.setMockInitialValues({});
    setupServiceLocator();
  });

  tearDownAll(() {
    ServiceLocator().reset();
  });

  group('SpiritualStats - Default Values', () {
    test('new SpiritualStats has zero values', () {
      final stats = SpiritualStats();

      expect(stats.totalDevocionalesRead, 0);
      expect(stats.currentStreak, 0);
      expect(stats.longestStreak, 0);
      expect(stats.favoritesCount, 0);
      expect(stats.readDevocionalIds, isEmpty);
      expect(stats.unlockedAchievements, isEmpty);
      expect(stats.lastActivityDate, isNull);
    });
  });

  group('SpiritualStats - CopyWith', () {
    test('copyWith updates totalDevocionalesRead', () {
      final stats = SpiritualStats();
      final updated = stats.copyWith(totalDevocionalesRead: 10);

      expect(updated.totalDevocionalesRead, 10);
      expect(updated.currentStreak, 0); // Unchanged
    });

    test('copyWith updates currentStreak', () {
      final stats = SpiritualStats();
      final updated = stats.copyWith(currentStreak: 5);

      expect(updated.currentStreak, 5);
    });

    test('copyWith updates longestStreak', () {
      final stats = SpiritualStats();
      final updated = stats.copyWith(longestStreak: 30);

      expect(updated.longestStreak, 30);
    });

    test('copyWith updates favoritesCount', () {
      final stats = SpiritualStats();
      final updated = stats.copyWith(favoritesCount: 15);

      expect(updated.favoritesCount, 15);
    });

    test('copyWith updates lastActivityDate', () {
      final stats = SpiritualStats();
      final now = DateTime.now();
      final updated = stats.copyWith(lastActivityDate: now);

      expect(updated.lastActivityDate, now);
    });

    test('copyWith updates readDevocionalIds', () {
      final stats = SpiritualStats();
      final updated = stats.copyWith(readDevocionalIds: ['dev1', 'dev2']);

      expect(updated.readDevocionalIds, ['dev1', 'dev2']);
    });

    test('copyWith preserves unchanged values', () {
      final stats = SpiritualStats(
        totalDevocionalesRead: 10,
        currentStreak: 5,
        longestStreak: 15,
        favoritesCount: 3,
      );
      final updated = stats.copyWith(currentStreak: 6);

      expect(updated.totalDevocionalesRead, 10);
      expect(updated.currentStreak, 6);
      expect(updated.longestStreak, 15);
      expect(updated.favoritesCount, 3);
    });
  });

  group('SpiritualStats - JSON Serialization', () {
    test('toJson serializes all fields', () {
      final stats = SpiritualStats(
        totalDevocionalesRead: 10,
        currentStreak: 5,
        longestStreak: 15,
        favoritesCount: 3,
        readDevocionalIds: ['dev1', 'dev2'],
      );

      final json = stats.toJson();

      expect(json['totalDevocionalesRead'], 10);
      expect(json['currentStreak'], 5);
      expect(json['longestStreak'], 15);
      expect(json['favoritesCount'], 3);
      expect(json['readDevocionalIds'], ['dev1', 'dev2']);
    });

    test('fromJson deserializes all fields', () {
      final json = {
        'totalDevocionalesRead': 10,
        'currentStreak': 5,
        'longestStreak': 15,
        'favoritesCount': 3,
        'readDevocionalIds': ['dev1', 'dev2'],
        'unlockedAchievements': [],
        'lastActivityDate': null,
      };

      final stats = SpiritualStats.fromJson(json);

      expect(stats.totalDevocionalesRead, 10);
      expect(stats.currentStreak, 5);
      expect(stats.longestStreak, 15);
      expect(stats.favoritesCount, 3);
      expect(stats.readDevocionalIds, ['dev1', 'dev2']);
    });

    test('fromJson handles missing fields gracefully', () {
      final json = <String, dynamic>{};

      final stats = SpiritualStats.fromJson(json);

      expect(stats.totalDevocionalesRead, 0);
      expect(stats.currentStreak, 0);
    });

    test('round-trip serialization preserves data', () {
      final original = SpiritualStats(
        totalDevocionalesRead: 100,
        currentStreak: 7,
        longestStreak: 30,
        favoritesCount: 25,
        readDevocionalIds: ['a', 'b', 'c'],
      );

      final json = original.toJson();
      final restored = SpiritualStats.fromJson(json);

      expect(restored.totalDevocionalesRead, original.totalDevocionalesRead);
      expect(restored.currentStreak, original.currentStreak);
      expect(restored.longestStreak, original.longestStreak);
      expect(restored.favoritesCount, original.favoritesCount);
    });
  });

  group('Achievement - Model Tests', () {
    test('Achievement has all required properties', () {
      final achievement = Achievement(
        id: 'first_reading',
        title: 'First Reading',
        description: 'Read your first devotional',
        icon: Icons.book,
        color: Colors.amber,
        threshold: 1,
        type: AchievementType.reading,
      );

      expect(achievement.id, 'first_reading');
      expect(achievement.title, 'First Reading');
      expect(achievement.description, 'Read your first devotional');
      expect(achievement.threshold, 1);
      expect(achievement.type, AchievementType.reading);
      expect(achievement.isUnlocked, false);
    });

    test('Achievement copyWith updates isUnlocked', () {
      final achievement = Achievement(
        id: 'test',
        title: 'Test',
        description: 'Test',
        icon: Icons.star,
        color: Colors.blue,
        threshold: 1,
        type: AchievementType.reading,
      );

      final unlocked = achievement.copyWith(isUnlocked: true);

      expect(unlocked.isUnlocked, true);
      expect(unlocked.id, achievement.id);
    });
  });

  group('AchievementType - Enum Tests', () {
    test('AchievementType has all expected values', () {
      expect(AchievementType.values, contains(AchievementType.reading));
      expect(AchievementType.values, contains(AchievementType.streak));
      expect(AchievementType.values, contains(AchievementType.favorites));
    });

    test('AchievementType has exactly 3 values', () {
      expect(AchievementType.values, hasLength(3));
    });
  });

  group('PredefinedAchievements - Constants', () {
    test('PredefinedAchievements.all is not empty', () {
      expect(PredefinedAchievements.all, isNotEmpty);
    });

    test('all achievements have unique IDs', () {
      final ids = PredefinedAchievements.all.map((a) => a.id).toSet();
      expect(ids.length, PredefinedAchievements.all.length);
    });

    test('all achievements have positive thresholds', () {
      for (final achievement in PredefinedAchievements.all) {
        expect(achievement.threshold, greaterThan(0));
      }
    });

    test('all achievements have non-empty titles', () {
      for (final achievement in PredefinedAchievements.all) {
        expect(achievement.title, isNotEmpty);
      }
    });

    test('all achievements have non-empty descriptions', () {
      for (final achievement in PredefinedAchievements.all) {
        expect(achievement.description, isNotEmpty);
      }
    });

    test('achievements are initially locked', () {
      for (final achievement in PredefinedAchievements.all) {
        expect(achievement.isUnlocked, false);
      }
    });
  });

  group('Achievement JSON Serialization', () {
    test('Achievement toJson serializes all fields', () {
      final achievement = Achievement(
        id: 'test',
        title: 'Test Achievement',
        description: 'Test description',
        icon: Icons.star,
        color: Colors.amber,
        threshold: 5,
        type: AchievementType.streak,
        isUnlocked: true,
      );

      final json = achievement.toJson();

      expect(json['id'], 'test');
      expect(json['title'], 'Test Achievement');
      expect(json['description'], 'Test description');
      expect(json['threshold'], 5);
      expect(json['isUnlocked'], true);
    });

    test('Achievement fromJson deserializes all fields', () {
      final json = {
        'id': 'test',
        'title': 'Test Achievement',
        'description': 'Test description',
        'iconCodePoint': Icons.star.codePoint,
        'colorValue': 0xFFFFC107, // Colors.amber color value
        'threshold': 5,
        'type': 'AchievementType.streak',
        'isUnlocked': true,
      };

      final achievement = Achievement.fromJson(json);

      expect(achievement.id, 'test');
      expect(achievement.title, 'Test Achievement');
      expect(achievement.threshold, 5);
      expect(achievement.type, AchievementType.streak);
      expect(achievement.isUnlocked, true);
    });
  });

  group('SpiritualStats - Achievement Tracking', () {
    test('stats can store unlocked achievements', () {
      final achievement = Achievement(
        id: 'first',
        title: 'First',
        description: 'First desc',
        icon: Icons.star,
        color: Colors.amber,
        threshold: 1,
        type: AchievementType.reading,
        isUnlocked: true,
      );

      final stats = SpiritualStats(unlockedAchievements: [achievement]);

      expect(stats.unlockedAchievements, hasLength(1));
      expect(stats.unlockedAchievements.first.isUnlocked, true);
    });

    test('stats can track multiple achievements', () {
      final achievements = <Achievement>[
        Achievement(
          id: '1',
          title: 'A1',
          description: 'D1',
          icon: Icons.star,
          color: Colors.amber,
          threshold: 1,
          type: AchievementType.reading,
          isUnlocked: true,
        ),
        Achievement(
          id: '2',
          title: 'A2',
          description: 'D2',
          icon: Icons.star,
          color: Colors.blue,
          threshold: 5,
          type: AchievementType.streak,
          isUnlocked: true,
        ),
        Achievement(
          id: '3',
          title: 'A3',
          description: 'D3',
          icon: Icons.star,
          color: Colors.green,
          threshold: 10,
          type: AchievementType.favorites,
          isUnlocked: true,
        ),
      ];

      final stats = SpiritualStats(unlockedAchievements: achievements);

      expect(stats.unlockedAchievements, hasLength(3));
    });
  });

  group('SpiritualStats - Edge Cases', () {
    test('handles empty readDevocionalIds', () {
      final stats = SpiritualStats(readDevocionalIds: []);
      expect(stats.readDevocionalIds, isEmpty);
    });

    test('handles null lastActivityDate', () {
      final stats = SpiritualStats();
      expect(stats.lastActivityDate, isNull);
    });

    test('handles large numbers', () {
      final stats = SpiritualStats(
        totalDevocionalesRead: 999999,
        currentStreak: 365,
        longestStreak: 1000,
        favoritesCount: 50000,
      );

      expect(stats.totalDevocionalesRead, 999999);
      expect(stats.currentStreak, 365);
    });
  });
}
