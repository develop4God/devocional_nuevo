// lib/services/compression_service.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';

/// Service for compressing and decompressing backup data
class CompressionService {
  /// Compress JSON data using GZip
  static Uint8List compressJson(Map<String, dynamic> data) {
    try {
      // Convert to JSON string
      final jsonString = json.encode(data);

      // Convert to bytes
      final bytes = utf8.encode(jsonString);

      // Compress using GZip
      final compressed = GZipEncoder().encode(bytes);

      debugPrint(
        'Compression: ${bytes.length} bytes -> ${compressed.length} bytes',
      );

      return Uint8List.fromList(compressed);
    } catch (e) {
      debugPrint('Error compressing data: $e');
      // Return uncompressed data as fallback
      return Uint8List.fromList(utf8.encode(json.encode(data)));
    }
  }

  /// Decompress GZip data to JSON
  static Map<String, dynamic>? decompressJson(Uint8List compressedData) {
    try {
      // Try to decompress
      final decompressed = GZipDecoder().decodeBytes(compressedData);

      // Convert to string
      final jsonString = utf8.decode(decompressed);

      // Parse JSON
      final data = json.decode(jsonString) as Map<String, dynamic>;

      debugPrint(
        'Decompression: ${compressedData.length} bytes -> ${decompressed.length} bytes',
      );

      return data;
    } catch (e) {
      debugPrint('Error decompressing data, trying as uncompressed: $e');

      // Try to parse as uncompressed JSON
      try {
        final jsonString = utf8.decode(compressedData);
        return json.decode(jsonString) as Map<String, dynamic>;
      } catch (e2) {
        debugPrint('Error parsing uncompressed data: $e2');
        return null;
      }
    }
  }

  /// Get compression ratio as percentage
  static double getCompressionRatio(int originalSize, int compressedSize) {
    if (originalSize == 0) return 0.0;
    return ((originalSize - compressedSize) / originalSize) * 100;
  }

  /// Estimate compressed size for given data size
  /// Based on typical JSON compression ratios (60-80%)
  static int estimateCompressedSize(int originalSize) {
    return (originalSize * 0.3).round(); // Assume 70% compression
  }

  /// Check if compression is beneficial for given data size
  /// Small files (< 1KB) might not benefit from compression
  static bool shouldCompress(int dataSize) {
    return dataSize > 1024; // Only compress files larger than 1KB
  }

  /// Create a compressed archive with multiple files
  static Uint8List createArchive(Map<String, dynamic> files) {
    try {
      final archive = Archive();

      files.forEach((filename, data) {
        final jsonString = json.encode(data);
        final bytes = utf8.encode(jsonString);

        final file = ArchiveFile(filename, bytes.length, bytes);
        archive.addFile(file);
      });

      final zipData = ZipEncoder().encode(archive);

      debugPrint(
        'Archive created with ${files.length} files, size: ${zipData.length} bytes',
      );

      return Uint8List.fromList(zipData);
    } catch (e) {
      debugPrint('Error creating archive: $e');
      return Uint8List(0);
    }
  }

  /// Extract files from compressed archive
  static Map<String, dynamic>? extractArchive(Uint8List archiveData) {
    try {
      final archive = ZipDecoder().decodeBytes(archiveData);
      final extractedFiles = <String, dynamic>{};

      for (final file in archive) {
        if (file.isFile) {
          final content = file.content as List<int>;
          final jsonString = utf8.decode(content);
          final data = json.decode(jsonString);
          extractedFiles[file.name] = data;
        }
      }

      debugPrint('Archive extracted with ${extractedFiles.length} files');

      return extractedFiles;
    } catch (e) {
      debugPrint('Error extracting archive: $e');
      return null;
    }
  }
}
