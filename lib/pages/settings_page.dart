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
import 'package:devocional_nuevo/pages/contact_page.dart'; // Importa ContactPage para la navegación directa
import 'package:devocional_nuevo/providers/theme_provider.dart'; // Importa el ThemeProvider
import 'package:devocional_nuevo/utils/theme_constants.dart'; // Importa las constantes de tema para acceder a appThemeFamilies y settingsOptionTextStyle

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
            Row( // Agrupamos el icono y el texto en una nueva Row
              children: [
                Icon(Icons.palette, color: colorScheme.primary), // Icono para temas
                const SizedBox(width: 10), // Espacio entre icono y texto
                Text(
                  'Seleccionar Tema:',
                  style: textTheme.bodyMedium?.merge(settingsOptionTextStyle).copyWith(color: colorScheme.onSurface), // Estilo estandarizado
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Dropdown para elegir la familia de tema
            DropdownButtonFormField<String>(
              value: themeProvider.currentThemeFamily,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Colores',
                labelStyle: TextStyle(color: textTheme.bodyMedium?.color),
              ),
              items: themeFamilies.map((String familyName) {
                return DropdownMenuItem<String>(
                  value: familyName,
                  child: Text(themeDisplayNames[familyName] ?? familyName, style: TextStyle(color: textTheme.bodyMedium?.color)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  themeProvider.setThemeFamily(newValue);
                }
              },
            ),
            const SizedBox(height: 20), // Espacio después del selector de familia de tema

            // Sección para alternar el modo (claro/oscuro)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row( // Agrupamos el icono y el texto en una nueva Row
                  children: [
                    Icon(Icons.contrast, color: colorScheme.primary), // Icono para "Luz baja"
                    const SizedBox(width: 10), // Espacio entre el icono y el texto
                    Text(
                      'Luz baja:',
                      style: textTheme.bodyMedium?.merge(settingsOptionTextStyle).copyWith(color: colorScheme.onSurface), // Estilo estandarizado
                    ),
                  ],
                ),
                Switch(
                  value: themeProvider.currentBrightness == Brightness.dark,
                  onChanged: (bool value) {
                    themeProvider.setBrightness(value ? Brightness.dark : Brightness.light);
                  },
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
                    Expanded(
                      child: Text(
                        'Configuración de notificaciones',
                        style: textTheme.bodyMedium?.merge(settingsOptionTextStyle).copyWith(color: colorScheme.onSurface), // Estilo estandarizado
                        maxLines: 1, // Añadido para evitar desbordamiento
                        overflow: TextOverflow.ellipsis, // Añadido para truncar texto
                      ),
                    ),
                  ],
                ),
              ),
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
                    Expanded(
                      child: Text(
                        'Favoritos guardados',
                        style: textTheme.bodyMedium?.merge(settingsOptionTextStyle).copyWith(color: colorScheme.onSurface), // Estilo estandarizado
                        maxLines: 1, // Añadido para evitar desbordamiento
                        overflow: TextOverflow.ellipsis, // Añadido para truncar texto
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Opcion para Contáctanos, entre Favoritos guardados y Acerca de
            const SizedBox(height: 20), // Espacio después de favoritos guardados
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ContactPage()), // Navega directamente a ContactPage
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.contact_mail, color: colorScheme.primary), // Icono para contacto
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Contáctanos',
                        style: textTheme.bodyMedium?.merge(settingsOptionTextStyle).copyWith(color: colorScheme.onSurface),
                        maxLines: 1, // Añadido para evitar desbordamiento
                        overflow: TextOverflow.ellipsis, // Añadido para truncar texto
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Acerca de
            const SizedBox(height: 20), // Espacio antes de Acerca de
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
                    Expanded(
                      child: Text(
                        'Acerca de Devocionales Cristianos',
                        style: textTheme.bodyMedium?.merge(settingsOptionTextStyle).copyWith(color: colorScheme.onSurface), // Estilo estandarizado
                        maxLines: 1, // Añadido para evitar desbordamiento
                        overflow: TextOverflow.ellipsis, // Añadido para truncar texto
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
