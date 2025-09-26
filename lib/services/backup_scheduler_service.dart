// lib/services/backup_scheduler_service.dart
import 'package:devocional_nuevo/services/google_drive_auth_service.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'connectivity_service.dart';
import 'google_drive_backup_service.dart';

/// Service for scheduling automatic backups in the background
class BackupSchedulerService {
  static const String _taskName = 'automatic_backup_task';
  static const String _taskTag = 'backup';

  final GoogleDriveBackupService _backupService;
  final ConnectivityService _connectivityService;

  BackupSchedulerService({
    required GoogleDriveBackupService backupService,
    required ConnectivityService connectivityService,
  })  : _backupService = backupService,
        _connectivityService = connectivityService;

  /// Initialize the background task system
  static Future<void> initialize() async {
    try {
      debugPrint('🔧 [SCHEDULER] Inicializando background scheduler...');
      await Workmanager().initialize(
        callbackDispatcher,
        // isInDebugMode removido - está deprecado
      );
      debugPrint(
        '✅ [SCHEDULER] Background scheduler inicializado correctamente',
      );
    } catch (e) {
      debugPrint('❌ [SCHEDULER] Error inicializando background scheduler: $e');
    }
  }

  /// Schedule automatic backup based on frequency
  Future<void> scheduleAutomaticBackup() async {
    debugPrint('🚀 [SCHEDULER] === INICIANDO scheduleAutomaticBackup() ===');

    try {
      final frequency = await _backupService.getBackupFrequency();
      final isEnabled = await _backupService.isAutoBackupEnabled();

      debugPrint('📊 [SCHEDULER] Frecuencia actual: $frequency');
      debugPrint('📊 [SCHEDULER] Auto backup habilitado: $isEnabled');

      if (!isEnabled) {
        debugPrint(
            '⚠️ [SCHEDULER] Auto backup deshabilitado, cancelando tareas...');
        await Workmanager().cancelByUniqueName(_taskName);
        await Workmanager().cancelByUniqueName('unique_backup_worker_test');
        debugPrint('✅ [SCHEDULER] Tareas canceladas por backup deshabilitado');
        return;
      }

      if (frequency == GoogleDriveBackupService.frequencyManual ||
          frequency == GoogleDriveBackupService.frequencyDeactivated) {
        debugPrint(
            '⚠️ [SCHEDULER] Frecuencia es manual/desactivada, cancelando tareas...');
        await Workmanager().cancelByUniqueName(_taskName);
        await Workmanager().cancelByUniqueName('unique_backup_worker_test');
        debugPrint(
            '✅ [SCHEDULER] Tareas canceladas por frecuencia manual/desactivada');
        return;
      }

      Duration initialDelay;
      Duration frequency_;

      switch (frequency) {
        case GoogleDriveBackupService.frequencyDaily:
          debugPrint('📅 [SCHEDULER] Configurando backup diario...');
          // Calcular tiempo hasta las próximas 2:00 AM
          final now = DateTime.now();
          final today2AM = DateTime(now.year, now.month, now.day, 2, 0);
          final tomorrow2AM = today2AM.add(Duration(days: 1));

          DateTime nextBackup;
          if (now.isBefore(today2AM)) {
            nextBackup = today2AM;
            debugPrint(
                '🕐 [SCHEDULER] Próximo backup: HOY a las 2:00 AM ($nextBackup)');
          } else {
            nextBackup = tomorrow2AM;
            debugPrint(
                '🕐 [SCHEDULER] Próximo backup: MAÑANA a las 2:00 AM ($nextBackup)');
          }

          initialDelay = nextBackup.difference(now);
          frequency_ = const Duration(hours: 24);

          debugPrint(
              '⏰ [SCHEDULER] Delay inicial: ${initialDelay.inHours}h ${initialDelay.inMinutes % 60}m');
          debugPrint(
              '🔄 [SCHEDULER] Frecuencia de repetición: ${frequency_.inHours}h');
          break;

        default:
          debugPrint(
              '⚠️ [SCHEDULER] Frecuencia no reconocida: $frequency, usando daily por defecto');
          initialDelay = const Duration(hours: 24);
          frequency_ = const Duration(hours: 24);
      }

      // Cancel existing tasks
      debugPrint('🗑️ [SCHEDULER] Cancelando tareas existentes...');
      await Workmanager().cancelByUniqueName(_taskName);
      await Workmanager().cancelByUniqueName(
          'unique_backup_worker_test'); // Cancelar prueba anterior
      debugPrint('✅ [SCHEDULER] Tareas existentes canceladas');

      // === INICIO: CAMBIO TEMPORAL PARA PRUEBAS ===
      if (kDebugMode) {
        debugPrint(
            '📋 [SCHEDULER] Registrando tarea de prueba (un solo disparo)...');
        await Workmanager().registerOneOffTask(
          'unique_backup_worker_test', // Unique name diferente
          _taskName, // Task name para el dispatcher
          initialDelay: const Duration(seconds: 60),
          constraints: Constraints(
            networkType: NetworkType.connected,
          ),
        );
        debugPrint(
            '🎉 [SCHEDULER] Tarea de prueba registrada. Se ejecutará en 5s.');
      } else {
        // Solo registrar la tarea periódica en producción
        debugPrint('📋 [SCHEDULER] Registrando nueva tarea periódica...');
        debugPrint('📋 [SCHEDULER] - Nombre: $_taskName');
        debugPrint(
            '📋 [SCHEDULER] - Delay inicial: ${initialDelay.inMinutes} minutos');
        debugPrint('📋 [SCHEDULER] - Frecuencia: ${frequency_.inHours} horas');

        await Workmanager().registerPeriodicTask(
          _taskName,
          _taskName,
          frequency: frequency_,
          initialDelay: initialDelay,
          constraints: Constraints(
            networkType: NetworkType.connected,
            requiresBatteryNotLow: true,
            requiresCharging: false,
            requiresDeviceIdle: false,
            requiresStorageNotLow: true,
          ),
          tag: _taskTag,
        );
        // ADEMÁS registrar prueba en debug
        if (kDebugMode) {
          await Workmanager().registerOneOffTask(
            'unique_backup_worker_test',
            _taskName,
            initialDelay: const Duration(seconds: 60),
            constraints: Constraints(networkType: NetworkType.connected),
          );
        }
      }
      // === FIN: CAMBIO TEMPORAL PARA PRUEBAS ===

      debugPrint('🎉 [SCHEDULER] ¡Backup automático programado exitosamente!');
      debugPrint('🎉 [SCHEDULER] - Frecuencia: $frequency');
      debugPrint(
          '🎉 [SCHEDULER] - Próxima ejecución: ${DateTime.now().add(initialDelay)}');
    } catch (e) {
      debugPrint('❌ [SCHEDULER] Error programando backup automático: $e');
      debugPrint('❌ [SCHEDULER] Stack trace: ${StackTrace.current}');
    }

    debugPrint('🏁 [SCHEDULER] === FIN scheduleAutomaticBackup() ===');
  }

