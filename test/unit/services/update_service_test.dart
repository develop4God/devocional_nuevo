@Tags(['critical', 'unit', 'services'])
library;

import 'dart:async';

import 'package:devocional_nuevo/services/i_update_service.dart';
import 'package:devocional_nuevo/services/update_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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
  Completer<void>? startGate;
  late UpdateService service;
  late List<String> reports;
  late int installedBuild;
  late Object? installedBuildError;
  late Map<String, String> failingMethods;

  UpdateService newService() => UpdateService(
        installedBuild: () async {
          if (installedBuildError != null) throw installedBuildError!;
          return installedBuild;
        },
        reportError: (e, s, reason) => reports.add('$reason: $e'),
      );

  Map<String, Object?> info({
    int availability = 2,
    bool immediate = true,
    bool flexible = true,
    int priority = 0,
    int staleness = 0,
    int installStatus = 0,
    int availableVersion = 100,
  }) =>
      {
        'updateAvailability': availability,
        'immediateAllowed': immediate,
        'flexibleAllowed': flexible,
        'availableVersionCode': availableVersion,
        'updatePriority': priority,
        'clientVersionStalenessDays': staleness,
        'installStatus': installStatus,
        'packageName': 'com.example.app',
      };

  // availability 3 = developerTriggeredUpdateInProgress, status 11 = downloaded
  Map<String, Object?> downloadedInfo() =>
      info(availability: 3, installStatus: 11);

  // The first check is [first]; later checks (the verification of a downloaded
  // event) answer from [later].
  void answerChecks(Map<String, Object?> later, {Map<String, Object?>? first}) {
    var checks = 0;
    messenger.setMockMethodCallHandler(methods, (call) async {
      if (call.method != 'checkForUpdate') return null;
      return ++checks == 1 ? (first ?? info()) : later;
    });
  }

  setUp(() async {
    calls = [];
    playInfo = info();
    emittedStatuses = [];
    startFlexibleError = null;
    immediateError = null;
    startGate = null;
    reports = [];
    installedBuild = 50;
    installedBuildError = null;
    failingMethods = {};
    service = newService();

    messenger.setMockMethodCallHandler(methods, (call) async {
      calls.add(call.method);
      final failure = failingMethods[call.method];
      if (failure != null) throw PlatformException(code: failure);
      if (call.method == 'checkForUpdate') return playInfo;
      if (call.method == 'startFlexibleUpdate') await startGate?.future;
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

  group('download progress state', () {
    // 2 = downloading, 5 = failed, 6 = canceled, 11 = downloaded
    test('is downloading once the user accepts the flexible update', () async {
      emittedStatuses = [2];

      await service.onColdStart();

      expect(service.updateDownloading.value, isTrue);
      expect(service.updateReady.value, isFalse);
    });

    test('is not downloading when the user denies the update', () async {
      startFlexibleError = 'USER_DENIED_UPDATE';

      await service.onColdStart();

      expect(service.updateDownloading.value, isFalse);
    });

    test('stops downloading and raises the banner when downloaded', () async {
      emittedStatuses = [2, 11];
      answerChecks(downloadedInfo());

      await service.onColdStart();
      await Future<void>.delayed(Duration.zero);

      expect(service.updateDownloading.value, isFalse);
      expect(service.updateReady.value, isTrue);
    });

    test('stops downloading when the download fails or is canceled', () async {
      for (final terminal in [5, 6]) {
        service.dispose();
        service = newService();
        emittedStatuses = [2, terminal];

        await service.onColdStart();
        await Future<void>.delayed(Duration.zero);

        expect(service.updateDownloading.value, isFalse, reason: '$terminal');
      }
    });

    test('stops downloading when a later check finds no download running',
        () async {
      playInfo = info(availability: 3, installStatus: 2);
      await service.onColdStart();
      expect(service.updateDownloading.value, isTrue);

      // 1 = updateNotAvailable: the download ended without a status event.
      playInfo = info(availability: 1);
      await service.onResume();

      expect(service.updateDownloading.value, isFalse);
    });

    test('a resume check while the accept dialog is open keeps the spinner',
        () async {
      emittedStatuses = [2];
      startGate = Completer<void>();
      final coldStart = service.onColdStart();
      await Future<void>.delayed(Duration.zero);
      expect(service.updateDownloading.value, isTrue);

      // The snapshot predates the download: it must not hide the spinner.
      playInfo = info(availability: 2);
      await service.onResume();

      expect(service.updateDownloading.value, isTrue);
      startGate!.complete();
      await coldStart;
    });

    test('a dialog answered after dispose does not touch the notifiers',
        () async {
      startGate = Completer<void>();
      final logs = <String>[];
      await runZoned(
        () async {
          final coldStart = service.onColdStart();
          await Future<void>.delayed(Duration.zero);
          service.dispose();
          startGate!.complete();
          await coldStart;
        },
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) => logs.add(line),
        ),
      );

      expect(logs.where((l) => l.contains('error checking')), isEmpty);
    });

    test('a check reporting downloaded clears the downloading flag', () async {
      playInfo = info(availability: 3, installStatus: 2);
      await service.onColdStart();
      expect(service.updateDownloading.value, isTrue);

      playInfo = downloadedInfo();
      await service.onResume();

      expect(service.updateDownloading.value, isFalse);
      expect(service.updateReady.value, isTrue);
    });

    test('follows a download already running from a previous session',
        () async {
      playInfo = info(availability: 3, installStatus: 2);

      await service.onColdStart();

      expect(service.updateDownloading.value, isTrue);
    });
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

    test('already downloaded update is installed right away', () async {
      playInfo = downloadedInfo();

      await service.onColdStart();

      expect(calls, contains('completeFlexibleUpdate'));
      expect(calls, isNot(contains('startFlexibleUpdate')));
      expect(service.updateReady.value, isFalse);
    });

    test('failed install of a downloaded update falls back to the banner',
        () async {
      playInfo = downloadedInfo();
      messenger.setMockMethodCallHandler(methods, (call) async {
        calls.add(call.method);
        if (call.method == 'checkForUpdate') return playInfo;
        if (call.method == 'completeFlexibleUpdate') {
          throw PlatformException(code: 'not_ready');
        }
        return null;
      });

      await service.onColdStart();

      expect(calls, contains('completeFlexibleUpdate'));
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

  group('flexible offer', () {
    test('a declined offer is made again on the next start', () async {
      startFlexibleError = 'USER_DENIED_UPDATE';
      await service.onColdStart();

      final later = newService();
      calls.clear();
      await later.onColdStart();
      later.dispose();

      expect(calls, contains('startFlexibleUpdate'));
    });

    test('a failed offer is made again on the next start', () async {
      startFlexibleError = 'IN_APP_UPDATE_FAILED';
      await service.onColdStart();

      final later = newService();
      calls.clear();
      await later.onColdStart();
      later.dispose();

      expect(calls, contains('startFlexibleUpdate'));
    });

    test('an already downloaded update is still installed', () async {
      playInfo = downloadedInfo();

      await service.onColdStart();

      expect(calls, contains('completeFlexibleUpdate'));
      expect(service.updateReady.value, isFalse);
    });
  });

  group('critical update', () {
    test('a declined critical update is asked again on every start', () async {
      playInfo = info(priority: 5);
      immediateError = 'USER_DENIED_UPDATE';
      await service.onColdStart();

      final later = newService();
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
      answerChecks(downloadedInfo());

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
      answerChecks(downloadedInfo());

      await service.onColdStart();
      await pumpEventQueue();

      expect(calls, isNot(contains('completeFlexibleUpdate')));
      expect(service.updateReady.value, isTrue);
    });

    test('downloaded status while visible only raises the banner', () async {
      emittedStatuses = [2, 11];
      answerChecks(downloadedInfo());

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

  group('in-progress update', () {
    // availability 3 = developerTriggeredUpdateInProgress, status 2 = downloading
    Map<String, Object?> inProgressInfo(
            {int priority = 0, bool immediate = true}) =>
        info(
          availability: 3,
          installStatus: 2,
          priority: priority,
          immediate: immediate,
        );

    test('cold start resumes a critical immediate update', () async {
      playInfo = inProgressInfo(priority: 5);

      await service.onColdStart();

      expect(calls, contains('performImmediateUpdate'));
    });

    test('resume resumes a critical immediate update', () async {
      playInfo = inProgressInfo(priority: 5);

      await service.onResume();

      expect(calls, contains('performImmediateUpdate'));
    });

    test('a regular in-progress update is not resumed as immediate', () async {
      playInfo = inProgressInfo();

      await service.onResume();
      await service.onColdStart();

      expect(calls, isNot(contains('performImmediateUpdate')));
    });

    test('immediate not allowed is not resumed', () async {
      playInfo = inProgressInfo(priority: 5, immediate: false);

      await service.onColdStart();

      expect(calls, isNot(contains('performImmediateUpdate')));
    });

    test('a canceled resume is swallowed and asked again on next resume',
        () async {
      playInfo = inProgressInfo(priority: 5);
      immediateError = 'USER_DENIED_UPDATE';

      await expectLater(service.onResume(), completes);
      await service.onResume();

      expect(calls.where((c) => c == 'performImmediateUpdate'), hasLength(2));
    });

    test('a later resume can resume again after concurrent ones finish',
        () async {
      playInfo = inProgressInfo(priority: 5);
      final release = Completer<void>();
      messenger.setMockMethodCallHandler(methods, (call) async {
        calls.add(call.method);
        if (call.method == 'checkForUpdate') return playInfo;
        if (call.method == 'performImmediateUpdate') await release.future;
        return null;
      });

      final first = service.onResume();
      final second = service.onResume();
      await pumpEventQueue();
      release.complete();
      await Future.wait([first, second]);
      await service.onResume();

      expect(calls.where((c) => c == 'performImmediateUpdate'), hasLength(2));
    });

    test('concurrent checks before completion call it exactly once', () async {
      playInfo = inProgressInfo(priority: 5);
      final release = Completer<void>();
      messenger.setMockMethodCallHandler(methods, (call) async {
        calls.add(call.method);
        if (call.method == 'checkForUpdate') return playInfo;
        if (call.method == 'performImmediateUpdate') await release.future;
        return null;
      });

      final first = service.onResume();
      final second = service.onResume();
      await pumpEventQueue();
      expect(calls.where((c) => c == 'performImmediateUpdate'), hasLength(1));
      release.complete();
      await Future.wait([first, second]);
    });

    test('a critical in-progress update still listens for the download',
        () async {
      emittedStatuses = [11];
      answerChecks(downloadedInfo(), first: inProgressInfo(priority: 5));

      await service.onResume();
      await pumpEventQueue();

      expect(service.updateReady.value, isTrue);
    });

    test('cold start with a running flexible download listens for it',
        () async {
      emittedStatuses = [2, 11];
      answerChecks(downloadedInfo(), first: inProgressInfo());

      await service.onColdStart();
      await pumpEventQueue();

      expect(service.updateReady.value, isTrue);
      expect(calls, isNot(contains('startFlexibleUpdate')));
    });

    test('repeated checks attach only one status listener', () async {
      playInfo = inProgressInfo();
      var listens = 0;
      messenger.setMockStreamHandler(
        events,
        MockStreamHandler.inline(onListen: (args, sink) => listens++),
      );

      await service.onColdStart();
      await service.onResume();
      await service.onResume();
      await pumpEventQueue();

      expect(listens, 1);
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

        expect(
          await service.applyDownloadedUpdate(),
          UpdateInstallResult.failed,
        );
        expect(
          await service.applyDownloadedUpdate(),
          UpdateInstallResult.failed,
        );

        expect(calls.where((c) => c == 'completeFlexibleUpdate'), hasLength(2));
        expect(service.updateReady.value, isTrue);
      });
    }

    test(
        'coming back to the foreground while Play still reports downloaded '
        'releases the call as unconfirmed, without an error', () async {
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

      expect(await applying, UpdateInstallResult.unconfirmed);
      expect(service.updateReady.value, isTrue);
    });

    test('an unconfirmed install can be requested again', () async {
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
      calls.clear();

      for (var i = 0; i < 2; i++) {
        final applying = service.applyDownloadedUpdate();
        await pumpEventQueue();
        await service.onResume();
        expect(await applying, UpdateInstallResult.unconfirmed);
      }

      expect(calls.where((c) => c == 'completeFlexibleUpdate'), hasLength(2));
      expect(service.updateReady.value, isTrue);
    });

    test('never gives up by itself, however long Play takes', () async {
      playInfo = downloadedInfo();
      await service.onResume();
      messenger.setMockMethodCallHandler(methods, (call) async {
        return Completer<Object?>().future;
      });

      UpdateInstallResult? result;
      unawaited(service.applyDownloadedUpdate().then((v) => result = v));
      await Future<void>.delayed(const Duration(seconds: 1));

      expect(result, isNull);
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
      expect(await applying, UpdateInstallResult.installing);
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

      expect(await first, UpdateInstallResult.installing);
      expect(await second, UpdateInstallResult.installing);
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

      expect(
        await service.applyDownloadedUpdate(),
        UpdateInstallResult.failed,
      );
      fail = false;
      expect(
        await service.applyDownloadedUpdate(),
        UpdateInstallResult.installing,
      );

      expect(calls.where((c) => c == 'completeFlexibleUpdate'), hasLength(2));
    });

    group('foreground while Play is installing', () {
      // availability 3 = in progress, status 3 = installing
      Map<String, Object?> installingInfo() =>
          info(availability: 3, installStatus: 3);

      test('does not fail a user-requested install that is progressing',
          () async {
        playInfo = downloadedInfo();
        await service.onResume();
        final release = Completer<void>();
        messenger.setMockMethodCallHandler(methods, (call) async {
          if (call.method == 'checkForUpdate') return installingInfo();
          if (call.method == 'completeFlexibleUpdate') await release.future;
          return null;
        });

        var done = false;
        final applying = service.applyDownloadedUpdate().whenComplete(() {
          done = true;
        });
        await pumpEventQueue();
        await service.onResume();
        await pumpEventQueue();
        expect(done, isFalse);

        release.complete();
        expect(await applying, UpdateInstallResult.installing);
        expect(service.updateReady.value, isFalse);
      });

      test('does not raise the banner for a cold-start install in progress',
          () async {
        playInfo = downloadedInfo();
        final release = Completer<void>();
        messenger.setMockMethodCallHandler(methods, (call) async {
          if (call.method == 'checkForUpdate') return playInfo;
          if (call.method == 'completeFlexibleUpdate') await release.future;
          return null;
        });
        final coldStart = service.onColdStart();
        await pumpEventQueue();

        playInfo = installingInfo();
        await service.onResume();
        await pumpEventQueue();

        expect(service.updateReady.value, isFalse);
        release.complete();
        await coldStart;
        expect(service.updateReady.value, isFalse);
      });
    });

    test('completes the update and clears updateReady', () async {
      playInfo = downloadedInfo();
      await service.onResume();

      final applied = await service.applyDownloadedUpdate();

      expect(applied, UpdateInstallResult.installing);
      expect(calls, contains('completeFlexibleUpdate'));
      expect(service.updateReady.value, isFalse);
    });

    test('returns failed and keeps updateReady when Play fails', () async {
      playInfo = downloadedInfo();
      await service.onResume();
      messenger.setMockMethodCallHandler(methods, (call) async {
        if (call.method == 'completeFlexibleUpdate') {
          throw PlatformException(code: 'not_ready');
        }
        return null;
      });

      final applied = await service.applyDownloadedUpdate();

      expect(applied, UpdateInstallResult.failed);
      expect(service.updateReady.value, isTrue);
    });
  });

  group('phantom download verification', () {
    // 11 = downloaded, 5 = failed
    test('downloaded event with availableVersionCode <= installed is ignored',
        () async {
      emittedStatuses = [2, 11];
      answerChecks(
        info(availability: 3, installStatus: 11, availableVersion: 50),
      );

      await service.onColdStart();
      await pumpEventQueue();

      expect(service.updateReady.value, isFalse);
      expect(service.updateDownloading.value, isFalse);
    });

    test('downloaded event with a newer availableVersionCode raises ready',
        () async {
      emittedStatuses = [2, 11];
      answerChecks(
        info(availability: 3, installStatus: 11, availableVersion: 51),
      );

      await service.onColdStart();
      await pumpEventQueue();

      expect(service.updateReady.value, isTrue);
      expect(service.updateDownloading.value, isFalse);
    });

    test('downloaded event whose re-check no longer says downloaded is ignored',
        () async {
      emittedStatuses = [11];
      answerChecks(info(availability: 1));

      await service.onColdStart();
      await pumpEventQueue();

      expect(service.updateReady.value, isFalse);
    });

    test('check throwing during verification shows nothing and reports',
        () async {
      emittedStatuses = [2, 11];
      var checks = 0;
      messenger.setMockMethodCallHandler(methods, (call) async {
        if (call.method != 'checkForUpdate') return null;
        if (++checks == 1) return info();
        throw PlatformException(code: 'boom');
      });

      await service.onColdStart();
      await pumpEventQueue();

      expect(service.updateReady.value, isFalse);
      expect(service.updateDownloading.value, isFalse);
      expect(reports, hasLength(1));
      expect(reports.single, contains('boom'));
    });

    test('unknown installed build fails closed', () async {
      installedBuildError = const FormatException('bad build');
      playInfo = downloadedInfo();

      await service.onResume();

      expect(service.updateReady.value, isFalse);
      expect(reports, hasLength(1));
    });

    test('cold start with unverified downloaded never completes the update',
        () async {
      playInfo = info(
        availability: 3,
        installStatus: 11,
        availableVersion: 50,
      );

      await service.onColdStart();

      expect(calls, isNot(contains('completeFlexibleUpdate')));
      expect(service.updateReady.value, isFalse);
      expect(service.updateDownloading.value, isFalse);
    });

    test('cold start with verified downloaded installs it', () async {
      playInfo = downloadedInfo();

      await service.onColdStart();

      expect(calls, contains('completeFlexibleUpdate'));
    });

    test('resume with phantom downloaded clears a ready flag', () async {
      playInfo = downloadedInfo();
      await service.onResume();
      expect(service.updateReady.value, isTrue);

      playInfo = info(availability: 3, installStatus: 11, availableVersion: 50);
      await service.onResume();

      expect(service.updateReady.value, isFalse);
    });

    test('logs the phantom with both build numbers', () async {
      final logs = <String>[];
      playInfo = info(availability: 3, installStatus: 11, availableVersion: 50);

      await runZoned(
        () => service.onResume(),
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) => logs.add(line),
        ),
      );

      final line = logs.firstWhere((l) => l.contains('phantom'));
      expect(line, contains('available=50'));
      expect(line, contains('installed=50'));
    });
  });

  group('failure handling', () {
    test('checkForUpdate PlatformException is reported and clears downloading',
        () async {
      playInfo = info(availability: 3, installStatus: 2);
      await service.onColdStart();
      expect(service.updateDownloading.value, isTrue);

      failingMethods['checkForUpdate'] = 'boom';
      await service.onResume();

      expect(service.updateDownloading.value, isFalse);
      expect(reports, hasLength(1));
      expect(reports.single, contains('check'));
    });

    test('startFlexibleUpdate PlatformException is reported, not downloading',
        () async {
      failingMethods['startFlexibleUpdate'] = 'boom';

      await service.onColdStart();

      expect(service.updateDownloading.value, isFalse);
      expect(reports, hasLength(1));
    });

    test('user denied flexible update clears downloading without a report',
        () async {
      emittedStatuses = [2];
      failingMethods['startFlexibleUpdate'] = 'USER_DENIED_UPDATE';

      await service.onColdStart();

      expect(service.updateDownloading.value, isFalse);
      expect(reports, isEmpty);
    });

    test('failed startFlexibleUpdate result clears downloading', () async {
      emittedStatuses = [2];
      failingMethods['startFlexibleUpdate'] = 'IN_APP_UPDATE_FAILED';

      await service.onColdStart();

      expect(service.updateDownloading.value, isFalse);
    });

    test('performImmediateUpdate PlatformException is reported', () async {
      playInfo = info(priority: 5);
      failingMethods['performImmediateUpdate'] = 'boom';

      await service.onColdStart();

      expect(reports, hasLength(1));
      expect(reports.single, contains('boom'));
    });

    test('resume of an immediate update failing is reported', () async {
      playInfo = info(availability: 3, installStatus: 2, priority: 5);
      failingMethods['performImmediateUpdate'] = 'boom';

      await service.onResume();

      expect(reports, hasLength(1));
    });

    test('completeFlexibleUpdate PlatformException is reported and failed',
        () async {
      failingMethods['completeFlexibleUpdate'] = 'boom';

      final result = await service.applyDownloadedUpdate();

      expect(result, UpdateInstallResult.failed);
      expect(reports, hasLength(1));
      expect(reports.single, contains('boom'));
    });

    test('install can be requested again after a failure', () async {
      failingMethods['completeFlexibleUpdate'] = 'boom';
      await service.applyDownloadedUpdate();
      failingMethods.clear();

      final result = await service.applyDownloadedUpdate();

      expect(result, UpdateInstallResult.installing);
      expect(reports, hasLength(1));
    });

    test('listener error is reported and clears downloading', () async {
      messenger.setMockStreamHandler(
        events,
        MockStreamHandler.inline(onListen: (args, sink) {
          sink.success(2);
          sink.error(code: 'stream', message: 'broken');
        }),
      );

      await service.onColdStart();
      await pumpEventQueue();

      expect(service.updateDownloading.value, isFalse);
      expect(reports, hasLength(1));
    });

    test('a failing reporter never escapes', () async {
      service.dispose();
      service = UpdateService(
        installedBuild: () async => 50,
        reportError: (e, s, reason) => throw StateError('no firebase'),
      );
      failingMethods['checkForUpdate'] = 'boom';

      await service.onResume();

      expect(service.updateReady.value, isFalse);
    });

    test('out-of-order: downloaded event after dispose is harmless', () async {
      emittedStatuses = [11];
      await service.onColdStart();
      service.dispose();
      await pumpEventQueue();

      expect(reports, isEmpty);
    });
  });

  group('phase logging', () {
    test('logs a line for each phase transition', () async {
      final logs = <String>[];
      emittedStatuses = [2, 11];
      answerChecks(downloadedInfo());
      await runZoned(
        () async {
          await service.onColdStart();
          await pumpEventQueue();
          await service.applyDownloadedUpdate();
        },
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) => logs.add(line),
        ),
      );

      for (final phase in [
        'downloading',
        'downloaded-verified',
        'installing'
      ]) {
        expect(logs, contains(contains('phase=$phase')), reason: phase);
      }
    });
  });

  group('diagnostic logging', () {
    late List<String> logs;

    Future<void> captureLogs(Future<void> Function() body) => runZoned(
          body,
          zoneSpecification: ZoneSpecification(
            print: (self, parent, zone, line) => logs.add(line),
          ),
        );

    setUp(() => logs = []);

    test('logs are visible even when debugPrint is silenced (release mode)',
        () async {
      final originalDebugPrint = debugPrint;
      addTearDown(() => debugPrint = originalDebugPrint);
      debugPrint = (String? message, {int? wrapWidth}) {};

      await captureLogs(() => service.onColdStart());

      expect(logs, contains(contains('[UpdateService] check')));
      expect(logs, contains(contains('decision=')));
    });

    test('logs what Play reported and the decision taken', () async {
      playInfo = info(priority: 3, staleness: 7);

      await captureLogs(() => service.onColdStart());

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

      await captureLogs(() => service.onColdStart());

      expect(logs, contains(contains('error checking for updates')));
      expect(logs, contains(contains('boom')));
    });
  });
}
