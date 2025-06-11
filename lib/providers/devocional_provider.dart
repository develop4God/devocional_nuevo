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
  String
      _selectedVersion = //aca se agregan nuevas versiones cuando hayan, para devocional page
      'RVR1960'; // Versión por defecto

  List<Devocional> _favoriteDevocionales =
      []; // Lista de devocionales favoritos
  bool _showInvitationDialog = true; // Para el diálogo de invitación

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

    // No llamar notifyListeners() aquí si esta función es llamada
    // en un contexto donde el árbol de widgets aún se está construyendo.
    // La notificación inicial ocurrirá al final de esta función,
    // o cuando _fetchAllDevocionalesForLanguage/filterDevocionalesByVersion
    // llamen a notifyListeners().

    try {
      final prefs = await SharedPreferences.getInstance();
      // Cargar preferencias guardadas, o usar valores por defecto
      _selectedLanguage = prefs.getString('selectedLanguage') ??
          PlatformDispatcher.instance.locale.languageCode;
      _selectedVersion = prefs.getString('selectedVersion') ??
          'RVR1960'; // Asegúrate de que este sea tu valor por defecto principal

      await _loadFavorites(); // Cargar favoritos guardados
      await _loadInvitationDialogPreference(); // Cargar preferencia del diálogo

      await _fetchAllDevocionalesForLanguage(); // Cargar y filtrar los devocionales
    } catch (e) {
      _errorMessage = 'Error al inicializar los datos: $e';
      debugPrint('Error en initializeData: $e');
      // Asegurarse de notificar en caso de error para que la UI pueda reaccionar
      notifyListeners();
    } finally {
      _isLoading = false;
      // notifyListeners() ya se llama en _filterDevocionalesByVersion o en el catch.
    }
  }

  // Carga todos los devocionales para el idioma actualmente seleccionado desde la API.
  Future<void> _fetchAllDevocionalesForLanguage() async {
    _isLoading = true;
    _errorMessage = null; // Limpiar error antes de nueva carga
    notifyListeners(); // Notificar que la carga ha comenzado

    try {
      final response = await http.get(Uri.parse(Constants.apiUrl));

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
        debugPrint(
            'Advertencia: No se encontraron datos para el idioma $_selectedLanguage');
        _allDevocionalesForCurrentLanguage = [];
        _filteredDevocionales =
            []; // Asegurarse de que esta lista también se vacíe
        _errorMessage =
            'No se encontraron datos para el idioma: $_selectedLanguage en la estructura JSON.';
        // No llamar notifyListeners aquí, ya que el finally lo hará.
        return; // Salir de la función si no hay datos del idioma
      }

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
      // notifyListeners() ya se llama dentro de _filterDevocionalesByVersion
    } catch (e) {
      _errorMessage =
          'Error al cargar los devocionales para el idioma $_selectedLanguage: $e';
      _allDevocionalesForCurrentLanguage = [];
      _filteredDevocionales =
          []; // Vaciar también la lista filtrada en caso de error
      debugPrint('Error en _fetchAllDevocionalesForLanguage: $e');
      notifyListeners(); // Notificar en caso de error
    } finally {
      _isLoading = false;
      // notifyListeners() ya se llama en _filterDevocionalesByVersion o en el catch.
    }
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
          'No se encontraron devocionales para la versión $_selectedVersion en el idioma $_selectedLanguage.';
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
    if (_selectedLanguage != language) {
      _selectedLanguage = language;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedLanguage', language);
      // Recargar y refiltrar todos los devocionales para el nuevo idioma
      await _fetchAllDevocionalesForLanguage();
      // notifyListeners() ya se llama al final de _fetchAllDevocionalesForLanguage
    }
  }

  void setSelectedVersion(String version) async {
    if (_selectedVersion != version) {
      _selectedVersion = version;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedVersion', version);
      // Solo refiltrar la lista actual, ya que el idioma no ha cambiado
      _filterDevocionalesByVersion();
      // notifyListeners() ya se llama al final de _filterDevocionalesByVersion
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
    // No notificar aquí, initializeData() lo hará
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

    if (isFavorite(devocional)) {
      _favoriteDevocionales.removeWhere((fav) => fav.id == devocional.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Devocional removido de favoritos'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      _favoriteDevocionales.add(devocional);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Devocional guardado como favorito'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    _saveFavorites(); // Guardar el cambio inmediatamente
    notifyListeners(); // Notificar a los widgets para que se actualicen
  }

  // --- Lógica del Diálogo de Invitación ---

  Future<void> _loadInvitationDialogPreference() async {
    final prefs = await SharedPreferences.getInstance();
    // Leer el valor guardado. Si no existe, se usa true por defecto.
    _showInvitationDialog = prefs.getBool('showInvitationDialog') ?? true;
    // No notificar aquí; initializeData() lo hará
  }

  Future<void> setInvitationDialogVisibility(bool shouldShow) async {
    _showInvitationDialog = shouldShow;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showInvitationDialog', shouldShow);
    notifyListeners();
  }
}
