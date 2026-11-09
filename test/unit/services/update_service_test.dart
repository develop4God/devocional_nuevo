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
  late DateTime clock;

  setUp(() {
    methodCalls.clear();
    installSink = null;
    installListenCount = 0;
    installCancelCount = 0;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    mockInstallEvents();
    preferences = FakeUpdatePreferences();
    clock = DateTime(2026, 1, 1);
    service = UpdateService(preferences: preferences, now: () => clock);
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

    test('overlapping checks launch one immediate update', () async {
      // The plugin may never complete performImmediateUpdate, and Play's
      // immediate UI pauses/resumes the activity, which re-checks.
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
        hasLength(1),
      );
    });

    test('a never-completing immediate update is relaunched after the window',
        () async {
      mockChannel(
        checkResult: info(priority: 5),
        onImmediate: () => Completer<void>().future,
      );

      unawaited(service.checkForUpdate());
      await pumpEventQueue();
      clock = clock.add(const Duration(minutes: 5));
      unawaited(service.checkForUpdate());
      await pumpEventQueue();

      expect(
        methodCalls.where((m) => m == 'performImmediateUpdate'),
        hasLength(2),
      );
    });

    test('a stale completion of an old launch keeps the newer launch guarded',
        () async {
      final completers = <Completer<void>>[];
      mockChannel(
        checkResult: info(priority: 5),
        onImmediate: () {
          final completer = Completer<void>();
          completers.add(completer);
          return completer.future;
        },
      );

      unawaited(service.checkForUpdate()); // launch A, never completes yet
      await pumpEventQueue();
      clock = clock.add(const Duration(minutes: 5));
      unawaited(service.checkForUpdate()); // launch B after the window
      await pumpEventQueue();
      completers.first.complete(); // A finishes late
      await pumpEventQueue();
      unawaited(service.checkForUpdate()); // must still be guarded by B
      await pumpEventQueue();

      expect(
        methodCalls.where((m) => m == 'performImmediateUpdate'),
        hasLength(2),
      );
    });

    test('a completed immediate update does not block the next check',
        () async {
      mockChannel(checkResult: info(priority: 5));

      await service.checkForUpdate();
      await service.checkForUpdate();

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

    test('urgent update beats a downloaded update', () async {
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
  group('UpdateService downloaded update', () {
    Map<String, Object?> downloaded({int priority = 2, int availability = 2}) =>
        info(
          availability: availability,
          installStatus: installStatusDownloaded,
          priority: priority,
        );

    test('downloaded on cold start is ready with no platform install call',
        () async {
      mockChannel(
        checkResult: downloaded(availability: updateNotAvailable),
      );

      await service.checkForUpdate();
      await pumpEventQueue();

      expect(service.updateReady.value, isTrue);
      expect(service.updateDownloading.value, isFalse);
      expect(methodCalls, ['checkForUpdate']);
    });

    test('downloaded on a later check (resume) is ready', () async {
      mockChannel(checkResult: info(availability: updateNotAvailable));
      await service.checkForUpdate();
      expect(service.updateReady.value, isFalse);

      mockChannel(checkResult: downloaded());
      await service.checkForUpdate();

      expect(service.updateReady.value, isTrue);
      expect(methodCalls, isNot(contains('completeFlexibleUpdate')));
      expect(methodCalls, isNot(contains('performImmediateUpdate')));
    });

    test('downloaded even if declined or low priority is ready', () async {
      preferences.declined = 100;
      mockChannel(checkResult: downloaded(priority: 0));

      await service.checkForUpdate();

      expect(service.updateReady.value, isTrue);
    });

    test('download finishing mid-session raises ready, never installs',
        () async {
      mockChannel(checkResult: info(priority: 2));

      await service.checkForUpdate();
      installSink!.success(installStatusDownloading);
      await pumpEventQueue();
      expect(service.updateDownloading.value, isTrue);
      expect(service.updateReady.value, isFalse);

      installSink!.success(installStatusDownloaded);
      await pumpEventQueue();
      goToBackground();
      await pumpEventQueue();
      goToForeground();

      expect(service.updateDownloading.value, isFalse);
      expect(service.updateReady.value, isTrue);
      expect(methodCalls, isNot(contains('completeFlexibleUpdate')));
      expect(methodCalls, isNot(contains('performImmediateUpdate')));
      expect(installCancelCount, 1, reason: 'listener cancelled when done');
    });

    test('failed or canceled download clears downloading, not ready', () async {
      mockChannel(checkResult: info(priority: 2));

      await service.checkForUpdate();
      installSink!.success(installStatusDownloading);
      await pumpEventQueue();
      installSink!.success(5); // failed
      await pumpEventQueue();

      expect(service.updateDownloading.value, isFalse);
      expect(service.updateReady.value, isFalse);
    });

    test('download already running on cold start is followed to ready',
        () async {
      mockChannel(
        checkResult: info(
          availability: developerTriggeredUpdateInProgress,
          installStatus: installStatusDownloading,
          priority: 2,
        ),
      );

      await service.checkForUpdate();
      expect(service.updateDownloading.value, isTrue);
      expect(installListenCount, 1);
      expect(methodCalls, ['checkForUpdate']);

      installSink!.success(installStatusDownloaded);
      await pumpEventQueue();

      expect(service.updateDownloading.value, isFalse);
      expect(service.updateReady.value, isTrue);
    });

    test('a second check while following a download adds no listener',
        () async {
      mockChannel(
        checkResult: info(
          availability: developerTriggeredUpdateInProgress,
          installStatus: installStatusDownloading,
          priority: 2,
        ),
      );

      await service.checkForUpdate();
      await service.checkForUpdate();

      expect(installListenCount, 1);
    });

    test('nothing is ready or downloading without a download', () async {
      mockChannel(checkResult: info(priority: 1));

      await service.checkForUpdate();

      expect(service.updateReady.value, isFalse);
      expect(service.updateDownloading.value, isFalse);
    });

    test('urgent update does not raise ready', () async {
      mockChannel(checkResult: downloaded(priority: 4));

      await service.checkForUpdate();

      expect(service.updateReady.value, isFalse);
      expect(methodCalls, ['checkForUpdate', 'performImmediateUpdate']);
    });

    test('downloaded with immediate not allowed is still ready', () async {
      mockChannel(
        checkResult: info(
          installStatus: installStatusDownloaded,
          immediateAllowed: false,
          flexibleAllowed: false,
          priority: 2,
        ),
      );

      await service.checkForUpdate();

      expect(service.updateReady.value, isTrue);
    });

    test('preferences read failure still raises ready', () async {
      preferences.throwOnRead = true;
      mockChannel(checkResult: downloaded());

      await service.checkForUpdate();

      expect(service.updateReady.value, isTrue);
    });

    test('a downloaded check starts no flexible flow', () async {
      mockChannel(checkResult: downloaded());

      await service.checkForUpdate();
      await service.checkForUpdate();

      expect(methodCalls, isNot(contains('startFlexibleUpdate')));
    });
  });

  group('UpdateService flexible spinner', () {
    test('consent reply without a downloading event leaves no stale spinner',
        () async {
      mockChannel(checkResult: info(priority: 2));

      await service.checkForUpdate();

      expect(service.updateDownloading.value, isFalse);
      installSink!.success(installStatusDownloading);
      await pumpEventQueue();
      expect(service.updateDownloading.value, isTrue);
    });

    // Emits `downloading` while startFlexibleUpdate is pending, then ends it.
    void mockFlexibleAfterDownloading({
      String? errorCode,
      Future<void> Function()? onEnd,
    }) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        methodCalls.add(call.method);
        if (call.method == 'checkForUpdate') return info(priority: 2);
        if (call.method == 'startFlexibleUpdate') {
          installSink!.success(installStatusDownloading);
          await pumpEventQueue();
          if (onEnd != null) await onEnd();
          if (errorCode != null) throw PlatformException(code: errorCode);
        }
        return null;
      });
    }

    test('install stream error after downloading clears the spinner', () async {
      mockChannel(checkResult: info(priority: 2));
      await service.checkForUpdate();
      installSink!.success(installStatusDownloading);
      await pumpEventQueue();
      expect(service.updateDownloading.value, isTrue);

      installSink!.error(code: 'ERROR');
      await pumpEventQueue();

      expect(service.updateDownloading.value, isFalse);
    });

    test('install stream closing after downloading clears the spinner',
        () async {
      mockChannel(checkResult: info(priority: 2));
      await service.checkForUpdate();
      installSink!.success(installStatusDownloading);
      await pumpEventQueue();

      installSink!.endOfStream();
      await pumpEventQueue();

      expect(service.updateDownloading.value, isFalse);
    });

    test('startFlexibleUpdate throwing after downloading clears the spinner',
        () async {
      mockFlexibleAfterDownloading(errorCode: 'IN_APP_UPDATE_FAILED');

      await service.checkForUpdate();

      expect(service.updateDownloading.value, isFalse);
    });

    test('user denied result after downloading clears the spinner', () async {
      mockFlexibleAfterDownloading(errorCode: 'USER_DENIED_UPDATE');

      await service.checkForUpdate();

      expect(service.updateDownloading.value, isFalse);
    });

    test('a ready update keeps the spinner off when the stream then closes',
        () async {
      mockChannel(checkResult: info(priority: 2));
      await service.checkForUpdate();
      installSink!.success(installStatusDownloading);
      installSink!.success(installStatusDownloaded);
      await pumpEventQueue();
      installSink!.endOfStream();
      await pumpEventQueue();

      expect(service.updateReady.value, isTrue);
      expect(service.updateDownloading.value, isFalse);
    });

    test('retry after a failed download handles each event once', () async {
      mockChannel(checkResult: info(priority: 2));
      await service.checkForUpdate();
      installSink!.success(installStatusDownloading);
      await pumpEventQueue();
      installSink!.success(5); // failed
      await pumpEventQueue();
      expect(service.updateDownloading.value, isFalse);

      await service.checkForUpdate();
      installSink!.success(installStatusDownloading);
      await pumpEventQueue();
      installSink!.success(installStatusDownloaded);
      installSink!.success(installStatusDownloaded);
      await pumpEventQueue();

      expect(installListenCount, 2);
      expect(installCancelCount, 2);
      expect(service.updateReady.value, isTrue);
      expect(service.updateDownloading.value, isFalse);
    });
  });

  group('UpdateService.applyDownloadedUpdate', () {
    void mockApply({bool throws = false}) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        methodCalls.add(call.method);
        if (call.method == 'checkForUpdate') {
          return info(
            installStatus: installStatusDownloaded,
            priority: 2,
          );
        }
        if (call.method == 'completeFlexibleUpdate') {
          if (throws) throw PlatformException(code: 'ERROR');
          // The real plugin never replies.
          return Completer<Object?>().future;
        }
        return null;
      });
    }

    test('calls completeFlexibleUpdate once even on double tap', () async {
      mockApply();

      final first = service.applyDownloadedUpdate();
      final second = service.applyDownloadedUpdate();
      await pumpEventQueue();

      expect(
        methodCalls.where((m) => m == 'completeFlexibleUpdate'),
        hasLength(1),
      );
      expect(identical(first, second), isTrue);
    });

    test('does not wait for a reply and is not completed by the plugin',
        () async {
      mockApply();
      var done = false;
      unawaited(service.applyDownloadedUpdate().then((_) => done = true));
      await pumpEventQueue();

      expect(done, isFalse);
    });

    test('platform error returns failed and allows another tap', () async {
      mockApply(throws: true);

      final result = await service.applyDownloadedUpdate();
      await service.applyDownloadedUpdate();

      expect(result, UpdateInstallResult.failed);
      expect(
        methodCalls.where((m) => m == 'completeFlexibleUpdate'),
        hasLength(2),
      );
    });

    test('returning to foreground still downloaded reports unconfirmed',
        () async {
      mockApply();
      final pending = service.applyDownloadedUpdate();
      await pumpEventQueue();

      await service.checkForUpdate();

      expect(await pending, UpdateInstallResult.unconfirmed);
      expect(service.updateReady.value, isTrue);

      // The card is tappable again.
      unawaited(service.applyDownloadedUpdate());
      await pumpEventQueue();
      expect(
        methodCalls.where((m) => m == 'completeFlexibleUpdate'),
        hasLength(2),
      );
    });

    test('tap, abandon, resume without a check, tap again calls Play again',
        () async {
      mockApply();

      unawaited(service.applyDownloadedUpdate());
      await pumpEventQueue();
      goToBackground();
      goToForeground();
      unawaited(service.applyDownloadedUpdate());
      await pumpEventQueue();

      expect(
        methodCalls.where((m) => m == 'completeFlexibleUpdate'),
        hasLength(2),
      );
    });

    test('a second tap in a later tick does not orphan the first future',
        () async {
      mockApply();

      final first = service.applyDownloadedUpdate();
      await pumpEventQueue();
      final second = service.applyDownloadedUpdate();
      await pumpEventQueue();

      await service.checkForUpdate();

      expect(await first, UpdateInstallResult.unconfirmed);
      expect(await second, UpdateInstallResult.unconfirmed);
    });

    test('is never called by checkForUpdate', () async {
      mockApply();

      await service.checkForUpdate();
      await service.checkForUpdate();

      expect(methodCalls, isNot(contains('completeFlexibleUpdate')));
    });
  });
}
