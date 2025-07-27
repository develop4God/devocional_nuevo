import 'package:in_app_update/in_app_update.dart';
import 'package:flutter/material.dart';

class UpdateService {
  
  // Verificar si hay actualizaciones disponibles
  static Future<void> checkForUpdate() async {
    try {
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
      print('Error checking for updates: $e');
    }
  }
  
  // Actualización inmediata (forzada)
  static Future<void> performImmediateUpdate() async {
    try {
      await InAppUpdate.performImmediateUpdate();
    } catch (e) {
      print('Error performing immediate update: $e');
    }
  }
  
  // Actualización flexible
  static Future<void> performFlexibleUpdate() async {
    try {
      await InAppUpdate.startFlexibleUpdate();
      
      // Escuchar el estado de la descarga
      InAppUpdate.flexibleUpdateDownloadListener.listen((status) {
        if (status == InstallStatus.downloaded) {
          // Completar la instalación automáticamente
          InAppUpdate.completeFlexibleUpdate();
        }
      });
    } catch (e) {
      print('Error performing flexible update: $e');
    }
  }
}
