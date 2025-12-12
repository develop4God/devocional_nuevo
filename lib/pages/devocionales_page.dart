import 'dart:developer' as developer;
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:bible_reader_core/bible_reader_core.dart';
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
import 'package:devocional_nuevo/services/devocionales_tracking.dart';
import 'package:devocional_nuevo/services/update_service.dart';
import 'package:devocional_nuevo/utils/bubble_constants.dart';
import 'package:devocional_nuevo/utils/copyright_utils.dart';
import 'package:devocional_nuevo/widgets/add_prayer_modal.dart';
import 'package:devocional_nuevo/widgets/add_thanksgiving_modal.dart';
import 'package:devocional_nuevo/widgets/app_bar_constants.dart'
    show CustomAppBar;
import 'package:devocional_nuevo/widgets/app_bar_constants.dart';
import 'package:devocional_nuevo/widgets/devocionales_page_drawer.dart';
import 'package:devocional_nuevo/widgets/floating_font_control_buttons.dart';
import 'package:devocional_nuevo/widgets/tts_miniplayer_widget.dart';
import 'package:devocional_nuevo/widgets/tts_player_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart'; // Re-agregado para animación post-splash
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/audio_controller.dart';
import '../controllers/tts_audio_controller.dart';
import '../services/spiritual_stats_service.dart';
import '../services/tts/bible_text_formatter.dart';
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
  int _currentDevocionalIndex = 0;
  static const String _lastDevocionalIndexKey = 'lastDevocionalIndex';
  final DevocionalesTracking _tracking = DevocionalesTracking();
  final FlutterTts _flutterTts = FlutterTts();
  late final TtsAudioController _ttsAudioController;
  AudioController? _audioController;
  bool _routeSubscribed = false;
  int _currentStreak = 0;
  late Future<int> _streakFuture;

  // Font control variables
  bool _showFontControls = false;
  double _fontSize = 16.0;

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
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _audioController = Provider.of<AudioController>(context, listen: false);
      _tracking.initialize(context);
      _precacheLottieAnimations();
    });
    _loadFontSize();
    _loadInitialData();
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
            '🔄 [DEBUG] Global RouteObserver subscribed for DevocionalesPage');
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
    final route = ModalRoute.of(context);
    if (_routeSubscribed && route is PageRoute) {
      routeObserver.unsubscribe(this);
      debugPrint(
          '🗑️ [DEBUG] Global RouteObserver unsubscribed for DevocionalesPage');
      _routeSubscribed = false;
    }
    _tracking.dispose();
    _stopSpeaking();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() {});
  }

  Future<void> _loadInitialData() async {
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
            _currentDevocionalIndex = _findFirstUnreadDevocionalIndex(
              devocionalProvider.devocionales,
              readDevocionalIds,
            );
            developer.log(
              'Devocional cargado al inicio (primer no leído): $_currentDevocionalIndex',
            );
          });
          _startTrackingCurrentDevocional();
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
            _startTrackingCurrentDevocional();
          }
        }
      }
    });
  }

  /// Find the first unread devotional index starting from the beginning
  int _findFirstUnreadDevocionalIndex(
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

  void _startTrackingCurrentDevocional() {
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
        _startTrackingCurrentDevocional();
      });

      HapticFeedback.lightImpact();

      if (devocionalProvider.showInvitationDialog) {
        if (mounted) {
          _showInvitation(context);
        }
      }

      _saveCurrentDevocionalIndex();
    }
  }

  void _goToPreviousDevocional() async {
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
        _startTrackingCurrentDevocional();
      });

      HapticFeedback.lightImpact();
    }
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuart,
        );
      }
    });
  }

  Future<void> _saveCurrentDevocionalIndex() async {
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

  Widget _buildStreakBadge(bool isDark, int streak) {
    final textColor = isDark ? Colors.black87 : Colors.white;
    final backgroundColor = isDark ? Colors.white24 : Colors.black12;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: SizedBox(
              width: 28,
              height: 28,
              child: Lottie.asset(
                'assets/lottie/fire.json',
                repeat: true,
                animate: true,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${'progress.streak'.tr()} $streak',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
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
      MaterialPageRoute(builder: (context) => const PrayersPage()),
    );
  }

  void _goToBible() async {
    final devocionalProvider =
        Provider.of<DevocionalProvider>(context, listen: false);
    final appLanguage = devocionalProvider.selectedLanguage;

    debugPrint('🟦 [Bible] Using app language instead of device: $appLanguage');

    List<BibleVersion> versions =
        await BibleVersionRegistry.getVersionsForLanguage(appLanguage);

    debugPrint(
        '🟩 [Bible] Versions for app language ($appLanguage): ${versions.map((v) => '${v.name} (${v.languageCode}) - downloaded: ${v.isDownloaded}').join(', ')}');

    if (versions.isEmpty) {
      versions = await BibleVersionRegistry.getVersionsForLanguage('es');
    }

    if (versions.isEmpty) {
      versions = await BibleVersionRegistry.getAllVersions();
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BibleReaderPage(
          versions: versions,
        ),
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
                          border: Border.all(
                            color: colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '🙏',
                              style: TextStyle(fontSize: 48),
                            ),
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
                          border: Border.all(
                            color: colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '☺️',
                              style: TextStyle(fontSize: 48),
                            ),
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
    ttsBuffer.write(BibleTextFormatter.normalizeTtsText(
        devocional.versiculo, language, devocional.version));
    ttsBuffer.write('\n$reflectionLabel: ');
    ttsBuffer.write(BibleTextFormatter.normalizeTtsText(
        devocional.reflexion, language, devocional.version));
    if (devocional.paraMeditar.isNotEmpty) {
      ttsBuffer.write('\n$meditateLabel: ');
      ttsBuffer.write(devocional.paraMeditar.map((m) {
        return '${BibleTextFormatter.normalizeTtsText(m.cita, language, devocional.version)}: ${m.texto}';
      }).join('\n'));
    }
    ttsBuffer.write('\n$prayerLabel: ');
    ttsBuffer.write(BibleTextFormatter.normalizeTtsText(
        devocional.oracion, language, devocional.version));
    return ttsBuffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeState.systemUiOverlayStyle,
      child: Scaffold(
        drawer: const DevocionalesDrawer(),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Stack(
            children: [
              CustomAppBar(
                titleText: 'devotionals.my_intimate_space_with_god'.tr(),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: SafeArea(
                  child: IconButton(
                    icon: const Icon(
                      Icons.text_increase_outlined,
                      color: Colors.white,
                    ),
                    tooltip: 'bible.adjust_font_size'.tr(),
                    onPressed: _toggleFontControls,
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.small(
          onPressed: _showAddPrayerOrThanksgivingChoice,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          tooltip: 'tooltips.add_prayer_or_thanksgiving'.tr(),
          child: const Icon(Icons.add, size: 30),
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
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            _getLocalizedDateFormat(context)
                                                .format(DateTime.now()),
                                            style:
                                                textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      FutureBuilder<int>(
                                        future: _streakFuture,
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const SizedBox(
                                              width: 40,
                                              height: 40,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            );
                                          }
                                          final streak =
                                              snapshot.data ?? _currentStreak;
                                          if (streak <= 0) {
                                            return const SizedBox.shrink();
                                          }
                                          final isDark =
                                              Theme.of(context).brightness ==
                                                  Brightness.dark;
                                          return _buildStreakBadge(
                                              isDark, streak);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withAlpha(
                                      (0.1 * 255).round(),
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: colorScheme.primary.withAlpha(
                                        (0.3 * 255).round(),
                                      ),
                                    ),
                                  ),
                                  child: AutoSizeText(
                                    currentDevocional.versiculo,
                                    textAlign: TextAlign.center,
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 12,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'devotionals.reflection'.tr(),
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  currentDevocional.reflexion,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontSize: _fontSize,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'devotionals.to_meditate'.tr(),
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...currentDevocional.paraMeditar.map((item) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '${item.cita}: ',
                                            style:
                                                textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: _fontSize,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                          TextSpan(
                                            text: item.texto,
                                            style:
                                                textTheme.bodyMedium?.copyWith(
                                              fontSize: _fontSize,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(height: 20),
                                Text(
                                  'devotionals.prayer'.tr(),
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  currentDevocional.oracion,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontSize: _fontSize,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                if (currentDevocional.version != null ||
                                    currentDevocional.language != null ||
                                    currentDevocional.tags != null)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'devotionals.details'.tr(),
                                        style: textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      if (currentDevocional.tags != null &&
                                          currentDevocional.tags!.isNotEmpty)
                                        Text(
                                          'devotionals.topics'.tr({
                                            'topics':
                                                currentDevocional.tags!.join(
                                              ', ',
                                            ),
                                          }),
                                          style: textTheme.bodySmall?.copyWith(
                                            fontSize: 14,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      if (currentDevocional.version != null)
                                        Text(
                                          'devotionals.version'.tr({
                                            'version':
                                                currentDevocional.version,
                                          }),
                                          style: textTheme.bodySmall?.copyWith(
                                            fontSize: 14,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      const SizedBox(height: 10),
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                          ),
                                          child: Consumer<DevocionalProvider>(
                                            builder:
                                                (context, provider, child) {
                                              return Text(
                                                CopyrightUtils.getCopyrightText(
                                                  provider.selectedLanguage,
                                                  provider.selectedVersion,
                                                ),
                                                style: textTheme.bodySmall
                                                    ?.copyWith(
                                                  fontSize: 12,
                                                  color: colorScheme.onSurface
                                                      .withValues(alpha: 0.7),
                                                ),
                                                textAlign: TextAlign.center,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                              ],
                            ),
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

            final Color appBarForegroundColor =
                Theme.of(context).appBarTheme.foregroundColor ??
                    colorScheme.onPrimary;
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
                          return Column(
                            children: [
                              LinearProgressIndicator(
                                value: progress,
                                minHeight: 4,
                                backgroundColor: Colors.grey[300],
                                color: colorScheme.primary,
                              ),
                              // TtsMiniplayer integrado en el bottom area
                              ValueListenableBuilder<TtsPlayerState>(
                                valueListenable: _ttsAudioController.state,
                                builder: (context, state, _) {
                                  if (state == TtsPlayerState.idle)
                                    return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: ValueListenableBuilder<Duration>(
                                      valueListenable:
                                          _ttsAudioController.currentPosition,
                                      builder: (context, currentPos, __) {
                                        return ValueListenableBuilder<Duration>(
                                          valueListenable:
                                              _ttsAudioController.totalDuration,
                                          builder: (context, totalDur, ___) {
                                            return ValueListenableBuilder<
                                                double>(
                                              valueListenable:
                                                  _ttsAudioController
                                                      .playbackRate,
                                              builder: (context, rate, ____) {
                                                return TtsMiniplayerWidget(
                                                  currentPosition: currentPos,
                                                  totalDuration: totalDur,
                                                  isPlaying: state ==
                                                      TtsPlayerState.playing,
                                                  playbackRate: rate,
                                                  playbackRates:
                                                      _ttsAudioController
                                                          .supportedRates,
                                                  onStop: () =>
                                                      _ttsAudioController
                                                          .stop(),
                                                  onSeekStart: () {},
                                                  onSeek: (d) =>
                                                      _ttsAudioController
                                                          .seek(d),
                                                  onTogglePlay: () {
                                                    if (state ==
                                                        TtsPlayerState
                                                            .playing) {
                                                      _ttsAudioController
                                                          .pause();
                                                    } else {
                                                      _ttsAudioController
                                                          .play();
                                                    }
                                                  },
                                                  onCycleRate: () async {
                                                    // Delegate cycling to the TTS controller so it
                                                    // handles persistence and engine updates.
                                                    try {
                                                      await _ttsAudioController
                                                          .cyclePlaybackRate();
                                                    } catch (e) {
                                                      debugPrint(
                                                          '[DevocionalesPage] cyclePlaybackRate failed: $e');
                                                    }
                                                  },
                                                  onRateChanged:
                                                      (newRate) async {
                                                    // Reiniciar audio y recalcular duración
                                                    await _ttsAudioController
                                                        .stop();
                                                    await _ttsAudioController
                                                        .flutterTts
                                                        .setSpeechRate(newRate);
                                                    _ttsAudioController
                                                        .playbackRate
                                                        .value = newRate;
                                                    await _ttsAudioController
                                                        .play();
                                                  },
                                                  onVoiceSelector: () async {
                                                    await showModalBottomSheet(
                                                      context: context,
                                                      isScrollControlled: true,
                                                      shape:
                                                          const RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.vertical(
                                                                top: Radius
                                                                    .circular(
                                                                        28)),
                                                      ),
                                                      builder: (ctx) =>
                                                          FractionallySizedBox(
                                                        heightFactor: 0.8,
                                                        child: Padding(
                                                          padding: EdgeInsets.only(
                                                              bottom: MediaQuery
                                                                      .of(ctx)
                                                                  .viewInsets
                                                                  .bottom),
                                                          child:
                                                              VoiceSelectorDialog(
                                                            language: Localizations
                                                                    .localeOf(
                                                                        context)
                                                                .languageCode,
                                                            sampleText: _buildTtsTextForDevocional(
                                                                currentDevocional!,
                                                                Localizations
                                                                        .localeOf(
                                                                            context)
                                                                    .languageCode),
                                                            onVoiceSelected: (name,
                                                                locale) async {},
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
                                    ),
                                  );
                                },
                              ),
                            ],
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
                                icon: Icon(Icons.arrow_back_ios,
                                    size: 16, color: colorScheme.primary),
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
                                      color: colorScheme.primary, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  foregroundColor: colorScheme.primary,
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
                                                  'bottom_nav_tts_player'),
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
                                      color: colorScheme.primary, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  foregroundColor: colorScheme.primary,
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
                                    Icon(Icons.arrow_forward_ios,
                                        size: 16, color: colorScheme.primary),
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
                            onPressed: currentDevocional != null
                                ? () => devocionalProvider.toggleFavorite(
                                      currentDevocional,
                                      context,
                                    )
                                : null,
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
                              )),
                          IconButton(
                            key: const Key('bottom_appbar_bible_icon'),
                            tooltip: 'tooltips.bible'.tr(),
                            onPressed: () async {
                              await BubbleUtils.markAsShown(
                                  BubbleUtils.getIconBubbleId(
                                      Icons.auto_stories_outlined, 'new'));
                              _goToBible();
                            },
                            icon: const Icon(
                              Icons.auto_stories_outlined,
                              color: Colors.white,
                              size: 32,
                            ).newIconBadge,
                          ),
                          IconButton(
                            key: const Key('bottom_appbar_share_icon'),
                            tooltip: 'devotionals.share_devotional'.tr(),
                            onPressed: currentDevocional != null
                                ? () => _shareAsText(currentDevocional)
                                : null,
                            icon: Icon(
                              Icons.share_outlined,
                              color: appBarForegroundColor,
                              size: 30,
                            ),
                          ),
                          IconButton(
                            key: const Key('bottom_appbar_progress_icon'),
                            tooltip: 'tooltips.progress'.tr(),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProgressPage(),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.emoji_events_outlined,
                              color: appBarForegroundColor,
                              size: 30,
                            ),
                          ),
                          IconButton(
                            key: const Key('bottom_appbar_settings_icon'),
                            tooltip: 'tooltips.settings'.tr(),
                            onPressed: () async {
                              await BubbleUtils.markAsShown(
                                BubbleUtils.getIconBubbleId(
                                  Icons.app_settings_alt_outlined,
                                  'new',
                                ),
                              );
                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsPage(),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.app_settings_alt_outlined,
                              color: appBarForegroundColor,
                              size: 30,
                            ).newIconBadge,
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
}
