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
  /// NOTE: dbFile now matches the download path format: bibles/{language}-{versionName}/bible.db
  static const Map<String, List<Map<String, String>>> _versionsByLanguage = {
    'es': [
      {'name': 'RVR1960', 'id': 'es-RVR1960'},
      {'name': 'NVI', 'id': 'es-NVI'},
    ],
    'en': [
      {'name': 'KJV', 'id': 'en-KJV'},
      {'name': 'NIV', 'id': 'en-NIV'},
    ],
    'pt': [
      {'name': 'ARC', 'id': 'pt-ARC'},
      {'name': 'NVI', 'id': 'pt-NVI'},
    ],
    'fr': [
      {'name': 'LSG1910', 'id': 'fr-LSG1910'},
    ],
    'ja': [
      {'name': 'SK2003', 'id': 'ja-SK2003'},
      {'name': 'JCB', 'id': 'ja-JCB'},
    ],
  };

  /// Get all Bible versions for a specific language
  static Future<List<BibleVersion>> getVersionsForLanguage(
    String languageCode,
  ) async {
    final versions = _versionsByLanguage[languageCode] ?? [];
    final List<BibleVersion> bibleVersions = [];

    for (final versionInfo in versions) {
      final versionId = versionInfo['id']!;
      // Path matches the download path: bibles/{versionId}/bible.db
      final dbFileName = 'bibles/$versionId/bible.db';
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
