// lib/providers/devocional_provider.dart - SIMPLIFIED VERSION

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui';

import 'package:devocional_nuevo/controllers/audio_controller.dart'; // NEW
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/localization_provider.dart';
import 'package:devocional_nuevo/services/devocionales_tracking.dart';
import 'package:devocional_nuevo/services/remote_config_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:devocional_nuevo/services/tts/i_tts_service.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart' show Provider;
import 'package:shared_preferences/shared_preferences.dart';

/// Simplified provider focused on data management only
/// Audio functionality moved to AudioController
class DevocionalProvider with ChangeNotifier {
  // ========== CORE DATA ==========
  List<Devocional> _allDevocionalesForCurrentLanguage = [];
  List<Devocional> _filteredDevocionales = [];
  List<Devocional> _favoriteDevocionales = [];

  bool _isLoading = false;
  String? _errorMessage;
  String _selectedLanguage = 'es';
  String _selectedVersion = 'RVR1960';
  bool _showInvitationDialog = true;

  // ========== SERVICES ==========
  final SpiritualStatsService _statsService = SpiritualStatsService();
  late final AudioController _audioController; // NEW - Injected dependency

  // ========== OFFLINE FUNCTIONALITY ==========
  bool _isDownloading = false;
  String? _downloadStatus;
  bool _isOfflineMode = false;

  // ========== READING TRACKER ==========
  final ReadingTracker _readingTracker = ReadingTracker();

  // ========== GETTERS ==========
  List<Devocional> get devocionales => _filteredDevocionales;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String get selectedLanguage => _selectedLanguage;

  String get selectedVersion => _selectedVersion;

  List<Devocional> get favoriteDevocionales => _favoriteDevocionales;

  bool get showInvitationDialog => _showInvitationDialog;

  // Offline getters
  bool get isDownloading => _isDownloading;

  String? get downloadStatus => _downloadStatus;

  bool get isOfflineMode => _isOfflineMode;

  // Audio getters (delegates to AudioController)
  AudioController get audioController => _audioController;

  bool get isAudioPlaying => _audioController.isPlaying;

  bool get isAudioPaused => _audioController.isPaused;

  String? get currentPlayingDevocionalId =>
      _audioController.currentDevocionalId;

  bool isDevocionalPlaying(String devocionalId) =>
      _audioController.isDevocionalPlaying(devocionalId);

  // Reading tracker getters
  int get currentReadingSeconds => _readingTracker.currentReadingSeconds;

  double get currentScrollPercentage => _readingTracker.currentScrollPercentage;

  String? get currentTrackedDevocionalId =>
      _readingTracker.currentTrackedDevocionalId;

  // Supported languages - Updated to include Chinese
  static const List<String> _supportedLanguages = [
    'es',
    'en',
    'pt',
    'fr',
    'ja',
    'zh', // Add Chinese
  ];
  static const String _fallbackLanguage = 'es';

  List<String> get supportedLanguages => List.from(_supportedLanguages);

  // Get available Bible versions for current language
  List<String> get availableVersions {
    return Constants.bibleVersionsByLanguage[_selectedLanguage] ?? ['RVR1960'];
  }

  // Get available versions for a specific language
  List<String> getVersionsForLanguage(String language) {
    return Constants.bibleVersionsByLanguage[language] ?? [];
  }

  // ========== CONSTRUCTOR ==========
  DevocionalProvider() {
    debugPrint('🏗️ Provider: Constructor iniciado');

    // Initialize audio controller with DI
    _audioController = AudioController(getService<ITtsService>());
    _audioController.initialize();

    // Listen to audio controller changes and relay to our listeners
    _audioController.addListener(_onAudioStateChanged);

    debugPrint('✅ Provider: Constructor completado');
  }

  bool? get isSpeaking => null;

  /// Handle audio state changes
  void _onAudioStateChanged() {
    // Simply relay the change to our listeners
    // This keeps the main provider reactive to audio changes
    notifyListeners();
  }

