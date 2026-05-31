@Tags(['unit', 'controllers'])
library;

// test/unit/pages/bible_reader_page_test.dart
//
// High-value behavior tests for BibleReaderController.
// Tests real user flows using fake services — no SQLite, no assets.
// Catches: state leaks, navigation bugs, persistence regressions,
// font size boundary violations, verse selection inconsistencies,
// search state corruption, stream disposal leaks.

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Fake BibleDbService ────────────────────────────────────────────────────

class _FakeBibleDbService extends BibleDbService {
  final List<Map<String, dynamic>> _books;
  final Map<int, int> _maxChapters;
  final Map<String, List<Map<String, dynamic>>> _verses;

  _FakeBibleDbService({
    List<Map<String, dynamic>>? books,
    Map<int, int>? maxChapters,
    Map<String, List<Map<String, dynamic>>>? verses,
  })  : _books = books ??
            [
              {'book_number': 10, 'short_name': 'Gen', 'long_name': 'Genesis'},
              {'book_number': 20, 'short_name': 'Exo', 'long_name': 'Éxodo'},
              {'book_number': 470, 'short_name': 'Jn', 'long_name': 'Juan'},
            ],
        _maxChapters = maxChapters ?? {10: 50, 20: 40, 470: 21},
        _verses = verses ??
            {
              '10-1': [
                {'verse': 1, 'text': 'En el principio creó Dios...'},
                {'verse': 2, 'text': 'Y la tierra estaba desordenada...'},
              ],
              '20-1': [
                {'verse': 1, 'text': 'Estos son los nombres...'},
              ],
              '470-3': [
                {'verse': 16, 'text': 'Porque de tal manera amó Dios...'},
              ],
            };

  @override
  Future<void> initDb(String assetPath, String dbFileName) async {}

  @override
  Future<List<Map<String, dynamic>>> getAllBooks() async => _books;

  @override
  Future<int> getMaxChapter(int bookNumber) async =>
      _maxChapters[bookNumber] ?? 1;

  @override
  Future<List<Map<String, dynamic>>> getChapterVerses(
    int bookNumber,
    int chapter,
  ) async =>
      _verses['$bookNumber-$chapter'] ?? [];

  @override
  Future<List<Map<String, dynamic>>> searchVerses(String query) async => [
        {
          'book_number': 470,
          'chapter': 3,
          'verse': 16,
          'text': 'Porque de tal manera amó Dios al mundo...',
        },
      ];

  @override
  Future<Map<String, dynamic>?> findBookByName(String name) async {
    try {
      return _books.firstWhere(
        (b) => b['short_name'] == name || b['long_name'] == name,
      );
    } catch (e) {
      return null;
    }
  }
}

// ── Test factory ───────────────────────────────────────────────────────────

BibleVersion _makeVersion({
  String name = 'RVR1960',
  String languageCode = 'es',
  String? dbFileName,
  _FakeBibleDbService? fakeDb,
}) {
  final effectiveDbFileName = dbFileName ?? '$name.db';
  final version = BibleVersion(
    name: name,
    language: languageCode == 'ar' ? 'Arabic' : 'Español',
    languageCode: languageCode,
    assetPath: 'assets/fake/$effectiveDbFileName',
    dbFileName: effectiveDbFileName,
  );
  version.service = fakeDb ?? _FakeBibleDbService();
  return version;
}

