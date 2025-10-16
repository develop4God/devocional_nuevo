/// BibleReaderController - Framework-agnostic controller for Bible Reader functionality
///
/// This controller manages all business logic for the Bible Reader feature.
/// It's designed to be:
/// - Framework-agnostic (no Flutter dependencies)
/// - Testable (all services injected)
/// - Ready for Bloc/Riverpod integration (exposes state stream)
/// - Fully decoupled from UI layer

import 'dart:async';

import 'package:bible_reader_core/src/bible_db_service.dart';
import 'package:bible_reader_core/src/bible_preferences_service.dart';
import 'package:bible_reader_core/src/bible_reader_service.dart';
import 'package:bible_reader_core/src/bible_reader_state.dart';
import 'package:bible_reader_core/src/bible_version.dart';

class BibleReaderController {
  BibleReaderState _state;
  final List<BibleVersion> allVersions;
  final BibleReaderService readerService;
  final BiblePreferencesService preferencesService;

  final _stateController = StreamController<BibleReaderState>.broadcast();

  /// Stream of state changes - suitable for Bloc/Riverpod integration
  Stream<BibleReaderState> get stateStream => _stateController.stream;

  /// Current state
  BibleReaderState get state => _state;

  BibleReaderController({
    required this.allVersions,
    required this.readerService,
    required this.preferencesService,
    BibleReaderState? initialState,
  }) : _state = initialState ?? const BibleReaderState();

  void dispose() {
    _stateController.close();
  }

