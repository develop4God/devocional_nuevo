@Tags(['unit', 'services'])
library;

// test/unit/services/in_app_review_service_test.dart

import 'package:devocional_nuevo/services/in_app_review_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Real behavioral tests for InAppReviewService.shouldShowReviewRequest.
///
/// Drives the actual service through SharedPreferences state combinations
/// instead of re-asserting copied constants, so a regression in the
/// service's milestone/cooldown logic actually fails these tests.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('shouldShowReviewRequest — milestones', () {
    test('returns true at first milestone (5) with no prior state', () async {
      final result = await InAppReviewService.shouldShowReviewRequest(5);
      expect(result, isTrue);
    });

    test('returns true at each milestone (25, 50, 100, 200)', () async {
      for (final milestone in [25, 50, 100, 200]) {
        SharedPreferences.setMockInitialValues({
          'review_first_time_check_done': true,
        });
        final result = await InAppReviewService.shouldShowReviewRequest(
          milestone,
        );
        expect(result, isTrue, reason: '$milestone should trigger a review');
      }
    });

    test('returns false for a non-milestone count', () async {
      SharedPreferences.setMockInitialValues({
        'review_first_time_check_done': true,
      });
      final result = await InAppReviewService.shouldShowReviewRequest(42);
      expect(result, isFalse);
    });
  });

  group('shouldShowReviewRequest — user opt-out state', () {
    test('returns false when user already rated the app', () async {
      SharedPreferences.setMockInitialValues({'user_rated_app': true});
      final result = await InAppReviewService.shouldShowReviewRequest(25);
      expect(result, isFalse);
    });

    test('returns false when user chose never ask again', () async {
      SharedPreferences.setMockInitialValues({
        'never_ask_review_again': true,
      });
      final result = await InAppReviewService.shouldShowReviewRequest(25);
      expect(result, isFalse);
    });
  });

  group('shouldShowReviewRequest — first-time check', () {
    test(
      'first-time user with 5+ devotionals triggers review before any milestone check',
      () async {
        final result = await InAppReviewService.shouldShowReviewRequest(10);
        expect(result, isTrue);
      },
    );

    test('marks first-time check done after triggering', () async {
      await InAppReviewService.shouldShowReviewRequest(10);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('review_first_time_check_done'), isTrue);
    });

    test(
      'does not re-trigger first-time check on a later non-milestone call',
      () async {
        await InAppReviewService.shouldShowReviewRequest(10);

        final result = await InAppReviewService.shouldShowReviewRequest(11);
        expect(result, isFalse);
      },
    );
  });

  group('shouldShowReviewRequest — cooldown periods', () {
    test('global cooldown blocks review within 90 days', () async {
      final recent = DateTime.now().subtract(const Duration(days: 10));
      SharedPreferences.setMockInitialValues({
        'review_first_time_check_done': true,
        'last_review_request_date': recent.millisecondsSinceEpoch ~/ 1000,
      });

      final result = await InAppReviewService.shouldShowReviewRequest(25);
      expect(result, isFalse);
    });

    test('global cooldown allows review after 90+ days', () async {
      final old = DateTime.now().subtract(const Duration(days: 91));
      SharedPreferences.setMockInitialValues({
        'review_first_time_check_done': true,
        'last_review_request_date': old.millisecondsSinceEpoch ~/ 1000,
      });

      final result = await InAppReviewService.shouldShowReviewRequest(25);
      expect(result, isTrue);
    });

    test('remind-later cooldown blocks review within 30 days', () async {
      final recent = DateTime.now().subtract(const Duration(days: 5));
      SharedPreferences.setMockInitialValues({
        'review_first_time_check_done': true,
        'review_remind_later_date': recent.millisecondsSinceEpoch ~/ 1000,
      });

      final result = await InAppReviewService.shouldShowReviewRequest(25);
      expect(result, isFalse);
    });

    test('remind-later cooldown allows review after 30+ days', () async {
      final old = DateTime.now().subtract(const Duration(days: 31));
      SharedPreferences.setMockInitialValues({
        'review_first_time_check_done': true,
        'review_remind_later_date': old.millisecondsSinceEpoch ~/ 1000,
      });

      final result = await InAppReviewService.shouldShowReviewRequest(25);
      expect(result, isTrue);
    });
  });

  group('shouldShowReviewRequest — error resilience', () {
    test('never throws for edge-case counts', () async {
      for (final count in [0, -1, 1000000]) {
        await expectLater(
          InAppReviewService.shouldShowReviewRequest(count),
          completes,
        );
      }
    });
  });

  group('clearAllPreferences', () {
    test('resets all review state so milestones can trigger again', () async {
      SharedPreferences.setMockInitialValues({
        'user_rated_app': true,
        'never_ask_review_again': true,
        'review_first_time_check_done': true,
      });

      await InAppReviewService.clearAllPreferences();

      final result = await InAppReviewService.shouldShowReviewRequest(5);
      expect(result, isTrue);
    });
  });
}
