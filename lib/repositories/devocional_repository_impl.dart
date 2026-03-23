// lib/repositories/devocional_repository_impl.dart

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:devocional_nuevo/constants/devocional_years.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/cache_metadata_service.dart';
import 'package:devocional_nuevo/services/devocional_index_service.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'devocional_repository.dart';

/// Concrete implementation of [DevocionalRepository].
///
/// Extracts all data access logic from DevocionalProvider following the
/// EncounterRepository pattern.
class DevocionalRepositoryImpl implements DevocionalRepository {
  final http.Client _httpClient;
  final DevocionalIndexService _devocionalIndexService;
  final CacheMetadataService _cacheMetadataService;

  Map<String, dynamic>? _cachedIndex;
  bool _indexUnreachable = false;
  bool _indexFetched = false;

  DevocionalRepositoryImpl({
    required http.Client httpClient,
    DevocionalIndexService? devocionalIndexService,
    CacheMetadataService? cacheMetadataService,
  })  : _httpClient = httpClient,
        _devocionalIndexService =
            devocionalIndexService ?? DevocionalIndexService(httpClient),
        _cacheMetadataService = cacheMetadataService ?? CacheMetadataService();

  // ── EXISTING METHOD ────────────────────────────────────────────────────────

  @override
  int findFirstUnreadDevocionalIndex(
    List<Devocional> devocionales,
    List<String> readDevocionalIds,
  ) {
    if (devocionales.isEmpty) return 0;

    // Convert to Set for O(1) lookup instead of O(n) - 365× faster with 730 devotionals
    final unreadSet = readDevocionalIds.toSet();

    for (int i = 0; i < devocionales.length; i++) {
      if (!unreadSet.contains(devocionales[i].id)) {
        return i;
      }
    }

    // If all devotionals are read, start from the beginning
    return 0;
  }

  // ── INDEX CACHE ────────────────────────────────────────────────────────────

  @override
  bool get wasLastFetchOffline => _indexUnreachable;

  void resetIndexCache() {
    _cachedIndex = null;
    _indexUnreachable = false;
    _indexFetched = false;
    debugPrint('🔄 [DevocionalRepository] Index cache reset');
  }

  Future<void> _ensureIndexFetched() async {
    if (_indexFetched) return;
    _cachedIndex = await _devocionalIndexService.fetchIndex();
    _indexUnreachable = (_cachedIndex == null);
    _indexFetched = true;
  }

  // ── DATA LOADING ────────────────────────────────────────────────────────────

