// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:devocional_nuevo/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

patrolTest(
  'should show "Descargar devocionales" with download icon when no local data',
  (tester) async {
    app.main();
    await tester.pumpAndSettle();
    await tester('Open Drawer').tap();
    await tester('#drawer_download_devotionals').waitUntilVisible();
    expect(tester('#drawer_download_devotionals').visible, isTrue);
    expect(tester('Descargar devocionales').visible, isTrue);
    expect(tester('Para uso sin internet').visible, isTrue);
  },
);

patrolTest(
  'should show "Disfruta contenido sin internet" with offline pin icon when local data exists',
  (tester) async {
    app.main();
    await tester.pumpAndSettle();
    await tester('Open Drawer').tap();
    await tester('#drawer_download_devotionals').waitUntilVisible();
    expect(tester('Descargar devocionales').visible, isTrue);
    expect(tester('Disfruta contenido sin internet').visible, isTrue);
  },
);

patrolTest('should open download confirmation dialog when tapped', (tester) async {
  app.main();
  await tester.pumpAndSettle();
  await tester('Open Drawer').tap();
  await tester('#drawer_download_devotionals').waitUntilVisible();
  await tester('#drawer_download_devotionals').tap();
  await tester('⬇️✨ Confirmar descarga').waitUntilVisible();
  expect(tester('⬇️✨ Confirmar descarga').visible, isTrue);
  expect(tester('Esta descarga se realiza una sola vez').visible, isTrue);
  expect(tester('Cancelar').visible, isTrue);
  expect(tester('Aceptar').visible, isTrue);
});
