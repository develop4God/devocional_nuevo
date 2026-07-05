// lib/services/notification_service.dart
//notification_service.dart - Save User Timezone to Firestore
//notification_service.dart - Guardar lastLogin en Firestore
//notification_service.dart (Ajuste FCM y Autenticación para que no haya usuario nulo)
//notification_service.dart (Ajuste de Permisos)
//
// NotificationService - Migrated to Dependency Injection
// This service manages Firebase Cloud Messaging (FCM), local notifications,
// and notification settings. It is registered in ServiceLocator as a lazy
// singleton for better testability and maintainability.
//
// IMPORTANT: Private Constructor Pattern
// Direct instantiation is prevented to enforce DI usage.
// The constructor is private and can only be accessed via the factory method.
//
// Usage:
//   final notificationService = getService<NotificationService>();
//   await notificationService.initialize();
//
// DO NOT attempt direct instantiation:
//   ❌ final service = NotificationService(); // COMPILE ERROR - constructor is private
//
// ALWAYS use ServiceLocator:
//   ✅ final service = getService<NotificationService>();
//   ✅ final service = ServiceLocator().get<NotificationService>();

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Importaciones para Firebase Cloud Messaging y Firestore
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart'; // Used to get local timezone string
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart'
    as tzdata; // Importado con alias tzdata
import 'package:timezone/timezone.dart' as tz;

// **INICIO DE MODIFICACIÓN: Nueva función de nivel superior para el background handler**
// Esta función debe estar fuera de cualquier clase.
@pragma('vm:entry-point')
void flutterLocalNotificationsBackgroundHandler(
  NotificationResponse notificationResponse,
) async {
  debugLog(
    '🔔 [NotificationService] Background notification response: ${notificationResponse.payload}',
  );
  // Puedes añadir lógica adicional aquí si necesitas procesar la notificación en segundo plano.
  // Por ejemplo, navegar a una pantalla específica o actualizar el estado de la aplicación.
  // Asegúrate de que cualquier inicialización de Firebase o servicios se haga aquí si es necesario.
}
// **FIN DE MODIFICACIÓN**

class NotificationService {
  // Private constructor to prevent direct instantiation
  // Always use getService<NotificationService>() or ServiceLocator.get<NotificationService>()
  NotificationService._();

  // Factory constructor for ServiceLocator registration
  factory NotificationService.create() => NotificationService._();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _notificationTimeKey = 'notification_time';
  static const String _defaultNotificationTime = '09:00';
  static const String _fcmTokenKey = 'fcm_token';

  // FCM token retrieval: the plugin reports transient network / Play Services
  // errors only as text in the message (code: 'unknown'), so they are
  // detected by substring.
  static const int _maxTokenAttempts = 3;
  static const String _transientTokenError = 'SERVICE_NOT_AVAILABLE';
  static const Duration _transientRetryBase = Duration(seconds: 2);
  static const Duration _tokenRetryBase = Duration(milliseconds: 600);

  Function(String? payload)? onNotificationTapped;

  /// NUEVO: Actualiza el campo lastLogin cada vez que el usuario ingresa a la app
  Future<void> updateLastLogin() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final userDocRef = _firestore.collection('users').doc(user.uid);
      await userDocRef.set({
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugLog(
        '🔔 [NotificationService] lastLogin updated for user ${user.uid}',
      );
    }
  }