  @override
  Future<List<Devocional>> fetchAll(
    int year,
    String language,
    String version,
  ) async {
    await _ensureIndexFetched();

    final String filePath = await _getLocalFilePath(year, language, version);

    final String? indexDate = _indexUnreachable
        ? null
        : _devocionalIndexService.getFileDate(
            _cachedIndex!,
            language,
            version,
            year.toString(),
          );

    final String? sidecarDate =
        await _cacheMetadataService.readManifestDate(filePath);

    final bool isStale = (indexDate != null) &&
        (sidecarDate == null || sidecarDate != indexDate);

    if (isStale) {
      developer.log(
        '🔄 [CACHE] Stale detected: ${year}_${language}_$version'
        ' — index: $indexDate, sidecar: $sidecarDate',
        name: 'DevocionalCache',
      );
    }

    final bool hasLocal = await File(filePath).exists();

    if (!isStale && hasLocal) {
      developer.log(
        '✅ [CACHE] Fresh: ${year}_${language}_$version — using local cache',
        name: 'DevocionalCache',
      );
      final Map<String, dynamic>? localData =
          await _loadFromLocalStorage(year, language, version);
      if (localData != null) {
        return _extractDevocionalesFromData(localData, language);
      }
    } else {
      try {
        debugPrint(
          'Loading from API for year $year, language: $language, version: $version',
        );
        final String url = Constants.getDevocionalesApiUrlMultilingual(
          year,
          language,
          version,
        );
        debugPrint('🔍 Requesting URL: $url');
        final response = await _httpClient.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final String responseBody = utf8.decode(response.bodyBytes);
          final Map<String, dynamic> data = json.decode(responseBody);
          final List<Devocional> yearDevocionales =
              _extractDevocionalesFromData(data, language);
          if (yearDevocionales.isNotEmpty) {
            await _saveToLocalStorage(year, language, responseBody, version);
          }
          return yearDevocionales;
        } else {
          debugPrint(
            '⚠️ Failed to load year $year from API: ${response.statusCode}',
          );
          if (hasLocal) {
            final Map<String, dynamic>? localData =
                await _loadFromLocalStorage(year, language, version);
            if (localData != null) {
              return _extractDevocionalesFromData(localData, language);
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error loading year $year: $e');
        if (hasLocal) {
          final Map<String, dynamic>? localData =
              await _loadFromLocalStorage(year, language, version);
          if (localData != null) {
            return _extractDevocionalesFromData(localData, language);
          }
        }
      }
    }

    return [];
  }

  @override
  List<Devocional> filterByVersion(
    List<Devocional> devocionales,
    String version,
  ) {
    if (version.isEmpty) return List.from(devocionales);
    return devocionales.where((d) => d.version == version).toList();
  }

  // ── JSON PARSING ──────────────────────────────────────────────────────────

  List<Devocional> _extractDevocionalesFromData(
    Map<String, dynamic> data,
    String language,
  ) {
    final Map<String, dynamic>? languageRoot =
        data['data'] as Map<String, dynamic>?;
    final Map<String, dynamic>? languageData =
        languageRoot?[language] as Map<String, dynamic>?;

    if (languageData == null) {
      debugPrint('No data found for language $language');
      return [];
    }

    return _parseLanguageData(languageData);
  }

  List<Devocional> _parseLanguageData(Map<String, dynamic> languageData) {
    final List<Devocional> loaded = [];

    languageData.forEach((dateKey, dateValue) {
      if (dateValue is List) {
        for (var devocionalJson in dateValue) {
          try {
            loaded.add(
              Devocional.fromJson(devocionalJson as Map<String, dynamic>),
            );
          } catch (e) {
            debugPrint('Error parsing devotional for $dateKey: $e');
          }
        }
      }
    });

    return loaded;
  }

  // ── LOCAL STORAGE ──────────────────────────────────────────────────────────

  Future<Directory> _getLocalStorageDirectory() async {
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    final Directory devocionalesDir = Directory(
      '${appDocumentsDir.path}/devocionales',
    );
    if (!await devocionalesDir.exists()) {
      await devocionalesDir.create(recursive: true);
    }
    return devocionalesDir;
  }

  Future<String> _getLocalFilePath(
    int year,
    String language, [
    String? version,
  ]) async {
    final Directory storageDir = await _getLocalStorageDirectory();
    // Include version in filename for new languages; maintain backward
    // compatibility for Spanish RVR1960 (original format).
    if (language == 'es' && version == 'RVR1960') {
      return '${storageDir.path}/devocional_${year}_$language.json';
    } else {
      final versionSuffix = version != null ? '_$version' : '';
      return '${storageDir.path}/devocional_${year}_$language$versionSuffix.json';
    }
  }

  @override
  Future<bool> hasLocalData(int year, String language, String version) async {
    try {
      final String filePath = await _getLocalFilePath(year, language, version);
      return await File(filePath).exists();
    } catch (e) {
      debugPrint('Error checking local file: $e');
      return false;
    }
  }

  Future<void> _saveToLocalStorage(
    int year,
    String language,
    String content, [
    String? version,
  ]) async {
    try {
      final String filePath = await _getLocalFilePath(year, language, version);
      final File file = File(filePath);
      await file.writeAsString(content);
      debugPrint('✅ Data saved to local storage: $filePath');

      // Always write sidecar atomically after JSON save.
      // Use per-file date from cached index if available, today as fallback.
      final String manifestDate = _devocionalIndexService.getFileDate(
            _cachedIndex ?? {},
            language,
            version ?? '',
            year.toString(),
          ) ??
          DateTime.now().toIso8601String().split('T').first;

      await _cacheMetadataService.writeMetadata(filePath, manifestDate);
    } catch (e) {
      debugPrint('❌ Error saving to local storage: $e');
    }
  }

  Future<Map<String, dynamic>?> _loadFromLocalStorage(
    int year,
    String language, [
    String? version,
  ]) async {
    try {
      final String filePath = await _getLocalFilePath(year, language, version);
      final File file = File(filePath);

      if (!await file.exists()) return null;

      final String content = await file.readAsString();
      final firstDevanagari = content.codeUnits
          .where((c) => c >= 0x0900 && c <= 0x097F)
          .take(3)
          .toList();
      debugPrint('[ENCODING_CHECK] codeUnits: $firstDevanagari');
      return json.decode(content) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error loading from local storage: $e');
      return null;
    }
  }

  @override
  Future<bool> downloadAndStoreDevocionales(
    int year,
    String language,
    String version,
  ) async {
    try {
      final String url = Constants.getDevocionalesApiUrlMultilingual(
        year,
        language,
        version,
      );
      debugPrint('🔍 Requesting URL: $url');
      debugPrint('🔍 Language: $language, Version: $version');
      final response = await _httpClient.get(Uri.parse(url));

      if (response.statusCode == 404) {
        debugPrint(
          '❌ File not found (404): $language $version year $year',
        );
        throw Exception(
          'File not available for $language $version year $year',
        );
      } else if (response.statusCode != 200) {
        debugPrint(
          '❌ HTTP Error ${response.statusCode}: ${response.reasonPhrase}',
        );
        throw Exception(
          'HTTP Error ${response.statusCode}: ${response.reasonPhrase}',
        );
      }

      final Map<String, dynamic> jsonData =
          json.decode(utf8.decode(response.bodyBytes));

      if (jsonData['data'] == null) {
        throw Exception('Invalid JSON structure: missing "data" field');
      }

      await _saveToLocalStorage(
        year,
        language,
        utf8.decode(response.bodyBytes),
        version,
      );

      return true;
    } catch (e) {
      debugPrint('❌ Error in downloadAndStoreDevocionales: $e');
      return false;
    }
  }

  @override
  Future<void> clearOldFiles() async {
    final Directory storageDir = await _getLocalStorageDirectory();
    final List<FileSystemEntity> files = await storageDir.list().toList();
    for (final FileSystemEntity file in files) {
      if (file is File) {
        await file.delete();
        debugPrint('File deleted: ${file.path}');
      }
    }
  }

  // ── DOWNLOAD ORCHESTRATION ─────────────────────────────────────────────────

  @override
  Future<bool> downloadCurrentYearDevocionales(
    String language,
    String version,
  ) async {
    final List<int> yearsToDownload = await getAvailableYears();
    bool allSuccess = true;

    for (final year in yearsToDownload) {
      bool success =
          await downloadAndStoreDevocionales(year, language, version);

      if (!success) {
        final fallbackVersion =
            await _tryVersionFallback(year, language, version);
        success = fallbackVersion != null;
      }

      if (!success) {
        allSuccess = false;
        debugPrint('⚠️ Failed to download devotionals for year $year');
      }
    }

    return allSuccess;
  }

  @override
  Future<bool> hasCurrentYearLocalData(String language, String version) async {
    final int currentYear = DateTime.now().year;
    return hasLocalData(currentYear, language, version);
  }

  @override
  Future<bool> hasTargetYearsLocalData(String language, String version) async {
    final List<int> years = await getAvailableYears();
    for (final year in years) {
      if (!await hasLocalData(year, language, version)) return false;
    }
    return years.isNotEmpty;
  }

  // ── AVAILABLE YEARS ───────────────────────────────────────────────────────

  @override
  Future<List<int>> getAvailableYears() async {
    await _ensureIndexFetched();

    if (!_indexUnreachable && _cachedIndex != null) {
      final years = _devocionalIndexService.extractAvailableYears(_cachedIndex);
      if (years.isNotEmpty) return years;
      developer.log(
        '⚠️ [DevocionalRepository] Index has no years — using fallback',
        name: 'DevocionalCache',
      );
    } else {
      developer.log(
        '⚠️ [DevocionalRepository] Offline — using fallback years: ${DevocionalYears.availableYears}',
        name: 'DevocionalCache',
      );
    }

    return DevocionalYears.availableYears;
  }

  // ── VERSION FALLBACK ──────────────────────────────────────────────────────

  /// Tries alternate versions for [language] when [currentVersion] fails.
  ///
  /// Returns the successful fallback version string, or null if all fail.
  /// No side effects on provider state.
  Future<String?> _tryVersionFallback(
    int year,
    String language,
    String currentVersion,
  ) async {
    debugPrint(
      '🔄 Trying version fallback for $language $currentVersion',
    );

    final availableVersions = Constants.bibleVersionsByLanguage[language] ?? [];
    debugPrint(
      '🔄 Available versions for $language: $availableVersions',
    );

    final defaultVersion = Constants.defaultVersionByLanguage[language];
    final versionsToTry = <String>[];

    if (defaultVersion != null && defaultVersion != currentVersion) {
      versionsToTry.add(defaultVersion);
    }

    for (final version in availableVersions) {
      if (version != currentVersion && version != defaultVersion) {
        versionsToTry.add(version);
      }
    }

    debugPrint('🔄 Versions to try in order: $versionsToTry');

    for (final version in versionsToTry) {
      debugPrint('🔄 Trying fallback version: $version');
      final success =
          await downloadAndStoreDevocionales(year, language, version);
      if (success) {
        debugPrint('✅ Fallback successful with version: $version');
        return version;
      }
    }

    debugPrint('❌ All version fallbacks failed for $language');
    return null;
  }
}
