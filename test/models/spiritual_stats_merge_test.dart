import 'package:devocional_nuevo/models/spiritual_stats_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpiritualStats.merge()', () {
    test(
      'Device A ahead — A has higher streak/reads, merged result ≥ A values',
      () {
        // Device A: 20 reads, streak 10
        final deviceA = SpiritualStats(
          readDevocionalIds: List.generate(20, (i) => 'id_$i'),
          currentStreak: 10,
          longestStreak: 15,
          lastActivityDate: DateTime(2025, 4, 20),
          totalDevocionalesRead: 20,
          unlockedAchievements: [
            Achievement(
              id: 'streak_7',
              title: 'Test Streak',
              description: 'Test',
              icon: Icons.star,
              color: Colors.blue,
              threshold: 7,
              type: AchievementType.streak,
              isUnlocked: true,
            ),
          ],
          favoritesCount: 5,
        );

        // Device B: 10 reads, streak 5 (behind)
        final deviceB = SpiritualStats(
          readDevocionalIds: List.generate(10, (i) => 'id_$i'),
          currentStreak: 5,
          longestStreak: 8,
          lastActivityDate: DateTime(2025, 4, 15),
          totalDevocionalesRead: 10,
          unlockedAchievements: [],
          favoritesCount: 2,
        );

        // Merge
        final merged = SpiritualStats.merge(deviceA, deviceB);

        // Verify A's values are preserved or exceeded
        expect(merged.readDevocionalIds.length, equals(20)); // union is 20
        expect(merged.currentStreak, equals(10)); // max(10, 5) = 10
        expect(merged.longestStreak, equals(15)); // max(15, 8) = 15
        expect(merged.favoritesCount, equals(5)); // max(5, 2) = 5
        expect(merged.lastActivityDate, equals(DateTime(2025, 4, 20))); // newer
      },
    );

    test(
      'Device B ahead — B has higher streak/reads, merged result ≥ B values',
      () {
        // Device A: 10 reads, streak 5 (behind)
        final deviceA = SpiritualStats(
          readDevocionalIds: List.generate(10, (i) => 'id_a_$i'),
          currentStreak: 5,
          longestStreak: 8,
          lastActivityDate: DateTime(2025, 4, 10),
          totalDevocionalesRead: 10,
          unlockedAchievements: [],
          favoritesCount: 2,
        );

        // Device B: 25 reads, streak 12 (with same IDs as A for cleaner test)
        final deviceB = SpiritualStats(
          readDevocionalIds: [
            ...List.generate(10, (i) => 'id_a_$i'), // Overlap with A
            ...List.generate(15, (i) => 'id_b_${i + 10}'), // B's unique IDs
          ],
          currentStreak: 12,
          longestStreak: 18,
          lastActivityDate: DateTime(2025, 4, 25),
          totalDevocionalesRead: 25,
          unlockedAchievements: [
            Achievement(
              id: 'month_reader',
              title: 'Month Reader',
              description: 'Test',
              icon: Icons.calendar_month,
              color: Colors.purple,
              threshold: 30,
              type: AchievementType.reading,
              isUnlocked: true,
            ),
          ],
          favoritesCount: 8,
        );

        // Merge
        final merged = SpiritualStats.merge(deviceA, deviceB);

        // Verify B's values are preserved or exceeded
        expect(
          merged.readDevocionalIds.length,
          equals(25),
        ); // union is 25 unique
        expect(merged.currentStreak, equals(12)); // max(5, 12) = 12
        expect(merged.longestStreak, equals(18)); // max(8, 18) = 18
        expect(merged.favoritesCount, equals(8)); // max(2, 8) = 8
        expect(merged.lastActivityDate, equals(DateTime(2025, 4, 25))); // newer
        expect(
          merged.unlockedAchievements.length,
          equals(1),
        ); // B's achievement
      },
    );

    test(
      'Disjoint read IDs — A has IDs 1–5, B has IDs 6–10, merged has all 10',
      () {
        // Device A: IDs 0–4
        final deviceA = SpiritualStats(
          readDevocionalIds: List.generate(5, (i) => 'id_${i + 0}'),
          currentStreak: 3,
          longestStreak: 5,
          totalDevocionalesRead: 5,
        );

        // Device B: IDs 5–9 (completely different)
        final deviceB = SpiritualStats(
          readDevocionalIds: List.generate(5, (i) => 'id_${i + 5}'),
          currentStreak: 2,
          longestStreak: 3,
          totalDevocionalesRead: 5,
        );

        // Merge
        final merged = SpiritualStats.merge(deviceA, deviceB);

        // Verify all unique IDs are in merged set
        expect(merged.readDevocionalIds.length, equals(10));
        expect(
          merged.readDevocionalIds.toSet().length,
          equals(10),
        ); // No duplicates
        expect(merged.totalDevocionalesRead, equals(10));
      },
    );

    test(
      'Overlapping read IDs — A and B share some IDs, merged list has no duplicates',
      () {
        // Device A: IDs 0–9
        final deviceA = SpiritualStats(
          readDevocionalIds: List.generate(10, (i) => 'id_$i'),
          currentStreak: 5,
          longestStreak: 7,
          totalDevocionalesRead: 10,
        );

        // Device B: IDs 5–14 (overlap: 5–9)
        final deviceB = SpiritualStats(
          readDevocionalIds: List.generate(10, (i) => 'id_${i + 5}'),
          currentStreak: 4,
          longestStreak: 6,
          totalDevocionalesRead: 10,
        );

        // Merge
        final merged = SpiritualStats.merge(deviceA, deviceB);

        // Verify union with no duplicates
        expect(merged.readDevocionalIds.length, equals(15)); // IDs 0–14
        expect(
          merged.readDevocionalIds.toSet().length,
          equals(15),
        ); // All unique
        expect(merged.totalDevocionalesRead, equals(15));
      },
    );

    test(
      'Achievement union — A unlocked streak_7, B unlocked month_reader, merged has both',
      () {
        final achievementA = Achievement(
          id: 'streak_7',
          title: 'Streak 7',
          description: 'Test',
          icon: Icons.whatshot,
          color: Colors.red,
          threshold: 7,
          type: AchievementType.streak,
          isUnlocked: true,
        );

        final achievementB = Achievement(
          id: 'month_reader',
          title: 'Month Reader',
          description: 'Test',
          icon: Icons.calendar_month,
          color: Colors.purple,
          threshold: 30,
          type: AchievementType.reading,
          isUnlocked: true,
        );

        // Device A: has streak_7
        final deviceA = SpiritualStats(
          readDevocionalIds: ['id_0'],
          currentStreak: 7,
          longestStreak: 7,
          unlockedAchievements: [achievementA],
          totalDevocionalesRead: 1,
        );

        // Device B: has month_reader
        final deviceB = SpiritualStats(
          readDevocionalIds: ['id_1'],
          currentStreak: 5,
          longestStreak: 5,
          unlockedAchievements: [achievementB],
          totalDevocionalesRead: 1,
        );

        // Merge
        final merged = SpiritualStats.merge(deviceA, deviceB);

        // Verify both achievements are in merged
        expect(merged.unlockedAchievements.length, equals(2));
        final ids = merged.unlockedAchievements.map((a) => a.id).toSet();
        expect(ids.contains('streak_7'), isTrue);
        expect(ids.contains('month_reader'), isTrue);
        // All achievements should be marked as unlocked
        expect(merged.unlockedAchievements.every((a) => a.isUnlocked), isTrue);
      },
    );

    test(
      'Empty remote — merge with SpiritualStats() (all zeros/empty) == local',
      () {
        final deviceA = SpiritualStats(
          readDevocionalIds: List.generate(5, (i) => 'id_$i'),
          currentStreak: 3,
          longestStreak: 5,
          lastActivityDate: DateTime(2025, 4, 20),
          unlockedAchievements: [
            Achievement(
              id: 'first_read',
              title: 'First Read',
              description: 'Test',
              icon: Icons.auto_stories,
              color: Colors.green,
              threshold: 1,
              type: AchievementType.reading,
              isUnlocked: true,
            ),
          ],
          favoritesCount: 3,
          totalDevocionalesRead: 5,
        );

        final emptyRemote = SpiritualStats(); // All defaults (0/empty)

        // Merge
        final merged = SpiritualStats.merge(deviceA, emptyRemote);

        // Verify local is preserved when remote is empty
        expect(merged.readDevocionalIds.length, equals(5));
        expect(merged.currentStreak, equals(3));
        expect(merged.longestStreak, equals(5));
        expect(merged.favoritesCount, equals(3));
        expect(merged.lastActivityDate, equals(DateTime(2025, 4, 20)));
        expect(merged.unlockedAchievements.length, equals(1));
        expect(merged.totalDevocionalesRead, equals(5));
      },
    );

    test(
      'lastActivityDate — A has older date, B has newer, merged takes B date',
      () {
        final olderDate = DateTime(2025, 1, 1);
        final newerDate = DateTime(2025, 4, 25);

        final deviceA = SpiritualStats(
          readDevocionalIds: List.generate(10, (i) => 'id_a_$i'),
          lastActivityDate: olderDate,
          currentStreak: 5,
          longestStreak: 5,
          totalDevocionalesRead: 10,
        );

        final deviceB = SpiritualStats(
          readDevocionalIds: List.generate(10, (i) => 'id_b_$i'),
          lastActivityDate: newerDate,
          currentStreak: 3,
          longestStreak: 3,
          totalDevocionalesRead: 10,
        );

        // Merge
        final merged = SpiritualStats.merge(deviceA, deviceB);

        // Verify newer date is selected
        expect(merged.lastActivityDate, equals(newerDate));
      },
    );
  });
}
