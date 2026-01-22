import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_event.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/providers/localization_provider.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:devocional_nuevo/widgets/devocionales/app_bar_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApplicationLanguagePage extends StatefulWidget {
  const ApplicationLanguagePage({super.key});

  @override
  State<ApplicationLanguagePage> createState() =>
      _ApplicationLanguagePageState();
}

class _ApplicationLanguagePageState extends State<ApplicationLanguagePage> {
  final Map<String, bool> _downloadStatus = {};
  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _isDownloading = {};
  String? _currentLanguage;

  @override
  void initState() {
    super.initState();
    _loadDownloadStatus();
  }

  Future<void> _loadDownloadStatus() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    final localizationProvider = Provider.of<LocalizationProvider>(
      context,
      listen: false,
    );
    _currentLanguage = localizationProvider.currentLocale.languageCode;

    setState(() {
      for (final languageCode in Constants.supportedLanguages.keys) {
        // Check if language is downloaded by checking for local files
        bool isDownloaded = false;
        if (languageCode == 'es') {
          // Spanish is always considered "downloaded" as it's the base language
          isDownloaded = true;
        } else {
          // For other languages, check if we have actual local files
          isDownloaded =
              prefs.getBool('language_downloaded_$languageCode') ?? false;
        }

        _downloadStatus[languageCode] = isDownloaded;
        _downloadProgress[languageCode] = 0.0;
        _isDownloading[languageCode] = false;
      }
    });
  }

  Future<void> _downloadLanguage(String languageCode) async {
    if (_isDownloading[languageCode] == true) return;

    // If language is already downloaded and it's the current language, just navigate back
    if (_downloadStatus[languageCode] == true &&
        languageCode == _currentLanguage) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isDownloading[languageCode] = true;
      _downloadProgress[languageCode] = 0.0;
    });

    final devocionalProvider = Provider.of<DevocionalProvider>(
      context,
      listen: false,
    );
    final localizationProvider = Provider.of<LocalizationProvider>(
      context,
      listen: false,
    );

    try {
      // Simulate progress updates
      for (double progress = 0.1; progress <= 0.9; progress += 0.1) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          setState(() {
            _downloadProgress[languageCode] = progress;
          });
        }
      }

      // Change language in provider
      await localizationProvider.changeLanguage(languageCode);

      // Update DevocionalProvider with new language (pass context for UI locale update)
      if (mounted) {
        devocionalProvider.setSelectedLanguage(languageCode, context);

        // Update DiscoveryBloc with new language
        if (Constants.enableDiscoveryFeature) {
          context
              .read<DiscoveryBloc>()
              .add(RefreshDiscoveryStudies(languageCode: languageCode));
        }
      }

      // Set default version for the language
      final defaultVersion = Constants.defaultVersionByLanguage[languageCode];
      if (defaultVersion != null) {
        devocionalProvider.setSelectedVersion(defaultVersion);
      }

      // Cambiar el contexto de TTS al idioma y versión seleccionados
      devocionalProvider.audioController.ttsService.setLanguageContext(
        languageCode,
        defaultVersion ?? '',
      );
      // Usar el metodo getTtsLocale del provider de localización
      await devocionalProvider.audioController.ttsService.setLanguage(
        localizationProvider.getTtsLocale(),
      );

      // Download devotional content (only if not already downloaded or if it's not Spanish)
      bool downloadSuccess = true;
      if (!(_downloadStatus[languageCode] == true) || languageCode == 'es') {
        downloadSuccess =
            await devocionalProvider.downloadCurrentYearDevocionales();
      }

      if (downloadSuccess) {
        // Auto-assign best voice for the language
        await _assignBestVoiceForLanguage(languageCode, devocionalProvider);

        setState(() {
          _downloadProgress[languageCode] = 1.0;
          _downloadStatus[languageCode] = true;
          _currentLanguage = languageCode;
        });

        // Save download status
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('language_downloaded_$languageCode', true);

        // Wait a bit to show 100% progress
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          // Return to settings
          Navigator.pop(context);
        }
      } else {
        throw Exception('application_language.download_failed'.tr());
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading[languageCode] = false;
          if (_downloadStatus[languageCode] != true) {
            _downloadProgress[languageCode] = 0.0;
          }
        });
      }
    }
  }

  Future<void> _assignBestVoiceForLanguage(
    String languageCode,
    DevocionalProvider provider,
  ) async {
    try {
      debugPrint('🎵 Auto-assigning best voice for language: $languageCode');

      // Get available voices for this language
      final voices = await provider.getVoicesForLanguage(languageCode);
      debugPrint('🎵 Available voices for $languageCode: ${voices.length}');

      if (voices.isNotEmpty) {
        // Find the best voice: prioritize US locales, then female voices
        String? bestVoice;
        String? bestVoiceName;
        String? bestVoiceLocale;

        // Look for US voices first
        for (final voice in voices) {
          if (voice.contains('-US') || voice.contains('(en-US)')) {
            bestVoice = voice;
            break;
          }
        }

        // If no US voice found, look for female voices
        if (bestVoice == null) {
          for (final voice in voices) {
            final lowerVoice = voice.toLowerCase();
            if (lowerVoice.contains('female') ||
                lowerVoice.contains('♀') ||
                _isLikelyFemaleVoice(lowerVoice)) {
              bestVoice = voice;
              break;
            }
          }
        }

        // If still no voice found, just use the first one
        bestVoice ??= voices.first;

        // Parse voice name and locale
        if (bestVoice.contains(' (') && bestVoice.contains(')')) {
          final parts = bestVoice.split(' (');
          bestVoiceName = parts[0];
          final localeWithGender = parts[1].replaceAll(')', '');
          // Extract locale (remove gender info)
          final localeParts = localeWithGender.split(' ');
          bestVoiceLocale =
              localeParts.last; // Get the last part which should be locale
        } else {
          bestVoiceName = bestVoice;
          bestVoiceLocale = _getDefaultLocaleForLanguage(languageCode);
        }

        debugPrint(
          '🎵 Selected best voice: $bestVoiceName with locale: $bestVoiceLocale',
        );

        // Set the voice
        final voiceName = bestVoiceName;
        final voiceLocale = bestVoiceLocale;

        await provider.setTtsVoice({'name': voiceName, 'locale': voiceLocale});

        // Save the voice preference
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('tts_voice_$languageCode', bestVoice);

        debugPrint(
          '✅ Auto-assigned voice: $bestVoice for language $languageCode',
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error auto-assigning voice for $languageCode: $e');
      // Don't throw - voice assignment failure shouldn't block language change
    }
  }

  bool _isLikelyFemaleVoice(String voiceName) {
    final femaleNames = [
      'samantha',
      'karen',
      'moira',
      'tessa',
      'fiona',
      'anna',
      'maria',
      'lucia',
      'sophia',
      'isabella',
      'helena',
      'alice',
      'emma',
      'olivia',
      'susan',
      'victoria',
      'catherine',
      'audrey',
      'zoe',
      'ava',
      'kate',
      'sara',
      'laura',
    ];

    for (final name in femaleNames) {
      if (voiceName.contains(name)) {
        return true;
      }
    }
    return false;
  }

  String _getDefaultLocaleForLanguage(String languageCode) {
    switch (languageCode) {
      case 'es':
        return 'es-ES';
      case 'en':
        return 'en-US';
      case 'pt':
        return 'pt-BR';
      case 'fr':
        return 'fr-FR';
      case 'ja':
        return 'ja-JP';
      case 'zh':
        return 'zh-CN';
      default:
        return '$languageCode-${languageCode.toUpperCase()}';
    }
  }

  void _showErrorSnackBar(String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: theme.colorScheme.onError),
        ),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  bool get _isAnyDownloading => _isDownloading.values.any((v) => v == true);

  Widget _buildLanguageItem(String languageCode, String languageName) {
    final theme = Theme.of(context);
    final isDownloaded = _downloadStatus[languageCode] ?? false;
    final isCurrentLanguage = languageCode == _currentLanguage;
    final isDownloading = _isDownloading[languageCode] ?? false;
    final progress = _downloadProgress[languageCode] ?? 0.0;

    final bool disableTap = _isAnyDownloading ||
        (isDownloaded && isCurrentLanguage) ||
        isDownloading;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCurrentLanguage
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.language,
            color: isCurrentLanguage
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          languageName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isCurrentLanguage ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: _buildLanguageSubtitle(
          languageCode,
          isCurrentLanguage,
          isDownloaded,
          theme,
        ),
        trailing: _buildTrailingWidget(
          languageCode,
          isDownloaded,
          isDownloading,
          progress,
          theme,
        ),
        onTap: disableTap ? null : () => _downloadLanguage(languageCode),
      ),
    );
  }

  Widget? _buildLanguageSubtitle(
    String languageCode,
    bool isCurrentLanguage,
    bool isDownloaded,
    ThemeData theme,
  ) {
    if (isCurrentLanguage) {
      return Text(
        'application_language.current_language'.tr(),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      );
    } else if (isDownloaded) {
      return Text(
        'application_language.downloaded'.tr(),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    return null;
  }

  Widget _buildTrailingWidget(
    String languageCode,
    bool isDownloaded,
    bool isDownloading,
    double progress,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;

    if (isDownloading) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.primary.withAlpha(100),
            width: 2,
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
        ),
      );
    }

    IconData iconData;
    if (isDownloaded) {
      // If it's the current language, show check mark, otherwise show switch icon
      if (languageCode == _currentLanguage) {
        iconData = Icons.file_download_done_rounded;
      } else {
        // Show switch icon for downloaded but not current language
        iconData = Icons.swap_horiz_rounded;
      }
    } else {
      iconData = Icons.file_download_outlined;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.primary.withAlpha(180),
          width: 2,
        ),
        color: isDownloaded && languageCode == _currentLanguage
            ? colorScheme.primary.withAlpha(26)
            : Colors.transparent,
      ),
      child: Center(
        child: Icon(
          iconData,
          color: colorScheme.primary,
          size: 20,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeState.systemUiOverlayStyle,
      child: Scaffold(
        appBar: CustomAppBar(titleText: 'application_language.title'.tr()),
        backgroundColor: theme.colorScheme.surface,
        body: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'application_language.description'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ...Constants.supportedLanguages.entries.map((entry) {
              return _buildLanguageItem(entry.key, entry.value);
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
