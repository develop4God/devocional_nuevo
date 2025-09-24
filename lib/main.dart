import 'dart:developer' as developer;

import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/prayer_bloc.dart';
import 'package:devocional_nuevo/controllers/audio_controller.dart';
import 'package:devocional_nuevo/pages/devocionales_page.dart';
import 'package:devocional_nuevo/pages/onboarding/onboarding_flow.dart';
import 'package:devocional_nuevo/pages/settings_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/providers/localization_provider.dart';
import 'package:devocional_nuevo/providers/theme_provider.dart';
import 'package:devocional_nuevo/services/backup_scheduler_service.dart';
import 'package:devocional_nuevo/services/connectivity_service.dart';
import 'package:devocional_nuevo/services/google_drive_auth_service.dart';
import 'package:devocional_nuevo/services/google_drive_backup_service.dart';
import 'package:devocional_nuevo/services/notification_service.dart';
import 'package:devocional_nuevo/services/onboarding_service.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:devocional_nuevo/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

// Global navigator key for app navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log(
    'BackgroundServiceCallback: Manejando mensaje FCM en segundo plano: ${message.messageId}',
    name: 'BackgroundServiceCallback',
  );
  await Firebase.initializeApp();
  tzdata.initializeTimeZones();
  try {
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));
    developer.log(
      'BackgroundServiceCallback: Zona horaria re-inicializada a: $currentTimeZone',
      name: 'BackgroundServiceCallback',
    );
  } catch (e) {
    developer.log(
      'BackgroundServiceCallback: Error al re-inicializar la zona horaria en segundo plano: $e',
      name: 'BackgroundServiceCallback',
      error: e,
    );
    tz.setLocalLocation(tz.getLocation('UTC'));
    developer.log(
      'BackgroundServiceCallback: Volviendo a la zona horaria UTC en segundo plano.',
      name: 'BackgroundServiceCallback',
    );
  }
  final NotificationService notificationService = NotificationService();
  await notificationService.initialize();
  final String? title = message.notification?.title;
  final String? body = message.notification?.body;
  final String? payload = message.data['payload'] as String?;
  if (title != null && body != null) {
    await notificationService.showImmediateNotification(
      title,
      body,
      payload: payload,
      id: message.messageId.hashCode,
    );
    developer.log(
      'BackgroundServiceCallback: Notificación FCM mostrada en segundo plano: $title',
      name: 'BackgroundServiceCallback',
    );
  } else {
    developer.log(
      'BackgroundServiceCallback: Mensaje FCM de segundo plano sin título o cuerpo de notificación.',
      name: 'BackgroundServiceCallback',
    );
  }
  developer.log(
    'BackgroundServiceCallback: Manejo de mensaje FCM en segundo plano completado.',
    name: 'BackgroundServiceCallback',
  );
}

void main() async {
  developer.log('App: Función main() iniciada.', name: 'MainApp');
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // ➕ INICIALIZAR BACKUP SCHEDULER
  try {
    await BackupSchedulerService.initialize();
    developer.log(
      'AppInitializer: BackupSchedulerService inicializado correctamente.',
      name: 'MainApp',
    );
  } catch (e) {
    developer.log(
      'ERROR: Error inicializando BackupSchedulerService: $e',
      name: 'MainApp',
      error: e,
    );
  }
  // Configurar el manejador de mensajes FCM en segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  developer.log(
    'App: Manejador de mensajes FCM en segundo plano registrado.',
    name: 'MainApp',
  );

  // Lanzar runApp lo antes posible (sin inicializaciones bloqueantes)
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LocalizationProvider()),
        ChangeNotifierProvider(create: (context) => DevocionalProvider()),
        BlocProvider(create: (context) => PrayerBloc()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AudioController()),
        // Agregar BackupBloc
        BlocProvider(
          create: (context) => BackupBloc(
            backupService: GoogleDriveBackupService(
              authService: GoogleDriveAuthService(),
              connectivityService: ConnectivityService(),
              statsService: SpiritualStatsService(),
            ),
            schedulerService: null, // ✅ El BLoC maneja null correctamente
            devocionalProvider: context.read<DevocionalProvider>(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// App principal - Siempre muestra SplashScreen primero
// App principal - Siempre muestra SplashScreen primero
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<bool> _initializationFuture; // ← Cambiar nombre

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeApp(); // ← Nuevo método unificado
  }

  /// Método unificado que inicializa servicios y verifica onboarding
  Future<bool> _initializeApp() async {
    try {
      // 1. Primero inicializar localización (crítico para traducciones)
      await Provider.of<LocalizationProvider>(context, listen: false)
          .initialize();

      developer.log(
        'App: LocalizationService inicializado correctamente',
        name: 'MainApp',
      );

      // 2. Luego verificar si debe mostrar onboarding (incluye Remote Config)
      final shouldShowOnboarding =
          await OnboardingService.instance.shouldShowOnboarding();

      developer.log(
        'App: Onboarding check completado. Mostrar: $shouldShowOnboarding',
        name: 'MainApp',
      );

      return shouldShowOnboarding;
    } catch (e) {
      developer.log(
        'ERROR: Error en inicialización de app: $e',
        name: 'MainApp',
        error: e,
      );

      // En caso de error, no mostrar onboarding para evitar crashes
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localizationProvider = Provider.of<LocalizationProvider>(context);

    return MaterialApp(
      title: 'Devocionales',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.currentTheme,
      navigatorKey: navigatorKey,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: localizationProvider.supportedLocales,
      locale: localizationProvider.currentLocale,
      home: FutureBuilder<bool>(
        future: _initializationFuture, // ← Usar el future unificado
        builder: (context, snapshot) {
          // Mostrar splash mientras se inicializa
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }

          // Si hay error, ir directo a la app principal
          if (snapshot.hasError) {
            developer.log(
              'ERROR: Error en FutureBuilder de inicialización: ${snapshot.error}',
              name: 'MainApp',
              error: snapshot.error,
            );
            return const AppInitializer();
          }

          // Si debe mostrar onboarding (Remote Config enabled + not completed)
          if (snapshot.hasData && snapshot.data == true) {
            return OnboardingFlow(
              onComplete: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const AppInitializer(),
                  ),
                );
              },
            );
          }

          // Caso normal: ir a la app principal
          return const AppInitializer();
        },
      ),
      routes: {
        '/settings': (context) => const SettingsPage(),
        '/devocionales': (context) => const DevocionalesPage(),
      },
    );
  }
}

