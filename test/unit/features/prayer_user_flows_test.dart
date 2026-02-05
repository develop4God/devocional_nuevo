@Tags(['critical', 'unit', 'features'])
library;

// test/critical_coverage/prayer_user_flows_test.dart
// High-value user behavior tests for Prayer functionality

import 'package:devocional_nuevo/models/prayer_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Prayer Model - User Behavior Tests', () {
    // SCENARIO 1: User creates a new prayer
    test('user creates new prayer with all required fields', () {
      final prayer = Prayer(
        id: '123',
        text: 'Please help my family',
        createdDate: DateTime.now(),
        status: PrayerStatus.active,
      );

      expect(prayer.id, equals('123'));
      expect(prayer.text, equals('Please help my family'));
      expect(prayer.isActive, isTrue);
      expect(prayer.isAnswered, isFalse);
      expect(prayer.answeredDate, isNull);
      expect(prayer.answeredComment, isNull);
    });

    // SCENARIO 2: User marks prayer as answered
    test('user marks prayer as answered with comment', () {
      final prayer = Prayer(
        id: '123',
        text: 'Please help my family',
        createdDate: DateTime.now().subtract(const Duration(days: 30)),
        status: PrayerStatus.active,
      );

      final answeredPrayer = prayer.copyWith(
        status: PrayerStatus.answered,
        answeredDate: DateTime.now(),
        answeredComment: 'God answered my prayer!',
      );

      expect(answeredPrayer.isActive, isFalse);
      expect(answeredPrayer.isAnswered, isTrue);
      expect(answeredPrayer.answeredDate, isNotNull);
      expect(answeredPrayer.answeredComment, equals('God answered my prayer!'));
    });

    // SCENARIO 3: User edits prayer text
    test('user edits prayer text preserving other fields', () {
      final originalPrayer = Prayer(
        id: '123',
        text: 'Original prayer',
        createdDate: DateTime(2025, 1, 1),
        status: PrayerStatus.active,
      );

      final editedPrayer = originalPrayer.copyWith(text: 'Updated prayer text');

      expect(editedPrayer.id, equals('123'));
      expect(editedPrayer.text, equals('Updated prayer text'));
      expect(editedPrayer.createdDate, equals(DateTime(2025, 1, 1)));
      expect(editedPrayer.status, equals(PrayerStatus.active));
    });

    // SCENARIO 4: User reactivates answered prayer
    test('user reactivates answered prayer clearing answer data', () {
      final answeredPrayer = Prayer(
        id: '123',
        text: 'My prayer',
        createdDate: DateTime.now().subtract(const Duration(days: 60)),
        status: PrayerStatus.answered,
        answeredDate: DateTime.now().subtract(const Duration(days: 30)),
        answeredComment: 'Was answered!',
      );

      final reactivatedPrayer = answeredPrayer.copyWith(
        status: PrayerStatus.active,
        clearAnsweredDate: true,
        clearAnsweredComment: true,
      );

      expect(reactivatedPrayer.isActive, isTrue);
      expect(reactivatedPrayer.answeredDate, isNull);
      expect(reactivatedPrayer.answeredComment, isNull);
    });

    // SCENARIO 5: Calculate days since prayer creation
    test('daysOld calculates correctly for various ages', () {
      final oldPrayer = Prayer(
        id: '1',
        text: 'Old prayer',
        createdDate: DateTime.now().subtract(const Duration(days: 100)),
        status: PrayerStatus.active,
      );

      final newPrayer = Prayer(
        id: '2',
        text: 'New prayer',
        createdDate: DateTime.now(),
        status: PrayerStatus.active,
      );

      expect(oldPrayer.daysOld, equals(100));
      expect(newPrayer.daysOld, equals(0));
    });

    // SCENARIO 6: JSON serialization round-trip
    test('prayer survives JSON serialization round-trip', () {
      final original = Prayer(
        id: 'prayer-001',
        text: 'Test prayer with special chars: ñ, é, 日本語',
        createdDate: DateTime(2025, 6, 15, 10, 30, 0),
        status: PrayerStatus.answered,
        answeredDate: DateTime(2025, 7, 1, 14, 0, 0),
        answeredComment: 'Answered with blessings!',
      );

      final json = original.toJson();
      final restored = Prayer.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.text, equals(original.text));
      expect(restored.status, equals(original.status));
      expect(restored.answeredComment, equals(original.answeredComment));
    });

    // SCENARIO 7: Handle malformed JSON gracefully
    test('fromJson handles missing and malformed data gracefully', () {
      // Missing most fields
      final minimalJson = <String, dynamic>{};
      final minimalPrayer = Prayer.fromJson(minimalJson);
      expect(minimalPrayer.text, equals(''));
      expect(minimalPrayer.status, equals(PrayerStatus.active));

      // Invalid date format
      final badDateJson = {
        'id': '123',
        'text': 'Test',
        'createdDate': 'not-a-date',
        'status': 'active',
      };
      final badDatePrayer = Prayer.fromJson(badDateJson);
      expect(badDatePrayer.createdDate.year, equals(DateTime.now().year));

      // Unknown status
      final unknownStatusJson = {
        'id': '123',
        'text': 'Test',
        'status': 'unknown_status',
      };
      final unknownStatusPrayer = Prayer.fromJson(unknownStatusJson);
      expect(unknownStatusPrayer.status, equals(PrayerStatus.active));
    });

    // SCENARIO 8: Status enum conversions
    test('PrayerStatus enum converts correctly', () {
      expect(PrayerStatus.active.toString(), equals('active'));
      expect(PrayerStatus.answered.toString(), equals('answered'));

      expect(PrayerStatus.fromString('active'), equals(PrayerStatus.active));
      expect(
        PrayerStatus.fromString('answered'),
        equals(PrayerStatus.answered),
      );
      expect(PrayerStatus.fromString('ACTIVE'), equals(PrayerStatus.active));
      expect(PrayerStatus.fromString('invalid'), equals(PrayerStatus.active));
    });

    // SCENARIO 9: Edge case - very long prayer text
    test('handles very long prayer text', () {
      final longText = 'Prayer ' * 1000; // 7000+ chars
      final prayer = Prayer(
        id: 'long-prayer',
        text: longText,
        createdDate: DateTime.now(),
        status: PrayerStatus.active,
      );

      expect(prayer.text.length, greaterThan(5000));

      final json = prayer.toJson();
      final restored = Prayer.fromJson(json);
      expect(restored.text, equals(longText));
    });

    // SCENARIO 10: Edge case - prayer created at midnight
    test('handles prayers created at edge time boundaries', () {
      final midnightPrayer = Prayer(
        id: 'midnight',
        text: 'Midnight prayer',
        createdDate: DateTime(2025, 1, 1, 0, 0, 0),
        status: PrayerStatus.active,
      );

      final endOfDayPrayer = Prayer(
        id: 'eod',
        text: 'End of day prayer',
        createdDate: DateTime(2025, 12, 31, 23, 59, 59),
        status: PrayerStatus.active,
      );

      expect(midnightPrayer.createdDate.hour, equals(0));
      expect(endOfDayPrayer.createdDate.hour, equals(23));

      final midnightJson = midnightPrayer.toJson();
      final restoredMidnight = Prayer.fromJson(midnightJson);
      expect(restoredMidnight.createdDate.hour, equals(0));
    });
  });

  group('Prayer Sorting & Filtering - User Flows', () {
    late List<Prayer> prayers;

    setUp(() {
      prayers = [
        Prayer(
          id: '1',
          text: 'Old active prayer',
          createdDate: DateTime.now().subtract(const Duration(days: 30)),
          status: PrayerStatus.active,
        ),
        Prayer(
          id: '2',
          text: 'Recent active prayer',
          createdDate: DateTime.now().subtract(const Duration(days: 1)),
          status: PrayerStatus.active,
        ),
        Prayer(
          id: '3',
          text: 'Answered prayer',
          createdDate: DateTime.now().subtract(const Duration(days: 60)),
          status: PrayerStatus.answered,
          answeredDate: DateTime.now().subtract(const Duration(days: 5)),
        ),
        Prayer(
          id: '4',
          text: 'New prayer',
          createdDate: DateTime.now(),
          status: PrayerStatus.active,
        ),
      ];
    });

    test('user filters to see only active prayers', () {
      final activePrayers = prayers.where((p) => p.isActive).toList();

      expect(activePrayers.length, equals(3));
      expect(activePrayers.every((p) => p.isActive), isTrue);
    });

    test('user filters to see only answered prayers', () {
      final answeredPrayers = prayers.where((p) => p.isAnswered).toList();

      expect(answeredPrayers.length, equals(1));
      expect(answeredPrayers.first.id, equals('3'));
    });

    test('user sorts prayers by creation date (newest first)', () {
      final sorted = List<Prayer>.from(prayers)
        ..sort((a, b) => b.createdDate.compareTo(a.createdDate));

      expect(sorted.first.id, equals('4')); // Newest
      expect(sorted.last.id, equals('3')); // Oldest
    });

    test('user sorts prayers by days old (oldest first)', () {
      final sorted = List<Prayer>.from(prayers)
        ..sort((a, b) => b.daysOld.compareTo(a.daysOld));

      expect(sorted.first.id, equals('3')); // Oldest (60 days)
      expect(sorted.last.id, equals('4')); // Newest (0 days)
    });

    test('user searches prayers by text content', () {
      final searchResults = prayers
          .where((p) => p.text.toLowerCase().contains('active'))
          .toList();

      expect(searchResults.length, equals(2));
    });

    test('user counts prayers by status', () {
      final activeCount = prayers.where((p) => p.isActive).length;
      final answeredCount = prayers.where((p) => p.isAnswered).length;

      expect(activeCount, equals(3));
      expect(answeredCount, equals(1));
    });
  });

  group('Prayer Statistics - User Insights', () {
    test('calculate prayer answer rate', () {
      final prayers = [
        Prayer(
          id: '1',
          text: 'P1',
          createdDate: DateTime.now(),
          status: PrayerStatus.active,
        ),
        Prayer(
          id: '2',
          text: 'P2',
          createdDate: DateTime.now(),
          status: PrayerStatus.answered,
        ),
        Prayer(
          id: '3',
          text: 'P3',
          createdDate: DateTime.now(),
          status: PrayerStatus.answered,
        ),
        Prayer(
          id: '4',
          text: 'P4',
          createdDate: DateTime.now(),
          status: PrayerStatus.active,
        ),
      ];

      final totalPrayers = prayers.length;
      final answeredPrayers = prayers.where((p) => p.isAnswered).length;
      final answerRate =
          totalPrayers > 0 ? (answeredPrayers / totalPrayers) * 100 : 0.0;

      expect(answerRate, equals(50.0)); // 2/4 = 50%
    });

    test('calculate average days to answer', () {
      final answeredPrayers = [
        Prayer(
          id: '1',
          text: 'P1',
          createdDate: DateTime.now().subtract(const Duration(days: 30)),
          status: PrayerStatus.answered,
          answeredDate: DateTime.now().subtract(const Duration(days: 20)),
        ),
        Prayer(
          id: '2',
          text: 'P2',
          createdDate: DateTime.now().subtract(const Duration(days: 60)),
          status: PrayerStatus.answered,
          answeredDate: DateTime.now().subtract(const Duration(days: 40)),
        ),
      ];

      int totalDays = 0;
      for (final prayer in answeredPrayers) {
        if (prayer.answeredDate != null) {
          totalDays +=
              prayer.answeredDate!.difference(prayer.createdDate).inDays;
        }
      }
      final avgDays = totalDays / answeredPrayers.length;

      expect(avgDays, equals(15.0)); // (10 + 20) / 2 = 15
    });

    test('identify longest waiting active prayer', () {
      final prayers = [
        Prayer(
          id: '1',
          text: 'P1',
          createdDate: DateTime.now().subtract(const Duration(days: 10)),
          status: PrayerStatus.active,
        ),
        Prayer(
          id: '2',
          text: 'P2',
          createdDate: DateTime.now().subtract(const Duration(days: 100)),
          status: PrayerStatus.active,
        ),
        Prayer(
          id: '3',
          text: 'P3',
          createdDate: DateTime.now().subtract(const Duration(days: 50)),
          status: PrayerStatus.active,
        ),
      ];

      final activePrayers = prayers.where((p) => p.isActive).toList();
      activePrayers.sort((a, b) => b.daysOld.compareTo(a.daysOld));
      final longestWaiting = activePrayers.first;

      expect(longestWaiting.id, equals('2'));
      expect(longestWaiting.daysOld, equals(100));
    });
  });
}
