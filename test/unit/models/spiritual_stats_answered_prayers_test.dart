@Tags(['unit', 'models'])
library;

// test/unit/models/spiritual_stats_answered_prayers_test.dart
//
// Tests for answered prayers count feature in SpiritualStats model
// Validates that answered prayers count is properly included in backups,
// merged across devices, and persisted in spiritual stats.

import 'package:devocional_nuevo/models/spiritual_stats_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpiritualStats Answered Prayers Feature', () {
    test('SpiritualStats fromJson includes answeredPrayersCount', () {
      final json = {
        'totalDevocionalesRead': 10,
        'currentStreak': 5,
        'longestStreak': 7,
        'lastActivityDate': '2026-05-31T00:00:00.000',
        'unlockedAchievements': <Map<String, dynamic>>[],
        'favoritesCount': 3,
        'readDevocionalIds': ['dev1', 'dev2', 'dev3'],
        'answeredPrayersCount': 8,
      };

      final stats = SpiritualStats.fromJson(json);

      expect(stats.answeredPrayersCount, equals(8));
      expect(stats.totalDevocionalesRead, equals(10));
      expect(stats.currentStreak, equals(5));
    });

    test(
      'SpiritualStats fromJson defaults answeredPrayersCount to 0 when missing',
      () {
        final json = {
          'totalDevocionalesRead': 10,
          'currentStreak': 5,
          'longestStreak': 7,
          'readDevocionalIds': <String>[],
        };

        final stats = SpiritualStats.fromJson(json);

        expect(stats.answeredPrayersCount, equals(0));
      },
    );

    test('SpiritualStats toJson includes answeredPrayersCount', () {
      final stats = SpiritualStats(
        totalDevocionalesRead: 10,
        currentStreak: 5,
        longestStreak: 7,
        lastActivityDate: DateTime(2026, 5, 31),
        unlockedAchievements: [],
        favoritesCount: 3,
        readDevocionalIds: ['dev1', 'dev2'],
        answeredPrayersCount: 12,
      );

      final json = stats.toJson();

      expect(json['answeredPrayersCount'], equals(12));
      expect(json['totalDevocionalesRead'], equals(10));
      expect(json['currentStreak'], equals(5));
    });

    test('SpiritualStats copyWith preserves answeredPrayersCount', () {
      final original = SpiritualStats(
        totalDevocionalesRead: 5,
        currentStreak: 3,
        longestStreak: 3,
        answeredPrayersCount: 7,
      );

      final updated = original.copyWith(currentStreak: 4);

      expect(updated.answeredPrayersCount, equals(7));
      expect(updated.currentStreak, equals(4));
    });

    test('SpiritualStats copyWith updates answeredPrayersCount', () {
      final original = SpiritualStats(answeredPrayersCount: 5);

      final updated = original.copyWith(answeredPrayersCount: 10);

      expect(updated.answeredPrayersCount, equals(10));
    });

    test(
      'SpiritualStats merge takes max answeredPrayersCount from both devices',
      () {
        final deviceA = SpiritualStats(
          totalDevocionalesRead: 10,
          currentStreak: 5,
          longestStreak: 7,
          readDevocionalIds: ['dev1', 'dev2'],
          answeredPrayersCount: 8,
        );

        final deviceB = SpiritualStats(
          totalDevocionalesRead: 8,
          currentStreak: 3,
          longestStreak: 5,
          readDevocionalIds: ['dev2', 'dev3'],
          answeredPrayersCount: 12,
        );

        final merged = SpiritualStats.merge(deviceA, deviceB);

        // Should take max answered prayers count
        expect(merged.answeredPrayersCount, equals(12));

        // Verify other merge logic still works
        expect(merged.currentStreak, equals(5)); // max streak
        expect(merged.readDevocionalIds.length, equals(3)); // union of IDs
      },
    );

    test(
      'SpiritualStats merge handles zero answeredPrayersCount on one device',
      () {
        final deviceA = SpiritualStats(answeredPrayersCount: 15);

        final deviceB = SpiritualStats(answeredPrayersCount: 0);

        final merged = SpiritualStats.merge(deviceA, deviceB);

        expect(merged.answeredPrayersCount, equals(15));
      },
    );

    test(
      'SpiritualStats merge with both devices having zero answered prayers',
      () {
        final deviceA = SpiritualStats(answeredPrayersCount: 0);

        final deviceB = SpiritualStats(answeredPrayersCount: 0);

        final merged = SpiritualStats.merge(deviceA, deviceB);

        expect(merged.answeredPrayersCount, equals(0));
      },
    );
  });
}
