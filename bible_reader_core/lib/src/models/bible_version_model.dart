import '../exceptions/bible_version_error_code.dart';
import '../exceptions/bible_version_exceptions.dart';

/// Valid ISO 639-1 language codes for Bible versions.
const Set<String> _validLanguageCodes = {
  'es',
  'en',
  'pt',
  'fr',
  'ja',
  'de',
  'it',
  'ko',
  'zh',
  'ru',
  'ar',
  'he',
  'el',
  'la',
};

/// Data model for Bible version metadata.
///
/// This is a pure Dart class with no framework dependencies.
/// Manual equality implementation is used instead of package:equatable.
class BibleVersionMetadata {
  /// Unique identifier for the version (e.g., 'es-RVR1960', 'en-KJV').
  final String id;

  /// Display name of the version (e.g., 'Reina Valera 1960').
  final String name;

  /// Language code (e.g., 'es', 'en', 'pt').
  final String language;

  /// Full language name (e.g., 'Español', 'English').
  final String languageName;

  /// Filename of the database file (e.g., 'RVR1960_es.SQLite3').
  final String filename;

  /// URL to download the version (compressed .gz file).
  final String downloadUrl;

  /// URL to download the raw uncompressed file.
  final String rawUrl;

  /// Size of the compressed download in bytes.
  final int sizeBytes;

  /// Size of the uncompressed database in bytes.
  final int uncompressedSizeBytes;

  /// Version string (e.g., '1.0.0').
  final String version;

  /// Description of the Bible version.
  final String description;

  /// License information.
  final String license;

  /// SHA-256 hash for integrity verification (optional).
  final String? sha256Hash;

  /// Schema version for database compatibility (optional).
  final int? schemaVersion;

  /// Creates a Bible version metadata instance.
  const BibleVersionMetadata({
    required this.id,
    required this.name,
    required this.language,
    required this.languageName,
    required this.filename,
    required this.downloadUrl,
    required this.rawUrl,
    required this.sizeBytes,
    required this.uncompressedSizeBytes,
    required this.version,
    required this.description,
    required this.license,
    this.sha256Hash,
    this.schemaVersion,
  });

  /// Creates a BibleVersionMetadata from a JSON map.
  factory BibleVersionMetadata.fromJson(Map<String, dynamic> json) {
    return BibleVersionMetadata(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      language: json['language'] as String? ?? '',
      languageName: json['languageName'] as String? ?? '',
      filename: json['filename'] as String? ?? '',
      downloadUrl: json['downloadUrl'] as String? ?? '',
      rawUrl: json['rawUrl'] as String? ?? '',
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      uncompressedSizeBytes: json['uncompressedSizeBytes'] as int? ?? 0,
      version: json['version'] as String? ?? '1.0.0',
      description: json['description'] as String? ?? '',
      license: json['license'] as String? ?? '',
      sha256Hash: json['sha256Hash'] as String?,
      schemaVersion: json['schemaVersion'] as int?,
    );
  }

  /// Creates a BibleVersionMetadata from JSON with validation.
  ///
  /// Throws [MetadataValidationException] if the data is invalid.
  factory BibleVersionMetadata.fromJsonValidated(Map<String, dynamic> json) {
    final metadata = BibleVersionMetadata.fromJson(json);
    final errors = metadata.validate();
    if (errors.isNotEmpty) {
      throw MetadataValidationException(errors);
    }
    return metadata;
  }

  /// Validates the metadata and returns a list of validation errors.
  ///
  /// Returns an empty list if the metadata is valid.
  List<String> validate() {
    final errors = <String>[];

    // Required fields
    if (id.isEmpty) {
      errors.add('ID is required');
    }
    if (name.isEmpty) {
      errors.add('Name is required');
    }
    if (language.isEmpty) {
      errors.add('Language code is required');
    } else if (!_validLanguageCodes.contains(language)) {
      errors.add('Invalid language code: $language');
    }

    // URL format validation
    if (downloadUrl.isNotEmpty && !_isValidUrl(downloadUrl)) {
      errors.add('Invalid download URL format');
    }
    if (rawUrl.isNotEmpty && !_isValidUrl(rawUrl)) {
      errors.add('Invalid raw URL format');
    }

    // File size validation
    if (sizeBytes < 0) {
      errors.add('Size bytes must be non-negative');
    }
    if (uncompressedSizeBytes < 0) {
      errors.add('Uncompressed size bytes must be non-negative');
    }

    return errors;
  }

