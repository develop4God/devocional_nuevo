import 'package:devocional_nuevo/utils/copyright_utils.dart';
import 'package:test/test.dart';

void main() {
  group('CopyrightUtils', () {
    test('returns French BDS disclaimer and display name', () {
      final text = CopyrightUtils.getCopyrightText('fr', 'BDS');
      expect(text, contains('Bible du Semeur'));

      final displayName =
          CopyrightUtils.getBibleVersionDisplayName('fr', 'BDS');
      expect(displayName, equals('Bible du Semeur'));
    });

    test('returns Hindi HIOV disclaimer and display name', () {
      final text =
          CopyrightUtils.getCopyrightText('hi', 'पवित्र बाइबिल (ओ.वी.)');
      expect(text, contains('हिन्दी ओ.वी. संस्करण'));
      expect(text, contains('HIOV'));

      final displayName = CopyrightUtils.getBibleVersionDisplayName(
        'hi',
        'पवित्र बाइबिल (ओ.वी.)',
      );
      expect(displayName, equals('हिन्दी ओ.वी. संस्करण'));
    });

    test('returns Hindi HERV disclaimer and display name (fixed from ERV)', () {
      // Test with full Devanagari name
      final text = CopyrightUtils.getCopyrightText('hi', 'पवित्र बाइबिल');
      expect(text, contains('आसान हिंदी संस्करण'));
      expect(text, contains('HERV')); // Fixed: now shows HERV instead of ERV
      expect(text, contains('Bible League International'));
      expect(text, contains('1995, 2010'));

      // Test with abbreviation code
      final textAbbr = CopyrightUtils.getCopyrightText('hi', 'HERV');
      expect(textAbbr, contains('HERV'));
      expect(textAbbr, contains('Bible League International'));

      final displayName =
          CopyrightUtils.getBibleVersionDisplayName('hi', 'पवित्र बाइबिल');
      expect(displayName, equals('आसान हिंदी संस्करण'));
    });

    test('Hindi HIOV abbreviation also works', () {
      final text = CopyrightUtils.getCopyrightText('hi', 'HIOV');
      expect(text, contains('HIOV'));
      expect(text, contains('Bible Society of India'));
    });

    test('falls back to default when version missing', () {
      final text = CopyrightUtils.getCopyrightText('fr', 'UNKNOWN');
      expect(text, anyOf(contains('Louis Segond'), contains('Bible')));
    });

    test('fallback to en when language missing', () {
      final text = CopyrightUtils.getCopyrightText('de', 'KJV');
      expect(text, contains('King James'));
    });
  });
}
