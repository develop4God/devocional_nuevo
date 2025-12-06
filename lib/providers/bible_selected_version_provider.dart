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
        '[BibleProvider] Nuevo idioma: $_selectedLanguage, versión: $_selectedVersion');
    // Validar si la versión está descargada y si no, descargarla automáticamente
    await _ensureVersionDownloaded();
    // Actualizar la lista de versiones disponibles
    await _updateAvailableVersions();
    // Log para depuración: mostrar estado final y cantidad de versículos
    _logger.i(
        '[BibleProvider] Estado tras cambio de idioma: $_state, Versículos cargados: ${_verses.length}');
    if (_state == BibleProviderState.ready) {
      _logger.i(
          '[BibleProvider] ✅ Biblia lista para uso inmediato tras cambio de idioma');
    } else if (_state == BibleProviderState.error) {
      _logger
          .e('[BibleProvider] ❌ Error tras cambio de idioma: $_errorMessage');
    }
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
    final allVersions =
        await _repository.fetchVersionsByLanguage(_selectedLanguage);
    final downloadedIds = await _repository.getDownloadedVersionIds();
    _availableVersions = allVersions
        .map(
          (meta) => BibleVersion(
            name: meta.name,
            language: meta.languageName,
            languageCode: meta.language,
            dbFileName: 'bibles/${meta.filename}',
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
          '📖 [BibleProvider] _ensureVersionDownloaded: $_selectedLanguage, $_selectedVersion');
      // 1. Verificación local directa antes de consultar la API
      final biblesDir = await _repository.storage.getBiblesDirectory();
      final filename = '${_selectedVersion}_${_selectedLanguage}.SQLite3';
      final dbPath = '$biblesDir/$filename';
      final fileExists = await _repository.storage.fileExists(dbPath);
      final downloadedIds = await _repository.getDownloadedVersionIds();
      final versionId = '${_selectedLanguage}-${_selectedVersion}';

      if (fileExists && downloadedIds.contains(versionId)) {
        _logger.i(
            '✅ [BibleProvider] Versión ya descargada y registrada: $dbPath. Se omite descarga y se avanza.');
        final hasVerses =
            await _fetchVerses(_selectedLanguage, _selectedVersion);
        _logger.i('📄 [BibleProvider] ¿Hay versículos?: $hasVerses');
        if (!hasVerses) {
          _state = BibleProviderState.error;
          _errorMessage =
              '❌ No se encontraron versículos para la versión ($_selectedVersion)';
          _logger.e('❌ [BibleProvider] ERROR fetch: $_errorMessage');
          notifyListeners();
          return;
        }
        _state = BibleProviderState.ready;
        _errorMessage = null;
        _logger.i('🎉 [BibleProvider] READY');
        notifyListeners();
        return;
      }

      // 2. Si no está, consulta la API y descarga
      _logger.i(
          '🌐 [BibleProvider] Archivo no encontrado o no registrado, consultando API...');
      final isDownloaded = await _isVersionDownloaded(
        _selectedLanguage,
        _selectedVersion,
      );
      _logger.i('📥 [BibleProvider] ¿Descargada?: $isDownloaded');
      if (!isDownloaded) {
        _state = BibleProviderState.downloading;
        notifyListeners();
        _logger.i('⬇️ [BibleProvider] Descargando versión...');
        final success = await _downloadVersion(
          _selectedLanguage,
          _selectedVersion,
        );
        _logger.i(success
            ? '✅ [BibleProvider] Descarga exitosa'
            : '❌ [BibleProvider] Descarga fallida');
        if (!success) {
          _state = BibleProviderState.error;
          _errorMessage =
              '❌ No se pudo descargar la versión bíblica ($_selectedVersion)';
          _logger.e('❌ [BibleProvider] ERROR descarga: $_errorMessage');
          notifyListeners();
          return;
        }
      }
      final hasVerses = await _fetchVerses(_selectedLanguage, _selectedVersion);
      _logger.i('📄 [BibleProvider] ¿Hay versículos?: $hasVerses');
      if (!hasVerses) {
        _state = BibleProviderState.error;
        _errorMessage =
            '❌ No se encontraron versículos para la versión ($_selectedVersion)';
        _logger.e('❌ [BibleProvider] ERROR fetch: $_errorMessage');
        notifyListeners();
        return;
      }
      _state = BibleProviderState.ready;
      _errorMessage = null;
      _logger.i('🎉 [BibleProvider] READY');
      notifyListeners();
    } catch (e) {
      _state = BibleProviderState.error;
      _errorMessage = '❌ Error: $e';
      _logger.e('❌ [BibleProvider] ERROR general: $e');
      notifyListeners();
    }
  }

  /// Simula si la versión está descargada (reemplaza por tu lógica real)
  Future<bool> _isVersionDownloaded(String lang, String version) async {
    await _repository.initialize();
    final downloadedIds = await _repository.getDownloadedVersionIds();
    final allVersions = await _repository.fetchVersionsByLanguage(lang);
    _logger.i(
      '[BibleProvider] Versiones disponibles para $lang: ${allVersions.map((v) => v.name).join(', ')}',
    );
    BibleVersionMetadata versionObj;
    try {
      versionObj = allVersions.firstWhere(
        (v) => v.name == version,
        orElse: () => allVersions.first,
      );
    } catch (_) {
      _errorMessage =
          'No hay ninguna versión bíblica disponible para el idioma $lang.';
      _state = BibleProviderState.error;
      notifyListeners();
      return false;
    }
    _selectedVersion = versionObj.name;
    final biblesDir = await _repository.storage.getBiblesDirectory();
    final dbPath = '$biblesDir/${versionObj.filename}';
    _logger.i('[BibleProvider] Verificando archivo en: $dbPath');
    final fileExists = await _repository.storage.fileExists(dbPath);
    if (!fileExists) {
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
    final allVersions = await _repository.fetchVersionsByLanguage(lang);
    _logger.i('[BibleProvider] Iniciando descarga para $lang/$version');
    BibleVersionMetadata versionObj;
    try {
      versionObj = allVersions.firstWhere(
        (v) => v.name == version,
        orElse: () => allVersions.first,
      );
    } catch (_) {
      _errorMessage =
          'No hay ninguna versión bíblica disponible para el idioma $lang.';
      _state = BibleProviderState.error;
      notifyListeners();
      return false;
    }
    _selectedVersion = versionObj.name;
    _logger.i('[BibleProvider] URL de descarga: ${versionObj.downloadUrl}');
    try {
      await _repository.downloadVersion(versionObj.id);
      final biblesDir = await _repository.storage.getBiblesDirectory();
      final dbPath = '$biblesDir/${versionObj.filename}';
      final fileExists = await _repository.storage.fileExists(dbPath);
      _logger
          .i('[BibleProvider] ¿Archivo guardado correctamente?: $fileExists');
      return fileExists;
    } catch (e) {
      _logger.e('[BibleProvider] Error al descargar: $e');
      return false;
    }
  }

  Future<bool> _fetchVerses(String lang, String version) async {
    try {
      final biblesDir = await _repository.storage.getBiblesDirectory();
      final filename = '${version}_${lang}.SQLite3';
      final dbPath = '$biblesDir/$filename';
      final fileExists = await _repository.storage.fileExists(dbPath);
      String dbFilePath;
      if (fileExists) {
        _logger.i('💾 [BibleProvider] Usando archivo local existente: $dbPath');
        dbFilePath = dbPath;
      } else {
        await _repository.initialize();
        final allVersions = await _repository.fetchVersionsByLanguage(lang);
        final versionObj = allVersions.firstWhere(
          (v) => v.name == version,
          orElse: () => allVersions.first,
        );
        dbFilePath = biblesDir + '/' + versionObj.filename;
        _logger.i(
            '🌐 [BibleProvider] Archivo no encontrado, usando metadata: $dbFilePath');
      }
      _logger.i('💡 [BibleProvider] Abriendo base de datos en: $dbFilePath');
      final dbService = BibleDbService(customDatabasePath: dbFilePath);
      await dbService.initDbFromPath();
      final books = await dbService.getAllBooks();
      if (books.isEmpty) return false;
      final firstBook = books.first;
      final bookNumber = firstBook['book_number'] as int? ?? 1;
      final verses = await dbService.getChapterVerses(bookNumber, 1);
      _verses = verses;
      _logger.i('💡 [BibleProvider] Versículos cargados: ${_verses.length}');
      return _verses.isNotEmpty;
    } catch (e) {
      _logger.e('[BibleProvider] ERROR al obtener versículos: $e');
      return false;
    }
  }
}
