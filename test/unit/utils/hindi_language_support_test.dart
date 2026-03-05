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
      expect(hindiVersions, contains('पवित्र बाइबिल (ओ.वी.)'));
      expect(hindiVersions, contains('पवित्र बाइबिल'));
    });

    test('Hindi should have default Bible version', () {
      expect(Constants.defaultVersionByLanguage.containsKey('hi'), isTrue);
      expect(
        Constants.defaultVersionByLanguage['hi'],
        equals('पवित्र बाइबिल (ओ.वी.)'),
      );
    });

    test('Default Hindi version should be MASTER_VERSION', () {
      const masterVersion = 'पवित्र बाइबिल (ओ.वी.)';
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
      expect(hindiVersions[0], equals('पवित्र बाइबिल (ओ.वी.)'));
      expect(hindiVersions[1], equals('पवित्र बाइबिल'));
    });
  });
}
