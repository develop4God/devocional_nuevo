// lib/main.dart
// Punto de entrada principal de la aplicación
// Inicializa servicios, configuraciones y lanza la interfaz de usuario

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // Para formateo de fechas en español
import 'package:flutter_localizations/flutter_localizations.dart'; // Para soporte de localización
import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/data/latest.dart' as tz; // Importación correcta para inicializar timezone
import 'package:workmanager/workmanager.dart'; // Para tareas en segundo plano

// Importaciones de archivos locales
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/splash_screen.dart';
import 'package:devocional_nuevo/services/notification_service.dart';
import 'package:devocional_nuevo/services/firebase_messaging_service.dart';
import 'package:devocional_nuevo/services/background_service_new.dart';

// Importaciones para el sistema de temas
import 'package:devocional_nuevo/providers/theme_provider.dart'; // Importa el ThemeProvider
import 'package:devocional_nuevo/pages/settings_page.dart'; // Importa la página de ajustes para las rutas

/// Función principal que inicia la aplicación
void main() async {
  // Asegura que los widgets estén inicializados antes de hacer operaciones asíncronas
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializar timezone globalmente al inicio de la aplicación
  tz.initializeTimeZones();

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

    // Imprimir el token FCM en consola automáticamente al iniciar la app
    await FirebaseMessagingService().printFcmToken();

    // Obtener y guardar el token FCM
    final token = await FirebaseMessagingService().getToken();
    if (token != null) {
      await NotificationService().saveDeviceToken(token);
    }
  } catch (e) {
    debugPrint('Error al inicializar servicios: $e');
    // Continuar con la app incluso si hay error en la inicialización de servicios
  }

  // Iniciar la aplicación envolviendo MyApp con ChangeNotifierProvider para ThemeProvider
  runApp(
    MultiProvider( // Usamos MultiProvider para tener múltiples providers
      providers: [
        ChangeNotifierProvider(create: (context) => DevocionalProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()), // Agrega ThemeProvider
      ],
      child: const MyApp(),
    ),
  );
}

/// Widget principal de la aplicación
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener el ThemeProvider para acceder al tema actual
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Configurar el Provider para gestión de estado
    return MaterialApp(
      title: 'Devocionales',
      debugShowCheckedModeBanner: false,
      // Usar el tema actual del ThemeProvider
      theme: themeProvider.currentTheme,
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
      // Definir las rutas de la aplicación
      routes: {
        '/settings': (context) => const SettingsPage(), // Ruta para la página de ajustes
      },
    );
  }
}
