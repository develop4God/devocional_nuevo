// test/unit/translation_validation_test.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Translation Validation Tests', () {
    late Map<String, dynamic> spanishTranslations;
    late Map<String, dynamic> englishTranslations;
    late Map<String, dynamic> portugueseTranslations;
    late Map<String, dynamic> frenchTranslations;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      try {
        // Load all translation files directly from file system if possible
        final directory = Directory.current;
        final spanishFile =
            File('${directory.path}/assets/translations/es.json');
        final englishFile =
            File('${directory.path}/assets/translations/en.json');
        final portugueseFile =
            File('${directory.path}/assets/translations/pt.json');
        final frenchFile =
            File('${directory.path}/assets/translations/fr.json');

        if (await spanishFile.exists()) {
          final spanishJson = await spanishFile.readAsString();
          final englishJson = await englishFile.readAsString();
          final portugueseJson = await portugueseFile.readAsString();
          final frenchJson = await frenchFile.readAsString();

          spanishTranslations = json.decode(spanishJson);
          englishTranslations = json.decode(englishJson);
          portugueseTranslations = json.decode(portugueseJson);
          frenchTranslations = json.decode(frenchJson);
        } else {
          throw Exception('Files not found, falling back to rootBundle');
        }
      } catch (e) {
        // Fallback to rootBundle if file system access fails
        final spanishJson =
            await rootBundle.loadString('assets/translations/es.json');
        final englishJson =
            await rootBundle.loadString('assets/translations/en.json');
        final portugueseJson =
            await rootBundle.loadString('assets/translations/pt.json');
        final frenchJson =
            await rootBundle.loadString('assets/translations/fr.json');

        spanishTranslations = json.decode(spanishJson);
        englishTranslations = json.decode(englishJson);
        portugueseTranslations = json.decode(portugueseJson);
        frenchTranslations = json.decode(frenchJson);
      }
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

    test('Spanish translations should contain all required sections', () {
      expect(spanishTranslations, contains('app'));
      expect(spanishTranslations, contains('devotionals'));
      expect(spanishTranslations, contains('prayer'));
      expect(spanishTranslations, contains('settings'));
      expect(spanishTranslations, contains('navigation'));
      expect(spanishTranslations, contains('drawer'));
      expect(spanishTranslations, contains('stats'));
      expect(spanishTranslations, contains('errors'));
      expect(spanishTranslations, contains('messages'));
      expect(spanishTranslations, contains('favorites'));
      expect(spanishTranslations, contains('contact'));
      expect(spanishTranslations, contains('sharing'));
      expect(spanishTranslations, contains('download'));
      expect(spanishTranslations, contains('about'));
    });

    test('Settings section should have all required keys', () {
      final settings = spanishTranslations['settings'] as Map<String, dynamic>;

      expect(settings, contains('title'));
      expect(settings, contains('language'));
      expect(settings, contains('language_changed'));
      expect(settings, contains('bible_version'));
      expect(settings, contains('version_changed'));
      expect(settings, contains('donate'));
      expect(settings, contains('contact_us'));
      expect(settings, contains('about_app'));
      expect(settings, contains('paypal_launch_error'));
      expect(settings, contains('paypal_error'));
      expect(settings, contains('paypal_no_app_error'));
    });

    test('Favorites section should have all required keys', () {
      final favorites =
          spanishTranslations['favorites'] as Map<String, dynamic>;

      expect(favorites, contains('title'));
      expect(favorites, contains('empty_title'));
      expect(favorites, contains('empty_description'));
      expect(favorites, contains('remove_tooltip'));
      expect(favorites, contains('removed_message'));
    });

    test('Contact section should have all required keys', () {
      final contact = spanishTranslations['contact'] as Map<String, dynamic>;

      expect(contact, contains('bugs'));
      expect(contact, contains('feedback'));
      expect(contact, contains('improvements'));
      expect(contact, contains('other'));
      expect(contact, contains('select_type_error'));
      expect(contact, contains('enter_message_error'));
      expect(contact, contains('email_subject'));
    });

    test('Prayer section should have all required keys', () {
      final prayer = spanishTranslations['prayer'] as Map<String, dynamic>;

      expect(prayer, contains('invitation_title'));
      expect(prayer, contains('invitation_message'));
      expect(prayer, contains('invitation_content'));
      expect(prayer, contains('pray_now'));
      expect(prayer, contains('maybe_later'));
      expect(prayer, contains('dont_show_again'));
      expect(prayer, contains('already_prayed'));
      expect(prayer, contains('prayer_time'));
      expect(prayer, contains('praying'));
    });

    test('About section should have all required keys', () {
      final about = spanishTranslations['about'] as Map<String, dynamic>;

      expect(about, contains('title'));
      expect(about, contains('app_name'));
      expect(about, contains('version'));
      expect(about, contains('loading_version'));
      expect(about, contains('description'));
      expect(about, contains('main_features'));
      expect(about, contains('developed_by'));
      expect(about, contains('terms_copyright'));
      expect(about, contains('link_error'));
    });

    test('All translation values should be non-empty strings', () {
      _validateAllValuesAreNonEmpty(spanishTranslations, 'Spanish');
      _validateAllValuesAreNonEmpty(englishTranslations, 'English');
      _validateAllValuesAreNonEmpty(portugueseTranslations, 'Portuguese');
      _validateAllValuesAreNonEmpty(frenchTranslations, 'French');
    });

    test('All languages should support parameter interpolation correctly', () {
      // Test parameter interpolation format
      final testCases = [
        'settings.paypal_error',
        'favorites.removed_message',
        'contact.email_subject'
      ];

      for (final testCase in testCases) {
        final spanishValue = _getNestedValue(spanishTranslations, testCase);
        final englishValue = _getNestedValue(englishTranslations, testCase);
        final portugueseValue =
            _getNestedValue(portugueseTranslations, testCase);
        final frenchValue = _getNestedValue(frenchTranslations, testCase);

        expect(spanishValue, contains('{'),
            reason: 'Spanish $testCase should contain parameter placeholder');
        expect(englishValue, contains('{'),
            reason: 'English $testCase should contain parameter placeholder');
        expect(portugueseValue, contains('{'),
            reason:
                'Portuguese $testCase should contain parameter placeholder');
        expect(frenchValue, contains('{'),
            reason: 'French $testCase should contain parameter placeholder');
      }
    });
  });
}

