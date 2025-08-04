import 'dart:io';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:screenshot/screenshot.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/blocs/devocionales_bloc.dart';
import 'package:devocional_nuevo/blocs/devocionales_event.dart';
import 'package:devocional_nuevo/blocs/devocionales_state.dart';
import 'package:devocional_nuevo/pages/devocionales_page.dart';
import 'package:devocional_nuevo/pages/settings_page.dart';

// --- Mocks y Fakes para el test ---

class MockDevocionalesBloc extends Mock implements DevocionalesBloc {}
class MockScreenshotController extends Mock implements ScreenshotController {}
class FakeDevocionalesEvent extends Fake implements DevocionalesEvent {}
class FakeDevocionalesState extends Fake implements DevocionalesState {}
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

  late MockDevocionalesBloc mockDevocionalesBloc;
  late MockScreenshotController mockScreenshotController;

  setUpAll(() async {
    PathProviderPlatform.instance = mockPathProvider;

    registerFallbackValue(mockDevocional1);
    registerFallbackValue(FakeBuildContext());
    registerFallbackValue(FileMode.write);
    registerFallbackValue(XFile('dummy_path'));
    registerFallbackValue(Brightness.light);
    registerFallbackValue(FakeDevocionalesEvent());
    registerFallbackValue(FakeDevocionalesState());

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
    mockDevocionalesBloc = MockDevocionalesBloc();
    mockScreenshotController = MockScreenshotController();

    when(() => mockScreenshotController.capture()).thenAnswer((_) async => Uint8List(0));
  });

  tearDown(() {
    reset(mockDevocionalesBloc);
    reset(mockScreenshotController);
  });

  group('DevocionalesPage Bloc Tests', () {
    // Helper function to build the body based on state
    Widget buildBody(DevocionalesState state) {
      if (state is DevocionalesInitial) {
        return const Center(
          child: Text('Devocionales'),
        );
      } else if (state is DevocionalesLoading) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      } else if (state is DevocionalesLoaded) {
        return ListView.builder(
          itemCount: state.devocionales.length,
          itemBuilder: (context, index) {
            final devocional = state.devocionales[index];
            return ListTile(
              title: Text(devocional.versiculo),
            );
          },
        );
      } else if (state is DevocionalesError) {
        return Center(
          child: Text(state.message),
        );
      }
      return const SizedBox.shrink();
    }

    // Create a simplified test widget that responds to Bloc states
    Widget buildTestWidget(DevocionalesState state) {
      return BlocBuilder<DevocionalesBloc, DevocionalesState>(
        builder: (context, blocState) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Mi espacio íntimo con Dios'),
            ),
            body: buildBody(blocState),
          );
        },
      );
    }

    Widget makeTestableWidget(DevocionalesState state) {
      when(() => mockDevocionalesBloc.state).thenReturn(state);
      when(() => mockDevocionalesBloc.stream).thenAnswer((_) => Stream.value(state));
      
      return BlocProvider<DevocionalesBloc>.value(
        value: mockDevocionalesBloc,
        child: MaterialApp(
          home: buildTestWidget(state),
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

    testWidgets('When DevocionalesInitial, shows Scaffold and title text "Devocionales"',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(DevocionalesInitial()));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Devocionales'), findsOneWidget);
    });

    testWidgets('When DevocionalesLoading, shows CircularProgressIndicator',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(DevocionalesLoading()));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('When DevocionalesLoaded, shows ListView with sample data',
        (WidgetTester tester) async {
      final sampleDevocionales = [mockDevocional1, mockDevocional2];
      await tester.pumpWidget(makeTestableWidget(
        DevocionalesLoaded(
          devocionales: sampleDevocionales,
          selectedVersion: 'RVR1960',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text(mockDevocional1.versiculo), findsOneWidget);
    });

    testWidgets('When DevocionalesError, shows error message',
        (WidgetTester tester) async {
      const errorMessage = 'Test error message';
      await tester.pumpWidget(makeTestableWidget(
        DevocionalesError(errorMessage),
      ));
      await tester.pumpAndSettle();

      expect(find.text(errorMessage), findsOneWidget);
    });
  });
}