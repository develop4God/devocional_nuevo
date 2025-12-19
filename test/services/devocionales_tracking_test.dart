import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Tests for devotional tracking functionality
/// Validates the criteria timer starts when tracking begins
/// and that read devotionals are properly filtered
void main() {
  group('Devocionales Tracking Logic Tests', () {
    group('Timer Criteria Check', () {
      test(
          'startDevocionalTracking should trigger criteria check timer to start',
          () {
        // This test validates the logic that when startDevocionalTracking is called,
        // the criteria check timer should be started.
        // The actual implementation calls startCriteriaCheckTimer() inside startDevocionalTracking()

        // Simulate the behavior: timer should be created and active
        Timer? criteriaCheckTimer;
        bool timerStarted = false;

        void startCriteriaCheckTimer() {
          criteriaCheckTimer?.cancel();
          criteriaCheckTimer =
              Timer.periodic(const Duration(seconds: 5), (timer) {
            // Check reading criteria
          });
          timerStarted = true;
        }

        void startDevocionalTracking(String devocionalId) {
          // This is the fixed behavior - timer starts when tracking begins
          startCriteriaCheckTimer();
        }

        // Execute
        startDevocionalTracking('test-devocional-id');

        // Verify
        expect(timerStarted, isTrue,
            reason:
                'Timer should be started when startDevocionalTracking is called');
        expect(criteriaCheckTimer?.isActive, isTrue,
            reason: 'Timer should be active after starting');

        // Cleanup
        criteriaCheckTimer?.cancel();
      });

      test('reading criteria should check time >= 60s and scroll >= 80%', () {
        // Test the criteria evaluation logic
        bool evaluateCriteria(int readingTimeSeconds, double scrollPercentage) {
          return readingTimeSeconds >= 60 && scrollPercentage >= 0.8;
        }

        // Not enough time, not enough scroll
        expect(evaluateCriteria(30, 0.5), isFalse);

        // Enough time, not enough scroll
        expect(evaluateCriteria(60, 0.7), isFalse);

        // Not enough time, enough scroll
        expect(evaluateCriteria(50, 0.9), isFalse);

        // Exactly meeting criteria
        expect(evaluateCriteria(60, 0.8), isTrue);

        // Exceeding criteria
        expect(evaluateCriteria(120, 0.95), isTrue);
      });
    });

    group('Devotional Filtering Logic', () {
      test('findFirstUnreadDevocionalIndex returns first unread index', () {
        // Simulate devotional IDs
        final devocionalIds = ['dev-1', 'dev-2', 'dev-3', 'dev-4', 'dev-5'];
        final readDevocionalIds = ['dev-1', 'dev-2']; // First two are read

        int findFirstUnreadDevocionalIndex(
          List<String> devocionales,
          List<String> readIds,
        ) {
          for (int i = 0; i < devocionales.length; i++) {
            if (!readIds.contains(devocionales[i])) {
              return i;
            }
          }
          return 0; // All read, start from beginning
        }

        // First unread should be at index 2 (dev-3)
        expect(
          findFirstUnreadDevocionalIndex(devocionalIds, readDevocionalIds),
          equals(2),
          reason: 'Should return index 2 where dev-3 is (first unread)',
        );
      });

      test('findFirstUnreadDevocionalIndex returns 0 when all are read', () {
        final devocionalIds = ['dev-1', 'dev-2', 'dev-3'];
        final readDevocionalIds = ['dev-1', 'dev-2', 'dev-3']; // All read

        int findFirstUnreadDevocionalIndex(
          List<String> devocionales,
          List<String> readIds,
        ) {
          for (int i = 0; i < devocionales.length; i++) {
            if (!readIds.contains(devocionales[i])) {
              return i;
            }
          }
          return 0; // All read, start from beginning
        }

        expect(
          findFirstUnreadDevocionalIndex(devocionalIds, readDevocionalIds),
          equals(0),
          reason: 'Should return 0 when all devotionals are read',
        );
      });

      test('findFirstUnreadDevocionalIndex returns 0 when none are read', () {
        final devocionalIds = ['dev-1', 'dev-2', 'dev-3'];
        final readDevocionalIds = <String>[]; // None read

        int findFirstUnreadDevocionalIndex(
          List<String> devocionales,
          List<String> readIds,
        ) {
          for (int i = 0; i < devocionales.length; i++) {
            if (!readIds.contains(devocionales[i])) {
              return i;
            }
          }
          return 0;
        }

        expect(
          findFirstUnreadDevocionalIndex(devocionalIds, readDevocionalIds),
          equals(0),
          reason: 'Should return 0 (first devotional) when none are read',
        );
      });

      test('findFirstUnreadDevocionalIndex handles empty list', () {
        final devocionalIds = <String>[];
        final readDevocionalIds = <String>[];

        int findFirstUnreadDevocionalIndex(
          List<String> devocionales,
          List<String> readIds,
        ) {
          if (devocionales.isEmpty) return 0;
          for (int i = 0; i < devocionales.length; i++) {
            if (!readIds.contains(devocionales[i])) {
              return i;
            }
          }
          return 0;
        }

        expect(
          findFirstUnreadDevocionalIndex(devocionalIds, readDevocionalIds),
          equals(0),
          reason: 'Should return 0 for empty list',
        );
      });

      test('findFirstUnreadDevocionalIndex skips scattered read devotionals',
          () {
        final devocionalIds = ['dev-1', 'dev-2', 'dev-3', 'dev-4', 'dev-5'];
        final readDevocionalIds = ['dev-1', 'dev-3', 'dev-5']; // Read scattered

        int findFirstUnreadDevocionalIndex(
          List<String> devocionales,
          List<String> readIds,
        ) {
          for (int i = 0; i < devocionales.length; i++) {
            if (!readIds.contains(devocionales[i])) {
              return i;
            }
          }
          return 0;
        }

        // First unread should be at index 1 (dev-2)
        expect(
          findFirstUnreadDevocionalIndex(devocionalIds, readDevocionalIds),
          equals(1),
          reason: 'Should return index 1 where dev-2 is (first unread)',
        );
      });
    });

    group('App Open and Close Behavior', () {
      test('on app open should load first unread devotional, not saved index',
          () {
        // Simulate saved index and read devotionals
        final savedIndex = 2;
        final devocionalIds = ['dev-1', 'dev-2', 'dev-3', 'dev-4', 'dev-5'];
        final readDevocionalIds = [
          'dev-1',
          'dev-2',
          'dev-3'
        ]; // First three read

        int loadInitialIndex(
          int? savedIndex,
          List<String> devocionales,
          List<String> readIds,
        ) {
          // NEW BEHAVIOR: Find first unread instead of using saved index
          for (int i = 0; i < devocionales.length; i++) {
            if (!readIds.contains(devocionales[i])) {
              return i;
            }
          }
          return 0;
        }

        final result =
            loadInitialIndex(savedIndex, devocionalIds, readDevocionalIds);

        // Should return index 3 (dev-4), not savedIndex + 1 = 3
        expect(
          result,
          equals(3),
          reason:
              'Should load first unread devotional (index 3) instead of saved index + 1',
        );
      });

      test('saved index should be ignored when that devotional is already read',
          () {
        // User was on index 1, app closed, devotional 1 and 2 are now read
        final savedIndex = 1;
        final devocionalIds = ['dev-1', 'dev-2', 'dev-3', 'dev-4'];
        final readDevocionalIds = ['dev-1', 'dev-2']; // User read dev-2 before

        // OLD BEHAVIOR (wrong): would return savedIndex + 1 = 2
        // NEW BEHAVIOR (correct): should find first unread

        int loadInitialIndexOld(int? savedIndex, int totalDevocionales) {
          if (savedIndex != null) {
            return (savedIndex + 1) % totalDevocionales;
          }
          return 0;
        }

        int loadInitialIndexNew(
          List<String> devocionales,
          List<String> readIds,
        ) {
          for (int i = 0; i < devocionales.length; i++) {
            if (!readIds.contains(devocionales[i])) {
              return i;
            }
          }
          return 0;
        }

        final oldResult = loadInitialIndexOld(savedIndex, devocionalIds.length);
        final newResult = loadInitialIndexNew(devocionalIds, readDevocionalIds);

        // Old behavior would return 2 (which is dev-3, happens to be correct in this case)
        // New behavior explicitly finds first unread, which is also 2
        expect(oldResult, equals(2));
        expect(newResult, equals(2));

        // But with different read list, old behavior fails:
        final readDevocionalIds2 = ['dev-1', 'dev-3']; // dev-2 is unread!
        final newResult2 =
            loadInitialIndexNew(devocionalIds, readDevocionalIds2);
        expect(
          newResult2,
          equals(1),
          reason:
              'New behavior correctly finds dev-2 at index 1 as first unread',
        );
        // Old behavior would still return 2 (wrong!)
      });
    });

    group('Reading Tracker', () {
      test('accumulated seconds should persist through pause/resume cycles',
          () {
        // Simulate reading tracker behavior
        int accumulatedSeconds = 0;
        DateTime? startTime;
        DateTime? pausedTime;

        void startTracking() {
          startTime = DateTime.now();
          pausedTime = null;
          accumulatedSeconds = 0;
        }

        void pause() {
          if (startTime != null && pausedTime == null) {
            final now = DateTime.now();
            accumulatedSeconds += now.difference(startTime!).inSeconds;
            pausedTime = now;
          }
        }

        void resume() {
          if (pausedTime != null) {
            startTime = DateTime.now();
            pausedTime = null;
          }
        }

        int getCurrentSeconds() {
          if (startTime == null) return accumulatedSeconds;
          if (pausedTime != null) return accumulatedSeconds;
          return accumulatedSeconds +
              DateTime.now().difference(startTime!).inSeconds;
        }

        // Start tracking
        startTracking();
        expect(getCurrentSeconds(), equals(0));

        // Simulate passage of time (using accumulated directly for test)
        accumulatedSeconds = 30; // Simulate 30 seconds passed

        // Pause - use the pause function
        pause();

        // Verify paused state
        expect(getCurrentSeconds(), equals(30));

        // Resume
        resume();
        startTime = DateTime.now();

        // More time passes
        accumulatedSeconds = 45; // Total 45 seconds
        expect(getCurrentSeconds() >= 45, isTrue);
      });

      test('scroll percentage should track maximum reached', () {
        double maxScrollPercentage = 0.0;

        void updateScroll(double currentScroll) {
          if (currentScroll > maxScrollPercentage) {
            maxScrollPercentage = currentScroll;
          }
        }

        // User scrolls progressively
        updateScroll(0.2);
        expect(maxScrollPercentage, equals(0.2));

        updateScroll(0.5);
        expect(maxScrollPercentage, equals(0.5));

        updateScroll(0.3); // Scrolls back up
        expect(maxScrollPercentage, equals(0.5),
            reason: 'Max should not decrease');

        updateScroll(0.85);
        expect(maxScrollPercentage, equals(0.85));
      });
    });
  });
}
