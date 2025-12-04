import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/adapters/http_client_adapter.dart';
import 'package:devocional_nuevo/adapters/storage_adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BibleProviderState { loading, downloading, ready, error }

/// Provider para la versión bíblica seleccionada globalmente.
/// Cambia automáticamente al cambiar el idioma y permite selección manual.
class BibleSelectedVersionProvider extends ChangeNotifier {
  String _selectedLanguage = 'es';
  String _selectedVersion = 'RVR1960';
  BibleProviderState _state = BibleProviderState.loading;
  String? _errorMessage;

  // Mapa de versión por defecto por idioma
  static const Map<String, String> _defaultVersionByLanguage = {
    'es': 'RVR1960',
    'en': 'KJV',
    'pt': 'ARC',
    'fr': 'LSG1910',
    'ja': 'SK2003',
  };

  final BibleVersionRepository _repository = BibleVersionRepository(
    httpClient: HttpClientAdapter.create(),
    storage: StorageAdapter(),
  );
  List<Map<String, dynamic>> _verses = [];

  List<Map<String, dynamic>> get verses => _verses;

  String get selectedLanguage => _selectedLanguage;

  String get selectedVersion => _selectedVersion;

  BibleProviderState get state => _state;

  String? get errorMessage => _errorMessage;

  /// Inicializa el provider con idioma y versión guardados o por defecto
  Future<void> initialize({String? languageCode}) async {
    debugPrint(
        '[BibleProvider] Inicializando con idioma: [1m$languageCode[0m');
    _state = BibleProviderState.loading;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    _selectedLanguage =
        languageCode ?? prefs.getString('selectedLanguage') ?? 'es';
    _selectedVersion = prefs.getString('selectedBibleVersion') ??
        _defaultVersionByLanguage[_selectedLanguage] ??
        'RVR1960';
    debugPrint(
        '[BibleProvider] Idioma: $_selectedLanguage, Versión: $_selectedVersion');
    await _ensureVersionDownloaded();
  }

  /// Cambia el idioma y selecciona la versión por defecto de ese idioma
  Future<void> setLanguage(String languageCode) async {
    debugPrint('[BibleProvider] setLanguage: $languageCode');
    _state = BibleProviderState.loading;
    notifyListeners();
    _selectedLanguage = languageCode;
    _selectedVersion = _defaultVersionByLanguage[languageCode] ?? 'RVR1960';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', languageCode);
    await prefs.setString('selectedBibleVersion', _selectedVersion);
    debugPrint(
        '[BibleProvider] Nuevo idioma: $_selectedLanguage, versión: $_selectedVersion');
    await _ensureVersionDownloaded();
  }

  /// Cambia la versión bíblica seleccionada manualmente
  Future<void> setVersion(String version) async {
    debugPrint('[BibleProvider] setVersion: $version');
    _state = BibleProviderState.loading;
    notifyListeners();
    _selectedVersion = version;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedBibleVersion', version);
    await _ensureVersionDownloaded();
  }

  /// Hace fetch de la información de la Biblia para el idioma y versión actual
  Future<void> fetchBibleInfo() async {
    debugPrint('[BibleProvider] fetchBibleInfo()');
    _state = BibleProviderState.loading;
    notifyListeners();
    await _ensureVersionDownloaded();
  }

  /// Lógica para descargar la versión si no está presente y hacer fetch
  Future<void> _ensureVersionDownloaded() async {
    try {
      debugPrint(
          '[BibleProvider] _ensureVersionDownloaded: $_selectedLanguage, $_selectedVersion');
      final isDownloaded =
          await _isVersionDownloaded(_selectedLanguage, _selectedVersion);
      debugPrint('[BibleProvider] ¿Descargada?: $isDownloaded');
      if (!isDownloaded) {
        _state = BibleProviderState.downloading;
        notifyListeners();
        final success =
            await _downloadVersion(_selectedLanguage, _selectedVersion);
        debugPrint('[BibleProvider] Descarga exitosa: $success');
        if (!success) {
          _state = BibleProviderState.error;
          _errorMessage =
              'No se pudo descargar la versión bíblica ($_selectedVersion)';
          debugPrint('[BibleProvider] ERROR descarga: $_errorMessage');
          notifyListeners();
          return;
        }
      }
      final hasVerses = await _fetchVerses(_selectedLanguage, _selectedVersion);
      debugPrint('[BibleProvider] ¿Hay versículos?: $hasVerses');
      if (!hasVerses) {
        _state = BibleProviderState.error;
        _errorMessage =
            'No se encontraron versículos para la versión ($_selectedVersion)';
        debugPrint('[BibleProvider] ERROR fetch: $_errorMessage');
        notifyListeners();
        return;
      }
      _state = BibleProviderState.ready;
      _errorMessage = null;
      debugPrint('[BibleProvider] READY');
      notifyListeners();
    } catch (e) {
      _state = BibleProviderState.error;
      _errorMessage = 'Error: $e';
      debugPrint('[BibleProvider] ERROR general: $e');
      notifyListeners();
    }
  }

  /// Simula si la versión está descargada (reemplaza por tu lógica real)
  Future<bool> _isVersionDownloaded(String lang, String version) async {
    await _repository.initialize();
    final downloadedIds = await _repository.getDownloadedVersionIds();
    final allVersions = await _repository.fetchAvailableVersions();
    final versionObj = allVersions.firstWhere(
      (v) => v.language == lang && v.name == version,
      orElse: () => allVersions.firstWhere(
        (v) => v.language == lang,
        orElse: () => allVersions.first,
      ),
    );
    return downloadedIds.contains(versionObj.id);
  }

  Future<bool> _downloadVersion(String lang, String version) async {
    await _repository.initialize();
    final allVersions = await _repository.fetchAvailableVersions();
    final versionObj = allVersions.firstWhere(
      (v) => v.language == lang && v.name == version,
      orElse: () => allVersions.firstWhere(
        (v) => v.language == lang,
        orElse: () => allVersions.first,
      ),
    );
    try {
      await _repository.downloadVersion(versionObj.id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _fetchVerses(String lang, String version) async {
    // Aquí deberías usar el servicio de lectura de la Biblia, no el repositorio de versiones.
    // Ejemplo de integración real:
    // final dbService = BibleDbService();
    // final result = await dbService.getVerses(
    //   versionId: versionObj.id,
    //   book: 'John',
    //   chapter: 3,
    // );
    // _verses = result.map((v) => v.toJson()).toList();
    // return _verses.isNotEmpty;
    // Por ahora, simula fetch exitoso:
    await Future.delayed(const Duration(milliseconds: 500));
    _verses = [
      {'verse': 1, 'text': 'Versículo de ejemplo.'}
    ];
    return true;
  }
}
