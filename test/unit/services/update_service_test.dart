@Tags(['critical', 'unit', 'services'])
library;

import 'dart:async';

import 'package:devocional_nuevo/services/i_update_service.dart';
import 'package:devocional_nuevo/services/update_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('de.ffuf.in_app_update/methods');
  final methodCalls = <String>[];

  // UpdateAvailability values used by in_app_update.
  const updateAvailable = 2;
  const developerTriggeredUpdateInProgress = 3;
  const updateNotAvailable = 1;

  Map<String, Object?> info({
    int availability = updateAvailable,
    bool immediateAllowed = true,
    int priority = 0,
  }) =>
      {
        'updateAvailability': availability,
        'immediateAllowed': immediateAllowed,
        'flexibleAllowed': true,
        'availableVersionCode': 100,
        'updatePriority': priority,
        'clientVersionStalenessDays': 30,
        'installStatus': 0,
        'packageName': 'com.example.app',
      };

  void mockChannel({
    Map<String, Object?>? checkResult,
    bool checkThrows = false,
    bool immediateThrows = false,
    Future<void> Function()? onImmediate,
  }) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      methodCalls.add(call.method);
      if (call.method == 'checkForUpdate') {
        if (checkThrows) {
          throw PlatformException(code: 'ERROR', message: 'Platform error');
        }
        return checkResult;
      }
      if (call.method == 'performImmediateUpdate' && immediateThrows) {
        throw PlatformException(code: 'ERROR', message: 'Update failed');
      }
      if (call.method == 'performImmediateUpdate' && onImmediate != null) {
        await onImmediate();
      }
      return null;
    });
  }

  late IUpdateService service;

  setUp(() {
    methodCalls.clear();
    service = UpdateService();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('UpdateService.checkForUpdate', () {
    test('urgent update starts exactly one immediate update', () async {
      mockChannel(checkResult: info(priority: 4));

      await service.checkForUpdate();

      expect(methodCalls, ['checkForUpdate', 'performImmediateUpdate']);
    });

    test('normal priority update never blocks nor starts a flexible update',
        () async {
      for (final priority in [0, 1, 2, 3]) {
        methodCalls.clear();
        mockChannel(checkResult: info(priority: priority));

        await service.checkForUpdate();

        expect(
          methodCalls,
          ['checkForUpdate'],
          reason: 'priority $priority must be left to Play auto-update',
        );
      }
    });

    test('urgent update without immediate allowed does nothing', () async {
      mockChannel(checkResult: info(priority: 5, immediateAllowed: false));

      await service.checkForUpdate();

      expect(methodCalls, ['checkForUpdate']);
    });

    test('no update available does nothing', () async {
      mockChannel(
        checkResult: info(availability: updateNotAvailable, priority: 5),
      );

      await service.checkForUpdate();

      expect(methodCalls, ['checkForUpdate']);
    });

    test('in-progress urgent update is resumed', () async {
      mockChannel(
        checkResult: info(
          availability: developerTriggeredUpdateInProgress,
          priority: 4,
        ),
      );

      await service.checkForUpdate();

      expect(methodCalls, ['checkForUpdate', 'performImmediateUpdate']);
    });

    test('in-progress urgent update without immediate allowed is not resumed',
        () async {
      mockChannel(
        checkResult: info(
          availability: developerTriggeredUpdateInProgress,
          priority: 4,
          immediateAllowed: false,
        ),
      );

      await service.checkForUpdate();

      expect(methodCalls, ['checkForUpdate']);
    });

    test('in-progress low priority update is not resumed', () async {
      mockChannel(
        checkResult: info(
          availability: developerTriggeredUpdateInProgress,
          priority: 0,
        ),
      );

      await service.checkForUpdate();

      expect(methodCalls, ['checkForUpdate']);
    });

    test('a never-completing immediate update does not block later checks',
        () async {
      // The plugin may never complete performImmediateUpdate.
      mockChannel(
        checkResult: info(priority: 5),
        onImmediate: () => Completer<void>().future,
      );

      unawaited(service.checkForUpdate());
      await pumpEventQueue();
      unawaited(service.checkForUpdate());
      await pumpEventQueue();

      expect(
        methodCalls.where((m) => m == 'performImmediateUpdate'),
        hasLength(2),
      );
    });

    test('user denying the update completes normally', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        methodCalls.add(call.method);
        if (call.method == 'checkForUpdate') return info(priority: 5);
        throw PlatformException(code: 'USER_DENIED_UPDATE');
      });

      await expectLater(service.checkForUpdate(), completes);

      expect(methodCalls, ['checkForUpdate', 'performImmediateUpdate']);
    });

    test('checkForUpdate failure completes normally and does nothing else',
        () async {
      mockChannel(checkThrows: true);

      await expectLater(service.checkForUpdate(), completes);

      expect(methodCalls, ['checkForUpdate']);
    });

    test('performImmediateUpdate failure completes normally', () async {
      mockChannel(checkResult: info(priority: 5), immediateThrows: true);

      await expectLater(service.checkForUpdate(), completes);

      expect(methodCalls, ['checkForUpdate', 'performImmediateUpdate']);
    });
  });
}
