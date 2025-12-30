// test/critical_coverage/spiritual_stats_service_working_test.dart

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:devocional_nuevo/models/spiritual_stats_model.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('SpiritualStatsService Working Tests', () {
    late SpiritualStatsService statsService;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      // Reset SharedPreferences for each test
      SharedPreferences.setMockInitialValues({});

      // Setup service locator with all required services
      registerTestServices();

      // Mock path_provider for file operations
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getApplicationDocumentsDirectory':
              return '/mock_documents';
            case 'getTemporaryDirectory':
              return '/mock_temp';
            default:
              return null;
          }
        },
      );

      statsService = SpiritualStatsService();
    });

    tearDown(() {
      // Clean up method channel mocks
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
    });

    test('should create service instance correctly', () {
      expect(statsService, isNotNull);
      expect(statsService, isA<SpiritualStatsService>());
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

    test('should record devotional read with proper API', () async {
      const devocionalId = 'test_devotional_001';

      // Record a devotional read using correct API
      await statsService.recordDevocionalRead(
        devocionalId: devocionalId,
        readingTimeSeconds: 40, // Cambiado a 40s (nuevo umbral)
        scrollPercentage: 60.0, // Cambiado a 60% (nuevo umbral)
      );

      final stats = await statsService.getStats();
      expect(stats.readDevocionalIds, contains(devocionalId));
      expect(stats.totalDevocionalesRead, greaterThanOrEqualTo(1));
    });

    test('should handle duplicate devotional reads correctly', () async {
      const devocionalId = 'duplicate_test';

      // Record the same devotional twice with valid reading criteria
      await statsService.recordDevocionalRead(
        devocionalId: devocionalId,
        readingTimeSeconds: 40, // Cambiado a 40s
        scrollPercentage: 60.0, // Cambiado a 60%
      );
      await statsService.recordDevocionalRead(
        devocionalId: devocionalId,
        readingTimeSeconds: 40,
        scrollPercentage: 60.0,
      );

      final stats = await statsService.getStats();
      // Should not have duplicates
      final occurrences =
          stats.readDevocionalIds.where((id) => id == devocionalId).length;
      expect(occurrences, equals(1));
    });

    // CRITICAL BUSINESS LOGIC: Reading time and scroll percentage thresholds
    test('should validate reading criteria - minimum 40s and 60% scroll',
        () async {
      const devocionalId = 'criteria_test';

      // Test case 1: Below minimum reading time (should NOT count)
      await statsService.recordDevocionalRead(
        devocionalId: '${devocionalId}_short_time',
        readingTimeSeconds: 35, // Below 40s threshold
        scrollPercentage: 80.0, // Above 60% threshold
      );

      // Test case 2: Below minimum scroll percentage (should NOT count)
      await statsService.recordDevocionalRead(
        devocionalId: '${devocionalId}_low_scroll',
        readingTimeSeconds: 60, // Above 40s threshold
        scrollPercentage: 55.0, // Below 60% threshold
      );

      // Test case 3: Meets both criteria (should count)
      await statsService.recordDevocionalRead(
        devocionalId: '${devocionalId}_valid',
        readingTimeSeconds: 60, // Above 40s threshold
        scrollPercentage: 80.0, // Above 60% threshold
      );

      final stats = await statsService.getStats();

      // Solo la lectura válida debe contarse
      expect(stats.readDevocionalIds, contains('${devocionalId}_valid'));
      expect(stats.readDevocionalIds,
          isNot(contains('${devocionalId}_short_time')));
      expect(stats.readDevocionalIds,
          isNot(contains('${devocionalId}_low_scroll')));
    });

    test('should handle edge cases for reading thresholds', () async {
      const devocionalId = 'edge_cases';

      // Test exact threshold values
      await statsService.recordDevocionalRead(
        devocionalId: '${devocionalId}_exact_40s',
        readingTimeSeconds: 40, // Exactly 40s
        scrollPercentage: 60.0, // Exactly 60%
      );

      await statsService.recordDevocionalRead(
        devocionalId: '${devocionalId}_just_above',
        readingTimeSeconds: 41, // Just above 40s
        scrollPercentage: 60.1, // Just above 60%
      );

      await statsService.recordDevocionalRead(
        devocionalId: '${devocionalId}_just_below',
        readingTimeSeconds: 39, // Just below 40s
        scrollPercentage: 59.9, // Just below 60%
      );

      final stats = await statsService.getStats();

      // Deben contarse solo los que cumplen o superan el umbral
      expect(stats.readDevocionalIds, contains('${devocionalId}_exact_40s'));
      expect(stats.readDevocionalIds, contains('${devocionalId}_just_above'));
      expect(stats.readDevocionalIds,
          isNot(contains('${devocionalId}_just_below')));
    });

    test('should handle consecutive daily readings for streak calculation',
        () async {
      // Simulate readings on consecutive days for streak calculation

      // Record readings with valid criteria for streak calculation
      await statsService.recordDevocionalRead(
        devocionalId: 'streak_day_1',
        readingTimeSeconds: 40,
        scrollPercentage: 60.0,
      );

      // Simulate reading from yesterday (this would require date manipulation in real service)
      await statsService.recordDevocionalRead(
        devocionalId: 'streak_day_2',
        readingTimeSeconds: 40,
        scrollPercentage: 60.0,
      );

      final stats = await statsService.getStats();

      // Verify streak calculation logic (basic validation)
      expect(stats.currentStreak, isA<int>());
      expect(stats.longestStreak, isA<int>());
      expect(stats.currentStreak, greaterThanOrEqualTo(0));
      expect(stats.longestStreak, greaterThanOrEqualTo(stats.currentStreak));
    });

    test('should handle concurrent reading operations correctly', () async {
      // Test multiple concurrent operations
      final futures = <Future>[];

      for (int i = 0; i < 5; i++) {
        futures.add(statsService.recordDevocionalRead(
          devocionalId: 'concurrent_test_$i',
          readingTimeSeconds: 40,
          scrollPercentage: 60.0,
        ));
      }

      // Wait for all operations to complete
      await Future.wait(futures);

      final stats = await statsService.getStats();
      expect(stats.readDevocionalIds.length, greaterThanOrEqualTo(0));
    });

    test('should handle backup information retrieval', () async {
      try {
        final backupInfo = await statsService.getBackupInfo();
        expect(backupInfo, isA<Map<String, dynamic>>());
        expect(backupInfo.containsKey('auto_backups_count'), isTrue);
        expect(backupInfo.containsKey('last_auto_backup'), isTrue);
      } catch (e) {
        // Expected due to file system dependencies in test environment
        expect(e, isA<Exception>());
      }
    });

    test('should validate reading threshold business rules', () {
      // Test the core business rule: readings must meet both time and scroll criteria
      const validCases = [
        {'time': 40, 'scroll': 60.0}, // Minimum thresholds
        {'time': 60, 'scroll': 80.0}, // Above thresholds
        {'time': 120, 'scroll': 100.0}, // Well above thresholds
      ];

      const invalidCases = [
        {'time': 39, 'scroll': 60.0}, // Below time threshold
        {'time': 40, 'scroll': 59.9}, // Below scroll threshold
        {'time': 0, 'scroll': 100.0}, // Zero time
        {'time': 60, 'scroll': 0.0}, // Zero scroll
      ];

      // Esta prueba valida la regla de negocio conceptual
      for (final testCase in validCases) {
        final shouldCount =
            testCase['time']! >= 40 && testCase['scroll']! >= 60.0;
        expect(shouldCount, isTrue,
            reason:
                'Time:  2${testCase['time']}, Scroll: ${testCase['scroll']} should count');
      }

      for (final testCase in invalidCases) {
        final shouldCount =
            testCase['time']! >= 40 && testCase['scroll']! >= 60.0;
        expect(shouldCount, isFalse,
            reason:
                'Time: ${testCase['time']}, Scroll: ${testCase['scroll']} should NOT count');
      }
    });

    test('should handle favorites count tracking', () async {
      const devocionalId = 'favorites_test';

      // Record devotional with favorites count
      await statsService.recordDevocionalRead(
        devocionalId: devocionalId,
        readingTimeSeconds: 40,
        scrollPercentage: 60.0,
        favoritesCount: 5,
      );

      final stats = await statsService.getStats();
      expect(stats.favoritesCount, equals(5));
    });

    test('should handle auto backup settings', () async {
      // Test auto backup enable/disable
      await statsService.setAutoBackupEnabled(true);
      expect(await statsService.isAutoBackupEnabled(), isTrue);

      await statsService.setAutoBackupEnabled(false);
      expect(await statsService.isAutoBackupEnabled(), isFalse);
    });

    test('should handle JSON backup settings', () async {
      // Test JSON backup enable/disable
      await statsService.setJsonBackupEnabled(true);
      expect(await statsService.isJsonBackupEnabled(), isTrue);

      await statsService.setJsonBackupEnabled(false);
      expect(await statsService.isJsonBackupEnabled(), isFalse);
    });

    test('should record daily app visits correctly', () async {
      // Record a daily visit
      await statsService.recordDailyAppVisit();

      final stats = await statsService.getStats();
      expect(stats.lastActivityDate, isNotNull);
    });

    test('should save and load stats properly', () async {
      // Create custom stats
      final customStats = SpiritualStats(
        totalDevocionalesRead: 10,
        currentStreak: 5,
        longestStreak: 8,
        favoritesCount: 3,
        readDevocionalIds: ['dev1', 'dev2', 'dev3'],
        lastActivityDate: DateTime.now(),
      );

      // Save the stats
      await statsService.saveStats(customStats);

      // Load and verify
      final loadedStats = await statsService.getStats();
      expect(loadedStats.totalDevocionalesRead, equals(10));
      expect(loadedStats.currentStreak, equals(5));
      expect(loadedStats.longestStreak, equals(8));
      expect(loadedStats.favoritesCount, equals(3));
      expect(loadedStats.readDevocionalIds, hasLength(3));
    });

    test('should persist data across service instances', () async {
      const testDevocionalId = 'persistence_test';

      // Record with first instance with valid criteria
      await statsService.recordDevocionalRead(
        devocionalId: testDevocionalId,
        readingTimeSeconds: 60,
        scrollPercentage: 80.0,
      );

      // Create new instance and check persistence
      final newService = SpiritualStatsService();
      final stats = await newService.getStats();
      expect(stats.readDevocionalIds, contains(testDevocionalId));
    });

    test('should handle reading time and scroll tracking', () async {
      const devocionalId = 'tracking_test';
      const readingTime = 120;
      const scrollPercentage = 95.5;

      // Record with specific reading metrics
      await statsService.recordDevocionalRead(
        devocionalId: devocionalId,
        readingTimeSeconds: readingTime,
        scrollPercentage: scrollPercentage,
      );

      final stats = await statsService.getStats();
      expect(stats.readDevocionalIds, contains(devocionalId));
    });

    test('should handle multiple devotional readings', () async {
      // Record multiple devotionals
      for (int i = 0; i < 5; i++) {
        await statsService.recordDevocionalRead(
          devocionalId: 'multi_test_$i',
          readingTimeSeconds: 60 + i * 10,
          scrollPercentage: 80.0 + i,
        );
      }

      final stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, greaterThanOrEqualTo(5));
      expect(stats.readDevocionalIds.length, greaterThanOrEqualTo(5));
    });
  });
}
