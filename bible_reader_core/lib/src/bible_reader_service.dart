import 'package:bible_reader_core/src/bible_db_service.dart';
import 'package:bible_reader_core/src/bible_reading_position_service.dart';
import 'package:bible_reader_core/src/bible_reference_parser.dart';
import 'package:logger/logger.dart';

/// Service containing core business logic for Bible reading functionality
/// This service is framework-agnostic and can be easily tested without Flutter dependencies
class BibleReaderService {
  BibleDbService dbService;
  final BibleReadingPositionService positionService;
  final Logger _logger = Logger();

  BibleReaderService({required this.dbService, required this.positionService});

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

  /// Navigate to next chapter, moving to next book if at end
  /// Returns {bookNumber, chapter, scrollToTop: true, bookName: ...} or null if at Bible end
  Future<Map<String, dynamic>?> navigateToNextChapter({
    required int currentBookNumber,
    required int currentChapter,
    required List<Map<String, dynamic>> books,
  }) async {
    final maxChapter = await dbService.getMaxChapter(currentBookNumber);

    if (currentChapter < maxChapter) {
      return {
        'bookNumber': currentBookNumber,
        'chapter': currentChapter + 1,
        'scrollToTop': true,
      };
    }

    // Move to next book
    final currentIndex = books.indexWhere(
      (b) => b['book_number'] == currentBookNumber,
    );
    if (currentIndex >= 0 && currentIndex < books.length - 1) {
      final nextBook = books[currentIndex + 1];
      return {
        'bookNumber': nextBook['book_number'],
        'bookName': nextBook['short_name'],
        'chapter': 1,
        'scrollToTop': true,
      };
    }

    return null; // At end of Bible
  }

  /// Navigate to previous chapter, moving to previous book if at start
  /// Returns {bookNumber, chapter, scrollToTop: true, bookName: ...} or null if at Bible start
  Future<Map<String, dynamic>?> navigateToPreviousChapter({
    required int currentBookNumber,
    required int currentChapter,
    required List<Map<String, dynamic>> books,
  }) async {
    if (currentChapter > 1) {
      return {
        'bookNumber': currentBookNumber,
        'chapter': currentChapter - 1,
        'scrollToTop': true,
      };
    }

    // Move to previous book's last chapter
    final currentIndex = books.indexWhere(
      (b) => b['book_number'] == currentBookNumber,
    );
    if (currentIndex > 0) {
      final previousBook = books[currentIndex - 1];
      final maxChapter = await dbService.getMaxChapter(
        previousBook['book_number'],
      );
      return {
        'bookNumber': previousBook['book_number'],
        'bookName': previousBook['short_name'],
        'chapter': maxChapter,
        'scrollToTop': true,
      };
    }

    return null; // At start of Bible
  }

  /// Select a book with optional chapter specification
  /// Returns {bookNumber, bookName, chapter, maxChapter}
  Future<Map<String, dynamic>> selectBook({
    required Map<String, dynamic> book,
    int? chapter,
    bool goToLastChapter = false,
  }) async {
    final bookNumber = book['book_number'] as int;
    final maxChapter = await dbService.getMaxChapter(bookNumber);

    int targetChapter = 1;
    if (goToLastChapter) {
      targetChapter = maxChapter;
    } else if (chapter != null && chapter > 0 && chapter <= maxChapter) {
      targetChapter = chapter;
    }

    return {
      'bookNumber': bookNumber,
      'bookName': book['short_name'],
      'chapter': targetChapter,
      'maxChapter': maxChapter,
    };
  }

  /// Search verses with automatic Bible reference detection
  /// Returns {isReference: bool, navigationTarget: {...}?, searchResults: [...]}
  Future<Map<String, dynamic>> searchWithReferenceDetection(
    String query,
  ) async {
    if (query.trim().isEmpty) {
      return {'isReference': false, 'searchResults': []};
    }

    // Try parsing as Bible reference first
    final reference = BibleReferenceParser.parse(query);
    if (reference != null) {
      final bookName = reference['bookName'] as String;
      final chapter = reference['chapter'] as int;
      final verse = reference['verse'] as int?;

      // Find book
      final book = await dbService.findBookByName(bookName);
      if (book != null) {
        final bookNumber = book['book_number'] as int;
        final maxChapter = await dbService.getMaxChapter(bookNumber);

        // Validate chapter
        if (chapter > 0 && chapter <= maxChapter) {
          return {
            'isReference': true,
            'navigationTarget': {
              'bookNumber': bookNumber,
              'bookName': book['short_name'],
              'chapter': chapter,
              'verse': verse,
            },
          };
        }
      }
    }

    // Fall back to text search
    final results = await dbService.searchVerses(query);
    return {'isReference': false, 'searchResults': results};
  }

  /// Restore reading position from saved state
  /// Returns null if position invalid or book not found
  Future<Map<String, dynamic>?> restorePosition({
    required Map<String, dynamic> savedPosition,
    required List<Map<String, dynamic>> books,
  }) async {
    _logger.i(
        '[BibleReaderService] restorePosition: savedPosition=$savedPosition, books.length=${books.length}, dbService=$dbService, dbService.isInitialized=${dbService.isInitialized}');
    final bookNumber = savedPosition['bookNumber'] as int?;
    final chapter = savedPosition['chapter'] as int?;
    if (bookNumber == null || chapter == null) return null;
    // Verify book exists
    final bookIndex = books.indexWhere((b) => b['book_number'] == bookNumber);
    if (bookIndex == -1) return null;
    final book = books[bookIndex];
    // Validación extra: asegurar que dbService está inicializada
    if (!dbService.isInitialized) {
      _logger.e(
          '[BibleReaderService] ERROR: dbService no inicializada en restorePosition');
      throw Exception('BibleDbService no inicializada en restorePosition');
    }
    // Verify chapter is valid
    final maxChapter = await dbService.getMaxChapter(bookNumber);
    if (chapter < 1 || chapter > maxChapter) return null;
    _logger.i(
        '[BibleReaderService] restorePosition: bookNumber=$bookNumber, chapter=$chapter, maxChapter=$maxChapter, bookName=${book['short_name']}');
    return {
      'bookNumber': bookNumber,
      'bookName': book['short_name'],
      'chapter': chapter,
      'verse': savedPosition['verse'] ?? 1,
    };
  }
}
