@Tags(['unit', 'services'])
library;

import 'package:bible_reader_core/src/bible_reading_position_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('BibleReadingPositionService Tests', () {
    setUp(() {
      // Initialize SharedPreferences with empty values
      SharedPreferences.setMockInitialValues({});
    });

    test('should save reading position', () async {
      final service = BibleReadingPositionService();

      await service.savePosition(
        bookName: 'John',
        bookNumber: 480,
        chapter: 1,
        verse: 1,
        version: 'RVR1960',
        languageCode: 'es',
      );

      final position = await service.getLastPosition();

      expect(position, isNotNull);
      expect(position!['bookName'], equals('John'));
      expect(position['bookNumber'], equals(480));
      expect(position['chapter'], equals(1));
      expect(position['verse'], equals(1));
      expect(position['version'], equals('RVR1960'));
      expect(position['languageCode'], equals('es'));
    });

    test('should return null when no position is saved', () async {
      final service = BibleReadingPositionService();

      final position = await service.getLastPosition();

      expect(position, isNull);
    });

    test('should clear saved position', () async {
      final service = BibleReadingPositionService();

      await service.savePosition(
        bookName: 'Exodus',
        bookNumber: 20,
        chapter: 3,
        verse: 14,
        version: 'KJ2000',
        languageCode: 'en',
      );

      await service.clearPosition();

      final position = await service.getLastPosition();

      expect(position, isNull);
    });

    test(
      'remaps legacy KJV_en.SQLite3 position to KJ2000_en.SQLite3',
      () async {
        // Positions saved before the KJV → KJ2000 rename must keep working.
        SharedPreferences.setMockInitialValues({
          'bible_last_book': 'John',
          'bible_last_book_number': 480,
          'bible_last_chapter': 3,
          'bible_last_verse': 16,
          'bible_last_version': 'KJV_en.SQLite3',
          'bible_last_language': 'en',
        });
        final service = BibleReadingPositionService();

        final position = await service.getLastPosition();

        expect(position, isNotNull);
        expect(position!['version'], equals('KJ2000_en.SQLite3'));
        expect(position['bookName'], equals('John'));
        expect(position['chapter'], equals(3));
        expect(position['verse'], equals(16));
      },
    );

    test('does not remap non-legacy version filenames', () async {
      final service = BibleReadingPositionService();

      await service.savePosition(
        bookName: 'Genesis',
        bookNumber: 10,
        chapter: 1,
        version: 'NIV_en.SQLite3',
        languageCode: 'en',
      );

      final position = await service.getLastPosition();

      expect(position, isNotNull);
      expect(position!['version'], equals('NIV_en.SQLite3'));
    });

    test('should update position when saved multiple times', () async {
      final service = BibleReadingPositionService();

      await service.savePosition(
        bookName: 'Matthew',
        bookNumber: 450,
        chapter: 1,
        version: 'RVR1960',
        languageCode: 'es',
      );

      await service.savePosition(
        bookName: 'John',
        bookNumber: 480,
        chapter: 3,
        verse: 16,
        version: 'NIV',
        languageCode: 'en',
      );

      final position = await service.getLastPosition();

      expect(position, isNotNull);
      expect(position!['bookName'], equals('John'));
      expect(position['bookNumber'], equals(480));
      expect(position['chapter'], equals(3));
      expect(position['verse'], equals(16));
      expect(position['version'], equals('NIV'));
      expect(position['languageCode'], equals('en'));
    });
  });
}
