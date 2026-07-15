@Tags(['unit', 'services'])
library;

import 'package:devocional_nuevo/blocs/onboarding/onboarding_models.dart';
import 'package:devocional_nuevo/services/onboarding_service.dart';
import 'package:devocional_nuevo/services/remote_config_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'remote_config_service_test.mocks.dart';

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
      );
    });

    test('returns false when remote config is not ready', () async {
      final unreadyRemoteConfigService = RemoteConfigService.create(
        remoteConfig: MockFirebaseRemoteConfig(),
      );
      final unreadyService = OnboardingService.create(
        remoteConfigService: unreadyRemoteConfigService,
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

    test('loadConfiguration clears and returns empty on corrupted JSON',
        () async {
      SharedPreferences.setMockInitialValues({
        'onboarding_configuration': 'not valid json',
      });

      expect(await service.loadConfiguration(), isEmpty);
    });

    test(
      'loadConfiguration returns empty on valid JSON with a malformed '
      '(non-Map) payload',
      () async {
        SharedPreferences.setMockInitialValues({
          'onboarding_configuration':
              '{"schemaVersion":1,"payload":"a string, not a map"}',
        });

        expect(await service.loadConfiguration(), isEmpty);
      },
    );

    test(
      'concurrent saveConfiguration calls are serialized, last write wins',
      () async {
        final first = service.saveConfiguration({'selectedThemeFamily': 'A'});
        final second = service.saveConfiguration({
          'selectedThemeFamily': 'B',
        });

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
  });
}
