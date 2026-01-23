// lib/providers/devocional_provider.dart - SIMPLIFIED VERSION

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:devocional_nuevo/constants/devocional_years.dart';
import 'package:devocional_nuevo/controllers/audio_controller.dart'; // NEW
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/localization_provider.dart';
import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/devocionales_tracking.dart';
import 'package:devocional_nuevo/services/remote_config_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:devocional_nuevo/services/tts/i_tts_service.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart' show Provider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

/// Simplified provider focused on data management only
/// Audio functionality moved to AudioController
class DevocionalProvider with ChangeNotifier {
  // ========== CONCURRENCY PROTECTION ==========
  final _favoritesLock = Lock();

  // ========== CORE DATA ==========
  List<Devocional> _allDevocionalesForCurrentLanguage = [];
  List<Devocional> _filteredDevocionales = [];
  List<Devocional> _favoriteDevocionales = [];
  Set<String> _favoriteIds = {}; // ID-based favorites storage

  bool _isLoading = false;
  bool _isSwitchingVersion = false;
  String? _errorMessage;
  String _selectedLanguage = 'es';
  String _selectedVersion = 'RVR1960';
  bool _showInvitationDialog = true;

  // Session-based telemetry throttle flags
  bool _hasFiredMismatchTelemetry = false;

  // ========== SERVICES ==========
  final SpiritualStatsService _statsService = SpiritualStatsService();
  AudioController?
      _audioController; // nullable to allow disabling audio in tests

  // ========== OFFLINE FUNCTIONALITY ==========
  bool _isDownloading = false;
  String? _downloadStatus;
  bool _isOfflineMode = false;

  // ========== READING TRACKER ==========
  final ReadingTracker _readingTracker = ReadingTracker();

  // ========== GETTERS ==========
  List<Devocional> get devocionales => _filteredDevocionales;

  bool get isLoading => _isLoading;
  
  bool get isSwitchingVersion => _isSwitchingVersion;

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
  AudioController get audioController => _audioController!;

  bool get isAudioPlaying => _audioController!.isPlaying;

  bool get isAudioPaused => _audioController!.isPaused;

  String? get currentPlayingDevocionalId =>
      _audioController!.currentDevocionalId;

  bool isDevocionalPlaying(String devocionalId) =>
      _audioController!.isDevocionalPlaying(devocionalId);

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
  DevocionalProvider({
    http.Client? httpClient,
    bool enableAudio = true,
  })  : assert(
          enableAudio || !kReleaseMode,
          'Audio must not be disabled in release builds',
        ),
        httpClient = httpClient ?? http.Client() {
    debugPrint('🏗️ Provider: Constructor iniciado');

    // Initialize audio controller with DI if enabled
    if (enableAudio) {
      _audioController = AudioController(getService<ITtsService>());
      _audioController!.initialize();

      // Listen to audio controller changes and relay to our listeners
      _audioController!.addListener(_onAudioStateChanged);
    }

    debugPrint('✅ Provider: Constructor completado');
  }

