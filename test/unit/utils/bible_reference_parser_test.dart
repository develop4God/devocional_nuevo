@Tags(['unit', 'utils'])
library;

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BibleReferenceParser Tests', () {
    test('should parse reference with verse in Spanish (Juan 3:16)', () {
      final result = BibleReferenceParser.parse('Juan 3:16');
      expect(result, isNotNull);
      expect(result!['bookName'], 'Juan');
      expect(result['chapter'], 3);
      expect(result['verse'], 16);
    });

    test('should parse reference with verse in English (John 3:16)', () {
      final result = BibleReferenceParser.parse('John 3:16');
      expect(result, isNotNull);
      expect(result!['bookName'], 'John');
      expect(result['chapter'], 3);
      expect(result['verse'], 16);
    });

    test('should parse reference with verse and book number (1 Juan 3:16)', () {
      final result = BibleReferenceParser.parse('1 Juan 3:16');
      expect(result, isNotNull);
      expect(result!['bookName'], '1 Juan');
      expect(result['chapter'], 3);
      expect(result['verse'], 16);
    });

    test('should parse reference without verse (Juan 3)', () {
      final result = BibleReferenceParser.parse('Juan 3');
      expect(result, isNotNull);
      expect(result!['bookName'], 'Juan');
      expect(result['chapter'], 3);
      expect(result['verse'], isNull);
    });

    test('should parse reference with accented names (Génesis 1:1)', () {
      final result = BibleReferenceParser.parse('Génesis 1:1');
      expect(result, isNotNull);
      expect(result!['bookName'], 'Génesis');
      expect(result['chapter'], 1);
      expect(result['verse'], 1);
    });

    test('should parse Genesis abbreviation (Gn 9:4)', () {
      final result = BibleReferenceParser.parse('Gn 9:4');
      expect(result, isNotNull);
      expect(result!['bookName'], 'Gn');
      expect(result['chapter'], 9);
      expect(result['verse'], 4);
    });

    test('should parse Genesis in English (Genesis 1:1)', () {
      final result = BibleReferenceParser.parse('Genesis 1:1');
      expect(result, isNotNull);
      expect(result!['bookName'], 'Genesis');
      expect(result['chapter'], 1);
      expect(result['verse'], 1);
    });

    test('should parse multi-word book name (1 Corintios 13:4)', () {
      final result = BibleReferenceParser.parse('1 Corintios 13:4');
      expect(result, isNotNull);
      expect(result!['bookName'], '1 Corintios');
      expect(result['chapter'], 13);
      expect(result['verse'], 4);
    });

    test('should return null for plain text search', () {
      final result = BibleReferenceParser.parse('search text');
      expect(result, isNull);
    });

    test('should return null for invalid format', () {
      final result = BibleReferenceParser.parse('invalid:format:text');
      expect(result, isNull);
    });

    test('should handle extra whitespace', () {
      final result = BibleReferenceParser.parse('  Juan  3:16  ');
      expect(result, isNotNull);
      expect(result!['bookName'], 'Juan');
      expect(result['chapter'], 3);
      expect(result['verse'], 16);
    });

    test('should be case-insensitive', () {
      final result = BibleReferenceParser.parse('JUAN 3:16');
      expect(result, isNotNull);
      expect(result!['bookName'], 'JUAN');
      expect(result['chapter'], 3);
      expect(result['verse'], 16);
    });

    test('should parse S. Juan format (S.Juan 3:16)', () {
      final result = BibleReferenceParser.parse('S.Juan 3:16');
      expect(result, isNotNull);
      expect(result!['bookName'], 'S.Juan');
      expect(result['chapter'], 3);
      expect(result['verse'], 16);
    });

    test('should parse 2 Samuel format (2 Samuel 7:12)', () {
      final result = BibleReferenceParser.parse('2 Samuel 7:12');
      expect(result, isNotNull);
      expect(result!['bookName'], '2 Samuel');
      expect(result['chapter'], 7);
      expect(result['verse'], 12);
    });
  });
}
