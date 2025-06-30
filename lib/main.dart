// lib/main.dart
// Punto de entrada principal de la aplicación
// Inicializa servicios, configuraciones y lanza la interfaz de usuario

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // Para formateo de fechas en español
import 'package:flutter_localizations/flutter_localizations.dart'; // Para soporte de localización
import 'package:firebase_core/firebase_core.dart';
import 'package:workmanager/workmanager.dart'; // Para tareas en segundo plano

// Importaciones de archivos locales
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/splash_screen.dart';
import 'package:devocional_nuevo/services/notification_service.dart';
import 'package:devocional_nuevo/services/firebase_messaging_service.dart';
import 'package:devocional_nuevo/services/background_service_new.dart';

/// Función principal que inicia la aplicación
void main() async {
  // Asegura que los widgets estén inicializados antes de hacer operaciones asíncronas
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar formato de fechas en español
  await initializeDateFormatting('es', null);

  try {
    // Inicializar Firebase
    await Firebase.initializeApp();

    // Inicializar servicio de notificaciones locales
    await NotificationService().initialize();

    // Inicializar servicio de notificaciones remotas (Firebase)
    await FirebaseMessagingService().initialize();

    // Inicializar servicio de tareas en segundo plano
    final backgroundService = BackgroundServiceNew();
    await backgroundService.initialize();
    
    // Programar notificaciones periódicas
    await backgroundService.registerPeriodicTask();

    // Suscribirse al tema general de notificaciones
    await FirebaseMessagingService().subscribeToTopic('general');

    // Obtener y guardar el token FCM
    final token = await FirebaseMessagingService().getToken();
    if (token != null) {
      await NotificationService().saveDeviceToken(token);
    }
  } catch (e) {
    debugPrint('Error al inicializar servicios: $e');
    // Continuar con la app incluso si hay error en la inicialización de servicios
  }

  // Iniciar la aplicación
  runApp(const MyApp());
}

/// Widget principal de la aplicación
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Configurar el Provider para gestión de estado
    return ChangeNotifierProvider(
      create: (context) => DevocionalProvider(),
      child: MaterialApp(
        title: 'Devocionales',
        debugShowCheckedModeBanner: false,
        // Configuración del tema de la aplicación
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
          // Estilos de texto personalizados
          textTheme: const TextTheme(
            displaySmall: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 255, 255, 255),
              shadows: [
                Shadow(
                  offset: Offset(2.0, 2.0),
                  blurRadius: 5.0,
                  color: Color.fromARGB(200, 0, 0, 0),
                ),
              ],
            ),
            // Otros estilos de texto pueden agregarse aquí
          ),
        ),
        // Configuración de localización para soporte multiidioma
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''), // Inglés
          Locale('es', ''), // Español
        ],
        // Pantalla inicial de la aplicación
        home: const SplashScreen(),
      ),
    );
  }
}