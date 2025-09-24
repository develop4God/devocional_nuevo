import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/backup_event.dart';
import 'package:devocional_nuevo/blocs/backup_state.dart';
import 'package:devocional_nuevo/pages/onboarding/onboarding_backup_configuration_page.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockBackupBloc extends MockBloc<BackupEvent, BackupState>
    implements BackupBloc {}

void main() {
  group('OnboardingBackupConfigurationPage Tests', () {
    late MockBackupBloc mockBackupBloc;

    setUpAll(() {
      registerFallbackValue(const LoadBackupSettings());
      registerFallbackValue(const BackupInitial());
    });

    setUp(() async {
      mockBackupBloc = MockBackupBloc();
      SharedPreferences.setMockInitialValues({});
      await LocalizationService.instance.initialize();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: BlocProvider<BackupBloc>(
          create: (context) => mockBackupBloc,
          child: OnboardingBackupConfigurationPage(
            onNext: () {},
            onBack: () {},
            onSkip: () {},
          ),
        ),
      );
    }

    testWidgets('should display backup configuration UI', (tester) async {
      when(() => mockBackupBloc.state).thenReturn(const BackupInitial());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Protect your spiritual progress'), findsOneWidget);
      expect(find.text('Connect Google Drive'), findsOneWidget);
      expect(find.text('Configure later'), findsOneWidget);
    });

    testWidgets('should show connecting state when pressed', (tester) async {
      when(() => mockBackupBloc.state).thenReturn(const BackupInitial());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Connect Google Drive'));
      await tester.pump();

      expect(find.text('Connecting...'), findsOneWidget);
      verify(() => mockBackupBloc.add(const SignInToGoogleDrive())).called(1);
    });

    testWidgets('should handle successful authentication', (tester) async {
      when(() => mockBackupBloc.state).thenReturn(const BackupInitial());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Simulate successful authentication
      when(() => mockBackupBloc.state).thenReturn(
        const BackupLoaded(
          autoBackupEnabled: false,
          backupFrequency: 'daily',
          wifiOnlyEnabled: false,
          compressionEnabled: false,
          backupOptions: {},
          estimatedSize: 0,
          storageInfo: {},
          isAuthenticated: true,
        ),
      );

      await tester.tap(find.text('Connect Google Drive'));
      await tester.pumpAndSettle();

      // The page should handle the successful authentication
    });

    testWidgets('should handle authentication cancellation', (tester) async {
      when(() => mockBackupBloc.state).thenReturn(const BackupInitial());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap to start connecting
      await tester.tap(find.text('Connect Google Drive'));
      await tester.pump();

      // Simulate user cancelling (BackupLoaded with isAuthenticated: false)
      when(() => mockBackupBloc.state).thenReturn(
        const BackupLoaded(
          autoBackupEnabled: false,
          backupFrequency: 'daily',
          wifiOnlyEnabled: false,
          compressionEnabled: false,
          backupOptions: {},
          estimatedSize: 0,
          storageInfo: {},
          isAuthenticated: false,
        ),
      );

      await tester.pumpAndSettle();

      // Should return to normal state
      expect(find.text('Connect Google Drive'), findsOneWidget);
    });

    testWidgets('should handle authentication error', (tester) async {
      when(() => mockBackupBloc.state).thenReturn(const BackupInitial());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Simulate authentication error
      when(() => mockBackupBloc.state).thenReturn(
        const BackupError('Authentication failed'),
      );

      await tester.tap(find.text('Connect Google Drive'));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.text('Authentication failed'), findsOneWidget);
    });

    testWidgets('should handle timeout correctly', (tester) async {
      when(() => mockBackupBloc.state).thenReturn(const BackupInitial());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Connect Google Drive'));
      await tester.pump();

      // Fast forward to trigger timeout
      await tester.pump(const Duration(seconds: 31));

      expect(find.text('Connection timeout. Please try again.'), findsOneWidget);
    });

    testWidgets('should show localized strings correctly', (tester) async {
      when(() => mockBackupBloc.state).thenReturn(const BackupInitial());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check that localized strings are displayed (not raw keys)
      expect(find.text('onboarding_backup_title'), findsNothing);
      expect(find.text('onboarding_backup_subtitle'), findsNothing);
      expect(find.text('onboarding_connect_google_drive'), findsNothing);
    });
  });
}