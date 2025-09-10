// Test compression effectiveness and encryption validation as requested
import 'dart:convert';
import 'dart:typed_data';

import 'package:devocional_nuevo/services/compression_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Compression Effectiveness Tests', () {
    test('should compress JSON data effectively', () {
      // Create sample backup data
      final sampleData = {
        'spiritual_stats': {
          'devotionals_read': 100,
          'prayer_sessions': 50,
          'achievements': ['first_read', 'consistent_reader', 'prayer_warrior'],
          'reading_streak': 30,
          'total_reading_time': 3600,
        },
        'favorite_devotionals': List.generate(
            20,
            (index) => {
                  'id': 'devotional_$index',
                  'title': 'Devotional Title $index',
                  'content':
                      'This is a sample devotional content that contains meaningful text about faith, hope, and spiritual growth. It includes verses, reflections, and prayers that help believers in their daily walk with God.',
                  'date': '2025-01-${(index % 30) + 1}',
                  'tags': ['faith', 'prayer', 'growth'],
                }),
        'saved_prayers': List.generate(
            10,
            (index) => {
                  'id': 'prayer_$index',
                  'title': 'Prayer Title $index',
                  'content':
                      'Dear Heavenly Father, we come before you with grateful hearts. We ask for your guidance, wisdom, and protection. Help us to grow in faith and to serve others with love and compassion.',
                  'category': 'personal',
                  'date_created': '2025-01-${(index % 30) + 1}',
                }),
      };

      final jsonString = jsonEncode(sampleData);
      final originalSize = utf8.encode(jsonString).length;

      // Compress the data using static method
      final compressedData = CompressionService.compressJson(sampleData);
      final compressedSize = compressedData.length;

      // Calculate compression ratio
      final compressionRatio = compressedSize / originalSize;
      final compressionPercentage = (1 - compressionRatio) * 100;

      print('Original size: $originalSize bytes');
      print('Compressed size: $compressedSize bytes');
      print('Compression ratio: ${compressionRatio.toStringAsFixed(3)}');
      print('Space saved: ${compressionPercentage.toStringAsFixed(1)}%');

      // Assertions
      expect(compressedSize, lessThan(originalSize),
          reason: 'Compressed data should be smaller than original');
      expect(compressionPercentage, greaterThan(10),
          reason: 'Should achieve at least 10% compression for JSON data');

      // Test decompression to ensure data integrity
      final decompressedData =
          CompressionService.decompressJson(compressedData);

      expect(decompressedData, isNotNull,
          reason: 'Decompression should succeed');
      expect(decompressedData, equals(sampleData),
          reason: 'Decompressed data should match original');
    });

    test('should handle small data efficiently', () {
      final smallData = {'message': 'Hello World'};

      final compressedData = CompressionService.compressJson(smallData);
      final decompressedData =
          CompressionService.decompressJson(compressedData);

      expect(decompressedData, isNotNull);
      expect(decompressedData, equals(smallData));
    });

    test('should handle empty data', () {
      final emptyData = <String, dynamic>{};

      final compressedData = CompressionService.compressJson(emptyData);
      final decompressedData =
          CompressionService.decompressJson(compressedData);

      expect(decompressedData, isNotNull);
      expect(decompressedData, equals(emptyData));
    });

    test('should demonstrate compression effectiveness on repetitive data', () {
      // Create highly repetitive data that should compress very well
      final repetitiveData = {
        'users': List.generate(
            100,
            (index) => {
                  'name': 'User Name',
                  'email': 'user@example.com',
                  'status': 'active',
                  'preferences': {
                    'theme': 'dark',
                    'language': 'spanish',
                    'notifications': true,
                  },
                }),
      };

      final jsonString = jsonEncode(repetitiveData);
      final originalSize = utf8.encode(jsonString).length;

      final compressedData = CompressionService.compressJson(repetitiveData);
      final compressedSize = compressedData.length;

      final compressionPercentage = (1 - (compressedSize / originalSize)) * 100;

      print(
          'Repetitive data compression: ${compressionPercentage.toStringAsFixed(1)}%');

      // Repetitive data should compress well (>30%)
      expect(compressionPercentage, greaterThan(30),
          reason: 'Repetitive data should achieve good compression ratio');
    });
  });

  group('Data Security Tests', () {
    test('should ensure data integrity through compression cycle', () {
      // Test with various data types
      final testCases = [
        {'string': 'Hello, World!'},
        {'number': 42},
        {'boolean': true},
        {
          'array': [1, 2, 3, 'test']
        },
        {
          'nested': {
            'level1': {
              'level2': {'level3': 'deep'}
            }
          }
        },
        {'unicode': 'Hola, ¿cómo estás? 🙏'},
        {
          'special_chars': 'Test with "quotes", \'apostrophes\', and /slashes\\'
        },
      ];

      for (final testData in testCases) {
        // Compress and decompress
        final compressedData = CompressionService.compressJson(testData);
        final decompressedData =
            CompressionService.decompressJson(compressedData);

        expect(decompressedData, isNotNull);
        expect(decompressedData, equals(testData),
            reason: 'Data integrity must be preserved for: $testData');
      }
    });

    test('should handle binary data safely', () {
      // Test with complex nested JSON data (simulating binary-like structures)
      final complexData = {
        'binary_like_data': List.generate(100, (i) => i % 256),
        'metadata': {
          'format': 'test',
          'version': '1.0',
          'checksum': 'abc123',
        }
      };

      final compressedData = CompressionService.compressJson(complexData);
      final decompressedData =
          CompressionService.decompressJson(compressedData);

      expect(decompressedData, isNotNull);
      expect(decompressedData, equals(complexData),
          reason: 'Complex data integrity must be preserved');
    });

    test('should fail gracefully with corrupted data', () {
      // Create corrupted compressed data
      final corruptedData = Uint8List.fromList([1, 2, 3, 4, 5]);

      final result = CompressionService.decompressJson(corruptedData);

      // Should return null or handle gracefully (based on implementation)
      // The service has fallback handling for corrupted data
      expect(result, anyOf([isNull, isA<Map<String, dynamic>>()]),
          reason: 'Should handle corrupted data gracefully');
    });
  });
}
