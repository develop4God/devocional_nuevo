import 'package:bible_reader_core/src/bible_db_service.dart';
import 'package:bible_reader_core/src/bible_reader_service.dart';
import 'package:bible_reader_core/src/bible_reading_position_service.dart';
import 'package:bible_reader_core/src/bible_version.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock BibleDbService for testing
class MockBibleDbService extends BibleDbService {
  bool initDbCalled = false;
  String? lastAssetPath;
  String? lastDbName;
  List<Map<String, dynamic>> mockBooks = [];
  Map<int, int> mockMaxChapters = {};
  Map<String, List<Map<String, dynamic>>> mockChapterVerses = {};
  List<Map<String, dynamic>> mockSearchResults = [];
  Map<String, dynamic>? mockFoundBook;

  @override
  Future<void> initDb(String dbAssetPath, String dbName) async {
    initDbCalled = true;
    lastAssetPath = dbAssetPath;
    lastDbName = dbName;
  }

  @override
  Future<List<Map<String, dynamic>>> getAllBooks() async {
    return mockBooks;
  }

  @override
  Future<int> getMaxChapter(int bookNumber) async {
    return mockMaxChapters[bookNumber] ?? 1;
  }

  @override
  Future<List<Map<String, dynamic>>> getChapterVerses(
    int bookNumber,
    int chapter,
  ) async {
    final key = '$bookNumber:$chapter';
    return mockChapterVerses[key] ?? [];
  }

  @override
  Future<List<Map<String, dynamic>>> searchVerses(String searchQuery) async {
    return mockSearchResults;
  }

  @override
  Future<Map<String, dynamic>?> findBookByName(String bookName) async {
    return mockFoundBook;
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

    group('initializeVersion', () {
      test('should call dbService.initDb with correct parameters', () async {
        final version = BibleVersion(
          name: 'RVR1960',
          language: 'Spanish',
          languageCode: 'es',
          assetPath: 'assets/bibles/rvr1960.db',
          dbFileName: 'rvr1960.db',
        );

        await service.initializeVersion(version);

        expect(mockDbService.initDbCalled, isTrue);
        expect(mockDbService.lastAssetPath, equals('assets/bibles/rvr1960.db'));
        expect(mockDbService.lastDbName, equals('rvr1960.db'));
      });
    });

    group('loadBooks', () {
      test('should return books from dbService', () async {
        mockDbService.mockBooks = [
          {'book_number': 1, 'short_name': 'Gen', 'long_name': 'Genesis'},
          {'book_number': 2, 'short_name': 'Ex', 'long_name': 'Exodus'},
        ];

        final books = await service.loadBooks();

        expect(books.length, equals(2));
        expect(books[0]['short_name'], equals('Gen'));
        expect(books[1]['short_name'], equals('Ex'));
      });

      test('should return empty list when no books', () async {
        mockDbService.mockBooks = [];

        final books = await service.loadBooks();

        expect(books, isEmpty);
      });
    });

    group('getMaxChapter', () {
      test('should return max chapter for a book', () async {
        mockDbService.mockMaxChapters[1] = 50;

        final maxChapter = await service.getMaxChapter(1);

        expect(maxChapter, equals(50));
      });

      test('should return default value when book not found', () async {
        final maxChapter = await service.getMaxChapter(999);

        expect(maxChapter, equals(1));
      });
    });

    group('loadChapter', () {
      test('should return verses for a chapter', () async {
        mockDbService.mockChapterVerses['1:1'] = [
          {
            'book_number': 1,
            'chapter': 1,
            'verse': 1,
            'text': 'In the beginning...'
          },
          {
            'book_number': 1,
            'chapter': 1,
            'verse': 2,
            'text': 'And the earth...'
          },
        ];

        final verses = await service.loadChapter(1, 1);

        expect(verses.length, equals(2));
        expect(verses[0]['verse'], equals(1));
        expect(verses[1]['verse'], equals(2));
      });

      test('should return empty list when chapter has no verses', () async {
        final verses = await service.loadChapter(999, 999);

        expect(verses, isEmpty);
      });
    });

    group('searchVerses', () {
      test('should return search results from dbService', () async {
        mockDbService.mockSearchResults = [
          {
            'book_number': 43,
            'chapter': 3,
            'verse': 16,
            'text': 'For God so loved the world...',
            'short_name': 'John',
          },
        ];

        final results = await service.searchVerses('love');

        expect(results.length, equals(1));
        expect(results[0]['chapter'], equals(3));
        expect(results[0]['verse'], equals(16));
      });

      test('should return empty list for empty query', () async {
        final results = await service.searchVerses('');

        expect(results, isEmpty);
      });

      test('should return empty list for whitespace-only query', () async {
        final results = await service.searchVerses('   ');

        expect(results, isEmpty);
      });
    });

    group('findBookByName', () {
      test('should return book when found', () async {
        mockDbService.mockFoundBook = {
          'book_number': 43,
          'short_name': 'John',
          'long_name': 'Gospel of John',
        };

        final book = await service.findBookByName('John');

        expect(book, isNotNull);
        expect(book!['book_number'], equals(43));
        expect(book['short_name'], equals('John'));
      });

      test('should return null when book not found', () async {
        mockDbService.mockFoundBook = null;

        final book = await service.findBookByName('InvalidBook');

        expect(book, isNull);
      });

      test('should return null for empty name', () async {
        final book = await service.findBookByName('');

        expect(book, isNull);
      });

      test('should return null for whitespace-only name', () async {
        final book = await service.findBookByName('   ');

        expect(book, isNull);
      });
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
  });
}
