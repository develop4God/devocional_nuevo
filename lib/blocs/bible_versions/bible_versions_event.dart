import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:equatable/equatable.dart';

abstract class BibleVersionsEvent extends Equatable {
  const BibleVersionsEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the remote versions available for [languageCode].
/// [forceRefresh] bypasses the repository's session cache.
class LoadAvailableVersions extends BibleVersionsEvent {
  final String languageCode;
  final bool forceRefresh;

  const LoadAvailableVersions({
    required this.languageCode,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [languageCode, forceRefresh];
}

/// Starts downloading [version].
class DownloadBibleVersion extends BibleVersionsEvent {
  final BibleVersion version;

  const DownloadBibleVersion(this.version);

  @override
  List<Object?> get props => [version];
}

/// Internal — threaded from the repository's onProgress callback.
/// Not dispatched by UI code.
class DownloadProgressUpdated extends BibleVersionsEvent {
  final String dbFileName;
  final double? progress;

  const DownloadProgressUpdated({
    required this.dbFileName,
    required this.progress,
  });

  @override
  List<Object?> get props => [dbFileName, progress];
}

/// Internal — signals a successful download completion.
class DownloadCompleted extends BibleVersionsEvent {
  final String dbFileName;

  const DownloadCompleted(this.dbFileName);

  @override
  List<Object?> get props => [dbFileName];
}

/// Internal — signals a failed download.
class DownloadFailed extends BibleVersionsEvent {
  final String dbFileName;
  final String errorMessageKey;

  const DownloadFailed({
    required this.dbFileName,
    required this.errorMessageKey,
  });

  @override
  List<Object?> get props => [dbFileName, errorMessageKey];
}
