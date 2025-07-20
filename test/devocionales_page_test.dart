//devocionales_page_test.dart
import 'dart:io';
import 'package:flutter/rendering.dart'; // NUEVO: Importación para debugDumpApp
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/pages/devocionales_page.dart';
import 'package:devocional_nuevo/providers/theme_provider.dart'; // Importa el ThemeProvider
import 'package:devocional_nuevo/pages/settings_page.dart'; // Importa SettingsPage para usar en rutas

// --- Mocks y Fakes para el test ---

// Mock de DevocionalProvider
class MockDevocionalProvider extends Mock
    with ChangeNotifier
    implements DevocionalProvider {}

// Mock de ScreenshotController
class MockScreenshotController extends Mock implements ScreenshotController {}

// MODIFICACIÓN: Mock de ThemeProvider con valores por defecto para getters no nulos
class MockThemeProvider extends Mock
    with ChangeNotifier
    implements ThemeProvider {
  @override
  String get currentThemeFamily => 'default'; // Asegura que siempre devuelva un String no nulo
  @override
  Brightness get currentBrightness => Brightness.light; // Asegura que siempre devuelva un Brightness no nulo
}

// Extiende PathProviderPlatform e implementa explícitamente el método a mockear.
class MockPathProviderPlatform extends PathProviderPlatform with Mock {
  MockPathProviderPlatform() : super(); // Vuelve al constructor sin token

  @override
  Future<String?> getApplicationDocumentsPath() async => '/mock_app_documents_dir'; // Añade esta implementación concreta
}
// Fake para BuildContext
class FakeBuildContext extends Fake implements BuildContext {}