  /// Checks if a URL is valid.
  static bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (_) {
      return false;
    }
  }

  /// Returns true if this metadata passes validation.
  bool get isValid => validate().isEmpty;

  /// Converts this metadata to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'language': language,
      'languageName': languageName,
      'filename': filename,
      'downloadUrl': downloadUrl,
      'rawUrl': rawUrl,
      'sizeBytes': sizeBytes,
      'uncompressedSizeBytes': uncompressedSizeBytes,
      'version': version,
      'description': description,
      'license': license,
      if (sha256Hash != null) 'sha256Hash': sha256Hash,
      if (schemaVersion != null) 'schemaVersion': schemaVersion,
    };
  }

  /// Creates a copy with optionally modified fields.
  BibleVersionMetadata copyWith({
    String? id,
    String? name,
    String? language,
    String? languageName,
    String? filename,
    String? downloadUrl,
    String? rawUrl,
    int? sizeBytes,
    int? uncompressedSizeBytes,
    String? version,
    String? description,
    String? license,
    String? sha256Hash,
    int? schemaVersion,
  }) {
    return BibleVersionMetadata(
      id: id ?? this.id,
      name: name ?? this.name,
      language: language ?? this.language,
      languageName: languageName ?? this.languageName,
      filename: filename ?? this.filename,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      rawUrl: rawUrl ?? this.rawUrl,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      uncompressedSizeBytes:
          uncompressedSizeBytes ?? this.uncompressedSizeBytes,
      version: version ?? this.version,
      description: description ?? this.description,
      license: license ?? this.license,
      sha256Hash: sha256Hash ?? this.sha256Hash,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BibleVersionMetadata &&
        other.id == id &&
        other.name == name &&
        other.language == language &&
        other.languageName == languageName &&
        other.filename == filename &&
        other.downloadUrl == downloadUrl &&
        other.rawUrl == rawUrl &&
        other.sizeBytes == sizeBytes &&
        other.uncompressedSizeBytes == uncompressedSizeBytes &&
        other.version == version &&
        other.description == description &&
        other.license == license &&
        other.sha256Hash == sha256Hash &&
        other.schemaVersion == schemaVersion;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      name,
      language,
      languageName,
      filename,
      downloadUrl,
      rawUrl,
      sizeBytes,
      uncompressedSizeBytes,
      version,
      description,
      license,
      sha256Hash,
      schemaVersion,
    ]);
  }

  @override
  String toString() {
    return 'BibleVersionMetadata(id: $id, name: $name, language: $language)';
  }
}

/// Represents the download state of a Bible version.
enum DownloadState {
  /// The version is not downloaded and available for download.
  notDownloaded,

  /// The version is queued for download behind other downloads.
  queued,

  /// The version is currently being downloaded.
  downloading,

  /// The download has been paused by the user.
  paused,

  /// The download is complete and validating the database.
  validating,

  /// The version has been downloaded and is available.
  downloaded,

  /// The download failed and needs to be retried.
  failed,
}

/// Combines version metadata with its current download state.
class BibleVersionWithState {
  /// The version metadata.
  final BibleVersionMetadata metadata;

  /// The current download state.
  final DownloadState state;

  /// Download progress as a value between 0.0 and 1.0.
  /// Only meaningful when state is [DownloadState.downloading].
  final double progress;

  /// Error code if state is [DownloadState.failed].
  final BibleVersionErrorCode? errorCode;

  /// Optional context data for error message formatting.
  final Map<String, dynamic>? errorContext;

  /// Queue position when state is [DownloadState.queued].
  /// 0 means not in queue, 1 means next to download.
  final int queuePosition;

  /// Flag to indicate if this version is currently selected.
  final bool isSelected;

  /// Creates a version with state.
  const BibleVersionWithState({
    required this.metadata,
    required this.state,
    this.progress = 0.0,
    this.errorCode,
    this.errorContext,
    this.queuePosition = 0,
    this.isSelected = false,
  });

  /// Creates a copy with optionally modified fields.
  ///
  /// Use `clearError: true` to explicitly clear the error.
  BibleVersionWithState copyWith({
    BibleVersionMetadata? metadata,
    DownloadState? state,
    double? progress,
    BibleVersionErrorCode? errorCode,
    Map<String, dynamic>? errorContext,
    bool clearError = false,
    int? queuePosition,
    bool? isSelected,
  }) {
    return BibleVersionWithState(
      metadata: metadata ?? this.metadata,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      errorContext: clearError ? null : (errorContext ?? this.errorContext),
      queuePosition: queuePosition ?? this.queuePosition,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BibleVersionWithState &&
        other.metadata == metadata &&
        other.state == state &&
        other.progress == progress &&
        other.errorCode == errorCode &&
        other.queuePosition == queuePosition;
  }

  @override
  int get hashCode =>
      Object.hash(metadata, state, progress, errorCode, queuePosition);

  @override
  String toString() {
    return 'BibleVersionWithState(id: ${metadata.id}, state: $state, progress: $progress)';
  }
}
