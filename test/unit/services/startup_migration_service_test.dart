@Tags(['unit', 'services'])
library;

// test/unit/services/startup_migration_service_test.dart
//
// Unit tests for StartupMigrationService gap-detection logic (V2).
// Covers leading gap (index 0) and interior gap, plus guards.

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/models/spiritual_stats_model.dart';
import 'package:devocional_nuevo/services/i_analytics_service.dart';
import 'package:devocional_nuevo/services/i_spiritual_stats_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/startup_migration_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Minimal test fakes ───────────────────────────────────────────────────────

class _FakeAnalyticsService implements IAnalyticsService {
  @override
  Future<void> logCustomEvent({
    required String eventName,
    Map<String, Object>? parameters,
  }) async {}

  @override
  Future<void> logTtsPlay() async {}

  @override
  Future<void> logDevocionalComplete({
    required String devocionalId,
    required String campaignTag,
    String source = 'read',
    int? readingTimeSeconds,
    double? scrollPercentage,
    double? listenedPercentage,
  }) async {}

  @override
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> resetAnalyticsData() async {}

  @override
  Future<void> logBottomBarAction({required String action}) async {}

  @override
  Future<void> logAppInit({Map<String, Object>? parameters}) async {}

  @override
  Future<void> logNavigationNext({
    required int currentIndex,
    required int totalDevocionales,
    required String viaBloc,
    String? fallbackReason,
  }) async {}

  @override
  Future<void> logNavigationPrevious({
    required int currentIndex,
    required int totalDevocionales,
    required String viaBloc,
    String? fallbackReason,
  }) async {}

  @override
  Future<void> logFabTapped({required String source}) async {}

  @override
  Future<void> logFabChoiceSelected({
    required String source,
    required String choice,
  }) async {}

  @override
  Future<void> logDiscoveryAction({
    required String action,
    String? studyId,
  }) async {}

  @override
  Future<void> logEncounterAction({
    required String action,
    String? encounterId,
    int? cardOrder,
  }) async {}

  @override
  Future<void> logBibleOpen({
    String? translation,
    String? book,
    int? chapter,
  }) async {}

  @override
  Future<void> logTtsBiblePlay({
    String? translation,
    String? book,
    int? chapter,
  }) async {}
}

class _FakeStatsService implements ISpiritualStatsService {
  final List<String> markedAsRead = [];

  @override
  Future<SpiritualStats> getStats() async => SpiritualStats();

  @override
  Future<void> saveStats(SpiritualStats stats) async {}

  @override
  Future<SpiritualStats> recordDevocionalRead({
    required String devocionalId,
    int? favoritesCount,
    int readingTimeSeconds = 0,
    double scrollPercentage = 0.0,
  }) async =>
      SpiritualStats();

  @override
  Future<SpiritualStats> recordDevocionalHeard({
    required String devocionalId,
    required double listenedPercentage,
    int? favoritesCount,
  }) async =>
      SpiritualStats();

  @override
  Future<SpiritualStats> recordDevocionalCompletado({
    required String devocionalId,
    int readingTimeSeconds = 0,
    double scrollPercentage = 0.0,
    double listenedPercentage = 0.0,
    int? favoritesCount,
    String source = 'unknown',
  }) async =>
      SpiritualStats();

  @override
  Future<Map<String, dynamic>> getAllStats() async => {};

  @override
  Future<void> restoreStats(Map<String, dynamic> backupData) async {}

  @override
  Future<bool> isJsonBackupEnabled() async => false;

  @override
  Future<void> setJsonBackupEnabled(bool enabled) async {}

  @override
  Future<bool> hasDevocionalBeenRead(String devocionalId) async => false;

  @override
  Future<List<DateTime>> getReadDatesForVisualization() async => [];

  @override
  Future<void> resetStats() async {}

  @override
  Future<String?> exportStatsAsJson() async => null;

  @override
  Future<bool> importStatsFromJson(String jsonString) async => false;

  @override
  Future<String?> getBackupFilePath() async => null;

  @override
  Future<SpiritualStats> updateFavoritesCount(int favoritesCount) async =>
      SpiritualStats();

  @override
  Future<bool> createManualBackup() async => false;

  @override
  Future<void> bulkMarkAsRead(List<String> ids) async {
    markedAsRead.addAll(ids);
  }
}

// ── Helper ───────────────────────────────────────────────────────────────────

Devocional _dev(String id) => Devocional(
      id: id,
      versiculo: 'v',
      reflexion: 'r',
      paraMeditar: [],
      oracion: 'o',
      date: DateTime(2024),
    );

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late _FakeStatsService fakeStats;
  late StartupMigrationService sut;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ServiceLocator().reset();
    ServiceLocator().registerSingleton<IAnalyticsService>(
      _FakeAnalyticsService(),
    );
    fakeStats = _FakeStatsService();
    sut = StartupMigrationService(statsService: fakeStats);
  });

  tearDown(() {
    ServiceLocator().reset();
  });

  group('leading gap at index 0', () {
    test('fills gap when first devotional is unread and second is read',
        () async {
      final devs = [_dev('d0'), _dev('d1'), _dev('d2')];
      await sut.runAll(devs, ['d1', 'd2']);

      expect(fakeStats.markedAsRead, contains('d0'));
      expect(fakeStats.markedAsRead.length, 1);
    });

    test('real-world case: filipenses2_3-4RVR1960 skipped, d1 and d2 read',
        () async {
      final devs = [
        _dev('filipenses2_3-4RVR1960'),
        _dev('d1'),
        _dev('d2'),
      ];
      await sut.runAll(devs, ['d1', 'd2']);

      expect(fakeStats.markedAsRead, contains('filipenses2_3-4RVR1960'));
      expect(fakeStats.markedAsRead.length, 1);
    });

    test('does NOT fill when first devotional is already read', () async {
      final devs = [_dev('d0'), _dev('d1'), _dev('d2')];
      await sut.runAll(devs, ['d0', 'd1', 'd2']);

      expect(fakeStats.markedAsRead, isEmpty);
    });

    test('does NOT fill when second entry is also unread', () async {
      final devs = [_dev('d0'), _dev('d1'), _dev('d2')];
      await sut
          .runAll(devs, ['d2']); // d0 and d1 both unread — not a leading gap
      expect(fakeStats.markedAsRead, isEmpty);
    });
  });

  group('interior gap', () {
    test('fills gap when N-1 read, N unread, N+1 read', () async {
      final devs = [_dev('d0'), _dev('d1'), _dev('d2')];
      await sut.runAll(devs, ['d0', 'd2']);

      expect(fakeStats.markedAsRead, contains('d1'));
      expect(fakeStats.markedAsRead.length, 1);
    });
  });

  group('guards', () {
    test('no-ops on empty devocionales list', () async {
      await sut.runAll([], ['d0']);
      expect(fakeStats.markedAsRead, isEmpty);
    });

    test('no-ops on empty read IDs', () async {
      await sut.runAll([_dev('d0')], []);
      expect(fakeStats.markedAsRead, isEmpty);
    });

    test('no-ops on second call — already-ran flag set', () async {
      final devs = [_dev('d0'), _dev('d1'), _dev('d2')];
      await sut.runAll(devs, ['d1', 'd2']); // first call — fills d0
      await sut.runAll(devs, ['d1', 'd2']); // second call — no-op
      expect(fakeStats.markedAsRead, hasLength(1));
    });
  });
}
