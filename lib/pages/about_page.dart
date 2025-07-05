// lib/pages/about_page.dart

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _appVersion = 'Cargando...';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  // Método para obtener la versión de la aplicación
  Future<void> _initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = info.version;
    });
  }

  // Método para lanzar URL externas
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Si la URL no se puede abrir, muestra un SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el enlace.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme
        .of(context)
        .textTheme;
    final ColorScheme colorScheme = Theme
        .of(context)
        .colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Acerca de tu app',
          style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor), // Usa el color del foreground del AppBar del tema
        ),
        centerTitle: true, // Asegura que el título del AppBar esté centrado si hay espacio
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Alinea los hijos a la izquierda por defecto
          children: <Widget>[
            // Ícono de la Aplicación (Centrado como lo deseas)
            Align(
              alignment: Alignment.center, // Centra el ícono dentro de su espacio disponible
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.0), // Bordes redondeados
                child: Image.asset(
                  'assets/icons/app_icon.png', // Ruta de tu ícono, ¡confirma que exista!
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Nombre de la Aplicación
            Text(
              'Devocionales Cristianos',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary, // Usa el color primario de tu tema
              ),
              textAlign: TextAlign.left, // **Corregido:** Alineado a la izquierda
            ),
            const SizedBox(height: 8),

            // Versión de la Aplicación
            Text(
              'Versión $_appVersion',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface, // MODIFICADO: de Colors.grey[600] a colorScheme.onSurface
              ),
              textAlign: TextAlign.center, // centrado
            ),
            const SizedBox(height: 10),

            // Descripción de la Aplicación
            Text(
              'Devocionales Cristianos te trae inspiración diaria directamente a tu teléfono. Disfruta de mensajes bíblicos actualizados, explora, guarda tus favoritos, comparte la palabra y personaliza tu experiencia de lectura.',
              style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface), // MODIFICADO: Añadido colorScheme.onSurface
              textAlign: TextAlign.center, //centrado
            ),
            const SizedBox(height: 10),

            // Características Principales
            Text(
              'Características Principales:',
              style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold, color: colorScheme.onSurface), // MODIFICADO: Añadido colorScheme.onSurface
              textAlign: TextAlign.center, // centrado
            ),
            const SizedBox(height: 10),
            const Column(  // Añadido 'const' para mejorar el rendimiento
              crossAxisAlignment: CrossAxisAlignment.start, // Los ítems de características ya están alineados a la izquierda
              children: <Widget>[
                _FeatureItem(text: '• Devocionales Diarios'),
                _FeatureItem(text: '• Soporte Multi-Versión'),
                _FeatureItem(text: '• Favoritos'),
                _FeatureItem(text: '• Compartir Contenido'),
                _FeatureItem(text: '• Personalización de Idioma'),
                _FeatureItem(text: '• Temas personalizables'),
                _FeatureItem(text: '• Temas Oscuro y Claro'),
                _FeatureItem(text: '• Opciones de Notificación'),

              ],
            ),
            const SizedBox(height: 30),

            // Desarrollado por
            Center( // Envuelve el texto con Center para centrarlo horizontalmente
              child: Text(
                'Desarrollado por Develop4God',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface, // MODIFICADO: de Colors.grey[700] a colorScheme.onSurface
                ),
                textAlign: TextAlign.center, // Este textAlign ahora centrará el texto dentro del Center
              ),
            ),
            const SizedBox(height: 30),

            // Enlace a la Web (Términos y Condiciones / Copyright)
            Center( // Envuelve el botón en un Center para centrarlo horizontalmente
              child: ElevatedButton.icon(
                onPressed: () => _launchURL('https://develop4god.github.io/'),
                icon: Icon(Icons.public, color: colorScheme.onPrimary), // MODIFICADO: de Colors.white a colorScheme.onPrimary
                label: Text('Términos y Condiciones / Copyright', style: TextStyle(color: colorScheme.onPrimary)), // MODIFICADO: de Colors.white a colorScheme.onPrimary
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary, // MODIFICADO: de Colors.deepPurple a colorScheme.primary
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget auxiliar para elementos de la lista de características
class _FeatureItem extends StatelessWidget {
  final String text;

  const _FeatureItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        text,
        style: Theme
            .of(context)
            .textTheme
            .bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface), // MODIFICADO: Añadido colorScheme.onSurface
        textAlign: TextAlign.center, // centrado
      ),
    );
  }
}
