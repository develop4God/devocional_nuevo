@Tags(['unit', 'providers'])
library;

import 'package:devocional_nuevo/models/spiritual_stats_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/repositories/devocional_repository.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

class _MockDevocionalRepository extends Mock implements DevocionalRepository {}

/// Records the calls DevocionalProvider makes to the stats service.
class _RecordingStatsService extends FakeSpiritualStatsService {
  final List<String> readIds = [];
  final List<int?> readFavoritesCounts = [];
  final List<int> favoritesCounts = [];

  @override
  Future<SpiritualStats> recordDevocionalRead({
    required String devocionalId,
    int? favoritesCount,
    int readingTimeSeconds = 0,
    double scrollPercentage = 0.0,
  }) async {
    readIds.add(devocionalId);
    readFavoritesCounts.add(favoritesCount);
    return SpiritualStats();
  }

  @override
  Future<SpiritualStats> updateFavoritesCount(int favoritesCount) async {
    favoritesCounts.add(favoritesCount);
    return SpiritualStats();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingStatsService stats;
  late DevocionalProvider provider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ServiceLocator().reset();
    stats = _RecordingStatsService();
    provider = DevocionalProvider(
      enableAudio: false,
      devocionalRepository: _MockDevocionalRepository(),
      statsService: stats,
    );
  });

  tearDown(() {
    provider.dispose();
    ServiceLocator().reset();
  });

  group('DevocionalProvider uses the injected ISpiritualStatsService', () {
    test('recordDevocionalRead delegates to the injected service', () async {
      await provider.recordDevocionalRead('dev_42');

      expect(stats.readIds, ['dev_42']);
      expect(stats.readFavoritesCounts, [0]);
    });

    test('adding and removing a favorite updates the favorites count',
        () async {
      await provider.toggleFavorite('dev_1');
      await provider.toggleFavorite('dev_2');
      await provider.toggleFavorite('dev_1');
      await Future<void>.delayed(Duration.zero);

      expect(stats.favoritesCounts, [1, 2, 1]);
    });

    test('toggleFavorite with an empty id never touches stats', () async {
      await expectLater(provider.toggleFavorite(''), throwsArgumentError);

      expect(stats.favoritesCounts, isEmpty);
    });
  });
}
