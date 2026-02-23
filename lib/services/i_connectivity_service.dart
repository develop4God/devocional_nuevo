// lib/services/i_connectivity_service.dart
//
// Abstract interface for [ConnectivityService].
// Depend on this interface (not the concrete class) for
// Dependency Inversion and easy test mocking.

/// Abstract interface defining network connectivity service capabilities.
abstract class IConnectivityService {
  /// Stream of WiFi connection status.
  Stream<bool> get wifiStatusStream;

  /// Initialize connectivity monitoring.
  void initialize();

  /// Check if currently connected to WiFi.
  Future<bool> isConnectedToWifi();

  /// Check if currently connected to mobile data.
  Future<bool> isConnectedToMobile();

  /// Check if connected to any network.
  Future<bool> isConnected();

  /// Check if backup should proceed based on WiFi-only setting.
  Future<bool> shouldProceedWithBackup(bool wifiOnlyEnabled);

  /// Dispose resources.
  void dispose();
}
