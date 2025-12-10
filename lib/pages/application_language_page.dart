import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/providers/bible_selected_version_provider.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/providers/localization_provider.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:devocional_nuevo/widgets/app_bar_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
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
  String? _languageInProgress;

  bool _globalLoading = false;
  double _globalProgress = 0.0;
  String? _globalLanguage;
  String? _globalError;

  @override
  void initState() {
    super.initState();
    _loadDownloadStatus();
  }

  Future<void> _loadDownloadStatus() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    final localizationProvider =
        Provider.of<LocalizationProvider>(context, listen: false);
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

  Widget _buildLanguageItem(String languageCode, String languageName) {
    final theme = Theme.of(context);
    final isDownloaded = _downloadStatus[languageCode] ?? false;
    final isCurrentLanguage = languageCode == _currentLanguage;
    final isDownloading = _isDownloading[languageCode] ?? false;
    final progress = _downloadProgress[languageCode] ?? 0.0;
    final isProcessing = _languageInProgress == languageCode;
    final isLocked =
        _languageInProgress != null && _languageInProgress != languageCode;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isProcessing
          ? theme.colorScheme.primaryContainer.withAlpha(40)
          : null,
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
            languageCode, isCurrentLanguage, isDownloaded, theme),
        trailing: _buildTrailingWidget(
            languageCode, isDownloaded, isDownloading, progress, theme,
            isProcessing: isProcessing),
        onTap:
            (isDownloading || isLocked || (isDownloaded && isCurrentLanguage))
                ? null
                : () => _onChangeLanguage(languageCode),
      ),
    );
  }

  Widget? _buildLanguageSubtitle(String languageCode, bool isCurrentLanguage,
      bool isDownloaded, ThemeData theme) {
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

  Widget _buildTrailingWidget(String languageCode, bool isDownloaded,
      bool isDownloading, double progress, ThemeData theme,
      {required bool isProcessing}) {
    if (isDownloading || isProcessing) {
      return SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).toInt()}%',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    if (isDownloaded) {
      // If it's the current language, show check mark, otherwise show switch icon
      if (languageCode == _currentLanguage) {
        return Icon(
          Icons.file_download_done_rounded,
          color: theme.colorScheme.primary,
        );
      } else {
        return Icon(
          Icons.file_download_done_rounded,
          color: theme.colorScheme.primary,
        );
      }
    }

    return Icon(
      Icons.file_download_outlined,
      color: theme.colorScheme.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;

    if (_globalLoading) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: themeState.systemUiOverlayStyle,
        child: Scaffold(
          appBar: CustomAppBar(
            titleText: 'application_language.title'.tr(),
          ),
          backgroundColor: theme.colorScheme.surface,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 180,
                  child: Lottie.asset(
                    'assets/lottie/language_translation.json',
                    repeat: true,
                    animate: true,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'application_language.loading_language'
                      .tr({'language': _globalLanguage ?? ''}),
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text('${(_globalProgress * 100).toInt()}%',
                    style: theme.textTheme.bodyMedium),
                if (_globalError != null) ...[
                  const SizedBox(height: 16),
                  Text(_globalError!, style: TextStyle(color: Colors.red)),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text('Reintentar'),
                    onPressed: () {
                      setState(() {
                        _globalLoading = false;
                        _globalError = null;
                      });
                    },
                  ),
                ]
              ],
            ),
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeState.systemUiOverlayStyle,
      child: Scaffold(
        appBar: CustomAppBar(
          titleText: 'application_language.title'.tr(),
        ),
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

  void _onChangeLanguage(String languageCode) async {
    if (_languageInProgress != null || _globalLoading) return;
    setState(() {
      _globalLoading = true;
      _globalProgress = 0.0;
      _globalLanguage =
          Constants.supportedLanguages[languageCode] ?? languageCode;
      _globalError = null;
      _languageInProgress = languageCode;
      _isDownloading[languageCode] = true;
      _downloadProgress[languageCode] = 0.0;
    });
    // Capturar dependencias de context antes de cualquier await
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final localizationProvider =
        Provider.of<LocalizationProvider>(context, listen: false);
    final devocionalProvider =
        Provider.of<DevocionalProvider>(context, listen: false);
    final bibleVersionProvider =
        Provider.of<BibleSelectedVersionProvider>(context, listen: false);
    final snackBarBackground = Theme.of(context).appBarTheme.backgroundColor ??
        Theme.of(context).colorScheme.primary;
    final snackBarText = 'application_language.current_language'.tr();
    final errorText = 'application_language.download_failed'.tr();
    try {
      // Simular progreso real (puedes conectar aquí el callback real si lo tienes)
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 120));
        if (!context.mounted) return;
        setState(() {
          _globalProgress = i / 10.0;
        });
      }
      await localizationProvider.changeLanguage(languageCode);
      devocionalProvider.setSelectedLanguage(languageCode);
      final defaultVersion = Constants.defaultVersionByLanguage[languageCode];
      if (defaultVersion != null) {
        devocionalProvider.setSelectedVersion(defaultVersion);
      }
      devocionalProvider.audioController.ttsService
          .setLanguageContext(languageCode, defaultVersion ?? '');
      await devocionalProvider.audioController.ttsService
          .setLanguage(localizationProvider.getTtsLocale());
      await bibleVersionProvider.setLanguage(languageCode, fromSettings: true);
      if (!context.mounted) return;
      setState(() {
        _currentLanguage = languageCode;
        _downloadStatus[languageCode] = true;
        _isDownloading[languageCode] = false;
        _languageInProgress = null;
        _globalLoading = false;
        _globalProgress = 1.0;
      });
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: snackBarBackground,
          content: Text(
            snackBarText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      setState(() {
        _globalError = errorText;
        _globalLoading = true;
      });
    }
  }
}
