import 'dart:developer' as developer;

import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/backup_event.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/prayer_bloc.dart';
import 'package:devocional_nuevo/blocs/testimony_bloc.dart';
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
import 'package:devocional_nuevo/repositories/discovery_repository.dart';
import 'package:devocional_nuevo/services/connectivity_service.dart';
import 'package:devocional_nuevo/services/discovery_favorites_service.dart';
import 'package:devocional_nuevo/services/discovery_progress_tracker.dart';
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
import 'package:devocional_nuevo/utils/session_manager.dart';
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
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

// Global navigator key for app navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// Global RouteObserver
final RouteObserver<PageRoute<dynamic>> routeObserver =
    RouteObserver<PageRoute<dynamic>>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log(
    'BackgroundServiceCallback: Manejando mensaje FCM en segundo plano: ${message.messageId}',
    name: 'BackgroundServiceCallback',
  );
  await Firebase.initializeApp();

  try {
    setupServiceLocator();
  } catch (e) {
    final locator = ServiceLocator();
    locator
        .registerLazySingleton<NotificationService>(NotificationService.create);
  }

  tzdata.initializeTimeZones();
  try {
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));
  } catch (e) {
    tz.setLocalLocation(tz.getLocation('UTC'));
  }
  final notificationService = getService<NotificationService>();
  await notificationService.initialize();
  final String? title = message.notification?.title;
  final String? body = message.notification?.body;
  if (title != null && body != null) {
    await notificationService.showImmediateNotification(
      title,
      body,
      payload: message.data['payload'] as String?,
      id: message.messageId.hashCode,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  Future.microtask(() async {
    final FirebaseInAppMessaging inAppMessaging =
        FirebaseInAppMessaging.instance;
    await inAppMessaging.setAutomaticDataCollectionEnabled(true);
    inAppMessaging.triggerEvent('app_launch');
  });

  setupServiceLocator();

  try {
    final remoteConfigService = getService<RemoteConfigService>();
    await remoteConfigService.initialize();
  } catch (e) {
    // Remote config is non-critical, app continues without it
    developer.log('Remote config initialization failed: $e',
        name: 'main', error: e);
  }

  SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Session Manager
  SessionManager().initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LocalizationProvider()),
        ChangeNotifierProvider(create: (context) => DevocionalProvider()),
        BlocProvider(create: (context) => PrayerBloc()),
        BlocProvider(create: (context) => ThanksgivingBloc()),
        BlocProvider(create: (context) => TestimonyBloc()),
        if (Constants.enableDiscoveryFeature)
          BlocProvider(
            create: (context) => DiscoveryBloc(
              repository: getService<DiscoveryRepository>(),
              progressTracker: getService<DiscoveryProgressTracker>(),
              favoritesService: getService<
                  DiscoveryFavoritesService>(), // ✅ FIXED: Injected service
            ),
          ),
        BlocProvider(
          create: (context) {
            final themeBloc = ThemeBloc();
            themeBloc.add(const LoadTheme());
            return themeBloc;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => AudioController(getService<ITtsService>()),
        ),
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

  @override
  void dispose() {
    try {
      getService<http.Client>().close();
    } catch (e) {
      // HTTP client cleanup is non-critical during disposal
      developer.log('HTTP client cleanup failed: $e',
          name: 'dispose', error: e);
    }
    super.dispose();
  }

  Future<void> _loadDeveloperMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _developerMode = prefs.getBool('developerMode') ?? false;
    });
  }

  Future<bool> _initializeApp() async {
    try {
      final localizationProvider =
          Provider.of<LocalizationProvider>(context, listen: false);
      await localizationProvider.initialize();
      if (!mounted) return false;

      if (Constants.enableOnboardingFeature) {
        return await OnboardingService.instance.shouldShowOnboarding();
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizationProvider = Provider.of<LocalizationProvider>(context);

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        ThemeData currentTheme = (themeState is ThemeLoaded)
            ? themeState.themeData
            : context.read<ThemeBloc>().currentTheme;

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
            navigatorObservers: [routeObserver],
            home: FutureBuilder<bool>(
              future: _initializationFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SplashScreen();
                }
                if (snapshot.hasData && snapshot.data == true) {
                  return OnboardingFlow(
                    onComplete: () {
                      Navigator.of(context).pushReplacement(PageRouteBuilder(
                          pageBuilder: (context, a, b) =>
                              const AppInitializer(),
                          transitionDuration: Duration.zero));
                    },
                  );
                }
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

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeInBackground();
  }

  Future<void> _initializeInBackground() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    await _initCriticalServices();
    await _initAppData();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (context, a, b) => const DevocionalesPage(),
        transitionDuration: const Duration(milliseconds: 300)));
    _initNonCriticalServices();
  }

  Future<void> _initCriticalServices() async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      if (auth.currentUser == null) await auth.signInAnonymously();
    } catch (e) {
      // Anonymous auth is non-critical, app works without it
      developer.log('Anonymous auth failed: $e',
          name: '_initializeApp', error: e);
    }
    try {
      tzdata.initializeTimeZones();
    } catch (e) {
      // Timezone initialization already has UTC fallback
      developer.log('Timezone initialization failed: $e',
          name: '_initializeApp', error: e);
    }
  }

  void _initNonCriticalServices() {
    Future.delayed(const Duration(seconds: 1), () async {
      try {
        if (!mounted) return;
        final languageCode =
            Provider.of<LocalizationProvider>(context, listen: false)
                .currentLocale
                .languageCode;
        await getService<ITtsService>().initializeTtsOnAppStart(languageCode);
      } catch (e) {
        // TTS is non-critical, app works without it
        developer.log('TTS initialization failed: $e',
            name: '_initNonCriticalServices', error: e);
      }
    });

    Future.delayed(const Duration(seconds: 2), () async {
      try {
        await getService<NotificationService>().initialize();
        if (!kDebugMode) await FirebaseMessaging.instance.requestPermission();
      } catch (e) {
        // Notification permissions are non-critical
        developer.log('Notification initialization failed: $e',
            name: '_initNonCriticalServices', error: e);
      }
    });

    if (Constants.enableBackupFeature) {
      Future.delayed(const Duration(seconds: 3), () async {
        try {
          if (!mounted) return;
          final spiritualStatsService = SpiritualStatsService();
          await spiritualStatsService.getStats();
          if (!await spiritualStatsService.isAutoBackupEnabled()) {
            await spiritualStatsService.setAutoBackupEnabled(true);
          }
          if (!mounted) return;
          context.read<BackupBloc>().add(const CheckStartupBackup());
        } catch (e) {
          // Backup is non-critical, app works without it
          developer.log('Backup initialization failed: $e',
              name: '_initNonCriticalServices', error: e);
        }
      });
    }
  }

  Future<void> _initAppData() async {
    if (!mounted) return;
    try {
      await Provider.of<DevocionalProvider>(context, listen: false)
          .initializeData();
    } catch (e) {
      // Data initialization errors are logged for debugging
      developer.log('DevocionalProvider initialization failed: $e',
          name: '_initAppData', error: e);
    }
  }

  @override
  Widget build(BuildContext context) => const SplashScreen();
}
