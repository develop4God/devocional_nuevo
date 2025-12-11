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
/// Features:
/// - Download queue management with priority support
/// - Retry logic with exponential backoff
/// - Queue position tracking
/// - Validation state tracking
///
/// Usage:
/// ```dart
/// final bloc = BibleVersionBloc(repository: repository);
/// bloc.add(const LoadBibleVersionsEvent());
///
/// // Later, download with high priority:
/// bloc.add(DownloadVersionEvent('es-RVR1960', priority: DownloadPriority.high));
/// ```
class BibleVersionBloc extends Bloc<BibleVersionEvent, BibleVersionState> {
  /// The underlying repository for Bible version operations.
  final BibleVersionRepository repository;

  /// Active download progress subscriptions.
  final Map<String, StreamSubscription<double>> _progressSubscriptions = {};

  /// Subscription for queue position updates.
  StreamSubscription<Map<String, int>>? _queuePositionSubscription;

  /// Creates a BibleVersionBloc with the given repository.
  BibleVersionBloc({required this.repository})
      : super(const BibleVersionInitial()) {
    on<LoadBibleVersionsEvent>(_onLoadVersions);
    on<DownloadVersionEvent>(_onDownloadVersion);
    on<DeleteVersionEvent>(_onDeleteVersion);
    on<UpdateDownloadProgressEvent>(_onUpdateProgress);
    on<DownloadCompletedEvent>(_onDownloadCompleted);
    on<DownloadFailedEvent>(_onDownloadFailed);
    on<UpdateQueuePositionsEvent>(_onUpdateQueuePositions);
    on<ValidationStartedEvent>(_onValidationStarted);

    // Subscribe to queue position updates
    _queuePositionSubscription =
        repository.queuePositionUpdates.listen((positions) {
      add(UpdateQueuePositionsEvent(positions));
    });
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
      late final List<BibleVersionMetadata> metadata;
      if (event.languageCode != null) {
        // Only fetch the requested language to avoid unnecessary API calls
        metadata =
            await repository.fetchVersionsByLanguage(event.languageCode!);
      } else {
        metadata = await repository.fetchAvailableVersions();
      }
      final downloadedIds = await repository.getDownloadedVersionIds();

      // Obtener el id de la versión seleccionada (si está disponible)
      final selectedVersionId = event.selectedVersionId;

      // Convert to versions with state, marcando la seleccionada
      final versions = metadata.map((m) {
        final isDownloaded = downloadedIds.contains(m.id);
        final isSelected =
            selectedVersionId != null && m.id == selectedVersionId;
        return BibleVersionWithState(
          metadata: m,
          state: isDownloaded
              ? DownloadState.downloaded
              : DownloadState.notDownloaded,
          isSelected: isSelected,
        );
      }).toList();

      emit(BibleVersionLoaded(
        versions: versions,
        downloadedVersionIds: downloadedIds.toSet(),
      ));
    } on NetworkException {
      emit(const BibleVersionError(errorCode: BibleVersionErrorCode.network));
    } on MetadataParsingException {
      emit(const BibleVersionError(
          errorCode: BibleVersionErrorCode.metadataParsing));
    } catch (e) {
      emit(BibleVersionError(
        errorCode: BibleVersionErrorCode.unknown,
        context: {'error': e.toString()},
      ));
    }
  }

  Future<void> _onDownloadVersion(
    DownloadVersionEvent event,
    Emitter<BibleVersionState> emit,
  ) async {
    final currentState = state;
    if (currentState is! BibleVersionLoaded) return;

    // Check if version is already queued or downloading
    final existingVersion = currentState.versions.firstWhere(
      (v) => v.metadata.id == event.versionId,
      orElse: () => throw StateError('Version not found: ${event.versionId}'),
    );
    if (existingVersion.state == DownloadState.downloading ||
        existingVersion.state == DownloadState.queued) {
      return; // Already in progress
    }

    // Update the version state to queued initially
    final versions = currentState.versions.map((v) {
      if (v.metadata.id == event.versionId) {
        return v.copyWith(
            state: DownloadState.queued, progress: 0.0, clearError: true);
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

    // Start download with priority
    try {
      await repository.downloadVersion(event.versionId,
          priority: event.priority);
      add(DownloadCompletedEvent(event.versionId));
    } on InsufficientStorageException catch (e) {
      add(DownloadFailedEvent(
        versionId: event.versionId,
        errorCode: BibleVersionErrorCode.storage,
        context: {'requiredBytes': e.requiredBytes},
      ));
    } on DatabaseCorruptedException {
      add(DownloadFailedEvent(
        versionId: event.versionId,
        errorCode: BibleVersionErrorCode.corrupted,
      ));
    } on MaxRetriesExceededException catch (e) {
      add(DownloadFailedEvent(
        versionId: event.versionId,
        errorCode: BibleVersionErrorCode.maxRetriesExceeded,
        context: {'attempts': e.attempts},
      ));
    } on NetworkException {
      add(DownloadFailedEvent(
        versionId: event.versionId,
        errorCode: BibleVersionErrorCode.network,
      ));
    } catch (e) {
      add(DownloadFailedEvent(
        versionId: event.versionId,
        errorCode: BibleVersionErrorCode.unknown,
        context: {'error': e.toString()},
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
          return v.copyWith(
              state: DownloadState.notDownloaded,
              progress: 0.0,
              clearError: true);
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
        errorCode: BibleVersionErrorCode.unknown,
        context: {'error': e.toString()},
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
          errorCode: event.errorCode,
          errorContext: event.context,
        );
      }
      return v;
    }).toList();

    emit(currentState.copyWith(versions: versions));
  }

  void _onUpdateQueuePositions(
    UpdateQueuePositionsEvent event,
    Emitter<BibleVersionState> emit,
  ) {
    final currentState = state;
    if (currentState is! BibleVersionLoaded) return;

    // Update version states based on queue positions
    final versions = currentState.versions.map((v) {
      final position = event.positions[v.metadata.id];
      if (position != null) {
        // In queue - update position, preserve downloading state if already downloading
        final newState = v.state == DownloadState.downloading
            ? DownloadState.downloading
            : DownloadState.queued;
        return v.copyWith(state: newState, queuePosition: position);
      } else if (v.state == DownloadState.queued) {
        // Was in queue but now processing - set to downloading
        return v.copyWith(state: DownloadState.downloading, queuePosition: 0);
      }
      return v;
    }).toList();

    emit(currentState.copyWith(
      versions: versions,
      queuePositions: event.positions,
    ));
  }

  void _onValidationStarted(
    ValidationStartedEvent event,
    Emitter<BibleVersionState> emit,
  ) {
    final currentState = state;
    if (currentState is! BibleVersionLoaded) return;

    final versions = currentState.versions.map((v) {
      if (v.metadata.id == event.versionId) {
        return v.copyWith(state: DownloadState.validating);
      }
      return v;
    }).toList();

    emit(currentState.copyWith(versions: versions));
  }

  @override
  Future<void> close() {
    _queuePositionSubscription?.cancel();
    for (final subscription in _progressSubscriptions.values) {
      subscription.cancel();
    }
    _progressSubscriptions.clear();
    repository.dispose();
    return super.close();
  }
}
