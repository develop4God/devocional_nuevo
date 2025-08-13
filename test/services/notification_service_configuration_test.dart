// test/services/notification_service_configuration_test.dart
// Tests for NotificationService configuration management

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:devocional_nuevo/services/notification_service.dart';
import 'notification_service_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService - Configuration Management', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockUsersCollection;
    late MockDocumentReference mockUserDoc;
    late MockCollectionReference mockSettingsCollection;
    late MockDocumentReference mockNotificationDoc;
    late MockDocumentSnapshot mockDocSnapshot;
    late MockSharedPreferences mockSharedPrefs;

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
      mockSharedPrefs = MockSharedPreferences();

      // Register fallback values
      registerFallbackValue(const SetOptions());
      registerFallbackValue({});
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
      reset(mockSharedPrefs);
    });

    test('areNotificationsEnabled() returns default true when no prefs exist', () async {
      // Arrange
      when(() => mockSharedPrefs.getBool('notifications_enabled')).thenReturn(null);
      final notificationService = NotificationService();

      // Act
      final result = await notificationService.areNotificationsEnabled();

      // Assert
      expect(result, isTrue);
      verify(() => mockSharedPrefs.getBool('notifications_enabled')).called(1);
    });

    test('areNotificationsEnabled() returns stored boolean from SharedPreferences', () async {
      // Arrange
      when(() => mockSharedPrefs.getBool('notifications_enabled')).thenReturn(false);
      final notificationService = NotificationService();

      // Act
      final result = await notificationService.areNotificationsEnabled();

      // Assert
      expect(result, isFalse);
      verify(() => mockSharedPrefs.getBool('notifications_enabled')).called(1);
    });

    test('setNotificationsEnabled(true) persists to both SharedPrefs and Firestore when user authenticated', () async {
      // Arrange
      final notificationService = NotificationService();

      // Act
      await notificationService.setNotificationsEnabled(true);

      // Assert
      verify(() => mockSharedPrefs.setBool('notifications_enabled', true)).called(1);
      verify(() => mockNotificationDoc.get()).called(1);
      verify(() => mockNotificationDoc.set(
        any(that: allOf([
          isA<Map<String, dynamic>>(),
          predicate<Map<String, dynamic>>((map) => 
            map['notificationsEnabled'] == true &&
            map.containsKey('notificationTime') &&
            map.containsKey('userTimezone') &&
            map.containsKey('lastUpdated')
          ),
        ])),
        any(that: isA<SetOptions>()),
      )).called(1);
    });

    test('setNotificationsEnabled(false) persists state and skips Firestore when user null', () async {
      // Arrange
      NotificationServiceTestHelper.setupFirebaseAuthMocks(
        mockFirebaseAuth,
        mockUser,
        isAuthenticated: false,
      );
      final notificationService = NotificationService();

      // Act
      await notificationService.setNotificationsEnabled(false);

      // Assert
      verify(() => mockSharedPrefs.setBool('notifications_enabled', false)).called(1);
      verifyNever(() => mockNotificationDoc.get());
      verifyNever(() => mockNotificationDoc.set(any(), any()));
    });

    test('getNotificationTime() returns default "09:00" when no prefs exist', () async {
      // Arrange
      when(() => mockSharedPrefs.getString('notification_time')).thenReturn(null);
      final notificationService = NotificationService();

      // Act
      final result = await notificationService.getNotificationTime();

      // Assert
      expect(result, equals('09:00'));
      verify(() => mockSharedPrefs.getString('notification_time')).called(1);
    });

    test('getNotificationTime() returns stored time from SharedPreferences', () async {
      // Arrange
      when(() => mockSharedPrefs.getString('notification_time')).thenReturn('15:30');
      final notificationService = NotificationService();

      // Act
      final result = await notificationService.getNotificationTime();

      // Assert
      expect(result, equals('15:30'));
      verify(() => mockSharedPrefs.getString('notification_time')).called(1);
    });

    test('setNotificationTime() updates SharedPrefs and Firestore with authenticated user', () async {
      // Arrange
      final notificationService = NotificationService();

      // Act
      await notificationService.setNotificationTime('14:30');

      // Assert
      verify(() => mockSharedPrefs.setString('notification_time', '14:30')).called(1);
      verify(() => mockNotificationDoc.get()).called(1);
      verify(() => mockNotificationDoc.set(
        any(that: allOf([
          isA<Map<String, dynamic>>(),
          predicate<Map<String, dynamic>>((map) => 
            map['notificationTime'] == '14:30' &&
            map.containsKey('notificationsEnabled') &&
            map.containsKey('userTimezone') &&
            map.containsKey('lastUpdated')
          ),
        ])),
        any(that: isA<SetOptions>()),
      )).called(1);
    });

    test('setNotificationTime() handles Firestore write failures gracefully', () async {
      // Arrange
      when(() => mockNotificationDoc.set(any(), any()))
          .thenThrow(Exception('Firestore write failed'));
      final notificationService = NotificationService();

      // Act & Assert - should not throw
      await expectLater(
        () => notificationService.setNotificationTime('16:00'),
        returnsNormally,
      );

      // Verify SharedPrefs was still updated
      verify(() => mockSharedPrefs.setString('notification_time', '16:00')).called(1);
    });

    test('setNotificationTime() skips Firestore when user not authenticated', () async {
      // Arrange
      NotificationServiceTestHelper.setupFirebaseAuthMocks(
        mockFirebaseAuth,
        mockUser,
        isAuthenticated: false,
      );
      final notificationService = NotificationService();

      // Act
      await notificationService.setNotificationTime('12:00');

      // Assert
      verify(() => mockSharedPrefs.setString('notification_time', '12:00')).called(1);
      verifyNever(() => mockNotificationDoc.get());
      verifyNever(() => mockNotificationDoc.set(any(), any()));
    });

    test('setNotificationsEnabled() handles Firestore read failure gracefully', () async {
      // Arrange
      when(() => mockNotificationDoc.get())
          .thenThrow(Exception('Firestore read failed'));
      final notificationService = NotificationService();

      // Act & Assert - should not throw
      await expectLater(
        () => notificationService.setNotificationsEnabled(true),
        returnsNormally,
      );

      // Verify SharedPrefs was still updated
      verify(() => mockSharedPrefs.setBool('notifications_enabled', true)).called(1);
    });

    test('setNotificationTime() handles Firestore read failure gracefully', () async {
      // Arrange
      when(() => mockNotificationDoc.get())
          .thenThrow(Exception('Firestore read failed'));
      final notificationService = NotificationService();

      // Act & Assert - should not throw
      await expectLater(
        () => notificationService.setNotificationTime('10:30'),
        returnsNormally,
      );

      // Verify SharedPrefs was still updated
      verify(() => mockSharedPrefs.setString('notification_time', '10:30')).called(1);
    });

    test('setNotificationsEnabled() uses existing Firestore values when available', () async {
      // Arrange
      final existingData = {
        'notificationsEnabled': false,
        'notificationTime': '18:00',
        'userTimezone': 'Europe/London',
      };
      when(() => mockDocSnapshot.data()).thenReturn(existingData);
      final notificationService = NotificationService();

      // Act
      await notificationService.setNotificationsEnabled(true);

      // Assert
      verify(() => mockNotificationDoc.set(
        any(that: allOf([
          isA<Map<String, dynamic>>(),
          predicate<Map<String, dynamic>>((map) => 
            map['notificationsEnabled'] == true &&
            map['notificationTime'] == '18:00' &&
            map['userTimezone'] == 'Europe/London' &&
            map.containsKey('lastUpdated')
          ),
        ])),
        any(that: isA<SetOptions>()),
      )).called(1);
    });

    test('setNotificationTime() uses existing Firestore values when available', () async {
      // Arrange
      final existingData = {
        'notificationsEnabled': false,
        'notificationTime': '08:00',
        'userTimezone': 'Asia/Tokyo',
      };
      when(() => mockDocSnapshot.data()).thenReturn(existingData);
      final notificationService = NotificationService();

      // Act
      await notificationService.setNotificationTime('20:00');

      // Assert
      verify(() => mockNotificationDoc.set(
        any(that: allOf([
          isA<Map<String, dynamic>>(),
          predicate<Map<String, dynamic>>((map) => 
            map['notificationsEnabled'] == false &&
            map['notificationTime'] == '20:00' &&
            map['userTimezone'] == 'Asia/Tokyo' &&
            map.containsKey('lastUpdated')
          ),
        ])),
        any(that: isA<SetOptions>()),
      )).called(1);
    });
  });
}