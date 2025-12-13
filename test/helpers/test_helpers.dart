import 'package:devocional_nuevo/services/service_locator.dart';

/// Sets up all required services for testing
/// This ensures tests have access to all necessary dependencies
void registerTestServices() {
  ServiceLocator().reset();
  setupServiceLocator();
}
