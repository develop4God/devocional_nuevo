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
    );
  }

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
      uncompressedSizeBytes: uncompressedSizeBytes ?? this.uncompressedSizeBytes,
      version: version ?? this.version,
      description: description ?? this.description,
      license: license ?? this.license,
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
        other.license == license;
  }

  @override
  int get hashCode {
    return Object.hash(
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
    );
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

  /// The version is currently being downloaded.
  downloading,

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

  /// Error message if state is [DownloadState.failed].
  final String? errorMessage;

  /// Creates a version with state.
  const BibleVersionWithState({
    required this.metadata,
    required this.state,
    this.progress = 0.0,
    this.errorMessage,
  });

  /// Creates a copy with optionally modified fields.
  /// 
  /// Use `clearError: true` to explicitly clear the error message.
  BibleVersionWithState copyWith({
    BibleVersionMetadata? metadata,
    DownloadState? state,
    double? progress,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BibleVersionWithState(
      metadata: metadata ?? this.metadata,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BibleVersionWithState &&
        other.metadata == metadata &&
        other.state == state &&
        other.progress == progress &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(metadata, state, progress, errorMessage);

  @override
  String toString() {
    return 'BibleVersionWithState(id: ${metadata.id}, state: $state, progress: $progress)';
  }
}
