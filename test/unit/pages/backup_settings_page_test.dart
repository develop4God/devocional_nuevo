@Tags(['unit', 'pages', 'backup'])
library;

// test/unit/pages/backup_settings_page_test.dart
//
// Widget-mount and interaction coverage for BackupSettingsPage. The page
// takes an optional `bloc` constructor param specifically for tests, so it
// is pumped with a MockBackupBloc (bloc_test's MockBloc) — same pattern as
// test/unit/widgets/backup_configuration_sheet_test.dart. ThemeBloc is
// stubbed with the repo's established FakeThemeBloc pattern (see
// test/unit/pages/settings_page_test.dart) since the page unconditionally
// does context.watch<ThemeBloc>().

import 'package:bloc_test/bloc_test.dart';
import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/backup_event.dart';
import 'package:devocional_nuevo/blocs/backup_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_event.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/pages/backup_settings_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../helpers/test_helpers.dart';
import '../../helpers/widget_pump_helper.dart';

class MockBackupBloc extends MockBloc<BackupEvent, BackupState>
    implements BackupBloc {}

class MockDevocionalProvider extends Mock implements DevocionalProvider {}

class FakeThemeBloc extends Fake implements ThemeBloc {
  @override
  Stream<ThemeState> get stream => Stream.value(
        ThemeLoaded.withThemeData(
          themeFamily: 'Deep Purple',
          brightness: Brightness.light,
        ),
      );

  @override
  ThemeState get state => ThemeLoaded.withThemeData(
        themeFamily: 'Deep Purple',
        brightness: Brightness.light,
      );

  @override
  void add(ThemeEvent event) {}

  @override
  Future<void> close() async {}
}

void main() {
  late MockBackupBloc mockBackupBloc;
  late MockDevocionalProvider mockDevocionalProvider;

  setUpAll(() {
    registerFallbackValue(const LoadBackupSettings());
  });

  setUp(() async {
    await registerTestServices();
    mockBackupBloc = MockBackupBloc();
    mockDevocionalProvider = MockDevocionalProvider();
  });

  BackupLoaded loadedState({
    bool isAuthenticated = false,
    bool autoBackupEnabled = false,
    DateTime? lastBackupTime,
  }) {
    return BackupLoaded(
      autoBackupEnabled: autoBackupEnabled,
      backupFrequency: 'daily',
      wifiOnlyEnabled: false,
      compressionEnabled: false,
      backupOptions: const {},
      estimatedSize: 0,
      isAuthenticated: isAuthenticated,
      userEmail: isAuthenticated ? 'user@example.com' : null,
      lastBackupTime: lastBackupTime,
    );
  }

  Future<void> pumpPage(WidgetTester tester, BackupState state) async {
    when(() => mockBackupBloc.state).thenReturn(state);
    whenListen(mockBackupBloc, const Stream<BackupState>.empty());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          BlocProvider<ThemeBloc>.value(value: FakeThemeBloc()),
          ChangeNotifierProvider<DevocionalProvider>.value(
            value: mockDevocionalProvider,
          ),
        ],
        child: MaterialApp(
          home: DefaultAssetBundle(
            bundle: TestAssetBundle(),
            child: BackupSettingsPage(bloc: mockBackupBloc),
          ),
        ),
      ),
    );
    // Some states (BackupLoading spinner, BackupSigningIn/BackupRestoring
    // Lottie loops) animate indefinitely, so pumpAndSettle would time out.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('BackupSettingsPage smoke test', () {
    for (final entry in <String, BackupState>{
      'BackupInitial': const BackupInitial(),
      'BackupLoading': const BackupLoading(),
      'BackupLoaded (unauthenticated)': loadedState(),
      'BackupLoaded (authenticated, auto-backup on)':
          loadedState(isAuthenticated: true, autoBackupEnabled: true),
      'BackupSigningIn': const BackupSigningIn(),
      'BackupRestoring': const BackupRestoring(),
      'BackupError': const BackupError('boom'),
    }.entries) {
      testWidgets('renders without throwing for ${entry.key}', (tester) async {
        await pumpPage(tester, entry.value);

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('BackupSettingsPage interactions', () {
    testWidgets('tapping connect button dispatches SignInToGoogleDrive',
        (tester) async {
      await pumpPage(tester, loadedState());

      await tester.tap(find.text('backup.google_drive_connection'.tr()));
      await tester.pump();

      verify(() => mockBackupBloc.add(const SignInToGoogleDrive())).called(1);
    });

    testWidgets(
        'turning off auto-backup switch shows confirmation before signing out',
        (tester) async {
      await pumpPage(
        tester,
        loadedState(
          isAuthenticated: true,
          autoBackupEnabled: true,
          lastBackupTime: DateTime.now(),
        ),
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      verifyNever(() => mockBackupBloc.add(any()));
    });

    testWidgets(
        'confirming the logout dialog dispatches SignOutFromGoogleDrive',
        (tester) async {
      await pumpPage(
        tester,
        loadedState(
          isAuthenticated: true,
          autoBackupEnabled: true,
          lastBackupTime: DateTime.now(),
        ),
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      await tester.tap(find.text('backup.backup_confirm'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      verify(() => mockBackupBloc.add(const SignOutFromGoogleDrive()))
          .called(1);
    });

    testWidgets('cancelling the logout dialog does not sign out',
        (tester) async {
      await pumpPage(
        tester,
        loadedState(
          isAuthenticated: true,
          autoBackupEnabled: true,
          lastBackupTime: DateTime.now(),
        ),
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      await tester.tap(find.text('backup.backup_cancel'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      verifyNever(() => mockBackupBloc.add(any()));
    });
  });

  group('BackupSettingsPage state-driven UI', () {
    testWidgets('BackupLoading shows a progress indicator', (tester) async {
      await pumpPage(tester, const BackupLoading());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('BackupError shows the retry button and error message',
        (tester) async {
      await pumpPage(tester, const BackupError('network down'));

      expect(find.text('backup.error_loading'.tr()), findsOneWidget);
      expect(find.text('backup.retry'.tr()), findsOneWidget);
    });

    testWidgets('tapping retry on BackupError dispatches LoadBackupSettings',
        (tester) async {
      await pumpPage(tester, const BackupError('network down'));

      await tester.tap(find.text('backup.retry'.tr()));
      await tester.pump();

      verify(() => mockBackupBloc.add(const LoadBackupSettings())).called(1);
    });
  });
}
