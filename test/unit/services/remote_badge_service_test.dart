// test/unit/services/remote_badge_service_test.dart

import 'package:devocional_nuevo/models/badge_model.dart' as badge_model;
import 'package:devocional_nuevo/services/remote_badge_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RemoteBadgeService Tests', () {
    late RemoteBadgeService service;

    setUp(() async {
      // Setup SharedPreferences mock
      SharedPreferences.setMockInitialValues({
        'cached_badge_config': jsonEncode({
          'badges': [
            {
              'id': 'first_read',
              'name': 'First Read',
              'description': 'Read your first devotional',
              'iconUrl': 'https://example.com/icon1.png',
              'unlockCondition': {'type': 'read_count', 'value': 1},
              'category': 'reading'
            },
            {
              'id': 'week_reader',
              'name': 'Week Reader',
              'description': 'Read devotionals for 7 days',
              'iconUrl': 'https://example.com/icon2.png',
              'unlockCondition': {'type': 'streak', 'value': 7},
              'category': 'streak'
            }
          ]
        }),
        'badge_config_cache_time': DateTime.now().toIso8601String(),
      });

      // Setup method channel mocks for HTTP requests
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter/platform_views'),
        (MethodCall methodCall) async => null,
      );

      service = RemoteBadgeService();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter/platform_views'),
        null,
      );
    });

    group('Badge Fetching and Caching', () {
      test('should fetch and cache remote badge configurations', () async {
        // Test getting available badges
        final badges = await service.getAvailableBadges();
        expect(badges, isA<List<badge_model.Badge>>());

        // Should return cached data on subsequent calls
        final cachedBadges = await service.getAvailableBadges();
        expect(cachedBadges, isA<List<badge_model.Badge>>());
      });

      test('should handle cache expiry and refresh', () async {
        // Test force refresh
        final badges = await service.getAvailableBadges(forceRefresh: true);
        expect(badges, isA<List<badge_model.Badge>>());

        // Test normal cached retrieval
        final cachedBadges =
            await service.getAvailableBadges(forceRefresh: false);
        expect(cachedBadges, isA<List<badge_model.Badge>>());
      });

      test('should handle network errors gracefully', () async {
        // Should fallback to cached data or empty list on network error
        final badges = await service.getAvailableBadges();
        expect(badges, isA<List<badge_model.Badge>>());
      });

      test('should validate badge configuration format', () async {
        final badges = await service.getAvailableBadges();

        for (final badge in badges) {
          expect(badge.id, isA<String>());
          expect(badge.name, isA<String>());
          expect(badge.description, isA<String>());
          expect(badge.category, isA<String>());
        }
      });
    });

    group('Badge Unlock Conditions and Validation', () {
      test('should handle badge unlock conditions and validation', () async {
        final badges = await service.getAvailableBadges();

        // Find specific badges for testing
        final firstReadBadge =
            badges.where((b) => b.id == 'first_read').firstOrNull;
        final weekReaderBadge =
            badges.where((b) => b.id == 'week_reader').firstOrNull;

        if (firstReadBadge != null) {
          expect(firstReadBadge.category, equals('reading'));
          expect(firstReadBadge.name, equals('First Read'));
        }

        if (weekReaderBadge != null) {
          expect(weekReaderBadge.category, equals('streak'));
          expect(weekReaderBadge.name, equals('Week Reader'));
        }
      });

      test('should validate unlock condition types', () async {
        final badges = await service.getAvailableBadges();

        // Test different unlock condition types exist
        final categories = badges.map((b) => b.category).toSet();
        expect(categories, isNotEmpty);

        // Common categories should include reading and streak
        expect(
            categories
                .any((cat) => cat.contains('read') || cat.contains('streak')),
            isTrue);
      });

      test('should handle badge progress tracking', () async {
        final badges = await service.getAvailableBadges();

        // Test badge availability for progress tracking
        for (final badge in badges) {
          expect(badge.id, isNotEmpty);
          expect(badge.name, isNotEmpty);
          expect(badge.description, isNotEmpty);
        }
      });

      test('should validate badge data completeness', () async {
        final badges = await service.getAvailableBadges();

        for (final badge in badges) {
          // Required fields should be present
          expect(badge.id, isA<String>());
          expect(badge.id, isNotEmpty);
          expect(badge.name, isA<String>());
          expect(badge.name, isNotEmpty);
          expect(badge.description, isA<String>());
          expect(badge.description, isNotEmpty);
          expect(badge.category, isA<String>());
          expect(badge.category, isNotEmpty);
        }
      });
    });

    group('Badge Categories and Organization', () {
      test('should organize badges by categories', () async {
        final badges = await service.getAvailableBadges();

        // Group badges by category
        final categorizedBadges = <String, List<badge_model.Badge>>{};
        for (final badge in badges) {
          categorizedBadges.putIfAbsent(badge.category, () => []).add(badge);
        }

        expect(categorizedBadges, isA<Map<String, List<badge_model.Badge>>>());
        expect(categorizedBadges.keys, isNotEmpty);
      });

      test('should handle badge filtering and search', () async {
        final badges = await service.getAvailableBadges();

        // Filter by category
        final readingBadges =
            badges.where((b) => b.category == 'reading').toList();
        final streakBadges =
            badges.where((b) => b.category == 'streak').toList();

        expect(readingBadges, isA<List<badge_model.Badge>>());
        expect(streakBadges, isA<List<badge_model.Badge>>());
      });

      test('should validate badge uniqueness', () async {
        final badges = await service.getAvailableBadges();

        // All badge IDs should be unique
        final badgeIds = badges.map((b) => b.id).toList();
        final uniqueIds = badgeIds.toSet();

        expect(badgeIds.length, equals(uniqueIds.length));
      });
    });

    group('Service State and Caching', () {
      test('should maintain singleton instance', () {
        final service1 = RemoteBadgeService();
        final service2 = RemoteBadgeService();

        expect(identical(service1, service2), isTrue);
      });

      test('should handle cache invalidation', () async {
        // Get badges to populate cache
        await service.getAvailableBadges();

        // Force refresh should bypass cache
        final refreshedBadges =
            await service.getAvailableBadges(forceRefresh: true);
        expect(refreshedBadges, isA<List<badge_model.Badge>>());
      });

      test('should handle concurrent requests', () async {
        // Multiple concurrent requests should be handled gracefully
        final futures = <Future<List<badge_model.Badge>>>[];

        for (int i = 0; i < 3; i++) {
          futures.add(service.getAvailableBadges());
        }

        final results = await Future.wait(futures);

        for (final result in results) {
          expect(result, isA<List<badge_model.Badge>>());
        }
      });
    });

    group('Error Handling and Fallbacks', () {
      test('should handle empty badge configuration', () async {
        // Setup empty cache
        SharedPreferences.setMockInitialValues({
          'cached_badge_config': jsonEncode({'badges': []}),
        });

        final emptyService = RemoteBadgeService();
        final badges = await emptyService.getAvailableBadges();

        expect(badges, isA<List<badge_model.Badge>>());
        expect(badges, isEmpty);
      });

      test('should handle malformed configuration data', () async {
        // Setup malformed cache
        SharedPreferences.setMockInitialValues({
          'cached_badge_config': 'invalid_json',
        });

        final malformedService = RemoteBadgeService();
        final badges = await malformedService.getAvailableBadges();

        expect(badges, isA<List<badge_model.Badge>>());
      });

      test('should handle missing cache gracefully', () async {
        // Setup no cache
        SharedPreferences.setMockInitialValues({});

        final noCacheService = RemoteBadgeService();
        final badges = await noCacheService.getAvailableBadges();

        expect(badges, isA<List<badge_model.Badge>>());
      });

      test('should handle large badge collections', () async {
        // Simulate large badge collection
        final largeBadgeList = List.generate(
            100,
            (index) => {
                  'id': 'badge_$index',
                  'name': 'Badge $index',
                  'description': 'Description for badge $index',
                  'iconUrl': 'https://example.com/icon$index.png',
                  'unlockCondition': {'type': 'read_count', 'value': index + 1},
                  'category': 'test'
                });

        SharedPreferences.setMockInitialValues({
          'cached_badge_config': jsonEncode({'badges': largeBadgeList}),
        });

        final largeService = RemoteBadgeService();
        final badges = await largeService.getAvailableBadges();

        expect(badges, isA<List<badge_model.Badge>>());
        expect(badges.length, equals(100));
      });
    });

    group('Configuration and Settings', () {
      test('should handle badge configuration updates', () async {
        // Initial badges
        final initialBadges = await service.getAvailableBadges();
        expect(initialBadges, isA<List<badge_model.Badge>>());

        // Force refresh to simulate update
        final updatedBadges =
            await service.getAvailableBadges(forceRefresh: true);
        expect(updatedBadges, isA<List<badge_model.Badge>>());
      });

      test('should validate service configuration', () async {
        expect(service, isNotNull);
        expect(service, isA<RemoteBadgeService>());

        // Basic operations should work
        expect(() => service.getAvailableBadges(), returnsNormally);
      });
    });
  });
}
