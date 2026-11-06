@Tags(['critical', 'unit', 'services'])
library;

import 'package:devocional_nuevo/services/update_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  UpdateAction decide({
    bool updateAvailable = true,
    bool inProgress = false,
    bool immediateAllowed = true,
    bool flexibleAllowed = false,
    bool declinedForThisVersion = false,
    bool downloaded = false,
    int priority = 0,
  }) =>
      UpdatePolicy.decide(
        updateAvailable: updateAvailable,
        inProgress: inProgress,
        immediateAllowed: immediateAllowed,
        flexibleAllowed: flexibleAllowed,
        declinedForThisVersion: declinedForThisVersion,
        downloaded: downloaded,
        priority: priority,
      );

  group('UpdatePolicy.decide', () {
    test('critical priority is 4', () {
      expect(UpdatePolicy.criticalPriority, 4);
    });

    test('priority 4 and 5 trigger an immediate update', () {
      expect(decide(priority: 4), UpdateAction.immediate);
      expect(decide(priority: 5), UpdateAction.immediate);
    });

    test('priority 3 and 0 do nothing', () {
      expect(decide(priority: 3), UpdateAction.none);
      expect(decide(priority: 0), UpdateAction.none);
    });

    test('urgent update without immediate allowed does nothing', () {
      expect(
        decide(priority: 5, immediateAllowed: false),
        UpdateAction.none,
      );
    });

    test('no update available does nothing even with high priority', () {
      expect(
        decide(updateAvailable: false, priority: 5),
        UpdateAction.none,
      );
    });

    test('in-progress urgent update is resumed', () {
      for (final priority in [4, 5]) {
        expect(
          decide(
            updateAvailable: false,
            inProgress: true,
            priority: priority,
          ),
          UpdateAction.resumeImmediate,
          reason: 'priority $priority',
        );
      }
    });

    test('in-progress urgent update without immediate allowed does nothing',
        () {
      expect(
        decide(inProgress: true, immediateAllowed: false, priority: 4),
        UpdateAction.none,
      );
    });

    test('in-progress low priority update does nothing', () {
      for (final priority in [0, 3]) {
        expect(
          decide(updateAvailable: false, inProgress: true, priority: priority),
          UpdateAction.none,
          reason: 'priority $priority (e.g. leftover flexible download)',
        );
      }
    });

    test('in-progress takes precedence over update available', () {
      expect(
        decide(updateAvailable: true, inProgress: true, priority: 5),
        UpdateAction.resumeImmediate,
      );
    });

    test('flexible priority is 2', () {
      expect(UpdatePolicy.flexiblePriority, 2);
    });

    test('priority 2 and 3 start a flexible update when allowed', () {
      for (final priority in [2, 3]) {
        expect(
          decide(priority: priority, flexibleAllowed: true),
          UpdateAction.flexible,
          reason: 'priority $priority',
        );
      }
    });

    test('priority 0 and 1 are left to Play auto-update', () {
      for (final priority in [0, 1]) {
        expect(
          decide(priority: priority, flexibleAllowed: true),
          UpdateAction.none,
          reason: 'priority $priority',
        );
      }
    });

    test('flexible not allowed does nothing', () {
      expect(decide(priority: 3), UpdateAction.none);
    });

    test('version declined by the user is not asked again', () {
      expect(
        decide(
          priority: 2,
          flexibleAllowed: true,
          declinedForThisVersion: true,
        ),
        UpdateAction.none,
      );
    });

    test('no update available does not start a flexible update', () {
      expect(
        decide(updateAvailable: false, priority: 3, flexibleAllowed: true),
        UpdateAction.none,
      );
    });

    test('urgent update beats flexible', () {
      expect(
        decide(priority: 4, flexibleAllowed: true),
        UpdateAction.immediate,
      );
    });

    test('downloaded flexible update is completed', () {
      expect(
        decide(updateAvailable: false, downloaded: true, priority: 2),
        UpdateAction.completeFlexible,
      );
      expect(
        decide(downloaded: true, priority: 2, flexibleAllowed: true),
        UpdateAction.completeFlexible,
      );
    });

    test('downloaded update is completed even if declined or low priority', () {
      expect(
        decide(downloaded: true, priority: 0, declinedForThisVersion: true),
        UpdateAction.completeFlexible,
      );
    });

    test('urgent update beats completing a downloaded flexible update', () {
      expect(
        decide(downloaded: true, priority: 4),
        UpdateAction.immediate,
      );
    });
  });
}
