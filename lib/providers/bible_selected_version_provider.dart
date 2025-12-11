import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/adapters/http_client_adapter.dart';
import 'package:devocional_nuevo/adapters/storage_adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BibleProviderState { loading, downloading, ready, error }

/// Provider para la versión bíblica seleccionada globalmente.
/// Cambia automáticamente al cambiar el idioma y permite selección manual.
///
/// Optimized for fast initialization:
/// - Checks local files first before making network requests
/// - Skips GitHub API calls when files are already downloaded
/// - Provides download progress feedback to UI
class BibleSelectedVersionProvider extends ChangeNotifier {
  String _selectedLanguage = 'es';
  String _selectedVersion = 'RVR1960';
  BibleProviderState _state = BibleProviderState.loading;
  String? _errorMessage;

  /// Download progress (0.0 to 1.0) - visible to UI for user feedback
  double _downloadProgress = 0.0;

  /// Flag to track if repository has been initialized
  bool _repositoryInitialized = false;

  // Mapa de versión por defecto por idioma
  static const Map<String, String> _defaultVersionByLanguage = {
    'es': 'RVR1960',
    'en': 'KJV',
    'pt': 'ARC',
    'fr': 'LSG1910',
    'ja': '新改訳2003',
  };

  // SharedPreferences key to track migrated versions (format: 'lang:version')
  static const String _migratedVersionsKey = 'migrated_bible_versions';

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

  /// Returns the current download progress (0.0 to 1.0)
  double get downloadProgress => _downloadProgress;

  List<BibleVersion> get availableVersions => _availableVersions;

  final Logger _logger = Logger();

