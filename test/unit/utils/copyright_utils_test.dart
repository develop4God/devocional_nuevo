import 'package:devocional_nuevo/utils/copyright_utils.dart';
import 'package:test/test.dart';

void main() {
  group('CopyrightUtils', () {
    test('returns French BDS copyright disclaimer', () {
      final text = CopyrightUtils.getCopyrightText('fr', 'BDS');
      expect(text, contains('Bible du Semeur'));
    });

    test('returns Hindi HIOV copyright disclaimer', () {
      final text =
          CopyrightUtils.getCopyrightText('hi', 'पवित्र बाइबिल (ओ.वी.)');
      expect(text, contains('हिन्दी ओ.वी. संस्करण'));
      expect(text, contains('HIOV'));
    });

    test('returns Hindi HERV copyright disclaimer (fixed from ERV)', () {
      // Test with database file name
      final text = CopyrightUtils.getCopyrightText('hi', 'HERV_hi.SQLite3');
      expect(text, contains('आसान हिंदी संस्करण'));
      expect(text, contains('HERV')); // Fixed: now shows HERV instead of ERV
      expect(text, contains('Bible League International'));
      expect(text, contains('1995, 2010'));

      // Test with abbreviation code
      final textAbbr = CopyrightUtils.getCopyrightText('hi', 'HERV');
      expect(textAbbr, contains('HERV'));
      expect(textAbbr, contains('Bible League International'));
    });

    test('Hindi HIOV abbreviation also works', () {
      final text = CopyrightUtils.getCopyrightText('hi', 'HIOV');
      expect(text, contains('HIOV'));
      expect(text, contains('Bible Society of India'));
    });

    test('falls back to default when version missing', () {
      final text = CopyrightUtils.getCopyrightText('fr', 'UNKNOWN');
      expect(text, anyOf(contains('Louis Segond'), contains('Bible')));
    });

    test('returns German LU17 copyright disclaimer', () {
      final text = CopyrightUtils.getCopyrightText('de', 'LU17');
      expect(text, contains('Lutherbibel'));
      expect(text, contains('Deutsche Bibelgesellschaft'));
    });

    test('returns German SCH2000 copyright disclaimer', () {
      final text = CopyrightUtils.getCopyrightText('de', 'SCH2000');
      expect(text, contains('Schlachter 2000'));
      expect(text, contains('Genfer Bibelgesellschaft'));
    });

    test('returns German copyright with database filename', () {
      final text = CopyrightUtils.getCopyrightText('de', 'LU17_de.SQLite3');
      expect(text, contains('Lutherbibel'));
      expect(text, contains('2016'));
    });

    test('returns German copyright with display name', () {
      final text =
          CopyrightUtils.getCopyrightText('de', 'Lutherbibel 2017 (LU17)');
      expect(text, contains('Deutsche Bibelgesellschaft'));
    });

    test('German falls back to default when version missing', () {
      final text = CopyrightUtils.getCopyrightText('de', 'UNKNOWN');
      expect(text, contains('Lutherbibel'));
    });

    test('fallback to en when language missing', () {
      final text = CopyrightUtils.getCopyrightText('xx', 'KJV');
      expect(text, contains('King James'));
    });

    test('returns Filipino ASND copyright disclaimer', () {
      final text = CopyrightUtils.getCopyrightText('fil', 'ASND');
      expect(text, contains('Ang Salita ng Dios'));
      expect(text, contains('Biblica'));
    });

    test('returns Filipino MBB05 copyright disclaimer', () {
      final text = CopyrightUtils.getCopyrightText('fil', 'MBB05');
      expect(text, contains('Magandang Balita Biblia'));
      expect(text, contains('Philippine Bible Society'));
    });

    test('returns Filipino ADB copyright disclaimer', () {
      final text = CopyrightUtils.getCopyrightText('fil', 'ADB_fil.SQLite3');
      expect(text, contains('Ang Dating Biblia'));
      expect(text, contains('Philippine Bible Society'));
    });

    test('returns Filipino copyright with database filename ASND', () {
      final text = CopyrightUtils.getCopyrightText('fil', 'ASND_fil.SQLite3');
      expect(text, contains('Ang Salita ng Dios'));
      expect(text, contains('Biblica'));
    });

    test('returns Filipino copyright with database filename MBB05', () {
      final text = CopyrightUtils.getCopyrightText('fil', 'MBB05_fil.SQLite3');
      expect(text, contains('Magandang Balita Biblia'));
      expect(text, contains('Philippine Bible Society'));
    });

    test('returns Filipino copyright with database filename ADB', () {
      final text = CopyrightUtils.getCopyrightText('fil', 'ADB_fil.SQLite3');
      expect(text, contains('Ang Dating Biblia'));
      expect(text, contains('Philippine Bible Society'));
    });

    test('returns Filipino copyright with display name ASND', () {
      final text =
          CopyrightUtils.getCopyrightText('fil', 'Ang Salita ng Dios (ASND)');
      expect(text, contains('Biblica'));
    });

    test('returns Filipino copyright with display name MBB05', () {
      final text = CopyrightUtils.getCopyrightText(
          'fil', 'Magandang Balita Biblia (MBB05)');
      expect(text, contains('Philippine Bible Society'));
    });

    test('returns Filipino copyright with display name ADB', () {
      final text =
          CopyrightUtils.getCopyrightText('fil', 'Ang Dating Biblia (ADB)');
      expect(text, contains('Philippine Bible Society'));
    });

    test('Filipino falls back to MBB05 default when version missing', () {
      final text = CopyrightUtils.getCopyrightText('fil', 'UNKNOWN');
      expect(text, contains('Magandang Balita Biblia'));
    });
  });
}
