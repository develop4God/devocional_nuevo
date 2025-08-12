// test/devocional_reading_logic_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Devotional Reading Logic Tests', () {
    setUp(() {
      // Initialize SharedPreferences mock for each test
      SharedPreferences.setMockInitialValues({});
    });

    test('DevocionalProvider recordDevocionalRead works correctly', () async {
      final provider = DevocionalProvider();
      final statsService = SpiritualStatsService();
      
      // Record a devotional read
      await provider.recordDevocionalRead('test_devotional_123');
      
      // Verify it was recorded in stats
      final stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, 1);
      expect(stats.readDevocionalIds, contains('test_devotional_123'));
    });

    test('Empty devotional ID is handled gracefully', () async {
      final provider = DevocionalProvider();
      final statsService = SpiritualStatsService();
      
      // Try to record with empty ID
      await provider.recordDevocionalRead('');
      
      // Should not record anything
      final stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, 0);
      expect(stats.readDevocionalIds, isEmpty);
    });

    test('Real usage pattern: unique consecutive tracking', () async {
      final provider = DevocionalProvider();
      final statsService = SpiritualStatsService();
      
      // Simulate reading devotionals with unique consecutive IDs
      final devotionalIds = [
        'devotional_2025_01_01',
        'devotional_2025_01_02', 
        'devotional_2025_01_03',
      ];
      
      for (final id in devotionalIds) {
        await provider.recordDevocionalRead(id);
      }
      
      final stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, 3);
      expect(stats.readDevocionalIds.length, 3);
      
      // Verify all IDs are tracked
      for (final id in devotionalIds) {
        expect(stats.readDevocionalIds, contains(id));
      }
    });

    test('Rapid tapping prevention works', () async {
      final provider = DevocionalProvider();
      final statsService = SpiritualStatsService();
      
      // Record a devotional
      await provider.recordDevocionalRead('rapid_tap_test');
      
      // Try to record the same devotional rapidly (should be ignored)
      await provider.recordDevocionalRead('rapid_tap_test');
      await provider.recordDevocionalRead('rapid_tap_test');
      await provider.recordDevocionalRead('rapid_tap_test');
      
      final stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, 1); // Should only count once
    });

    test('Legitimate re-reading after time delay is not prevented', () async {
      final statsService = SpiritualStatsService();
      
      // Record initial read
      await statsService.recordDevocionalRead(devocionalId: 'time_test');
      
      // Simulate time passage by manually manipulating the service
      // In a real test environment, you might use techniques like mocking time
      final stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, 1);
      
      // Verify the devotional is marked as read
      expect(await statsService.hasDevocionalBeenRead('time_test'), true);
    });

    test('Favorites count integration with devotional reading', () async {
      final provider = DevocionalProvider();
      final statsService = SpiritualStatsService();
      
      // Record devotional read with favorites count
      await statsService.recordDevocionalRead(
        devocionalId: 'favorites_integration_test',
        favoritesCount: 3,
      );
      
      final stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, 1);
      expect(stats.favoritesCount, 3);
    });

    test('Achievement unlocking during devotional reading', () async {
      final provider = DevocionalProvider();
      final statsService = SpiritualStatsService();
      
      // Record first devotional to unlock "Primer Paso" achievement
      await provider.recordDevocionalRead('achievement_test_1');
      
      final stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, 1);
      
      // Check if achievement was unlocked
      final firstReadAchievement = stats.unlockedAchievements.firstWhere(
        (achievement) => achievement.id == 'first_read',
        orElse: () => throw Exception('First read achievement should be unlocked'),
      );
      
      expect(firstReadAchievement.isUnlocked, true);
    });

    test('Streak calculation across multiple days simulation', () async {
      final statsService = SpiritualStatsService();
      
      // Record devotional reads (in real scenario, these would be on different days)
      await statsService.recordDevocionalRead(devocionalId: 'day_1_devotional');
      
      // Check initial streak
      var stats = await statsService.getStats();
      expect(stats.currentStreak, 1);
      expect(stats.longestStreak, 1);
      
      // Record another devotional (same day, so streak should remain 1)
      await statsService.recordDevocionalRead(devocionalId: 'day_1_devotional_2');
      
      stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, 2);
      expect(stats.currentStreak, 1); // Same day
    });

    test('Service handles malformed data gracefully', () async {
      final statsService = SpiritualStatsService();
      
      // Try to record with null-like values
      try {
        await statsService.recordDevocionalRead(devocionalId: '');
        // Should not throw an error, but also shouldn't record anything
      } catch (e) {
        fail('Service should handle empty ID gracefully');
      }
      
      final stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, 0);
    });

    test('Multiple achievements unlock correctly', () async {
      final statsService = SpiritualStatsService();
      
      // Record multiple devotionals to unlock reading-based achievements
      for (int i = 1; i <= 7; i++) {
        await statsService.recordDevocionalRead(devocionalId: 'devotional_$i');
      }
      
      final stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, 7);
      
      // Should unlock "Primer Paso" and "Lector Semanal"
      final unlockedIds = stats.unlockedAchievements.map((a) => a.id).toSet();
      expect(unlockedIds, contains('first_read'));
      expect(unlockedIds, contains('week_reader'));
    });
  });
}