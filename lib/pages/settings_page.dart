// lib/pages/settings_page.dart (o la ruta que tengas)

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;
import 'package:flutter/cupertino.dart'; // Necesario para CupertinoIcons

import 'package:devocional_nuevo/pages/favorites_page.dart';
import 'package:devocional_nuevo/pages/about_page.dart';
import 'package:devocional_nuevo/pages/notification_permission_page.dart';
import 'package:devocional_nuevo/services/notification_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLanguage = 'es'; // Idioma por defecto
  bool _notificationsEnabled = false;
  String _notificationTime = '08:00';
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final enabled = await _notificationService.areNotificationsEnabled();
    final time = await _notificationService.getNotificationTime();
    setState(() {
      _notificationsEnabled = enabled;
      _notificationTime = time;
    });
  }

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

  Future<void> _toggleNotifications(bool enabled) async {
    if (enabled) {
      // Verificar si tenemos permisos
      final hasPermission = await _notificationService.hasNotificationPermissions();
      
      if (!hasPermission) {
        // Si no tenemos permisos, mostrar pantalla de solicitud
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationPermissionPage(),
          ),
        );
        
        // Si el usuario no concedió permisos, no activar notificaciones
        if (result != true) {
          return;
        }
      }
    }
    
    setState(() {
      _notificationsEnabled = enabled;
    });
    
    await _notificationService.setNotificationsEnabled(enabled);
    
    if (enabled) {
      _showSuccessSnackBar('Notificaciones activadas para las $_notificationTime');
    } else {
      _showSuccessSnackBar('Notificaciones desactivadas');
    }
  }

  Future<void> _selectNotificationTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(_notificationTime.split(':')[0]),
        minute: int.parse(_notificationTime.split(':')[1]),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.deepPurple,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        _notificationTime = timeString;
      });
      
      await _notificationService.setNotificationTime(timeString);
      
      if (_notificationsEnabled) {
        _showSuccessSnackBar('Hora de notificación actualizada: $timeString');
      }
    }
  }

  Future<void> _testNotification() async {
    // URL de una imagen de ejemplo para la notificación
    const String imageUrl = 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80';
    
    try {
      await _notificationService.showImmediateNotification(
        title: '🙏 Prueba de Notificación',
        body: '¡Las notificaciones están funcionando correctamente!',
        payload: 'test_notification',
        bigPicture: imageUrl,
      );
      _showSuccessSnackBar('Notificación de prueba enviada');
    } catch (e) {
      // Si hay error con la imagen, enviar notificación sin imagen
      await _notificationService.showImmediateNotification(
        title: '🙏 Prueba de Notificación',
        body: '¡Las notificaciones están funcionando correctamente!',
      );
      _showSuccessSnackBar('Notificación de prueba enviada (sin imagen)');
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
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
            
            // --- SECCIÓN DE NOTIFICACIONES ---
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),
            
            // Título de la sección
            const Row(
              children: [
                Icon(Icons.notifications, color: Colors.deepPurple),
                SizedBox(width: 10),
                Text(
                  'Notificaciones',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            
            // Switch para habilitar/deshabilitar notificaciones
            Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.deepPurple),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Recordatorio diario',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                Switch(
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                  activeColor: Colors.deepPurple,
                ),
              ],
            ),
            
            // Selector de hora (solo visible si las notificaciones están habilitadas)
            if (_notificationsEnabled) ...[
              const SizedBox(height: 15),
              InkWell(
                onTap: _selectNotificationTime,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.deepPurple),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Hora de notificación',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.deepPurple),
                        ),
                        child: Text(
                          _notificationTime,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: Colors.deepPurple),
                    ],
                  ),
                ),
              ),
              
              // Botón de prueba
              const SizedBox(height: 15),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _testNotification,
                  icon: const Icon(Icons.send),
                  label: const Text('Probar notificación'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ],
            
            // --- Fila para "Favoritos guardados" ---
            const SizedBox(height: 30),
            const Divider(),
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