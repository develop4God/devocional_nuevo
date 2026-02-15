import 'dart:developer' as developer;
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_bloc.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_event.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/controllers/font_size_controller.dart';
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
import 'package:devocional_nuevo/utils/localized_date_formatter.dart';
import 'package:devocional_nuevo/widgets/add_entry_choice_modal.dart';
import 'package:devocional_nuevo/widgets/add_prayer_modal.dart';
import 'package:devocional_nuevo/widgets/add_testimony_modal.dart';
import 'package:devocional_nuevo/widgets/add_thanksgiving_modal.dart';
import 'package:devocional_nuevo/widgets/devocionales/app_bar_constants.dart';
import 'package:devocional_nuevo/widgets/devocionales/devocionales_content_widget.dart';
import 'package:devocional_nuevo/widgets/devocionales/devocionales_page_drawer.dart';
import 'package:devocional_nuevo/widgets/devocionales/salvation_prayer_dialog.dart';
import 'package:devocional_nuevo/widgets/devocionales/tts_modal_manager.dart';
import 'package:devocional_nuevo/widgets/floating_font_control_buttons.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lottie/lottie.dart'; // Re-agregado para animación post-splash
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/audio_controller.dart';
import '../controllers/tts_audio_controller.dart';
import '../services/analytics_service.dart';
import '../services/spiritual_stats_service.dart';
import '../widgets/animated_fab_with_text.dart';
import '../widgets/devocionales/devocionales_bottom_bar.dart';

/// Initialization state for the devotionals page
/// Following Flutter state management best practices
enum _PageInitializationState {
  /// Initial state - waiting to start initialization
  notStarted,

  /// Loading devotionals and initializing BLoC
  loading,

  /// Successfully initialized and ready to display content
  ready,

  /// Initialization failed - can retry
  error,
}

/// Configuration constants for the devotionals page
/// Avoiding magic numbers as per Flutter style guide
class _PageConstants {
  const _PageConstants._();

  /// Duration for post-splash animation display
  static const postSplashAnimationDuration = Duration(seconds: 7);

  /// Duration for scroll-to-top animation
  static const scrollToTopDuration = Duration(milliseconds: 300);

  /// Lottie animation width
  static const lottieAnimationWidth = 200.0;

