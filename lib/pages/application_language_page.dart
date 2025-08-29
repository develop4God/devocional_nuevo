import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/providers/localization_provider.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApplicationLanguagePage extends StatefulWidget {
  const ApplicationLanguagePage({super.key});

  @override
  State<ApplicationLanguagePage> createState() => _ApplicationLanguagePageState();
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
    
    final localizationProvider = Provider.of<LocalizationProvider>(context, listen: false);
    _currentLanguage = localizationProvider.currentLocale.languageCode;
    
    setState(() {
      for (final languageCode in Constants.supportedLanguages.keys) {
        _downloadStatus[languageCode] = prefs.getBool('language_downloaded_$languageCode') ?? (languageCode == 'es');
        _downloadProgress[languageCode] = 0.0;
        _isDownloading[languageCode] = false;
      }
    });
  }

  Future<void> _downloadLanguage(String languageCode) async {
    if (_isDownloading[languageCode] == true) return;
    
    setState(() {
      _isDownloading[languageCode] = true;
      _downloadProgress[languageCode] = 0.0;
    });

    final devocionalProvider = Provider.of<DevocionalProvider>(context, listen: false);
    final localizationProvider = Provider.of<LocalizationProvider>(context, listen: false);
    
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
      
      // Update DevocionalProvider with new language
      devocionalProvider.setSelectedLanguage(languageCode);

      // Set default version for the language
      final defaultVersion = Constants.defaultVersionByLanguage[languageCode];
      if (defaultVersion != null) {
        devocionalProvider.setSelectedVersion(defaultVersion);
      }

      // Download devotional content
      final downloadSuccess = await devocionalProvider.downloadCurrentYearDevocionales();
      
      if (downloadSuccess) {
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Widget _buildLanguageItem(String languageCode, String languageName) {
    final theme = Theme.of(context);
    final isDownloaded = _downloadStatus[languageCode] ?? false;
    final isCurrentLanguage = languageCode == _currentLanguage;
    final isDownloading = _isDownloading[languageCode] ?? false;
    final progress = _downloadProgress[languageCode] ?? 0.0;

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
        subtitle: isCurrentLanguage
          ? Text(
              'application_language.current_language'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            )
          : null,
        trailing: _buildTrailingWidget(languageCode, isDownloaded, isDownloading, progress, theme),
        onTap: isDownloaded && !isDownloading
          ? () => _downloadLanguage(languageCode)
          : isDownloading
            ? null
            : () => _downloadLanguage(languageCode),
      ),
    );
  }

  Widget _buildTrailingWidget(String languageCode, bool isDownloaded, bool isDownloading, double progress, ThemeData theme) {
    if (isDownloading) {
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
      return Icon(
        Icons.check_circle,
        color: theme.colorScheme.primary,
      );
    }

    return Icon(
      Icons.download,
      color: theme.colorScheme.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('application_language.title'.tr()),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
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
    );
  }
}