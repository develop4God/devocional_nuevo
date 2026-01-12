// test/integration/discovery_offline_cache_test.dart
// Integration tests for Discovery offline cache functionality

import 'dart:convert';
import 'dart:io';

import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_event.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_state.dart';
import 'package:devocional_nuevo/models/discovery_devotional_model.dart';
import 'package:devocional_nuevo/models/discovery_section_model.dart';
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

  group('Discovery Offline Cache Tests', () {
    late MockHttpClient mockHttpClient;
    late MockDiscoveryProgressTracker mockProgressTracker;

    setUp(() {
      mockHttpClient = MockHttpClient();
      mockProgressTracker = MockDiscoveryProgressTracker();
      SharedPreferences.setMockInitialValues({});
    });

    test('Loads study from cache when available', () async {
      final cachedStudy = DiscoveryDevotional(
        id: 'study1',
        versiculo: 'John 3:16',
        reflexion: 'Cached reflection',
        paraMeditar: ['Cached point'],
        oracion: 'Cached prayer',
        date: DateTime.now(),
        secciones: [
          DiscoverySection(
            titulo: 'Cached Section',
            contenido: 'Cached content',
            tipo: SectionType.natural,
          ),
        ],
        preguntasDiscovery: ['Cached question'],
        versiculoClave: 'John 3:16',
      );

      // Setup cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'discovery_cache_study1_es',
        jsonEncode(cachedStudy.toJson()),
      );

      final repository = DiscoveryRepository(httpClient: mockHttpClient);
      final bloc = DiscoveryBloc(
        repository: repository,
        progressTracker: mockProgressTracker,
      );

      // Load study - should come from cache
      bloc.add(LoadDiscoveryStudy('study1', languageCode: 'es'));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<DiscoveryLoaded>());
      final state = bloc.state as DiscoveryLoaded;
      expect(state.isStudyLoaded('study1'), isTrue);
      expect(state.getStudy('study1')?.reflexion, 'Cached reflection');

      // HTTP client should not have been called (loaded from cache)
      verifyNever(() => mockHttpClient.get(any()));

      bloc.close();
    });

    test('Falls back to network when cache is empty', () async {
      final networkStudy = DiscoveryDevotional(
        id: 'study1',
        versiculo: 'John 3:16',
        reflexion: 'Network reflection',
        paraMeditar: ['Network point'],
        oracion: 'Network prayer',
        date: DateTime.now(),
        secciones: [
          DiscoverySection(
            titulo: 'Network Section',
            contenido: 'Network content',
            tipo: SectionType.natural,
          ),
        ],
        preguntasDiscovery: ['Network question'],
        versiculoClave: 'John 3:16',
      );

      // Setup network response
      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response(
          jsonEncode(networkStudy.toJson()),
          200,
        ),
      );

      final repository = DiscoveryRepository(httpClient: mockHttpClient);
      final bloc = DiscoveryBloc(
        repository: repository,
        progressTracker: mockProgressTracker,
      );

      bloc.add(LoadDiscoveryStudy('study1', languageCode: 'es'));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<DiscoveryLoaded>());
      final state = bloc.state as DiscoveryLoaded;
      expect(state.isStudyLoaded('study1'), isTrue);
      expect(state.getStudy('study1')?.reflexion, 'Network reflection');

      // HTTP client should have been called
      verify(() => mockHttpClient.get(any())).called(greaterThan(0));

      bloc.close();
    });

    test('Caches study after successful network fetch', () async {
      final networkStudy = DiscoveryDevotional(
        id: 'study1',
        versiculo: 'John 3:16',
        reflexion: 'To be cached',
        paraMeditar: ['Point 1'],
        oracion: 'Prayer',
        date: DateTime.now(),
        secciones: [],
        preguntasDiscovery: [],
        versiculoClave: 'John 3:16',
      );

      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response(
          jsonEncode(networkStudy.toJson()),
          200,
        ),
      );

      final repository = DiscoveryRepository(httpClient: mockHttpClient);
      final bloc = DiscoveryBloc(
        repository: repository,
        progressTracker: mockProgressTracker,
      );

      bloc.add(LoadDiscoveryStudy('study1', languageCode: 'es'));
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify study was cached
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('discovery_cache_study1_es');
      expect(cachedData, isNotNull);
      expect(cachedData, contains('To be cached'));

      bloc.close();
    });

    test('Handles network error gracefully when cache exists', () async {
      final cachedStudy = DiscoveryDevotional(
        id: 'study1',
        versiculo: 'John 3:16',
        reflexion: 'Cached fallback',
        paraMeditar: [],
        oracion: 'Prayer',
        date: DateTime.now(),
        secciones: [],
        preguntasDiscovery: [],
        versiculoClave: 'John 3:16',
      );

      // Setup cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'discovery_cache_study1_es',
        jsonEncode(cachedStudy.toJson()),
      );

      // Setup network to fail
      when(() => mockHttpClient.get(any()))
          .thenThrow(const SocketException('No internet'));

      final repository = DiscoveryRepository(httpClient: mockHttpClient);
      final bloc = DiscoveryBloc(
        repository: repository,
        progressTracker: mockProgressTracker,
      );

      bloc.add(LoadDiscoveryStudy('study1', languageCode: 'es'));
      await Future.delayed(const Duration(milliseconds: 100));

      // Should load from cache despite network error
      expect(bloc.state, isA<DiscoveryLoaded>());
      final state = bloc.state as DiscoveryLoaded;
      expect(state.isStudyLoaded('study1'), isTrue);
      expect(state.getStudy('study1')?.reflexion, 'Cached fallback');

      bloc.close();
    });

    test('Shows error when both network and cache fail', () async {
      // No cache, network fails
      when(() => mockHttpClient.get(any()))
          .thenThrow(const SocketException('No internet'));

      final repository = DiscoveryRepository(httpClient: mockHttpClient);
      final bloc = DiscoveryBloc(
        repository: repository,
        progressTracker: mockProgressTracker,
      );

      bloc.add(LoadDiscoveryStudy('study1', languageCode: 'es'));
      await Future.delayed(const Duration(milliseconds: 100));

      // Should show error state
      expect(bloc.state, isA<DiscoveryError>());

      bloc.close();
    });

    test('Repository can clear cache', () async {
      // Setup some cached data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('discovery_cache_study1_es', 'cached data 1');
      await prefs.setString('discovery_cache_study2_es', 'cached data 2');
      await prefs.setString('other_key', 'should not be deleted');

      final repository = DiscoveryRepository(httpClient: mockHttpClient);

      // Clear cache
      await repository.clearCache();

      // Discovery cache should be cleared
      expect(prefs.getString('discovery_cache_study1_es'), isNull);
      expect(prefs.getString('discovery_cache_study2_es'), isNull);

      // Other keys should remain
      expect(prefs.getString('other_key'), 'should not be deleted');
    });

    test('Index is cached for 1 hour', () async {
      final indexResponse = {
        'studies': [
          {'id': 'study1'},
          {'id': 'study2'},
        ],
      };

      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode(indexResponse), 200),
      );

      final repository = DiscoveryRepository(httpClient: mockHttpClient);

      // First call - should fetch from network
      final studies1 = await repository.fetchAvailableStudies();
      expect(studies1.length, 2);

      // Second call immediately after - should use cache
      final studies2 = await repository.fetchAvailableStudies();
      expect(studies2.length, 2);

      // Should only call network once (second call used cache)
      verify(() => mockHttpClient.get(any())).called(1);
    });
  });
}
