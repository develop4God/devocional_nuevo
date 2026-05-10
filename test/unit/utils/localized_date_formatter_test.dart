import 'package:devocional_nuevo/utils/localized_date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    await initializeDateFormatting('en');
    await initializeDateFormatting('fr');
    await initializeDateFormatting('pt');
    await initializeDateFormatting('ja');
    await initializeDateFormatting('zh');
    await initializeDateFormatting('de');
    await initializeDateFormatting('fil');
    await initializeDateFormatting('hi');
    await initializeDateFormatting('ar');
  });

  group('LocalizedDateFormatter', () {
    final testDate = DateTime(2025, 3, 15); // Saturday, March 15

    test('formats Spanish dates correctly', () {
      final format = LocalizedDateFormatter.getDateFormat('es');
      final result = format.format(testDate);
      expect(result, contains('15'));
      expect(result, contains('marzo'));
    });

    test('formats English dates correctly', () {
      final format = LocalizedDateFormatter.getDateFormat('en');
      final result = format.format(testDate);
      expect(result, contains('March'));
      expect(result, contains('15'));
    });

    test('formats French dates correctly', () {
      final format = LocalizedDateFormatter.getDateFormat('fr');
      final result = format.format(testDate);
      expect(result, contains('15'));
      expect(result, contains('mars'));
    });

    test('formats Portuguese dates correctly', () {
      final format = LocalizedDateFormatter.getDateFormat('pt');
      final result = format.format(testDate);
      expect(result, contains('15'));
      expect(result, contains('março'));
    });

    test('formats Japanese dates correctly', () {
      final format = LocalizedDateFormatter.getDateFormat('ja');
      final result = format.format(testDate);
      expect(result, contains('2025'));
      expect(result, contains('3'));
      expect(result, contains('15'));
    });

    test('formats Chinese dates correctly', () {
      final format = LocalizedDateFormatter.getDateFormat('zh');
      final result = format.format(testDate);
      expect(result, contains('2025'));
      expect(result, contains('3'));
      expect(result, contains('15'));
    });

    test('formats German dates correctly', () {
      final format = LocalizedDateFormatter.getDateFormat('de');
      final result = format.format(testDate);
      expect(result, contains('15'));
      // German month can appear as "März" or abbreviated "Mrz"
      expect(result.contains('März') || result.contains('Mrz'), isTrue);
    });

    test('formats Filipino dates correctly with "ng" preposition', () {
      final format = LocalizedDateFormatter.getDateFormat('fil');
      final result = format.format(testDate);
      // Filipino format: "Day, d ng Month" (e.g., "Saturday, 15 ng March")
      expect(
        result,
        contains('15'),
        reason: 'Filipino date should contain day number 15',
      );
      expect(
        result,
        contains('ng'),
        reason: 'Filipino date should contain "ng" preposition',
      );
      // Month name in Filipino (March = Marso)
      expect(
        result.contains('Marso') || result.contains('March'),
        isTrue,
        reason: 'Filipino date should contain month name',
      );
    });

    test('formats specific Filipino date correctly - April 27, 2026', () {
      final format = LocalizedDateFormatter.getDateFormat('fil');
      final aprilDate = DateTime(
        2026,
        4,
        27,
      ); // This is a Monday (Lunes) in 2026
      final result = format.format(aprilDate);

      // Expected format: "Lunes, 27 ng Abril"
      expect(result, contains('27'), reason: 'Should contain day 27');
      expect(
        result,
        contains('ng'),
        reason: 'Should contain ng preposition between day and month',
      );
      expect(
        result.contains('Abril') || result.contains('April'),
        isTrue,
        reason: 'Should contain April month name',
      );
      expect(
        result.contains('Lunes') || result.contains('Monday'),
        isTrue,
        reason: 'Should contain Monday weekday name',
      );
    });

    test('formats Hindi dates correctly', () {
      final format = LocalizedDateFormatter.getDateFormat('hi');
      final result = format.format(testDate);
      expect(result, contains('15'));
      // Hindi month names are in Devanagari script
      expect(result, isNotEmpty);
    });

    test('formats Arabic dates correctly', () {
      final format = LocalizedDateFormatter.getDateFormat('ar');
      final result = format.format(testDate);
      expect(result, isNotEmpty);
      // Arabic text should be present
      expect(result.length, greaterThan(0));
    });

    test('defaults to English for unknown locale', () {
      final format = LocalizedDateFormatter.getDateFormat('xx');
      final result = format.format(testDate);
      expect(result, contains('March'));
      expect(result, contains('15'));
    });

    test('defaults to English for empty locale', () {
      final format = LocalizedDateFormatter.getDateFormat('');
      final result = format.format(testDate);
      expect(result, contains('March'));
    });

    test('all supported locales return valid DateFormat', () {
      final locales = [
        'es',
        'en',
        'fr',
        'pt',
        'ja',
        'zh',
        'de',
        'fil',
        'hi',
        'ar',
      ];
      for (final locale in locales) {
        final format = LocalizedDateFormatter.getDateFormat(locale);
        expect(
          format,
          isA<DateFormat>(),
          reason: 'Locale $locale should return a valid DateFormat',
        );
        // Should not throw when formatting
        expect(
          () => format.format(testDate),
          returnsNormally,
          reason: 'Locale $locale should format without error',
        );
      }
    });

    test('returns consistent results for same locale and date', () {
      final format1 = LocalizedDateFormatter.getDateFormat('es');
      final format2 = LocalizedDateFormatter.getDateFormat('es');
      expect(format1.format(testDate), equals(format2.format(testDate)));
    });
  });
}
