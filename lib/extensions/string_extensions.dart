import '../services/localization_service.dart';
import '../services/service_locator.dart';

/// Extension on String to provide easy translation access
extension StringTranslation on String {
  /// Translate this string using the localization service
  /// Usage: 'devotionals.app_title'.tr()
  /// With parameters: 'messages.welcome'.tr({'name': 'John'})
  String tr([Map<String, dynamic>? params]) {
    return getService<LocalizationService>().translate(this, params);
  }
}
