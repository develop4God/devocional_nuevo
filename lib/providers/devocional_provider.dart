// lib/providers/devocional_provider.dart

import 'dart:convert';
import 'dart:io'; // Para manejo de archivos locales
import 'dart:ui'; // Necesario para PlatformDispatcher para obtener el locale

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/utils/constants.dart'; // Importación necesaria para Constants.apiUrl
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Importación correcta para http
import 'package:path_provider/path_provider.dart'; // Para acceso a directorios del dispositivo
import 'package:shared_preferences/shared_preferences.dart';

class DevocionalProvider with ChangeNotifier {
  // Lista para almacenar TODOS los devocionales cargados para el idioma actual, de todas las fechas.
  List<Devocional> _allDevocionalesForCurrentLanguage = [];

  // Lista de devocionales después de filtrar por la versión seleccionada.
  List<Devocional> _filteredDevocionales = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Propiedades para el idioma y la versión seleccionados
  String _selectedLanguage =
      'es'; // Idioma por defecto (se detectará del dispositivo)
  String _selectedVersion = 'RVR1960'; // Versión por defecto

  List<Devocional> _favoriteDevocionales =
      []; // Lista de devocionales favoritos
  bool _showInvitationDialog = true; // Para el diálogo de invitación

  // Service for tracking spiritual statistics
  final SpiritualStatsService _statsService = SpiritualStatsService();

  // Propiedades para funcionalidad offline
  bool _isDownloading = false; // Estado de descarga
  String? _downloadStatus; // Mensaje de estado de descarga
  bool _isOfflineMode = false; // Indica si se está usando modo offline

  // Lista de idiomas soportados por tu API
  static const List<String> _supportedLanguages = [
    'es'
  ]; // Agrega más cuando los tengas
  static const String _fallbackLanguage = 'es'; // Idioma de fallback

  // Getters públicos
  List<Devocional> get devocionales =>
      _filteredDevocionales; // La UI consume esta lista filtrada
  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String get selectedLanguage => _selectedLanguage;

  String get selectedVersion => _selectedVersion;

  List<Devocional> get favoriteDevocionales => _favoriteDevocionales;

  bool get showInvitationDialog => _showInvitationDialog;

  // Getters para funcionalidad offline
  bool get isDownloading => _isDownloading;

  String? get downloadStatus => _downloadStatus;

  bool get isOfflineMode => _isOfflineMode;

  // Constructor: inicializa los datos cuando el provider se crea
  DevocionalProvider() {
    // initializeData() se llama fuera del constructor, usualmente en AppInitializer
    // usando addPostFrameCallback. Esto asegura que las preferencias se carguen
    // y los datos se obtengan sin conflictos con la fase de construcción.
  }

  // --- Métodos de inicialización y carga ---

  Future<void> initializeData() async {
    // Evitar llamadas múltiples si ya está cargando
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null; // Limpiar errores al iniciar

    try {
      final prefs = await SharedPreferences.getInstance();

      // Obtener el idioma del dispositivo
      String deviceLanguage = PlatformDispatcher.instance.locale.languageCode;

      // Cargar preferencias guardadas, con fallback inteligente
      String savedLanguage =
          prefs.getString('selectedLanguage') ?? deviceLanguage;

      // Aplicar fallback si el idioma no está soportado
      _selectedLanguage = _getSupportedLanguageWithFallback(savedLanguage);

      // Si el idioma cambió por el fallback, guardarlo
      if (_selectedLanguage != savedLanguage) {
        await prefs.setString('selectedLanguage', _selectedLanguage);
        debugPrint(
            'Idioma cambiado a $_selectedLanguage debido a falta de soporte para $savedLanguage');
      }

      _selectedVersion = prefs.getString('selectedVersion') ?? 'RVR1960';

      await _loadFavorites(); // Cargar favoritos guardados
      await _loadInvitationDialogPreference(); // Cargar preferencia del diálogo

      await _fetchAllDevocionalesForLanguage(); // Cargar y filtrar los devocionales
    } catch (e) {
      _errorMessage = 'Error al inicializar los datos: $e';
      debugPrint('Error en initializeData: $e');
      notifyListeners();
    } finally {
      _isLoading = false;
    }
  }

  // Método para obtener un idioma soportado con fallback
  String _getSupportedLanguageWithFallback(String requestedLanguage) {
    if (_supportedLanguages.contains(requestedLanguage)) {
      return requestedLanguage;
    }

    debugPrint(
        'Idioma $requestedLanguage no soportado, usando fallback: $_fallbackLanguage');
    return _fallbackLanguage;
  }

