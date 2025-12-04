import 'dart:io';

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage adapter that implements the framework-agnostic [BibleVersionStorage]
/// interface using Flutter's path_provider and shared_preferences.
///
/// This adapter bridges the bible_reader_core package with Flutter's storage APIs.
///
/// Usage:
/// ```dart
/// final adapter = StorageAdapter();
/// final biblesDir = await adapter.getBiblesDirectory();
/// await adapter.writeFile('$biblesDir/test.db', bytes);
/// ```
class StorageAdapter implements BibleVersionStorage {
  /// SharedPreferences key for storing downloaded version IDs.
  static const _downloadedVersionsKey = 'bible_downloaded_versions';

  /// Cached bibles directory path.
  String? _biblesDirectory;

  @override
  Future<String> getBiblesDirectory() async {
    if (_biblesDirectory != null) {
      return _biblesDirectory!;
    }

    final documentsDir = await getApplicationDocumentsDirectory();
    _biblesDirectory = '${documentsDir.path}/bibles';

    // Ensure directory exists
    final dir = Directory(_biblesDirectory!);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    return _biblesDirectory!;
  }

  @override
  Future<void> saveDownloadedVersions(List<String> versionIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_downloadedVersionsKey, versionIds);
  }

  @override
  Future<List<String>> getDownloadedVersions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_downloadedVersionsKey) ?? [];
  }

  @override
  Future<void> writeFile(String path, List<int> bytes) async {
    final file = File(path);
    
    // Create parent directories if needed
    final parentDir = file.parent;
    if (!parentDir.existsSync()) {
      await parentDir.create(recursive: true);
    }
    
    await file.writeAsBytes(bytes, flush: true);
  }

  @override
  Future<List<int>> readFile(String path) async {
    final file = File(path);
    return await file.readAsBytes();
  }

  @override
  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }

  @override
  Future<int> getAvailableSpace() async {
    // On most platforms, getting accurate free space requires platform-specific code.
    // For now, return 0 to indicate "unknown" which disables the space check.
    // TODO: Implement platform-specific storage space detection if needed.
    return 0;
  }

  @override
  Future<void> deleteDirectory(String path) async {
    final dir = Directory(path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  @override
  Future<bool> directoryExists(String path) async {
    return await Directory(path).exists();
  }

  @override
  Future<void> createDirectory(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  @override
  Future<List<String>> listFiles(String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!dir.existsSync()) {
      return [];
    }

    final files = <String>[];
    await for (final entity in dir.list()) {
      if (entity is File) {
        files.add(entity.path.split('/').last);
      }
    }
    return files;
  }
}
