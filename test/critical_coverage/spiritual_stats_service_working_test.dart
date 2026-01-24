import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('SpiritualStatsService user behavior', () {
    late SpiritualStatsService statsService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      registerTestServices();
      statsService = SpiritualStatsService();
    });

    test('should initialize stats with default values', () async {
      final stats = await statsService.getStats();
      expect(stats, isNotNull);
      expect(stats.totalDevocionalesRead, equals(0));
      expect(stats.currentStreak, equals(0));
      expect(stats.longestStreak, equals(0));
      expect(stats.favoritesCount, equals(0));
      expect(stats.readDevocionalIds, isEmpty);
    });

    test('should record devotional read and update stats when criteria met',
        () async {
      final devocionalId = 'dev1';
      final statsBefore = await statsService.getStats();
      expect(statsBefore.readDevocionalIds.contains(devocionalId), isFalse);
      await statsService.recordDevocionalRead(
        devocionalId: devocionalId,
        readingTimeSeconds: 65, // >= 60s
        scrollPercentage: 0.85, // >= 0.8
      );
      final statsAfter = await statsService.getStats();
      expect(statsAfter.readDevocionalIds.contains(devocionalId), isTrue);
      expect(statsAfter.totalDevocionalesRead,
          statsBefore.totalDevocionalesRead + 1);
    });

    test('should not record devotional read if criteria not met', () async {
      final devocionalId = 'dev3';
      await statsService.recordDevocionalRead(
        devocionalId: devocionalId,
        readingTimeSeconds: 30, // < 60s
        scrollPercentage: 0.9, // >= 0.8
      );
      final stats = await statsService.getStats();
      expect(stats.readDevocionalIds.contains(devocionalId), isFalse);
      expect(stats.totalDevocionalesRead, 0);
    });

    test('should not duplicate devotional read', () async {
      final devocionalId = 'dev2';
      await statsService.recordDevocionalRead(
        devocionalId: devocionalId,
        readingTimeSeconds: 70, // >= 60s
        scrollPercentage: 0.9, // >= 0.8
      );
      final statsOnce = await statsService.getStats();
      await statsService.recordDevocionalRead(
        devocionalId: devocionalId,
        readingTimeSeconds: 80, // >= 60s
        scrollPercentage: 0.95, // >= 0.8
      );
      final statsTwice = await statsService.getStats();
      expect(
          statsTwice.readDevocionalIds.where((id) => id == devocionalId).length,
          1);
      expect(statsTwice.totalDevocionalesRead, statsOnce.totalDevocionalesRead);
    });
  });
}
