//bible_reader_page.dart
import 'dart:ui' as ui;

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/utils/copyright_utils.dart';
import 'package:devocional_nuevo/widgets/app_bar_constants.dart';
import 'package:devocional_nuevo/widgets/bible_reader_action_modal.dart';
import 'package:devocional_nuevo/widgets/bible_verse_grid_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus;
import 'package:shared_preferences/shared_preferences.dart';

/// Helper class to parse Bible references like "Juan 3:16", "Genesis 1:1", etc.
class BibleReferenceParser {
  /// Parses a Bible reference string and returns book name, chapter, and optional verse
  /// Returns null if the input doesn't match a Bible reference pattern
  static Map<String, dynamic>? parse(String input) {
    final trimmed = input.trim();

    // Pattern 1: "Book Chapter:Verse" (e.g., "Juan 3:16", "Genesis 1:1")
    // Pattern 2: "Book Chapter" (e.g., "Juan 3", "Genesis 1")
    // Supports book names with numbers (e.g., "1 Juan", "2 Corintios")
    // Supports book names with spaces and accents

    // Match patterns like: "1 Juan 3:16" or "Juan 3:16" or "Genesis 1:1"
    final regexWithVerse = RegExp(
      r'^(\d+\s+)?([a-záéíóúñü\s\.]+?)\s+(\d+):(\d+)$',
      caseSensitive: false,
      unicode: true,
    );

    // Match patterns like: "1 Juan 3" or "Juan 3" or "Genesis 1"
    final regexWithoutVerse = RegExp(
      r'^(\d+\s+)?([a-záéíóúñü\s\.]+?)\s+(\d+)$',
      caseSensitive: false,
      unicode: true,
    );

    // Try with verse first
    var match = regexWithVerse.firstMatch(trimmed);
    if (match != null) {
      final bookPrefix = match.group(1)?.trim() ?? '';
      final bookName = match.group(2)!.trim();
      final chapter = int.tryParse(match.group(3)!);
      final verse = int.tryParse(match.group(4)!);

      if (chapter != null && verse != null) {
        final fullBookName =
            bookPrefix.isEmpty ? bookName : '$bookPrefix $bookName';
        return {
          'bookName': fullBookName,
          'chapter': chapter,
          'verse': verse,
        };
      }
    }

    // Try without verse
    match = regexWithoutVerse.firstMatch(trimmed);
    if (match != null) {
      final bookPrefix = match.group(1)?.trim() ?? '';
      final bookName = match.group(2)!.trim();
      final chapter = int.tryParse(match.group(3)!);

      if (chapter != null) {
        final fullBookName =
            bookPrefix.isEmpty ? bookName : '$bookPrefix $bookName';
        return {
          'bookName': fullBookName,
          'chapter': chapter,
        };
      }
    }

    return null;
  }
}

class BibleReaderPage extends StatefulWidget {
  final List<BibleVersion> versions;

  const BibleReaderPage({super.key, required this.versions});

  @override
  State<BibleReaderPage> createState() => _BibleReaderPageState();
}

class _BibleReaderPageState extends State<BibleReaderPage> {
  late BibleVersion _selectedVersion;
  List<BibleVersion> _availableVersions = [];
  String _deviceLanguage = '';
  List<Map<String, dynamic>> _books = [];
  String? _selectedBookName;
  int? _selectedBookNumber;
  int? _selectedChapter;
  int? _selectedVerse; // For direct verse navigation
  int _maxChapter = 1;
  int _maxVerse = 1; // Maximum verse in current chapter
  List<Map<String, dynamic>> _verses = [];
  final Set<String> _selectedVerses = {}; // format: "book|chapter|verse"
  final Set<String> _persistentlyMarkedVerses =
      {}; // Verses marked for persistent highlighting
  double _fontSize = 18; // Made mutable for font size adjustment
  bool _showFontControls = false; // Toggle for font size controls
  bool _bottomSheetOpen = false;
  bool _isLoading = true;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  final BibleReadingPositionService _positionService =
      BibleReadingPositionService();
  final ScrollController _scrollController =
      ScrollController(); // For verse navigation
  final Map<int, GlobalKey> _verseKeys = {}; // Keys for direct verse scrolling

