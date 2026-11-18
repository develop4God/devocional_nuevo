@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/floating_font_control_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  final decrease = find.byKey(FloatingFontControlButtons.decreaseButtonKey);
  final increase = find.byKey(FloatingFontControlButtons.increaseButtonKey);

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await registerTestServices();
    await getService<LocalizationService>().initialize();
  });

  Future<void> pumpPanel(
    WidgetTester tester, {
    double fontSize = 16.0,
    String language = 'en',
    ValueChanged<double>? onSizeSelected,
    VoidCallback? onReset,
    VoidCallback? onClose,
    double textScale = 1.0,
  }) async {
    final locale = Locale(language);
    await tester.runAsync(
      () => getService<LocalizationService>().changeLocale(locale),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: [locale],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: Stack(
            children: [
              FloatingFontControlButtons(
                currentFontSize: fontSize,
                onSizeSelected: onSizeSelected ?? (_) {},
                onReset: onReset ?? () {},
                onClose: onClose ?? () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  double glyphSize(WidgetTester tester, Finder button) {
    final text = tester.widget<Text>(
      find.descendant(of: button, matching: find.byType(Text)),
    );
    return text.style!.fontSize!;
  }

  String glyphOf(WidgetTester tester, Finder button) => tester
      .widget<Text>(find.descendant(of: button, matching: find.byType(Text)))
      .data!;

  group('FloatingFontControlButtons', () {
    const glyphs = {
      'en': 'A',
      'es': 'A',
      'zh': '字',
      'ja': 'あ',
      'hi': 'अ',
      'ar': 'خط',
    };

    for (final entry in glyphs.entries) {
      testWidgets('renders the localized glyph for ${entry.key}', (t) async {
        await pumpPanel(t, language: entry.key);
        expect(glyphOf(t, decrease), entry.value);
        expect(glyphOf(t, increase), entry.value);
      });
    }

    testWidgets('decrease glyph is small and increase glyph is big', (
      t,
    ) async {
      await pumpPanel(t, fontSize: 24.0);
      expect(glyphSize(t, decrease), 18.0);
      expect(glyphSize(t, increase), 32.0);
    });

    testWidgets('buttons are 64dp circles', (t) async {
      await pumpPanel(t, fontSize: 24.0);
      expect(t.getSize(decrease), const Size(64, 64));
      expect(t.getSize(increase), const Size(64, 64));
    });

    testWidgets('shows the localized step name for the current size', (
      t,
    ) async {
      final names = {
        16.0: 'Normal',
        20.0: 'Large',
        24.0: 'Larger',
        28.0: 'Very large',
        32.0: 'Maximum',
      };
      for (final entry in names.entries) {
        await pumpPanel(t, fontSize: entry.key);
        expect(find.text(entry.value), findsOneWidget);
      }
    });

    testWidgets('shows the title and no sample text', (t) async {
      await pumpPanel(t);
      expect(find.text('Font size'), findsOneWidget);
    });

    testWidgets('legacy size 17 is displayed as the Normal step', (t) async {
      await pumpPanel(t, fontSize: 17.0);
      expect(find.text('Normal'), findsOneWidget);
      expect(t.widget<Slider>(find.byType(Slider)).value, 0.0);
    });

    testWidgets('decrease is disabled at the minimum stop', (t) async {
      await pumpPanel(t, fontSize: 16.0);
      expect(t.widget<FilledButton>(decrease).onPressed, isNull);
      expect(t.widget<FilledButton>(increase).onPressed, isNotNull);
    });

    testWidgets('increase is disabled at the maximum stop', (t) async {
      await pumpPanel(t, fontSize: 32.0);
      expect(t.widget<FilledButton>(increase).onPressed, isNull);
      expect(t.widget<FilledButton>(decrease).onPressed, isNotNull);
    });

    testWidgets('tapping increase selects the next stop', (t) async {
      final selected = <double>[];
      await pumpPanel(t, fontSize: 20.0, onSizeSelected: selected.add);
      await t.tap(increase);
      expect(selected, [24.0]);
    });

    testWidgets('tapping decrease selects the previous stop', (t) async {
      final selected = <double>[];
      await pumpPanel(t, fontSize: 20.0, onSizeSelected: selected.add);
      await t.tap(decrease);
      expect(selected, [16.0]);
    });

    testWidgets('slider has 5 stops and selecting one reports its size', (
      t,
    ) async {
      final selected = <double>[];
      await pumpPanel(t, fontSize: 16.0, onSizeSelected: selected.add);
      final slider = t.widget<Slider>(find.byType(Slider));
      expect(slider.divisions, 4);
      slider.onChanged!(3.0);
      expect(selected, [28.0]);
    });

    testWidgets('slider exposes a semantic label and value', (t) async {
      final handle = t.ensureSemantics();
      await pumpPanel(t, fontSize: 24.0);
      expect(
        t.getSemantics(find.byType(Slider)),
        matchesSemantics(
          label: 'Font size',
          value: 'Larger',
          hasEnabledState: true,
          isEnabled: true,
          isSlider: true,
          isFocusable: true,
          hasIncreaseAction: true,
          hasDecreaseAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('buttons and icons have localized tooltips', (t) async {
      await pumpPanel(t);
      expect(find.byTooltip('Decrease size'), findsOneWidget);
      expect(find.byTooltip('Increase size'), findsOneWidget);
      expect(find.byTooltip('Reset'), findsOneWidget);
      expect(find.byTooltip('Close'), findsOneWidget);
    });

    testWidgets('reset and close callbacks fire', (t) async {
      var resets = 0;
      var closes = 0;
      await pumpPanel(
        t,
        fontSize: 28.0,
        onReset: () => resets++,
        onClose: () => closes++,
      );
      await t.tap(find.byIcon(Icons.undo));
      expect(resets, 1);
      await t.tap(find.byIcon(Icons.close));
      expect(closes, 1);
    });

    testWidgets('tapping outside the panel closes it', (t) async {
      var closes = 0;
      await pumpPanel(t, onClose: () => closes++);
      await t.tapAt(const Offset(10, 10));
      expect(closes, 1);
    });

    testWidgets('touch targets are at least 56dp', (t) async {
      await pumpPanel(t);
      for (final icon in [Icons.undo, Icons.close]) {
        final size = t.getSize(
          find.ancestor(
              of: find.byIcon(icon), matching: find.byType(IconButton)),
        );
        expect(size.width, greaterThanOrEqualTo(56));
        expect(size.height, greaterThanOrEqualTo(56));
      }
    });

    testWidgets('RTL (ar) places decrease to the right of increase', (
      t,
    ) async {
      await pumpPanel(t, language: 'ar', fontSize: 24.0);
      expect(
        t.getCenter(decrease).dx,
        greaterThan(t.getCenter(increase).dx),
      );
    });

    testWidgets('Arabic RTL with 1.5x text scale has no overflow', (t) async {
      await pumpPanel(t, language: 'ar', fontSize: 28.0, textScale: 1.5);
      expect(t.takeException(), isNull);
    });

    testWidgets('title and step name share one line, close together',
        (t) async {
      await pumpPanel(t, fontSize: 16.0);
      final title = t.getRect(find.text('Font size'));
      final step = t.getRect(find.text('Normal'));
      expect(title.height, lessThan(30), reason: 'title must not wrap');
      expect((title.center.dy - step.center.dy).abs(), lessThan(4));
      expect(step.left - title.right, lessThan(16));
    });

    testWidgets('title stays on one line on a narrow screen', (t) async {
      t.view.physicalSize = const Size(360, 800);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.reset);
      await pumpPanel(t, fontSize: 16.0, textScale: 1.3);
      final text = t.widget<Text>(find.text('Font size'));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(t.getSize(find.text('Font size')).height, lessThan(40));
      expect(t.takeException(), isNull);
    });

    testWidgets('German at 1.5x text scale has no overflow', (t) async {
      await pumpPanel(t, language: 'de', fontSize: 28.0, textScale: 1.5);
      expect(t.takeException(), isNull);
    });

    testWidgets('LTR (en) places decrease to the left of increase', (t) async {
      await pumpPanel(t, fontSize: 24.0);
      expect(t.getCenter(decrease).dx, lessThan(t.getCenter(increase).dx));
    });

    testWidgets('app bar icon is A+ for Latin languages', (t) async {
      await pumpPanel(t, language: 'en');
      expect(
        FloatingFontControlButtons.appBarIcon(),
        Icons.text_increase_outlined,
      );
    });

    for (final lang in ['hi', 'ar', 'ja', 'zh']) {
      testWidgets('app bar icon avoids Latin A+ for $lang', (t) async {
        await pumpPanel(t, language: lang);
        expect(FloatingFontControlButtons.appBarIcon(), Icons.zoom_in);
      });
    }

    testWidgets('panel has a primary-colored border', (t) async {
      await pumpPanel(t);
      final material = t.widget<Material>(
        find
            .descendant(
              of: find.byType(FloatingFontControlButtons),
              matching: find.byType(Material),
            )
            .first,
      );
      final shape = material.shape! as RoundedRectangleBorder;
      final primary =
          Theme.of(t.element(find.byType(Scaffold))).colorScheme.primary;
      expect(shape.side.color, primary);
      expect(shape.side.width, greaterThanOrEqualTo(2));
      expect(material.shadowColor, primary);
    });
  });
}
