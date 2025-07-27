import 'dart:developer' as developer;
import 'package:in_app_update/in_app_update.dart';

class UpdateService {

  // Verificar si hay actualizaciones disponibles
  static Future<void> checkForUpdate() async {
    try {n
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          // Actualización inmediata (forzada)
          await performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          // Actualización flexible (opcional)
          await performFlexibleUpdate();
        }
      }
    } catch (e) {
      developer.log('Error checking for updates: $e', name: 'UpdateService');
    }
  }

  // Actualización inmediata (forzada)
  static Future<void> performImmediateUpdate() async {
    try {
      await InAppUpdate.performImmediateUpdate();
      developer.log('Immediate update completed', name: 'UpdateService');
    } catch (e) {
      developer.log('Error performing immediate update: $e', name: 'UpdateService');
    }
  }

  // Actualización flexible básica
  static Future<void> performFlexibleUpdate() async {
    try {
      await InAppUpdate.startFlexibleUpdate();
      developer.log('Flexible update started successfully', name: 'UpdateService');

      // Esperar un tiempo razonable para la descarga
      await Future.delayed(const Duration(seconds: 10));

      // Intentar completar la actualización
      await InAppUpdate.completeFlexibleUpdate();
      developer.log('Flexible update completed', name: 'UpdateService');

    } catch (e) {
      developer.log('Error performing flexible update: $e', name: 'UpdateService');
    }
  }

  // Actualización flexible con monitoreo y callback
  static Future<void> performFlexibleUpdateWithCallback({
    Function(String)? onStatusChange,
  }) async {
    try {
      onStatusChange?.call('Iniciando actualización...');

      await InAppUpdate.startFlexibleUpdate();
      developer.log('Flexible update started successfully', name: 'UpdateService');
      onStatusChange?.call('Descargando actualización...');

      // Monitorear el progreso de la descarga
      await _monitorFlexibleUpdateProgress(onStatusChange);

    } catch (e) {
      onStatusChange?.call('Error en actualización');
      developer.log('Error performing flexible update: $e', name: 'UpdateService');
    }
  }

  // Método privado para monitorear el progreso
  static Future<void> _monitorFlexibleUpdateProgress(
      Function(String)? onStatusChange,
      ) async {
    try {
      // Simular progreso de descarga con verificaciones periódicas
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(seconds: 2));

        onStatusChange?.call('Descargando... ${i * 10}%');
        developer.log('Download progress: ${i * 10}%', name: 'UpdateService');

        // Después del 80% intentar completar la actualización
        if (i >= 8) {
          try {
            onStatusChange?.call('Preparando instalación...');
            await InAppUpdate.completeFlexibleUpdate();
            onStatusChange?.call('Actualización completada exitosamente');
            developer.log('Flexible update completed successfully', name: 'UpdateService');
            return;
          } catch (e) {
            // Si falla, continúar esperando
            developer.log('Update not ready yet, continuing...', name: 'UpdateService');
          }
        }
      }

      // Último intento de completar la actualización
      try {
        await InAppUpdate.completeFlexibleUpdate();
        onStatusChange?.call('Actualización completada');
        developer.log('Flexible update completed on final attempt', name: 'UpdateService');
      } catch (e) {
        onStatusChange?.call('Error al completar actualización');
        developer.log('Failed to complete flexible update: $e', name: 'UpdateService');
      }

    } catch (e) {
      onStatusChange?.call('Error durante el monitoreo');
      developer.log('Error monitoring flexible update progress: $e', name: 'UpdateService');
    }
  }

  // Método para verificar y completar actualizaciones flexibles pendientes
  static Future<bool> completeFlexibleUpdateIfAvailable() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
      developer.log('Flexible update completed successfully', name: 'UpdateService');
      return true;
    } catch (e) {
      developer.log('No flexible update available to complete: $e', name: 'UpdateService');
      return false;
    }
  }

  // Método para obtener información detallada de actualización
  static Future<Map<String, dynamic>> getUpdateInfo() async {
    try {
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();

      return {
        'updateAvailable': info.updateAvailability == UpdateAvailability.updateAvailable,
        'immediateUpdateAllowed': info.immediateUpdateAllowed,
        'flexibleUpdateAllowed': info.flexibleUpdateAllowed,
        'availableVersionCode': info.availableVersionCode,
        'updatePriority': info.updatePriority,
        'clientVersionStalenessDays': info.clientVersionStalenessDays,
      };
    } catch (e) {
      developer.log('Error getting update info: $e', name: 'UpdateService');
      return {
        'updateAvailable': false,
        'error': e.toString(),
      };
    }
  }
}