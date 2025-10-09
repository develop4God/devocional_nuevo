import 'package:devocional_nuevo/models/bible_version.dart';
import 'package:devocional_nuevo/services/bible_db_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BibleVersion Model Tests', () {
    test('should create BibleVersion with all required fields', () {
      final version = BibleVersion(
        name: 'RVR1960',
        assetPath: 'assets/biblia/RVR1960.SQLite3',
        dbFileName: 'RVR1960.SQLite3',
      );

      expect(version.name, equals('RVR1960'));
      expect(version.assetPath, equals('assets/biblia/RVR1960.SQLite3'));
      expect(version.dbFileName, equals('RVR1960.SQLite3'));
      expect(version.service, isNull);
    });

    test('should create BibleVersion with service', () {
      final service = BibleDbService();
      final version = BibleVersion(
        name: 'RVR1960',
        assetPath: 'assets/biblia/RVR1960.SQLite3',
        dbFileName: 'RVR1960.SQLite3',
        service: service,
      );

      expect(version.service, equals(service));
    });

    test('should allow service to be assigned after creation', () {
      final version = BibleVersion(
        name: 'RVR1960',
        assetPath: 'assets/biblia/RVR1960.SQLite3',
        dbFileName: 'RVR1960.SQLite3',
      );

      expect(version.service, isNull);

      version.service = BibleDbService();
      expect(version.service, isNotNull);
    });
  });
}