  /// Inicializa el provider con idioma y versión guardados o por defecto
  Future<void> initialize({String? languageCode}) async {
    _logger.i(
      '[BibleProvider] Inicializando con idioma: \u001b[1m$languageCode\u001b[0m',
    );
    _state = BibleProviderState.loading;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedLanguage =
          languageCode ?? prefs.getString('selectedLanguage') ?? 'es';
      // Read selectedBibleVersion preference. New format: 'lang:version'.
      final rawSelected = prefs.getString('selectedBibleVersion');
      if (rawSelected != null) {
        if (rawSelected.contains(':')) {
          // new format -> parse lang:version
          final parts = rawSelected.split(':');
          if (parts.length >= 2) {
            // respect saved language only if languageCode not explicitly provided
            if (languageCode == null) {
              _selectedLanguage = parts[0];
            }
            _selectedVersion = parts.sublist(1).join(':');
          } else {
            // fallback to default mapping
            _selectedVersion =
                _defaultVersionByLanguage[_selectedLanguage] ?? 'RVR1960';
          }
        } else {
          // legacy format (version only). Migrate to new format immediately.
          _selectedVersion = rawSelected;
          await prefs.setString(
              'selectedBibleVersion', '$_selectedLanguage:$_selectedVersion');
          _logger.i(
              '[BibleProvider] Migrated preference selectedBibleVersion -> $_selectedLanguage:$_selectedVersion');
        }
      } else {
        _selectedVersion =
            _defaultVersionByLanguage[_selectedLanguage] ?? 'RVR1960';
      }
      _logger.i(
        '[BibleProvider] Idioma: $_selectedLanguage, Versión: $_selectedVersion',
      );
      // Comprobación local rápida: si la versión ya existe localmente, cargamos
      // los versículos y devolvemos READY inmediatamente para no bloquear el UI.
      final biblesDir = await _repository.storage.getBiblesDirectory();
      final filename = '${_selectedVersion}_$_selectedLanguage.SQLite3';
      final dbPath = '$biblesDir/$filename';
      final fileExists = await _repository.storage.fileExists(dbPath);
      if (fileExists) {
        final hasVerses = await _fetchVerses(
          _selectedLanguage,
          _selectedVersion,
        );
        if (hasVerses) {
          _state = BibleProviderState.ready;
          _errorMessage = null;
          _logger.i('🎉 [BibleProvider] READY (local)');
          notifyListeners();
        }
      }

      // Si el usuario tenía una versión guardada explícitamente y no existe
      // localmente, hacemos la descarga de forma síncrona aquí para evitar
      // condiciones de carrera con el BibleReader que espera el archivo.
      final bool userPreferredVersionExists =
          prefs.containsKey('selectedBibleVersion');

      if (!fileExists && userPreferredVersionExists) {
        _logger.i(
            '[BibleProvider] User preferred version ($_selectedVersion) not found locally - downloading now');
        try {
          await _updateAvailableVersions();
          await _ensureVersionDownloaded();
        } catch (e) {
          _logger.w(
              '[BibleProvider] Failed to download user preferred version: $e');
        }
      } else {
        // Lanzar actualización y descarga en background. No await para no bloquear el inicio.
        // ignore: unawaited_futures
        Future(() async {
          try {
            await _updateAvailableVersions();
            await _ensureVersionDownloaded();
          } catch (e) {
            _logger.w('[BibleProvider] Background init error: $e');
          }
        });
      }
    } catch (e) {
      // No debemos bloquear el arranque de la app por un fallo de red.
      _logger.e(
        '[BibleProvider] Error durante initialize (ignorando para no bloquear app): $e',
      );
      // Si ya hay alguna Biblia local, intentamos dejar el estado en ready; de lo contrario, marcamos error pero sin lanzar.
      if (_verses.isNotEmpty) {
        _state = BibleProviderState.ready;
        _errorMessage = null;
      } else {
        _state = BibleProviderState.error;
        _errorMessage = 'No se pudo inicializar la Biblia (sin conexión).';
      }
      notifyListeners();
    }
  }

  /// Cambia el idioma y selecciona la versión por defecto de ese idioma
  Future<void> setLanguage(
    String languageCode, {
    bool fromSettings = false,
  }) async {
    if (fromSettings) {
      _logger.i(
        '[BibleProvider] ⚙️ Cambio de idioma solicitado desde Settings: $languageCode',
      );
    } else {
      _logger.i('[BibleProvider] setLanguage: $languageCode');
    }
    _state = BibleProviderState.loading;
    notifyListeners();
    _selectedLanguage = languageCode;
    _selectedVersion = _defaultVersionByLanguage[languageCode] ?? 'RVR1960';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', languageCode);
    // Save new preference format 'lang:version'
    await prefs.setString(
        'selectedBibleVersion', '$_selectedLanguage:$_selectedVersion');
    _logger.i(
      '[BibleProvider] Nuevo idioma: $_selectedLanguage, versión: $_selectedVersion',
    );
    // Validar si la versión está descargada y si no, descargarla automáticamente
    await _ensureVersionDownloaded();
    // Actualizar la lista de versiones disponibles
    await _updateAvailableVersions();
    // Log para depuración: mostrar estado final y cantidad de versículos
    _logger.i(
      '[BibleProvider] Estado tras cambio de idioma: $_state, Versículos cargados: ${_verses.length}',
    );
    if (_state == BibleProviderState.ready) {
      _logger.i(
        '[BibleProvider] ✅ Biblia lista para uso inmediato tras cambio de idioma',
      );
    } else if (_state == BibleProviderState.error) {
      _logger.e(
        '[BibleProvider] ❌ Error tras cambio de idioma: $_errorMessage',
      );
    }
  }

  /// Cambia la versión bíblica seleccionada manualmente
  Future<void> setVersion(String version) async {
    _logger.i('[BibleProvider] setVersion: $version');
    _state = BibleProviderState.loading;
    notifyListeners();
    _selectedVersion = version;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'selectedBibleVersion', '$_selectedLanguage:$_selectedVersion');
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
    final allVersions = await _repository.fetchVersionsByLanguage(
      _selectedLanguage,
    );
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
    // --- NUEVO: Si no hay versión seleccionada pero hay alguna descargada, selecciona la primera descargada ---
    if (_availableVersions.where((v) => v.isDownloaded).isNotEmpty) {
      final downloaded =
          _availableVersions.where((v) => v.isDownloaded).toList();
      if (_selectedVersion.isEmpty ||
          !_availableVersions.any(
            (v) => v.name == _selectedVersion && v.isDownloaded,
          )) {
        _selectedVersion = downloaded.first.name;
        final prefs = await SharedPreferences.getInstance();
        // Save preference in new 'lang:version' format to keep consistency.
        await prefs.setString(
            'selectedBibleVersion', '$_selectedLanguage:$_selectedVersion');
        _logger.i(
          '[BibleProvider] No había versión activa, se selecciona automáticamente: $_selectedVersion',
        );
      }
    }
    notifyListeners();
  }

  /// Ensures repository is initialized (only once)
  Future<void> _ensureRepositoryInitialized() async {
    if (!_repositoryInitialized) {
      await _repository.initialize();
      _repositoryInitialized = true;
    }
  }

  /// Lógica para descargar la versión si no está presente y hacer fetch
  /// OPTIMIZED: Prioritizes local file checks to avoid unnecessary network calls
  Future<void> _ensureVersionDownloaded() async {
    final stopwatch = Stopwatch()..start();
    try {
      _logger.i(
        '📖 [BibleProvider] _ensureVersionDownloaded: $_selectedLanguage, $_selectedVersion',
      );

      // 1. Fast local file check FIRST - avoid any network call if file exists
      final biblesDir = await _repository.storage.getBiblesDirectory();
      final filename = '${_selectedVersion}_$_selectedLanguage.SQLite3';
      final dbPath = '$biblesDir/$filename';
      var fileExists = await _repository.storage.fileExists(dbPath);

      if (fileExists) {
        _logger.i(
          '✅ [BibleProvider] Archivo local encontrado: $dbPath (${stopwatch.elapsedMilliseconds}ms)',
        );

        // Ensure downloaded versions list is in sync
        await _ensureRepositoryInitialized();
        final downloadedIds = await _repository.getDownloadedVersionIds();
        final versionId = '$_selectedLanguage-$_selectedVersion';

        if (!downloadedIds.contains(versionId)) {
          // File exists but not registered - add it to registry
          _logger.i(
            '[BibleProvider] Registrando versión local no registrada: $versionId',
          );
          await _repository.storage.saveDownloadedVersions([
            ...downloadedIds,
            versionId,
          ]);
        }

        final hasVerses = await _fetchVerses(
          _selectedLanguage,
          _selectedVersion,
        );
        _logger.i(
          '📄 [BibleProvider] ¿Hay versículos?: $hasVerses (${stopwatch.elapsedMilliseconds}ms)',
        );

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
        _logger.i(
          '🎉 [BibleProvider] READY (local, ${stopwatch.elapsedMilliseconds}ms total)',
        );
        notifyListeners();
        return;
      }

      // 1.b Try migrating from bundled assets or legacy locations before downloading
      final migrated =
          await _tryMigrateFromAssets(_selectedLanguage, _selectedVersion);
      if (migrated) {
        _logger.i(
            '[BibleProvider] Migration from assets succeeded for $_selectedVersion');
        // Re-check file existence and proceed as ready if migration produced usable DB
        final fileExistsAfter = await _repository.storage.fileExists(dbPath);
        if (fileExistsAfter) {
          final hasVerses =
              await _fetchVerses(_selectedLanguage, _selectedVersion);
          if (hasVerses) {
            _state = BibleProviderState.ready;
            _errorMessage = null;
            _downloadProgress = 1.0;
            notifyListeners();
            return;
          }
        }
      }

      // 2. File not found locally - need to download
      _logger.i(
        '🌐 [BibleProvider] Archivo no encontrado, iniciando descarga...',
      );

      // Check if version is available and not already downloading
      final isAlreadyDownloaded = await _isVersionDownloadedOptimized(
        _selectedLanguage,
        _selectedVersion,
      );

      if (!isAlreadyDownloaded) {
        _state = BibleProviderState.downloading;
        _downloadProgress = 0.0;
        notifyListeners();

        _logger.i('⬇️ [BibleProvider] Descargando versión...');
        final success = await _downloadVersionWithProgress(
          _selectedLanguage,
          _selectedVersion,
        );

        _logger.i(
          success
              ? '✅ [BibleProvider] Descarga exitosa (${stopwatch.elapsedMilliseconds}ms)'
              : '❌ [BibleProvider] Descarga fallida',
        );

        if (!success) {
          _state = BibleProviderState.error;
          _errorMessage =
              '❌ No se pudo descargar la versión bíblica ($_selectedVersion)';
          _logger.e('❌ [BibleProvider] ERROR descarga: $_errorMessage');
          _downloadProgress = 0.0;
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
      _downloadProgress = 1.0;
      _logger.i(
        '🎉 [BibleProvider] READY (${stopwatch.elapsedMilliseconds}ms total)',
      );
      notifyListeners();
    } catch (e) {
      _state = BibleProviderState.error;
      _errorMessage = '❌ Error: $e';
      _downloadProgress = 0.0;
      _logger.e(
        '❌ [BibleProvider] ERROR general: $e (${stopwatch.elapsedMilliseconds}ms)',
      );
      notifyListeners();
    }
  }

  /// OPTIMIZED: Check if version is downloaded without making API calls when possible
  Future<bool> _isVersionDownloadedOptimized(
    String lang,
    String version,
  ) async {
    // First check the local file directly
    final biblesDir = await _repository.storage.getBiblesDirectory();
    final filename = '${version}_$lang.SQLite3';
    final dbPath = '$biblesDir/$filename';
    final fileExists = await _repository.storage.fileExists(dbPath);

    if (fileExists) {
      _logger.i('[BibleProvider] ✅ Archivo local verificado: $dbPath');
      return true;
    }

    // File doesn't exist, check registry and update if needed
    await _ensureRepositoryInitialized();
    final downloadedIds = await _repository.getDownloadedVersionIds();
    final versionId = '$lang-$version';

    if (downloadedIds.contains(versionId)) {
      // Registry says it's downloaded but file is missing - clean up registry
      _logger.w(
        '[BibleProvider] Versión registrada pero archivo no existe, limpiando registro',
      );
      final updatedIds = downloadedIds.where((id) => id != versionId).toList();
      await _repository.storage.saveDownloadedVersions(updatedIds);
    }

    return false;
  }

  /// Downloads version with progress tracking for UI feedback
  Future<bool> _downloadVersionWithProgress(String lang, String version) async {
    await _ensureRepositoryInitialized();

    // Only fetch metadata from API when we actually need to download
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

    // Subscribe to progress updates with proper cleanup
    final progressSubscription =
        _repository.downloadProgress(versionObj.id).listen((progress) {
      _downloadProgress = progress;
      notifyListeners();
    });

    try {
      // First attempt: try a direct streaming download + on-the-fly decompress
      final biblesDir = await _repository.storage.getBiblesDirectory();
      final dbPath = '$biblesDir/${versionObj.filename}';

      final url = versionObj.downloadUrl;
      bool directOk = false;
      if (url.isNotEmpty) {
        _logger.i('[BibleProvider] Attempting direct stream download...');
        directOk = await _downloadDirectAndDecompress(url, dbPath);
        _logger.i('[BibleProvider] Direct download result: $directOk');
      }

      if (!directOk) {
        // Fallback to repository implementation (existing behavior)
        _logger.i('[BibleProvider] Falling back to repository.downloadVersion');
        await _repository.downloadVersion(versionObj.id);
      }

      final fileExists = await _repository.storage.fileExists(dbPath);

      _logger.i(
        '[BibleProvider] ¿Archivo guardado correctamente?: $fileExists',
      );
      _downloadProgress = 1.0;
      return fileExists;
    } catch (e) {
      _logger.e('[BibleProvider] Error al descargar: $e');
      _downloadProgress = 0.0;
      return false;
    } finally {
      // Always cancel subscription to prevent memory leaks
      await progressSubscription.cancel();
    }
  }

  /// Downloads and writes a (possibly gzipped) file by streaming it and
  /// decoding gzip on-the-fly when appropriate. Reports progress using
  /// `_downloadProgress` and notifies listeners.
  Future<bool> _downloadDirectAndDecompress(
      String url, String targetPath) async {
    await _ensureRepositoryInitialized();

    final adapter = HttpClientAdapter.create();
    Stream<HttpDownloadProgress>? progressStream;
    IOSink? sink;
    StreamController<List<int>>? compressedController;
    try {
      progressStream = adapter.downloadStream(url, percentStep: 1);

      final targetFile = File(targetPath);
      await targetFile.create(recursive: true);
      sink = targetFile.openWrite();

      final bool gzByUrl = url.toLowerCase().endsWith('.gz');

      // Controller that receives compressed chunks from adapter and, if gz, will
      // be decoded using gzip.decoder; otherwise we will write chunks directly.
      compressedController = StreamController<List<int>>();
      final Stream<List<int>> decodedStream = gzByUrl
          ? compressedController.stream.transform(gzip.decoder)
          : compressedController.stream;

      // Writer task: consumes decodedStream and writes to file
      final writer = () async {
        await for (final chunk in decodedStream) {
          sink!.add(chunk);
        }
      }();

      // Feed the compressed controller while reporting progress
      await for (final event in progressStream) {
        // update progress using compressed bytes info (adapter reports downloaded/total)
        if (event.total != null && event.total! > 0) {
          _downloadProgress = min(1.0, event.downloaded / event.total!);
          notifyListeners();
        }
        // Push chunk into controller for decoding/writing
        compressedController.add(event.data);
      }

      // Close controller to signal EOF to decoder, then wait writer
      await compressedController.close();
      await writer;

      await sink.flush();
      await sink.close();

      // final progress set
      _downloadProgress = 1.0;
      notifyListeners();

      // close adapter client
      try {
        adapter.close();
      } catch (_) {}

      return true;
    } catch (e, st) {
      _logger.e('[BibleProvider] Direct download exception: $e\n$st');
      try {
        await compressedController?.close();
      } catch (_) {}
      try {
        await sink?.close();
      } catch (_) {}
      try {
        adapter.close();
      } catch (_) {}
      _downloadProgress = 0.0;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _fetchVerses(String lang, String version) async {
    try {
      final biblesDir = await _repository.storage.getBiblesDirectory();
      final filename = '${version}_$lang.SQLite3';
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
        dbFilePath = '$biblesDir/${versionObj.filename}';
        _logger.i(
          '🌐 [BibleProvider] Archivo no encontrado, usando metadata: $dbFilePath',
        );
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

  /// Verifica si la versión está descargada para el idioma actual
  Future<bool> isVersionDownloaded() async {
    return await _isVersionDownloadedOptimized(
      _selectedLanguage,
      _selectedVersion,
    );
  }

  /// Attempt to copy database file from bundled assets (legacy behavior) into storage.
  /// Returns true if migration wrote a valid file to the bibles directory.
  Future<bool> _tryMigrateFromAssets(String lang, String version) async {
    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getStringList(_migratedVersionsKey) ?? <String>[];
    final key = '$lang:$version';

    try {
      final biblesDir = await _repository.storage.getBiblesDirectory();
      final filename = '${version}_$lang.SQLite3';
      final assetPaths = <String>[
        'assets/bibles/$filename',
        // common location
        'assets/$filename',
        // alternative
        'flutter_assets/assets/bibles/$filename',
        // possible path in some builds
        'flutter_assets/$filename',
      ];

      // If we've already migrated this version earlier, skip reattempt but verify file exists
      if (migrated.contains(key)) {
        final targetPath = '$biblesDir/$filename';
        final exists = await _repository.storage.fileExists(targetPath);
        _logger.i(
            '[BibleProvider] Migration previously done for $key, fileExists: $exists');
        return exists;
      }

      for (final assetPath in assetPaths) {
        try {
          final data = await rootBundle.load(assetPath);
          final bytes = data.buffer.asUint8List();
          final targetPath = '$biblesDir/$filename';
          await _repository.storage.writeFile(targetPath, bytes);
          final exists = await _repository.storage.fileExists(targetPath);
          if (exists) {
            _logger
                .i('[BibleProvider] Migrated asset $assetPath -> $targetPath');
            // Mark as migrated to avoid retrying
            final updated = List<String>.from(migrated)..add(key);
            await prefs.setStringList(_migratedVersionsKey, updated);
            // Also register in repository downloaded list
            try {
              await _ensureRepositoryInitialized();
              final downloadedIds = await _repository.getDownloadedVersionIds();
              final versionId = '$lang-$version';
              if (!downloadedIds.contains(versionId)) {
                await _repository.storage
                    .saveDownloadedVersions([...downloadedIds, versionId]);
              }
            } catch (e) {
              _logger.w(
                  '[BibleProvider] Warning registering migrated version: $e');
            }
            return true;
          }
        } catch (e) {
          // Asset not found at this path or load failed — keep trying other candidates
          _logger.t(
              '[BibleProvider] Asset not found or failed to load: $assetPath ($e)');
        }
      }
    } catch (e) {
      _logger.w('[BibleProvider] Migration attempt failed: $e');
    }
    return false;
  }
}
