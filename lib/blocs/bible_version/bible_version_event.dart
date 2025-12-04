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

  const LoadBibleVersionsEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

/// Event to download a Bible version.
class DownloadVersionEvent extends BibleVersionEvent {
  /// The ID of the version to download.
  final String versionId;

  const DownloadVersionEvent(this.versionId);

  @override
  List<Object?> get props => [versionId];
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

  /// Error message describing the failure.
  final String errorMessage;

  const DownloadFailedEvent({
    required this.versionId,
    required this.errorMessage,
  });

  @override
  List<Object?> get props => [versionId, errorMessage];
}
