@Tags(['unit', 'utils'])
library;

import 'dart:io';

import 'package:archive/archive.dart';
import 'package:bible_reader_core/src/bible_db_service.dart';
import 'package:bible_reader_core/src/bible_version_registry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// Preferences store whose writes always fail.
class _FailingWriteStore extends SharedPreferencesStorePlatform {
  @override
  Future<Map<String, Object>> getAll() async => {};

  @override
  Future<bool> setValue(String valueType, String key, Object value) =>
      throw Exception('disk full');

  @override
  Future<bool> remove(String key) async => true;

  @override
  Future<bool> clear() async => true;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bible_db_install_test');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('BibleDbService.installFromGzipBytes', () {
    test('valid gzip bytes are decompressed and written to the final path',
        () async {
      final originalBytes = List<int>.generate(500, (i) => i % 256);
      final compressed = GZipEncoder().encode(originalBytes);

      final resultPath = await BibleDbService.installFromGzipBytes(
        compressed,
        'TEST_en.SQLite3',
        targetDir: tempDir,
      );

      expect(resultPath, '${tempDir.path}/TEST_en.SQLite3');
      final finalFile = File(resultPath);
      expect(finalFile.existsSync(), isTrue);
      expect(await finalFile.readAsBytes(), equals(originalBytes));

      // No leftover .part file
      expect(File('$resultPath.part').existsSync(), isFalse);
    });

    test('corrupt gzip bytes throw and leave no .part or final file behind',
        () async {
      final corruptBytes = <int>[1, 2, 3, 4, 5, 6, 7, 8];

      await expectLater(
        BibleDbService.installFromGzipBytes(
          corruptBytes,
          'CORRUPT_en.SQLite3',
          targetDir: tempDir,
        ),
        throwsA(anything),
      );

      final finalPath = '${tempDir.path}/CORRUPT_en.SQLite3';
      expect(File(finalPath).existsSync(), isFalse);
      expect(File('$finalPath.part').existsSync(), isFalse);
    });
  });

  group('BibleDbService.ensureInstalled', () {
    // A real bundled version, so the registry knows its shipped hash.
    const bundled = 'HERV_hi.SQLite3';
    final newAsset = List<int>.generate(300, (i) => (i * 7) % 256);
    late int assetLoads;

    Future<List<int>> loadAsset(String path) async {
      assetLoads++;
      return GZipEncoder().encode(newAsset);
    }

    setUp(() {
      assetLoads = 0;
      SharedPreferences.setMockInitialValues({});
    });

    Future<String> install(String dbName) => BibleDbService.ensureInstalled(
          'assets/biblia/$dbName',
          dbName,
          targetDir: tempDir,
          loadAsset: loadAsset,
        );

    test('re-extracts a bundled file extracted before hashes were stored',
        () async {
      File('${tempDir.path}/$bundled').writeAsBytesSync([9, 9, 9]);

      final path = await install(bundled);

      expect(File(path).readAsBytesSync(), newAsset);
      expect(
        await BibleVersionRegistry.storedHash(bundled),
        BibleVersionRegistry.bundledHash(bundled),
      );
    });

    test('leaves a bundled file alone once its hash is stored', () async {
      File('${tempDir.path}/$bundled').writeAsBytesSync([9, 9, 9]);
      await BibleVersionRegistry.saveStoredHash(bundled, 'downloaded');

      final path = await install(bundled);

      expect(assetLoads, 0);
      expect(File(path).readAsBytesSync(), [9, 9, 9]);
      expect(await BibleVersionRegistry.storedHash(bundled), 'downloaded');
    });

    test('extracts a missing bundled file and stores its hash', () async {
      final path = await install(bundled);

      expect(File(path).readAsBytesSync(), newAsset);
      expect(
        await BibleVersionRegistry.storedHash(bundled),
        BibleVersionRegistry.bundledHash(bundled),
      );
    });

    test('still installs the file when recording its hash fails', () async {
      SharedPreferencesStorePlatform.instance = _FailingWriteStore();
      SharedPreferences.resetStatic();

      final path = await install(bundled);

      expect(File(path).readAsBytesSync(), newAsset);
    });

    test('never re-extracts an existing non-bundled file', () async {
      File('${tempDir.path}/NGU_de.SQLite3').writeAsBytesSync([1, 2]);

      await install('NGU_de.SQLite3');

      expect(assetLoads, 0);
    });
  });
}