// Mock para la clase File para operaciones de archivo simuladas en tests
class MockFile extends Mock implements File {
  @override
  Future<File> create({bool recursive = false, bool exclusive = false}) => super.noSuchMethod(
    Invocation.method(#create, [], {#recursive: recursive, #exclusive: exclusive}),
  ) as Future<File>;

  @override
  Future<File> writeAsBytes(List<int> bytes,
      {FileMode mode = FileMode.write, bool flush = false}) =>
      super.noSuchMethod(
        Invocation.method(#writeAsBytes, [bytes], {#mode: mode, #flush: flush}),
      ) as Future<File>;

  @override
  String get path => super.noSuchMethod(
    Invocation.getter(#path),
  ) as String;
}

// --- Datos de prueba simulados ---
final Devocional mockDevocional1 = Devocional(
  id: '1',
  versiculo: 'Juan 3:16 - De tal manera amó Dios al mundo...',
  reflexion: 'Reflexión sobre el amor de Dios...',
  paraMeditar: [
    ParaMeditar(cita: 'Romanos 5:8', texto: 'Mas Dios muestra su amor para con nosotros...'),
  ],
  oracion: 'Oración por el amor de Dios...',
  date: DateTime(2023, 1, 1),
  version: 'RVR1960',
  language: 'es',
  tags: ['Amor', 'Dios'],
);

final Devocional mockDevocional2 = Devocional(
  id: '2',
  versiculo: 'Filipenses 4:13 - Todo lo puedo en Cristo que me fortalece.',
  reflexion: 'Reflexión sobre la fortaleza en Cristo...',
  paraMeditar: [
    ParaMeditar(cita: 'Isaías 41:10', texto: 'No temas, porque yo estoy contigo...'),
  ],
  oracion: 'Oración por fortaleza...',
  date: DateTime(2023, 1, 2),
  version: 'RVR1960',
  language: 'es',
  tags: ['Fe', 'Fortaleza'],
);

// Declaramos los mocks a nivel global
final MockPathProviderPlatform mockPathProvider = MockPathProviderPlatform();

void main() {
  // Inicializa el Binding de Widgets de Flutter para tests
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDevocionalProvider mockDevocionalProvider;
  late MockScreenshotController mockScreenshotController;
  late MockThemeProvider mockThemeProvider; // Declara el mock de ThemeProvider

  setUpAll(() async {
    PathProviderPlatform.instance = mockPathProvider;


    registerFallbackValue(mockDevocional1);
    registerFallbackValue(FakeBuildContext());
    registerFallbackValue(FileMode.write);
    registerFallbackValue(XFile('dummy_path'));
    registerFallbackValue(Brightness.light); // Para ThemeProvider

    await initializeDateFormatting('es', null);

    // Mockear PackageInfo.fromPlatform()
    PackageInfo.setMockInitialValues(
      appName: 'Devocionales Cristianos',
      packageName: 'com.devocional.nuevo',
      version: '1.2.3',
      buildNumber: '456',
      buildSignature: 'build_signature',
      installerStore: 'installer_store',
    );
  });

  setUp(() {
    mockDevocionalProvider = MockDevocionalProvider();
    mockScreenshotController = MockScreenshotController();
    mockThemeProvider = MockThemeProvider(); // Inicializa el mock de ThemeProvider
    // NOTA: Los getters currentThemeFamily y currentBrightness ya tienen valores por defecto en MockThemeProvider

    // SIEMPRE: stub global para evitar errores de null en bool
    when(() => mockDevocionalProvider.isFavorite(any())).thenReturn(false);
    when(() => mockDevocionalProvider.showInvitationDialog).thenReturn(false);

    // Configuración por defecto del provider para la mayoría de los tests
    when(() => mockDevocionalProvider.isLoading).thenReturn(false);
    when(() => mockDevocionalProvider.errorMessage).thenReturn(null);
    when(() => mockDevocionalProvider.devocionales).thenReturn([mockDevocional1, mockDevocional2]);
    when(() => mockDevocionalProvider.selectedVersion).thenReturn('RVR1960');

    // Mocks para ThemeProvider - Corrección de Future<void>
    when(() => mockThemeProvider.setThemeFamily(any())).thenAnswer((_) async {});
    when(() => mockThemeProvider.setBrightness(any())).thenAnswer((_) async {});


    // Mockea las llamadas a métodos del provider (void methods)
    when(() => mockDevocionalProvider.initializeData()).thenAnswer((_) async {});
    when(() => mockDevocionalProvider.setSelectedVersion(any())).thenAnswer((_) async {});
    when(() => mockDevocionalProvider.toggleFavorite(any(), any())).thenAnswer((_) {});
    when(() => mockDevocionalProvider.setInvitationDialogVisibility(any())).thenAnswer((_) async {});

    // Mockear la captura de pantalla
    when(() => mockScreenshotController.capture()).thenAnswer((_) async => Uint8List(0));
  });

  tearDown(() {
    reset(mockDevocionalProvider);
    reset(mockScreenshotController);
    reset(mockThemeProvider); // Resetea el mock de ThemeProvider
  });

  group('DevocionalesPage UI and Interaction', () {
    // MODIFICACIÓN: createWidgetUnderTest ahora envuelve con MultiProvider para incluir ThemeProvider
    Widget createWidgetUnderTest() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<DevocionalProvider>.value(
            value: mockDevocionalProvider,
          ),
          ChangeNotifierProvider<ThemeProvider>.value( // AÑADIDO: ThemeProvider para las pruebas
            value: mockThemeProvider,
          ),
        ],
        child: MaterialApp(
          home: DevocionalesPage(key: GlobalKey(),),
          // MODIFICACIÓN: Añadir rutas para que Navigator.push funcione en las pruebas
          // Usamos el widget real SettingsPage aquí para que el test pueda interactuar con él
          // y verificar su contenido.
          routes: {
            '/settings': (context) => const SettingsPage(), // Usar la página real de Settings
            '/favorites': (context) => const Text('Favorites Page Mock'),
            '/contact': (context) => const Text('Contact Page Mock'),
            '/about': (context) => const Text('About Page Mock'),
            '/notifications': (context) => const Text('Notifications Page Mock'),
          },
        ),
      );
    }

    testWidgets('Muestra indicador de carga cuando el provider está cargando', (WidgetTester tester) async {
      when(() => mockDevocionalProvider.isLoading).thenReturn(true);

      await tester.pumpWidget(createWidgetUnderTest());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Muestra mensaje de error cuando el provider tiene error y no hay devocionales', (WidgetTester tester) async {
      when(() => mockDevocionalProvider.isLoading).thenReturn(false);
      when(() => mockDevocionalProvider.errorMessage).thenReturn('Error de prueba!');
      when(() => mockDevocionalProvider.devocionales).thenReturn([]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      expect(find.text('Error de prueba!'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Muestra mensaje de no devocionales cuando la lista está vacía', (WidgetTester tester) async {
      when(() => mockDevocionalProvider.isLoading).thenReturn(false);
      when(() => mockDevocionalProvider.errorMessage).thenReturn(null);
      when(() => mockDevocionalProvider.devocionales).thenReturn([]);

      await tester.pumpWidget(createWidgetUnderTest());
      expect(find.text('No hay devocionales disponibles para el idioma/versión seleccionados.'), findsOneWidget);
    });

    testWidgets('Muestra el primer devocional y navega al siguiente', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text(mockDevocional1.versiculo), findsOneWidget);
      expect(find.text(mockDevocional2.versiculo), findsNothing);

      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();

      expect(find.text(mockDevocional1.versiculo), findsNothing);
      expect(find.text(mockDevocional2.versiculo), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();
      expect(find.text(mockDevocional2.versiculo), findsOneWidget);
    });

    testWidgets('Navega al devocional anterior', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();
      expect(find.text(mockDevocional2.versiculo), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text(mockDevocional1.versiculo), findsOneWidget);
      expect(find.text(mockDevocional2.versiculo), findsNothing);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text(mockDevocional1.versiculo), findsOneWidget);
    });

    testWidgets('Alternar favorito correctamente', (WidgetTester tester) async {
      // Control de estado manual para simular cambio de favorito
      bool isFav = false;
      when(() => mockDevocionalProvider.isFavorite(mockDevocional1)).thenAnswer((_) => isFav);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // MODIFICACIÓN: Buscar el IconButton por su tooltip, ya que está en el BottomAppBar
      final favoriteButtonFinder = find.byTooltip('Guardar como favorito');

      expect(favoriteButtonFinder, findsOneWidget); // Debe encontrar el botón por su tooltip
      expect(find.byIcon(Icons.favorite), findsNothing); // Asegura que el corazón lleno no está inicialmente

      // Simula el cambio de estado al hacer favorito
      when(() => mockDevocionalProvider.toggleFavorite(mockDevocional1, any())).thenAnswer((_) {
        isFav = true;
        mockDevocionalProvider.notifyListeners();
      });

      await tester.tap(favoriteButtonFinder); // Toca el botón de favorito
      await tester.pumpAndSettle();

      // Verifica que el icono cambió a corazón lleno y el tooltip a 'Quitar de favoritos'
      expect(find.byTooltip('Quitar de favoritos'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing); // Asegura que el corazón delineado ya no está
    });

    testWidgets('Navega a la página de Configuración', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // MODIFICACIÓN: Buscar el IconButton de configuración por su tooltip, ya que está en el BottomAppBar
      final settingsButtonFinder = find.byTooltip('Configuración');

      expect(settingsButtonFinder, findsOneWidget); // Asegura que el botón de configuración está presente
      await tester.tap(settingsButtonFinder); // Toca el botón de configuración
      await tester.pump(); // NUEVO: Un pump adicional para un ciclo de renderizado extra
      await tester.pumpAndSettle(); // Espera que la navegación y la nueva página se asienten

      // MODIFICACIÓN: Verificar que la SettingsPage se ha renderizado y luego buscar el texto
      expect(find.byType(SettingsPage), findsOneWidget); // Verifica que la SettingsPage está en el árbol
      debugDumpApp();
      expect(find.text('Más opciones'), findsOneWidget); // Busca el texto directamente en la página de configuración

    });

    testWidgets('Muestra el diálogo de invitación cuando showInvitationDialog es true', (WidgetTester tester) async {
      when(() => mockDevocionalProvider.showInvitationDialog).thenReturn(true);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // AGREGA ESTA LÍNEA para simular avanzar al siguiente devocional (o el trigger real en tu app)
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();

      expect(find.text('¡Oración de fe, para vida eterna!'), findsOneWidget);
      expect(find.text('Ya la hice 🙏\nNo mostrar nuevamente'), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      verify(() => mockDevocionalProvider.setInvitationDialogVisibility(false)).called(1);
      expect(find.text('¡Oración de fe, para vida eterna!'), findsNothing);
    });
  });
}
