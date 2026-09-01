@Tags(['unit', 'pages'])
library;

import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_repository.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/pages/notification_config_page.dart';
import 'package:devocional_nuevo/services/auth_service.dart';
import 'package:devocional_nuevo/services/notification_service.dart';
import 'package:devocional_nuevo/services/push_messaging.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/user_profile_store.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

class TestThemeBloc extends ThemeBloc {
  TestThemeBloc() : super(repository: ThemeRepository()) {
    emit(
      ThemeLoaded(
        themeFamily: ThemeRepository.defaultThemeFamily,
        brightness: Brightness.light,
        themeData: ThemeData.light(),
      ),
    );
  }
}

Future<void> pumpPage(
  WidgetTester tester, {
  required MockFirebaseAuth auth,
  required FakeFirebaseFirestore firestore,
}) async {
  await tester.pumpWidget(
    BlocProvider<ThemeBloc>(
      create: (_) => TestThemeBloc(),
      child: MaterialApp(
        home: NotificationConfigPage(auth: auth, firestore: firestore),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('NotificationConfigPage', () {
    setUp(() async {
      await registerTestServicesWithFakes();

      // NotificationService's own factory always wires real Firebase-backed
      // dependencies (FirestoreUserProfileStore, FirebaseCloudMessaging),
      // bypassing the fakes registerTestServicesWithFakes() swapped in for
      // IUserProfileStore/IPushMessaging. Override it directly so the
      // service methods the page calls don't hit real Firebase.
      final locator = ServiceLocator();
      locator.unregister<NotificationService>();
      locator.registerSingleton<NotificationService>(
        NotificationService.create(
          authService: locator.get<IAuthService>(),
          userProfileStore: locator.get<IUserProfileStore>(),
          pushMessaging: locator.get<IPushMessaging>(),
        ),
      );
    });

    testWidgets(
      'loads existing settings from Firestore and renders enabled switch',
      (tester) async {
        final mockUser = MockUser(uid: 'user-1');
        final auth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
        final firestore = FakeFirebaseFirestore();
        await firestore
            .collection('users')
            .doc('user-1')
            .collection('settings')
            .doc('notifications')
            .set({
          'notificationsEnabled': false,
          'notificationTime': '07:30',
        });

        await pumpPage(tester, auth: auth, firestore: firestore);

        final switchWidget = tester.widget<Switch>(find.byType(Switch));
        expect(switchWidget.value, isFalse);
        expect(find.text('7:30 AM'), findsOneWidget);
      },
    );

    testWidgets(
      'creates default settings document when none exists',
      (tester) async {
        final mockUser = MockUser(uid: 'user-2');
        final auth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
        final firestore = FakeFirebaseFirestore();

        await pumpPage(tester, auth: auth, firestore: firestore);

        final docRef = firestore
            .collection('users')
            .doc('user-2')
            .collection('settings')
            .doc('notifications');
        final snapshot = await docRef.get();

        expect(snapshot.exists, isTrue);
        expect(snapshot.data()!['notificationsEnabled'], isTrue);
        expect(snapshot.data()!['notificationTime'], isNotNull);

        final switchWidget = tester.widget<Switch>(find.byType(Switch));
        expect(switchWidget.value, isTrue);
      },
    );

    testWidgets(
      'toggling the switch updates Firestore and flips the UI',
      (tester) async {
        final mockUser = MockUser(uid: 'user-3');
        final auth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
        final firestore = FakeFirebaseFirestore();
        final docRef = firestore
            .collection('users')
            .doc('user-3')
            .collection('settings')
            .doc('notifications');
        await docRef.set({
          'notificationsEnabled': true,
          'notificationTime': '09:00',
        });

        await pumpPage(tester, auth: auth, firestore: firestore);

        expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

        final snapshot = await docRef.get();
        expect(snapshot.data()!['notificationsEnabled'], isFalse);
      },
    );

    testWidgets(
      'confirm button is disabled until a new time is picked',
      (tester) async {
        final mockUser = MockUser(uid: 'user-4');
        final auth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
        final firestore = FakeFirebaseFirestore();
        await firestore
            .collection('users')
            .doc('user-4')
            .collection('settings')
            .doc('notifications')
            .set({
          'notificationsEnabled': true,
          'notificationTime': '09:00',
        });

        await pumpPage(tester, auth: auth, firestore: firestore);

        final confirmButton = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(confirmButton.onPressed, isNull);
      },
    );
  });
}
