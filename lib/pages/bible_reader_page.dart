//bible_reader_page.dart - Pure UI presentation layer
import 'dart:ui' as ui;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/services/tts/utils/tts_chunk_processor.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/bible_reader_tts_text_builder.dart';
import 'package:devocional_nuevo/services/tts/bible_text_formatter.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:devocional_nuevo/utils/copyright_utils.dart';
import 'package:devocional_nuevo/widgets/bible/bible_book_selector_dialog.dart';
import 'package:devocional_nuevo/widgets/bible/bible_chapter_grid_selector.dart';
import 'package:devocional_nuevo/widgets/bible/bible_reader_action_modal.dart';
import 'package:devocional_nuevo/widgets/bible/bible_reader_tts_miniplayer_presenter.dart';
import 'package:devocional_nuevo/widgets/bible/bible_search_overlay.dart';
import 'package:devocional_nuevo/widgets/bible/bible_verse_grid_selector.dart';
import 'package:devocional_nuevo/widgets/devocionales/app_bar_constants.dart';
import 'package:devocional_nuevo/widgets/floating_font_control_buttons.dart';
import 'package:devocional_nuevo/widgets/modern_voice_feature_dialog.dart';
import 'package:devocional_nuevo/widgets/voice_selector_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lottie/lottie.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus;

/// Pure UI presentation layer for Bible Reader
/// All business logic is handled by BibleReaderController
class BibleReaderPage extends StatefulWidget {
  final List<BibleVersion> versions;
  final BibleReaderService? readerService; // Optional for DI
  final BiblePreferencesService? preferencesService; // Optional for DI
  /// Optional [FlutterTts] instance for dependency injection / testing.
  /// When null a new instance is created internally in [initState].
  final FlutterTts? flutterTts;

  const BibleReaderPage({
    super.key,
    required this.versions,
    this.readerService,
    this.preferencesService,
    this.flutterTts,
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

  // TTS fields — FlutterTts is resolved in initState (not at field-level) so
  // that an injected instance from widget.flutterTts takes precedence.
  late final TtsAudioController _ttsAudioController;
  late final BibleReaderTtsMiniplayerPresenter _ttsMiniplayerPresenter;
  late final VoiceSettingsService _voiceSettingsService;
  // Guards addPostFrameCallback callbacks after dispose().
  bool _disposed = false;

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
      analyticsService: getService<AnalyticsService>(),
      // Delegate voice selector to the single implementation on this page.
      onShowVoiceSelector: (ctx, lang, sampleText) =>
          _showBibleVoiceSelector(ctx, lang, sampleText),
    );

    // Auto-open miniplayer when TTS starts playing — same pattern as
    // devocionales_page (tested by 3000+ users in production).
    // Opens on LOADING state for instant feedback; no need to wait for
    // setStartHandler (which can take seconds on large chapters like Psalm 119).
    _ttsAudioController.state.addListener(_handleTtsStateChange);

    // Initialize controller with device language
    final deviceLanguage = ui.PlatformDispatcher.instance.locale.languageCode;
    _controller.initialize(deviceLanguage);
  }

