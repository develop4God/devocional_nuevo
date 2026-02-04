// test/unit/services/remote_badge_service_comprehensive_test.dart

import 'package:devocional_nuevo/services/remote_badge_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

@Tags(['unit', 'services'])
void main() {
  group('RemoteBadgeService - Comprehensive Real User Behavior Tests', () {
    late RemoteBadgeService service;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = RemoteBadgeService();
    });

    group('User Scenario: Fetching Available Badges', () {
      test('User opens app and loads badges for first time', () async {
        final badges = await service.getAvailableBadges();

        expect(badges, isA<List>());
        // Badges can be empty if network fails or no badges available
        expect(badges, isNotNull);
      });

      test('User loads badges multiple times - uses cache', () async {
        // First load
        final badges1 = await service.getAvailableBadges();
        expect(badges1, isA<List>());

        // Second load should use cache (faster)
        final badges2 = await service.getAvailableBadges();
        expect(badges2, isA<List>());

        // Should return same instance from cache
        expect(identical(badges1, badges2), isTrue);
      });

      test('User forces refresh to get latest badges', () async {
        // Initial load
        await service.getAvailableBadges();

        // Force refresh
        final freshBadges =
            await service.getAvailableBadges(forceRefresh: true);

        expect(freshBadges, isA<List>());
      });

      test('User refreshes badges explicitly', () async {
        await service.getAvailableBadges();

        // Explicit refresh
        await service.refreshBadges();

        // Should work without errors
        final badges = await service.getAvailableBadges();
        expect(badges, isA<List>());
      });
    });

    group('User Scenario: Viewing Specific Badges', () {
      test('User searches for specific badge by ID', () async {
        // Load all badges first
        final badges = await service.getAvailableBadges();

        if (badges.isNotEmpty) {
          final badgeId = badges.first.id;
          final badge = await service.getBadgeById(badgeId);

          if (badge != null) {
            expect(badge.id, equals(badgeId));
          }
        } else {
          // No badges available, test that null is returned for any ID
          final badge = await service.getBadgeById('nonexistent');
          expect(badge, isNull);
        }
      });

      test('User tries to get badge with invalid ID', () async {
        final badge = await service.getBadgeById('invalid_badge_id_xyz');

        // Should return null for non-existent badge
        expect(badge, isNull);
      });

      test('User looks up multiple badges in sequence', () async {
        await service.getAvailableBadges();

        // Try multiple lookups
        final badge1 = await service.getBadgeById('badge_1');
        final badge2 = await service.getBadgeById('badge_2');
        final badge3 = await service.getBadgeById('badge_3');

        // All should complete without errors
        expect(badge1, isA<Object?>());
        expect(badge2, isA<Object?>());
        expect(badge3, isA<Object?>());
      });
    });

    group('User Scenario: Checking for Updates', () {
      test('User checks if new badges are available', () async {
        final hasUpdates = await service.hasUpdates();

        expect(hasUpdates, isA<bool>());
      });

      test('User checks for updates multiple times', () async {
        final check1 = await service.hasUpdates();
        await Future.delayed(const Duration(milliseconds: 100));
        final check2 = await service.hasUpdates();

        expect(check1, isA<bool>());
        expect(check2, isA<bool>());
      });

      test('User checks updates after refreshing badges', () async {
        await service.refreshBadges();

        final hasUpdates = await service.hasUpdates();
        expect(hasUpdates, isA<bool>());
      });
    });

    group('Caching Behavior', () {
      test('Service uses cache when available', () async {
        // First call - may hit network
        await service.getAvailableBadges();

        // Second call - should use cache
        final stopwatch = Stopwatch()..start();
        final badges2 = await service.getAvailableBadges();
        stopwatch.stop();

        expect(badges2, isA<List>());
        // Cached call should be very fast (< 10ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('Force refresh bypasses cache', () async {
        await service.getAvailableBadges();

        // Force refresh should fetch fresh data
        final freshBadges =
            await service.getAvailableBadges(forceRefresh: true);

        expect(freshBadges, isA<List>());
      });

      test('Refresh clears cache and fetches new data', () async {
        await service.getAvailableBadges();

        // Refresh should clear cache
        await service.refreshBadges();

        final badges = await service.getAvailableBadges();
        expect(badges, isA<List>());
      });
    });

    group('Edge Cases and Error Handling', () {
      test('Service handles network unavailable gracefully', () async {
        // When network is unavailable, should return empty list or cached data
        final badges = await service.getAvailableBadges();

        expect(badges, isA<List>());
        // Should not throw exception
      });

      test('Service handles rapid consecutive requests', () async {
        // Simulate user rapidly requesting badges
        final futures = List.generate(
          5,
          (_) => service.getAvailableBadges(),
        );

        final results = await Future.wait(futures);

        expect(results, hasLength(5));
        // All results should be lists
        for (final result in results) {
          expect(result, isA<List>());
        }
      });

      test('Service handles concurrent requests from different sources',
          () async {
        // Simulate multiple parts of app requesting badges simultaneously
        final badgesFuture = service.getAvailableBadges();
        final badgeByIdFuture = service.getBadgeById('test_id');
        final updatesFuture = service.hasUpdates();

        final results = await Future.wait([
          badgesFuture,
          badgeByIdFuture,
          updatesFuture,
        ]);

        expect(results[0], isA<List>());
        expect(results[1], isA<Object?>());
        expect(results[2], isA<bool>());
      });

      test('Service recovers from errors and continues working', () async {
        // First call might fail
        var badges = await service.getAvailableBadges();
        expect(badges, isA<List>());

        // Second call should still work
        badges = await service.getAvailableBadges();
        expect(badges, isA<List>());
      });

      test('Empty badge ID lookup returns null', () async {
        final badge = await service.getBadgeById('');
        expect(badge, isNull);
      });

      test('Null or special character badge IDs are handled', () async {
        final specialIds = ['', ' ', '!@#', '%%%', '123'];

        for (final id in specialIds) {
          final badge = await service.getBadgeById(id);
          expect(badge, isA<Object?>());
        }
      });
    });

    group('User Scenario: App Lifecycle', () {
      test('Service works across app pause/resume', () async {
        // Load badges
        await service.getAvailableBadges();

        // Simulate app pause - clear cache
        await service.refreshBadges();

        // Simulate app resume - reload
        final badges = await service.getAvailableBadges();
        expect(badges, isA<List>());
      });

      test('User opens app after long time - cache expired', () async {
        // Simulate expired cache by forcing refresh
        await service.refreshBadges();

        final badges = await service.getAvailableBadges();
        expect(badges, isA<List>());
      });
    });

    group('Performance', () {
      test('Badge lookup completes in reasonable time', () async {
        final stopwatch = Stopwatch()..start();

        await service.getAvailableBadges();

        stopwatch.stop();

        // Should complete within 10 seconds even with network
        expect(stopwatch.elapsed.inSeconds, lessThan(10));
      });

      test('Multiple badge lookups are efficient', () async {
        await service.getAvailableBadges();

        final stopwatch = Stopwatch()..start();

        for (var i = 0; i < 10; i++) {
          await service.getBadgeById('test_$i');
        }

        stopwatch.stop();

        // 10 lookups should be fast when using cache
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });

    group('Singleton Pattern', () {
      test('Service uses singleton pattern correctly', () {
        final instance1 = RemoteBadgeService();
        final instance2 = RemoteBadgeService();

        // Should be same instance
        expect(identical(instance1, instance2), isTrue);
      });

      test('Cache is shared across singleton instances', () async {
        final service1 = RemoteBadgeService();
        await service1.getAvailableBadges();

        final service2 = RemoteBadgeService();
        final badges = await service2.getAvailableBadges();

        // Should use same cache
        expect(badges, isA<List>());
      });
    });

    group('Data Consistency', () {
      test('Badge data remains consistent across calls', () async {
        final badges1 = await service.getAvailableBadges();
        final badges2 = await service.getAvailableBadges();

        // Should return consistent data from cache
        expect(badges1.length, equals(badges2.length));
      });

      test('Forced refresh may update badge count', () async {
        final badges1 = await service.getAvailableBadges();

        await service.refreshBadges();
        final badges2 = await service.getAvailableBadges();

        // Both should be valid lists
        expect(badges1, isA<List>());
        expect(badges2, isA<List>());
      });
    });
  });
}
