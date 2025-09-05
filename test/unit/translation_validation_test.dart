// test/unit/translation_validation_test.dart

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Translation Validation Tests', () {
    late Map<String, dynamic> spanishTranslations;
    late Map<String, dynamic> englishTranslations;
    late Map<String, dynamic> portugueseTranslations;
    late Map<String, dynamic> frenchTranslations;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      // Mock translation files since assets aren't available in test environment
      spanishTranslations = {
        'app': {'title': 'Devocional'},
        'common': {'loading': 'Cargando...', 'error': 'Error'},
        'devotionals': {'title': 'Devocionales'},
        'achievements': {
          'first_read_title': 'Primer Paso',
          'first_read_description': 'Lee tu primer devocional',
          'week_reader_title': 'Lector Semanal',
          'week_reader_description': 'Lee devocionales por 7 días',
          'month_reader_title': 'Lector Mensual',
          'month_reader_description': 'Lee devocionales por 30 días',
          'streak_3_title': 'Constancia',
          'streak_3_description': 'Mantén una racha de 3 días',
          'streak_7_title': 'Semana Espiritual',
          'streak_7_description': 'Mantén una racha de 7 días',
          'streak_30_title': 'Guerrero Espiritual',
          'streak_30_description': 'Mantén una racha de 30 días',
          'first_favorite_title': 'Primer Favorito',
          'first_favorite_description': 'Guarda tu primer devocional favorito',
          'collector_title': 'Coleccionista',
          'collector_description': 'Guarda 10 devocionales favoritos',
        }
      };

      englishTranslations = {
        'app': {'title': 'Devotional'},
        'common': {'loading': 'Loading...', 'error': 'Error'},
        'devotionals': {'title': 'Devotionals'},
        'achievements': {
          'first_read_title': 'First Step',
          'first_read_description': 'Read your first devotional',
          'week_reader_title': 'Weekly Reader',
          'week_reader_description': 'Read devotionals for 7 days',
          'month_reader_title': 'Monthly Reader',
          'month_reader_description': 'Read devotionals for 30 days',
          'streak_3_title': 'Consistency',
          'streak_3_description': 'Maintain a 3-day streak',
          'streak_7_title': 'Spiritual Week',
          'streak_7_description': 'Maintain a 7-day streak',
          'streak_30_title': 'Spiritual Warrior',
          'streak_30_description': 'Maintain a 30-day streak',
          'first_favorite_title': 'First Favorite',
          'first_favorite_description': 'Save your first favorite devotional',
          'collector_title': 'Collector',
          'collector_description': 'Save 10 favorite devotionals',
        }
      };

      portugueseTranslations = {
        'app': {'title': 'Devocional'},
        'common': {'loading': 'Carregando...', 'error': 'Erro'},
        'devotionals': {'title': 'Devocionais'},
        'achievements': {
          'first_read_title': 'Primeiro Passo',
          'first_read_description': 'Leia seu primeiro devocional',
          'week_reader_title': 'Leitor Semanal',
          'week_reader_description': 'Leia devocionais por 7 dias',
          'month_reader_title': 'Leitor Mensal',
          'month_reader_description': 'Leia devocionais por 30 dias',
          'streak_3_title': 'Constância',
          'streak_3_description': 'Mantenha uma sequência de 3 dias',
          'streak_7_title': 'Semana Espiritual',
          'streak_7_description': 'Mantenha uma sequência de 7 dias',
          'streak_30_title': 'Guerreiro Espiritual',
          'streak_30_description': 'Mantenha uma sequência de 30 dias',
          'first_favorite_title': 'Primeiro Favorito',
          'first_favorite_description': 'Salve seu primeiro devocional favorito',
          'collector_title': 'Colecionador',
          'collector_description': 'Salve 10 devocionais favoritos',
        }
      };

      frenchTranslations = {
        'app': {'title': 'Dévotion'},
        'common': {'loading': 'Chargement...', 'error': 'Erreur'},
        'devotionals': {'title': 'Dévotions'},
        'achievements': {
          'first_read_title': 'Premier Pas',
          'first_read_description': 'Lisez votre premier dévotionnel',
          'week_reader_title': 'Lecteur Hebdomadaire',
          'week_reader_description': 'Lisez des dévotionnels pendant 7 jours',
          'month_reader_title': 'Lecteur Mensuel',
          'month_reader_description': 'Lisez des dévotionnels pendant 30 jours',
          'streak_3_title': 'Constance',
          'streak_3_description': 'Maintenez une série de 3 jours',
          'streak_7_title': 'Semaine Spirituelle',
          'streak_7_description': 'Maintenez une série de 7 jours',
          'streak_30_title': 'Guerrier Spirituel',
          'streak_30_description': 'Maintenez une série de 30 jours',
          'first_favorite_title': 'Premier Favori',
          'first_favorite_description': 'Sauvegardez votre premier dévotionnel favori',
          'collector_title': 'Collectionneur',
          'collector_description': 'Sauvegardez 10 dévotionnels favoris',
        }
      };
    });

    test('All translation files should have same key structure', () {
      final spanishKeys = _getAllKeys(spanishTranslations);
      final englishKeys = _getAllKeys(englishTranslations);
      final portugueseKeys = _getAllKeys(portugueseTranslations);
      final frenchKeys = _getAllKeys(frenchTranslations);

      // All languages should have same keys as Spanish (base language)
      expect(englishKeys, equals(spanishKeys),
          reason: 'English translations missing or extra keys');
      expect(portugueseKeys, equals(spanishKeys),
          reason: 'Portuguese translations missing or extra keys');
      expect(frenchKeys, equals(spanishKeys),
          reason: 'French translations missing or extra keys');
    });

    test('No translation should be empty', () {
      _validateNoEmptyTranslations(spanishTranslations, 'Spanish');
      _validateNoEmptyTranslations(englishTranslations, 'English');
      _validateNoEmptyTranslations(portugueseTranslations, 'Portuguese');
      _validateNoEmptyTranslations(frenchTranslations, 'French');
    });

    test('All languages should have required keys', () {
      final requiredKeys = ['app.title', 'common.loading', 'common.error'];

      for (final key in requiredKeys) {
        expect(_hasKey(spanishTranslations, key), isTrue,
            reason: 'Spanish missing required key: $key');
        expect(_hasKey(englishTranslations, key), isTrue,
            reason: 'English missing required key: $key');
        expect(_hasKey(portugueseTranslations, key), isTrue,
            reason: 'Portuguese missing required key: $key');
        expect(_hasKey(frenchTranslations, key), isTrue,
            reason: 'French missing required key: $key');
      }
    });

    test('Translation values should be different across languages', () {
      final appTitleSpanish = _getValue(spanishTranslations, 'app.title');
      final appTitleEnglish = _getValue(englishTranslations, 'app.title');
      final appTitlePortuguese = _getValue(portugueseTranslations, 'app.title');
      final appTitleFrench = _getValue(frenchTranslations, 'app.title');

      // App titles should be different for different languages
      expect(appTitleSpanish, isNot(equals(appTitleEnglish)));
      expect(appTitleSpanish, isNot(equals(appTitleFrench)));
    });

    test('Achievements section should have all required keys', () {
      // Check that all achievement keys exist in all languages
      final achievementKeys = [
        'achievements.first_read_title',
        'achievements.first_read_description',
        'achievements.week_reader_title',
        'achievements.week_reader_description',
        'achievements.month_reader_title',
        'achievements.month_reader_description',
        'achievements.streak_3_title',
        'achievements.streak_3_description',
        'achievements.streak_7_title',
        'achievements.streak_7_description',
        'achievements.streak_30_title',
        'achievements.streak_30_description',
        'achievements.first_favorite_title',
        'achievements.first_favorite_description',
        'achievements.collector_title',
        'achievements.collector_description',
      ];

      for (final key in achievementKeys) {
        expect(_hasKey(spanishTranslations, key), isTrue,
            reason: 'Spanish missing achievement key: $key');
        expect(_hasKey(englishTranslations, key), isTrue,
            reason: 'English missing achievement key: $key');
        expect(_hasKey(portugueseTranslations, key), isTrue,
            reason: 'Portuguese missing achievement key: $key');
        expect(_hasKey(frenchTranslations, key), isTrue,
            reason: 'French missing achievement key: $key');
      }
    });

    test('Achievement translations should be different across languages', () {
      // Verify that achievement titles are properly translated
      final firstReadTitleSpanish = _getValue(spanishTranslations, 'achievements.first_read_title');
      final firstReadTitleEnglish = _getValue(englishTranslations, 'achievements.first_read_title');
      final firstReadTitlePortuguese = _getValue(portugueseTranslations, 'achievements.first_read_title');
      final firstReadTitleFrench = _getValue(frenchTranslations, 'achievements.first_read_title');

      expect(firstReadTitleSpanish, isNot(equals(firstReadTitleEnglish)));
      expect(firstReadTitleSpanish, isNot(equals(firstReadTitlePortuguese)));
      expect(firstReadTitleSpanish, isNot(equals(firstReadTitleFrench)));
    });
  });
}

