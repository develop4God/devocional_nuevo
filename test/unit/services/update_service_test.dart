@Tags(['critical', 'unit', 'services'])
library;

import 'package:devocional_nuevo/services/update_service.dart';
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
    now = DateTime(2026, 10, 24, 12);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = UpdateService(prefs, clock: () => now);

    messenger.setMockMethodCallHandler(methods, (call) async {
      calls.add(call.method);
      if (call.method == 'checkForUpdate') return playInfo;
      if (call.method == 'startFlexibleUpdate' && startFlexibleError != null) {
        throw PlatformException(code: startFlexibleError!);
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

    test('very stale version performs an immediate update', () async {
      playInfo = info(staleness: 60);

      await service.onColdStart();

      expect(calls, contains('performImmediateUpdate'));
    });

    test('already downloaded update is applied before anything else', () async {
      playInfo = downloadedInfo();

      await service.onColdStart();

      expect(calls, contains('completeFlexibleUpdate'));
      expect(calls, isNot(contains('startFlexibleUpdate')));
      expect(service.updateReady.value, isFalse);
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

      final later = UpdateService(prefs, clock: () => now);
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

    test('throttle never blocks applying an already downloaded update',
        () async {
      await prefs.setInt(_offerKey, now.millisecondsSinceEpoch);
      playInfo = downloadedInfo();

      await service.onColdStart();

      expect(calls, contains('completeFlexibleUpdate'));
    });

    test('throttle never blocks a critical update', () async {
      await prefs.setInt(_offerKey, now.millisecondsSinceEpoch);
      playInfo = info(priority: 5);

      await service.onColdStart();

      expect(calls, contains('performImmediateUpdate'));
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
}
