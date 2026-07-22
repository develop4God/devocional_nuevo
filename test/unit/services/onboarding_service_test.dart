@Tags(['unit', 'services', 'onboarding'])
library;

import 'package:devocional_nuevo/blocs/onboarding/onboarding_models.dart';
import 'package:devocional_nuevo/models/spiritual_stats_model.dart';
import 'package:devocional_nuevo/services/onboarding_service.dart';
import 'package:devocional_nuevo/services/remote_config_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';
import 'remote_config_service_test.mocks.dart';

/// Fake stats service with a settable devotional read count, so tests can
/// simulate an "existing user" (>=5 devotionals read) for the onboarding
/// backfill without depending on the shared [FakeSpiritualStatsService],
/// which always returns a fixed zero-value [SpiritualStats].
class _FakeStatsServiceWithCount extends FakeSpiritualStatsService {
  _FakeStatsServiceWithCount(this.totalDevocionalesRead);

  final int totalDevocionalesRead;

  @override
  Future<SpiritualStats> getStats() async =>
      SpiritualStats(totalDevocionalesRead: totalDevocionalesRead);
}

/// Fake stats service whose [getStats] always throws, to exercise the
/// backfill's error path.
class _ThrowingStatsService extends FakeSpiritualStatsService {
  @override
  Future<SpiritualStats> getStats() async =>
      throw Exception('stats read failed');
}

/// Fake stats service that fails the first [failFirst] calls, then
/// succeeds with [thenReturns] devotionals read on every call after.
/// Tracks [callCount] so tests can assert exactly how many times the
/// backfill actually invoked [getStats].
class _FlakyStatsService extends FakeSpiritualStatsService {
  _FlakyStatsService({required this.failFirst, required this.thenReturns});

  final int failFirst;
  final int thenReturns;
  int callCount = 0;

  @override
  Future<SpiritualStats> getStats() async {
    callCount++;
    if (callCount <= failFirst) {
      throw Exception('stats read failed');
    }
    return SpiritualStats(totalDevocionalesRead: thenReturns);
  }
}

/// Fake stats service that counts how many times [getStats] is invoked,
/// used to verify the backfill's write-serialization actually prevents a
/// duplicate stats read when two checks race on the same instance.
class _CountingStatsService extends FakeSpiritualStatsService {
  _CountingStatsService(this.totalDevocionalesRead);

  final int totalDevocionalesRead;
  int callCount = 0;

  @override
  Future<SpiritualStats> getStats() async {
    callCount++;
    return SpiritualStats(totalDevocionalesRead: totalDevocionalesRead);
  }
}

