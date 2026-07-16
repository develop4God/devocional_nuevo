@Tags(['unit', 'models', 'backup'])
library;

// test/unit/models/backup_content_summary_test.dart
// High-value tests for BackupContentSummary value object.
// Covers: equality, isEmpty, totalItems, and edge cases.

import 'package:devocional_nuevo/models/backup_content_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Canonical factory for non-empty summary used across multiple tests
  // ---------------------------------------------------------------------------
  BackupContentSummary filled() => const BackupContentSummary(
        prayersCount: 5,
        thanksgivingsCount: 3,
        testimoniesCount: 2,
        favoritesCount: 10,
        encountersCount: 4,
        discoveryCount: 1,
        versesCount: 7,
        readDevocionalesCount: 0,
        answeredPrayersCount: 6,
      );

  const BackupContentSummary empty = BackupContentSummary(
    prayersCount: 0,
    thanksgivingsCount: 0,
    testimoniesCount: 0,
    favoritesCount: 0,
    encountersCount: 0,
    discoveryCount: 0,
    versesCount: 0,
    readDevocionalesCount: 0,
  );

  // ---------------------------------------------------------------------------
  group('BackupContentSummary — value equality', () {
    test('two identical instances are equal', () {
      expect(filled(), equals(filled()));
      expect(filled().hashCode, equals(filled().hashCode));
    });

    test('instances with different prayersCount are not equal', () {
      final a = filled();
      final b = const BackupContentSummary(
        prayersCount: 99,
        thanksgivingsCount: 3,
        testimoniesCount: 2,
        favoritesCount: 10,
        encountersCount: 4,
        discoveryCount: 1,
        versesCount: 7,
      );
      expect(a, isNot(equals(b)));
    });

    test('instances with different versesCount are not equal', () {
      final a = filled();
      final b = const BackupContentSummary(
        prayersCount: 5,
        thanksgivingsCount: 3,
        testimoniesCount: 2,
        favoritesCount: 10,
        encountersCount: 4,
        discoveryCount: 1,
        versesCount: 0, // changed
      );
      expect(a, isNot(equals(b)));
    });

    test('two empty instances are equal', () {
      expect(empty, equals(empty));
    });
  });

  // ---------------------------------------------------------------------------
  group('BackupContentSummary.isEmpty', () {
    test('returns true when all counts are zero', () {
      expect(empty.isEmpty, isTrue);
    });

    test('returns false when at least one count is non-zero', () {
      const onlyPrayers = BackupContentSummary(
        prayersCount: 1,
        thanksgivingsCount: 0,
        testimoniesCount: 0,
        favoritesCount: 0,
        encountersCount: 0,
        discoveryCount: 0,
        versesCount: 0,
        readDevocionalesCount: 0,
      );
      expect(onlyPrayers.isEmpty, isFalse);
    });

    test('returns false for filled summary', () {
      expect(filled().isEmpty, isFalse);
    });

    test('returns false when only versesCount is non-zero', () {
      const onlyVerses = BackupContentSummary(
        prayersCount: 0,
        thanksgivingsCount: 0,
        testimoniesCount: 0,
        favoritesCount: 0,
        encountersCount: 0,
        discoveryCount: 0,
        versesCount: 1,
        readDevocionalesCount: 0,
      );
      expect(onlyVerses.isEmpty, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  group('BackupContentSummary.totalItems', () {
    test('returns 0 for empty summary', () {
      expect(empty.totalItems, equals(0));
    });

    test('returns sum of all counters', () {
      // 5+3+2+10+4+1+7+0+6 = 38
      expect(filled().totalItems, equals(38));
    });

    test('single-item summary has totalItems of 1', () {
      const single = BackupContentSummary(
        prayersCount: 0,
        thanksgivingsCount: 0,
        testimoniesCount: 0,
        favoritesCount: 0,
        encountersCount: 0,
        discoveryCount: 0,
        versesCount: 1,
        readDevocionalesCount: 0,
      );
      expect(single.totalItems, equals(1));
    });
  });

  // ---------------------------------------------------------------------------
  group('BackupContentSummary — props contract (Equatable)', () {
    test('props contains all 9 fields in declaration order', () {
      final s = filled();
      expect(
        s.props,
        equals([
          s.prayersCount,
          s.thanksgivingsCount,
          s.testimoniesCount,
          s.favoritesCount,
          s.encountersCount,
          s.discoveryCount,
          s.versesCount,
          s.readDevocionalesCount,
          s.answeredPrayersCount,
        ]),
      );
    });
  });

  // ---------------------------------------------------------------------------
  group('BackupContentSummary — each field is independently readable', () {
    test('all fields hold assigned values', () {
      final s = filled();
      expect(s.prayersCount, 5);
      expect(s.thanksgivingsCount, 3);
      expect(s.testimoniesCount, 2);
      expect(s.favoritesCount, 10);
      expect(s.encountersCount, 4);
      expect(s.discoveryCount, 1);
      expect(s.versesCount, 7);
      expect(s.readDevocionalesCount, 0);
      expect(s.answeredPrayersCount, 6);
    });
  });
}
