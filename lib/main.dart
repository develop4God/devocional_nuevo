// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // Importación necesaria para initializeDateFormatting
import 'package:flutter_localizations/flutter_localizations.dart'; // Importación para delegados de localización
import 'package:firebase_core/firebase_core.dart';
import 'package:workmanager/workmanager.dart';

// Importa los archivos que acabas de separar
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/splash_screen.dart'; // Asegúrate de que esta ruta sea correcta
import 'package:devocional_nuevo/services/notification_service.dart';
import 'package:devocional_nuevo/services/firebase_messaging_service.dart';
import 'package:devocional_nuevo/services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es', null);
  
  try {
    // Inicializar Firebase
    await Firebase.initializeApp();
    
    // Inicializar servicio de notificaciones locales
    await NotificationService().initialize();
    
    // Inicializar servicio de notificaciones remotas (Firebase)
    await FirebaseMessagingService().initialize();
    
    // Inicializar servicio de tareas en segundo plano
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
    );
    
    // Programar tareas periódicas
    await BackgroundService().scheduleDailyDevotionalFetch();
    
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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DevocionalProvider(),
      child: MaterialApp(
        title: 'Devocionales',
        debugShowCheckedModeBanner: false,
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
          // --- Define el estilo para el texto del splash screen aquí ---
          textTheme: const TextTheme(
            displaySmall: TextStyle(
              // Usamos displaySmall para un texto de título grande
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 255, 255, 255), // Blanco
              shadows: [
                Shadow(
                  offset: Offset(2.0, 2.0), // Sombra más fuerte
                  blurRadius: 5.0, // Más desenfoque
                  color: Color.fromARGB(200, 0, 0, 0), // Sombra negra más opaca
                ),
              ],
            ),
            // Puedes añadir más estilos de texto aquí para un tema consistente
          ),
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''), // Soporte para inglés
          Locale('es', ''), // Soporte para español
        ],
        home: const SplashScreen(), // El SplashScreen es la primera pantalla
      ),
    );
  }
}
