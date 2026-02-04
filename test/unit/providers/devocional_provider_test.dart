import 'dart:async';
import 'dart:convert';

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/i_tts_service.dart';
import 'package:devocional_nuevo/services/tts_service.dart'; // for TtsState
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal fake implementation of ITtsService to satisfy provider constructor

@Tags(['unit', 'providers'])
class FakeTtsService implements ITtsService {
  final StreamController<TtsState> _stateController =
      StreamController.broadcast();
  final StreamController<double> _progressController =
      StreamController<double>.broadcast();

  @override
  Stream<TtsState> get stateStream => _stateController.stream;

  @override
  Stream<double> get progressStream => _progressController.stream;

  @override
  void setLanguageContext(String language, String version) {}

  @override
  Future<void> assignDefaultVoiceForLanguage(String languageCode) async {}

  @override
  Future<void> dispose() async {
    await _stateController.close();
    await _progressController.close();
  }

  @override
  Future<List<String>> getLanguages() async => [];

  @override
  Future<List<String>> getVoices() async => [];

  @override
  Future<List<String>> getVoicesForLanguage(String language) async => [];

  @override
  String formatBibleBook(String reference) => reference;

  @override
  String? get currentDevocionalId => null;

  @override
  TtsState get currentState => TtsState.idle;

  @override
  bool get isActive => true;

  @override
  bool get isDisposed => false;

  @override
  bool get isPaused => false;

  @override
  bool get isPlaying => false;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> initializeTtsOnAppStart(String languageCode) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> setLanguage(String language) async {}

  @override
  Future<void> setSpeechRate(double rate) async {}

  @override
  Future<void> setVoice(Map<String, String> voice) async {}

  @override
  Future<void> speakDevotional(Devocional devocional) async {}

  @override
  Future<void> speakText(String text) async {}

  @override
  Future<void> stop() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Reset service locator and register fake TTS service
    ServiceLocator().reset();
    ServiceLocator().registerSingleton<ITtsService>(FakeTtsService());
  });

  test('saveFavorites persists ids and schema version', () async {
    // Start with empty mock prefs for this test
    SharedPreferences.setMockInitialValues({});

    final provider = DevocionalProvider();

    // Use the new helpers to add a favorite and persist without UI
    await provider.addFavoriteId('test-id');
    // Ensure async writes complete
    await Future.delayed(const Duration(milliseconds: 50));

    final prefs = await SharedPreferences.getInstance();
    final favsJson = prefs.getString('favorite_ids');

    expect(favsJson, isNotNull);

    final List<dynamic> decoded =
        favsJson == null ? [] : (jsonDecode(favsJson) as List<dynamic>);
    expect(decoded, contains('test-id'));

    final int? schemaVersion = prefs.getInt('favorites_schema_version');
    expect(schemaVersion, equals(Constants.favoritesSchemaVersion));
  });

  test('migrates legacy favorites to favorite_ids and sets schema version',
      () async {
    // Create a legacy-style favorites list (array of serialized devotionals)
    final legacyDev = Devocional(
      id: 'legacy-id',
      versiculo: '',
      reflexion: '',
      paraMeditar: <ParaMeditar>[],
      oracion: '',
      date: DateTime.now(),
      version: 'RVR1960',
    );

    final legacyJson = jsonEncode([legacyDev.toJson()]);

    // Seed SharedPreferences with the legacy key
    SharedPreferences.setMockInitialValues({'favorites': legacyJson});

    final provider = DevocionalProvider();

    // Trigger reload/migration
    await provider.reloadFavoritesFromStorage();

    // Allow async writes to complete
    await Future.delayed(const Duration(milliseconds: 50));

    final prefs = await SharedPreferences.getInstance();
    final favIdsJson = prefs.getString('favorite_ids');
    expect(favIdsJson, isNotNull);

    final List<dynamic> decoded =
        favIdsJson == null ? [] : (jsonDecode(favIdsJson) as List<dynamic>);
    expect(decoded, contains('legacy-id'));

    final int? schemaVersion = prefs.getInt('favorites_schema_version');
    expect(schemaVersion, equals(Constants.favoritesSchemaVersion));
  });
}
