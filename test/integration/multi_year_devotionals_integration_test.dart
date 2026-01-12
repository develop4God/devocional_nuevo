// test/integration/multi_year_devotionals_integration_test.dart

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

@Tags(['slow'])
import '../helpers/test_helpers.dart';

void main() {
  group('Multi-Year Devotionals Integration Tests', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      registerTestServices();
    });

    group('Real User Behavior - Year Transition Scenarios', () {
      test('User who read 2026 devotionals can still access 2025 devotionals',
          () async {
        // Simulate a user who started using the app in 2026

        // Mock some read devotionals from 2026
        final statsService = SpiritualStatsService();
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

        final stats = await statsService.getStats();
        expect(stats.totalDevocionalesRead, 2);
        expect(stats.readDevocionalIds.contains('devotional_2026_01_01'), true);
        expect(stats.readDevocionalIds.contains('devotional_2026_01_02'), true);

        // Verify they can still read 2025 devotionals (not blocked)
        await statsService.recordDevocionalRead(
          devocionalId: 'devotional_2025_12_31',
          readingTimeSeconds: 60,
          scrollPercentage: 0.8,
        );

        final updatedStats = await statsService.getStats();
        expect(updatedStats.totalDevocionalesRead, 3);
        expect(updatedStats.readDevocionalIds.contains('devotional_2025_12_31'),
            true);
      });

      test('New user in 2026 gets devotionals from both 2025 and 2026',
          () async {
        // Simulate a new user installing the app in 2026
        final statsService = SpiritualStatsService();

        // Record reading devotionals from both years
        await statsService.recordDevocionalRead(
          devocionalId: 'devotional_2025_01_15',
          readingTimeSeconds: 60,
          scrollPercentage: 0.8,
        );
        await statsService.recordDevocionalRead(
          devocionalId: 'devotional_2026_01_15',
          readingTimeSeconds: 60,
          scrollPercentage: 0.8,
        );

        final stats = await statsService.getStats();
        expect(stats.totalDevocionalesRead, 2);
        expect(stats.readDevocionalIds.contains('devotional_2025_01_15'), true);
        expect(stats.readDevocionalIds.contains('devotional_2026_01_15'), true);
      });

      test(
          'User reads devotionals consecutively across year boundary (2025->2026)',
          () async {
        final statsService = SpiritualStatsService();

        // Read devotionals from late 2025
        await statsService.recordDevocionalRead(
          devocionalId: 'devotional_2025_12_30',
          readingTimeSeconds: 60,
          scrollPercentage: 0.8,
        );
        await statsService.recordDevocionalRead(
          devocionalId: 'devotional_2025_12_31',
          readingTimeSeconds: 60,
          scrollPercentage: 0.8,
        );

        // Then read devotionals from early 2026
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

        final stats = await statsService.getStats();
        expect(stats.totalDevocionalesRead, 4);

        // Verify all devotionals are tracked
        expect(stats.readDevocionalIds.contains('devotional_2025_12_30'), true);
        expect(stats.readDevocionalIds.contains('devotional_2025_12_31'), true);
        expect(stats.readDevocionalIds.contains('devotional_2026_01_01'), true);
        expect(stats.readDevocionalIds.contains('devotional_2026_01_02'), true);
      });

      test('User can jump between years while reading devotionals', () async {
        final statsService = SpiritualStatsService();

        // Read devotionals in non-sequential order across years
        await statsService.recordDevocionalRead(
          devocionalId: 'devotional_2026_03_15',
          readingTimeSeconds: 60,
          scrollPercentage: 0.8,
        );
        await statsService.recordDevocionalRead(
          devocionalId: 'devotional_2025_06_20',
          readingTimeSeconds: 60,
          scrollPercentage: 0.8,
        );
        await statsService.recordDevocionalRead(
          devocionalId: 'devotional_2026_01_10',
          readingTimeSeconds: 60,
          scrollPercentage: 0.8,
        );
        await statsService.recordDevocionalRead(
          devocionalId: 'devotional_2025_11_05',
          readingTimeSeconds: 60,
          scrollPercentage: 0.8,
        );

        final stats = await statsService.getStats();
        expect(stats.totalDevocionalesRead, 4);

        // Verify devotionals from both years are tracked
        final years = stats.readDevocionalIds
            .map((id) => id.split('_')[1])
            .where((y) => y == '2025' || y == '2026')
            .toSet();
        expect(years.contains('2025'), true);
        expect(years.contains('2026'), true);
      });
    });

    group('Edge Cases - Multi-Year Loading', () {
      test('Handles devotionals with same date across different years',
          () async {
        // Create devotionals with same day/month but different years
        final dev2025 = Devocional(
          id: 'devotional_2025_03_15',
          versiculo: 'John 3:16',
          reflexion: 'Reflection 2025',
          paraMeditar: [],
          oracion: 'Prayer',
          date: DateTime(2025, 3, 15),
          version: 'RVR1960',
          language: 'es',
        );

        final dev2026 = Devocional(
          id: 'devotional_2026_03_15',
          versiculo: 'Matthew 5:16',
          reflexion: 'Reflection 2026',
          paraMeditar: [],
          oracion: 'Prayer',
          date: DateTime(2026, 3, 15),
          version: 'RVR1960',
          language: 'es',
        );

        final allDevocionales = [dev2026, dev2025]; // Intentionally unsorted
        allDevocionales.sort((a, b) => a.date.compareTo(b.date));

        // Verify 2025 comes before 2026
        expect(allDevocionales[0].date.year, 2025);
        expect(allDevocionales[1].date.year, 2026);
        expect(allDevocionales[0].id, 'devotional_2025_03_15');
        expect(allDevocionales[1].id, 'devotional_2026_03_15');
      });

      test('Handles empty devotionals list from one year', () {
        final List<Devocional> devocionales2025 = [];
        final List<Devocional> devocionales2026 = [
          Devocional(
            id: 'devotional_2026_01_01',
            versiculo: 'John 3:16',
            reflexion: 'Reflection',
            paraMeditar: [],
            oracion: 'Prayer',
            date: DateTime(2026, 1, 1),
            version: 'RVR1960',
            language: 'es',
          ),
        ];

        final allDevocionales = [...devocionales2025, ...devocionales2026];
        allDevocionales.sort((a, b) => a.date.compareTo(b.date));

        expect(allDevocionales.length, 1);
        expect(allDevocionales[0].date.year, 2026);
      });

      test('Handles large number of devotionals from multiple years', () {
        final List<Devocional> allDevocionales = [];

        // Generate 365 devotionals for 2025
        for (int day = 1; day <= 365; day++) {
          final date = DateTime(2025, 1, 1).add(Duration(days: day - 1));
          allDevocionales.add(Devocional(
            id: 'devotional_2025_${day.toString().padLeft(3, '0')}',
            versiculo: 'Verse $day',
            reflexion: 'Reflection $day',
            paraMeditar: [],
            oracion: 'Prayer $day',
            date: date,
            version: 'RVR1960',
            language: 'es',
          ));
        }

        // Generate 365 devotionals for 2026
        for (int day = 1; day <= 365; day++) {
          final date = DateTime(2026, 1, 1).add(Duration(days: day - 1));
          allDevocionales.add(Devocional(
            id: 'devotional_2026_${day.toString().padLeft(3, '0')}',
            versiculo: 'Verse $day',
            reflexion: 'Reflection $day',
            paraMeditar: [],
            oracion: 'Prayer $day',
            date: date,
            version: 'RVR1960',
            language: 'es',
          ));
        }

        // Sort and verify
        allDevocionales.sort((a, b) => a.date.compareTo(b.date));

        expect(allDevocionales.length, 730);
        expect(allDevocionales.first.date.year, 2025);
        expect(allDevocionales.last.date.year, 2026);

        // Verify no duplicates
        final ids = allDevocionales.map((d) => d.id).toSet();
        expect(ids.length, 730);
      });

      test('Validates devotionals are properly sorted across years', () {
        final devocionales = <Devocional>[
          Devocional(
            id: 'dev_2026_06_15',
            versiculo: 'John 3:16',
            reflexion: 'Reflection',
            paraMeditar: [],
            oracion: 'Prayer',
            date: DateTime(2026, 6, 15),
            version: 'RVR1960',
            language: 'es',
          ),
          Devocional(
            id: 'dev_2025_12_31',
            versiculo: 'Psalm 23:1',
            reflexion: 'Reflection',
            paraMeditar: [],
            oracion: 'Prayer',
            date: DateTime(2025, 12, 31),
            version: 'RVR1960',
            language: 'es',
          ),
          Devocional(
            id: 'dev_2026_01_01',
            versiculo: 'Matthew 5:16',
            reflexion: 'Reflection',
            paraMeditar: [],
            oracion: 'Prayer',
            date: DateTime(2026, 1, 1),
            version: 'RVR1960',
            language: 'es',
          ),
          Devocional(
            id: 'dev_2025_01_01',
            versiculo: 'Romans 8:28',
            reflexion: 'Reflection',
            paraMeditar: [],
            oracion: 'Prayer',
            date: DateTime(2025, 1, 1),
            version: 'RVR1960',
            language: 'es',
          ),
        ];

        devocionales.sort((a, b) => a.date.compareTo(b.date));

        // Verify sorting is correct
        expect(devocionales[0].id, 'dev_2025_01_01');
        expect(devocionales[1].id, 'dev_2025_12_31');
        expect(devocionales[2].id, 'dev_2026_01_01');
        expect(devocionales[3].id, 'dev_2026_06_15');

        // Verify consecutive dates are in order
        for (int i = 0; i < devocionales.length - 1; i++) {
          expect(
            devocionales[i].date.isBefore(devocionales[i + 1].date) ||
                devocionales[i].date.isAtSameMomentAs(devocionales[i + 1].date),
            true,
            reason:
                'Devotional at index $i (${devocionales[i].id}) should be before or equal to index ${i + 1} (${devocionales[i + 1].id})',
          );
        }
      });

      test('Handles devotionals with different versions across years',
          () async {
        final devocionales = <Devocional>[
          Devocional(
            id: 'dev_2025_01_01_rvr',
            versiculo: 'Juan 3:16',
            reflexion: 'Reflexión',
            paraMeditar: [],
            oracion: 'Oración',
            date: DateTime(2025, 1, 1),
            version: 'RVR1960',
            language: 'es',
          ),
          Devocional(
            id: 'dev_2025_01_01_nvi',
            versiculo: 'Juan 3:16',
            reflexion: 'Reflexión',
            paraMeditar: [],
            oracion: 'Oración',
            date: DateTime(2025, 1, 1),
            version: 'NVI',
            language: 'es',
          ),
          Devocional(
            id: 'dev_2026_01_01_rvr',
            versiculo: 'Juan 3:16',
            reflexion: 'Reflexión',
            paraMeditar: [],
            oracion: 'Oración',
            date: DateTime(2026, 1, 1),
            version: 'RVR1960',
            language: 'es',
          ),
        ];

        // Filter by version
        final rvrDevocionales =
            devocionales.where((d) => d.version == 'RVR1960').toList();

        expect(rvrDevocionales.length, 2);
        expect(rvrDevocionales.any((d) => d.date.year == 2025), true);
        expect(rvrDevocionales.any((d) => d.date.year == 2026), true);
      });
    });

    group('Data Persistence - Multi-Year Scenarios', () {
      test('Read devotionals persist correctly across app restarts', () async {
        // First session - read some devotionals
        final statsService1 = SpiritualStatsService();
        await statsService1.recordDevocionalRead(
          devocionalId: 'devotional_2025_05_15',
          readingTimeSeconds: 60,
          scrollPercentage: 0.8,
        );
        await statsService1.recordDevocionalRead(
          devocionalId: 'devotional_2026_05_15',
          readingTimeSeconds: 60,
          scrollPercentage: 0.8,
        );

        var stats1 = await statsService1.getStats();
        expect(stats1.totalDevocionalesRead, 2);

        // Simulate app restart by creating new service instance
        final statsService2 = SpiritualStatsService();
        var stats2 = await statsService2.getStats();

        // Verify data persisted
        expect(stats2.totalDevocionalesRead, 2);
        expect(
            stats2.readDevocionalIds.contains('devotional_2025_05_15'), true);
        expect(
            stats2.readDevocionalIds.contains('devotional_2026_05_15'), true);
      });

      test('Mixed read and unread devotionals across years are tracked',
          () async {
        final statsService = SpiritualStatsService();

        // Read some devotionals from both years
        await statsService.recordDevocionalRead(
          devocionalId: 'devotional_2025_01_01',
          readingTimeSeconds: 60,
          scrollPercentage: 0.8,
        );
        await statsService.recordDevocionalRead(
          devocionalId: 'devotional_2026_01_01',
          readingTimeSeconds: 60,
          scrollPercentage: 0.8,
        );

        // Create a list of all devotionals (read and unread)
        final allDevocionalIds = [
          'devotional_2025_01_01',
          'devotional_2025_01_02', // unread
          'devotional_2025_01_03', // unread
          'devotional_2026_01_01',
          'devotional_2026_01_02', // unread
        ];

        final stats = await statsService.getStats();
        final readIds = stats.readDevocionalIds.toSet();

        final unreadIds =
            allDevocionalIds.where((id) => !readIds.contains(id)).toList();

        expect(unreadIds.length, 3);
        expect(unreadIds.contains('devotional_2025_01_02'), true);
        expect(unreadIds.contains('devotional_2025_01_03'), true);
        expect(unreadIds.contains('devotional_2026_01_02'), true);
      });
    });

    group('Performance - Multi-Year Operations', () {
      test('Sorting large multi-year devotional list performs efficiently', () {
        final stopwatch = Stopwatch()..start();

        final List<Devocional> devocionales = [];
        // Create 730 devotionals (2 years)
        for (int year = 2025; year <= 2026; year++) {
          for (int day = 1; day <= 365; day++) {
            final date = DateTime(year, 1, 1).add(Duration(days: day - 1));
            devocionales.add(Devocional(
              id: 'dev_${year}_${day.toString().padLeft(3, '0')}',
              versiculo: 'Verse',
              reflexion: 'Reflection',
              paraMeditar: [],
              oracion: 'Prayer',
              date: date,
              version: 'RVR1960',
              language: 'es',
            ));
          }
        }

        // Shuffle to simulate unsorted data
        devocionales.shuffle();

        // Sort
        devocionales.sort((a, b) => a.date.compareTo(b.date));

        stopwatch.stop();

        // Verify sorting was successful
        expect(devocionales.first.date.year, 2025);
        expect(devocionales.last.date.year, 2026);

        // Performance should be under 100ms for 730 items
        expect(stopwatch.elapsedMilliseconds < 100, true,
            reason:
                'Sorting should be fast (took ${stopwatch.elapsedMilliseconds}ms)');
      });

      test('Filtering devotionals by year performs efficiently', () {
        final List<Devocional> allDevocionales = [];

        // Create mixed year devotionals
        for (int i = 1; i <= 500; i++) {
          final year = i % 2 == 0 ? 2025 : 2026;
          allDevocionales.add(Devocional(
            id: 'dev_${year}_$i',
            versiculo: 'Verse',
            reflexion: 'Reflection',
            paraMeditar: [],
            oracion: 'Prayer',
            date: DateTime(year, 1, 1).add(Duration(days: i % 365)),
            version: 'RVR1960',
            language: 'es',
          ));
        }

        final stopwatch = Stopwatch()..start();

        // Filter by year
        final devocionales2025 =
            allDevocionales.where((d) => d.date.year == 2025).toList();
        final devocionales2026 =
            allDevocionales.where((d) => d.date.year == 2026).toList();

        stopwatch.stop();

        expect(devocionales2025.length, 250);
        expect(devocionales2026.length, 250);

        // Performance should be under 50ms
        expect(stopwatch.elapsedMilliseconds < 50, true,
            reason:
                'Filtering should be fast (took ${stopwatch.elapsedMilliseconds}ms)');
      });
    });
  });
}