  Future<void> initialize() async {
    try {
      // Usar tzdata.initializeTimeZones() como se ha confirmado que funciona
      tzdata.initializeTimeZones();
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
      debugLog(
        '🔔 [NotificationService] tz.local.name: ${tz.local.name}, tz.local.currentTimeZone: ${tz.local.currentTimeZone}',
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) =>
            _onNotificationTapped(details),
        // **INICIO DE MODIFICACIÓN: Referenciar la nueva función de nivel superior**
        onDidReceiveBackgroundNotificationResponse:
            flutterLocalNotificationsBackgroundHandler,
        // **FIN DE MODIFICACIÓN**
      );

      await _requestPermissions();
      debugLog('🔔 [NotificationService] Initialized');

      // **INICIO DE MODIFICACIÓN: Escuchar cambios de autenticación antes de inicializar FCM y guardar settings**
      // Esto asegura que haya un usuario (UID) disponible antes de intentar guardar tokens o settings.
      // Se elimina la llamada directa a _initializeFCM() y la lógica de settings de aquí.
      _auth.authStateChanges().listen((user) async {
        if (user != null) {
          debugLog(
            '🔔 [NotificationService] Authenticated user detected: ${user.uid}',
          );

          // Actualizar lastLogin cada vez que el usuario ingresa
          await updateLastLogin();

          // Ahora, inicializar FCM y gestionar el token solo si hay un usuario
          await _initializeFCM();

          // Manejar el mensaje inicial si la app se abrió desde una notificación
          final RemoteMessage? initialMessage =
              await _firebaseMessaging.getInitialMessage();
          if (initialMessage != null) {
            debugLog(
              '🔔 [NotificationService] App opened from initial notification: ${initialMessage.messageId}',
            );
            _handleMessage(initialMessage);
          }

          // Asegurar que la configuración de notificaciones esté completa en Firestore
          final userId = user.uid;
          final currentDeviceTimezone =
              await FlutterTimezone.getLocalTimezone();

          final settingsDoc = await _firestore
              .collection('users')
              .doc(userId)
              .collection('settings')
              .doc('notifications')
              .get();

          bool initialNotificationsEnabled = settingsDoc.exists
              ? (settingsDoc.data()?['notificationsEnabled'] ?? true)
              : true;
          String initialNotificationTime = settingsDoc.exists
              ? (settingsDoc.data()?['notificationTime'] ??
                  _defaultNotificationTime)
              : _defaultNotificationTime;
          String initialUserTimezone = settingsDoc.exists
              ? (settingsDoc.data()?['userTimezone'] ?? currentDeviceTimezone)
              : currentDeviceTimezone;

          await _saveNotificationSettingsToFirestore(
            userId,
            initialNotificationsEnabled,
            initialNotificationTime,
            initialUserTimezone,
          );
        } else {
          debugLog('🔔 [NotificationService] No authenticated user.');
        }
      });
      // **FIN DE MODIFICACIÓN**
    } catch (e) {
      debugLog('❌ [NotificationService] ERROR in initialize: $e');
    }
  }

  // Método para inicializar FCM, obtener/guardar token y configurar listeners
  Future<void> _initializeFCM() async {
    try {
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugLog(
        '🔔 [NotificationService] User permission granted: ${settings.authorizationStatus}',
      );
      String? token;
      for (int attempt = 1; attempt <= _maxTokenAttempts; attempt++) {
        final stopwatch = Stopwatch()..start();
        try {
          token = await _firebaseMessaging.getToken();
          if (token != null) {
            debugLog(
              '🔔 [NotificationService] FCM token obtained on attempt $attempt: $token',
            );
            break;
          } else {
            debugLog(
              '🔔 [NotificationService] FCM token null on attempt $attempt',
            );
          }
        } catch (e) {
          final msg = e.toString();
          final details = e is FirebaseException
              ? 'plugin: ${e.plugin}, code: ${e.code}, message: ${e.message}'
              : 'type: ${e.runtimeType}';
          debugLog(
            '❌ [NotificationService] Error obtaining token '
            '(attempt $attempt, ${stopwatch.elapsedMilliseconds}ms, $details): $msg',
          );
          if (attempt < _maxTokenAttempts) {
            // Longer backoff for transient network errors.
            final base = msg.contains(_transientTokenError)
                ? _transientRetryBase
                : _tokenRetryBase;
            await Future.delayed(base * attempt);
            continue;
          }
          // Do not rethrow: continue so the listeners get registered.
          // onTokenRefresh will deliver the token once connectivity returns.
        }
        if (token == null && attempt < _maxTokenAttempts) {
          await Future.delayed(_tokenRetryBase * attempt);
        }
      }
      if (token != null) {
        await _saveFcmToken(token);
      } else {
        debugLog(
          '🔔 [NotificationService] Could not obtain FCM token after $_maxTokenAttempts attempts (token still null).',
        );
      }
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugLog('🔔 [NotificationService] FCM token refreshed: $newToken');
        _saveFcmToken(newToken);
      });
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugLog(
          '🔔 [NotificationService] Foreground FCM message: ${message.messageId}',
        );
        _handleMessage(message);
      });
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugLog(
          '🔔 [NotificationService] App opened from notification: ${message.messageId}',
        );
        _handleMessage(message);
      });
      // Verification runs in _saveNotificationSettingsToFirestore, after the
      // settings document exists; verifying here would report null settings.
    } catch (e) {
      debugLog('❌ [NotificationService] ERROR in _initializeFCM: $e');
    }
  }

  // NUEVO: Método para manejar mensajes FCM y mostrarlos localmente
  void _handleMessage(RemoteMessage message) {
    // Solo procesar si el mensaje contiene una sección de notificación o datos relevantes
    if (message.notification != null || message.data.isNotEmpty) {
      debugLog(
        '🔔 [NotificationService] FCM message received. ID: ${message.messageId}',
      );

      // Si el mensaje FCM ya contiene una sección 'notification', el sistema operativo
      // ya la mostrará automáticamente. No necesitamos mostrar una notificación local adicional
      // a menos que queramos personalizarla o añadir lógica específica.
      // Si quieres que FCM maneje la visualización por sí mismo, no llames a showImmediateNotification aquí.

      // Si el mensaje es de solo datos y quieres mostrar una notificación:
      if (message.notification == null && message.data.isNotEmpty) {
        debugLog(
          '🔔 [NotificationService] Data-only FCM message, showing local notification.',
        );
        showImmediateNotification(
          message.data['title'] ?? 'Notificación de Datos',
          message.data['body'] ?? 'Contenido de datos',
          payload: message.data['payload'] as String?,
          id: message.messageId.hashCode,
        );
      }
      // Si el mensaje tiene una sección de notificación, el SO ya la mostró.
      // Aquí puedes manejar la lógica de navegación o actualización de UI si es necesario,
      // pero no mostrar otra notificación local.
      else if (message.notification != null) {
        debugLog(
          '🔔 [NotificationService] FCM message contains notification (already shown by the OS).',
        );
        // Aquí podrías añadir lógica para manejar el payload o navegar
        // if (onNotificationTapped != null && message.data['payload'] != null) {
        //   onNotificationTapped!(message.data['payload'] as String?);
        // }
      }
    }
  }

  // Método para guardar el token FCM en Firestore
  Future<void> _saveFcmToken(String token) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        debugLog(
          '🔔 [NotificationService] User not authenticated, cannot save FCM token.',
        );
        return;
      }

      final userDocRef = _firestore.collection('users').doc(user.uid);

      // Añadir el campo lastLogin al documento principal del usuario
      // Eliminado para evitar duplicidad
      // await userDocRef.set(
      //   {'lastLogin': FieldValue.serverTimestamp()},
      //   SetOptions(merge: true),
      // ); // Usar merge para no sobrescribir subcolecciones

      final tokenRef = userDocRef.collection('fcmTokens').doc(token);

      await tokenRef.set({
        'token': token,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.toString(),
      }, SetOptions(merge: true));

      debugLog(
        '🔔 [NotificationService] FCM token saved to Firestore for user ${user.uid}',
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);
      debugLog(
        '🔔 [NotificationService] FCM token saved to SharedPreferences.',
      );
    } catch (e) {
      debugLog('❌ [NotificationService] ERROR in _saveFcmToken: $e');
    }
  }

  // **INICIO DE MODIFICACIÓN: Método unificado para guardar TODA la configuración de notificaciones**
  // Este método reemplaza la lógica de _saveUserTimezoneToFirestore y es el punto central para guardar.
  Future<void> _saveNotificationSettingsToFirestore(
    String userId,
    bool notificationsEnabled,
    String notificationTime,
    String userTimezone,
  ) async {
    try {
      String currentLanguage = await _getCurrentAppLanguage();
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('notifications');
      await docRef.set({
        'notificationsEnabled': notificationsEnabled,
        'notificationTime': notificationTime,
        'userTimezone': userTimezone,
        'lastUpdated': FieldValue.serverTimestamp(),
        'preferredLanguage': currentLanguage,
      }, SetOptions(merge: true));
      debugLog(
        '🔔 [NotificationService] Notification settings saved for $userId: Enabled: $notificationsEnabled, Time: $notificationTime, Timezone: $userTimezone, Language: $currentLanguage',
      );
      // Verificación tras guardar configuración
      await verifyNotificationSetup();
    } catch (e) {
      debugLog(
        '❌ [NotificationService] Error saving notification settings for user $userId: $e',
      );
    }
  }

  // **FIN DE MODIFICACIÓN**

  // **INICIO DE MODIFICACIÓN: Método _saveUserTimezoneToFirestore comentado**
  // NUEVO MÉTODO: Guardar la zona horaria del usuario en Firestore
  // Future<void> _saveUserTimezoneToFirestore() async {
  //   try {
  //     final User? user = _auth.currentUser;
  //     if (user == null) {
  //       developer.log('NotificationService: Usuario no autenticado, no se puede guardar la zona horaria.', name: 'NotificationService');
  //       return;
  //     }

  //     final String userTimezone = await FlutterTimezone.getLocalTimezone();
  //     final settingsRef = _firestore.collection('users').doc(user.uid).collection('settings').doc('notifications');

  //     await settingsRef.set({
  //       'userTimezone': userTimezone,
  //       'lastUpdated': FieldValue.serverTimestamp(),
  //     }, SetOptions(merge: true)); // Usa merge para no sobrescribir otras configuraciones

  //     developer.log('NotificationService: Zona horaria del usuario ($userTimezone) guardada en Firestore para el usuario ${user.uid}', name: 'NotificationService');
  //   } catch (e) {
  //     developer.log('ERROR en _saveUserTimezoneToFirestore: $e', name: 'NotificationService', error: e);
  //   }
  // }
  // **FIN DE MODIFICACIÓN**

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    debugLog(
      '🔔 [NotificationService] Notification tapped: ${notificationResponse.payload}',
    );
    if (onNotificationTapped != null) {
      onNotificationTapped!(notificationResponse.payload);
    }
  }

  Future<bool> _requestPermissions() async {
    try {
      // **INICIO DE MODIFICACIÓN: Ajuste para reportar permisos con precisión**
      bool allPermissionsGranted =
          true; // Variable para rastrear si todos los permisos fueron concedidos

      if (defaultTargetPlatform == TargetPlatform.android) {
        final notificationStatus = await Permission.notification.request();
        allPermissionsGranted = allPermissionsGranted &&
            (notificationStatus == PermissionStatus.granted);

        if (await Permission.scheduleExactAlarm.isDenied) {
          final alarmStatus = await Permission.scheduleExactAlarm.request();
          allPermissionsGranted = allPermissionsGranted &&
              (alarmStatus == PermissionStatus.granted);
        }

        if (await Permission.ignoreBatteryOptimizations.isDenied) {
          final batteryStatus =
              await Permission.ignoreBatteryOptimizations.request();
          allPermissionsGranted = allPermissionsGranted &&
              (batteryStatus == PermissionStatus.granted);
        }
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final bool? result = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        allPermissionsGranted = result ??
            false; // Para iOS, el resultado directo de requestPermissions
      }
      debugLog(
        '🔔 [NotificationService] Permissions granted: $allPermissionsGranted',
      );
      return allPermissionsGranted; // Retorna el estado combinado de todos los permisos
      // **FIN DE MODIFICACIÓN**
    } catch (e) {
      debugLog('❌ [NotificationService] ERROR in _requestPermissions: $e');
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
    debugLog(
        '🔔 [NotificationService] Notifications enabled set to $enabled');

    // **INICIO DE MODIFICACIÓN: Usar el método unificado para guardar el estado en Firestore**
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        // Obtener la hora de notificación actual y la zona horaria para mantener la consistencia
        final settingsDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('notifications')
            .get();
        String currentNotificationTime =
            settingsDoc.data()?['notificationTime'] ?? _defaultNotificationTime;
        String currentUserTimezone = settingsDoc.data()?['userTimezone'] ??
            await FlutterTimezone.getLocalTimezone();

        await _saveNotificationSettingsToFirestore(
          user.uid,
          enabled, // El nuevo estado de habilitado
          currentNotificationTime, // La hora actual (sin cambios aquí)
          currentUserTimezone, // La zona horaria actual (sin cambios aquí)
        );
        debugLog(
          '🔔 [NotificationService] Notifications enabled ($enabled) saved to Firestore for user ${user.uid}',
        );
      } catch (e) {
        debugLog(
          '❌ [NotificationService] ERROR in setNotificationsEnabled saving to Firestore: $e',
        );
      }
    }
    // **FIN DE MODIFICACIÓN**

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
    debugLog('🔔 [NotificationService] Notification time set to $time');

    // **INICIO DE MODIFICACIÓN: Usar el método unificado para guardar la hora en Firestore**
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        // Obtener el estado actual de notificaciones habilitadas y la zona horaria
        final settingsDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('notifications')
            .get();
        bool currentNotificationsEnabled =
            settingsDoc.data()?['notificationsEnabled'] ??
                true; // Por defecto true si no existe
        String currentUserTimezone = settingsDoc.data()?['userTimezone'] ??
            await FlutterTimezone.getLocalTimezone();

        await _saveNotificationSettingsToFirestore(
          user.uid,
          currentNotificationsEnabled,
          // El estado de habilitado actual (sin cambios aquí)
          time, // La nueva hora
          currentUserTimezone, // La zona horaria actual (sin cambios aquí)
        );
        debugLog(
          '🔔 [NotificationService] Notification time ($time) saved to Firestore for user ${user.uid}',
        );
      } catch (e) {
        debugLog(
          '❌ [NotificationService] ERROR in setNotificationTime saving to Firestore: $e',
        );
      }
    }
    // **FIN DE MODIFICACIÓN**

    // IMPORTANTE: La llamada a scheduleDailyNotification() se elimina de aquí.
    // La programación diaria ahora se gestiona desde el servidor (Cloud Function)
    // a través de FCM.
    // if (await areNotificationsEnabled()) {
    //   await scheduleDailyNotification();
    // }
  }

  Future<void> showImmediateNotification(
    String title,
    String body, {
    String? payload,
    int? id,
  }) async {
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
      debugLog(
          '🔔 [NotificationService] Immediate notification shown: $title');
    } catch (e) {
      debugLog(
        '❌ [NotificationService] ERROR in showImmediateNotification: $e',
      );
    }
  }

  // Esta función ahora solo se usa para mostrar la notificación localmente
  // cuando el backend (Cloud Function) envía un mensaje FCM.
  // Ya NO se usa para programar la notificación diaria desde la app.
  Future<void> scheduleDailyNotification() async {
    // La lógica de cancelación y programación se mantiene si se necesita para otros fines locales,
    // pero para la notificación diaria, el servidor es el que orquesta.
    await cancelScheduledNotifications();

    // **INICIO DE MODIFICACIÓN: Leer configuración de Firestore para programación local**
    // Asegurarse de leer los datos de la ubicación correcta y con valores por defecto.
    final User? user = _auth.currentUser;
    if (user == null) {
      debugLog(
        '🔔 [NotificationService] User not authenticated, cannot schedule local notification.',
      );
      return;
    }

    final docSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('notifications')
        .get();

    if (!docSnapshot.exists || docSnapshot.data() == null) {
      debugLog(
        '🔔 [NotificationService] No notification settings found to schedule.',
      );
      return;
    }

    final data = docSnapshot.data()!;
    bool notificationsEnabled = data['notificationsEnabled'] ?? false;
    String notificationTimeStr =
        data['notificationTime'] ?? _defaultNotificationTime;
    String userTimezoneStr =
        data['userTimezone'] ?? await FlutterTimezone.getLocalTimezone();

    if (!notificationsEnabled) {
      debugLog(
        '🔔 [NotificationService] Local notifications disabled, not scheduling.',
      );
      await cancelScheduledNotifications();
      return;
    }
    // **FIN DE MODIFICACIÓN**

    // Parsear la hora de notificación y la zona horaria
    final parts = notificationTimeStr.split(':');
    final int hour = int.parse(parts[0]);
    final int minute = int.parse(parts[1]);

    // Establecer la zona horaria del usuario para programar la notificación
    try {
      tz.setLocalLocation(tz.getLocation(userTimezoneStr));
      debugLog(
        '🔔 [NotificationService] Local timezone set to: $userTimezoneStr',
      );
    } catch (e) {
      debugLog(
        '❌ [NotificationService] Error setting local timezone to $userTimezoneStr. Using fallback timezone. Error: $e',
      );
      tz.setLocalLocation(
        tz.getLocation('America/Panama'),
      ); // Fallback a una zona conocida
    }

    // Calcular la hora de la próxima notificación
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    debugLog('🔔 [NotificationService] tz.TZDateTime.now(tz.local): $now');
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
    debugLog(
      '🔔 [NotificationService] Final scheduled date for daily notification: $scheduledDate',
    );

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
      // Se eliminó uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_devotional_payload',
    );
    debugLog(
      '🔔 [NotificationService] Daily notification scheduled for: $scheduledDate',
    );
  }

  Future<void> cancelScheduledNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    debugLog(
        '🔔 [NotificationService] All scheduled notifications cancelled');
  }

  // Metodo para obtener el idioma actual de la aplicación desde SharedPreferences
  Future<String> _getCurrentAppLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('locale') ?? 'es';
    } catch (e) {
      debugLog('❌ [NotificationService] Error getting current language: $e');
      return 'es'; // Valor por defecto en caso de error
    }
  }

  Future<void> verifyNotificationSetup() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugLog(
        '🔔 [NotificationService] verifyNotificationSetup → NO authenticated user',
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString(_fcmTokenKey);
    final settingsDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('notifications')
        .get();
    final data = settingsDoc.data() ?? {};
    final enabled = data['notificationsEnabled'];
    final notifTime = data['notificationTime'];
    final timezone = data['userTimezone'];
    debugLog(
      '🔔 [NotificationService] verifyNotificationSetup → User: ${user.uid}, Local token: ${storedToken != null ? 'OK' : 'NO'}, Firestore notificationsEnabled: $enabled, Time: $notifTime, TZ: $timezone',
    );
  }
}