// Widget que maneja la inicialización mientras muestra SplashScreen
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    // Inicializar servicios en background mientras se muestra SplashScreen
    _initializeInBackground();
  }

  Future<void> _initializeInBackground() async {
    // Dar tiempo para que el SplashScreen se muestre
    await Future.delayed(const Duration(milliseconds: 600));

    // Inicialización completa: servicios + datos
    await _initServices();
    await _initAppData();

    developer.log(
      'AppInitializer: Inicialización completa terminada.',
      name: 'MainApp',
    );
  }

  Future<void> _initServices() async {
    // Get providers before any async operations
    final localizationProvider = Provider.of<LocalizationProvider>(
      context,
      listen: false,
    );

    // Inicialización global
    try {
      tzdata.initializeTimeZones();
      await initializeDateFormatting('es', null);
      developer.log(
        'AppInitializer: Zona horaria y formateo de fechas inicializados.',
        name: 'MainApp',
      );
    } catch (e) {
      developer.log(
        'ERROR en AppInitializer: Error al inicializar zona horaria o date formatting: $e',
        name: 'MainApp',
        error: e,
      );
    }

    // Initialize localization service
    try {
      await localizationProvider.initialize();
      developer.log(
        'AppInitializer: Localization service initialized successfully.',
        name: 'MainApp',
      );
    } catch (e) {
      developer.log(
        'ERROR en AppInitializer: Error al inicializar localization service: $e',
        name: 'MainApp',
        error: e,
      );
    }

    // Firebase Auth
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
        developer.log(
          'MainApp: Usuario anónimo autenticado: ${auth.currentUser?.uid}',
          name: 'MainApp',
        );
      } else {
        developer.log(
          'MainApp: Usuario ya autenticado: ${auth.currentUser?.uid}',
          name: 'MainApp',
        );
      }
    } catch (e) {
      developer.log(
        'ERROR en AppInitializer: Error al inicializar Firebase Auth o autenticar anónimamente: $e',
        name: 'MainApp',
        error: e,
      );
    }

    // Notification services
    try {
      await NotificationService().initialize();
      developer.log(
        'AppInitializer: Servicios de notificación (FCM) registrados correctamente.',
        name: 'MainApp',
      );

      // Request notification permissions if not in debug mode
      if (!kDebugMode) {
        developer.log(
          'Solicitando permiso de notificaciones...',
          name: 'DebugFlow',
        );
        final settings = await FirebaseMessaging.instance.requestPermission();
        developer.log(
          'Permiso solicitado, estado: ${settings.authorizationStatus}',
          name: 'DebugFlow',
        );
      } else {
        developer.log(
          'NO se solicita permiso de notificaciones en modo debug',
          name: 'DebugFlow',
        );
      }
    } catch (e) {
      debugPrint('Error al inicializar servicios de notificación: $e');
      developer.log(
        'ERROR en AppInitializer: Error al inicializar servicios de notificación: $e',
        name: 'MainApp',
        error: e,
      );
    }

    // Spiritual stats service
    try {
      final spiritualStatsService = SpiritualStatsService();

      // Verificar integridad de datos al inicio
      await spiritualStatsService.getStats();

      // Habilitar auto-backup si no está configurado (primera vez)
      if (!await spiritualStatsService.isAutoBackupEnabled()) {
        await spiritualStatsService.setAutoBackupEnabled(true);
        developer.log(
          'AppInitializer: Auto-backup de estadísticas espirituales habilitado por defecto.',
          name: 'MainApp',
        );
      }

      // Obtener información de backup para logging
      final backupInfo = await spiritualStatsService.getBackupInfo();
      developer.log(
        'AppInitializer: Sistema de backup inicializado. Auto-backups: ${backupInfo['auto_backups_count']}, Último backup: ${backupInfo['last_auto_backup']}',
        name: 'MainApp',
      );
    } catch (e) {
      developer.log(
        'ERROR en AppInitializer: Error al inicializar sistema de backup de estadísticas: $e',
        name: 'MainApp',
        error: e,
      );
      // No es crítico, la app puede continuar funcionando
    }
  }

  // Inicializar datos de la aplicación
  Future<void> _initAppData() async {
    if (!mounted) return;

    try {
      final devocionalProvider = Provider.of<DevocionalProvider>(
        context,
        listen: false,
      );
      await devocionalProvider.initializeData();
      developer.log(
        'AppInitializer: Datos del DevocionalProvider cargados correctamente.',
        name: 'MainApp',
      );
    } catch (e) {
      developer.log(
        'ERROR en AppInitializer: Error al cargar datos del DevocionalProvider: $e',
        name: 'MainApp',
        error: e,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // SIEMPRE muestra el SplashScreen con tus efectos
    // La inicialización ocurre en background
    return const SplashScreen();
  }
}