  // Carga todos los devocionales para el idioma actualmente seleccionado desde almacenamiento local o API.
  Future<void> _fetchAllDevocionalesForLanguage() async {
    _isLoading = true;
    _errorMessage = null; // Limpiar error antes de nueva carga
    _isOfflineMode = false; // Reset offline mode
    notifyListeners(); // Notificar que la carga ha comenzado

    try {
      final int currentYear = DateTime.now().year;

      // Primero, intentar cargar desde almacenamiento local
      Map<String, dynamic>? localData =
          await _loadFromLocalStorage(currentYear, _selectedLanguage);

      if (localData != null) {
        debugPrint('Cargando devocionales desde almacenamiento local');
        _isOfflineMode = true;
        await _processDevocionalData(localData);
        return;
      }

      // Si no hay datos locales, cargar desde la API sin guardar automáticamente
      debugPrint(
          'No se encontraron datos locales, cargando desde API para uso inmediato');
      final response = await http
          .get(Uri.parse(Constants.getDevocionalesApiUrl(currentYear)));

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to load devocionales from API: ${response.statusCode}');
      }

      final String responseBody = response.body;
      final Map<String, dynamic> data = json.decode(responseBody);

      // Procesar los datos descargados para uso inmediato (sin guardar)
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

  // Método auxiliar para procesar los datos de un idioma
  Future<void> _processLanguageData(Map<String, dynamic> languageData) async {
    final List<Devocional> loadedDevocionales = [];

    languageData.forEach((dateKey, dateValue) {
      if (dateValue is List) {
        for (var devocionalJson in dateValue) {
          try {
            // No filtramos por versión aquí; cargamos todos los devocionales del idioma.
            loadedDevocionales.add(
                Devocional.fromJson(devocionalJson as Map<String, dynamic>));
          } catch (e) {
            debugPrint('Error al parsear devocional para $dateKey: $e');
          }
        }
      }
    });

    // Ordenar los devocionales por fecha para mantener un orden consistente
    loadedDevocionales.sort((a, b) => a.date.compareTo(b.date));

    _allDevocionalesForCurrentLanguage = loadedDevocionales;
    _errorMessage = null; // Limpiar cualquier error previo
    _filterDevocionalesByVersion(); // Ahora sí, aplicamos el filtro de versión
  }

  // Filtra los devocionales cargados por la versión actualmente seleccionada
  void _filterDevocionalesByVersion() {
    _filteredDevocionales = _allDevocionalesForCurrentLanguage
        .where((devocional) => devocional.version == _selectedVersion)
        .toList();

    if (_filteredDevocionales.isEmpty &&
        _allDevocionalesForCurrentLanguage.isNotEmpty) {
      // Solo mostrar advertencia si hay devocionales en el idioma pero no para la versión
      _errorMessage =
          'No se encontraron devocionales para la versión $_selectedVersion.';
      debugPrint('Advertencia: $_errorMessage');
    } else if (_allDevocionalesForCurrentLanguage.isEmpty) {
      // Si no hay ningún devocional cargado, el error ya se manejaría en _fetchAllDevocionalesForLanguage
      _errorMessage = 'No hay devocionales disponibles.';
      debugPrint('Información: No hay devocionales cargados.');
    } else {
      _errorMessage = null; // Limpiar error si se encontraron devocionales
    }
    notifyListeners(); // Notificar para que la UI se actualice
  }

  // --- Métodos para cambiar idioma y versión ---

  void setSelectedLanguage(String language) async {
    // Aplicar fallback si el idioma no está soportado
    String supportedLanguage = _getSupportedLanguageWithFallback(language);

    if (_selectedLanguage != supportedLanguage) {
      _selectedLanguage = supportedLanguage;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedLanguage', supportedLanguage);

      // Mostrar mensaje si se aplicó fallback
      if (language != supportedLanguage) {
        debugPrint('Idioma $language no disponible, usando $supportedLanguage');
      }

      // Recargar y refiltrar todos los devocionales para el nuevo idioma
      await _fetchAllDevocionalesForLanguage();
    }
  }

  void setSelectedVersion(String version) async {
    if (_selectedVersion != version) {
      _selectedVersion = version;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedVersion', version);
      // Solo refiltrar la lista actual, ya que el idioma no ha cambiado
      _filterDevocionalesByVersion();
    }
  }

  // --- Lógica de favoritos ---

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
    final String favoritesJson = json.encode(_favoriteDevocionales
        .map((devocional) => devocional.toJson())
        .toList());
    await prefs.setString('favorites', favoritesJson);
  }