  /// Cancel automatic backup scheduling
  Future<void> cancelAutomaticBackup() async {
    debugPrint('🛑 [SCHEDULER] === INICIANDO cancelAutomaticBackup() ===');
    try {
      await Workmanager().cancelByUniqueName(_taskName);
      await Workmanager().cancelByUniqueName('unique_backup_worker_test');
      debugPrint(
          '✅ [SCHEDULER] Programación de backup automático cancelada exitosamente');
    } catch (e) {
      debugPrint('❌ [SCHEDULER] Error cancelando backup automático: $e');
    }
    debugPrint('🏁 [SCHEDULER] === FIN cancelAutomaticBackup() ===');
  }

  /// Cancel all scheduled tasks
  static Future<void> cancelAllTasks() async {
    debugPrint('🛑 [SCHEDULER] === INICIANDO cancelAllTasks() ===');

    try {
      await Workmanager().cancelAll();
      debugPrint('✅ [SCHEDULER] Todas las tareas programadas canceladas');
    } catch (e) {
      debugPrint('❌ [SCHEDULER] Error cancelando todas las tareas: $e');
    }

    debugPrint('🏁 [SCHEDULER] === FIN cancelAllTasks() ===');
  }

  /// Check if backup should run now
  Future<bool> shouldRunBackup() async {
    // === INICIO: CAMBIO TEMPORAL PARA PRUEBAS ===
    // Esto fuerza el backup para pruebas en modo de depuración.
    if (kDebugMode) {
      debugPrint(
          '⚠️ [SCHEDULER] Modo debug, forzando shouldRunBackup() a true.');
      return true;
    }
    // === FIN: CAMBIO TEMPORAL PARA PRUEBAS ===
    debugPrint('🔍 [SCHEDULER] === VERIFICANDO shouldRunBackup() ===');

    try {
      // Check if auto backup is enabled
      final autoEnabled = await _backupService.isAutoBackupEnabled();
      debugPrint('📊 [SCHEDULER] Auto backup habilitado: $autoEnabled');

      if (!autoEnabled) {
        debugPrint('⚠️ [SCHEDULER] Auto backup deshabilitado');
        return false;
      }

      // Check if it's time for backup
      final shouldCreate = await _backupService.shouldCreateAutoBackup();
      debugPrint('📊 [SCHEDULER] Debería crear backup: $shouldCreate');

      if (!shouldCreate) {
        debugPrint('⚠️ [SCHEDULER] Aún no es tiempo para backup');
        return false;
      }

      // Check connectivity requirements
      final wifiOnlyEnabled = await _backupService.isWifiOnlyEnabled();
      debugPrint('📊 [SCHEDULER] Solo WiFi habilitado: $wifiOnlyEnabled');

      final connectivityOk = await _connectivityService.shouldProceedWithBackup(
        wifiOnlyEnabled,
      );
      debugPrint('📊 [SCHEDULER] Conectividad OK: $connectivityOk');

      if (!connectivityOk) {
        debugPrint('⚠️ [SCHEDULER] Requisitos de conectividad no cumplidos');
        return false;
      }

      debugPrint(
        '✅ [SCHEDULER] ¡Todas las condiciones cumplidas, backup debe ejecutarse!',
      );
      return true;
    } catch (e) {
      debugPrint('❌ [SCHEDULER] Error verificando si ejecutar backup: $e');
      return false;
    } finally {
      debugPrint('🏁 [SCHEDULER] === FIN shouldRunBackup() ===');
    }
  }

