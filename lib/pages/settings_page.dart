import 'dart:developer' as developer;

import 'package:devocional_nuevo/pages/about_page.dart';
import 'package:devocional_nuevo/pages/contact_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/providers/theme_provider.dart';
import 'package:devocional_nuevo/utils/theme_constants.dart';
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
  String _selectedLanguage = 'es'; // Idioma por defecto
  double _ttsSpeed = 0.5; // Velocidad de TTS por defecto

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
    Provider.of<ThemeProvider>(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    appThemeFamilies.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuraciones',
          style: TextStyle(color: Colors.white),
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
                  // Se cambia a OutlinedButton.icon
                  onPressed: _launchPaypal,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface, // Color del texto
                    side: BorderSide(
                      color: colorScheme.primary,
                      // Color del borde del tema principal
                      width: 2.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(20.0), // Bordes redondeados
                    ),
                  ),
                  icon: Icon(Icons.favorite_border, color: colorScheme.primary),
                  // Icono de corazón
                  label: Text(
                    'Donar',
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
            // Sección para seleccionar el idioma
            Row(
              children: [
                Icon(Icons.language, color: colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Idioma:',
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedLanguage,
                  items: const [
                    DropdownMenuItem(value: 'es', child: Text('Español')),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedLanguage = newValue;
                        developer.log('Idioma cambiado a: $_selectedLanguage',
                            name: 'SettingsPage');
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Sección para configuración de Audio/TTS
            Text(
              'Configuración de Audio',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 15),
            // Velocidad de voz
            Row(
              children: [
                Icon(Icons.speed, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Velocidad de lectura:',
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
            const SizedBox(height: 15),
            // Idioma de voz

            const SizedBox(
              height: 20,
            ),
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
                    Icon(Icons.info_outline, color: colorScheme.primary),
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
