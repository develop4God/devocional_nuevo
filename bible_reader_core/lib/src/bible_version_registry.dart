import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bible_version.dart';

class BibleVersionRegistry {
  static const Map<String, String> _languageNames = {
    'es': 'Español',
    'en': 'English',
    'pt': 'Português',
    'fr': 'Français',
    'ja': '日本語',
    'zh': '中文', // Add Chinese
    'hi': 'हिन्दी', // Add Hindi
    'de': 'Deutsch', // Add German
    'ar': 'العربية', // Add Arabic
    'fil': 'Filipino', // Add Filipino
  };

  /// Bundled versions. `hash` is the bible_versions index hash (first 16 hex
  /// chars of the SHA-256 of the `.gz` asset) of the file shipped in
  /// `assets/biblia/`, so the remote index can flag a newer copy as an
  /// update. Must change whenever the asset is replaced.
  static const Map<String, List<Map<String, String>>> _versionsByLanguage = {
    'es': [
      {
        'name': 'Reina Valera 1960 (RVR1960)',
        'dbFile': 'RVR1960_es.SQLite3',
        'hash': 'c290a43e65846a86'
      },
      {
        'name': 'Nueva Versión Internacional (NVI)',
        'dbFile': 'NVI_es.SQLite3',
        'hash': 'ea9c9aa3784c3b62'
      },
      {
        'name': 'Nueva Traducción Viviente (NTV)',
        'dbFile': 'NTV_es.SQLite3',
        'hash': 'b6075527be30852f'
      },
    ],
    'en': [
      {
        'name': 'King James Version (KJV)',
        'dbFile': 'KJV_en.SQLite3',
        'hash': '8d98dd247b02d357'
      },
      {
        'name': 'New International Version (NIV)',
        'dbFile': 'NIV_en.SQLite3',
        'hash': '456f21c7c06385aa'
      },
      {
        'name': 'English Standard Version (ESV)',
        'dbFile': 'ESV_en.SQLite3',
        'hash': '2716d368b9d3d176'
      },
    ],
    'pt': [
      {
        'name': 'Almeida Revista e Corrigida (ARC)',
        'dbFile': 'ARC_pt.SQLite3',
        'hash': 'd07c4c4bd082cb5d'
      },
      {
        'name': 'Nova Versão Internacional (NVI)',
        'dbFile': 'NVI_pt.SQLite3',
        'hash': '78a44c72ce5c9e14'
      },
    ],
    'fr': [
      {
        'name': 'Louis Segond 1910 (LSG1910)',
        'dbFile': 'LSG1910_fr.SQLite3',
        'hash': 'f85a978becbf7f2f'
      },
      // Use _fr suffix to identify French database asset
      {
        'name': 'Bible du Semeur (BDS)',
        'dbFile': 'BDS_fr.SQLite3',
        'hash': '034c92f3d06cef5b'
      },
    ],
    'ja': [
      {
        'name': '新改訳2003',
        'dbFile': 'SK2003_ja.SQLite3',
        'hash': '99671a5613bb01c5'
      },
      {
        'name': 'リビングバイブル',
        'dbFile': 'JCB_ja.SQLite3',
        'hash': '93f95219fde96363'
      },
    ],
    'zh': [
      {
        'name': '和合本1919',
        'dbFile': 'CUV1919_zh.SQLite3',
        'hash': '89c84548b6775c4e'
      },
      // Asset filename uses CNVS_zh.SQLite3.gz (note the extra 'S'), match the asset
      {'name': '新译本', 'dbFile': 'CNVS_zh.SQLite3', 'hash': '77f4e8e1b9e1e1f3'},
    ], // Add Chinese
    'hi': [
      {
        'name': 'पवित्र बाइबिल (ओ.वी.)',
        'dbFile': 'HIOV_hi.SQLite3',
        'hash': '83581d145d1ecd60'
      },
      {
        'name': 'पवित्र बाइबिल (HERV)',
        'dbFile': 'HERV_hi.SQLite3',
        'hash': 'f03056a265e7bfc2'
      },
    ], // Add Hindi
    'de': [
      {
        'name': 'Lutherbibel 2017 (LU17)',
        'dbFile': 'LU17_de.SQLite3',
        'hash': '62a813610300f95c'
      },
      {
        'name': 'Schlachter 2000 (SCH2000)',
        'dbFile': 'SCH2000_de.SQLite3',
        'hash': 'ef1ec5eeecadfba4'
      },
    ], // Add German
    'ar': [
      {
        'name': 'كتاب الحياة',
        'dbFile': 'NAV_ar.SQLite3',
        'hash': '7ee85cd36e41d655'
      },
      {
        'name': 'فان دايك',
        'dbFile': 'SVDA_ar.SQLite3',
        'hash': '9bb498f5c5ef0667'
      },
    ], // Added Arabic
    'fil': [
      {
        'name': 'Magandang Balita Biblia (MBB05)',
        'dbFile': 'MBB05_fil.SQLite3',
        'hash': '440b628b0df0cf16',
      },
      {
        'name': 'Ang Salita ng Dios (ASND)',
        'dbFile': 'ASND_fil.SQLite3',
        'hash': '3cfc2fc8facc5573'
      },
      {
        'name': 'Ang Dating Biblia (ADB)',
        'dbFile': 'ADB_fil.SQLite3',
        'hash': '7e257bb1ccdf5a38'
      },
    ], // Added Filipino (fil)
  };