  /// Execute backup in background - IMPLEMENTACIÓN COMPLETA
  static Future<void> executeBackgroundBackup() async {
    debugPrint('🚀 [BACKGROUND] === INICIANDO executeBackgroundBackup() ===');
    debugPrint(
      '🚀 [BACKGROUND] Timestamp: ${DateTime.now().toIso8601String()}',
    );

    try {
      // Crear servicios en el isolate separado (necesario para background tasks)
      final authService = GoogleDriveAuthService();
      final connectivityService = ConnectivityService();
      final statsService = SpiritualStatsService();

      final backupService = GoogleDriveBackupService(
        authService: authService,
        connectivityService: connectivityService,
        statsService: statsService,
      );

      final schedulerService = BackupSchedulerService(
        backupService: backupService,
        connectivityService: connectivityService,
      );

      debugPrint(
        '🔧 [BACKGROUND] Servicios inicializados en background isolate',
      );

      // Verificar si debe ejecutarse el backup
      final shouldRun = await schedulerService.shouldRunBackup();
      debugPrint('🔍 [BACKGROUND] ¿Debe ejecutarse backup? $shouldRun');

      if (shouldRun) {
        debugPrint('✅ [BACKGROUND] Ejecutando backup automático...');
        final success = await backupService.createBackup(null);

        if (success) {
          debugPrint(
            '🎉 [BACKGROUND] Backup automático completado exitosamente',
          );
        } else {
          debugPrint('❌ [BACKGROUND] Error en backup automático');
        }
      } else {
        debugPrint('⚠️ [BACKGROUND] Condiciones no cumplidas, backup omitido');
      }
    } catch (e) {
      debugPrint('❌ [BACKGROUND] Error ejecutando backup en background: $e');
      debugPrint('❌ [BACKGROUND] Stack trace: ${StackTrace.current}');
    }

    debugPrint('🏁 [BACKGROUND] === FIN executeBackgroundBackup() ===');
  }

