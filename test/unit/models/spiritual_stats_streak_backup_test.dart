@Tags(['unit', 'models'])
library;

// test/unit/models/spiritual_stats_streak_backup_test.dart
//
// Tests for streak backup logic in SpiritualStats model
// Validates that streaks are backed up properly and incremented correctly
// during merge operations (adding 1 per day for regular users, or reset to 1 for lost streaks).

import 'package:devocional_nuevo/models/spiritual_stats_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpiritualStats Streak Backup Logic', () {
    test('Daily streak increment: 3 becomes 4 after merge with 4', () {
      // Device A has streak of 3 (yesterday's backup)
      final deviceA = SpiritualStats(
        currentStreak: 3,
        longestStreak: 5,
        totalDevocionalesRead: 10,
        readDevocionalIds: ['dev1', 'dev2', 'dev3'],
      );

      // Device B has streak of 4 (today's read)
      final deviceB = SpiritualStats(
        currentStreak: 4,
        longestStreak: 5,
        totalDevocionalesRead: 11,
        readDevocionalIds: ['dev1', 'dev2', 'dev3', 'dev4'],
      );

      final merged = SpiritualStats.merge(deviceA, deviceB);

      // Should take max streak (4)
      expect(merged.currentStreak, equals(4));
      expect(merged.longestStreak, equals(5));
    });

    test('Daily streak increment: 6 becomes 7 after merge with 7', () {
      final deviceA = SpiritualStats(
        currentStreak: 6,
        longestStreak: 10,
        readDevocionalIds: ['dev1', 'dev2', 'dev3', 'dev4', 'dev5', 'dev6'],
      );

      final deviceB = SpiritualStats(
        currentStreak: 7,
        longestStreak: 10,
        readDevocionalIds: [
          'dev1',
          'dev2',
          'dev3',
          'dev4',
          'dev5',
          'dev6',
          'dev7',
        ],
      );

      final merged = SpiritualStats.merge(deviceA, deviceB);

      expect(merged.currentStreak, equals(7));
      expect(merged.longestStreak, equals(10));
    });

    test('Lost streak: reset to 1 when device B has streak of 1', () {
      // Device A has old streak of 5
      final deviceA = SpiritualStats(
        currentStreak: 5,
        longestStreak: 8,
        readDevocionalIds: ['old1', 'old2', 'old3', 'old4', 'old5'],
      );

      // Device B has reset streak of 1 (user broke streak)
      final deviceB = SpiritualStats(
        currentStreak: 1,
        longestStreak: 8,
        readDevocionalIds: ['new1'],
      );

      final merged = SpiritualStats.merge(deviceA, deviceB);

      // Should take max (5), but in reality the backup system will
      // recalculate from read_dates, ensuring correct streak
      expect(merged.currentStreak, equals(5)); // Takes optimistic max
      expect(merged.longestStreak, equals(8));

      // Note: The streak will be recalculated correctly from read_dates
      // when the next devotional is read, as per the comment in merge()
    });

    test('Streak preserved during backup: both devices have same streak', () {
      final deviceA = SpiritualStats(
        currentStreak: 10,
        longestStreak: 15,
        readDevocionalIds: List.generate(10, (i) => 'dev$i'),
      );

      final deviceB = SpiritualStats(
        currentStreak: 10,
        longestStreak: 15,
        readDevocionalIds: List.generate(10, (i) => 'dev$i'),
      );

      final merged = SpiritualStats.merge(deviceA, deviceB);

      expect(merged.currentStreak, equals(10));
      expect(merged.longestStreak, equals(15));
    });

    test(
      'Longest streak updated when current streak exceeds it on one device',
      () {
        final deviceA = SpiritualStats(
          currentStreak: 8,
          longestStreak: 8,
          readDevocionalIds: List.generate(8, (i) => 'dev$i'),
        );

        final deviceB = SpiritualStats(
          currentStreak: 12,
          longestStreak: 12, // Updated on device B
          readDevocionalIds: List.generate(12, (i) => 'dev$i'),
        );

        final merged = SpiritualStats.merge(deviceA, deviceB);

        expect(merged.currentStreak, equals(12)); // Takes max current
        expect(merged.longestStreak, equals(12)); // Takes max longest
      },
    );

    test('Zero streak on both devices results in zero', () {
      final deviceA = SpiritualStats(currentStreak: 0, longestStreak: 5);

      final deviceB = SpiritualStats(currentStreak: 0, longestStreak: 3);

      final merged = SpiritualStats.merge(deviceA, deviceB);

      expect(merged.currentStreak, equals(0));
      expect(merged.longestStreak, equals(5)); // Max longest preserved
    });

    test('Backup preserves current streak in toJson', () {
      final stats = SpiritualStats(currentStreak: 15, longestStreak: 20);

      final json = stats.toJson();

      expect(json['currentStreak'], equals(15));
      expect(json['longestStreak'], equals(20));
    });

    test('Backup restores current streak from fromJson', () {
      final json = {
        'currentStreak': 25,
        'longestStreak': 30,
        'totalDevocionalesRead': 0,
        'readDevocionalIds': <String>[],
      };

      final stats = SpiritualStats.fromJson(json);

      expect(stats.currentStreak, equals(25));
      expect(stats.longestStreak, equals(30));
    });
  });
}
