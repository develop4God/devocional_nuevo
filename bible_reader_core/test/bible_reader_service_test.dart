import 'package:bible_reader_core/src/bible_db_service.dart';
import 'package:bible_reader_core/src/bible_reader_service.dart';
import 'package:bible_reader_core/src/bible_reading_position_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock BibleDbService for testing
class MockBibleDbService extends BibleDbService {
  Map<int, int> mockMaxChapters = {};
  Map<String, dynamic>? mockFoundBook;
  List<Map<String, dynamic>> mockSearchResults = [];

  @override
  Future<int> getMaxChapter(int bookNumber) async {
    return mockMaxChapters[bookNumber] ?? 1;
  }

  @override
  Future<Map<String, dynamic>?> findBookByName(String bookName) async {
    return mockFoundBook;
  }

  @override
  Future<List<Map<String, dynamic>>> searchVerses(String searchQuery) async {
    return mockSearchResults;
  }
}

void main() {
  group('BibleReaderService Tests', () {
    late MockBibleDbService mockDbService;
    late BibleReadingPositionService positionService;
    late BibleReaderService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockDbService = MockBibleDbService();
      positionService = BibleReadingPositionService();
      service = BibleReaderService(
        dbService: mockDbService,
        positionService: positionService,
      );
    });

    group('Reading Position', () {
      test('should save reading position', () async {
        await service.saveReadingPosition(
          bookName: 'Genesis',
          bookNumber: 1,
          chapter: 5,
          verse: 10,
          version: 'RVR1960',
          languageCode: 'es',
        );

        final position = await service.getLastPosition();

        expect(position, isNotNull);
        expect(position!['bookName'], equals('Genesis'));
        expect(position['bookNumber'], equals(1));
        expect(position['chapter'], equals(5));
        expect(position['verse'], equals(10));
        expect(position['version'], equals('RVR1960'));
        expect(position['languageCode'], equals('es'));
      });

      test('should return null when no position saved', () async {
        final position = await service.getLastPosition();

        expect(position, isNull);
      });

      test('should clear saved position', () async {
        await service.saveReadingPosition(
          bookName: 'Genesis',
          bookNumber: 1,
          chapter: 1,
          version: 'RVR1960',
          languageCode: 'es',
        );

        await service.clearPosition();
        final position = await service.getLastPosition();

        expect(position, isNull);
      });

      test('should use default verse value of 1 when not provided', () async {
        await service.saveReadingPosition(
          bookName: 'Exodus',
          bookNumber: 2,
          chapter: 20,
          version: 'KJV',
          languageCode: 'en',
        );

        final position = await service.getLastPosition();

        expect(position, isNotNull);
        expect(position!['verse'], equals(1));
      });
    });

    group('Navigation - navigateToNextChapter', () {
      test('should move to next chapter in same book', () async {
        mockDbService.mockMaxChapters[1] = 50;
        final books = [
          {'book_number': 1, 'short_name': 'Gen'},
        ];

        final result = await service.navigateToNextChapter(
          currentBookNumber: 1,
          currentChapter: 10,
          books: books,
        );

        expect(result, isNotNull);
        expect(result!['bookNumber'], equals(1));
        expect(result['chapter'], equals(11));
        expect(result['scrollToTop'], isTrue);
        expect(result['bookName'], isNull);
      });

      test(
        'should move to first chapter of next book at end of book',
        () async {
          mockDbService.mockMaxChapters[1] = 50;
          final books = [
            {'book_number': 1, 'short_name': 'Gen'},
            {'book_number': 2, 'short_name': 'Ex'},
          ];

          final result = await service.navigateToNextChapter(
            currentBookNumber: 1,
            currentChapter: 50,
            books: books,
          );

          expect(result, isNotNull);
          expect(result!['bookNumber'], equals(2));
          expect(result['bookName'], equals('Ex'));
          expect(result['chapter'], equals(1));
          expect(result['scrollToTop'], isTrue);
        },
      );

      test('should return null at end of Bible', () async {
        mockDbService.mockMaxChapters[66] = 22;
        final books = [
          {'book_number': 66, 'short_name': 'Rev'},
        ];

        final result = await service.navigateToNextChapter(
          currentBookNumber: 66,
          currentChapter: 22,
          books: books,
        );

        expect(result, isNull);
      });
    });

    group('Navigation - navigateToPreviousChapter', () {
      test('should move to previous chapter in same book', () async {
        final books = [
          {'book_number': 1, 'short_name': 'Gen'},
        ];

        final result = await service.navigateToPreviousChapter(
          currentBookNumber: 1,
          currentChapter: 10,
          books: books,
        );

        expect(result, isNotNull);
        expect(result!['bookNumber'], equals(1));
        expect(result['chapter'], equals(9));
        expect(result['scrollToTop'], isTrue);
        expect(result['bookName'], isNull);
      });

      test(
        'should move to last chapter of previous book at start of book',
        () async {
          mockDbService.mockMaxChapters[1] = 50;
          final books = [
            {'book_number': 1, 'short_name': 'Gen'},
            {'book_number': 2, 'short_name': 'Ex'},
          ];

          final result = await service.navigateToPreviousChapter(
            currentBookNumber: 2,
            currentChapter: 1,
            books: books,
          );

          expect(result, isNotNull);
          expect(result!['bookNumber'], equals(1));
          expect(result['bookName'], equals('Gen'));
          expect(result['chapter'], equals(50));
          expect(result['scrollToTop'], isTrue);
        },
      );

      test('should return null at start of Bible', () async {
        final books = [
          {'book_number': 1, 'short_name': 'Gen'},
        ];

        final result = await service.navigateToPreviousChapter(
          currentBookNumber: 1,
          currentChapter: 1,
          books: books,
        );

        expect(result, isNull);
      });
    });

    group('Navigation - selectBook', () {
      test('should select book at first chapter by default', () async {
        mockDbService.mockMaxChapters[43] = 21;
        final book = {'book_number': 43, 'short_name': 'John'};

        final result = await service.selectBook(book: book);

        expect(result['bookNumber'], equals(43));
        expect(result['bookName'], equals('John'));
        expect(result['chapter'], equals(1));
        expect(result['maxChapter'], equals(21));
      });

      test('should select book at specified chapter', () async {
        mockDbService.mockMaxChapters[43] = 21;
        final book = {'book_number': 43, 'short_name': 'John'};

        final result = await service.selectBook(book: book, chapter: 3);

        expect(result['bookNumber'], equals(43));
        expect(result['bookName'], equals('John'));
        expect(result['chapter'], equals(3));
        expect(result['maxChapter'], equals(21));
      });

      test('should select book at last chapter when specified', () async {
        mockDbService.mockMaxChapters[43] = 21;
        final book = {'book_number': 43, 'short_name': 'John'};

        final result = await service.selectBook(
          book: book,
          goToLastChapter: true,
        );

        expect(result['bookNumber'], equals(43));
        expect(result['bookName'], equals('John'));
        expect(result['chapter'], equals(21));
        expect(result['maxChapter'], equals(21));
      });

      test('should default to chapter 1 for invalid chapter', () async {
        mockDbService.mockMaxChapters[43] = 21;
        final book = {'book_number': 43, 'short_name': 'John'};

        final result = await service.selectBook(book: book, chapter: 999);

        expect(result['chapter'], equals(1));
      });
    });

    group('Search - searchWithReferenceDetection', () {
      test('should return empty results for empty query', () async {
        final result = await service.searchWithReferenceDetection('');

        expect(result['isReference'], isFalse);
        expect(result['searchResults'], isEmpty);
      });

      test('should detect valid Bible reference and navigate', () async {
        mockDbService.mockFoundBook = {
          'book_number': 43,
          'short_name': 'Juan',
          'long_name': 'Juan',
        };
        mockDbService.mockMaxChapters[43] = 21;

        final result = await service.searchWithReferenceDetection('Juan 3:16');

        expect(result['isReference'], isTrue);
        expect(result['navigationTarget'], isNotNull);
        final target = result['navigationTarget'] as Map<String, dynamic>;
        expect(target['bookNumber'], equals(43));
        expect(target['bookName'], equals('Juan'));
        expect(target['chapter'], equals(3));
        expect(target['verse'], equals(16));
      });

      test('should detect reference without verse', () async {
        mockDbService.mockFoundBook = {
          'book_number': 1,
          'short_name': 'Genesis',
        };
        mockDbService.mockMaxChapters[1] = 50;

        final result = await service.searchWithReferenceDetection('Genesis 1');

        expect(result['isReference'], isTrue);
        final target = result['navigationTarget'] as Map<String, dynamic>;
        expect(target['chapter'], equals(1));
        expect(target['verse'], isNull);
      });

      test('should fall back to text search for invalid reference', () async {
        mockDbService.mockFoundBook = null;
        mockDbService.mockSearchResults = [
          {'book_number': 43, 'chapter': 3, 'verse': 16, 'text': 'For God...'},
        ];

        final result = await service.searchWithReferenceDetection('love');

        expect(result['isReference'], isFalse);
        expect(result['searchResults'], isNotEmpty);
        expect(result['searchResults'].length, equals(1));
      });

      test('should fall back to text search for invalid chapter', () async {
        mockDbService.mockFoundBook = {'book_number': 43, 'short_name': 'Juan'};
        mockDbService.mockMaxChapters[43] = 21;
        mockDbService.mockSearchResults = [];

        final result = await service.searchWithReferenceDetection('Juan 999:1');

        expect(result['isReference'], isFalse);
        expect(result['searchResults'], isEmpty);
      });
    });

    group('Position - restorePosition', () {
      test('should restore valid position', () async {
        mockDbService.mockMaxChapters[43] = 21;
        final savedPosition = {'bookNumber': 43, 'chapter': 3, 'verse': 16};
        final books = [
          {'book_number': 43, 'short_name': 'Juan'},
        ];

        final result = await service.restorePosition(
          savedPosition: savedPosition,
          books: books,
        );

        expect(result, isNotNull);
        expect(result!['bookNumber'], equals(43));
        expect(result['bookName'], equals('Juan'));
        expect(result['chapter'], equals(3));
        expect(result['verse'], equals(16));
      });

      test('should return null for missing bookNumber', () async {
        final savedPosition = {'chapter': 3};
        final books = [
          {'book_number': 43, 'short_name': 'Juan'},
        ];

        final result = await service.restorePosition(
          savedPosition: savedPosition,
          books: books,
        );

        expect(result, isNull);
      });

      test('should return null for missing chapter', () async {
        final savedPosition = {'bookNumber': 43};
        final books = [
          {'book_number': 43, 'short_name': 'Juan'},
        ];

        final result = await service.restorePosition(
          savedPosition: savedPosition,
          books: books,
        );

        expect(result, isNull);
      });

      test('should return null for book not found', () async {
        final savedPosition = {'bookNumber': 999, 'chapter': 1};
        final books = [
          {'book_number': 43, 'short_name': 'Juan'},
        ];

        final result = await service.restorePosition(
          savedPosition: savedPosition,
          books: books,
        );

        expect(result, isNull);
      });

      test('should return null for invalid chapter (too low)', () async {
        mockDbService.mockMaxChapters[43] = 21;
        final savedPosition = {'bookNumber': 43, 'chapter': 0};
        final books = [
          {'book_number': 43, 'short_name': 'Juan'},
        ];

        final result = await service.restorePosition(
          savedPosition: savedPosition,
          books: books,
        );

        expect(result, isNull);
      });

      test('should return null for invalid chapter (too high)', () async {
        mockDbService.mockMaxChapters[43] = 21;
        final savedPosition = {'bookNumber': 43, 'chapter': 999};
        final books = [
          {'book_number': 43, 'short_name': 'Juan'},
        ];

        final result = await service.restorePosition(
          savedPosition: savedPosition,
          books: books,
        );

        expect(result, isNull);
      });

      test('should use default verse 1 when not provided', () async {
        mockDbService.mockMaxChapters[43] = 21;
        final savedPosition = {'bookNumber': 43, 'chapter': 3};
        final books = [
          {'book_number': 43, 'short_name': 'Juan'},
        ];

        final result = await service.restorePosition(
          savedPosition: savedPosition,
          books: books,
        );

        expect(result, isNotNull);
        expect(result!['verse'], equals(1));
      });
    });
  });
}
