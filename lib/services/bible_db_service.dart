import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class BibleDbService {
  late Database _db;

  Future<void> initDb(String dbAssetPath, String dbName) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDirectory.path, dbName);

    if (!File(dbPath).existsSync()) {
      // Read the asset correctly using rootBundle
      final data = await rootBundle.load(dbAssetPath);
      final bytes = data.buffer.asUint8List();
      await File(dbPath).writeAsBytes(bytes, flush: true);
    }

    _db = await openDatabase(dbPath, readOnly: true);
  }

  // Get all books
  Future<List<Map<String, dynamic>>> getAllBooks() async {
    return await _db.query('books');
  }

  // Get the maximum chapter number for a book
  Future<int> getMaxChapter(int bookNumber) async {
    final result = await _db.rawQuery(
      'SELECT MAX(chapter) as maxChapter FROM verses WHERE book_number = ?',
      [bookNumber],
    );
    return result.first['maxChapter'] as int? ?? 1;
  }

  // Get verses from a chapter
  Future<List<Map<String, dynamic>>> getChapterVerses(
      int bookNumber, int chapter) async {
    return await _db.query(
      'verses',
      where: 'book_number = ? AND chapter = ?',
      whereArgs: [bookNumber, chapter],
    );
  }

  // (Optional) Get a chapter using the original method
  Future<List<Map<String, dynamic>>> getChapter({
    required int bookNumber,
    required int chapter,
    String tableName = "verses",
  }) async {
    return await _db.query(
      tableName,
      where: 'book_number = ? AND chapter = ?',
      whereArgs: [bookNumber, chapter],
    );
  }
}
