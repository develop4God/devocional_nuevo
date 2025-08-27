// test/spiritual_stats_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/models/spiritual_stats_model.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Spiritual Stats Tests', () {
    setUp(() {
      // Initialize Flutter binding for tests
      TestWidgetsFlutterBinding.ensureInitialized();
      // Initialize SharedPreferences mock for each test
      SharedPreferences.setMockInitialValues({});
    });

    test('SpiritualStats model creation and serialization', () {
      final stats = SpiritualStats(
        totalDevocionalesRead: 5,
        currentStreak: 3,
        longestStreak: 7,
        lastActivityDate: DateTime(2025, 1, 1),
        favoritesCount: 2,
        readDevocionalIds: ['dev1', 'dev2', 'dev3'],
      );

      expect(stats.totalDevocionalesRead, 5);
      expect(stats.currentStreak, 3);
      expect(stats.longestStreak, 7);
      expect(stats.favoritesCount, 2);
      expect(stats.readDevocionalIds.length, 3);

      // Test serialization
      final json = stats.toJson();
      final statsFromJson = SpiritualStats.fromJson(json);

      expect(statsFromJson.totalDevocionalesRead, stats.totalDevocionalesRead);
      expect(statsFromJson.currentStreak, stats.currentStreak);
      expect(statsFromJson.longestStreak, stats.longestStreak);
      expect(statsFromJson.favoritesCount, stats.favoritesCount);
      expect(statsFromJson.readDevocionalIds, stats.readDevocionalIds);
    });

    test('Achievement model creation and serialization', () {
      final achievement = Achievement(
        id: 'test_achievement',
        title: 'Test Achievement',
        description: 'Test description',
        icon: Icons.star,
        color: Colors.blue,
        threshold: 5,
        type: AchievementType.reading,
        isUnlocked: true,
      );

      expect(achievement.isUnlocked, true);
      expect(achievement.threshold, 5);
      expect(achievement.type, AchievementType.reading);

      // Test serialization
      final json = achievement.toJson();
      final achievementFromJson = Achievement.fromJson(json);

      expect(achievementFromJson.id, achievement.id);
      expect(achievementFromJson.title, achievement.title);
      expect(achievementFromJson.isUnlocked, achievement.isUnlocked);
      expect(achievementFromJson.type, achievement.type);
    });

    test('PredefinedAchievements contains expected achievements', () {
      final achievements = PredefinedAchievements.all;

      expect(achievements.isNotEmpty, true);
      expect(achievements.length, greaterThanOrEqualTo(8));

      // Check for specific achievements
      final firstReadAchievement = achievements.firstWhere(
        (a) => a.id == 'first_read',
        orElse: () => throw Exception('first_read achievement not found'),
      );

      expect(firstReadAchievement.title, 'Primer Paso');
      expect(firstReadAchievement.threshold, 1);
      expect(firstReadAchievement.type, AchievementType.reading);
    });

    test('SpiritualStatsService basic functionality', () async {
      final service = SpiritualStatsService();

      // Get initial stats
      final initialStats = await service.getStats();
      expect(initialStats.totalDevocionalesRead, 0);
      expect(initialStats.currentStreak, 0);
      expect(initialStats.readDevocionalIds, isEmpty);

      // Record a devotional read
      final updatedStats = await service.recordDevocionalRead(
        devocionalId: 'devotional_123',
        readingTimeSeconds: 60,
        scrollPercentage: 0.8,
      );
      expect(updatedStats.totalDevocionalesRead, 1);
      expect(updatedStats.currentStreak, 0); // Reading devotionals doesn't affect streak
      expect(updatedStats.lastActivityDate, isNotNull);
      expect(updatedStats.readDevocionalIds, contains('devotional_123'));

      // Update favorites count
      final statsWithFavorites = await service.updateFavoritesCount(5);
      expect(statsWithFavorites.favoritesCount, 5);
    });

    test('Devotional ID tracking prevents duplicates', () async {
      final service = SpiritualStatsService();

      // Record the same devotional multiple times
      await service.recordDevocionalRead(
        devocionalId: 'devotional_456',
        readingTimeSeconds: 60,
        scrollPercentage: 0.8,
      );
      await service.recordDevocionalRead(
        devocionalId: 'devotional_456',
        readingTimeSeconds: 60,
        scrollPercentage: 0.8,
      );
      await service.recordDevocionalRead(
        devocionalId: 'devotional_456',
        readingTimeSeconds: 60,
        scrollPercentage: 0.8,
      );

      final stats = await service.getStats();

      // Should only count once
      expect(stats.totalDevocionalesRead, 1);
      expect(stats.readDevocionalIds.length, 1);
      expect(stats.readDevocionalIds.first, 'devotional_456');
    });

    test('Anti-spam protection prevents rapid reading', () async {
      final service = SpiritualStatsService();

      // Record first read
      final firstStats = await service.recordDevocionalRead(
        devocionalId: 'devotional_spam_test',
        readingTimeSeconds: 60,
        scrollPercentage: 0.8,
      );
      expect(firstStats.totalDevocionalesRead, 1);

      // Try to record the same devotional immediately (should be ignored)
      final secondStats = await service.recordDevocionalRead(
        devocionalId: 'devotional_spam_test',
        readingTimeSeconds: 60,
        scrollPercentage: 0.8,
      );
      expect(secondStats.totalDevocionalesRead, 1); // Should not increase
    });

    test('Different devotionals on same day count correctly', () async {
      final service = SpiritualStatsService();

      // Record multiple different devotionals
      await service.recordDevocionalRead(
        devocionalId: 'devotional_1',
        readingTimeSeconds: 60,
        scrollPercentage: 0.8,
      );
      await service.recordDevocionalRead(
        devocionalId: 'devotional_2',
        readingTimeSeconds: 60,
        scrollPercentage: 0.8,
      );
      await service.recordDevocionalRead(
        devocionalId: 'devotional_3',
        readingTimeSeconds: 60,
        scrollPercentage: 0.8,
      );

      final stats = await service.getStats();

      expect(stats.totalDevocionalesRead, 3);
      expect(stats.currentStreak, 0); // Reading devotionals doesn't affect streak in this implementation
      expect(stats.readDevocionalIds.length, 3);
      expect(stats.readDevocionalIds, contains('devotional_1'));
      expect(stats.readDevocionalIds, contains('devotional_2'));
      expect(stats.readDevocionalIds, contains('devotional_3'));
    });

    test('Achievement unlocking works correctly', () async {
      final service = SpiritualStatsService();

      // Record first devotional read to unlock "Primer Paso"
      final stats = await service.recordDevocionalRead(
        devocionalId: 'devotional_achievement_test',
        readingTimeSeconds: 60,
        scrollPercentage: 0.8,
      );

      // Check if first read achievement is unlocked
      final firstReadAchievement = stats.unlockedAchievements.firstWhere(
        (achievement) => achievement.id == 'first_read',
        orElse: () =>
            throw Exception('First read achievement should be unlocked'),
      );

      expect(firstReadAchievement.isUnlocked, true);
    });

    test('Favorites count achievement unlocking', () async {
      final service = SpiritualStatsService();

      // Update favorites count to unlock achievement
      final stats = await service.updateFavoritesCount(1);

      // Check if first favorite achievement is unlocked
      final firstFavoriteAchievement = stats.unlockedAchievements.firstWhere(
        (achievement) => achievement.id == 'first_favorite',
        orElse: () =>
            throw Exception('First favorite achievement should be unlocked'),
      );

      expect(firstFavoriteAchievement.isUnlocked, true);
    });

    test('hasDevocionalBeenRead works correctly', () async {
      final service = SpiritualStatsService();

      // Initially, no devotional has been read
      expect(await service.hasDevocionalBeenRead('test_devotional'), false);

      // Record a devotional read
      await service.recordDevocionalRead(
        devocionalId: 'test_devotional',
        readingTimeSeconds: 60,
        scrollPercentage: 0.8,
      );

      // Now it should return true
      expect(await service.hasDevocionalBeenRead('test_devotional'), true);

      // Other devotionals should still return false
      expect(await service.hasDevocionalBeenRead('other_devotional'), false);
    });

    test('Reset stats clears all data', () async {
      final service = SpiritualStatsService();

      // Add some data
      await service.recordDevocionalRead(
        devocionalId: 'test_reset',
        readingTimeSeconds: 60,
        scrollPercentage: 0.8,
      );
      await service.updateFavoritesCount(5);

      // Verify data exists
      var stats = await service.getStats();
      expect(stats.totalDevocionalesRead, 1);
      expect(stats.favoritesCount, 5);

      // Reset and verify data is cleared
      await service.resetStats();
      stats = await service.getStats();
      expect(stats.totalDevocionalesRead, 0);
      expect(stats.favoritesCount, 0);
      expect(stats.readDevocionalIds, isEmpty);
    });
  });
}
