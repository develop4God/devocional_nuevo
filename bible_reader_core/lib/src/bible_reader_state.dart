import 'package:bible_reader_core/src/bible_version.dart';

/// Immutable state class for Bible Reader
/// Designed to be framework-agnostic and ready for Bloc/Riverpod integration
class BibleReaderState {
  final List<BibleVersion> availableVersions;
  final BibleVersion? selectedVersion;
  final String deviceLanguage;
  final List<Map<String, dynamic>> books;
  final String? selectedBookName;
  final int? selectedBookNumber;
  final int? selectedChapter;
  final int? selectedVerse;
  final int maxChapter;
  final int maxVerse;
  final List<Map<String, dynamic>> verses;
  final Set<String> selectedVerses;
  final Set<String> persistentlyMarkedVerses;
  final double fontSize;
  final bool showFontControls;
  final bool isLoading;
  final bool isSearching;
  final List<Map<String, dynamic>> searchResults;
  final String searchQuery;

  const BibleReaderState({
    this.availableVersions = const [],
    this.selectedVersion,
    this.deviceLanguage = '',
    this.books = const [],
    this.selectedBookName,
    this.selectedBookNumber,
    this.selectedChapter,
    this.selectedVerse,
    this.maxChapter = 1,
    this.maxVerse = 1,
    this.verses = const [],
    this.selectedVerses = const {},
    this.persistentlyMarkedVerses = const {},
    this.fontSize = 18.0,
    this.showFontControls = false,
    this.isLoading = false,
    this.isSearching = false,
    this.searchResults = const [],
    this.searchQuery = '',
  });

  BibleReaderState copyWith({
    List<BibleVersion>? availableVersions,
    BibleVersion? selectedVersion,
    String? deviceLanguage,
    List<Map<String, dynamic>>? books,
    String? selectedBookName,
    int? selectedBookNumber,
    int? selectedChapter,
    int? selectedVerse,
    int? maxChapter,
    int? maxVerse,
    List<Map<String, dynamic>>? verses,
    Set<String>? selectedVerses,
    Set<String>? persistentlyMarkedVerses,
    double? fontSize,
    bool? showFontControls,
    bool? isLoading,
    bool? isSearching,
    List<Map<String, dynamic>>? searchResults,
    String? searchQuery,
  }) {
    return BibleReaderState(
      availableVersions: availableVersions ?? this.availableVersions,
      selectedVersion: selectedVersion ?? this.selectedVersion,
      deviceLanguage: deviceLanguage ?? this.deviceLanguage,
      books: books ?? this.books,
      selectedBookName: selectedBookName ?? this.selectedBookName,
      selectedBookNumber: selectedBookNumber ?? this.selectedBookNumber,
      selectedChapter: selectedChapter ?? this.selectedChapter,
      selectedVerse: selectedVerse ?? this.selectedVerse,
      maxChapter: maxChapter ?? this.maxChapter,
      maxVerse: maxVerse ?? this.maxVerse,
      verses: verses ?? this.verses,
      selectedVerses: selectedVerses ?? this.selectedVerses,
      persistentlyMarkedVerses:
          persistentlyMarkedVerses ?? this.persistentlyMarkedVerses,
      fontSize: fontSize ?? this.fontSize,
      showFontControls: showFontControls ?? this.showFontControls,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      searchResults: searchResults ?? this.searchResults,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
