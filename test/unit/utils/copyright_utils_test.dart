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
