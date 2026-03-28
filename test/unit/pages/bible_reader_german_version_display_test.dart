@Tags(['unit', 'pages'])
library;

// test/unit/pages/bible_reader_german_version_display_test.dart
//
// Regression test for the German-version duplicate-abbreviation bug.
//
// Root cause: _getDisplayName() in BibleReaderPage only stripped the trailing
// "(CODE)" suffix for es/en/pt/fr.  Because 'de' was missing, the full name
// e.g. "Lutherbibel 2017 (LU17)" was passed unchanged to _versionPickerLabel,
// which then appended "· LU17" again, producing:
//     "Lutherbibel 2017 (LU17) · LU17"
//
// Fix: 'de' added to the Latin-script branch so the suffix is stripped first.

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors the _getDisplayName logic from BibleReaderPage.
String getDisplayName(String name, String languageCode) {
  if (languageCode == 'es' ||
      languageCode == 'en' ||
      languageCode == 'pt' ||
      languageCode == 'fr' ||
      languageCode == 'de') {
    final regex = RegExp(r'^(.+?)\s*\([A-Z0-9]+\)$');
    final match = regex.firstMatch(name);
    if (match != null) return match.group(1)!.trim();
  }
  return name;
}

/// Mirrors the _versionPickerLabel logic from BibleReaderPage.
String versionPickerLabel(BibleVersion version) {
  final displayName = getDisplayName(version.name, version.languageCode);
  final abbr = Constants.versionAbbreviation(version);
  if (abbr.isEmpty) return displayName;
  return '$displayName · $abbr';
}

BibleVersion _makeVersion({
  required String name,
  required String languageCode,
  required String dbFileName,
}) =>
    BibleVersion(
      name: name,
      language: languageCode,
      languageCode: languageCode,
      assetPath: 'assets/biblia/$dbFileName',
      dbFileName: dbFileName,
    );

void main() {
  group('German Bible version display — no duplicate abbreviation', () {
    test('LU17 picker label is "Lutherbibel 2017 · LU17" (no duplicate)', () {
      final version = _makeVersion(
        name: 'Lutherbibel 2017 (LU17)',
        languageCode: 'de',
        dbFileName: 'LU17_de.SQLite3',
      );

      expect(getDisplayName(version.name, version.languageCode),
          equals('Lutherbibel 2017'),
          reason: 'getDisplayName must strip the (LU17) suffix for German');

      expect(Constants.versionAbbreviation(version), equals('LU17'),
          reason: 'versionAbbreviation must return LU17 from dbFileName');

      expect(versionPickerLabel(version), equals('Lutherbibel 2017 · LU17'),
          reason: 'Picker label must NOT contain duplicate abbreviation');
    });

    test('SCH2000 picker label is "Schlachter 2000 · SCH2000" (no duplicate)',
        () {
      final version = _makeVersion(
        name: 'Schlachter 2000 (SCH2000)',
        languageCode: 'de',
        dbFileName: 'SCH2000_de.SQLite3',
      );

      expect(getDisplayName(version.name, version.languageCode),
          equals('Schlachter 2000'),
          reason: 'getDisplayName must strip the (SCH2000) suffix for German');

      expect(Constants.versionAbbreviation(version), equals('SCH2000'),
          reason: 'versionAbbreviation must return SCH2000 from dbFileName');

      expect(versionPickerLabel(version), equals('Schlachter 2000 · SCH2000'),
          reason: 'Picker label must NOT contain duplicate abbreviation');
    });

    // ── Regression: other Latin-script languages must still work ──────────

    test('Spanish RVR1960 picker label remains correct', () {
      final version = _makeVersion(
        name: 'Reina Valera 1960 (RVR1960)',
        languageCode: 'es',
        dbFileName: 'RVR1960_es.SQLite3',
      );
      expect(
          versionPickerLabel(version), equals('Reina Valera 1960 · RVR1960'));
    });

    test('English KJV picker label remains correct', () {
      final version = _makeVersion(
        name: 'King James Version (KJV)',
        languageCode: 'en',
        dbFileName: 'KJV_en.SQLite3',
      );
      expect(versionPickerLabel(version), equals('King James Version · KJV'));
    });

    test('French LSG1910 picker label remains correct', () {
      final version = _makeVersion(
        name: 'Louis Segond 1910 (LSG1910)',
        languageCode: 'fr',
        dbFileName: 'LSG1910_fr.SQLite3',
      );
      expect(
          versionPickerLabel(version), equals('Louis Segond 1910 · LSG1910'));
    });

    // ── Native-script languages must NOT be touched ────────────────────────

    test('Japanese version name is shown as-is (no code stripped)', () {
      final version = _makeVersion(
        name: '新改訳2003',
        languageCode: 'ja',
        dbFileName: 'SK2003_ja.SQLite3',
      );
      // versionAbbreviation returns '' for ja
      expect(Constants.versionAbbreviation(version), equals(''),
          reason: 'Japanese must return empty abbreviation');
      expect(versionPickerLabel(version), equals('新改訳2003'),
          reason: 'Japanese name must be used as-is');
    });
  });
}