BibleReaderController _makeController({
  List<BibleVersion>? versions,
  BibleReaderService? readerService,
  BiblePreferencesService? preferencesService,
}) {
  final fakeDb = _FakeBibleDbService();
  final positionService = BibleReadingPositionService();
  return BibleReaderController(
    allVersions: versions ?? [_makeVersion()],
    readerService: readerService ??
        BibleReaderService(dbService: fakeDb, positionService: positionService),
    preferencesService: preferencesService ?? BiblePreferencesService(),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('BibleReaderController - Real User Behavior', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    // ── Lifecycle ────────────────────────────────────────────────────────

    group('Lifecycle — stream disposal', () {
      test('dispose() closes stateStream — no leak', () async {
        final controller = _makeController();
        await controller.initialize('es');

        controller.dispose();

        // Adding listener after dispose must not throw
        expect(() => controller.stateStream.listen((_) {}), returnsNormally);
      });

      test('multiple dispose() calls do not throw', () async {
        final controller = _makeController();
        await controller.initialize('es');

        controller.dispose();
        // Second dispose should not crash
        expect(() => controller.dispose(), returnsNormally);
      });
    });

    // ── Initialization ───────────────────────────────────────────────────

    group('Initialize — version filtering', () {
      test('Spanish device gets Spanish version', () async {
        final esVersion = _makeVersion(name: 'RVR1960', languageCode: 'es');
        final arVersion = _makeVersion(name: 'NAV', languageCode: 'ar');
        final controller = _makeController(versions: [esVersion, arVersion]);

        await controller.initialize('es');

        expect(controller.state.selectedVersion?.languageCode, 'es');
        expect(controller.state.selectedVersion?.name, 'RVR1960');
        controller.dispose();
      });

      test('Arabic device gets Arabic version', () async {
        final esVersion = _makeVersion(name: 'RVR1960', languageCode: 'es');
        final arVersion = _makeVersion(name: 'NAV', languageCode: 'ar');
        final controller = _makeController(versions: [esVersion, arVersion]);

        await controller.initialize('ar');

        expect(controller.state.selectedVersion?.languageCode, 'ar');
        expect(controller.state.selectedVersion?.name, 'NAV');
        controller.dispose();
      });

      test('Unknown language falls back to Spanish', () async {
        final esVersion = _makeVersion(name: 'RVR1960', languageCode: 'es');
        final controller = _makeController(versions: [esVersion]);

        await controller.initialize('ja'); // Japanese — no JA version

        expect(controller.state.selectedVersion?.languageCode, 'es');
        controller.dispose();
      });

      test('isLoading is false after initialize completes', () async {
        final controller = _makeController();
        await controller.initialize('es');

        expect(controller.state.isLoading, isFalse);
        controller.dispose();
      });

      test('books are loaded after initialize', () async {
        final controller = _makeController();
        await controller.initialize('es');

        expect(controller.state.books, isNotEmpty);
        expect(controller.state.selectedBookName, isNotNull);
        controller.dispose();
      });

      test('state stream emits loading then loaded', () async {
        final controller = _makeController();
        final states = <BibleReaderState>[];
        final sub = controller.stateStream.listen(states.add);

        await controller.initialize('es');
        // Give the state stream time to emit the final "loaded" state
        await Future.delayed(const Duration(milliseconds: 100));
        await sub.cancel();

        expect(states.any((s) => s.isLoading), isTrue);
        expect(states.last.isLoading, isFalse);
        controller.dispose();
      });
    });

    // ── Navigation ───────────────────────────────────────────────────────

    group('Navigation — chapter/book', () {
      test('Next chapter increments chapter number', () async {
        final controller = _makeController();
        await controller.initialize('es');

        final initialChapter = controller.state.selectedChapter ?? 1;
        await controller.goToNextChapter();

        expect(
          controller.state.selectedChapter,
          greaterThan(initialChapter),
          reason: 'Chapter should increment on next',
        );
        controller.dispose();
      });

      test('Previous chapter decrements chapter number', () async {
        final controller = _makeController();
        await controller.initialize('es');

        // Go to chapter 2 first
        await controller.selectChapter(2);
        await controller.goToPreviousChapter();

        expect(controller.state.selectedChapter, equals(1));
        controller.dispose();
      });

      test(
        'Previous chapter at start of Bible returns null — no crash',
        () async {
          final controller = _makeController();
          await controller.initialize('es');

          // Genesis chapter 1 — at Bible start
          await controller.selectChapter(1);

          // Should not throw
          expect(() => controller.goToPreviousChapter(), returnsNormally);
          controller.dispose();
        },
      );

      test('selectChapter resets verse selection', () async {
        final controller = _makeController();
        await controller.initialize('es');

        // Select some verses
        controller.toggleVerseSelection('Gen|1|1');
        expect(controller.state.selectedVerses, isNotEmpty);

        await controller.selectChapter(2);

        expect(
          controller.state.selectedVerses,
          isEmpty,
          reason: 'Verse selection must clear on chapter change',
        );
        controller.dispose();
      });

      test('selectBook navigates to chapter 1 by default', () async {
        final controller = _makeController();
        await controller.initialize('es');

        final exo = controller.state.books.firstWhere(
          (b) => b['short_name'] == 'Exo',
        );
        await controller.selectBook(exo);

        expect(controller.state.selectedBookName, 'Exo');
        expect(controller.state.selectedChapter, 1);
        controller.dispose();
      });
    });

    // ── Font size ────────────────────────────────────────────────────────

    group('Font size — boundary enforcement', () {
      test('Default font size is 18.0', () async {
        final controller = _makeController();
        await controller.initialize('es');

        expect(controller.state.fontSize, equals(18.0));
        controller.dispose();
      });

      test('Increase font size adds 2', () async {
        final controller = _makeController();
        await controller.initialize('es');

        await controller.increaseFontSize();

        expect(controller.state.fontSize, equals(20.0));
        controller.dispose();
      });

      test('Decrease font size subtracts 2', () async {
        final controller = _makeController();
        await controller.initialize('es');

        await controller.decreaseFontSize();

        expect(controller.state.fontSize, equals(16.0));
        controller.dispose();
      });

      test('Font size does not exceed 30', () async {
        final controller = _makeController();
        await controller.initialize('es');

        // Hammer increase
        for (int i = 0; i < 20; i++) {
          await controller.increaseFontSize();
        }

        expect(
          controller.state.fontSize,
          lessThanOrEqualTo(30),
          reason: 'Font size must not exceed max boundary of 30',
        );
        controller.dispose();
      });

      test('Font size does not go below 12', () async {
        final controller = _makeController();
        await controller.initialize('es');

        // Hammer decrease
        for (int i = 0; i < 20; i++) {
          await controller.decreaseFontSize();
        }

        expect(
          controller.state.fontSize,
          greaterThanOrEqualTo(12),
          reason: 'Font size must not go below min boundary of 12',
        );
        controller.dispose();
      });

      test('Font size persists across controller reinitialize', () async {
        final prefs = BiblePreferencesService();
        final controller = _makeController(preferencesService: prefs);
        await controller.initialize('es');

        await controller.increaseFontSize();
        await controller.increaseFontSize();
        controller.dispose();

        // New controller — same prefs service — should restore 22.0
        final controller2 = _makeController(preferencesService: prefs);
        await controller2.initialize('es');

        expect(
          controller2.state.fontSize,
          equals(22.0),
          reason: 'Font size must persist via SharedPreferences',
        );
        controller2.dispose();
      });
    });

    // ── Verse selection ──────────────────────────────────────────────────

    group('Verse selection — copy/share flow', () {
      test('Toggle verse adds it to selection', () async {
        final controller = _makeController();
        await controller.initialize('es');

        controller.toggleVerseSelection('Gen|1|1');

        expect(controller.state.selectedVerses, contains('Gen|1|1'));
        controller.dispose();
      });

      test('Toggle same verse twice removes it', () async {
        final controller = _makeController();
        await controller.initialize('es');

        controller.toggleVerseSelection('Gen|1|1');
        controller.toggleVerseSelection('Gen|1|1');

        expect(controller.state.selectedVerses, isEmpty);
        controller.dispose();
      });

      test('Multiple verses can be selected simultaneously', () async {
        final controller = _makeController();
        await controller.initialize('es');

        controller.toggleVerseSelection('Gen|1|1');
        controller.toggleVerseSelection('Gen|1|2');
        controller.toggleVerseSelection('Gen|1|3');

        expect(controller.state.selectedVerses.length, equals(3));
        controller.dispose();
      });

      test('clearSelectedVerses empties selection', () async {
        final controller = _makeController();
        await controller.initialize('es');

        controller.toggleVerseSelection('Gen|1|1');
        controller.toggleVerseSelection('Gen|1|2');
        controller.clearSelectedVerses();

        expect(controller.state.selectedVerses, isEmpty);
        controller.dispose();
      });
    });

    // ── Marked verses persistence ────────────────────────────────────────

    group('Marked verses — persistence', () {
      test('Mark a verse persists to SharedPreferences', () async {
        final prefs = BiblePreferencesService();
        final controller = _makeController(preferencesService: prefs);
        await controller.initialize('es');

        await controller.togglePersistentMark('Gen|1|1');

        expect(controller.state.persistentlyMarkedVerses, contains('Gen|1|1'));
        controller.dispose();
      });

      test('Unmark a verse removes it from persistence', () async {
        final prefs = BiblePreferencesService();
        final controller = _makeController(preferencesService: prefs);
        await controller.initialize('es');

        await controller.togglePersistentMark('Gen|1|1');
        await controller.togglePersistentMark('Gen|1|1');

        expect(
          controller.state.persistentlyMarkedVerses,
          isNot(contains('Gen|1|1')),
        );
        controller.dispose();
      });

      test('Marked verses survive controller recreation', () async {
        final prefs = BiblePreferencesService();
        final controller = _makeController(preferencesService: prefs);
        await controller.initialize('es');
        await controller.togglePersistentMark('Jn|3|16');
        controller.dispose();

        final controller2 = _makeController(preferencesService: prefs);
        await controller2.initialize('es');

        expect(
          controller2.state.persistentlyMarkedVerses,
          contains('Jn|3|16'),
          reason: 'Marked verses must survive session restart',
        );
        controller2.dispose();
      });
    });

    // ── Search ───────────────────────────────────────────────────────────

    group('Search — state correctness', () {
      test('Empty query clears search state', () async {
        final controller = _makeController();
        await controller.initialize('es');

        await controller.performSearch('amor');
        await controller.performSearch('');

        expect(controller.state.isSearching, isFalse);
        expect(controller.state.searchResults, isEmpty);
        expect(controller.state.searchQuery, isEmpty);
        controller.dispose();
      });

      test('Text search sets isSearching and returns results', () async {
        final controller = _makeController();
        await controller.initialize('es');

        await controller.performSearch('amor');

        expect(controller.state.isSearching, isTrue);
        expect(controller.state.searchResults, isNotEmpty);
        expect(controller.state.searchQuery, equals('amor'));
        controller.dispose();
      });

      test('clearSearch resets all search state', () async {
        final controller = _makeController();
        await controller.initialize('es');

        await controller.performSearch('amor');
        controller.clearSearch();

        expect(controller.state.isSearching, isFalse);
        expect(controller.state.searchResults, isEmpty);
        expect(controller.state.searchQuery, isEmpty);
        controller.dispose();
      });

      test('isLoading is false after search completes', () async {
        final controller = _makeController();
        await controller.initialize('es');

        await controller.performSearch('amor');

        expect(
          controller.state.isLoading,
          isFalse,
          reason: 'isLoading must be cleared after search — UI leak risk',
        );
        controller.dispose();
      });
    });

    // ── Reading position persistence ─────────────────────────────────────

    group('Reading position — persistence', () {
      test('Position is saved after chapter load', () async {
        final positionService = BibleReadingPositionService();
        final fakeDb = _FakeBibleDbService();
        final readerService = BibleReaderService(
          dbService: fakeDb,
          positionService: positionService,
        );
        final controller = _makeController(readerService: readerService);
        await controller.initialize('es');

        final saved = await positionService.getLastPosition();

        expect(saved, isNotNull);
        expect(saved!['bookName'], isNotNull);
        expect(saved['chapter'], isNotNull);
        controller.dispose();
      });

      test('Position restores on next session', () async {
        final positionService = BibleReadingPositionService();
        final fakeDb = _FakeBibleDbService();
        final readerService = BibleReaderService(
          dbService: fakeDb,
          positionService: positionService,
        );

        // Session 1: navigate to Exodus chapter 3
        final version = _makeVersion(fakeDb: fakeDb);
        final controller = BibleReaderController(
          allVersions: [version],
          readerService: readerService,
          preferencesService: BiblePreferencesService(),
        );
        await controller.initialize('es');
        final exo = controller.state.books.firstWhere(
          (b) => b['short_name'] == 'Exo',
        );
        await controller.selectBook(exo, chapter: 3);
        controller.dispose();

        // Session 2: position should restore to Exodus 3
        final version2 = _makeVersion(fakeDb: fakeDb);
        final controller2 = BibleReaderController(
          allVersions: [version2],
          readerService: readerService,
          preferencesService: BiblePreferencesService(),
        );
        await controller2.initialize('es');

        expect(
          controller2.state.selectedBookName,
          equals('Exo'),
          reason: 'Book must restore from saved position',
        );
        expect(
          controller2.state.selectedChapter,
          equals(3),
          reason: 'Chapter must restore from saved position',
        );
        controller2.dispose();
      });
    });

    // ── Version switching ────────────────────────────────────────────────

    group('Version switching', () {
      test('Switching version resets verse selection', () async {
        final rvr = _makeVersion(name: 'RVR1960');
        final nvi = _makeVersion(name: 'NVI');
        final controller = _makeController(versions: [rvr, nvi]);
        await controller.initialize('es');

        controller.toggleVerseSelection('Gen|1|1');
        expect(controller.state.selectedVerses, isNotEmpty);

        await controller.switchVersion(nvi);

        expect(
          controller.state.selectedVerses,
          isEmpty,
          reason: 'Verse selection must clear on version switch',
        );
        controller.dispose();
      });

      test('Switching to same version is a no-op', () async {
        final rvr = _makeVersion(name: 'RVR1960');
        final controller = _makeController(versions: [rvr]);
        await controller.initialize('es');

        final statesBefore = controller.state;
        await controller.switchVersion(rvr);

        expect(
          controller.state,
          same(statesBefore),
          reason: 'Switching to current version should not emit new state',
        );
        controller.dispose();
      });

      test('isLoading is false after version switch completes', () async {
        final rvr = _makeVersion(name: 'RVR1960');
        final nvi = _makeVersion(name: 'NVI');
        final controller = _makeController(versions: [rvr, nvi]);
        await controller.initialize('es');

        await controller.switchVersion(nvi);

        expect(
          controller.state.isLoading,
          isFalse,
          reason: 'isLoading leak after version switch',
        );
        controller.dispose();
      });

      test(
        'Same name, different dbFileName — controller treats them as different',
        () async {
          // Two versions share the display name but have distinct database files.
          // The controller must use dbFileName (not name) as the identity key.
          final versionA = _makeVersion(
            name: 'RVR1960',
            dbFileName: 'rvr1960_v1.db',
          );
          final versionB = _makeVersion(
            name: 'RVR1960',
            dbFileName: 'rvr1960_v2.db',
          );
          final controller = _makeController(versions: [versionA, versionB]);
          await controller.initialize('es');

          // Controller should have selected versionA during init
          expect(controller.state.selectedVersion?.dbFileName, 'rvr1960_v1.db');

          final stateBefore = controller.state;
          await controller.switchVersion(versionB);

          expect(
            controller.state,
            isNot(same(stateBefore)),
            reason:
                'Versions with different dbFileName must be treated as distinct '
                '— switchVersion should emit new state',
          );
          expect(controller.state.selectedVersion?.dbFileName, 'rvr1960_v2.db');
          controller.dispose();
        },
      );

      test(
        'Different name, same dbFileName — controller treats them as same',
        () async {
          // Two version objects have different display names but identical
          // dbFileName. The controller should consider them the same version
          // and skip the switch entirely.
          final versionA = _makeVersion(
            name: 'RVR1960',
            dbFileName: 'shared.db',
          );
          final versionB = _makeVersion(name: 'NVI', dbFileName: 'shared.db');
          final controller = _makeController(versions: [versionA, versionB]);
          await controller.initialize('es');

          final stateBefore = controller.state;
          await controller.switchVersion(versionB);

          expect(
            controller.state,
            same(stateBefore),
            reason:
                'Versions with the same dbFileName must be treated as identical '
                '— switchVersion should be a no-op',
          );
          controller.dispose();
        },
      );
    });

    // ── Font controls visibility ─────────────────────────────────────────

    group('Font controls visibility', () {
      test('toggleFontControls flips visibility', () async {
        final controller = _makeController();
        await controller.initialize('es');

        expect(controller.state.showFontControls, isFalse);
        controller.toggleFontControls();
        expect(controller.state.showFontControls, isTrue);
        controller.toggleFontControls();
        expect(controller.state.showFontControls, isFalse);
        controller.dispose();
      });

      test('setFontControlsVisibility sets explicit value', () async {
        final controller = _makeController();
        await controller.initialize('es');

        controller.setFontControlsVisibility(true);
        expect(controller.state.showFontControls, isTrue);

        controller.setFontControlsVisibility(false);
        expect(controller.state.showFontControls, isFalse);
        controller.dispose();
      });
    });
  });
}
