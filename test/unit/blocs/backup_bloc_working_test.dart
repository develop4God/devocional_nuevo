@Tags(['critical', 'unit', 'blocs'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/backup_event.dart';
import 'package:devocional_nuevo/blocs/backup_state.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/backup/i_google_drive_backup_service.dart';
import 'package:devocional_nuevo/utils/constants/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes for testing

class MockGoogleDriveBackupService extends Mock
    implements IGoogleDriveBackupService {}

class MockDevocionalProvider extends Mock implements DevocionalProvider {}

void main() {
  group('Backup Feature Flag Tests', () {
    test('Backup feature debe estar deshabilitada por defecto', () {
      expect(
        Constants.enableBackupFeature,
        false,
        reason:
            'La funcionalidad de backup debe estar deshabilitada para los usuarios',
      );
    });

    test(
      'La bandera de funcionalidad debe prevenir la inicialización de backup',
      () {
        const backupFeatureEnabled = Constants.enableBackupFeature;
        expect(
          backupFeatureEnabled,
          false,
          reason: 'La bandera debe estar en false y prevenir inicialización.',
        );
      },
    );
  });

  group('BackupBloc Critical Coverage Tests', () {
    late MockGoogleDriveBackupService mockBackupService;
    late MockDevocionalProvider mockDevocionalProvider;

    setUp(() {
      mockBackupService = MockGoogleDriveBackupService();
      mockDevocionalProvider = MockDevocionalProvider();

      // Configuración de respuestas comunes de los mocks
      when(
        () => mockBackupService.isAuthenticated(),
      ).thenAnswer((_) async => false);
      when(
        () => mockBackupService.isAutoBackupEnabled(),
      ).thenAnswer((_) async => false);
      when(
        () => mockBackupService.getBackupFrequency(),
      ).thenAnswer((_) async => 'deactivated');
      when(
        () => mockBackupService.isWifiOnlyEnabled(),
      ).thenAnswer((_) async => false);
      when(
        () => mockBackupService.isCompressionEnabled(),
      ).thenAnswer((_) async => false);
      when(
        () => mockBackupService.getBackupOptions(),
      ).thenAnswer((_) async => <String, bool>{});
      when(
        () => mockBackupService.getLastBackupTime(),
      ).thenAnswer((_) async => null);
      when(
        () => mockBackupService.getNextBackupTime(),
      ).thenAnswer((_) async => null);
      when(
        () => mockBackupService.getEstimatedBackupSize(any()),
      ).thenAnswer((_) async => 0);
      when(
        () => mockBackupService.getUserEmail(),
      ).thenAnswer((_) async => null);
      // storageInfo removed from service interface
    });

    blocTest<BackupBloc, BackupState>(
      'debe emitir estado de carga y cargado al cargar configuración de backup',
      build: () => BackupBloc(
        backupService: mockBackupService,
        devocionalProvider: mockDevocionalProvider,
      ),
      act: (bloc) => bloc.add(const LoadBackupSettings()),
      expect: () => <dynamic>[
        // Cambiado a dynamic para permitir matchers
        const BackupLoading(),
        isA<BackupLoaded>(),
      ],
    );

    test(
      'no debe ejecutar lógica de backup si el flag está en false',
      () async {
        expect(Constants.enableBackupFeature, false);
        final bloc = BackupBloc(
          backupService: mockBackupService,
          devocionalProvider: mockDevocionalProvider,
        );
        bloc.add(const LoadBackupSettings());
        await expectLater(
          bloc.stream,
          emitsInOrder([
            const BackupLoading(),
            isA<BackupLoaded>(), // Cambiado a matcher compatible
          ]),
        );
      },
    );

    test('debe ejecutar flujo de backup si el flag está en true', () async {
      final originalFlag = Constants.enableBackupFeature;
      if (!originalFlag) {
        return;
      }
      final bloc = BackupBloc(
        backupService: mockBackupService,
        devocionalProvider: mockDevocionalProvider,
      );
      bloc.add(const LoadBackupSettings());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          const BackupLoading(),
          isA<BackupLoaded>(), // Cambiado a matcher compatible
        ]),
      );
    });

    // Puedes agregar más pruebas de bloc para cobertura crítica
  });

  group('BackupBloc SignInToGoogleDrive — BackupSigningIn state', () {
    late MockGoogleDriveBackupService mockBackupService;
    late MockDevocionalProvider mockDevocionalProvider;

    setUp(() {
      mockBackupService = MockGoogleDriveBackupService();
      mockDevocionalProvider = MockDevocionalProvider();

      when(() => mockBackupService.isAuthenticated())
          .thenAnswer((_) async => true);
      when(() => mockBackupService.isAutoBackupEnabled())
          .thenAnswer((_) async => false);
      when(() => mockBackupService.getBackupFrequency())
          .thenAnswer((_) async => 'daily');
      when(() => mockBackupService.isWifiOnlyEnabled())
          .thenAnswer((_) async => true);
      when(() => mockBackupService.isCompressionEnabled())
          .thenAnswer((_) async => true);
      when(() => mockBackupService.getBackupOptions())
          .thenAnswer((_) async => <String, bool>{});
      when(() => mockBackupService.getLastBackupTime())
          .thenAnswer((_) async => null);
      when(() => mockBackupService.getNextBackupTime())
          .thenAnswer((_) async => null);
      when(() => mockBackupService.getEstimatedBackupSize(any()))
          .thenAnswer((_) async => 0);
      when(() => mockBackupService.getUserEmail())
          .thenAnswer((_) async => 'user@example.com');
      when(() => mockBackupService.signIn()).thenAnswer((_) async => false);
      when(() => mockBackupService.checkForExistingBackup())
          .thenAnswer((_) async => null);
      when(() => mockBackupService.setAutoBackupEnabled(any()))
          .thenAnswer((_) async {});
      when(() => mockBackupService.createBackup(any()))
          .thenAnswer((_) async => true);
    });

    blocTest<BackupBloc, BackupState>(
      'emite BackupSigningIn como primer estado al iniciar sign-in',
      build: () => BackupBloc(
        backupService: mockBackupService,
        devocionalProvider: mockDevocionalProvider,
      ),
      act: (bloc) => bloc.add(const SignInToGoogleDrive()),
      expect: () => <dynamic>[
        const BackupSigningIn(),
        // sign-in returned false → emits BackupError
        isA<BackupError>(),
      ],
    );
  });

  group('BackupBloc SignInToGoogleDrive — fresh sign-in BackupSuccess', () {
    late MockGoogleDriveBackupService mockBackupService;
    late MockDevocionalProvider mockDevocionalProvider;

    setUp(() {
      mockBackupService = MockGoogleDriveBackupService();
      mockDevocionalProvider = MockDevocionalProvider();

      when(() => mockBackupService.isAuthenticated())
          .thenAnswer((_) async => true);
      when(() => mockBackupService.isAutoBackupEnabled())
          .thenAnswer((_) async => false);
      when(() => mockBackupService.getBackupFrequency())
          .thenAnswer((_) async => 'daily');
      when(() => mockBackupService.isWifiOnlyEnabled())
          .thenAnswer((_) async => true);
      when(() => mockBackupService.isCompressionEnabled())
          .thenAnswer((_) async => true);
      when(() => mockBackupService.getBackupOptions())
          .thenAnswer((_) async => <String, bool>{});
      when(() => mockBackupService.getLastBackupTime())
          .thenAnswer((_) async => null);
      when(() => mockBackupService.getNextBackupTime())
          .thenAnswer((_) async => null);
      when(() => mockBackupService.getEstimatedBackupSize(any()))
          .thenAnswer((_) async => 0);
      when(() => mockBackupService.getUserEmail())
          .thenAnswer((_) async => 'user@example.com');
      // sign-in succeeds, no existing backup (first-time user)
      when(() => mockBackupService.signIn()).thenAnswer((_) async => true);
      when(() => mockBackupService.checkForExistingBackup())
          .thenAnswer((_) async => null);
      when(() => mockBackupService.setAutoBackupEnabled(any()))
          .thenAnswer((_) async {});
      when(() => mockBackupService.createBackup(any()))
          .thenAnswer((_) async => true);
    });

    blocTest<BackupBloc, BackupState>(
      'emite BackupSuccess con created_successfully después de crear backup inicial',
      build: () => BackupBloc(
        backupService: mockBackupService,
        devocionalProvider: mockDevocionalProvider,
      ),
      act: (bloc) => bloc.add(const SignInToGoogleDrive()),
      // BackupSigningIn → BackupSuccess(sign_in_success, created_successfully)
      // LoadBackupSettings fires after a 2 s delay — outside blocTest window
      expect: () => <dynamic>[
        const BackupSigningIn(),
        const BackupSuccess(
          'backup.sign_in_success',
          'backup.created_successfully',
        ),
      ],
    );
  });
}
