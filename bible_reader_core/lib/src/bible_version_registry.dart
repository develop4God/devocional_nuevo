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
  };

  static const Map<String, List<Map<String, String>>> _versionsByLanguage = {
    'es': [
      {'name': 'RVR1960', 'dbFile': 'RVR1960_es.SQLite3'},
      {'name': 'NVI', 'dbFile': 'NVI_es.SQLite3'},
    ],
    'en': [
      {'name': 'KJV', 'dbFile': 'KJV_en.SQLite3'},
      {'name': 'NIV', 'dbFile': 'NIV_en.SQLite3'},
    ],
    'pt': [
      {'name': 'ARC', 'dbFile': 'ARC_pt.SQLite3'},
      {'name': 'NVI', 'dbFile': 'NVI_pt.SQLite3'},
    ],
    'fr': [
      {'name': 'LSG1910', 'dbFile': 'LSG1910_fr.SQLite3'},
    ],
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
