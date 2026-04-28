@Tags(['unit', 'utils'])
library;

import 'package:bible_reader_core/src/bible_text_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BibleTextNormalizer Tests', () {
    test('should return empty string for null input', () {
      expect(BibleTextNormalizer.clean(null), '');
    });

    test('should return empty string for empty input', () {
      expect(BibleTextNormalizer.clean(''), '');
    });

    test('should remove simple bracketed references [1]', () {
      const text = 'Verse text [1] continues here';
      expect(BibleTextNormalizer.clean(text), 'Verse text  continues here');
    });

    test('should remove letter bracketed references [a]', () {
      const text = 'Verse text [a] continues here';
      expect(BibleTextNormalizer.clean(text), 'Verse text  continues here');
    });

    test(
      'should remove bracketed references with special characters [36†]',
      () {
        const text = 'Verse text [36†] continues here';
        expect(BibleTextNormalizer.clean(text), 'Verse text  continues here');
      },
    );

    test('should remove bracketed references with mixed content [a1]', () {
      const text = 'Verse text [a1] continues here';
      expect(BibleTextNormalizer.clean(text), 'Verse text  continues here');
    });

    test('should remove bracketed references with words [note]', () {
      const text = 'Verse text [note] continues here';
      expect(BibleTextNormalizer.clean(text), 'Verse text  continues here');
    });

    test('should remove multiple bracketed references', () {
      const text = 'Verse [1] text [a] continues [36†] here';
      expect(BibleTextNormalizer.clean(text), 'Verse  text  continues  here');
    });

    test('should remove HTML tags <pb/>', () {
      const text = 'Verse text<pb/>continues here';
      expect(BibleTextNormalizer.clean(text), 'Verse textcontinues here');
    });

    test('should remove HTML tags <f>', () {
      const text = 'Verse text<f>note</f>continues here';
      expect(BibleTextNormalizer.clean(text), 'Verse textnotecontinues here');
    });

    test('should remove both HTML tags and bracketed references', () {
      const text = 'Verse<pb/> text [1] continues [36†] here<f>note</f>';
      expect(
        BibleTextNormalizer.clean(text),
        'Verse text  continues  herenote',
      );
    });

    test('should trim whitespace from result', () {
      const text = '  Verse text  ';
      expect(BibleTextNormalizer.clean(text), 'Verse text');
    });

    test('should handle text with no tags or references', () {
      const text = 'Clean verse text';
      expect(BibleTextNormalizer.clean(text), 'Clean verse text');
    });

    test('should remove circled lowercase letter footnote markers ⓐ ⓑ', () {
      const text = 'Sinabi ⓐ ng Diyos: Magkaroon ng liwanag ⓑ.';
      final result = BibleTextNormalizer.clean(text);
      expect(result, isNot(contains('ⓐ')));
      expect(result, isNot(contains('ⓑ')));
      expect(result, contains('Sinabi'));
      expect(result, contains('ng Diyos'));
    });

    test('should remove circled uppercase letter markers Ⓐ Ⓑ', () {
      const text = 'God Ⓐ said let there be light Ⓑ.';
      final result = BibleTextNormalizer.clean(text);
      expect(result, isNot(contains('Ⓐ')));
      expect(result, isNot(contains('Ⓑ')));
    });

    test('should remove circled number markers ①②③', () {
      const text = 'Verse ① contains a note ② about this ③.';
      final result = BibleTextNormalizer.clean(text);
      expect(result, isNot(contains('①')));
      expect(result, isNot(contains('②')));
      expect(result, isNot(contains('③')));
    });

    test('removes footnote markers from MBB05-style Filipino verse text', () {
      // Realistic MBB05 verse with inline footnote markers
      const text = 'Sinabi ⓑ ng Diyos, "Magkaroon ng liwanag ⓐ";';
      final result = BibleTextNormalizer.clean(text);
      expect(result, isNot(contains('ⓑ')));
      expect(result, isNot(contains('ⓐ')));
      expect(result, contains('Sinabi'));
    });
  });
}
