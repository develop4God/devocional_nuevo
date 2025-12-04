/// Exceptions for the Bible version repository.
///
/// These exceptions provide specific error types for different failure scenarios
/// that can occur during Bible version operations.
library;

/// Base exception for all Bible version repository errors.
class BibleVersionException implements Exception {
  /// Human-readable error message.
  final String message;

  /// Optional underlying error that caused this exception.
  final Object? cause;

  /// Creates a Bible version exception.
  const BibleVersionException(this.message, [this.cause]);

  @override
  String toString() => 'BibleVersionException: $message';
}

/// Exception thrown when a network operation fails.
class NetworkException extends BibleVersionException {
  /// HTTP status code if available.
  final int? statusCode;

  /// Creates a network exception.
  const NetworkException(
    String message, {
    this.statusCode,
    Object? cause,
  }) : super(message, cause);

  @override
  String toString() => 'NetworkException: $message (statusCode: $statusCode)';
}

/// Exception thrown when there isn't enough storage space.
class InsufficientStorageException extends BibleVersionException {
  /// Available space in bytes.
  final int availableBytes;

  /// Required space in bytes.
  final int requiredBytes;

  /// Creates an insufficient storage exception.
  const InsufficientStorageException({
    required this.availableBytes,
    required this.requiredBytes,
    Object? cause,
  }) : super(
          'Insufficient storage space: need $requiredBytes bytes, '
          'but only $availableBytes available',
          cause,
        );

  @override
  String toString() =>
      'InsufficientStorageException: need $requiredBytes bytes, '
      'have $availableBytes bytes';
}

/// Exception thrown when a downloaded database is corrupted.
class DatabaseCorruptedException extends BibleVersionException {
  /// The version ID that was corrupted.
  final String versionId;

  /// Creates a database corrupted exception.
  const DatabaseCorruptedException(this.versionId, [Object? cause])
      : super('Database for version $versionId is corrupted', cause);

  @override
  String toString() => 'DatabaseCorruptedException: $versionId';
}

/// Exception thrown when metadata JSON is malformed.
class MetadataParsingException extends BibleVersionException {
  /// Creates a metadata parsing exception.
  const MetadataParsingException(super.message, [super.cause]);

  @override
  String toString() => 'MetadataParsingException: $message';
}

/// Exception thrown when a requested version is not found.
class VersionNotFoundException extends BibleVersionException {
  /// The version ID that was not found.
  final String versionId;

  /// Creates a version not found exception.
  const VersionNotFoundException(this.versionId, [Object? cause])
      : super('Version $versionId not found', cause);

  @override
  String toString() => 'VersionNotFoundException: $versionId';
}

/// Exception thrown when a download is cancelled.
class DownloadCancelledException extends BibleVersionException {
  /// The version ID whose download was cancelled.
  final String versionId;

  /// Creates a download cancelled exception.
  const DownloadCancelledException(this.versionId, [Object? cause])
      : super('Download cancelled for version $versionId', cause);

  @override
  String toString() => 'DownloadCancelledException: $versionId';
}

/// Exception thrown when decompression fails.
class DecompressionException extends BibleVersionException {
  /// The version ID that failed to decompress.
  final String versionId;

  /// Creates a decompression exception.
  const DecompressionException(this.versionId, [Object? cause])
      : super('Failed to decompress version $versionId', cause);

  @override
  String toString() => 'DecompressionException: $versionId';
}

/// Exception thrown when metadata validation fails.
class MetadataValidationException extends BibleVersionException {
  /// List of validation errors.
  final List<String> errors;

  /// Creates a metadata validation exception.
  MetadataValidationException(this.errors)
      : super('Metadata validation failed: ${errors.join(', ')}');

  @override
  String toString() => 'MetadataValidationException: ${errors.join(', ')}';
}

/// Exception thrown when maximum retry attempts are exceeded.
class MaxRetriesExceededException extends BibleVersionException {
  /// The version ID that exceeded retries.
  final String versionId;

  /// Number of retry attempts made.
  final int attempts;

  /// Creates a max retries exceeded exception.
  const MaxRetriesExceededException({
    required this.versionId,
    required this.attempts,
    Object? cause,
  }) : super('Download failed after $attempts attempts for $versionId', cause);

  @override
  String toString() =>
      'MaxRetriesExceededException: $versionId after $attempts attempts';
}
