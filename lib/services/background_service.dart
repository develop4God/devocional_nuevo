// lib/services/background_service.dart

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

// Identificadores de tareas
const String fetchDevotionalTask = 'fetchDevotionalTask';
const String checkForUpdatesTask = 'checkForUpdatesTask';

// Esta función debe definirse a nivel global para ser llamada por Workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    debugPrint('Ejecutando tarea en segundo plano: $taskName');
    
    switch (taskName) {
      case fetchDevotionalTask:
        await _handleFetchDevotionalTask();
        break;
      case checkForUpdatesTask:
        await _handleCheckForUpdatesTask();
        break;
      default:
        debugPrint('Tarea desconocida: $taskName');
    }
    
    return Future.value(true);
  });
}

// Manejar la tarea de obtener el devocional
Future<void> _handleFetchDevotionalTask() async {
  debugPrint('Obteniendo devocional en segundo plano');
  
  try {
    // Aquí implementarías la lógica para obtener el devocional del día
    // Por ejemplo, hacer una petición HTTP a tu API
    
    // Verificar si las notificaciones están habilitadas
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    
    if (notificationsEnabled) {
      // Mostrar notificación con el devocional del día
      final notificationService = NotificationService();
      await notificationService.showImmediateNotification(
        title: '🙏 Devocional de Hoy',
        body: 'Tu momento de reflexión diaria te está esperando',
      );
    }
  } catch (e) {
    debugPrint('Error al obtener devocional en segundo plano: $e');
  }
}

// Manejar la tarea de verificar actualizaciones
Future<void> _handleCheckForUpdatesTask() async {
  debugPrint('Verificando actualizaciones en segundo plano');
  
  try {
    // Aquí implementarías la lógica para verificar si hay actualizaciones
    // Por ejemplo, comparar la versión actual con la versión en el servidor
    
    // Si hay una actualización disponible, mostrar notificación
    final notificationService = NotificationService();
    await notificationService.showImmediateNotification(
      title: '📱 Actualización Disponible',
      body: 'Hay una nueva versión de la aplicación disponible',
    );
  } catch (e) {
    debugPrint('Error al verificar actualizaciones en segundo plano: $e');
  }
}

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();
  
  // Inicializar el servicio de tareas en segundo plano
  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
    
    debugPrint('Servicio de tareas en segundo plano inicializado');
  }
  
  // Programar tarea periódica para obtener el devocional
  Future<void> scheduleDailyDevotionalFetch() async {
    await Workmanager().registerPeriodicTask(
      'dailyDevotional',
      fetchDevotionalTask,
      frequency: const Duration(hours: 24),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
    
    debugPrint('Tarea diaria de devocional programada');
  }
  
  // Programar tarea periódica para verificar actualizaciones
  Future<void> scheduleWeeklyUpdateCheck() async {
    await Workmanager().registerPeriodicTask(
      'weeklyUpdate',
      checkForUpdatesTask,
      frequency: const Duration(days: 7),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
    
    debugPrint('Tarea semanal de verificación de actualizaciones programada');
  }
  
  // Cancelar todas las tareas programadas
  Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
    debugPrint('Todas las tareas en segundo plano canceladas');
  }
}