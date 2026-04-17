import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

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
    'tl': 'Tagalog', // Add Tagalog
  };

  static const Map<String, List<Map<String, String>>> _versionsByLanguage = {
    'es': [
      {'name': 'Reina Valera 1960 (RVR1960)', 'dbFile': 'RVR1960_es.SQLite3'},
      {'name': 'Nueva Versión Internacional (NVI)', 'dbFile': 'NVI_es.SQLite3'},
    ],
    'en': [
      {'name': 'King James Version (KJV)', 'dbFile': 'KJV_en.SQLite3'},
      {'name': 'New International Version (NIV)', 'dbFile': 'NIV_en.SQLite3'},
    ],
    'pt': [
      {'name': 'Almeida Revista e Corrigida (ARC)', 'dbFile': 'ARC_pt.SQLite3'},
      {'name': 'Nova Versão Internacional (NVI)', 'dbFile': 'NVI_pt.SQLite3'},
    ],
    'fr': [
      {'name': 'Louis Segond 1910 (LSG1910)', 'dbFile': 'LSG1910_fr.SQLite3'},
      // Use _fr suffix to identify French database asset
      {'name': 'Bible du Semeur (BDS)', 'dbFile': 'BDS_fr.SQLite3'},
    ],
    'ja': [
      {'name': '新改訳2003', 'dbFile': 'SK2003_ja.SQLite3'},
      {'name': 'リビングバイブル', 'dbFile': 'JCB_ja.SQLite3'},
    ],
    'zh': [
      {'name': '和合本1919', 'dbFile': 'CUV1919_zh.SQLite3'},
      // Asset filename uses CNVS_zh.SQLite3.gz (note the extra 'S'), match the asset
      {'name': '新译本', 'dbFile': 'CNVS_zh.SQLite3'},
    ], // Add Chinese
    'hi': [
      {'name': 'पवित्र बाइबिल (ओ.वी.)', 'dbFile': 'HIOV_hi.SQLite3'},
      {'name': 'पवित्र बाइबिल (HERV)', 'dbFile': 'HERV_hi.SQLite3'},
    ], // Add Hindi
    'de': [
      {'name': 'Lutherbibel 2017 (LU17)', 'dbFile': 'LU17_de.SQLite3'},
      {'name': 'Schlachter 2000 (SCH2000)', 'dbFile': 'SCH2000_de.SQLite3'},
    ], // Add German
    'ar': [
      {'name': 'كتاب الحياة', 'dbFile': 'NAV_ar.SQLite3'},
      {
        'name': 'فان دايك',
        'dbFile': 'SVDA_ar.SQLite3',
      },
    ], // Added Arabic
    'tl': [
      {'name': 'Ang Dating Biblia (ADB)', 'dbFile': 'ADB_tl.SQLite3'},
      {
        'name': 'Ang Salita ng Dios (ASND)',
        'dbFile': 'ASND_tl.SQLite3',
      },
    ], // Added Tagalog
  };

  /// Get all Bible versions for a specific language
  static Future<List<BibleVersion>> getVersionsForLanguage(
    String languageCode,
  ) async {
    final versions = _versionsByLanguage[languageCode] ?? [];
    final List<BibleVersion> bibleVersions = [];

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
        ),
      );
    }

    return bibleVersions;
  }

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
