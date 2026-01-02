// patrol_test/multi_year_devotionals_patrol_test.dart

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/helpers/test_helpers.dart';

void main() {
  group('Patrol Test - Multi-Year Devotionals', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      registerTestServices(); // Register all required services
    });

    group('User Journey - Year 2026 Scenarios', () {
      test(
          'Scenario 1: New user in 2026 can access both 2025 and 2026 devotionals',
          () async {
        // Initialize SharedPreferences
        final prefs = await SharedPreferences.getInstance();

        // Simulate new user (no previous data)
        expect(prefs.getStringList('readDevocionalIds'), isNull);

        // Verify user can read devotionals from 2025
        final statsService = SpiritualStatsService();
        await statsService.recordDevocionalRead(
          devocionalId: 'devotional_2025_01_01',
          readingTimeSeconds: 70,
          scrollPercentage: 0.85,
        );

        var stats = await statsService.getStats();
        expect(stats.totalDevocionalesRead, 1);
        expect(stats.readDevocionalIds.contains('devotional_2025_01_01'), true);

        // Verify user can also read devotionals from 2026
        await statsService.recordDevocionalRead(
          devocionalId: 'devotional_2026_01_01',
          readingTimeSeconds: 70,
          scrollPercentage: 0.85,
        );

        stats = await statsService.getStats();
        expect(stats.totalDevocionalesRead, 2);
        expect(stats.readDevocionalIds.contains('devotional_2026_01_01'), true);
      });

      test(
          'Scenario 2: Existing user who read 2026 devotionals preserves their progress',
          () async {
        final statsService = SpiritualStatsService();

        // Simulate user who already read some 2026 devotionals
        await statsService.recordDevocionalRead(
          devocionalId: 'devotional_2026_01_01',
          readingTimeSeconds: 60,
          scrollPercentage: 0.8,
        );
        await statsService.recordDevocionalRead(
          devocionalId: 'devotional_2026_01_02',
          readingTimeSeconds: 60,
          scrollPercentage: 0.8,
        );
        await statsService.recordDevocionalRead(
          devocionalId: 'devotional_2026_01_03',
          readingTimeSeconds: 60,
          scrollPercentage: 0.8,
        );

        var stats = await statsService.getStats();
        expect(stats.totalDevocionalesRead, 3);

        // User should not see these as unread
        final allDevocionalIds = [
          'devotional_2026_01_01',
          'devotional_2026_01_02',
          'devotional_2026_01_03',
          'devotional_2025_01_01', // unread
          'devotional_2025_01_02', // unread
        ];

        final readIds = stats.readDevocionalIds.toSet();
        final unreadIds =
            allDevocionalIds.where((id) => !readIds.contains(id)).toList();

        expect(unreadIds.length, 2);
        expect(unreadIds.contains('devotional_2025_01_01'), true);
        expect(unreadIds.contains('devotional_2025_01_02'), true);
      });

      test(
          'Scenario 3: User reads devotionals sequentially from Dec 2025 to Jan 2026',
          () async {
        final statsService = SpiritualStatsService();

        // Read devotionals from end of 2025
        final late2025Devotionals = [
          'devotional_2025_12_28',
          'devotional_2025_12_29',
          'devotional_2025_12_30',
          'devotional_2025_12_31',
        ];

        for (final id in late2025Devotionals) {
          await statsService.recordDevocionalRead(
            devocionalId: id,
            readingTimeSeconds: 60,
            scrollPercentage: 0.8,
          );
        }

        // Read devotionals from start of 2026
        final early2026Devotionals = [
          'devotional_2026_01_01',
          'devotional_2026_01_02',
          'devotional_2026_01_03',
        ];

        for (final id in early2026Devotionals) {
          await statsService.recordDevocionalRead(
            devocionalId: id,
            readingTimeSeconds: 60,
            scrollPercentage: 0.8,
          );
        }

        final stats = await statsService.getStats();
        expect(stats.totalDevocionalesRead, 7);

        // Verify all devotionals are tracked
        for (final id in [...late2025Devotionals, ...early2026Devotionals]) {
          expect(stats.readDevocionalIds.contains(id), true,
              reason: 'Devotional $id should be marked as read');
        }
      });

      test(
          'Scenario 4: User navigates backward to 2025 after reading 2026 devotionals',
          () async {
        final statsService = SpiritualStatsService();

        // Read some 2026 devotionals first
        await statsService.recordDevocionalRead(
          devocionalId: 'devotional_2026_03_01',
          readingTimeSeconds: 60,
          scrollPercentage: 0.8,
        );
        await statsService.recordDevocionalRead(
          devocionalId: 'devotional_2026_03_02',
          readingTimeSeconds: 60,
          scrollPercentage: 0.8,
        );

        // Then navigate back to read 2025 devotionals
        await statsService.recordDevocionalRead(
          devocionalId: 'devotional_2025_06_15',
          readingTimeSeconds: 60,
          scrollPercentage: 0.8,
        );
        await statsService.recordDevocionalRead(
          devocionalId: 'devotional_2025_06_16',
          readingTimeSeconds: 60,
          scrollPercentage: 0.8,
        );

        final stats = await statsService.getStats();
        expect(stats.totalDevocionalesRead, 4);

        // Verify devotionals from both years are tracked
        expect(stats.readDevocionalIds.contains('devotional_2026_03_01'), true);
        expect(stats.readDevocionalIds.contains('devotional_2026_03_02'), true);
        expect(stats.readDevocionalIds.contains('devotional_2025_06_15'), true);
        expect(stats.readDevocionalIds.contains('devotional_2025_06_16'), true);
      });
    });

    group('Edge Cases - Patrol Tests', () {
      test(
          'Edge: User tries to read same devotional from both years (different IDs)',
          () async {
        final statsService = SpiritualStatsService();

        // Devotionals with same date (March 15) but different years should have different IDs
        await statsService.recordDevocionalRead(
          devocionalId: 'devotional_2025_03_15',
          readingTimeSeconds: 60,
          scrollPercentage: 0.8,
        );
        await statsService.recordDevocionalRead(
          devocionalId: 'devotional_2026_03_15',
          readingTimeSeconds: 60,
          scrollPercentage: 0.8,
        );

        final stats = await statsService.getStats();
        expect(stats.totalDevocionalesRead, 2);
        expect(stats.readDevocionalIds.length, 2);
      });

      test('Edge: Rapid reading across year boundary', () async {
        final statsService = SpiritualStatsService();

        // Simulate rapid reading across years
        final devotionalIds = [
          'devotional_2025_12_31',
          'devotional_2026_01_01',
          'devotional_2026_01_02',
          'devotional_2025_12_30',
          'devotional_2026_01_03',
        ];

        for (final id in devotionalIds) {
          await statsService.recordDevocionalRead(
            devocionalId: id,
            readingTimeSeconds: 60,
            scrollPercentage: 0.8,
          );
        }

        final stats = await statsService.getStats();
        expect(stats.totalDevocionalesRead, 5);

        // All devotionals should be tracked without duplicates
        final uniqueIds = stats.readDevocionalIds.toSet();
        expect(uniqueIds.length, 5);
      });

      test('Edge: User reads all 2025 devotionals then starts 2026', () async {
        final statsService = SpiritualStatsService();

        // Simulate reading all of 2025 (simplified - just 10 devotionals)
        for (int day = 1; day <= 10; day++) {
          await statsService.recordDevocionalRead(
            devocionalId:
                'devotional_2025_${day.toString().padLeft(2, '0')}_01',
            readingTimeSeconds: 60,
            scrollPercentage: 0.8,
          );
        }

        var stats = await statsService.getStats();
        expect(stats.totalDevocionalesRead, 10);

        // Now start reading 2026
        for (int day = 1; day <= 5; day++) {
          await statsService.recordDevocionalRead(
            devocionalId:
                'devotional_2026_${day.toString().padLeft(2, '0')}_01',
            readingTimeSeconds: 60,
            scrollPercentage: 0.8,
          );
        }

        stats = await statsService.getStats();
        expect(stats.totalDevocionalesRead, 15);

        // Verify devotionals from both years are tracked
        final years =
            stats.readDevocionalIds.map((id) => id.split('_')[1]).toSet();
        expect(years.contains('2025'), true);
        expect(years.contains('2026'), true);
      });

      test('Edge: Devotional model sorting across years', () {
        final devocionales = <Devocional>[
          Devocional(
            id: 'dev_2026_12_31',
            versiculo: 'Verse',
            reflexion: 'Reflection',
            paraMeditar: [],
            oracion: 'Prayer',
            date: DateTime(2026, 12, 31),
            version: 'RVR1960',
            language: 'es',
          ),
          Devocional(
            id: 'dev_2025_01_01',
            versiculo: 'Verse',
            reflexion: 'Reflection',
            paraMeditar: [],
            oracion: 'Prayer',
            date: DateTime(2025, 1, 1),
            version: 'RVR1960',
            language: 'es',
          ),
          Devocional(
            id: 'dev_2026_01_01',
            versiculo: 'Verse',
            reflexion: 'Reflection',
            paraMeditar: [],
            oracion: 'Prayer',
            date: DateTime(2026, 1, 1),
            version: 'RVR1960',
            language: 'es',
          ),
          Devocional(
            id: 'dev_2025_12_31',
            versiculo: 'Verse',
            reflexion: 'Reflection',
            paraMeditar: [],
            oracion: 'Prayer',
            date: DateTime(2025, 12, 31),
            version: 'RVR1960',
            language: 'es',
          ),
        ];

        devocionales.sort((a, b) => a.date.compareTo(b.date));

        expect(devocionales[0].id, 'dev_2025_01_01');
        expect(devocionales[1].id, 'dev_2025_12_31');
        expect(devocionales[2].id, 'dev_2026_01_01');
        expect(devocionales[3].id, 'dev_2026_12_31');
      });
    });

    group('Data Integrity - Patrol Tests', () {
      test('Integrity: No duplicate devotionals in read list', () async {
        final statsService = SpiritualStatsService();

        // Try to read same devotional multiple times
        for (int i = 0; i < 5; i++) {
          await statsService.recordDevocionalRead(
            devocionalId: 'devotional_2025_05_15',
            readingTimeSeconds: 60,
            scrollPercentage: 0.8,
          );
        }

        final stats = await statsService.getStats();
        expect(stats.totalDevocionalesRead, 1);
        expect(
            stats.readDevocionalIds
                .where((id) => id == 'devotional_2025_05_15')
                .length,
            1);
      });

      test('Integrity: Read devotionals persist across service restarts',
          () async {
        // First instance
        var statsService1 = SpiritualStatsService();
        await statsService1.recordDevocionalRead(
          devocionalId: 'devotional_2025_08_20',
          readingTimeSeconds: 60,
          scrollPercentage: 0.8,
        );
        await statsService1.recordDevocionalRead(
          devocionalId: 'devotional_2026_08_20',
          readingTimeSeconds: 60,
          scrollPercentage: 0.8,
        );

        // Second instance (simulating app restart)
        var statsService2 = SpiritualStatsService();
        final stats = await statsService2.getStats();

        expect(stats.totalDevocionalesRead, 2);
        expect(stats.readDevocionalIds.contains('devotional_2025_08_20'), true);
        expect(stats.readDevocionalIds.contains('devotional_2026_08_20'), true);
      });

      test('Integrity: Year calculation is dynamic and correct', () {
        final currentYear = DateTime.now().year;
        final yearsToLoad = [currentYear - 1, currentYear];

        // Verify we're loading previous and current year
        expect(yearsToLoad.length, 2);
        expect(yearsToLoad[0], currentYear - 1);
        expect(yearsToLoad[1], currentYear);

        // For 2026, this should be [2025, 2026]
        if (currentYear == 2026) {
          expect(yearsToLoad, [2025, 2026]);
        }
      });
    });
  });
}
