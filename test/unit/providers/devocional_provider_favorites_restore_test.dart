import 'dart:convert';

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/repositories/devocional_repository.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

class FakeDevocionalRepository implements DevocionalRepository {
  final List<Devocional> _items;
  FakeDevocionalRepository(this._items);

  @override
  Future<List<Devocional>> fetchAll(int year, String language, String version) async {
    return _items;
  }

  @override
  List<Devocional> filterByVersion(List<Devocional> devocionales, String version) {
    if (version.isEmpty) return devocionales;
    return devocionales.where((d) => d.version == version).toList();
  }

  @override
  Future<bool> hasLocalData(int year, String language, String version) async => true;

  @override
  Future<bool> downloadAndStoreDevocionales(int year, String language, String version) async => true;

  @override
  bool get wasLastFetchOffline => false;

  @override
  Future<bool> downloadCurrentYearDevocionales(String language, String version) async => true;

  @override
  Future<bool> hasCurrentYearLocalData(String language, String version) async => true;

  @override
  Future<bool> hasTargetYearsLocalData(String language, String version) async => true;

  @override
  Future<List<int>> getAvailableYears() async => [2020];

  @override
  int findFirstUnreadDevocionalIndex(List<Devocional> devocionales, List<String> readDevocionalIds) {
    return 0;
  }
  @override
  Future<void> clearOldFiles() async {}

  @override
  void resetCache() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await setupFirebaseMocks();
    await registerTestServices();
  });

  test('Favorites are restored and synced with loaded devotionals', () async {
    // Prepare two devotionals available in repository
    final dev1 = Devocional(
      id: 'd1',
      versiculo: 'v1',
      reflexion: 'r1',
      paraMeditar: [],
      oracion: 'o1',
      date: DateTime(2020, 1, 1),
      version: 'RVR1960',
      language: 'es',
    );
    final dev2 = Devocional(
      id: 'd2',
      versiculo: 'v2',
      reflexion: 'r2',
      paraMeditar: [],
      oracion: 'o2',
      date: DateTime(2020, 1, 2),
      version: 'RVR1960',
      language: 'es',
    );

    // Override repository in the service locator with our fake
    final locator = ServiceLocator();
    if (locator.isRegistered<DevocionalRepository>()) {
      locator.unregister<DevocionalRepository>();
    }
    locator.registerSingleton<DevocionalRepository>(
      FakeDevocionalRepository([dev1, dev2]),
    );

    // Simulate restored favorites in SharedPreferences: only d2
    final restored = json.encode(['d2']);
    // SharedPreferences mock already initialized in registerTestServices
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favorite_ids', restored);

    final provider = DevocionalProvider();

    // Initialize provider which loads favorites and devotionals
    await provider.initializeData();

    // After initialization, favoriteIds should contain d2 and favoriteDevocionales should include dev2
    expect(provider.favoriteIds.contains('d2'), isTrue);
    expect(provider.favoriteDevocionales.length, 1);
    expect(provider.favoriteDevocionales.first.id, 'd2');

    // Now simulate a restore that changed favorites to d1
    final restored2 = json.encode(['d1']);
    await prefs.setString('favorite_ids', restored2);

    // Call reloadFavoritesFromStorage to pick up new favorites
    await provider.reloadFavoritesFromStorage();

    expect(provider.favoriteIds.contains('d1'), isTrue);
    expect(provider.favoriteDevocionales.length, 1);
    expect(provider.favoriteDevocionales.first.id, 'd1');
  });
}
