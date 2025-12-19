//bible_reader_page.dart - Pure UI presentation layer
import 'dart:ui' as ui;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/utils/copyright_utils.dart';
import 'package:devocional_nuevo/widgets/app_bar_constants.dart';
import 'package:devocional_nuevo/widgets/bible_book_selector_dialog.dart';
import 'package:devocional_nuevo/widgets/bible_chapter_grid_selector.dart';
import 'package:devocional_nuevo/widgets/bible_reader_action_modal.dart';
import 'package:devocional_nuevo/widgets/bible_search_overlay.dart';
import 'package:devocional_nuevo/widgets/bible_verse_grid_selector.dart';
import 'package:devocional_nuevo/widgets/floating_font_control_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus;
import 'package:lottie/lottie.dart';

/// Pure UI presentation layer for Bible Reader
/// All business logic is handled by BibleReaderController
class BibleReaderPage extends StatefulWidget {
  final List<BibleVersion> versions;
  final BibleReaderService? readerService; // Optional for DI
  final BiblePreferencesService? preferencesService; // Optional for DI

  const BibleReaderPage({
    super.key,
    required this.versions,
    this.readerService,
    this.preferencesService,
  });

  @override
  State<BibleReaderPage> createState() => _BibleReaderPageState();
}

class _BibleReaderPageState extends State<BibleReaderPage> {
  late BibleReaderController _controller;
  bool _bottomSheetOpen = false;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();

    // Initialize services with injection
    final readerService = widget.readerService ??
        BibleReaderService(
          dbService: BibleDbService(),
          positionService: BibleReadingPositionService(),
        );
    final preferencesService =
        widget.preferencesService ?? BiblePreferencesService();

    // Create controller with injected services
    _controller = BibleReaderController(
      allVersions: widget.versions,
      readerService: readerService,
      preferencesService: preferencesService,
    );

