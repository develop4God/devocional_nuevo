// lib/pages/settings_page.dart - SENIOR SIMPLE APPROACH
import 'dart:developer' as developer;

// Import condicional - solo carga debug widget en debug builds
import 'package:devocional_nuevo/debug/debug_settings_section.dart'
    if (dart.library.js) 'package:devocional_nuevo/debug/debug_settings_section_stub.dart'
    if (kReleaseMode) 'package:devocional_nuevo/debug/debug_settings_section_stub.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/pages/about_page.dart';
import 'package:devocional_nuevo/pages/application_language_page.dart';
import 'package:devocional_nuevo/pages/backup_settings_page.dart';
import 'package:devocional_nuevo/pages/contact_page.dart';
import 'package:devocional_nuevo/pages/donate_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/providers/localization_provider.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _ttsSpeed = 0.4;
  final VoiceSettingsService _voiceSettingsService = VoiceSettingsService();

  // Feature flag state - simple and direct
  String _donationMode = 'paypal'; // Default fallback
  bool _showBadgesTab = false;
  bool _showBackupSection = false;

  @override
  void initState() {
    super.initState();
    _loadTtsSettings();
    _loadFeatureFlags();
  }

  Future<void> _loadTtsSettings() async {
    final localizationProvider = Provider.of<LocalizationProvider>(
      context,
      listen: false,
    );

    try {
      final currentLanguage = localizationProvider.currentLocale.languageCode;
      await _voiceSettingsService.autoAssignDefaultVoice(currentLanguage);

      final prefs = await SharedPreferences.getInstance();
      final savedRate = prefs.getDouble('tts_rate') ?? 0.5;

      if (mounted) {
        setState(() {
          _ttsSpeed = savedRate;
        });
      }
    } catch (e) {
      developer.log('Error loading TTS settings: $e');
      if (mounted) {
        _showErrorSnackBar('Error loading voice settings: $e');
      }
    }
  }

  Future<void> _loadFeatureFlags() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      // Configure with minimal settings
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? const Duration(seconds: 0)
              : const Duration(minutes: 5),
        ),
      );

      // Set defaults matching your Firebase config
      await remoteConfig.setDefaults({
        'donation_mode': 'paypal',
        'show_badges_tab': false,
        'show_backup_section': false,
      });

      await remoteConfig.fetchAndActivate();

      if (mounted) {
        setState(() {
          _donationMode = remoteConfig.getString('donation_mode');
          _showBadgesTab = remoteConfig.getBool('show_badges_tab');
          _showBackupSection = remoteConfig.getBool('show_backup_section');
        });
      }

      developer.log(
        'Feature flags loaded: donation_mode=$_donationMode, badges=$_showBadgesTab',
      );
    } catch (e) {
      developer.log('Feature flags failed to load: $e, using defaults');
      // Keep default values - app continues working
    }
  }

  Future<void> _refreshFeatureFlags() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetchAndActivate();

      if (mounted) {
        setState(() {
          _donationMode = remoteConfig.getString('donation_mode');
          _showBadgesTab = remoteConfig.getBool('show_badges_tab');
          _showBackupSection = remoteConfig.getBool('show_backup_section');
        });
      }

      developer.log('Feature flags refreshed: donation_mode=$_donationMode');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration updated from server'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      developer.log('Failed to refresh feature flags: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to update configuration');
      }
    }
  }

  Future<void> _onSpeedChanged(double value) async {
    try {
      final devocionalProvider = Provider.of<DevocionalProvider>(
        context,
        listen: false,
      );
      await devocionalProvider.setTtsSpeechRate(value);
    } catch (e) {
      developer.log('Error setting TTS speed: $e');
      if (mounted) {
        _showErrorSnackBar('Error setting speech rate: $e');
      }
    }
  }

  // Original PayPal method - preserved exactly
  Future<void> _launchPaypal() async {
    const String baseUrl =
        'https://www.paypal.com/donate/?hosted_button_id=CGQNBA4YPUG7A';
    const String paypalUrlWithLocale = '$baseUrl&locale.x=es_ES';
    final Uri url = Uri.parse(paypalUrlWithLocale);

    developer.log('Launching PayPal URL: $url', name: 'PayPalLaunch');

    try {
      if (await canLaunchUrl(url)) {
        final launched = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );

        if (!launched) {
          developer.log('launchUrl returned false', name: 'PayPalLaunch');
          _showErrorSnackBar('settings.paypal_launch_error'.tr());
        } else {
          developer.log('PayPal opened successfully', name: 'PayPalLaunch');
        }
      } else {
        developer.log('canLaunchUrl returned false', name: 'PayPalLaunch');
        _showErrorSnackBar('settings.paypal_no_app_error'.tr());
      }
    } catch (e) {
      developer.log('Error launching PayPal: $e', name: 'PayPalLaunch');
      _showErrorSnackBar('settings.paypal_error'.tr({'error': e.toString()}));
    }
  }

  Future<void> _navigateToDonatePage() async {
    try {
      developer.log(
        'Navigating to advanced donate page',
        name: 'DonateNavigation',
      );

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DonatePage()),
      );
    } catch (e) {
      developer.log(
        'Error navigating to donate page: $e',
        name: 'DonateNavigation',
      );
      _showErrorSnackBar('Error opening donation page: $e');
    }
  }

  // Simple decision method - senior approach
  Future<void> _handleDonateAction() async {
    developer.log('Donate action triggered with mode: $_donationMode');

    if (_donationMode == 'google') {
      await _navigateToDonatePage();
    } else {
      // Default to PayPal - safe fallback
      await _launchPaypal();
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizationProvider = Provider.of<LocalizationProvider>(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'settings.title'.tr(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Support/Donation Button
            SizedBox(
              child: Align(
                alignment: Alignment.topRight,
                child: OutlinedButton.icon(
                  onPressed: _handleDonateAction, // Simple decision here
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide(color: colorScheme.primary, width: 2.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  label: Text(
                    'settings.donate'.tr(),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Language Selection
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ApplicationLanguagePage(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
                child: Row(
                  children: [
                    Icon(Icons.language, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'settings.language'.tr(),
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Constants.supportedLanguages[localizationProvider
                                    .currentLocale.languageCode] ??
                                localizationProvider.currentLocale.languageCode,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Audio Settings
            Text(
              'settings.audio_settings'.tr(),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 15),

            Row(
              children: [
                Icon(Icons.speed, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'settings.tts_speed'.tr(),
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            Slider(
              value: _ttsSpeed,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              label: '${(_ttsSpeed * 100).round()}%',
              onChanged: (double value) {
                setState(() {
                  _ttsSpeed = value;
                });
              },
              onChangeEnd: _onSpeedChanged,
            ),

            const SizedBox(height: 20),

            // Backup Settings - conditional display
            if (_showBackupSection) ...[
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BackupSettingsPage(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_to_drive_outlined,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'settings.backup_option'.tr(),
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Contact
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ContactPage()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.contact_mail, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'settings.contact_us'.tr(),
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // About
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutPage()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.perm_device_info_outlined,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'settings.about_app'.tr(),
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Debug Section - only in debug mode
            if (kDebugMode) ...[
              DebugSettingsSection(
                donationMode: _donationMode,
                showBadgesTab: _showBadgesTab,
                showBackupSection: _showBackupSection,
                onRefreshFlags: _refreshFeatureFlags,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
