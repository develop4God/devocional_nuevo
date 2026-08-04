@Tags(['critical', 'unit', 'services'])
library;

import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('SpiritualStatsService streak calculation', () {
    late SpiritualStatsService statsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await registerTestServices();
      statsService = SpiritualStatsService();
    });

    test('builds and extends streak beyond 30 days correctly', () async {
      // Build 30-day streak via debug helper addStreakDay
      for (int i = 0; i < 30; i++) {
        final s = await statsService.addStreakDay();
        expect(s.currentStreak, equals(i + 1));
      }

      final stats30 = await statsService.getStats();
      expect(stats30.currentStreak, equals(30));

      // Add one more day -> expect 31
      final s31 = await statsService.addStreakDay();
      expect(s31.currentStreak, equals(31));
    });

    test('streak has no artificial ceiling and keeps counting past 500',
        () async {
      // Regression-proofing: nothing in _calculateCurrentStreak caps the
      // count. Seed a long unbroken run of consecutive read-dates directly
      // (instead of looping addStreakDay 500 times, which would just be
      // slow) and confirm the calculated streak matches the seeded length
      // exactly, then extend it by one more day.
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      const seededStreak = 500;
      final readDates = List.generate(
        seededStreak,
        (i) => today.subtract(Duration(days: i)),
      );

      await statsService.restoreStats({
        'stats': {
          'totalDevocionalesRead': seededStreak,
          'currentStreak': seededStreak,
          'longestStreak': seededStreak,
          'lastActivityDate': today.toIso8601String(),
          'readDevocionalIds': <String>[],
          'unlockedAchievements': <Map<String, dynamic>>[],
        },
        'read_dates':
            readDates.map((d) => d.toIso8601String().split('T').first).toList(),
      });

      final stats500 = await statsService.getStats();
      expect(stats500.currentStreak, equals(500));

      final s501 = await statsService.addStreakDay();
      expect(s501.currentStreak, equals(501));
    });

    test(
      'recordDailyAppVisit is idempotent when called repeatedly the same day',
      () async {
        // Regression: streak refresh is now triggered on every app resume
        // (not just cold start), so recordDailyAppVisit can be invoked many
        // times per day. It must not duplicate today's read-date entry or
        // inflate the streak.
        await statsService.recordDailyAppVisit();
        final readDatesAfterFirst =
            await statsService.getReadDatesForVisualization();

        await statsService.recordDailyAppVisit();
        await statsService.recordDailyAppVisit();
        final readDatesAfterRepeat =
            await statsService.getReadDatesForVisualization();

        expect(readDatesAfterRepeat.length, equals(readDatesAfterFirst.length));
        final stats = await statsService.getStats();
        expect(stats.currentStreak, equals(1));
      },
    );

    test(
      'streak extends across a day rollover when app is only resumed, not restarted',
      () async {
        // Regression for: streak did not advance after midnight unless the
        // app was force-closed and reopened. devocionales_page.dart's resume
        // handler only read stats via getStats() -- it never re-ran
        // recordDailyAppVisit(), so a new calendar day was never registered
        // until a cold start. Simulates "yesterday was the last read day"
        // (as if the app had been open since before midnight) and verifies
        // that calling recordDailyAppVisit() -- now wired into every streak
        // refresh, including resume -- extends the streak to include today.
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));

        await statsService.restoreStats({
          'stats': {
            'totalDevocionalesRead': 1,
            'currentStreak': 1,
            'longestStreak': 1,
            'lastActivityDate': yesterday.toIso8601String(),
            'readDevocionalIds': <String>[],
            'unlockedAchievements': <Map<String, dynamic>>[],
          },
          'read_dates': [yesterday.toIso8601String().split('T').first],
        });

        final statsBefore = await statsService.getStats();
        expect(statsBefore.currentStreak, equals(1));

        // Equivalent to the app resuming after midnight passed in the background.
        await statsService.recordDailyAppVisit();

        final statsAfter = await statsService.getStats();
        expect(statsAfter.currentStreak, equals(2));
      },
    );
  });
}