  // ========== INITIALIZATION ==========
  Future<void> initializeData() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      String deviceLanguage = PlatformDispatcher.instance.locale.languageCode;

      String savedLanguage =
          prefs.getString('selectedLanguage') ?? deviceLanguage;
      _selectedLanguage = _getSupportedLanguageWithFallback(savedLanguage);

      if (_selectedLanguage != savedLanguage) {
        await prefs.setString('selectedLanguage', _selectedLanguage);
      }

      // Set default version based on selected language
      String savedVersion = prefs.getString('selectedVersion') ?? '';
      String defaultVersion =
          Constants.defaultVersionByLanguage[_selectedLanguage] ?? 'RVR1960';
      _selectedVersion =
          savedVersion.isNotEmpty ? savedVersion : defaultVersion;

      await _loadFavorites();
      await _loadInvitationDialogPreference();
      await _fetchAllDevocionalesForLanguage();
    } catch (e) {
      _errorMessage = 'Error al inicializar los datos: $e';
      debugPrint('Error en initializeData: $e');
      notifyListeners();
    } finally {
      _isLoading = false;
    }
  }

  String _getSupportedLanguageWithFallback(String requestedLanguage) {
    if (_supportedLanguages.contains(requestedLanguage)) {
      return requestedLanguage;
    }
    return _fallbackLanguage;
  }

  // ========== AUDIO METHODS (DELEGATES) ==========
  Future<void> playDevotional(Devocional devocional) async {
    debugPrint('🎵 Provider: playDevotional llamado para ${devocional.id}');
    // Update TTS language context before playing
    _audioController.ttsService
        .setLanguageContext(_selectedLanguage, _selectedVersion);
    await _audioController.playDevotional(devocional);
  }

  Future<void> pauseAudio() async {
    await _audioController.pause();
  }

  Future<void> resumeAudio() async {
    await _audioController.resume();
  }

  Future<void> stopAudio() async {
    await _audioController.stop();
  }

  Future<void> toggleAudioPlayPause(Devocional devocional) async {
    await _audioController.togglePlayPause(devocional);
  }

  Future<List<String>> getAvailableLanguages() async {
    return await _audioController.getAvailableLanguages();
  }

  Future<List<String>> getAvailableVoices() async {
    return await _audioController.getAvailableVoices();
  }

  Future<List<String>> getVoicesForLanguage(String language) async {
    return await _audioController.getVoicesForLanguage(language);
  }

  Future<void> setTtsLanguage(String language) async {
    await _audioController.setLanguage(language);
  }

  Future<void> setTtsVoice(Map<String, String> voice) async {
    await _audioController.setVoice(voice);
  }

  Future<void> setTtsSpeechRate(double rate) async {
    await _audioController.setSpeechRate(rate);
  }

  // ========== READING TRACKING (DELEGATES) ==========
  void startDevocionalTracking(String devocionalId,
      {ScrollController? scrollController}) {
    _readingTracker.startTracking(devocionalId,
        scrollController: scrollController);
  }

  void pauseTracking() {
    _readingTracker.pause();
  }

  void resumeTracking() {
    _readingTracker.resume();
  }

  Future<void> recordDevocionalRead(String devocionalId) async {
    final trackingData = _readingTracker.finalize(devocionalId);
    developer.log(
        '[PROVIDER] Finalizando tracking para: $devocionalId, tiempo: ${trackingData.readingTime}s, scroll: ${(trackingData.scrollPercentage * 100).toStringAsFixed(1)}%',
        name: 'DevocionalProvider');

    // Get feature flags from Remote Config (with ready check)
    try {
      final remoteConfig = getService<RemoteConfigService>();

      // Only use flags if Remote Config is ready
      if (remoteConfig.isReady) {
        final useLegacyMode = remoteConfig.featureLegacy;
        final useBlocMode = remoteConfig.featureBloc;

        developer.log(
          '[PROVIDER] Feature flags - legacy: $useLegacyMode, bloc: $useBlocMode',
          name: 'DevocionalProvider',
        );

        // Example: Use flags to control behavior
        if (useLegacyMode) {
          developer.log(
            '[PROVIDER] Using legacy mode for recording devotional',
            name: 'DevocionalProvider',
          );
          // Future: Add legacy recording logic here
        }

        if (useBlocMode) {
          developer.log(
            '[PROVIDER] BLoC mode enabled for devotional tracking',
            name: 'DevocionalProvider',
          );
          // Future: Emit event to BLoC instead of direct service call
        }
      } else {
        developer.log(
          '[PROVIDER] Remote Config not ready yet, using defaults',
          name: 'DevocionalProvider',
        );
      }
    } catch (e) {
      developer.log(
        '[PROVIDER] Error reading feature flags, using defaults: $e',
        name: 'DevocionalProvider',
        error: e,
      );
    }

    try {
      await _statsService.recordDevocionalRead(
        devocionalId: devocionalId,
        favoritesCount: _favoriteDevocionales.length,
        readingTimeSeconds: trackingData.readingTime,
        scrollPercentage: trackingData.scrollPercentage,
      );
      developer.log('[PROVIDER] Devocional guardado en stats: $devocionalId',
          name: 'DevocionalProvider');
      debugPrint('✅ Recorded devotional read: $devocionalId');
      notifyListeners();
    } catch (e) {
      developer.log('[PROVIDER] Error guardando devocional: $e',
          name: 'DevocionalProvider');
      debugPrint('❌ Error recording devotional read: $e');
    }
  }

  /// Registra que un devocional fue escuchado (para TTS)
  Future<String> recordDevocionalHeard(String devocionalId,
      double listenedPercentage, BuildContext context) async {
    try {
      // Usar el tracking unificado para registrar y verificar milestone
      await DevocionalesTracking()
          .recordDevocionalHeard(devocionalId, listenedPercentage);
      // Obtener stats actualizados tras registrar 'heard'
      final stats = await _statsService.getStats();
      notifyListeners(); // Notificar a la UI de cualquier cambio
      if (stats.readDevocionalIds.contains(devocionalId)) {
        // Si ya está en la lista de leídos/escuchados => ya fue registrado
        return 'ya_registrado';
      } else {
        // Si no está, asumimos que el registro fue guardado correctamente
        return 'guardado';
      }
    } catch (e) {
      debugPrint('❌ Error recording devotional heard: $e');
      return 'error';
    }
  }

  // ========== DATA LOADING ==========
  Future<void> _fetchAllDevocionalesForLanguage() async {
    _isLoading = true;
    _errorMessage = null;
    _isOfflineMode = false;
    notifyListeners();

    try {
      final int currentYear = DateTime.now().year;

      // Try local storage first
      Map<String, dynamic>? localData = await _loadFromLocalStorage(
          currentYear, _selectedLanguage, _selectedVersion);

      if (localData != null) {
        debugPrint('Loading from local storage');
        _isOfflineMode = true;
        await _processDevocionalData(localData);
        return;
      }

      // Load from API with language and version
      debugPrint(
          'Loading from API for language: $_selectedLanguage, version: $_selectedVersion');
      final String url = Constants.getDevocionalesApiUrlMultilingual(
          currentYear, _selectedLanguage, _selectedVersion);
      debugPrint('🔍 Requesting URL: $url');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to load from API: ${response.statusCode}');
      }

      final String responseBody = response.body;
      final Map<String, dynamic> data = json.decode(responseBody);
      await _processDevocionalData(data);
    } catch (e) {
      _errorMessage = 'Error al cargar los devocionales: $e';
      _allDevocionalesForCurrentLanguage = [];
      _filteredDevocionales = [];
      debugPrint('Error en _fetchAllDevocionalesForLanguage: $e');
      notifyListeners();
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _processDevocionalData(Map<String, dynamic> data) async {
    final Map<String, dynamic>? languageRoot =
        data['data'] as Map<String, dynamic>?;
    final Map<String, dynamic>? languageData =
        languageRoot?[_selectedLanguage] as Map<String, dynamic>?;

    if (languageData == null) {
      if (_selectedLanguage != _fallbackLanguage) {
        final Map<String, dynamic>? fallbackData =
            languageRoot?[_fallbackLanguage] as Map<String, dynamic>?;
        if (fallbackData != null) {
          _selectedLanguage = _fallbackLanguage;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('selectedLanguage', _fallbackLanguage);
          await _processLanguageData(fallbackData);
          return;
        }
      }

      debugPrint('No data found for any supported language');
      _allDevocionalesForCurrentLanguage = [];
      _filteredDevocionales = [];
      _errorMessage = 'No se encontraron datos disponibles en la API.';
      return;
    }

    await _processLanguageData(languageData);
  }

  Future<void> _processLanguageData(Map<String, dynamic> languageData) async {
    final List<Devocional> loadedDevocionales = [];

    languageData.forEach((dateKey, dateValue) {
      if (dateValue is List) {
        for (var devocionalJson in dateValue) {
          try {
            loadedDevocionales.add(
                Devocional.fromJson(devocionalJson as Map<String, dynamic>));
          } catch (e) {
            debugPrint('Error parsing devotional for $dateKey: $e');
          }
        }
      }
    });

    loadedDevocionales.sort((a, b) => a.date.compareTo(b.date));
    _allDevocionalesForCurrentLanguage = loadedDevocionales;
    _errorMessage = null;
    _filterDevocionalesByVersion();
  }

  void _filterDevocionalesByVersion() {
    _filteredDevocionales = _allDevocionalesForCurrentLanguage
        .where((devocional) => devocional.version == _selectedVersion)
        .toList();

    if (_filteredDevocionales.isEmpty &&
        _allDevocionalesForCurrentLanguage.isNotEmpty) {
      _errorMessage =
          'No se encontraron devocionales para la versión $_selectedVersion.';
    } else if (_allDevocionalesForCurrentLanguage.isEmpty) {
      _errorMessage = 'No hay devocionales disponibles.';
    } else {
      _errorMessage = null;
    }

    notifyListeners();
  }

  // ========== LANGUAGE & VERSION SETTINGS ==========
  void setSelectedLanguage(String language, BuildContext? context) async {
    String supportedLanguage = _getSupportedLanguageWithFallback(language);

    if (_selectedLanguage != supportedLanguage) {
      _selectedLanguage = supportedLanguage;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedLanguage', supportedLanguage);

      // Defensive: ensure version is valid for the new language
      List<String> versions =
          Constants.bibleVersionsByLanguage[supportedLanguage] ?? ['RVR1960'];
      String defaultVersion =
          Constants.defaultVersionByLanguage[supportedLanguage] ??
              versions.first;
      if (!versions.contains(_selectedVersion)) {
        _selectedVersion = defaultVersion;
        await prefs.setString('selectedVersion', defaultVersion);
      }

      // Update UI locale/translations via LocalizationProvider
      if (context != null && context.mounted) {
        final localizationProvider =
            Provider.of<LocalizationProvider>(context, listen: false);
        await localizationProvider.changeLanguage(supportedLanguage);
      }

      // Update TTS language context immediately
      _audioController.ttsService
          .setLanguageContext(_selectedLanguage, _selectedVersion);

      if (language != supportedLanguage) {
        debugPrint(
            'Language $language not available, using $supportedLanguage');
      }

      await _fetchAllDevocionalesForLanguage();
    }
  }

  void setSelectedVersion(String version) async {
    if (_selectedVersion != version) {
      _selectedVersion = version;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedVersion', version);
      // Actualizar el contexto de TTS al cambiar la versión
      _audioController.ttsService
          .setLanguageContext(_selectedLanguage, _selectedVersion);
      await _fetchAllDevocionalesForLanguage();
    }
  }

  // ========== FAVORITES MANAGEMENT ==========
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favoritesJson = prefs.getString('favorites');

    if (favoritesJson != null) {
      final List<dynamic> decodedList = json.decode(favoritesJson);
      _favoriteDevocionales = decodedList
          .map((item) => Devocional.fromJson(item as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String favoritesJson = json.encode(
      _favoriteDevocionales.map((devocional) => devocional.toJson()).toList(),
    );
    await prefs.setString('favorites', favoritesJson);
  }

  bool isFavorite(Devocional devocional) {
    return _favoriteDevocionales.any((fav) => fav.id == devocional.id);
  }

  void toggleFavorite(Devocional devocional, BuildContext context) {
    if (devocional.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede guardar devocional sin ID'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (isFavorite(devocional)) {
      _favoriteDevocionales.removeWhere((fav) => fav.id == devocional.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('devotionals_page.removed_from_favorites'.tr(),
              style: TextStyle(color: colorScheme.onSecondary)),
          duration: const Duration(seconds: 2),
          backgroundColor: colorScheme.secondary,
        ),
      );
    } else {
      _favoriteDevocionales.add(devocional);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('devotionals_page.added_to_favorites'.tr(),
              style: TextStyle(color: colorScheme.onSecondary)),
          duration: const Duration(seconds: 2),
          backgroundColor: colorScheme.secondary,
        ),
      );
    }

    _saveFavorites();
    _statsService.updateFavoritesCount(_favoriteDevocionales.length);
    notifyListeners();
  }

  /// Reload favorites from SharedPreferences after restore
  /// This method is called after backup restoration to sync the provider
  /// state with the updated SharedPreferences data
  Future<void> reloadFavoritesFromStorage() async {
    try {
      await _loadFavorites();
      notifyListeners(); // Notifica a todos los Consumers (FavoritesPage)
      debugPrint('✅ Provider: Favorites reloaded from storage after restore');
    } catch (e) {
      debugPrint('❌ Error reloading favorites from storage: $e');
    }
  }

  // ========== INVITATION DIALOG ==========
  Future<void> _loadInvitationDialogPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _showInvitationDialog = prefs.getBool('showInvitationDialog') ?? true;
  }

  Future<void> setInvitationDialogVisibility(bool shouldShow) async {
    _showInvitationDialog = shouldShow;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showInvitationDialog', shouldShow);
    notifyListeners();
  }

  // ========== OFFLINE FUNCTIONALITY ==========
  Future<Directory> _getLocalStorageDirectory() async {
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    final Directory devocionalesDir =
        Directory('${appDocumentsDir.path}/devocionales');

    if (!await devocionalesDir.exists()) {
      await devocionalesDir.create(recursive: true);
    }
    return devocionalesDir;
  }

  Future<String> _getLocalFilePath(int year, String language,
      [String? version]) async {
    final Directory storageDir = await _getLocalStorageDirectory();
    // Include version in filename for new languages, maintain backward compatibility for Spanish
    if (language == 'es' && version == 'RVR1960') {
      return '${storageDir.path}/devocional_${year}_$language.json';
    } else {
      final versionSuffix = version != null ? '_$version' : '';
      return '${storageDir.path}/devocional_${year}_$language$versionSuffix.json';
    }
  }

  Future<bool> hasLocalFile(int year, String language,
      [String? version]) async {
    try {
      final String filePath = await _getLocalFilePath(year, language, version);
      final File file = File(filePath);
      return await file.exists();
    } catch (e) {
      debugPrint('Error checking local file: $e');
      return false;
    }
  }

  Future<bool> downloadAndStoreDevocionales(int year) async {
    if (_isDownloading) return false;

    _isDownloading = true;
    _downloadStatus = 'Descargando devocionales del año $year...';
    notifyListeners();

    try {
      final String url = Constants.getDevocionalesApiUrlMultilingual(
          year, _selectedLanguage, _selectedVersion);
      debugPrint('🔍 Requesting URL: $url');
      debugPrint('🔍 Language: $_selectedLanguage, Version: $_selectedVersion');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 404) {
        debugPrint(
            '❌ File not found (404): $_selectedLanguage $_selectedVersion year $year');
        throw Exception(
            'File not available for $_selectedLanguage $_selectedVersion year $year');
      } else if (response.statusCode != 200) {
        debugPrint(
            '❌ HTTP Error ${response.statusCode}: ${response.reasonPhrase}');
        throw Exception(
            'HTTP Error ${response.statusCode}: ${response.reasonPhrase}');
      }

      final Map<String, dynamic> jsonData = json.decode(response.body);

      if (jsonData['data'] == null) {
        throw Exception('Invalid JSON structure: missing "data" field');
      }

      final String filePath =
          await _getLocalFilePath(year, _selectedLanguage, _selectedVersion);
      final File file = File(filePath);
      await file.writeAsString(response.body);

      _downloadStatus = 'Devocionales del año $year descargados exitosamente';
      debugPrint('✅ File saved to: $filePath');
      return true;
    } catch (e) {
      _downloadStatus = 'Error al descargar devocionales: $e';
      debugPrint('❌ Error in downloadAndStoreDevocionales: $e');
      return false;
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> _loadFromLocalStorage(int year, String language,
      [String? version]) async {
    try {
      final String filePath = await _getLocalFilePath(year, language, version);
      final File file = File(filePath);

      if (!await file.exists()) return null;

      final String content = await file.readAsString();
      return json.decode(content) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error loading from local storage: $e');
      return null;
    }
  }

  Future<void> clearOldLocalFiles() async {
    try {
      final Directory storageDir = await _getLocalStorageDirectory();
      final List<FileSystemEntity> files = await storageDir.list().toList();

      for (final FileSystemEntity file in files) {
        if (file is File) {
          await file.delete();
          debugPrint('File deleted: ${file.path}');
        }
      }

      _downloadStatus = 'Archivos locales eliminados';
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting local files: $e');
      _downloadStatus = 'Error al eliminar archivos locales';
      notifyListeners();
    }
  }

  // ========== UTILITY METHODS ==========
  bool isLanguageSupported(String language) {
    return _supportedLanguages.contains(language);
  }

  Future<bool> downloadCurrentYearDevocionales() async {
    final int currentYear = DateTime.now().year;

    // Try current year first
    bool success = await downloadAndStoreDevocionales(currentYear);

    // If current year fails, try fallback logic for missing versions
    if (!success) {
      success = await _tryVersionFallback(currentYear);
    }

    return success;
  }

  Future<bool> _tryVersionFallback(int year) async {
    debugPrint(
        '🔄 Trying version fallback for $_selectedLanguage $_selectedVersion');

    // Get available versions for the language
    final availableVersions =
        Constants.bibleVersionsByLanguage[_selectedLanguage] ?? [];
    debugPrint(
        '🔄 Available versions for $_selectedLanguage: $availableVersions');

    // Try other versions for the same language, prioritizing the default version first
    final defaultVersion =
        Constants.defaultVersionByLanguage[_selectedLanguage];
    final versionsToTry = <String>[];

    // Add default version first if it's different from current
    if (defaultVersion != null && defaultVersion != _selectedVersion) {
      versionsToTry.add(defaultVersion);
    }

    // Add other versions
    for (final version in availableVersions) {
      if (version != _selectedVersion && version != defaultVersion) {
        versionsToTry.add(version);
      }
    }

    debugPrint('🔄 Versions to try in order: $versionsToTry');

    for (final version in versionsToTry) {
      debugPrint('🔄 Trying fallback version: $version');
      final originalVersion = _selectedVersion;
      _selectedVersion = version;

      final success = await downloadAndStoreDevocionales(year);
      if (success) {
        debugPrint('✅ Fallback successful with version: $version');
        // Update stored version preference
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('selected_version_$_selectedLanguage', version);
        await prefs.setString(
            'selectedVersion', version); // Also update global preference
        notifyListeners();
        return true;
      }

      // Restore original version if fallback failed
      _selectedVersion = originalVersion;
    }

    debugPrint('❌ All version fallbacks failed for $_selectedLanguage');
    return false;
  }

  Future<bool> downloadDevocionalesForYear(int year) async {
    return await downloadAndStoreDevocionales(year);
  }

  Future<bool> downloadDevocionalesWithProgress({
    required Function(double) onProgress,
    int startYear = 2025,
    int endYear = 2026,
  }) async {
    final totalYears = endYear - startYear + 1;
    int doneYears = 0;
    bool allSuccess = true;

    for (int year = startYear; year <= endYear; year++) {
      bool success = await downloadAndStoreDevocionales(year);
      doneYears++;
      double progress = doneYears / totalYears;
      onProgress(progress);
      if (!success) allSuccess = false;
    }

    return allSuccess;
  }

  Future<bool> hasCurrentYearLocalData() async {
    final int currentYear = DateTime.now().year;
    return await hasLocalFile(currentYear, _selectedLanguage, _selectedVersion);
  }

  Future<bool> hasTargetYearsLocalData() async {
    final bool has2025 =
        await hasLocalFile(2025, _selectedLanguage, _selectedVersion);
    final bool has2026 =
        await hasLocalFile(2026, _selectedLanguage, _selectedVersion);
    return has2025 && has2026;
  }

  Future<void> forceRefreshFromAPI() async {
    _isOfflineMode = false;
    await _fetchAllDevocionalesForLanguage();
  }

  void clearDownloadStatus() {
    _downloadStatus = null;
    notifyListeners();
  }

  void forceUIUpdate() {
    notifyListeners();
  }

  // ========== CLEANUP ==========
  @override
  void dispose() {
    debugPrint('🧹 Provider: Disposing...');

    // Dispose audio controller
    _audioController.removeListener(_onAudioStateChanged);
    _audioController.dispose();

    // Dispose reading tracker
    _readingTracker.dispose();

    super.dispose();
    debugPrint('✅ Provider: Disposed');
  }

  void stop() {}

  void speakDevocional(String s) {}

  /// Devuelve la lista de devocionales no leídos según los IDs guardados en stats
  Future<List<Devocional>> getDevocionalesNoLeidos() async {
    final stats = await _statsService.getStats();
    final leidos = stats.readDevocionalIds.toSet();
    final noLeidos =
        _filteredDevocionales.where((d) => !leidos.contains(d.id)).toList();
    debugPrint(
        '🔎 [NO LEÍDOS] Devocionales no leídos: [1m${noLeidos.length}[0m');
    if (noLeidos.isNotEmpty) {
      debugPrint(
          '📖 [PRIMEROS] Mostrando: ${noLeidos.take(3).map((d) => d.id).toList()}');
    } else {
      debugPrint('🎉 [COMPLETADO] ¡No hay devocionales pendientes!');
    }
    return noLeidos;
  }
}

