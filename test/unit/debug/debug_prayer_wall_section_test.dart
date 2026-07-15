@Tags(['unit'])
library;

import 'package:devocional_nuevo/debug/sections/debug_prayer_wall_section.dart';
import 'package:devocional_nuevo/models/prayer_wall_entry.dart';
import 'package:devocional_nuevo/pages/prayer_wall_page.dart';
import 'package:devocional_nuevo/repositories/i_prayer_wall_repository.dart';
import 'package:devocional_nuevo/services/auth_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

class _FakeAuthService implements IAuthService {
  @override
  String? get currentUserId => 'test-uid';
}

class _FakePrayerWallRepository implements IPrayerWallRepository {
  @override
  Future<List<PrayerWallEntry>> fetchApprovedPrayers({
    required String userLanguage,
    int limit = 20,
  }) async =>
      [];

  @override
  Stream<PrayerWallEntry?> watchMyPendingPrayer({required String uid}) =>
      const Stream.empty();

  @override
  Future<String> submitPrayer({
    required String originalText,
    required String language,
    required bool isAnonymous,
    required String authorHash,
  }) async =>
      'fake-id';

  @override
  Future<void> tapPrayHand({required String prayerId}) async {}

  @override
  Future<void> reportPrayer({required String prayerId}) async {}

  @override
  Future<void> deletePrayer({
    required String prayerId,
    required String uid,
  }) async {}
}

void main() {
  setUp(() async {
    await registerTestServices();
    final locator = ServiceLocator();
    if (locator.isRegistered<IPrayerWallRepository>()) {
      locator.unregister<IPrayerWallRepository>();
    }
    locator.registerLazySingleton<IPrayerWallRepository>(
      () => _FakePrayerWallRepository(),
    );
    if (locator.isRegistered<IAuthService>()) {
      locator.unregister<IAuthService>();
    }
    locator.registerLazySingleton<IAuthService>(() => _FakeAuthService());
  });

  testWidgets('tapping "Open Prayer Wall" navigates to PrayerWallPage', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DebugPrayerWallSection())),
    );

    expect(find.byType(DebugPrayerWallSection), findsOneWidget);
    expect(find.text('Open Prayer Wall'), findsOneWidget);

    await tester.tap(find.text('Open Prayer Wall'));
    await tester.pumpAndSettle();

    expect(find.byType(PrayerWallPage), findsOneWidget);
  });
}
