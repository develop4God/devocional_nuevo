// test/unit/services/compression_service_test.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:devocional_nuevo/services/compression_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CompressionService Tests', () {
    group('compressJson', () {
      test('should compress simple JSON data successfully', () {
        // Arrange
        final testData = {
          'key1': 'value1',
          'key2': 'value2',
          'number': 123,
          'boolean': true,
        };

        // Act
        final compressedData = CompressionService.compressJson(testData);

        // Assert
        expect(compressedData, isA<Uint8List>());
        expect(compressedData.length, greaterThan(0));

        // Compressed data should typically be smaller than original for larger datasets
        // For small datasets, compression might be larger due to overhead
        final originalJsonString = json.encode(testData);
        final originalBytes = utf8.encode(originalJsonString).length;
        expect(
            compressedData.length,
            lessThanOrEqualTo(
                originalBytes * 2)); // Allow for compression overhead
      });

      test('should compress complex nested JSON data', () {
        // Arrange
        final testData = {
          'user': {
            'id': 123,
            'name': 'Test User',
            'preferences': {
              'theme': 'dark',
              'language': 'es',
              'notifications': true,
            },
            'history': List.generate(
                50,
                (i) => {
                      'date': '2023-01-${i + 1}',
                      'action': 'read_devotional_$i',
                      'duration': i * 2,
                    }),
          },
          'stats': {
            'total_readings': 150,
            'streak_days': 30,
            'favorite_themes': ['faith', 'hope', 'love'],
          },
        };

        // Act
        final compressedData = CompressionService.compressJson(testData);

        // Assert
        expect(compressedData, isA<Uint8List>());
        expect(compressedData.length, greaterThan(0));

        // For larger datasets, compression should be effective
        final originalJsonString = json.encode(testData);
        final originalBytes = utf8.encode(originalJsonString).length;
        expect(originalBytes,
            greaterThan(1000)); // Ensure we have substantial data
        expect(compressedData.length,
            lessThan(originalBytes)); // Should be compressed
      });

      test('should handle empty JSON data', () {
        // Arrange
        final testData = <String, dynamic>{};

        // Act
        final compressedData = CompressionService.compressJson(testData);

        // Assert
        expect(compressedData, isA<Uint8List>());
        expect(compressedData.length, greaterThan(0));
      });

      test('should handle JSON data with null values', () {
        // Arrange
        final testData = {
          'key1': 'value1',
          'key2': null,
          'key3': {
            'nested': null,
            'valid': 'data',
          },
        };

        // Act
        final compressedData = CompressionService.compressJson(testData);

        // Assert
        expect(compressedData, isA<Uint8List>());
        expect(compressedData.length, greaterThan(0));
      });

      test('should handle JSON data with special characters and Unicode', () {
        // Arrange
        final testData = {
          'spanish': 'Hola, ¿cómo estás?',
          'french': 'Bonjour, ça va?',
          'emoji': '😊 🙏 ❤️',
          'special': '!@#\$%^&*()_+-={}[]|\\:";\'<>?,./~`',
          'unicode': 'This has unicode: \u00A9 \u00AE \u2122',
        };

        // Act
        final compressedData = CompressionService.compressJson(testData);

        // Assert
        expect(compressedData, isA<Uint8List>());
        expect(compressedData.length, greaterThan(0));
      });

      test('should return fallback data when compression fails', () {
        // Arrange - Create data that might cause issues (circular reference simulation)
        // Since we can't create actual circular references in JSON, we test with very large data
        final largeString = 'x' * 1000000; // 1MB string
        final testData = {
          'large_data': largeString,
        };

        // Act
        final compressedData = CompressionService.compressJson(testData);

        // Assert
        expect(compressedData, isA<Uint8List>());
        expect(compressedData.length, greaterThan(0));

        // Should still return valid data (either compressed or fallback)
        // The method should not throw exceptions
      });
    });

    group('decompressJson', () {
      test('should decompress data that was compressed successfully', () {
        // Arrange
        final originalData = {
          'devotional_id': 'test_123',
          'title': 'Test Devotional',
          'content':
              'This is a test devotional content with some length to test compression.',
          'date': '2023-12-01',
          'tags': ['faith', 'hope', 'love'],
          'stats': {
            'read_count': 5,
            'favorite': true,
          },
        };

        // Act
        final compressedData = CompressionService.compressJson(originalData);
        final decompressedData =
            CompressionService.decompressJson(compressedData);

        // Assert
        expect(decompressedData, isNotNull);
        expect(decompressedData, equals(originalData));
        expect(decompressedData!['devotional_id'], equals('test_123'));
        expect(decompressedData['title'], equals('Test Devotional'));
        expect(decompressedData['tags'], equals(['faith', 'hope', 'love']));
        expect(decompressedData['stats']['read_count'], equals(5));
        expect(decompressedData['stats']['favorite'], equals(true));
      });

      test('should decompress complex nested data correctly', () {
        // Arrange
        final originalData = {
          'user_preferences': {
            'theme': 'Deep Purple',
            'brightness': 'light',
            'language': 'es',
            'notifications': {
              'devotionals': true,
              'prayers': false,
              'reminders': true,
            },
          },
          'reading_history': List.generate(
              20,
              (i) => {
                    'id': 'devotional_$i',
                    'date': '2023-12-${i + 1}',
                    'completed': i % 2 == 0,
                    'notes': 'Test notes for devotional $i',
                  }),
          'statistics': {
            'total_days': 365,
            'streak': 15,
            'favorites_count': 8,
            'categories_read': {
              'faith': 45,
              'hope': 32,
              'love': 28,
              'wisdom': 19,
            },
          },
        };

        // Act
        final compressedData = CompressionService.compressJson(originalData);
        final decompressedData =
            CompressionService.decompressJson(compressedData);

        // Assert
        expect(decompressedData, isNotNull);
        expect(decompressedData, equals(originalData));

        // Verify nested structure
        expect(decompressedData!['user_preferences']['theme'],
            equals('Deep Purple'));
        expect(
            decompressedData['user_preferences']['notifications']
                ['devotionals'],
            equals(true));
        expect(decompressedData['reading_history'].length, equals(20));
        expect(decompressedData['reading_history'][0]['id'],
            equals('devotional_0'));
        expect(decompressedData['statistics']['categories_read']['faith'],
            equals(45));
      });

      test('should handle empty compressed data gracefully', () {
        // Arrange
        final emptyData = Uint8List(0);

        // Act
        final result = CompressionService.decompressJson(emptyData);

        // Assert
        expect(result, isNull);
      });

      test('should handle invalid compressed data gracefully', () {
        // Arrange - Create invalid compressed data
        final invalidData = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

        // Act
        final result = CompressionService.decompressJson(invalidData);

        // Assert
        // Should either return null or attempt to parse as uncompressed data
        // The method should not throw exceptions
        expect(result, anyOf(isNull, isA<Map<String, dynamic>>()));
      });

      test('should attempt to parse uncompressed JSON data as fallback', () {
        // Arrange - Create uncompressed JSON data
        final uncompressedData = {
          'test': 'data',
          'number': 123,
        };
        final jsonString = json.encode(uncompressedData);
        final jsonBytes = Uint8List.fromList(utf8.encode(jsonString));

        // Act
        final result = CompressionService.decompressJson(jsonBytes);

        // Assert
        expect(result, isNotNull);
        expect(result, equals(uncompressedData));
      });

      test('should preserve data types during compression cycle', () {
        // Arrange
        final originalData = {
          'string_value': 'test string',
          'int_value': 42,
          'double_value': 3.14159,
          'bool_true': true,
          'bool_false': false,
          'null_value': null,
          'array_strings': ['item1', 'item2', 'item3'],
          'array_numbers': [1, 2, 3, 4, 5],
          'array_mixed': ['text', 123, true, null],
          'nested_object': {
            'inner_string': 'inner value',
            'inner_number': 999,
            'inner_bool': false,
          },
        };

        // Act
        final compressedData = CompressionService.compressJson(originalData);
        final decompressedData =
            CompressionService.decompressJson(compressedData);

        // Assert
        expect(decompressedData, isNotNull);
        expect(decompressedData!['string_value'], isA<String>());
        expect(decompressedData['int_value'], isA<int>());
        expect(decompressedData['double_value'], isA<double>());
        expect(decompressedData['bool_true'], isA<bool>());
        expect(decompressedData['bool_false'], isA<bool>());
        expect(decompressedData['null_value'], isNull);
        expect(decompressedData['array_strings'], isA<List>());
        expect(decompressedData['array_numbers'], isA<List>());
        expect(decompressedData['nested_object'], isA<Map>());

        // Verify exact values
        expect(decompressedData['string_value'], equals('test string'));
        expect(decompressedData['int_value'], equals(42));
        expect(decompressedData['double_value'], equals(3.14159));
        expect(decompressedData['bool_true'], equals(true));
        expect(decompressedData['bool_false'], equals(false));
        expect(decompressedData['array_strings'],
            equals(['item1', 'item2', 'item3']));
        expect(decompressedData['nested_object']['inner_string'],
            equals('inner value'));
      });
    });

    group('round-trip compression and decompression', () {
      test('should maintain data integrity through multiple compression cycles',
          () {
        // Arrange
        final originalData = {
          'cycle_test': 'multiple compression test',
          'data': List.generate(
              10,
              (i) => {
                    'id': i,
                    'value': 'item_$i',
                    'timestamp': DateTime.now().millisecondsSinceEpoch,
                  }),
        };

        // Act - Multiple compression cycles
        var currentData = Map<String, dynamic>.from(originalData);
        for (int cycle = 0; cycle < 3; cycle++) {
          final compressed = CompressionService.compressJson(currentData);
          final decompressed = CompressionService.decompressJson(compressed);
          expect(decompressed, isNotNull, reason: 'Cycle $cycle failed');
          currentData = Map<String, dynamic>.from(decompressed!);
        }

        // Assert
        expect(currentData, equals(originalData));
      });

      test('should handle large devotional data typical in app usage', () {
        // Arrange - Simulate real app data structure
        final devotionalData = {
          'devotionals': List.generate(
              100,
              (i) => {
                    'id': 'devotional_$i',
                    'title': 'Devotional Title $i',
                    'content': 'This is the content for devotional $i. ' *
                        10, // Longer content
                    'date': '2023-${(i % 12) + 1}-${(i % 28) + 1}',
                    'category': ['faith', 'hope', 'love', 'wisdom'][i % 4],
                    'read': i % 3 == 0,
                    'favorite': i % 7 == 0,
                    'notes': i % 5 == 0 ? 'User notes for devotional $i' : null,
                  }),
          'user_stats': {
            'total_devotionals_read': 73,
            'current_streak': 15,
            'longest_streak': 42,
            'favorite_categories': {
              'faith': 25,
              'hope': 18,
              'love': 22,
              'wisdom': 8,
            },
          },
          'app_settings': {
            'theme': 'Deep Purple',
            'brightness': 'light',
            'language': 'es',
            'notifications_enabled': true,
            'audio_enabled': true,
            'font_size': 'medium',
          },
        };

        // Act
        final startTime = DateTime.now();
        final compressedData = CompressionService.compressJson(devotionalData);
        final compressionTime = DateTime.now().difference(startTime);

        final decompressStartTime = DateTime.now();
        final decompressedData =
            CompressionService.decompressJson(compressedData);
        final decompressionTime =
            DateTime.now().difference(decompressStartTime);

        // Assert
        expect(decompressedData, isNotNull);
        expect(decompressedData, equals(devotionalData));

        // Performance assertions - should complete quickly
        expect(compressionTime.inMilliseconds, lessThan(1000),
            reason: 'Compression took too long');
        expect(decompressionTime.inMilliseconds, lessThan(1000),
            reason: 'Decompression took too long');

        // Compression efficiency for large datasets
        final originalSize = utf8.encode(json.encode(devotionalData)).length;
        final compressedSize = compressedData.length;
        expect(compressedSize, lessThan(originalSize),
            reason: 'Large dataset should be compressed efficiently');
      });
    });

    group('edge cases and error handling', () {
      test('should handle very deep nested structures', () {
        // Arrange - Create deeply nested structure
        Map<String, dynamic> createNestedStructure(int depth) {
          if (depth <= 0) {
            return {'value': 'leaf_node'};
          }
          return {'level_$depth': createNestedStructure(depth - 1)};
        }

        final deepData = createNestedStructure(20); // 20 levels deep

        // Act
        final compressedData = CompressionService.compressJson(deepData);
        final decompressedData =
            CompressionService.decompressJson(compressedData);

        // Assert
        expect(decompressedData, isNotNull);
        expect(decompressedData, equals(deepData));
      });

      test('should handle data with repeated patterns efficiently', () {
        // Arrange - Data with lots of repetition (should compress well)
        final repetitiveData = {
          'pattern': 'This is a repeated pattern. ' * 100,
          'list': List.filled(50, 'repeated_item'),
          'nested_repetition': List.generate(
              20,
              (i) => {
                    'common_key': 'common_value',
                    'another_common_key': 'another_common_value',
                    'index': i,
                  }),
        };

        // Act
        final compressedData = CompressionService.compressJson(repetitiveData);
        final decompressedData =
            CompressionService.decompressJson(compressedData);

        // Assert
        expect(decompressedData, isNotNull);
        expect(decompressedData, equals(repetitiveData));

        // Should achieve good compression ratio due to repetition
        final originalSize = utf8.encode(json.encode(repetitiveData)).length;
        final compressedSize = compressedData.length;
        final compressionRatio = compressedSize / originalSize;
        expect(compressionRatio, lessThan(0.5),
            reason: 'Should achieve good compression on repetitive data');
      });
    });
  });
}