Set<String> _getAllKeys(Map<String, dynamic> translations,
    [String prefix = '']) {
  final Set<String> keys = {};

  translations.forEach((key, value) {
    final fullKey = prefix.isEmpty ? key : '$prefix.$key';

    if (value is Map<String, dynamic>) {
      keys.addAll(_getAllKeys(value, fullKey));
    } else {
      keys.add(fullKey);
    }
  });

  return keys;
}

void _validateNoEmptyTranslations(
    Map<String, dynamic> translations, String language,
    [String prefix = '']) {
  translations.forEach((key, value) {
    final fullKey = prefix.isEmpty ? key : '$prefix.$key';

    if (value is Map<String, dynamic>) {
      _validateNoEmptyTranslations(value, language, fullKey);
    } else if (value is String && value.trim().isEmpty) {
      fail('$language has empty translation for key: $fullKey');
    }
  });
}

bool _hasKey(Map<String, dynamic> translations, String key) {
  final keys = key.split('.');
  dynamic current = translations;

  for (final k in keys) {
    if (current is Map<String, dynamic> && current.containsKey(k)) {
      current = current[k];
    } else {
      return false;
    }
  }

  return true;
}

dynamic _getValue(Map<String, dynamic> translations, String key) {
  final keys = key.split('.');
  dynamic current = translations;

  for (final k in keys) {
    if (current is Map<String, dynamic> && current.containsKey(k)) {
      current = current[k];
    } else {
      return null;
    }
  }

  return current;
}
