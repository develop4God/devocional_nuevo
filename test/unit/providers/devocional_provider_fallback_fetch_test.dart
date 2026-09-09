@Tags(['unit', 'providers'])
library;

// test/unit/providers/devocional_provider_fallback_fetch_test.dart
//
// Regression test for DevocionalProvider's fallback-language fetch path
// (_fetchAllDevocionalesForLanguage's inner loop, devocional_provider.dart):
// when the selected language returns zero devotionals, the provider retries
// with the fallback language directly via httpClient.get(), bypassing
// DevocionalRepository. That call previously had no .timeout(), so a stalled
// connection could hang initializeData() forever.

import 'dart:async';

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/repositories/devocional_repository.dart';
import 'package:devocional_nuevo/services/cache_metadata_service.dart';
import 'package:devocional_nuevo/services/devocional_index_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockDevocionalIndexService extends Mock
    implements DevocionalIndexService {}

class _MockCacheMetadataService extends Mock implements CacheMetadataService {}

class _MockDevocionalRepository extends Mock implements DevocionalRepository {}

void main() {
  group('DevocionalProvider fallback-language fetch', () {
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
      'does not hang forever on a stalled connection',
      () async {
        SharedPreferences.setMockInitialValues({'selectedLanguage': 'en'});

        final mockIndexService = _MockDevocionalIndexService();
        final mockCacheService = _MockCacheMetadataService();
        final mockRepository = _MockDevocionalRepository();

        when(
          () => mockRepository.getAvailableYears(),
        ).thenAnswer((_) async => [2026]);
        when(
          () => mockRepository.fetchAll(any(), any(), any()),
        ).thenAnswer((_) async => <Devocional>[]);
        when(() => mockRepository.wasLastFetchOffline).thenReturn(false);

        // Simulates a stalled connection: the completer is never resolved,
        // so without a .timeout() this Future never completes.
        final stalledClient = MockClient((request) {
          return Completer<http.Response>().future;
        });

        final provider = DevocionalProvider(
          httpClient: stalledClient,
          enableAudio: false,
          devocionalIndexService: mockIndexService,
          cacheMetadataService: mockCacheService,
          devocionalRepository: mockRepository,
        );

        await expectLater(
          provider.initializeData(),
          completes,
        );
      },
      timeout: const Timeout(Duration(seconds: 25)),
    );
  });
}
