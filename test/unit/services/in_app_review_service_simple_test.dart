// test/unit/services/in_app_review_service_simple_test.dart
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

    group('shouldShowReviewRequest', () {
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

      test('should return true for first-time users with 5+ devotionals', () async {
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

      test('should return false for first-time users with less than 5 devotionals', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act
        final result = await InAppReviewService.shouldShowReviewRequest(4);

        // Assert
        expect(result, isFalse);
      });

      test('should respect milestone thresholds', () async {
        // Arrange - User already had first time check done
        SharedPreferences.setMockInitialValues({
          'review_first_time_check_done': true,
        });

        final milestones = [5, 25, 50, 100, 200];
        
        for (final milestone in milestones) {
          // Reset SharedPreferences but keep first time check done
          SharedPreferences.setMockInitialValues({
            'review_first_time_check_done': true,
          });

          // Act
          final result = await InAppReviewService.shouldShowReviewRequest(milestone);

          // Assert
          expect(result, isTrue, reason: 'Milestone $milestone should trigger review');
        }
      });

      test('should return false for non-milestone devotional counts', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'review_first_time_check_done': true,
        });

        final nonMilestones = [6, 10, 24, 26, 49, 51, 99, 101, 150, 199, 250];
        
        for (final count in nonMilestones) {
          // Reset SharedPreferences
          SharedPreferences.setMockInitialValues({
            'review_first_time_check_done': true,
          });

          // Act
          final result = await InAppReviewService.shouldShowReviewRequest(count);

          // Assert
          expect(result, isFalse, reason: 'Count $count should not trigger review');
        }
      });

      test('should handle remind later cooldown period', () async {
        // Arrange - Set remind later date to 20 days ago (within 30-day cooldown)
        final remindLaterDate = DateTime.now().subtract(const Duration(days: 20));
        SharedPreferences.setMockInitialValues({
          'review_first_time_check_done': true,
          'review_remind_later_date': remindLaterDate.millisecondsSinceEpoch,
        });

        // Act
        final result = await InAppReviewService.shouldShowReviewRequest(50);

        // Assert
        expect(result, isFalse);
      });

      test('should show review after remind later cooldown expires', () async {
        // Arrange - Set remind later date to 40 days ago (beyond 30-day cooldown)
        final remindLaterDate = DateTime.now().subtract(const Duration(days: 40));
        SharedPreferences.setMockInitialValues({
          'review_first_time_check_done': true,
          'review_remind_later_date': remindLaterDate.millisecondsSinceEpoch,
        });

        // Act
        final result = await InAppReviewService.shouldShowReviewRequest(100);

        // Assert
        expect(result, isTrue);
      });

      test('should respect global cooldown period between reviews', () async {
        // Arrange - Set last review request to 60 days ago (within 90-day cooldown)
        final lastRequestDate = DateTime.now().subtract(const Duration(days: 60));
        SharedPreferences.setMockInitialValues({
          'review_first_time_check_done': true,
          'last_review_request_date': lastRequestDate.millisecondsSinceEpoch,
        });

        // Act
        final result = await InAppReviewService.shouldShowReviewRequest(200);

        // Assert
        expect(result, isFalse);
      });

      test('should show review after global cooldown expires', () async {
        // Arrange - Set last review request to 100 days ago (beyond 90-day cooldown)
        final lastRequestDate = DateTime.now().subtract(const Duration(days: 100));
        SharedPreferences.setMockInitialValues({
          'review_first_time_check_done': true,
          'last_review_request_date': lastRequestDate.millisecondsSinceEpoch,
        });

        // Act
        final result = await InAppReviewService.shouldShowReviewRequest(200);

        // Assert
        expect(result, isTrue);
      });

      test('should limit review requests to maximum count', () async {
        // Arrange - Set review request count to 3 (maximum allowed)
        SharedPreferences.setMockInitialValues({
          'review_first_time_check_done': true,
          'review_request_count': 3,
        });

        // Act
        final result = await InAppReviewService.shouldShowReviewRequest(200);

        // Assert
        expect(result, isFalse);
      });

      test('should allow review requests below maximum count', () async {
        // Arrange - Set review request count to 2 (below maximum)
        SharedPreferences.setMockInitialValues({
          'review_first_time_check_done': true,
          'review_request_count': 2,
        });

        // Act
        final result = await InAppReviewService.shouldShowReviewRequest(200);

        // Assert
        expect(result, isTrue);
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
        expect(prefs.getString('other_unrelated_pref'), equals('should_remain'));
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
    });

    group('checkAndShow integration', () {
      test('should complete without errors when context is not mounted', () async {
        // Arrange
        when(() => mockContext.mounted).thenReturn(false);
        final stats = SpiritualStats(totalDevocionalesRead: 50);

        // Act & Assert - Should complete gracefully
        await expectLater(
          InAppReviewService.checkAndShow(stats, mockContext),
          completes,
        );
      });

      test('should handle SpiritualStats with various devotional counts', () async {
        // Arrange
        when(() => mockContext.mounted).thenReturn(true);
        
        final testCounts = [0, 1, 4, 5, 10, 25, 49, 50, 99, 100, 200, 500];
        
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

      test('should handle exceptions gracefully without crashing app', () async {
        // Arrange
        when(() => mockContext.mounted).thenReturn(true);
        final stats = SpiritualStats(totalDevocionalesRead: 50);

        // Act & Assert - Should complete even if internal errors occur
        await expectLater(
          InAppReviewService.checkAndShow(stats, mockContext),
          completes,
        );
      });
    });

    group('performance and reliability', () {
      test('should complete shouldShowReviewRequest within reasonable time', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'review_first_time_check_done': true,
          'review_request_count': 1,
          'last_review_request_date': DateTime.now().subtract(const Duration(days: 100)).millisecondsSinceEpoch,
        });

        // Act
        final stopwatch = Stopwatch()..start();
        await InAppReviewService.shouldShowReviewRequest(100);
        stopwatch.stop();

        // Assert - Should complete quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(100),
            reason: 'shouldShowReviewRequest took too long: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should handle high-frequency calls efficiently', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'review_first_time_check_done': true,
        });

        // Act - High frequency calls
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 50; i++) {
          await InAppReviewService.shouldShowReviewRequest(50);
        }
        
        stopwatch.stop();

        // Assert - Should complete reasonably quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(2000),
            reason: '50 calls took too long: ${stopwatch.elapsedMilliseconds}ms');
      });
    });
  });
}