// ========== READING TRACKER ==========
/// Separate class to handle reading tracking logic
class ReadingTracker {
  DateTime? _startTime;
  DateTime? _pausedTime;
  int _accumulatedSeconds = 0;
  Timer? _timer;

  double _maxScrollPercentage = 0.0;
  ScrollController? _scrollController;

  String? _currentDevocionalId;
  String? _lastFinalizedId;
  TrackingData? _lastFinalizedData;

  // Getters
  int get currentReadingSeconds {
    if (_startTime == null) return _accumulatedSeconds;
    if (_pausedTime != null) {
      // Si está pausado, solo devuelve el acumulado
      return _accumulatedSeconds;
    } else {
      // Si está activo, suma el tiempo actual
      return _accumulatedSeconds +
          DateTime.now().difference(_startTime!).inSeconds;
    }
  }

  double get currentScrollPercentage => _maxScrollPercentage;

  String? get currentTrackedDevocionalId => _currentDevocionalId;

  /// Start tracking for a devotional
  void startTracking(String devocionalId,
      {ScrollController? scrollController}) {
    if (_currentDevocionalId == devocionalId) {
      _resumeTimer();
      return;
    }

    if (_currentDevocionalId != null) {
      _finalizeCurrentTracking();
    }

    _initializeTracking(devocionalId, scrollController);
  }

