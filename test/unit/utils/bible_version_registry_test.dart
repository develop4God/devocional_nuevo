import 'package:bible_reader_core/src/bible_version_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BibleVersionRegistry Tests', () {
    test('should get supported languages', () {
      final languages = BibleVersionRegistry.getSupportedLanguages();

      expect(languages, isNotEmpty);
      expect(languages, contains('es'));
      expect(languages, contains('en'));
      expect(languages, contains('pt'));
      expect(languages, contains('fr'));
    });

    test('should get language name', () {
      expect(BibleVersionRegistry.getLanguageName('es'), equals('Español'));
      expect(BibleVersionRegistry.getLanguageName('en'), equals('English'));
      expect(BibleVersionRegistry.getLanguageName('pt'), equals('Português'));
      expect(BibleVersionRegistry.getLanguageName('fr'), equals('Français'));
    });

    test('should get versions for Spanish language', () async {
      final versions = await BibleVersionRegistry.getVersionsForLanguage('es');

      expect(versions, isNotEmpty);
      expect(versions.any((v) => v.name == 'RVR1960'), isTrue);
      expect(versions.any((v) => v.name == 'NVI'), isTrue);
      expect(versions.every((v) => v.languageCode == 'es'), isTrue);
      expect(versions.every((v) => v.language == 'Español'), isTrue);
    });

    test('should get versions for English language', () async {
      final versions = await BibleVersionRegistry.getVersionsForLanguage('en');

      expect(versions, isNotEmpty);
      expect(versions.any((v) => v.name == 'KJV'), isTrue);
      expect(versions.any((v) => v.name == 'NIV'), isTrue);
      expect(versions.every((v) => v.languageCode == 'en'), isTrue);
      expect(versions.every((v) => v.language == 'English'), isTrue);
    });

    test('should get versions for Portuguese language', () async {
      final versions = await BibleVersionRegistry.getVersionsForLanguage('pt');

      expect(versions, isNotEmpty);
      expect(versions.any((v) => v.name == 'ARC'), isTrue);
      expect(versions.every((v) => v.languageCode == 'pt'), isTrue);
      expect(versions.every((v) => v.language == 'Português'), isTrue);
    });

    test('should get versions for French language', () async {
      final versions = await BibleVersionRegistry.getVersionsForLanguage('fr');

      expect(versions, isNotEmpty);
      expect(versions.any((v) => v.name == 'LSG1910'), isTrue);
      expect(versions.every((v) => v.languageCode == 'fr'), isTrue);
      expect(versions.every((v) => v.language == 'Français'), isTrue);
    });

    test('should return empty list for unsupported language', () async {
      final versions = await BibleVersionRegistry.getVersionsForLanguage('de');

      expect(versions, isEmpty);
    });

    test('should get all versions', () async {
      final versions = await BibleVersionRegistry.getAllVersions();

      expect(versions, isNotEmpty);
      expect(versions.length, greaterThanOrEqualTo(6)); // At least 6 versions
      expect(versions.any((v) => v.name == 'RVR1960'), isTrue);
      expect(versions.any((v) => v.name == 'KJV'), isTrue);
      expect(versions.any((v) => v.name == 'ARC'), isTrue);
      expect(versions.any((v) => v.name == 'LSG1910'), isTrue);
    });

    test('all versions should have proper metadata', () async {
      final versions = await BibleVersionRegistry.getAllVersions();

      for (final version in versions) {
        expect(version.name, isNotEmpty);
        expect(version.language, isNotEmpty);
        expect(version.languageCode, isNotEmpty);
        expect(version.dbFileName, isNotEmpty);
        expect(version.dbFileName, contains('.SQLite3'));
      }
    });
  });
}
