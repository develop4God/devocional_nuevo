import 'package:bible_reader_core/src/bible_canon_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BibleCanonFilter', () {
    group('isCanonical', () {
      test('returns true for all 66 canonical book_numbers', () {
        const canonical = [
          10,
          20,
          30,
          40,
          50,
          60,
          70,
          80,
          90,
          100,
          110,
          120,
          130,
          140,
          150,
          160,
          190,
          220,
          230,
          240,
          250,
          260,
          290,
          300,
          310,
          330,
          340,
          350,
          360,
          370,
          380,
          390,
          400,
          410,
          420,
          430,
          440,
          450,
          460,
          470,
          480,
          490,
          500,
          510,
          520,
          530,
          540,
          550,
          560,
          570,
          580,
          590,
          600,
          610,
          620,
          630,
          640,
          650,
          660,
          670,
          680,
          690,
          700,
          710,
          720,
          730,
        ];
        expect(canonical, hasLength(66));
        for (final n in canonical) {
          expect(BibleCanonFilter.isCanonical(n), isTrue,
              reason: 'book_number $n should be canonical');
        }
      });

      test('returns false for MBB05 deuterocanonical book_numbers', () {
        // Actual non-canonical book_numbers found in MBB05_fil.SQLite3
        const mbb05Deuterocanonical = [
          170,
          180,
          192,
          270,
          280,
          315,
          320,
          323,
          325,
          345,
          462,
          464,
        ];
        for (final n in mbb05Deuterocanonical) {
          expect(BibleCanonFilter.isCanonical(n), isFalse,
              reason: 'book_number $n (MBB05) should not be canonical');
        }
      });

      test('returns false for LU17 deuterocanonical book_numbers', () {
        // Actual non-canonical book_numbers found in LU17_de.SQLite3
        const lu17Deuterocanonical = [
          170,
          180,
          192,
          270,
          280,
          320,
          341,
          462,
          464,
          790,
        ];
        for (final n in lu17Deuterocanonical) {
          expect(BibleCanonFilter.isCanonical(n), isFalse,
              reason: 'book_number $n (LU17) should not be canonical');
        }
      });
    });

    group('filterCanonical', () {
      test('returns all books unchanged for a clean 66-book DB', () {
        // Replace with actual canonical numbers for first 3 + last
        final books = [
          {'book_number': 10, 'long_name': 'Genesis'},
          {'book_number': 20, 'long_name': 'Exodus'},
          {'book_number': 730, 'long_name': 'Revelation'},
        ];
        final result = BibleCanonFilter.filterCanonical(books);
        expect(result, hasLength(3));
      });

      test('strips deuterocanonical rows from MBB05-style input', () {
        final mixed = [
          {'book_number': 160, 'long_name': 'Nehemias'},
          {'book_number': 170, 'long_name': 'Tobit'}, // deuterocanonical
          {'book_number': 180, 'long_name': 'Judith'}, // deuterocanonical
          {'book_number': 190, 'long_name': 'Ester'},
          {
            'book_number': 192,
            'long_name': 'Ester (extended)'
          }, // deuterocanonical
        ];
        final result = BibleCanonFilter.filterCanonical(mixed);
        expect(result, hasLength(2));
        expect(result.map((b) => b['book_number']), containsAll([160, 190]));
        expect(result.map((b) => b['book_number']), isNot(contains(170)));
        expect(result.map((b) => b['book_number']), isNot(contains(180)));
        expect(result.map((b) => b['book_number']), isNot(contains(192)));
      });

      test('returns empty list for empty input', () {
        expect(BibleCanonFilter.filterCanonical([]), isEmpty);
      });
    });
  });
}
