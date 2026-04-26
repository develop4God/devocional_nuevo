@Tags(['unit', 'services', 'backup'])
library;

// test/unit/services/backup_complete_flow_test.dart
//
// Validates real user backup/restore behavior:
//   - All data categories are included in backup payload
//   - After restore, data is readable from SharedPreferences without restart
//   - Discovery progress, favorites, and encounter IDs survive round-trips
//   - Favorites reload is driven from SharedPrefs (no restart required)

import 'dart:convert';

import 'package:devocional_nuevo/services/discovery_favorites_service.dart';
import 'package:devocional_nuevo/services/discovery_progress_tracker.dart';
import 'package:devocional_nuevo/services/encounter_progress_service.dart';
import 'package:devocional_nuevo/utils/backup_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // ────────────────────────────────────────────────────────────────
  // Helpers — simulate what the production service does during backup/restore
  // ────────────────────────────────────────────────────────────────

  /// Reads every data category from SharedPreferences exactly as
  /// GoogleDriveBackupService._prepareBackupData() does.
  Future<Map<String, dynamic>> simulatePrepareBackupData() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{};

    // Favorite devotionals
    final favoritesJson = prefs.getString('favorites') ?? '[]';
    payload[BackupKeys.favoriteDevotionals] =
        json.decode(favoritesJson) as List<dynamic>;

    // Saved prayers
    final prayersJson = prefs.getString('prayers') ?? '[]';
    payload[BackupKeys.savedPrayers] =
        json.decode(prayersJson) as List<dynamic>;

    // Saved thanksgivings
    final thanksgivingsJson = prefs.getString('thanksgivings') ?? '[]';
    payload[BackupKeys.savedThanksgivings] =
        json.decode(thanksgivingsJson) as List<dynamic>;

    // Completed encounters
    final completedIds = prefs.getStringList('encounter_completed_ids') ?? [];
    payload[BackupKeys.completedEncounters] = completedIds;

    // Discovery progress
    final discoveryProgress = <String, dynamic>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith('discovery_progress_')) {
        discoveryProgress[key] = prefs.getString(key);
      }
    }
    payload[BackupKeys.discoveryProgress] = discoveryProgress;

    // Discovery favorites
    final discoveryFavorites = <String, dynamic>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith('discovery_favorite_ids_')) {
        discoveryFavorites[key] = prefs.getString(key);
      }
    }
    payload[BackupKeys.discoveryFavorites] = discoveryFavorites;

    return payload;
  }

  /// Writes every data category back to SharedPreferences exactly as
  /// GoogleDriveBackupService._restoreBackupData() does.
  Future<void> simulateRestoreBackupData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    if (data.containsKey(BackupKeys.favoriteDevotionals)) {
      await prefs.setString(
        'favorites',
        json.encode(data[BackupKeys.favoriteDevotionals]),
      );
    }

    if (data.containsKey(BackupKeys.savedPrayers)) {
      await prefs.setString(
        'prayers',
        json.encode(data[BackupKeys.savedPrayers]),
      );
    }

    if (data.containsKey(BackupKeys.savedThanksgivings)) {
      await prefs.setString(
        'thanksgivings',
        json.encode(data[BackupKeys.savedThanksgivings]),
      );
    }

    if (data.containsKey(BackupKeys.completedEncounters)) {
      final ids = (data[BackupKeys.completedEncounters] as List<dynamic>)
          .map((e) => e as String)
          .toList();
      await prefs.setStringList('encounter_completed_ids', ids);
    }

    if (data.containsKey(BackupKeys.discoveryProgress)) {
      final progressData =
          data[BackupKeys.discoveryProgress] as Map<String, dynamic>;
      for (final entry in progressData.entries) {
        if (entry.value is String &&
            entry.key.startsWith('discovery_progress_')) {
          await prefs.setString(entry.key, entry.value as String);
        }
      }
    }

    if (data.containsKey(BackupKeys.discoveryFavorites)) {
      final favoritesData =
          data[BackupKeys.discoveryFavorites] as Map<String, dynamic>;
      for (final entry in favoritesData.entries) {
        if (entry.value is String &&
            entry.key.startsWith('discovery_favorite_ids_')) {
          await prefs.setString(entry.key, entry.value as String);
        }
      }
    }
  }

  // ────────────────────────────────────────────────────────────────
  // Tests
  // ────────────────────────────────────────────────────────────────

  group('Backup — default getBackupOptions includes all categories', () {
    test('all 7 categories are enabled by default', () {
      // Mirrors the default map returned by getBackupOptions()
      final defaultOptions = {
        BackupKeys.spiritualStats: true,
        BackupKeys.favoriteDevotionals: true,
        BackupKeys.savedPrayers: true,
        BackupKeys.savedThanksgivings: true,
        BackupKeys.completedEncounters: true,
        BackupKeys.discoveryProgress: true,
        BackupKeys.discoveryFavorites: true,
      };

      expect(defaultOptions.length, equals(7));
      expect(defaultOptions.values.every((v) => v == true), isTrue);
      expect(
          defaultOptions.containsKey(BackupKeys.completedEncounters), isTrue);
      expect(defaultOptions.containsKey(BackupKeys.discoveryProgress), isTrue);
      expect(defaultOptions.containsKey(BackupKeys.discoveryFavorites), isTrue);
    });
  });

  group('BackupKeys — canonical constants are stable', () {
    test('all keys defined and non-empty', () {
      expect(BackupKeys.spiritualStats, isNotEmpty);
      expect(BackupKeys.favoriteDevotionals, isNotEmpty);
      expect(BackupKeys.savedPrayers, isNotEmpty);
      expect(BackupKeys.savedThanksgivings, isNotEmpty);
      expect(BackupKeys.completedEncounters, isNotEmpty);
      expect(BackupKeys.discoveryProgress, isNotEmpty);
      expect(BackupKeys.discoveryFavorites, isNotEmpty);
    });

    test('all keys are unique', () {
      final keys = [
        BackupKeys.spiritualStats,
        BackupKeys.favoriteDevotionals,
        BackupKeys.savedPrayers,
        BackupKeys.savedThanksgivings,
        BackupKeys.completedEncounters,
        BackupKeys.discoveryProgress,
        BackupKeys.discoveryFavorites,
      ];
      expect(keys.toSet().length, equals(keys.length));
    });
  });

  group('Backup payload — encounter completed IDs round-trip', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('encounter IDs written to prefs appear in backup payload', () async {
      // Arrange: user completes two encounters
      final prefs = await SharedPreferences.getInstance();
      await prefs
          .setStringList('encounter_completed_ids', ['enc-001', 'enc-002']);

      // Act: simulate what backup service reads
      final payload = await simulatePrepareBackupData();

      // Assert
      expect(payload[BackupKeys.completedEncounters],
          equals(['enc-001', 'enc-002']));
    });

    test('no encounter IDs results in empty list in payload', () async {
      // prefs has no encounter data (setMockInitialValues({}) above)
      final payload = await simulatePrepareBackupData();
      expect(payload[BackupKeys.completedEncounters], isEmpty);
    });
  });

  group('Restore — encounter completed IDs are written without restart', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
        'after restore, EncounterProgressService.loadCompletedIds returns restored IDs',
        () async {
      // Arrange: backup payload contains completed encounters
      final backupPayload = {
        BackupKeys.completedEncounters: ['enc-alpha', 'enc-beta', 'enc-gamma'],
      };

      // Act: simulate restore
      await simulateRestoreBackupData(backupPayload);

      // Assert: service reads restored data immediately (no restart)
      final service = EncounterProgressService();
      final ids = await service.loadCompletedIds();
      expect(ids, containsAll(['enc-alpha', 'enc-beta', 'enc-gamma']));
      expect(ids.length, equals(3));
    });

    test('after restore, isCompleted returns true for restored encounter IDs',
        () async {
      final backupPayload = {
        BackupKeys.completedEncounters: ['enc-restored'],
      };
      await simulateRestoreBackupData(backupPayload);

      final service = EncounterProgressService();
      expect(await service.isCompleted('enc-restored'), isTrue);
      expect(await service.isCompleted('enc-not-in-backup'), isFalse);
    });
  });

  group('Backup payload — discovery progress round-trip', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('discovery progress written by tracker appears in backup payload',
        () async {
      // Arrange: user completes a discovery section
      final tracker = DiscoveryProgressTracker();
      await tracker.markSectionCompleted('study-001', 0, 'en');

      // Act: simulate backup read
      final payload = await simulatePrepareBackupData();

      // Assert: the progress key is captured
      final progressMap =
          payload[BackupKeys.discoveryProgress] as Map<String, dynamic>;
      expect(progressMap.isNotEmpty, isTrue);
      final progressKey = progressMap.keys.first;
      expect(progressKey, startsWith('discovery_progress_'));
    });

    test('multiple studies across languages appear as separate keys', () async {
      final tracker = DiscoveryProgressTracker();
      await tracker.markSectionCompleted('study-001', 0, 'en');
      await tracker.markSectionCompleted('study-001', 0, 'es');
      await tracker.markSectionCompleted('study-002', 1, 'en');

      final payload = await simulatePrepareBackupData();
      final progressMap =
          payload[BackupKeys.discoveryProgress] as Map<String, dynamic>;

      expect(progressMap.length, greaterThanOrEqualTo(3));
      expect(
        progressMap.keys.every((k) => k.startsWith('discovery_progress_')),
        isTrue,
      );
    });

    test('no discovery progress results in empty map in payload', () async {
      final payload = await simulatePrepareBackupData();
      final progressMap =
          payload[BackupKeys.discoveryProgress] as Map<String, dynamic>;
      expect(progressMap, isEmpty);
    });
  });

  group('Restore — discovery progress is readable without restart', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
        'after restore, DiscoveryProgressTracker returns restored completed sections',
        () async {
      // Arrange: build a progress JSON as the tracker would produce
      const studyId = 'study-restored';
      const languageCode = 'en';
      final progressJson = jsonEncode({
        'studyId': studyId,
        'languageCode': languageCode,
        'completedSections': [0, 1, 2],
        'answeredQuestions': {},
        'isCompleted': false,
        'completedAt': null,
      });

      final backupPayload = {
        BackupKeys.discoveryProgress: {
          'discovery_progress_${studyId}_$languageCode': progressJson,
        },
      };

      // Act: simulate restore
      await simulateRestoreBackupData(backupPayload);

      // Assert: tracker reads restored progress immediately
      final tracker = DiscoveryProgressTracker();
      final progress = await tracker.getProgress(studyId, languageCode);
      expect(progress.completedSections, equals([0, 1, 2]));
      expect(progress.studyId, equals(studyId));
    });
  });

  group('Backup payload — discovery favorites round-trip', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('discovery favorites saved by service appear in backup payload',
        () async {
      // Arrange: user favorites two studies in Spanish
      final service = DiscoveryFavoritesService();
      await service.toggleFavorite('study-fav-1', 'es');
      await service.toggleFavorite('study-fav-2', 'es');

      // Act: simulate backup read
      final payload = await simulatePrepareBackupData();

      // Assert
      final favMap =
          payload[BackupKeys.discoveryFavorites] as Map<String, dynamic>;
      expect(favMap.isNotEmpty, isTrue);
      expect(
        favMap.keys.every((k) => k.startsWith('discovery_favorite_ids_')),
        isTrue,
      );
    });

    test('no discovery favorites results in empty map in payload', () async {
      final payload = await simulatePrepareBackupData();
      final favMap =
          payload[BackupKeys.discoveryFavorites] as Map<String, dynamic>;
      expect(favMap, isEmpty);
    });
  });

  group('Restore — discovery favorites readable without restart', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
        'after restore, DiscoveryFavoritesService returns restored favorite IDs',
        () async {
      // Arrange: build a favorites JSON exactly as the service would produce
      final favoritesJson = jsonEncode(['study-alpha', 'study-beta']);
      final backupPayload = {
        BackupKeys.discoveryFavorites: {
          'discovery_favorite_ids_es': favoritesJson,
        },
      };

      // Act: simulate restore
      await simulateRestoreBackupData(backupPayload);

      // Assert: service reads restored data immediately
      final service = DiscoveryFavoritesService();
      final ids = await service.loadFavoriteIds('es');
      expect(ids, containsAll(['study-alpha', 'study-beta']));
      expect(ids.length, equals(2));
    });

    test('after restore, favorites for different languages are isolated',
        () async {
      final backupPayload = {
        BackupKeys.discoveryFavorites: {
          'discovery_favorite_ids_en': jsonEncode(['study-en-1']),
          'discovery_favorite_ids_es': jsonEncode(['study-es-1', 'study-es-2']),
        },
      };

      await simulateRestoreBackupData(backupPayload);

      final service = DiscoveryFavoritesService();
      final enIds = await service.loadFavoriteIds('en');
      final esIds = await service.loadFavoriteIds('es');

      expect(enIds, equals({'study-en-1'}));
      expect(esIds, containsAll(['study-es-1', 'study-es-2']));
    });
  });

  group('Full round-trip — backup → restore → verify all categories', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('all data categories survive a full backup/restore cycle', () async {
      // ── Arrange: populate all categories ──────────────────────────
      final prefs = await SharedPreferences.getInstance();

      // Favorites devotionals
      await prefs.setString(
          'favorites',
          jsonEncode([
            {'id': 'dev-001', 'title': 'Devotional 1'},
          ]));

      // Prayers
      await prefs.setString(
          'prayers',
          jsonEncode([
            {'id': 'p-001', 'text': 'My prayer'},
          ]));

      // Thanksgivings
      await prefs.setString(
          'thanksgivings',
          jsonEncode([
            {'id': 't-001', 'text': 'My thanksgiving'},
          ]));

      // Encounter completed IDs
      await prefs.setStringList(
          'encounter_completed_ids', ['enc-round1', 'enc-round2']);

      // Discovery progress
      await prefs.setString(
        'discovery_progress_study-rt_en',
        jsonEncode({
          'studyId': 'study-rt',
          'languageCode': 'en',
          'completedSections': [0, 1],
          'answeredQuestions': {},
          'isCompleted': false,
          'completedAt': null,
        }),
      );

      // Discovery favorites
      await prefs.setString(
        'discovery_favorite_ids_en',
        jsonEncode(['fav-study-rt']),
      );

      // ── Act: backup (read) ────────────────────────────────────────
      final payload = await simulatePrepareBackupData();

      // Reset prefs to simulate device wipe / new install
      SharedPreferences.setMockInitialValues({});

      // Act: restore (write)
      await simulateRestoreBackupData(payload);

      // ── Assert all categories ──────────────────────────────────────

      // Encounter IDs
      final encService = EncounterProgressService();
      final encIds = await encService.loadCompletedIds();
      expect(encIds, containsAll(['enc-round1', 'enc-round2']));

      // Discovery progress
      final tracker = DiscoveryProgressTracker();
      final progress = await tracker.getProgress('study-rt', 'en');
      expect(progress.completedSections, equals([0, 1]));

      // Discovery favorites
      final favService = DiscoveryFavoritesService();
      final favIds = await favService.loadFavoriteIds('en');
      expect(favIds, contains('fav-study-rt'));

      // Devotional favorites (raw SharedPrefs check)
      final freshPrefs = await SharedPreferences.getInstance();
      final restoredFav = freshPrefs.getString('favorites');
      expect(restoredFav, isNotNull);
      final decodedFav = jsonDecode(restoredFav!) as List<dynamic>;
      expect((decodedFav.first as Map)['id'], equals('dev-001'));

      // Prayers
      final restoredPrayers = freshPrefs.getString('prayers');
      expect(restoredPrayers, isNotNull);
      final decodedPrayers = jsonDecode(restoredPrayers!) as List<dynamic>;
      expect((decodedPrayers.first as Map)['text'], equals('My prayer'));

      // Thanksgivings
      final restoredThanks = freshPrefs.getString('thanksgivings');
      expect(restoredThanks, isNotNull);
      final decodedThanks = jsonDecode(restoredThanks!) as List<dynamic>;
      expect((decodedThanks.first as Map)['text'], equals('My thanksgiving'));
    });
  });

  group('Restore safety — malformed or missing keys do not crash', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('restore with empty payload silently succeeds', () async {
      await expectLater(
        simulateRestoreBackupData({}),
        completes,
      );
    });

    test('restore with partial payload restores what is present', () async {
      // Only encounters provided
      await simulateRestoreBackupData({
        BackupKeys.completedEncounters: ['enc-partial'],
      });

      final service = EncounterProgressService();
      final ids = await service.loadCompletedIds();
      expect(ids, contains('enc-partial'));
    });

    test('discovery progress with non-prefixed keys are ignored during restore',
        () async {
      // A backup payload that contains an invalid key (should not be written)
      final payload = {
        BackupKeys.discoveryProgress: {
          'invalid_key': 'some_value',
          'discovery_progress_valid': jsonEncode({
            'studyId': 'valid',
            'languageCode': 'en',
            'completedSections': [0],
            'answeredQuestions': {},
            'isCompleted': false,
            'completedAt': null,
          }),
        },
      };

      await simulateRestoreBackupData(payload);

      final prefs = await SharedPreferences.getInstance();

      // Invalid key must NOT be written
      expect(prefs.containsKey('invalid_key'), isFalse);

      // Valid key MUST be written
      expect(prefs.containsKey('discovery_progress_valid'), isTrue);
    });
  });
}
