import 'dart:convert';
import 'dart:typed_data';

import 'package:devocional_nuevo/services/compression_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CompressionService Unit Tests', () {
    group('JSON Compression and Decompression', () {
      test('should compress and decompress simple JSON data successfully', () {
        // Arrange
        final testData = {
          'name': 'Test User',
          'age': 30,
          'email': 'test@example.com',
        };

        // Act
        final compressed = CompressionService.compressJson(testData);
        final decompressed = CompressionService.decompressJson(compressed);

        // Assert
        expect(compressed, isA<Uint8List>());
        expect(compressed.isNotEmpty, isTrue);
        expect(decompressed, equals(testData));
      });

      test('should compress and decompress complex nested JSON data', () {
        // Arrange
        final complexData = {
          'user': {
            'profile': {
              'name': 'Juan Pérez',
              'preferences': ['español', 'reading', 'prayer'],
              'stats': {
                'devotionals_read': 150,
                'prayer_time': 3600,
                'streak': 30,
              },
            },
            'settings': {
              'notifications': true,
              'theme': 'light',
              'language': 'es',
            },
          },
          'data': List.generate(50, (i) => {
                'id': 'devotional_$i',
                'title': 'Devocional del día $i',
                'content': 'Contenido extenso del devocional número $i' * 10,
                'date': DateTime.now().subtract(Duration(days: i)).toIso8601String(),
              }),
        };

        // Act
        final compressed = CompressionService.compressJson(complexData);
        final decompressed = CompressionService.decompressJson(compressed);

        // Assert
        expect(decompressed, isNotNull);
        expect(decompressed!['user']['profile']['name'], equals('Juan Pérez'));
        expect(decompressed['data'], hasLength(50));
        expect(decompressed['user']['settings']['language'], equals('es'));
      });

      test('should handle empty data gracefully', () {
        // Arrange
        final emptyData = <String, dynamic>{};

        // Act
        final compressed = CompressionService.compressJson(emptyData);
        final decompressed = CompressionService.decompressJson(compressed);

        // Assert
        expect(compressed, isNotEmpty);
        expect(decompressed, equals(emptyData));
      });

      test('should handle data with special characters and unicode', () {
        // Arrange
        final unicodeData = {
          'spanish': 'Niño, corazón, señoría',
          'chinese': '你好世界',
          'emoji': '🙏📖✝️❤️',
          'symbols': '@#\$%^&*()_+{}[]|\\:";\'<>?,./',
          'numbers': [1, 2, 3, 4.5, -10, 0.001],
          'boolean': true,
          'null_value': null,
        };

        // Act
        final compressed = CompressionService.compressJson(unicodeData);
        final decompressed = CompressionService.decompressJson(compressed);

        // Assert
        expect(decompressed, equals(unicodeData));
        expect(decompressed!['emoji'], equals('🙏📖✝️❤️'));
        expect(decompressed['chinese'], equals('你好世界'));
      });

      test('should achieve significant compression on repetitive data', () {
        // Arrange - Create repetitive data that should compress well
        final repetitiveData = {
          'items': List.generate(100, (i) => {
                'type': 'devotional',
                'category': 'daily_reading',
                'language': 'spanish',
                'version': 'reina_valera_1960',
                'tags': ['bible', 'prayer', 'reflection'],
                'content': 'Este es un contenido repetitivo que debería comprimir muy bien ' * 20,
              }),
        };

        final originalJson = json.encode(repetitiveData);
        final originalSize = utf8.encode(originalJson).length;

        // Act
        final compressed = CompressionService.compressJson(repetitiveData);
        final compressionRatio = CompressionService.getCompressionRatio(originalSize, compressed.length);

        // Assert
        expect(compressionRatio, greaterThan(50)); // Should achieve >50% compression
        expect(compressed.length, lessThan(originalSize));
      });
    });

    group('Compression Ratio Calculation', () {
      test('should calculate compression ratio correctly', () {
        // Arrange
        const originalSize = 1000;
        const compressedSize = 300;

        // Act
        final ratio = CompressionService.getCompressionRatio(originalSize, compressedSize);

        // Assert
        expect(ratio, equals(70.0)); // (1000-300)/1000 * 100 = 70%
      });

      test('should return 0% for equal sizes', () {
        // Arrange
        const size = 500;

        // Act
        final ratio = CompressionService.getCompressionRatio(size, size);

        // Assert
        expect(ratio, equals(0.0));
      });

      test('should return 0% for zero original size', () {
        // Act
        final ratio = CompressionService.getCompressionRatio(0, 100);

        // Assert
        expect(ratio, equals(0.0));
      });

      test('should handle negative compression ratio (expansion)', () {
        // Arrange - compressed size larger than original
        const originalSize = 100;
        const compressedSize = 150;

        // Act
        final ratio = CompressionService.getCompressionRatio(originalSize, compressedSize);

        // Assert
        expect(ratio, equals(-50.0)); // Negative indicates expansion
      });
    });

    group('Compression Size Estimation', () {
      test('should estimate compressed size reasonably', () {
        // Arrange
        const originalSize = 10000;

        // Act
        final estimatedSize = CompressionService.estimateCompressedSize(originalSize);

        // Assert
        expect(estimatedSize, equals(3000)); // 30% of original
        expect(estimatedSize, lessThan(originalSize));
      });

      test('should handle small sizes', () {
        // Arrange
        const smallSize = 10;

        // Act
        final estimatedSize = CompressionService.estimateCompressedSize(smallSize);

        // Assert
        expect(estimatedSize, equals(3)); // 30% of 10
      });
    });

    group('Compression Decision Logic', () {
      test('should recommend compression for large files', () {
        // Arrange
        const largeSize = 5000;

        // Act
        final shouldCompress = CompressionService.shouldCompress(largeSize);

        // Assert
        expect(shouldCompress, isTrue);
      });

      test('should not recommend compression for small files', () {
        // Arrange
        const smallSize = 500;

        // Act
        final shouldCompress = CompressionService.shouldCompress(smallSize);

        // Assert
        expect(shouldCompress, isFalse);
      });

      test('should have correct threshold at 1KB', () {
        // Assert
        expect(CompressionService.shouldCompress(1023), isFalse);
        expect(CompressionService.shouldCompress(1024), isFalse);
        expect(CompressionService.shouldCompress(1025), isTrue);
      });
    });

    group('Archive Creation and Extraction', () {
      test('should create archive with multiple files', () {
        // Arrange
        final files = {
          'devotional_1.json': {
            'id': 'dev_1',
            'title': 'First Devotional',
            'content': 'Content of first devotional',
          },
          'devotional_2.json': {
            'id': 'dev_2', 
            'title': 'Second Devotional',
            'content': 'Content of second devotional',
          },
          'settings.json': {
            'theme': 'light',
            'language': 'es',
            'notifications': true,
          },
        };

        // Act
        final archive = CompressionService.createArchive(files);

        // Assert
        expect(archive, isA<Uint8List>());
        expect(archive.isNotEmpty, isTrue);
      });

      test('should create archive from empty file map', () {
        // Arrange
        final emptyFiles = <String, dynamic>{};

        // Act
        final archive = CompressionService.createArchive(emptyFiles);

        // Assert
        expect(archive, isA<Uint8List>());
        // Empty archive should still be a valid archive structure
      });

      test('should extract files from archive correctly', () {
        // Arrange
        final originalFiles = {
          'test_file_1.json': {'data': 'test content 1'},
          'test_file_2.json': {'data': 'test content 2'},
        };

        final archive = CompressionService.createArchive(originalFiles);

        // Act
        final extractedFiles = CompressionService.extractArchive(archive);

        // Assert
        expect(extractedFiles, isNotNull);
        expect(extractedFiles!.keys, containsAll(['test_file_1.json', 'test_file_2.json']));
        expect(extractedFiles['test_file_1.json'], equals({'data': 'test content 1'}));
        expect(extractedFiles['test_file_2.json'], equals({'data': 'test content 2'}));
      });
    });

    group('Error Handling', () {
      test('should handle malformed compressed data gracefully', () {
        // Arrange
        final malformedData = Uint8List.fromList([1, 2, 3, 4, 5]);

        // Act
        final result = CompressionService.decompressJson(malformedData);

        // Assert - Should return null or handle gracefully
        expect(result, isNull);
      });

      test('should handle null or invalid JSON data in compression', () {
        // Arrange
        final Map<String, dynamic> dataWithNulls = {
          'valid_field': 'test',
          'null_field': null,
          'empty_string': '',
          'zero': 0,
          'false_bool': false,
        };

        // Act & Assert - Should not throw
        expect(() => CompressionService.compressJson(dataWithNulls), returnsNormally);
        
        final compressed = CompressionService.compressJson(dataWithNulls);
        final decompressed = CompressionService.decompressJson(compressed);
        
        expect(decompressed, equals(dataWithNulls));
      });

      test('should handle extremely large data sets', () {
        // Arrange - Create a large dataset
        final largeData = {
          'large_array': List.generate(1000, (i) => {
                'index': i,
                'data': 'Large data content item number $i' * 100,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              }),
        };

        // Act & Assert - Should handle large data without throwing
        expect(() => CompressionService.compressJson(largeData), returnsNormally);
        
        final compressed = CompressionService.compressJson(largeData);
        expect(compressed.isNotEmpty, isTrue);
        
        final decompressed = CompressionService.decompressJson(compressed);
        expect(decompressed, isNotNull);
        expect(decompressed!['large_array'], hasLength(1000));
      });

      test('should handle corrupted archive data', () {
        // Arrange
        final corruptedArchive = Uint8List.fromList([0, 1, 2, 3, 4, 5]);

        // Act
        final result = CompressionService.extractArchive(corruptedArchive);

        // Assert - Should handle gracefully
        expect(result, isNull);
      });
    });

    group('Performance and Optimization', () {
      test('should process data within reasonable time limits', () {
        // Arrange
        final testData = {
          'performance_test': List.generate(500, (i) => {
                'id': i,
                'content': 'Performance test data ' * 50,
              }),
        };

        // Act & Measure
        final stopwatch = Stopwatch()..start();
        final compressed = CompressionService.compressJson(testData);
        final decompressed = CompressionService.decompressJson(compressed);
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should complete within 1 second
        expect(decompressed, equals(testData));
      });

      test('should be memory efficient with large datasets', () {
        // Arrange
        final memoryTestData = {
          'memory_test': List.generate(100, (i) => {
                'chunk_$i': 'A' * 1000, // 1KB per chunk
              }),
        };

        // Act - Multiple compression/decompression cycles
        Map<String, dynamic>? result = memoryTestData;
        for (int i = 0; i < 5; i++) {
          final compressed = CompressionService.compressJson(result!);
          result = CompressionService.decompressJson(compressed);
        }

        // Assert
        expect(result, equals(memoryTestData));
      });
    });
  });
}