    // Initialize controller with device language
    final deviceLanguage = ui.PlatformDispatcher.instance.locale.languageCode;
    _controller.initialize(deviceLanguage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // UI helper methods
  void _scrollToVerse(int verseNumber) async {
    final verses = _controller.state.verses;
    if (verses.isEmpty) return;

    final index = verses.indexWhere((v) => v['verse'] == verseNumber);
    if (index == -1) return;

    if (_itemScrollController.isAttached) {
      await _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  void _scrollToTop() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted || !_itemScrollController.isAttached) return;
      _itemScrollController.jumpTo(index: 0);
    });
  }

  Future<void> _showVerseGridSelector() async {
    final state = _controller.state;
    if (state.selectedBookName == null || state.selectedChapter == null) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return BibleVerseGridSelector(
          totalVerses: state.maxVerse,
          selectedVerse: state.selectedVerse ?? 1,
          bookName: state.books.firstWhere(
              (b) => b['short_name'] == state.selectedBookName)['long_name'],
          chapterNumber: state.selectedChapter!,
          onVerseSelected: (verseNumber) {
            Navigator.of(context).pop();
            _controller.selectVerse(verseNumber);
            Future.delayed(const Duration(milliseconds: 100), () {
              _scrollToVerse(verseNumber);
            });
          },
        );
      },
    );
  }

  Future<void> _showChapterGridSelector() async {
    final state = _controller.state;
    if (state.selectedBookName == null) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return BibleChapterGridSelector(
          totalChapters: state.maxChapter,
          selectedChapter: state.selectedChapter ?? 1,
          bookName: state.books.firstWhere(
              (b) => b['short_name'] == state.selectedBookName)['long_name'],
          onChapterSelected: (chapterNumber) async {
            Navigator.of(context).pop();
            await _controller.selectChapter(chapterNumber);
            _scrollToTop(); // Always scroll to top after chapter change
          },
        );
      },
    );
  }

  Future<void> _showBookSelector() async {
    final state = _controller.state;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return BibleBookSelectorDialog(
          books: state.books,
          selectedBookName: state.selectedBookName,
          onBookSelected: (book) async {
            await _controller.selectBook(book);
            _scrollToTop();
          },
        );
      },
    );
  }

  void _showSearchOverlay() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return BibleSearchOverlay(
          controller: _controller,
          onScrollToVerse: _scrollToVerse,
          cleanVerseText: _cleanVerseText,
        );
      },
    );
  }

  void _onVerseTap(int verseNumber) {
    final state = _controller.state;
    final key =
        "${state.selectedBookName}|${state.selectedChapter}|$verseNumber";
    final wasSelected = state.selectedVerses.contains(key);

    debugPrint(
        '[BibleReader] Tapping verse $verseNumber, key: $key, wasSelected: $wasSelected');
    debugPrint(
        '[BibleReader] Before tap: selectedVerses: ${state.selectedVerses}, selectedVerse: ${state.selectedVerse}, scroll attached: ${_itemScrollController.isAttached}');

    _controller.toggleVerseSelection(key);

    final afterState = _controller.state;
    debugPrint(
        '[BibleReader] After tap: selectedVerses: ${afterState.selectedVerses}, selectedVerse: ${afterState.selectedVerse}');

    // Do not update selectedVerse, do not scroll!
    // Only show/hide modal if needed
    if (!wasSelected) {
      if (afterState.selectedVerses.isNotEmpty && !_bottomSheetOpen) {
        debugPrint('[BibleReader] Opening bottom sheet');
        _showBottomSheet();
      }
    } else {
      if (afterState.selectedVerses.isEmpty && _bottomSheetOpen) {
        debugPrint('[BibleReader] Closing bottom sheet');
        Navigator.of(context).pop();
        _bottomSheetOpen = false;
      }
    }
  }

  void _showBottomSheet() {
    _bottomSheetOpen = true;

    // Check if all selected verses are already saved
    final selectedVerses = _controller.state.selectedVerses.toList();
    final persistentlyMarkedVerses = _controller.state.persistentlyMarkedVerses;
    final areVersesSaved =
        selectedVerses.every((key) => persistentlyMarkedVerses.contains(key));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BibleReaderActionModal(
          selectedVersesText: _getSelectedVersesText(),
          selectedVersesReference: _getSelectedVersesReference(),
          onSave: () => _saveSelectedVerses(context),
          onCopy: () => _copySelectedVerses(context),
          onShare: () => _shareSelectedVerses(context),
          onImage: () {
            Navigator.pop(context);
            _controller.clearSelectedVerses();
          },
          areVersesSaved: areVersesSaved,
          onDeleteSaved:
              areVersesSaved ? () => _deleteSelectedVerses(context) : null,
        );
      },
    ).whenComplete(() {
      _bottomSheetOpen = false;
    });
  }

  String _cleanVerseText(dynamic text) {
    return BibleTextNormalizer.clean(text?.toString());
  }

  String _getSelectedVersesText() {
    final state = _controller.state;
    return BibleVerseFormatter.formatVerses(
      selectedVerseKeys: state.selectedVerses,
      verses: state.verses,
      books: state.books,
      versionName: state.selectedVersion?.name ?? '',
      cleanText: _cleanVerseText,
    );
  }

  String _getSelectedVersesReference() {
    final selectedVerses = _controller.state.selectedVerses;
    if (selectedVerses.isEmpty) return '';

    final sortedVerses = selectedVerses.toList()..sort();
    final parts = sortedVerses.first.split('|');
    final book = parts[0];
    final chapter = parts[1];

    if (selectedVerses.length == 1) {
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

  void _shareSelectedVerses(BuildContext modalContext) {
    final text = _getSelectedVersesText();
    SharePlus.instance.share(ShareParams(text: text));
    Navigator.pop(modalContext);
    _controller.clearSelectedVerses();
  }

  void _copySelectedVerses(BuildContext modalContext) {
    final text = _getSelectedVersesText();
    Clipboard.setData(ClipboardData(text: text));
    Navigator.pop(modalContext);
    _controller.clearSelectedVerses();
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
    final selectedVerses = List.from(_controller.state.selectedVerses);
    for (final verseKey in selectedVerses) {
      await _controller.togglePersistentMark(verseKey);
    }

    if (!mounted) return;

    // Close modal immediately after mounted check
    if (modalContext.mounted) {
      Navigator.pop(modalContext);
    }
    _controller.clearSelectedVerses();

    // Capture widget's context-dependent values immediately after mounted check
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    scaffoldMessenger.showSnackBar(
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

  void _deleteSelectedVerses(BuildContext modalContext) async {
    final selectedVerses = List.from(_controller.state.selectedVerses);
    for (final verseKey in selectedVerses) {
      // Toggle will remove the mark if it's already marked
      await _controller.togglePersistentMark(verseKey);
    }

    if (!mounted) return;

    // Close modal immediately after mounted check
    if (modalContext.mounted) {
      Navigator.pop(modalContext);
    }
    _controller.clearSelectedVerses();

    // Capture widget's context-dependent values immediately after mounted check
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          'bible.deleted_marked_verses'.tr(),
          style: TextStyle(color: colorScheme.onSecondary),
        ),
        backgroundColor: colorScheme.secondary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;
    return StreamBuilder<BibleReaderState>(
      stream: _controller.stateStream,
      initialData: _controller.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? _controller.state;
        final colorScheme = Theme.of(context).colorScheme;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (state.selectedVerse != null &&
              state.verses.any((v) => v['verse'] == state.selectedVerse) &&
              state.isSearching) {
            _scrollToVerse(state.selectedVerse!);
          } else if (state.verses.isNotEmpty &&
              state.selectedVerses.isEmpty &&
              !state.isSearching &&
              state.selectedVerse == 1 &&
              !ModalRoute.of(context)!.isCurrent) {
            _scrollToTop();
          }
        });

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: themeState.systemUiOverlayStyle,
          child: Scaffold(
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
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                        ),
                        if (!state.isLoading && state.selectedVersion != null)
                          Text(
                            '${state.selectedVersion!.name} (${state.selectedVersion!.language})',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
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
                  Positioned(
                    right: state.availableVersions.length > 1 ? 96 : 48,
                    top: 0,
                    bottom: 0,
                    child: SafeArea(
                      child: IconButton(
                        icon: Icon(
                          Icons.search,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        tooltip: 'bible.search'.tr(),
                        onPressed: _showSearchOverlay,
                      ),
                    ),
                  ),
                  Positioned(
                    right: state.availableVersions.length > 1 ? 48 : 0,
                    top: 0,
                    bottom: 0,
                    child: SafeArea(
                      child: IconButton(
                        icon: Icon(
                          Icons.text_increase_outlined,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        tooltip: 'bible.adjust_font_size'.tr(),
                        onPressed: () => _controller.toggleFontControls(),
                      ),
                    ),
                  ),
                  if (state.availableVersions.length > 1)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: SafeArea(
                        child: PopupMenuButton<BibleVersion>(
                          icon: Icon(
                            Icons.menu,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          tooltip: 'bible.select_version'.tr(),
                          onSelected: (version) async {
                            final scaffoldMessenger =
                                ScaffoldMessenger.of(context);
                            final colorScheme = Theme.of(context).colorScheme;
                            await _controller.switchVersion(version);
                            if (!mounted) return;
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'bible.loading_version'
                                      .tr({'version': version.name}),
                                  style:
                                      TextStyle(color: colorScheme.onSecondary),
                                ),
                                backgroundColor: colorScheme.secondary,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          itemBuilder: (context) =>
                              state.availableVersions.map((version) {
                            return PopupMenuItem<BibleVersion>(
                              value: version,
                              child: Row(
                                children: [
                                  if (version.name ==
                                      state.selectedVersion?.name)
                                    Icon(Icons.check,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
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
            body: Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
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
                                      color: Theme.of(context)
                                              .outlinedButtonTheme
                                              .style
                                              ?.side
                                              ?.resolve({})?.color ??
                                          colorScheme.outline,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.auto_stories_outlined,
                                          size: 20, color: colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          state.selectedBookName != null
                                              ? state.books.firstWhere((b) =>
                                                      b['short_name'] ==
                                                      state.selectedBookName)[
                                                  'long_name']
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
                              child: OutlinedButton.icon(
                                onPressed: _showChapterGridSelector,
                                icon: Icon(Icons.format_list_numbered,
                                    size: 18, color: colorScheme.primary),
                                label: Text(
                                  'C. ${state.selectedChapter ?? 1}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _showVerseGridSelector,
                                icon: const Icon(Icons.format_list_numbered,
                                    size: 18),
                                label: Text(
                                  'V. ${state.selectedVerse ?? 1}',
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
                      Expanded(
                        child: state.verses.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Lottie animation shown while loading the Bible version
                                    Lottie.asset(
                                      'assets/lottie/book_stars.json',
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.contain,
                                      repeat: true,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'bible.loading_version'.tr({
                                        'version':
                                            state.selectedVersion?.name ?? ''
                                      }),
                                    ),
                                  ],
                                ),
                              )
                            : ScrollablePositionedList.builder(
                                itemScrollController: _itemScrollController,
                                itemPositionsListener: _itemPositionsListener,
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 32),
                                itemCount: state.verses.length + 2,
                                // +1 título, +1 disclaimer
                                itemBuilder: (context, idx) {
                                  if (idx == 0) {
                                    // Título como primer elemento scrollable
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        state.selectedBookName != null &&
                                                state.selectedChapter != null
                                            ? '${state.books.firstWhere((b) => b['short_name'] == state.selectedBookName, orElse: () => {
                                                  'long_name':
                                                      state.selectedBookName
                                                })['long_name']} ${state.selectedChapter}'
                                            : '',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  }
                                  // Último item: disclaimer de copyright
                                  if (idx == state.verses.length + 1) {
                                    if (state.selectedVersion == null) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 24),
                                      child: Text(
                                        CopyrightUtils.getCopyrightText(
                                            state.selectedVersion!.languageCode,
                                            state.selectedVersion!.name),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                color: colorScheme.onSurface
                                                    .withValues(alpha: 153)),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  }
                                  // Versos
                                  final verse = state.verses[idx - 1];
                                  final verseNumber = verse['verse'];
                                  final key =
                                      "${state.selectedBookName}|${state.selectedChapter}|$verseNumber";
                                  final isSelected =
                                      state.selectedVerses.contains(key);
                                  final isPersistentlyMarked = state
                                      .persistentlyMarkedVerses
                                      .contains(key);
                                  return GestureDetector(
                                    onTap: () => _onVerseTap(verseNumber),
                                    onLongPress: () =>
                                        _controller.togglePersistentMark(key),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 4),
                                      decoration: isSelected
                                          ? BoxDecoration(
                                              color: colorScheme
                                                  .primaryContainer
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
                                            fontSize: state.fontSize,
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
                                              text: _cleanVerseText(
                                                  verse['text']),
                                              style: isPersistentlyMarked
                                                  ? TextStyle(
                                                      backgroundColor:
                                                          colorScheme.secondary
                                                              .withValues(
                                                                  alpha: 0.25),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    )
                                                  : null,
                                            )
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
                ),
                if (state.showFontControls)
                  FloatingFontControlButtons(
                    currentFontSize: state.fontSize,
                    onIncrease: _controller.increaseFontSize,
                    onDecrease: _controller.decreaseFontSize,
                    onClose: () => _controller.setFontControlsVisibility(false),
                  ),
              ],
            ),
            bottomNavigationBar: !state.isLoading &&
                    state.selectedBookName != null
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back_ios,
                                  color: colorScheme.primary),
                              tooltip: 'bible.previous_chapter'.tr(),
                              onPressed: () async {
                                await _controller.goToPreviousChapter();
                                _scrollToTop();
                              },
                            ),
                            // Button sizes to its content; avoid IntrinsicWidth to prevent intrinsic-measurement errors
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: ElevatedButton(
                                onPressed: _showBookSelector,
                                style: ElevatedButton.styleFrom(
                                  // allow the button to shrink to fit content
                                  minimumSize: const Size(0, 0),
                                  backgroundColor: colorScheme.primaryContainer,
                                  foregroundColor: colorScheme.onPrimaryContainer,
                                  elevation: 2,
                                  shadowColor:
                                      colorScheme.primary.withValues(alpha: 0.3),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0, horizontal: 16.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: AutoSizeText(
                                  state.selectedBookName != null
                                      ? '${state.books.firstWhere((b) => b['short_name'] == state.selectedBookName, orElse: () => {
                                            'long_name': state.selectedBookName
                                          })['long_name']} ${state.selectedChapter}'
                                      : '',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onPrimaryContainer,
                                      ),
                                  maxLines: 1,
                                  minFontSize: 11,
                                  maxFontSize: 15,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.arrow_forward_ios,
                                  color: colorScheme.primary),
                              tooltip: 'bible.next_chapter'.tr(),
                              onPressed: () async {
                                await _controller.goToNextChapter();
                                _itemScrollController.jumpTo(index: 0);
                                _scrollToTop();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
