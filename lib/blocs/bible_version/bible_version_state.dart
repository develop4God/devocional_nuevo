import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:equatable/equatable.dart';

/// States for the BibleVersionBloc.
abstract class BibleVersionState extends Equatable {
  const BibleVersionState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded.
class BibleVersionInitial extends BibleVersionState {
  const BibleVersionInitial();
}

/// State while loading Bible versions from the catalog.
class BibleVersionLoading extends BibleVersionState {
  const BibleVersionLoading();
}

/// State when Bible versions are successfully loaded.
class BibleVersionLoaded extends BibleVersionState {
  /// List of all available Bible versions with their current state.
  final List<BibleVersionWithState> versions;

  /// Set of version IDs that are currently downloaded.
  final Set<String> downloadedVersionIds;

  /// Current queue positions for queued downloads.
  final Map<String, int> queuePositions;

  const BibleVersionLoaded({
    required this.versions,
    required this.downloadedVersionIds,
    this.queuePositions = const {},
  });

  /// Returns versions filtered by language.
  List<BibleVersionWithState> getVersionsByLanguage(String languageCode) {
    return versions
        .where((v) => v.metadata.language == languageCode)
        .toList();
  }

  /// Returns only downloaded versions.
  List<BibleVersionWithState> get downloadedVersions {
    return versions
        .where((v) => v.state == DownloadState.downloaded)
        .toList();
  }

  /// Returns versions that are not downloaded.
  List<BibleVersionWithState> get availableVersions {
    return versions
        .where((v) => v.state == DownloadState.notDownloaded)
        .toList();
  }

  /// Returns versions currently in the download queue.
  List<BibleVersionWithState> get queuedVersions {
    return versions
        .where((v) => v.state == DownloadState.queued)
        .toList();
  }

  /// Returns versions currently being validated.
  List<BibleVersionWithState> get validatingVersions {
    return versions
        .where((v) => v.state == DownloadState.validating)
        .toList();
  }

  /// Creates a copy with updated versions.
  BibleVersionLoaded copyWith({
    List<BibleVersionWithState>? versions,
    Set<String>? downloadedVersionIds,
    Map<String, int>? queuePositions,
  }) {
    return BibleVersionLoaded(
      versions: versions ?? this.versions,
      downloadedVersionIds: downloadedVersionIds ?? this.downloadedVersionIds,
      queuePositions: queuePositions ?? this.queuePositions,
    );
  }

  @override
  List<Object?> get props => [versions, downloadedVersionIds, queuePositions];
}

/// State when loading or an operation fails.
class BibleVersionError extends BibleVersionState {
  /// Error message describing what went wrong.
  final String message;

  /// Previous state before the error, if available.
  /// This allows the UI to show an error while keeping the last known data.
  final BibleVersionLoaded? previousState;

  const BibleVersionError({
    required this.message,
    this.previousState,
  });

  @override
  List<Object?> get props => [message, previousState];
}
