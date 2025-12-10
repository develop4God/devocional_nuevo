import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:equatable/equatable.dart';

/// Events for the BibleVersionBloc.
abstract class BibleVersionEvent extends Equatable {
  const BibleVersionEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load available Bible versions from the remote catalog.
class LoadBibleVersionsEvent extends BibleVersionEvent {
  /// If true, forces a refresh from the server.
  final bool forceRefresh;

  /// Optional language code to fetch only that language's versions (e.g., 'fr').
  final String? languageCode;

  const LoadBibleVersionsEvent({this.forceRefresh = false, this.languageCode});

  @override
  List<Object?> get props => [forceRefresh, languageCode];
}

/// Event to download a Bible version.
class DownloadVersionEvent extends BibleVersionEvent {
  /// The ID of the version to download.
  final String versionId;

  /// Download priority (high moves to front of queue).
  final DownloadPriority priority;

  const DownloadVersionEvent(
    this.versionId, {
    this.priority = DownloadPriority.normal,
  });

  @override
  List<Object?> get props => [versionId, priority];
}

/// Event to delete a downloaded Bible version.
class DeleteVersionEvent extends BibleVersionEvent {
  /// The ID of the version to delete.
  final String versionId;

  const DeleteVersionEvent(this.versionId);

  @override
  List<Object?> get props => [versionId];
}

/// Event to update download progress.
class UpdateDownloadProgressEvent extends BibleVersionEvent {
  /// The ID of the version being downloaded.
  final String versionId;

  /// Progress as a value between 0.0 and 1.0.
  final double progress;

  const UpdateDownloadProgressEvent({
    required this.versionId,
    required this.progress,
  });

  @override
  List<Object?> get props => [versionId, progress];
}

/// Event when a download completes successfully.
class DownloadCompletedEvent extends BibleVersionEvent {
  /// The ID of the version that was downloaded.
  final String versionId;

  const DownloadCompletedEvent(this.versionId);

  @override
  List<Object?> get props => [versionId];
}

/// Event when a download fails.
class DownloadFailedEvent extends BibleVersionEvent {
  /// The ID of the version that failed to download.
  final String versionId;

  /// Error code for localization.
  final BibleVersionErrorCode errorCode;

  /// Optional context data for error message formatting.
  final Map<String, dynamic>? context;

  const DownloadFailedEvent({
    required this.versionId,
    required this.errorCode,
    this.context,
  });

  @override
  List<Object?> get props => [versionId, errorCode, context];
}

/// Event to update queue positions.
class UpdateQueuePositionsEvent extends BibleVersionEvent {
  /// Map of version ID to queue position.
  final Map<String, int> positions;

  const UpdateQueuePositionsEvent(this.positions);

  @override
  List<Object?> get props => [positions];
}

/// Event when validation starts after download.
class ValidationStartedEvent extends BibleVersionEvent {
  /// The ID of the version being validated.
  final String versionId;

  const ValidationStartedEvent(this.versionId);

  @override
  List<Object?> get props => [versionId];
}
