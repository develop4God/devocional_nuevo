// lib/pages/settings_page.dart - SENIOR SIMPLE APPROACH (HARD DISABLE badges, backup, force PayPal donation)
import 'dart:developer' as developer;

import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/pages/about_page.dart';
import 'package:devocional_nuevo/pages/application_language_page.dart';
import 'package:devocional_nuevo/pages/contact_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/providers/localization_provider.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:devocional_nuevo/widgets/app_bar_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String _donationMode = 'paypal'; // Hardcoded to PayPal
  bool _showBadgesTab = false; // Always hidden
  bool _showBackupSection = false; // Always hidden

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
      // --- HABILITAR BACKUP ---
      setState(() {
        _donationMode = 'paypal'; // Siempre PayPal
        _showBadgesTab = false; // Siempre oculto
        _showBackupSection = true; // Habilitado
      });
      developer.log(
          '[FORCED ON] Feature flags set to: donation_mode=$_donationMode, badges=$_showBadgesTab, backup=$_showBackupSection');
    } catch (e) {
      developer.log('Feature flags failed to load: $e, using defaults');
      // Keep default values - app continues working
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
    final Uri url = Uri.parse('https://paypal.me/develop4God');

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

  // Simple decision method - senior approach
  Future<void> _handleDonateAction() async {
    developer.log('Donate action triggered with mode: $_donationMode');
    // Only PayPal available
    await _launchPaypal();
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
    final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;

    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: themeState.systemUiOverlayStyle,
        child: Scaffold(
          appBar: CustomAppBar(
            titleText: 'settings.title'.tr(),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Support/Donation Button (PayPal always)
                SizedBox(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: OutlinedButton.icon(
                      onPressed: _handleDonateAction,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.onSurface,
                        side:
                            BorderSide(color: colorScheme.primary, width: 2.0),
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
                                Constants.supportedLanguages[
                                        localizationProvider
                                            .currentLocale.languageCode] ??
                                    localizationProvider
                                        .currentLocale.languageCode,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              // Mostrar solo el idioma, sin versión bíblica
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

                // Backup Settings - conditional display (ahora habilitado)
                // if (_showBackupSection) ...[
                //   InkWell(
                //     onTap: () async {
                //       developer.log('[DEBUG] Settings: Backup row tapped.',
                //           name: 'SettingsPage');
                //       final bubbleId = 'settings_backup_option';
                //       developer.log(
                //           '[DEBUG] Settings: Calling BubbleUtils.markAsShown for bubbleId=bubbleId',
                //           name: 'SettingsPage');
                //       await BubbleUtils.markAsShown(bubbleId);
                //       developer.log(
                //           '[DEBUG] Settings: markAsShown completed for bubbleId=bubbleId',
                //           name: 'SettingsPage');
                //       if (!context.mounted) {
                //         developer.log(
                //             '[DEBUG] Settings: Context not mounted after await. Navigation skipped.',
                //             name: 'SettingsPage');
                //         return;
                //       }
                //       developer.log(
                //           '[DEBUG] Settings: Navigating to BackupSettingsPage',
                //           name: 'SettingsPage');
                //       Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //           builder: (context) => const BackupSettingsPage(),
                //         ),
                //       );
                //     },
                //     borderRadius: BorderRadius.circular(8.0),
                //     child: Container(
                //       padding: const EdgeInsets.symmetric(
                //         vertical: 12,
                //         horizontal: 4,
                //       ),
                //       child: Row(
                //         children: [
                //           Icon(Icons.add_to_drive_rounded,
                //               color: colorScheme.primary),
                //           const SizedBox(width: 10),
                //           Expanded(
                //             child: Column(
                //               crossAxisAlignment: CrossAxisAlignment.start,
                //               children: [
                //                 Text(
                //                   'settings.backup_option'.tr(),
                //                   style: textTheme.bodyMedium?.copyWith(
                //                     fontSize: 16,
                //                     color: colorScheme.onSurface,
                //                   ),
                //                 ),
                //                 const SizedBox(height: 4),
                //                 Text(
                //                   'settings.backup_subtitle'.tr(),
                //                   style: textTheme.bodySmall?.copyWith(
                //                     color: colorScheme.onSurfaceVariant,
                //                     fontSize: 12,
                //                   ),
                //                 ),
                //               ],
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),
                //   ),
                //   const SizedBox(height: 20),
                // ],

                // Contact
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ContactPage()),
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
                      MaterialPageRoute(
                          builder: (context) => const AboutPage()),
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
              ],
            ),
          ),
        ));
  }
}
