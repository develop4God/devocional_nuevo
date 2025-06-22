// lib/pages/settings_page.dart (o la ruta que tengas)

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;
import 'package:flutter/cupertino.dart'; // Necesario para CupertinoIcons

import 'package:devocional_nuevo/pages/favorites_page.dart';
import 'package:devocional_nuevo/pages/about_page.dart'; //

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLanguage = 'es'; // Idioma por defecto

  Future<void> _launchPaypal() async {
    // URL original del botón de donación
    const String baseUrl =
        'https://www.paypal.com/donate/?hosted_button_id=CGQNBA4YPUG7A';

    // Añadir el parámetro de idioma para español.
    const String paypalUrlWithLocale = '$baseUrl&locale.x=es_ES';

    final url = Uri.parse(paypalUrlWithLocale);

    developer.log('Intentando abrir URL: $url', name: 'PayPalLaunch');

    if (await canLaunchUrl(url)) {
      developer.log('canLaunchUrl devolvió true. Intentando launchUrl.',
          name: 'PayPalLaunch');
      try {
        bool launched = await launchUrl(url,
            mode: LaunchMode
                .platformDefault); // Usando platformDefault como lo sugerimos antes

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
    return Scaffold(
      appBar: AppBar(
        title:
        const Text('Más opciones', style: TextStyle(color: Colors.white)), // El color del texto seguirá siendo blanco por tu AppBarTheme en main.dart
        // Ya no necesitas especificar backgroundColor ni foregroundColor aquí.
        // Ahora heredará automáticamente de tu ThemeData en main.dart
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Inicio de la sección del botón de donación corregido
            SizedBox(
              child: Align(
                alignment: Alignment.topRight,
                child: ElevatedButton(
                  child: const Text(
                    'Donar',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[700],
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    minimumSize: const Size(100, 30),
                  ),
                  onPressed: _launchPaypal,
                ),
              ),
            ),
            // Fin de la sección del botón de donación corregido
            Row(
              children: [
                const Icon(Icons.language, color: Colors.deepPurple),
                const SizedBox(width: 10),
                const Text('Idioma:', style: TextStyle(fontSize: 18)),
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
                    //child: Text('Inglés'), //comentado, luego habilitar
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
            // --- Fila para "Favoritos guardados" ---
            const SizedBox(height: 20),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FavoritesPage()),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.square_favorites_alt,
                        color: Colors.deepPurple),
                    SizedBox(width: 10),
                    Text('Favoritos guardados', style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ),
            // --- NUEVA SECCIÓN: Fila para "Acerca de Devocionales Cristianos" ---
            const SizedBox(height: 20), // Espacio entre Favoritos y Acerca de
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutPage()),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.deepPurple), // Ícono de información
                    SizedBox(width: 10),
                    Text('Acerca de Devocionales Cristianos', // Texto de la opción
                        style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ),
            // --- FIN NUEVA SECCIÓN ---
          ],
        ),
      ),
    );
  }
}