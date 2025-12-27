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
import 'package:devocional_nuevo/pages/settings_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/repositories/navigation_repository_impl.dart';
import 'package:devocional_nuevo/repositories/devocional_repository_impl.dart';
import 'package:devocional_nuevo/services/devocionales_tracking.dart';
import 'package:devocional_nuevo/services/update_service.dart';
import 'package:devocional_nuevo/utils/bubble_constants.dart';
import 'package:devocional_nuevo/widgets/add_prayer_modal.dart';
import 'package:devocional_nuevo/widgets/add_thanksgiving_modal.dart';
import 'package:devocional_nuevo/widgets/app_bar_constants.dart';
import 'package:devocional_nuevo/widgets/devocionales/devocionales_content_widget.dart';
import 'package:devocional_nuevo/widgets/devocionales_page_drawer.dart';
import 'package:devocional_nuevo/widgets/floating_font_control_buttons.dart';
import 'package:devocional_nuevo/widgets/tts_miniplayer_modal.dart';
import 'package:devocional_nuevo/widgets/tts_player_widget.dart';
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

import 'package:devocional_nuevo/services/service_locator.dart';
import '../controllers/audio_controller.dart';
import '../controllers/tts_audio_controller.dart';
import '../services/analytics_service.dart';
import '../services/spiritual_stats_service.dart';
import '../services/tts/bible_text_formatter.dart';
import '../widgets/voice_selector_dialog.dart';
import '../widgets/animated_fab_with_text.dart';

class DevocionalesPage extends StatefulWidget {
  final String? initialDevocionalId;

  const DevocionalesPage({super.key, this.initialDevocionalId});

  @override
  State<DevocionalesPage> createState() => _DevocionalesPageState();
}

