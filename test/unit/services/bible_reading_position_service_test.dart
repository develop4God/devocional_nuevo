import 'package:devocional_nuevo/services/bible_reading_position_service.dart';
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
        bookName: 'Genesis',
        bookNumber: 1,
        chapter: 1,
        verse: 1,
        version: 'RVR1960',
        languageCode: 'es',
      );

      final position = await service.getLastPosition();

      expect(position, isNotNull);
      expect(position!['bookName'], equals('Genesis'));
      expect(position['bookNumber'], equals(1));
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
        bookNumber: 2,
        chapter: 3,
        verse: 14,
        version: 'KJV',
        languageCode: 'en',
      );

      await service.clearPosition();

      final position = await service.getLastPosition();

      expect(position, isNull);
    });

    test('should update position when saved multiple times', () async {
      final service = BibleReadingPositionService();

      await service.savePosition(
        bookName: 'Matthew',
        bookNumber: 40,
        chapter: 1,
        version: 'RVR1960',
        languageCode: 'es',
      );

      await service.savePosition(
        bookName: 'John',
        bookNumber: 43,
        chapter: 3,
        verse: 16,
        version: 'NIV',
        languageCode: 'en',
      );

      final position = await service.getLastPosition();

      expect(position, isNotNull);
      expect(position!['bookName'], equals('John'));
      expect(position['bookNumber'], equals(43));
      expect(position['chapter'], equals(3));
      expect(position['verse'], equals(16));
      expect(position['version'], equals('NIV'));
      expect(position['languageCode'], equals('en'));
    });
  });
}
