import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;
import 'package:flutter/cupertino.dart'; // Necesario para CupertinoIcons

import 'package:devocional_nuevo/pages/favorites_page.dart'; // Importado para la navegación a FavoritesPage

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
    // 'es_ES' es para español de España. Puedes probar con 'es_LA' o solo 'es' si 'es_ES' no funciona como esperas.
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
            const Text('Más opciones', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Image.network(
                  'https://www.paypalobjects.com/webstatic/icon/pp258.png',
                  height: 15,
                ),
                label: const Text('Donar con PayPal / Tarjeta',
                    style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[700],
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: _launchPaypal,
              ),
            ),
            //const SizedBox(height: 30),
            //const Text(
            //'Preferencias',
            //style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            //),
            //const SizedBox(height: 30),
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
                    DropdownMenuItem(
                      value: 'en',
                      child: Text('Inglés'),
                    ),
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
            // --- Nueva fila para "Favoritos guardados" (ahora totalmente interactiva) ---
            const SizedBox(height: 20), // Espacio entre el idioma y favoritos
            // Usamos InkWell para que toda la fila sea clickeable y tenga feedback visual
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FavoritesPage()),
                );
              },
              child: Padding(
                // Añadimos Padding aquí para mantener el espaciado interno de la fila
                padding: const EdgeInsets.symmetric(
                    vertical: 8.0), // Ajusta este padding si es necesario
                child: Row(
                  children: [
                    const Icon(
                        CupertinoIcons
                            .square_favorites_alt, // Icono de favoritos
                        color: Colors.deepPurple),
                    const SizedBox(width: 10),
                    const Text('Favoritos guardados', // Texto para favoritos
                        style: TextStyle(fontSize: 18)),
                    // Eliminamos Spacer y IconButton de flecha, ya que toda la fila es clickeable
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
