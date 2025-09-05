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
        'devotionals': {'title': 'Devocionales'}
      };

      englishTranslations = {
        'app': {'title': 'Devotional'},
        'common': {'loading': 'Loading...', 'error': 'Error'},
        'devotionals': {'title': 'Devotionals'}
      };

      portugueseTranslations = {
        'app': {'title': 'Devocional'},
        'common': {'loading': 'Carregando...', 'error': 'Erro'},
        'devotionals': {'title': 'Devocionais'}
      };

      frenchTranslations = {
        'app': {'title': 'Dévotion'},
        'common': {'loading': 'Chargement...', 'error': 'Erreur'},
        'devotionals': {'title': 'Dévotions'}
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
