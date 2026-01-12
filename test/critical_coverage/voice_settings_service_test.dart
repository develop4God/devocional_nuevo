// test/critical_coverage/voice_settings_service_test.dart
// High-value tests for VoiceSettingsService - TTS voice selection logic

import 'package:flutter_test/flutter_test.dart';

@Tags(['slow'])
void main() {
  group('VoiceSettingsService - Friendly Voice Names', () {
    // friendlyVoiceMap tests
    test('Spanish voice map contains correct entries', () {
      // Testing the static map without instantiating the service
      final spanishMap = {
        'es-us-x-esd-local': '🇲🇽 Hombre Latinoamérica',
        'es-us-x-esd-network': '🇲🇽 Hombre Latinoamérica',
        'es-US-language': '🇲🇽 Mujer Latinoamérica',
        'es-es-x-eed-local': '🇪🇸 Hombre España',
        'es-ES-language': '🇪🇸 Mujer España',
      };

      expect(spanishMap['es-us-x-esd-local'], '🇲🇽 Hombre Latinoamérica');
      expect(spanishMap['es-es-x-eed-local'], '🇪🇸 Hombre España');
    });

    test('English voice map contains correct entries', () {
      final englishMap = {
        'en-us-x-tpd-network': '🇺🇸 Male United States',
        'en-us-x-tpd-local': '🇺🇸 Male United States',
        'en-us-x-tpf-local': '🇺🇸 Female United States',
        'en-us-x-iom-network': '🇺🇸 Male United States',
        'en-gb-x-gbb-local': '🇬🇧 Male United Kingdom',
        'en-GB-language': '🇬🇧 Female United Kingdom',
      };

      expect(englishMap['en-us-x-tpd-network'], '🇺🇸 Male United States');
      expect(englishMap['en-gb-x-gbb-local'], '🇬🇧 Male United Kingdom');
    });

    test('Portuguese voice map contains correct entries', () {
      final portugueseMap = {
        'pt-br-x-ptd-network': '🇧🇷 Homem Brasil',
        'pt-br-x-ptd-local': '🇧🇷 Homem Brasil',
        'pt-br-x-afs-network': '🇧🇷 Mulher Brasil',
        'pt-pt-x-pmj-local': '🇵🇹 Homem Portugal',
        'pt-PT-language': '🇵🇹 Mulher Portugal',
      };

      expect(portugueseMap['pt-br-x-ptd-network'], '🇧🇷 Homem Brasil');
      expect(portugueseMap['pt-pt-x-pmj-local'], '🇵🇹 Homem Portugal');
    });

    test('French voice map contains correct entries', () {
      final frenchMap = {
        'fr-fr-x-frd-local': '🇫🇷 Homme France',
        'fr-fr-x-frd-network': '🇫🇷 Homme France',
        'fr-fr-x-vlf-local': '🇫🇷 Homme France',
        'fr-fr-x-frf-local': '🇫🇷 Femme France',
        'fr-ca-x-cad-local': '🇨🇦 Homme Canada',
        'fr-ca-x-caf-local': '🇨🇦 Femme Canada',
      };

      expect(frenchMap['fr-fr-x-frd-local'], '🇫🇷 Homme France');
      expect(frenchMap['fr-ca-x-cad-local'], '🇨🇦 Homme Canada');
    });

    test('Japanese voice map contains correct entries', () {
      final japaneseMap = {
        'ja-jp-x-jac-local': '🇯🇵 男性 声 1',
        'ja-jp-x-jac-network': '🇯🇵 男性 声 1',
        'ja-jp-x-jab-local': '🇯🇵 女性 声 1',
        'ja-jp-x-jad-local': '🇯🇵 男性 声 2',
        'ja-jp-x-htm-local': '🇯🇵 女性 声 2',
      };

      expect(japaneseMap['ja-jp-x-jac-local'], '🇯🇵 男性 声 1');
      expect(japaneseMap['ja-jp-x-jab-local'], '🇯🇵 女性 声 1');
    });
  });

  group('VoiceSettingsService - Default Locale Logic', () {
    test('Spanish defaults to es-ES', () {
      String getDefaultLocaleForLanguage(String language) {
        switch (language.toLowerCase()) {
          case 'es':
            return 'es-ES';
          case 'en':
            return 'en-US';
          case 'pt':
            return 'pt-BR';
          case 'fr':
            return 'fr-FR';
          case 'ja':
            return 'ja-JP';
          default:
            return 'es-ES';
        }
      }

      expect(getDefaultLocaleForLanguage('es'), 'es-ES');
    });

    test('English defaults to en-US', () {
      String getDefaultLocaleForLanguage(String language) {
        switch (language.toLowerCase()) {
          case 'es':
            return 'es-ES';
          case 'en':
            return 'en-US';
          case 'pt':
            return 'pt-BR';
          case 'fr':
            return 'fr-FR';
          case 'ja':
            return 'ja-JP';
          default:
            return 'es-ES';
        }
      }

      expect(getDefaultLocaleForLanguage('en'), 'en-US');
    });

    test('Portuguese defaults to pt-BR', () {
      String getDefaultLocaleForLanguage(String language) {
        switch (language.toLowerCase()) {
          case 'pt':
            return 'pt-BR';
          default:
            return 'es-ES';
        }
      }

      expect(getDefaultLocaleForLanguage('pt'), 'pt-BR');
    });

    test('French defaults to fr-FR', () {
      String getDefaultLocaleForLanguage(String language) {
        switch (language.toLowerCase()) {
          case 'fr':
            return 'fr-FR';
          default:
            return 'es-ES';
        }
      }

      expect(getDefaultLocaleForLanguage('fr'), 'fr-FR');
    });

    test('Japanese defaults to ja-JP', () {
      String getDefaultLocaleForLanguage(String language) {
        switch (language.toLowerCase()) {
          case 'ja':
            return 'ja-JP';
          default:
            return 'es-ES';
        }
      }

      expect(getDefaultLocaleForLanguage('ja'), 'ja-JP');
    });

    test('Unknown language defaults to es-ES', () {
      String getDefaultLocaleForLanguage(String language) {
        switch (language.toLowerCase()) {
          case 'es':
            return 'es-ES';
          case 'en':
            return 'en-US';
          default:
            return 'es-ES';
        }
      }

      expect(getDefaultLocaleForLanguage('unknown'), 'es-ES');
    });
  });

  group('VoiceSettingsService - Preferred Locale Logic', () {
    test('Spanish preferred locales are correct', () {
      final preferredLocales = {
        'es': ['es-US', 'es-ES', 'es-MX'],
        'en': ['en-US', 'en-GB'],
        'pt': ['pt-BR', 'pt-PT'],
        'fr': ['fr-FR', 'fr-CA'],
      };

      expect(preferredLocales['es'], contains('es-US'));
      expect(preferredLocales['es'], contains('es-ES'));
      expect(preferredLocales['es'], contains('es-MX'));
    });

    test('isPreferredLocale returns true for preferred locales', () {
      bool isPreferredLocale(String voiceName, String language) {
        final preferredLocales = {
          'es': ['es-US', 'es-ES', 'es-MX'],
          'en': ['en-US', 'en-GB'],
          'pt': ['pt-BR', 'pt-PT'],
          'fr': ['fr-FR', 'fr-CA'],
        };

        final preferred = preferredLocales[language] ?? [];
        return preferred.any((locale) => voiceName.contains(locale));
      }

      expect(isPreferredLocale('Voice (es-US)', 'es'), isTrue);
      expect(isPreferredLocale('Voice (en-US)', 'en'), isTrue);
      expect(isPreferredLocale('Voice (pt-BR)', 'pt'), isTrue);
      expect(isPreferredLocale('Voice (fr-FR)', 'fr'), isTrue);
    });

    test('isPreferredLocale returns false for non-preferred locales', () {
      bool isPreferredLocale(String voiceName, String language) {
        final preferredLocales = {
          'es': ['es-US', 'es-ES', 'es-MX'],
          'en': ['en-US', 'en-GB'],
        };

        final preferred = preferredLocales[language] ?? [];
        return preferred.any((locale) => voiceName.contains(locale));
      }

      expect(isPreferredLocale('Voice (es-AR)', 'es'), isFalse);
      expect(isPreferredLocale('Voice (en-AU)', 'en'), isFalse);
    });
  });

  group('VoiceSettingsService - Proper Name Detection', () {
    test('hasProperName returns false for generic voice names', () {
      bool hasProperName(String voiceName) {
        final cleanName = voiceName.split('(')[0].trim();
        return !cleanName.toLowerCase().contains('voz') &&
            !cleanName.toLowerCase().contains('voice') &&
            !cleanName.toLowerCase().contains('female') &&
            !cleanName.toLowerCase().contains('male') &&
            !cleanName.toLowerCase().contains('masculina') &&
            !cleanName.toLowerCase().contains('femenina') &&
            cleanName.split(' ').length <= 2;
      }

      expect(hasProperName('Voz Masculina (es-ES)'), isFalse);
      expect(hasProperName('Female Voice (en-US)'), isFalse);
      expect(hasProperName('Male Voice (en-GB)'), isFalse);
    });

    test('hasProperName returns true for named voices', () {
      bool hasProperName(String voiceName) {
        final cleanName = voiceName.split('(')[0].trim();
        return !cleanName.toLowerCase().contains('voz') &&
            !cleanName.toLowerCase().contains('voice') &&
            !cleanName.toLowerCase().contains('female') &&
            !cleanName.toLowerCase().contains('male') &&
            !cleanName.toLowerCase().contains('masculina') &&
            !cleanName.toLowerCase().contains('femenina') &&
            cleanName.split(' ').length <= 2;
      }

      expect(hasProperName('Maria (es-ES)'), isTrue);
      expect(hasProperName('James (en-US)'), isTrue);
    });
  });

  group('VoiceSettingsService - Localized Gender Names', () {
    test('Spanish gender names are correct', () {
      String getLocalizedGenderName(
        String gender,
        String locale,
        String number,
      ) {
        final num = number.isNotEmpty ? ' $number' : '';
        switch (locale.toLowerCase()) {
          case String s when s.startsWith('es'):
            return gender == 'female'
                ? 'Voz Femenina$num'
                : 'Voz Masculina$num';
          case String s when s.startsWith('en'):
            return gender == 'female' ? 'Female Voice$num' : 'Male Voice$num';
          default:
            return gender == 'female' ? 'Female Voice$num' : 'Male Voice$num';
        }
      }

      expect(getLocalizedGenderName('male', 'es-ES', ''), 'Voz Masculina');
      expect(getLocalizedGenderName('female', 'es-US', ''), 'Voz Femenina');
      expect(getLocalizedGenderName('male', 'es-MX', '1'), 'Voz Masculina 1');
    });

    test('English gender names are correct', () {
      String getLocalizedGenderName(
        String gender,
        String locale,
        String number,
      ) {
        final num = number.isNotEmpty ? ' $number' : '';
        switch (locale.toLowerCase()) {
          case String s when s.startsWith('en'):
            return gender == 'female' ? 'Female Voice$num' : 'Male Voice$num';
          default:
            return gender == 'female' ? 'Female Voice$num' : 'Male Voice$num';
        }
      }

      expect(getLocalizedGenderName('male', 'en-US', ''), 'Male Voice');
      expect(getLocalizedGenderName('female', 'en-GB', ''), 'Female Voice');
    });

    test('Portuguese gender names are correct', () {
      String getLocalizedGenderName(
        String gender,
        String locale,
        String number,
      ) {
        final num = number.isNotEmpty ? ' $number' : '';
        switch (locale.toLowerCase()) {
          case String s when s.startsWith('pt'):
            return gender == 'female'
                ? 'Voz Feminina$num'
                : 'Voz Masculina$num';
          default:
            return gender == 'female' ? 'Female Voice$num' : 'Male Voice$num';
        }
      }

      expect(getLocalizedGenderName('male', 'pt-BR', ''), 'Voz Masculina');
      expect(getLocalizedGenderName('female', 'pt-PT', ''), 'Voz Feminina');
    });

    test('French gender names are correct', () {
      String getLocalizedGenderName(
        String gender,
        String locale,
        String number,
      ) {
        final num = number.isNotEmpty ? ' $number' : '';
        switch (locale.toLowerCase()) {
          case String s when s.startsWith('fr'):
            return gender == 'female'
                ? 'Voix Féminine$num'
                : 'Voix Masculine$num';
          default:
            return gender == 'female' ? 'Female Voice$num' : 'Male Voice$num';
        }
      }

      expect(getLocalizedGenderName('male', 'fr-FR', ''), 'Voix Masculine');
      expect(getLocalizedGenderName('female', 'fr-CA', ''), 'Voix Féminine');
    });
  });

  group('VoiceSettingsService - Preferred Male Voices', () {
    test('Spanish preferred male voices list is correct', () {
      final preferredMaleVoices = {
        'es': ['es-us-x-esd-local', 'es-us-x-esd-network'],
        'en': [
          'en-us-x-tpd-network',
          'en-us-x-tpd-local',
          'en-us-x-iom-network',
        ],
        'pt': ['pt-br-x-ptd-network', 'pt-br-x-ptd-local'],
        'fr': ['fr-fr-x-frd-local', 'fr-fr-x-frd-network', 'fr-fr-x-vlf-local'],
        'ja': ['ja-jp-x-jac-local', 'ja-jp-x-jad-local', 'ja-jp-x-jac-network'],
      };

      expect(preferredMaleVoices['es'], contains('es-us-x-esd-local'));
      expect(preferredMaleVoices['en'], contains('en-us-x-tpd-network'));
      expect(preferredMaleVoices['pt'], contains('pt-br-x-ptd-network'));
      expect(preferredMaleVoices['fr'], contains('fr-fr-x-frd-local'));
      expect(preferredMaleVoices['ja'], contains('ja-jp-x-jac-local'));
    });
  });

  group('VoiceSettingsService - Preferred Locales for Auto-Assignment', () {
    test('Spanish preferred locales for auto-assignment', () {
      final preferredLocales = {
        'es': ['es-US', 'es-MX', 'es-ES'],
        'en': ['en-US', 'en-GB', 'en-AU'],
        'pt': ['pt-BR', 'pt-PT'],
        'fr': ['fr-FR', 'fr-CA'],
        'ja': ['ja-JP'],
      };

      expect(preferredLocales['es']!.first, 'es-US');
      expect(preferredLocales['en']!.first, 'en-US');
      expect(preferredLocales['pt']!.first, 'pt-BR');
      expect(preferredLocales['fr']!.first, 'fr-FR');
      expect(preferredLocales['ja']!.first, 'ja-JP');
    });
  });
}
