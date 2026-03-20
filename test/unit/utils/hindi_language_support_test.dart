import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Hindi Language Support Tests', () {
    test('Hindi should be in supported languages', () {
      expect(Constants.supportedLanguages.containsKey('hi'), isTrue);
      expect(Constants.supportedLanguages['hi'], equals('हिन्दी'));
    });

    test('Hindi should have Bible versions defined', () {
      expect(Constants.bibleVersionsByLanguage.containsKey('hi'), isTrue);
      final hindiVersions = Constants.bibleVersionsByLanguage['hi']!;
      expect(hindiVersions, isNotEmpty);
      expect(hindiVersions.length, equals(2));
      expect(hindiVersions, contains('HIOV'));
      expect(hindiVersions, contains('HERV'));
    });

    test('Hindi should have default Bible version', () {
      expect(Constants.defaultVersionByLanguage.containsKey('hi'), isTrue);
      expect(
        Constants.defaultVersionByLanguage['hi'],
        equals('HIOV'),
      );
    });

    test('Default Hindi version should be MASTER_VERSION', () {
      const masterVersion = 'HIOV';
      expect(
        Constants.defaultVersionByLanguage['hi'],
        equals(masterVersion),
      );
    });

    test('Hindi language code should be MASTER_LANG', () {
      const masterLang = 'hi';
      expect(Constants.supportedLanguages.containsKey(masterLang), isTrue);
    });

    test('Hindi versions should be in correct order (Master first)', () {
      final hindiVersions = Constants.bibleVersionsByLanguage['hi']!;
      expect(hindiVersions[0], equals('HIOV'));
      expect(hindiVersions[1], equals('HERV'));
    });

    test('Hindi version display names should be available', () async {
      // Version display names now come from BibleVersionRegistry
      final versions = await BibleVersionRegistry.getVersionsForLanguage('hi');
      expect(versions.length, equals(2));

      final hiovVersion = versions.firstWhere((v) => v.dbFileName.startsWith('HIOV'));
      expect(hiovVersion.name, equals('पवित्र बाइबिल (ओ.वी.)'));

      final hervVersion = versions.firstWhere((v) => v.dbFileName.startsWith('HERV'));
      expect(hervVersion.name, equals('पवित्र बाइबिल (HERV)'));
    });
  });
}
