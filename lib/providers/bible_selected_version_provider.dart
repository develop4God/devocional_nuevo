import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/adapters/http_client_adapter.dart';
import 'package:devocional_nuevo/adapters/storage_adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
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
  List<BibleVersion> _availableVersions = [];

  List<Map<String, dynamic>> get verses => _verses;

  String get selectedLanguage => _selectedLanguage;

  String get selectedVersion => _selectedVersion;

  BibleProviderState get state => _state;

  String? get errorMessage => _errorMessage;

  List<BibleVersion> get availableVersions => _availableVersions;

  final Logger _logger = Logger();

  /// Inicializa el provider con idioma y versión guardados o por defecto
  Future<void> initialize({String? languageCode}) async {
    _logger.i(
      '[BibleProvider] Inicializando con idioma: [1m$languageCode[0m',
    );
    _state = BibleProviderState.loading;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    _selectedLanguage =
        languageCode ?? prefs.getString('selectedLanguage') ?? 'es';
    _selectedVersion = prefs.getString('selectedBibleVersion') ??
        _defaultVersionByLanguage[_selectedLanguage] ??
        'RVR1960';
    _logger.i(
      '[BibleProvider] Idioma: $_selectedLanguage, Versión: $_selectedVersion',
    );
    await _ensureVersionDownloaded();
    await _updateAvailableVersions();
  }

  /// Cambia el idioma y selecciona la versión por defecto de ese idioma
  Future<void> setLanguage(String languageCode) async {
    _logger.i('[BibleProvider] setLanguage: $languageCode');
    _state = BibleProviderState.loading;
    notifyListeners();
    _selectedLanguage = languageCode;
    _selectedVersion = _defaultVersionByLanguage[languageCode] ?? 'RVR1960';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', languageCode);
    await prefs.setString('selectedBibleVersion', _selectedVersion);
    _logger.i(
      '[BibleProvider] Nuevo idioma: $_selectedLanguage, versión: $_selectedVersion',
    );
    await _ensureVersionDownloaded();
    await _updateAvailableVersions();
  }

  /// Cambia la versión bíblica seleccionada manualmente
  Future<void> setVersion(String version) async {
    _logger.i('[BibleProvider] setVersion: $version');
    _state = BibleProviderState.loading;
    notifyListeners();
    _selectedVersion = version;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedBibleVersion', version);
    await _ensureVersionDownloaded();
    await _updateAvailableVersions();
  }

  /// Hace fetch de la información de la Biblia para el idioma y versión actual
  Future<void> fetchBibleInfo() async {
    _logger.i('[BibleProvider] fetchBibleInfo()');
    _state = BibleProviderState.loading;
    notifyListeners();
    await _ensureVersionDownloaded();
    // Actualiza la lista de versiones disponibles
    await _updateAvailableVersions();
  }

  Future<void> _updateAvailableVersions() async {
    await _repository.initialize();
    final allVersions = await _repository.fetchAvailableVersions();
    final downloadedIds = await _repository.getDownloadedVersionIds();
    _availableVersions = allVersions
        .where((v) => v.language == _selectedLanguage)
        .map(
          (meta) => BibleVersion(
            name: meta.name,
            language: meta.languageName,
            languageCode: meta.language,
            // Path must match where StorageAdapter saves files: {documentsDir}/bibles/{versionId}/bible.db
            dbFileName: 'bibles/${meta.id}/bible.db',
            isDownloaded: downloadedIds.contains(meta.id),
          ),
        )
        .toList();
    notifyListeners();
  }

  /// Lógica para descargar la versión si no está presente y hacer fetch
  Future<void> _ensureVersionDownloaded() async {
    try {
      _logger.i(
        '[BibleProvider] _ensureVersionDownloaded: $_selectedLanguage, $_selectedVersion',
      );
      final isDownloaded = await _isVersionDownloaded(
        _selectedLanguage,
        _selectedVersion,
      );
      _logger.i('[BibleProvider] ¿Descargada?: $isDownloaded');
      if (!isDownloaded) {
        _state = BibleProviderState.downloading;
        notifyListeners();
        final success = await _downloadVersion(
          _selectedLanguage,
          _selectedVersion,
        );
        _logger.i('[BibleProvider] Descarga exitosa: $success');
        if (!success) {
          _state = BibleProviderState.error;
          _errorMessage =
              'No se pudo descargar la versión bíblica ($_selectedVersion)';
          _logger.e('[BibleProvider] ERROR descarga: $_errorMessage');
          notifyListeners();
          return;
        }
      }
      final hasVerses = await _fetchVerses(_selectedLanguage, _selectedVersion);
      _logger.i('[BibleProvider] ¿Hay versículos?: $hasVerses');
      if (!hasVerses) {
        _state = BibleProviderState.error;
        _errorMessage =
            'No se encontraron versículos para la versión ($_selectedVersion)';
        _logger.e('[BibleProvider] ERROR fetch: $_errorMessage');
        notifyListeners();
        return;
      }
      _state = BibleProviderState.ready;
      _errorMessage = null;
      _logger.i('[BibleProvider] READY');
      notifyListeners();
    } catch (e) {
      _state = BibleProviderState.error;
      _errorMessage = 'Error: $e';
      _logger.e('[BibleProvider] ERROR general: $e');
      notifyListeners();
    }
  }

  /// Simula si la versión está descargada (reemplaza por tu lógica real)
  Future<bool> _isVersionDownloaded(String lang, String version) async {
    await _repository.initialize();
    final downloadedIds = await _repository.getDownloadedVersionIds();
    final allVersions = await _repository.fetchAvailableVersions();
    _logger.i(
      '[BibleProvider] Versiones disponibles para $lang: ${allVersions.where((v) => v.language == lang).map((v) => v.name).join(', ')}',
    );
    BibleVersionMetadata versionObj;
    try {
      versionObj = allVersions.firstWhere(
        (v) => v.language == lang && v.name == version,
        orElse: () => allVersions.firstWhere((v) => v.language == lang),
      );
    } catch (_) {
      _errorMessage =
          'No hay ninguna versión bíblica disponible para el idioma $lang.';
      _state = BibleProviderState.error;
      notifyListeners();
      return false;
    }
    _selectedVersion = versionObj.name;
    // Construir la ruta real del archivo guardado por el StorageAdapter usando el id
    final biblesDir = await _repository.storage.getBiblesDirectory();
    final dbPath = '$biblesDir/${versionObj.id}/bible.db';
    final fileExists = await _repository.storage.fileExists(dbPath);
    if (!fileExists) {
      // Si el archivo no existe, elimina el ID de la lista y fuerza descarga
      if (downloadedIds.contains(versionObj.id)) {
        downloadedIds.remove(versionObj.id);
        await _repository.storage.saveDownloadedVersions(downloadedIds);
      }
      _logger.w('[BibleProvider] Archivo no encontrado en $dbPath');
      return false;
    }
    return downloadedIds.contains(versionObj.id);
  }

  Future<bool> _downloadVersion(String lang, String version) async {
    await _repository.initialize();
    final allVersions = await _repository.fetchAvailableVersions();
    _logger.i(
      '[BibleProvider] Versiones disponibles para $lang: ${allVersions.where((v) => v.language == lang).map((v) => v.name).join(', ')}',
    );
    BibleVersionMetadata versionObj;
    try {
      versionObj = allVersions.firstWhere(
        (v) => v.language == lang && v.name == version,
        orElse: () => allVersions.firstWhere((v) => v.language == lang),
      );
    } catch (_) {
      _errorMessage =
          'No hay ninguna versión bíblica disponible para el idioma $lang.';
      _state = BibleProviderState.error;
      notifyListeners();
      return false;
    }
    _selectedVersion = versionObj.name;
    _logger.i(
      '[BibleProvider] URL de descarga para [1m${versionObj.name}[0m: ${versionObj.downloadUrl}',
    );
    try {
      await _repository.downloadVersion(versionObj.id);
      // Log de la ruta donde se espera guardar el archivo
      final biblesDir = await _repository.storage.getBiblesDirectory();
      final dbPath = '$biblesDir/${versionObj.filename}';
      _logger.i('[BibleProvider] Intentando guardar archivo en: $dbPath');
      final filesAfterDownload = await _repository.storage.listFiles(biblesDir);
      _logger.i(
        '[BibleProvider] Archivos en el directorio de biblias después de la descarga:',
      );
      for (var file in filesAfterDownload) {
        _logger.i(' - $file');
      }
      // Verificar si el archivo existe justo después de la descarga
      final fileExists = await _repository.storage.fileExists(dbPath);
      _logger.i(
        '[BibleProvider] ¿Archivo guardado correctamente?: $fileExists',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _fetchVerses(String lang, String version) async {
    try {
      await _repository.initialize();
      final allVersions = await _repository.fetchAvailableVersions();
      final versionObj = allVersions.firstWhere(
        (v) => v.language == lang && v.name == version,
        orElse: () => allVersions.firstWhere((v) => v.language == lang),
      );
      // Construir la ruta real del archivo guardado por el StorageAdapter usando el id
      final biblesDir = await _repository.storage.getBiblesDirectory();
      final dbPath = '$biblesDir/${versionObj.id}/bible.db';
      final dbService = BibleDbService(customDatabasePath: dbPath);
      await dbService.initDbFromPath();
      // Obtener el primer libro y capítulo disponibles
      final books = await dbService.getAllBooks();
      if (books.isEmpty) return false;
      final firstBook = books.first;
      final bookNumber = firstBook['book_number'] as int? ?? 1;
      final verses = await dbService.getChapterVerses(bookNumber, 1);
      _verses = verses;
      return _verses.isNotEmpty;
    } catch (e) {
      _logger.e('[BibleProvider] ERROR al obtener versículos: $e');
      return false;
    }
  }
}