  @override
  void initState() {
    super.initState();

    // DEBUG: Print all passed versions
    debugPrint('🟦 [Bible] All versions passed to widget:');
    for (final v in widget.versions) {
      debugPrint('    ${v.name} (${v.languageCode}) - ${v.assetPath}');
    }

    _loadFontSize();
    _loadMarkedVerses();
    _detectLanguageAndInitialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _detectLanguageAndInitialize() async {
    setState(() {
      _isLoading = true;
    });

    // Detect device language
    _deviceLanguage = ui.PlatformDispatcher.instance.locale.languageCode;

    // Filter versions by device language
    _availableVersions = widget.versions
        .where((v) => v.languageCode == _deviceLanguage)
        .toList();

    // If no versions for device language, fall back to all versions or Spanish
    if (_availableVersions.isEmpty) {
      _availableVersions =
          widget.versions.where((v) => v.languageCode == 'es').toList();
      if (_availableVersions.isEmpty) {
        _availableVersions = widget.versions;
      }
    }

    // Try to restore last reading position
    final lastPosition = await _positionService.getLastPosition();

    if (lastPosition != null &&
        _availableVersions.any((v) =>
            v.name == lastPosition['version'] &&
            v.languageCode == lastPosition['languageCode'])) {
      // Restore last version and position
      _selectedVersion = _availableVersions.firstWhere(
        (v) =>
            v.name == lastPosition['version'] &&
            v.languageCode == lastPosition['languageCode'],
      );
      await _initVersion();
      await _restorePosition(lastPosition);
    } else {
      // Start with first available version
      _selectedVersion = _availableVersions.isNotEmpty
          ? _availableVersions.first
          : widget.versions.first;
      await _initVersion();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _restorePosition(Map<String, dynamic> position) async {
    // Find the book in the loaded books
    final book = _books.firstWhere(
      (b) =>
          b['short_name'] == position['bookName'] ||
          b['book_number'] == position['bookNumber'],
      orElse: () => _books.isNotEmpty ? _books[0] : {},
    );

    if (book.isNotEmpty) {
      setState(() {
        _selectedBookName = book['short_name'];
        _selectedBookNumber = book['book_number'];
        _selectedChapter = position['chapter'];
      });
      await _loadMaxChapter();
      await _loadVerses();
    }
  }

  // Load font size preference
  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('bible_font_size') ?? 18.0;
    });
  }

