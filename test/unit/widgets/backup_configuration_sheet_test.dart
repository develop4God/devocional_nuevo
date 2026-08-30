@Tags(['unit', 'widgets', 'backup'])
library;

// test/unit/widgets/backup_configuration_sheet_test.dart
//
// High-value behavior tests for BackupConfigurationSheet.
// Uses a MockBackupBloc (bloc_test's MockBloc) stubbed with a BackupLoaded
// state — same pattern as
// test/unit/onboarding/onboarding_backup_safeguard_widget_test.dart.

import 'package:bloc_test/bloc_test.dart';
import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/backup_event.dart';
import 'package:devocional_nuevo/blocs/backup_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/widgets/backup_configuration_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class MockBackupBloc extends MockBloc<BackupEvent, BackupState>
    implements BackupBloc {}

void main() {
  late MockBackupBloc mockBackupBloc;

  setUpAll(() {
    registerFallbackValue(const LoadBackupSettings());
  });

  setUp(() async {
    await registerTestServices();
    mockBackupBloc = MockBackupBloc();
  });

  BackupLoaded loadedState({
    bool wifiOnlyEnabled = false,
    bool compressionEnabled = false,
    bool isAuthenticated = true,
  }) {
    return BackupLoaded(
      autoBackupEnabled: true,
      backupFrequency: 'daily',
      wifiOnlyEnabled: wifiOnlyEnabled,
      compressionEnabled: compressionEnabled,
      backupOptions: const {},
      estimatedSize: 0,
      isAuthenticated: isAuthenticated,
      userEmail: isAuthenticated ? 'user@example.com' : null,
    );
  }

  Future<void> pumpSheet(
    WidgetTester tester, {
    required BackupLoaded state,
  }) async {
    when(() => mockBackupBloc.state).thenReturn(state);
    whenListen(mockBackupBloc, const Stream<BackupState>.empty());

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<BackupBloc>.value(
          value: mockBackupBloc,
          child: Scaffold(
            body: BackupConfigurationSheet(
              state: state,
              backupBloc: mockBackupBloc,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders wifi-only and compression toggles reflecting state',
      (tester) async {
    await pumpSheet(
      tester,
      state: loadedState(wifiOnlyEnabled: true, compressionEnabled: false),
    );

    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches, hasLength(2));
    expect(switches[0].value, isTrue); // wifi only
    expect(switches[1].value, isFalse); // compression
  });

  testWidgets('tapping the wifi-only toggle adds ToggleWifiOnly event',
      (tester) async {
    await pumpSheet(tester, state: loadedState(wifiOnlyEnabled: false));

    await tester.tap(find.byType(Switch).first);
    await tester.pump();

    verify(() => mockBackupBloc.add(const ToggleWifiOnly(true))).called(1);
  });

  testWidgets('tapping the compression toggle adds ToggleCompression event',
      (tester) async {
    await pumpSheet(tester, state: loadedState(compressionEnabled: false));

    await tester.tap(find.byType(Switch).last);
    await tester.pump();

    verify(() => mockBackupBloc.add(const ToggleCompression(true))).called(1);
  });

  testWidgets('close icon button pops the sheet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<BackupBloc>.value(
          value: mockBackupBloc,
          child: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  final state = loadedState();
                  when(() => mockBackupBloc.state).thenReturn(state);
                  whenListen(mockBackupBloc, const Stream<BackupState>.empty());
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => BackupConfigurationSheet(
                      state: state,
                      backupBloc: mockBackupBloc,
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(BackupConfigurationSheet), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(BackupConfigurationSheet), findsNothing);
  });

  testWidgets('logout button shows a confirmation dialog before signing out',
      (tester) async {
    await pumpSheet(tester, state: loadedState());

    await tester.tap(find.byKey(const Key('logout_button')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    verifyNever(() => mockBackupBloc.add(any()));
  });

  testWidgets(
      'confirming logout adds SignOutFromGoogleDrive and closes the dialog',
      (tester) async {
    await pumpSheet(tester, state: loadedState());

    await tester.tap(find.byKey(const Key('logout_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('backup.backup_confirm'.tr()));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    verify(() => mockBackupBloc.add(const SignOutFromGoogleDrive())).called(1);
  });

  testWidgets('cancelling the logout dialog does not sign out', (tester) async {
    await pumpSheet(tester, state: loadedState());

    await tester.tap(find.byKey(const Key('logout_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('backup.backup_cancel'.tr()));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    verifyNever(() => mockBackupBloc.add(any()));
  });
}
