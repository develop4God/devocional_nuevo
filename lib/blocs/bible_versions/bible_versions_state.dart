import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:equatable/equatable.dart';

/// Per-version download progress/status, keyed by dbFileName in
/// [BibleVersionsLoaded.downloadStatuses].
class VersionDownloadStatus extends Equatable {
  final double? progress;
  final bool isComplete;
  final String? errorMessageKey;

  const VersionDownloadStatus({
    this.progress,
    this.isComplete = false,
    this.errorMessageKey,
  });

  VersionDownloadStatus copyWith({
    double? progress,
    bool? isComplete,
    String? errorMessageKey,
  }) {
    return VersionDownloadStatus(
      progress: progress ?? this.progress,
      isComplete: isComplete ?? this.isComplete,
      errorMessageKey: errorMessageKey ?? this.errorMessageKey,
    );
  }

  @override
  List<Object?> get props => [progress, isComplete, errorMessageKey];
}

abstract class BibleVersionsState extends Equatable {
  const BibleVersionsState();

  @override
  List<Object?> get props => [];
}

class BibleVersionsInitial extends BibleVersionsState {}

class BibleVersionsLoading extends BibleVersionsState {}

class BibleVersionsLoaded extends BibleVersionsState {
  final List<BibleVersion> remoteVersions;
  final Map<String, VersionDownloadStatus> downloadStatuses;

  const BibleVersionsLoaded({
    required this.remoteVersions,
    required this.downloadStatuses,
  });

  BibleVersionsLoaded copyWith({
    List<BibleVersion>? remoteVersions,
    Map<String, VersionDownloadStatus>? downloadStatuses,
  }) {
    return BibleVersionsLoaded(
      remoteVersions: remoteVersions ?? this.remoteVersions,
      downloadStatuses: downloadStatuses ?? this.downloadStatuses,
    );
  }

  @override
  List<Object?> get props => [remoteVersions, downloadStatuses];
}

class BibleVersionsError extends BibleVersionsState {
  final String messageKey;

  const BibleVersionsError(this.messageKey);

  @override
  List<Object?> get props => [messageKey];
}