  @override
  void dispose() {
    _disposed = true;
    _ttsAudioController.stop();
    try {
      _ttsAudioController.state.removeListener(_handleTtsStateChange);
    } catch (_) {}
    _ttsMiniplayerPresenter.dispose();
    _ttsAudioController.dispose();
    _controller.dispose();
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
      if (s == TtsPlayerState.completed) {
        if (_ttsMiniplayerPresenter.isShowing) {
          _ttsMiniplayerPresenter.resetModalState();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_disposed) return;
            if (mounted && Navigator.canPop(context)) {
              debugPrint(
                '🏁 [BibleReader Modal] Closing modal on COMPLETED state',
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
            (b) => b['short_name'] == state.selectedBookName,
          )['long_name'],
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
            (b) => b['short_name'] == state.selectedBookName,
          )['long_name'],
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

  void _showBottomSheet() {
    _bottomSheetOpen = true;

    // Check if all selected verses are already saved
    final selectedVerses = _controller.state.selectedVerses.toList();
    final persistentlyMarkedVerses = _controller.state.persistentlyMarkedVerses;
    final areVersesSaved = selectedVerses.every(
      (key) => persistentlyMarkedVerses.contains(key),
    );

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
      final normalized =
          BibleTextFormatter.normalizeTtsText(ttsText, languageCode, version);
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
          '[BibleReader TTS] Mostrando diálogo de configuración de voz...');
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
                await _showBibleVoiceSelector(context, languageCode,
                    BibleReaderTtsTextBuilder.build(state));
              },
              onContinue: () async {
                debugPrint(
                    '[BibleReader TTS] Usuario continuó sin configurar voz');
                Navigator.of(ctx).pop();
                await voiceService.setUserSavedVoice(languageCode);
                if (ttsState != TtsPlayerState.loading) {
                  // Only set text if we're starting fresh (idle or after completion)
                  if (ttsState == TtsPlayerState.idle ||
                      ttsState == TtsPlayerState.completed) {
                    debugPrint(
                        '[BibleReader TTS] Configurando texto para primera reproducción');
                    _updateTtsText(state);
                  } else if (ttsState == TtsPlayerState.paused) {
                    // Don't reset text when resuming from pause
                    debugPrint(
                        '[BibleReader TTS] Reanudando desde pausa (sin reset)');
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
            '[BibleReader TTS] 🔄 Completed, reseteando antes de play()');
        await _ttsAudioController.stop();
        // Only set text when completed (will be starting fresh from beginning)
        debugPrint('[BibleReader TTS] Reseteando texto después de completion');
        _updateTtsText(state);
      } else if (ttsState == TtsPlayerState.paused) {
        // CRITICAL FIX: Don't call setText() when resuming from pause!
        // setText() resets accumulatedPosition to zero, causing skip to next chunk.
        // Just resume from current position using play() alone.
        debugPrint(
            '[BibleReader TTS] ⏸️→▶️ Reanudando desde posición guardada (sin reset de texto)');
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
        debugPrint(
          '[BibleReader TTS] Voice re-applied after selector closed',
        );
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
                  // Version menu (rightmost in RTL, leftmost action in LTR)
                  if (state.availableVersions.length > 1)
                    PopupMenuButton<BibleVersion>(
                      icon: Icon(
                        Icons.menu,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      tooltip: 'bible.select_version'.tr(),
                      onSelected: (version) async {
                        final scaffoldMessenger = ScaffoldMessenger.of(
                          context,
                        );
                        final colorScheme = Theme.of(context).colorScheme;
                        await _controller.switchVersion(version);
                        if (!mounted) return;
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'bible.loading_version'.tr({
                                'version': version.name,
                              }),
                              style: TextStyle(
                                color: colorScheme.onSecondary,
                              ),
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
                              if (version.dbFileName ==
                                  state.selectedVersion?.dbFileName)
                                Icon(
                                  Icons.check,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  size: 20,
                                )
                              else
                                const SizedBox(width: 20),
                              const SizedBox(width: 8),
                              Text(_versionPickerLabel(version)),
                            ],
                          ),
                        );
                      }).toList(),
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
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
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
                                      Icon(
                                        Icons.auto_stories_outlined,
                                        size: 20,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          state.selectedBookName != null
                                              ? state.books.firstWhere(
                                                  (b) =>
                                                      b['short_name'] ==
                                                      state.selectedBookName,
                                                )['long_name']
                                              : 'Seleccionar libro',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        color: colorScheme.onSurface,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _showChapterGridSelector,
                                icon: Icon(
                                  Icons.format_list_numbered,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                                label: Text(
                                  '${getChapterPrefix(state.selectedVersion?.languageCode)} ${state.selectedChapter ?? 1}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _showVerseGridSelector,
                                icon: const Icon(
                                  Icons.format_list_numbered,
                                  size: 18,
                                ),
                                label: Text(
                                  '${getVersePrefix(state.selectedVersion?.languageCode)} ${state.selectedVerse ?? 1}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
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
                                            state.selectedVersion?.name ?? '',
                                      }),
                                    ),
                                  ],
                                ),
                              )
                            : ScrollablePositionedList.builder(
                                itemScrollController: _itemScrollController,
                                itemPositionsListener: _itemPositionsListener,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  32,
                                ),
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
                                          state.selectedVersion!.name,
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: colorScheme.onSurface
                                                  .withValues(alpha: 153),
                                            ),
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
                                        vertical: 8,
                                        horizontal: 4,
                                      ),
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
                                                verse['text'],
                                              ),
                                              style: isPersistentlyMarked
                                                  ? TextStyle(
                                                      backgroundColor:
                                                          colorScheme.secondary
                                                              .withValues(
                                                        alpha: 0.25,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w500,
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
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.arrow_back_ios,
                                color: colorScheme.primary,
                              ),
                              tooltip: 'bible.previous_chapter'.tr(),
                              onPressed: () async {
                                _ttsAudioController.stop();
                                await _controller.goToPreviousChapter();
                                _scrollToTop();
                              },
                            ),
                            // TTS play/pause button
                            _buildTtsButton(context, state, colorScheme),
                            // Botón de capítulo expandido para tablets y pantallas grandes
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: SizedBox(
                                  height: 44,
                                  child: ElevatedButton(
                                    onPressed: _showBookSelector,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          colorScheme.primaryContainer,
                                      foregroundColor:
                                          colorScheme.onPrimaryContainer,
                                      elevation: 2,
                                      shadowColor: colorScheme.primary
                                          .withValues(alpha: 0.3),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10.0,
                                        horizontal: 16.0,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: AutoSizeText(
                                        state.selectedBookName != null
                                            ? '${state.books.firstWhere((b) => b['short_name'] == state.selectedBookName, orElse: () => {
                                                  'long_name':
                                                      state.selectedBookName
                                                })['long_name']} ${state.selectedChapter}'
                                            : '',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme
                                                  .onPrimaryContainer,
                                            ),
                                        maxLines: 1,
                                        minFontSize: 11,
                                        maxFontSize: 15,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.arrow_forward_ios,
                                color: colorScheme.primary,
                              ),
                              tooltip: 'bible.next_chapter'.tr(),
                              onPressed: () async {
                                _ttsAudioController.stop();
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

  /// Builds the TTS play/pause button for the bottom navigation bar.
  /// Reuses the same visual style as the devotional TTS player.
  Widget _buildTtsButton(
    BuildContext context,
    BibleReaderState readerState,
    ColorScheme colorScheme,
  ) {
    return ValueListenableBuilder<TtsPlayerState>(
      valueListenable: _ttsAudioController.state,
      builder: (context, ttsState, _) {
        final themeColor = colorScheme.primary;
        const borderWidth = 2.0;

        Widget mainIcon;
        BoxDecoration decoration;

        if (ttsState == TtsPlayerState.loading) {
          mainIcon = const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
          decoration = BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: themeColor, width: borderWidth),
          );
        } else if (ttsState == TtsPlayerState.playing) {
          mainIcon = Icon(Icons.pause, size: 28, color: themeColor);
          decoration = BoxDecoration(
            border: Border.all(color: themeColor, width: borderWidth),
            borderRadius: BorderRadius.circular(12),
          );
        } else {
          mainIcon = Icon(Icons.play_arrow, size: 28, color: themeColor);
          decoration = BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: themeColor, width: borderWidth),
          );
        }

        return Material(
          color: Colors.transparent,
          elevation: 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: readerState.verses.isNotEmpty
                ? () => _handleTtsPlayPause(readerState)
                : null,
            child: Container(
              decoration: decoration,
              width: 44,
              height: 44,
              child: Center(child: mainIcon),
            ),
          ),
        );
      },
    );
  }
}
