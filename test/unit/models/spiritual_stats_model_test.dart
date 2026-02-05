@Tags(['unit', 'models'])
library;

import 'package:devocional_nuevo/models/spiritual_stats_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpiritualStats Model Tests', () {
    test('should create and serialize SpiritualStats correctly', () {
      // Test creation with custom values
      final lastActivity = DateTime(2024, 1, 15, 10, 30);
      final readIds = ['dev_1', 'dev_2', 'dev_3'];
      final achievements = <Achievement>[];

      final stats = SpiritualStats(
        totalDevocionalesRead: 15,
        currentStreak: 7,
        longestStreak: 12,
        lastActivityDate: lastActivity,
        favoritesCount: 5,
        readDevocionalIds: readIds,
        unlockedAchievements: achievements,
      );

      // Verify properties
      expect(stats.totalDevocionalesRead, equals(15));
      expect(stats.currentStreak, equals(7));
      expect(stats.longestStreak, equals(12));
      expect(stats.lastActivityDate, equals(lastActivity));
      expect(stats.favoritesCount, equals(5));
      expect(stats.readDevocionalIds, equals(readIds));
      expect(stats.unlockedAchievements, equals(achievements));

      // Test serialization/deserialization
      final json = stats.toJson();
      final statsFromJson = SpiritualStats.fromJson(json);
      expect(
        statsFromJson.totalDevocionalesRead,
        equals(stats.totalDevocionalesRead),
      );
      expect(statsFromJson.currentStreak, equals(stats.currentStreak));
      expect(statsFromJson.readDevocionalIds, equals(stats.readDevocionalIds));
    });

    test('should create SpiritualStats with default values', () {
      final stats = SpiritualStats();
      expect(stats.totalDevocionalesRead, equals(0));
      expect(stats.currentStreak, equals(0));
      expect(stats.longestStreak, equals(0));
      expect(stats.lastActivityDate, isNull);
      expect(stats.unlockedAchievements, isEmpty);
      expect(stats.favoritesCount, equals(0));
      expect(stats.readDevocionalIds, isEmpty);
    });

    test('should copy SpiritualStats with updated values', () {
      final original = SpiritualStats(
        totalDevocionalesRead: 5,
        currentStreak: 3,
      );
      final updated = original.copyWith(currentStreak: 8, longestStreak: 10);

      expect(updated.totalDevocionalesRead, equals(5)); // unchanged
      expect(updated.currentStreak, equals(8)); // changed
      expect(updated.longestStreak, equals(10)); // changed
    });
  });
}
