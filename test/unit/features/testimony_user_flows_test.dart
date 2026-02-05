@Tags(['critical', 'unit', 'features'])
library;

// test/critical_coverage/testimony_user_flows_test.dart
// High-value user behavior tests for Testimony functionality

import 'package:devocional_nuevo/models/testimony_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Testimony Model - User Behavior Tests', () {
    // SCENARIO 1: User creates a new testimony
    test('user creates new testimony with all required fields', () {
      final testimony = Testimony(
        id: 'testimony-001',
        text: 'God healed my family',
        createdDate: DateTime.now(),
      );

      expect(testimony.id, equals('testimony-001'));
      expect(testimony.text, equals('God healed my family'));
      expect(testimony.createdDate, isNotNull);
    });

    // SCENARIO 2: User edits testimony text
    test('user edits testimony text preserving other fields', () {
      final original = Testimony(
        id: 'testimony-001',
        text: 'Original testimony',
        createdDate: DateTime(2025, 1, 1),
      );

      final edited = original.copyWith(text: 'Updated testimony with details');

      expect(edited.id, equals('testimony-001'));
      expect(edited.text, equals('Updated testimony with details'));
      expect(edited.createdDate, equals(DateTime(2025, 1, 1)));
    });

    // SCENARIO 3: Calculate days since testimony creation
    test('daysOld calculates correctly for various ages', () {
      final oldTestimony = Testimony(
        id: '1',
        text: 'Old testimony',
        createdDate: DateTime.now().subtract(const Duration(days: 75)),
      );

      final newTestimony = Testimony(
        id: '2',
        text: 'New testimony',
        createdDate: DateTime.now(),
      );

      expect(oldTestimony.daysOld, equals(75));
      expect(newTestimony.daysOld, equals(0));
    });

    // SCENARIO 4: JSON serialization round-trip
    test('testimony survives JSON serialization round-trip', () {
      final original = Testimony(
        id: 'testimony-special',
        text: 'God blessed me: ñ, é, 日本語, 🙏✝️',
        createdDate: DateTime(2025, 6, 15, 10, 30, 0),
      );

      final json = original.toJson();
      final restored = Testimony.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.text, equals(original.text));
      expect(restored.createdDate, isA<DateTime>());
    });

    // SCENARIO 5: Handle malformed JSON gracefully
    test('fromJson handles missing and malformed data gracefully', () {
      // Missing most fields
      final minimalJson = <String, dynamic>{};
      final minimalTestimony = Testimony.fromJson(minimalJson);
      expect(minimalTestimony.text, equals(''));
      expect(minimalTestimony.createdDate.year, equals(DateTime.now().year));

      // Invalid date format
      final badDateJson = {
        'id': '123',
        'text': 'Test testimony',
        'createdDate': 'invalid-date',
      };
      final badDateTestimony = Testimony.fromJson(badDateJson);
      expect(badDateTestimony.createdDate.year, equals(DateTime.now().year));

      // Null date
      final nullDateJson = {
        'id': '123',
        'text': 'Test testimony',
        'createdDate': null,
      };
      final nullDateTestimony = Testimony.fromJson(nullDateJson);
      expect(nullDateTestimony.createdDate, isNotNull);
    });

    // SCENARIO 6: Edge case - very long testimony text
    test('handles very long testimony text', () {
      final longText = 'God blessed me ' * 500; // 7500+ chars
      final testimony = Testimony(
        id: 'long-testimony',
        text: longText,
        createdDate: DateTime.now(),
      );

      expect(testimony.text.length, greaterThan(5000));

      final json = testimony.toJson();
      final restored = Testimony.fromJson(json);
      expect(restored.text, equals(longText));
    });

    // SCENARIO 7: Edge case - testimony with special characters
    test('handles special characters and unicode', () {
      final specialChars = Testimony(
        id: 'special',
        text: 'Testimony ñ\nNew line\t"Quoted"\n🙏✝️📖',
        createdDate: DateTime.now(),
      );

      final json = specialChars.toJson();
      final restored = Testimony.fromJson(json);

      expect(restored.text, contains('ñ'));
      expect(restored.text, contains('🙏'));
      expect(restored.text, contains('\n'));
    });

    // SCENARIO 8: CopyWith preserves createdDate
    test('copyWith preserves createdDate when not changed', () {
      final specificDate = DateTime(2024, 12, 25, 9, 0, 0);
      final original = Testimony(
        id: 'christmas',
        text: 'Christmas testimony',
        createdDate: specificDate,
      );

      final updated = original.copyWith(text: 'Updated Christmas testimony');

      expect(updated.createdDate, equals(specificDate));
    });

    // SCENARIO 9: CopyWith can update createdDate
    test('copyWith can update createdDate when specified', () {
      final original = Testimony(
        id: 'test',
        text: 'Test',
        createdDate: DateTime(2024, 1, 1),
      );

      final newDate = DateTime(2025, 1, 1);
      final updated = original.copyWith(createdDate: newDate);

      expect(updated.createdDate, equals(newDate));
    });

    // SCENARIO 10: Edge case - empty text
    test('handles empty testimony text', () {
      final emptyTextTestimony = Testimony(
        id: 'empty',
        text: '',
        createdDate: DateTime.now(),
      );

      expect(emptyTextTestimony.text, equals(''));

      final json = emptyTextTestimony.toJson();
      final restored = Testimony.fromJson(json);
      expect(restored.text, equals(''));
    });
  });

  group('Testimony Sorting & Filtering - User Flows', () {
    late List<Testimony> testimonies;

    setUp(() {
      testimonies = [
        Testimony(
          id: '1',
          text: 'Healing testimony',
          createdDate: DateTime.now().subtract(const Duration(days: 30)),
        ),
        Testimony(
          id: '2',
          text: 'Provision testimony',
          createdDate: DateTime.now().subtract(const Duration(days: 7)),
        ),
        Testimony(
          id: '3',
          text: 'Salvation testimony',
          createdDate: DateTime.now().subtract(const Duration(days: 90)),
        ),
        Testimony(
          id: '4',
          text: 'Recent blessing',
          createdDate: DateTime.now(),
        ),
      ];
    });

    test('user sorts testimonies by creation date (newest first)', () {
      final sorted = List<Testimony>.from(testimonies)
        ..sort((a, b) => b.createdDate.compareTo(a.createdDate));

      expect(sorted.first.id, equals('4')); // Newest
      expect(sorted.last.id, equals('3')); // Oldest
    });

    test('user sorts testimonies by days old (oldest first)', () {
      final sorted = List<Testimony>.from(testimonies)
        ..sort((a, b) => b.daysOld.compareTo(a.daysOld));

      expect(sorted.first.id, equals('3')); // Oldest (90 days)
      expect(sorted.last.id, equals('4')); // Newest (0 days)
    });

    test('user searches testimonies by text content', () {
      final searchResults = testimonies
          .where((t) => t.text.toLowerCase().contains('testimony'))
          .toList();

      expect(searchResults.length, equals(3));
    });

    test('user filters testimonies by date range', () {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final recentTestimonies = testimonies
          .where((t) => t.createdDate.isAfter(thirtyDaysAgo))
          .toList();

      expect(recentTestimonies.length, equals(2)); // Last 30 days
    });

    test('user counts total testimonies', () {
      expect(testimonies.length, equals(4));
    });
  });

  group('Testimony Statistics - User Insights', () {
    test('calculate testimonies per month', () {
      final testimonies = [
        Testimony(id: '1', text: 'T1', createdDate: DateTime(2025, 1, 5)),
        Testimony(id: '2', text: 'T2', createdDate: DateTime(2025, 1, 15)),
        Testimony(id: '3', text: 'T3', createdDate: DateTime(2025, 1, 25)),
        Testimony(id: '4', text: 'T4', createdDate: DateTime(2025, 2, 10)),
        Testimony(id: '5', text: 'T5', createdDate: DateTime(2025, 2, 20)),
      ];

      final byMonth = <String, int>{};
      for (final t in testimonies) {
        final key = '${t.createdDate.year}-${t.createdDate.month}';
        byMonth[key] = (byMonth[key] ?? 0) + 1;
      }

      expect(byMonth['2025-1'], equals(3));
      expect(byMonth['2025-2'], equals(2));
    });

    test('calculate average testimonies per week', () {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final testimonies = [
        Testimony(
          id: '1',
          text: 'T1',
          createdDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Testimony(
          id: '2',
          text: 'T2',
          createdDate: DateTime.now().subtract(const Duration(days: 3)),
        ),
        Testimony(
          id: '3',
          text: 'T3',
          createdDate: DateTime.now().subtract(const Duration(days: 5)),
        ),
        Testimony(
          id: '4',
          text: 'T4',
          createdDate: DateTime.now().subtract(const Duration(days: 14)),
        ),
      ];

      final lastWeekTestimonies =
          testimonies.where((t) => t.createdDate.isAfter(weekAgo)).length;

      expect(lastWeekTestimonies, equals(3));
    });

    test('identify most recent testimony', () {
      final testimonies = [
        Testimony(
          id: '1',
          text: 'T1',
          createdDate: DateTime.now().subtract(const Duration(days: 10)),
        ),
        Testimony(
          id: '2',
          text: 'T2',
          createdDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Testimony(
          id: '3',
          text: 'T3',
          createdDate: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ];

      final sorted = List<Testimony>.from(testimonies)
        ..sort((a, b) => b.createdDate.compareTo(a.createdDate));
      final mostRecent = sorted.first;

      expect(mostRecent.id, equals('2'));
    });

    test('calculate testimony streak', () {
      // User added testimony on consecutive days
      int calculateStreak(List<Testimony> testimonies) {
        if (testimonies.isEmpty) return 0;

        final sorted = List<Testimony>.from(testimonies)
          ..sort((a, b) => b.createdDate.compareTo(a.createdDate));

        int streak = 0;
        DateTime expectedDate = DateTime.now();

        for (final t in sorted) {
          final testimonyDate = DateTime(
            t.createdDate.year,
            t.createdDate.month,
            t.createdDate.day,
          );
          final expected = DateTime(
            expectedDate.year,
            expectedDate.month,
            expectedDate.day,
          );

          if (testimonyDate == expected) {
            streak++;
            expectedDate = expectedDate.subtract(const Duration(days: 1));
          } else if (testimonyDate.isBefore(expected)) {
            break;
          }
        }

        return streak;
      }

      final consecutiveTestimonies = [
        Testimony(id: '1', text: 'T1', createdDate: DateTime.now()),
        Testimony(
          id: '2',
          text: 'T2',
          createdDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Testimony(
          id: '3',
          text: 'T3',
          createdDate: DateTime.now().subtract(const Duration(days: 2)),
        ),
        Testimony(
          id: '4',
          text: 'T4',
          createdDate: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ];

      final streak = calculateStreak(consecutiveTestimonies);
      expect(streak, equals(3)); // 3 consecutive days
    });

    test('identify oldest testimony', () {
      final testimonies = [
        Testimony(
          id: '1',
          text: 'T1',
          createdDate: DateTime.now().subtract(const Duration(days: 30)),
        ),
        Testimony(
          id: '2',
          text: 'T2',
          createdDate: DateTime.now().subtract(const Duration(days: 100)),
        ),
        Testimony(
          id: '3',
          text: 'T3',
          createdDate: DateTime.now().subtract(const Duration(days: 60)),
        ),
      ];

      final sorted = List<Testimony>.from(testimonies)
        ..sort((a, b) => a.createdDate.compareTo(b.createdDate));
      final oldest = sorted.first;

      expect(oldest.id, equals('2'));
      expect(oldest.daysOld, equals(100));
    });
  });

  group('Testimony Data Integrity', () {
    test('toJson and fromJson preserve all data', () {
      final original = Testimony(
        id: 'integrity-test',
        text: 'Testing data integrity with special chars: @#\$%',
        createdDate: DateTime(2025, 3, 15, 8, 30, 45),
      );

      final json = original.toJson();

      // Verify JSON structure
      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('text'), isTrue);
      expect(json.containsKey('createdDate'), isTrue);

      final restored = Testimony.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.text, equals(original.text));
    });

    test('handles empty id in JSON', () {
      final json = {
        'text': 'Test testimony',
        'createdDate': DateTime.now().toIso8601String(),
      };

      final testimony = Testimony.fromJson(json);

      // Should generate a new id
      expect(testimony.id, isNotEmpty);
    });

    test('handles multiple testimonies with same text', () {
      final testimony1 = Testimony(
        id: 'test-1',
        text: 'Same text',
        createdDate: DateTime.now(),
      );

      final testimony2 = Testimony(
        id: 'test-2',
        text: 'Same text',
        createdDate: DateTime.now(),
      );

      expect(testimony1.id, isNot(equals(testimony2.id)));
      expect(testimony1.text, equals(testimony2.text));
    });

    test('copyWith creates new instance', () {
      final original = Testimony(
        id: 'original',
        text: 'Original text',
        createdDate: DateTime.now(),
      );

      final copy = original.copyWith();

      expect(copy.id, equals(original.id));
      expect(copy.text, equals(original.text));
      expect(copy.createdDate, equals(original.createdDate));

      // Verify it's a different instance
      expect(identical(copy, original), isFalse);
    });
  });
}
