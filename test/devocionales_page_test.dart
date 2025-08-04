import 'dart:io';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/pages/devocionales_page.dart';
import 'package:devocional_nuevo/providers/theme_provider.dart';
import 'package:devocional_nuevo/pages/settings_page.dart';

// --- Mocks y Fakes para el test ---

class MockDevocionalProvider extends Mock with ChangeNotifier implements DevocionalProvider {}
class MockScreenshotController extends Mock implements ScreenshotController {}
class MockThemeProvider extends Mock with ChangeNotifier implements ThemeProvider {
  @override
  String get currentThemeFamily => 'default';
  @override
  Brightness get currentBrightness => Brightness.light;
}
class MockPathProviderPlatform extends PathProviderPlatform with Mock {
  MockPathProviderPlatform() : super();
  @override
  Future<String?> getApplicationDocumentsPath() async => '/mock_app_documents_dir';
}
class FakeBuildContext extends Fake implements BuildContext {}
class MockFile extends Mock implements File {
  @override
  Future<File> create({bool recursive = false, bool exclusive = false}) => super.noSuchMethod(
    Invocation.method(#create, [], {#recursive: recursive, #exclusive: exclusive}),
  ) as Future<File>;
  @override
  Future<File> writeAsBytes(List<int> bytes, {FileMode mode = FileMode.write, bool flush = false}) =>
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
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDevocionalProvider mockDevocionalProvider;
  late MockScreenshotController mockScreenshotController;
  late MockThemeProvider mockThemeProvider;

  setUpAll(() async {
    PathProviderPlatform.instance = mockPathProvider;

    registerFallbackValue(mockDevocional1);
    registerFallbackValue(FakeBuildContext());
    registerFallbackValue(FileMode.write);
    registerFallbackValue(XFile('dummy_path'));
    registerFallbackValue(Brightness.light);

    await initializeDateFormatting('es', null);

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
    mockThemeProvider = MockThemeProvider();

    when(() => mockDevocionalProvider.showInvitationDialog).thenReturn(false);
    when(() => mockDevocionalProvider.isLoading).thenReturn(false);
    when(() => mockDevocionalProvider.errorMessage).thenReturn(null);
    when(() => mockDevocionalProvider.devocionales).thenReturn([mockDevocional1, mockDevocional2]);
    when(() => mockDevocionalProvider.selectedVersion).thenReturn('RVR1960');
    when(() => mockDevocionalProvider.isFavorite(any())).thenReturn(false);

    when(() => mockThemeProvider.setThemeFamily(any())).thenAnswer((_) async {});
    when(() => mockThemeProvider.setBrightness(any())).thenAnswer((_) async {});
    when(() => mockDevocionalProvider.initializeData()).thenAnswer((_) async {});
    when(() => mockDevocionalProvider.setSelectedVersion(any())).thenAnswer((_) async {});
    when(() => mockDevocionalProvider.setInvitationDialogVisibility(any())).thenAnswer((_) async {});
    when(() => mockScreenshotController.capture()).thenAnswer((_) async => Uint8List(0));
  });

  tearDown(() {
    reset(mockDevocionalProvider);
    reset(mockScreenshotController);
    reset(mockThemeProvider);
  });

  group('DevocionalesPage UI and Interaction', () {
    Widget createWidgetUnderTest() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<DevocionalProvider>.value(
            value: mockDevocionalProvider,
          ),
          ChangeNotifierProvider<ThemeProvider>.value(
            value: mockThemeProvider,
          ),
        ],
        child: MaterialApp(
          home: DevocionalesPage(key: GlobalKey(),),
          routes: {
            '/settings': (context) => const SettingsPage(),
            '/favorites': (context) => const Text('Favorites Page Mock'),
            '/contact': (context) => const Text('Contact Page Mock'),
            '/about': (context) => const Text('About Page Mock'),
            '/notifications': (context) => const Text('Notifications Page Mock'),
          },
        ),
      );
    }

    testWidgets('Alternar favorito correctamente', (WidgetTester tester) async {
      var isFav = false;
      when(() => mockDevocionalProvider.isFavorite(mockDevocional1)).thenAnswer((_) => isFav);
      when(() => mockDevocionalProvider.toggleFavorite(mockDevocional1, any())).thenAnswer((_) {
        isFav = !isFav;
        mockDevocionalProvider.notifyListeners();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byTooltip('Guardar como favorito'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);

      await tester.tap(find.byTooltip('Guardar como favorito'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Quitar de favoritos'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
    });

    testWidgets('Navega a la página de Configuración', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final settingsButtonFinder = find.byTooltip('Configuración');
      expect(settingsButtonFinder, findsOneWidget);
      await tester.tap(settingsButtonFinder);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.text('Más opciones'), findsOneWidget);
    });

    // ... otros tests ...
  });
}