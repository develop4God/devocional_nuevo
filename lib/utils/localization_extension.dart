import 'package:devocional_nuevo/services/localization_service.dart';

extension LocalizationExtension on String {
  String tr() {
    return LocalizationService.instance.translate(this);
  }
}
