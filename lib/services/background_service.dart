// lib/services/background_service.dart
// Servicio para manejar tareas en segundo plano y notificaciones periódicas

import 'dart:isolate';
import 'dart:ui';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class BackgroundService {
  static const String _isolateName = 'isolate';
  static const int _alarmId = 0;

  /// Inicializa el servicio de alarmas y configura la comunicación entre aislados
  static Future<void> initialize() async {
    // Inicializar el servicio de alarmas de Android
    await AndroidAlarmManager.initialize();

    // Registrar el puerto para comunicación entre aislados
    final ReceivePort port = ReceivePort();
    IsolateNameServer.registerPortWithName(port.sendPort, _isolateName);

    // Escuchar mensajes del aislado secundario
    port.listen((dynamic data) async {
      // Este callback se ejecuta cuando recibimos un mensaje
      if (data != null) {
        // Usar el singleton de NotificationService para mostrar la notificación
        await NotificationService().showDailyDevotionalNotification();
      }
    });
  }

  /// Programa notificaciones periódicas diarias
  static Future<void> schedulePeriodicNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

    if (notificationsEnabled) {
      // Programar verificación diaria a las 8:00 AM
      await AndroidAlarmManager.periodic(
        const Duration(days: 1),
        _alarmId,
        _fireNotification,
        startAt: DateTime.now().add(const Duration(days: 1)).copyWith(hour: 8, minute: 0),
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );
    }
  }

  /// Cancela todas las notificaciones periódicas programadas
  static Future<void> cancelPeriodicNotifications() async {
    await AndroidAlarmManager.cancel(_alarmId);
  }

  /// Callback que se ejecuta cuando se dispara la alarma
  @pragma('vm:entry-point')
  static Future<void> _fireNotification() async {
    // Intentar comunicarse con el aislado principal
    final SendPort? send = IsolateNameServer.lookupPortByName(_isolateName);
    send?.send(null);

    // Disparar notificación usando el singleton de NotificationService
    await NotificationService().showDailyDevotionalNotification();
  }

  /// Punto de entrada para el aislado secundario
  /// Esta función es necesaria para que el aislado pueda ejecutarse correctamente
  @pragma('vm:entry-point')
  static void _isolateEntryPoint() {
    // Configurar comunicación entre aislados
    final ReceivePort port = ReceivePort();
    IsolateNameServer.registerPortWithName(port.sendPort, _isolateName);

    // Escuchar mensajes y mostrar notificaciones cuando sea necesario
    port.listen((dynamic data) async {
      // Usar el singleton de NotificationService para mostrar la notificación
      await NotificationService().showDailyDevotionalNotification();
    });
  }
}