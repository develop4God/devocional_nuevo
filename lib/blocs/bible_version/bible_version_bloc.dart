import 'dart:async';

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bible_version_event.dart';
import 'bible_version_state.dart';

/// BLoC for managing Bible version downloads and state.
///
/// This BLoC wraps the framework-agnostic [BibleVersionRepository] from
/// bible_reader_core and converts its streams/futures to BLoC events and states.
///
/// Usage:
/// ```dart
/// final bloc = BibleVersionBloc(repository: repository);
/// bloc.add(const LoadBibleVersionsEvent());
///
/// // Later:
/// bloc.add(DownloadVersionEvent('es-RVR1960'));
/// ```
class BibleVersionBloc extends Bloc<BibleVersionEvent, BibleVersionState> {
  /// The underlying repository for Bible version operations.
  final BibleVersionRepository repository;

  /// Active download progress subscriptions.
  final Map<String, StreamSubscription<double>> _progressSubscriptions = {};

  /// Creates a BibleVersionBloc with the given repository.
  BibleVersionBloc({required this.repository})
      : super(const BibleVersionInitial()) {
    on<LoadBibleVersionsEvent>(_onLoadVersions);
    on<DownloadVersionEvent>(_onDownloadVersion);
    on<DeleteVersionEvent>(_onDeleteVersion);
    on<UpdateDownloadProgressEvent>(_onUpdateProgress);
    on<DownloadCompletedEvent>(_onDownloadCompleted);
    on<DownloadFailedEvent>(_onDownloadFailed);
  }

  Future<void> _onLoadVersions(
    LoadBibleVersionsEvent event,
    Emitter<BibleVersionState> emit,
  ) async {
    emit(const BibleVersionLoading());

    try {
      // Clear cache if forced refresh
      if (event.forceRefresh) {
        repository.clearMetadataCache();
      }

      // Initialize repository to load downloaded versions
      await repository.initialize();

      // Fetch available versions
      final metadata = await repository.fetchAvailableVersions();
      final downloadedIds = await repository.getDownloadedVersionIds();

      // Convert to versions with state
      final versions = metadata.map((m) {
        final isDownloaded = downloadedIds.contains(m.id);
        return BibleVersionWithState(
          metadata: m,
          state: isDownloaded ? DownloadState.downloaded : DownloadState.notDownloaded,
        );
      }).toList();

      emit(BibleVersionLoaded(
        versions: versions,
        downloadedVersionIds: downloadedIds.toSet(),
      ));
    } on NetworkException catch (e) {
      emit(BibleVersionError(message: 'Network error: ${e.message}'));
    } on MetadataParsingException catch (e) {
      emit(BibleVersionError(message: 'Invalid catalog data: ${e.message}'));
    } catch (e) {
      emit(BibleVersionError(message: 'Failed to load versions: $e'));
    }
  }

  Future<void> _onDownloadVersion(
    DownloadVersionEvent event,
    Emitter<BibleVersionState> emit,
  ) async {
    final currentState = state;
    if (currentState is! BibleVersionLoaded) return;

    // Update the version state to downloading
    final versions = currentState.versions.map((v) {
      if (v.metadata.id == event.versionId) {
        return v.copyWith(state: DownloadState.downloading, progress: 0.0);
      }
      return v;
    }).toList();

    emit(currentState.copyWith(versions: versions));

    // Subscribe to progress updates
    _progressSubscriptions[event.versionId]?.cancel();
    _progressSubscriptions[event.versionId] =
        repository.downloadProgress(event.versionId).listen(
      (progress) {
        add(UpdateDownloadProgressEvent(
          versionId: event.versionId,
          progress: progress,
        ));
      },
    );

    // Start download
    try {
      await repository.downloadVersion(event.versionId);
      add(DownloadCompletedEvent(event.versionId));
    } on InsufficientStorageException catch (e) {
      add(DownloadFailedEvent(
        versionId: event.versionId,
        errorMessage: 'Not enough storage space. Need ${_formatBytes(e.requiredBytes)}.',
      ));
    } on DatabaseCorruptedException {
      add(DownloadFailedEvent(
        versionId: event.versionId,
        errorMessage: 'Downloaded file was corrupted. Please try again.',
      ));
    } on NetworkException catch (e) {
      add(DownloadFailedEvent(
        versionId: event.versionId,
        errorMessage: 'Network error: ${e.message}',
      ));
    } catch (e) {
      add(DownloadFailedEvent(
        versionId: event.versionId,
        errorMessage: 'Download failed: $e',
      ));
    }
  }

  Future<void> _onDeleteVersion(
    DeleteVersionEvent event,
    Emitter<BibleVersionState> emit,
  ) async {
    final currentState = state;
    if (currentState is! BibleVersionLoaded) return;

    try {
      await repository.deleteVersion(event.versionId);

      // Update versions list
      final versions = currentState.versions.map((v) {
        if (v.metadata.id == event.versionId) {
          return v.copyWith(state: DownloadState.notDownloaded, progress: 0.0);
        }
        return v;
      }).toList();

      final downloadedIds = Set<String>.from(currentState.downloadedVersionIds)
        ..remove(event.versionId);

      emit(currentState.copyWith(
        versions: versions,
        downloadedVersionIds: downloadedIds,
      ));
    } catch (e) {
      emit(BibleVersionError(
        message: 'Failed to delete version: $e',
        previousState: currentState,
      ));
    }
  }

  void _onUpdateProgress(
    UpdateDownloadProgressEvent event,
    Emitter<BibleVersionState> emit,
  ) {
    final currentState = state;
    if (currentState is! BibleVersionLoaded) return;

    final versions = currentState.versions.map((v) {
      if (v.metadata.id == event.versionId) {
        return v.copyWith(progress: event.progress);
      }
      return v;
    }).toList();

    emit(currentState.copyWith(versions: versions));
  }

  void _onDownloadCompleted(
    DownloadCompletedEvent event,
    Emitter<BibleVersionState> emit,
  ) {
    _progressSubscriptions[event.versionId]?.cancel();
    _progressSubscriptions.remove(event.versionId);

    final currentState = state;
    if (currentState is! BibleVersionLoaded) return;

    final versions = currentState.versions.map((v) {
      if (v.metadata.id == event.versionId) {
        return v.copyWith(state: DownloadState.downloaded, progress: 1.0);
      }
      return v;
    }).toList();

    final downloadedIds = Set<String>.from(currentState.downloadedVersionIds)
      ..add(event.versionId);

    emit(currentState.copyWith(
      versions: versions,
      downloadedVersionIds: downloadedIds,
    ));
  }

  void _onDownloadFailed(
    DownloadFailedEvent event,
    Emitter<BibleVersionState> emit,
  ) {
    _progressSubscriptions[event.versionId]?.cancel();
    _progressSubscriptions.remove(event.versionId);

    final currentState = state;
    if (currentState is! BibleVersionLoaded) return;

    final versions = currentState.versions.map((v) {
      if (v.metadata.id == event.versionId) {
        return v.copyWith(
          state: DownloadState.failed,
          progress: 0.0,
          errorMessage: event.errorMessage,
        );
      }
      return v;
    }).toList();

    emit(currentState.copyWith(versions: versions));
  }

  /// Formats bytes to human-readable string.
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Future<void> close() {
    for (final subscription in _progressSubscriptions.values) {
      subscription.cancel();
    }
    _progressSubscriptions.clear();
    repository.dispose();
    return super.close();
  }
}