  // Save font size preference
  Future<void> _saveFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('bible_font_size', _fontSize);
  }

  // Increase font size
  void _increaseFontSize() {
    if (_fontSize < 30) {
      setState(() {
        _fontSize += 2;
      });
      _saveFontSize();
    }
  }

  // Decrease font size
  void _decreaseFontSize() {
    if (_fontSize > 12) {
      setState(() {
        _fontSize -= 2;
      });
      _saveFontSize();
    }
  }

  // Load persistently marked verses
  Future<void> _loadMarkedVerses() async {
    final prefs = await SharedPreferences.getInstance();
    final markedList = prefs.getStringList('bible_marked_verses') ?? [];
    setState(() {
      _persistentlyMarkedVerses.clear();
      _persistentlyMarkedVerses.addAll(markedList);
    });
  }

  // Save persistently marked verses
  Future<void> _saveMarkedVerses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'bible_marked_verses', _persistentlyMarkedVerses.toList());
  }

  // Toggle verse persistent marking
  void _toggleVersePersistentMark(String verseKey) {
    setState(() {
      if (_persistentlyMarkedVerses.contains(verseKey)) {
        _persistentlyMarkedVerses.remove(verseKey);
      } else {
        _persistentlyMarkedVerses.add(verseKey);
      }
    });
    _saveMarkedVerses();
  }

  // Scroll to specific verse
  void _scrollToVerse(int verseNumber) async {
    debugPrint('[scrollToVerse] Called for verseNumber: $verseNumber');
    final key = _verseKeys[verseNumber];

    // If key/context is not available, pre-scroll to approximate position
    if (key == null || key.currentContext == null) {
      // Estimate position: item height * (verseNumber - 1)
      // Use a default item height based on your UI design
      const double itemHeight =
          56.0; // Tune this value to match your verse height
      final double targetOffset = (verseNumber - 1) * itemHeight;
      if (_scrollController.hasClients) {
        debugPrint('[scrollToVerse] Pre-scrolling to offset: $targetOffset');
        await _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
        await Future.delayed(const Duration(milliseconds: 80));
      }
    }

    // Try multiple times to get the context after scrolling/rebuild
    const int maxTries = 8;
    const Duration tryDelay = Duration(milliseconds: 60);
    bool found = false;

    for (int tryNum = 0; tryNum < maxTries; tryNum++) {
      final retryKey = _verseKeys[verseNumber];
      if (retryKey?.currentContext != null) {
        debugPrint(
            '[scrollToVerse] Ensuring visibility for verse $verseNumber (try $tryNum)');
        Scrollable.ensureVisible(
          retryKey!.currentContext!,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
        found = true;
        break;
      }
      await Future.delayed(tryDelay);
    }

    if (!found) {
      debugPrint(
          '[scrollToVerse] Still no context for verse $verseNumber after $maxTries tries');
    }
  }

  /// Scroll to top of the chapter
  void _scrollToTop() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  /// Show verse grid selector dialog
  Future<void> _showVerseGridSelector() async {
    if (_selectedBookName == null || _selectedChapter == null) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return BibleVerseGridSelector(
          totalVerses: _maxVerse,
          selectedVerse: _selectedVerse ?? 1,
          bookName: _selectedBookName!,
          chapterNumber: _selectedChapter!,
          onVerseSelected: (verseNumber) {
            Navigator.of(context).pop();
            setState(() {
              _selectedVerse = verseNumber;
            });
            // Scroll to the selected verse after the dialog closes
            Future.delayed(const Duration(milliseconds: 100), () {
              _scrollToVerse(verseNumber);
            });
          },
        );
      },
    );
  }

  // Show book selector dialog with search
  Future<void> _showBookSelector() async {
    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> filteredBooks = List.from(_books);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void filterBooks(String query) {
              setDialogState(() {
                if (query.length < 2) {
                  filteredBooks = List.from(_books);
                } else {
                  filteredBooks = _books.where((book) {
                    final longName = book['long_name'].toString().toLowerCase();
                    final shortName =
                        book['short_name'].toString().toLowerCase();
                    final searchLower = query.toLowerCase();
                    return longName.contains(searchLower) ||
                        shortName.contains(searchLower);
                  }).toList();
                }
              });
            }

            return AlertDialog(
              title: Text('bible.search_book'.tr()),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'bible.search_book_placeholder'.tr(),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  searchController.clear();
                                  filterBooks('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: filterBooks,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredBooks.length,
                        itemBuilder: (context, index) {
                          final book = filteredBooks[index];
                          final isSelected =
                              book['short_name'] == _selectedBookName;
                          return ListTile(
                            title: Text(book['long_name']),
                            subtitle: Text(book['short_name']),
                            selected: isSelected,
                            selectedTileColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.3),
                            onTap: () async {
                              Navigator.of(context).pop();
                              setState(() {
                                _selectedBookName = book['short_name'];
                                _selectedBookNumber = book['book_number'];
                                _selectedChapter = 1;
                                _selectedVerses.clear();
                              });
                              await _loadMaxChapter();
                              await _loadVerses();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _initVersion() async {
    setState(() {
      _isLoading = true;
    });

    _selectedVersion.service ??= BibleDbService();
    await _selectedVersion.service!.initDb(
      _selectedVersion.assetPath,
      _selectedVersion.dbFileName,
    );
    await _loadBooks();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadBooks() async {
    final books = await _selectedVersion.service!.getAllBooks();
    setState(() {
      _books = books;
      if (books.isNotEmpty) {
        _selectedBookName = books[0]['short_name'];
        _selectedBookNumber = books[0]['book_number'];
        _selectedChapter = 1;
      }
    });
    await _loadMaxChapter();
    await _loadVerses();
  }

  Future<void> _loadMaxChapter() async {
    if (_selectedBookNumber == null) return;
    final max =
        await _selectedVersion.service!.getMaxChapter(_selectedBookNumber!);
    setState(() {
      _maxChapter = max;
    });
  }

  Future<void> _loadVerses() async {
    if (_selectedBookNumber == null || _selectedChapter == null) return;
    final verses = await _selectedVersion.service!.getChapterVerses(
      _selectedBookNumber!,
      _selectedChapter!,
    );
    setState(() {
      _verses = verses;
      _maxVerse = verses.isNotEmpty ? (verses.last['verse'] as int? ?? 1) : 1;
      // Initialize selected verse if not set
      if (_selectedVerse == null || _selectedVerse! > _maxVerse) {
        _selectedVerse = 1;
      }
      // Create GlobalKeys for each verse for direct scrolling
      _verseKeys.clear();
      for (final verse in verses) {
        final verseNum = verse['verse'] as int;
        _verseKeys[verseNum] = GlobalKey();
      }
    });

    // Save reading position
    if (_selectedBookName != null) {
      await _positionService.savePosition(
        bookName: _selectedBookName!,
        bookNumber: _selectedBookNumber!,
        chapter: _selectedChapter!,
        version: _selectedVersion.name,
        languageCode: _selectedVersion.languageCode,
      );
    }
  }

  /// Navigate to the previous chapter (or previous book if at first chapter)
  Future<void> _goToPreviousChapter() async {
    if (_selectedBookNumber == null || _selectedChapter == null) return;

    if (_selectedChapter! > 1) {
      // Go to previous chapter in same book
      setState(() {
        _selectedChapter = _selectedChapter! - 1;
        _selectedVerse = 1;
        _selectedVerses.clear();
      });
      await _loadVerses();
      _scrollToTop();
    } else {
      // Go to last chapter of previous book
      final currentBookIndex =
          _books.indexWhere((b) => b['book_number'] == _selectedBookNumber);
      if (currentBookIndex > 0) {
        final previousBook = _books[currentBookIndex - 1];
        await _selectBook(previousBook,
            goToLastChapter: true); // Will load last chapter
      }
    }
  }

  /// Navigate to the next chapter (or next book if at last chapter)
  Future<void> _goToNextChapter() async {
    if (_selectedBookNumber == null || _selectedChapter == null) return;

    if (_selectedChapter! < _maxChapter) {
      // Go to next chapter in same book
      setState(() {
        _selectedChapter = _selectedChapter! + 1;
        _selectedVerse = 1;
        _selectedVerses.clear();
      });
      await _loadVerses();
      _scrollToTop();
    } else {
      // Go to first chapter of next book
      final currentBookIndex =
          _books.indexWhere((b) => b['book_number'] == _selectedBookNumber);
      if (currentBookIndex >= 0 && currentBookIndex < _books.length - 1) {
        final nextBook = _books[currentBookIndex + 1];
        await _selectBook(nextBook, chapter: 1);
      }
    }
  }

  /// Helper method to select a book and optionally a chapter
  Future<void> _selectBook(
    Map<String, dynamic> book, {
    int? chapter,
    bool goToLastChapter = false,
  }) async {
    setState(() {
      _selectedBookName = book['short_name'];
      _selectedBookNumber = book['book_number'];
      _selectedVerses.clear();
    });

    await _loadMaxChapter();

    // Determine which chapter to load
    if (goToLastChapter) {
      setState(() {
        _selectedChapter = _maxChapter;
        _selectedVerse = 1;
      });
    } else if (chapter != null) {
      setState(() {
        _selectedChapter = chapter;
        _selectedVerse = 1;
      });
    } else {
      setState(() {
        _selectedChapter = 1;
        _selectedVerse = 1;
      });
    }

    await _loadVerses();
    _scrollToTop();
  }

  Future<void> _switchVersion(BibleVersion newVersion) async {
    if (newVersion.name == _selectedVersion.name) return;

    setState(() {
      _isLoading = true;
    });

    _selectedVersion = newVersion;

    // Show a brief message that the version is being loaded
    if (mounted) {
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'bible.loading_version'.tr({'version': newVersion.name}),
            style: TextStyle(color: colorScheme.onSecondary),
          ),
          backgroundColor: colorScheme.secondary,
          duration: const Duration(seconds: 1),
        ),
      );
    }

    await _initVersion();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // First, try to parse as a Bible reference
    final reference = BibleReferenceParser.parse(query);

    if (reference != null) {
      // It's a Bible reference - try to navigate directly
      final bookName = reference['bookName'] as String;
      final chapter = reference['chapter'] as int;
      // Note: verse is available but not used for scrolling yet
      // Future enhancement could scroll to specific verse
      // final verse = reference['verse'] as int?;

      // Try to find the book in the database
      final book = await _selectedVersion.service!.findBookByName(bookName);

      if (book != null) {
        // Book found - navigate to it
        final bookNumber = book['book_number'] as int;
        final maxChapter =
            await _selectedVersion.service!.getMaxChapter(bookNumber);

        // Validate chapter exists
        if (chapter > 0 && chapter <= maxChapter) {
          setState(() {
            _selectedBookName = book['short_name'];
            _selectedBookNumber = bookNumber;
            _selectedChapter = chapter;
            _isSearching = false;
            _searchResults = [];
            _searchController.clear();
            _isLoading = false;
          });

          await _loadMaxChapter();
          await _loadVerses();

          // Close keyboard
          if (mounted) {
            FocusScope.of(context).unfocus();
          }

          return;
        }
      }
    }

    // Not a valid reference or book not found - fall back to text search
    final results = await _selectedVersion.service!.searchVerses(query);

    setState(() {
      _searchResults = results;
      _isSearching = true;
      _isLoading = false;
    });
  }

  void _jumpToSearchResult(Map<String, dynamic> result) async {
    final bookNumber = result['book_number'] as int;
    final chapter = result['chapter'] as int;
    final verse = result['verse'] as int;

    // Find the book
    final book = _books.firstWhere(
      (b) => b['book_number'] == bookNumber,
      orElse: () => _books[0],
    );

    setState(() {
      _selectedBookName = book['short_name'];
      _selectedBookNumber = bookNumber;
      _selectedChapter = chapter;
      _isSearching = false;
      _searchResults = [];
      _searchController.clear();
    });

    await _loadMaxChapter();
    await _loadVerses();

    // Scroll to the found verse
    _scrollToVerse(verse);

    // Close keyboard
    if (mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  void _onVerseTap(int verseNumber) {
    final key = "$_selectedBookName|$_selectedChapter|$verseNumber";
    setState(() {
      if (_selectedVerses.contains(key)) {
        _selectedVerses.remove(key);
      } else {
        _selectedVerses.add(key);
      }
    });
    if (_selectedVerses.isNotEmpty && !_bottomSheetOpen) {
      _showBottomSheet();
    } else if (_selectedVerses.isEmpty && _bottomSheetOpen) {
      Navigator.of(context).pop();
      _bottomSheetOpen = false;
    }
  }

  void _showBottomSheet() {
    _bottomSheetOpen = true;

    final parentContext = context; // Capture the State's context

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BibleReaderActionModal(
          selectedVersesText: _getSelectedVersesText(),
          selectedVersesReference: _getSelectedVersesReference(),
          onSave: () => _saveSelectedVerses(context),
          onCopy: () => _copySelectedVerses(context),
          onShare: _shareSelectedVerses,
          onImage: () {
            // TODO: Implement image sharing
            Navigator.pop(context);
          },
        );
      },
    ).whenComplete(() {
      _bottomSheetOpen = false;
    });
  }

  //text normalizer
  String _cleanVerseText(dynamic text) {
    return BibleTextNormalizer.clean(text?.toString());
  }

  String _getSelectedVersesText() {
    return BibleVerseFormatter.formatVerses(
      selectedVerseKeys: _selectedVerses,
      verses: _verses,
      books: _books,
      versionName: _selectedVersion.name,
      cleanText: _cleanVerseText,
    );
  }

  String _getSelectedVersesReference() {
    if (_selectedVerses.isEmpty) return '';

    final sortedVerses = _selectedVerses.toList()..sort();
    final parts = sortedVerses.first.split('|');
    final book = parts[0];
    final chapter = parts[1];

    if (_selectedVerses.length == 1) {
      final verse = parts[2];
      return '$book $chapter:$verse';
    } else {
      final firstVerse = int.parse(parts[2]);
      final lastParts = sortedVerses.last.split('|');
      final lastVerse = int.parse(lastParts[2]);

      if (firstVerse == lastVerse) {
        return '$book $chapter:$firstVerse';
      } else {
        return '$book $chapter:$firstVerse-$lastVerse';
      }
    }
  }

  void _shareSelectedVerses() {
    final text = _getSelectedVersesText();
    SharePlus.instance.share(ShareParams(text: text));
  }

  void _copySelectedVerses(BuildContext modalContext) {
    final text = _getSelectedVersesText();
    Clipboard.setData(ClipboardData(text: text));
    Navigator.pop(modalContext);
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'bible.copied_to_clipboard'.tr(),
          style: TextStyle(color: colorScheme.onSecondary),
        ),
        backgroundColor: colorScheme.secondary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _saveSelectedVerses(BuildContext modalContext) async {
    // Add selected verses to persistent marked verses
    for (final verseKey in _selectedVerses) {
      _persistentlyMarkedVerses.add(verseKey);
    }

    // Pop the modal immediately before any async/await
    Navigator.pop(modalContext);

    // Save to SharedPreferences
    await _saveMarkedVerses();

    // Clear selection...
    if (!mounted) return;
    setState(() {
      _selectedVerses.clear();
    });

    // Show confirmation
    final colorScheme = Theme.of(context).colorScheme;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'bible.save_marked_verses'.tr(),
            style: TextStyle(color: colorScheme.onSecondary),
          ),
          backgroundColor: colorScheme.secondary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Stack(
          children: [
            CustomAppBar(
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'bible.title'.tr(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                  ),
                  if (!_isLoading)
                    Text(
                      '${_selectedVersion.name} (${_selectedVersion.language})',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withValues(alpha: 0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                ],
              ),
            ),
            // Font size toggle button
            Positioned(
              right: _availableVersions.length > 1 ? 48 : 0,
              top: 0,
              bottom: 0,
              child: SafeArea(
                child: IconButton(
                  icon: Icon(
                    Icons.format_size,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  tooltip: 'bible.adjust_font_size'.tr(),
                  onPressed: () {
                    setState(() {
                      _showFontControls = !_showFontControls;
                    });
                  },
                ),
              ),
            ),
            if (_availableVersions.length > 1)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: SafeArea(
                  child: PopupMenuButton<BibleVersion>(
                    icon: Icon(
                      Icons.menu,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary, // always white
                    ),
                    tooltip: 'bible.select_version'.tr(),
                    onSelected: _switchVersion,
                    itemBuilder: (context) => _availableVersions.map((version) {
                      return PopupMenuItem<BibleVersion>(
                        value: version,
                        child: Row(
                          children: [
                            if (version.name == _selectedVersion.name)
                              Icon(Icons.check,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20)
                            else
                              const SizedBox(width: 20),
                            const SizedBox(width: 8),
                            Text(version.name),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('bible.loading'.tr()),
                ],
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  // Search bar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'bible.search_placeholder'.tr(),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _isSearching = false;
                                    _searchResults = [];
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: _performSearch,
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                  // Show search results if searching
                  if (_isSearching)
                    Expanded(
                      child: _buildSearchResults(colorScheme),
                    )
                  else ...[
                    // Book and chapter selector
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: InkWell(
                              onTap: _showBookSelector,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: colorScheme.outline
                                        .withValues(alpha: 0.5),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.auto_stories_outlined,
                                        size: 20, color: colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _selectedBookName != null
                                            ? _books.firstWhere((b) =>
                                                b['short_name'] ==
                                                _selectedBookName)['long_name']
                                            : 'Seleccionar libro',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.arrow_drop_down,
                                        color: colorScheme.onSurface),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButton<int>(
                              value: _selectedChapter,
                              icon: const Icon(Icons.arrow_drop_down),
                              isExpanded: true,
                              items: List.generate(_maxChapter, (i) => i + 1)
                                  .map(
                                    (ch) => DropdownMenuItem<int>(
                                      value: ch,
                                      child: Text('bible.chapter'
                                          .tr({'number': ch.toString()})),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) async {
                                if (val == null) return;
                                setState(() {
                                  _selectedChapter = val;
                                  _selectedVerse = 1; // Reset to verse 1
                                  _selectedVerses.clear();
                                });
                                await _loadVerses();
                                _scrollToTop(); // Scroll to top of new chapter
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showVerseGridSelector(),
                              icon: const Icon(Icons.format_list_numbered,
                                  size: 18),
                              label: Text(
                                'V. $_selectedVerse',
                                style: const TextStyle(fontSize: 14),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Font size controls (collapsible)
                    if (_showFontControls)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          border: Border(
                            bottom: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.text_decrease),
                              onPressed: _decreaseFontSize,
                              tooltip: 'bible.decrease_font'.tr(),
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'bible.font_size_label'.tr(),
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.text_increase),
                              onPressed: _increaseFontSize,
                              tooltip: 'bible.increase_font'.tr(),
                              color: colorScheme.primary,
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () {
                                setState(() {
                                  _showFontControls = false;
                                });
                              },
                              tooltip: 'Cerrar',
                            ),
                          ],
                        ),
                      ),
                    // Verses list
                    Expanded(
                      child: _verses.isEmpty
                          ? Center(child: Text('bible.no_verses'.tr()))
                          : ListView.builder(
                              controller: _scrollController,
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 32),
                              // <-- extra bottom padding
                              itemCount: _verses.length,
                              itemBuilder: (context, idx) {
                                final verse = _verses[idx];
                                final verseNumber = verse['verse'];
                                final key =
                                    "$_selectedBookName|$_selectedChapter|$verseNumber";
                                final isSelected =
                                    _selectedVerses.contains(key);
                                final isPersistentlyMarked =
                                    _persistentlyMarkedVerses.contains(key);
                                return GestureDetector(
                                  key: _verseKeys[verseNumber],
                                  onTap: () => _onVerseTap(verseNumber),
                                  onLongPress: () =>
                                      _toggleVersePersistentMark(key),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 4),
                                    decoration: isSelected
                                        ? BoxDecoration(
                                            color: colorScheme.primaryContainer
                                                .withValues(alpha: 0.3),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: colorScheme.primary,
                                              width: 2,
                                            ),
                                          )
                                        : null,
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: _fontSize,
                                          color: colorScheme.onSurface,
                                          height: 1.6,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: "${verse['verse']} ",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                              fontSize: 14,
                                            ),
                                          ),
                                          TextSpan(
                                            text:
                                                _cleanVerseText(verse['text']),
                                            style: isPersistentlyMarked
                                                ? TextStyle(
                                                    decoration: TextDecoration
                                                        .underline,
                                                    decorationColor:
                                                        colorScheme.secondary,
                                                    decorationThickness: 2,
                                                    fontWeight: FontWeight.w500,
                                                  )
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    // --- COPYRIGHT / DISCLAIMER ---
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Text(
                        CopyrightUtils.getCopyrightText(
                          _selectedVersion.languageCode,
                          _selectedVersion.name,
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: !_isLoading && _selectedBookName != null
          ? Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous chapter button
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios,
                            color: colorScheme.primary),
                        tooltip: 'bible.previous_chapter'.tr(),
                        onPressed: _goToPreviousChapter,
                      ),
                      // Current book and chapter display
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: _showBookSelector,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 6.0, horizontal: 4.0),
                            child: Text(
                              _selectedBookName != null
                                  ? '${_books.firstWhere((b) => b['short_name'] == _selectedBookName, orElse: () => {
                                        'long_name': _selectedBookName
                                      })['long_name']} $_selectedChapter'
                                  : '',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                    // Optional: highlight as clickable
                                    decoration: TextDecoration.underline,
                                    // Optional: hint it's a button
                                    decorationColor: colorScheme.primary,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      // Next chapter button
                      IconButton(
                        icon: Icon(Icons.arrow_forward_ios,
                            color: colorScheme.primary),
                        tooltip: 'bible.next_chapter'.tr(),
                        onPressed: _goToNextChapter,
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  /// Helper method to build highlighted text spans for search results
  List<TextSpan> _buildHighlightedTextSpans(
    String text,
    String query,
    ColorScheme colorScheme,
  ) {
    if (query.trim().isEmpty) {
      return [
        TextSpan(
          text: text,
          style: TextStyle(
            fontSize: 15,
            color: colorScheme.onSurface,
            height: 1.4,
          ),
        ),
      ];
    }

    final List<TextSpan> spans = [];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int lastIndex = 0;

    // Find all occurrences of the query (case-insensitive)
    while (true) {
      final index = lowerText.indexOf(lowerQuery, lastIndex);
      if (index == -1) {
        // Add remaining text
        if (lastIndex < text.length) {
          spans.add(
            TextSpan(
              text: text.substring(lastIndex),
              style: TextStyle(
                fontSize: 15,
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          );
        }
        break;
      }

      // Add text before match
      if (index > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, index),
            style: TextStyle(
              fontSize: 15,
              color: colorScheme.onSurface,
              height: 1.4,
            ),
          ),
        );
      }

      // Add highlighted match
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(
            fontSize: 15,
            color: colorScheme.onSurface,
            height: 1.4,
            fontWeight: FontWeight.bold,
            backgroundColor: colorScheme.primaryContainer,
            decoration: TextDecoration.underline,
            decorationColor: colorScheme.primary,
          ),
        ),
      );

      lastIndex = index + query.length;
    }

    return spans;
  }

  Widget _buildSearchResults(ColorScheme colorScheme) {
    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'bible.no_matches_retry'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, idx) {
        final result = _searchResults[idx];
        final bookName = result['long_name'] ?? result['short_name'];
        final chapter = result['chapter'];
        final verse = result['verse'];
        final text = _cleanVerseText(result['text']);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _jumpToSearchResult(result),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$bookName $chapter:$verse',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: _buildHighlightedTextSpans(
                        text,
                        _searchController.text,
                        colorScheme,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
