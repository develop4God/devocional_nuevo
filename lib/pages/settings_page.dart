import 'dart:developer' as developer;

import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/pages/about_page.dart';
import 'package:devocional_nuevo/pages/contact_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/providers/localization_provider.dart';
import 'package:devocional_nuevo/utils/constants.dart';
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
  double _ttsSpeed = 0.4; // Velocidad de TTS por defecto

  @override
  void initState() {
    super.initState();
    _loadTtsLanguages();
  }

  Future<void> _loadTtsLanguages() async {
    final devocionalProvider =
        Provider.of<DevocionalProvider>(context, listen: false);
    try {
      final languages = await devocionalProvider.getAvailableLanguages();
      // Load saved preferences
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString('tts_language');
      final savedRate = prefs.getDouble('tts_rate') ?? 0.5;

      setState(() {
        _ttsSpeed = savedRate;
        // Use saved language if available, otherwise default to Spanish
        if (savedLanguage != null && languages.contains(savedLanguage)) {
        } else if (languages.contains('es-ES')) {
        } else if (languages.contains('es')) {
        } else if (languages.isNotEmpty) {}
      });
    } catch (e) {
      developer.log('Error loading TTS languages: $e');
    }
  }

  Future<void> _launchPaypal() async {
    const String baseUrl =
        'https://www.paypal.com/donate/?hosted_button_id=CGQNBA4YPUG7A';
    const String paypalUrlWithLocale = '$baseUrl&locale.x=es_ES';
    final Uri url = Uri.parse(paypalUrlWithLocale);

    developer.log('Intentando abrir URL: $url', name: 'PayPalLaunch');

    if (await canLaunchUrl(url)) {
      developer.log(
        'canLaunchUrl devolvió true. Intentando launchUrl.',
        name: 'PayPalLaunch',
      );
      try {
        final launched = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );

        if (!launched) {
          developer.log(
            'launchUrl devolvió false. No se pudo lanzar.',
            name: 'PayPalLaunch',
          );
          _showErrorSnackBar(
            'No se pudo abrir PayPal. El sistema no pudo lanzar la URL.',
          );
        } else {
          developer.log('PayPal abierto exitosamente.', name: 'PayPalLaunch');
        }
      } catch (e) {
        developer.log(
          'Error al intentar lanzar PayPal: $e',
          error: e,
          name: 'PayPalLaunch',
        );
        _showErrorSnackBar('Error al abrir PayPal: ${e.toString()}');
      }
    } else {
      developer.log(
        'canLaunchUrl devolvió false. No hay aplicación para manejar esta URL.',
        name: 'PayPalLaunch',
      );
      _showErrorSnackBar(
        'No se pudo abrir PayPal. Asegúrate de tener un navegador web o la app de PayPal instalada.',
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
            // Botón de donación
            SizedBox(
              child: Align(
                alignment: Alignment.topRight,
                child: OutlinedButton.icon(
                  onPressed: _launchPaypal,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide(
                      color: colorScheme.primary,
                      width: 2.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  icon: Icon(Icons.favorite_border, color: colorScheme.primary),
                  label: Text(
                    'Donar', // Keep as is for now, can be translated later
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

            // Language Selection Section
            Row(
              children: [
                Icon(Icons.language, color: colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'settings.language'.tr(),
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: localizationProvider.currentLocale.languageCode,
                  items: Constants.supportedLanguages.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (String? newLanguage) async {
                    if (newLanguage != null) {
                      await localizationProvider.changeLanguage(newLanguage);

                      // Update DevocionalProvider with new language
                      final devocionalProvider =
                          Provider.of<DevocionalProvider>(context,
                              listen: false);
                      devocionalProvider.setSelectedLanguage(newLanguage);

                      // Automatically set the default version for the new language
                      final defaultVersion =
                          Constants.defaultVersionByLanguage[newLanguage];
                      if (defaultVersion != null) {
                        devocionalProvider.setSelectedVersion(defaultVersion);
                      }

                      developer.log('Language changed to: $newLanguage',
                          name: 'SettingsPage');
                      developer.log('Version changed to: $defaultVersion',
                          name: 'SettingsPage');

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('settings.language_changed'.tr()),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Bible Version Selection
            Consumer<DevocionalProvider>(
              builder: (context, devocionalProvider, child) {
                final currentLanguage =
                    localizationProvider.currentLocale.languageCode;
                final versions =
                    Constants.bibleVersionsByLanguage[currentLanguage] ?? [];

                // Ensure the selected version is available for current language
                String? currentVersion = devocionalProvider.selectedVersion;
                if (!versions.contains(currentVersion)) {
                  // If current version is not available, use default for language
                  currentVersion =
                      Constants.defaultVersionByLanguage[currentLanguage];

                  // Update provider with correct version
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (currentVersion != null) {
                      devocionalProvider.setSelectedVersion(currentVersion!);
                    }
                  });
                }

                // Only show version selector if there are versions available
                if (versions.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.book, color: colorScheme.primary),
                        const SizedBox(width: 10),
                        Text(
                          'settings.bible_version'.tr(),
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 10),
                        DropdownButton<String>(
                          value: versions.contains(currentVersion)
                              ? currentVersion
                              : versions.first,
                          items: versions.map((version) {
                            return DropdownMenuItem(
                              value: version,
                              child: Text(version),
                            );
                          }).toList(),
                          onChanged: (String? newVersion) async {
                            if (newVersion != null) {
                              devocionalProvider.setSelectedVersion(newVersion);

                              developer.log(
                                  'Bible version changed to: $newVersion',
                                  name: 'SettingsPage');

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('settings.version_changed'.tr()),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),

            // Audio/TTS Configuration Section
            Text(
              'settings.audio_settings'.tr(),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 15),

            // Reading Speed
            Row(
              children: [
                Icon(Icons.speed, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'settings.tts_speed'.tr(),
                    style: textTheme.bodyMedium
                        ?.copyWith(fontSize: 16, color: colorScheme.onSurface),
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
              onChangeEnd: (double value) async {
                // Save the TTS speed
                final devocionalProvider =
                    Provider.of<DevocionalProvider>(context, listen: false);
                await devocionalProvider.setTtsSpeechRate(value);
              },
            ),

            const SizedBox(height: 10),

            // Contact Information
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
                        'Contáctanos',
                        style: textTheme.bodyMedium?.copyWith(
                            fontSize: 16, color: colorScheme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                    Icon(Icons.perm_device_info_outlined,
                        color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Acerca de Devocionales Cristianos',
                        style: textTheme.bodyMedium?.copyWith(
                            fontSize: 16, color: colorScheme.onSurface),
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
    );
  }
}