  final http.Client httpClient;

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
    _audioController!.ttsService.setLanguageContext(
      _selectedLanguage,
      _selectedVersion,
    );
    await _audioController!.playDevotional(devocional);
  }

  Future<void> pauseAudio() async {
    await _audioController!.pause();
  }

  Future<void> resumeAudio() async {
    await _audioController!.resume();
  }

  Future<void> stopAudio() async {
    await _audioController!.stop();
  }

  Future<void> toggleAudioPlayPause(Devocional devocional) async {
    await _audioController!.togglePlayPause(devocional);
  }

  Future<List<String>> getAvailableLanguages() async {
    return await _audioController!.getAvailableLanguages();
  }

  Future<List<String>> getAvailableVoices() async {
    return await _audioController!.getAvailableVoices();
  }

  Future<List<String>> getVoicesForLanguage(String language) async {
    return await _audioController!.getVoicesForLanguage(language);
  }

  Future<void> setTtsLanguage(String language) async {
    await _audioController!.setLanguage(language);
  }

  Future<void> setTtsVoice(Map<String, String> voice) async {
    await _audioController!.setVoice(voice);
  }

  Future<void> setTtsSpeechRate(double rate) async {
    await _audioController!.setSpeechRate(rate);
  }

  // ========== READING TRACKING (DELEGATES) ==========
  void startDevocionalTracking(
    String devocionalId, {
    ScrollController? scrollController,
  }) {
    _readingTracker.startTracking(
      devocionalId,
      scrollController: scrollController,
    );
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
      '[PROVIDER] Finalizando tracking para: $devocionalId, tiempo: \\${trackingData.readingTime}s, scroll: \\${(trackingData.scrollPercentage * 100).toStringAsFixed(1)}%',
      name: 'DevocionalProvider',
    );

    // Get feature flags from Remote Config (with ready check)
    try {
      final remoteConfig = getService<RemoteConfigService>();
      final analytics = getService<AnalyticsService>();

      if (remoteConfig.isReady) {
        final useLegacy = remoteConfig.featureLegacy;
        final useBloc = remoteConfig.featureBloc;

        developer.log(
          '[PROVIDER] Feature flags - legacy: $useLegacy, bloc: $useBloc',
          name: 'DevocionalProvider',
        );

        // 🔥 TRACK cual modo se usó
        await analytics.logCustomEvent(
          eventName: 'devotional_tracking_mode',
          parameters: {
            'mode': useBloc ? 'bloc' : 'legacy',
            'legacy_flag': useLegacy,
            'bloc_flag': useBloc,
            'remote_config_ready': true,
            'devocional_id': devocionalId,
          },
        );

        if (useBloc) {
          developer.log(
            '[PROVIDER] Using BLoC tracking',
            name: 'DevocionalProvider',
          );
          try {
            // TODO: BLoC tracking logic
            await analytics.logCustomEvent(
              eventName: 'devotional_bloc_success',
              parameters: {'devocional_id': devocionalId},
            );
          } catch (e, stack) {
            await analytics.logCustomEvent(
              eventName: 'devotional_bloc_error',
              parameters: {
                'devocional_id': devocionalId,
                'error': e.toString(),
              },
            );
            await FirebaseCrashlytics.instance.recordError(
              e,
              stack,
              reason: 'BLoC tracking mode failed',
            );
          }
        } else {
          developer.log(
            '[PROVIDER] Using legacy tracking',
            name: 'DevocionalProvider',
          );
          await analytics.logCustomEvent(
            eventName: 'devotional_legacy_success',
            parameters: {'devocional_id': devocionalId},
          );
        }
      } else {
        await analytics.logCustomEvent(
          eventName: 'devotional_tracking_mode',
          parameters: {
            'mode': 'legacy',
            'remote_config_ready': false,
            'reason': 'remote_config_not_ready',
            'devocional_id': devocionalId,
          },
        );
        developer.log(
          '[PROVIDER] Remote Config not ready yet, using defaults',
          name: 'DevocionalProvider',
        );
      }
    } catch (e, stack) {
      developer.log(
        '[PROVIDER] Error reading feature flags, using defaults: $e',
        name: 'DevocionalProvider',
        error: e,
      );
      await FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Error reading feature flags in recordDevocionalRead',
      );
    }

    try {
      await _statsService.recordDevocionalRead(
        devocionalId: devocionalId,
        favoritesCount: _favoriteDevocionales.length,
        readingTimeSeconds: trackingData.readingTime,
        scrollPercentage: trackingData.scrollPercentage,
      );
      developer.log(
        '[PROVIDER] Devocional guardado en stats: $devocionalId',
        name: 'DevocionalProvider',
      );
      debugPrint('✅ Recorded devotional read: $devocionalId');
      notifyListeners();
    } catch (e) {
      developer.log(
        '[PROVIDER] Error guardando devocional: $e',
        name: 'DevocionalProvider',
      );
      debugPrint('❌ Error recording devotional read: $e');
    }
  }

  /// Registra que un devocional fue escuchado (para TTS)
  Future<String> recordDevocionalHeard(
    String devocionalId,
    double listenedPercentage,
    BuildContext context,
  ) async {
    try {
      // Usar el tracking unificado para registrar y verificar milestone
      await DevocionalesTracking().recordDevocionalHeard(
        devocionalId,
        listenedPercentage,
      );
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
      // Load devotionals from all available years to ensure no data loss
      // All historical years remain accessible
      final List<int> yearsToLoad = DevocionalYears.availableYears;
      final List<Devocional> allDevocionales = [];
      final Set<int> loadedLocalYears = {};
      final Set<int> loadedApiYears = {};

      // Try loading from local storage first for all years
      for (final year in yearsToLoad) {
        Map<String, dynamic>? localData = await _loadFromLocalStorage(
          year,
          _selectedLanguage,
          _selectedVersion,
        );

        if (localData != null) {
          debugPrint('Loading from local storage for year $year');
          final List<Devocional> yearDevocionales =
              await _extractDevocionalesFromData(localData);
          if (yearDevocionales.isNotEmpty) {
            loadedLocalYears.add(year);
            allDevocionales.addAll(yearDevocionales);
          }
        }
      }

      // If we loaded all years from local storage, use that
      if (loadedLocalYears.length == yearsToLoad.length) {
        _isOfflineMode = true;
        allDevocionales.sort((a, b) => a.date.compareTo(b.date));
        _allDevocionalesForCurrentLanguage = allDevocionales;
        _errorMessage = null;
        _filterDevocionalesByVersion();
        return;
      }

      // Otherwise, load missing years from API
      for (final year in yearsToLoad) {
        // Skip years already loaded from local storage
        if (loadedLocalYears.contains(year)) {
          continue;
        }

        try {
          debugPrint(
            'Loading from API for year $year, language: $_selectedLanguage, version: $_selectedVersion',
          );
          final String url = Constants.getDevocionalesApiUrlMultilingual(
            year,
            _selectedLanguage,
            _selectedVersion,
          );
          debugPrint('🔍 Requesting URL: $url');
          final response = await httpClient.get(Uri.parse(url));

          if (response.statusCode == 200) {
            final String responseBody = response.body;
            final Map<String, dynamic> data = json.decode(responseBody);
            final List<Devocional> yearDevocionales =
                await _extractDevocionalesFromData(data);
            if (yearDevocionales.isNotEmpty) {
              loadedApiYears.add(year);
              allDevocionales.addAll(yearDevocionales);
            }
          } else {
            debugPrint(
              '⚠️ Failed to load year $year from API: ${response.statusCode}',
            );
          }
        } catch (e) {
          debugPrint('⚠️ Error loading year $year: $e');
          // Continue to next year instead of failing completely
        }
      }

      if (allDevocionales.isEmpty) {
        throw Exception('No devotionals loaded from any year');
      }

      // Sort all devotionals by date
      allDevocionales.sort((a, b) => a.date.compareTo(b.date));
      _allDevocionalesForCurrentLanguage = allDevocionales;
      _errorMessage = null;
      _filterDevocionalesByVersion();

      // Log which years were successfully loaded
      final loadedYears = {...loadedLocalYears, ...loadedApiYears};
      debugPrint(
        '✅ Successfully loaded devotionals from years: ${loadedYears.toList()}',
      );
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

  /// Extract devotionals list from JSON data structure
  Future<List<Devocional>> _extractDevocionalesFromData(
    Map<String, dynamic> data,
  ) async {
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
          return await _parseLanguageData(fallbackData);
        }
      }

      debugPrint('No data found for any supported language');
      return [];
    }

    return await _parseLanguageData(languageData);
  }

  /// Parse language data and return list of devotionals
  Future<List<Devocional>> _parseLanguageData(
    Map<String, dynamic> languageData,
  ) async {
    final List<Devocional> loadedDevocionales = [];

    languageData.forEach((dateKey, dateValue) {
      if (dateValue is List) {
        for (var devocionalJson in dateValue) {
          try {
            loadedDevocionales.add(
              Devocional.fromJson(devocionalJson as Map<String, dynamic>),
            );
          } catch (e) {
            debugPrint('Error parsing devotional for $dateKey: $e');
          }
        }
      }
    });

    return loadedDevocionales;
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

    _syncFavoritesWithLoadedDevotionals();
    notifyListeners();
  }

  // ========== LANGUAGE & VERSION SETTINGS ==========
  Future<void> setSelectedLanguage(String language, BuildContext? context) async {
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
        final localizationProvider = Provider.of<LocalizationProvider>(
          context,
          listen: false,
        );
        await localizationProvider.changeLanguage(supportedLanguage);
      }

      // Update TTS language context immediately
      if (_audioController != null) {
        _audioController!.ttsService.setLanguageContext(
          _selectedLanguage,
          _selectedVersion,
        );
      }

      if (language != supportedLanguage) {
        debugPrint(
          'Language $language not available, using $supportedLanguage',
        );
      }

      await _fetchAllDevocionalesForLanguage();
    }
  }

  Future<void> setSelectedVersion(String version) async {
    if (_selectedVersion != version) {
      _isSwitchingVersion = true;
      notifyListeners();
      
      try {
        _selectedVersion = version;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('selectedVersion', version);
        // Actualizar el contexto de TTS al cambiar la versión
        if (_audioController != null) {
          _audioController!.ttsService.setLanguageContext(
            _selectedLanguage,
            _selectedVersion,
          );
        }
        await _fetchAllDevocionalesForLanguage();
      } finally {
        _isSwitchingVersion = false;
        notifyListeners();
      }
    }
  }

  // ========== FAVORITES MANAGEMENT ==========
  Future<void> _loadFavorites() async {
    await _favoritesLock.synchronized(() async {
      final prefs = await SharedPreferences.getInstance();
      final String? favoriteIdsJson = prefs.getString('favorite_ids');

      if (favoriteIdsJson != null) {
        try {
          final List<dynamic> decodedList = json.decode(favoriteIdsJson);
          _favoriteIds = decodedList.cast<String>().toSet();
          developer.log(
            '⭐FAVORITES_LOAD: ${_favoriteIds.length} IDs loaded',
            name: 'Favorites',
          );
        } catch (e) {
          developer.log(
            '❌FAVORITES_ERROR: Failed decoding favorite_ids: $e',
            name: 'Favorites',
          );
          _favoriteIds = {};
        }
      } else {
        // Legacy migration fallback
        final String? favoritesJson = prefs.getString('favorites');
        if (favoritesJson != null) {
          try {
            final List<dynamic> decodedList = json.decode(favoritesJson);
            final int totalLegacy = decodedList.length;

            _favoriteIds = decodedList
                .map((item) =>
                    Devocional.fromJson(item as Map<String, dynamic>).id)
                .where((id) => id.isNotEmpty)
                .toSet();

            final int migrated = _favoriteIds.length;
            final int dropped = totalLegacy - migrated;

            // Save migrated favorites (will acquire lock internally)
            await _saveFavoritesInternal();

            // Clean up legacy key after successful migration
            if (_favoriteIds.isNotEmpty) {
              await prefs.remove('favorites');
              developer.log(
                '⭐FAVORITES_CLEANUP: Legacy key removed',
                name: 'Favorites',
              );
            }

            developer.log(
              '⭐FAVORITES_MIGRATE: $migrated migrated from legacy (dropped: $dropped)',
              name: 'Favorites',
            );

            // Log telemetry for migration
            try {
              final analytics = getService<AnalyticsService>();

              // Log migration success
              analytics.logCustomEvent(
                eventName: 'favorites_migration_success',
                parameters: {
                  'total_legacy': totalLegacy,
                  'migrated': migrated,
                  'dropped': dropped,
                },
              );

              // Log data loss if any IDs were dropped
              if (dropped > 0) {
                analytics.logCustomEvent(
                  eventName: 'favorites_migration_data_loss',
                  parameters: {
                    'total_legacy': totalLegacy,
                    'migrated': migrated,
                    'dropped': dropped,
                  },
                );
                developer.log(
                  '⚠️FAVORITES_WARN: Migration data loss - $dropped favorites had empty IDs',
                  name: 'Favorites',
                );
              }
            } catch (e) {
              developer.log(
                '❌FAVORITES_ERROR: Failed to send migration telemetry: $e',
                name: 'Favorites',
              );
            }
          } catch (e) {
            developer.log(
              '❌FAVORITES_ERROR: Failed loading legacy favorites: $e',
              name: 'Favorites',
            );
            _favoriteIds = {};

            // Log migration failure
            try {
              final analytics = getService<AnalyticsService>();
              analytics.logCustomEvent(
                eventName: 'favorites_migration_failure',
                parameters: {
                  'error': e.toString(),
                },
              );
            } catch (analyticsError) {
              developer.log(
                '❌FAVORITES_ERROR: Failed to send migration failure telemetry: $analyticsError',
                name: 'Favorites',
              );
            }
          }
        } else {
          developer.log(
            '⭐FAVORITES_LOAD: New user, no favorites',
            name: 'Favorites',
          );
        }
      }
    });
  }

  /// Internal save method that assumes lock is already held
  Future<void> _saveFavoritesInternal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('favorite_ids', json.encode(_favoriteIds.toList()));
      developer.log(
        '⭐FAVORITES_SAVE: ${_favoriteIds.length} IDs saved',
        name: 'Favorites',
      );

      // Optional: persist a local schema version for favorites to allow
      // future migrations to detect and upgrade stored format.
      try {
        await prefs.setInt(
          'favorites_schema_version',
          Constants.favoritesSchemaVersion,
        );
      } catch (e) {
        developer.log(
          '❌FAVORITES_ERROR: Failed to set favorites_schema_version: $e',
          name: 'Favorites',
        );
      }
    } catch (e) {
      developer.log(
        '❌FAVORITES_ERROR: Save failed: $e',
        name: 'Favorites',
      );
      rethrow;
    }
  }

  Future<void> _saveFavorites() async {
    await _favoritesLock.synchronized(() async {
      await _saveFavoritesInternal();
    });
  }

  /// Public helper: persist current favorites to SharedPreferences.
  /// This is intentionally a thin wrapper around [_saveFavorites] so tests
  /// can call it without relying on UI interactions.
  Future<void> saveFavorites() async {
    await _saveFavorites();
  }

  /// Public helper: add a favorite ID programmatically (no UI) and persist it.
  /// Useful for unit tests or programmatic changes that don't need SnackBars.
  Future<void> addFavoriteId(String id) async {
    if (id.isEmpty) return;

    int count = 0;
    bool wasAdded = false;

    await _favoritesLock.synchronized(() async {
      // Check for duplicates to avoid unnecessary saves
      if (_favoriteIds.contains(id)) {
        return;
      }
      _favoriteIds.add(id);
      wasAdded = true;
      // Keep _favoriteDevocionales in sync only if possible; for tests we only
      // need the persisted IDs and schema version.
      count = _favoriteIds.length;
      await _saveFavoritesInternal();
    });

    // Update stats outside lock to avoid blocking critical section
    if (wasAdded) {
      _statsService.updateFavoritesCount(count);
      notifyListeners();
    }
  }

  void _syncFavoritesWithLoadedDevotionals() {
    if (_favoriteIds.isEmpty || _allDevocionalesForCurrentLanguage.isEmpty) {
      _favoriteDevocionales = [];
      return;
    }

    _favoriteDevocionales = _allDevocionalesForCurrentLanguage
        .where((d) => _favoriteIds.contains(d.id))
        .toList();

    developer.log(
      '⭐FAVORITES_SYNC: ${_favoriteDevocionales.length} synced from ${_favoriteIds.length} IDs',
      name: 'Favorites',
    );

    // Optional telemetry: detect and report mismatch between stored IDs and
    // the devotionals actually found for the current language/version.
    // Use session-based throttling to prevent analytics flooding
    if (_favoriteIds.length != _favoriteDevocionales.length &&
        !_hasFiredMismatchTelemetry) {
      _hasFiredMismatchTelemetry = true;
      try {
        final analytics = getService<AnalyticsService>();
        analytics.logCustomEvent(
          eventName: 'favorites_id_mismatch',
          parameters: {
            'favorite_ids_count': _favoriteIds.length,
            'favorite_devocionales_count': _favoriteDevocionales.length,
            'language': _selectedLanguage,
            'version': _selectedVersion,
          },
        );
        developer.log(
          '[PROVIDER] favorites_id_mismatch logged: ids=${_favoriteIds.length}, found=${_favoriteDevocionales.length}',
          name: 'DevocionalProvider',
        );
      } catch (e) {
        developer.log(
          '❌FAVORITES_ERROR: Failed to send favorites mismatch telemetry: $e',
          name: 'Favorites',
        );
      }
    } else if (_favoriteIds.length != _favoriteDevocionales.length) {
      developer.log(
        '⚠️FAVORITES_WARN: Mismatch persists (throttled)',
        name: 'Favorites',
      );
    }
  }

  bool isFavorite(Devocional devocional) {
    return _favoriteIds.contains(devocional.id);
  }

  /// Toggle favorite status for a devotional
  /// Returns true if favorite was added, false if removed
  /// Throws an exception if the operation fails
  Future<bool> toggleFavorite(String id) async {
    if (id.isEmpty) {
      developer.log(
        '❌FAVORITES_ERROR: Cannot toggle favorite with empty ID',
        name: 'Favorites',
      );
      throw ArgumentError('Cannot toggle favorite with empty ID');
    }

    return await _favoritesLock.synchronized(() async {
      try {
        final wasAdded = !_favoriteIds.contains(id);

        if (wasAdded) {
          _favoriteIds.add(id);
          final dev = _allDevocionalesForCurrentLanguage
              .where((d) => d.id == id)
              .firstOrNull;
          if (dev != null) {
            _favoriteDevocionales.add(dev);
          }
        } else {
          _favoriteIds.remove(id);
          _favoriteDevocionales.removeWhere((d) => d.id == id);
        }

        final count = _favoriteIds.length;
        await _saveFavoritesInternal();

        // Update stats outside lock to avoid blocking critical section
        _statsService.updateFavoritesCount(count);
        notifyListeners();

        return wasAdded;
      } catch (e, stack) {
        developer.log(
          'Failed to toggle favorite',
          error: e,
          stackTrace: stack,
          name: 'Favorites',
        );
        rethrow; // Let UI handle
      }
    });
  }

  /// Legacy method for backwards compatibility with BuildContext
  /// Wraps the new toggleFavorite and shows SnackBar messages
  @Deprecated('Use toggleFavorite(String id) instead')
  void toggleFavoriteWithContext(
      Devocional devocional, BuildContext context) async {
    if (devocional.id.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se puede guardar devocional sin ID'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      final wasAdded = await toggleFavorite(devocional.id);
      if (!context.mounted) return;

      final ColorScheme colorScheme = Theme.of(context).colorScheme;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasAdded
                ? 'devotionals_page.added_to_favorites'.tr()
                : 'devotionals_page.removed_from_favorites'.tr(),
            style: TextStyle(color: colorScheme.onSecondary),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: colorScheme.secondary,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('errors.update_favorite_failed'.tr())),
      );
    }
  }

  /// Reload favorites from SharedPreferences after restore
  /// This method is called after backup restoration to sync the provider
  /// state with the updated SharedPreferences data
  Future<void> reloadFavoritesFromStorage() async {
    try {
      await _loadFavorites();
      await _favoritesLock.synchronized(() async {
        _syncFavoritesWithLoadedDevotionals();
      });
      notifyListeners(); // Notifica a todos los Consumers (FavoritesPage)
      developer.log(
        '⭐FAVORITES_LOAD: Favorites reloaded from storage after restore',
        name: 'Favorites',
      );
    } catch (e) {
      developer.log(
        '❌FAVORITES_ERROR: Error reloading favorites from storage: $e',
        name: 'Favorites',
      );
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
    final Directory devocionalesDir = Directory(
      '${appDocumentsDir.path}/devocionales',
    );

    if (!await devocionalesDir.exists()) {
      await devocionalesDir.create(recursive: true);
    }
    return devocionalesDir;
  }

  Future<String> _getLocalFilePath(
    int year,
    String language, [
    String? version,
  ]) async {
    final Directory storageDir = await _getLocalStorageDirectory();
    // Include version in filename for new languages, maintain backward compatibility for Spanish
    if (language == 'es' && version == 'RVR1960') {
      return '${storageDir.path}/devocional_${year}_$language.json';
    } else {
      final versionSuffix = version != null ? '_$version' : '';
      return '${storageDir.path}/devocional_${year}_$language$versionSuffix.json';
    }
  }

  Future<bool> hasLocalFile(
    int year,
    String language, [
    String? version,
  ]) async {
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
        year,
        _selectedLanguage,
        _selectedVersion,
      );
      debugPrint('🔍 Requesting URL: $url');
      debugPrint('🔍 Language: $_selectedLanguage, Version: $_selectedVersion');
      final response = await httpClient.get(Uri.parse(url));

      if (response.statusCode == 404) {
        debugPrint(
          '❌ File not found (404): $_selectedLanguage $_selectedVersion year $year',
        );
        throw Exception(
          'File not available for $_selectedLanguage $_selectedVersion year $year',
        );
      } else if (response.statusCode != 200) {
        debugPrint(
          '❌ HTTP Error ${response.statusCode}: ${response.reasonPhrase}',
        );
        throw Exception(
          'HTTP Error ${response.statusCode}: ${response.reasonPhrase}',
        );
      }

      final Map<String, dynamic> jsonData = json.decode(response.body);

      if (jsonData['data'] == null) {
        throw Exception('Invalid JSON structure: missing "data" field');
      }

      final String filePath = await _getLocalFilePath(
        year,
        _selectedLanguage,
        _selectedVersion,
      );
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

  Future<Map<String, dynamic>?> _loadFromLocalStorage(
    int year,
    String language, [
    String? version,
  ]) async {
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
    // Download all available years to ensure no data loss
    // All historical years remain accessible
    final List<int> yearsToDownload = DevocionalYears.availableYears;
    bool allSuccess = true;

    for (final year in yearsToDownload) {
      bool success = await downloadAndStoreDevocionales(year);

      // If download fails, try fallback logic for missing versions
      if (!success) {
        success = await _tryVersionFallback(year);
      }

      if (!success) {
        allSuccess = false;
        debugPrint('⚠️ Failed to download devotionals for year $year');
      }
    }

    return allSuccess;
  }

  Future<bool> _tryVersionFallback(int year) async {
    debugPrint(
      '🔄 Trying version fallback for $_selectedLanguage $_selectedVersion',
    );

    // Get available versions for the language
    final availableVersions =
        Constants.bibleVersionsByLanguage[_selectedLanguage] ?? [];
    debugPrint(
      '🔄 Available versions for $_selectedLanguage: $availableVersions',
    );

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
          'selectedVersion',
          version,
        ); // Also update global preference
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

      // Safely call the onProgress callback: schedule it and catch errors coming from UI
      try {
        // Schedule a microtask so UI setState calls happen outside of provider's execution stack
        Future.microtask(() {
          try {
            onProgress(progress);
          } catch (e, st) {
            debugPrint('onProgress callback threw an error: $e');
            FirebaseCrashlytics.instance
                .recordError(e, st, reason: 'onProgress callback error');
          }
        });
      } catch (e, st) {
        // If scheduling the callback fails for any reason, log and continue
        debugPrint('Failed to schedule onProgress callback: $e');
        FirebaseCrashlytics.instance.recordError(e, st,
            reason: 'Failed to schedule onProgress callback');
      }

      if (!success) allSuccess = false;
    }

    return allSuccess;
  }

  Future<bool> hasCurrentYearLocalData() async {
    final int currentYear = DateTime.now().year;
    return await hasLocalFile(currentYear, _selectedLanguage, _selectedVersion);
  }

  Future<bool> hasTargetYearsLocalData() async {
    final bool has2025 = await hasLocalFile(
      2025,
      _selectedLanguage,
      _selectedVersion,
    );
    final bool has2026 = await hasLocalFile(
      2026,
      _selectedLanguage,
      _selectedVersion,
    );
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
    _audioController?.removeListener(_onAudioStateChanged);
    _audioController?.dispose();

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
      '🔎 [NO LEÍDOS] Devocionales no leídos: [1m${noLeidos.length}[0m',
    );
    if (noLeidos.isNotEmpty) {
      debugPrint(
        '📖 [PRIMEROS] Mostrando: ${noLeidos.take(3).map((d) => d.id).toList()}',
      );
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
  void startTracking(
    String devocionalId, {
    ScrollController? scrollController,
  }) {
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
    String devocionalId,
    ScrollController? scrollController,
  ) {
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
      '[TRACKER] pause() - acumulado: $_accumulatedSeconds segundos, session: $sessionSeconds, startTime: $_startTime, pausedTime: $_pausedTime',
    );
    _timer?.cancel();
  }

  void resume() {
    if (_currentDevocionalId == null || _pausedTime == null) return;
    _startTime = DateTime.now();
    debugPrint(
      '[TRACKER] resume() - acumulado antes de reanudar: $_accumulatedSeconds segundos, pausedTime: $_pausedTime',
    );
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

  TrackingData({required this.readingTime, required this.scrollPercentage});
}
