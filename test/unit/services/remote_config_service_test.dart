import 'package:devocional_nuevo/services/remote_config_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Generate mocks for FirebaseRemoteConfig
@GenerateMocks([FirebaseRemoteConfig])
import 'remote_config_service_test.mocks.dart';

@Tags(['unit', 'services'])
void main() {
  group('RemoteConfigService', () {
    late ServiceLocator locator;
    late MockFirebaseRemoteConfig mockRemoteConfig;
    late RemoteConfigService service;

    setUp(() {
      // Reset service locator before each test
      locator = ServiceLocator();
      locator.reset();

      // Create mock and service with injected dependency
      mockRemoteConfig = MockFirebaseRemoteConfig();
      service = RemoteConfigService.create(remoteConfig: mockRemoteConfig);
    });

    tearDown(() {
      // Clean up after each test
      locator.reset();
    });

    group('Dependency Injection', () {
      test('should allow injection of FirebaseRemoteConfig for testing', () {
        // Service created with mock should not be null
        expect(service, isNotNull);
        expect(service, isA<RemoteConfigService>());
      });

      test('should use factory constructor pattern for DI', () {
        // Este test verifica que el servicio real sigue el patrón de DI
        // En vez de usar la instancia real (que requiere Firebase inicializado), usamos un mock
        final realService = RemoteConfigService.create(
          remoteConfig: mockRemoteConfig,
        );
        expect(realService, isA<RemoteConfigService>());
      });

      test('should be registered as lazy singleton in ServiceLocator', () {
        // Register service in locator
        locator.registerLazySingleton<RemoteConfigService>(
          () => RemoteConfigService.create(remoteConfig: mockRemoteConfig),
        );

        // Get service twice
        final instance1 = locator.get<RemoteConfigService>();
        final instance2 = locator.get<RemoteConfigService>();

        // Should return same instance (singleton behavior)
        expect(instance1, same(instance2));
      });
    });

    group('Feature Flags', () {
      test('should return default false for feature_legacy', () {
        when(mockRemoteConfig.getBool('feature_legacy')).thenReturn(false);

        expect(service.featureLegacy, false);
        verify(mockRemoteConfig.getBool('feature_legacy')).called(1);
      });

      test('should return default false for feature_bloc', () {
        when(mockRemoteConfig.getBool('feature_bloc')).thenReturn(false);

        expect(service.featureBloc, false);
        verify(mockRemoteConfig.getBool('feature_bloc')).called(1);
      });

      test('should return true when feature_legacy is enabled', () {
        when(mockRemoteConfig.getBool('feature_legacy')).thenReturn(true);

        expect(service.featureLegacy, true);
        verify(mockRemoteConfig.getBool('feature_legacy')).called(1);
      });

      test('should return true when feature_bloc is enabled', () {
        when(mockRemoteConfig.getBool('feature_bloc')).thenReturn(true);

        expect(service.featureBloc, true);
        verify(mockRemoteConfig.getBool('feature_bloc')).called(1);
      });

      test('should handle getBool errors and return false', () {
        when(
          mockRemoteConfig.getBool('feature_legacy'),
        ).thenThrow(Exception('Remote Config error'));

        // Should not throw, should return false
        expect(service.featureLegacy, false);
      });
    });

    group('Initialization', () {
      test('should initialize successfully with valid config', () async {
        // Mock the initialization chain
        when(mockRemoteConfig.setDefaults(any)).thenAnswer((_) async => {});
        when(
          mockRemoteConfig.setConfigSettings(any),
        ).thenAnswer((_) async => {});
        when(mockRemoteConfig.fetchAndActivate()).thenAnswer((_) async => true);
        when(mockRemoteConfig.getBool('feature_legacy')).thenReturn(false);
        when(mockRemoteConfig.getBool('feature_bloc')).thenReturn(false);

        await service.initialize();

        // Verify initialization calls
        verify(mockRemoteConfig.setDefaults(any)).called(1);
        verify(mockRemoteConfig.setConfigSettings(any)).called(1);
        verify(mockRemoteConfig.fetchAndActivate()).called(1);

        // Should be ready after successful initialization
        expect(service.isReady, true);
      });

      test('should not reinitialize if already initialized', () async {
        // First initialization
        when(mockRemoteConfig.setDefaults(any)).thenAnswer((_) async => {});
        when(
          mockRemoteConfig.setConfigSettings(any),
        ).thenAnswer((_) async => {});
        when(mockRemoteConfig.fetchAndActivate()).thenAnswer((_) async => true);
        when(mockRemoteConfig.getBool(any)).thenReturn(false);

        await service.initialize();
        await service.initialize(); // Second call should skip

        // Should only initialize once
        verify(mockRemoteConfig.setDefaults(any)).called(1);
        verify(mockRemoteConfig.fetchAndActivate()).called(1);
      });

      test('should handle initialization errors gracefully', () async {
        when(mockRemoteConfig.setDefaults(any)).thenAnswer((_) async => {});
        when(
          mockRemoteConfig.setConfigSettings(any),
        ).thenThrow(Exception('Config error'));

        // Should not throw
        await service.initialize();

        // Should still be ready (using defaults)
        expect(service.isReady, true);
      });

      test('should reset initialization status for testing', () async {
        // Initialize first
        when(mockRemoteConfig.setDefaults(any)).thenAnswer((_) async => {});
        when(
          mockRemoteConfig.setConfigSettings(any),
        ).thenAnswer((_) async => {});
        when(mockRemoteConfig.fetchAndActivate()).thenAnswer((_) async => true);
        when(mockRemoteConfig.getBool(any)).thenReturn(false);

        await service.initialize();
        expect(service.isReady, true);

        // Reset
        service.resetForTesting();
        expect(service.isReady, false);

        // Should be able to initialize again
        await service.initialize();
        expect(service.isReady, true);
      });
    });

    group('Refresh', () {
      test('should refresh remote config values', () async {
        when(mockRemoteConfig.fetchAndActivate()).thenAnswer((_) async => true);
        when(mockRemoteConfig.getBool(any)).thenReturn(false);

        await service.refresh();

        verify(mockRemoteConfig.fetchAndActivate()).called(1);
      });

      test('should handle refresh errors gracefully', () async {
        when(
          mockRemoteConfig.fetchAndActivate(),
        ).thenThrow(Exception('Network error'));

        // Should not throw
        await service.refresh();

        verify(mockRemoteConfig.fetchAndActivate()).called(1);
      });
    });
  });
}
