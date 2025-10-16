import 'package:bible_reader_core/src/bible_db_service.dart';
import 'package:bible_reader_core/src/bible_reading_position_service.dart';
import 'package:bible_reader_core/src/bible_reference_parser.dart';
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

  /// Navigate to next chapter, moving to next book if at end
  /// Returns {bookNumber, chapter, scrollToTop: true, bookName: ...} or null if at Bible end
  Future<Map<String, dynamic>?> navigateToNextChapter({
    required int currentBookNumber,
    required int currentChapter,
    required List<Map<String, dynamic>> books,
  }) async {
    final maxChapter = await getMaxChapter(currentBookNumber);

    if (currentChapter < maxChapter) {
      return {
        'bookNumber': currentBookNumber,
        'chapter': currentChapter + 1,
        'scrollToTop': true,
      };
    }

    // Move to next book
    final currentIndex =
        books.indexWhere((b) => b['book_number'] == currentBookNumber);
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
    final currentIndex =
        books.indexWhere((b) => b['book_number'] == currentBookNumber);
    if (currentIndex > 0) {
      final previousBook = books[currentIndex - 1];
      final maxChapter = await getMaxChapter(previousBook['book_number']);
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
    final maxChapter = await getMaxChapter(bookNumber);

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
      String query) async {
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
      final book = await findBookByName(bookName);
      if (book != null) {
        final bookNumber = book['book_number'] as int;
        final maxChapter = await getMaxChapter(bookNumber);

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
    final results = await searchVerses(query);
    return {
      'isReference': false,
      'searchResults': results,
    };
  }

  /// Restore reading position from saved state
  /// Returns null if position invalid or book not found
  Future<Map<String, dynamic>?> restorePosition({
    required Map<String, dynamic> savedPosition,
    required List<Map<String, dynamic>> books,
  }) async {
    final bookNumber = savedPosition['bookNumber'] as int?;
    final chapter = savedPosition['chapter'] as int?;

    if (bookNumber == null || chapter == null) return null;

    // Verify book exists
    final bookIndex = books.indexWhere((b) => b['book_number'] == bookNumber);
    if (bookIndex == -1) return null;

    final book = books[bookIndex];

    // Verify chapter is valid
    final maxChapter = await getMaxChapter(bookNumber);
    if (chapter < 1 || chapter > maxChapter) return null;

    return {
      'bookNumber': bookNumber,
      'bookName': book['short_name'],
      'chapter': chapter,
      'verse': savedPosition['verse'] ?? 1,
    };
  }
}
