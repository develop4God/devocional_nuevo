//bible_reader_page.dart - Pure UI presentation layer
import 'dart:async';
import 'dart:ui' as ui;

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/blocs/bible_note_bloc.dart';
import 'package:devocional_nuevo/blocs/bible_note_state.dart';
import 'package:devocional_nuevo/blocs/bible_versions/bible_versions_bloc.dart';
import 'package:devocional_nuevo/blocs/bible_versions/bible_versions_event.dart';
import 'package:devocional_nuevo/blocs/bible_versions/bible_versions_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/controllers/tts_auto_scroll_driver.dart';
import 'package:devocional_nuevo/controllers/tts_scroll_target.dart';
import 'package:devocional_nuevo/services/tts/utils/tts_chunk_processor.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/utils/constants/bubble_constants.dart';
import 'package:devocional_nuevo/repositories/i_bible_version_repository.dart';
import 'package:devocional_nuevo/services/i_analytics_service.dart';
import 'package:devocional_nuevo/services/i_user_recency_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/bible_reader_tts_text_builder.dart';
import 'package:devocional_nuevo/services/tts/tts_verse_index_resolver.dart';
import 'package:devocional_nuevo/services/tts/bible_text_formatter.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:devocional_nuevo/utils/constants/constants.dart';
import 'package:devocional_nuevo/widgets/app_snack_bar.dart';
import 'package:devocional_nuevo/widgets/bible/bible_book_selector_dialog.dart';
import 'package:devocional_nuevo/widgets/bible/bible_chapter_grid_selector.dart';
import 'package:devocional_nuevo/widgets/bible/bible_note_modal.dart';
import 'package:devocional_nuevo/widgets/bible/bible_note_viewer.dart';
import 'package:devocional_nuevo/widgets/bible/bible_reader_action_modal.dart';
import 'package:devocional_nuevo/widgets/bible/bible_reader_bottom_bar.dart';
import 'package:devocional_nuevo/widgets/bible/bible_reader_drawer.dart';
import 'package:devocional_nuevo/widgets/bible/bible_reader_selector_bar.dart';
import 'package:devocional_nuevo/widgets/bible/bible_reader_tts_miniplayer_presenter.dart';
import 'package:devocional_nuevo/widgets/bible/bible_search_overlay.dart';
import 'package:devocional_nuevo/widgets/bible/bible_verse_grid_selector.dart';
import 'package:devocional_nuevo/widgets/bible/bible_verse_list_view.dart';
import 'package:devocional_nuevo/widgets/bible/kjv_kj2000_banner.dart';
import 'package:devocional_nuevo/widgets/devocionales/app_bar_constants.dart';
import 'package:devocional_nuevo/widgets/floating_font_control_buttons.dart';
import 'package:devocional_nuevo/widgets/modern_voice_feature_dialog.dart';
import 'package:devocional_nuevo/widgets/voice_selector_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus;
import 'package:shared_preferences/shared_preferences.dart';

/// Pure UI presentation layer for Bible Reader
/// All business logic is handled by BibleReaderController
class BibleReaderPage extends StatefulWidget {
  final List<BibleVersion> versions;
  final BibleReaderService? readerService; // Optional for DI
  final BiblePreferencesService? preferencesService; // Optional for DI
  /// Optional [FlutterTts] instance for dependency injection / testing.
  /// When null a new instance is created internally in [initState].
  final FlutterTts? flutterTts;

  /// Optional book/chapter/verse to jump to on open, e.g. when arriving from
  /// a saved note. Applied once, after the reader finishes loading.
  final ({String bookName, int chapter, int verse})? initialReference;

  /// Called after a version finishes downloading from the drawer, so the
  /// parent (e.g. app_navigation_shell's Bible tab) can refresh its version
  /// list. Optional so BibleReaderPage remains usable standalone.
  final VoidCallback? onVersionsMayHaveChanged;

  const BibleReaderPage({
    super.key,
    required this.versions,
    this.readerService,
    this.preferencesService,
    this.flutterTts,
    this.initialReference,
    this.onVersionsMayHaveChanged,
  });

  @override
  State<BibleReaderPage> createState() => _BibleReaderPageState();
}

class _BibleReaderPageState extends State<BibleReaderPage> {
  late BibleReaderController _controller;
  late BibleVersionsBloc _versionsBloc;
  bool _bottomSheetOpen = false;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  // TTS fields — FlutterTts is resolved in initState (not at field-level) so
  // that an injected instance from widget.flutterTts takes precedence.
  late final TtsAudioController _ttsAudioController;
  late final BibleReaderTtsMiniplayerPresenter _ttsMiniplayerPresenter;
  late final TtsAutoScrollDriver _ttsAutoScrollDriver;
  late final VoiceSettingsService _voiceSettingsService;

