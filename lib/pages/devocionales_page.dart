import 'dart:developer' as developer;
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_bloc.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_event.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/main.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/pages/bible_reader_page.dart';
import 'package:devocional_nuevo/pages/prayers_page.dart';
import 'package:devocional_nuevo/pages/progress_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/repositories/devocional_repository_impl.dart';
import 'package:devocional_nuevo/repositories/navigation_repository_impl.dart';
import 'package:devocional_nuevo/services/devocionales_tracking.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/update_service.dart';
import 'package:devocional_nuevo/utils/devotional_share_helper.dart';
import 'package:devocional_nuevo/widgets/add_entry_choice_modal.dart';
import 'package:devocional_nuevo/widgets/add_prayer_modal.dart';
import 'package:devocional_nuevo/widgets/add_testimony_modal.dart';
import 'package:devocional_nuevo/widgets/add_thanksgiving_modal.dart';
import 'package:devocional_nuevo/widgets/devocionales/app_bar_constants.dart';
import 'package:devocional_nuevo/widgets/devocionales/devocionales_content_widget.dart';
import 'package:devocional_nuevo/widgets/devocionales/devocionales_page_drawer.dart';
import 'package:devocional_nuevo/widgets/floating_font_control_buttons.dart';
import 'package:devocional_nuevo/widgets/tts_miniplayer_modal.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart'; // Re-agregado para animación post-splash
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/audio_controller.dart';
import '../controllers/tts_audio_controller.dart';
import '../services/analytics_service.dart';
import '../services/spiritual_stats_service.dart';
import '../services/tts/bible_text_formatter.dart';
import '../widgets/animated_fab_with_text.dart';
import '../widgets/devocionales/devocionales_bottom_bar.dart';
import '../widgets/voice_selector_dialog.dart';

class DevocionalesPage extends StatefulWidget {
  final String? initialDevocionalId;

  const DevocionalesPage({super.key, this.initialDevocionalId});

  @override
  State<DevocionalesPage> createState() => _DevocionalesPageState();
}

