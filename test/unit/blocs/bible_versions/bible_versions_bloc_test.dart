@Tags(['unit', 'blocs'])
library;

import 'dart:async';

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:devocional_nuevo/blocs/bible_versions/bible_versions_bloc.dart';
import 'package:devocional_nuevo/blocs/bible_versions/bible_versions_event.dart';
import 'package:devocional_nuevo/blocs/bible_versions/bible_versions_state.dart';
import 'package:devocional_nuevo/repositories/bible_version_repository.dart';
import 'package:devocional_nuevo/repositories/i_bible_version_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-written fake implementing the full [IBibleVersionRepository]
/// contract, with controllable fetch/download behavior per test.
class FakeBibleVersionRepository implements IBibleVersionRepository {
  List<BibleVersion> versionsToReturn = [];
  Object? fetchError;

  /// Queue of actions to run for each dbFileName's downloadVersion call —
  /// lets a test script out progress callbacks then success/failure.
  final Map<String, Future<void> Function(void Function(double?)? onProgress)>
      downloadBehaviors = {};

  @override
  Future<List<BibleVersion>> fetchRemoteVersions(String languageCode) async {
    if (fetchError != null) throw fetchError!;
    return versionsToReturn;
  }

  @override
  Future<void> downloadVersion(
    BibleVersion version, {
    void Function(double? progress)? onProgress,
  }) async {
    final behavior = downloadBehaviors[version.dbFileName];
    if (behavior == null) {
      throw StateError('No behavior configured for ${version.dbFileName}');
    }
    await behavior(onProgress);
  }
}

BibleVersion _version(String dbFileName, {String name = 'Test Version'}) {
  return BibleVersion(
    name: name,
    language: 'Test',
    languageCode: 'xx',
    assetPath: '',
    dbFileName: dbFileName,
    isDownloaded: false,
    remoteUrl: 'https://example.com/$dbFileName.gz',
  );
}

void main() {
  group('BibleVersionsBloc', () {
    late FakeBibleVersionRepository repository;

    setUp(() {
      repository = FakeBibleVersionRepository();
    });

    blocTest<BibleVersionsBloc, BibleVersionsState>(
      'load success emits Loading then Loaded with fetched versions',
      build: () {
        repository.versionsToReturn = [_version('KJV_xx.SQLite3')];
        return BibleVersionsBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const LoadAvailableVersions(languageCode: 'xx')),
      expect: () => [
        isA<BibleVersionsLoading>(),
        isA<BibleVersionsLoaded>()
            .having((s) => s.remoteVersions, 'remoteVersions', hasLength(1))
            .having((s) => s.downloadStatuses, 'downloadStatuses', isEmpty),
      ],
    );

    blocTest<BibleVersionsBloc, BibleVersionsState>(
      'load failure emits Loading then Error',
      build: () {
        repository.fetchError = Exception('network down');
        return BibleVersionsBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const LoadAvailableVersions(languageCode: 'xx')),
      expect: () => [
        isA<BibleVersionsLoading>(),
        isA<BibleVersionsError>().having(
          (s) => s.messageKey,
          'messageKey',
          'bible.download_error_network',
        ),
      ],
    );

    blocTest<BibleVersionsBloc, BibleVersionsState>(
      'download progress sequence updates status then completes',
      build: () {
        final version = _version('KJV_xx.SQLite3');
        repository.versionsToReturn = [version];
        repository.downloadBehaviors['KJV_xx.SQLite3'] = (onProgress) async {
          onProgress?.call(0.5);
          onProgress?.call(1.0);
        };
        return BibleVersionsBloc(repository: repository);
      },
      act: (bloc) async {
        bloc.add(const LoadAvailableVersions(languageCode: 'xx'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(DownloadBibleVersion(_version('KJV_xx.SQLite3')));
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        final state = bloc.state as BibleVersionsLoaded;
        final status = state.downloadStatuses['KJV_xx.SQLite3'];
        expect(status, isNotNull);
        expect(status!.isComplete, isTrue);
        expect(status.progress, 1.0);
      },
    );

    blocTest<BibleVersionsBloc, BibleVersionsState>(
      'download failure leaves other entries untouched',
      build: () {
        final versionA = _version('A_xx.SQLite3');
        final versionB = _version('B_xx.SQLite3');
        repository.versionsToReturn = [versionA, versionB];
        repository.downloadBehaviors['A_xx.SQLite3'] = (onProgress) async {
          onProgress?.call(1.0);
        };
        repository.downloadBehaviors['B_xx.SQLite3'] = (onProgress) async {
          throw BibleVersionDownloadException(
            BibleVersionDownloadErrorKind.corrupt,
            'bad gzip',
          );
        };
        return BibleVersionsBloc(repository: repository);
      },
      act: (bloc) async {
        bloc.add(const LoadAvailableVersions(languageCode: 'xx'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(DownloadBibleVersion(_version('A_xx.SQLite3')));
        await Future<void>.delayed(Duration.zero);
        bloc.add(DownloadBibleVersion(_version('B_xx.SQLite3')));
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        final state = bloc.state as BibleVersionsLoaded;
        final statusA = state.downloadStatuses['A_xx.SQLite3'];
        final statusB = state.downloadStatuses['B_xx.SQLite3'];

        expect(statusA!.isComplete, isTrue);
        expect(statusA.errorMessageKey, isNull);

        expect(statusB!.errorMessageKey, 'bible.download_error_corrupt');
        expect(statusB.isComplete, isFalse);
      },
    );

    blocTest<BibleVersionsBloc, BibleVersionsState>(
      'concurrent downloads are tracked independently',
      build: () {
        final versionA = _version('A_xx.SQLite3');
        final versionB = _version('B_xx.SQLite3');
        repository.versionsToReturn = [versionA, versionB];

        final completerA = Completer<void>();
        final completerB = Completer<void>();

        repository.downloadBehaviors['A_xx.SQLite3'] = (onProgress) async {
          onProgress?.call(0.3);
          await completerA.future;
          onProgress?.call(1.0);
        };
        repository.downloadBehaviors['B_xx.SQLite3'] = (onProgress) async {
          onProgress?.call(0.7);
          await completerB.future;
          onProgress?.call(1.0);
        };

        // Complete both shortly after being started so the test settles.
        Future<void>.delayed(const Duration(milliseconds: 2), () {
          completerA.complete();
          completerB.complete();
        });

        return BibleVersionsBloc(repository: repository);
      },
      act: (bloc) async {
        bloc.add(const LoadAvailableVersions(languageCode: 'xx'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(DownloadBibleVersion(_version('A_xx.SQLite3')));
        bloc.add(DownloadBibleVersion(_version('B_xx.SQLite3')));
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        final state = bloc.state as BibleVersionsLoaded;
        final statusA = state.downloadStatuses['A_xx.SQLite3'];
        final statusB = state.downloadStatuses['B_xx.SQLite3'];

        expect(statusA!.isComplete, isTrue);
        expect(statusB!.isComplete, isTrue);
      },
    );
  });
}
