import 'dart:async' show TimeoutException, unawaited;
import 'dart:developer' as developer;

import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_bloc.dart';
import 'package:devocional_nuevo/blocs/prayer_bloc.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_bloc.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_event.dart';
import 'package:devocional_nuevo/blocs/testimony_bloc.dart';
import 'package:devocional_nuevo/blocs/thanksgiving_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_event.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/controllers/audio_controller.dart';
import 'package:devocional_nuevo/pages/debug_page.dart';
import 'package:devocional_nuevo/pages/app_navigation_shell.dart';
import 'package:devocional_nuevo/pages/encounters/encounters_list_page.dart';
import 'package:devocional_nuevo/pages/onboarding/onboarding_flow.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/providers/localization_provider.dart';
import 'package:devocional_nuevo/repositories/discovery_repository.dart';
import 'package:devocional_nuevo/repositories/encounter_repository.dart';
import 'package:devocional_nuevo/repositories/i_supporter_profile_repository.dart';
import 'package:devocional_nuevo/services/deep_link_handler.dart';
import 'package:devocional_nuevo/services/discovery_favorites_service.dart';
import 'package:devocional_nuevo/services/discovery_progress_tracker.dart';
import 'package:devocional_nuevo/services/i_encounter_progress_service.dart';
import 'package:devocional_nuevo/services/backup/i_google_drive_backup_service.dart';
import 'package:devocional_nuevo/services/iap/i_iap_service.dart';
import 'package:devocional_nuevo/services/notification_service.dart';
import 'package:devocional_nuevo/services/onboarding_service.dart';
import 'package:devocional_nuevo/services/remote_config_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/i_startup_migration_service.dart';
import 'package:devocional_nuevo/services/i_spiritual_stats_service.dart';
import 'package:devocional_nuevo/services/tts/i_tts_service.dart';
import 'package:devocional_nuevo/splash_screen.dart';
import 'package:devocional_nuevo/utils/constants/constants.dart';
import 'package:devocional_nuevo/utils/network_error_utils.dart';
import 'package:devocional_nuevo/utils/constants/theme_constants.dart';
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
  if (kDebugMode) {
    debugPrint(
      '🔔 [BackgroundServiceCallback] Handling background FCM message: ${message.messageId}',
    );
  }
  // Ensure Firebase is initialized in the background isolate before using any
  // Firebase-dependent services. If you have generated DefaultFirebaseOptions,
  // prefer using `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
  await Firebase.initializeApp();

  try {
    // setupServiceLocator is async now — await it so services are registered
    // before we call getService<T>().
    await setupServiceLocator();
  } catch (e) {
    // If the locator setup fails for any reason (e.g. SharedPreferences not
    // available in this isolate), ensure NotificationService is at least
    // registered so we can show notifications.
    final locator = ServiceLocator();
    locator.registerLazySingleton<NotificationService>(
      NotificationService.create,
    );
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

  // Silence all debugPrint output in release builds. debugPrint is NOT
  // stripped by tree shaking; it prints to the system log in release unless
  // overridden (https://docs.flutter.dev/testing/code-debugging).
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  await Firebase.initializeApp();

  // --- Crashlytics error handlers ----------------------------------------
  // Transient network errors (SocketException, DNS failure, etc.) are NOT app
  // bugs.  They are recorded as non-fatal so they appear in Crashlytics' non-
  // fatal event log without polluting the fatal-crash dashboard.
  FlutterError.onError = (FlutterErrorDetails details) {
    if (isTransientNetworkError(details.exception)) {
      developer.log(
        'Non-fatal network error (flaky network): ${details.exception}',
        name: 'FlutterError.onError',
        error: details.exception,
        stackTrace: details.stack,
      );
      return; // just return, never touch Crashlytics
    }
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (isTransientNetworkError(error)) {
      developer.log(
        'Non-fatal network error (PlatformDispatcher): $error',
        name: 'PlatformDispatcher.onError',
        error: error,
        stackTrace: stack,
      );
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        fatal: false,
        reason: 'Transient network error — not an app bug',
      );
      return true;
    }
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  // -----------------------------------------------------------------------

  Future.microtask(() async {
    final FirebaseInAppMessaging inAppMessaging =
        FirebaseInAppMessaging.instance;
    await inAppMessaging.setAutomaticDataCollectionEnabled(true);
    inAppMessaging.triggerEvent('app_launch');
  });

  // setupServiceLocator() returns a Future now — await to ensure services
  // are registered before any call to getService<T>().
  await setupServiceLocator();

  try {
    final remoteConfigService = getService<RemoteConfigService>();
    await remoteConfigService.initialize();
  } catch (e) {
    // Remote config is non-critical, app continues without it
    developer.log(
      'Remote config initialization failed: $e',
      name: 'main',
      error: e,
    );
  }

  // Initialize deep link handler
  try {
    final deepLinkHandler = getService<DeepLinkHandler>();
    await deepLinkHandler.initialize();
  } catch (e) {
    // Deep link handler is non-critical, app continues without it
    developer.log(
      'Deep link handler initialization failed: $e',
      name: 'main',
      error: e,
    );
  }

  SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LocalizationProvider()),
        ChangeNotifierProvider(create: (context) => DevocionalProvider()),
        BlocProvider(
          create: (context) => PrayerBloc(
            statsService: getService<ISpiritualStatsService>(),
          ),
        ),
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
        if (Constants.enableEncountersFeature)
          BlocProvider(
            create: (context) => EncounterBloc(
              repository: getService<EncounterRepository>(),
              progressService: getService<IEncounterProgressService>(),
              cacheManager: getService<BaseCacheManager>(),
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
        BlocProvider(create: (context) => DevocionalesNavigationBloc()),
        BlocProvider(
          lazy: false,
          create: (context) => BackupBloc(
            backupService: getService<IGoogleDriveBackupService>(),
            devocionalProvider: context.read<DevocionalProvider>(),
            discoveryBloc: context.read<DiscoveryBloc>(),
            encounterBloc: context.read<EncounterBloc>(),
            navigationBloc: context.read<DevocionalesNavigationBloc>(),
          ),
        ),
        BlocProvider(
          create: (context) {
            final bloc = SupporterBloc(
              iapService: getService<IIapService>(),
              profileRepository: getService<ISupporterProfileRepository>(),
            );
            // Initialize on startup so goldSupporterName (and purchases) are
            // loaded from SharedPreferences before the devotional page shows.
            debugPrint('🚀 [main] Dispatching InitializeSupporter at startup');
            bloc.add(InitializeSupporter());
            return bloc;
          },
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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late Future<bool> _initializationFuture;
  bool _developerMode = false;
  DateTime? _lastPausedTime;

  // 🔥 Community Best Practice: 2+ hours for devotional/Bible apps
  static const Duration _staleThreshold = Duration(hours: 2);

  // 🔥 CRITICAL: Persist to disk to survive process death
  static const String _pauseTimeKey = 'app_last_paused_timestamp';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializationFuture = _initializeApp();
    _loadDeveloperMode();

    // 🔥 CRITICAL: Check on startup if we're stale from process death
    _checkForStaleSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    try {
      getService<http.Client>().close();
    } catch (e) {
      // HTTP client cleanup is non-critical during disposal
      developer.log(
        'HTTP client cleanup failed: $e',
        name: 'dispose',
        error: e,
      );
    }
    super.dispose();
  }

  /// 🔥 Check on app startup if session was stale from process death
  Future<void> _checkForStaleSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTimestamp = prefs.getInt(_pauseTimeKey);

      if (savedTimestamp != null) {
        final savedTime = DateTime.fromMillisecondsSinceEpoch(savedTimestamp);
        final elapsed = DateTime.now().difference(savedTime);

        developer.log(
          '⏱️ App restarted after ${elapsed.inMinutes} minutes (from disk)',
          name: 'MyApp',
        );

        if (elapsed > _staleThreshold) {
          developer.log(
            '🔄 Session was stale (${elapsed.inHours}h) - cleared from disk',
            name: 'MyApp',
          );
          await prefs.remove(_pauseTimeKey);
          // Don't restart here - let app initialize fresh naturally
        }
      }
    } catch (e) {
      developer.log(
        'Error checking stale session: $e',
        name: 'MyApp',
        error: e,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    developer.log('🔄 App lifecycle state changed: $state', name: 'MyApp');

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App going to background - record the time
      _lastPausedTime = DateTime.now();

      try {
        // 🔥 SAVE TO DISK (critical for process death survival)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
          _pauseTimeKey,
          _lastPausedTime!.millisecondsSinceEpoch,
        );

        developer.log(
          '⏸️ App paused at: $_lastPausedTime and saved to disk',
          name: 'MyApp',
        );
      } catch (e) {
        developer.log('Error saving pause time: $e', name: 'MyApp', error: e);
      }
    } else if (state == AppLifecycleState.resumed) {
      developer.log('▶️ App resumed', name: 'MyApp');

      try {
        // 🔥 Load from disk (in case process was killed and restarted)
        final prefs = await SharedPreferences.getInstance();
        final savedTimestamp = prefs.getInt(_pauseTimeKey);

        if (savedTimestamp != null) {
          _lastPausedTime = DateTime.fromMillisecondsSinceEpoch(savedTimestamp);

          final timeInBackground = DateTime.now().difference(_lastPausedTime!);
          developer.log(
            '⏱️ App resumed after ${timeInBackground.inMinutes} minutes (from disk)',
            name: 'MyApp',
          );

          if (timeInBackground > _staleThreshold) {
            developer.log(
              '🔄 Session stale (${timeInBackground.inHours}h) - refreshing data',
              name: 'MyApp',
            );
            await prefs.remove(_pauseTimeKey);
            _handleStaleSession();
          } else {
            developer.log(
              '✅ Session fresh (${timeInBackground.inMinutes}m) - no refresh needed',
              name: 'MyApp',
            );
          }
        } else {
          developer.log('✅ No saved pause time - fresh start', name: 'MyApp');
        }
      } catch (e) {
        developer.log(
          'Error restoring pause time: $e',
          name: 'MyApp',
          error: e,
        );
      }

      _lastPausedTime = null;

      unawaited(
        getService<NotificationService>()
            .retryFcmTokenIfMissing(reason: 'app resumed'),
      );
    }
  }

  /// 🎯 DON'T restart navigation - just refresh data (community best practice)
  void _handleStaleSession() {
    if (!mounted) return;
    // Refresh data only — do NOT re-initialize LocalizationProvider.
    // Re-running _initializeApp() causes FutureBuilder to flash ConnectionState.waiting → black screen.
    Provider.of<DevocionalProvider>(
      context,
      listen: false,
    ).refreshDevocionals();
    developer.log('🔄 Data refreshed due to stale session', name: 'MyApp');
  }

  Future<void> _loadDeveloperMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _developerMode = prefs.getBool('developerMode') ?? false;
    });
  }

  Future<bool> _initializeApp() async {
    try {
      final localizationProvider = Provider.of<LocalizationProvider>(
        context,
        listen: false,
      );
      await localizationProvider.initialize();
      if (!mounted) return false;

      return await getService<OnboardingService>().shouldShowOnboarding();
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
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder: (context, a, b) =>
                              const AppInitializer(),
                          transitionDuration: Duration.zero,
                        ),
                      );
                    },
                  );
                }
                return const AppInitializer();
              },
            ),
            routes: {
              '/devocionales': (context) =>
                  AppNavigationShell(key: AppNavigationShell.shellKey),
              if (Constants.enableEncountersFeature)
                '/encounters': (context) => const EncountersListPage(),
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
  // Minimum time SplashScreen is visible — matches AnimationController duration
  static const Duration _kMinSplashDisplay = Duration(milliseconds: 1500);

  // Startup watchdog ceiling:
  // Firebase cold start P99 (~3s) + network round trip P99 (~5s) + buffer (4s)
  // Calibrate from Stopwatch telemetry after first production run.
  static const Duration _kAppStartupTimeout = Duration(seconds: 12);

  @override
  void initState() {
    super.initState();
    _initializeInBackground();
  }

  Future<void> _initializeInBackground() async {
    final stopwatch = Stopwatch()..start();

    try {
      await Future.wait([
        _initCriticalServices(),
        _initAppData(),
        Future.delayed(_kMinSplashDisplay),
      ]).timeout(
        _kAppStartupTimeout,
        onTimeout: () => _handleStartupTimeout(stopwatch),
      );
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        fatal: false,
        reason:
            'AppInitializer startup error after ${stopwatch.elapsedMilliseconds}ms',
      );
      developer.log(
        'Startup error after ${stopwatch.elapsedMilliseconds}ms: $e',
        name: 'AppInitializer',
        error: e,
      );
      // Never leave the user on a black screen — navigate with whatever state is ready
    }

    stopwatch.stop();
    FirebaseCrashlytics.instance.log(
      'AppInitializer: startup completed in ${stopwatch.elapsedMilliseconds}ms',
    );
    developer.log(
      '⏱️ App startup completed in ${stopwatch.elapsedMilliseconds}ms',
      name: 'AppInitializer',
    );

    if (!mounted) {
      FirebaseCrashlytics.instance.recordError(
        Exception('AppInitializer: not mounted after init'),
        StackTrace.current,
        fatal: false,
        reason:
            'Widget unmounted before navigation could fire — likely black screen',
      );
      return;
    }
    _initNonCriticalServices();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, a, b) =>
            AppNavigationShell(key: AppNavigationShell.shellKey),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  List<dynamic> _handleStartupTimeout(Stopwatch stopwatch) {
    developer.log(
      'Startup timeout after ${stopwatch.elapsedMilliseconds}ms',
      name: 'AppInitializer',
    );
    FirebaseCrashlytics.instance.recordError(
      TimeoutException('App startup timeout'),
      StackTrace.current,
      fatal: false,
      reason: 'App startup exceeded ${_kAppStartupTimeout.inSeconds}s',
    );
    // Proceed — navigate with whatever state is ready
    return [];
  }

  Future<void> _initCriticalServices() async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      if (auth.currentUser == null) await auth.signInAnonymously();
    } catch (e) {
      // Anonymous auth is non-critical, app works without it
      developer.log(
        'Anonymous auth failed: $e',
        name: '_initializeApp',
        error: e,
      );
    }
    try {
      tzdata.initializeTimeZones();
    } catch (e) {
      // Timezone initialization already has UTC fallback
      developer.log(
        'Timezone initialization failed: $e',
        name: '_initializeApp',
        error: e,
      );
    }
  }

  void _initNonCriticalServices() {
    Future.delayed(const Duration(seconds: 1), () async {
      try {
        if (!mounted) return;
        final languageCode = Provider.of<LocalizationProvider>(
          context,
          listen: false,
        ).currentLocale.languageCode;
        await getService<ITtsService>().initializeTtsOnAppStart(languageCode);
      } catch (e) {
        // TTS is non-critical, app works without it
        developer.log(
          'TTS initialization failed: $e',
          name: '_initNonCriticalServices',
          error: e,
        );
      }
    });

    Future.delayed(const Duration(seconds: 2), () async {
      try {
        await getService<NotificationService>().initialize();
        if (!kDebugMode) await FirebaseMessaging.instance.requestPermission();
      } catch (e) {
        // Notification permissions are non-critical
        developer.log(
          'Notification initialization failed: $e',
          name: '_initNonCriticalServices',
          error: e,
        );
      }
    });
  }

  Future<void> _initAppData() async {
    if (!mounted) return;
    try {
      final devocionalProvider = Provider.of<DevocionalProvider>(
        context,
        listen: false,
      );
      await devocionalProvider.initializeData();

      // Run all one-time startup migrations after data is loaded.
      final stats = await getService<ISpiritualStatsService>().getStats();
      await getService<IStartupMigrationService>().runAll(
        devocionalProvider.devocionales,
        stats.readDevocionalIds,
      );
    } catch (e) {
      // Data initialization errors are logged for debugging
      developer.log(
        'DevocionalProvider initialization failed: $e',
        name: '_initAppData',
        error: e,
      );
    }
  }

  @override
  Widget build(BuildContext context) => const SplashScreen();
}
