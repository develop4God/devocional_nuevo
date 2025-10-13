import 'package:flutter_test/flutter_test.dart';

import '../../../bible_reader_core/lib/src/bible_db_service.dart';
import '../../../bible_reader_core/lib/src/bible_version.dart';

void main() {
  group('BibleVersion Model Tests', () {
    test('should create BibleVersion with all required fields', () {
      final version = BibleVersion(
        name: 'RVR1960',
        language: 'Español',
        languageCode: 'es',
        assetPath: 'assets/biblia/RVR1960_es.SQLite3',
        dbFileName: 'RVR1960_es.SQLite3',
      );

      expect(version.name, equals('RVR1960'));
      expect(version.language, equals('Español'));
      expect(version.languageCode, equals('es'));
      expect(version.assetPath, equals('assets/biblia/RVR1960_es.SQLite3'));
      expect(version.dbFileName, equals('RVR1960_es.SQLite3'));
      expect(version.service, isNull);
      expect(version.isDownloaded, isTrue); // default value
    });

    test('should create BibleVersion with service', () {
      final service = BibleDbService();
      final version = BibleVersion(
        name: 'RVR1960',
        language: 'Español',
        languageCode: 'es',
        assetPath: 'assets/biblia/RVR1960_es.SQLite3',
        dbFileName: 'RVR1960_es.SQLite3',
        service: service,
      );

      expect(version.service, equals(service));
    });

    test('should allow service to be assigned after creation', () {
      final version = BibleVersion(
        name: 'RVR1960',
        language: 'Español',
        languageCode: 'es',
        assetPath: 'assets/biblia/RVR1960_es.SQLite3',
        dbFileName: 'RVR1960_es.SQLite3',
      );

      expect(version.service, isNull);

      version.service = BibleDbService();
      expect(version.service, isNotNull);
    });

    test('should create BibleVersion with isDownloaded flag', () {
      final version = BibleVersion(
        name: 'KJV',
        language: 'English',
        languageCode: 'en',
        assetPath: 'assets/biblia/KJV_en.SQLite3',
        dbFileName: 'KJV_en.SQLite3',
        isDownloaded: false,
      );

      expect(version.isDownloaded, isFalse);
    });
  });
}
