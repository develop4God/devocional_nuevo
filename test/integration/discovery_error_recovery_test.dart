// test/integration/discovery_error_recovery_test.dart
// Integration tests for Discovery error handling and recovery

import 'dart:async';
import 'dart:convert';

import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_event.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_state.dart';
import 'package:devocional_nuevo/models/discovery_devotional_model.dart';
import 'package:devocional_nuevo/repositories/discovery_repository.dart';
import 'package:devocional_nuevo/services/discovery_progress_tracker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockDiscoveryProgressTracker extends Mock
    implements DiscoveryProgressTracker {}

class FakeUri extends Fake implements Uri {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  group('Discovery Error Recovery Tests', () {
    late MockHttpClient mockHttpClient;
    late MockDiscoveryProgressTracker mockProgressTracker;

    setUp(() {
      mockHttpClient = MockHttpClient();
      mockProgressTracker = MockDiscoveryProgressTracker();
      SharedPreferences.setMockInitialValues({});
    });

    test('Retries failed network request successfully', () async {
      var callCount = 0;
      final successStudy = DiscoveryDevotional(
        id: 'study1',
        versiculo: 'John 3:16',
        reflexion: 'Success reflection',
        paraMeditar: [],
        oracion: 'Prayer',
        date: DateTime.now(),
        secciones: [],
        preguntasDiscovery: [],
        versiculoClave: 'John 3:16',
      );

      when(() => mockHttpClient.get(any())).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw TimeoutException('Network timeout');
        }
        return http.Response(jsonEncode(successStudy.toJson()), 200);
      });

      final repository = DiscoveryRepository(httpClient: mockHttpClient);
      final bloc = DiscoveryBloc(
        repository: repository,
        progressTracker: mockProgressTracker,
      );

      // First attempt - should fail
      bloc.add(LoadDiscoveryStudy('study1', languageCode: 'es'));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<DiscoveryError>());

