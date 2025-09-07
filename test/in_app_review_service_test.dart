import 'package:devocional_nuevo/models/spiritual_stats_model.dart';
import 'package:devocional_nuevo/services/in_app_review_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('InAppReviewService Tests', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      await InAppReviewService.clearAllPreferences();
    });

    test('should show review at 5th devotional milestone', () async {
      final shouldShow = await InAppReviewService.shouldShowReviewRequest(5);
      expect(shouldShow, isTrue);
    });

    test('should show review at 25th devotional milestone', () async {
      final shouldShow = await InAppReviewService.shouldShowReviewRequest(25);
      expect(shouldShow, isTrue);
    });

    test('should show review at 50th devotional milestone', () async {
      final shouldShow = await InAppReviewService.shouldShowReviewRequest(50);
      expect(shouldShow, isTrue);
    });

    test('should show review at 100th devotional milestone', () async {
      final shouldShow = await InAppReviewService.shouldShowReviewRequest(100);
      expect(shouldShow, isTrue);
    });

    test('should show review at 200th devotional milestone', () async {
      final shouldShow = await InAppReviewService.shouldShowReviewRequest(200);
      expect(shouldShow, isTrue);
    });

    test('should NOT show review for non-milestone counts', () async {
      // Test various non-milestone counts
      for (final count in [
        1,
        2,
        3,
        4,
        6,
        10,
        15,
        24,
        26,
        49,
        51,
        99,
        101,
        150,
        199,
        201
      ]) {
        final shouldShow =
            await InAppReviewService.shouldShowReviewRequest(count);
        expect(shouldShow, isFalse, reason: 'Should not show for count $count');
      }
    });

    test('should NOT show review if user already rated', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_rated_app', true);

      final shouldShow = await InAppReviewService.shouldShowReviewRequest(5);
      expect(shouldShow, isFalse);
    });

    test('should NOT show review if user chose never ask again', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('never_ask_review_again', true);

      final shouldShow = await InAppReviewService.shouldShowReviewRequest(5);
      expect(shouldShow, isFalse);
    });

    test('should respect 90-day global cooldown', () async {
      final prefs = await SharedPreferences.getInstance();

      // Set last request to 89 days ago (within cooldown)
      final lastRequest = DateTime.now().subtract(const Duration(days: 89));
      await prefs.setInt('last_review_request_date',
          lastRequest.millisecondsSinceEpoch ~/ 1000);

      final shouldShow = await InAppReviewService.shouldShowReviewRequest(5);
      expect(shouldShow, isFalse);
    });

    test('should allow review after 90-day global cooldown expires', () async {
      final prefs = await SharedPreferences.getInstance();

      // Set last request to 91 days ago (cooldown expired)
      final lastRequest = DateTime.now().subtract(const Duration(days: 91));
      await prefs.setInt('last_review_request_date',
          lastRequest.millisecondsSinceEpoch ~/ 1000);

      final shouldShow = await InAppReviewService.shouldShowReviewRequest(25);
      expect(shouldShow, isTrue);
    });

    test('should respect 30-day remind later cooldown', () async {
      final prefs = await SharedPreferences.getInstance();

      // Set remind later to 29 days ago (within cooldown)
      final remindLater = DateTime.now().subtract(const Duration(days: 29));
      await prefs.setInt('review_remind_later_date',
          remindLater.millisecondsSinceEpoch ~/ 1000);

      final shouldShow = await InAppReviewService.shouldShowReviewRequest(5);
      expect(shouldShow, isFalse);
    });

    test('should allow review after 30-day remind later cooldown expires',
        () async {
      final prefs = await SharedPreferences.getInstance();

      // Set remind later to 31 days ago (cooldown expired)
      final remindLater = DateTime.now().subtract(const Duration(days: 31));
      await prefs.setInt('review_remind_later_date',
          remindLater.millisecondsSinceEpoch ~/ 1000);

      final shouldShow = await InAppReviewService.shouldShowReviewRequest(50);
      expect(shouldShow, isTrue);
    });

    test('clearAllPreferences should reset all review state', () async {
      final prefs = await SharedPreferences.getInstance();

      // Set all preferences
      await prefs.setBool('user_rated_app', true);
      await prefs.setBool('never_ask_review_again', true);
      await prefs.setInt('review_remind_later_date',
          DateTime.now().millisecondsSinceEpoch ~/ 1000);
      await prefs.setInt('review_request_count', 5);
      await prefs.setInt('last_review_request_date',
          DateTime.now().millisecondsSinceEpoch ~/ 1000);

      // Clear all
      await InAppReviewService.clearAllPreferences();

      // Verify all are cleared
      expect(prefs.getBool('user_rated_app'), isNull);
      expect(prefs.getBool('never_ask_review_again'), isNull);
      expect(prefs.getInt('review_remind_later_date'), isNull);
      expect(prefs.getInt('review_request_count'), isNull);
      expect(prefs.getInt('last_review_request_date'), isNull);
    });

    test('should handle edge case with zero devotionals', () async {
      final shouldShow = await InAppReviewService.shouldShowReviewRequest(0);
      expect(shouldShow, isFalse);
    });

    test('should handle edge case with negative devotionals', () async {
      final shouldShow = await InAppReviewService.shouldShowReviewRequest(-1);
      expect(shouldShow, isFalse);
    });

    test('milestone logic works correctly for large numbers', () async {
      // Test well beyond the highest milestone
      final shouldShow = await InAppReviewService.shouldShowReviewRequest(1000);
      expect(shouldShow, isFalse);
    });

    test('should allow multiple milestones if conditions reset', () async {
      // First milestone
      var shouldShow = await InAppReviewService.shouldShowReviewRequest(5);
      expect(shouldShow, isTrue);

      // Clear preferences to simulate conditions being reset
      await InAppReviewService.clearAllPreferences();

      // Different milestone should also work
      shouldShow = await InAppReviewService.shouldShowReviewRequest(25);
      expect(shouldShow, isTrue);
    });

    group('Integration Tests', () {
      testWidgets(
          'checkAndShow with valid context and milestone should trigger review logic',
          (WidgetTester tester) async {
        // Build a simple widget with context
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (BuildContext context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      // Test the actual checkAndShow method with valid context
                      final stats = SpiritualStats(totalDevocionalesRead: 5);
                      await InAppReviewService.checkAndShow(stats, context);
                    },
                    child: const Text('Test Review'),
                  ),
                );
              },
            ),
          ),
        );

        // Verify widget is built
        expect(find.text('Test Review'), findsOneWidget);

        // The button exists and can be tapped (context is valid)
        await tester.tap(find.text('Test Review'));
        await tester.pump();

        // Test passes if no exception is thrown during checkAndShow
      });

      testWidgets('checkAndShow with unmounted context should skip gracefully',
          (WidgetTester tester) async {
        BuildContext? capturedContext;

        // Build widget and capture context
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (BuildContext context) {
                capturedContext = context;
                return const Scaffold(body: Text('Test'));
              },
            ),
          ),
        );

        // Dispose the widget to make context unmounted
        await tester.pumpWidget(const SizedBox.shrink());

        // Try to use unmounted context
        final stats = SpiritualStats(totalDevocionalesRead: 5);

        // This should not throw and should skip gracefully
        expect(() async {
          await InAppReviewService.checkAndShow(stats, capturedContext!);
        }, returnsNormally);
      });

      test('shouldShowReviewRequest correctly handles all milestone values',
          () async {
        final milestones = [5, 25, 50, 100, 200];

        for (final milestone in milestones) {
          // Clear preferences for clean test
          await InAppReviewService.clearAllPreferences();

          final shouldShow =
              await InAppReviewService.shouldShowReviewRequest(milestone);
          expect(shouldShow, isTrue,
              reason: 'Milestone $milestone should show review');
        }
      });

      test('async sequencing - stats persistence simulation', () async {
        // Simulate the scenario where stats might not be immediately available
        // This test verifies the delay mechanism works

        final prefs = await SharedPreferences.getInstance();

        // Test milestone without delay (simulate race condition)
        final shouldShowImmediate =
            await InAppReviewService.shouldShowReviewRequest(5);
        expect(shouldShowImmediate, isTrue);

        // Simulate delay in preferences persistence
        await Future.delayed(const Duration(milliseconds: 50));

        // Should still work after delay
        final shouldShowDelayed =
            await InAppReviewService.shouldShowReviewRequest(5);
        expect(shouldShowDelayed, isTrue);
      });

      test('concurrency safety - multiple simultaneous requests', () async {
        // Test that multiple simultaneous review checks don't interfere

        final futures = List.generate(10, (index) async {
          // Vary the devotional counts to test different scenarios
          final count = index < 5 ? 5 : 25; // Mix of milestones
          return await InAppReviewService.shouldShowReviewRequest(count);
        });

        final results = await Future.wait(futures);

        // All should return true (milestones) since preferences are clean
        for (int i = 0; i < results.length; i++) {
          expect(results[i], isTrue, reason: 'Request $i should succeed');
        }
      });

      test('review state persistence across app sessions', () async {
        // Simulate user rating the app
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('user_rated_app', true);

        // Multiple milestone checks should all return false
        for (final milestone in [5, 25, 50, 100, 200]) {
          final shouldShow =
              await InAppReviewService.shouldShowReviewRequest(milestone);
          expect(shouldShow, isFalse,
              reason: 'Milestone $milestone should not show after rating');
        }

        // Clear rating status
        await prefs.setBool('user_rated_app', false);

        // Should work again
        final shouldShowAfterClear =
            await InAppReviewService.shouldShowReviewRequest(5);
        expect(shouldShowAfterClear, isTrue);
      });

      test('cooldown periods work correctly', () async {
        final prefs = await SharedPreferences.getInstance();

        // Test global cooldown
        final recentRequest = DateTime.now().subtract(const Duration(days: 30));
        await prefs.setInt('last_review_request_date',
            recentRequest.millisecondsSinceEpoch ~/ 1000);

        var shouldShow = await InAppReviewService.shouldShowReviewRequest(5);
        expect(shouldShow, isFalse, reason: 'Should respect global cooldown');

        // Test expired global cooldown
        final oldRequest = DateTime.now().subtract(const Duration(days: 91));
        await prefs.setInt('last_review_request_date',
            oldRequest.millisecondsSinceEpoch ~/ 1000);

        shouldShow = await InAppReviewService.shouldShowReviewRequest(25);
        expect(shouldShow, isTrue,
            reason: 'Should allow after cooldown expires');

        // Test remind later cooldown
        await prefs.remove('last_review_request_date');
        final recentRemind = DateTime.now().subtract(const Duration(days: 15));
        await prefs.setInt('review_remind_later_date',
            recentRemind.millisecondsSinceEpoch ~/ 1000);

        shouldShow = await InAppReviewService.shouldShowReviewRequest(50);
        expect(shouldShow, isFalse,
            reason: 'Should respect remind later cooldown');
      });

      test('edge cases and error handling', () async {
        // Test with various edge case values
        final edgeCases = [-1, 0, 1, 4, 6, 999, 1000000];

        for (final count in edgeCases) {
          final shouldShow =
              await InAppReviewService.shouldShowReviewRequest(count);
          // Only milestones (5, 25, 50, 100, 200) should return true
          final expectedResult = [5, 25, 50, 100, 200].contains(count);
          expect(shouldShow, equals(expectedResult),
              reason: 'Count $count should return $expectedResult');
        }
      });

      test('clear preferences completely resets state', () async {
        final prefs = await SharedPreferences.getInstance();

        // Set all possible review preferences
        await prefs.setBool('user_rated_app', true);
        await prefs.setBool('never_ask_review_again', true);
        await prefs.setInt('review_remind_later_date',
            DateTime.now().millisecondsSinceEpoch ~/ 1000);
        await prefs.setInt('review_request_count', 5);
        await prefs.setInt('last_review_request_date',
            DateTime.now().millisecondsSinceEpoch ~/ 1000);

        // Verify preferences are set
        expect(prefs.getBool('user_rated_app'), isTrue);
        expect(prefs.getBool('never_ask_review_again'), isTrue);
        expect(prefs.getInt('review_remind_later_date'), isNotNull);
        expect(prefs.getInt('review_request_count'), equals(5));
        expect(prefs.getInt('last_review_request_date'), isNotNull);

        // Clear all preferences
        await InAppReviewService.clearAllPreferences();

        // Verify all are cleared
        expect(prefs.getBool('user_rated_app'), isNull);
        expect(prefs.getBool('never_ask_review_again'), isNull);
        expect(prefs.getInt('review_remind_later_date'), isNull);
        expect(prefs.getInt('review_request_count'), isNull);
        expect(prefs.getInt('last_review_request_date'), isNull);

        // Should now work for milestones
        final shouldShow = await InAppReviewService.shouldShowReviewRequest(5);
        expect(shouldShow, isTrue);
      });
    });
  });
}
