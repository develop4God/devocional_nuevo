import 'package:shared_preferences/shared_preferences.dart';

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

    return {
      'bookName': bookName,
      'bookNumber': bookNumber,
      'chapter': chapter,
      'verse': verse ?? 1,
      'version': version,
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
