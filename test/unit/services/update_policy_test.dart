@Tags(['critical', 'unit', 'services'])
library;

import 'package:devocional_nuevo/services/update_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  UpdateAction decide({
    bool updateAvailable = true,
    bool inProgress = false,
    bool immediateAllowed = true,
    int priority = 0,
  }) =>
      UpdatePolicy.decide(
        updateAvailable: updateAvailable,
        inProgress: inProgress,
        immediateAllowed: immediateAllowed,
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
  });
}
