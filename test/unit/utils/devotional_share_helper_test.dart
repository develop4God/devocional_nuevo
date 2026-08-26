@Tags(['unit', 'utils'])
library;

// test/unit/utils/devotional_share_helper_test.dart

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/utils/devotional_share_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

void main() {
  Devocional buildDevocional({
    List<ParaMeditar> paraMeditar = const [],
    String reflexion = 'Una reflexión profunda.',
    String oracion = 'Señor, guíanos hoy.',
  }) {
    return Devocional(
      id: 'dev-1',
      versiculo: 'Juan 3:16',
      reflexion: reflexion,
      paraMeditar: paraMeditar,
      oracion: oracion,
      date: DateTime(2026, 1, 1),
    );
  }

  group('DevotionalShareHelper.generarTextoParaCompartir', () {
    test('includes verse, reflection, and prayer content', () {
      final devocional = buildDevocional();

      final text = DevotionalShareHelper.generarTextoParaCompartir(
        devocional,
      );

      expect(text, contains('Juan 3:16'));
      expect(text, contains('Una reflexión profunda.'));
      expect(text, contains('Señor, guíanos hoy.'));
    });

    test('includes the download link and package id', () {
      final text = DevotionalShareHelper.generarTextoParaCompartir(
        buildDevocional(),
      );

      expect(
        text,
        contains(
          'https://play.google.com/store/apps/details?id=com.develop4god.devocional_nuevo',
        ),
      );
    });

    test('omits meditation section when paraMeditar is empty', () {
      final text = DevotionalShareHelper.generarTextoParaCompartir(
        buildDevocional(paraMeditar: []),
      );

      expect(text, isNot(contains('📌')));
    });

    test('includes each meditation citation and text when present', () {
      final devocional = buildDevocional(
        paraMeditar: [
          ParaMeditar(cita: 'Salmos 23:1', texto: 'El Señor es mi pastor.'),
          ParaMeditar(cita: 'Salmos 23:4', texto: 'No temeré mal alguno.'),
        ],
      );

      final text = DevotionalShareHelper.generarTextoParaCompartir(
        devocional,
      );

      expect(text, contains('Salmos 23:1'));
      expect(text, contains('El Señor es mi pastor.'));
      expect(text, contains('Salmos 23:4'));
      expect(text, contains('No temeré mal alguno.'));
    });

    test('collapses triple line breaks in reflection and prayer', () {
      final devocional = buildDevocional(
        reflexion: 'Primera línea.\n\n\nSegunda línea.',
        oracion: 'Oración uno.\n\n\nOración dos.',
      );

      final text = DevotionalShareHelper.generarTextoParaCompartir(
        devocional,
      );

      expect(text, isNot(contains('\n\n\n')));
      expect(text, contains('Primera línea.\n\nSegunda línea.'));
      expect(text, contains('Oración uno.\n\nOración dos.'));
    });

    test(
        'falls back to Spanish default text when localization service is '
        'unavailable', () {
      final text = DevotionalShareHelper.generarTextoParaCompartir(
        buildDevocional(),
      );

      expect(text, contains('Devocional del día'));
      expect(text, contains('Versículo:'));
      expect(text, contains('Reflexión:'));
      expect(text, contains('Oración:'));
    });

    group('with localization service registered', () {
      setUp(() async {
        TestWidgetsFlutterBinding.ensureInitialized();
        SharedPreferences.setMockInitialValues({});
        await registerTestServices();
      });

      test('still produces non-empty shareable text', () {
        final text = DevotionalShareHelper.generarTextoParaCompartir(
          buildDevocional(),
        );

        expect(text, isNotEmpty);
        expect(text, contains('Juan 3:16'));
        expect(
          text,
          contains(
            'https://play.google.com/store/apps/details?id=com.develop4god.devocional_nuevo',
          ),
        );
      });
    });
  });
}
