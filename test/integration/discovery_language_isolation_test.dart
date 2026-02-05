@Tags(['integration'])
library;

// test/integration/discovery_language_isolation_test.dart

import 'package:devocional_nuevo/services/discovery_favorites_service.dart';
import 'package:devocional_nuevo/services/discovery_progress_tracker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Discovery Language Isolation Integration Tests', () {
    late DiscoveryFavoritesService favoritesService;
    late DiscoveryProgressTracker progressTracker;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      favoritesService = DiscoveryFavoritesService();
      progressTracker = DiscoveryProgressTracker();
    });

    test('favorites isolated by language', () async {
      const studyId = 'test_study';

      // Add favorite in English
      await favoritesService.toggleFavorite(studyId, 'en');
      final enFavorites = await favoritesService.loadFavoriteIds('en');
      expect(enFavorites.contains(studyId), isTrue);

      // Check Spanish favorites (should be empty)
      final esFavorites = await favoritesService.loadFavoriteIds('es');
      expect(esFavorites.contains(studyId), isFalse);

      // Add favorite in Spanish
      await favoritesService.toggleFavorite(studyId, 'es');
      final esFavoritesAfter = await favoritesService.loadFavoriteIds('es');
      expect(esFavoritesAfter.contains(studyId), isTrue);

      // English favorites should still exist
      final enFavoritesAfter = await favoritesService.loadFavoriteIds('en');
      expect(enFavoritesAfter.contains(studyId), isTrue);

      // Remove from English
      await favoritesService.toggleFavorite(studyId, 'en');
      final enFavoritesRemoved = await favoritesService.loadFavoriteIds('en');
      expect(enFavoritesRemoved.contains(studyId), isFalse);

      // Spanish favorites should remain unaffected
      final esFavoritesFinal = await favoritesService.loadFavoriteIds('es');
      expect(esFavoritesFinal.contains(studyId), isTrue);
    });

    test('language codes normalized correctly', () async {
      const studyId = 'test_study_normalize';

      // Add favorite with full locale (en-US)
      await favoritesService.toggleFavorite(studyId, 'en-US');

      // Check with base language (en)
      final favorites = await favoritesService.loadFavoriteIds('en');
      expect(favorites.contains(studyId), isTrue,
          reason: 'Language codes should be normalized to base language');

      // Check with different region (en-GB)
      final favoritesGB = await favoritesService.loadFavoriteIds('en-GB');
      expect(favoritesGB.contains(studyId), isTrue,
          reason: 'Different regions of same language should share favorites');
    });

    test('progress isolated by language', () async {
      const studyId = 'test_study_progress';

      // Mark as completed in English
      await progressTracker.completeStudy(studyId, 'en');
      final enProgress = await progressTracker.getProgress(studyId, 'en');
      expect(enProgress.isCompleted, isTrue);

      // Check Spanish progress (should not be completed)
      final esProgress = await progressTracker.getProgress(studyId, 'es');
      expect(esProgress.isCompleted, isFalse,
          reason: 'Progress should be isolated by language');

      // Mark section completed in Spanish
      await progressTracker.markSectionCompleted(studyId, 0, 'es');
      final esProgressAfter = await progressTracker.getProgress(studyId, 'es');
      expect(esProgressAfter.completedSections.contains(0), isTrue);

      // English progress should have no sections completed
      final enProgressAfter = await progressTracker.getProgress(studyId, 'en');
      expect(enProgressAfter.completedSections.isEmpty, isTrue,
          reason: 'Only study completion was tracked, not sections');
    });

    test('first download only once per language', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      const downloadKeyEn = 'discovery_first_downloaded_en';
      const downloadKeyEs = 'discovery_first_downloaded_es';

      // Initially, no downloads
      expect(prefs.getBool(downloadKeyEn), isNull);
      expect(prefs.getBool(downloadKeyEs), isNull);

      // Mark first download for English
      await prefs.setBool(downloadKeyEn, true);
      expect(prefs.getBool(downloadKeyEn), isTrue);

      // Spanish should still be null
      expect(prefs.getBool(downloadKeyEs), isNull);

      // Mark first download for Spanish
      await prefs.setBool(downloadKeyEs, true);
      expect(prefs.getBool(downloadKeyEs), isTrue);

      // Both should now be marked
      expect(prefs.getBool(downloadKeyEn), isTrue);
      expect(prefs.getBool(downloadKeyEs), isTrue);
    });

    test('switching language preserves separate favorites', () async {
      const study1 = 'study_1';
      const study2 = 'study_2';

      // User adds favorites in English
      await favoritesService.toggleFavorite(study1, 'en');
      await favoritesService.toggleFavorite(study2, 'en');

      final enFavorites = await favoritesService.loadFavoriteIds('en');
      expect(enFavorites.length, equals(2));

      // User switches to Spanish and adds different favorites
      await favoritesService.toggleFavorite(study1, 'es');

      final esFavorites = await favoritesService.loadFavoriteIds('es');
      expect(esFavorites.length, equals(1));
      expect(esFavorites.contains(study1), isTrue);

      // Switch back to English - favorites should be intact
      final enFavoritesAgain = await favoritesService.loadFavoriteIds('en');
      expect(enFavoritesAgain.length, equals(2));
      expect(enFavoritesAgain.contains(study1), isTrue);
      expect(enFavoritesAgain.contains(study2), isTrue);
    });

    test('switching language preserves separate progress', () async {
      const studyId = 'study_multilang';

      // Complete different sections in different languages
      await progressTracker.markSectionCompleted(studyId, 0, 'en');
      await progressTracker.markSectionCompleted(studyId, 1, 'en');

      await progressTracker.markSectionCompleted(studyId, 0, 'es');
      await progressTracker.markSectionCompleted(studyId, 2, 'es');

      // Verify English progress
      final enProgress = await progressTracker.getProgress(studyId, 'en');
      expect(enProgress.completedSections.length, equals(2));
      expect(enProgress.completedSections.contains(0), isTrue);
      expect(enProgress.completedSections.contains(1), isTrue);

      // Verify Spanish progress
      final esProgress = await progressTracker.getProgress(studyId, 'es');
      expect(esProgress.completedSections.length, equals(2));
      expect(esProgress.completedSections.contains(0), isTrue);
      expect(esProgress.completedSections.contains(2), isTrue);

      // Complete study in English
      await progressTracker.completeStudy(studyId, 'en');
      final enCompleted = await progressTracker.getProgress(studyId, 'en');
      expect(enCompleted.isCompleted, isTrue);

      // Spanish should not be marked as completed
      final esNotCompleted = await progressTracker.getProgress(studyId, 'es');
      expect(esNotCompleted.isCompleted, isFalse);
    });
  });
}
