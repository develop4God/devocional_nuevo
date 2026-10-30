@Tags(['critical', 'unit', 'services'])
library;

import 'dart:async';

import 'package:devocional_nuevo/services/update_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _offerKey = 'update_last_offer_ms';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methods = MethodChannel('de.ffuf.in_app_update/methods');
  const events = EventChannel('de.ffuf.in_app_update/stateEvents');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<String> calls;
  late Map<String, Object?> playInfo;
  late List<int> emittedStatuses;
  late String? startFlexibleError;
  late String? immediateError;
  late DateTime now;
  late SharedPreferences prefs;
  late UpdateService service;

  Map<String, Object?> info({
    int availability = 2,
    bool immediate = true,
    bool flexible = true,
    int priority = 0,
    int staleness = 0,
    int installStatus = 0,
  }) =>
      {
        'updateAvailability': availability,
        'immediateAllowed': immediate,
        'flexibleAllowed': flexible,
        'availableVersionCode': 100,
        'updatePriority': priority,
        'clientVersionStalenessDays': staleness,
        'installStatus': installStatus,
        'packageName': 'com.example.app',
      };

  // availability 3 = developerTriggeredUpdateInProgress, status 11 = downloaded
  Map<String, Object?> downloadedInfo() =>
      info(availability: 3, installStatus: 11);

  setUp(() async {
    calls = [];
    playInfo = info();
    emittedStatuses = [];
    startFlexibleError = null;
    immediateError = null;
    now = DateTime(2026, 10, 24, 12);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = UpdateService(
      prefs,
      clock: () => now,
    );

    messenger.setMockMethodCallHandler(methods, (call) async {
      calls.add(call.method);
      if (call.method == 'checkForUpdate') return playInfo;
      if (call.method == 'startFlexibleUpdate' && startFlexibleError != null) {
        throw PlatformException(code: startFlexibleError!);
      }
      if (call.method == 'performImmediateUpdate' && immediateError != null) {
        throw PlatformException(code: immediateError!);
      }
      return null;
    });
    messenger.setMockStreamHandler(
      events,
      MockStreamHandler.inline(onListen: (args, sink) {
        emittedStatuses.forEach(sink.success);
      }),
    );
  });

  tearDown(() {
    service.dispose();
    messenger.setMockMethodCallHandler(methods, null);
    messenger.setMockStreamHandler(events, null);
  });

  group('cold start', () {
    test('regular update with immediate allowed is flexible, never blocking',
        () async {
      await service.onColdStart();

      expect(calls, contains('startFlexibleUpdate'));
      expect(calls, isNot(contains('performImmediateUpdate')));
      expect(calls, isNot(contains('completeFlexibleUpdate')));
    });

    test('critical priority performs an immediate update', () async {
      playInfo = info(priority: 5);

      await service.onColdStart();

      expect(calls, contains('performImmediateUpdate'));
      expect(calls, isNot(contains('startFlexibleUpdate')));
    });

    test('already downloaded update raises the banner, never restarts',
        () async {
      playInfo = downloadedInfo();

      await service.onColdStart();

      expect(calls, isNot(contains('completeFlexibleUpdate')));
      expect(calls, isNot(contains('startFlexibleUpdate')));
      expect(service.updateReady.value, isTrue);
    });

    test('no update available does nothing', () async {
      playInfo = info(availability: 1);

      await service.onColdStart();

      expect(calls, ['checkForUpdate']);
    });

    test('platform error is swallowed', () async {
      messenger.setMockMethodCallHandler(methods, (call) async {
        throw PlatformException(code: 'boom');
      });

      await expectLater(service.onColdStart(), completes);
      expect(service.updateReady.value, isFalse);
    });

    test('second cold start in the same process never applies mid-session',
        () async {
      await service.onColdStart();
      calls.clear();
      playInfo = downloadedInfo();

      await service.onColdStart();

      expect(calls, isNot(contains('completeFlexibleUpdate')));
      expect(service.updateReady.value, isTrue);
    });
  });

  group('flexible offer throttle', () {
    test('declining the offer suppresses new offers for 24 hours', () async {
      startFlexibleError = 'USER_DENIED_UPDATE';
      await service.onColdStart();
      expect(prefs.getInt(_offerKey), now.millisecondsSinceEpoch);

      final later = UpdateService(
        prefs,
        clock: () => now,
      );
      now = now.add(const Duration(hours: 23));
      calls.clear();
      await later.onColdStart();
      later.dispose();

      expect(calls, isNot(contains('startFlexibleUpdate')));
    });

    test('accepted offer is recorded', () async {
      await service.onColdStart();

      expect(prefs.getInt(_offerKey), now.millisecondsSinceEpoch);
    });

    test('failed offer is not recorded so it is retried next start', () async {
      startFlexibleError = 'IN_APP_UPDATE_FAILED';

      await service.onColdStart();

      expect(prefs.getInt(_offerKey), isNull);
    });

    test('unexpected platform error is not recorded', () async {
      startFlexibleError = 'SOMETHING_ELSE';

      await service.onColdStart();

      expect(prefs.getInt(_offerKey), isNull);
    });

    test('offer is made again after 24 hours', () async {
      await prefs.setInt(
        _offerKey,
        now.subtract(const Duration(hours: 24)).millisecondsSinceEpoch,
      );

      await service.onColdStart();

      expect(calls, contains('startFlexibleUpdate'));
    });

    test('throttle never hides an already downloaded update', () async {
      await prefs.setInt(_offerKey, now.millisecondsSinceEpoch);
      playInfo = downloadedInfo();

      await service.onColdStart();

      expect(service.updateReady.value, isTrue);
    });

    test('throttle never blocks a critical update', () async {
      await prefs.setInt(_offerKey, now.millisecondsSinceEpoch);
      playInfo = info(priority: 5);

      await service.onColdStart();

      expect(calls, contains('performImmediateUpdate'));
    });
  });

  group('critical update', () {
    test('a declined critical update is asked again on every start', () async {
      playInfo = info(priority: 5);
      immediateError = 'USER_DENIED_UPDATE';
      await service.onColdStart();

      final later = UpdateService(prefs, clock: () => now);
      calls.clear();
      await later.onColdStart();
      later.dispose();

      expect(calls, contains('performImmediateUpdate'));
      expect(calls, isNot(contains('startFlexibleUpdate')));
    });
  });

  group('download ready signal', () {
    test('downloaded status from Play raises updateReady', () async {
      emittedStatuses = [2, 11];

      await service.onColdStart();
      await pumpEventQueue();

      expect(service.updateReady.value, isTrue);
    });

    test('in-progress statuses do not raise updateReady', () async {
      emittedStatuses = [1, 2];

      await service.onColdStart();
      await pumpEventQueue();

      expect(service.updateReady.value, isFalse);
    });

    test('downloaded status while hidden never installs, banner waits',
        () async {
      emittedStatuses = [2, 11];

      await service.onColdStart();
      await pumpEventQueue();

      expect(calls, isNot(contains('completeFlexibleUpdate')));
      expect(service.updateReady.value, isTrue);
    });

    test('downloaded status while visible only raises the banner', () async {
      emittedStatuses = [2, 11];

      await service.onColdStart();
      await pumpEventQueue();

      expect(calls, isNot(contains('completeFlexibleUpdate')));
      expect(service.updateReady.value, isTrue);
    });

    test('in-progress statuses while hidden never complete the update',
        () async {
      emittedStatuses = [1, 2];

      await service.onColdStart();
      await pumpEventQueue();

      expect(calls, isNot(contains('completeFlexibleUpdate')));
    });

    test('repeated downloaded statuses never install by themselves', () async {
      emittedStatuses = [11, 11];

      await service.onColdStart();
      await pumpEventQueue();

      expect(calls, isNot(contains('completeFlexibleUpdate')));
    });
  });

  group('resume', () {
    test('downloaded update raises updateReady without restarting', () async {
      playInfo = downloadedInfo();

      await service.onResume();

      expect(service.updateReady.value, isTrue);
      expect(calls, isNot(contains('completeFlexibleUpdate')));
    });

    test('never starts a new offer or blocking update', () async {
      playInfo = info(priority: 5);

      await service.onResume();

      expect(calls, ['checkForUpdate']);
    });
  });

  group('applyDownloadedUpdate', () {
    for (final status in [5, 6]) {
      test(
          'a completion Play never answers ends when Play reports status '
          '$status, so it can be retried', () async {
        playInfo = downloadedInfo();
        await service.onResume();
        emittedStatuses = [status];
        messenger.setMockMethodCallHandler(methods, (call) async {
          calls.add(call.method);
          if (call.method == 'completeFlexibleUpdate') {
            return Completer<void>().future;
          }
          return;
        });
        calls.clear();

        expect(await service.applyDownloadedUpdate(), isFalse);
        expect(await service.applyDownloadedUpdate(), isFalse);

        expect(calls.where((c) => c == 'completeFlexibleUpdate'), hasLength(2));
        expect(service.updateReady.value, isTrue);
      });
    }

    test('coming back to the foreground ends a wait Play never answers',
        () async {
      playInfo = downloadedInfo();
      await service.onResume();
      messenger.setMockMethodCallHandler(methods, (call) async {
        calls.add(call.method);
        if (call.method == 'checkForUpdate') return playInfo;
        if (call.method == 'completeFlexibleUpdate') {
          return Completer<Object?>().future;
        }
        return null;
      });

      final applying = service.applyDownloadedUpdate();
      await pumpEventQueue();
      await service.onResume();

      expect(await applying, isFalse);
      expect(service.updateReady.value, isTrue);
    });

    test('waits for the real outcome instead of giving up after a delay',
        () async {
      playInfo = downloadedInfo();
      await service.onResume();
      final release = Completer<void>();
      messenger.setMockMethodCallHandler(methods, (call) async {
        if (call.method == 'completeFlexibleUpdate') await release.future;
        return null;
      });

      var done = false;
      final applying = service.applyDownloadedUpdate().then((v) {
        done = true;
        return v;
      });
      await Future<void>.delayed(const Duration(seconds: 1));
      expect(done, isFalse);

      release.complete();
      expect(await applying, isTrue);
    });

    test('overlapping requests complete the update only once', () async {
      final release = Completer<void>();
      playInfo = downloadedInfo();
      await service.onResume();
      messenger.setMockMethodCallHandler(methods, (call) async {
        calls.add(call.method);
        if (call.method == 'completeFlexibleUpdate') await release.future;
        return null;
      });
      calls.clear();

      final first = service.applyDownloadedUpdate();
      final second = service.applyDownloadedUpdate();
      await pumpEventQueue();
      release.complete();

      expect(await first, isTrue);
      expect(await second, isTrue);
      expect(calls.where((c) => c == 'completeFlexibleUpdate'), hasLength(1));
    });

    test('a failed install can be retried afterwards', () async {
      playInfo = downloadedInfo();
      await service.onResume();
      var fail = true;
      messenger.setMockMethodCallHandler(methods, (call) async {
        calls.add(call.method);
        if (call.method == 'completeFlexibleUpdate' && fail) {
          throw PlatformException(code: 'not_ready');
        }
        return null;
      });
      calls.clear();

      expect(await service.applyDownloadedUpdate(), isFalse);
      fail = false;
      expect(await service.applyDownloadedUpdate(), isTrue);

      expect(calls.where((c) => c == 'completeFlexibleUpdate'), hasLength(2));
    });

    test('completes the update and clears updateReady', () async {
      playInfo = downloadedInfo();
      await service.onResume();

      final applied = await service.applyDownloadedUpdate();

      expect(applied, isTrue);
      expect(calls, contains('completeFlexibleUpdate'));
      expect(service.updateReady.value, isFalse);
    });

    test('returns false and keeps updateReady when Play fails', () async {
      playInfo = downloadedInfo();
      await service.onResume();
      messenger.setMockMethodCallHandler(methods, (call) async {
        if (call.method == 'completeFlexibleUpdate') {
          throw PlatformException(code: 'not_ready');
        }
        return null;
      });

      final applied = await service.applyDownloadedUpdate();

      expect(applied, isFalse);
      expect(service.updateReady.value, isTrue);
    });
  });

  group('diagnostic logging', () {
    late List<String> logs;
    late DebugPrintCallback originalDebugPrint;

    setUp(() {
      logs = [];
      originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };
    });

    tearDown(() => debugPrint = originalDebugPrint);

    test('logs what Play reported and the decision taken', () async {
      playInfo = info(priority: 3, staleness: 7);

      await service.onColdStart();

      final report = logs.firstWhere((l) => l.contains('check coldStart'));
      expect(
          report, contains('availability=UpdateAvailability.updateAvailable'));
      expect(report, contains('priority=3'));
      expect(report, contains('staleness=7'));
      expect(logs, contains(contains('decision=UpdateAction.flexible')));
    });

    test('logs the platform error instead of hiding it', () async {
      messenger.setMockMethodCallHandler(methods, (call) async {
        throw PlatformException(code: 'boom');
      });

      await service.onColdStart();

      expect(logs, contains(contains('error checking for updates')));
      expect(logs, contains(contains('boom')));
    });

    test('logs why an offer was skipped', () async {
      await prefs.setInt(_offerKey, now.millisecondsSinceEpoch);

      await service.onColdStart();

      expect(logs, contains(contains('offer skipped')));
    });
  });
}
