import 'package:devocional_nuevo/services/in_app_review_service.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_setup.dart';

void main() {
  group('Devocionales Tracking Integration Tests', () {
    setUp(() async {
      TestSetup.setupCommonMocks();
      SharedPreferences.setMockInitialValues({});

      // Clear all review preferences
      await InAppReviewService.clearAllPreferences();

      // Reset spiritual stats
      await SpiritualStatsService().resetStats();
    });

    tearDown(() async {
      TestSetup.cleanupMocks();
    });

    test(
        'Stats service correctly records devotionals and triggers review logic',
        () async {
      final statsService = SpiritualStatsService();

      // Record 4 devotionals (should not trigger review)
      for (int i = 1; i <= 4; i++) {
        await statsService.recordDevocionalRead(
          devocionalId: 'test_$i',
          readingTimeSeconds: 120,
          scrollPercentage: 0.9,
        );
      }

      // Verify 4 devotionals recorded
      var stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, equals(4));

      // Check if review would be triggered (should be false)
      var shouldShow = await InAppReviewService.shouldShowReviewRequest(
          stats.totalDevocionalesRead);
      expect(shouldShow, isFalse,
          reason: '4 devotionals should not trigger review');

      // Record 5th devotional (should trigger review logic)
      await statsService.recordDevocionalRead(
        devocionalId: 'test_5',
        readingTimeSeconds: 120,
        scrollPercentage: 0.9,
      );

      // Add delay (simulating the fix in the integration)
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify 5 devotionals recorded
      stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, equals(5));

      // Check if review would be triggered (should be true)
      shouldShow = await InAppReviewService.shouldShowReviewRequest(
          stats.totalDevocionalesRead);
      expect(shouldShow, isTrue, reason: '5 devotionals should trigger review');
    });

    test('Audio completion also triggers review logic', () async {
      final statsService = SpiritualStatsService();

      // Record 4 reading devotionals
      for (int i = 1; i <= 4; i++) {
        await statsService.recordDevocionalRead(
          devocionalId: 'read_$i',
          readingTimeSeconds: 80,
          scrollPercentage: 0.85,
        );
      }

      // Record 1 audio devotional to reach milestone
      await statsService.recordDevotionalHeard(
        devocionalId: 'audio_5',
        listenedPercentage: 0.9,
      );

      // Add delay
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify 5 total devotionals
      final stats = await statsService.getStats();
      expect(stats.totalDevocionalesRead, equals(5));

      // Should trigger review
      final shouldShow = await InAppReviewService.shouldShowReviewRequest(
          stats.totalDevocionalesRead);
      expect(shouldShow, isTrue,
          reason: 'Mixed reading/audio to 5 should trigger review');
    });

    test('All milestone values work correctly', () async {
      final milestones = [5, 25, 50, 100, 200];

      for (final milestone in milestones) {
        // Clear review preferences for clean test
        await InAppReviewService.clearAllPreferences();

        final shouldShow =
            await InAppReviewService.shouldShowReviewRequest(milestone);
        expect(shouldShow, isTrue,
            reason: 'Milestone $milestone should trigger review');
      }
    });

    test('Review state persistence works correctly', () async {
      // Test user already rated scenario
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_rated_app', true);

      var shouldShow = await InAppReviewService.shouldShowReviewRequest(5);
      expect(shouldShow, isFalse,
          reason: 'Should not show if user already rated');

      // Test never ask again scenario
      await prefs.setBool('user_rated_app', false);
      await prefs.setBool('never_ask_review_again', true);

      shouldShow = await InAppReviewService.shouldShowReviewRequest(25);
      expect(shouldShow, isFalse,
          reason: 'Should not show if user chose never ask again');

      // Clear all restrictions
      await InAppReviewService.clearAllPreferences();

      shouldShow = await InAppReviewService.shouldShowReviewRequest(50);
      expect(shouldShow, isTrue,
          reason: 'Should show after clearing restrictions');
    });

    test('Cooldown periods prevent over-prompting', () async {
      final prefs = await SharedPreferences.getInstance();

      // Test global cooldown (89 days ago - still within 90 days)
      final recentRequest = DateTime.now().subtract(const Duration(days: 89));
      await prefs.setInt('last_review_request_date',
          recentRequest.millisecondsSinceEpoch ~/ 1000);

      var shouldShow = await InAppReviewService.shouldShowReviewRequest(100);
      expect(shouldShow, isFalse, reason: 'Should respect global cooldown');

      // Test expired cooldown (91 days ago)
      final oldRequest = DateTime.now().subtract(const Duration(days: 91));
      await prefs.setInt('last_review_request_date',
          oldRequest.millisecondsSinceEpoch ~/ 1000);

      shouldShow = await InAppReviewService.shouldShowReviewRequest(100);
      expect(shouldShow, isTrue, reason: 'Should allow after cooldown expires');

      // Test remind later cooldown
      await prefs.remove('last_review_request_date');
      final remindLater = DateTime.now().subtract(const Duration(days: 15));
      await prefs.setInt('review_remind_later_date',
          remindLater.millisecondsSinceEpoch ~/ 1000);

      shouldShow = await InAppReviewService.shouldShowReviewRequest(200);
      expect(shouldShow, isFalse,
          reason: 'Should respect remind later cooldown');
    });

    test('Sequential recording maintains correct count', () async {
      final statsService = SpiritualStatsService();

      // Record devotionals one by one
      for (int i = 1; i <= 7; i++) {
        await statsService.recordDevocionalRead(
          devocionalId: 'sequential_$i',
          readingTimeSeconds: 70,
          scrollPercentage: 0.82,
        );

        final stats = await statsService.getStats();
        expect(stats.totalDevocionalesRead, equals(i),
            reason: 'Count should be $i after $i recordings');

        // Check milestone detection
        final shouldShow = await InAppReviewService.shouldShowReviewRequest(
            stats.totalDevocionalesRead);
        if (i == 5) {
          expect(shouldShow, isTrue,
              reason: 'Should trigger review at 5th devotional');
        } else {
          expect(shouldShow, isFalse,
              reason: 'Should not trigger review at $i devotionals');
        }

        // Clear review state for next iteration (except user preferences)
        if (i == 5) {
          await InAppReviewService.clearAllPreferences();
        }
      }
    });

    test('Review request frequency limits work', () async {
      // Test that after showing review once, cooldown prevents immediate re-showing

      // First milestone should show
      await InAppReviewService.clearAllPreferences();
      var shouldShow = await InAppReviewService.shouldShowReviewRequest(5);
      expect(shouldShow, isTrue);

      // Simulate review attempt (this sets last_review_request_date)
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await prefs.setInt('last_review_request_date', now);
      await prefs.setInt('review_request_count', 1);

      // Same milestone should not show again immediately
      shouldShow = await InAppReviewService.shouldShowReviewRequest(5);
      expect(shouldShow, isFalse, reason: 'Should not show again immediately');

      // Next milestone should also not show due to cooldown
      shouldShow = await InAppReviewService.shouldShowReviewRequest(25);
      expect(shouldShow, isFalse,
          reason: 'Should not show next milestone during cooldown');
    });

    test('Error handling ensures stats recording is not affected', () async {
      // Even if review logic fails, devotional recording should work

      final statsService = SpiritualStatsService();

      // This should work regardless of review check status
      final stats = await statsService.recordDevocionalRead(
        devocionalId: 'error_safe_test',
        readingTimeSeconds: 95,
        scrollPercentage: 0.87,
      );

      expect(stats.totalDevocionalesRead, equals(1));
      expect(stats.readDevocionalIds, contains('error_safe_test'));

      // Stats should be retrievable
      final retrievedStats = await statsService.getStats();
      expect(retrievedStats.totalDevocionalesRead, equals(1));
      expect(retrievedStats.readDevocionalIds, contains('error_safe_test'));
    });
  });
}
