import 'dart:developer' as developer;

import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/pages/about_page.dart';
import 'package:devocional_nuevo/pages/application_language_page.dart';
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
  List<String> _availableVoices = [];
  String? _selectedVoice;

  @override
  void initState() {
    super.initState();
    _loadTtsSettings();
  }

  Future<void> _loadTtsSettings() async {
    final devocionalProvider =
        Provider.of<DevocionalProvider>(context, listen: false);
    final localizationProvider =
        Provider.of<LocalizationProvider>(context, listen: false);

    try {
      // Load available voices for current language
      final currentLanguage = localizationProvider.currentLocale.languageCode;
      final voices =
          await devocionalProvider.getVoicesForLanguage(currentLanguage);

      // Load saved preferences
      final prefs = await SharedPreferences.getInstance();
      final savedRate = prefs.getDouble('tts_rate') ?? 0.5;
      final savedVoice = prefs.getString('tts_voice_$currentLanguage');

      setState(() {
        _ttsSpeed = savedRate;
        _availableVoices = voices;
        _selectedVoice = savedVoice;
      });
    } catch (e) {
      developer.log('Error loading TTS settings: $e');
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
            'settings.paypal_launch_error'.tr(),
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
        _showErrorSnackBar('settings.paypal_error'.tr({'error': e.toString()}));
      }
    } else {
      developer.log(
        'canLaunchUrl devolvió false. No hay aplicación para manejar esta URL.',
        name: 'PayPalLaunch',
      );
      _showErrorSnackBar(
        'settings.paypal_no_app_error'.tr(),
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

            // Language Selection Section
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ApplicationLanguagePage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
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
                            Constants.supportedLanguages[localizationProvider.currentLocale.languageCode] ?? 
                                localizationProvider.currentLocale.languageCode,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

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

            const SizedBox(height: 20),

            // Voice Selection
            if (_availableVoices.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.record_voice_over, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'settings.tts_voice'.tr(),
                      style: textTheme.bodyMedium?.copyWith(
                          fontSize: 16, color: colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButton<String>(
                value: _selectedVoice,
                isExpanded: true,
                hint: Text('settings.select_voice'.tr()),
                items: _availableVoices.map((voice) {
                  return DropdownMenuItem(
                    value: voice,
                    child: Text(
                      voice,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (String? newVoice) async {
                  if (newVoice != null && mounted) {
                    setState(() {
                      _selectedVoice = newVoice;
                    });

                    // Parse voice name and locale
                    final voiceParts = newVoice.split(' (');
                    final voiceName = voiceParts[0];
                    final locale = voiceParts.length > 1
                        ? voiceParts[1].replaceAll(')', '')
                        : '';

                    // Capture context before async operations
                    final currentContext = context;
                    final devocionalProvider = Provider.of<DevocionalProvider>(
                        currentContext,
                        listen: false);
                    final localizationProvider =
                        Provider.of<LocalizationProvider>(currentContext,
                            listen: false);
                    final currentLanguage =
                        localizationProvider.currentLocale.languageCode;

                    // Set the voice
                    await devocionalProvider.setTtsVoice({
                      'name': voiceName,
                      'locale': locale,
                    });

                    // Save preference
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString(
                        'tts_voice_$currentLanguage', newVoice);

                    if (mounted) {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        SnackBar(
                          content: Text('settings.voice_changed'.tr()),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 20),
            ],

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
                        'settings.contact_us'.tr(),
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
                        'settings.about_app'.tr(),
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
