import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/services/tts/bible_reader_tts_text_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BibleReaderTtsTextBuilder', () {
    test('build returns empty string when verses are empty', () {
      const state = BibleReaderState(
        verses: [],
        selectedBookName: 'Gen',
        selectedChapter: 1,
      );

      expect(BibleReaderTtsTextBuilder.build(state), isEmpty);
    });

    test('build includes book name and chapter header', () {
      final state = BibleReaderState(
        verses: [
          {'verse': 1, 'text': 'In the beginning God created.'},
        ],
        books: [
          {'short_name': 'Gen', 'long_name': 'Genesis'},
        ],
        selectedBookName: 'Gen',
        selectedChapter: 1,
      );

      final result = BibleReaderTtsTextBuilder.build(state);
      expect(result, contains('Genesis 1'));
      expect(result, contains('In the beginning God created.'));
    });

    test('build concatenates multiple verses', () {
      final state = BibleReaderState(
        verses: [
          {'verse': 1, 'text': 'Verse one text.'},
          {'verse': 2, 'text': 'Verse two text.'},
          {'verse': 3, 'text': 'Verse three text.'},
        ],
        books: [
          {'short_name': 'Exo', 'long_name': 'Exodus'},
        ],
        selectedBookName: 'Exo',
        selectedChapter: 3,
      );

      final result = BibleReaderTtsTextBuilder.build(state);
      expect(result, contains('Exodus 3'));
      expect(result, contains('Verse one text.'));
      expect(result, contains('Verse two text.'));
      expect(result, contains('Verse three text.'));
    });

    test('build cleans HTML tags from verse text', () {
      final state = BibleReaderState(
        verses: [
          {'verse': 1, 'text': '<pb/>In the <f>beginning</f> God created.'},
        ],
        books: [
          {'short_name': 'Gen', 'long_name': 'Genesis'},
        ],
        selectedBookName: 'Gen',
        selectedChapter: 1,
      );

      final result = BibleReaderTtsTextBuilder.build(state);
      expect(result, isNot(contains('<pb/>')));
      expect(result, isNot(contains('<f>')));
      expect(result, contains('In the beginning God created.'));
    });

    test('build cleans bracketed references from verse text', () {
      final state = BibleReaderState(
        verses: [
          {'verse': 1, 'text': 'God said [1] let there be light [a].'},
        ],
        books: [
          {'short_name': 'Gen', 'long_name': 'Genesis'},
        ],
        selectedBookName: 'Gen',
        selectedChapter: 1,
      );

      final result = BibleReaderTtsTextBuilder.build(state);
      expect(result, isNot(contains('[1]')));
      expect(result, isNot(contains('[a]')));
      expect(result, contains('God said  let there be light'));
    });

    test('build handles missing book gracefully', () {
      final state = BibleReaderState(
        verses: [
          {'verse': 1, 'text': 'Text here.'},
        ],
        books: [],
        selectedBookName: 'Unknown',
        selectedChapter: 5,
      );

      final result = BibleReaderTtsTextBuilder.build(state);
      // When books list is empty, no header is produced — only verse text
      expect(result, contains('Text here.'));
      expect(result, isNotEmpty);
    });

    test('build uses selectedBookName when book not found in list', () {
      final state = BibleReaderState(
        verses: [
          {'verse': 1, 'text': 'Text here.'},
        ],
        books: [
          {'short_name': 'Other', 'long_name': 'Other Book'},
        ],
        selectedBookName: 'Unknown',
        selectedChapter: 5,
      );

      final result = BibleReaderTtsTextBuilder.build(state);
      // Falls back to selectedBookName when book not found
      expect(result, contains('Unknown 5'));
      expect(result, contains('Text here.'));
    });

    test('build handles null verse text', () {
      final state = BibleReaderState(
        verses: [
          {'verse': 1, 'text': null},
          {'verse': 2, 'text': 'Valid text.'},
        ],
        books: [
          {'short_name': 'Gen', 'long_name': 'Genesis'},
        ],
        selectedBookName: 'Gen',
        selectedChapter: 1,
      );

      final result = BibleReaderTtsTextBuilder.build(state);
      expect(result, contains('Valid text.'));
    });

    group('buildFromSelectedVerses', () {
      test('returns empty string when no verses selected', () {
        final state = BibleReaderState(
          verses: [
            {'verse': 1, 'text': 'Text.'},
          ],
          books: [
            {'short_name': 'Gen', 'long_name': 'Genesis'},
          ],
          selectedBookName: 'Gen',
          selectedChapter: 1,
        );

        final result =
            BibleReaderTtsTextBuilder.buildFromSelectedVerses(state, {});
        expect(result, isEmpty);
      });

      test('only includes selected verses', () {
        final state = BibleReaderState(
          verses: [
            {'verse': 1, 'text': 'First verse.'},
            {'verse': 2, 'text': 'Second verse.'},
            {'verse': 3, 'text': 'Third verse.'},
          ],
          books: [
            {'short_name': 'Psa', 'long_name': 'Psalms'},
          ],
          selectedBookName: 'Psa',
          selectedChapter: 23,
        );

        final result = BibleReaderTtsTextBuilder.buildFromSelectedVerses(
          state,
          {'Psa|23|1', 'Psa|23|3'},
        );

        expect(result, contains('Psalms 23'));
        expect(result, contains('First verse.'));
        expect(result, isNot(contains('Second verse.')));
        expect(result, contains('Third verse.'));
      });
    });
  });
}
