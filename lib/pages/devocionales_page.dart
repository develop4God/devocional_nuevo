import 'dart:developer' as developer;
import 'dart:io' show File;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/pages/my_badges_page.dart';
import 'package:devocional_nuevo/pages/prayers_page.dart';
import 'package:devocional_nuevo/pages/progress_page.dart';
import 'package:devocional_nuevo/pages/settings_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/devocionales_tracking.dart';
import 'package:devocional_nuevo/services/update_service.dart';
import 'package:devocional_nuevo/utils/bubble_constants.dart';
import 'package:devocional_nuevo/utils/copyright_utils.dart';
import 'package:devocional_nuevo/widgets/add_prayer_modal.dart';
import 'package:devocional_nuevo/widgets/app_bar_constants.dart'
    show CustomAppBar;
import 'package:devocional_nuevo/widgets/app_bar_constants.dart';
import 'package:devocional_nuevo/widgets/devocionales_page_drawer.dart';
import 'package:devocional_nuevo/widgets/tts_player_widget.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/audio_controller.dart';
import '../services/spiritual_stats_service.dart';

class DevocionalesPage extends StatefulWidget {
  final String? initialDevocionalId;

  const DevocionalesPage({super.key, this.initialDevocionalId});

  @override
  State<DevocionalesPage> createState() => _DevocionalesPageState();
}