  /// SharedPreferences key for the `{dbFileName: displayName}` map of
  /// downloaded remote versions. Written by the download flow, read here.
  static const String _remoteVersionNamesPrefKey = 'bible_remote_version_names';

  /// Get all Bible versions for a specific language — bundled assets plus
  /// any remote versions the user has already downloaded.
  static Future<List<BibleVersion>> getVersionsForLanguage(
    String languageCode,
  ) async {
    final versions = _versionsByLanguage[languageCode] ?? [];
    final List<BibleVersion> bibleVersions = [];
    final storedEntries = await _loadStoredEntries();

    for (final versionInfo in versions) {
      final dbFileName = versionInfo['dbFile']!;
      final isDownloaded = await _isVersionDownloaded(dbFileName);

      bibleVersions.add(
        BibleVersion(
          name: versionInfo['name']!,
          language: _languageNames[languageCode] ?? languageCode,
          languageCode: languageCode,
          assetPath: 'assets/biblia/$dbFileName',
          dbFileName: dbFileName,
          isDownloaded: isDownloaded,
          // A bundled version updated from the index keeps the hash of the
          // downloaded copy; otherwise it is the shipped asset.
          remoteHash:
              _storedHash(storedEntries[dbFileName]) ?? versionInfo['hash'],
        ),
      );
    }

    bibleVersions.addAll(
      await getDownloadedRemoteVersionsForLanguage(languageCode),
    );

    return bibleVersions;
  }

  /// Enumerates downloaded remote (non-bundled) Bible version database
  /// files for [languageCode] in the app documents directory, matching
  /// `*_$languageCode.SQLite3` and not already present in
  /// [_versionsByLanguage]. Display names come from the
  /// `bible_remote_version_names` SharedPreferences map, written at
  /// successful download time by the download flow.
  static Future<List<BibleVersion>> getDownloadedRemoteVersionsForLanguage(
    String languageCode,
  ) async {
    final bundledFileNames = (_versionsByLanguage[languageCode] ?? [])
        .map((v) => v['dbFile'])
        .toSet();

    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dir = Directory(documentsDirectory.path);
      if (!dir.existsSync()) return [];

      final prefs = await SharedPreferences.getInstance();
      final namesJson = prefs.getString(_remoteVersionNamesPrefKey);
      final Map<String, dynamic> names = namesJson != null
          ? jsonDecode(namesJson) as Map<String, dynamic>
          : {};
      debugPrint(
        '[BibleVersionRegistry] getDownloadedRemoteVersionsForLanguage('
        '$languageCode) namesJson=$namesJson',
      );

      final suffix = '_$languageCode.SQLite3';
      final List<BibleVersion> result = [];

      final allFiles = dir
          .listSync()
          .whereType<File>()
          .map((f) => basename(f.path))
          .toList();
      debugPrint(
        '[BibleVersionRegistry] documents dir files matching *$suffix: '
        '${allFiles.where((f) => f.endsWith(suffix)).toList()} '
        '(bundledFileNames=$bundledFileNames)',
      );

      for (final entity in dir.listSync()) {
        if (entity is! File) continue;
        final fileName = basename(entity.path);
        if (!fileName.endsWith(suffix)) continue;
        if (bundledFileNames.contains(fileName)) continue;

        // Entries may be a plain display-name string (legacy) or a
        // {"name": ..., "disclaimer": ..., "hash": ...} map (current
        // format).
        final stored = names[fileName];
        String displayName = fileName;
        String? disclaimer;
        String? hash;
        if (stored is String) {
          displayName = stored;
        } else if (stored is Map) {
          displayName = stored['name'] as String? ?? fileName;
          disclaimer = stored['disclaimer'] as String?;
          hash = stored['hash'] as String?;
        }

        result.add(
          BibleVersion(
            name: displayName,
            language: _languageNames[languageCode] ?? languageCode,
            languageCode: languageCode,
            assetPath: '',
            dbFileName: fileName,
            isDownloaded: true,
            disclaimer: disclaimer,
            remoteHash: hash,
          ),
        );
      }

      return result;
    } catch (e) {
      return [];
    }
  }

  /// Reads the `bible_remote_version_names` map; empty when absent or
  /// unreadable.
  static Future<Map<String, dynamic>> _loadStoredEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_remoteVersionNamesPrefKey);
      return json != null ? jsonDecode(json) as Map<String, dynamic> : {};
    } catch (e) {
      return {};
    }
  }

  static String? _storedHash(Object? stored) =>
      stored is Map ? stored['hash'] as String? : null;

  /// Get all available Bible versions across all languages
  static Future<List<BibleVersion>> getAllVersions() async {
    final List<BibleVersion> allVersions = [];

    for (final languageCode in _versionsByLanguage.keys) {
      final versions = await getVersionsForLanguage(languageCode);
      allVersions.addAll(versions);
    }

    return allVersions;
  }

  /// Check if a Bible version database is downloaded locally
  static Future<bool> _isVersionDownloaded(String dbFileName) async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbPath = join(documentsDirectory.path, dbFileName);
      return File(dbPath).existsSync();
    } catch (e) {
      // If we can't check, assume it needs to be downloaded from assets
      return false;
    }
  }

  /// Check if asset exists
  static Future<bool> assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get supported languages
  static List<String> getSupportedLanguages() {
    return _versionsByLanguage.keys.toList();
  }

  /// Get language name
  static String getLanguageName(String languageCode) {
    return _languageNames[languageCode] ?? languageCode;
  }
}
