// test/critical_coverage/spiritual_stats_service_working_test.dart

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:devocional_nuevo/models/spiritual_stats_model.dart';

void main() {
  group('SpiritualStatsService Working Tests', () {
    late SpiritualStatsService statsService;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      // Reset SharedPreferences for each test
      SharedPreferences.setMockInitialValues({});

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
        readingTimeSeconds: 60,
        scrollPercentage: 80.0,
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
        readingTimeSeconds: 60,
        scrollPercentage: 80.0,
      );
      await statsService.recordDevocionalRead(
        devocionalId: devocionalId,
        readingTimeSeconds: 60,
        scrollPercentage: 80.0,
      );

      final stats = await statsService.getStats();
      // Should not have duplicates
      final occurrences =
          stats.readDevocionalIds.where((id) => id == devocionalId).length;
      expect(occurrences, equals(1));
    });

    test('should handle favorites count in devotional recording', () async {
      const devocionalId = 'favorites_test';

      // Record devotional with favorites count
      await statsService.recordDevocionalRead(
        devocionalId: devocionalId,
        readingTimeSeconds: 60,
        scrollPercentage: 80.0,
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
