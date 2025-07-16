// lib/services/notification_service.dart
//notification_service.dart - Save User Timezone to Firestore
//notification_service.dart - Guardar lastLogin en Firestore


import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart'; // Used to get local timezone string

// Importaciones para Firebase Cloud Messaging y Firestore
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Las siguientes importaciones están comentadas porque no se usan en la lógica actual.
// Si las necesitas para futuros métodos (ej. _downloadAndSaveFile), descomenta.
// import 'package:http/http.dart' as http;
// import 'package:path_provider/path_provider.dart';
// import 'dart:io' as io;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _notificationTimeKey = 'notification_time';
  static const String _defaultNotificationTime = '09:00';
  static const String _fcmTokenKey = 'fcm_token';

  Function(String? payload)? onNotificationTapped;

  Future<void> initialize() async {
    try {
      tzdata.initializeTimeZones();
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
      developer.log(
          'NotificationService: tz.local.name: ${tz.local.name}, tz.local.currentTimeZone: ${tz.local.currentTimeZone}',
          name: 'NotificationService');

      // INICIO DEL CAMBIO: Se inicializan las configuraciones directamente en InitializationSettings
      const InitializationSettings initializationSettings =
      InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      );
      // FIN DEL CAMBIO

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      await _requestPermissions();
      developer.log('NotificationService: Initialized',
          name: 'NotificationService');

      // Inicializar FCM y gestionar el token, y configurar los listeners de mensajes
      await _initializeFCM();

      // Manejar el mensaje inicial si la app se abrió desde una notificación
      final RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        developer.log('NotificationService: Aplicación abierta desde notificación inicial: ${initialMessage.messageId}', name: 'NotificationService');
        _handleMessage(initialMessage);
      }

      // NUEVO: Guardar la zona horaria del usuario en Firestore
      await _saveUserTimezoneToFirestore();

    } catch (e) {
      developer.log('ERROR en NotificationService: $e',
          name: 'NotificationService', error: e);
    }
  }

  // Método para inicializar FCM, obtener/guardar token y configurar listeners
  Future<void> _initializeFCM() async {
    try {
      // Solicitar permiso para notificaciones (iOS y Android 13+)
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      developer.log('NotificationService: Permiso de usuario concedido: ${settings.authorizationStatus}', name: 'NotificationService');

      // Obtener el token FCM
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        developer.log('NotificationService: Token FCM obtenido: $token', name: 'NotificationService');
        await _saveFcmToken(token); // Guardar token en Firestore
      } else {
        developer.log('NotificationService: El token FCM es nulo.', name: 'NotificationService');
      }

      // Escuchar cambios en el token
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        developer.log('NotificationService: Token FCM refrescado: $newToken', name: 'NotificationService');
        _saveFcmToken(newToken); // Actualizar token en Firestore
      });

      // NUEVO: Listener para mensajes FCM cuando la app está en primer plano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        developer.log('NotificationService: Mensaje FCM en primer plano: ${message.messageId}', name: 'NotificationService');
        _handleMessage(message);
      });

      // NUEVO: Listener para cuando el usuario toca una notificación FCM
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        developer.log('NotificationService: Aplicación abierta desde notificación: ${message.messageId}', name: 'NotificationService');
        _handleMessage(message);
      });

    } catch (e) {
      developer.log('ERROR en _initializeFCM: $e', name: 'NotificationService', error: e);
    }
  }

  // NUEVO: Método para manejar mensajes FCM y mostrarlos localmente
  void _handleMessage(RemoteMessage message) {
    if (message.notification != null) {
      developer.log('NotificationService: Mensaje FCM contiene notificación: ${message.notification!.title}', name: 'NotificationService');
      showImmediateNotification(
        message.notification!.title ?? 'Notificación',
        message.notification!.body ?? 'Contenido de la notificación',
        payload: message.data['payload'] as String?,
        id: message.messageId.hashCode, // Usar un ID único para la notificación local
      );
    } else if (message.data.isNotEmpty) {
      developer.log('NotificationService: Mensaje FCM contiene solo datos: ${message.data}', name: 'NotificationService');
      // Puedes procesar mensajes de datos aquí si no tienen una sección de notificación.
      // Por ejemplo, mostrar una notificación local personalizada basada en los datos.
      showImmediateNotification(
        message.data['title'] ?? 'Notificación de Datos',
        message.data['body'] ?? 'Contenido de datos',
        payload: message.data['payload'] as String?,
        id: message.messageId.hashCode,
      );
    }
  }

  // Método para guardar el token FCM en Firestore
  Future<void> _saveFcmToken(String token) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        developer.log('NotificationService: Usuario no autenticado, no se puede guardar el token FCM.', name: 'NotificationService');
        return;
      }

      // Añadir el campo lastLogin al documento principal del usuario
      final userDocRef = _firestore.collection('users').doc(user.uid);
      await userDocRef.set({
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Usar merge para no sobrescribir subcolecciones

      final tokenRef = userDocRef.collection('fcmTokens').doc(token);

      await tokenRef.set({
        'token': token,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.toString(),
      }, SetOptions(merge: true));

      developer.log('NotificationService: Token FCM y lastLogin guardados en Firestore para el usuario ${user.uid}', name: 'NotificationService');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);
      developer.log('NotificationService: Token FCM guardado en SharedPreferences.', name: 'NotificationService');

    } catch (e) {
      developer.log('ERROR en _saveFcmToken: $e', name: 'NotificationService', error: e);
    }
  }

  // NUEVO MÉTODO: Guardar la zona horaria del usuario en Firestore
  Future<void> _saveUserTimezoneToFirestore() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        developer.log('NotificationService: Usuario no autenticado, no se puede guardar la zona horaria.', name: 'NotificationService');
        return;
      }

      final String userTimezone = await FlutterTimezone.getLocalTimezone();
      final settingsRef = _firestore.collection('users').doc(user.uid).collection('settings').doc('notifications');

      await settingsRef.set({
        'userTimezone': userTimezone,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Usa merge para no sobrescribir otras configuraciones

      developer.log('NotificationService: Zona horaria del usuario ($userTimezone) guardada en Firestore para el usuario ${user.uid}', name: 'NotificationService');
    } catch (e) {
      developer.log('ERROR en _saveUserTimezoneToFirestore: $e', name: 'NotificationService', error: e);
    }
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    developer.log('Notificación tocada: ${notificationResponse.payload}',
        name: 'NotificationService');
    if (onNotificationTapped != null) {
      onNotificationTapped!(notificationResponse.payload);
    }
  }

  Future<bool> _requestPermissions() async {
    try {
      bool granted = true;
      if (defaultTargetPlatform == TargetPlatform.android) {
        final notificationStatus = await Permission.notification.request();
        granted = granted && notificationStatus == PermissionStatus.granted;

        if (await Permission.scheduleExactAlarm.isDenied) {
          final alarmStatus = await Permission.scheduleExactAlarm.request();
          granted = granted && alarmStatus == PermissionStatus.granted;
        }

        if (await Permission.ignoreBatteryOptimizations.isDenied) {
          final batteryStatus =
          await Permission.ignoreBatteryOptimizations.request();
          granted = granted && batteryStatus == PermissionStatus.granted;
        }
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final bool? result = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        granted = result ?? false;
      }
      developer.log('NotificationService: Permisos concedidos: $granted',
          name: 'NotificationService');
      return granted;
    } catch (e) {
      developer.log('ERROR en _requestPermissions: $e',
          name: 'NotificationService', error: e);
      return false;
    }
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
    developer.log('NotificationService: Notificaciones activadas establecidas en $enabled',
        name: 'NotificationService');

    // Guardar el estado de las notificaciones en Firestore
    final User? user = _auth.currentUser;
    if (user != null) {
      final settingsRef = _firestore.collection('users').doc(user.uid).collection('settings').doc('notifications');
      await settingsRef.set({
        'notificationsEnabled': enabled, // Guardar el estado 'enabled'
        'lastUpdated': FieldValue.serverTimestamp(), // Opcional: actualizar la marca de tiempo
      }, SetOptions(merge: true)); // Usar merge para no sobrescribir otros campos
      developer.log('NotificationService: Estado de notificaciones ($enabled) guardado en Firestore para el usuario ${user.uid}', name: 'NotificationService');
    }

    // IMPORTANTE: Las llamadas a scheduleDailyNotification() y cancelScheduledNotifications()
    // se eliminan de aquí. La programación diaria ahora se gestiona desde el servidor (Cloud Function)
    // a través de FCM.
    // if (enabled) {
    //   await scheduleDailyNotification();
    // } else {
    //   await cancelScheduledNotifications();
    // }
  }

  Future<String> getNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_notificationTimeKey) ?? _defaultNotificationTime;
  }

  Future<void> setNotificationTime(String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationTimeKey, time);
    developer.log('NotificationService: Hora de notificación establecida en $time',
        name: 'NotificationService');
    // IMPORTANTE: La llamada a scheduleDailyNotification() se elimina de aquí.
    // La programación diaria ahora se gestiona desde el servidor (Cloud Function)
    // a través de FCM.
    // if (await areNotificationsEnabled()) {
    //   await scheduleDailyNotification();
    // }
  }

  Future<void> showImmediateNotification(String title, String body,
      {String? payload, int? id}) async {
    try {
      AndroidNotificationDetails? androidPlatformChannelSpecifics;

      if (defaultTargetPlatform == TargetPlatform.android) {
        androidPlatformChannelSpecifics = const AndroidNotificationDetails(
          'immediate_devotional',
          'Devocional Inmediato',
          channelDescription: 'Notificación inmediata del devocional',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(''),
        );
      } else {
        androidPlatformChannelSpecifics = const AndroidNotificationDetails(
          'immediate_devotional',
          'Devocional Inmediato',
          channelDescription: 'Notificación inmediata del devocional',
          importance: Importance.max,
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
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        id ?? 1,
        title,
        body,
        platformChannelSpecifics,
        payload: payload ?? 'immediate_devotional',
      );
      developer.log('Notificación inmediata mostrada: $title',
          name: 'NotificationService');
    } catch (e) {
      developer.log('ERROR en showImmediateNotification: $e',
          name: 'NotificationService', error: e);
    }
  }

  // Esta función ahora solo se usa para mostrar la notificación localmente
  // cuando el backend (Cloud Function) envía un mensaje FCM.
  // Ya NO se usa para programar la notificación diaria desde la app.
  Future<void> scheduleDailyNotification() async {
    // La lógica de cancelación y programación se mantiene si se necesita para otros fines locales,
    // pero para la notificación diaria, el servidor es el que orquesta.
    await cancelScheduledNotifications();

    final String timeString = await getNotificationTime();
    final List<String> timeParts = timeString.split(':');
    final int hour = int.parse(timeParts[0]);
    final int minute = int.parse(timeParts[1]);

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    developer.log(
        'NotificationService: tz.TZDateTime.now(tz.local) obtenido: $now',
        name: 'NotificationService');
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    developer.log(
        'NotificationService: Fecha programada final para notificación diaria: $scheduledDate',
        name: 'NotificationService');

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'daily_devotional',
      'Devocional Diario',
      channelDescription: 'Recordatorio diario para leer el devocional',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      sound: RawResourceAndroidNotificationSound('notification'),
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
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

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Recordatorio Diario',
      '¡Es hora de tu devocional diario!',
      scheduledDate,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_devotional_payload',
    );
    developer.log('Notificación diaria programada para: $scheduledDate',
        name: 'NotificationService');
  }

  Future<void> cancelScheduledNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    developer.log(
        'NotificationService: Todas las notificaciones programadas canceladas',
        name: 'NotificationService');
  }

// Métodos que estaban en tu archivo pero no se usan actualmente
// Si los necesitas, asegúrate de que las importaciones (http, path_provider, io) estén activas.
// Future<void> _checkAndSetLastNotificationDate() async {
//   final prefs = await SharedPreferences.getInstance();
//   final lastNotificationDate = prefs.getString(_lastNotificationDateKey);
//   final today = DateTime.now().toIso8601String().split('T')[0];

//   if (lastNotificationDate != today) {
//     await scheduleDailyNotification();
//     await prefs.setString(_lastNotificationDateKey, today);
//   }
// }

// Future<String> _downloadAndSaveFile(String url, String fileName) async {
//   final io.Directory directory = await getApplicationDocumentsDirectory();
//   final String filePath = '${directory.path}/$fileName';
//   final http.Response response = await http.get(Uri.parse(url));
//   final io.File file = io.File(filePath);
//   await file.writeAsBytes(response.bodyBytes);
//   developer.log('File downloaded and saved: $filePath', name: 'NotificationService');
//   return filePath;
// }
}