/// Recursively gets all translation keys as a flattened set
Set<String> _getAllKeys(Map<String, dynamic> translations,
    [String prefix = '']) {
  final keys = <String>{};

  for (final entry in translations.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';

    if (entry.value is Map<String, dynamic>) {
      keys.addAll(_getAllKeys(entry.value as Map<String, dynamic>, key));
    } else {
      keys.add(key);
    }
  }

  return keys;
}

/// Gets a nested value using dot notation (e.g., 'settings.title')
String _getNestedValue(Map<String, dynamic> translations, String key) {
  final parts = key.split('.');
  dynamic current = translations;

  for (final part in parts) {
    if (current is Map<String, dynamic> && current.containsKey(part)) {
      current = current[part];
    } else {
      throw Exception('Key $key not found in translations');
    }
  }

  return current.toString();
}

/// Validates that all translation values are non-empty strings
void _validateAllValuesAreNonEmpty(
    Map<String, dynamic> translations, String languageName,
    [String prefix = '']) {
  for (final entry in translations.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';

    if (entry.value is Map<String, dynamic>) {
      _validateAllValuesAreNonEmpty(
          entry.value as Map<String, dynamic>, languageName, key);
    } else {
      expect(entry.value, isA<String>(),
          reason: '$languageName translation key $key should be a string');
      expect(entry.value.toString().trim(), isNotEmpty,
          reason: '$languageName translation key $key should not be empty');
    }
  }
}
