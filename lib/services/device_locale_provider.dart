import 'dart:ui';

/// Provides the device's system locale.
///
/// Exists so [LocalizationService] can depend on an injectable interface
/// rather than reading `PlatformDispatcher.instance` directly — the engine
/// singleton has no test-controllable equivalent, so tests inject a fake
/// implementation instead of pinning a value through a production API.
abstract class DeviceLocaleProvider {
  Locale get locale;
}

class PlatformDeviceLocaleProvider implements DeviceLocaleProvider {
  const PlatformDeviceLocaleProvider();

  @override
  Locale get locale => PlatformDispatcher.instance.locale;
}
