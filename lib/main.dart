import 'dart:developer' as developer;

import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/backup_event.dart';
import 'package:devocional_nuevo/blocs/prayer_bloc.dart';
import 'package:devocional_nuevo/blocs/thanksgiving_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_event.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/controllers/audio_controller.dart';
import 'package:devocional_nuevo/pages/debug_page.dart';
import 'package:devocional_nuevo/pages/devocionales_page.dart';
import 'package:devocional_nuevo/pages/onboarding/onboarding_flow.dart';
import 'package:devocional_nuevo/pages/settings_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/providers/localization_provider.dart';
import 'package:devocional_nuevo/services/connectivity_service.dart';
import 'package:devocional_nuevo/services/google_drive_auth_service.dart';
import 'package:devocional_nuevo/services/google_drive_backup_service.dart';
import 'package:devocional_nuevo/services/notification_service.dart';
import 'package:devocional_nuevo/services/onboarding_service.dart';
import 'package:devocional_nuevo/services/remote_config_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:devocional_nuevo/services/tts/i_tts_service.dart';
import 'package:devocional_nuevo/splash_screen.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:devocional_nuevo/utils/theme_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

// Global navigator key for app navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// ADD this global RouteObserver at the top level
final RouteObserver<PageRoute<dynamic>> routeObserver =
    RouteObserver<PageRoute<dynamic>>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log(
    'BackgroundServiceCallback: Manejando mensaje FCM en segundo plano: ${message.messageId}',
    name: 'BackgroundServiceCallback',
  );
  await Firebase.initializeApp();

  // Setup ServiceLocator para el isolate de background con manejo de errores
  try {
    setupServiceLocator();
    developer.log(
      'BackgroundServiceCallback: ServiceLocator initialized in background isolate.',
      name: 'BackgroundServiceCallback',
    );
  } catch (e, stack) {
    developer.log(
      'ServiceLocator setup failed in background isolate',
      name: 'BackgroundServiceCallback',
      error: e,
      stackTrace: stack,
    );
    // Registrar solo NotificationService como fallback
    final locator = ServiceLocator();
    locator.registerLazySingleton<NotificationService>(
      NotificationService.create,
    );
    developer.log(
      'BackgroundServiceCallback: Solo NotificationService registrado como fallback en background isolate.',
      name: 'BackgroundServiceCallback',
    );
  }

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
  final notificationService = getService<NotificationService>();
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

  // AGREGAR Crashlytics para manejo global de errores
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Inicializar Firebase In-App Messaging en background (non-blocking)
  Future.microtask(() async {
    final FirebaseInAppMessaging inAppMessaging =
        FirebaseInAppMessaging.instance;
    await inAppMessaging.setAutomaticDataCollectionEnabled(true);
    inAppMessaging.triggerEvent('app_launch');
    inAppMessaging.triggerEvent('on_foreground');
    developer.log(
      'App: Firebase In-App Messaging inicializado en background.',
      name: 'MainApp',
    );
  });

  // Setup dependency injection
  setupServiceLocator();
  developer.log(
    'App: Service locator initialized with DI container.',
    name: 'MainApp',
  );

  // Initialize Remote Config (AWAIT for it to be ready before runApp)
  // This ensures feature flags are available from app start
  try {
    final remoteConfigService = getService<RemoteConfigService>();
    await remoteConfigService.initialize();
    developer.log(
      'App: RemoteConfigService initialized successfully.',
      name: 'MainApp',
    );
  } catch (e, stack) {
    developer.log(
      'App: Failed to initialize RemoteConfigService, using defaults',
      name: 'MainApp',
      error: e,
      stackTrace: stack,
    );
  }

  // Configure system UI overlay style for consistent navigation bar appearance
  // This ensures dark gray navigation bar with white buttons across all themes
  SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  developer.log(
    'App: System UI overlay style configured for consistent navigation bar.',
    name: 'MainApp',
  );

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
        BlocProvider(create: (context) => ThanksgivingBloc()),
        BlocProvider(
          create: (context) {
            final themeBloc = ThemeBloc();
            themeBloc.add(const LoadTheme()); // Load theme on app start
            return themeBloc;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => AudioController(getService<ITtsService>()),
        ),
        // Agregar BackupBloc
        BlocProvider(
          create: (context) => BackupBloc(
            backupService: GoogleDriveBackupService(
              authService: GoogleDriveAuthService(),
              connectivityService: ConnectivityService(),
              statsService: SpiritualStatsService(),
            ),
            devocionalProvider: context.read<DevocionalProvider>(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// App principal - Siempre muestra SplashScreen primero
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<bool> _initializationFuture;
  bool _developerMode = false;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeApp();
    _loadDeveloperMode();
  }

  Future<void> _loadDeveloperMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _developerMode = prefs.getBool('developerMode') ?? false;
    });
  }

  /// Metodo unificado que inicializa servicios y verifica onboarding
  Future<bool> _initializeApp() async {
    try {
      // Capture provider reference before any async operation to avoid
      // context-after-dispose issues if widget unmounts during async gaps
      final localizationProvider = Provider.of<LocalizationProvider>(
        context,
        listen: false,
      );

      // 1. Primero inicializar localización (crítico para traducciones)
      await localizationProvider.initialize();

      // Check if widget is still mounted after async operation
      if (!mounted) {
        developer.log(
          'App: Widget unmounted during initialization, aborting',
          name: 'MainApp',
        );
        return false;
      }

      developer.log(
        'App: LocalizationService inicializado correctamente',
        name: 'MainApp',
      );

      // 2. Verificar si debe mostrar onboarding solo si la feature está habilitada
      if (Constants.enableOnboardingFeature) {
        final shouldShowOnboarding =
            await OnboardingService.instance.shouldShowOnboarding();

        // Check if widget is still mounted after second async operation
        if (!mounted) {
          developer.log(
            'App: Widget unmounted during onboarding check, aborting',
            name: 'MainApp',
          );
          return false;
        }

        developer.log(
          'App: Onboarding check completado. Mostrar: $shouldShowOnboarding',
          name: 'MainApp',
        );

        return shouldShowOnboarding;
      } else {
        developer.log(
          'App: Onboarding feature deshabilitada por feature flag',
          name: 'MainApp',
        );
        return false;
      }
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
    final localizationProvider = Provider.of<LocalizationProvider>(context);

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        // Get theme from state, fallback to default if not loaded
        ThemeData currentTheme;
        if (themeState is ThemeLoaded) {
          currentTheme = themeState.themeData;
        } else {
          // Fallback theme while loading or in error state
          currentTheme = context.read<ThemeBloc>().currentTheme;
        }

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: systemUiOverlayStyle,
          child: MaterialApp(
            title: 'Devocionales',
            debugShowCheckedModeBanner: false,
            theme: currentTheme,
            navigatorKey: navigatorKey,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: localizationProvider.supportedLocales,
            locale: localizationProvider.currentLocale,
            // ADD this line to connect the global RouteObserver
            navigatorObservers: [routeObserver],
            home: FutureBuilder<bool>(
              future: _initializationFuture,
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
                        // INICIO: CAMBIO PARA TRANSICIÓN INSTANTÁNEA (SOLUCIONA EL FLICKER)
                        PageRouteBuilder(
                          pageBuilder: (context, a, b) =>
                              const AppInitializer(),
                          transitionDuration: Duration.zero,
                        ),
                        // FIN: CAMBIO PARA TRANSICIÓN INSTANTÁNEA
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
              if (kDebugMode || _developerMode)
                '/debug': (context) => const DebugPage(),
            },
          ),
        );
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
    // Aumentar delay para mostrar el SplashScreen más tiempo
    await Future.delayed(const Duration(milliseconds: 3000));

    // Solo inicializar lo crítico primero
    await _initCriticalServices();
    await _initAppData();

    // Navegar a la página principal INMEDIATAMENTE
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, a, b) => const DevocionalesPage(),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );

    // Inicializar servicios no críticos DESPUÉS en background
    _initNonCriticalServices();

    developer.log(
      'AppInitializer: Inicialización completa terminada.',
      name: 'MainApp',
    );
  }

  Future<void> _initCriticalServices() async {
    // Solo Firebase Auth (necesario para firestore)
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
      developer.log('ERROR: Firebase Auth: $e', name: 'MainApp', error: e);
    }

    // Timezone (necesario para algunas features)
    try {
      tzdata.initializeTimeZones();
      developer.log(
        'AppInitializer: Zona horaria inicializada.',
        name: 'MainApp',
      );
    } catch (e) {
      developer.log('ERROR: Timezone: $e', name: 'MainApp', error: e);
    }
  }

  void _initNonCriticalServices() {
    // TTS - diferido 1 segundo
    Future.delayed(const Duration(seconds: 1), () async {
      try {
        if (!mounted) return;
        final localizationProvider = Provider.of<LocalizationProvider>(
          context,
          listen: false,
        );
        final languageCode = localizationProvider.currentLocale.languageCode;
        await getService<ITtsService>().initializeTtsOnAppStart(languageCode);
        debugPrint(
          '[MAIN] TTS inicializado en background con idioma: $languageCode',
        );
      } catch (e) {
        developer.log(
          'ERROR: TTS initialization: $e',
          name: 'MainApp',
          error: e,
        );
      }
    });

    // Notifications - diferido 2 segundos
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        await getService<NotificationService>().initialize();
        developer.log(
          'AppInitializer: Servicios de notificación inicializados en background.',
          name: 'MainApp',
        );

        // Request notification permissions if not in debug mode
        if (!kDebugMode) {
          final settings = await FirebaseMessaging.instance.requestPermission();
          developer.log(
            'Permiso de notificaciones solicitado en background: ${settings.authorizationStatus}',
            name: 'MainApp',
          );
        } else {
          developer.log(
            'NO se solicita permiso de notificaciones en modo debug',
            name: 'DebugFlow',
          );
        }
      } catch (e) {
        developer.log(
          'ERROR: Notification services: $e',
          name: 'MainApp',
          error: e,
        );
      }
    });

    // Spiritual stats & backup - diferido 3 segundos
    if (Constants.enableBackupFeature) {
      Future.delayed(const Duration(seconds: 3), () async {
        try {
          if (!mounted) return;
          final spiritualStatsService = SpiritualStatsService();

          // Verificar integridad de datos
          await spiritualStatsService.getStats();

          // Habilitar auto-backup si no está configurado
          if (!await spiritualStatsService.isAutoBackupEnabled()) {
            await spiritualStatsService.setAutoBackupEnabled(true);
            developer.log(
              'AppInitializer: Auto-backup habilitado por defecto.',
              name: 'MainApp',
            );
          }

          // Backup check
          if (!mounted) return;
          try {
            final backupBloc = context.read<BackupBloc>();
            backupBloc.add(const CheckStartupBackup());
            debugPrint('🌅 [MAIN] Startup backup check initiated');
          } catch (e) {
            debugPrint('❌ [MAIN] Error starting backup check: $e');
          }

          developer.log(
            'AppInitializer: Sistema de backup inicializado en background.',
            name: 'MainApp',
          );
        } catch (e) {
          developer.log(
            'ERROR: Spiritual stats/backup: $e',
            name: 'MainApp',
            error: e,
          );
        }
      });
    } else {
      developer.log(
        'AppInitializer: Backup feature deshabilitada por feature flag',
        name: 'MainApp',
      );
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
        'ERROR: DevocionalProvider data: $e',
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