void main() {
  group('OnboardingService.shouldShowOnboarding', () {
    late MockFirebaseRemoteConfig mockRemoteConfig;
    late RemoteConfigService remoteConfigService;
    late OnboardingService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockRemoteConfig = MockFirebaseRemoteConfig();
      remoteConfigService = RemoteConfigService.create(
        remoteConfig: mockRemoteConfig,
      );
      when(mockRemoteConfig.setDefaults(any)).thenAnswer((_) => Future.value());
      when(
        mockRemoteConfig.setConfigSettings(any),
      ).thenAnswer((_) => Future.value());
      when(mockRemoteConfig.fetchAndActivate()).thenAnswer((_) async => true);
      await remoteConfigService.initialize();
      service = OnboardingService.create(
        remoteConfigService: remoteConfigService,
        statsService: FakeSpiritualStatsService(),
      );
    });

    test('returns false when remote config is not ready', () async {
      final unreadyRemoteConfigService = RemoteConfigService.create(
        remoteConfig: MockFirebaseRemoteConfig(),
      );
      final unreadyService = OnboardingService.create(
        remoteConfigService: unreadyRemoteConfigService,
        statsService: FakeSpiritualStatsService(),
      );

      expect(await unreadyService.shouldShowOnboarding(), false);
    });

    test('returns false when enable_onboarding_flow is false', () async {
      when(
        mockRemoteConfig.getBool('enable_onboarding_flow'),
      ).thenReturn(false);

      expect(await service.shouldShowOnboarding(), false);
    });

    test(
      'returns true when flag is enabled and onboarding not completed',
      () async {
        when(
          mockRemoteConfig.getBool('enable_onboarding_flow'),
        ).thenReturn(true);

        expect(await service.shouldShowOnboarding(), true);
      },
    );

    test(
      'returns false when flag is enabled but onboarding already completed',
      () async {
        when(
          mockRemoteConfig.getBool('enable_onboarding_flow'),
        ).thenReturn(true);
        await service.setOnboardingComplete();

        expect(await service.shouldShowOnboarding(), false);
      },
    );

    test('returns false when reading the flag throws', () async {
      when(
        mockRemoteConfig.getBool('enable_onboarding_flow'),
      ).thenThrow(Exception('remote config error'));

      expect(await service.shouldShowOnboarding(), false);
    });
  });

  group('OnboardingService existing-user backfill', () {
    late MockFirebaseRemoteConfig mockRemoteConfig;
    late RemoteConfigService remoteConfigService;

    Future<OnboardingService> buildService(int totalDevocionalesRead) async {
      SharedPreferences.setMockInitialValues({});
      mockRemoteConfig = MockFirebaseRemoteConfig();
      remoteConfigService = RemoteConfigService.create(
        remoteConfig: mockRemoteConfig,
      );
      when(mockRemoteConfig.setDefaults(any)).thenAnswer((_) => Future.value());
      when(
        mockRemoteConfig.setConfigSettings(any),
      ).thenAnswer((_) => Future.value());
      when(mockRemoteConfig.fetchAndActivate()).thenAnswer((_) async => true);
      await remoteConfigService.initialize();
      when(
        mockRemoteConfig.getBool('enable_onboarding_flow'),
      ).thenReturn(true);

      return OnboardingService.create(
        remoteConfigService: remoteConfigService,
        statsService: _FakeStatsServiceWithCount(totalDevocionalesRead),
      );
    }

    test(
      'marks onboarding complete for a device with 5+ devotionals read',
      () async {
        final service = await buildService(5);

        expect(await service.isOnboardingComplete(), true);
        expect(await service.shouldShowOnboarding(), false);
      },
    );

    test(
      'does not mark onboarding complete for a device with under 5 '
      'devotionals read',
      () async {
        final service = await buildService(4);

        expect(await service.isOnboardingComplete(), false);
        expect(await service.shouldShowOnboarding(), true);
      },
    );

    test(
      'backfill runs only once — later reading history does not '
      'retroactively complete onboarding after the first check',
      () async {
        final service = await buildService(0);

        // First check: under threshold, not completed, backfill flag set.
        expect(await service.isOnboardingComplete(), false);

        // Simulate the user reading past the threshold afterwards; the
        // one-time backfill must not run again and flip this to true.
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('onboarding_backfill_applied'), true);
      },
    );

    test(
      'a failing stats read during backfill does not propagate, and the '
      'backfill is NOT marked applied so it retries on the next check',
      () async {
        SharedPreferences.setMockInitialValues({});
        final throwingRemoteConfig = MockFirebaseRemoteConfig();
        final throwingRemoteConfigService = RemoteConfigService.create(
          remoteConfig: throwingRemoteConfig,
        );
        when(
          throwingRemoteConfig.setDefaults(any),
        ).thenAnswer((_) => Future.value());
        when(
          throwingRemoteConfig.setConfigSettings(any),
        ).thenAnswer((_) => Future.value());
        when(
          throwingRemoteConfig.fetchAndActivate(),
        ).thenAnswer((_) async => true);
        await throwingRemoteConfigService.initialize();
        when(
          throwingRemoteConfig.getBool('enable_onboarding_flow'),
        ).thenReturn(true);

        final service = OnboardingService.create(
          remoteConfigService: throwingRemoteConfigService,
          statsService: _ThrowingStatsService(),
        );

        // Exception from getStats() must not propagate out of the check.
        expect(await service.isOnboardingComplete(), false);

        // The backfill must NOT be marked applied on a failed read, so a
        // transient error (e.g. a plugin channel not ready yet) gets
        // retried on the next check instead of permanently misclassifying
        // an existing engaged user as new.
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('onboarding_backfill_applied'), isNot(true));
        expect(prefs.getBool('onboarding_complete'), isNot(true));
      },
    );

    test(
      'a stats read that keeps failing retries the backfill on every '
      'check, and succeeds once the read recovers',
      () async {
        SharedPreferences.setMockInitialValues({});
        mockRemoteConfig = MockFirebaseRemoteConfig();
        remoteConfigService = RemoteConfigService.create(
          remoteConfig: mockRemoteConfig,
        );
        when(mockRemoteConfig.setDefaults(any))
            .thenAnswer((_) => Future.value());
        when(
          mockRemoteConfig.setConfigSettings(any),
        ).thenAnswer((_) => Future.value());
        when(mockRemoteConfig.fetchAndActivate()).thenAnswer((_) async => true);
        await remoteConfigService.initialize();
        when(
          mockRemoteConfig.getBool('enable_onboarding_flow'),
        ).thenReturn(true);

        final flakyStats = _FlakyStatsService(failFirst: 2, thenReturns: 5);
        final service = OnboardingService.create(
          remoteConfigService: remoteConfigService,
          statsService: flakyStats,
        );

        // First two checks: stats read fails, backfill not applied yet.
        expect(await service.isOnboardingComplete(), false);
        expect(await service.isOnboardingComplete(), false);

        // Third check: stats read succeeds, backfill runs and applies.
        expect(await service.isOnboardingComplete(), true);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('onboarding_backfill_applied'), true);
        expect(flakyStats.callCount, 3);
      },
    );

    test(
      'concurrent first-time checks only read stats once and apply the '
      'backfill exactly once',
      () async {
        SharedPreferences.setMockInitialValues({});
        mockRemoteConfig = MockFirebaseRemoteConfig();
        remoteConfigService = RemoteConfigService.create(
          remoteConfig: mockRemoteConfig,
        );
        when(mockRemoteConfig.setDefaults(any))
            .thenAnswer((_) => Future.value());
        when(
          mockRemoteConfig.setConfigSettings(any),
        ).thenAnswer((_) => Future.value());
        when(mockRemoteConfig.fetchAndActivate()).thenAnswer((_) async => true);
        await remoteConfigService.initialize();
        when(
          mockRemoteConfig.getBool('enable_onboarding_flow'),
        ).thenReturn(true);

        final countingStats = _CountingStatsService(5);
        final service = OnboardingService.create(
          remoteConfigService: remoteConfigService,
          statsService: countingStats,
        );

        final results = await Future.wait([
          service.isOnboardingComplete(),
          service.isOnboardingComplete(),
        ]);

        expect(results, [true, true]);
        expect(
          countingStats.callCount,
          1,
          reason: '_serialized must prevent a second concurrent call from '
              'reading stats again once the backfill flag is about to be set',
        );
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('onboarding_backfill_applied'), true);
        expect(prefs.getBool('onboarding_complete'), true);
      },
    );

    test(
      'resetOnboarding preserves the backfill-applied flag so a QA reset '
      'on a device with real reading history is not immediately '
      're-backfilled to complete',
      () async {
        final service = await buildService(5);

        // Triggers the backfill and marks it applied.
        await service.isOnboardingComplete();
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('onboarding_backfill_applied'), true);

        await service.resetOnboarding();

        expect(
          prefs.getBool('onboarding_backfill_applied'),
          true,
          reason: 'resetOnboarding must not clear the backfill flag',
        );
        expect(await service.isOnboardingComplete(), false);
      },
    );
  });

  group('OnboardingService configuration/progress persistence', () {
    late MockFirebaseRemoteConfig mockRemoteConfig;
    late RemoteConfigService remoteConfigService;
    late OnboardingService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockRemoteConfig = MockFirebaseRemoteConfig();
      remoteConfigService = RemoteConfigService.create(
        remoteConfig: mockRemoteConfig,
      );
      service = OnboardingService.create(
        remoteConfigService: remoteConfigService,
        statsService: FakeSpiritualStatsService(),
      );
    });

    test('saveConfiguration/loadConfiguration round-trip', () async {
      await service.saveConfiguration({'selectedThemeFamily': 'Blue'});

      final loaded = await service.loadConfiguration();

      expect(loaded['selectedThemeFamily'], 'Blue');
    });

    test('clearConfiguration removes saved configuration', () async {
      await service.saveConfiguration({'selectedThemeFamily': 'Blue'});
      await service.clearConfiguration();

      expect(await service.loadConfiguration(), isEmpty);
    });

    test('saveProgress/loadProgress round-trip', () async {
      final progress = OnboardingProgress.fromStepCompletion(const [
        true,
        false,
        false,
        false,
      ]);
      await service.saveProgress(progress);

      final loaded = await service.loadProgress();

      expect(loaded?.completedSteps, 1);
    });

    test('clearProgress removes saved progress', () async {
      await service.saveProgress(
        OnboardingProgress.fromStepCompletion(const [
          true,
          false,
          false,
          false,
        ]),
      );
      await service.clearProgress();

      expect(await service.loadProgress(), isNull);
    });

    test(
      'loadConfiguration clears and returns empty on corrupted JSON',
      () async {
        SharedPreferences.setMockInitialValues({
          'onboarding_configuration': 'not valid json',
        });

        expect(await service.loadConfiguration(), isEmpty);
      },
    );

    test(
        'loadConfiguration returns empty on valid JSON with a malformed '
        '(non-Map) payload', () async {
      SharedPreferences.setMockInitialValues({
        'onboarding_configuration':
            '{"schemaVersion":1,"payload":"a string, not a map"}',
      });

      expect(await service.loadConfiguration(), isEmpty);
    });

    test(
      'concurrent saveConfiguration calls are serialized, last write wins',
      () async {
        final first = service.saveConfiguration({'selectedThemeFamily': 'A'});
        final second = service.saveConfiguration({'selectedThemeFamily': 'B'});

        await Future.wait([first, second]);

        final loaded = await service.loadConfiguration();
        expect(loaded['selectedThemeFamily'], 'B');
      },
    );

    test(
      'a failing save does not wedge the write queue for subsequent saves',
      () async {
        // Force the first save to fail by handing it a value jsonEncode
        // cannot serialize.
        final failing = service.saveConfiguration({
          'bad': DateTime.now(), // DateTime is not directly JSON-encodable
        });

        await failing;

        // The queue must not be stuck: a subsequent save should still
        // complete and persist correctly.
        await service.saveConfiguration({'selectedThemeFamily': 'Blue'});

        final loaded = await service.loadConfiguration();
        expect(loaded['selectedThemeFamily'], 'Blue');
      },
    );

    test('loadProgress clears and returns null on corrupted JSON', () async {
      SharedPreferences.setMockInitialValues({
        'onboarding_progress': 'not valid json',
      });

      expect(await service.loadProgress(), isNull);
    });

    test(
        'loadProgress returns null and clears storage when the payload is '
        'missing a required key (completedSteps)', () async {
      SharedPreferences.setMockInitialValues({
        'onboarding_progress': '{"schemaVersion":1,"payload":'
            '{"totalSteps":4,"stepCompletionStatus":[true,false,false,false],'
            '"progressPercentage":25.0}}',
      });

      expect(await service.loadProgress(), isNull);

      // Confirms the invalid entry was actually removed, not just ignored.
      expect(await service.loadProgress(), isNull);
    });

    test(
        'loadProgress returns null when a required field has the wrong type '
        '(totalSteps as a String instead of an int)', () async {
      SharedPreferences.setMockInitialValues({
        'onboarding_progress': '{"schemaVersion":1,"payload":'
            '{"totalSteps":"4","completedSteps":1,'
            '"stepCompletionStatus":[true,false,false,false],'
            '"progressPercentage":25.0}}',
      });

      expect(await service.loadProgress(), isNull);
    });

    test(
        'loadProgress migrates a pre-schema-version (legacy, unwrapped) '
        'payload and returns the parsed values unchanged', () async {
      // Legacy shape: no {schemaVersion, payload} wrapper at all — the
      // raw progress fields were stored directly under the storage key.
      // _isValidProgressStructure falls back to validating this shape
      // directly (onboarding_service.dart:385), and schemaVersion reads
      // as 0 via `wrapper['schemaVersion'] as int? ?? 0`, so this
      // exercises the schemaVersion < _currentSchemaVersion branch and
      // calls _migrateProgress.
      SharedPreferences.setMockInitialValues({
        'onboarding_progress': '{"totalSteps":4,"completedSteps":2,'
            '"stepCompletionStatus":[true,true,false,false],'
            '"progressPercentage":50.0}',
      });

      final migrated = await service.loadProgress();

      expect(migrated, isNotNull);
      expect(migrated!.totalSteps, 4);
      expect(migrated.completedSteps, 2);
      expect(migrated.stepCompletionStatus, [true, true, false, false]);
      expect(migrated.progressPercentage, 50.0);
    });

    test(
      'loadProgress does NOT re-persist migrated data — unlike '
      'loadConfiguration, a second load re-runs migration from the same '
      'legacy storage shape rather than reading back an upgraded v1 record',
      () async {
        const legacyJson = '{"totalSteps":4,"completedSteps":2,'
            '"stepCompletionStatus":[true,true,false,false],'
            '"progressPercentage":50.0}';
        SharedPreferences.setMockInitialValues({
          'onboarding_progress': legacyJson,
        });

        await service.loadProgress();

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString('onboarding_progress'),
          legacyJson,
          reason: 'loadProgress has no self-healing re-save, unlike '
              'loadConfiguration; storage stays at the legacy shape after '
              'a migrated read',
        );
      },
    );
  });
}
