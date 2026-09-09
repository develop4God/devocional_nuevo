@Tags(['unit', 'providers'])
library;

// test/unit/providers/devocional_provider_version_switch_offline_test.dart
//
// Regression test: when the user switches Bible version via the drawer and
// the network is unavailable (fetch for the new version fails), the drawer
// must keep showing the previously selected version, not the unavailable
// one, even though an error message is shown.

import 'dart:io';

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/repositories/devocional_repository.dart';
import 'package:devocional_nuevo/services/cache_metadata_service.dart';
import 'package:devocional_nuevo/services/devocional_index_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockDevocionalIndexService extends Mock
    implements DevocionalIndexService {}

class _MockCacheMetadataService extends Mock implements CacheMetadataService {}

class _MockDevocionalRepository extends Mock implements DevocionalRepository {}

void main() {
  group('DevocionalProvider.setSelectedVersion offline handling', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      const MethodChannel firebaseCoreChannel = MethodChannel(
        'plugins.flutter.io/firebase_core',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(firebaseCoreChannel, (
        MethodCall methodCall,
      ) async {
        switch (methodCall.method) {
          case 'Firebase#initializeCore':
            return [
              {
                'name': '[DEFAULT]',
                'options': {
                  'apiKey': 'fake-api-key',
                  'appId': 'fake-app-id',
                  'messagingSenderId': 'fake-sender-id',
                  'projectId': 'fake-project-id',
                },
                'pluginConstants': {},
              },
            ];
          case 'Firebase#initializeApp':
            return {
              'name': '[DEFAULT]',
              'options': {
                'apiKey': 'fake-api-key',
                'appId': 'fake-app-id',
                'messagingSenderId': 'fake-sender-id',
                'projectId': 'fake-project-id',
              },
              'pluginConstants': {},
            };
          default:
            return null;
        }
      });

      const MethodChannel crashlyticsChannel = MethodChannel(
        'plugins.flutter.io/firebase_crashlytics',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(crashlyticsChannel, (
        MethodCall methodCall,
      ) async {
        switch (methodCall.method) {
          case 'Crashlytics#checkForUnsentReports':
            return false;
          case 'Crashlytics#didCrashOnPreviousExecution':
            return false;
          default:
            return null;
        }
      });

      try {
        await Firebase.initializeApp();
      } catch (e) {
        // Firebase may already be initialized by another test file in the
        // same run.
      }
    });

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'reverts to the previous version when the new version fails to load (no network)',
      () async {
        SharedPreferences.setMockInitialValues({
          'selectedLanguage': 'es',
          'selectedVersion': 'RVR1960',
        });

        final mockIndexService = _MockDevocionalIndexService();
        final mockCacheService = _MockCacheMetadataService();
        final mockRepository = _MockDevocionalRepository();

        final sampleDevocional = Devocional(
          id: 'sample_1',
          date: DateTime(2026, 1, 1),
          versiculo: 'Sample verse',
          reflexion: 'Sample reflection',
          paraMeditar: [],
          oracion: 'Sample prayer',
          version: 'RVR1960',
          language: 'es',
        );

        when(() => mockRepository.getAvailableYears())
            .thenAnswer((_) async => [2026]);
        when(() => mockRepository.wasLastFetchOffline).thenReturn(false);
        when(() => mockRepository.filterByVersion(any(), any())).thenAnswer(
          (invocation) {
            final list = invocation.positionalArguments[0] as List<Devocional>;
            final version = invocation.positionalArguments[1] as String;
            return list.where((d) => d.version == version).toList();
          },
        );

        // Current version (RVR1960) fetches fine; new version (NVI) fails
        // as if the network is unavailable.
        when(() => mockRepository.fetchAll(any(), 'es', 'RVR1960'))
            .thenAnswer((_) async => [sampleDevocional]);
        when(() => mockRepository.fetchAll(any(), 'es', 'NVI'))
            .thenThrow(Exception('Network unreachable'));

        final provider = DevocionalProvider(
          enableAudio: false,
          devocionalIndexService: mockIndexService,
          cacheMetadataService: mockCacheService,
          devocionalRepository: mockRepository,
        );

        await provider.initializeData();
        expect(provider.selectedVersion, 'RVR1960');

        await provider.setSelectedVersion('NVI');

        // The drawer/UI must keep showing the previously selected version,
        // not the one that failed to load.
        expect(provider.selectedVersion, 'RVR1960');
        expect(provider.errorMessage, isNotNull);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('selectedVersion'), 'RVR1960');
      },
    );

    test(
      'keeps the revert fetch\'s own error when reverting also fails (network fully down)',
      () async {
        SharedPreferences.setMockInitialValues({
          'selectedLanguage': 'es',
          'selectedVersion': 'RVR1960',
        });

        final mockIndexService = _MockDevocionalIndexService();
        final mockCacheService = _MockCacheMetadataService();
        final mockRepository = _MockDevocionalRepository();

        final sampleDevocional = Devocional(
          id: 'sample_1',
          date: DateTime(2026, 1, 1),
          versiculo: 'Sample verse',
          reflexion: 'Sample reflection',
          paraMeditar: [],
          oracion: 'Sample prayer',
          version: 'RVR1960',
          language: 'es',
        );

        when(() => mockRepository.wasLastFetchOffline).thenReturn(false);
        when(() => mockRepository.filterByVersion(any(), any())).thenAnswer(
          (invocation) {
            final list = invocation.positionalArguments[0] as List<Devocional>;
            final version = invocation.positionalArguments[1] as String;
            return list.where((d) => d.version == version).toList();
          },
        );
        when(() => mockRepository.fetchAll(any(), 'es', 'RVR1960'))
            .thenAnswer((_) async => [sampleDevocional]);

        // First call (init) succeeds; the second call (fetching NVI) fails
        // with a transient network error; the third call (reverting to
        // RVR1960) fails with a non-network error, so the two failures map
        // to different error messages and a masked/stale message is
        // observable.
        var callCount = 0;
        when(() => mockRepository.getAvailableYears()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return [2026];
          if (callCount == 2) {
            throw const SocketException('Network unreachable');
          }
          throw Exception('Local cache corrupted');
        });

        final provider = DevocionalProvider(
          enableAudio: false,
          devocionalIndexService: mockIndexService,
          cacheMetadataService: mockCacheService,
          devocionalRepository: mockRepository,
        );

        await provider.initializeData();
        expect(provider.selectedVersion, 'RVR1960');

        await provider.setSelectedVersion('NVI');

        // Reverted the selected version even though the revert fetch failed.
        expect(provider.selectedVersion, 'RVR1960');
        // The error shown must reflect the revert fetch's own (non-network)
        // failure, not be silently overwritten by the original NVI
        // (network) failure's message.
        expect(provider.errorMessage, 'devotionals.generic_error');
        expect(provider.devocionales, isEmpty);
      },
    );
  });
}
