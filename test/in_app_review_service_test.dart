import 'package:devocional_nuevo/services/in_app_review_service.dart';
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
      for (final count in [1, 2, 3, 4, 6, 10, 15, 24, 26, 49, 51, 99, 101, 150, 199, 201]) {
        final shouldShow = await InAppReviewService.shouldShowReviewRequest(count);
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
      await prefs.setInt('last_review_request_date', lastRequest.millisecondsSinceEpoch ~/ 1000);
      
      final shouldShow = await InAppReviewService.shouldShowReviewRequest(5);
      expect(shouldShow, isFalse);
    });

    test('should allow review after 90-day global cooldown expires', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // Set last request to 91 days ago (cooldown expired)
      final lastRequest = DateTime.now().subtract(const Duration(days: 91));
      await prefs.setInt('last_review_request_date', lastRequest.millisecondsSinceEpoch ~/ 1000);
      
      final shouldShow = await InAppReviewService.shouldShowReviewRequest(25);
      expect(shouldShow, isTrue);
    });

    test('should respect 30-day remind later cooldown', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // Set remind later to 29 days ago (within cooldown)
      final remindLater = DateTime.now().subtract(const Duration(days: 29));
      await prefs.setInt('review_remind_later_date', remindLater.millisecondsSinceEpoch ~/ 1000);
      
      final shouldShow = await InAppReviewService.shouldShowReviewRequest(5);
      expect(shouldShow, isFalse);
    });

    test('should allow review after 30-day remind later cooldown expires', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // Set remind later to 31 days ago (cooldown expired)
      final remindLater = DateTime.now().subtract(const Duration(days: 31));
      await prefs.setInt('review_remind_later_date', remindLater.millisecondsSinceEpoch ~/ 1000);
      
      final shouldShow = await InAppReviewService.shouldShowReviewRequest(50);
      expect(shouldShow, isTrue);
    });

    test('clearAllPreferences should reset all review state', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // Set all preferences
      await prefs.setBool('user_rated_app', true);
      await prefs.setBool('never_ask_review_again', true);
      await prefs.setInt('review_remind_later_date', DateTime.now().millisecondsSinceEpoch ~/ 1000);
      await prefs.setInt('review_request_count', 5);
      await prefs.setInt('last_review_request_date', DateTime.now().millisecondsSinceEpoch ~/ 1000);
      
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
  });
}