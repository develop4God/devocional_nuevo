@Tags(['unit', 'services'])
library;

import 'package:devocional_nuevo/services/remote_config_service.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FirebaseRemoteConfig])
import 'remote_config_service_test.mocks.dart';

void main() {
  group('RemoteConfigService', () {
    late MockFirebaseRemoteConfig mockRemoteConfig;
    late RemoteConfigService service;

    setUp(() {
      mockRemoteConfig = MockFirebaseRemoteConfig();
      service = RemoteConfigService.create(remoteConfig: mockRemoteConfig);
    });

    test('enableOnboardingFlow returns true when remote flag is true', () {
      when(
        mockRemoteConfig.getBool('enable_onboarding_flow'),
      ).thenReturn(true);

      expect(service.enableOnboardingFlow, true);
    });

    test('enableOnboardingFlow returns false when remote flag is false', () {
      when(
        mockRemoteConfig.getBool('enable_onboarding_flow'),
      ).thenReturn(false);

      expect(service.enableOnboardingFlow, false);
    });

    test('enableOnboardingFlow returns false when reading throws', () {
      when(
        mockRemoteConfig.getBool('enable_onboarding_flow'),
      ).thenThrow(Exception('remote config error'));

      expect(service.enableOnboardingFlow, false);
    });

    test('isReady is false before initialize() is called', () {
      expect(service.isReady, false);
    });

    test('initialize() sets isReady to true on success', () async {
      when(mockRemoteConfig.setDefaults(any)).thenAnswer((_) => Future.value());
      when(
        mockRemoteConfig.setConfigSettings(any),
      ).thenAnswer((_) => Future.value());
      when(mockRemoteConfig.fetchAndActivate()).thenAnswer((_) async => true);

      await service.initialize();

      expect(service.isReady, true);
    });

    test('initialize() sets isReady to true even when fetch fails', () async {
      when(mockRemoteConfig.setDefaults(any)).thenAnswer((_) => Future.value());
      when(
        mockRemoteConfig.setConfigSettings(any),
      ).thenAnswer((_) => Future.value());
      when(
        mockRemoteConfig.fetchAndActivate(),
      ).thenThrow(Exception('network error'));

      await service.initialize();

      expect(
        service.isReady,
        true,
        reason: 'Service should be usable with defaults even if fetch fails',
      );
    });
  });
}
