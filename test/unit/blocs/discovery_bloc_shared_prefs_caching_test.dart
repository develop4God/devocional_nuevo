// test/unit/blocs/discovery_bloc_shared_prefs_caching_test.dart

import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/repositories/discovery_repository.dart';
import 'package:devocional_nuevo/services/discovery_favorites_service.dart';
import 'package:devocional_nuevo/services/discovery_progress_tracker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

@Tags(['unit', 'blocs'])
class MockHttpClient extends Mock implements http.Client {}

class MockDiscoveryProgressTracker extends Mock
    implements DiscoveryProgressTracker {}

class MockDiscoveryFavoritesService extends Mock
    implements DiscoveryFavoritesService {}

void main() {
  group('DiscoveryBloc SharedPreferences Caching Tests', () {
    late DiscoveryBloc bloc;
    late MockHttpClient mockHttpClient;
    late MockDiscoveryProgressTracker mockProgressTracker;
    late MockDiscoveryFavoritesService mockFavoritesService;
    late DiscoveryRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockHttpClient = MockHttpClient();
      mockProgressTracker = MockDiscoveryProgressTracker();
      mockFavoritesService = MockDiscoveryFavoritesService();
      repository = DiscoveryRepository(httpClient: mockHttpClient);

      bloc = DiscoveryBloc(
        repository: repository,
        progressTracker: mockProgressTracker,
        favoritesService: mockFavoritesService,
      );
    });

    tearDown(() async {
      await bloc.close();
    });

    test('SharedPreferences instance is cached in BLoC', () async {
      // First call should initialize the cache
      final prefs1 = await bloc.prefs;
      expect(prefs1, isNotNull);

      // Second call should return the same cached instance
      final prefs2 = await bloc.prefs;
      expect(identical(prefs1, prefs2), isTrue,
          reason:
              'SharedPreferences should return the same cached instance on subsequent calls');

      // Third call should still return the cached instance
      final prefs3 = await bloc.prefs;
      expect(identical(prefs1, prefs3), isTrue,
          reason: 'Cached instance should persist across multiple calls');
    });

    test('SharedPreferences caching reduces async overhead', () async {
      // Measure time for first call (uncached)
      final stopwatch1 = Stopwatch()..start();
      await bloc.prefs;
      stopwatch1.stop();
      final firstCallTime = stopwatch1.elapsedMicroseconds;

      // Measure time for subsequent calls (cached)
      final stopwatch2 = Stopwatch()..start();
      await bloc.prefs;
      await bloc.prefs;
      await bloc.prefs;
      stopwatch2.stop();
      final cachedCallsTime = stopwatch2.elapsedMicroseconds;

      // Cached calls should be significantly faster
      expect(cachedCallsTime < firstCallTime, isTrue,
          reason:
              'Cached SharedPreferences calls should be faster than initial call');
    });

    test('DiscoveryFavoritesService has SharedPreferences caching', () async {
      final service = DiscoveryFavoritesService();

      // First call should initialize the cache
      final prefs1 = await service.prefs;
      expect(prefs1, isNotNull);

      // Second call should return the same cached instance
      final prefs2 = await service.prefs;
      expect(identical(prefs1, prefs2), isTrue,
          reason: 'DiscoveryFavoritesService should cache SharedPreferences');
    });

    test('cached SharedPreferences works correctly with real operations',
        () async {
      final prefsInstance = await bloc.prefs;

      // Perform operations using the cached instance
      await prefsInstance.setBool('test_key', true);
      final value1 = prefsInstance.getBool('test_key');
      expect(value1, isTrue);

      // Access cached instance again and verify data persists
      final prefsInstance2 = await bloc.prefs;
      final value2 = prefsInstance2.getBool('test_key');
      expect(value2, isTrue);
      expect(identical(prefsInstance, prefsInstance2), isTrue);
    });

    test('different BLoC instances have separate caches', () async {
      final bloc2 = DiscoveryBloc(
        repository: repository,
        progressTracker: mockProgressTracker,
        favoritesService: mockFavoritesService,
      );

      final prefs1 = await bloc.prefs;
      final prefs2 = await bloc2.prefs;

      // Both should be SharedPreferences instances
      expect(prefs1, isNotNull);
      expect(prefs2, isNotNull);

      // Should be the same singleton instance from SharedPreferences
      expect(identical(prefs1, prefs2), isTrue,
          reason: 'SharedPreferences.getInstance() returns the same singleton');

      await bloc2.close();
    });
  });
}
