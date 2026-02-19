// test/helpers/widget_pump_helper.dart
//
// Helpers for pumping SupporterPage in widget tests.
//
// The page contains Lottie animations that must be intercepted via a mock
// [AssetBundle] to prevent hangs during [tester.pumpWidget].  See
// [_TestAssetBundle] for details.
//
// Usage:
//   final bloc = SupporterBloc(iapService: fakeIap, profileRepository: fakeRepo);
//   bloc.add(InitializeSupporter());
//   await Future.delayed(Duration(milliseconds: 50));
//   await pumpSupporterPage(tester, bloc);
//   expect(find.byType(Scaffold), findsOneWidget);

import 'dart:convert';

import 'package:devocional_nuevo/blocs/supporter/supporter_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_event.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/pages/supporter_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test-only [ThemeBloc] fake that immediately provides a loaded theme state.
class _FakeThemeBloc extends Fake implements ThemeBloc {
  @override
  Stream<ThemeState> get stream => const Stream.empty();

  @override
  ThemeState get state => ThemeLoaded.withThemeData(
      themeFamily: 'Deep Purple', brightness: Brightness.light);

  @override
  bool get isClosed => false;

  @override
  void add(ThemeEvent event) {}

  @override
  Future<void> close() async {}
}

/// Minimal valid Lottie JSON with a short non-repeating animation.
///
/// Key properties:
///   - `op: 2, fr: 30` → ~67ms duration so a repeating controller doesn't
///     spin infinitely (a zero-duration repeat would).
///   - Empty layers → minimal parsing overhead.
const _emptyLottieJson =
    '{"v":"5.5.7","fr":30,"ip":0,"op":2,"w":1,"h":1,"layers":[]}';

/// [AssetBundle] that intercepts `*.json` requests and returns
/// [_emptyLottieJson]. All other requests forward to [rootBundle].
class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.endsWith('.json')) {
      final bytes = utf8.encode(_emptyLottieJson);
      return ByteData.view(Uint8List.fromList(bytes).buffer);
    }
    return rootBundle.load(key);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key.endsWith('.json')) return _emptyLottieJson;
    return rootBundle.loadString(key, cache: cache);
  }
}

/// Pumps a [SupporterPage] wrapped in the providers it needs.
///
/// **Important:** the caller should pre-initialise [bloc] to
/// `SupporterLoaded` state *before* calling this helper so that
/// `initState` does NOT dispatch `InitializeSupporter` during the
/// pump (which would trigger async microtask chains that interact
/// badly with the test binding's fake-async zone).
///
/// ```dart
/// bloc.add(InitializeSupporter());
/// await Future.delayed(Duration(milliseconds: 50));
/// await pumpSupporterPage(tester, bloc);
/// ```
///
/// The helper also wraps the tree in a [DefaultAssetBundle] that
/// returns minimal Lottie JSON to prevent infinite animation tickers.
Future<void> pumpSupporterPage(
  WidgetTester tester,
  SupporterBloc bloc,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: MultiBlocProvider(
          providers: [
            BlocProvider<SupporterBloc>.value(value: bloc),
            BlocProvider<ThemeBloc>.value(value: _FakeThemeBloc()),
          ],
          child: const SupporterPage(),
        ),
      ),
    ),
  );
  await tester.pump();
}
