import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';
import 'notification_service.dart';

// Nombre de la tarea en segundo plano
const String taskName = 'com.develop4god.devocional_nuevo.backgroundTask';

class BackgroundServiceNew {
  static final BackgroundServiceNew _instance = BackgroundServiceNew._internal();
  
  factory BackgroundServiceNew() {
    return _instance;
  }
  
  BackgroundServiceNew._internal();
  
  // Inicializar el servicio de fondo
  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
    
    // Registrar la tarea periódica
    await registerPeriodicTask();
  }
  
  // Registrar una tarea periódica
  Future<void> registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      'periodicTask',
      taskName,
      frequency: const Duration(hours: 12),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 15),
    );
  }
  
  // Registrar una tarea única
  Future<void> registerOneOffTask() async {
    await Workmanager().registerOneOffTask(
      'oneOffTask',
      taskName,
      initialDelay: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 15),
    );
  }
  
  // Cancelar todas las tareas
  Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
  }
}

// Esta función debe estar en el ámbito global
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      // Inicializar DartPluginRegistrant para poder usar plugins en el callback
      WidgetsFlutterBinding.ensureInitialized();
      DartPluginRegistrant.ensureInitialized();
      
      // Ejecutar la tarea en segundo plano
      await _executeBackgroundTask();
      
      return true;
    } catch (e) {
      print('Error en la tarea en segundo plano: $e');
      return false;
    }
  });
}

// Ejecutar la tarea en segundo plano
Future<void> _executeBackgroundTask() async {
  try {
    // Obtener las preferencias compartidas
    final prefs = await SharedPreferences.getInstance();
    
    // Verificar si es necesario mostrar una notificación
    final lastNotificationDate = prefs.getString(Constants.PREF_LAST_NOTIFICATION_DATE) ?? '';
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    if (lastNotificationDate != today) {
      // Mostrar una notificación
      final notificationService = NotificationService();
      await notificationService.initialize();
      
      // Mostrar una notificación con el devocional del día
      await notificationService.showDailyDevotionalNotification();
      
      // Guardar la fecha de la última notificación
      await prefs.setString(Constants.PREF_LAST_NOTIFICATION_DATE, today);
    }
  } catch (e) {
    print('Error al ejecutar la tarea en segundo plano: $e');
  }
}