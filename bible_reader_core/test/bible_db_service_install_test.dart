@Tags(['unit', 'utils'])
library;

import 'dart:io';

import 'package:archive/archive.dart';
import 'package:bible_reader_core/src/bible_db_service.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
