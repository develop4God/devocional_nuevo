@Tags(['critical', 'unit', 'services'])
library;

// test/critical_coverage/compression_service_working_test.dart
// High-value tests for CompressionService - real user flows and edge cases

import 'dart:convert';
import 'dart:typed_data';

import 'package:devocional_nuevo/services/compression_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CompressionService Critical Tests', () {
    // SCENARIO 1: User creates backup - data compressed successfully
    test('compressJson should compress valid JSON data', () {
      final testData = {
        'devocionales': [
          {'id': 'dev1', 'title': 'Test Devotional 1'},
          {'id': 'dev2', 'title': 'Test Devotional 2'},
        ],
        'prayers': [
          {'id': 'prayer1', 'text': 'Test prayer content'},
        ],
        'settings': {'language': 'es', 'theme': 'dark'},
      };

      final compressed = CompressionService.compressJson(testData);

      expect(compressed, isNotNull);
      expect(compressed, isA<Uint8List>());
      expect(compressed.length, greaterThan(0));
      // Compressed should be smaller than original JSON
      final originalSize = utf8.encode(json.encode(testData)).length;
      expect(compressed.length, lessThan(originalSize));
    });

    // SCENARIO 2: User restores backup - data decompressed successfully
    test('decompressJson should decompress data correctly', () {
      final testData = {
        'devocionales': [
          {'id': 'dev1', 'title': 'Test Devotional'},
        ],
        'timestamp': '2025-01-01T00:00:00Z',
      };

      final compressed = CompressionService.compressJson(testData);
      final decompressed = CompressionService.decompressJson(compressed);

      expect(decompressed, isNotNull);
      expect(decompressed, equals(testData));
    });

    // SCENARIO 3: Backup contains large amount of data
    test('compressJson handles large data efficiently', () {
      // Create large test data simulating real user data
      final largePrayers = List.generate(
        100,
        (i) => {
          'id': 'prayer_$i',
          'text': 'This is prayer number $i with some additional text ' * 10,
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      final largeData = {
        'prayers': largePrayers,
        'devocionales': List.generate(
          50,
          (i) => {'id': 'dev_$i', 'reflexion': 'Long reflection text ' * 20},
        ),
      };

      final compressed = CompressionService.compressJson(largeData);
      final originalSize = utf8.encode(json.encode(largeData)).length;

      // Should achieve significant compression on repetitive text
      expect(compressed.length, lessThan(originalSize * 0.5));

      // Should decompress correctly
      final decompressed = CompressionService.decompressJson(compressed);
      expect(decompressed, equals(largeData));
    });

    // SCENARIO 4: Handle corrupted backup data
    test('decompressJson handles corrupted data gracefully', () {
      final corruptedData = Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);

      final result = CompressionService.decompressJson(corruptedData);

      expect(result, isNull);
    });

    // SCENARIO 5: Handle uncompressed JSON data (backward compatibility)
    test('decompressJson handles uncompressed JSON as fallback', () {
      final jsonData = {'test': 'value', 'number': 42};
      final uncompressedBytes = Uint8List.fromList(
        utf8.encode(json.encode(jsonData)),
      );

      final result = CompressionService.decompressJson(uncompressedBytes);

      expect(result, isNotNull);
      expect(result, equals(jsonData));
    });

    // SCENARIO 6: Compression ratio calculation for user feedback
    test('getCompressionRatio calculates correctly', () {
      expect(CompressionService.getCompressionRatio(1000, 300), equals(70.0));
      expect(CompressionService.getCompressionRatio(100, 50), equals(50.0));
      expect(CompressionService.getCompressionRatio(0, 0), equals(0.0));
      expect(CompressionService.getCompressionRatio(100, 100), equals(0.0));
    });

    // SCENARIO 7: Estimate compressed size for storage quota warnings
    test('estimateCompressedSize provides reasonable estimate', () {
      final estimate = CompressionService.estimateCompressedSize(1000);
      expect(estimate, equals(300)); // 30% of original
    });

    // SCENARIO 8: Small file detection to skip unnecessary compression
    test('shouldCompress returns false for small files', () {
      expect(CompressionService.shouldCompress(500), isFalse);
      expect(CompressionService.shouldCompress(1024), isFalse);
      expect(CompressionService.shouldCompress(1025), isTrue);
      expect(CompressionService.shouldCompress(10000), isTrue);
    });

    // SCENARIO 9: Archive multiple files (multi-device sync)
    test('createArchive creates valid ZIP archive', () {
      final files = {
        'prayers.json': {
          'prayers': ['p1', 'p2'],
        },
        'settings.json': {'theme': 'dark'},
        'stats.json': {'total': 100},
      };

      final archive = CompressionService.createArchive(files);

      expect(archive, isNotNull);
      expect(archive.length, greaterThan(0));
    });

    // SCENARIO 10: Extract archive for restore
    test('extractArchive extracts files correctly', () {
      final files = {
        'data1.json': {'key1': 'value1'},
        'data2.json': {'key2': 'value2'},
      };

      final archive = CompressionService.createArchive(files);
      final extracted = CompressionService.extractArchive(archive);

      expect(extracted, isNotNull);
      expect(extracted!.keys.length, equals(2));
      expect(extracted['data1.json'], equals({'key1': 'value1'}));
      expect(extracted['data2.json'], equals({'key2': 'value2'}));
    });

    // SCENARIO 11: Handle empty data edge case
    test('compressJson handles empty map', () {
      final emptyData = <String, dynamic>{};

      final compressed = CompressionService.compressJson(emptyData);
      final decompressed = CompressionService.decompressJson(compressed);

      expect(decompressed, equals(emptyData));
    });

    // SCENARIO 12: Handle special characters in data (internationalization)
    test('compressJson handles Unicode and special characters', () {
      final internationalData = {
        'spanish': 'Reflexión espiritual con ñ y á',
        'portuguese': 'Devoção e bênção',
        'japanese': '日本語テキスト',
        'french': 'Réflexion avec accents',
        'emojis': '🙏 ✝️ 📖',
      };

      final compressed = CompressionService.compressJson(internationalData);
      final decompressed = CompressionService.decompressJson(compressed);

      expect(decompressed, equals(internationalData));
    });

    // SCENARIO 13: Nested data structures
    test('compressJson handles deeply nested structures', () {
      final nestedData = {
        'level1': {
          'level2': {
            'level3': {
              'level4': {
                'data': [1, 2, 3],
              },
            },
          },
        },
      };

      final compressed = CompressionService.compressJson(nestedData);
      final decompressed = CompressionService.decompressJson(compressed);

      expect(decompressed, equals(nestedData));
    });

    // SCENARIO 14: Archive with corrupted data handling
    test('extractArchive handles corrupted archive gracefully', () {
      final corruptedArchive = Uint8List.fromList([1, 2, 3, 4, 5]);

      final result = CompressionService.extractArchive(corruptedArchive);

      // Implementation returns empty map or null on corruption
      expect(result == null || result.isEmpty, isTrue);
    });

    // SCENARIO 15: Real-world backup data simulation
    test('handles realistic backup data structure', () {
      final realisticBackup = {
        'version': '1.0.0',
        'timestamp': DateTime.now().toIso8601String(),
        'user_data': {
          'spiritual_stats': {
            'total_read': 150,
            'current_streak': 7,
            'longest_streak': 30,
            'favorites_count': 25,
          },
          'prayers': List.generate(
            30,
            (i) => {
              'id': 'prayer_$i',
              'text': 'Test prayer $i',
              'answered': i % 3 == 0,
              'created_at':
                  DateTime.now().subtract(Duration(days: i)).toIso8601String(),
            },
          ),
          'thanksgivings': List.generate(
            20,
            (i) => {'id': 'thanks_$i', 'text': 'Thanksgiving $i'},
          ),
        },
        'settings': {
          'language': 'es',
          'bible_version': 'RVR1960',
          'notifications_enabled': true,
          'daily_reminder_time': '08:00',
        },
      };

      final compressed = CompressionService.compressJson(realisticBackup);
      final originalSize = utf8.encode(json.encode(realisticBackup)).length;

      // Check compression is effective
      final ratio = CompressionService.getCompressionRatio(
        originalSize,
        compressed.length,
      );
      expect(ratio, greaterThan(30)); // At least 30% compression

      // Verify data integrity
      final decompressed = CompressionService.decompressJson(compressed);
      expect(decompressed, equals(realisticBackup));
    });
  });
}