class _DevocionalesPageState extends State<DevocionalesPage>
    with WidgetsBindingObserver, RouteAware {
  final ScreenshotController screenshotController = ScreenshotController();
  final ScrollController _scrollController = ScrollController();
  final DevocionalesTracking _tracking = DevocionalesTracking();
  final FlutterTts _flutterTts = FlutterTts();
  late final TtsAudioController _ttsAudioController;
  AudioController? _audioController;
  bool _routeSubscribed = false;
  int _currentStreak = 0;
  late Future<int> _streakFuture;

  // Navigation BLoC
  late DevocionalesNavigationBloc _navigationBloc;

  // Font control variables
  bool _showFontControls = false;
  double _fontSize = 16.0;

  static bool _postSplashAnimationShown =
      false; // Controla mostrar solo una vez
  bool _showPostSplashAnimation = false; // Estado local
  bool _isTtsModalShowing = false; // Prevent multiple TTS modals

  // Lista de animaciones Lottie disponibles
  final List<String> _lottieAssets = [
    'assets/lottie/bird_love.json',
    'assets/lottie/confetti.json',
    'assets/lottie/happy_bird.json',
    'assets/lottie/dog_walking.json',
    'assets/lottie/book_animation.json',
    'assets/lottie/plant.json',
  ];
  String? _selectedLottieAsset;

  @override
  void initState() {
    super.initState();
    _ttsAudioController = TtsAudioController(flutterTts: _flutterTts);
    // Listener para cerrar miniplayer automáticamente cuando el TTS complete
    _ttsAudioController.state.addListener(_handleTtsStateChange);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _audioController = Provider.of<AudioController>(context, listen: false);
      _tracking.initialize(context);
      _precacheLottieAnimations();
    });
    _loadFontSize();

    // Create BLoC immediately to avoid spinner on app start
    _navigationBloc = DevocionalesNavigationBloc(
      navigationRepository: NavigationRepositoryImpl(),
      devocionalRepository: DevocionalRepositoryImpl(),
    );
    // Initialize asynchronously in background
    _initializeNavigationBloc();

    // Log analytics event for app initialization with BLoC
    getService<AnalyticsService>().logAppInit(
      parameters: {'use_navigation_bloc': 'true'},
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate();
    });
    _pickRandomLottie();
    _streakFuture = _loadStreak();
    if (!_postSplashAnimationShown) {
      _showPostSplashAnimation = true;
      _postSplashAnimationShown = true;
      Future.delayed(const Duration(seconds: 7), () {
        if (mounted) setState(() => _showPostSplashAnimation = false);
      });
    }
  }

  Future<void> _initializeNavigationBloc() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final devocionalProvider = Provider.of<DevocionalProvider>(
        context,
        listen: false,
      );

      // Wait for devotionals to load
      if (!devocionalProvider.isLoading &&
          devocionalProvider.devocionales.isEmpty) {
        await devocionalProvider.initializeData();
        if (!mounted) return;
      }

      if (devocionalProvider.devocionales.isEmpty) {
        developer.log('No devotionals available to initialize Navigation BLoC');
        return;
      }

      // Record daily app visit
      final spiritualStatsService = SpiritualStatsService();
      await spiritualStatsService.recordDailyAppVisit();

      // Get read devotional IDs for finding first unread
      final stats = await spiritualStatsService.getStats();
      final readDevocionalIds = stats.readDevocionalIds;

      // Find first unread index or use saved index
      int initialIndex = 0;
      if (widget.initialDevocionalId != null) {
        // Deep link - find index by ID
        final index = devocionalProvider.devocionales.indexWhere(
          (d) => d.id == widget.initialDevocionalId,
        );
        initialIndex = index != -1 ? index : 0;
      } else {
        // Find first unread using repository (pure logic, deterministic)
        initialIndex =
            DevocionalRepositoryImpl().findFirstUnreadDevocionalIndex(
          devocionalProvider.devocionales,
          readDevocionalIds,
        );
      }

      // Initialize navigation with full devotionals list
      // Guard early and avoid race windows: check mounted and bloc state immediately
      if (!mounted) return;
      if (_navigationBloc.isClosed) return;
      try {
        _navigationBloc.add(
          InitializeNavigation(
            initialIndex: initialIndex,
            devocionales: devocionalProvider.devocionales,
          ),
        );
        developer.log('Navigation BLoC initialized at index: $initialIndex');
      } catch (e, st) {
        developer.log('Failed to initialize BLoC: $e');
        try {
          FirebaseCrashlytics.instance.recordError(e, st);
        } catch (_) {
          developer.log('Failed to report initialization error to Crashlytics');
        }
      }
    });
  }

  Future<void> _precacheLottieAnimations() async {
    try {
      // Precache the fire.json animation to ensure it loads on first app start
      await Future.wait([
        rootBundle.load('assets/lottie/fire.json'),
        // Precache other frequently used animations
        ..._lottieAssets.map((asset) => rootBundle.load(asset)),
      ]);
      debugPrint('✅ Lottie animations precached successfully');
    } catch (e) {
      debugPrint('⚠️ Error precaching Lottie animations: $e');
    }
  }

  Future<int> _loadStreak() async {
    final stats = await SpiritualStatsService().getStats();
    if (!mounted) return 0;
    setState(() {
      _currentStreak = stats.currentStreak;
    });
    return stats.currentStreak;
  }

  void _pickRandomLottie() {
    final random = Random();
    setState(() {
      _selectedLottieAsset =
          _lottieAssets[random.nextInt(_lottieAssets.length)];
    });
  }

  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _fontSize = prefs.getDouble('devocional_font_size') ?? 16.0;
    });
  }

  void _toggleFontControls() {
    setState(() {
      _showFontControls = !_showFontControls;
    });
  }

  Future<void> _increaseFontSize() async {
    if (_fontSize < 28.0) {
      setState(() {
        _fontSize += 1;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('devocional_font_size', _fontSize);
    }
  }

  Future<void> _decreaseFontSize() async {
    if (_fontSize > 12.0) {
      setState(() {
        _fontSize -= 1;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('devocional_font_size', _fontSize);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_routeSubscribed) {
      final route = ModalRoute.of(context);
      if (route is PageRoute) {
        routeObserver.subscribe(this, route);
        debugPrint(
          '🔄 [DEBUG] Global RouteObserver subscribed for DevocionalesPage',
        );
        _routeSubscribed = true;
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _tracking.pauseTracking();
      debugPrint('🔄 App paused - tracking and criteria timer paused');

      // Stop audio when going to background to prevent resource issues
      if (_audioController != null && _audioController!.isActive) {
        debugPrint('🎵 Pausing audio due to app going to background');
        _audioController!.pause();
      }
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 App resumed - refreshing state');

      // Resume tracking
      _tracking.resumeTracking();

      // Check for updates
      UpdateService.checkForUpdate();

      // Refresh UI state to ensure everything is in sync
      if (mounted) {
        setState(() {
          // Force rebuild to ensure UI is fresh
          debugPrint('🔄 Forcing UI refresh after app resume');
        });
      }

      debugPrint('✅ App resumed - tracking and UI refreshed');
    }
  }

  @override
  void didPush() {
    _tracking.resumeTracking();
    debugPrint('📄 DevocionalesPage pushed → tracking resumed');
  }

  @override
  void didPopNext() {
    _tracking.resumeTracking();
    debugPrint('📄 DevocionalesPage popped next → tracking resumed');
  }

  @override
  void didPushNext() {
    _tracking.pauseTracking();
    debugPrint('📄 DevocionalesPage didPushNext → tracking PAUSED');
    if (_audioController != null && _audioController!.isActive) {
      debugPrint('🎵 [DEBUG] Navigation away - stopping audio (force)');
      _audioController!.forceStop();
    }
  }

  @override
  void dispose() {
    // Remover listener agregado en initState
    try {
      _ttsAudioController.state.removeListener(_handleTtsStateChange);
    } catch (_) {}
    _ttsAudioController.dispose();
    _tracking.dispose();
    _scrollController.dispose();
    _navigationBloc.close(); // Clean up BLoC
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() {});
  }

  void _goToNextDevocional() async {
    try {
      // Guard: Don't navigate if BLoC is not ready (prevents race condition)
      if (_navigationBloc.state is! NavigationReady) {
        debugPrint('⚠️ Navigation blocked: BLoC not ready yet');
        return;
      }

      // Stop audio/TTS before navigation
      if (_audioController != null && _audioController!.isActive) {
        debugPrint(
          'DevocionalesPage: Stopping AudioController before navigation',
        );
        await _audioController!.stop();
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 100));
      } else {
        await _stopSpeaking();
      }

      if (!mounted) return;

      // Get current state for analytics
      final currentState = _navigationBloc.state;
      final currentIndex =
          currentState is NavigationReady ? currentState.currentIndex : 0;
      final totalDevocionales =
          currentState is NavigationReady ? currentState.totalDevocionales : 0;

      // Dispatch navigation event
      _navigationBloc.add(const NavigateToNext());

      // Scroll to top
      _scrollToTop();

      // Trigger haptic feedback
      HapticFeedback.mediumImpact();

      // Log analytics event
      await getService<AnalyticsService>().logNavigationNext(
        currentIndex: currentIndex,
        totalDevocionales: totalDevocionales,
        viaBloc: 'true',
      );

      // Check if we should show invitation dialog
      if (!mounted) return;
      final devocionalProvider = Provider.of<DevocionalProvider>(
        context,
        listen: false,
      );
      if (devocionalProvider.showInvitationDialog) {
        _showInvitation(context);
      }
    } catch (e, stackTrace) {
      // Log error to Crashlytics
      debugPrint('❌ BLoC navigation error: $e');
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'NavigationBloc.NavigateToNext failed',
        information: [
          'Feature: Navigation BLoC',
          'Action: Navigate to next devotional',
        ],
        fatal: false,
      );
    }
  }

  void _goToPreviousDevocional() async {
    try {
      // Guard: Don't navigate if BLoC is not ready (prevents race condition)
      if (_navigationBloc.state is! NavigationReady) {
        debugPrint('⚠️ Navigation blocked: BLoC not ready yet');
        return;
      }

      // Stop audio/TTS before navigation
      if (_audioController != null && _audioController!.isActive) {
        debugPrint(
          'DevocionalesPage: Stopping AudioController before navigation',
        );
        await _audioController!.stop();
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
      } else {
        await _stopSpeaking();
      }

      // Get current state for analytics
      final currentState = _navigationBloc.state;
      final currentIndex =
          currentState is NavigationReady ? currentState.currentIndex : 0;
      final totalDevocionales =
          currentState is NavigationReady ? currentState.totalDevocionales : 0;

      // Dispatch navigation event
      _navigationBloc.add(const NavigateToPrevious());

      // Scroll to top
      _scrollToTop();

      // Trigger haptic feedback
      HapticFeedback.mediumImpact();

      // Log analytics event
      await getService<AnalyticsService>().logNavigationPrevious(
        currentIndex: currentIndex,
        totalDevocionales: totalDevocionales,
        viaBloc: 'true',
      );
    } catch (e, stackTrace) {
      // Log error to Crashlytics
      debugPrint('❌ BLoC navigation error: $e');
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'NavigationBloc.NavigateToPrevious failed',
        information: [
          'Feature: Navigation BLoC',
          'Action: Navigate to previous devotional',
        ],
        fatal: false,
      );
    }
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300), // Changed from 400ms
          curve: Curves.easeInOutCubic, // Changed from easeOutQuart
        );
      }
    });
  }

  void _showInvitation(BuildContext context) {
    if (!mounted) return;

    final devocionalProvider = Provider.of<DevocionalProvider>(
      context,
      listen: false,
    );

    bool doNotShowAgainChecked = !devocionalProvider.showInvitationDialog;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          key: const Key('salvation_prayer_dialog'),
          backgroundColor: colorScheme.surface,
          title: Text(
            "devotionals.salvation_prayer_title".tr(),
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "devotionals.salvation_prayer_intro".tr(),
                  textAlign: TextAlign.justify,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  "devotionals.salvation_prayer".tr(),
                  textAlign: TextAlign.justify,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  "devotionals.salvation_promise".tr(),
                  textAlign: TextAlign.justify,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Checkbox(
                  value: doNotShowAgainChecked,
                  onChanged: (val) {
                    setDialogState(() {
                      doNotShowAgainChecked = val ?? false;
                    });
                  },
                  activeColor: colorScheme.primary,
                ),
                Expanded(
                  child: Text(
                    'prayer.already_prayed'.tr(),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                key: const Key('salvation_prayer_continue_button'),
                onPressed: () {
                  devocionalProvider.setInvitationDialogVisibility(
                    !doNotShowAgainChecked,
                  );
                  Navigator.of(dialogContext).pop();
                },
                child: Text(
                  "devotionals.continue".tr(),
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateFormat _getLocalizedDateFormat(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    switch (locale) {
      case 'es':
        return DateFormat("EEEE, d 'de' MMMM", 'es');
      case 'en':
        return DateFormat('EEEE, MMMM d', 'en');
      case 'fr':
        return DateFormat('EEEE d MMMM', 'fr');
      case 'pt':
        return DateFormat("EEEE, d 'de' MMMM", 'pt');
      case 'ja':
        return DateFormat('y年M月d日 EEEE', 'ja');
      case 'zh':
        // Chinese date format: e.g. 2025年12月29日 星期一
        return DateFormat('y年M月d日 EEEE', 'zh');
      default:
        return DateFormat('EEEE, MMMM d', 'en');
    }
  }

  Future<void> _shareAsText(Devocional devocional) async {
    final devotionalText =
        DevotionalShareHelper.generarTextoParaCompartir(devocional);

    await SharePlus.instance.share(ShareParams(text: devotionalText));
  }

  void _goToPrayers() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PrayersPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _goToBible() async {
    final devocionalProvider = Provider.of<DevocionalProvider>(
      context,
      listen: false,
    );
    final appLanguage = devocionalProvider.selectedLanguage;

    debugPrint('🟦 [Bible] Using app language instead of device: $appLanguage');

    List<BibleVersion> versions =
        await BibleVersionRegistry.getVersionsForLanguage(appLanguage);

    debugPrint(
      '🟩 [Bible] Versions for app language ($appLanguage): ${versions.map((v) => '${v.name} (${v.languageCode}) - downloaded: ${v.isDownloaded}').join(', ')}',
    );

    if (versions.isEmpty) {
      versions = await BibleVersionRegistry.getVersionsForLanguage('es');
    }

    if (versions.isEmpty) {
      versions = await BibleVersionRegistry.getAllVersions();
    }

    if (!mounted) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            BibleReaderPage(versions: versions),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _showAddPrayerOrThanksgivingChoice() {
    // Log FAB tap event
    getService<AnalyticsService>().logFabTapped(source: 'devocionales_page');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return AddEntryChoiceModal(
          source: 'devocionales_page',
          onAddPrayer: _showAddPrayerModal,
          onAddThanksgiving: _showAddThanksgivingModal,
          onAddTestimony: _showAddTestimonyModal,
        );
      },
    );
  }

  void _showAddPrayerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddPrayerModal(),
    );
  }

  void _showAddThanksgivingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddThanksgivingModal(),
    );
  }

  void _showAddTestimonyModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTestimonyModal(),
    );
  }

  void _showFavoritesFeedback(bool wasAdded) {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasAdded
              ? 'devotionals_page.added_to_favorites'.tr()
              : 'devotionals_page.removed_from_favorites'.tr(),
          style: TextStyle(color: colorScheme.onSecondary),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: colorScheme.secondary,
      ),
    );
  }

  // Helper para construir el texto usado por el selector de voz
  String _buildTtsTextForDevocional(Devocional devocional, String language) {
    final verseLabel = 'devotionals.verse'.tr().replaceAll(':', '');
    final reflectionLabel = 'devotionals.reflection'.tr().replaceAll(':', '');
    final meditateLabel = 'devotionals.to_meditate'.tr().replaceAll(':', '');
    final prayerLabel = 'devotionals.prayer'.tr().replaceAll(':', '');

    final StringBuffer ttsBuffer = StringBuffer();
    ttsBuffer.write('$verseLabel: ');
    ttsBuffer.write(
      BibleTextFormatter.normalizeTtsText(
        devocional.versiculo,
        language,
        devocional.version,
      ),
    );
    ttsBuffer.write('\n$reflectionLabel: ');
    ttsBuffer.write(
      BibleTextFormatter.normalizeTtsText(
        devocional.reflexion,
        language,
        devocional.version,
      ),
    );
    if (devocional.paraMeditar.isNotEmpty) {
      ttsBuffer.write('\n$meditateLabel: ');
      ttsBuffer.write(
        devocional.paraMeditar.map((m) {
          return '${BibleTextFormatter.normalizeTtsText(m.cita, language, devocional.version)}: ${m.texto}';
        }).join('\n'),
      );
    }
    ttsBuffer.write('\n$prayerLabel: ');
    ttsBuffer.write(
      BibleTextFormatter.normalizeTtsText(
        devocional.oracion,
        language,
        devocional.version,
      ),
    );
    return ttsBuffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return _buildWithBloc(context);
  }

  /// Build UI using Navigation BLoC
  Widget _buildWithBloc(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;

    // Listen to DevocionalProvider changes to update BLoC when bible version or language changes
    return Consumer<DevocionalProvider>(
      builder: (context, devocionalProvider, child) {
        // When devotionals change (language/version change), update BLoC
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (devocionalProvider.devocionales.isNotEmpty) {
            final currentState = _navigationBloc.state;
            if (currentState is NavigationReady) {
              final currentList = currentState.devocionales;
              final newList = devocionalProvider.devocionales;
              if (currentList.length != newList.length ||
                  currentList.hashCode != newList.hashCode) {
                // Get fresh stats to find correct unread index in the new version
                final stats = await SpiritualStatsService().getStats();
                _navigationBloc.add(
                  UpdateDevocionales(newList, stats.readDevocionalIds),
                );
              }
            }
          }
        });

        return BlocListener<DevocionalesNavigationBloc,
            DevocionalesNavigationState>(
          bloc: _navigationBloc,
          listener: (context, state) {
            if (state is NavigationReady) {
              // Start tracking when navigation state changes
              _tracking.clearAutoCompletedExcept(state.currentDevocional.id);
              _tracking.startDevocionalTracking(
                state.currentDevocional.id,
                _scrollController,
              );
            }
          },
          child: BlocBuilder<DevocionalesNavigationBloc,
              DevocionalesNavigationState>(
            bloc: _navigationBloc,
            builder: (context, state) {
              if (state is NavigationError) {
                final TextTheme textTheme = Theme.of(context).textTheme;
                return Scaffold(
                  appBar: AppBar(title: Text('devotionals.error'.tr())),
                  body: Center(
                    child: Text(
                      state.message,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                );
              }

              Devocional currentDevocional;
              bool canNavigateNext;
              bool canNavigatePrevious;

              if (state is NavigationReady) {
                currentDevocional = state.currentDevocional;
                canNavigateNext = state.canNavigateNext;
                canNavigatePrevious = state.canNavigatePrevious;
              } else if (devocionalProvider.devocionales.isNotEmpty) {
                currentDevocional = devocionalProvider.devocionales[0];
                canNavigateNext = devocionalProvider.devocionales.length > 1;
                canNavigatePrevious = false;
              } else {
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  ),
                );
              }

              final bool isFavorite = devocionalProvider.isFavorite(
                currentDevocional,
              );

              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: themeState.systemUiOverlayStyle,
                child: Scaffold(
                  drawer: const DevocionalesDrawer(),
                  appBar: CustomAppBar(
                    titleWidget: AutoSizeText(
                      'devotionals.my_intimate_space_with_god'.tr(),
                      maxLines: 1,
                      minFontSize: 10,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(
                          Icons.text_increase_outlined,
                          color: Colors.white,
                        ),
                        tooltip: 'bible.adjust_font_size'.tr(),
                        onPressed: _toggleFontControls,
                      ),
                    ],
                  ),
                  floatingActionButton: AnimatedFabWithText(
                    onPressed: _showAddPrayerOrThanksgivingChoice,
                    text: 'prayer.add_prayer_thanksgiving_hint'.tr(),
                    fabColor: colorScheme.primary,
                    backgroundColor: colorScheme.secondary,
                    textColor: colorScheme.onPrimaryContainer,
                    iconColor: colorScheme.onPrimary,
                  ),
                  floatingActionButtonLocation:
                      FloatingActionButtonLocation.endFloat,
                  body: Stack(
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: Screenshot(
                              controller: screenshotController,
                              child: Container(
                                color: Theme.of(
                                  context,
                                ).scaffoldBackgroundColor,
                                child: DevocionalesContentWidget(
                                  devocional: currentDevocional,
                                  fontSize: _fontSize,
                                  scrollController: _scrollController,
                                  onVerseCopy: () async {
                                    try {
                                      await Clipboard.setData(
                                        ClipboardData(
                                          text: currentDevocional.versiculo,
                                        ),
                                      );
                                      if (!context.mounted) return;
                                      HapticFeedback.selectionClick();
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      final ColorScheme colorScheme = Theme.of(
                                        context,
                                      ).colorScheme;
                                      messenger.showSnackBar(
                                        SnackBar(
                                          backgroundColor:
                                              colorScheme.secondary,
                                          duration: const Duration(seconds: 2),
                                          content: Text(
                                            'share.copied_to_clipboard'.tr(),
                                            style: TextStyle(
                                              color: colorScheme.onSecondary,
                                            ),
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      debugPrint(
                                        '[DevocionalesPage] Error copying verse to clipboard: $e',
                                      );
                                    }
                                  },
                                  onStreakBadgeTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ProgressPage(),
                                      ),
                                    );
                                  },
                                  currentStreak: _currentStreak,
                                  streakFuture: _streakFuture,
                                  getLocalizedDateFormat: (context) =>
                                      _getLocalizedDateFormat(
                                    context,
                                  ).format(DateTime.now()),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_showFontControls)
                        FloatingFontControlButtons(
                          currentFontSize: _fontSize,
                          onIncrease: _increaseFontSize,
                          onDecrease: _decreaseFontSize,
                          onClose: () =>
                              setState(() => _showFontControls = false),
                        ),
                      if (_showPostSplashAnimation)
                        Positioned(
                          top: MediaQuery.of(context).padding.top +
                              kToolbarHeight,
                          right: 0,
                          child: IgnorePointer(
                            child: Lottie.asset(
                              _selectedLottieAsset ??
                                  'assets/lottie/happy_bird.json',
                              width: 200,
                              repeat: true,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                    ],
                  ),
                  bottomNavigationBar: _buildBottomNavigationBar(
                    context,
                    currentDevocional,
                    isFavorite,
                    canNavigateNext,
                    canNavigatePrevious,
                    colorScheme,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Build bottom navigation bar (shared by both BLoC and Legacy)
  Widget _buildBottomNavigationBar(
    BuildContext context,
    Devocional currentDevocional,
    bool isFavorite,
    bool canNavigateNext,
    bool canNavigatePrevious,
    ColorScheme colorScheme,
  ) {
    return DevocionalesBottomBar(
      currentDevocional: currentDevocional,
      isFavorite: isFavorite,
      canNavigateNext: canNavigateNext,
      canNavigatePrevious: canNavigatePrevious,
      ttsAudioController: _ttsAudioController,
      onPrevious: _goToPreviousDevocional,
      onNext: _goToNextDevocional,
      onShowInvitation: () => _showInvitation(context),
      onBible: _goToBible,
      onShare: () => _shareAsText(currentDevocional),
      onPrayers: _goToPrayers,
      onFavoriteToggled: _showFavoritesFeedback,
    );
  }

  void _handleTtsStateChange() {
    try {
      final s = _ttsAudioController.state.value;

      // ✅ IMPROVED: Show modal immediately when LOADING starts (not waiting for playing)
      // This provides instant feedback and shows spinner during TTS initialization (up to 7s)
      if ((s == TtsPlayerState.loading || s == TtsPlayerState.playing) &&
          mounted &&
          !_isTtsModalShowing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _isTtsModalShowing) return;
          debugPrint(
            '🎵 [Modal] Opening modal on state: $s (immediate feedback)',
          );
          _showTtsModal();
        });
      }

      // Only mark modal as not showing when audio COMPLETES
      // Keep modal open during pause/loading (don't reset flag)
      if (s == TtsPlayerState.completed) {
        _isTtsModalShowing = false;
      }
    } catch (e) {
      debugPrint('[DevocionalesPage] Error en _handleTtsStateChange: $e');
    }
  }

  void _showTtsModal() {
    if (!mounted || _isTtsModalShowing) return;

    _isTtsModalShowing = true;

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return ValueListenableBuilder<TtsPlayerState>(
          valueListenable: _ttsAudioController.state,
          builder: (context, state, _) {
            if (state == TtsPlayerState.completed) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.canPop(ctx)) {
                  Navigator.of(ctx).pop();
                }
              });
            }

            return ValueListenableBuilder<Duration>(
              valueListenable: _ttsAudioController.currentPosition,
              builder: (context, currentPos, __) {
                return ValueListenableBuilder<Duration>(
                  valueListenable: _ttsAudioController.totalDuration,
                  builder: (context, totalDur, ___) {
                    return ValueListenableBuilder<double>(
                      valueListenable: _ttsAudioController.playbackRate,
                      builder: (context, rate, ____) {
                        return TtsMiniplayerModal(
                          positionListenable:
                              _ttsAudioController.currentPosition,
                          totalDurationListenable:
                              _ttsAudioController.totalDuration,
                          stateListenable: _ttsAudioController.state,
                          playbackRateListenable:
                              _ttsAudioController.playbackRate,
                          playbackRates: _ttsAudioController.supportedRates,
                          onStop: () {
                            _ttsAudioController.stop();
                            _isTtsModalShowing = false;
                            if (Navigator.canPop(ctx)) {
                              Navigator.of(ctx).pop();
                            }
                          },
                          onSeek: (d) => _ttsAudioController.seek(d),
                          onTogglePlay: () {
                            if (state == TtsPlayerState.playing) {
                              _ttsAudioController.pause();
                            } else {
                              try {
                                getService<AnalyticsService>().logTtsPlay();
                              } catch (e) {
                                debugPrint(
                                  '❌ Error logging TTS play analytics: $e',
                                );
                              }
                              _ttsAudioController.play();
                            }
                          },
                          onCycleRate: () async {
                            if (state == TtsPlayerState.playing) {
                              await _ttsAudioController.pause();
                            }
                            try {
                              await _ttsAudioController.cyclePlaybackRate();
                            } catch (e) {
                              debugPrint(
                                '[DevocionalesPage] cyclePlaybackRate failed: $e',
                              );
                            }
                          },
                          onVoiceSelector: () async {
                            final languageCode = Localizations.localeOf(
                              context,
                            ).languageCode;

                            // Get current devotional from BLoC state
                            final currentState = _navigationBloc.state;
                            final currentDevocional =
                                currentState is NavigationReady
                                    ? currentState.currentDevocional
                                    : Provider.of<DevocionalProvider>(
                                        context,
                                        listen: false,
                                      ).devocionales.first;

                            final sampleText = _buildTtsTextForDevocional(
                              currentDevocional,
                              languageCode,
                            );

                            if (state == TtsPlayerState.playing) {
                              await _ttsAudioController.pause();
                            }

                            await showModalBottomSheet(
                              // ignore: use_build_context_synchronously
                              context: ctx,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(28),
                                ),
                              ),
                              builder: (voiceCtx) => FractionallySizedBox(
                                heightFactor: 0.8,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(
                                      voiceCtx,
                                    ).viewInsets.bottom,
                                  ),
                                  child: VoiceSelectorDialog(
                                    language: languageCode,
                                    sampleText: sampleText,
                                    onVoiceSelected: (name, locale) async {},
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      _isTtsModalShowing = false;
    });
  }
}
