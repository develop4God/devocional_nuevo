// lib/pages/notification_config_page.dart

import 'package:flutter/material.dart';
import 'package:devocional_nuevo/services/notification_service.dart';
import 'dart:developer' as developer;
// NEW IMPORTS for Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationConfigPage extends StatefulWidget {
  const NotificationConfigPage({super.key});

  @override
  State<NotificationConfigPage> createState() => _NotificationConfigPageState();
}

class _NotificationConfigPageState extends State<NotificationConfigPage> {
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _notificationsEnabled = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  // Nueva variable para la hora seleccionada temporalmente por el usuario
  TimeOfDay? _newlySelectedTime;
  bool _isLoading = true;
  String? _userId;
  DocumentReference? _userNotificationSettingsRef;

  @override
  void initState() {
    super.initState();
    _initializeFirebaseAndLoadSettings();
  }

  Future<void> _initializeFirebaseAndLoadSettings() async {
    final user = _auth.currentUser;
    if (user == null) {
      developer.log(
          'NotificationConfigPage: User not authenticated. Cannot load/save settings.',
          name: 'NotificationConfigPage');
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        // ACCIÓN: Ajuste del SnackBar para usar colorScheme.secondary y onSecondary
        final ColorScheme colorScheme =
            Theme.of(context).colorScheme; // Obtener colorScheme
        messenger.showSnackBar(
          SnackBar(
            backgroundColor:
                colorScheme.secondary, // Fondo del SnackBar usando secondary
            content: Text(
              'Error: Usuario no autenticado. Por favor, reinicia la aplicación.', // TEXTO TRADUCIDO
              style: TextStyle(
                  color: colorScheme
                      .onSecondary), // Texto del SnackBar usando onSecondary
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }
    _userId = user.uid;
    _userNotificationSettingsRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('settings')
        .doc('notifications');

    await _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (_userNotificationSettingsRef == null) {
        developer.log(
            'NotificationConfigPage: _userNotificationSettingsRef is null. Cannot load settings.',
            name: 'NotificationConfigPage');
        return;
      }

      final docSnapshot = await _userNotificationSettingsRef!.get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        _notificationsEnabled = data['notificationsEnabled'] ??
            true; // Si no existe, por defecto true

        // INICIO DEL AJUSTE 1: Manejo de timeString
        String timeString;
        bool shouldUpdateFirestore = false;

        if (data['notificationTime'] is String) {
          timeString = data['notificationTime'];
        } else {
          // Si notificationTime no existe o no es String, usa el valor por defecto
          timeString = await _notificationService.getNotificationTime();
          shouldUpdateFirestore = true; // Marca para actualizar Firestore
        }

        _selectedTime = TimeOfDay(
            hour: int.parse(timeString.split(':')[0]),
            minute: int.parse(timeString.split(':')[1]));
        developer.log(
            'NotificationConfigPage: Settings loaded from Firestore. Enabled: $_notificationsEnabled, Time: $timeString',
            name: 'NotificationConfigPage');

        // Si se usó un valor por defecto para notificationTime, guárdalo en Firestore
        if (shouldUpdateFirestore) {
          await _userNotificationSettingsRef!.update({
            'notificationTime': timeString,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
          developer.log(
              'NotificationConfigPage: notificationTime was missing, updated Firestore with default: $timeString',
              name: 'NotificationConfigPage');
        }
        // FIN DEL AJUSTE 1
      } else {
        // INICIO DEL AJUSTE 2: Si el documento de configuración no existe en absoluto, créalo con valores por defecto
        _notificationsEnabled =
            true; // Por defecto, activar las notificaciones en la primera instalación si no hay datos.
        String timeString = await _notificationService
            .getNotificationTime(); // Obtiene la hora por defecto (ej. 09:00)
        final parts = timeString.split(':');
        _selectedTime =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

        await _userNotificationSettingsRef!.set({
          // Crea el documento
          'notificationsEnabled': _notificationsEnabled,
          'notificationTime': timeString, // Guarda la hora por defecto aquí
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        developer.log(
            'NotificationConfigPage: No settings found in Firestore. Defaults applied and saved. Enabled: $_notificationsEnabled, Time: $timeString',
            name: 'NotificationConfigPage');
      } // FIN DEL AJUSTE 2
      // Inicializa _newlySelectedTime con la hora actual al cargar
      _newlySelectedTime = _selectedTime;
    } catch (e) {
      developer.log('ERROR loading notification settings from Firestore: $e',
          name: 'NotificationConfigPage', error: e);
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        // ACCIÓN: Ajuste del SnackBar para usar colorScheme.secondary y onSecondary
        final ColorScheme colorScheme =
            Theme.of(context).colorScheme; // Obtener colorScheme
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: colorScheme.secondary,
            content: Text(
              'Error al cargar la configuración: $e', // Corregido el mensaje de error para mostrar 'e'
              style: TextStyle(color: colorScheme.onSecondary),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleNotifications(bool enabled) async {
    setState(() {
      _notificationsEnabled = enabled;
    });
    try {
      if (_userNotificationSettingsRef == null) {
        developer.log(
            'NotificationConfigPage: _userNotificationSettingsRef is null. Cannot save settings.',
            name: 'NotificationConfigPage');
        return;
      }
      await _userNotificationSettingsRef!.update({
        'notificationsEnabled': enabled,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      developer.log(
          'NotificationConfigPage: Notifications enabled set to $enabled in Firestore.',
          name: 'NotificationConfigPage');

      await _notificationService.setNotificationsEnabled(enabled);

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      // ACCIÓN: Ajuste del SnackBar para usar colorScheme.secondary y onSecondary
      final ColorScheme colorScheme =
          Theme.of(context).colorScheme; // Obtener colorScheme
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.secondary,
          content: Text(
            _notificationsEnabled
                ? 'Notificaciones activadas.'
                : 'Notificaciones desactivadas.', // Usando _notificationsEnabled
            style: TextStyle(color: colorScheme.onSecondary),
          ),
        ),
      );
    } catch (e) {
      developer.log('ERROR toggling notifications in Firestore: $e',
          name: 'NotificationConfigPage', error: e);
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        // ACCIÓN: Ajuste del SnackBar para usar colorScheme.secondary y onSecondary
        final ColorScheme colorScheme =
            Theme.of(context).colorScheme; // Obtener colorScheme
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: colorScheme.secondary,
            content: Text(
              'Error al cambiar estado: $e', // TEXTO TRADUCIDO
              style: TextStyle(color: colorScheme.onSecondary),
            ),
          ),
        );
      }
      setState(() {
        _notificationsEnabled = !enabled;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _newlySelectedTime ??
          _selectedTime, // Usa la hora nueva si existe, sino la actual
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _newlySelectedTime) {
      // Compara con _newlySelectedTime
      setState(() {
        _newlySelectedTime = picked; // Actualiza la hora temporalmente
      });
    }
  }

  // Nuevo método para confirmar y guardar la hora en Firestore
  Future<void> _confirmSelectedTime() async {
    if (_userNotificationSettingsRef == null || _newlySelectedTime == null) {
      developer.log(
          'NotificationConfigPage: _userNotificationSettingsRef or _newlySelectedTime is null. Cannot save time.',
          name: 'NotificationConfigPage');
      return;
    }

    // No permitir guardar si la hora no ha cambiado
    if (_newlySelectedTime == _selectedTime) {
      developer.log(
          'NotificationConfigPage: Time not changed, no need to save.',
          name: 'NotificationConfigPage');
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        // ACCIÓN: Ajuste del SnackBar para usar colorScheme.secondary y onSecondary
        final ColorScheme colorScheme =
            Theme.of(context).colorScheme; // Obtener colorScheme
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: colorScheme.secondary,
            content: Text(
              'La hora no ha cambiado.', // MENSAJE SI HORA NO CAMBIA
              style: TextStyle(color: colorScheme.onSecondary),
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true; // Opcional: mostrar carga mientras se guarda
    });

    try {
      final String timeString =
          '${_newlySelectedTime!.hour.toString().padLeft(2, '0')}:${_newlySelectedTime!.minute.toString().padLeft(2, '0')}';
      await _userNotificationSettingsRef!.update({
        'notificationTime': timeString,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      developer.log(
          'NotificationConfigPage: Notification time adjusted to $timeString in Firestore.',
          name: 'NotificationConfigPage');

      await _notificationService.setNotificationTime(timeString);

      if (!mounted) return;
      setState(() {
        _selectedTime = _newlySelectedTime!; // Actualiza la hora principal
        _newlySelectedTime = null; // Resetea la hora nueva después de guardar
      });
      final messenger = ScaffoldMessenger.of(context);
      // ACCIÓN: Ajuste del SnackBar para usar colorScheme.secondary y onSecondary
      final ColorScheme colorScheme =
          Theme.of(context).colorScheme; // Obtener colorScheme
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.secondary,
          content: Text(
            'Hora de notificación ajustada a $timeString', // TEXTO TRADUCIDO
            style: TextStyle(color: colorScheme.onSecondary),
          ),
        ),
      );
    } catch (e) {
      developer.log('ERROR setting notification time in Firestore: $e',
          name: 'NotificationConfigPage', error: e);
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        // ACCIÓN: Ajuste del SnackBar para usar colorScheme.secondary y onSecondary
        final ColorScheme colorScheme =
            Theme.of(context).colorScheme; // Obtener colorScheme
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: colorScheme.secondary,
            content: Text(
              'Error al ajustar la hora: $e', // TEXTO TRADUCIDO
              style: TextStyle(color: colorScheme.onSecondary),
            ),
          ),
        );
      }
      // Si falla, revertir _newlySelectedTime a la hora original
      setState(() {
        _newlySelectedTime = _selectedTime;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Se comenta el método _testNotification completo, ya no es necesario.
  // Future<void> _testNotification() async {
  //   try {
  //     await _notificationService.showImmediateNotification(
  //       'Prueba de Notificación', // TEXTO TRADUCIDO
  //       '¡Esta es una notificación de prueba desde la aplicación!', // TEXTO TRADUCIDO
  //       payload: 'test_notification_payload',
  //     );
  //     if (!mounted) return;
  //     final messenger = ScaffoldMessenger.of(context);
  //     messenger.showSnackBar(
  //       SnackBar(content: Text('Notificación de prueba enviada.', style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface))), // TEXTO TRADUCIDO
  //     );
  //   } catch (e) {
  //     developer.log('ERROR sending test notification: $e', name: 'NotificationConfigPage', error: e);
  //     if (mounted) {
  //       final messenger = ScaffoldMessenger.of(context);
  //       messenger.showSnackBar(
  //         SnackBar(content: Text('Error al enviar la prueba: $e', style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface))), // TEXTO TRADUCIDO
  //       );
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    // Determina si el botón de confirmar debe estar habilitado
    bool isConfirmButtonEnabled =
        _newlySelectedTime != null && _newlySelectedTime != _selectedTime;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Configuración Notificaciones',
              style: TextStyle(color: Colors.white)), // TEXTO TRADUCIDO
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración Notificaciones',
            style: TextStyle(color: Colors.white)), // TEXTO TRADUCIDO
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Activar/Desactivar Notificaciones', // TEXTO TRADUCIDO
                  style: textTheme.titleMedium
                      ?.copyWith(color: colorScheme.onSurface),
                ),
                Switch(
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                  activeThumbColor: colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: _notificationsEnabled ? () => _selectTime(context) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.access_time,
                        color: _notificationsEnabled
                            ? colorScheme.primary
                            : colorScheme.onSurface.withAlpha(127)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Hora de la notificación diaria', // TEXTO TRADUCIDO
                        style: textTheme.titleMedium?.copyWith(
                          color: _notificationsEnabled
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withAlpha(127),
                        ),
                      ),
                    ),
                    // Muestra la hora temporal si existe, sino la hora guardada
                    Text(
                      (_newlySelectedTime ?? _selectedTime).format(context),
                      style: textTheme.titleMedium?.copyWith(
                        color: _notificationsEnabled
                            ? colorScheme.primary
                            : colorScheme.onSurface.withAlpha(127),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 16,
                        color: _notificationsEnabled
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withAlpha(127)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Botón de Confirmar Hora
            ElevatedButton.icon(
              // Habilitado solo si las notificaciones están activadas Y hay una hora nueva seleccionada diferente a la actual
              onPressed: (_notificationsEnabled && isConfirmButtonEnabled)
                  ? _confirmSelectedTime
                  : null,
              icon: Icon(Icons.send,
                  color: (_notificationsEnabled && isConfirmButtonEnabled)
                      ? Colors.white
                      : Colors.white.withAlpha(127)),
              label: Text(
                'Confirmar hora', // Nuevo texto para el botón
                style: textTheme.titleMedium?.copyWith(
                  color: (_notificationsEnabled && isConfirmButtonEnabled)
                      ? Colors.white
                      : Colors.white.withAlpha(127),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    (_notificationsEnabled && isConfirmButtonEnabled)
                        ? colorScheme.primary
                        : colorScheme.primary.withAlpha(127),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
