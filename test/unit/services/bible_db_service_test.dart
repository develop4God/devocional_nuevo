import 'package:devocional_nuevo/services/bible_db_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BibleDbService Tests', () {
    test('should create BibleDbService instance', () {
      final service = BibleDbService();
      expect(service, isNotNull);
      expect(service, isA<BibleDbService>());
    });

    test('should have initDb method', () {
      final service = BibleDbService();
      expect(service.initDb, isA<Function>());
    });

    test('should have getAllBooks method', () {
      final service = BibleDbService();
      expect(service.getAllBooks, isA<Function>());
    });

    test('should have getMaxChapter method', () {
      final service = BibleDbService();
      expect(service.getMaxChapter, isA<Function>());
    });

    test('should have getChapterVerses method', () {
      final service = BibleDbService();
      expect(service.getChapterVerses, isA<Function>());
    });

    test('should have getChapter method', () {
      final service = BibleDbService();
      expect(service.getChapter, isA<Function>());
    });

    // Note: Integration tests with actual database would require
    // test database files and are better suited for integration testing
  });
}
