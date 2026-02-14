import 'dart:io';

import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Sets up all required services for testing
/// This ensures tests have access to all necessary dependencies
void registerTestServices() {
  ServiceLocator().reset();
  setupServiceLocator();
}

/// Sets up test services with fake implementations that don't require Firebase
/// Use this instead of registerTestServices() for widget tests that need analytics
void registerTestServicesWithFakes() {
  ServiceLocator().reset();
  setupServiceLocator();

  // Override AnalyticsService with fake that doesn't require Firebase
  final locator = ServiceLocator();
  if (locator.isRegistered<AnalyticsService>()) {
    locator.unregister<AnalyticsService>();
  }
  locator.registerSingleton<AnalyticsService>(FakeAnalyticsService());
}

/// Fake AnalyticsService that doesn't require Firebase initialization
/// Use this in widget tests to avoid Firebase initialization errors
class FakeAnalyticsService extends AnalyticsService {
  @override
  Future<void> logBottomBarAction({required String action}) async {
    // No-op for tests - don't actually log to Firebase
  }

  @override
  Future<void> logTtsPlay() async {}

  @override
  Future<void> logDevocionalComplete({
    required String devocionalId,
    required String campaignTag,
    String source = 'read',
    int? readingTimeSeconds,
    double? scrollPercentage,
    double? listenedPercentage,
  }) async {}

  @override
  Future<void> logNavigationNext({
    required int currentIndex,
    required int totalDevocionales,
    required String viaBloc,
    String? fallbackReason,
  }) async {}

  @override
  Future<void> logNavigationPrevious({
    required int currentIndex,
    required int totalDevocionales,
    required String viaBloc,
    String? fallbackReason,
  }) async {}

  @override
  Future<void> logFabTapped({required String source}) async {}

  @override
  Future<void> logFabChoiceSelected({
    required String source,
    required String choice,
  }) async {}

  @override
  Future<void> logDiscoveryAction({
    required String action,
    String? studyId,
  }) async {}

  @override
  Future<void> logCustomEvent({
    required String eventName,
    Map<String, Object>? parameters,
  }) async {}

  @override
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> resetAnalyticsData() async {}

  @override
  Future<void> logAppInit({Map<String, Object>? parameters}) async {}
}

/// Mock PathProvider for testing
/// Returns system temp directory for all path queries
class MockPathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }

  @override
  Future<String?> getTemporaryPath() async {
    return Directory.systemTemp.path;
  }
}