  void _emit(BibleReaderState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  /// Initialize the controller with device language and restore last position
  Future<void> initialize(String deviceLanguage) async {
    _emit(_state.copyWith(isLoading: true, deviceLanguage: deviceLanguage));

    // Filter versions by device language
    List<BibleVersion> availableVersions = allVersions
        .where((v) => v.languageCode == deviceLanguage)
        .toList();

    // Fallback to Spanish or all versions if no match
    if (availableVersions.isEmpty) {
      availableVersions = allVersions
          .where((v) => v.languageCode == 'es')
          .toList();
      if (availableVersions.isEmpty) {
        availableVersions = allVersions;
      }
    }

    // Select initial version
    final selectedVersion = availableVersions.isNotEmpty
        ? availableVersions.first
        : allVersions.first;

    // Initialize version's database service
    await _initializeVersionService(selectedVersion);

    // Load preferences
    final fontSize = await preferencesService.getFontSize();
    final markedVerses = await preferencesService.getMarkedVerses();

    _emit(
      _state.copyWith(
        availableVersions: availableVersions,
        selectedVersion: selectedVersion,
        fontSize: fontSize,
        persistentlyMarkedVerses: markedVerses,
      ),
    );

    // Try to restore last position
    final lastPosition = await readerService.getLastPosition();

    if (lastPosition != null &&
        _canRestorePosition(lastPosition, availableVersions)) {
      await _restoreLastPosition(lastPosition, availableVersions);
    } else {
      await _loadFirstBook();
    }

    _emit(_state.copyWith(isLoading: false));
  }

  bool _canRestorePosition(
    Map<String, dynamic> lastPosition,
    List<BibleVersion> availableVersions,
  ) {
    return availableVersions.any(
      (v) =>
          v.name == lastPosition['version'] &&
          v.languageCode == lastPosition['languageCode'],
    );
  }

  Future<void> _restoreLastPosition(
    Map<String, dynamic> lastPosition,
    List<BibleVersion> availableVersions,
  ) async {
    // Find and switch to saved version
    final savedVersion = availableVersions.firstWhere(
      (v) =>
          v.name == lastPosition['version'] &&
          v.languageCode == lastPosition['languageCode'],
    );

    await _initializeVersionService(savedVersion);

    // Load books
    final books = await savedVersion.service!.getAllBooks();

    // Restore position
    final position = await readerService.restorePosition(
      savedPosition: lastPosition,
      books: books,
    );

    if (position != null) {
      _emit(
        _state.copyWith(
          selectedVersion: savedVersion,
          books: books,
          selectedBookName: position['bookName'],
          selectedBookNumber: position['bookNumber'],
          selectedChapter: position['chapter'],
          selectedVerse: position['verse'],
        ),
      );

      // Load chapter data
      await _loadChapterData();
    } else {
      // Position restoration failed, load first book
      await _loadFirstBook();
    }
  }

  Future<void> _loadFirstBook() async {
    final books = await _state.selectedVersion!.service!.getAllBooks();

    if (books.isNotEmpty) {
      _emit(
        _state.copyWith(
          books: books,
          selectedBookName: books[0]['short_name'],
          selectedBookNumber: books[0]['book_number'],
          selectedChapter: 1,
          selectedVerse: 1,
        ),
      );

      await _loadChapterData();
    }
  }

  Future<void> _initializeVersionService(BibleVersion version) async {
    version.service ??= BibleDbService();
    await version.service!.initDb(version.assetPath, version.dbFileName);
    // Also initialize readerService.dbService with the same DB for business logic
    await readerService.dbService.initDb(version.assetPath, version.dbFileName);
  }

  Future<void> _loadChapterData() async {
    if (_state.selectedBookNumber == null || _state.selectedChapter == null) {
      return;
    }

    final maxChapter = await _state.selectedVersion!.service!.getMaxChapter(
      _state.selectedBookNumber!,
    );

    final verses = await _state.selectedVersion!.service!.getChapterVerses(
      _state.selectedBookNumber!,
      _state.selectedChapter!,
    );

    final maxVerse = verses.isNotEmpty
        ? (verses.last['verse'] as int? ?? 1)
        : 1;
    final selectedVerse = _state.selectedVerse;
    final validatedVerse = (selectedVerse == null || selectedVerse > maxVerse)
        ? 1
        : selectedVerse;

    _emit(
      _state.copyWith(
        maxChapter: maxChapter,
        verses: verses,
        maxVerse: maxVerse,
        selectedVerse: validatedVerse,
      ),
    );

    // Save reading position
    if (_state.selectedBookName != null) {
      await readerService.saveReadingPosition(
        bookName: _state.selectedBookName!,
        bookNumber: _state.selectedBookNumber!,
        chapter: _state.selectedChapter!,
        version: _state.selectedVersion!.name,
        languageCode: _state.selectedVersion!.languageCode,
      );
    }
  }

  /// Switch to a different Bible version
  Future<void> switchVersion(BibleVersion newVersion) async {
    if (newVersion.name == _state.selectedVersion?.name) return;

    _emit(_state.copyWith(isLoading: true));

    await _initializeVersionService(newVersion);

    final books = await newVersion.service!.getAllBooks();

    _emit(
      _state.copyWith(
        selectedVersion: newVersion,
        books: books,
        selectedBookName: books.isNotEmpty ? books[0]['short_name'] : null,
        selectedBookNumber: books.isNotEmpty ? books[0]['book_number'] : null,
        selectedChapter: 1,
        selectedVerse: 1,
        selectedVerses: {},
      ),
    );

    await _loadChapterData();

    _emit(_state.copyWith(isLoading: false));
  }

  /// Select a book and optionally a chapter
  Future<void> selectBook(Map<String, dynamic> book, {int? chapter}) async {
    _emit(
      _state.copyWith(
        selectedBookName: book['short_name'],
        selectedBookNumber: book['book_number'],
        selectedChapter: chapter ?? 1,
        selectedVerse: 1,
        selectedVerses: {},
      ),
    );

    await _loadChapterData();
  }

  /// Select a specific chapter
  Future<void> selectChapter(int chapter) async {
    _emit(
      _state.copyWith(
        selectedChapter: chapter,
        selectedVerse: 1,
        selectedVerses: {},
      ),
    );

    await _loadChapterData();
  }

  /// Select a specific verse (for navigation/highlighting)
  void selectVerse(int verse) {
    _emit(_state.copyWith(selectedVerse: verse));
  }

  /// Navigate to the next chapter
  Future<void> goToNextChapter() async {
    if (_state.selectedBookNumber == null || _state.selectedChapter == null) {
      return;
    }

    final result = await readerService.navigateToNextChapter(
      currentBookNumber: _state.selectedBookNumber!,
      currentChapter: _state.selectedChapter!,
      books: _state.books,
    );

    if (result == null) return; // At end of Bible

    _emit(
      _state.copyWith(
        selectedBookNumber: result['bookNumber'],
        selectedBookName: result['bookName'] ?? _state.selectedBookName,
        selectedChapter: result['chapter'],
        selectedVerse: 1,
        selectedVerses: {},
      ),
    );

    if (result['bookName'] != null) {
      // Book changed, need to reload max chapter
      final maxChapter = await _state.selectedVersion!.service!.getMaxChapter(
        result['bookNumber'],
      );
      _emit(_state.copyWith(maxChapter: maxChapter));
    }

    await _loadChapterData();
  }

  /// Navigate to the previous chapter
  Future<void> goToPreviousChapter() async {
    if (_state.selectedBookNumber == null || _state.selectedChapter == null) {
      return;
    }

    final result = await readerService.navigateToPreviousChapter(
      currentBookNumber: _state.selectedBookNumber!,
      currentChapter: _state.selectedChapter!,
      books: _state.books,
    );

    if (result == null) return; // At start of Bible

    _emit(
      _state.copyWith(
        selectedBookNumber: result['bookNumber'],
        selectedBookName: result['bookName'] ?? _state.selectedBookName,
        selectedChapter: result['chapter'],
        selectedVerse: 1,
        selectedVerses: {},
      ),
    );

    if (result['bookName'] != null) {
      // Book changed, need to reload max chapter
      final maxChapter = await _state.selectedVersion!.service!.getMaxChapter(
        result['bookNumber'],
      );
      _emit(_state.copyWith(maxChapter: maxChapter));
    }

    await _loadChapterData();
  }

  /// Perform search with automatic Bible reference detection
  Future<void> performSearch(String query) async {
    if (query.trim().isEmpty) {
      _emit(
        _state.copyWith(isSearching: false, searchResults: [], searchQuery: ''),
      );
      return;
    }

    _emit(_state.copyWith(isLoading: true));

    final result = await readerService.searchWithReferenceDetection(query);

    if (result['isReference'] == true) {
      // Direct navigation to Bible reference
      final target = result['navigationTarget'] as Map<String, dynamic>;

      _emit(
        _state.copyWith(
          selectedBookName: target['bookName'],
          selectedBookNumber: target['bookNumber'],
          selectedChapter: target['chapter'],
          selectedVerse: target['verse'] ?? 1,
          isSearching: false,
          searchResults: [],
          searchQuery: '',
          isLoading: false,
        ),
      );

      await _loadChapterData();
    } else {
      // Text search results
      _emit(
        _state.copyWith(
          searchResults: result['searchResults'] as List<Map<String, dynamic>>,
          searchQuery: query,
          isSearching: true,
          isLoading: false,
        ),
      );
    }
  }

  /// Jump to a search result
  Future<void> jumpToSearchResult(Map<String, dynamic> result) async {
    final bookNumber = result['book_number'] as int;
    final chapter = result['chapter'] as int;
    final verse = result['verse'] as int;

    // Find the book
    final book = _state.books.firstWhere(
      (b) => b['book_number'] == bookNumber,
      orElse: () => _state.books[0],
    );

    _emit(
      _state.copyWith(
        selectedBookName: book['short_name'],
        selectedBookNumber: bookNumber,
        selectedChapter: chapter,
        selectedVerse: verse,
        isSearching: false,
        searchResults: [],
        searchQuery: '',
      ),
    );

    await _loadChapterData();
  }

  /// Clear search results and exit search mode
  void clearSearch() {
    _emit(
      _state.copyWith(isSearching: false, searchResults: [], searchQuery: ''),
    );
  }

  /// Toggle verse selection for copy/share
  void toggleVerseSelection(String verseKey) {
    final selectedVerses = Set<String>.from(_state.selectedVerses);
    if (selectedVerses.contains(verseKey)) {
      selectedVerses.remove(verseKey);
    } else {
      selectedVerses.add(verseKey);
    }
    _emit(_state.copyWith(selectedVerses: selectedVerses));
  }

  /// Clear all selected verses
  void clearSelectedVerses() {
    _emit(_state.copyWith(selectedVerses: {}));
  }

  /// Toggle persistent marking of a verse
  Future<void> togglePersistentMark(String verseKey) async {
    final markedVerses = await preferencesService.toggleMarkedVerse(
      verseKey,
      _state.persistentlyMarkedVerses,
    );
    _emit(_state.copyWith(persistentlyMarkedVerses: markedVerses));
  }

  /// Increase font size
  Future<void> increaseFontSize() async {
    if (_state.fontSize < 30) {
      final newSize = _state.fontSize + 2;
      await preferencesService.saveFontSize(newSize);
      _emit(_state.copyWith(fontSize: newSize));
    }
  }

  /// Decrease font size
  Future<void> decreaseFontSize() async {
    if (_state.fontSize > 12) {
      final newSize = _state.fontSize - 2;
      await preferencesService.saveFontSize(newSize);
      _emit(_state.copyWith(fontSize: newSize));
    }
  }

  /// Toggle font controls visibility
  void toggleFontControls() {
    _emit(_state.copyWith(showFontControls: !_state.showFontControls));
  }

  /// Set font controls visibility
  void setFontControlsVisibility(bool visible) {
    _emit(_state.copyWith(showFontControls: visible));
  }
}
