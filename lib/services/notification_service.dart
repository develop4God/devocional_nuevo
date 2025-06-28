// lib/services/notification_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Claves para SharedPreferences
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _notificationTimeKey = 'notification_time';
  static const String _defaultNotificationTime = '08:00'; // 8:00 AM por defecto

  /// Inicializar el servicio de notificaciones
  Future<void> initialize() async {
    // Inicializar timezone
    tz.initializeTimeZones();
    
    // Configuración para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración para iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Configuración general
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Inicializar plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Solicitar permisos
    await _requestPermissions();
  }

  /// Manejar cuando se toca una notificación
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    debugPrint('Notificación tocada: ${notificationResponse.payload}');
    // Aquí puedes agregar lógica para navegar a una página específica
    // Por ejemplo, abrir el devocional del día
  }

  /// Solicitar permisos de notificación
  Future<bool> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Para Android 13+ (API 33+)
      final status = await Permission.notification.request();
      return status == PermissionStatus.granted;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Para iOS
      final bool? result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    }
    return true;
  }

  /// Verificar si las notificaciones están habilitadas en configuración
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? false;
  }

  /// Habilitar/deshabilitar notificaciones
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
    
    if (enabled) {
      await scheduleDailyNotification();
    } else {
      await cancelAllNotifications();
    }
  }

  /// Obtener hora de notificación configurada
  Future<String> getNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_notificationTimeKey) ?? _defaultNotificationTime;
  }

  /// Establecer hora de notificación
  Future<void> setNotificationTime(String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationTimeKey, time);
    
    // Si las notificaciones están habilitadas, reprogramar
    if (await areNotificationsEnabled()) {
      await scheduleDailyNotification();
    }
  }

  /// Programar notificación diaria
  Future<void> scheduleDailyNotification() async {
    // Cancelar notificaciones existentes
    await cancelAllNotifications();

    // Obtener hora configurada
    final timeString = await getNotificationTime();
    final timeParts = timeString.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // Crear fecha/hora para la notificación
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Si la hora ya pasó hoy, programar para mañana
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Configuración de la notificación para Android
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'daily_devotional',
      'Devocional Diario',
      channelDescription: 'Recordatorio diario para leer el devocional',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      sound: RawResourceAndroidNotificationSound('notification'),
      enableVibration: true,
    );

    // Configuración de la notificación para iOS
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      sound: 'default',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Configuración general
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Programar notificación
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      0, // ID de la notificación
      '🙏 Devocional de Hoy',
      'Tu momento de reflexión diaria te está esperando',
      scheduledDate,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repetir diariamente
      payload: 'daily_devotional',
    );

    debugPrint('Notificación programada para: $scheduledDate');
  }

  /// Mostrar notificación inmediata (para testing)
  Future<void> showImmediateNotification({
    String title = '🙏 Devocional de Hoy',
    String body = 'Tu momento de reflexión diaria te está esperando',
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'immediate_devotional',
      'Devocional Inmediato',
      channelDescription: 'Notificación inmediata del devocional',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      sound: 'default',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      1, // ID diferente para notificaciones inmediatas
      title,
      body,
      platformChannelSpecifics,
      payload: 'immediate_devotional',
    );
  }

  /// Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('Todas las notificaciones canceladas');
  }

  /// Obtener notificaciones pendientes (para debug)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  /// Verificar si hay permisos de notificación
  Future<bool> hasNotificationPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await Permission.notification.isGranted;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Para iOS, verificar a través del plugin
      return true; // Simplificado, en producción podrías hacer una verificación más robusta
    }
    return true;
  }
}