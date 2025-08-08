// lib/providers/devocional_provider.dart

import 'dart:convert';
import 'dart:ui'; // Necesario para PlatformDispatcher para obtener el locale
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Importación correcta para http
import 'package:shared_preferences/shared_preferences.dart';

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/utils/constants.dart'; // Importación necesaria para Constants.apiUrl

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

  // Carga todos los devocionales para el idioma actualmente seleccionado desde la API.
  Future<void> _fetchAllDevocionalesForLanguage() async {
    _isLoading = true;
    _errorMessage = null; // Limpiar error antes de nueva carga
    notifyListeners(); // Notificar que la carga ha comenzado

    try {
      // AHORA: Obtiene el año actual para pasarlo a la función que genera la URL.
      final response = await http
          .get(Uri.parse(Constants.getDevocionalesApiUrl(DateTime.now().year)));

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to load devocionales from API: ${response.statusCode}');
      }

      final String responseBody = response.body;
      final Map<String, dynamic> data = json.decode(responseBody);

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
    notifyListeners();
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
}
