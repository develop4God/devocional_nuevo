import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BibleVerseFormatter.formatVerses', () {
    final books = <Map<String, dynamic>>[
      {'short_name': 'Jn', 'long_name': 'Juan'},
    ];
    final verses = <Map<String, dynamic>>[
      {'verse': 16, 'text': 'Porque de tal manera amó Dios al mundo.'},
      {'verse': 17, 'text': 'Porque no envió Dios a su Hijo al mundo.'},
      {'verse': 18, 'text': 'El que en él cree, no es condenado.'},
      {'verse': 23, 'text': 'Texto del verso 23.'},
      {'verse': 26, 'text': 'Texto del verso 26.'},
    ];
    String cleanText(dynamic text) => text as String;

    test('formats a single selected verse as one line', () {
      final result = BibleVerseFormatter.formatVerses(
        selectedVerseKeys: ['Jn|3|16'],
        verses: verses,
        books: books,
        versionName: 'RVR1960',
        cleanText: cleanText,
      );

      expect(
        result,
        'Juan 3:16 (RVR1960) - Porque de tal manera amó Dios al mundo.',
      );
    });

    test('combines multiple selected verses into one block', () {
      final result = BibleVerseFormatter.formatVerses(
        selectedVerseKeys: ['Jn|3|16', 'Jn|3|17', 'Jn|3|18'],
        verses: verses,
        books: books,
        versionName: 'RVR1960',
        cleanText: cleanText,
      );

      expect(
        result,
        'Juan 3:16-18 (RVR1960)\n'
        '[16] Porque de tal manera amó Dios al mundo.\n'
        '[17] Porque no envió Dios a su Hijo al mundo.\n'
        '[18] El que en él cree, no es condenado.',
      );
    });

    test('combines verses regardless of selection order', () {
      final result = BibleVerseFormatter.formatVerses(
        selectedVerseKeys: ['Jn|3|18', 'Jn|3|16', 'Jn|3|17'],
        verses: verses,
        books: books,
        versionName: 'RVR1960',
        cleanText: cleanText,
      );

      expect(
        result,
        'Juan 3:16-18 (RVR1960)\n'
        '[16] Porque de tal manera amó Dios al mundo.\n'
        '[17] Porque no envió Dios a su Hijo al mundo.\n'
        '[18] El que en él cree, no es condenado.',
      );
    });

    test('collapses non-consecutive verses into comma-separated header', () {
      final result = BibleVerseFormatter.formatVerses(
        selectedVerseKeys: ['Jn|3|16', 'Jn|3|23', 'Jn|3|26'],
        verses: verses,
        books: books,
        versionName: 'RVR1960',
        cleanText: cleanText,
      );

      expect(
        result,
        'Juan 3:16, 23, 26 (RVR1960)\n'
        '[16] Porque de tal manera amó Dios al mundo.\n'
        '[23] Texto del verso 23.\n'
        '[26] Texto del verso 26.',
      );
    });

    test('collapses consecutive runs mixed with isolated verses', () {
      final result = BibleVerseFormatter.formatVerses(
        selectedVerseKeys: [
          'Jn|3|16',
          'Jn|3|17',
          'Jn|3|18',
          'Jn|3|23',
          'Jn|3|26'
        ],
        verses: verses,
        books: books,
        versionName: 'RVR1960',
        cleanText: cleanText,
      );

      expect(
        result,
        'Juan 3:16-18, 23, 26 (RVR1960)\n'
        '[16] Porque de tal manera amó Dios al mundo.\n'
        '[17] Porque no envió Dios a su Hijo al mundo.\n'
        '[18] El que en él cree, no es condenado.\n'
        '[23] Texto del verso 23.\n'
        '[26] Texto del verso 26.',
      );
    });

    test('returns empty string when no verses match', () {
      final result = BibleVerseFormatter.formatVerses(
        selectedVerseKeys: ['Jn|3|99'],
        verses: verses,
        books: books,
        versionName: 'RVR1960',
        cleanText: cleanText,
      );

      expect(result, '');
    });
  });
}