  /// Delay before stopping audio on navigation
  static const audioStopDelay = Duration(milliseconds: 100);
}

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
  late final TtsModalManager _ttsModalManager;
  final FontSizeController _fontSizeController = FontSizeController();
  AudioController? _audioController;
  bool _routeSubscribed = false;
  int _currentStreak = 0;
  late Future<int> _streakFuture;

  // Navigation BLoC and initialization state
  DevocionalesNavigationBloc? _navigationBloc;
  _PageInitializationState _initState = _PageInitializationState.notStarted;
  String? _initErrorMessage;

  // Track last processed devotionals to prevent duplicate updates
  List<Devocional>? _lastProcessedDevocionales;

  // Repository instances - reused to avoid re-instantiation
  late final NavigationRepositoryImpl _navigationRepository =
      NavigationRepositoryImpl();
  late final DevocionalRepositoryImpl _devocionalRepository =
      DevocionalRepositoryImpl();

  static bool _postSplashAnimationShown =
      false; // Controla mostrar solo una vez
  bool _showPostSplashAnimation = false; // Estado local

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
    _ttsModalManager = TtsModalManager(ttsAudioController: _ttsAudioController);
    // Listener para cerrar miniplayer automáticamente cuando el TTS complete
    _ttsAudioController.state.addListener(_handleTtsStateChange);
    _fontSizeController.addListener(_onFontSizeChanged);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _audioController = Provider.of<AudioController>(context, listen: false);
      _tracking.initialize(context);
      _precacheLottieAnimations();
    });
    _fontSizeController.load();

    // Initialize BLoC asynchronously after devotionals load
    // This prevents 30-second spinner on app start
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
      Future.delayed(_PageConstants.postSplashAnimationDuration, () {
        if (mounted) setState(() => _showPostSplashAnimation = false);
      });
    }
  }

  void _onFontSizeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initializeNavigationBloc() async {
    // Prevent multiple simultaneous initialization attempts
    if (_initState == _PageInitializationState.loading) {
      developer
          .log('Initialization already in progress, skipping duplicate call');
      return;
    }

    setState(() {
      _initState = _PageInitializationState.loading;
      _initErrorMessage = null;
    });

    // Direct async initialization - no postFrameCallback needed for Provider access
    try {
      if (!mounted) return;

      final devocionalProvider = Provider.of<DevocionalProvider>(
        context,
        listen: false,
      );

      // Wait for devotionals to load if needed
      if (!devocionalProvider.isLoading &&
          devocionalProvider.devocionales.isEmpty) {
        await devocionalProvider.initializeData();
        if (!mounted) return;
      }

      // Validate devotionals are available
      if (devocionalProvider.devocionales.isEmpty) {
        throw StateError('No devotionals available after initialization');
      }

      // Create BLoC with reused repository instances (avoids re-instantiation)
      _navigationBloc = DevocionalesNavigationBloc(
        navigationRepository: _navigationRepository,
        devocionalRepository: _devocionalRepository,
      );

      // Record daily app visit
      final spiritualStatsService = SpiritualStatsService();
      await spiritualStatsService.recordDailyAppVisit();

      // Get read devotional IDs for finding first unread
      final stats = await spiritualStatsService.getStats();
      final readDevocionalIds = stats.readDevocionalIds;

      // Determine initial index
      final initialIndex = _calculateInitialIndex(
        devocionalProvider.devocionales,
        readDevocionalIds,
      );

      // Initialize navigation with full devotionals list
      if (!mounted || _navigationBloc == null || _navigationBloc!.isClosed) {
        return;
      }

      _navigationBloc!.add(
        InitializeNavigation(
          initialIndex: initialIndex,
          devocionales: devocionalProvider.devocionales,
        ),
      );

      // Mark as successfully initialized
      if (mounted) {
        setState(() {
          _initState = _PageInitializationState.ready;
        });
      }

      // CRITICAL FIX: Start tracking explicitly after BLoC initialization
      // BlocListener only triggers on state CHANGES, not initial state
      // So we need to manually start tracking for the initial devotional
      if (mounted &&
          initialIndex >= 0 &&
          initialIndex < devocionalProvider.devocionales.length) {
        final initialDevocional = devocionalProvider.devocionales[initialIndex];
        debugPrint(
            '[DEVOCIONALES_PAGE] 🚀 Starting tracking for initial devotional: ${initialDevocional.id}');
        _tracking.clearAutoCompletedExcept(initialDevocional.id);
        _tracking.startDevocionalTracking(
          initialDevocional.id,
          _scrollController,
        );
      }

      developer.log(
          'Navigation BLoC initialized successfully at index: $initialIndex');
    } catch (error, stackTrace) {
      // Log raw error for debugging
      developer.log('Failed to initialize BLoC: $error');
      developer.log('Stack trace: $stackTrace');

      // CRITICAL FIX: Close BLoC before nulling to prevent memory leak
      try {
        await _navigationBloc?.close();
      } catch (e) {
        developer.log('Error closing BLoC during cleanup: $e');
      }
      _navigationBloc = null;

      // Record error for debugging
      try {
        await FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          reason: 'Failed to initialize DevocionalesNavigationBloc',
          fatal: false,
        );
      } catch (_) {
        developer.log('Failed to report initialization error to Crashlytics');
      }

      // Update state to error with user-friendly message
      if (mounted) {
        setState(() {
          _initState = _PageInitializationState.error;
          // Show raw error only in debug mode, otherwise show friendly localized message
          _initErrorMessage =
              kDebugMode ? error.toString() : 'devotionals.generic_error'.tr();
        });
      }
    }
  }

  /// Calculate the initial devotional index based on user state
  /// Returns the first unread devotional or deep link index
  int _calculateInitialIndex(
    List<Devocional> devocionales,
    List<String> readDevocionalIds,
  ) {
    // Handle deep link scenario
    if (widget.initialDevocionalId != null) {
      final index = devocionales.indexWhere(
        (d) => d.id == widget.initialDevocionalId,
      );
      return index != -1 ? index : 0;
    }

    // Find first unread using reused repository instance
    return _devocionalRepository.findFirstUnreadDevocionalIndex(
      devocionales,
      readDevocionalIds,
    );
  }

  /// Reliably compare two devotional lists by their IDs
  /// Avoids hashCode collision bugs
  bool _areDevocionalListsEqual(
    List<Devocional> list1,
    List<Devocional> list2,
  ) {
    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }

    return true;
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
    // Update the currentStreak state to ensure UI reflects latest value
    final streak = stats.currentStreak;
    setState(() {
      _currentStreak = streak;
    });
    debugPrint('🔥 Streak loaded and updated: $streak');
    return streak;
  }

  void _pickRandomLottie() {
    final random = Random();
    setState(() {
      _selectedLottieAsset =
          _lottieAssets[random.nextInt(_lottieAssets.length)];
    });
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

      // Refresh streak data to ensure fire lottie shows current value
      _streakFuture = _loadStreak();

      // Retry initialization if needed based on state
      if (_initState == _PageInitializationState.notStarted ||
          _initState == _PageInitializationState.error) {
        debugPrint(
          '🔄 Retrying BLoC initialization on resume (current state: $_initState)',
        );
        _initializeNavigationBloc();
      }

      // Refresh UI state to ensure everything is in sync
      if (mounted) {
        setState(() {
          debugPrint('🔄 Forcing UI refresh after app resume');
        });
      }

      debugPrint('✅ App resumed - tracking and UI refreshed');
    }
  }

  @override
  void didPush() {
    // Only resume if there's actually something being tracked
    // Otherwise we'll start an empty criteria timer
    debugPrint(
        '📄 DevocionalesPage pushed → checking if tracking should resume');
    final devocionalProvider =
        Provider.of<DevocionalProvider>(context, listen: false);
    if (devocionalProvider.currentTrackedDevocionalId != null) {
      _tracking.resumeTracking();
      debugPrint(
          '📄 Tracking resumed for: ${devocionalProvider.currentTrackedDevocionalId}');
    } else {
      debugPrint(
          '📄 No active tracking to resume - waiting for BLoC to initialize');
    }
  }

  @override
  void didPopNext() {
    // Refresh streak when returning to this page (e.g., from ProgressPage)
    _streakFuture = _loadStreak();

    // Only resume if there's actually something being tracked
    final devocionalProvider =
        Provider.of<DevocionalProvider>(context, listen: false);
    if (devocionalProvider.currentTrackedDevocionalId != null) {
      _tracking.resumeTracking();
      debugPrint(
          '📄 DevocionalesPage popped next → tracking resumed & streak refreshed');
    } else {
      debugPrint(
          '📄 DevocionalesPage popped next → no tracking to resume, streak refreshed');
    }
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
    _ttsModalManager.dispose();
    _fontSizeController.removeListener(_onFontSizeChanged);
    _fontSizeController.dispose();
    _tracking.dispose();
    _scrollController.dispose();
    _navigationBloc?.close(); // Clean up BLoC if it was created
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    if (!mounted) return;
    setState(() {});
  }

  void _goToNextDevocional() async {
    try {
      // Guard: Don't navigate if BLoC is not ready (prevents race condition)
      if (_navigationBloc == null ||
          _navigationBloc!.state is! NavigationReady) {
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
        await Future.delayed(_PageConstants.audioStopDelay);
        if (!mounted) return; // Check again after delay
      } else {
        await _stopSpeaking();
      }

      if (!mounted) return;

      // Get current state for analytics
      final currentState = _navigationBloc!.state;
      final currentIndex =
          currentState is NavigationReady ? currentState.currentIndex : 0;
      final totalDevocionales =
          currentState is NavigationReady ? currentState.totalDevocionales : 0;

      // Dispatch navigation event
      _navigationBloc!.add(const NavigateToNext());

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
      if (_navigationBloc == null ||
          _navigationBloc!.state is! NavigationReady) {
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
        await Future.delayed(_PageConstants.audioStopDelay);
        if (!mounted) return; // Check again after delay
      } else {
        await _stopSpeaking();
      }

      if (!mounted) return;

      // Get current state for analytics
      final currentState = _navigationBloc!.state;
      final currentIndex =
          currentState is NavigationReady ? currentState.currentIndex : 0;
      final totalDevocionales =
          currentState is NavigationReady ? currentState.totalDevocionales : 0;

      // Dispatch navigation event
      _navigationBloc!.add(const NavigateToPrevious());

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
          duration: _PageConstants.scrollToTopDuration,
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _showInvitation(BuildContext context) {
    SalvationPrayerDialog.show(context);
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
      '🟩 [Bible] Versions for app language ($appLanguage): '
      '${versions.map((v) => "${v.name} (${v.languageCode}) - downloaded: ${v.isDownloaded}").join(', ')}',
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

  @override
  Widget build(BuildContext context) {
    return _buildWithBloc(context);
  }

  /// Build loading scaffold while devotionals are initializing
  Widget _buildLoadingScaffold(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        titleText: 'devotionals.my_intimate_space_with_god'.tr(),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'devotionals.loading'.tr(),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  /// Build error scaffold when initialization fails
  Widget _buildErrorScaffold(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        titleText: 'devotionals.my_intimate_space_with_god'.tr(),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'devotionals.error_loading'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Show user-friendly error message
              if (_initErrorMessage != null)
                Text(
                  _initErrorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  developer.log('🔄 User manually triggered retry');
                  _initializeNavigationBloc();
                },
                icon: const Icon(Icons.refresh),
                label: Text('devotionals.retry'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build UI using Navigation BLoC
  Widget _buildWithBloc(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;

    // Listen to DevocionalProvider changes to update BLoC when bible version or language changes
    return Consumer<DevocionalProvider>(
      builder: (context, devocionalProvider, child) {
        // CRITICAL FIX: Check for devotional changes synchronously (no postFrameCallback)
        // Only update if list actually changed (avoid hashCode collision bug)
        if (_navigationBloc != null &&
            _initState == _PageInitializationState.ready &&
            devocionalProvider.devocionales.isNotEmpty) {
          final currentState = _navigationBloc!.state;

          if (currentState is NavigationReady) {
            final newList = devocionalProvider.devocionales;

            // Use reference equality check instead of unreliable hashCode
            final bool listsAreDifferent =
                !identical(_lastProcessedDevocionales, newList) &&
                    (_lastProcessedDevocionales == null ||
                        _lastProcessedDevocionales!.length != newList.length ||
                        !_areDevocionalListsEqual(
                            _lastProcessedDevocionales!, newList));

            if (listsAreDifferent) {
              // Schedule update after this build completes (only once per change)
              _lastProcessedDevocionales = newList;
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!mounted || _navigationBloc == null) return;

                // Get fresh stats to find correct unread index in the new version
                final stats = await SpiritualStatsService().getStats();
                _navigationBloc!.add(
                  UpdateDevocionales(newList, stats.readDevocionalIds),
                );
              });
            }
          }
        }

        // Handle initialization states with proper UI feedback
        switch (_initState) {
          case _PageInitializationState.notStarted:
          case _PageInitializationState.loading:
            return _buildLoadingScaffold(context);

          case _PageInitializationState.error:
            return _buildErrorScaffold(context);

          case _PageInitializationState.ready:
            // Continue to BLoC builder if ready
            break;
        }

        // Verify BLoC is actually ready (defensive check)
        if (_navigationBloc == null) {
          return _buildLoadingScaffold(context);
        }

        return BlocListener<DevocionalesNavigationBloc,
            DevocionalesNavigationState>(
          bloc: _navigationBloc!,
          listener: (context, state) {
            debugPrint(
                '[DEVOCIONALES_PAGE] 🔔 BlocListener triggered - state: ${state.runtimeType}');
            if (state is NavigationReady) {
              debugPrint(
                  '[DEVOCIONALES_PAGE] ✅ NavigationReady - starting tracking for: ${state.currentDevocional.id}');
              // Start tracking when navigation state changes
              _tracking.clearAutoCompletedExcept(state.currentDevocional.id);
              _tracking.startDevocionalTracking(
                state.currentDevocional.id,
                _scrollController,
              );
            } else {
              debugPrint(
                  '[DEVOCIONALES_PAGE] ⏭️ State is not NavigationReady, skipping tracking');
            }
          },
          child: BlocBuilder<DevocionalesNavigationBloc,
              DevocionalesNavigationState>(
            bloc: _navigationBloc!,
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
                        onPressed: _fontSizeController.toggleControls,
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
                                  fontSize: _fontSizeController.fontSize,
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
                                      LocalizedDateFormatter.formatForContext(
                                    context,
                                  ),
                                  isFavorite: isFavorite,
                                  onFavoriteToggle: () async {
                                    final wasAdded = await devocionalProvider
                                        .toggleFavorite(currentDevocional.id);
                                    _showFavoritesFeedback(wasAdded);
                                  },
                                  onShare: () =>
                                      _shareAsText(currentDevocional),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_fontSizeController.showControls)
                        FloatingFontControlButtons(
                          currentFontSize: _fontSizeController.fontSize,
                          onIncrease: _fontSizeController.increase,
                          onDecrease: _fontSizeController.decrease,
                          onClose: _fontSizeController.hideControls,
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
                              width: _PageConstants.lottieAnimationWidth,
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
      canNavigateNext: canNavigateNext,
      canNavigatePrevious: canNavigatePrevious,
      ttsAudioController: _ttsAudioController,
      onPrevious: _goToPreviousDevocional,
      onNext: _goToNextDevocional,
      onShowInvitation: () => _showInvitation(context),
      onBible: _goToBible,
      onPrayers: _goToPrayers,
    );
  }

  void _handleTtsStateChange() {
    try {
      final s = _ttsAudioController.state.value;

      // Show modal immediately when LOADING starts (instant feedback)
      if ((s == TtsPlayerState.loading || s == TtsPlayerState.playing) &&
          mounted &&
          !_ttsModalManager.isShowing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _ttsModalManager.isShowing) return;
          debugPrint(
            '🎵 [Modal] Opening modal on state: $s (immediate feedback)',
          );
          _ttsModalManager.showTtsModal(context, _getCurrentDevocional);
        });
      }

      // Close modal when audio completes or goes to idle
      if (s == TtsPlayerState.completed || s == TtsPlayerState.idle) {
        if (_ttsModalManager.isShowing) {
          _ttsModalManager.dispose();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && Navigator.canPop(context)) {
              debugPrint(
                '🏁 [Modal] Closing modal on state: $s (auto-cleanup)',
              );
              Navigator.of(context).pop();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('[DevocionalesPage] Error en _handleTtsStateChange: $e');
    }
  }

  /// Get the current devotional from BLoC or provider fallback
  Devocional? _getCurrentDevocional() {
    final currentState = _navigationBloc?.state;
    if (currentState is NavigationReady) {
      return currentState.currentDevocional;
    }
    final provider = Provider.of<DevocionalProvider>(context, listen: false);
    return provider.devocionales.isNotEmpty
        ? provider.devocionales.first
        : null;
  }
}
