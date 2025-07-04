// lib/pages/settings_page.dart
// Esta página permite al usuario configurar las opciones de la aplicación, incluyendo el tema.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart'; // Importa provider

import 'package:devocional_nuevo/pages/favorites_page.dart';
import 'package:devocional_nuevo/pages/about_page.dart';
import 'package:devocional_nuevo/pages/notification_page.dart';
import 'package:devocional_nuevo/providers/theme_provider.dart'; // Importa el ThemeProvider
import 'package:devocional_nuevo/utils/theme_constants.dart'; // Importa las constantes de tema para acceder a appThemeFamilies

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

    // Lista de nombres de familias de temas disponibles (obtenida directamente de theme_constants)
    final List<String> themeFamilies = appThemeFamilies.keys.toList();

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

            // Sección para seleccionar la familia de tema
            Text(
              'Seleccionar Familia de Tema:', // MODIFICADO: Texto del título
              style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface), // Usa el color de texto de la superficie
            ),
            const SizedBox(height: 10),
            // Dropdown para elegir la familia de tema
            DropdownButtonFormField<String>(
              value: themeProvider.currentThemeFamily, // MODIFICADO: Usar currentThemeFamily
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Familia de Tema', // MODIFICADO: Texto del label
                labelStyle: TextStyle(color: textTheme.bodyMedium?.color), // Color del label
              ),
              items: themeFamilies.map((String familyName) {
                return DropdownMenuItem<String>(
                  value: familyName,
                  child: Text(familyName, style: TextStyle(color: textTheme.bodyMedium?.color)), // Color del texto del item
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  themeProvider.setThemeFamily(newValue); // MODIFICADO: Usar setThemeFamily
                }
              },
            ),
            const SizedBox(height: 20), // Espacio después del selector de familia de tema

            // Sección para alternar el modo (claro/oscuro)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Modo Oscuro:',
                  style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
                ),
                Switch(
                  value: themeProvider.currentBrightness == Brightness.dark, // MODIFICADO: Usar currentBrightness
                  onChanged: (bool value) {
                    // MODIFICADO: Usar setBrightness directamente
                    themeProvider.setBrightness(value ? Brightness.dark : Brightness.light);
                  },
                  activeColor: colorScheme.primary, // Color del switch cuando está activo
                ),
              ],
            ),
            const SizedBox(height: 20), // Espacio después del switch de modo

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
            const SizedBox(height: 30),
            Row(
              children: [
                // Icono de favoritos usa el color primario del tema
                Icon(Icons.favorite, color: colorScheme.primary),
                const SizedBox(width: 10),
                // Texto de favoritos usa el color de texto de la superficie
                Text('Favoritos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textTheme.bodyMedium?.color)),
              ],
            ),
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
