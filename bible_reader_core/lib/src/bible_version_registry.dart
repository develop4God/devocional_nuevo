import 'dart:io';

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
  };

  /// Version info by language.
  /// The filename matches the GitHub repo structure: {VERSION}_{LANG}.SQLite3
  static const Map<String, List<Map<String, String>>> _versionsByLanguage = {
    'es': [
      {'name': 'RVR1960', 'filename': 'RVR1960_es.SQLite3'},
      {'name': 'NVI', 'filename': 'NVI_es.SQLite3'},
    ],
    'en': [
      {'name': 'KJV', 'filename': 'KJV_en.SQLite3'},
      {'name': 'NIV', 'filename': 'NIV_en.SQLite3'},
    ],
    'pt': [
      {'name': 'ARC', 'filename': 'ARC_pt.SQLite3'},
      {'name': 'NVI', 'filename': 'NVI_pt.SQLite3'},
    ],
    'fr': [
      {'name': 'LSG1910', 'filename': 'LSG1910_fr.SQLite3'},
    ],
    'ja': [
      {'name': 'SK2003', 'filename': 'SK2003_ja.SQLite3'},
      {'name': 'JCB', 'filename': 'JCB_ja.SQLite3'},
    ],
  };

  /// Get all Bible versions for a specific language
  static Future<List<BibleVersion>> getVersionsForLanguage(
    String languageCode,
  ) async {
    final versions = _versionsByLanguage[languageCode] ?? [];
    final List<BibleVersion> bibleVersions = [];

    for (final versionInfo in versions) {
      final filename = versionInfo['filename']!;
      // Path is: bibles/{filename} (e.g., bibles/KJV_en.SQLite3)
      final dbFileName = 'bibles/$filename';
      final isDownloaded = await _isVersionDownloaded(dbFileName);

      bibleVersions.add(
        BibleVersion(
          name: versionInfo['name']!,
          language: _languageNames[languageCode] ?? languageCode,
          languageCode: languageCode,
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

  /// Get supported languages
  static List<String> getSupportedLanguages() {
    return _versionsByLanguage.keys.toList();
  }

  /// Get language name
  static String getLanguageName(String languageCode) {
    return _languageNames[languageCode] ?? languageCode;
  }
}
