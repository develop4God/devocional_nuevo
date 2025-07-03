import 'package:flutter/material.dart';
import 'package:devocional_nuevo/pages/notification_permission_page.dart';
import 'package:devocional_nuevo/services/notification_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
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

  Future<void> _toggleNotifications(bool enabled) async {
    if (enabled) {
      final hasPermission = await _notificationService.hasNotificationPermissions();
      if (!hasPermission) {
        if (!mounted) return;
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationPermissionPage(),
          ),
        );
        if (!mounted) return;
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
        // Asegura que el TimePicker también use los colores del tema
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary, // Usa el color primario del tema
              onPrimary: Theme.of(context).colorScheme.onPrimary, // Usa el color de texto sobre primario
              surface: Theme.of(context).colorScheme.surface, // Usa el color de superficie del tema
              onSurface: Theme.of(context).colorScheme.onSurface, // Usa el color de texto sobre superficie
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
          backgroundColor: Colors.green, // Se mantiene verde para éxito
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtiene el esquema de colores del tema actual
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    // Obtiene el tema de texto del tema actual
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notificaciones',
          style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor), // Usa el color del foreground del AppBar del tema
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row( // Eliminado const para poder usar colorScheme
              children: [
                Icon(Icons.notifications, color: colorScheme.primary), // Usa el color primario del tema
                const SizedBox(width: 10),
                Text(
                  'Notificaciones',
                  style: TextStyle( // Eliminado const para poder usar colorScheme
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary, // Usa el color primario del tema
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Icon(Icons.notifications_active, color: colorScheme.primary), // Usa el color primario del tema
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Recordatorio diario',
                    style: textTheme.bodyMedium?.copyWith(fontSize: 16, color: colorScheme.onSurface), // Usa el color de texto de la superficie
                  ),
                ),
                Switch(
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                  activeColor: colorScheme.primary, // Usa el color primario del tema
                ),
              ],
            ),
            if (_notificationsEnabled) ...[
              const SizedBox(height: 15),
              InkWell(
                onTap: _selectNotificationTime,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: colorScheme.primary), // Usa el color primario del tema
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Hora de notificación',
                          style: textTheme.bodyMedium?.copyWith(fontSize: 16, color: colorScheme.onSurface), // Usa el color de texto de la superficie
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha((255 * 0.1).round()), // Usar withAlpha para la transparencia
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.primary), // Usa el color primario para el borde
                        ),
                        child: Text(
                          _notificationTime,
                          style: textTheme.bodyMedium?.copyWith( // Usa el estilo de texto del tema
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary, // Usa el color primario del tema
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right, color: colorScheme.primary), // Usa el color primario del tema
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _testNotification,
                  icon: Icon(Icons.send, color: Theme.of(context).elevatedButtonTheme.style?.foregroundColor?.resolve(WidgetState.values.toSet())),
                  label: Text('Probar notificación', style: TextStyle(color: Theme.of(context).elevatedButtonTheme.style?.foregroundColor?.resolve(WidgetState.values.toSet()))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary, // Usa el color primario del tema
                    foregroundColor: colorScheme.onPrimary, // Usa el color de texto sobre primario
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
