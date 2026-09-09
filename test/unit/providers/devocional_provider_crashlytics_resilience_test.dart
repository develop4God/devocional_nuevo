@Tags(['unit', 'providers'])
library;

// test/unit/providers/devocional_provider_crashlytics_resilience_test.dart
//
// Regression test proving DevocionalProvider's Crashlytics breadcrumb calls
// (_logFetchBreadcrumb in devocional_provider.dart) are diagnostic-only: a
// Crashlytics#log platform-channel failure must never propagate and break
// the actual devotional fetch. This class of bug was found while adding
// startup logging — Crashlytics calls placed unguarded inside the fetch loop
// caused a Firebase-not-ready failure to abort initializeData() entirely.

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

Devocional _fixtureDevocional() => Devocional(
      id: '2026-01-01',
      versiculo: 'Test verse',
      reflexion: 'Test reflection',
      paraMeditar: const [],
      oracion: 'Test prayer',
      date: DateTime(2026, 1, 1),
    );

void main() {
  group('DevocionalProvider Crashlytics call resilience', () {
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

      try {
        await Firebase.initializeApp();
      } catch (e) {
        // Firebase may already be initialized by another test file in the
        // same run.
      }
    });

    setUp(() {
      SharedPreferences.setMockInitialValues({});

      // Simulate a broken Crashlytics platform channel: every call throws,
      // as would happen if Crashlytics isn't ready yet on this session.
      const MethodChannel crashlyticsChannel = MethodChannel(
        'plugins.flutter.io/firebase_crashlytics',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(crashlyticsChannel, (
        MethodCall methodCall,
      ) async {
        throw PlatformException(
          code: 'error',
          message: 'Simulated Crashlytics channel failure',
        );
      });
    });

    tearDown(() {
      const MethodChannel crashlyticsChannel = MethodChannel(
        'plugins.flutter.io/firebase_crashlytics',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(crashlyticsChannel, null);
    });

    test(
      'a failing Crashlytics#log call does not abort initializeData()',
      () async {
        SharedPreferences.setMockInitialValues({'selectedLanguage': 'es'});

        final mockIndexService = _MockDevocionalIndexService();
        final mockCacheService = _MockCacheMetadataService();
        final mockRepository = _MockDevocionalRepository();

        when(
          () => mockRepository.getAvailableYears(),
        ).thenAnswer((_) async => [2026]);
        when(
          () => mockRepository.fetchAll(any(), any(), any()),
        ).thenAnswer((_) async => [_fixtureDevocional()]);
        when(() => mockRepository.wasLastFetchOffline).thenReturn(false);
        when(
          () => mockRepository.filterByVersion(any(), any()),
        ).thenAnswer(
          (invocation) => invocation.positionalArguments[0] as List<Devocional>,
        );

        final provider = DevocionalProvider(
          httpClient: MockClient(
            (request) async => http.Response('{}', 200),
          ),
          enableAudio: false,
          devocionalIndexService: mockIndexService,
          cacheMetadataService: mockCacheService,
          devocionalRepository: mockRepository,
        );

        await provider.initializeData();

        // If _logFetchBreadcrumb's guard were removed, the Crashlytics#log
        // failure above would surface as _fetchAllDevocionalesForLanguage's
        // catch branch instead, leaving devocionales empty and errorMessage
        // set — proving the diagnostic call broke the real fetch.
        expect(provider.devocionales, isNotEmpty);
        expect(provider.errorMessage, isNull);
      },
    );
  });
}