class _DevocionalesPageState extends State<DevocionalesPage>
    with WidgetsBindingObserver {
  final ScreenshotController screenshotController = ScreenshotController();
  final ScrollController _scrollController = ScrollController();
  int _currentDevocionalIndex = 0;
  static const String _lastDevocionalIndexKey = 'lastDevocionalIndex';
  final DevocionalesTracking _tracking = DevocionalesTracking();
  final FlutterTts _flutterTts = FlutterTts();

  AudioController? _audioController;
  bool _showBadgesTab = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _audioController = Provider.of<AudioController>(context, listen: false);
      _tracking.initialize(context);
      _tracking.startCriteriaCheckTimer();
    });

    _loadInitialData();
    _loadFeatureFlags();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate();
    });
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
  void dispose() {
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

        final prefs = await SharedPreferences.getInstance();
        final int? savedIndex = prefs.getInt(_lastDevocionalIndexKey);

        if (mounted) {
          setState(() {
            if (savedIndex != null) {
              _currentDevocionalIndex =
                  (savedIndex + 1) % devocionalProvider.devocionales.length;
              developer.log(
                'Devocional cargado al inicio (índice siguiente): $_currentDevocionalIndex',
              );
            } else {
              _currentDevocionalIndex = 0;
              developer.log(
                'No hay índice guardado. Iniciando en el primer devocional (índice 0).',
              );
            }
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

  Future<void> _loadFeatureFlags() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? const Duration(seconds: 0)
              : const Duration(minutes: 5),
        ),
      );

      await remoteConfig.setDefaults({'show_badges_tab': false});
      await remoteConfig.fetchAndActivate();

      if (mounted) {
        setState(() {
          _showBadgesTab = remoteConfig.getBool('show_badges_tab');
        });
      }

      developer.log('Badges tab flag loaded: $_showBadgesTab');
    } catch (e) {
      developer.log('Failed to load badges flag: $e, keeping default false');
    }
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
        return DateFormat('EEEE, d \'de\' MMMM', 'es');
      case 'en':
        return DateFormat('EEEE, MMMM d', 'en');
      case 'fr':
        return DateFormat('EEEE d MMMM', 'fr');
      case 'pt':
        return DateFormat('EEEE, d \'de\' MMMM', 'pt');
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
    final shareMessage = "drawer.share_message".tr();

    final text =
        '$devotionalText\n\n$shareMessage'; // Use interpolation instead of '+'

    await SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _shareAsImage(Devocional devocional) async {
    final image = await screenshotController.capture();
    if (image != null) {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = await File('${directory.path}/devocional.png').create();
      await imagePath.writeAsBytes(image);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(imagePath.path)],
          text: 'devotionals.devotional_of_the_day'.tr(),
          subject: 'devotionals.app_title'.tr(),
        ),
      );
    }
  }

  void _showShareOptions(Devocional devocional) {
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
                'devotionals.share_devotional'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _shareAsText(devocional);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.text_fields,
                              size: 32,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'tooltips.share_as_text'.tr(),
                              style: Theme.of(context).textTheme.bodyMedium,
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
                        _shareAsImage(devocional);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.image,
                              size: 32,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'tooltips.share_as_image'.tr(),
                              style: Theme.of(context).textTheme.bodyMedium,
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

  void _goToPrayers() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrayersPage()),
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

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      drawer: const DevocionalesDrawer(),
      appBar: CustomAppBar(
        titleText: 'devotionals.my_intimate_space_with_god'.tr(),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _showAddPrayerModal,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        tooltip: 'tooltips.add_prayer'.tr(),
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Consumer<DevocionalProvider>(
        builder: (context, devocionalProvider, child) {
          final List<Devocional> devocionales = devocionalProvider.devocionales;

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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _getLocalizedDateFormat(context).format(DateTime.now()),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
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
                              fontSize: 16,
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
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: item.texto,
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontSize: 16,
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
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (currentDevocional.version != null ||
                              currentDevocional.language != null ||
                              currentDevocional.tags != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                      'topics': currentDevocional.tags!.join(
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
                                      'version': currentDevocional.version,
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
                                      builder: (context, provider, child) {
                                        return Text(
                                          CopyrightUtils.getCopyrightText(
                                            provider.selectedLanguage,
                                            provider.selectedVersion,
                                          ),
                                          style: textTheme.bodySmall?.copyWith(
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
      bottomNavigationBar: Consumer<DevocionalProvider>(
        builder: (context, devocionalProvider, child) {
          final List<Devocional> devocionales = devocionalProvider.devocionales;
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
                        final chunkIndex = audioController.currentChunkIndex;
                        final totalChunks = audioController.totalChunks;

                        return Column(
                          children: [
                            LinearProgressIndicator(
                              value: progress,
                              minHeight: 4,
                              backgroundColor: Colors.grey[300],
                              color: colorScheme.primary,
                            ),
                            if (chunkIndex != null && totalChunks != null)
                              const Padding(padding: EdgeInsets.only(top: 2)),
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
                            child: ElevatedButton.icon(
                              onPressed: _currentDevocionalIndex > 0
                                  ? _goToPreviousDevocional
                                  : null,
                              icon: const Icon(Icons.arrow_back_ios, size: 16),
                              label: Text(
                                'devotionals.previous'.tr(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _currentDevocionalIndex > 0
                                    ? colorScheme.primary
                                    : colorScheme.outline.withValues(
                                        alpha: 0.3,
                                      ),
                                foregroundColor: _currentDevocionalIndex > 0
                                    ? Colors.white
                                    : colorScheme.outline,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                elevation: _currentDevocionalIndex > 0 ? 2 : 0,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: currentDevocional != null
                                ? TtsPlayerWidget(devocional: currentDevocional)
                                : const SizedBox(width: 56, height: 56),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 45,
                            child: ElevatedButton.icon(
                              onPressed: _currentDevocionalIndex <
                                      devocionales.length - 1
                                  ? _goToNextDevocional
                                  : null,
                              label: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                              icon: Text(
                                'devotionals.next'.tr(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _currentDevocionalIndex <
                                        devocionales.length - 1
                                    ? colorScheme.primary
                                    : colorScheme.outline.withValues(
                                        alpha: 0.3,
                                      ),
                                foregroundColor: _currentDevocionalIndex <
                                        devocionales.length - 1
                                    ? Colors.white
                                    : colorScheme.outline,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                elevation: _currentDevocionalIndex <
                                        devocionales.length - 1
                                    ? 2
                                    : 0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              BottomAppBar(
                height: 70,
                color: appBarBackgroundColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
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
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.white,
                        size: 32,
                      ),
                    ),
                    IconButton(
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
                      tooltip: 'devotionals.share_devotional'.tr(),
                      onPressed: currentDevocional != null
                          ? () => _showShareOptions(currentDevocional)
                          : null,
                      icon: Icon(
                        Icons.share_outlined,
                        color: appBarForegroundColor,
                        size: 30,
                      ),
                    ),
                    if (_showBadgesTab)
                      IconButton(
                        tooltip: 'donate.my_badges'.tr(),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyBadgesPage(),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.military_tech_outlined,
                          color: appBarForegroundColor,
                          size: 30,
                        ),
                      ),
                    IconButton(
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
            ],
          );
        },
      ),
    );
  }
}
