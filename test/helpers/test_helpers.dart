import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';

void registerTestServices() {
  ServiceLocator().reset();
  ServiceLocator().registerLazySingleton<VoiceSettingsService>(
      () => VoiceSettingsService());
}
