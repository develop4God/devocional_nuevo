// lib/services/firebase_messaging_service.dart

import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

// Esta función debe definirse a nivel global para manejar mensajes en segundo plano
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Asegúrate de que Firebase esté inicializado
  await Firebase.initializeApp();
  debugPrint('Mensaje recibido en segundo plano: ${message.messageId}');
  
  // Aquí puedes procesar el mensaje o almacenarlo para procesarlo cuando la app se abra
  // Por ejemplo, guardar en SharedPreferences que hay una notificación pendiente
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('pending_notification', jsonEncode(message.data));
}

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final NotificationService _localNotificationService = NotificationService();
  
  // Canal para notificaciones de alta prioridad
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notificaciones Importantes',
    description: 'Canal para notificaciones importantes de la aplicación',
    importance: Importance.high,
  );

  // Inicializar el servicio de Firebase Messaging
  Future<void> initialize() async {
    // Inicializar Firebase
    await Firebase.initializeApp();
    
    // Configurar manejador de mensajes en segundo plano
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Solicitar permisos para iOS
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    
    // Configurar canal para Android
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
    
    // Configurar FCM para mostrar notificaciones cuando la app está en primer plano
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Manejar mensajes cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Mensaje recibido en primer plano: ${message.messageId}');
      _handleMessage(message);
    });
    
    // Manejar cuando se toca una notificación y la app está en segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notificación abierta desde segundo plano: ${message.messageId}');
      _handleMessageOpenedApp(message);
    });
    
    // Verificar si la app se abrió desde una notificación
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App abierta desde notificación: ${initialMessage.messageId}');
      _handleInitialMessage(initialMessage);
    }
    
    // Verificar notificaciones pendientes
    _checkPendingNotifications();
  }
  
  // Obtener el token de FCM para este dispositivo
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
  
  // Suscribirse a un tema para recibir notificaciones
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    debugPrint('Suscrito al tema: $topic');
  }
  
  // Cancelar suscripción a un tema
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    debugPrint('Cancelada suscripción al tema: $topic');
  }
  
  // Manejar un mensaje recibido cuando la app está en primer plano
  void _handleMessage(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    
    // Si el mensaje tiene una notificación y estamos en Android
    if (notification != null && android != null) {
      _localNotificationService.showImmediateNotification(
        title: notification.title ?? 'Notificación',
        body: notification.body ?? 'Has recibido una notificación',
      );
    }
    
    // También puedes manejar datos personalizados
    if (message.data.isNotEmpty) {
      debugPrint('Datos del mensaje: ${message.data}');
      // Procesar datos según tu lógica de negocio
    }
  }
  
  // Manejar cuando se abre una notificación con la app en segundo plano
  void _handleMessageOpenedApp(RemoteMessage message) {
    // Aquí puedes implementar navegación a una pantalla específica
    // basada en los datos del mensaje
    if (message.data.containsKey('screen')) {
      final screen = message.data['screen'];
      debugPrint('Navegar a pantalla: $screen');
      // Implementar navegación según tu lógica
    }
  }
  
  // Manejar cuando la app se abre desde una notificación (app cerrada)
  void _handleInitialMessage(RemoteMessage message) {
    // Similar a _handleMessageOpenedApp, pero para cuando la app estaba cerrada
    if (message.data.containsKey('screen')) {
      final screen = message.data['screen'];
      debugPrint('Navegar a pantalla desde app cerrada: $screen');
      // Implementar navegación según tu lógica
    }
  }
  
  // Verificar si hay notificaciones pendientes guardadas
  Future<void> _checkPendingNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingNotification = prefs.getString('pending_notification');
    
    if (pendingNotification != null) {
      try {
        final data = jsonDecode(pendingNotification) as Map<String, dynamic>;
        debugPrint('Notificación pendiente encontrada: $data');
        
        // Procesar la notificación pendiente
        // Por ejemplo, mostrar una notificación local
        _localNotificationService.showImmediateNotification(
          title: data['title'] ?? 'Notificación pendiente',
          body: data['body'] ?? 'Tienes una notificación pendiente',
        );
        
        // Limpiar la notificación pendiente
        await prefs.remove('pending_notification');
      } catch (e) {
        debugPrint('Error al procesar notificación pendiente: $e');
      }
    }
  }
}