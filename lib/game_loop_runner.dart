import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:devocional_nuevo/pages/devocionales_page.dart';
import 'package:devocional_nuevo/pages/favorites_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const MethodChannel _platform =
    MethodChannel('com.devocional_nuevo.test_channel');

final List<String> _activityLog = [];

Future<String?> getInitialIntentAction() async {
  try {
    developer.log("GameLoopRunner: Entrando a getInitialIntentAction",
        name: "GameLoopRunner");
    final String? result =
        await _platform.invokeMethod('getInitialIntentAction');
    logStep("Intent detectado: $result");
    return result;
  } on PlatformException catch (e) {
    developer.log(
        "GameLoopRunner: Error de plataforma al obtener el intent: ${e.message}",
        name: 'GameLoopRunner',
        error: e);
    logStep("ERROR detectando intent: ${e.message}");
    return null;
  } catch (e, s) {
    developer.log("GameLoopRunner: Error inesperado: $e",
        name: 'GameLoopRunner', error: e, stackTrace: s);
    logStep("ERROR inesperado en getInitialIntentAction: $e");
    return null;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final intentAction = await getInitialIntentAction();
  final bool isGameLoop =
      (intentAction == 'com.google.intent.action.TEST_LOOP');

  developer.log("Modo Game Loop: $isGameLoop", name: "GameLoopRunner");

  if (!isGameLoop) {
    await requestNotificationPermissionIfNeeded();
  }

  runApp(MyApp(isGameLoop: isGameLoop));
}

/// Aquí defines cómo pedir el permiso de notificaciones localmente
Future<void> requestNotificationPermissionIfNeeded() async {
  // Ejemplo básico para Android (ajusta acorde a tu implementación)
  // No pidas permiso aquí si está en Game Loop (controlado arriba).
  // Puedes usar plugins como permission_handler o flutter_local_notifications

  // Sólo un placeholder con log:
  developer.log("Solicitando permiso de notificaciones (solo en modo normal)",
      name: "GameLoopRunner");
  // Aquí agrega tu llamada para pedir el permiso real, por ejemplo:
  // final status = await Permission.notification.request();
  // if (!status.isGranted) throw Exception("Permiso de notificaciones denegado");
}

class MyApp extends StatelessWidget {
  final bool isGameLoop;

  const MyApp({required this.isGameLoop, super.key});

  @override
  Widget build(BuildContext context) {
    if (isGameLoop) {
      return const GameLoopApp();
    } else {
      return const NormalApp();
    }
  }
}

// --- Modo Game Loop ---

class GameLoopApp extends StatefulWidget {
  const GameLoopApp({super.key});

  @override
  State<GameLoopApp> createState() => _GameLoopAppState();
}

class _GameLoopAppState extends State<GameLoopApp> {
  @override
  void initState() {
    super.initState();

    // Ejecutar el Game Loop luego de construir el primer frame (para que Navigator esté listo)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await runAutomatedGameLoop();
        await reportTestResultAndExit(
            true, 'Game Loop completed successfully.');
      } catch (e, s) {
        developer.log('Error en Game Loop: $e', error: e, stackTrace: s);
        await reportTestResultAndExit(false, 'Error durante Game Loop: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Devocional Game Loop',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: testHomeWidget(),
      routes: {
        '/settings': (context) => const SettingsPageStub(),
      },
    );
  }
}

// --- Modo Normal (UI estándar, permisos solicitados) ---

class NormalApp extends StatelessWidget {
  const NormalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Devocional Normal',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: testHomeWidget(),
      routes: {
        '/settings': (context) => const SettingsPageStub(),
      },
    );
  }
}

Widget testHomeWidget() => const DevocionalesPage();

class SettingsPageStub extends StatelessWidget {
  const SettingsPageStub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings page')),
    );
  }
}

// Ejecuta las navegaciones automáticas del Game Loop
Future<void> runAutomatedGameLoop() async {
  logStep('Iniciando Game Loop automatizado...');
  await Future.delayed(const Duration(seconds: 4));

  if (navigatorKey.currentState != null) {
    logStep("Navegando a SettingsPage");
    navigatorKey.currentState!.pushNamed('/settings');
    await Future.delayed(const Duration(seconds: 3));

    logStep("Regresando de SettingsPage");
    navigatorKey.currentState!.pop();
    await Future.delayed(const Duration(seconds: 2));

    logStep("Navegando a FavoritesPage");
    navigatorKey.currentState!
        .push(MaterialPageRoute(builder: (context) => const FavoritesPage()));
    await Future.delayed(const Duration(seconds: 3));

    logStep("Regresando de FavoritesPage");
    navigatorKey.currentState!.pop();
    await Future.delayed(const Duration(seconds: 2));
  } else {
    logStep("navigatorKey.currentState es null, no se puede navegar");
  }
  logStep('Flujo de navegación de prueba completado.');
}

// Guarda el resultado del test y cierra la app.
Future<void> reportTestResultAndExit(bool success, String message) async {
  logStep('Reportando resultado del test y saliendo...');
  final directory = await getApplicationCacheDirectory();
  final testResultsDir =
      Directory('${directory.path}/firebase-test-lab-game-loops');
  if (!await testResultsDir.exists()) {
    await testResultsDir.create(recursive: true);
  }
  final File outputFile = File('${testResultsDir.path}/results.json');
  final Map<String, dynamic> results = {
    'success': success,
    'message': message,
    'timestamp': DateTime.now().toIso8601String(),
    'build_mode': kDebugMode ? 'debug' : 'release',
    'app_version': '1.0.0',
    'activity_log': List<String>.from(_activityLog),
  };
  try {
    await outputFile.writeAsString(jsonEncode(results));
    logStep('Resultados escritos en: ${outputFile.path}');
  } catch (e, s) {
    developer.log('GameLoopRunner: ERROR al escribir los resultados: $e',
        name: 'GameLoopRunner', error: e, stackTrace: s);
    logStep("ERROR escribiendo resultados: $e");
  }

  // Notifica a Firebase Test Lab que el Game Loop terminó
  try {
    await _platform.invokeMethod('openUrl', 'firebase-game-loop-complete://');
  } catch (e) {
    developer.log(
        'GameLoopRunner: ERROR llamando a firebase-game-loop-complete:// URL: $e',
        name: 'GameLoopRunner',
        error: e);
  }

  logStep('Aplicación cerrada después del test.');
  SystemNavigator.pop();
}

void logStep(String message) {
  final timestamp = DateTime.now().toIso8601String();
  final logMessage = "[$timestamp] $message";
  _activityLog.add(logMessage);
  developer.log(logMessage, name: "GameLoopRunner");
}