  bool isFavorite(Devocional devocional) {
    return _favoriteDevocionales.any((fav) => fav.id == devocional.id);
  }

  void toggleFavorite(Devocional devocional, BuildContext context) {
    // Si el devocional no tiene ID, no se puede guardar como favorito
    if (devocional.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede guardar devocional sin ID'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Obtiene el esquema de colores del tema actual
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (isFavorite(devocional)) {
      _favoriteDevocionales.removeWhere((fav) => fav.id == devocional.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Devocional removido de favoritos',
            style: TextStyle(color: colorScheme.onSecondary),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: colorScheme.secondary,
        ),
      );
    } else {
      _favoriteDevocionales.add(devocional);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Devocional guardado como favorito',
            style: TextStyle(color: colorScheme.onSecondary),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: colorScheme.secondary,
        ),
      );
    }
    _saveFavorites();
    
    // Update spiritual stats with new favorites count
    _statsService.updateFavoritesCount(_favoriteDevocionales.length);
    
    notifyListeners();
  }

  /// Record that a devotional was read (call this when user completes reading a devotional)
  /// This should only be called when the user has truly read the content, not just navigated
  Future<void> recordDevocionalRead(String devocionalId) async {
    if (devocionalId.isEmpty) {
      debugPrint('Cannot record devotional read: empty ID');
      return;
    }
    
    try {
      await _statsService.recordDevocionalRead(
        devocionalId: devocionalId,
        favoritesCount: _favoriteDevocionales.length,
      );
      debugPrint('Recorded devotional read: $devocionalId');
    } catch (e) {
      debugPrint('Error recording devotional read: $e');
    }
  }

  // --- Lógica del Diálogo de Invitación ---

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

  // --- Métodos de utilidad ---

  // Obtener lista de idiomas soportados (para UI de configuración)
  List<String> get supportedLanguages => List.from(_supportedLanguages);

  // Verificar si un idioma está soportado
  bool isLanguageSupported(String language) {
    return _supportedLanguages.contains(language);
  }

  // Método auxiliar para procesar datos de devocionales desde cualquier fuente
  Future<void> _processDevocionalData(Map<String, dynamic> data) async {
    // Acceder a la sección 'data' del JSON y luego al idioma detectado/seleccionado
    final Map<String, dynamic>? languageRoot =
        data['data'] as Map<String, dynamic>?;
    final Map<String, dynamic>? languageData =
        languageRoot?[_selectedLanguage] as Map<String, dynamic>?;

    if (languageData == null) {
      // Si no se encuentra el idioma actual, intentar con el fallback
      if (_selectedLanguage != _fallbackLanguage) {
        debugPrint(
            'No se encontraron datos para $_selectedLanguage, intentando con fallback $_fallbackLanguage');

        final Map<String, dynamic>? fallbackData =
            languageRoot?[_fallbackLanguage] as Map<String, dynamic>?;

        if (fallbackData != null) {
          // Cambiar al idioma de fallback automáticamente
          _selectedLanguage = _fallbackLanguage;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('selectedLanguage', _fallbackLanguage);

          // Procesar los datos del fallback
          await _processLanguageData(fallbackData);
          return;
        }
      }

      // Si ni el idioma solicitado ni el fallback están disponibles
      debugPrint(
          'Advertencia: No se encontraron datos para ningún idioma soportado');
      _allDevocionalesForCurrentLanguage = [];
      _filteredDevocionales = [];
      _errorMessage = 'No se encontraron datos disponibles en la API.';
      return;
    }

    // Procesar los datos del idioma solicitado
    await _processLanguageData(languageData);
  }

  // --- Métodos para funcionalidad offline ---

  /// Obtiene el directorio donde se almacenarán los archivos JSON localmente
  Future<Directory> _getLocalStorageDirectory() async {
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    final Directory devocionalesDir =
        Directory('${appDocumentsDir.path}/devocionales');

    // Crear el directorio si no existe
    if (!await devocionalesDir.exists()) {
      await devocionalesDir.create(recursive: true);
    }

    return devocionalesDir;
  }

  /// Genera la ruta del archivo local para un año y idioma específicos
  Future<String> _getLocalFilePath(int year, String language) async {
    final Directory storageDir = await _getLocalStorageDirectory();
    return '${storageDir.path}/devocional_${year}_$language.json';
  }

  /// Verifica si existe un archivo local para el año y idioma especificados
  Future<bool> hasLocalFile(int year, String language) async {
    try {
      final String filePath = await _getLocalFilePath(year, language);
      final File file = File(filePath);
      return await file.exists();
    } catch (e) {
      debugPrint('Error verificando archivo local: $e');
      return false;
    }
  }

  /// Descarga y almacena el archivo JSON para un año específico
  Future<bool> downloadAndStoreDevocionales(int year) async {
    if (_isDownloading) {
      debugPrint('Ya hay una descarga en progreso');
      return false;
    }

    _isDownloading = true;
    _downloadStatus = 'Descargando devocionales del año $year...';
    notifyListeners();

    try {
      final String url = Constants.getDevocionalesApiUrl(year);
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Error al descargar: ${response.statusCode}');
      }

      // Validar que el JSON sea válido
      final Map<String, dynamic> jsonData = json.decode(response.body);

      // Verificar que tenga la estructura esperada
      if (jsonData['data'] == null) {
        throw Exception('Estructura JSON inválida: falta campo "data"');
      }

      // Guardar el archivo localmente
      final String filePath = await _getLocalFilePath(year, _selectedLanguage);
      final File file = File(filePath);
      await file.writeAsString(response.body);

      _downloadStatus = 'Devocionales del año $year descargados exitosamente';
      debugPrint('Archivo guardado en: $filePath');

      return true;
    } catch (e) {
      _downloadStatus = 'Error al descargar devocionales: $e';
      debugPrint('Error en downloadAndStoreDevocionales: $e');
      return false;
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }

  /// Carga los devocionales desde el almacenamiento local
  Future<Map<String, dynamic>?> _loadFromLocalStorage(
      int year, String language) async {
    try {
      final String filePath = await _getLocalFilePath(year, language);
      final File file = File(filePath);

      if (!await file.exists()) {
        return null;
      }

      final String content = await file.readAsString();
      return json.decode(content) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error cargando desde almacenamiento local: $e');
      return null;
    }
  }

  /// Elimina archivos locales antiguos (opcional, para gestión de espacio)
  Future<void> clearOldLocalFiles() async {
    try {
      final Directory storageDir = await _getLocalStorageDirectory();
      final List<FileSystemEntity> files = await storageDir.list().toList();

      for (final FileSystemEntity file in files) {
        if (file is File) {
          await file.delete();
          debugPrint('Archivo eliminado: ${file.path}');
        }
      }

      _downloadStatus = 'Archivos locales eliminados';
      notifyListeners();
    } catch (e) {
      debugPrint('Error eliminando archivos locales: $e');
      _downloadStatus = 'Error al eliminar archivos locales';
      notifyListeners();
    }
  }

  // --- Métodos públicos para la UI ---

  /// Descarga manualmente los devocionales para el año actual
  Future<bool> downloadCurrentYearDevocionales() async {
    final int currentYear = DateTime.now().year;
    return await downloadAndStoreDevocionales(currentYear);
  }

  /// Descarga devocionales para un año específico
  Future<bool> downloadDevocionalesForYear(int year) async {
    return await downloadAndStoreDevocionales(year);
  }

  /// Descarga devocionales para un año específico **con progreso**
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

      if (!success) {
        allSuccess = false;
      }
    }

    return allSuccess;
  }

  /// Verifica si hay datos locales para el año actual
  Future<bool> hasCurrentYearLocalData() async {
    final int currentYear = DateTime.now().year;
    return await hasLocalFile(currentYear, _selectedLanguage);
  }

  /// Verifica si hay datos locales para 2025 y 2026
  Future<bool> hasTargetYearsLocalData() async {
    final bool has2025 = await hasLocalFile(2025, _selectedLanguage);
    final bool has2026 = await hasLocalFile(2026, _selectedLanguage);
    return has2025 && has2026;
  }

  /// Fuerza la recarga desde la API (ignora archivos locales)
  Future<void> forceRefreshFromAPI() async {
    _isOfflineMode = false;
    await _fetchAllDevocionalesForLanguage();
  }

  /// Limpia el estado de descarga
  void clearDownloadStatus() {
    _downloadStatus = null;
    notifyListeners();
  }
}
