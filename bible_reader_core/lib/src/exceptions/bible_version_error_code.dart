/// Error codes for Bible version operations.
///
/// These error codes are used for localization in the UI layer.
/// The actual error messages should be loaded from i18n files.
enum BibleVersionErrorCode {
  /// Network error - failed to connect or download.
  network,

  /// Insufficient storage space on device.
  storage,

  /// Downloaded file is corrupted.
  corrupted,

  /// Requested version was not found.
  notFound,

  /// Metadata parsing failed.
  metadataParsing,

  /// Maximum retry attempts exceeded.
  maxRetriesExceeded,

  /// Decompression of downloaded file failed.
  decompression,

  /// Validation of metadata failed.
  metadataValidation,

  /// Unknown or generic error.
  unknown,
}

/// Extension methods for BibleVersionErrorCode.
extension BibleVersionErrorCodeExtension on BibleVersionErrorCode {
  /// Returns the localization key for this error code.
  String get localizationKey {
    switch (this) {
      case BibleVersionErrorCode.network:
        return 'bible_version.error_network';
      case BibleVersionErrorCode.storage:
        return 'bible_version.error_storage';
      case BibleVersionErrorCode.corrupted:
        return 'bible_version.error_corrupted';
      case BibleVersionErrorCode.notFound:
        return 'bible_version.error_not_found';
      case BibleVersionErrorCode.metadataParsing:
        return 'bible_version.error_metadata_parsing';
      case BibleVersionErrorCode.maxRetriesExceeded:
        return 'bible_version.error_max_retries';
      case BibleVersionErrorCode.decompression:
        return 'bible_version.error_decompression';
      case BibleVersionErrorCode.metadataValidation:
        return 'bible_version.error_metadata_validation';
      case BibleVersionErrorCode.unknown:
        return 'bible_version.error_unknown';
    }
  }
}
