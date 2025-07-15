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
      developer.log('NotificationConfigPage: User not authenticated. Cannot load/save settings.', name: 'NotificationConfigPage');
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          const SnackBar(content: Text('Error: Usuario no autenticado. Por favor, reinicia la aplicación.')), // TEXTO TRADUCIDO
        );
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }
    _userId = user.uid;
    _userNotificationSettingsRef = _firestore.collection('users').doc(_userId).collection('settings').doc('notifications');

    await _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (_userNotificationSettingsRef == null) {
        developer.log('NotificationConfigPage: _userNotificationSettingsRef is null. Cannot load settings.', name: 'NotificationConfigPage');
        return;
      }

      final docSnapshot = await _userNotificationSettingsRef!.get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        _notificationsEnabled = data['notificationsEnabled'] ?? true;
        final String timeString = data['notificationTime'] is String
            ? data['notificationTime']
            : await _notificationService.getNotificationTime();
        final parts = timeString.split(':');
        _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        developer.log('NotificationConfigPage: Settings loaded from Firestore. Enabled: $_notificationsEnabled, Time: $timeString', name: 'NotificationConfigPage');
      } else {
        _notificationsEnabled = await _notificationService.areNotificationsEnabled();
        String timeString = await _notificationService.getNotificationTime();
        final parts = timeString.split(':');
        _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

        await _userNotificationSettingsRef!.set({
          'notificationsEnabled': _notificationsEnabled,
          'notificationTime': timeString,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        developer.log('NotificationConfigPage: No settings found in Firestore. Defaults applied and saved. Enabled: $_notificationsEnabled, Time: $timeString', name: 'NotificationConfigPage');
      }
    } catch (e) {
      developer.log('ERROR loading notification settings from Firestore: $e', name: 'NotificationConfigPage', error: e);
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(content: Text('Error al cargar la configuración: $e')), // TEXTO TRADUCIDO
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
        developer.log('NotificationConfigPage: _userNotificationSettingsRef is null. Cannot save settings.', name: 'NotificationConfigPage');
        return;
      }
      await _userNotificationSettingsRef!.update({
        'notificationsEnabled': enabled,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      developer.log('NotificationConfigPage: Notifications enabled set to $enabled in Firestore.', name: 'NotificationConfigPage');

      await _notificationService.setNotificationsEnabled(enabled);

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(enabled ? 'Notificaciones activadas.' : 'Notificaciones desactivadas.'), // TEXTO TRADUCIDO
        ),
      );
    } catch (e) {
      developer.log('ERROR toggling notifications in Firestore: $e', name: 'NotificationConfigPage', error: e);
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(content: Text('Error al cambiar estado: $e')), // TEXTO TRADUCIDO
        );
      }
      setState(() {
        _notificationsEnabled = !enabled;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      try {
        if (_userNotificationSettingsRef == null) {
          developer.log('NotificationConfigPage: _userNotificationSettingsRef is null. Cannot save time.', name: 'NotificationConfigPage');
          return;
        }
        final String timeString =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        await _userNotificationSettingsRef!.update({
          'notificationTime': timeString,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        developer.log('NotificationConfigPage: Notification time adjusted to $timeString in Firestore.', name: 'NotificationConfigPage');

        await _notificationService.setNotificationTime(timeString);

        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text('Hora de notificación ajustada a $timeString')), // TEXTO TRADUCIDO
        );
      } catch (e) {
        developer.log('ERROR setting notification time in Firestore: $e', name: 'NotificationConfigPage', error: e);
        if (context.mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('Error al ajustar la hora: $e')), // TEXTO TRADUCIDO
          );
        }
      }
    }
  }

  Future<void> _testNotification() async {
    try {
      await _notificationService.showImmediateNotification(
        'Prueba de Notificación', // TEXTO TRADUCIDO
        '¡Esta es una notificación de prueba desde la aplicación!', // TEXTO TRADUCIDO
        payload: 'test_notification_payload',
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Notificación de prueba enviada.')), // TEXTO TRADUCIDO
      );
    } catch (e) {
      developer.log('ERROR sending test notification: $e', name: 'NotificationConfigPage', error: e);
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(content: Text('Error al enviar la prueba: $e')), // TEXTO TRADUCIDO
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Configuración de Notificaciones', style: TextStyle(color: Colors.white)), // TEXTO TRADUCIDO
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Notificaciones', style: TextStyle(color: Colors.white)), // TEXTO TRADUCIDO
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
                  'Activar Notificaciones', // TEXTO TRADUCIDO
                  style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
                ),
                Switch(
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                  activeColor: colorScheme.primary,
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
                    Icon(Icons.access_time, color: _notificationsEnabled ? colorScheme.primary : colorScheme.onSurface.withAlpha(127)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Hora de la notificación diaria', // TEXTO TRADUCIDO
                        style: textTheme.titleMedium?.copyWith(
                          color: _notificationsEnabled ? colorScheme.onSurface : colorScheme.onSurface.withAlpha(127),
                        ),
                      ),
                    ),
                    Text(
                      _selectedTime.format(context),
                      style: textTheme.titleMedium?.copyWith(
                        color: _notificationsEnabled ? colorScheme.primary : colorScheme.onSurface.withAlpha(127),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: _notificationsEnabled ? colorScheme.onSurface : colorScheme.onSurface.withAlpha(127)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _notificationsEnabled ? _testNotification : null,
              icon: Icon(Icons.notifications_active, color: _notificationsEnabled ? Colors.white : Colors.white.withAlpha(127)),
              label: Text(
                'Enviar Notificación de Prueba', // TEXTO TRADUCIDO
                style: textTheme.titleMedium?.copyWith(
                  color: _notificationsEnabled ? Colors.white : Colors.white.withAlpha(127),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _notificationsEnabled ? colorScheme.primary : colorScheme.primary.withAlpha(127),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