class _DevocionalesPageState extends State<DevocionalesPage>
    with WidgetsBindingObserver, RouteAware {
  // Feature flag: Master switch to enable/disable Navigation BLoC
  // Timeline: 30 days monitoring, then remove legacy code if stable
  // Days 1-7: Monitor Crashlytics for BLoC errors
  // Days 8-14: Analyze analytics data, verify BLoC adoption
  // Days 15-21: Gradual rollout to 50%, 75%, 100% (if no issues)
  // Days 22-30: Stability monitoring
  // After Day 30: Remove legacy code (separate PR)
  static const bool _useNavigationBloc = true;

  final ScreenshotController screenshotController = ScreenshotController();
  final ScrollController _scrollController = ScrollController();
  int _currentDevocionalIndex = 0;
  static const String _lastDevocionalIndexKey = 'lastDevocionalIndex';
  final DevocionalesTracking _tracking = DevocionalesTracking();
  final FlutterTts _flutterTts = FlutterTts();
  late final TtsAudioController _ttsAudioController;
  AudioController? _audioController;
  bool _routeSubscribed = false;
  int _currentStreak = 0;
  late Future<int> _streakFuture;

  // Navigation BLoC (only used when _useNavigationBloc = true)
  DevocionalesNavigationBloc? _navigationBloc;

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

    // Feature flag: Choose between BLoC and legacy navigation
    if (_useNavigationBloc) {
      // Create BLoC immediately to avoid spinner on app start
      _navigationBloc = DevocionalesNavigationBloc(
        navigationRepository: NavigationRepositoryImpl(),
        devocionalRepository: DevocionalRepositoryImpl(),
      );
      // Initialize asynchronously in background
      _initializeNavigationBloc();

      // Log analytics event for app initialization with BLoC
      getService<AnalyticsService>().logAppInit(parameters: {
        'use_navigation_bloc': 'true',
      });
    } else {
      _loadInitialDataLegacy();
    }

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
    if (mounted) {
      setState(() {
        _currentStreak = stats.currentStreak;
      });
    }
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
    } else if (state == AppLifecycleState.resumed) {
      _tracking.resumeTracking();
      debugPrint('🔄 App resumed - tracking and criteria timer resumed');
      UpdateService.checkForUpdate();
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
    _navigationBloc?.close(); // Clean up BLoC if initialized
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() {});
  }

  Future<void> _loadInitialDataLegacy() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final devocionalProvider = Provider.of<DevocionalProvider>(
        context,
        listen: false,
      );

      if (!devocionalProvider.isLoading &&
          devocionalProvider.devocionales.isEmpty) {
        await devocionalProvider.initializeData();
        if (!mounted) return;
      }

      if (devocionalProvider.devocionales.isNotEmpty) {
        final spiritualStatsService = SpiritualStatsService();
        await spiritualStatsService.recordDailyAppVisit();

        // Get read devotional IDs to filter already completed ones
        final stats = await spiritualStatsService.getStats();
        final readDevocionalIds = stats.readDevocionalIds;

        if (mounted) {
          setState(() {
            // Find the first unread devotional
            _currentDevocionalIndex = _findFirstUnreadDevocionalIndexLegacy(
              devocionalProvider.devocionales,
              readDevocionalIds,
            );
            developer.log(
              'Devocional cargado al inicio (primer no leído): $_currentDevocionalIndex',
            );
          });
          _startTrackingCurrentDevocionalLegacy();
        }
      } else {
        if (mounted) {
          setState(() {
            _currentDevocionalIndex = 0;
          });
        }
        developer.log('No hay devocionales disponibles para cargar el índice.');
      }

      if (widget.initialDevocionalId != null &&
          devocionalProvider.devocionales.isNotEmpty) {
        final index = devocionalProvider.devocionales.indexWhere(
          (d) => d.id == widget.initialDevocionalId,
        );
        if (index != -1) {
          if (mounted) {
            setState(() {
              _currentDevocionalIndex = index;
            });
            _startTrackingCurrentDevocionalLegacy();
          }
        }
      }
    });
  }

  /// Initialize Navigation BLoC with devotionals from provider
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
        // Find first unread
        initialIndex = _navigationBloc!.findFirstUnreadDevocionalIndex(
          devocionalProvider.devocionales,
          readDevocionalIds,
        );
      }

      // Initialize navigation with full devotionals list
      _navigationBloc!.add(
        InitializeNavigation(
          initialIndex: initialIndex,
          devocionales: devocionalProvider.devocionales,
        ),
      );

      developer.log(
        'Navigation BLoC initialized at index: $initialIndex',
      );
    });
  }

  /// Find the first unread devotional index starting from the beginning (Legacy)
  int _findFirstUnreadDevocionalIndexLegacy(
    List<Devocional> devocionales,
    List<String> readDevocionalIds,
  ) {
    if (devocionales.isEmpty) return 0;

    // Start from index 0 and find the first unread devotional
    for (int i = 0; i < devocionales.length; i++) {
      if (!readDevocionalIds.contains(devocionales[i].id)) {
        developer.log(
          'Primer devocional no leído encontrado en índice: $i (ID: ${devocionales[i].id})',
        );
        return i;
      }
    }

    // If all devotionals are read, start from the beginning
    developer.log(
      'Todos los devocionales han sido leídos, iniciando desde el principio',
    );
    return 0;
  }

  void _startTrackingCurrentDevocionalLegacy() {
    final devocionalProvider = Provider.of<DevocionalProvider>(
      context,
      listen: false,
    );
    if (devocionalProvider.devocionales.isNotEmpty &&
        _currentDevocionalIndex < devocionalProvider.devocionales.length) {
      final currentDevocional =
          devocionalProvider.devocionales[_currentDevocionalIndex];
      _tracking.clearAutoCompletedExcept(currentDevocional.id);
      _tracking.startDevocionalTracking(
        currentDevocional.id,
        _scrollController,
      );
    }
  }

  void _goToNextDevocional() async {
    if (_useNavigationBloc) {
      // BLoC mode: Dispatch NavigateToNext event with error handling and fallback
      if (_navigationBloc == null) return;

      try {
        // Stop audio/TTS before navigation
        if (_audioController != null && _audioController!.isActive) {
          debugPrint(
            'DevocionalesPage: Stopping AudioController before navigation',
          );
          await _audioController!.stop();
          await Future.delayed(const Duration(milliseconds: 100));
        } else {
          await _stopSpeaking();
        }

        if (!mounted) return;

        // Get current state for analytics
        final currentState = _navigationBloc!.state;
        final currentIndex =
            currentState is NavigationReady ? currentState.currentIndex : 0;
        final totalDevocionales = currentState is NavigationReady
            ? currentState.totalDevocionales
            : 0;

        // Dispatch navigation event
        _navigationBloc!.add(const NavigateToNext());

        // Scroll to top
        _scrollToTop();

        // Trigger haptic feedback
        HapticFeedback.mediumImpact();

        // Log analytics event (BLoC path)
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
        debugPrint('❌ BLoC navigation error, falling back to legacy: $e');
        await FirebaseCrashlytics.instance.recordError(
          e,
          stackTrace,
          reason: 'NavigationBloc.NavigateToNext failed',
          information: [
            'Feature: Navigation BLoC',
            'Action: Navigate to next devotional',
            'Fallback: Legacy navigation activated',
          ],
          fatal: false,
        );

        // Fallback to legacy navigation
        _goToNextDevocionalLegacy();

        // Log analytics event (fallback path)
        await getService<AnalyticsService>().logNavigationNext(
          currentIndex: _currentDevocionalIndex,
          totalDevocionales: 0,
          viaBloc: 'false',
          fallbackReason: 'bloc_error',
        );
      }
    } else {
      _goToNextDevocionalLegacy();
    }
  }

  void _goToNextDevocionalLegacy() async {
    if (!mounted) return;

    final devocionalProvider = Provider.of<DevocionalProvider>(
      context,
      listen: false,
    );

    final List<Devocional> devocionales = devocionalProvider.devocionales;

    if (_currentDevocionalIndex < devocionales.length - 1) {
      if (_audioController != null && _audioController!.isActive) {
        debugPrint(
          'DevocionalesPage: Stopping AudioController before navigation',
        );
        await _audioController!.stop();
        await Future.delayed(const Duration(milliseconds: 100));
      } else {
        await _stopSpeaking();
      }

      setState(() {
        _currentDevocionalIndex++;
      });

      _scrollToTop();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTrackingCurrentDevocionalLegacy();
      });

      HapticFeedback.mediumImpact(); // Changed from lightImpact

      if (devocionalProvider.showInvitationDialog) {
        if (mounted) {
          _showInvitation(context);
        }
      }

      _saveCurrentDevocionalIndexLegacy();
    }
  }

  void _goToPreviousDevocional() async {
    if (_useNavigationBloc) {
      // BLoC mode: Dispatch NavigateToPrevious event with error handling and fallback
      if (_navigationBloc == null) return;

      try {
        // Stop audio/TTS before navigation
        if (_audioController != null && _audioController!.isActive) {
          debugPrint(
            'DevocionalesPage: Stopping AudioController before navigation',
          );
          await _audioController!.stop();
          await Future.delayed(const Duration(milliseconds: 100));
        } else {
          await _stopSpeaking();
        }

        // Get current state for analytics
        final currentState = _navigationBloc!.state;
        final currentIndex =
            currentState is NavigationReady ? currentState.currentIndex : 0;
        final totalDevocionales = currentState is NavigationReady
            ? currentState.totalDevocionales
            : 0;

        // Dispatch navigation event
        _navigationBloc!.add(const NavigateToPrevious());

        // Scroll to top
        _scrollToTop();

        // Trigger haptic feedback
        HapticFeedback.mediumImpact();

        // Log analytics event (BLoC path)
        await getService<AnalyticsService>().logNavigationPrevious(
          currentIndex: currentIndex,
          totalDevocionales: totalDevocionales,
          viaBloc: 'true',
        );
      } catch (e, stackTrace) {
        // Log error to Crashlytics
        debugPrint('❌ BLoC navigation error, falling back to legacy: $e');
        await FirebaseCrashlytics.instance.recordError(
          e,
          stackTrace,
          reason: 'NavigationBloc.NavigateToPrevious failed',
          information: [
            'Feature: Navigation BLoC',
            'Action: Navigate to previous devotional',
            'Fallback: Legacy navigation activated',
          ],
          fatal: false,
        );

        // Fallback to legacy navigation
        _goToPreviousDevocionalLegacy();

        // Log analytics event (fallback path)
        await getService<AnalyticsService>().logNavigationPrevious(
          currentIndex: _currentDevocionalIndex,
          totalDevocionales: 0,
          viaBloc: 'false',
          fallbackReason: 'bloc_error',
        );
      }
    } else {
      _goToPreviousDevocionalLegacy();
    }
  }

  void _goToPreviousDevocionalLegacy() async {
    if (_currentDevocionalIndex > 0) {
      if (_audioController != null && _audioController!.isActive) {
        debugPrint(
          'DevocionalesPage: Stopping AudioController before navigation',
        );
        await _audioController!.stop();
        await Future.delayed(const Duration(milliseconds: 100));
      } else {
        await _stopSpeaking();
      }

      setState(() {
        _currentDevocionalIndex--;
      });

      _scrollToTop();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTrackingCurrentDevocionalLegacy();
      });

      HapticFeedback.mediumImpact(); // Changed from lightImpact
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

  Future<void> _saveCurrentDevocionalIndexLegacy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastDevocionalIndexKey, _currentDevocionalIndex);
    developer.log('Índice de devocional guardado: $_currentDevocionalIndex');
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

  Devocional? getCurrentDevocional(List<Devocional> devocionales) {
    if (devocionales.isNotEmpty &&
        _currentDevocionalIndex >= 0 &&
        _currentDevocionalIndex < devocionales.length) {
      return devocionales[_currentDevocionalIndex];
    }
    return null;
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
      default:
        return DateFormat('EEEE, MMMM d', 'en');
    }
  }

  Future<void> _shareAsText(Devocional devocional) async {
    final meditationsText =
        devocional.paraMeditar.map((p) => '${p.cita}: ${p.texto}').join('\n');

    final devotionalText = "devotionals.share_text_format".tr({
      'verse': devocional.versiculo,
      'reflection': devocional.reflexion,
      'meditations': meditationsText,
      'prayer': devocional.oracion,
    });

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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
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
              const SizedBox(height: 20),
              Text(
                'devotionals.choose_option'.tr(),
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _showAddPrayerModal();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: colorScheme.outline),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text('🙏', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              'prayer.prayer'.tr(),
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _showAddThanksgivingModal();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: colorScheme.outline),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text('☺️', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              'thanksgiving.thanksgiving'.tr(),
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
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

  String expandBibleVersion(String version, String language) {
    final expansions = BibleTextFormatter.getBibleVersionExpansions(language);
    return expansions[version] ?? version;
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
    // Delegate to BLoC or Legacy builder based on feature flag
    return _useNavigationBloc ? _buildWithBloc(context) : _buildLegacy(context);
  }

  /// Build UI using Navigation BLoC (when feature flag is true)
  Widget _buildWithBloc(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;

    // Listen to DevocionalProvider changes to update BLoC when bible version or language changes
    return Consumer<DevocionalProvider>(
      builder: (context, devocionalProvider, child) {
        // When devotionals change (language/version change), update BLoC
        // Use hashCode comparison for O(1) performance instead of list comparison
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_navigationBloc != null &&
              devocionalProvider.devocionales.isNotEmpty) {
            final currentState = _navigationBloc!.state;
            if (currentState is NavigationReady) {
              // Efficient check: compare list length and hashCode
              final currentList = currentState.devocionales;
              final newList = devocionalProvider.devocionales;
              if (currentList.length != newList.length ||
                  currentList.hashCode != newList.hashCode) {
                // Update BLoC with new devotionals list
                // The BLoC will automatically clamp the current index
                _navigationBloc!.add(
                  UpdateDevocionales(devocionalProvider.devocionales),
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
                return Scaffold(
                  appBar: AppBar(title: Text('devotionals.error'.tr())),
                  body: Center(
                    child: Text(
                      state.message,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.error),
                    ),
                  ),
                );
              }

              // While BLoC is initializing, use provider data if available
              // This prevents spinner on app start - shows first devotional immediately
              Devocional currentDevocional;
              bool canNavigateNext;
              bool canNavigatePrevious;

              if (state is NavigationReady) {
                currentDevocional = state.currentDevocional;
                canNavigateNext = state.canNavigateNext;
                canNavigatePrevious = state.canNavigatePrevious;
              } else if (devocionalProvider.devocionales.isNotEmpty) {
                // Use provider data temporarily while BLoC initializes
                currentDevocional = devocionalProvider.devocionales[0];
                canNavigateNext = devocionalProvider.devocionales.length > 1;
                canNavigatePrevious = false;
              } else {
                // Only show spinner if provider is also loading
                return Scaffold(
                  body: Center(
                    child:
                        CircularProgressIndicator(color: colorScheme.primary),
                  ),
                );
              }

              // Listen to provider for isFavorite to rebuild when favorites change
              final bool isFavorite =
                  devocionalProvider.isFavorite(currentDevocional);

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
                        icon: const Icon(Icons.text_increase_outlined,
                            color: Colors.white),
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
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
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
                                      final messenger =
                                          ScaffoldMessenger.of(context);
                                      final ColorScheme colorScheme =
                                          Theme.of(context).colorScheme;
                                      messenger.showSnackBar(
                                        SnackBar(
                                          backgroundColor:
                                              colorScheme.secondary,
                                          duration: const Duration(seconds: 2),
                                          content: Text(
                                            'share.copied_to_clipboard'.tr(),
                                            style: TextStyle(
                                                color: colorScheme.onSecondary),
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      debugPrint(
                                          '[DevocionalesPage] Error copying verse to clipboard: $e');
                                    }
                                  },
                                  onStreakBadgeTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const ProgressPage()),
                                    );
                                  },
                                  currentStreak: _currentStreak,
                                  streakFuture: _streakFuture,
                                  getLocalizedDateFormat: (context) =>
                                      _getLocalizedDateFormat(context)
                                          .format(DateTime.now()),
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
    final Color? appBarBackgroundColor =
        Theme.of(context).appBarTheme.backgroundColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: const BoxDecoration(color: Colors.transparent),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          child: Column(
            children: [
              Consumer<AudioController>(
                builder: (context, audioController, _) {
                  final progress = audioController.progress;
                  return LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.grey[300],
                    color: colorScheme.primary,
                  );
                },
              ),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 45,
                      child: OutlinedButton.icon(
                        key: const Key('bottom_nav_previous_button'),
                        onPressed: canNavigatePrevious
                            ? _goToPreviousDevocional
                            : null,
                        icon: Icon(
                          Icons.arrow_back_ios,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        label: Text(
                          'devotionals.previous'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: colorScheme.primary,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          foregroundColor: colorScheme.primary,
                          overlayColor: colorScheme.primary
                              .withAlpha((0.1 * 255).round()),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Builder(
                        builder: (context) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TtsPlayerWidget(
                                key: const Key('bottom_nav_tts_player'),
                                devocional: currentDevocional,
                                audioController: _ttsAudioController,
                                onCompleted: () {
                                  final provider =
                                      Provider.of<DevocionalProvider>(context,
                                          listen: false);
                                  if (provider.showInvitationDialog) {
                                    _showInvitation(context);
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 45,
                      child: OutlinedButton(
                        key: const Key('bottom_nav_next_button'),
                        onPressed: canNavigateNext ? _goToNextDevocional : null,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: colorScheme.primary,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          foregroundColor: colorScheme.primary,
                          overlayColor: colorScheme.primary
                              .withAlpha((0.1 * 255).round()),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'devotionals.next'.tr(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Add rest of bottom navigation bar code
        _buildActionButtons(context, currentDevocional, isFavorite,
            appBarBackgroundColor, colorScheme),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    Devocional currentDevocional,
    bool isFavorite,
    Color? appBarBackgroundColor,
    ColorScheme colorScheme,
  ) {
    final devocionalProvider = Provider.of<DevocionalProvider>(
      context,
      listen: false,
    );

    return SafeArea(
      top: false,
      child: BottomAppBar(
        height: 60,
        color: appBarBackgroundColor,
        padding: EdgeInsets.zero,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                key: const Key('bottom_appbar_favorite_icon'),
                tooltip: isFavorite
                    ? 'devotionals.remove_from_favorites_short'.tr()
                    : 'devotionals.save_as_favorite'.tr(),
                onPressed: () {
                  getService<AnalyticsService>()
                      .logBottomBarAction(action: 'favorite');
                  devocionalProvider.toggleFavorite(
                    currentDevocional,
                    context,
                  );
                },
                icon: Icon(
                  isFavorite ? Icons.star : Icons.favorite_border,
                  color: isFavorite ? Colors.amber : Colors.white,
                  size: 32,
                ),
              ),
              IconButton(
                key: const Key('bottom_appbar_prayers_icon'),
                tooltip: 'tooltips.my_prayers'.tr(),
                onPressed: () async {
                  getService<AnalyticsService>()
                      .logBottomBarAction(action: 'prayers');
                  HapticFeedback.mediumImpact();
                  await BubbleUtils.markAsShown(
                    BubbleUtils.getIconBubbleId(
                      Icons.local_fire_department_outlined,
                      'new',
                    ),
                  );
                  _goToPrayers();
                },
                icon: const Icon(
                  Icons.local_fire_department_outlined,
                  color: Colors.white,
                  size: 35,
                ),
              ),
              IconButton(
                key: const Key('bottom_appbar_bible_icon'),
                tooltip: 'tooltips.bible'.tr(),
                onPressed: () async {
                  getService<AnalyticsService>()
                      .logBottomBarAction(action: 'bible');
                  await BubbleUtils.markAsShown(
                    BubbleUtils.getIconBubbleId(
                      Icons.auto_stories_outlined,
                      'new',
                    ),
                  );
                  _goToBible();
                },
                icon: const Icon(
                  Icons.auto_stories_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              IconButton(
                key: const Key('bottom_appbar_share_icon'),
                tooltip: 'devotionals.share_devotional'.tr(),
                onPressed: () {
                  getService<AnalyticsService>()
                      .logBottomBarAction(action: 'share');
                  _shareAsText(currentDevocional);
                },
                icon: Icon(
                  Icons.share_outlined,
                  color: colorScheme.onPrimary,
                  size: 30,
                ),
              ),
              IconButton(
                key: const Key('bottom_appbar_progress_icon'),
                tooltip: 'tooltips.progress'.tr(),
                onPressed: () {
                  getService<AnalyticsService>()
                      .logBottomBarAction(action: 'progress');
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const ProgressPage(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      transitionDuration: const Duration(milliseconds: 250),
                    ),
                  );
                },
                icon: Icon(
                  Icons.emoji_events_outlined,
                  color: colorScheme.onPrimary,
                  size: 30,
                ),
              ),
              IconButton(
                key: const Key('bottom_appbar_settings_icon'),
                tooltip: 'tooltips.settings'.tr(),
                onPressed: () async {
                  debugPrint('🔥 [BottomBar] Tap: settings');
                  getService<AnalyticsService>()
                      .logBottomBarAction(action: 'settings');
                  await BubbleUtils.markAsShown(
                    BubbleUtils.getIconBubbleId(
                      Icons.app_settings_alt_outlined,
                      'new',
                    ),
                  );
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const SettingsPage(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      transitionDuration: const Duration(milliseconds: 250),
                    ),
                  );
                },
                icon: Icon(
                  Icons.app_settings_alt_outlined,
                  color: colorScheme.onPrimary,
                  size: 30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build UI using Legacy Provider pattern (when feature flag is false)
  Widget _buildLegacy(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;

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
              icon:
                  const Icon(Icons.text_increase_outlined, color: Colors.white),
              tooltip: 'bible.adjust_font_size'.tr(),
              onPressed: _toggleFontControls,
            ),
          ],
        ),
        floatingActionButton: AnimatedFabWithText(
          onPressed: _showAddPrayerOrThanksgivingChoice,
          text: 'prayer.add_prayer_thanksgiving_hint'.tr(),
          fabColor: colorScheme.primary, // Color del círculo con el +
          backgroundColor: colorScheme.secondary, // Color del fondo del texto
          textColor: colorScheme.onPrimaryContainer, // Color del texto
          iconColor: colorScheme.onPrimary, // Color del icono +
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: Stack(
          children: [
            Consumer<DevocionalProvider>(
              builder: (context, devocionalProvider, child) {
                final List<Devocional> devocionales =
                    devocionalProvider.devocionales;

                if (devocionales.isEmpty) {
                  return Center(
                    child: Text(
                      'devotionals.no_devotionals_available'.tr(),
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  );
                }

                if (_currentDevocionalIndex >= devocionales.length ||
                    _currentDevocionalIndex < 0) {
                  _currentDevocionalIndex = 0;
                }

                final Devocional currentDevocional =
                    devocionales[_currentDevocionalIndex];

                return Column(
                  children: [
                    Expanded(
                      child: Screenshot(
                        controller: screenshotController,
                        child: Container(
                          color: Theme.of(context).scaffoldBackgroundColor,
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
                                final messenger = ScaffoldMessenger.of(context);
                                final ColorScheme colorScheme =
                                    Theme.of(context).colorScheme;
                                messenger.showSnackBar(
                                  SnackBar(
                                    backgroundColor: colorScheme.secondary,
                                    duration: const Duration(seconds: 2),
                                    content: Text(
                                      'share.copied_to_clipboard'.tr(),
                                      style: TextStyle(
                                          color: colorScheme.onSecondary),
                                    ),
                                  ),
                                );
                              } catch (e) {
                                debugPrint(
                                    '[DevocionalesPage] Error copying verse to clipboard: $e');
                              }
                            },
                            onStreakBadgeTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const ProgressPage()),
                              );
                            },
                            currentStreak: _currentStreak,
                            streakFuture: _streakFuture,
                            getLocalizedDateFormat: (context) =>
                                _getLocalizedDateFormat(context)
                                    .format(DateTime.now()),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            if (_showFontControls)
              FloatingFontControlButtons(
                currentFontSize: _fontSize,
                onIncrease: _increaseFontSize,
                onDecrease: _decreaseFontSize,
                onClose: () => setState(() => _showFontControls = false),
              ),
            if (_showPostSplashAnimation)
              Positioned(
                top: MediaQuery.of(context).padding.top + kToolbarHeight,
                right: 0,
                child: IgnorePointer(
                  child: Lottie.asset(
                    _selectedLottieAsset ?? 'assets/lottie/happy_bird.json',
                    width: 200,
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: Consumer<DevocionalProvider>(
          builder: (context, devocionalProvider, child) {
            final List<Devocional> devocionales =
                devocionalProvider.devocionales;
            final Devocional? currentDevocional = getCurrentDevocional(
              devocionales,
            );
            final bool isFavorite = currentDevocional != null
                ? devocionalProvider.isFavorite(currentDevocional)
                : false;

            final Color? appBarBackgroundColor = Theme.of(
              context,
            ).appBarTheme.backgroundColor;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: const BoxDecoration(color: Colors.transparent),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Column(
                    children: [
                      Consumer<AudioController>(
                        builder: (context, audioController, _) {
                          final progress = audioController.progress;
                          // Eliminados chunkIndex y totalChunks
                          return LinearProgressIndicator(
                            value: progress,
                            minHeight: 6, // Changed from 4
                            backgroundColor: Colors.grey[300],
                            color: colorScheme.primary,
                            // If supported, add borderRadius
                          );
                        },
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 45,
                              child: OutlinedButton.icon(
                                key: const Key('bottom_nav_previous_button'),
                                onPressed: _currentDevocionalIndex > 0
                                    ? _goToPreviousDevocional
                                    : null,
                                icon: Icon(
                                  Icons.arrow_back_ios,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                                label: Text(
                                  'devotionals.previous'.tr(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: colorScheme.primary,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  foregroundColor: colorScheme.primary,
                                  overlayColor: colorScheme.primary.withAlpha(
                                      (0.1 * 255).round()), // Added feedback
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: currentDevocional != null
                                  ? Builder(
                                      builder: (context) {
                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Original TtsPlayerWidget (unchanged)
                                            TtsPlayerWidget(
                                              key: const Key(
                                                'bottom_nav_tts_player',
                                              ),
                                              devocional: currentDevocional,
                                              audioController:
                                                  _ttsAudioController,
                                              onCompleted: () {
                                                final provider = Provider.of<
                                                        DevocionalProvider>(
                                                    context,
                                                    listen: false);
                                                if (provider
                                                    .showInvitationDialog) {
                                                  _showInvitation(context);
                                                }
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    )
                                  : const SizedBox(width: 56, height: 56),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 45,
                              child: OutlinedButton(
                                key: const Key('bottom_nav_next_button'),
                                onPressed: _currentDevocionalIndex <
                                        devocionales.length - 1
                                    ? _goToNextDevocional
                                    : null,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: colorScheme.primary,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  foregroundColor: colorScheme.primary,
                                  overlayColor: colorScheme.primary.withAlpha(
                                      (0.1 * 255).round()), // Added feedback
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'devotionals.next'.tr(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: BottomAppBar(
                    height: 60,
                    color: appBarBackgroundColor,
                    padding: EdgeInsets.zero,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(
                            key: const Key('bottom_appbar_favorite_icon'),
                            tooltip: isFavorite
                                ? 'devotionals.remove_from_favorites_short'.tr()
                                : 'devotionals.save_as_favorite'.tr(),
                            onPressed: () {
                              debugPrint('🔥 [BottomBar] Tap: favorite');
                              getService<AnalyticsService>()
                                  .logBottomBarAction(action: 'favorite');
                              devocionalProvider.toggleFavorite(
                                currentDevocional!,
                                context,
                              );
                            },
                            icon: Icon(
                              isFavorite ? Icons.star : Icons.favorite_border,
                              color: isFavorite ? Colors.amber : Colors.white,
                              size: 32,
                            ),
                          ),
                          IconButton(
                            key: const Key('bottom_appbar_prayers_icon'),
                            tooltip: 'tooltips.my_prayers'.tr(),
                            onPressed: () async {
                              debugPrint('🔥 [BottomBar] Tap: prayers');
                              getService<AnalyticsService>()
                                  .logBottomBarAction(action: 'prayers');
                              HapticFeedback.mediumImpact();
                              await BubbleUtils.markAsShown(
                                BubbleUtils.getIconBubbleId(
                                  Icons.local_fire_department_outlined,
                                  'new',
                                ),
                              );
                              _goToPrayers();
                            },
                            icon: const Icon(
                              Icons.local_fire_department_outlined,
                              color: Colors.white,
                              size: 35,
                            ),
                          ),
                          IconButton(
                            key: const Key('bottom_appbar_bible_icon'),
                            tooltip: 'tooltips.bible'.tr(),
                            onPressed: () async {
                              debugPrint('🔥 [BottomBar] Tap: bible');
                              getService<AnalyticsService>()
                                  .logBottomBarAction(action: 'bible');
                              await BubbleUtils.markAsShown(
                                BubbleUtils.getIconBubbleId(
                                  Icons.auto_stories_outlined,
                                  'new',
                                ),
                              );
                              _goToBible();
                            },
                            icon: const Icon(
                              Icons.auto_stories_outlined,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          IconButton(
                            key: const Key('bottom_appbar_share_icon'),
                            tooltip: 'devotionals.share_devotional'.tr(),
                            onPressed: () {
                              debugPrint('🔥 [BottomBar] Tap: share');
                              getService<AnalyticsService>()
                                  .logBottomBarAction(action: 'share');
                              _shareAsText(currentDevocional!);
                            },
                            icon: Icon(
                              Icons.share_outlined,
                              color: colorScheme.onPrimary,
                              size: 30,
                            ),
                          ),
                          IconButton(
                            key: const Key('bottom_appbar_progress_icon'),
                            tooltip: 'tooltips.progress'.tr(),
                            onPressed: () {
                              debugPrint('🔥 [BottomBar] Tap: progress');
                              getService<AnalyticsService>()
                                  .logBottomBarAction(action: 'progress');
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      const ProgressPage(),
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    return FadeTransition(
                                        opacity: animation, child: child);
                                  },
                                  transitionDuration:
                                      const Duration(milliseconds: 250),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.emoji_events_outlined,
                              color: colorScheme.onPrimary,
                              size: 30,
                            ),
                          ),
                          IconButton(
                            key: const Key('bottom_appbar_settings_icon'),
                            tooltip: 'tooltips.settings'.tr(),
                            onPressed: () async {
                              debugPrint('🔥 [BottomBar] Tap: settings');
                              getService<AnalyticsService>()
                                  .logBottomBarAction(action: 'settings');
                              await BubbleUtils.markAsShown(
                                BubbleUtils.getIconBubbleId(
                                  Icons.app_settings_alt_outlined,
                                  'new',
                                ),
                              );
                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      const SettingsPage(),
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    return FadeTransition(
                                        opacity: animation, child: child);
                                  },
                                  transitionDuration:
                                      const Duration(milliseconds: 250),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.app_settings_alt_outlined,
                              color: colorScheme.onPrimary,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _handleTtsStateChange() {
    try {
      final s = _ttsAudioController.state.value;

      // Show modal when playback starts
      if (s == TtsPlayerState.playing && mounted && !_isTtsModalShowing) {
        // Check if modal is not already showing to avoid duplicates
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _isTtsModalShowing) return;
          _showTtsModal();
        });
      }

      if (s == TtsPlayerState.completed || s == TtsPlayerState.idle) {
        // Mark modal as not showing when audio stops
        _isTtsModalShowing = false;
      }
    } catch (e) {
      debugPrint('[DevocionalesPage] Error en _handleTtsStateChange: $e');
    }
  }

  void _showTtsModal() {
    // Prevent showing multiple modals
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
            // Auto-close modal when not playing/paused
            if (state == TtsPlayerState.idle ||
                state == TtsPlayerState.completed) {
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
                              // Track TTS play button press with Firebase Analytics
                              try {
                                getService<AnalyticsService>().logTtsPlay();
                              } catch (e) {
                                debugPrint(
                                    '❌ Error logging TTS play analytics: $e');
                                // Fail silently - analytics should not block functionality
                              }
                              _ttsAudioController.play();
                            }
                          },
                          onCycleRate: () async {
                            // CRITICAL: Pause before changing speed to avoid playback issues
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
                            // Capture context-dependent values BEFORE async gap
                            final languageCode =
                                Localizations.localeOf(context).languageCode;
                            final currentDevocional =
                                Provider.of<DevocionalProvider>(context,
                                        listen: false)
                                    .devocionales[_currentDevocionalIndex];
                            final sampleText = _buildTtsTextForDevocional(
                              currentDevocional,
                              languageCode,
                            );

                            // CRITICAL: Pause before opening voice selector to avoid playback issues
                            if (state == TtsPlayerState.playing) {
                              await _ttsAudioController.pause();
                            }

                            // Safe to use ctx here: ctx is from the outer builder scope (line 1514),
                            // not the widget context. Builder-provided contexts remain valid across
                            // async gaps within their scope, unlike widget contexts.
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
                                    bottom: MediaQuery.of(voiceCtx)
                                        .viewInsets
                                        .bottom,
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
