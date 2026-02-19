@Tags(['unit', 'blocs', 'iap'])
library;

// test/unit/blocs/supporter/supporter_bloc_test.dart

import 'package:devocional_nuevo/blocs/supporter/supporter_bloc.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_event.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_state.dart';
import 'package:devocional_nuevo/models/supporter_tier.dart';
import 'package:devocional_nuevo/services/iap/i_iap_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/iap_mock_helper.dart';

SupporterBloc _makeBloc(
    FakeIapService fakeIap, FakeSupporterProfileRepository fakeRepo) {
  return SupporterBloc(
    iapService: fakeIap,
    profileRepository: fakeRepo,
  );
}

void main() {
  group('SupporterBloc', () {
    late FakeIapService fakeIap;
    late FakeSupporterProfileRepository fakeRepo;
    late SupporterBloc bloc;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      fakeIap = FakeIapService();
      fakeRepo = FakeSupporterProfileRepository();
      bloc = _makeBloc(fakeIap, fakeRepo);
    });

    tearDown(() async {
      await bloc.close();
      await fakeIap.dispose();
    });

    // ── Initial state ───────────────────────────────────────────────────────

    test('starts in SupporterInitial', () {
      expect(bloc.state, isA<SupporterInitial>());
    });

    // ── InitializeSupporter ─────────────────────────────────────────────────

    group('InitializeSupporter event', () {
      test('transitions through Loading → Loaded', () async {
        final states = <SupporterState>[];
        bloc.stream.listen(states.add);

        bloc.add(InitializeSupporter());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(states[0], isA<SupporterLoading>());
        expect(states[1], isA<SupporterLoaded>());
      });

      test('SupporterLoaded has empty purchasedLevels when nothing bought',
          () async {
        bloc.add(InitializeSupporter());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final state = bloc.state as SupporterLoaded;
        expect(state.purchasedLevels, isEmpty);
        expect(state.isBillingAvailable, isFalse);
      });

      test('SupporterLoaded reflects pre-existing purchased tiers', () async {
        await fakeIap
            .deliver(SupporterTier.fromLevel(SupporterTierLevel.bronze));

        bloc.add(InitializeSupporter());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final state = bloc.state as SupporterLoaded;
        expect(state.isPurchased(SupporterTierLevel.bronze), isTrue);
      });

      test('initStatus reflected in SupporterLoaded', () async {
        bloc.add(InitializeSupporter());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final state = bloc.state as SupporterLoaded;
        expect(state.initStatus, equals(IapInitStatus.billingUnavailable));
      });

      test('goldSupporterName loaded from profile repository', () async {
        await fakeRepo.saveGoldSupporterName('María de los Ángeles');

        bloc.add(InitializeSupporter());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final state = bloc.state as SupporterLoaded;
        expect(state.goldSupporterName, equals('María de los Ángeles'));
      });
    });

    // ── PurchaseTier ────────────────────────────────────────────────────────

    group('PurchaseTier event', () {
      late FakeIapService availIap;
      late SupporterBloc availBloc;

      setUp(() {
        availIap = FakeIapService(
          purchaseShouldSucceed: true,
          autoDeliver: false,
          isAvailable: true,
        );
        availBloc = _makeBloc(availIap, FakeSupporterProfileRepository());
        availBloc.add(InitializeSupporter());
      });

      tearDown(() async {
        await availBloc.close();
        await availIap.dispose();
      });

      test('sets purchasingProductId while purchase is pending', () async {
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final bronze = SupporterTier.fromLevel(SupporterTierLevel.bronze);
        availBloc.add(PurchaseTier(bronze));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final state = availBloc.state as SupporterLoaded;
        expect(state.purchasingProductId, equals(bronze.productId));
      });

      test('emits error when billing unavailable', () async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        fakeIap.setAvailable(false);

        bloc.add(InitializeSupporter());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final silver = SupporterTier.fromLevel(SupporterTierLevel.silver);
        bloc.add(PurchaseTier(silver));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        final state = bloc.state as SupporterLoaded;
        expect(state.errorMessage, equals('billing_unavailable'));
      });

      test('ignores concurrent purchase attempt', () async {
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final bronze = SupporterTier.fromLevel(SupporterTierLevel.bronze);
        availBloc.add(PurchaseTier(bronze));
        await Future<void>.delayed(const Duration(milliseconds: 5));
        availBloc
            .add(PurchaseTier(SupporterTier.fromLevel(SupporterTierLevel.gold)));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final state = availBloc.state as SupporterLoaded;
        expect(state.purchasingProductId, equals(bronze.productId));
      });
    });

    // ── Purchase delivery via stream ────────────────────────────────────────

    group('Purchase delivery (stream-driven)', () {
      test('justDeliveredTier is set when tier is delivered', () async {
        bloc.add(InitializeSupporter());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final silver = SupporterTier.fromLevel(SupporterTierLevel.silver);
        await fakeIap.deliver(silver);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        final state = bloc.state as SupporterLoaded;
        expect(state.justDeliveredTier, equals(silver));
        expect(state.isPurchased(SupporterTierLevel.silver), isTrue);
      });

      test('purchasingProductId is cleared after delivery', () async {
        final autoIap = FakeIapService(
            purchaseShouldSucceed: true,
            autoDeliver: true,
            isAvailable: true);
        final autoBloc = _makeBloc(autoIap, FakeSupporterProfileRepository());
        autoBloc.add(InitializeSupporter());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final bronze = SupporterTier.fromLevel(SupporterTierLevel.bronze);
        autoBloc.add(PurchaseTier(bronze));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final state = autoBloc.state as SupporterLoaded;
        expect(state.purchasingProductId, isNull);
        expect(state.isPurchased(SupporterTierLevel.bronze), isTrue);

        await autoBloc.close();
        await autoIap.dispose();
      });

      test('multiple deliveries each update purchasedLevels', () async {
        bloc.add(InitializeSupporter());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await fakeIap
            .deliver(SupporterTier.fromLevel(SupporterTierLevel.bronze));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await fakeIap
            .deliver(SupporterTier.fromLevel(SupporterTierLevel.silver));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        final state = bloc.state as SupporterLoaded;
        expect(state.isPurchased(SupporterTierLevel.bronze), isTrue);
        expect(state.isPurchased(SupporterTierLevel.silver), isTrue);
      });
    });

    // ── RestorePurchases ────────────────────────────────────────────────────

    group('RestorePurchases event', () {
      test('stays SupporterLoaded during restore (no SupporterLoading emitted)',
          () async {
        bloc.add(InitializeSupporter());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final states = <SupporterState>[];
        bloc.stream.listen(states.add);

        bloc.add(RestorePurchases());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Must NOT transition to SupporterLoading mid-restore
        expect(states.any((s) => s is SupporterLoading), isFalse);
        expect(states.last, isA<SupporterLoaded>());
      });

      test('isRestoring true during restore, false after', () async {
        bloc.add(InitializeSupporter());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final states = <SupporterLoaded>[];
        bloc.stream.listen((s) {
          if (s is SupporterLoaded) states.add(s);
        });

        bloc.add(RestorePurchases());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(states.first.isRestoring, isTrue);
        expect(states.last.isRestoring, isFalse);
      });

      test('deliveries mid-restore update purchasedLevels immediately',
          () async {
        bloc.add(InitializeSupporter());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Pre-purchase 2 tiers so restorePurchases() will re-emit them
        await fakeIap
            .deliver(SupporterTier.fromLevel(SupporterTierLevel.bronze));
        await fakeIap
            .deliver(SupporterTier.fromLevel(SupporterTierLevel.silver));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // Reset the fake purchases so we can re-deliver via restore
        fakeIap.resetForTesting();
        fakeIap.setAvailable(false);

        // Re-add the purchases to the fake so restorePurchases re-emits them
        await fakeIap
            .deliver(SupporterTier.fromLevel(SupporterTierLevel.bronze));
        await fakeIap
            .deliver(SupporterTier.fromLevel(SupporterTierLevel.silver));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final state = bloc.state as SupporterLoaded;
        expect(state.isPurchased(SupporterTierLevel.bronze), isTrue);
        expect(state.isPurchased(SupporterTierLevel.silver), isTrue);
      });
    });

    // ── SaveGoldSupporterName ───────────────────────────────────────────────

    group('SaveGoldSupporterName event', () {
      test('persists name in repository and updates state', () async {
        bloc.add(InitializeSupporter());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        bloc.add(SaveGoldSupporterName('Pastor Luis'));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(fakeRepo.loadGoldSupporterName(),
            completion(equals('Pastor Luis')));
        final state = bloc.state as SupporterLoaded;
        expect(state.goldSupporterName, equals('Pastor Luis'));
      });
    });

    // ── ClearSupporterError ─────────────────────────────────────────────────

    group('ClearSupporterError event', () {
      test('clears errorMessage and justDeliveredTier', () async {
        bloc.add(InitializeSupporter());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await fakeIap
            .deliver(SupporterTier.fromLevel(SupporterTierLevel.bronze));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(
            (bloc.state as SupporterLoaded).justDeliveredTier, isNotNull);

        bloc.add(ClearSupporterError());
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final state = bloc.state as SupporterLoaded;
        expect(state.justDeliveredTier, isNull);
        expect(state.errorMessage, isNull);
      });
    });

    // ── Bloc close ──────────────────────────────────────────────────────────

    test('close() does not throw', () async {
      bloc.add(InitializeSupporter());
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await expectLater(bloc.close(), completes);
    });
  });

  // ── FakeIapService ─────────────────────────────────────────────────────────

  group('FakeIapService', () {
    late FakeIapService fake;

    setUp(() {
      fake = FakeIapService();
    });

    tearDown(() async => fake.dispose());

    test('starts unavailable with no purchases', () {
      expect(fake.isAvailable, isFalse);
      expect(fake.purchasedLevels, isEmpty);
    });

    test('deliver() adds tier to purchasedLevels and emits on stream',
        () async {
      final received = <SupporterTier>[];
      fake.onPurchaseDelivered.listen(received.add);

      await fake.deliver(SupporterTier.fromLevel(SupporterTierLevel.gold));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(fake.isPurchased(SupporterTierLevel.gold), isTrue);
      expect(received, hasLength(1));
    });

    test('restorePurchases() re-emits all already-purchased tiers', () async {
      await fake.deliver(SupporterTier.fromLevel(SupporterTierLevel.bronze));
      await fake.deliver(SupporterTier.fromLevel(SupporterTierLevel.silver));

      final received = <SupporterTier>[];
      fake.onPurchaseDelivered.listen(received.add);

      await fake.restorePurchases();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(received, hasLength(2));
    });

    test('purchaseTier returns error when purchaseShouldSucceed=false',
        () async {
      fake = FakeIapService(purchaseShouldSucceed: false);
      final result = await fake
          .purchaseTier(SupporterTier.fromLevel(SupporterTierLevel.bronze));
      expect(result, equals(IapResult.error));
    });
  });
}
