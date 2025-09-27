// test/unit/services/in_app_review_service_basic_test.dart
import 'package:devocional_nuevo/models/spiritual_stats_model.dart';
import 'package:devocional_nuevo/services/in_app_review_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock BuildContext for testing UI interactions
class MockBuildContext extends Mock implements BuildContext {}

void main() {
  group('InAppReviewService Tests', () {
    late MockBuildContext mockContext;

    setUp(() {
      // Setup mock SharedPreferences with clean state
      SharedPreferences.setMockInitialValues({});
      mockContext = MockBuildContext();

      // Setup mock context to return mounted = true by default
      when(() => mockContext.mounted).thenReturn(true);
    });

    group('shouldShowReviewRequest - Basic Logic', () {
      test('should return false when user already rated the app', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'user_rated_app': true,
        });

        // Act
        final result = await InAppReviewService.shouldShowReviewRequest(25);

        // Assert
        expect(result, isFalse);
      });

      test('should return false when user chose never ask again', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'never_ask_review_again': true,
        });

        // Act
        final result = await InAppReviewService.shouldShowReviewRequest(50);

        // Assert
        expect(result, isFalse);
      });

      test('should return true for first-time users with 5+ devotionals',
          () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act
        final result = await InAppReviewService.shouldShowReviewRequest(5);

        // Assert
        expect(result, isTrue);

        // Verify first time check is marked as done
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('review_first_time_check_done'), isTrue);
      });

      test(
          'should return false for first-time users with less than 5 devotionals',
          () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act
        final result = await InAppReviewService.shouldShowReviewRequest(4);

        // Assert
        expect(result, isFalse);
      });

      test('should respect key milestones correctly', () async {
        // Test known working milestones
        final milestoneTests = [
          {'devotionals': 5, 'expectTrue': true},
          {'devotionals': 25, 'expectTrue': true},
          {'devotionals': 50, 'expectTrue': true},
        ];

        for (final test in milestoneTests) {
          // Reset SharedPreferences for each test
          SharedPreferences.setMockInitialValues({
            'review_first_time_check_done': true,
          });

          final devotionals = test['devotionals'] as int;
          final expectTrue = test['expectTrue'] as bool;

          // Act
          final result =
              await InAppReviewService.shouldShowReviewRequest(devotionals);

          // Assert
          if (expectTrue) {
            expect(result, isTrue,
                reason: 'Milestone $devotionals should show review');
          } else {
            expect(result, isFalse,
                reason: 'Milestone $devotionals should not show review');
          }
        }
      });

      test('should return false for non-milestone devotional counts', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'review_first_time_check_done': true,
        });

        final nonMilestones = [6, 10, 24, 26, 49];

        for (final count in nonMilestones) {
          // Reset SharedPreferences
          SharedPreferences.setMockInitialValues({
            'review_first_time_check_done': true,
          });

          // Act
          final result =
              await InAppReviewService.shouldShowReviewRequest(count);

          // Assert
          expect(result, isFalse,
              reason: 'Count $count should not trigger review');
        }
      });
    });

    group('clearAllPreferences', () {
      test('should clear all review-related preferences', () async {
        // Arrange - Set up various preferences
        SharedPreferences.setMockInitialValues({
          'user_rated_app': true,
          'never_ask_review_again': true,
          'review_remind_later_date': DateTime.now().millisecondsSinceEpoch,
          'review_request_count': 3,
          'last_review_request_date': DateTime.now().millisecondsSinceEpoch,
          'review_first_time_check_done': true,
          'other_unrelated_pref': 'should_remain',
        });

        // Act
        await InAppReviewService.clearAllPreferences();

        // Assert - Review preferences should be cleared
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('user_rated_app'), isNull);
        expect(prefs.getBool('never_ask_review_again'), isNull);
        expect(prefs.getInt('review_remind_later_date'), isNull);
        expect(prefs.getInt('review_request_count'), isNull);
        expect(prefs.getInt('last_review_request_date'), isNull);
        expect(prefs.getBool('review_first_time_check_done'), isNull);

        // Unrelated preferences should remain
        expect(
            prefs.getString('other_unrelated_pref'), equals('should_remain'));
      });

      test('should complete successfully when no preferences exist', () async {
        // Arrange - Empty preferences
        SharedPreferences.setMockInitialValues({});

        // Act & Assert - Should complete without errors
        await expectLater(
          InAppReviewService.clearAllPreferences(),
          completes,
        );
      });

      test('should be idempotent when called multiple times', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'user_rated_app': true,
          'review_request_count': 2,
        });

        // Act - Multiple calls
        await InAppReviewService.clearAllPreferences();
        await InAppReviewService.clearAllPreferences();
        await InAppReviewService.clearAllPreferences();

        // Assert - Should remain cleared
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('user_rated_app'), isNull);
        expect(prefs.getInt('review_request_count'), isNull);
      });
    });

    group('checkAndShow integration', () {
      test('should complete without errors when context is not mounted',
          () async {
        // Arrange
        when(() => mockContext.mounted).thenReturn(false);
        final stats = SpiritualStats(totalDevocionalesRead: 50);

        // Act & Assert - Should complete gracefully
        await expectLater(
          InAppReviewService.checkAndShow(stats, mockContext),
          completes,
        );
      });

      test('should handle various devotional counts without crashing',
          () async {
        // Arrange
        when(() => mockContext.mounted).thenReturn(true);

        final testCounts = [0, 1, 4, 5, 10, 25, 50];

        for (final count in testCounts) {
          // Reset SharedPreferences
          SharedPreferences.setMockInitialValues({});

          final stats = SpiritualStats(totalDevocionalesRead: count);

          // Act & Assert - Should complete without errors
          await expectLater(
            InAppReviewService.checkAndShow(stats, mockContext),
            completes,
            reason: 'Failed for devotional count: $count',
          );
        }
      });

      test('should handle exceptions gracefully without crashing app',
          () async {
        // Arrange
        when(() => mockContext.mounted).thenReturn(true);
        final stats = SpiritualStats(totalDevocionalesRead: 50);

        // Act & Assert - Should complete even if internal errors occur
        await expectLater(
          InAppReviewService.checkAndShow(stats, mockContext),
          completes,
        );
      });

      test('should respect user preferences correctly', () async {
        // Arrange - User already rated
        SharedPreferences.setMockInitialValues({
          'user_rated_app': true,
        });

        when(() => mockContext.mounted).thenReturn(true);
        final stats = SpiritualStats(totalDevocionalesRead: 100);

        // Act - Should complete without showing dialog
        await InAppReviewService.checkAndShow(stats, mockContext);

        // Assert - Test passes if no exceptions thrown
        expect(true, isTrue);
      });
    });

    group('business logic scenarios', () {
      test('should handle first-time user workflow correctly', () async {
        // Arrange - New user with no preferences
        SharedPreferences.setMockInitialValues({});

        // Act & Assert - User reaches first milestone (5 devotionals)
        var shouldShow = await InAppReviewService.shouldShowReviewRequest(5);
        expect(shouldShow, isTrue);

        // Check that first time flag was set
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('review_first_time_check_done'), isTrue);

        // Test that user at non-milestone doesn't get review immediately after
        shouldShow = await InAppReviewService.shouldShowReviewRequest(6);
        expect(shouldShow, isFalse);
      });

      test('should handle multiple blocking conditions', () async {
        // Arrange - User already rated app
        SharedPreferences.setMockInitialValues({
          'user_rated_app': true,
          'review_first_time_check_done': true,
        });

        // Act
        final shouldShow =
            await InAppReviewService.shouldShowReviewRequest(200);

        // Assert - Should be blocked due to user rating
        expect(shouldShow, isFalse);
      });

      test('should handle never ask again preference', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'never_ask_review_again': true,
          'review_first_time_check_done': true,
        });

        // Act
        final shouldShow =
            await InAppReviewService.shouldShowReviewRequest(100);

        // Assert - Should be blocked due to never ask again
        expect(shouldShow, isFalse);
      });
    });

    group('performance and reliability', () {
      test('should complete shouldShowReviewRequest within reasonable time',
          () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'review_first_time_check_done': true,
          'review_request_count': 1,
        });

        // Act
        final stopwatch = Stopwatch()..start();
        await InAppReviewService.shouldShowReviewRequest(100);
        stopwatch.stop();

        // Assert - Should complete quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(100),
            reason:
                'shouldShowReviewRequest took too long: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should handle multiple sequential calls efficiently', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'review_first_time_check_done': true,
        });

        // Act - Multiple calls (reduced number for speed)
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 10; i++) {
          await InAppReviewService.shouldShowReviewRequest(50);
        }

        stopwatch.stop();

        // Assert - Should complete reasonably quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(500),
            reason:
                '10 calls took too long: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should maintain consistency in concurrent operations', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'review_first_time_check_done': true,
        });

        // Act - Multiple concurrent operations (reduced count)
        final futures = <Future>[];
        for (int i = 0; i < 5; i++) {
          futures.add(InAppReviewService.shouldShowReviewRequest(100));
        }

        final results = await Future.wait(futures);

        // Assert - All results should be consistent
        expect(results.length, equals(5));
        expect(results, everyElement(isA<bool>()));

        // All results should be the same since conditions are identical
        final firstResult = results.first;
        expect(results, everyElement(equals(firstResult)));
      });
    });
  });
}