  void _initializeTracking(
      String devocionalId, ScrollController? scrollController) {
    _currentDevocionalId = devocionalId;
    _startTime = DateTime.now();
    _pausedTime = null;
    _accumulatedSeconds = 0;
    _maxScrollPercentage = 0.0;

    _setupScrollController(scrollController);
    _startTimer();
  }

  void _setupScrollController(ScrollController? scrollController) {
    _scrollController = scrollController;
    if (scrollController != null) {
      scrollController.addListener(_onScrollChanged);
    }
  }

  void _onScrollChanged() {
    if (_scrollController?.hasClients == true) {
      final maxScrollExtent = _scrollController!.position.maxScrollExtent;
      final currentScrollPosition = _scrollController!.position.pixels;

      if (maxScrollExtent > 0) {
        final scrollPercentage =
            (currentScrollPosition / maxScrollExtent).clamp(0.0, 1.0);
        if (scrollPercentage > _maxScrollPercentage) {
          _maxScrollPercentage = scrollPercentage;
        }
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Timer just keeps running, calculations are done on demand
    });
  }

  void pause() {
    if (_currentDevocionalId == null || _startTime == null) return;
    final now = DateTime.now();
    final sessionSeconds = now.difference(_startTime!).inSeconds;
    _accumulatedSeconds += sessionSeconds;
    _pausedTime = now;
    debugPrint(
        '[TRACKER] pause() - acumulado: $_accumulatedSeconds segundos, session: $sessionSeconds, startTime: $_startTime, pausedTime: $_pausedTime');
    _timer?.cancel();
  }

