// lib/pages/notification_config_page.dart

import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/services/notification_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/devocionales/app_bar_constants.dart';
// NEW IMPORTS for Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationConfigPage extends StatefulWidget {
  const NotificationConfigPage({super.key});

  @override
  State<NotificationConfigPage> createState() => _NotificationConfigPageState();
}

class _NotificationConfigPageState extends State<NotificationConfigPage> {
  late final NotificationService _notificationService;
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
    // Get NotificationService from ServiceLocator
    _notificationService = getService<NotificationService>();
    _initializeFirebaseAndLoadSettings();
  }

  Future<void> _initializeFirebaseAndLoadSettings() async {
    final user = _auth.currentUser;
    if (user == null) {
      developer.log(
        'NotificationConfigPage: User not authenticated. Cannot load/save settings.',
        name: 'NotificationConfigPage',
      );
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        // ACCIÓN: Ajuste del SnackBar para usar colorScheme.secondary y onSecondary
        final ColorScheme colorScheme = Theme.of(
          context,
        ).colorScheme; // Obtener colorScheme
        messenger.showSnackBar(
          SnackBar(
            backgroundColor:
                colorScheme.secondary, // Fondo del SnackBar usando secondary
            content: Text(
              'notifications_config_page.user_not_authenticated'.tr(),
              // TEXTO TRADUCIDO
              style: TextStyle(
                color: colorScheme.onSecondary,
              ), // Texto del SnackBar usando onSecondary
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
          name: 'NotificationConfigPage',
        );
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
          minute: int.parse(timeString.split(':')[1]),
        );
        developer.log(
          'NotificationConfigPage: Settings loaded from Firestore. Enabled: $_notificationsEnabled, Time: $timeString',
          name: 'NotificationConfigPage',
        );

        // Si se usó un valor por defecto para notificationTime, guárdalo en Firestore
        if (shouldUpdateFirestore) {
          await _userNotificationSettingsRef!.update({
            'notificationTime': timeString,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
          developer.log(
            'NotificationConfigPage: notificationTime was missing, updated Firestore with default: $timeString',
            name: 'NotificationConfigPage',
          );
        }
        // FIN DEL AJUSTE 1
      } else {
        // INICIO DEL AJUSTE 2: Si el documento de configuración no existe en absoluto, créalo con valores por defecto
        _notificationsEnabled =
            true; // Por defecto, activar las notificaciones en la primera instalación si no hay datos.
        String timeString = await _notificationService
            .getNotificationTime(); // Obtiene la hora por defecto (ej. 09:00)
        final parts = timeString.split(':');
        _selectedTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );

        await _userNotificationSettingsRef!.set({
          // Crea el documento
          'notificationsEnabled': _notificationsEnabled,
          'notificationTime': timeString, // Guarda la hora por defecto aquí
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        developer.log(
          'NotificationConfigPage: No settings found in Firestore. Defaults applied and saved. Enabled: $_notificationsEnabled, Time: $timeString',
          name: 'NotificationConfigPage',
        );
      } // FIN DEL AJUSTE 2
      // Inicializa _newlySelectedTime con la hora actual al cargar
      _newlySelectedTime = _selectedTime;
    } catch (e) {
      developer.log(
        'ERROR loading notification settings from Firestore: $e',
        name: 'NotificationConfigPage',
        error: e,
      );
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        // ACCIÓN: Ajuste del SnackBar para usar colorScheme.secondary y onSecondary
        final ColorScheme colorScheme = Theme.of(
          context,
        ).colorScheme; // Obtener colorScheme
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: colorScheme.secondary,
            content: Text(
              'notifications_config_page.error_loading_settings'.tr({
                'error': e.toString(),
              }),
              // Corregido el mensaje de error para mostrar 'e'
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
          name: 'NotificationConfigPage',
        );
        return;
      }
      await _userNotificationSettingsRef!.update({
        'notificationsEnabled': enabled,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      developer.log(
        'NotificationConfigPage: Notifications enabled set to $enabled in Firestore.',
        name: 'NotificationConfigPage',
      );

      await _notificationService.setNotificationsEnabled(enabled);

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      // ACCIÓN: Ajuste del SnackBar para usar colorScheme.secondary y onSecondary
      final ColorScheme colorScheme = Theme.of(
        context,
      ).colorScheme; // Obtener colorScheme
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.secondary,
          content: Text(
            _notificationsEnabled
                ? 'notifications_config_page.notifications_enabled'.tr()
                : 'notifications_config_page.notifications_disabled'.tr(),
            // Usando _notificationsEnabled
            style: TextStyle(color: colorScheme.onSecondary),
          ),
        ),
      );
    } catch (e) {
      developer.log(
        'ERROR toggling notifications in Firestore: $e',
        name: 'NotificationConfigPage',
        error: e,
      );
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        // ACCIÓN: Ajuste del SnackBar para usar colorScheme.secondary y onSecondary
        final ColorScheme colorScheme = Theme.of(
          context,
        ).colorScheme; // Obtener colorScheme
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: colorScheme.secondary,
            content: Text(
              'notifications_config_page.error_changing_state'.tr({
                'error': e.toString(),
              }), // TEXTO TRADUCIDO
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
        name: 'NotificationConfigPage',
      );
      return;
    }

    // No permitir guardar si la hora no ha cambiado
    if (_newlySelectedTime == _selectedTime) {
      developer.log(
        'NotificationConfigPage: Time not changed, no need to save.',
        name: 'NotificationConfigPage',
      );
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        // ACCIÓN: Ajuste del SnackBar para usar colorScheme.secondary y onSecondary
        final ColorScheme colorScheme = Theme.of(
          context,
        ).colorScheme; // Obtener colorScheme
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: colorScheme.secondary,
            content: Text(
              'notifications_config_page.time_not_changed'
                  .tr(), // MENSAJE SI HORA NO CAMBIA
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
        name: 'NotificationConfigPage',
      );

      await _notificationService.setNotificationTime(timeString);

      if (!mounted) return;
      setState(() {
        _selectedTime = _newlySelectedTime!; // Actualiza la hora principal
        _newlySelectedTime = null; // Resetea la hora nueva después de guardar
      });
      final messenger = ScaffoldMessenger.of(context);
      // ACCIÓN: Ajuste del SnackBar para usar colorScheme.secondary y onSecondary
      final ColorScheme colorScheme = Theme.of(
        context,
      ).colorScheme; // Obtener colorScheme
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.secondary,
          content: Text(
            '${'notifications_config_page.notification_set'.tr()} $timeString',
            style: TextStyle(color: colorScheme.onSecondary),
          ),
        ),
      );
    } catch (e) {
      developer.log(
        'ERROR setting notification time in Firestore: $e',
        name: 'NotificationConfigPage',
        error: e,
      );
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        // ACCIÓN: Ajuste del SnackBar para usar colorScheme.secondary y onSecondary
        final ColorScheme colorScheme = Theme.of(
          context,
        ).colorScheme; // Obtener colorScheme
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: colorScheme.secondary,
            content: Text(
              'notifications_config_page.error_setting_time'.tr({
                'error': e.toString(),
              }), // TEXTO TRADUCIDO
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

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;

    // Determine if confirm button should be enabled
    bool isConfirmButtonEnabled =
        _newlySelectedTime != null && _newlySelectedTime != _selectedTime;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeState.systemUiOverlayStyle,
      child: Scaffold(
        appBar: CustomAppBar(
          titleText: 'notifications_config_page.notifications_config'.tr(),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'notifications_config_page.enable_notifications'.tr(),
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Switch(
                          value: _notificationsEnabled,
                          onChanged: _toggleNotifications,
                          activeTrackColor: colorScheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: _notificationsEnabled
                          ? () => _selectTime(context)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: _notificationsEnabled
                                  ? colorScheme.primary
                                  : colorScheme.onSurface.withAlpha(127),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'notifications_config_page.notification_time'
                                    .tr(),
                                style: textTheme.titleMedium?.copyWith(
                                  color: _notificationsEnabled
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurface.withAlpha(127),
                                ),
                              ),
                            ),
                            // Show temporary selected time if present, otherwise saved time
                            Text(
                              (_newlySelectedTime ?? _selectedTime).format(
                                context,
                              ),
                              style: textTheme.titleMedium?.copyWith(
                                color: _notificationsEnabled
                                    ? colorScheme.primary
                                    : colorScheme.onSurface.withAlpha(127),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: _notificationsEnabled
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurface.withAlpha(127),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed:
                          (_notificationsEnabled && isConfirmButtonEnabled)
                              ? _confirmSelectedTime
                              : null,
                      icon: Icon(
                        Icons.schedule_send_outlined,
                        size: 30,
                        color: (_notificationsEnabled && isConfirmButtonEnabled)
                            ? Colors.white
                            : Colors.white.withAlpha(127),
                      ),
                      label: Text(
                        'notifications_config_page.notification_confirm'.tr(),
                        style: textTheme.titleMedium?.copyWith(
                          color:
                              (_notificationsEnabled && isConfirmButtonEnabled)
                                  ? Colors.white
                                  : Colors.white.withAlpha(127),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            (_notificationsEnabled && isConfirmButtonEnabled)
                                ? colorScheme.primary
                                : colorScheme.primary.withAlpha(127),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
