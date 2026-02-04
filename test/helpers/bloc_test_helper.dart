// test/helpers/bloc_test_helper.dart
// Reusable test helpers for BLoC testing with mocked dependencies

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/repositories/discovery_repository.dart';
import 'package:devocional_nuevo/services/discovery_favorites_service.dart';
import 'package:devocional_nuevo/services/discovery_progress_tracker.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bloc_test_helper.mocks.dart';

// Note: we import the generated mocks so types like MockDiscoveryRepository
// are available inside this helper file. The generated file is
// `test/helpers/bloc_test_helper.mocks.dart` and is created by build_runner.

@GenerateMocks([
  DiscoveryRepository,
  DiscoveryProgressTracker,
  DiscoveryFavoritesService,
  DevocionalProvider,
])
class BlocTestHelper {}

/// Base class for BLoC tests with common setup
class DiscoveryBlocTestBase {
  // Use dynamic here to avoid analyzer issues when the generated mocks
  // aren't visible to certain analyzer runs. The helper constructs
  // the actual mock instances via the generated constructors.
  late dynamic mockRepository;
  late dynamic mockProgressTracker;
  late dynamic mockFavoritesService;

  /// Setup mocks with default behaviors
  void setupMocks() {
    SharedPreferences.setMockInitialValues({});
    mockRepository = MockDiscoveryRepository();
    mockProgressTracker = MockDiscoveryProgressTracker();
    mockFavoritesService = MockDiscoveryFavoritesService();

    // Default mock behaviors
    when(mockFavoritesService.loadFavoriteIds(any))
        .thenAnswer((_) async => <String>{});
    when(mockProgressTracker.getProgress(any, any))
        .thenAnswer((_) async => null);
  }

  /// Mock successful index fetch with empty studies
  void mockEmptyIndexFetch() {
    when(mockRepository.fetchIndex(forceRefresh: anyNamed('forceRefresh')))
        .thenAnswer((_) async => {'studies': []});
  }

  /// Mock successful index fetch with studies
  void mockIndexFetchWithStudies(List<Map<String, dynamic>> studies) {
    when(mockRepository.fetchIndex(forceRefresh: anyNamed('forceRefresh')))
        .thenAnswer((_) async => {'studies': studies});
  }

  /// Mock index fetch failure
  void mockIndexFetchFailure(String errorMessage) {
    when(mockRepository.fetchIndex(forceRefresh: anyNamed('forceRefresh')))
        .thenThrow(Exception(errorMessage));
  }

  /// Create sample study data for testing
  Map<String, dynamic> createSampleStudy({
    required String id,
    String? titleEs = 'Test Study',
    String? titleEn = 'Test Study EN',
    String emoji = '📖',
    int minutes = 5,
  }) {
    return {
      'id': id,
      'version': '1.0',
      'files': {'es': '$id.json', 'en': '${id}_en.json'},
      'titles': {'es': titleEs, 'en': titleEn},
      'subtitles': {'es': 'Subtitle', 'en': 'Subtitle EN'},
      'emoji': emoji,
      'estimated_reading_minutes': {'es': minutes, 'en': minutes},
    };
  }
}

/// Helper to create a MockDevocionalProvider with default behaviors
dynamic createMockDevocionalProvider({
  List<Devocional>? favoriteDevocionales,
  String? selectedLanguage,
}) {
  final mock = MockDevocionalProvider();
  when(mock.favoriteDevocionales)
      .thenReturn(favoriteDevocionales ?? <Devocional>[]);
  when(mock.selectedLanguage).thenReturn(selectedLanguage ?? 'es');
  return mock;
}
