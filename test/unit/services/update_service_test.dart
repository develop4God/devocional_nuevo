@Tags(['critical', 'unit', 'services'])
library;

import 'dart:async';

import 'package:devocional_nuevo/services/i_update_preferences.dart';
import 'package:devocional_nuevo/services/i_update_service.dart';
import 'package:devocional_nuevo/services/update_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeUpdatePreferences implements IUpdatePreferences {
  int? declined;
  bool throwOnRead = false;
  bool throwOnWrite = false;
  int writeCount = 0;

  @override
  Future<int?> getDeclinedVersionCode() async {
    if (throwOnRead) throw Exception('prefs failure');
    return declined;
  }

  @override
  Future<void> setDeclinedVersionCode(int versionCode) async {
    writeCount++;
    if (throwOnWrite) throw Exception('prefs write failure');
    declined = versionCode;
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('de.ffuf.in_app_update/methods');
  const events = EventChannel('de.ffuf.in_app_update/stateEvents');
  final methodCalls = <String>[];

  // InstallStatus values used by in_app_update.
  const installStatusUnknown = 0;
  const installStatusDownloading = 2;
  const installStatusDownloaded = 11;

  // UpdateAvailability values used by in_app_update.
  const updateAvailable = 2;
  const developerTriggeredUpdateInProgress = 3;
  const updateNotAvailable = 1;

  Map<String, Object?> info({
    int availability = updateAvailable,
    bool immediateAllowed = true,
    bool flexibleAllowed = true,
    int versionCode = 100,
    int installStatus = installStatusUnknown,
    int priority = 0,
  }) =>
      {
        'updateAvailability': availability,
        'immediateAllowed': immediateAllowed,
        'flexibleAllowed': flexibleAllowed,
        'availableVersionCode': versionCode,
        'updatePriority': priority,
        'clientVersionStalenessDays': 30,
        'installStatus': installStatus,
        'packageName': 'com.example.app',
      };

  void mockChannel({
    Map<String, Object?>? checkResult,
    bool checkThrows = false,
    bool immediateThrows = false,
    Future<void> Function()? onImmediate,
    Future<void> Function()? onFlexible,
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
      if (call.method == 'startFlexibleUpdate' && onFlexible != null) {
        await onFlexible();
      }
      return null;
    });
  }

  // Captures the install-state sink so tests can emit Play install events.
  MockStreamHandlerEventSink? installSink;
  var installListenCount = 0;
  var installCancelCount = 0;

  void mockInstallEvents() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
      events,
      MockStreamHandler.inline(
        onListen: (_, sink) {
          installListenCount++;
          installSink = sink;
        },
        onCancel: (_) => installCancelCount++,
      ),
    );
  }

  void goToBackground() {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  }

  void goToForeground() {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  }

  late FakeUpdatePreferences preferences;
  late IUpdateService service;

  setUp(() {
    methodCalls.clear();
    installSink = null;
    installListenCount = 0;
    installCancelCount = 0;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    mockInstallEvents();
    preferences = FakeUpdatePreferences();
    service = UpdateService(preferences: preferences);
  });

  tearDown(() {
    if (binding.lifecycleState != AppLifecycleState.resumed) {
      goToForeground();
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(events, null);
  });

  group('UpdateService.checkForUpdate', () {
    test('urgent update starts exactly one immediate update', () async {
      mockChannel(checkResult: info(priority: 4));

      await service.checkForUpdate();

      expect(methodCalls, ['checkForUpdate', 'performImmediateUpdate']);
    });

    test('low priority update never blocks nor starts a flexible update',
        () async {
      for (final priority in [0, 1]) {
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
      mockChannel(
        checkResult: info(
          priority: 5,
          immediateAllowed: false,
          flexibleAllowed: false,
        ),
      );

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

  group('UpdateService flexible update', () {
    test('priority 2 and 3 start exactly one flexible update', () async {
      for (final priority in [2, 3]) {
        methodCalls.clear();
        service = UpdateService(preferences: FakeUpdatePreferences());
        mockChannel(checkResult: info(priority: priority));

        await service.checkForUpdate();

        expect(
          methodCalls,
          ['checkForUpdate', 'startFlexibleUpdate'],
          reason: 'priority $priority',
        );
      }
    });

    test('flexible not allowed does not start a flexible update', () async {
      mockChannel(checkResult: info(priority: 2, flexibleAllowed: false));

      await service.checkForUpdate();

      expect(methodCalls, ['checkForUpdate']);
    });

    test('decline is persisted and suppresses the same version code', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        methodCalls.add(call.method);
        if (call.method == 'checkForUpdate') return info(priority: 2);
        throw PlatformException(code: 'USER_DENIED_UPDATE');
      });

      await service.checkForUpdate();
      expect(preferences.declined, 100);

      methodCalls.clear();
      await service.checkForUpdate();

      expect(methodCalls, ['checkForUpdate']);
    });

    test('a newer version code asks again after a decline', () async {
      preferences.declined = 100;
      mockChannel(checkResult: info(priority: 2, versionCode: 101));

      await service.checkForUpdate();

      expect(methodCalls, ['checkForUpdate', 'startFlexibleUpdate']);
    });

    test('a failed flexible update is not persisted as declined', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        methodCalls.add(call.method);
        if (call.method == 'checkForUpdate') return info(priority: 2);
        throw PlatformException(code: 'IN_APP_UPDATE_FAILED');
      });

      await service.checkForUpdate();
      expect(preferences.declined, isNull);

      methodCalls.clear();
      await service.checkForUpdate();
      expect(methodCalls, ['checkForUpdate', 'startFlexibleUpdate']);
    });

    test('a check while a flexible flow is pending starts no second flow',
        () async {
      // Play's consent dialog keeps startFlexibleUpdate pending while the
      // page re-checks on resume.
      final consent = Completer<void>();
      mockChannel(
        checkResult: info(priority: 2),
        onFlexible: () => consent.future,
      );

      unawaited(service.checkForUpdate());
      await pumpEventQueue();
      await service.checkForUpdate();

      expect(
        methodCalls.where((m) => m == 'startFlexibleUpdate'),
        hasLength(1),
      );
      consent.complete();
    });

    test('a check while downloading starts no second flow', () async {
      mockChannel(checkResult: info(priority: 2));

      await service.checkForUpdate();
      installSink!.success(installStatusDownloading);
      await pumpEventQueue();
      await service.checkForUpdate();

      expect(
        methodCalls.where((m) => m == 'startFlexibleUpdate'),
        hasLength(1),
      );
      expect(installListenCount, 1);
    });

    test('update downloaded mid-session is never completed in that session',
        () async {
      mockChannel(checkResult: info(priority: 2));

      await service.checkForUpdate();
      installSink!.success(installStatusDownloaded);
      await pumpEventQueue();
      goToBackground();
      await pumpEventQueue();
      goToForeground();
      // Play now reports the download on every check.
      mockChannel(
        checkResult: info(installStatus: installStatusDownloaded, priority: 2),
      );
      await service.checkForUpdate();
      goToBackground();
      await pumpEventQueue();

      expect(methodCalls, isNot(contains('completeFlexibleUpdate')));
      expect(installCancelCount, 1, reason: 'listener cancelled when done');
      expect(
        methodCalls.where((m) => m == 'startFlexibleUpdate'),
        hasLength(1),
      );
    });

    test('a fresh instance completes an update downloaded last session',
        () async {
      mockChannel(checkResult: info(priority: 2));
      await service.checkForUpdate();
      installSink!.success(installStatusDownloaded);
      await pumpEventQueue();

      // A new process creates a new lazy singleton; Play now reports the
      // download.
      methodCalls.clear();
      mockChannel(
        checkResult: info(installStatus: installStatusDownloaded, priority: 2),
      );
      await UpdateService(preferences: preferences).checkForUpdate();

      expect(methodCalls, ['checkForUpdate', 'completeFlexibleUpdate']);
    });

    test('first check completes an update downloaded on a previous launch',
        () async {
      mockChannel(
        checkResult: info(
          availability: updateNotAvailable,
          installStatus: installStatusDownloaded,
          priority: 2,
        ),
      );

      await service.checkForUpdate();

      expect(methodCalls, ['checkForUpdate', 'completeFlexibleUpdate']);
    });

    test('later checks in the same process do not complete a download',
        () async {
      mockChannel(
        checkResult: info(installStatus: installStatusDownloaded, priority: 2),
      );

      await service.checkForUpdate();
      await service.checkForUpdate();
      await service.checkForUpdate();

      expect(
        methodCalls.where((m) => m == 'completeFlexibleUpdate'),
        hasLength(1),
      );
      expect(methodCalls, isNot(contains('startFlexibleUpdate')));
    });

    test('a failed first check still lets the next check complete', () async {
      mockChannel(checkThrows: true);
      await service.checkForUpdate();

      mockChannel(
        checkResult: info(installStatus: installStatusDownloaded, priority: 2),
      );
      await service.checkForUpdate();

      expect(methodCalls, contains('completeFlexibleUpdate'));
    });

    test('urgent update beats completing a download on the first check',
        () async {
      mockChannel(
        checkResult: info(installStatus: installStatusDownloaded, priority: 4),
      );

      await service.checkForUpdate();

      expect(methodCalls, ['checkForUpdate', 'performImmediateUpdate']);
    });

    test('startFlexibleUpdate platform error completes normally', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        methodCalls.add(call.method);
        if (call.method == 'checkForUpdate') return info(priority: 2);
        throw PlatformException(code: 'ERROR');
      });

      await expectLater(service.checkForUpdate(), completes);
      expect(preferences.declined, isNull);
    });

    test('completeFlexibleUpdate platform error is swallowed', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        methodCalls.add(call.method);
        if (call.method == 'checkForUpdate') {
          return info(installStatus: installStatusDownloaded, priority: 2);
        }
        throw PlatformException(code: 'ERROR');
      });

      await expectLater(service.checkForUpdate(), completes);

      expect(methodCalls, contains('completeFlexibleUpdate'));
    });

    test('install listener error is swallowed and allows a new flow', () async {
      mockChannel(checkResult: info(priority: 2));

      await service.checkForUpdate();
      installSink!.error(code: 'ERROR');
      await pumpEventQueue();
      await service.checkForUpdate();

      expect(
        methodCalls.where((m) => m == 'startFlexibleUpdate'),
        hasLength(2),
      );
    });

    test('preferences failure completes normally', () async {
      preferences.throwOnRead = true;
      mockChannel(checkResult: info(priority: 2));

      await expectLater(service.checkForUpdate(), completes);
    });

    test('preferences read failure still launches an urgent update', () async {
      preferences.throwOnRead = true;
      mockChannel(checkResult: info(priority: 4));

      await service.checkForUpdate();

      expect(methodCalls, ['checkForUpdate', 'performImmediateUpdate']);
    });

    test('preferences read failure still completes a downloaded update',
        () async {
      preferences.throwOnRead = true;
      mockChannel(
        checkResult: info(installStatus: installStatusDownloaded, priority: 2),
      );

      await service.checkForUpdate();

      expect(methodCalls, contains('completeFlexibleUpdate'));
    });

    test('a never-replying completeFlexibleUpdate does not block a new flow',
        () async {
      // The real plugin never replies to completeFlexibleUpdate.
      var versionCode = 100;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        methodCalls.add(call.method);
        if (call.method == 'checkForUpdate') {
          return info(
            versionCode: versionCode,
            installStatus: versionCode == 100
                ? installStatusDownloaded
                : installStatusUnknown,
            priority: 2,
          );
        }
        if (call.method == 'completeFlexibleUpdate') {
          return Completer<Object?>().future;
        }
        return null;
      });

      unawaited(service.checkForUpdate());
      await pumpEventQueue();
      versionCode = 101;
      await service.checkForUpdate();

      expect(methodCalls, contains('startFlexibleUpdate'));
    });

    test('decline write failure is logged and not asked again this session',
        () async {
      preferences.throwOnWrite = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        methodCalls.add(call.method);
        if (call.method == 'checkForUpdate') return info(priority: 2);
        throw PlatformException(code: 'USER_DENIED_UPDATE');
      });

      await expectLater(service.checkForUpdate(), completes);
      expect(installCancelCount, 1, reason: 'flow ended exactly once');
      methodCalls.clear();
      await service.checkForUpdate();

      expect(methodCalls, ['checkForUpdate']);
    });

    test('decline without a version code writes nothing', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        methodCalls.add(call.method);
        if (call.method == 'checkForUpdate') {
          return {...info(priority: 2), 'availableVersionCode': null};
        }
        throw PlatformException(code: 'USER_DENIED_UPDATE');
      });

      await service.checkForUpdate();

      expect(preferences.writeCount, 0);
    });

    for (final status in [5, 6]) {
      test('install status $status resets the guard so a later check restarts',
          () async {
        mockChannel(checkResult: info(priority: 2));

        await service.checkForUpdate();
        installSink!.success(status);
        await pumpEventQueue();
        await service.checkForUpdate();

        expect(
          methodCalls.where((m) => m == 'startFlexibleUpdate'),
          hasLength(2),
        );
      });
    }

    test('install stream closing resets the guard', () async {
      mockChannel(checkResult: info(priority: 2));

      await service.checkForUpdate();
      installSink!.endOfStream();
      await pumpEventQueue();
      await service.checkForUpdate();

      expect(
        methodCalls.where((m) => m == 'startFlexibleUpdate'),
        hasLength(2),
      );
    });

    test('urgent update while a flexible flow is in flight launches immediate',
        () async {
      var priority = 2;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        methodCalls.add(call.method);
        if (call.method == 'checkForUpdate') return info(priority: priority);
        return null;
      });

      await service.checkForUpdate();
      priority = 4;
      await service.checkForUpdate();

      expect(methodCalls, contains('performImmediateUpdate'));
    });
  });
}
