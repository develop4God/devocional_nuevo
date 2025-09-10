// E2E Backup Test
// Tests the End-to-End backup functionality as requested in the comment
import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/backup_event.dart';
import 'package:devocional_nuevo/pages/backup_settings_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/google_drive_backup_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockGoogleDriveBackupService extends Mock
    implements GoogleDriveBackupService {}

class MockDevocionalProvider extends Mock implements DevocionalProvider {}

void main() {
  group('End-to-End Backup Tests', () {
    late MockGoogleDriveBackupService mockBackupService;
    late MockDevocionalProvider mockDevocionalProvider;

    setUp(() {
      mockBackupService = MockGoogleDriveBackupService();
      mockDevocionalProvider = MockDevocionalProvider();

      // Set up default mocks for DevocionalProvider
      when(() => mockDevocionalProvider.favoriteDevocionales).thenReturn([]);
    });

    /// Helper function to create a properly mocked BackupSettingsPage
    Widget createBackupPageWithMocks() {
      // Set up comprehensive mocks
      when(() => mockBackupService.isAuthenticated())
          .thenAnswer((_) async => false);
      when(() => mockBackupService.getUserEmail())
          .thenAnswer((_) async => null);
      when(() => mockBackupService.isAutoBackupEnabled())
          .thenAnswer((_) async => false);
      when(() => mockBackupService.getBackupFrequency())
          .thenAnswer((_) async => GoogleDriveBackupService.frequencyDaily);
      when(() => mockBackupService.isWifiOnlyEnabled())
          .thenAnswer((_) async => true);
      when(() => mockBackupService.isCompressionEnabled())
          .thenAnswer((_) async => true);
      when(() => mockBackupService.getBackupOptions())
          .thenAnswer((_) async => {
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

      final bloc = BackupBloc(
        backupService: mockBackupService,
        devocionalProvider: mockDevocionalProvider,
      );

      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<DevocionalProvider>.value(
                value: mockDevocionalProvider),
          ],
          child: BackupSettingsPage(bloc: bloc),
        ),
      );
    }

    group('Scenario 1: First-time use (no existing backup)', () {
      testWidgets('should display correct UI elements for first-time use',
          (WidgetTester tester) async {
        // Mock first-time use scenario
        when(() => mockBackupService.isAuthenticated())
            .thenAnswer((_) async => false);
        when(() => mockBackupService.getUserEmail())
            .thenAnswer((_) async => null);
        when(() => mockBackupService.isAutoBackupEnabled())
            .thenAnswer((_) async => false);
        when(() => mockBackupService.getBackupFrequency())
            .thenAnswer((_) async => GoogleDriveBackupService.frequencyManual);
        when(() => mockBackupService.isWifiOnlyEnabled())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.isCompressionEnabled())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.getBackupOptions())
            .thenAnswer((_) async => {
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

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<DevocionalProvider>.value(
                    value: mockDevocionalProvider),
              ],
              child: BlocProvider(
                create: (context) => BackupBloc(
                  backupService: mockBackupService,
                  devocionalProvider: mockDevocionalProvider,
                )..add(const LoadBackupSettings()),
                child: const BackupSettingsPage(),
              ),
            ),
          ),
        );

        // Wait for the state to load
        await tester.pump(const Duration(seconds: 2));

        // Verify App bar is visible and has correct title
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Copia de Seguridad'), findsWidgets);

        // Verify description text is shown as plain text (no icon container)
        expect(find.textContaining('Protege tu progreso espiritual'),
            findsOneWidget);

        // Verify Google Drive connection section shows icon and not connected state
        expect(find.byIcon(Icons.cloud), findsOneWidget);
        expect(find.textContaining('No conectado'), findsOneWidget);
        expect(find.textContaining('Toca para conectar'), findsOneWidget);

        // Verify backup options show zero values (no existing data)
        expect(find.textContaining('0 elementos'), findsWidgets);

        // Verify "Última copia de seguridad: no hay" is displayed
        expect(find.textContaining('no hay'), findsOneWidget);

        // Verify security section is visible
        expect(find.byIcon(Icons.security), findsOneWidget);
        expect(find.textContaining('Seguridad'), findsOneWidget);
      });

      testWidgets('should handle Google Drive login tap',
          (WidgetTester tester) async {
        // Mock successful login
        when(() => mockBackupService.signIn()).thenAnswer((_) async => true);

        await tester.pumpWidget(createBackupPageWithMocks());

        // Add the LoadBackupSettings event and wait for the page to load
        final bloc = tester.widget<BackupSettingsPage>(find.byType(BackupSettingsPage)).bloc!;
        bloc.add(const LoadBackupSettings());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Find and tap the Google Drive connection card (first InkWell)
        final connectionCard = find.byType(InkWell).first;
        expect(connectionCard, findsOneWidget);
        
        await tester.tap(connectionCard);
        await tester.pump();

        // Verify that SignInToGoogleDrive event was triggered
        verify(() => mockBackupService.signIn()).called(1);
      });

      testWidgets('should create manual backup successfully',
          (WidgetTester tester) async {
        // Mock authenticated state with successful backup creation
        when(() => mockBackupService.isAuthenticated())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.getUserEmail())
            .thenAnswer((_) async => 'test@gmail.com');
        when(() => mockBackupService.isAutoBackupEnabled())
            .thenAnswer((_) async => false);
        when(() => mockBackupService.getBackupFrequency())
            .thenAnswer((_) async => GoogleDriveBackupService.frequencyManual);
        when(() => mockBackupService.isWifiOnlyEnabled())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.isCompressionEnabled())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.getBackupOptions())
            .thenAnswer((_) async => {
                  'spiritual_stats': true,
                  'favorite_devotionals': true,
                  'saved_prayers': true,
                });
        when(() => mockBackupService.getLastBackupTime())
            .thenAnswer((_) async => null);
        when(() => mockBackupService.getNextBackupTime())
            .thenAnswer((_) async => null);
        when(() => mockBackupService.getEstimatedBackupSize(any()))
            .thenAnswer((_) async => 1024);
        when(() => mockBackupService.getStorageInfo())
            .thenAnswer((_) async => {'used_gb': 0.1, 'total_gb': 15.0});

        // Mock successful backup creation
        when(() => mockBackupService.createBackup(any()))
            .thenAnswer((_) async => true);

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<DevocionalProvider>.value(
                    value: mockDevocionalProvider),
              ],
              child: BlocProvider(
                create: (context) => BackupBloc(
                  backupService: mockBackupService,
                  devocionalProvider: mockDevocionalProvider,
                )..add(const LoadBackupSettings()),
                child: const BackupSettingsPage(),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(seconds: 2));

        // Find and tap the "Create backup" button
        final createBackupButton = find.text('Crear copia de seguridad');
        expect(createBackupButton, findsOneWidget);

        await tester.tap(createBackupButton);
        await tester.pump();

        // Verify backup creation was called
        verify(() => mockBackupService.createBackup(any())).called(1);
      });
    });

    group('Scenario 2: Existing backup', () {
      testWidgets('should display existing backup information correctly',
          (WidgetTester tester) async {
        final lastBackupTime = DateTime.now().subtract(const Duration(days: 1));

        // Mock existing backup scenario
        when(() => mockBackupService.isAuthenticated())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.getUserEmail())
            .thenAnswer((_) async => 'user@gmail.com');
        when(() => mockBackupService.isAutoBackupEnabled())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.getBackupFrequency())
            .thenAnswer((_) async => GoogleDriveBackupService.frequencyDaily);
        when(() => mockBackupService.isWifiOnlyEnabled())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.isCompressionEnabled())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.getBackupOptions())
            .thenAnswer((_) async => {
                  'spiritual_stats': true,
                  'favorite_devotionals': true,
                  'saved_prayers': true,
                });
        when(() => mockBackupService.getLastBackupTime())
            .thenAnswer((_) async => lastBackupTime);
        when(() => mockBackupService.getNextBackupTime()).thenAnswer(
            (_) async => DateTime.now().add(const Duration(hours: 12)));
        when(() => mockBackupService.getEstimatedBackupSize(any()))
            .thenAnswer((_) async => 5120);
        when(() => mockBackupService.getStorageInfo())
            .thenAnswer((_) async => {'used_gb': 1.2, 'total_gb': 15.0});

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<DevocionalProvider>.value(
                    value: mockDevocionalProvider),
              ],
              child: BlocProvider(
                create: (context) => BackupBloc(
                  backupService: mockBackupService,
                  devocionalProvider: mockDevocionalProvider,
                )..add(const LoadBackupSettings()),
                child: const BackupSettingsPage(),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(seconds: 2));

        // Verify last backup time is displayed
        expect(find.textContaining('Ayer'), findsOneWidget);

        // Verify next backup time is shown for automatic backups
        expect(find.textContaining('Próxima copia'), findsOneWidget);

        // Verify backup size is displayed
        expect(find.textContaining('5.0 KB'), findsOneWidget);

        // Verify authenticated state shows check mark
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });
    });

    group('Scenario 3: Scheduled backup frequencies', () {
      testWidgets('should handle Daily backup frequency correctly',
          (WidgetTester tester) async {
        // Mock authenticated state with daily backup
        when(() => mockBackupService.isAuthenticated())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.getUserEmail())
            .thenAnswer((_) async => 'test@gmail.com');
        when(() => mockBackupService.isAutoBackupEnabled())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.getBackupFrequency())
            .thenAnswer((_) async => GoogleDriveBackupService.frequencyDaily);
        when(() => mockBackupService.isWifiOnlyEnabled())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.isCompressionEnabled())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.getBackupOptions())
            .thenAnswer((_) async => {
                  'spiritual_stats': true,
                  'favorite_devotionals': true,
                  'saved_prayers': true,
                });
        when(() => mockBackupService.getLastBackupTime())
            .thenAnswer((_) async => null);
        when(() => mockBackupService.getNextBackupTime()).thenAnswer(
            (_) async => DateTime.now().add(const Duration(hours: 12)));
        when(() => mockBackupService.getEstimatedBackupSize(any()))
            .thenAnswer((_) async => 1024);
        when(() => mockBackupService.getStorageInfo())
            .thenAnswer((_) async => {'used_gb': 0.1, 'total_gb': 15.0});

        // Mock frequency change
        when(() => mockBackupService.setBackupFrequency(any()))
            .thenAnswer((_) async {});

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<DevocionalProvider>.value(
                    value: mockDevocionalProvider),
              ],
              child: BlocProvider(
                create: (context) => BackupBloc(
                  backupService: mockBackupService,
                  devocionalProvider: mockDevocionalProvider,
                )..add(const LoadBackupSettings()),
                child: const BackupSettingsPage(),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(seconds: 2));

        // Verify Daily option is selected in dropdown
        expect(find.text('Diariamente (2:00 AM)'), findsOneWidget);

        // Verify auto backup is enabled
        expect(find.byType(Switch), findsWidgets);

        // Test frequency change to Manual only
        final dropdown = find.byType(DropdownButton<String>);
        await tester.tap(dropdown);
        await tester.pump(const Duration(milliseconds: 500));

        await tester
            .tap(find.text('Solo cuando seleccione \'Crear copia\'').last);
        await tester.pump(const Duration(milliseconds: 500));

        verify(() => mockBackupService.setBackupFrequency(
            GoogleDriveBackupService.frequencyManual)).called(1);
      });

      testWidgets('should handle Deactivate option correctly',
          (WidgetTester tester) async {
        // Mock authenticated state
        when(() => mockBackupService.isAuthenticated())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.getUserEmail())
            .thenAnswer((_) async => 'test@gmail.com');
        when(() => mockBackupService.isAutoBackupEnabled())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.getBackupFrequency())
            .thenAnswer((_) async => GoogleDriveBackupService.frequencyDaily);
        when(() => mockBackupService.isWifiOnlyEnabled())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.isCompressionEnabled())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.getBackupOptions())
            .thenAnswer((_) async => {
                  'spiritual_stats': true,
                  'favorite_devotionals': true,
                  'saved_prayers': true,
                });
        when(() => mockBackupService.getLastBackupTime()).thenAnswer(
            (_) async => DateTime.now().subtract(const Duration(days: 1)));
        when(() => mockBackupService.getNextBackupTime())
            .thenAnswer((_) async => null);
        when(() => mockBackupService.getEstimatedBackupSize(any()))
            .thenAnswer((_) async => 1024);
        when(() => mockBackupService.getStorageInfo())
            .thenAnswer((_) async => {'used_gb': 0.1, 'total_gb': 15.0});

        // Mock deactivation
        when(() => mockBackupService.setBackupFrequency(any()))
            .thenAnswer((_) async {});
        when(() => mockBackupService.signOut()).thenAnswer((_) async {});

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<DevocionalProvider>.value(
                    value: mockDevocionalProvider),
              ],
              child: BlocProvider(
                create: (context) => BackupBloc(
                  backupService: mockBackupService,
                  devocionalProvider: mockDevocionalProvider,
                )..add(const LoadBackupSettings()),
                child: const BackupSettingsPage(),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(seconds: 2));

        // Test frequency change to Deactivate
        final dropdown = find.byType(DropdownButton<String>);
        await tester.tap(dropdown);
        await tester.pump(const Duration(milliseconds: 500));

        await tester.tap(find.text('Desactivar').last);
        await tester.pump(const Duration(milliseconds: 500));

        // Verify deactivation calls are made
        verify(() => mockBackupService.setBackupFrequency(
            GoogleDriveBackupService.frequencyDeactivated)).called(1);
      });
    });

    group('Interaction Tests', () {
      testWidgets('should have InkWell ripple effects on interactive elements',
          (WidgetTester tester) async {
        // Override authentication to true for this test
        when(() => mockBackupService.isAuthenticated())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.getUserEmail())
            .thenAnswer((_) async => 'test@gmail.com');

        await tester.pumpWidget(createBackupPageWithMocks());

        // Add the LoadBackupSettings event and wait for the page to load
        final bloc = tester.widget<BackupSettingsPage>(find.byType(BackupSettingsPage)).bloc!;
        bloc.add(const LoadBackupSettings());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify multiple InkWell widgets exist for interactive elements
        expect(find.byType(InkWell), findsWidgets);

        // Verify specific interactive elements have InkWell
        // Connection card, switch tiles, backup option tiles should all be tappable
        final inkWells = find.byType(InkWell);
        expect(inkWells, findsWidgets);
      });
    });
  });
}
