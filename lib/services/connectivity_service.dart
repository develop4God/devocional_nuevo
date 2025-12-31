// lib/services/connectivity_service.dart
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Service for managing network connectivity status
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final StreamController<bool> _wifiStatusController =
      StreamController<bool>.broadcast();

  /// Stream of WiFi connection status
  Stream<bool> get wifiStatusStream => _wifiStatusController.stream;

  /// Initialize connectivity monitoring
  void initialize() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) {
      final isWifi = results.contains(ConnectivityResult.wifi);
      _wifiStatusController.add(isWifi);
      debugPrint('Connectivity changed: WiFi=$isWifi');
    });
  }

  /// Check if currently connected to WiFi
  Future<bool> isConnectedToWifi() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final isWifi = results.contains(ConnectivityResult.wifi);
      debugPrint('Current WiFi status: $isWifi');
      return isWifi;
    } catch (e) {
      debugPrint('Error checking WiFi connectivity: $e');
      return false;
    }
  }

  /// Check if currently connected to mobile data
  Future<bool> isConnectedToMobile() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final isMobile = results.contains(ConnectivityResult.mobile);
      debugPrint('Current mobile data status: $isMobile');
      return isMobile;
    } catch (e) {
      debugPrint('Error checking mobile connectivity: $e');
      return false;
    }
  }

  /// Check if connected to any network
  Future<bool> isConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final isConnected =
          results.isNotEmpty && !results.contains(ConnectivityResult.none);
      debugPrint('Current connectivity status: $isConnected');
      return isConnected;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false;
    }
  }

  /// Check if backup should proceed based on WiFi-only setting
  Future<bool> shouldProceedWithBackup(bool wifiOnlyEnabled) async {
    if (!wifiOnlyEnabled) {
      // WiFi-only is disabled, so any connection is fine
      return await isConnected();
    }

    // WiFi-only is enabled, so we need WiFi connection
    return await isConnectedToWifi();
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _wifiStatusController.close();
  }
}
