import 'package:flutter_test/flutter_test.dart';

import '../../../bible_reader_core/lib/src/bible_text_normalizer.dart';

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

    test('should remove bracketed references with special characters [36†]',
        () {
      const text = 'Verse text [36†] continues here';
      expect(BibleTextNormalizer.clean(text), 'Verse text  continues here');
    });

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
          BibleTextNormalizer.clean(text), 'Verse text  continues  herenote');
    });

    test('should trim whitespace from result', () {
      const text = '  Verse text  ';
      expect(BibleTextNormalizer.clean(text), 'Verse text');
    });

    test('should handle text with no tags or references', () {
      const text = 'Clean verse text';
      expect(BibleTextNormalizer.clean(text), 'Clean verse text');
    });
  });
}
