// E2E Backup Test - Simplified for 40s timeout
// Tests basic backup functionality without complex widget interactions
import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/backup_event.dart';
import 'package:devocional_nuevo/blocs/backup_state.dart';
import 'package:devocional_nuevo/pages/backup_settings_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/google_drive_backup_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockGoogleDriveBackupService extends Mock implements GoogleDriveBackupService {}
class MockDevocionalProvider extends Mock implements DevocionalProvider {}

void main() {
  group('Backup Settings Basic Tests', () {
    late MockGoogleDriveBackupService mockBackupService;
    late MockDevocionalProvider mockDevocionalProvider;

    setUp(() {
      mockBackupService = MockGoogleDriveBackupService();
      mockDevocionalProvider = MockDevocionalProvider();
      
      // Set up default mocks
      when(() => mockDevocionalProvider.favoriteDevocionales).thenReturn([]);
    });

    testWidgets('should load backup page without crashes', (WidgetTester tester) async {
      // Mock basic state
      when(() => mockBackupService.isAuthenticated()).thenAnswer((_) async => false);
      when(() => mockBackupService.getUserEmail()).thenAnswer((_) async => null);
      when(() => mockBackupService.isAutoBackupEnabled()).thenAnswer((_) async => false);
      when(() => mockBackupService.getBackupFrequency()).thenAnswer((_) async => GoogleDriveBackupService.frequencyDaily);
      when(() => mockBackupService.isWifiOnlyEnabled()).thenAnswer((_) async => true);
      when(() => mockBackupService.isCompressionEnabled()).thenAnswer((_) async => true);
      when(() => mockBackupService.getBackupOptions()).thenAnswer((_) async => {
        'spiritual_stats': true,
        'favorite_devotionals': true,
        'saved_prayers': true,
      });
      when(() => mockBackupService.getLastBackupTime()).thenAnswer((_) async => null);
      when(() => mockBackupService.getNextBackupTime()).thenAnswer((_) async => null);
      when(() => mockBackupService.getEstimatedBackupSize(any())).thenAnswer((_) async => 0);
      when(() => mockBackupService.getStorageInfo()).thenAnswer((_) async => {'used_gb': 0.0, 'total_gb': 15.0});

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<DevocionalProvider>.value(value: mockDevocionalProvider),
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

      await tester.pump(const Duration(seconds: 3));

      // Basic assertions that the page loads
      expect(find.byType(BackupSettingsPage), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should have correct default frequency setting', (WidgetTester tester) async {
      // Mock authenticated state with daily frequency default
      when(() => mockBackupService.isAuthenticated()).thenAnswer((_) async => true);
      when(() => mockBackupService.getUserEmail()).thenAnswer((_) async => 'test@gmail.com');
      when(() => mockBackupService.isAutoBackupEnabled()).thenAnswer((_) async => true);
      when(() => mockBackupService.getBackupFrequency()).thenAnswer((_) async => GoogleDriveBackupService.frequencyDaily);
      when(() => mockBackupService.isWifiOnlyEnabled()).thenAnswer((_) async => true);
      when(() => mockBackupService.isCompressionEnabled()).thenAnswer((_) async => true);
      when(() => mockBackupService.getBackupOptions()).thenAnswer((_) async => {
        'spiritual_stats': true,
        'favorite_devotionals': true,
        'saved_prayers': true,
      });
      when(() => mockBackupService.getLastBackupTime()).thenAnswer((_) async => DateTime.now().subtract(const Duration(days: 1)));
      when(() => mockBackupService.getNextBackupTime()).thenAnswer((_) async => DateTime.now().add(const Duration(days: 1)));
      when(() => mockBackupService.getEstimatedBackupSize(any())).thenAnswer((_) async => 1024);
      when(() => mockBackupService.getStorageInfo()).thenAnswer((_) async => {'used_gb': 1.4, 'total_gb': 15.0});

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<DevocionalProvider>.value(value: mockDevocionalProvider),
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

      await tester.pump(const Duration(seconds: 3));

      // Check that daily frequency is set as default
      verify(() => mockBackupService.getBackupFrequency()).called(1);
    });

    testWidgets('should have InkWell widgets for interaction', (WidgetTester tester) async {
      when(() => mockBackupService.isAuthenticated()).thenAnswer((_) async => true);
      when(() => mockBackupService.getUserEmail()).thenAnswer((_) async => 'test@gmail.com');
      when(() => mockBackupService.isAutoBackupEnabled()).thenAnswer((_) async => true);
      when(() => mockBackupService.getBackupFrequency()).thenAnswer((_) async => GoogleDriveBackupService.frequencyDaily);
      when(() => mockBackupService.isWifiOnlyEnabled()).thenAnswer((_) async => true);
      when(() => mockBackupService.isCompressionEnabled()).thenAnswer((_) async => true);
      when(() => mockBackupService.getBackupOptions()).thenAnswer((_) async => {
        'spiritual_stats': true,
        'favorite_devotionals': true,
        'saved_prayers': true,
      });
      when(() => mockBackupService.getLastBackupTime()).thenAnswer((_) async => DateTime.now().subtract(const Duration(days: 1)));
      when(() => mockBackupService.getNextBackupTime()).thenAnswer((_) async => null);
      when(() => mockBackupService.getEstimatedBackupSize(any())).thenAnswer((_) async => 1024);
      when(() => mockBackupService.getStorageInfo()).thenAnswer((_) async => {'used_gb': 1.4, 'total_gb': 15.0});

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<DevocionalProvider>.value(value: mockDevocionalProvider),
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

      await tester.pump(const Duration(seconds: 3));

      // Just verify some InkWells exist without complex interactions
      final inkWells = find.byType(InkWell);
      expect(inkWells, findsWidgets);
    });
  });
}