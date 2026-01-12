import 'dart:io';

import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Sets up all required services for testing
/// This ensures tests have access to all necessary dependencies
void registerTestServices() {
  ServiceLocator().reset();
  setupServiceLocator();
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
