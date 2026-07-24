@Tags(['unit', 'utils'])
library;

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
      expect(languages, contains('hi'));
      expect(languages, contains('de'));
      expect(languages, contains('ar'));
    });

    test('should get language name', () {
      expect(BibleVersionRegistry.getLanguageName('es'), equals('Español'));
      expect(BibleVersionRegistry.getLanguageName('en'), equals('English'));
      expect(BibleVersionRegistry.getLanguageName('pt'), equals('Português'));
      expect(BibleVersionRegistry.getLanguageName('fr'), equals('Français'));
      expect(BibleVersionRegistry.getLanguageName('hi'), equals('हिन्दी'));
      expect(BibleVersionRegistry.getLanguageName('de'), equals('Deutsch'));
      expect(BibleVersionRegistry.getLanguageName('ar'), equals('العربية'));
    });

    test('should get versions for Spanish language', () async {
      final versions = await BibleVersionRegistry.getVersionsForLanguage('es');

      expect(versions, isNotEmpty);
      expect(
        versions.any((v) => v.name == 'Reina Valera 1960 (RVR1960)'),
        isTrue,
      );
      expect(
        versions.any((v) => v.name == 'Nueva Versión Internacional (NVI)'),
        isTrue,
      );
      expect(versions.every((v) => v.languageCode == 'es'), isTrue);
      expect(versions.every((v) => v.language == 'Español'), isTrue);
    });

    test('should get versions for English language', () async {
      final versions = await BibleVersionRegistry.getVersionsForLanguage('en');

      expect(versions, isNotEmpty);
      expect(versions.any((v) => v.name == 'King James 2000 (KJ2000)'), isTrue);
      expect(
        versions.any((v) => v.name == 'New International Version (NIV)'),
        isTrue,
      );
      expect(versions.every((v) => v.languageCode == 'en'), isTrue);
      expect(versions.every((v) => v.language == 'English'), isTrue);
    });

    test('should get versions for Portuguese language', () async {
      final versions = await BibleVersionRegistry.getVersionsForLanguage('pt');

      expect(versions, isNotEmpty);
      expect(
        versions.any((v) => v.name == 'Almeida Revista e Corrigida (ARC)'),
        isTrue,
      );
      expect(versions.every((v) => v.languageCode == 'pt'), isTrue);
      expect(versions.every((v) => v.language == 'Português'), isTrue);
    });

    test('should get versions for French language', () async {
      final versions = await BibleVersionRegistry.getVersionsForLanguage('fr');

      expect(versions, isNotEmpty);
      expect(
        versions.any((v) => v.name == 'Louis Segond 1910 (LSG1910)'),
        isTrue,
      );
      expect(versions.every((v) => v.languageCode == 'fr'), isTrue);
      expect(versions.every((v) => v.language == 'Français'), isTrue);
    });

    test('should get versions for Hindi language', () async {
      final versions = await BibleVersionRegistry.getVersionsForLanguage('hi');

      expect(versions, isNotEmpty);
      expect(versions.length, equals(2));
      expect(versions.any((v) => v.name == 'पवित्र बाइबिल (ओ.वी.)'), isTrue);
      expect(versions.any((v) => v.name == 'पवित्र बाइबिल (HERV)'), isTrue);
      expect(versions.every((v) => v.languageCode == 'hi'), isTrue);
      expect(versions.every((v) => v.language == 'हिन्दी'), isTrue);
    });

    test('should get versions for German language', () async {
      final versions = await BibleVersionRegistry.getVersionsForLanguage('de');

      expect(versions, isNotEmpty);
      expect(versions.length, equals(2));
      expect(versions.any((v) => v.name == 'Lutherbibel 2017 (LU17)'), isTrue);
      expect(
        versions.any((v) => v.name == 'Schlachter 2000 (SCH2000)'),
        isTrue,
      );
      expect(versions.every((v) => v.languageCode == 'de'), isTrue);
      expect(versions.every((v) => v.language == 'Deutsch'), isTrue);
    });

    test('should get versions for Arabic language', () async {
      final versions = await BibleVersionRegistry.getVersionsForLanguage('ar');

      expect(versions, isNotEmpty);
      expect(versions.length, equals(2));
      expect(versions.any((v) => v.name == 'كتاب الحياة'), isTrue);
      expect(versions.any((v) => v.name == 'فان دايك'), isTrue);
      expect(versions.every((v) => v.languageCode == 'ar'), isTrue);
      expect(versions.every((v) => v.language == 'العربية'), isTrue);
    });

    test('should return empty list for unsupported language', () async {
      final versions = await BibleVersionRegistry.getVersionsForLanguage('xx');

      expect(versions, isEmpty);
    });

    test('should get all versions', () async {
      final versions = await BibleVersionRegistry.getAllVersions();

      expect(versions, isNotEmpty);
      expect(
        versions.length,
        greaterThanOrEqualTo(18),
      ); // At least 18 versions (including Hindi, German, and Arabic)
      expect(
        versions.any((v) => v.name == 'Reina Valera 1960 (RVR1960)'),
        isTrue,
      );
      expect(versions.any((v) => v.name == 'King James 2000 (KJ2000)'), isTrue);
      expect(
        versions.any((v) => v.name == 'Almeida Revista e Corrigida (ARC)'),
        isTrue,
      );
      expect(
        versions.any((v) => v.name == 'Louis Segond 1910 (LSG1910)'),
        isTrue,
      );
      expect(versions.any((v) => v.name == 'Bible du Semeur (BDS)'), isTrue);
      expect(versions.any((v) => v.name == 'पवित्र बाइबिल (ओ.वी.)'), isTrue);
      expect(versions.any((v) => v.name == 'Lutherbibel 2017 (LU17)'), isTrue);
      expect(
        versions.any((v) => v.name == 'Schlachter 2000 (SCH2000)'),
        isTrue,
      );
      expect(versions.any((v) => v.name == 'كتاب الحياة'), isTrue);
      expect(versions.any((v) => v.name == 'فان دايك'), isTrue);
    });

    test('all versions should have proper metadata', () async {
      final versions = await BibleVersionRegistry.getAllVersions();

      for (final version in versions) {
        expect(version.name, isNotEmpty);
        expect(version.language, isNotEmpty);
        expect(version.languageCode, isNotEmpty);
        expect(version.assetPath, isNotEmpty);
        expect(version.dbFileName, isNotEmpty);
        expect(version.assetPath, contains('assets/biblia/'));
        expect(version.dbFileName, contains('.SQLite3'));
      }
    });
  });
}
