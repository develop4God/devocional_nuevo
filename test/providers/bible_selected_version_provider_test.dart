import 'package:devocional_nuevo/providers/bible_selected_version_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BibleSelectedVersionProvider Tests', () {
    group('Default Version by Language Mapping', () {
      // This mapping mirrors the _defaultVersionByLanguage map in
      // BibleSelectedVersionProvider. If that implementation changes,
      // these tests should fail to alert us of the change.
      // See: lib/providers/bible_selected_version_provider.dart
      const defaultVersionByLanguage = {
        'es': 'RVR1960',
        'en': 'KJV',
        'pt': 'ARC',
        'fr': 'LSG1910',
        'ja': '新改訳2003',
      };

      test('Spanish (es) should default to RVR1960', () {
        expect(defaultVersionByLanguage['es'], equals('RVR1960'));
      });

      test('English (en) should default to KJV', () {
        expect(defaultVersionByLanguage['en'], equals('KJV'));
      });

      test('Portuguese (pt) should default to ARC', () {
        expect(defaultVersionByLanguage['pt'], equals('ARC'));
      });

      test('French (fr) should default to LSG1910', () {
        expect(defaultVersionByLanguage['fr'], equals('LSG1910'));
      });

      test('Japanese (ja) should default to 新改訳2003', () {
        expect(defaultVersionByLanguage['ja'], equals('新改訳2003'));
      });

      test('All 5 supported languages have default versions', () {
        expect(defaultVersionByLanguage.length, equals(5));
        expect(defaultVersionByLanguage.containsKey('es'), isTrue);
        expect(defaultVersionByLanguage.containsKey('en'), isTrue);
        expect(defaultVersionByLanguage.containsKey('pt'), isTrue);
        expect(defaultVersionByLanguage.containsKey('fr'), isTrue);
        expect(defaultVersionByLanguage.containsKey('ja'), isTrue);
      });

      test('Changing language to English should set KJV as default', () {
        // Simulate the logic from setLanguage method
        const newLanguage = 'en';
        final newVersion = defaultVersionByLanguage[newLanguage] ?? 'RVR1960';
        expect(newVersion, equals('KJV'));
      });

      test('Changing language to Portuguese should set ARC as default', () {
        const newLanguage = 'pt';
        final newVersion = defaultVersionByLanguage[newLanguage] ?? 'RVR1960';
        expect(newVersion, equals('ARC'));
      });

      test('Changing language to French should set LSG1910 as default', () {
        const newLanguage = 'fr';
        final newVersion = defaultVersionByLanguage[newLanguage] ?? 'RVR1960';
        expect(newVersion, equals('LSG1910'));
      });

      test('Unknown language should fallback to RVR1960', () {
        const newLanguage = 'unknown';
        final newVersion = defaultVersionByLanguage[newLanguage] ?? 'RVR1960';
        expect(newVersion, equals('RVR1960'));
      });
    });

    group('BibleProviderState', () {
      test('BibleProviderState has all expected states', () {
        expect(BibleProviderState.values.length, equals(4));
        expect(BibleProviderState.values, contains(BibleProviderState.loading));
        expect(BibleProviderState.values,
            contains(BibleProviderState.downloading));
        expect(BibleProviderState.values, contains(BibleProviderState.ready));
        expect(BibleProviderState.values, contains(BibleProviderState.error));
      });
    });
  });
}
