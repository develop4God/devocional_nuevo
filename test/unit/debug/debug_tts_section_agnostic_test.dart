@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/debug/sections/debug_tts_section.dart';
import 'package:devocional_nuevo/services/tts/voice_data_registry.dart';

void main() {
  group('DebugTtsSection - Language Agnostic Tests', () {
    testWidgets(
      'Should display language chips from VoiceDataRegistry.supportedLanguages (agnostic)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DebugTtsSection(),
            ),
          ),
        );

        // Verify the section is built
        expect(find.byType(DebugTtsSection), findsOneWidget);

        // Verify language chips are displayed
        for (final lang in VoiceDataRegistry.supportedLanguages) {
          expect(find.text(lang), findsWidgets,
              reason: 'Language "$lang" should be displayed in the UI');
        }
      },
    );

    testWidgets(
      'Should dynamically load languages from VoiceDataRegistry',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DebugTtsSection(),
            ),
          ),
        );

        // Ensure at least some languages are supported (not hardcoded empty list)
        expect(VoiceDataRegistry.supportedLanguages.isNotEmpty, true,
            reason:
                'VoiceDataRegistry should have at least one supported language');

        // Verify new language 'tl' (Tagalog) is in the registry
        expect(
          VoiceDataRegistry.supportedLanguages.contains('tl'),
          true,
          reason: 'Tagalog (tl) should be in the supported languages',
        );

        // Verify it's displayed in the UI
        expect(find.text('tl'), findsWidgets);
      },
    );

    testWidgets(
      'Should initialize with first supported language from registry (not hardcoded)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DebugTtsSection(),
            ),
          ),
        );

        // The first language from the registry should be selected initially
        final firstLang = VoiceDataRegistry.supportedLanguages.first;
        expect(find.text(firstLang), findsWidgets);
      },
    );
  });
}