  /// Metodo helper para debug - Ver tareas programadas
  Future<void> debugScheduledTasks() async {
    debugPrint('🔍 [DEBUG] === VERIFICANDO TAREAS PROGRAMADAS ===');

    try {
      // Workmanager no tiene metodo directo para listar tareas
      // pero podemos verificar el estado
      debugPrint(
        '📋 [DEBUG] No hay método directo para listar tareas en Workmanager',
      );
      debugPrint(
        '📋 [DEBUG] Recomendación: Verificar en configuración del sistema',
      );

      final isEnabled = await _backupService.isAutoBackupEnabled();
      final frequency = await _backupService.getBackupFrequency();
      final nextTime = await _backupService.getNextBackupTime();

      debugPrint('📊 [DEBUG] Estado actual:');
      debugPrint('📊 [DEBUG] - Auto backup: $isEnabled');
      debugPrint('📊 [DEBUG] - Frecuencia: $frequency');
      debugPrint('📊 [DEBUG] - Próximo backup calculado: $nextTime');
    } catch (e) {
      debugPrint('❌ [DEBUG] Error verificando tareas: $e');
    }

    debugPrint('🏁 [DEBUG] === FIN VERIFICACIÓN TAREAS ===');
  }
}

/// Background task callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  final startTime = DateTime.now();
  debugPrint('🔧 [DISPATCHER] === INICIANDO CALLBACK DISPATCHER ===');
  debugPrint('⏰ [DISPATCHER] Hora de inicio: ${startTime.toIso8601String()}');

  Workmanager().executeTask((task, inputData) async {
    debugPrint('📞 [DISPATCHER] Tarea recibida: $task');
    debugPrint('📞 [DISPATCHER] Datos de entrada: $inputData');
    debugPrint(
      '📞 [DISPATCHER] Timestamp: ${DateTime.now().toIso8601String()}',
    );

    try {
      switch (task) {
        case BackupSchedulerService._taskName:
        // === INICIO: CAMBIO TEMPORAL PARA PRUEBAS ===
        case 'unique_backup_worker_test':
// === FIN: CAMBIO TEMPORAL PARA PRUEBAS ===
          debugPrint('✅ [DISPATCHER] Ejecutando tarea de backup automático...');
          await BackupSchedulerService.executeBackgroundBackup();
          debugPrint('✅ [DISPATCHER] Tarea de backup completada exitosamente');
          break;

        default:
          debugPrint('⚠️ [DISPATCHER] Tarea desconocida: $task');
          debugPrint('❌ [DISPATCHER] Retornando false por tarea no reconocida');
          return false;
      }

      debugPrint(
        '🎉 [DISPATCHER] Tarea completada exitosamente, retornando true',
      );
      return true;
    } catch (e) {
      debugPrint('❌ [DISPATCHER] Error en background task: $e');
      debugPrint('❌ [DISPATCHER] Stack trace: ${StackTrace.current}');
      debugPrint('❌ [DISPATCHER] Retornando false por error');
      return false;
    } finally {
      debugPrint('🏁 [DISPATCHER] === FIN CALLBACK DISPATCHER ===');
    }
  });
}
