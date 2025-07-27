import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'dart:developer' as developer;
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/splash_screen.dart';
import 'package:devocional_nuevo/services/notification_service.dart';
// Eliminadas las importaciones de Workmanager y BackgroundServiceNew
// import 'package:workmanager/workmanager.dart';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // NUEVA IMPORTACIÓN para Firebase Messaging
import 'package:devocional_nuevo/providers/theme_provider.dart'; // SOLUCIÓN: Asegúrate de que esta línea esté presente
import 'package:devocional_nuevo/pages/settings_page.dart'; // SOLUCIÓN: Asegúrate de que esta línea esté presente

// Esta es la función de nivel superior (top-level function) que Firebase Messaging llamará
// cuando un mensaje FCM llegue mientras la aplicación está en segundo plano o terminada.
// Debe estar fuera de cualquier clase y marcada con @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log('BackgroundServiceCallback: Manejando mensaje FCM en segundo plano: ${message.messageId}', name: 'BackgroundServiceCallback');

  // Asegurarse de que Firebase esté inicializado en este aislado de segundo plano
  // Esto es crucial porque el callback se ejecuta en un "aislado" separado.
  await Firebase.initializeApp();

  // Re-inicializar los datos de zona horaria y la ubicación local
  tzdata.initializeTimeZones();
  try {
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));
    developer.log('BackgroundServiceCallback: Zona horaria re-inicializada a: $currentTimeZone', name: 'BackgroundServiceCallback');
  } catch (e) {
    developer.log('BackgroundServiceCallback: Error al re-inicializar la zona horaria en segundo plano: $e', name: 'BackgroundServiceCallback', error: e);
    // Fallback a UTC si la detección de zona horaria falla en segundo plano
    tz.setLocalLocation(tz.getLocation('UTC'));
    developer.log('BackgroundServiceCallback: Volviendo a la zona horaria UTC en segundo plano.', name: 'BackgroundServiceCallback');
  }

  // Aquí se procesaría el mensaje FCM y se mostraría la notificación localmente.
  // Usamos NotificationService para mostrar la notificación.
  final NotificationService notificationService = NotificationService();
  await notificationService.initialize(); // Inicializar el servicio de notificación en el aislado de segundo plano

  // Extraer el título y el cuerpo del mensaje FCM
  final String? title = message.notification?.title;
  final String? body = message.notification?.body;
  final String? payload = message.data['payload'] as String?; // Si tienes un payload personalizado en los datos

  if (title != null && body != null) {
    await notificationService.showImmediateNotification(
      title,
      body,
      payload: payload,
      id: message.messageId.hashCode, // Usar un ID único basado en el messageId
    );
    developer.log('BackgroundServiceCallback: Notificación FCM mostrada en segundo plano: $title', name: 'BackgroundServiceCallback');
  } else {
    developer.log('BackgroundServiceCallback: Mensaje FCM de segundo plano sin título o cuerpo de notificación.', name: 'BackgroundServiceCallback');
  }

  developer.log('BackgroundServiceCallback: Manejo de mensaje FCM en segundo plano completado.', name: 'BackgroundServiceCallback');
}

void main() async {
  developer.log('App: Función main() iniciada.', name: 'MainApp');
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Inicialización explícita de Firebase

  // Configurar el manejador de mensajes FCM en segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  developer.log('App: Manejador de mensajes FCM en segundo plano registrado.', name: 'MainApp');

  // Inicializar los datos de zona horaria para el aislado principal de la aplicación
  tzdata.initializeTimeZones();
  // La ubicación local se establecerá en NotificationService.initialize() para la app en primer plano

  await initializeDateFormatting('es', null);

  // Eliminada la inicialización de Workmanager y el registro de tareas periódicas
  // Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  // developer.log('App: Workmanager inicializado.', name: 'MainApp');

  try {
    final FirebaseAuth auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
      developer.log('MainApp: Usuario anónimo autenticado: ${auth.currentUser?.uid}', name: 'MainApp');
    } else {
      developer.log('MainApp: Usuario ya autenticado: ${auth.currentUser?.uid}', name: 'MainApp');
    }
  } catch (e) {
    developer.log('ERROR en main: Error al inicializar Firebase Auth o autenticar anónimamente: $e', name: 'MainApp', error: e);
  }

  try {
    // Inicializar NotificationService para la aplicación en primer plano y configurar listeners FCM
    await NotificationService().initialize();
    developer.log('App: Servicios de notificación (FCM) registrados correctamente.', name: 'MainApp');
  } catch (e) {
    debugPrint('Error al inicializar servicios de notificación: $e');
    developer.log('ERROR en main: Error al inicializar servicios de notificación: $e', name: 'MainApp', error: e);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => DevocionalProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Devocionales',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.currentTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('es', ''),
      ],
      home: const SplashScreen(),
      routes: {
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}
