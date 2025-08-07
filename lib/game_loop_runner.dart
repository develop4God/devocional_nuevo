import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;

import 'package:devocional_nuevo/pages/devocionales_page.dart';
import 'package:devocional_nuevo/pages/favorites_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const MethodChannel _platform = MethodChannel('com.devocional_nuevo.test_channel');

final List<String> _activityLog = [];

Future<String?> getInitialIntentAction() async {
  try {
    developer.log("GameLoopRunner: Entrando a getInitialIntentAction", name: "GameLoopRunner");
    final String? result = await _platform.invokeMethod('getInitialIntentAction');
    logStep("Intent detectado: $result");
    return result;
  } on PlatformException catch (e) {
    developer.log("GameLoopRunner: Error de plataforma al obtener el intent: ${e.message}", name: 'GameLoopRunner', error: e);
    logStep("ERROR detectando intent: ${e.message}");
    return null;
  } catch (e, s) {
    developer.log("GameLoopRunner: Error inesperado: $e", name: 'GameLoopRunner', error: e, stackTrace: s);
    logStep("ERROR inesperado en getInitialIntentAction: $e");
    return null;
  }
}

Widget testHomeWidget() => const DevocionalesPage();

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
    navigatorKey.currentState!.push(MaterialPageRoute(builder: (context) => const FavoritesPage()));
    await Future.delayed(const Duration(seconds: 3));
    logStep("Regresando de FavoritesPage");
    navigatorKey.currentState!.pop();
    await Future.delayed(const Duration(seconds: 2));
  }
  logStep('Flujo de navegación de prueba completado.');
}

Future<void> reportTestResultAndExit(bool success, String message) async {
  logStep('Reportando resultado del test y saliendo...');
  final directory = await getApplicationCacheDirectory();
  final testResultsDir = Directory('${directory.path}/firebase-test-lab-game-loops');
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
    developer.log('GameLoopRunner: ERROR al escribir los resultados: $e', name: 'GameLoopRunner', error: e, stackTrace: s);
    logStep("ERROR escribiendo resultados: $e");
  }
  SystemNavigator.pop();
  logStep('Aplicación cerrada después del test.');
}

void logStep(String message) {
  final timestamp = DateTime.now().toIso8601String();
  final logMessage = "[$timestamp] $message";
  _activityLog.add(logMessage);
  developer.log(logMessage, name: "GameLoopRunner");
}