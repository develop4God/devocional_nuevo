import 'package:bible_reader_core/src/bible_preferences_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('BiblePreferencesService Tests', () {
    setUp(() {
      // Initialize SharedPreferences with empty values
      SharedPreferences.setMockInitialValues({});
    });

    group('Font Size', () {
      test('should return default font size when none saved', () async {
        final service = BiblePreferencesService();

        final fontSize = await service.getFontSize();

        expect(fontSize, equals(18.0));
      });

      test('should save and retrieve font size', () async {
        final service = BiblePreferencesService();

        await service.saveFontSize(20.0);
        final fontSize = await service.getFontSize();

        expect(fontSize, equals(20.0));
      });

      test('should update font size when saved multiple times', () async {
        final service = BiblePreferencesService();

        await service.saveFontSize(16.0);
        await service.saveFontSize(22.0);
        final fontSize = await service.getFontSize();

        expect(fontSize, equals(22.0));
      });
    });

    group('Marked Verses', () {
      test('should return empty set when no verses marked', () async {
        final service = BiblePreferencesService();

        final markedVerses = await service.getMarkedVerses();

        expect(markedVerses, isEmpty);
      });

      test('should save and retrieve marked verses', () async {
        final service = BiblePreferencesService();
        final verses = {'Juan|3|16', 'Genesis|1|1'};

        await service.saveMarkedVerses(verses);
        final markedVerses = await service.getMarkedVerses();

        expect(markedVerses, equals(verses));
      });

      test('should toggle verse marking on', () async {
        final service = BiblePreferencesService();
        final currentMarked = <String>{};

        final updatedMarked = await service.toggleMarkedVerse(
          'Juan|3|16',
          currentMarked,
        );

        expect(updatedMarked, contains('Juan|3|16'));
        expect(updatedMarked.length, equals(1));
      });

      test('should toggle verse marking off', () async {
        final service = BiblePreferencesService();
        final currentMarked = {'Juan|3|16', 'Genesis|1|1'};

        final updatedMarked = await service.toggleMarkedVerse(
          'Juan|3|16',
          currentMarked,
        );

        expect(updatedMarked, isNot(contains('Juan|3|16')));
        expect(updatedMarked, contains('Genesis|1|1'));
        expect(updatedMarked.length, equals(1));
      });

      test('should persist toggled verses', () async {
        final service = BiblePreferencesService();
        final currentMarked = <String>{};

        await service.toggleMarkedVerse('Juan|3|16', currentMarked);
        final markedVerses = await service.getMarkedVerses();

        expect(markedVerses, contains('Juan|3|16'));
      });

      test('should clear all marked verses', () async {
        final service = BiblePreferencesService();
        final verses = {'Juan|3|16', 'Genesis|1|1', 'Psalm|23|1'};

        await service.saveMarkedVerses(verses);
        await service.clearMarkedVerses();
        final markedVerses = await service.getMarkedVerses();

        expect(markedVerses, isEmpty);
      });

      test('should handle multiple marked verses', () async {
        final service = BiblePreferencesService();
        final verses = {
          'Juan|3|16',
          'Genesis|1|1',
          'Psalm|23|1',
          'Proverbs|3|5',
          'Romans|8|28',
        };

        await service.saveMarkedVerses(verses);
        final markedVerses = await service.getMarkedVerses();

        expect(markedVerses, equals(verses));
        expect(markedVerses.length, equals(5));
      });
    });
  });
}
