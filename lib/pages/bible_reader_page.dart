import 'dart:ui' as ui;

import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/bible_version.dart';
import 'package:devocional_nuevo/services/bible_db_service.dart';
import 'package:devocional_nuevo/services/bible_reading_position_service.dart';
import 'package:devocional_nuevo/utils/bible_text_normalizer.dart';
import 'package:devocional_nuevo/utils/copyright_utils.dart';
import 'package:devocional_nuevo/widgets/app_bar_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus;

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
  int _maxChapter = 1;
  List<Map<String, dynamic>> _verses = [];
  final Set<String> _selectedVerses = {}; // format: "book|chapter|verse"
  final double _fontSize = 18;
  bool _bottomSheetOpen = false;
  bool _isLoading = true;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  final BibleReadingPositionService _positionService =
      BibleReadingPositionService();

  @override
  void initState() {
    super.initState();
    _detectLanguageAndInitialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      backgroundColor: Theme.of(parentContext).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // If all verses are deselected, close the sheet

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'bible.selected_verses'
                        .tr({'count': '${_selectedVerses.length}'}),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _shareSelectedVerses(),
                          icon: const Icon(Icons.share),
                          label: Text('bible.share'.tr()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _copySelectedVerses(context),
                          // <-- pass modal context
                          icon: const Icon(Icons.copy),
                          label: Text('bible.copy'.tr()),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedVerses.clear();
                      });
                      Navigator.of(context).pop();
                      _bottomSheetOpen = false;
                    },
                    icon: const Icon(Icons.clear_all),
                    label: Text('bible.clear_selection'.tr()),
                  ),
                ],
              ),
            );
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
    final List<String> lines = [];
    final sortedVerses = _selectedVerses.toList()..sort();

    for (final key in sortedVerses) {
      final parts = key.split('|');
      final book = parts[0];
      final chapter = parts[1];
      final verseNum = int.parse(parts[2]);

      final verse = _verses.firstWhere(
        (v) => v['verse'] == verseNum,
        orElse: () => {},
      );

      if (verse.isNotEmpty) {
        lines.add(
            '$book $chapter:$verseNum - ${_cleanVerseText(verse['text'])}');
      }
    }

    return lines.join('\n\n');
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
                            child: DropdownButton<String>(
                              value: _selectedBookName,
                              icon: const Icon(Icons.arrow_drop_down),
                              isExpanded: true,
                              items: _books
                                  .map((b) => DropdownMenuItem<String>(
                                        value: b['short_name'],
                                        child: Text(
                                          b['long_name'],
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (val) async {
                                if (val == null) return;
                                final book = _books
                                    .firstWhere((b) => b['short_name'] == val);
                                setState(() {
                                  _selectedBookName = val;
                                  _selectedBookNumber = book['book_number'];
                                  _selectedChapter = 1;
                                  _selectedVerses.clear();
                                });
                                await _loadMaxChapter();
                                await _loadVerses();
                              },
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
                                  _selectedVerses.clear();
                                });
                                await _loadVerses();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Verses list
                    Expanded(
                      child: _verses.isEmpty
                          ? Center(child: Text('bible.no_verses'.tr()))
                          : ListView.builder(
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
                                return GestureDetector(
                                  onTap: () => _onVerseTap(verseNumber),
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
    );
  }

  Widget _buildSearchResults(ColorScheme colorScheme) {
    if (_searchResults.isEmpty) {
      return Center(
        child: Text('bible.no_search_results'.tr()),
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
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      color: colorScheme.onSurface,
                      height: 1.4,
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
