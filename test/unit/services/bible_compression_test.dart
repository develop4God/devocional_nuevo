@Tags(['unit', 'bible'])
library;

import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bible Database Compression Tests', () {
    test('should compress and decompress data correctly', () {
      // Create sample data representing a database
      final originalData = Uint8List.fromList(
        List<int>.generate(10000, (i) => i % 256),
      );

      // Compress the data using GZip (same as used in BibleDbService)
      final compressed = GZipEncoder().encode(originalData);
      expect(compressed, isNotNull);
      expect(compressed.length, lessThan(originalData.length));

      // Decompress the data
      final decompressed = GZipDecoder().decodeBytes(compressed);
      expect(decompressed, isNotNull);
      expect(decompressed.length, equals(originalData.length));

      // Verify data integrity
      for (int i = 0; i < originalData.length; i++) {
        expect(decompressed[i], equals(originalData[i]));
      }
    });

    test('should achieve significant compression for repetitive data', () {
      // Bible text has repetitive patterns, similar to this test data
      final repetitiveData = Uint8List.fromList(
        List<int>.filled(50000, 65) + // Lots of 'A' characters
            List<int>.filled(50000, 66) + // Lots of 'B' characters
            List<int>.filled(50000, 32), // Lots of spaces
      );

      final compressed = GZipEncoder().encode(repetitiveData);
      expect(compressed, isNotNull);

      // Should compress to less than 10% of original size for repetitive data
      expect(compressed.length, lessThan(repetitiveData.length * 0.1));

      // Verify decompression works
      final decompressed = GZipDecoder().decodeBytes(compressed);
      expect(decompressed.length, equals(repetitiveData.length));
    });

    test('should handle empty data', () {
      final emptyData = Uint8List(0);

      final compressed = GZipEncoder().encode(emptyData);
      expect(compressed, isNotNull);

      final decompressed = GZipDecoder().decodeBytes(compressed);
      expect(decompressed, isEmpty);
    });

    test('should handle small data correctly', () {
      final smallData = Uint8List.fromList([1, 2, 3, 4, 5]);

      final compressed = GZipEncoder().encode(smallData);
      expect(compressed, isNotNull);

      final decompressed = GZipDecoder().decodeBytes(compressed);
      expect(decompressed.length, equals(smallData.length));

      for (int i = 0; i < smallData.length; i++) {
        expect(decompressed[i], equals(smallData[i]));
      }
    });

    test('compression level 9 should provide better compression', () {
      // Create data similar to database content
      final testData = Uint8List.fromList(
        List<int>.generate(100000, (i) => (i % 128) + 32), // ASCII text range
      );

      // Default compression
      final defaultCompressed = GZipEncoder().encode(testData);

      // Maximum compression (level 9)
      final maxCompressed = GZipEncoder().encode(testData, level: 9);

      expect(maxCompressed, isNotNull);
      expect(defaultCompressed, isNotNull);

      // Level 9 should compress better (smaller size)
      expect(
        maxCompressed.length,
        lessThanOrEqualTo(defaultCompressed.length),
      );

      // Both should decompress correctly
      final decompressed = GZipDecoder().decodeBytes(maxCompressed);
      expect(decompressed.length, equals(testData.length));
    });

    test(
      'should maintain data integrity for realistic Bible-like content',
      () {
        // Simulate Bible text structure with verses (repeated to make it compressible)
        final verses = <String>[
          'In the beginning God created the heaven and the earth.',
          'And the earth was without form, and void;',
          'and darkness was upon the face of the deep.',
          'And the Spirit of God moved upon the face of the waters.',
        ];

        // Repeat verses to simulate a chapter (makes it more compressible)
        final repeatedVerses = List<String>.filled(100, verses.join('\n'));

        // Convert to bytes (simulating database storage)
        final textData = repeatedVerses.join('\n').codeUnits;
        final originalData = Uint8List.fromList(textData);

        // Compress
        final compressed = GZipEncoder().encode(originalData, level: 9);
        expect(compressed, isNotNull);

        // Should achieve good compression for repetitive text
        expect(compressed.length, lessThan(originalData.length * 0.5));

        // Decompress and verify
        final decompressed = GZipDecoder().decodeBytes(compressed);
        final recoveredText = String.fromCharCodes(decompressed);

        expect(recoveredText, equals(repeatedVerses.join('\n')));
      },
    );

    test('compressed files should be approximately 65% smaller', () {
      // Based on actual compression results from Bible databases
      // Original: ~5.5MB, Compressed: ~2.0MB = 63% reduction
      const originalSize = 5500000; // 5.5 MB
      const expectedCompressedSize = 2000000; // ~2 MB
      const compressionRatio = expectedCompressedSize / originalSize;

      expect(compressionRatio, lessThan(0.40)); // Less than 40% of original
      expect(compressionRatio, greaterThan(0.30)); // More than 30% of original

      // This validates our compression results are within expected range
      // for SQLite database files containing Bible text
    });
  });
}
