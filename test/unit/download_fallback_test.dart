import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Mock classes
class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('DevocionalProvider Download Fallback Tests', () {
    late DevocionalProvider provider;
    late MockHttpClient mockHttpClient;

    setUp(() {
      // Initialize shared preferences
      SharedPreferences.setMockInitialValues({});
      provider = DevocionalProvider();
      mockHttpClient = MockHttpClient();
    });

    test('should fall back to available version when selected version is missing', () async {
      // Arrange
      provider.setSelectedLanguage('en');
      provider.setSelectedVersion('NIV'); // This version doesn't exist for 2025
      
      // Mock the HTTP responses
      // First call (NIV) should fail with 404
      when(mockHttpClient.get(Uri.parse(Constants.getDevocionalesApiUrlMultilingual(2025, 'en', 'NIV'))))
          .thenAnswer((_) async => http.Response('Not Found', 404));
      
      // Second call (KJV fallback) should succeed
      when(mockHttpClient.get(Uri.parse(Constants.getDevocionalesApiUrlMultilingual(2025, 'en', 'KJV'))))
          .thenAnswer((_) async => http.Response('{"data": [{"id": "1", "title": "Test"}]}', 200));

      // Act
      final result = await provider.downloadCurrentYearDevocionales();

      // Assert
      expect(result, isTrue);
      expect(provider.selectedVersion, 'KJV'); // Should have fallen back to KJV
    });

    test('should maintain original version if fallback fails', () async {
      // Arrange  
      provider.setSelectedLanguage('fr');
      provider.setSelectedVersion('LSG1910'); // This exists, so no fallback needed
      
      // Mock successful response
      when(mockHttpClient.get(Uri.parse(Constants.getDevocionalesApiUrlMultilingual(2025, 'fr', 'LSG1910'))))
          .thenAnswer((_) async => http.Response('{"data": [{"id": "1", "title": "Test"}]}', 200));

      // Act
      final result = await provider.downloadCurrentYearDevocionales();

      // Assert
      expect(result, isTrue);
      expect(provider.selectedVersion, 'LSG1910'); // Should maintain original
    });

    test('should return false when all version fallbacks fail', () async {
      // Arrange
      provider.setSelectedLanguage('pt');
      provider.setSelectedVersion('NVI'); // This doesn't exist
      
      // Mock all possible responses to fail
      when(mockHttpClient.get(any))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      // Act
      final result = await provider.downloadCurrentYearDevocionales();

      // Assert
      expect(result, isFalse);
      expect(provider.selectedVersion, 'NVI'); // Should maintain original after failed fallback
    });
  });

  group('Constants URL Generation Tests', () {
    test('should generate correct URLs for 2025 multilingual files', () {
      // Test Spanish (backward compatibility)
      expect(
        Constants.getDevocionalesApiUrlMultilingual(2025, 'es', 'RVR1960'),
        'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_2025.json'
      );

      // Test other languages
      expect(
        Constants.getDevocionalesApiUrlMultilingual(2025, 'en', 'KJV'),
        'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_2025_en_KJV.json'
      );

      expect(
        Constants.getDevocionalesApiUrlMultilingual(2025, 'pt', 'ARC'),
        'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_2025_pt_ARC.json'
      );

      expect(
        Constants.getDevocionalesApiUrlMultilingual(2025, 'fr', 'LSG1910'),
        'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_2025_fr_LSG1910.json'
      );
    });
  });
}