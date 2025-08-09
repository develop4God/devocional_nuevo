import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:devocional_nuevo/widgets/offline_manager_widget.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';

// Mock for DevocionalProvider
class MockDevocionalProvider extends DevocionalProvider with Mock {
  bool _isDownloading = false;
  String? _downloadStatus;
  bool _isOfflineMode = false;

  @override
  bool get isDownloading => _isDownloading;
  
  @override
  String? get downloadStatus => _downloadStatus;
  
  @override
  bool get isOfflineMode => _isOfflineMode;

  void setDownloading(bool downloading) {
    _isDownloading = downloading;
    notifyListeners();
  }

  void setDownloadStatus(String? status) {
    _downloadStatus = status;
    notifyListeners();
  }

  void setOfflineMode(bool offline) {
    _isOfflineMode = offline;
    notifyListeners();
  }
}

void main() {
  late MockDevocionalProvider mockProvider;

  setUp(() {
    mockProvider = MockDevocionalProvider();
  });

  Widget createWidgetUnderTest({
    bool showCompactView = false,
    bool showStatusIndicator = true,
  }) {
    return MaterialApp(
      home: ChangeNotifierProvider<DevocionalProvider>.value(
        value: mockProvider,
        child: Scaffold(
          body: OfflineManagerWidget(
            showCompactView: showCompactView,
            showStatusIndicator: showStatusIndicator,
          ),
        ),
      ),
    );
  }

  group('OfflineManagerWidget', () {
    testWidgets('should render in compact view', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(showCompactView: true));
      
      // Should show download button in compact view
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Descargar año actual'), findsOneWidget);
      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('should render in full view with both buttons', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(showCompactView: false));
      
      // Should show both buttons in full view
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.text('Descargar año actual'), findsOneWidget);
      expect(find.text('Actualizar'), findsOneWidget);
    });

    testWidgets('should show offline mode indicator when in offline mode', (WidgetTester tester) async {
      mockProvider.setOfflineMode(true);
      
      await tester.pumpWidget(createWidgetUnderTest(showCompactView: false));
      await tester.pump();
      
      expect(find.text('Usando contenido offline'), findsOneWidget);
      expect(find.byIcon(Icons.offline_bolt), findsOneWidget);
    });

    testWidgets('should show download status when available', (WidgetTester tester) async {
      mockProvider.setDownloadStatus('Descargando devocionales...');
      mockProvider.setDownloading(true);
      
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      
      expect(find.text('Descargando devocionales...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show success status with check icon', (WidgetTester tester) async {
      mockProvider.setDownloadStatus('Descarga completada exitosamente');
      mockProvider.setDownloading(false);
      
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      
      expect(find.text('Descarga completada exitosamente'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should show error status with error icon', (WidgetTester tester) async {
      mockProvider.setDownloadStatus('Error al descargar devocionales');
      mockProvider.setDownloading(false);
      
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      
      expect(find.text('Error al descargar devocionales'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('should disable buttons when downloading', (WidgetTester tester) async {
      mockProvider.setDownloading(true);
      
      await tester.pumpWidget(createWidgetUnderTest(showCompactView: false));
      await tester.pump();
      
      // Buttons should be disabled
      final downloadButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final refreshButton = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      
      expect(downloadButton.onPressed, isNull);
      expect(refreshButton.onPressed, isNull);
    });

    testWidgets('should have close button for status messages', (WidgetTester tester) async {
      mockProvider.setDownloadStatus('Test status');
      mockProvider.setDownloading(false);
      
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      
      expect(find.byIcon(Icons.close), findsOneWidget);
      
      // Test that close button calls clearDownloadStatus
      when(() => mockProvider.clearDownloadStatus()).thenReturn(null);
      
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      
      verify(() => mockProvider.clearDownloadStatus()).called(1);
    });
  });
}