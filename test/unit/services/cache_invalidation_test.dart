@Tags(['unit', 'services'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:devocional_nuevo/services/cache_metadata_service.dart';
import 'package:devocional_nuevo/services/devocional_index_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
  });

  // ─────────────────────────────────────────────────────────────────────────
  // DevocionalIndexService
  // ─────────────────────────────────────────────────────────────────────────
  group('DevocionalIndexService', () {
    late MockHttpClient mockClient;
    late DevocionalIndexService service;

    setUp(() {
      mockClient = MockHttpClient();
      service = DevocionalIndexService(mockClient);
    });

    final validIndex = {
      'schema_version': 1,
      'updated_at': '2026-03-03',
      'files': {
        'es': {
          'RVR1960': {'2025': '2026-03-03', '2026': '2026-03-03'},
          'NVI': {'2025': '2026-03-03'},
        },
        'en': {
          'KJV': {'2025': '2026-03-03'},
        },
      },
    };

    // AC1 — index fetched on every init
    test('returns parsed index on HTTP 200', () async {
      when(() => mockClient.get(any()))
          .thenAnswer((_) async => http.Response(json.encode(validIndex), 200));

      final result = await service.fetchIndex();

      expect(result, isNotNull);
      expect(result!['schema_version'], equals(1));
      expect(result['updated_at'], equals('2026-03-03'));
    });

    // AC4 — offline / index unreachable
    test('returns null on HTTP 404', () async {
      when(() => mockClient.get(any()))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      final result = await service.fetchIndex();
      expect(result, isNull);
    });

    // AC4 — network exception
    test('returns null on network exception', () async {
      when(() => mockClient.get(any()))
          .thenThrow(const SocketException('no internet'));

      final result = await service.fetchIndex();
      expect(result, isNull);
    });

    // AC7 — unknown schema_version
    test('returns null when schema_version is unknown (> 1)', () async {
      final futureIndex = {
        'schema_version': 2,
        'updated_at': '2027-01-01',
        'files': {},
      };
      when(() => mockClient.get(any()))
          .thenAnswer((_) async => http.Response(json.encode(futureIndex), 200));

      final result = await service.fetchIndex();
      expect(result, isNull);
    });

    // getFileDate — normal lookup
    test('getFileDate returns correct date for existing key', () {
      final result = service.getFileDate(validIndex, 'es', 'RVR1960', '2025');
      expect(result, equals('2026-03-03'));
    });

    // AC6 — missing language key → null
    test('getFileDate returns null for missing language', () {
      final result = service.getFileDate(validIndex, 'hi', 'HBSI2002', '2025');
      expect(result, isNull);
    });

    // AC6 — missing version key → null
    test('getFileDate returns null for missing version', () {
      final result = service.getFileDate(validIndex, 'en', 'NIV', '2025');
      expect(result, isNull);
    });

    // AC6 — missing year key → null
    test('getFileDate returns null for missing year', () {
      final result = service.getFileDate(validIndex, 'en', 'KJV', '2027');
      expect(result, isNull);
    });

    // getFileDate — empty index → null, no crash
    test('getFileDate returns null on empty index without throwing', () {
      final result = service.getFileDate({}, 'es', 'RVR1960', '2025');
      expect(result, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // CacheMetadataService
  // ─────────────────────────────────────────────────────────────────────────
  group('CacheMetadataService', () {
    late CacheMetadataService service;
    late Directory tempDir;

    setUp(() async {
      service = CacheMetadataService();
      tempDir = await Directory.systemTemp.createTemp('cache_meta_test_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    // Helper: full path inside tempDir
    String contentPath(String filename) => '${tempDir.path}/$filename';

    // AC3 — sidecar missing → null
    test('readManifestDate returns null when sidecar absent', () async {
      final path = contentPath('devocional_2025_es.json');
      final result = await service.readManifestDate(path);
      expect(result, isNull);
    });

    // AC2 — write then read round-trip
    test('writeMetadata then readManifestDate returns the same date', () async {
      final path = contentPath('devocional_2025_es_RVR1960.json');
      await service.writeMetadata(path, '2026-03-15');

      final result = await service.readManifestDate(path);
      expect(result, equals('2026-03-15'));
    });

    // sidecar schema fields present
    test('written sidecar contains all required fields', () async {
      final path = contentPath('devocional_2026_en_KJV.json');
      await service.writeMetadata(path, '2026-03-10');

      final sidecarPath =
          '${path.substring(0, path.length - 5)}.meta.json';
      final content = await File(sidecarPath).readAsString();
      final parsed = json.decode(content) as Map<String, dynamic>;

      expect(parsed.containsKey('cached_at'), isTrue);
      expect(parsed.containsKey('manifest_date'), isTrue);
      expect(parsed.containsKey('schema_version'), isTrue);
      expect(parsed['manifest_date'], equals('2026-03-10'));
      expect(parsed['schema_version'], equals(1));
    });

    // es/RVR1960 backward compat filename
    test('sidecar path derived correctly for es backward-compat filename', () async {
      final path = contentPath('devocional_2025_es.json');
      await service.writeMetadata(path, '2026-03-03');

      final sidecarPath = contentPath('devocional_2025_es.meta.json');
      expect(await File(sidecarPath).exists(), isTrue);
    });

    // Overwrite sidecar updates date
    test('writeMetadata overwrites existing sidecar with new date', () async {
      final path = contentPath('devocional_2025_es_NVI.json');
      await service.writeMetadata(path, '2026-03-03');
      await service.writeMetadata(path, '2026-03-15');

      final result = await service.readManifestDate(path);
      expect(result, equals('2026-03-15'));
    });

    // Corrupt sidecar → null, no crash
    test('readManifestDate returns null for corrupt sidecar without throwing',
        () async {
      final path = contentPath('devocional_2025_es_NVI.json');
      final sidecarPath =
          '${path.substring(0, path.length - 5)}.meta.json';
      await File(sidecarPath).writeAsString('NOT_VALID_JSON{{{');

      final result = await service.readManifestDate(path);
      expect(result, isNull);
    });
  });
}