  // Cached verse-index resolver for TTS highlight. Rebuilt when the verse list
  // identity changes (a new chapter loads), keyed by the verses list
  // reference itself (compared via identical()) so we don't recompute
  // cumulative word counts on every playback tick.
  TtsVerseIndexResolver? _cachedVerseResolver;
  List<Map<String, dynamic>>? _cachedVerses;
  // Guards addPostFrameCallback callbacks after dispose().
  bool _disposed = false;
  // Set while an initialReference scroll-into-view is still owed, so the
  // post-frame callback in build() knows to act once verses finish loading.
  bool _pendingReferenceScroll = false;

  // Tracks the in-flight download listener from _handleDownloadVersion, so
  // dispose() can cancel it if the page is left mid-download.
  StreamSubscription<BibleVersionsState>? _downloadSubscription;

  // One-time notice about the KJV/KJ2000 relabeling fix (see commit
  // 9c26f98a and related). Shown only to English readers until dismissed.
  static const String _kjvBannerDismissedKey = 'kjv_kj2000_banner_dismissed';
  bool _showKjvBanner = false;

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

    final versionsLanguageCode = widget.versions.isNotEmpty
        ? widget.versions.first.languageCode
        : ui.PlatformDispatcher.instance.locale.languageCode;
    debugPrint(
      '[BibleReaderPage] dispatching LoadAvailableVersions('
      'languageCode=$versionsLanguageCode)',
    );
    _versionsBloc = BibleVersionsBloc(
      repository: getService<IBibleVersionRepository>(),
    )..add(LoadAvailableVersions(languageCode: versionsLanguageCode));

    // ── TTS ──────────────────────────────────────────────────────────────────
    // Resolve all TTS dependencies once at init-time, never inside handlers.
    _voiceSettingsService = getService<VoiceSettingsService>();
    final flutterTts = widget.flutterTts ?? FlutterTts();

    _ttsAudioController = TtsAudioController(
      flutterTts: flutterTts,
      voiceSettingsService: _voiceSettingsService,
      chunkProcessor: getService<TtsChunkProcessor>(),
    );
    _ttsMiniplayerPresenter = BibleReaderTtsMiniplayerPresenter(
      ttsAudioController: _ttsAudioController,
      analyticsService: getService<IAnalyticsService>(),
      // Delegate voice selector to the single implementation on this page.
      onShowVoiceSelector: (ctx, lang, sampleText) =>
          _showBibleVoiceSelector(ctx, lang, sampleText),
    );
    // Auto-scroll + current-verse highlight following TTS playback. The
    // highlight maps the playback fraction onto the verse via cumulative word
    // counts (long verses take proportionally longer), matching the word-based
    // position estimate; only reads the controller's progress notifiers.
    _ttsAutoScrollDriver = TtsAutoScrollDriver(
      controller: _ttsAudioController,
      // leadingCount: 1 — the chapter title occupies list index 0, so verse v
      // renders at list index v + 1.
      target: ItemScrollControllerTarget(
        _itemScrollController,
        itemCount: () => _controller.state.verses.length,
        leadingCount: 1,
      ),
      // Prefer the word-accurate progress offset; fall back to the estimate.
      indexForCharOffset: (offset) =>
          _verseIndexResolver()?.indexForCharOffset(offset),
      indexForFraction: (fraction) =>
          _verseIndexResolver()?.indexForFraction(fraction),
      // Verse count so the scroll follows the resolved verse index (same signal
      // as the highlight), not the faster-running estimated fraction.
      itemCount: () => _controller.state.verses.length,
    )..attach();

    // Auto-open miniplayer when TTS starts playing — same pattern as
    // devocionales_page (tested by 3000+ users in production).
    // Opens on LOADING state for instant feedback; no need to wait for
    // setStartHandler (which can take seconds on large chapters like Psalm 119).
    _ttsAudioController.state.addListener(_handleTtsStateChange);

    // Initialize controller with device language
    final deviceLanguage = ui.PlatformDispatcher.instance.locale.languageCode;
    final initialReference = widget.initialReference;
    debugPrint(
        '[BibleReaderPage] initState initialReference=$initialReference');
    if (initialReference != null) {
      _pendingReferenceScroll = true;
      _controller.initialize(deviceLanguage).then((_) async {
        if (_disposed) {
          debugPrint(
            '[BibleReaderPage] navigateToReference skipped: page disposed',
          );
          return;
        }
        try {
          debugPrint(
            '[BibleReaderPage] calling navigateToReference '
            'book=${initialReference.bookName} '
            'chapter=${initialReference.chapter} '
            'verse=${initialReference.verse}',
          );
          await _controller.navigateToReference(
            bookName: initialReference.bookName,
            chapter: initialReference.chapter,
            verse: initialReference.verse,
          );
          debugPrint('[BibleReaderPage] navigateToReference completed');
        } catch (e) {
          debugPrint('[BibleReaderPage] navigateToReference failed: $e');
        }
      });
    } else {
      _controller.initialize(deviceLanguage);
    }

