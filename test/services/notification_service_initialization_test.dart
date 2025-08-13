// test/services/notification_service_initialization_test.dart
// Tests for NotificationService initialization flow

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:devocional_nuevo/services/notification_service.dart';
import 'notification_service_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService - Initialization Flow', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockUsersCollection;
    late MockDocumentReference mockUserDoc;
    late MockCollectionReference mockSettingsCollection;
    late MockDocumentReference mockNotificationDoc;
    late MockDocumentSnapshot mockDocSnapshot;
    late MockFirebaseMessaging mockFirebaseMessaging;
    late MockNotificationSettings mockNotificationSettings;
    late MockSharedPreferences mockSharedPrefs;
    late MockFlutterLocalNotificationsPlugin mockLocalNotifications;
    late MockIOSFlutterLocalNotificationsPlugin mockIOSLocalNotifications;

    setUp(() {
      // Initialize mocks
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockFirestore = MockFirebaseFirestore();
      mockUsersCollection = MockCollectionReference();
      mockUserDoc = MockDocumentReference();
      mockSettingsCollection = MockCollectionReference();
      mockNotificationDoc = MockDocumentReference();
      mockDocSnapshot = MockDocumentSnapshot();
      mockFirebaseMessaging = MockFirebaseMessaging();
      mockNotificationSettings = MockNotificationSettings();
      mockSharedPrefs = MockSharedPreferences();
      mockLocalNotifications = MockFlutterLocalNotificationsPlugin();
      mockIOSLocalNotifications = MockIOSFlutterLocalNotificationsPlugin();

      // Register fallback values for mocktail
      registerFallbackValue(const SetOptions());
      registerFallbackValue(const InitializationSettings());
      registerFallbackValue({});
      registerFallbackValue(const NotificationDetails());
      registerFallbackValue(FieldValue.serverTimestamp());

      // Setup default mocks
      NotificationServiceTestHelper.setupFirebaseAuthMocks(
        mockFirebaseAuth,
        mockUser,
        userId: 'test_user_123',
        isAuthenticated: true,
      );

      NotificationServiceTestHelper.setupFirestoreMocks(
        mockFirestore,
        mockUsersCollection,
        mockUserDoc,
        mockSettingsCollection,
        mockNotificationDoc,
        mockDocSnapshot,
        docExists: true,
        docData: NotificationServiceTestHelper.createFirestoreNotificationSettings(),
      );

      NotificationServiceTestHelper.setupSharedPreferencesMocks(mockSharedPrefs);

      NotificationServiceTestHelper.setupFCMMocks(
        mockFirebaseMessaging,
        mockNotificationSettings,
      );

      NotificationServiceTestHelper.setupLocalNotificationsMocks(
        mockLocalNotifications,
        mockIOSLocalNotifications,
      );

      // Mock permission handling
      when(() => Permission.notification.request())
          .thenAnswer((_) async => PermissionStatus.granted);
      when(() => Permission.scheduleExactAlarm.isDenied)
          .thenAnswer((_) async => false);
      when(() => Permission.ignoreBatteryOptimizations.isDenied)
          .thenAnswer((_) async => false);
    });

    tearDown(() {
      reset(mockFirebaseAuth);
      reset(mockUser);
      reset(mockFirestore);
      reset(mockUsersCollection);
      reset(mockUserDoc);
      reset(mockSettingsCollection);
      reset(mockNotificationDoc);
      reset(mockDocSnapshot);
      reset(mockFirebaseMessaging);
      reset(mockNotificationSettings);
      reset(mockSharedPrefs);
      reset(mockLocalNotifications);
      reset(mockIOSLocalNotifications);
    });

    test('initialize() completes successfully with valid timezone', () async {
      // Arrange
      final notificationService = NotificationService.forTesting(
        localNotificationsPlugin: mockLocalNotifications,
        firebaseMessaging: mockFirebaseMessaging,
        firestore: mockFirestore,
        auth: mockFirebaseAuth,
      );

      // Act & Assert - should not throw
      await expectLater(
        () => notificationService.initialize(),
        returnsNormally,
      );

      // Verify local notifications initialization
      verify(() => mockLocalNotifications.initialize(
        any(),
        onDidReceiveNotificationResponse: any(named: 'onDidReceiveNotificationResponse'),
        onDidReceiveBackgroundNotificationResponse: any(named: 'onDidReceiveBackgroundNotificationResponse'),
      )).called(1);

      // Verify auth state listener setup
      verify(() => mockFirebaseAuth.authStateChanges()).called(1);
    });

    test('initialize() handles timezone initialization errors gracefully', () async {
      // Arrange
      final notificationService = NotificationService.forTesting(
        localNotificationsPlugin: mockLocalNotifications,
        firebaseMessaging: mockFirebaseMessaging,
        firestore: mockFirestore,
        auth: mockFirebaseAuth,
      );
      // Note: We can't easily mock static timezone methods, but we test that 
      // initialization doesn't fail if timezone setup has issues

      // Act & Assert - should not throw even if timezone setup fails
      await expectLater(
        () => notificationService.initialize(),
        returnsNormally,
      );
    });

    test('initialize() sets up auth state listener correctly', () async {
      // Arrange
      final notificationService = NotificationServiceTestHelper.createTestNotificationService(localNotificationsPlugin: mockLocalNotifications, firebaseMessaging: mockFirebaseMessaging, firestore: mockFirestore, auth: mockFirebaseAuth);

      // Act
      await notificationService.initialize();

      // Assert
      verify(() => mockFirebaseAuth.authStateChanges()).called(1);
    });

    test('initialize() requests permissions on first run', () async {
      // Arrange
      final notificationService = NotificationServiceTestHelper.createTestNotificationService(localNotificationsPlugin: mockLocalNotifications, firebaseMessaging: mockFirebaseMessaging, firestore: mockFirestore, auth: mockFirebaseAuth);

      // Act
      await notificationService.initialize();

      // Assert - verify permission request for Android
      verify(() => Permission.notification.request()).called(1);
    });

    test('initialize() handles permission denied scenarios', () async {
      // Arrange
      when(() => Permission.notification.request())
          .thenAnswer((_) async => PermissionStatus.denied);
      final notificationService = NotificationServiceTestHelper.createTestNotificationService(localNotificationsPlugin: mockLocalNotifications, firebaseMessaging: mockFirebaseMessaging, firestore: mockFirestore, auth: mockFirebaseAuth);

      // Act
      await notificationService.initialize();

      // Assert - should complete without throwing even with denied permissions
      verify(() => Permission.notification.request()).called(1);
    });

    test('initialize() handles FirebaseAuth.instance.authStateChanges() stream errors', () async {
      // Arrange
      when(() => mockFirebaseAuth.authStateChanges())
          .thenAnswer((_) => Stream.error(Exception('Auth stream error')));
      final notificationService = NotificationServiceTestHelper.createTestNotificationService(localNotificationsPlugin: mockLocalNotifications, firebaseMessaging: mockFirebaseMessaging, firestore: mockFirestore, auth: mockFirebaseAuth);

      // Act & Assert - should not throw
      await expectLater(
        () => notificationService.initialize(),
        returnsNormally,
      );
    });

    test('initialize() processes authenticated user and initializes FCM', () async {
      // Arrange
      final notificationService = NotificationServiceTestHelper.createTestNotificationService(localNotificationsPlugin: mockLocalNotifications, firebaseMessaging: mockFirebaseMessaging, firestore: mockFirestore, auth: mockFirebaseAuth);

      // Act
      await notificationService.initialize();

      // Give some time for the auth state stream to process
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - FCM initialization should happen when user is authenticated
      verify(() => mockFirebaseMessaging.requestPermission(
        alert: any(named: 'alert'),
        announcement: any(named: 'announcement'),
        badge: any(named: 'badge'),
        carPlay: any(named: 'carPlay'),
        criticalAlert: any(named: 'criticalAlert'),
        provisional: any(named: 'provisional'),
        sound: any(named: 'sound'),
      )).called(1);

      verify(() => mockFirebaseMessaging.getToken()).called(1);
    });

    test('initialize() handles null user in auth state changes', () async {
      // Arrange
      NotificationServiceTestHelper.setupFirebaseAuthMocks(
        mockFirebaseAuth,
        mockUser,
        isAuthenticated: false,
      );
      final notificationService = NotificationServiceTestHelper.createTestNotificationService(localNotificationsPlugin: mockLocalNotifications, firebaseMessaging: mockFirebaseMessaging, firestore: mockFirestore, auth: mockFirebaseAuth);

      // Act
      await notificationService.initialize();

      // Give some time for the auth state stream to process
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - FCM should not be initialized when user is null
      verifyNever(() => mockFirebaseMessaging.requestPermission(
        alert: any(named: 'alert'),
        announcement: any(named: 'announcement'),
        badge: any(named: 'badge'),
        carPlay: any(named: 'carPlay'),
        criticalAlert: any(named: 'criticalAlert'),
        provisional: any(named: 'provisional'),
        sound: any(named: 'sound'),
      ));
    });

    test('initialize() saves notification settings to Firestore on authentication', () async {
      // Arrange
      final notificationService = NotificationServiceTestHelper.createTestNotificationService(localNotificationsPlugin: mockLocalNotifications, firebaseMessaging: mockFirebaseMessaging, firestore: mockFirestore, auth: mockFirebaseAuth);

      // Act
      await notificationService.initialize();

      // Give some time for the auth state stream to process
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - Firestore settings should be saved
      verify(() => mockNotificationDoc.get()).called(1);
      verify(() => mockNotificationDoc.set(
        any(that: allOf([
          isA<Map<String, dynamic>>(),
          predicate<Map<String, dynamic>>((map) => 
            map.containsKey('notificationsEnabled') &&
            map.containsKey('notificationTime') &&
            map.containsKey('userTimezone') &&
            map.containsKey('lastUpdated')
          ),
        ])),
        any(that: isA<SetOptions>()),
      )).called(1);
    });

    test('initialize() handles Firestore read errors gracefully', () async {
      // Arrange
      when(() => mockNotificationDoc.get())
          .thenThrow(Exception('Firestore read error'));
      final notificationService = NotificationServiceTestHelper.createTestNotificationService(localNotificationsPlugin: mockLocalNotifications, firebaseMessaging: mockFirebaseMessaging, firestore: mockFirestore, auth: mockFirebaseAuth);

      // Act & Assert - should not throw
      await expectLater(
        () => notificationService.initialize(),
        returnsNormally,
      );
    });

    test('initialize() handles local notifications plugin initialization failure', () async {
      // Arrange
      when(() => mockLocalNotifications.initialize(
        any(),
        onDidReceiveNotificationResponse: any(named: 'onDidReceiveNotificationResponse'),
        onDidReceiveBackgroundNotificationResponse: any(named: 'onDidReceiveBackgroundNotificationResponse'),
      )).thenThrow(Exception('Local notifications init failed'));
      final notificationService = NotificationServiceTestHelper.createTestNotificationService(localNotificationsPlugin: mockLocalNotifications, firebaseMessaging: mockFirebaseMessaging, firestore: mockFirestore, auth: mockFirebaseAuth);

      // Act & Assert - should not throw, error should be caught and logged
      await expectLater(
        () => notificationService.initialize(),
        returnsNormally,
      );
    });
  });
}