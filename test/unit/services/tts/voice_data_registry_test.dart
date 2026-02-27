import 'package:devocional_nuevo/services/tts/voice_data_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceDataRegistry', () {
    group('supportedLanguages', () {
      test('includes all 7 supported languages', () {
        final languages = VoiceDataRegistry.supportedLanguages;
        expect(
            languages, containsAll(['es', 'en', 'pt', 'fr', 'ja', 'zh', 'hi']));
        expect(languages.length, 7);
      });
    });

    group('getVoiceMap', () {
      test('returns non-null map for all supported languages', () {
        for (final lang in VoiceDataRegistry.supportedLanguages) {
          expect(
            VoiceDataRegistry.getVoiceMap(lang),
            isNotNull,
            reason: 'Missing voice map for $lang',
          );
        }
      });

      test('returns null for unsupported language', () {
        expect(VoiceDataRegistry.getVoiceMap('xx'), isNull);
        expect(VoiceDataRegistry.getVoiceMap(''), isNull);
      });

      test('Spanish has 4 premium voices', () {
        expect(VoiceDataRegistry.spanishVoices.length, 4);
      });

      test('English has 6 premium voices', () {
        expect(VoiceDataRegistry.englishVoices.length, 6);
      });

      test('Hindi has premium voices with India flag', () {
        final hindiVoices = VoiceDataRegistry.hindiVoices;
        expect(hindiVoices, isNotEmpty);
        for (final entry in hindiVoices.entries) {
          expect(entry.value.emoji, '🇮🇳',
              reason: 'Hindi voice ${entry.key} should use India flag');
        }
      });
    });

    group('isPremiumVoice', () {
      test('returns true for known Spanish premium voice', () {
        expect(
          VoiceDataRegistry.isPremiumVoice('es-us-x-esd-local', 'es'),
          isTrue,
        );
      });

      test('returns false for unknown voice name', () {
        expect(
          VoiceDataRegistry.isPremiumVoice('unknown-voice', 'es'),
          isFalse,
        );
      });

      test('returns false for unsupported language', () {
        expect(
          VoiceDataRegistry.isPremiumVoice('es-us-x-esd-local', 'xx'),
          isFalse,
        );
      });

      test('returns true for Hindi premium voices', () {
        expect(
          VoiceDataRegistry.isPremiumVoice('hi-in-x-hid-local', 'hi'),
          isTrue,
        );
        expect(
          VoiceDataRegistry.isPremiumVoice('hi-IN-language', 'hi'),
          isTrue,
        );
      });
    });

    group('getVoiceMetadata', () {
      test('returns metadata for known English male voice', () {
        final meta = VoiceDataRegistry.getVoiceMetadata(
          'en-us-x-tpd-network',
          'en',
        );
        expect(meta, isNotNull);
        expect(meta!.emoji, '🇺🇸');
        expect(meta.description, 'Male United States');
        expect(meta.genderIcon, Icons.man_3_outlined);
      });

      test('returns metadata for known English female voice', () {
        final meta = VoiceDataRegistry.getVoiceMetadata(
          'en-us-x-tpf-local',
          'en',
        );
        expect(meta, isNotNull);
        expect(meta!.genderIcon, Icons.woman_outlined);
      });

      test('returns null for unknown voice', () {
        expect(
          VoiceDataRegistry.getVoiceMetadata('nonexistent', 'en'),
          isNull,
        );
      });

      test('returns Hindi metadata with Devanagari descriptions', () {
        final meta = VoiceDataRegistry.getVoiceMetadata(
          'hi-in-x-hid-local',
          'hi',
        );
        expect(meta, isNotNull);
        expect(meta!.description, contains('पुरुष')); // Male in Hindi
        expect(meta.description, contains('भारत')); // India in Hindi
      });

      test('all voices have non-empty descriptions', () {
        for (final lang in VoiceDataRegistry.supportedLanguages) {
          final map = VoiceDataRegistry.getVoiceMap(lang)!;
          for (final entry in map.entries) {
            expect(
              entry.value.description,
              isNotEmpty,
              reason: 'Voice ${entry.key} ($lang) has empty description',
            );
          }
        }
      });
    });

    group('getSampleText', () {
      test('returns Spanish text for es', () {
        final text = VoiceDataRegistry.getSampleText('es');
        expect(text, contains('Puede guardar esta voz'));
      });

      test('returns English text for en', () {
        final text = VoiceDataRegistry.getSampleText('en');
        expect(text, contains('You can save this voice'));
      });

      test('returns Hindi text for hi', () {
        final text = VoiceDataRegistry.getSampleText('hi');
        expect(text, contains('आवाज़'));
      });

      test('returns Spanish fallback for unknown language', () {
        final text = VoiceDataRegistry.getSampleText('xx');
        expect(text, VoiceDataRegistry.getSampleText('es'));
      });

      test('all supported languages have sample text', () {
        for (final lang in VoiceDataRegistry.supportedLanguages) {
          expect(
            VoiceDataRegistry.sampleTexts.containsKey(lang),
            isTrue,
            reason: 'Missing sample text for $lang',
          );
        }
      });
    });

    group('getPriorityLocales', () {
      test('returns priority locales for Spanish', () {
        final locales = VoiceDataRegistry.getPriorityLocales('es');
        expect(locales, contains('es-ES'));
        expect(locales, contains('es-US'));
      });

      test('returns priority locales for Hindi', () {
        final locales = VoiceDataRegistry.getPriorityLocales('hi');
        expect(locales, contains('hi-IN'));
      });

      test('returns empty list for unsupported language', () {
        expect(VoiceDataRegistry.getPriorityLocales('xx'), isEmpty);
      });

      test('all supported languages have priority locales', () {
        for (final lang in VoiceDataRegistry.supportedLanguages) {
          expect(
            VoiceDataRegistry.getPriorityLocales(lang),
            isNotEmpty,
            reason: 'Missing priority locales for $lang',
          );
        }
      });
    });

    group('voice metadata consistency', () {
      test('all premium voices have valid gender icons', () {
        final validIcons = [
          Icons.man_3_outlined,
          Icons.woman_outlined,
          Icons.person
        ];
        for (final lang in VoiceDataRegistry.supportedLanguages) {
          final map = VoiceDataRegistry.getVoiceMap(lang)!;
          for (final entry in map.entries) {
            expect(
              validIcons.contains(entry.value.genderIcon),
              isTrue,
              reason: 'Voice ${entry.key} ($lang) has invalid gender icon',
            );
          }
        }
      });

      test('all premium voices have non-empty emoji', () {
        for (final lang in VoiceDataRegistry.supportedLanguages) {
          final map = VoiceDataRegistry.getVoiceMap(lang)!;
          for (final entry in map.entries) {
            expect(
              entry.value.emoji,
              isNotEmpty,
              reason: 'Voice ${entry.key} ($lang) has empty emoji',
            );
          }
        }
      });
    });
  });
}