    if (versionsLanguageCode == 'en') {
      _checkKjvBannerVisibility();
    }
  }

  // Only existing users could have seen the old mislabeled KJV text, so a
  // brand-new user has nothing to be notified about.
  Future<void> _checkKjvBannerVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool(_kjvBannerDismissedKey) ?? false;
    final isNewUser = await getService<IUserRecencyService>().isNewUser();
    if (!dismissed && !isNewUser && mounted) {
      setState(() => _showKjvBanner = true);
    }
  }

  Future<void> _dismissKjvBanner() async {
    setState(() => _showKjvBanner = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kjvBannerDismissedKey, true);
  }

  @override
  void dispose() {
    _disposed = true;
    _ttsAudioController.stop();
    try {
      _ttsAudioController.state.removeListener(_handleTtsStateChange);
    } catch (_) {}
    _ttsAutoScrollDriver.dispose();
    _ttsMiniplayerPresenter.dispose();
    _ttsAudioController.dispose();
    _controller.dispose();
    _downloadSubscription?.cancel();
    _versionsBloc.close();
    super.dispose();
  }

  /// TTS state listener — mirrors the production-validated devocionales_page
  /// implementation (tested by 3000+ users).
  ///
  /// Key differences from the old bible_reader lambda:
  ///  • Opens the modal on [TtsPlayerState.loading] for instant feedback —
  ///    no need to wait for setStartHandler, which can take several seconds
  ///    on large chapters (Psalm 119 = ~12 kB, 4 chunks).
  ///  • Uses [WidgetsBinding.addPostFrameCallback] to avoid calling
  ///    showModalBottomSheet during a ValueNotifier notification frame.
  ///  • Explicitly handles [TtsPlayerState.completed] to close the modal
  ///    instead of relying solely on the modal builder's own close logic.
  void _handleTtsStateChange() {
    try {
      final s = _ttsAudioController.state.value;

      // Show modal immediately when LOADING starts (instant feedback while
      // the TTS engine warms up the first chunk).
      if ((s == TtsPlayerState.loading || s == TtsPlayerState.playing) &&
          mounted &&
          !_ttsMiniplayerPresenter.isShowing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_disposed || !mounted || _ttsMiniplayerPresenter.isShowing) {
            return;
          }
          debugPrint(
            '🎵 [BibleReader Modal] Opening modal on state: $s (instant feedback)',
          );
          _ttsMiniplayerPresenter.showMiniplayerModal(
            context,
            () => _controller.state,
          );
        });
      }

      // Close modal ONLY when audio completes (not on pause/stop/idle).
      // This listener runs BEFORE the modal's ValueListenableBuilder (it was
      // registered first), so resetModalState() here defuses the builder's
      // own auto-close condition — the pop must happen here, same as
      // devocionales_page. The postFrameCallback + canPop guard ensures we
      // only pop the miniplayer sheet, never the page itself.
      if (s == TtsPlayerState.completed) {
        if (_ttsMiniplayerPresenter.isShowing) {
          _ttsMiniplayerPresenter.resetModalState();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_disposed && mounted && Navigator.canPop(context)) {
              debugPrint(
                '🏁 [BibleReader Modal] Closing modal on COMPLETED state (audio finished)',
              );
              Navigator.of(context).pop();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('[BibleReaderPage] Error en _handleTtsStateChange: $e');
    }
  }

  // UI helper methods

  /// Builds (and caches) a [TtsVerseIndexResolver] for the current chapter,
  /// counting words the same way [BibleReaderTtsTextBuilder.build] produces the
  /// spoken text: a "BookName N." header followed by each cleaned verse. Cached
  /// by verse-list identity so it's not recomputed on every playback tick.
  TtsVerseIndexResolver? _verseIndexResolver() {
    final state = _controller.state;
    final verses = state.verses;
    if (verses.isEmpty) return null;

    if (identical(_cachedVerses, verses) && _cachedVerseResolver != null) {
      return _cachedVerseResolver;
    }

    // Mirror BibleReaderTtsTextBuilder.build char-for-char so the offsets the
    // TTS progress handler reports line up with these verse ranges.
    // Header: "BookName N.\n" (only when a book name resolves).
    final bookName = state.selectedBookName != null && state.books.isNotEmpty
        ? BibleVerseFormatter.resolveBookName(
            state.books,
            state.selectedBookName!,
          )
        : '';
    final chapter = state.selectedChapter ?? 1;
    final headerChars = bookName.isEmpty ? 0 : '$bookName $chapter.\n'.length;

    // Each verse contributes "cleanedText\n" (blank verses contribute nothing,
    // matching the builder which skips empty text). The builder trims the
    // whole spoken text at the end, stripping the trailing newline after the
    // last non-empty verse, so that verse's count must match (no +1).
    final verseCharCounts = verses.map((v) {
      final text = BibleTextNormalizer.clean(v['text']?.toString());
      return text.isEmpty ? 0 : text.length + 1; // +1 for the trailing newline
    }).toList();
    final lastNonEmpty = verseCharCounts.lastIndexWhere((c) => c > 0);
    if (lastNonEmpty != -1) {
      verseCharCounts[lastNonEmpty] -= 1;
    }

    final resolver = TtsVerseIndexResolver.fromCharCounts(
      verseCharCounts,
      headerChars: headerChars,
    );
    _cachedVerseResolver = resolver;
    _cachedVerses = verses;
    return resolver;
  }

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
          bookName: BibleVerseFormatter.resolveBookName(
            state.books,
            state.selectedBookName!,
          ),
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
          bookName: BibleVerseFormatter.resolveBookName(
            state.books,
            state.selectedBookName!,
          ),
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
      '[BibleReader] Tapping verse $verseNumber, key: $key, wasSelected: $wasSelected',
    );
    debugPrint(
      '[BibleReader] Before tap: selectedVerses: ${state.selectedVerses}, selectedVerse: ${state.selectedVerse}, scroll attached: ${_itemScrollController.isAttached}',
    );

    _controller.toggleVerseSelection(key);

    final afterState = _controller.state;
    debugPrint(
      '[BibleReader] After tap: selectedVerses: ${afterState.selectedVerses}, selectedVerse: ${afterState.selectedVerse}',
    );

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

  /// The book/chapter/verse range covered by the current verse selection.
  ({String bookName, int chapter, int startVerse, int endVerse})?
      _getSelectedVerseRange() {
    final selectedVerses = _controller.state.selectedVerses;
    if (selectedVerses.isEmpty) return null;

    final sortedVerses = selectedVerses.toList()..sort();
    final firstParts = sortedVerses.first.split('|');
    final lastParts = sortedVerses.last.split('|');

    if (firstParts.length < 3 || lastParts.length < 3) {
      return null;
    }

    final chapter = int.tryParse(firstParts[1]);
    final startVerse = int.tryParse(firstParts[2]);
    final endVerse = int.tryParse(lastParts[2]);
    if (chapter == null || startVerse == null || endVerse == null) {
      return null;
    }

    return (
      bookName: firstParts[0],
      chapter: chapter,
      startVerse: startVerse,
      endVerse: endVerse,
    );
  }

  void _showBottomSheet() {
    _bottomSheetOpen = true;

    // Check if all selected verses are already saved
    final selectedVerses = _controller.state.selectedVerses.toList();
    final persistentlyMarkedVerses = _controller.state.persistentlyMarkedVerses;
    final areVersesSaved = selectedVerses.every(
      (key) => persistentlyMarkedVerses.contains(key),
    );

    final range = _getSelectedVerseRange();
    final noteState = context.read<BibleNoteBloc>().state;
    final hasNote = range != null &&
        noteState is BibleNoteLoaded &&
        noteState.getNoteForRange(
              range.bookName,
              range.chapter,
              range.startVerse,
              range.endVerse,
            ) !=
            null;

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
          onNote: () => _openNoteEditor(context),
          areVersesSaved: areVersesSaved,
          hasNote: hasNote,
          onDeleteSaved:
              areVersesSaved ? () => _deleteSelectedVerses(context) : null,
        );
      },
    ).whenComplete(() {
      _bottomSheetOpen = false;
    });
  }

  void _openNoteEditor(BuildContext modalContext) {
    final range = _getSelectedVerseRange();
    if (range == null) return;

    final referenceLabel = _getSelectedVersesReference();
    final noteState = context.read<BibleNoteBloc>().state;
    final existingNote = noteState is BibleNoteLoaded
        ? noteState.getNoteForRange(
            range.bookName,
            range.chapter,
            range.startVerse,
            range.endVerse,
          )
        : null;

    Navigator.pop(modalContext);
    _controller.clearSelectedVerses();

    if (existingNote != null && existingNote.text.isNotEmpty) {
      BibleNoteViewer.show(
        context,
        bookName: range.bookName,
        chapter: range.chapter,
        startVerse: range.startVerse,
        endVerse: range.endVerse,
        referenceLabel: referenceLabel,
        note: existingNote.text,
        onEdit: () => BibleNoteModal.show(
          context,
          bookName: range.bookName,
          chapter: range.chapter,
          startVerse: range.startVerse,
          endVerse: range.endVerse,
          referenceLabel: referenceLabel,
          initialNote: existingNote.text,
        ),
      );
    } else {
      BibleNoteModal.show(
        context,
        bookName: range.bookName,
        chapter: range.chapter,
        startVerse: range.startVerse,
        endVerse: range.endVerse,
        referenceLabel: referenceLabel,
        initialNote: existingNote?.text,
      );
    }
  }

  void _openNoteForVerse(String bookName, int chapter, int verseNumber) {
    final noteState = context.read<BibleNoteBloc>().state;
    final existingNote = noteState is BibleNoteLoaded
        ? noteState.getNoteForVerse(bookName, chapter, verseNumber)
        : null;

    final startVerse = existingNote?.startVerse ?? verseNumber;
    final endVerse = existingNote?.endVerse ?? verseNumber;
    final fullBookName = BibleVerseFormatter.resolveBookName(
      _controller.state.books,
      bookName,
    );
    final referenceLabel = startVerse == endVerse
        ? '$fullBookName $chapter:$startVerse'
        : '$fullBookName $chapter:$startVerse-$endVerse';

    if (existingNote != null && existingNote.text.isNotEmpty) {
      BibleNoteViewer.show(
        context,
        bookName: bookName,
        chapter: chapter,
        startVerse: startVerse,
        endVerse: endVerse,
        referenceLabel: referenceLabel,
        note: existingNote.text,
        onEdit: () => BibleNoteModal.show(
          context,
          bookName: bookName,
          chapter: chapter,
          startVerse: startVerse,
          endVerse: endVerse,
          referenceLabel: referenceLabel,
          initialNote: existingNote.text,
        ),
      );
    } else {
      BibleNoteModal.show(
        context,
        bookName: bookName,
        chapter: chapter,
        startVerse: startVerse,
        endVerse: endVerse,
        referenceLabel: referenceLabel,
        initialNote: existingNote?.text,
      );
    }
  }

  String _cleanVerseText(dynamic text) {
    return BibleTextNormalizer.clean(text?.toString());
  }

  String _getSelectedVersesText() {
    final state = _controller.state;
    final version = state.selectedVersion;
    final versionName = version == null
        ? ''
        : (Constants.versionAbbreviation(version).isNotEmpty
            ? Constants.versionAbbreviation(version)
            : _getDisplayName(version.name, version.languageCode));
    return BibleVerseFormatter.formatVerses(
      selectedVerseKeys: state.selectedVerses,
      verses: state.verses,
      books: state.books,
      versionName: versionName,
      cleanText: _cleanVerseText,
    );
  }

  String _getSelectedVersesReference() {
    final selectedVerses = _controller.state.selectedVerses;
    if (selectedVerses.isEmpty) return '';

    final sortedVerses = selectedVerses.toList()..sort();
    final parts = sortedVerses.first.split('|');
    final book = BibleVerseFormatter.resolveBookName(
      _controller.state.books,
      parts[0],
    );
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
    AppSnackBar.show(context, 'bible.copied_to_clipboard'.tr());
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

    AppSnackBar.show(context, 'bible.save_marked_verses'.tr());
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

    AppSnackBar.show(context, 'bible.deleted_marked_verses'.tr());
  }

  // Helper para prefijos de capítulo y versículo según idioma
  String getChapterPrefix(String? lang) {
    if (lang == 'ja' || lang == 'zh') return '章'; // japonés o chino
    if (lang == 'ar') return 'ف'; // árabe
    if (lang == 'hi') return 'अ.';
    return 'C.';
  }

  String getVersePrefix(String? lang) {
    if (lang == 'ja' || lang == 'zh') return '节'; // japonés o chino
    if (lang == 'ar') return 'آ'; // árabe
    if (lang == 'hi') return 'प.';
    return 'V.';
  }

  /// Composes the full display label for a BibleVersion.
  /// SRP: single place owns version label composition for this UI surface.
  String _versionLabel(BibleVersion version) {
    // Use display name directly from registry
    return _getDisplayName(version.name, version.languageCode);
  }

  // -- TTS methods --

  /// Prepare and set TTS text from current Bible reader state.
  void _updateTtsText(BibleReaderState state) {
    final languageCode = state.selectedVersion?.languageCode ??
        ui.PlatformDispatcher.instance.locale.languageCode;
    final ttsText = BibleReaderTtsTextBuilder.build(state);
    if (ttsText.isNotEmpty) {
      // Normalize through BibleTextFormatter for proper book name pronunciation
      final version = state.selectedVersion?.name ?? '';
      final normalized = BibleTextFormatter.normalizeTtsText(
        ttsText,
        languageCode,
        version,
      );
      _ttsAudioController.setText(normalized, languageCode: languageCode);
      debugPrint(
        '[BibleReader TTS] Texto configurado: ${normalized.length} caracteres, idioma: $languageCode',
      );
    }
  }

  /// Handle TTS play/pause button tap — same logic as devotional TTS widget.
  Future<void> _handleTtsPlayPause(BibleReaderState state) async {
    final languageCode = state.selectedVersion?.languageCode ??
        ui.PlatformDispatcher.instance.locale.languageCode;
    final ttsState = _ttsAudioController.state.value;

    debugPrint('[BibleReader TTS] ========== HANDLE PLAY/PAUSE ==========');
    debugPrint('[BibleReader TTS] Estado actual: $ttsState');

    // Use the field resolved once in initState — never call getService<> here.
    final voiceService = _voiceSettingsService;
    final hasSaved = await voiceService.hasUserSavedVoice(languageCode);
    debugPrint('[BibleReader TTS] ¿Tiene voz guardada?: $hasSaved');

    if (!mounted) return;

    if (!hasSaved) {
      debugPrint(
        '[BibleReader TTS] Mostrando diálogo de configuración de voz...',
      );
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ModernVoiceFeatureDialog(
              onConfigure: () async {
                Navigator.of(ctx).pop();
                if (!mounted) return;
                await _showBibleVoiceSelector(
                  context,
                  languageCode,
                  BibleReaderTtsTextBuilder.build(state),
                );
              },
              onContinue: () async {
                debugPrint(
                  '[BibleReader TTS] Usuario continuó sin configurar voz',
                );
                Navigator.of(ctx).pop();
                await voiceService.setUserSavedVoice(languageCode);
                if (ttsState != TtsPlayerState.loading) {
                  // Only set text if we're starting fresh (idle or after completion)
                  if (ttsState == TtsPlayerState.idle ||
                      ttsState == TtsPlayerState.completed) {
                    debugPrint(
                      '[BibleReader TTS] Configurando texto para primera reproducción',
                    );
                    _updateTtsText(state);
                  } else if (ttsState == TtsPlayerState.paused) {
                    // Don't reset text when resuming from pause
                    debugPrint(
                      '[BibleReader TTS] Reanudando desde pausa (sin reset)',
                    );
                  }
                  _ttsAudioController.play();
                }
              },
            ),
          );
        },
      );
      return;
    }

    final friendlyName = await voiceService.loadSavedVoice(languageCode);
    debugPrint('[BibleReader TTS] 🗂️🔊 Voz aplicada: $friendlyName');

    if (ttsState == TtsPlayerState.playing) {
      debugPrint('[BibleReader TTS] ⏸️ Pausando');
      _ttsAudioController.pause();
    } else if (ttsState != TtsPlayerState.loading) {
      if (ttsState == TtsPlayerState.completed) {
        debugPrint(
          '[BibleReader TTS] 🔄 Completed, reseteando antes de play()',
        );
        await _ttsAudioController.stop();
        // Only set text when completed (will be starting fresh from beginning)
        debugPrint('[BibleReader TTS] Reseteando texto después de completion');
        _updateTtsText(state);
      } else if (ttsState == TtsPlayerState.paused) {
        // CRITICAL FIX: Don't call setText() when resuming from pause!
        // setText() resets accumulatedPosition to zero, causing skip to next chunk.
        // Just resume from current position using play() alone.
        debugPrint(
          '[BibleReader TTS] ⏸️→▶️ Reanudando desde posición guardada (sin reset de texto)',
        );
      } else if (ttsState == TtsPlayerState.idle) {
        // First time playing (idle state)
        debugPrint('[BibleReader TTS] 🚀 Primer play, configurando texto');
        _updateTtsText(state);
      }
      debugPrint('[BibleReader TTS] ▶️ Llamando play()');
      _ttsAudioController.play();
    }

    debugPrint('[BibleReader TTS] ========== FIN HANDLE PLAY/PAUSE ==========');
  }

  /// Shows the voice selector dialog.
  ///
  /// Shared implementation used by both the first-time play flow
  /// (_handleTtsPlayPause) and the miniplayer voice button (via presenter
  /// [onShowVoiceSelector] callback). Single path — no duplication.
  Future<void> _showBibleVoiceSelector(
    BuildContext context,
    String language,
    String sampleText,
  ) async {
    if (sampleText.isEmpty) return;
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => FractionallySizedBox(
        heightFactor: 0.8,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: VoiceSelectorDialog(
            language: language,
            sampleText: sampleText,
            onVoiceSelected: (name, locale) {
              // Called on each tap-to-preview inside the dialog.
              // The dialog's Save button handles persistence; here we
              // log the tap for diagnostics.
              debugPrint(
                '[BibleReader TTS] Voice tapped for preview: $name ($locale)',
              );
            },
          ),
        ),
      ),
    );

    // After the dialog closes (saved or dismissed), re-apply the current
    // saved voice to our TTS instance so the next play() uses it immediately
    // without waiting for TtsAudioController.play() to call applyVoiceToInstance.
    if (context.mounted) {
      try {
        await _voiceSettingsService.applyVoiceToInstance(
          _ttsAudioController.flutterTts,
          language,
        );
        debugPrint('[BibleReader TTS] Voice re-applied after selector closed');
      } catch (e) {
        debugPrint(
          '[BibleReader TTS] applyVoiceToInstance after selector failed: $e',
        );
      }
    }
  }

  String _versionPickerLabel(BibleVersion version) {
    final displayName = _getDisplayName(version.name, version.languageCode);
    final String abbr = Constants.versionAbbreviation(version);
    if (abbr.isEmpty) return displayName;
    return '$displayName · $abbr';
  }

  Future<void> _handleVersionSelected(
    BuildContext context,
    BibleVersion version,
  ) async {
    await _controller.switchVersion(version);
    if (!context.mounted) return;
    AppSnackBar.show(
      context,
      'bible.loading_version'.tr({'version': version.name}),
    );
  }

  /// Downloads [version] via [_versionsBloc], then switches the reader to
  /// it and notifies the parent so its cached version list picks up the new
  /// file (and its disclaimer) on the next drawer open.
  Future<void> _handleDownloadVersion(
    BuildContext context,
    BibleVersion version,
  ) async {
    // Cancel any previous in-flight listener before starting a new one, so
    // at most one download listener is ever tracked/live at a time.
    unawaited(_downloadSubscription?.cancel());
    _downloadSubscription = _versionsBloc.stream.listen((state) async {
      if (state is! BibleVersionsLoaded) return;
      final status = state.downloadStatuses[version.dbFileName];
      if (status == null) return;

      if (status.isComplete) {
        // Fire-and-forget: awaiting cancel() from within this stream's own
        // onData callback deadlocks, since the controller waits for this
        // callback to return before finalizing the cancellation.
        unawaited(_downloadSubscription?.cancel());
        _downloadSubscription = null;
        if (!mounted) return;
        // Close the drawer now that the download finished — it was kept
        // open (and undismissable) so the user could see the progress
        // indicator while downloading.
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        // Switch first, so the new version's reading position is saved
        // before onVersionsMayHaveChanged() below remounts this page with a
        // fresh key — otherwise the remount restores the previous version.
        // version may be the stale pre-download copy (e.g. a redownload
        // triggered from the update badge): hasUpdate must be cleared so
        // the controller's availableVersions doesn't keep showing an
        // update as still pending for the file just downloaded. remoteHash
        // is intentionally carried through as-is, since the file on disk
        // now matches it.
        await _controller.switchVersion(
          version.copyWith(isDownloaded: true, hasUpdate: false),
        );
        widget.onVersionsMayHaveChanged?.call();
        if (!context.mounted) return;
        AppSnackBar.show(
          context,
          'bible.loading_version'.tr({'version': version.name}),
        );
      } else if (status.errorMessageKey != null) {
        unawaited(_downloadSubscription?.cancel());
        _downloadSubscription = null;
        if (!context.mounted) return;
        AppSnackBar.show(context, status.errorMessageKey!.tr());
      }
    });

    _versionsBloc.add(DownloadBibleVersion(version));
  }

  /// Extract display name from version name
  /// - For Latin-script languages (es, en, pt, fr, de): removes trailing "(CODE)"
  ///   e.g. "Lutherbibel 2017 (LU17)" → "Lutherbibel 2017"
  /// - For native-script languages (ja, zh, hi): returns the name as-is
  String _getDisplayName(String name, String languageCode) {
    // German uses the same "Full Name (CODE)" convention as the other
    // Latin-script languages — strip the trailing parenthesised code so it
    // isn't duplicated when the abbreviation is appended by _versionPickerLabel.
    if (languageCode == 'es' ||
        languageCode == 'en' ||
        languageCode == 'pt' ||
        languageCode == 'fr' ||
        languageCode == 'de') {
      final regex = RegExp(r'^(.+?)\s*\([A-Z0-9]+\)$');
      final match = regex.firstMatch(name);
      if (match != null) {
        return match.group(1)!.trim();
      }
    }
    // For native-script languages (ja, zh, hi), use name as-is
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;
    return StreamBuilder<BibleReaderState>(
      stream: _controller.stateStream,
      initialData: _controller.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? _controller.state;
        final bibleNoteState = context.watch<BibleNoteBloc>().state;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pendingReferenceScroll &&
              state.selectedVerse != null &&
              state.verses.any((v) => v['verse'] == state.selectedVerse)) {
            _pendingReferenceScroll = false;
            _scrollToVerse(state.selectedVerse!);
          } else if (state.selectedVerse != null &&
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
              child: CustomAppBar(
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
                    if (!state.isLoading && state.selectedVersion != null)
                      Text(
                        _versionLabel(state.selectedVersion!),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimary.withValues(alpha: 0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                  ],
                ),
                actions: [
                  // Search button (leftmost in RTL, rightmost in LTR)
                  IconButton(
                    icon: Icon(
                      Icons.search,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    tooltip: 'bible.search'.tr(),
                    onPressed: _showSearchOverlay,
                  ),
                  // Font size button (middle position)
                  IconButton(
                    icon: Icon(
                      Icons.text_increase_outlined,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    tooltip: 'bible.adjust_font_size'.tr(),
                    onPressed: () => _controller.toggleFontControls(),
                  ),
                  // Versions end drawer trigger. Scaffold only auto-generates
                  // a hamburger icon for `drawer`, never for `endDrawer`, so
                  // this button must be added explicitly.
                  Builder(
                    builder: (context) => IconButton(
                      icon: Icon(
                        Icons.menu,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ).newIconBadge,
                      tooltip: 'bible.select_version'.tr(),
                      onPressed: () {
                        BubbleUtils.markAsShown(
                          BubbleUtils.getIconBubbleId(Icons.menu, 'new'),
                        );
                        Scaffold.of(context).openEndDrawer();
                      },
                    ),
                  ),
                ],
              ),
            ),
            endDrawer: state.availableVersions.isNotEmpty
                ? BlocBuilder<BibleVersionsBloc, BibleVersionsState>(
                    bloc: _versionsBloc,
                    builder: (context, versionsState) {
                      final downloadedFileNames = state.availableVersions
                          .map((v) => v.dbFileName)
                          .toSet();
                      final remoteVersions =
                          versionsState is BibleVersionsLoaded
                              ? versionsState.remoteVersions
                              : const <BibleVersion>[];
                      final downloadableVersions = remoteVersions
                          .where((v) =>
                              !downloadedFileNames.contains(v.dbFileName))
                          .toList();
                      // Downloaded versions the index reports as changed
                      // since download — surfaced as an update badge on
                      // the existing availableVersions entry rather than a
                      // separate downloadable tile. Keyed by dbFileName so
                      // the full remote entry (with remoteUrl/remoteHash,
                      // which the disk-scanned availableVersions entry
                      // never has) can be used for the redownload — not
                      // just its hasUpdate flag copied over, which would
                      // leave remoteUrl null and make the redownload fail.
                      final updatedVersionsByFileName = {
                        for (final v in remoteVersions)
                          if (v.hasUpdate &&
                              downloadedFileNames.contains(v.dbFileName))
                            v.dbFileName: v,
                      };
                      final availableVersions = state.availableVersions
                          .map((v) =>
                              updatedVersionsByFileName[v.dbFileName] ?? v)
                          .toList();
                      final downloadStatuses =
                          versionsState is BibleVersionsLoaded
                              ? versionsState.downloadStatuses
                              : const <String, VersionDownloadStatus>{};

                      return BibleReaderDrawer(
                        availableVersions: availableVersions,
                        selectedVersion: state.selectedVersion,
                        downloadableVersions: downloadableVersions,
                        downloadStatuses: downloadStatuses,
                        versionLabelBuilder: _versionPickerLabel,
                        onVersionSelected: (version) =>
                            _handleVersionSelected(context, version),
                        onDownloadVersion: (version) =>
                            _handleDownloadVersion(context, version),
                      );
                    },
                  )
                : null,
            body: Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      if (_showKjvBanner)
                        Builder(
                          builder: (context) => KjvKj2000Banner(
                            onDismiss: _dismissKjvBanner,
                            onOpenDrawer: () =>
                                Scaffold.of(context).openEndDrawer(),
                          ),
                        ),
                      BibleReaderSelectorBar(
                        state: state,
                        chapterPrefix: getChapterPrefix,
                        versePrefix: getVersePrefix,
                        onBookTap: _showBookSelector,
                        onChapterTap: _showChapterGridSelector,
                        onVerseTap: _showVerseGridSelector,
                      ),
                      Expanded(
                        child: ValueListenableBuilder<int?>(
                          valueListenable: _ttsAutoScrollDriver.currentIndex,
                          builder: (context, currentSpokenVerseIndex, _) {
                            return BibleVerseListView(
                              state: state,
                              bibleNoteState: bibleNoteState,
                              itemScrollController: _itemScrollController,
                              itemPositionsListener: _itemPositionsListener,
                              currentSpokenVerseIndex: currentSpokenVerseIndex,
                              cleanVerseText: _cleanVerseText,
                              onVerseTap: _onVerseTap,
                              onVerseLongPress:
                                  _controller.togglePersistentMark,
                              onNoteTap: _openNoteForVerse,
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
            bottomNavigationBar:
                !state.isLoading && state.selectedBookName != null
                    ? BibleReaderBottomBar(
                        state: state,
                        ttsAudioController: _ttsAudioController,
                        onPreviousChapter: () async {
                          _ttsAudioController.stop();
                          await _controller.goToPreviousChapter();
                          _scrollToTop();
                        },
                        onNextChapter: () async {
                          _ttsAudioController.stop();
                          await _controller.goToNextChapter();
                          _itemScrollController.jumpTo(index: 0);
                          _scrollToTop();
                        },
                        onBookTap: _showBookSelector,
                        onTtsPlayPause: _handleTtsPlayPause,
                      )
                    : null,
          ),
        );
      },
    );
  }
}
