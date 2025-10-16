import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing Bible reader preferences like font size and marked verses
class BiblePreferencesService {
  static const String _keyFontSize = 'bible_font_size';
  static const String _keyMarkedVerses = 'bible_marked_verses';

  /// Get the saved font size, defaults to 18.0
  Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyFontSize) ?? 18.0;
  }

  /// Save the font size preference
  Future<void> saveFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontSize, size);
  }

  /// Get the set of marked verses
  /// Returns a set of verse keys in the format "book|chapter|verse"
  Future<Set<String>> getMarkedVerses() async {
    final prefs = await SharedPreferences.getInstance();
    final markedList = prefs.getStringList(_keyMarkedVerses) ?? [];
    return Set<String>.from(markedList);
  }

  /// Save the set of marked verses
  Future<void> saveMarkedVerses(Set<String> verses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyMarkedVerses, verses.toList());
  }

  /// Toggle a verse's marked state
  /// If the verse is marked, it will be unmarked, and vice versa
  /// Returns the updated set of marked verses
  Future<Set<String>> toggleMarkedVerse(
    String verseKey,
    Set<String> currentMarked,
  ) async {
    final updatedMarked = Set<String>.from(currentMarked);
    if (updatedMarked.contains(verseKey)) {
      updatedMarked.remove(verseKey);
    } else {
      updatedMarked.add(verseKey);
    }
    await saveMarkedVerses(updatedMarked);
    return updatedMarked;
  }

  /// Clear all marked verses
  Future<void> clearMarkedVerses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyMarkedVerses);
  }
}
