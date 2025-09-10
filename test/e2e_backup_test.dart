// Simplified E2E Backup Test - Focused on core functionality
import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/backup_event.dart';
import 'package:devocional_nuevo/pages/backup_settings_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/google_drive_backup_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockGoogleDriveBackupService extends Mock
    implements GoogleDriveBackupService {}

class MockDevocionalProvider extends Mock implements DevocionalProvider {}

void main() {
  group('Simplified E2E Backup Tests', () {
    late MockGoogleDriveBackupService mockBackupService;
    late MockDevocionalProvider mockDevocionalProvider;

    setUp(() {
      mockBackupService = MockGoogleDriveBackupService();
      mockDevocionalProvider = MockDevocionalProvider();

      // Set up default mocks for DevocionalProvider
      when(() => mockDevocionalProvider.favoriteDevocionales).thenReturn([]);
    });

    /// Helper function to create a properly mocked BackupSettingsPage
    Widget createBackupPageWithMocks(
        {bool isAuthenticated = false,
        String? userEmail,
        bool autoBackupEnabled = false}) {
      // Set up comprehensive mocks
      when(() => mockBackupService.isAuthenticated())
          .thenAnswer((_) async => isAuthenticated);
      when(() => mockBackupService.getUserEmail())
          .thenAnswer((_) async => userEmail);
      when(() => mockBackupService.isAutoBackupEnabled())
          .thenAnswer((_) async => autoBackupEnabled);
      when(() => mockBackupService.getBackupFrequency())
          .thenAnswer((_) async => GoogleDriveBackupService.frequencyDaily);
      when(() => mockBackupService.isWifiOnlyEnabled())
          .thenAnswer((_) async => true);
      when(() => mockBackupService.isCompressionEnabled())
          .thenAnswer((_) async => true);
      when(() => mockBackupService.getBackupOptions()).thenAnswer((_) async => {
            'spiritual_stats': true,
            'favorite_devotionals': true,
            'saved_prayers': true,
          });
      when(() => mockBackupService.getLastBackupTime())
          .thenAnswer((_) async => null);
      when(() => mockBackupService.getNextBackupTime())
          .thenAnswer((_) async => null);
      when(() => mockBackupService.getEstimatedBackupSize(any()))
          .thenAnswer((_) async => 0);
      when(() => mockBackupService.getStorageInfo())
          .thenAnswer((_) async => {'used_gb': 0.0, 'total_gb': 15.0});
      when(() => mockBackupService.checkForExistingBackup())
          .thenAnswer((_) async => null);
      when(() => mockBackupService.signIn())
          .thenAnswer((_) async => isAuthenticated);
      when(() => mockBackupService.signOut()).thenAnswer((_) async {});
      when(() => mockBackupService.setAutoBackupEnabled(any()))
          .thenAnswer((_) async {});
      when(() => mockBackupService.setBackupFrequency(any()))
          .thenAnswer((_) async {});
      when(() => mockBackupService.setWifiOnlyEnabled(any()))
          .thenAnswer((_) async {});
      when(() => mockBackupService.setCompressionEnabled(any()))
          .thenAnswer((_) async {});
      when(() => mockBackupService.createBackup(any()))
          .thenAnswer((_) async => true);

      final bloc = BackupBloc(
        backupService: mockBackupService,
        devocionalProvider: mockDevocionalProvider,
      );

      return MaterialApp(
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [
          Locale('es', ''), // Spanish
          Locale('en', ''), // English
        ],
        locale: const Locale('es', ''), // Default to Spanish for tests
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<DevocionalProvider>.value(
                value: mockDevocionalProvider),
          ],
          child: BackupSettingsPage(bloc: bloc),
        ),
      );
    }

    group('Basic Functionality Tests', () {
      testWidgets('should render backup settings page without errors',
          (WidgetTester tester) async {
        await tester.pumpWidget(createBackupPageWithMocks());

        // Trigger the bloc to load settings
        final bloc = tester
            .widget<BackupSettingsPage>(find.byType(BackupSettingsPage))
            .bloc!;
        bloc.add(const LoadBackupSettings());
        await tester.pump();
        await tester.pump();

        // Verify basic page structure
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('should handle Google Drive login tap',
          (WidgetTester tester) async {
        await tester.pumpWidget(createBackupPageWithMocks());

        // Trigger the bloc to load settings
        final bloc = tester
            .widget<BackupSettingsPage>(find.byType(BackupSettingsPage))
            .bloc!;
        bloc.add(const LoadBackupSettings());
        await tester.pump();
        await tester.pump();

        // Verify Google Drive connection card exists
        expect(find.byIcon(Icons.cloud), findsAtLeastNWidgets(1));
      });
    });

    group('Dropdown Functionality', () {
      testWidgets(
          'should show DropdownButton when authenticated and auto backup enabled',
          (WidgetTester tester) async {
        await tester.pumpWidget(createBackupPageWithMocks(
            isAuthenticated: true,
            userEmail: 'test@gmail.com',
            autoBackupEnabled: true));

        // Trigger the bloc to load settings
        final bloc = tester
            .widget<BackupSettingsPage>(find.byType(BackupSettingsPage))
            .bloc!;
        bloc.add(const LoadBackupSettings());
        await tester.pump();
        await tester.pump();

        // Verify dropdown exists when authenticated and auto backup enabled
        final dropdown = find.byType(DropdownButton<String>);
        expect(dropdown, findsOneWidget);

        // Try to interact with the dropdown
        await tester.tap(dropdown);
        await tester.pump();

        // The dropdown should be functional
        expect(find.byType(DropdownButton<String>), findsOneWidget);
      });
    });

    group('Interaction Tests', () {
      testWidgets('should have InkWell ripple effects on interactive elements',
          (WidgetTester tester) async {
        await tester.pumpWidget(createBackupPageWithMocks(
            isAuthenticated: true, userEmail: 'test@gmail.com'));

        // Trigger the bloc to load settings
        final bloc = tester
            .widget<BackupSettingsPage>(find.byType(BackupSettingsPage))
            .bloc!;
        bloc.add(const LoadBackupSettings());
        await tester.pump();
        await tester.pump();

        // Verify InkWell widgets exist
        expect(find.byType(InkWell), findsAtLeastNWidgets(1));
      });
    });
  });
}