  void resume() {
    if (_currentDevocionalId == null || _pausedTime == null) return;
    _startTime = DateTime.now();
    debugPrint(
        '[TRACKER] resume() - acumulado antes de reanudar: $_accumulatedSeconds segundos, pausedTime: $_pausedTime');
    _pausedTime = null;
    _startTimer();
  }

  void _resumeTimer() {
    if (_timer?.isActive != true) {
      _startTimer();
    }
  }

  void _finalizeCurrentTracking() {
    if (_currentDevocionalId == null) return;
    final totalTime =
        (_accumulatedSeconds + _getCurrentSessionSeconds()).toInt();
    _lastFinalizedId = _currentDevocionalId;
    _lastFinalizedData = TrackingData(
      readingTime: totalTime,
      scrollPercentage: _maxScrollPercentage,
    );
    _cleanup();
  }

  TrackingData finalize(String devocionalId) {
    TrackingData result;
    if (_currentDevocionalId == devocionalId) {
      // Currently tracked devotional
      final totalTime =
          (_accumulatedSeconds + _getCurrentSessionSeconds()).toInt();
      result = TrackingData(
        readingTime: totalTime,
        scrollPercentage: _maxScrollPercentage,
      );
      _cleanup();
    } else if (_lastFinalizedId == devocionalId && _lastFinalizedData != null) {
      // Recently finalized devotional
      result = _lastFinalizedData!;
      _lastFinalizedId = null;
      _lastFinalizedData = null;
    } else {
      // Unknown devotional
      result = TrackingData(readingTime: 0, scrollPercentage: 0.0);
    }
    return result;
  }

  void _cleanup() {
    _timer?.cancel();
    _timer = null;

    if (_scrollController != null) {
      _scrollController!.removeListener(_onScrollChanged);
      _scrollController = null;
    }

    _currentDevocionalId = null;
    _startTime = null;
    _pausedTime = null;
    _accumulatedSeconds = 0;
    _maxScrollPercentage = 0.0;
  }

  void dispose() {
    _cleanup();
    _lastFinalizedId = null;
    _lastFinalizedData = null;
  }

  int _getCurrentSessionSeconds() {
    if (_startTime == null || _pausedTime != null) return 0;
    return DateTime.now().difference(_startTime!).inSeconds;
  }
}

/// Data class for tracking results
class TrackingData {
  final int readingTime;
  final double scrollPercentage;

  TrackingData({
    required this.readingTime,
    required this.scrollPercentage,
  });
}
