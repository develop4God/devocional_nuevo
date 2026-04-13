@Tags(['unit', 'widgets'])
library;

// test/unit/widgets/drawer_offline_widget_test.dart
//
// Unit tests for the offline/download feature.
//
// ✅ Tests the REAL DevocionalProvider delegation contract:
//    - Provider.hasTargetYearsLocalData() delegates to repository with the
//      correct language and version arguments.
//    - The provider correctly reflects the repository's answer (true/false).
//
// A FakeDevocionalRepository (not a Mock) is used so that tests exercise the
// real provider code path rather than only verifying what the mock returns.

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/repositories/devocional_repository.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Fake repository — implements the real interface without mocking.
// Tests can flip _localDataResult to drive provider responses.
// ---------------------------------------------------------------------------
class _FakeDevocionalRepository implements DevocionalRepository {
  bool _localDataResult;

  /// Captures the arguments the provider passed on the most recent call.
  String? capturedLanguage;
  String? capturedVersion;

  int hasTargetYearsCallCount = 0;

  _FakeDevocionalRepository({bool localDataResult = false})
      : _localDataResult = localDataResult;

  void setLocalData(bool value) => _localDataResult = value;

  @override
  Future<bool> hasTargetYearsLocalData(String language, String version) async {
    hasTargetYearsCallCount++;
    capturedLanguage = language;
    capturedVersion = version;
    return _localDataResult;
  }

  // ── Minimal stubs for remaining interface members ──────────────────────

  @override
  int findFirstUnreadDevocionalIndex(
          List<Devocional> devocionales, List<String> readDevocionalIds) =>
      0;

  @override
  Future<List<Devocional>> fetchAll(
          int year, String language, String version) async =>
      [];

  @override
  List<Devocional> filterByVersion(
          List<Devocional> devocionales, String version) =>
      devocionales;

  @override
  Future<bool> hasLocalData(int year, String language, String version) async =>
      _localDataResult;

  @override
  Future<bool> downloadAndStoreDevocionales(
          int year, String language, String version) async =>
      true;

  @override
  Future<void> clearOldFiles() async {}

  @override
  bool get wasLastFetchOffline => false;

  @override
  Future<bool> downloadCurrentYearDevocionales(
          String language, String version) async =>
      true;

  @override
  Future<bool> hasCurrentYearLocalData(String language, String version) async =>
      _localDataResult;

  @override
  Future<List<int>> getAvailableYears() async => [2025, 2026];

  @override
  void resetCache() {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
DevocionalProvider _makeProvider(_FakeDevocionalRepository repo) =>
    DevocionalProvider(
      devocionalRepository: repo,
      enableAudio: false, // no audio setup needed in unit tests
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Minimal service locator setup — provider constructor needs SharedPreferences
    // only when it resolves the repository from the locator (we inject it directly,
    // so this is a safety net only).
    ServiceLocator().reset();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Offline Content Feature — DevocionalProvider delegation', () {
    test(
      'hasTargetYearsLocalData returns false when repository has no data',
      () async {
        final fakeRepo = _FakeDevocionalRepository(localDataResult: false);
        final provider = _makeProvider(fakeRepo);

        final result = await provider.hasTargetYearsLocalData();

        expect(result, isFalse,
            reason:
                'Provider must return false when repository reports no local data');
        expect(fakeRepo.hasTargetYearsCallCount, 1,
            reason: 'Provider must delegate to the repository exactly once');
      },
    );

    test(
      'hasTargetYearsLocalData returns true when repository has data',
      () async {
        final fakeRepo = _FakeDevocionalRepository(localDataResult: true);
        final provider = _makeProvider(fakeRepo);

        final result = await provider.hasTargetYearsLocalData();

        expect(result, isTrue,
            reason:
                'Provider must return true when repository reports local data present');
      },
    );

    test(
      'hasTargetYearsLocalData passes the default language (es) to the repository',
      () async {
        final fakeRepo = _FakeDevocionalRepository();
        final provider = _makeProvider(fakeRepo);

        await provider.hasTargetYearsLocalData();

        expect(
          fakeRepo.capturedLanguage,
          isNotNull,
          reason: 'Provider must forward a language argument to the repository',
        );
        // Default language without initialization is 'es'
        expect(fakeRepo.capturedLanguage, equals('es'));
      },
    );

    test(
      'hasTargetYearsLocalData passes the default version (RVR1960) to the repository',
      () async {
        final fakeRepo = _FakeDevocionalRepository();
        final provider = _makeProvider(fakeRepo);

        await provider.hasTargetYearsLocalData();

        expect(
          fakeRepo.capturedVersion,
          isNotNull,
          reason: 'Provider must forward a version argument to the repository',
        );
        expect(fakeRepo.capturedVersion, equals('RVR1960'));
      },
    );

    test(
      'hasTargetYearsLocalData transitions from false to true after data is available',
      () async {
        final fakeRepo = _FakeDevocionalRepository(localDataResult: false);
        final provider = _makeProvider(fakeRepo);

        // State 1: no local data
        expect(await provider.hasTargetYearsLocalData(), isFalse);

        // Simulate download completing
        fakeRepo.setLocalData(true);

        // State 2: local data present
        expect(await provider.hasTargetYearsLocalData(), isTrue,
            reason:
                'Provider must reflect repository state change after download');
      },
    );

    test(
      'hasTargetYearsLocalData delegates on every call (not cached inside provider)',
      () async {
        final fakeRepo = _FakeDevocionalRepository(localDataResult: false);
        final provider = _makeProvider(fakeRepo);

        await provider.hasTargetYearsLocalData();
        await provider.hasTargetYearsLocalData();

        expect(fakeRepo.hasTargetYearsCallCount, 2,
            reason: 'Provider must not cache the result — it should delegate '
                'to the repository on every call so UI always reflects '
                'current disk state');
      },
    );
  });
}
