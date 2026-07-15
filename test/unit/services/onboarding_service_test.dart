@Tags(['unit', 'services'])
library;

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
}
