import 'package:devocional_nuevo/blocs/bible_versions/bible_versions_event.dart';
import 'package:devocional_nuevo/blocs/bible_versions/bible_versions_state.dart';
import 'package:devocional_nuevo/repositories/bible_version_repository.dart';
import 'package:devocional_nuevo/repositories/i_bible_version_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BibleVersionsBloc extends Bloc<BibleVersionsEvent, BibleVersionsState> {
  final IBibleVersionRepository _repository;

  BibleVersionsBloc({required IBibleVersionRepository repository})
      : _repository = repository,
        super(BibleVersionsInitial()) {
    on<LoadAvailableVersions>(_onLoadAvailableVersions);
    on<DownloadBibleVersion>(_onDownloadBibleVersion);
    on<DownloadProgressUpdated>(_onDownloadProgressUpdated);
    on<DownloadCompleted>(_onDownloadCompleted);
    on<DownloadFailed>(_onDownloadFailed);
  }

  Future<void> _onLoadAvailableVersions(
    LoadAvailableVersions event,
    Emitter<BibleVersionsState> emit,
  ) async {
    emit(BibleVersionsLoading());
    try {
      final versions = await _repository.fetchRemoteVersions(
        event.languageCode,
      );
      emit(
        BibleVersionsLoaded(
            remoteVersions: versions, downloadStatuses: const {}),
      );
    } catch (_) {
      emit(const BibleVersionsError('bible.download_error_network'));
    }
  }

  Future<void> _onDownloadBibleVersion(
    DownloadBibleVersion event,
    Emitter<BibleVersionsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! BibleVersionsLoaded) return;

    final dbFileName = event.version.dbFileName;
    final existingStatus = currentState.downloadStatuses[dbFileName];
    final alreadyInFlight = existingStatus != null &&
        !existingStatus.isComplete &&
        existingStatus.errorMessageKey == null;
    if (alreadyInFlight) return;

    emit(
      currentState.copyWith(
        downloadStatuses: {
          ...currentState.downloadStatuses,
          dbFileName: const VersionDownloadStatus(progress: 0.0),
        },
      ),
    );

    try {
      await _repository.downloadVersion(
        event.version,
        onProgress: (progress) {
          if (!isClosed) {
            add(
              DownloadProgressUpdated(
                dbFileName: dbFileName,
                progress: progress,
              ),
            );
          }
        },
      );
      if (!isClosed) add(DownloadCompleted(dbFileName));
    } on BibleVersionDownloadException catch (e) {
      if (!isClosed) {
        add(
          DownloadFailed(
            dbFileName: dbFileName,
            errorMessageKey: _errorKeyFor(e.kind),
          ),
        );
      }
    } catch (_) {
      if (!isClosed) {
        add(
          DownloadFailed(
            dbFileName: dbFileName,
            errorMessageKey: 'bible.download_error_network',
          ),
        );
      }
    }
  }

  void _onDownloadProgressUpdated(
    DownloadProgressUpdated event,
    Emitter<BibleVersionsState> emit,
  ) {
    final currentState = state;
    if (currentState is! BibleVersionsLoaded) return;

    final existing = currentState.downloadStatuses[event.dbFileName] ??
        const VersionDownloadStatus();
    emit(
      currentState.copyWith(
        downloadStatuses: {
          ...currentState.downloadStatuses,
          event.dbFileName: existing.copyWith(progress: event.progress),
        },
      ),
    );
  }

  void _onDownloadCompleted(
    DownloadCompleted event,
    Emitter<BibleVersionsState> emit,
  ) {
    final currentState = state;
    if (currentState is! BibleVersionsLoaded) return;

    final existing = currentState.downloadStatuses[event.dbFileName] ??
        const VersionDownloadStatus();
    emit(
      currentState.copyWith(
        downloadStatuses: {
          ...currentState.downloadStatuses,
          event.dbFileName: existing.copyWith(
            progress: 1.0,
            isComplete: true,
          ),
        },
      ),
    );
  }

  void _onDownloadFailed(
    DownloadFailed event,
    Emitter<BibleVersionsState> emit,
  ) {
    final currentState = state;
    if (currentState is! BibleVersionsLoaded) return;

    emit(
      currentState.copyWith(
        downloadStatuses: {
          ...currentState.downloadStatuses,
          event.dbFileName: VersionDownloadStatus(
            errorMessageKey: event.errorMessageKey,
          ),
        },
      ),
    );
  }

  String _errorKeyFor(BibleVersionDownloadErrorKind kind) {
    switch (kind) {
      case BibleVersionDownloadErrorKind.network:
        return 'bible.download_error_network';
      case BibleVersionDownloadErrorKind.corrupt:
        return 'bible.download_error_corrupt';
      case BibleVersionDownloadErrorKind.storage:
        return 'bible.download_error_storage';
    }
  }
}
