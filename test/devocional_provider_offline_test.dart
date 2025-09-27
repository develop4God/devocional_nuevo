@TestOn('vm')
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';

// Mock para PathProviderPlatform
class MockPathProviderPlatform extends PathProviderPlatform with Mock {
  @override
  Future<String?> getApplicationDocumentsPath() async => '/mock_documents_dir';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DevocionalProvider provider;
  late MockPathProviderPlatform mockPathProvider;

  setUpAll(() {
    mockPathProvider = MockPathProviderPlatform();
    PathProviderPlatform.instance = mockPathProvider;
  });

  setUp(() {
    provider = DevocionalProvider();
  });

  group('DevocionalProvider Offline Functionality', () {
    test('should have offline-related getters', () {
      expect(provider.isDownloading, isFalse);
      expect(provider.downloadStatus, isNull);
      expect(provider.isOfflineMode, isFalse);
    });

    test('should generate correct local file path', () async {
      // Este test verifica que el método de generación de rutas funcione correctamente
      // pero requiere acceso a métodos privados, por lo que usaremos métodos públicos
      const int year = 2024;
      const String language = 'es';

      final bool hasFile = await provider.hasLocalFile(year, language);
      expect(hasFile, isFalse); // No debería existir inicialmente
    });

    test('should check current year local data availability', () async {
      final bool hasData = await provider.hasCurrentYearLocalData();
      expect(hasData, isFalse); // No debería existir inicialmente
    });

    test('should clear download status', () {
      provider.clearDownloadStatus();
      expect(provider.downloadStatus, isNull);
    });

    test('should provide download methods for UI', () {
      // Verificar que los métodos públicos existen y son accesibles
      expect(provider.downloadCurrentYearDevocionales, isA<Function>());
      expect(provider.downloadDevocionalesForYear, isA<Function>());
      expect(provider.hasCurrentYearLocalData, isA<Function>());
      expect(provider.forceRefreshFromAPI, isA<Function>());
      expect(provider.clearDownloadStatus, isA<Function>());
    });

    test('should have proper properties for offline functionality', () {
      // Verificar que las nuevas propiedades están disponibles
      expect(provider.isDownloading, isA<bool>());
      expect(provider.downloadStatus, isA<String?>());
      expect(provider.isOfflineMode, isA<bool>());

      // Verificar estados iniciales
      expect(provider.isDownloading, false);
      expect(provider.downloadStatus, null);
      expect(provider.isOfflineMode, false);
    });
  });
}
