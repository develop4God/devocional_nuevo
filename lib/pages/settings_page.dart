// lib/pages/settings_page.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart'; // Importa provider

import 'package:devocional_nuevo/pages/favorites_page.dart';
import 'package:devocional_nuevo/pages/about_page.dart';
import 'package:devocional_nuevo/pages/notification_page.dart';
import 'package:devocional_nuevo/providers/theme_provider.dart'; // Importa el ThemeProvider

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLanguage = 'es'; // Idioma por defecto

  Future<void> _launchPaypal() async {
    const String baseUrl =
        'https://www.paypal.com/donate/?hosted_button_id=CGQNBA4YPUG7A';
    const String paypalUrlWithLocale = '$baseUrl&locale.x=es_ES';
    final url = Uri.parse(paypalUrlWithLocale);

    developer.log('Intentando abrir URL: $url', name: 'PayPalLaunch');

    if (await canLaunchUrl(url)) {
      developer.log('canLaunchUrl devolvió true. Intentando launchUrl.',
          name: 'PayPalLaunch');
      try {
        bool launched = await launchUrl(url,
            mode: LaunchMode.platformDefault);

        if (!launched) {
          developer.log('launchUrl devolvió false. No se pudo lanzar.',
              name: 'PayPalLaunch');
          _showErrorSnackBar(
              'No se pudo abrir PayPal. El sistema no pudo lanzar la URL.');
        } else {
          developer.log('PayPal abierto exitosamente.', name: 'PayPalLaunch');
        }
      } catch (e) {
        developer.log('Error al intentar lanzar PayPal: $e',
            error: e, name: 'PayPalLaunch');
        _showErrorSnackBar('Error al abrir PayPal: ${e.toString()}');
      }
    } else {
      developer.log(
          'canLaunchUrl devolvió false. No hay aplicación para manejar esta URL.',
          name: 'PayPalLaunch');
      _showErrorSnackBar(
          'No se pudo abrir PayPal. Asegúrate de tener un navegador web o la app de PayPal instalada.');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Accede al ThemeProvider para obtener y cambiar el tema
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Obtiene el esquema de colores del tema actual
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    // Obtiene el tema de texto del tema actual
    final TextTheme textTheme = Theme.of(context).textTheme;

    // Lista de nombres de temas disponibles para mostrar en el selector
    final List<String> themeNames = [
      'Deep Purple (Light)',
      'Deep Purple (Dark)',
      'Light Green (Light)',
      'Light Green (Dark)',
      'Cyan (Light)',
      'Cyan (Dark)',
      'Light Blue (Light)',
      'Light Blue (Dark)',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Más opciones',
          // Usa el color del foreground del AppBar del tema
          style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
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
                child: ElevatedButton(
                  onPressed: _launchPaypal,
                  style: ElevatedButton.styleFrom(
                    // El color de fondo del botón de donar no debería cambiar con el tema
                    backgroundColor: Colors.yellow[700],
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    minimumSize: const Size(100, 30),
                  ),
                  child: const Text(
                    'Donar',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
            // Selección de idioma
            Row(
              children: [
                // Icono de idioma usa el color primario del tema
                Icon(Icons.language, color: colorScheme.primary),
                const SizedBox(width: 10),
                // Texto de idioma usa el color de texto de la superficie
                Text('Idioma:', style: TextStyle(fontSize: 18, color: textTheme.bodyMedium?.color)),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedLanguage,
                  items: const [
                    DropdownMenuItem(
                      value: 'es',
                      child: Text('Español'),
                    ),
                    //DropdownMenuItem(
                    //value: 'en',
                    //child: Text('Inglés'),
                    //),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedLanguage = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20), // Espacio entre Idioma y Tema

            // Sección para seleccionar el tema
            Text(
              'Seleccionar Tema:',
              style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface), // Usa el color de texto de la superficie
            ),
            const SizedBox(height: 10),
            // Dropdown para elegir el tema
            DropdownButtonFormField<String>(
              value: themeProvider.currentThemeName, // Tema actual seleccionado
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Tema',
                labelStyle: TextStyle(color: textTheme.bodyMedium?.color), // Color del label
              ),
              items: themeNames.map((String name) {
                return DropdownMenuItem<String>(
                  value: name,
                  child: Text(name, style: TextStyle(color: textTheme.bodyMedium?.color)), // Color del texto del item
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  themeProvider.setTheme(newValue); // Cambia el tema usando el provider
                }
              },
            ),
            const SizedBox(height: 20), // Espacio después del selector de tema

            // Línea para acceder a la configuración de notificaciones
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationPage()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    // Icono de notificaciones usa el color primario del tema
                    Icon(Icons.notifications, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    // Texto de notificaciones usa el color de texto de la superficie
                    Text(
                      'Configuración de notificaciones',
                      style: TextStyle(fontSize: 18, color: textTheme.bodyMedium?.color),
                    ),
                  ],
                ),
              ),
            ),
            // Favoritos guardados
            // Texto de favoritos usa el color de texto de la superficie
            const SizedBox(height: 15),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FavoritesPage()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    // Icono de favoritos guardados usa el color primario del tema
                    Icon(CupertinoIcons.square_favorites_alt,
                        color: colorScheme.primary),
                    const SizedBox(width: 10),
                    // Texto de favoritos guardados usa el color de texto de la superficie
                    Text('Favoritos guardados', style: TextStyle(fontSize: 18, color: textTheme.bodyMedium?.color)),
                  ],
                ),
              ),
            ),
            // Acerca de
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
                    // Icono de información usa el color primario del tema
                    Icon(Icons.info_outline, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    // Texto de acerca de usa el color de texto de la superficie
                    Text('Acerca de Devocionales Cristianos',
                        style: TextStyle(fontSize: 18, color: textTheme.bodyMedium?.color)),
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
