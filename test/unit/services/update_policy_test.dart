@Tags(['critical', 'unit', 'services'])
library;

import 'package:devocional_nuevo/services/update_policy.dart';
import 'package:flutter_test/flutter_test.dart';

UpdateAction decide({
  bool available = true,
  bool immediateAllowed = true,
  bool flexibleAllowed = true,
  int? priority = 0,
  bool inProgress = false,
}) {
  return UpdatePolicy.decide(
    updateAvailable: available,
    immediateAllowed: immediateAllowed,
    flexibleAllowed: flexibleAllowed,
    priority: priority,
    inProgress: inProgress,
  );
}

void main() {
  group('UpdatePolicy.decide', () {
    test('regular update is flexible even when immediate is allowed', () {
      expect(decide(), UpdateAction.flexible);
    });

    test('no update available does nothing', () {
      expect(decide(available: false, priority: 5), UpdateAction.none);
    });

    test('priority at the critical threshold is immediate', () {
      expect(decide(priority: 4), UpdateAction.immediate);
      expect(decide(priority: 5), UpdateAction.immediate);
    });

    test('priority just below the threshold stays flexible', () {
      expect(decide(priority: 3), UpdateAction.flexible);
    });

    test('null priority is treated as regular', () {
      expect(decide(priority: null), UpdateAction.flexible);
    });

    test('a very old installed version alone never blocks', () {
      expect(decide(), UpdateAction.flexible);
    });

    test('critical update falls back to flexible when immediate not allowed',
        () {
      expect(
          decide(priority: 5, immediateAllowed: false), UpdateAction.flexible);
    });

    test('regular update with only immediate allowed does nothing', () {
      expect(decide(flexibleAllowed: false), UpdateAction.none);
    });

    test('neither type allowed does nothing, even when critical', () {
      expect(
        decide(priority: 5, immediateAllowed: false, flexibleAllowed: false),
        UpdateAction.none,
      );
    });
  });

  group('UpdatePolicy.decide in progress', () {
    test('critical in-progress update with immediate allowed is resumed', () {
      expect(
        decide(available: false, inProgress: true, priority: 4),
        UpdateAction.resumeImmediate,
      );
      expect(
        decide(available: false, inProgress: true, priority: 5),
        UpdateAction.resumeImmediate,
      );
    });

    test('regular in-progress update is not resumed', () {
      expect(
        decide(available: false, inProgress: true, priority: 3),
        UpdateAction.none,
      );
      expect(
        decide(available: false, inProgress: true, priority: null),
        UpdateAction.none,
      );
    });

    test('critical in-progress update without immediate allowed is not resumed',
        () {
      expect(
        decide(
          available: false,
          inProgress: true,
          priority: 5,
          immediateAllowed: false,
        ),
        UpdateAction.none,
      );
    });

    test('not in progress never resumes', () {
      expect(
        decide(available: false, priority: 5),
        UpdateAction.none,
      );
    });
  });
}
