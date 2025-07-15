import 'dart:developer' as developer;
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/widgets.dart';
import 'notification_service.dart';

// Clase para gestionar los servicios en segundo plano usando Workmanager.
class BackgroundServiceNew {
  // Nombre de la tarea periódica para Workmanager. Es una constante estática para evitar errores.
  // Ahora está dentro de la clase para ser accesible correctamente.
  static const String dailyNotificationTaskName = 'com.develop4god.devocional_nuevo.dailyNotificationTask';

  // Instancia Singleton para asegurar que solo haya una instancia de la clase.
  static final BackgroundServiceNew _instance = BackgroundServiceNew._internal();

  // Factory constructor para devolver la misma instancia.
  factory BackgroundServiceNew() => _instance;

  // Constructor privado.
  BackgroundServiceNew._internal();

  // Inicializa Workmanager y registra la tarea periódica.
  Future<void> initialize() async {
    // Log para indicar que el método initialize() ha sido llamado.
    developer.log('BackgroundServiceNew: initialize() called', name: 'BackgroundServiceNew');
    try {
      // Inicializa Workmanager con el callbackDispatcher.
      // isInDebugMode debe ser 'false' en producción.
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: true, // Cambia a false en producción
      );
      // Log para confirmar que Workmanager se ha inicializado.
      developer.log('BackgroundServiceNew: Workmanager initialized', name: 'BackgroundServiceNew');
      // Registra la tarea periódica después de la inicialización.
      await registerPeriodicTask();
    } catch (e) {
      // Captura y loguea cualquier error durante la inicialización de Workmanager.
      developer.log('ERROR en BackgroundServiceNew: $e', name: 'BackgroundServiceNew', error: e);
    }
  }

  // Registra una tarea periódica para la notificación diaria.
  Future<void> registerPeriodicTask() async {
    // Log para indicar que el método registerPeriodicTask() ha sido llamado.
    developer.log('BackgroundServiceNew: registerPeriodicTask() called', name: 'BackgroundServiceNew');
    try {
      // Log para indicar que se está registrando la tarea periódica.
      developer.log('BackgroundServiceNew: Registering periodic task', name: 'BackgroundServiceNew');

      // Obtener la hora configurada para la notificación desde SharedPreferences.
      final prefs = await SharedPreferences.getInstance();
      final timeString = prefs.getString('notification_time')?? '08:00';
      final timeParts = timeString.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Calcular el initialDelay para la próxima ejecución de la tarea.
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

      // Si la hora programada ya pasó para hoy, programar para mañana.
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      final initialDelay = scheduledDate.difference(now);

      // Registra la tarea periódica con Workmanager.
      // Se corrigió el orden de los argumentos: uniqueName primero, luego taskName.
      // Se usa dailyNotificationTaskName como uniqueName.
      await Workmanager().registerPeriodicTask(
        dailyNotificationTaskName, // Primer argumento: uniqueName (constante dailyNotificationTaskName)
        'dailyNotificationTask', // Segundo argumento: taskName (identificador de la tarea)
        frequency: const Duration(hours: 24), // La tarea se ejecutará cada 24 horas.
        initialDelay: initialDelay, // Retraso inicial hasta la primera ejecución.
        constraints: Constraints(
          networkType: NetworkType.notRequired, // No se requiere conexión a internet para esta tarea.
          requiresBatteryNotLow: false, // No requiere que la batería no esté baja.
          requiresCharging: false, // No requiere que el dispositivo esté cargando.
          requiresDeviceIdle: false, // No requiere que el dispositivo esté inactivo.
          requiresStorageNotLow: false, // No requiere que el almacenamiento no esté bajo.
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace, // Reemplaza cualquier tarea existente con el mismo uniqueName.
        backoffPolicy: BackoffPolicy.linear, // Política de reintento lineal.
        backoffPolicyDelay: const Duration(minutes: 10), // Retraso de 10 minutos entre reintentos.
      );
      // Log para confirmar que la tarea periódica ha sido registrada y para qué fecha/hora.
      developer.log('BackgroundServiceNew: Periodic task registered for $scheduledDate', name: 'BackgroundServiceNew');
    } catch (e) {
      // Captura y loguea cualquier error durante el registro de la tarea periódica.
      developer.log('ERROR en registerPeriodicTask: $e', name: 'BackgroundServiceNew', error: e);
    }
  }

  // Cancela todas las tareas de Workmanager registradas por la aplicación.
  Future<void> cancelAllTasks() async {
    try {
      // Log para indicar que se están cancelando todas las tareas.
      developer.log('BackgroundServiceNew: Cancelling all Workmanager tasks', name: 'BackgroundServiceNew');
      await Workmanager().cancelAll();
    } catch (e) {
      // Captura y loguea cualquier error durante la cancelación de tareas.
      developer.log('ERROR en cancelAllTasks: $e', name: 'BackgroundServiceNew', error: e);
    }
  }
}

// Función de nivel superior (top-level function) que Workmanager ejecuta en segundo plano.
// Debe tener la anotación @pragma('vm:entry-point').
@pragma('vm:entry-point')
void callbackDispatcher() {
  // Log para indicar que la ejecución de la tarea del Workmanager ha comenzado.
  developer.log('callbackDispatcher: Task execution started', name: 'BackgroundServiceCallback');
  // Define la lógica a ejecutar cuando Workmanager dispara una tarea.
  Workmanager().executeTask((task, inputData) async {
    // Log para indicar qué tarea se está ejecutando.
    developer.log('callbackDispatcher: Executing task: $task', name: 'BackgroundServiceCallback');
    try {
      // Asegura que el motor de Flutter esté inicializado para ejecutar código Dart.
      WidgetsFlutterBinding.ensureInitialized();
      // Llama al servicio de notificación para programar la notificación diaria.
      await NotificationService().scheduleDailyNotification();
      // Log para confirmar que la notificación se mostró exitosamente.
      developer.log('callbackDispatcher: Notification shown successfully', name: 'BackgroundServiceCallback');
      return true; // Indica que la tarea se completó con éxito.
    } catch (e) {
      // Captura y loguea cualquier error durante la ejecución de la tarea.
      developer.log('ERROR en callbackDispatcher: $e', name: 'BackgroundServiceCallback', error: e);
      return false; // Indica que la tarea falló.
    }
  });
}
