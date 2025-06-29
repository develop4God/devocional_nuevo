// lib/services/notification_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

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
  static const String _lastNotificationDateKey = 'last_notification_date';
  static const String _deviceTokenKey = 'device_token';

  // Callback para manejar la navegación cuando se toca una notificación
  Function(String? payload)? onNotificationTapped;

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

    // Verificar si es un nuevo día para programar notificación
    await _checkAndScheduleForNewDay();
  }

  /// Manejar cuando se toca una notificación
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    debugPrint('Notificación tocada: ${notificationResponse.payload}');

    // Llamar al callback si está definido
    if (onNotificationTapped != null) {
      onNotificationTapped!(notificationResponse.payload);
    }
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

  /// Verificar si es un nuevo día para programar notificación
  Future<void> _checkAndScheduleForNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final lastNotificationDate = prefs.getString(_lastNotificationDateKey);

    final today = DateTime.now().toIso8601String().split('T')[0];

    if (lastNotificationDate != today) {
      // Es un nuevo día, guardar la fecha actual
      await prefs.setString(_lastNotificationDateKey, today);

      // Si las notificaciones están habilitadas, programar para hoy
      if (await areNotificationsEnabled()) {
        await scheduleDailyNotification();
      }
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

    // Intentar obtener el título del devocional para hoy
    String title = '🙏 Devocional de Hoy';
    String body = 'Tu momento de reflexión diaria te está esperando';

    try {
      // Aquí podrías hacer una petición a tu API para obtener el título del devocional
      // Por ejemplo:
      // final devotionalData = await _fetchDevotionalData();
      // if (devotionalData != null) {
      //   title = '🙏 ${devotionalData['title']}';
      //   body = devotionalData['summary'] ?? body;
      // }
    } catch (e) {
      debugPrint('Error al obtener datos del devocional: $e');
      // Usar los valores por defecto si hay error
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
      styleInformation: BigTextStyleInformation(''),
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
      title,
      body,
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

  /// Mostrar notificación inmediata (para testing o notificaciones manuales)
  Future<void> showImmediateNotification({
    String title = '🙏 Devocional de Hoy',
    String body = 'Tu momento de reflexión diaria te está esperando',
    String? payload,
    String? bigPicture,
  }) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics;

    // Si hay una imagen grande, configurar notificación con estilo BigPicture
    if (bigPicture != null) {
      try {
        final String largeIconPath = await _downloadAndSaveFile(
          bigPicture,
          'largeIcon.png',
        );

        final String bigPicturePath = await _downloadAndSaveFile(
          bigPicture,
          'bigPicture.png',
        );

        androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'immediate_devotional',
          'Devocional Inmediato',
          channelDescription: 'Notificación inmediata del devocional',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          largeIcon: FilePathAndroidBitmap(largeIconPath),
          styleInformation: BigPictureStyleInformation(
            FilePathAndroidBitmap(bigPicturePath),
            hideExpandedLargeIcon: true,
          ),
        );
      } catch (e) {
        debugPrint('Error al configurar notificación con imagen: $e');
        // Si hay error, usar notificación estándar
        androidPlatformChannelSpecifics = const AndroidNotificationDetails(
          'immediate_devotional',
          'Devocional Inmediato',
          channelDescription: 'Notificación inmediata del devocional',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(''),
        );
      }
    } else {
      // Notificación estándar sin imagen
      androidPlatformChannelSpecifics = const AndroidNotificationDetails(
        'immediate_devotional',
        'Devocional Inmediato',
        channelDescription: 'Notificación inmediata del devocional',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(''),
      );
    }

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
    DarwinNotificationDetails(
      sound: 'default',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      attachments: [], // Aquí podrías añadir adjuntos para iOS
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      1, // ID diferente para notificaciones inmediatas
      title,
      body,
      platformChannelSpecifics,
      payload: payload ?? 'immediate_devotional',
    );
  }

  /// Descargar y guardar un archivo desde una URL
  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
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

  /// Guardar token del dispositivo para notificaciones remotas
  Future<void> saveDeviceToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceTokenKey, token);
    debugPrint('Token del dispositivo guardado: $token');
  }

  /// Obtener token del dispositivo
  Future<String?> getDeviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceTokenKey);
  }

  /// Mostrar notificación del devocional diario (para el servicio en segundo plano)
  Future<void> showDailyDevotionalNotification() async {
    // Verificar si las notificaciones están habilitadas
    if (!await areNotificationsEnabled()) {
      debugPrint('Notificaciones deshabilitadas, no se mostrará la notificación diaria');
      return;
    }

    // Obtener título y mensaje para la notificación
    String title = '🙏 Devocional de Hoy';
    String body = 'Tu momento de reflexión diaria te está esperando';

    try {
      // Aquí podrías hacer una petición a tu API para obtener el título del devocional
      // Similar a lo que tienes en scheduleDailyNotification
    } catch (e) {
      debugPrint('Error al obtener datos del devocional: $e');
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
      styleInformation: BigTextStyleInformation(''),
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

    // Mostrar notificación
    await _flutterLocalNotificationsPlugin.show(
      0, // Mismo ID que la notificación programada
      title,
      body,
      platformChannelSpecifics,
      payload: 'daily_devotional',
    );

    debugPrint('Notificación diaria mostrada');

    // Actualizar la fecha de la última notificación
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString(_lastNotificationDateKey, today);
  }
}