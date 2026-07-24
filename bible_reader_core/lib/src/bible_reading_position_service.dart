import 'package:shared_preferences/shared_preferences.dart';
import 'bible_canon_filter.dart';

class BibleReadingPositionService {
  static const String _keyBook = 'bible_last_book';
  static const String _keyBookNumber = 'bible_last_book_number';
  static const String _keyChapter = 'bible_last_chapter';
  static const String _keyVerse = 'bible_last_verse';
  static const String _keyVersion = 'bible_last_version';
  static const String _keyLanguage = 'bible_last_language';

  /// Save the current reading position
  Future<void> savePosition({
    required String bookName,
    required int bookNumber,
    required int chapter,
    int verse = 1,
    required String version,
    required String languageCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBook, bookName);
    await prefs.setInt(_keyBookNumber, bookNumber);
    await prefs.setInt(_keyChapter, chapter);
    await prefs.setInt(_keyVerse, verse);
    await prefs.setString(_keyVersion, version);
    await prefs.setString(_keyLanguage, languageCode);
  }

  /// Get the last saved reading position
  Future<Map<String, dynamic>?> getLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final bookName = prefs.getString(_keyBook);
    final bookNumber = prefs.getInt(_keyBookNumber);
    final chapter = prefs.getInt(_keyChapter);
    final verse = prefs.getInt(_keyVerse);
    final version = prefs.getString(_keyVersion);
    final languageCode = prefs.getString(_keyLanguage);

    if (bookName == null ||
        bookNumber == null ||
        chapter == null ||
        version == null ||
        languageCode == null) {
      return null;
    }

    // The English bible DB was renamed KJV → KJ2000 (the SQLite content was
    // always King James 2000). Remap positions saved before the rename so
    // users keep their reading position.
    const legacyVersionFiles = {'KJV_en.SQLite3': 'KJ2000_en.SQLite3'};
    final resolvedVersion = legacyVersionFiles[version] ?? version;

    // If a previously saved position points to a deuterocanonical book
    // (possible for LU17/MBB05 users before the canon filter was added),
    // reset silently to Genesis ch.1 rather than crashing navigation.
    final safeBookNumber =
        BibleCanonFilter.isCanonical(bookNumber) ? bookNumber : 10;
    final safeBookName =
        BibleCanonFilter.isCanonical(bookNumber) ? bookName : 'Genesis';
    final safeChapter = BibleCanonFilter.isCanonical(bookNumber) ? chapter : 1;

    return {
      'bookName': safeBookName,
      'bookNumber': safeBookNumber,
      'chapter': safeChapter,
      'verse': verse ?? 1,
      'version': resolvedVersion,
      'languageCode': languageCode,
    };
  }

  /// Clear saved position
  Future<void> clearPosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBook);
    await prefs.remove(_keyBookNumber);
    await prefs.remove(_keyChapter);
    await prefs.remove(_keyVerse);
    await prefs.remove(_keyVersion);
    await prefs.remove(_keyLanguage);
  }
}
