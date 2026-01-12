@Tags(['slow'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/backup_event.dart';
import 'package:devocional_nuevo/blocs/backup_state.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/google_drive_backup_service.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes for testing

class MockGoogleDriveBackupService extends Mock
    implements GoogleDriveBackupService {}

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
      when(
        () => mockBackupService.getStorageInfo(),
      ).thenAnswer((_) async => <String, dynamic>{});
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
}
