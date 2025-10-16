import 'package:bible_reader_core/src/bible_db_service.dart';
import 'package:bible_reader_core/src/bible_reading_position_service.dart';
import 'package:bible_reader_core/src/bible_version.dart';

/// Service containing core business logic for Bible reading functionality
/// This service is framework-agnostic and can be easily tested without Flutter dependencies
class BibleReaderService {
  final BibleDbService dbService;
  final BibleReadingPositionService positionService;

  BibleReaderService({
    required this.dbService,
    required this.positionService,
  });

  /// Initialize a Bible version by setting up its database
  Future<void> initializeVersion(BibleVersion version) async {
    await dbService.initDb(
      version.assetPath,
      version.dbFileName,
    );
  }

  /// Load all books from the current Bible version
  Future<List<Map<String, dynamic>>> loadBooks() async {
    return await dbService.getAllBooks();
  }

  /// Get the maximum chapter number for a specific book
  Future<int> getMaxChapter(int bookNumber) async {
    return await dbService.getMaxChapter(bookNumber);
  }

  /// Load all verses for a specific chapter in a book
  Future<List<Map<String, dynamic>>> loadChapter(
    int bookNumber,
    int chapter,
  ) async {
    return await dbService.getChapterVerses(bookNumber, chapter);
  }

  /// Search for verses containing the given query
  Future<List<Map<String, dynamic>>> searchVerses(String query) async {
    if (query.trim().isEmpty) return [];
    return await dbService.searchVerses(query);
  }

  /// Find a book by its name or abbreviation
  Future<Map<String, dynamic>?> findBookByName(String name) async {
    if (name.trim().isEmpty) return null;
    return await dbService.findBookByName(name);
  }

  /// Save the current reading position
  Future<void> saveReadingPosition({
    required String bookName,
    required int bookNumber,
    required int chapter,
    int verse = 1,
    required String version,
    required String languageCode,
  }) async {
    await positionService.savePosition(
      bookName: bookName,
      bookNumber: bookNumber,
      chapter: chapter,
      verse: verse,
      version: version,
      languageCode: languageCode,
    );
  }

  /// Get the last saved reading position
  Future<Map<String, dynamic>?> getLastPosition() async {
    return await positionService.getLastPosition();
  }

  /// Clear the saved reading position
  Future<void> clearPosition() async {
    await positionService.clearPosition();
  }
}
