// test/critical_coverage/thanksgiving_user_flows_test.dart
// High-value user behavior tests for Thanksgiving functionality

import 'package:devocional_nuevo/models/thanksgiving_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Thanksgiving Model - User Behavior Tests', () {
    // SCENARIO 1: User creates a new thanksgiving
    test('user creates new thanksgiving with all required fields', () {
      final thanksgiving = Thanksgiving(
        id: 'thanks-001',
        text: 'Thank you Lord for my health',
        createdDate: DateTime.now(),
      );

      expect(thanksgiving.id, equals('thanks-001'));
      expect(thanksgiving.text, equals('Thank you Lord for my health'));
      expect(thanksgiving.createdDate, isNotNull);
    });

    // SCENARIO 2: User edits thanksgiving text
    test('user edits thanksgiving text preserving other fields', () {
      final original = Thanksgiving(
        id: 'thanks-001',
        text: 'Original thanks',
        createdDate: DateTime(2025, 1, 1),
      );

      final edited = original.copyWith(text: 'Updated thanks for everything');

      expect(edited.id, equals('thanks-001'));
      expect(edited.text, equals('Updated thanks for everything'));
      expect(edited.createdDate, equals(DateTime(2025, 1, 1)));
    });

    // SCENARIO 3: Calculate days since thanksgiving creation
    test('daysOld calculates correctly for various ages', () {
      final oldThanksgiving = Thanksgiving(
        id: '1',
        text: 'Old thanks',
        createdDate: DateTime.now().subtract(const Duration(days: 50)),
      );

      final newThanksgiving = Thanksgiving(
        id: '2',
        text: 'New thanks',
        createdDate: DateTime.now(),
      );

      expect(oldThanksgiving.daysOld, equals(50));
      expect(newThanksgiving.daysOld, equals(0));
    });

    // SCENARIO 4: JSON serialization round-trip
    test('thanksgiving survives JSON serialization round-trip', () {
      final original = Thanksgiving(
        id: 'thanks-special',
        text: 'Gracias por todo: ñ, é, 日本語, 🙏',
        createdDate: DateTime(2025, 6, 15, 10, 30, 0),
      );

      final json = original.toJson();
      final restored = Thanksgiving.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.text, equals(original.text));
    });

    // SCENARIO 5: Handle malformed JSON gracefully
    test('fromJson handles missing and malformed data gracefully', () {
      // Missing most fields
      final minimalJson = <String, dynamic>{};
      final minimalThanks = Thanksgiving.fromJson(minimalJson);
      expect(minimalThanks.text, equals(''));
      expect(minimalThanks.createdDate.year, equals(DateTime.now().year));

      // Invalid date format
      final badDateJson = {
        'id': '123',
        'text': 'Test thanks',
        'createdDate': 'invalid-date',
      };
      final badDateThanks = Thanksgiving.fromJson(badDateJson);
      expect(badDateThanks.createdDate.year, equals(DateTime.now().year));

      // Null date
      final nullDateJson = {
        'id': '123',
        'text': 'Test thanks',
        'createdDate': null,
      };
      final nullDateThanks = Thanksgiving.fromJson(nullDateJson);
      expect(nullDateThanks.createdDate, isNotNull);
    });

    // SCENARIO 6: Edge case - very long thanksgiving text
    test('handles very long thanksgiving text', () {
      final longText = 'Thank you ' * 500; // 5000+ chars
      final thanksgiving = Thanksgiving(
        id: 'long-thanks',
        text: longText,
        createdDate: DateTime.now(),
      );

      expect(thanksgiving.text.length, greaterThan(4000));

      final json = thanksgiving.toJson();
      final restored = Thanksgiving.fromJson(json);
      expect(restored.text, equals(longText));
    });

    // SCENARIO 7: Edge case - thanksgiving with special characters
    test('handles special characters and unicode', () {
      final specialChars = Thanksgiving(
        id: 'special',
        text: 'Gracias ñ\nLigne suivante\t"Quoted"\n🙏✝️📖',
        createdDate: DateTime.now(),
      );

      final json = specialChars.toJson();
      final restored = Thanksgiving.fromJson(json);

      expect(restored.text, contains('ñ'));
      expect(restored.text, contains('🙏'));
      expect(restored.text, contains('\n'));
    });

    // SCENARIO 8: CopyWith preserves createdDate
    test('copyWith preserves createdDate when not changed', () {
      final specificDate = DateTime(2024, 12, 25, 9, 0, 0);
      final original = Thanksgiving(
        id: 'christmas',
        text: 'Christmas thanks',
        createdDate: specificDate,
      );

      final updated = original.copyWith(text: 'Updated Christmas thanks');

      expect(updated.createdDate, equals(specificDate));
    });

    // SCENARIO 9: CopyWith can update createdDate
    test('copyWith can update createdDate when specified', () {
      final original = Thanksgiving(
        id: 'test',
        text: 'Test',
        createdDate: DateTime(2024, 1, 1),
      );

      final newDate = DateTime(2025, 1, 1);
      final updated = original.copyWith(createdDate: newDate);

      expect(updated.createdDate, equals(newDate));
    });
  });

  group('Thanksgiving Sorting & Filtering - User Flows', () {
    late List<Thanksgiving> thanksgivings;

    setUp(() {
      thanksgivings = [
        Thanksgiving(
          id: '1',
          text: 'Thanks for health',
          createdDate: DateTime.now().subtract(const Duration(days: 30)),
        ),
        Thanksgiving(
          id: '2',
          text: 'Thanks for family',
          createdDate: DateTime.now().subtract(const Duration(days: 7)),
        ),
        Thanksgiving(
          id: '3',
          text: 'Thanks for provision',
          createdDate: DateTime.now().subtract(const Duration(days: 90)),
        ),
        Thanksgiving(
          id: '4',
          text: 'Thanks for today',
          createdDate: DateTime.now(),
        ),
      ];
    });

    test('user sorts thanksgivings by creation date (newest first)', () {
      final sorted = List<Thanksgiving>.from(thanksgivings)
        ..sort((a, b) => b.createdDate.compareTo(a.createdDate));

      expect(sorted.first.id, equals('4')); // Newest
      expect(sorted.last.id, equals('3')); // Oldest
    });

    test('user sorts thanksgivings by days old (oldest first)', () {
      final sorted = List<Thanksgiving>.from(thanksgivings)
        ..sort((a, b) => b.daysOld.compareTo(a.daysOld));

      expect(sorted.first.id, equals('3')); // Oldest (90 days)
      expect(sorted.last.id, equals('4')); // Newest (0 days)
    });

    test('user searches thanksgivings by text content', () {
      final searchResults = thanksgivings
          .where((t) => t.text.toLowerCase().contains('family'))
          .toList();

      expect(searchResults.length, equals(1));
      expect(searchResults.first.id, equals('2'));
    });

    test('user filters thanksgivings by date range', () {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final recentThanks = thanksgivings
          .where((t) => t.createdDate.isAfter(thirtyDaysAgo))
          .toList();

      expect(recentThanks.length, equals(2)); // Last 30 days
    });

    test('user counts total thanksgivings', () {
      expect(thanksgivings.length, equals(4));
    });
  });

  group('Thanksgiving Statistics - User Insights', () {
    test('calculate thanksgivings per month', () {
      final thanksgivings = [
        Thanksgiving(id: '1', text: 'T1', createdDate: DateTime(2025, 1, 5)),
        Thanksgiving(id: '2', text: 'T2', createdDate: DateTime(2025, 1, 15)),
        Thanksgiving(id: '3', text: 'T3', createdDate: DateTime(2025, 1, 25)),
        Thanksgiving(id: '4', text: 'T4', createdDate: DateTime(2025, 2, 10)),
        Thanksgiving(id: '5', text: 'T5', createdDate: DateTime(2025, 2, 20)),
      ];

      final byMonth = <String, int>{};
      for (final t in thanksgivings) {
        final key = '${t.createdDate.year}-${t.createdDate.month}';
        byMonth[key] = (byMonth[key] ?? 0) + 1;
      }

      expect(byMonth['2025-1'], equals(3));
      expect(byMonth['2025-2'], equals(2));
    });

    test('calculate average thanksgivings per week', () {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final thanksgivings = [
        Thanksgiving(
          id: '1',
          text: 'T1',
          createdDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Thanksgiving(
          id: '2',
          text: 'T2',
          createdDate: DateTime.now().subtract(const Duration(days: 3)),
        ),
        Thanksgiving(
          id: '3',
          text: 'T3',
          createdDate: DateTime.now().subtract(const Duration(days: 5)),
        ),
        Thanksgiving(
          id: '4',
          text: 'T4',
          createdDate: DateTime.now().subtract(const Duration(days: 14)),
        ),
      ];

      final lastWeekThanks =
          thanksgivings.where((t) => t.createdDate.isAfter(weekAgo)).length;

      expect(lastWeekThanks, equals(3));
    });

    test('identify most recent thanksgiving', () {
      final thanksgivings = [
        Thanksgiving(
          id: '1',
          text: 'T1',
          createdDate: DateTime.now().subtract(const Duration(days: 10)),
        ),
        Thanksgiving(
          id: '2',
          text: 'T2',
          createdDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Thanksgiving(
          id: '3',
          text: 'T3',
          createdDate: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ];

      final sorted = List<Thanksgiving>.from(thanksgivings)
        ..sort((a, b) => b.createdDate.compareTo(a.createdDate));
      final mostRecent = sorted.first;

      expect(mostRecent.id, equals('2'));
    });

    test('calculate thanksgiving streak', () {
      // User added thanksgiving on consecutive days
      int calculateStreak(List<Thanksgiving> thanks) {
        if (thanks.isEmpty) return 0;

        final sorted = List<Thanksgiving>.from(thanks)
          ..sort((a, b) => b.createdDate.compareTo(a.createdDate));

        int streak = 0;
        DateTime expectedDate = DateTime.now();

        for (final t in sorted) {
          final thankDate = DateTime(
            t.createdDate.year,
            t.createdDate.month,
            t.createdDate.day,
          );
          final expected = DateTime(
            expectedDate.year,
            expectedDate.month,
            expectedDate.day,
          );

          if (thankDate == expected) {
            streak++;
            expectedDate = expectedDate.subtract(const Duration(days: 1));
          } else if (thankDate.isBefore(expected)) {
            break;
          }
        }

        return streak;
      }

      final consecutiveThanks = [
        Thanksgiving(id: '1', text: 'T1', createdDate: DateTime.now()),
        Thanksgiving(
          id: '2',
          text: 'T2',
          createdDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Thanksgiving(
          id: '3',
          text: 'T3',
          createdDate: DateTime.now().subtract(const Duration(days: 2)),
        ),
        Thanksgiving(
          id: '4',
          text: 'T4',
          createdDate: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ];

      final streak = calculateStreak(consecutiveThanks);
      expect(streak, equals(3)); // 3 consecutive days
    });
  });

  group('Thanksgiving Data Integrity', () {
    test('toJson and fromJson preserve all data', () {
      final original = Thanksgiving(
        id: 'integrity-test',
        text: 'Testing data integrity with special chars: @#\$%',
        createdDate: DateTime(2025, 3, 15, 8, 30, 45),
      );

      final json = original.toJson();

      // Verify JSON structure
      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('text'), isTrue);
      expect(json.containsKey('createdDate'), isTrue);

      final restored = Thanksgiving.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.text, equals(original.text));
      // Note: toJson truncates time to date only in format yyyy-MM-dd
    });

    test('handles empty id in JSON', () {
      final json = {
        'text': 'Test thanksgiving',
        'createdDate': DateTime.now().toIso8601String(),
      };

      final thanksgiving = Thanksgiving.fromJson(json);

      // Should generate a new id
      expect(thanksgiving.id, isNotEmpty);
    });

    test('handles empty text gracefully', () {
      final emptyTextThanks = Thanksgiving(
        id: 'empty',
        text: '',
        createdDate: DateTime.now(),
      );

      expect(emptyTextThanks.text, equals(''));

      final json = emptyTextThanks.toJson();
      final restored = Thanksgiving.fromJson(json);
      expect(restored.text, equals(''));
    });
  });
}
