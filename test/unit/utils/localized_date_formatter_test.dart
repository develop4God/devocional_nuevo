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
      final locales = ['es', 'en', 'fr', 'pt', 'ja', 'zh'];
      for (final locale in locales) {
        final format = LocalizedDateFormatter.getDateFormat(locale);
        expect(format, isA<DateFormat>(),
            reason: 'Locale $locale should return a valid DateFormat');
        // Should not throw when formatting
        expect(() => format.format(testDate), returnsNormally,
            reason: 'Locale $locale should format without error');
      }
    });

    test('returns consistent results for same locale and date', () {
      final format1 = LocalizedDateFormatter.getDateFormat('es');
      final format2 = LocalizedDateFormatter.getDateFormat('es');
      expect(format1.format(testDate), equals(format2.format(testDate)));
    });
  });
}
