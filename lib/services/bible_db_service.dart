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

  // Search for verses containing a phrase
  // Prioritizes exact word matches over partial matches
  Future<List<Map<String, dynamic>>> searchVerses(String searchQuery) async {
    if (searchQuery.trim().isEmpty) return [];

    final query = searchQuery.trim();

    // Search with word boundaries for exact word matches (priority 1)
    final exactResults = await _db.rawQuery('''
      SELECT v.*, b.long_name, b.short_name, 1 as priority
      FROM verses v
      JOIN books b ON v.book_number = b.book_number
      WHERE v.text LIKE ?
      ORDER BY v.book_number, v.chapter, v.verse
      LIMIT 50
    ''', ['% $query %']);

    // Build exclusion list for next queries
    final exactIds = exactResults.map((r) => r['rowid']).toList();
    final exactIdsStr = exactIds.isEmpty ? '-1' : exactIds.join(',');

    // Search for verses that start with the word
    final startsWithResults = await _db.rawQuery('''
      SELECT v.*, b.long_name, b.short_name, 2 as priority
      FROM verses v
      JOIN books b ON v.book_number = b.book_number
      WHERE v.text LIKE ?
      AND v.rowid NOT IN ($exactIdsStr)
      ORDER BY v.book_number, v.chapter, v.verse
      LIMIT 25
    ''', ['$query %']);

    // Build combined exclusion list
    final combinedIds = [
      ...exactIds,
      ...startsWithResults.map((r) => r['rowid'])
    ];
    final combinedIdsStr = combinedIds.isEmpty ? '-1' : combinedIds.join(',');

    // Search for partial matches (priority 3)
    final partialResults = await _db.rawQuery('''
      SELECT v.*, b.long_name, b.short_name, 3 as priority
      FROM verses v
      JOIN books b ON v.book_number = b.book_number
      WHERE v.text LIKE ?
      AND v.rowid NOT IN ($combinedIdsStr)
      ORDER BY v.book_number, v.chapter, v.verse
      LIMIT 25
    ''', ['%$query%']);

    // Combine results with exact matches first
    return [...exactResults, ...startsWithResults, ...partialResults];
  }

  // Find a book by name or abbreviation (case-insensitive, partial match)
  Future<Map<String, dynamic>?> findBookByName(String bookName) async {
    if (bookName.trim().isEmpty) return null;

    final searchTerm = bookName.trim();

    // Try exact match first (case-insensitive)
    var results = await _db.rawQuery('''
      SELECT * FROM books 
      WHERE LOWER(long_name) = ? OR LOWER(short_name) = ?
      LIMIT 1
    ''', [searchTerm.toLowerCase(), searchTerm.toLowerCase()]);

    if (results.isNotEmpty) {
      return results.first;
    }

    // Try partial match at start of name
    results = await _db.rawQuery('''
      SELECT * FROM books 
      WHERE LOWER(long_name) LIKE ? OR LOWER(short_name) LIKE ?
      ORDER BY book_number
      LIMIT 1
    ''', ['${searchTerm.toLowerCase()}%', '${searchTerm.toLowerCase()}%']);

    if (results.isNotEmpty) {
      return results.first;
    }

    // Try contains match (for common abbreviations)
    results = await _db.rawQuery('''
      SELECT * FROM books 
      WHERE LOWER(long_name) LIKE ? OR LOWER(short_name) LIKE ?
      ORDER BY book_number
      LIMIT 1
    ''', ['%${searchTerm.toLowerCase()}%', '%${searchTerm.toLowerCase()}%']);

    return results.isNotEmpty ? results.first : null;
  }

  // Get a specific verse
  Future<Map<String, dynamic>?> getVerse({
    required int bookNumber,
    required int chapter,
    required int verse,
  }) async {
    final results = await _db.query(
      'verses',
      where: 'book_number = ? AND chapter = ? AND verse = ?',
      whereArgs: [bookNumber, chapter, verse],
      limit: 1,
    );

    return results.isNotEmpty ? results.first : null;
  }
}