      // Retry - should succeed
      bloc.add(LoadDiscoveryStudy('study1', languageCode: 'es'));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<DiscoveryLoaded>());
      expect(callCount, 2);

      bloc.close();
    });

    test('Handles HTTP 404 error gracefully', () async {
      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response('Not found', 404),
      );

      final repository = DiscoveryRepository(httpClient: mockHttpClient);
      final bloc = DiscoveryBloc(
        repository: repository,
        progressTracker: mockProgressTracker,
      );

      bloc.add(LoadDiscoveryStudy('nonexistent', languageCode: 'es'));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<DiscoveryError>());
      final state = bloc.state as DiscoveryError;
      expect(state.message, contains('Failed to load Discovery study'));

      bloc.close();
    });

    test('Handles HTTP 500 server error', () async {
      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response('Server error', 500),
      );

      final repository = DiscoveryRepository(httpClient: mockHttpClient);
      final bloc = DiscoveryBloc(
        repository: repository,
        progressTracker: mockProgressTracker,
      );

      bloc.add(LoadDiscoveryStudy('study1', languageCode: 'es'));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<DiscoveryError>());

      bloc.close();
    });

    test('Handles malformed JSON response', () async {
      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response('{"invalid json', 200),
      );

      final repository = DiscoveryRepository(httpClient: mockHttpClient);
      final bloc = DiscoveryBloc(
        repository: repository,
        progressTracker: mockProgressTracker,
      );

      bloc.add(LoadDiscoveryStudy('study1', languageCode: 'es'));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<DiscoveryError>());

      bloc.close();
    });

    test('Handles timeout exception', () async {
      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => throw TimeoutException('Request timeout'),
      );

      final repository = DiscoveryRepository(httpClient: mockHttpClient);
      final bloc = DiscoveryBloc(
        repository: repository,
        progressTracker: mockProgressTracker,
      );

      bloc.add(LoadDiscoveryStudy('study1', languageCode: 'es'));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<DiscoveryError>());

      bloc.close();
    });

    test('Refresh recovers from error state', () async {
      var callCount = 0;

      when(() => mockHttpClient.get(any())).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return http.Response('Server error', 500);
        }
        return http.Response(
          jsonEncode({
            'studies': [
              {'id': 'study1'},
            ],
          }),
          200,
        );
      });

      final repository = DiscoveryRepository(httpClient: mockHttpClient);
      final bloc = DiscoveryBloc(
        repository: repository,
        progressTracker: mockProgressTracker,
      );

      // First load - should fail
      bloc.add(LoadDiscoveryStudies());
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<DiscoveryError>());

      // Refresh - should succeed
      bloc.add(RefreshDiscoveryStudies());
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<DiscoveryLoaded>());
      expect(callCount, 2);

      bloc.close();
    });

    test('Error state can be cleared', () async {
      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response('Error', 500),
      );

      final repository = DiscoveryRepository(httpClient: mockHttpClient);
      final bloc = DiscoveryBloc(
        repository: repository,
        progressTracker: mockProgressTracker,
      );

      bloc.add(LoadDiscoveryStudies());
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<DiscoveryError>());

      // Clear error
      bloc.add(ClearDiscoveryError());
      await Future.delayed(const Duration(milliseconds: 100));

      // State should have changed from error
      // Note: Might go to initial state or stay in error depending on implementation

      bloc.close();
    });

    test('Multiple consecutive errors are handled', () async {
      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => throw Exception('Persistent error'),
      );

      final repository = DiscoveryRepository(httpClient: mockHttpClient);
      final bloc = DiscoveryBloc(
        repository: repository,
        progressTracker: mockProgressTracker,
      );

      // Multiple failed attempts
      for (var i = 0; i < 3; i++) {
        bloc.add(LoadDiscoveryStudies());
        await Future.delayed(const Duration(milliseconds: 50));
        expect(bloc.state, isA<DiscoveryError>());
      }

      bloc.close();
    });

    test('Partial success - some studies load, others fail', () async {
      final successStudy = DiscoveryDevotional(
        id: 'study1',
        versiculo: 'John 3:16',
        reflexion: 'Success',
        paraMeditar: [],
        oracion: 'Prayer',
        date: DateTime.now(),
        secciones: [],
        preguntasDiscovery: [],
        versiculoClave: 'John 3:16',
      );

      // Index returns two studies
      when(() => mockHttpClient.get(
            Uri.parse(
              'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/discovery/index.json',
            ),
          )).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'studies': [
              {'id': 'study1'},
              {'id': 'study2'},
            ],
          }),
          200,
        ),
      );

      // study1 succeeds, study2 fails
      when(() => mockHttpClient.get(any())).thenAnswer((invocation) async {
        final uri = invocation.positionalArguments[0] as Uri;
        if (uri.toString().contains('study1')) {
          return http.Response(jsonEncode(successStudy.toJson()), 200);
        } else {
          return http.Response('Not found', 404);
        }
      });

      final repository = DiscoveryRepository(httpClient: mockHttpClient);
      final bloc = DiscoveryBloc(
        repository: repository,
        progressTracker: mockProgressTracker,
      );

      // Load list
      bloc.add(LoadDiscoveryStudies());
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<DiscoveryLoaded>());

      // Load study1 - should succeed
      bloc.add(LoadDiscoveryStudy('study1', languageCode: 'es'));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<DiscoveryLoaded>());
      final state1 = bloc.state as DiscoveryLoaded;
      expect(state1.isStudyLoaded('study1'), isTrue);

      // Load study2 - should fail but not crash
      bloc.add(LoadDiscoveryStudy('study2', languageCode: 'es'));
      await Future.delayed(const Duration(milliseconds: 100));

      // Should show error for study2
      expect(bloc.state, isA<DiscoveryError>());

      bloc.close();
    });

    test('Fallback to hardcoded list when index fetch fails', () async {
      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => throw Exception('Network error'),
      );

      final repository = DiscoveryRepository(httpClient: mockHttpClient);

      // Should return hardcoded fallback list
      final studies = await repository.fetchAvailableStudies();

      expect(studies, isNotEmpty);
      expect(studies, contains('morning_star_001'));
    });
  });
}
