import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/bible_version.dart';
import 'package:devocional_nuevo/services/bible_db_service.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedVersion = widget.versions.first;
    _initVersion();
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // If all verses are deselected, close the sheet
            if (_selectedVerses.isEmpty) {
              Future.delayed(Duration.zero, () {
                if (mounted && Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              });
            }
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
                          onPressed: () => _copySelectedVerses(),
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

  String _cleanVerseText(dynamic text) {
    if (text == null) return '';
    return text.toString().trim();
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

  void _copySelectedVerses() {
    final text = _getSelectedVersesText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('bible.copied_to_clipboard'.tr()),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('bible.title'.tr()),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('bible.loading'.tr()),
                ],
              ),
            )
          : Column(
              children: [
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
                          padding: const EdgeInsets.all(16),
                          itemCount: _verses.length,
                          itemBuilder: (context, idx) {
                            final verse = _verses[idx];
                            final verseNumber = verse['verse'];
                            final key =
                                "$_selectedBookName|$_selectedChapter|$verseNumber";
                            final isSelected = _selectedVerses.contains(key);
                            return GestureDetector(
                              onTap: () => _onVerseTap(verseNumber),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 4),
                                decoration: isSelected
                                    ? BoxDecoration(
                                        color: colorScheme.primaryContainer
                                            .withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(8),
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
                                        text: _cleanVerseText(verse['text']),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
