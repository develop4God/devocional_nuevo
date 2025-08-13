// test/services/notification_service_settings_test.dart
// Tests for NotificationService settings persistence

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:devocional_nuevo/services/notification_service.dart';
import 'notification_service_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService - Settings Persistence', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockUsersCollection;
    late MockDocumentReference mockUserDoc;
    late MockCollectionReference mockSettingsCollection;
    late MockDocumentReference mockNotificationDoc;

    setUp(() {
      // Initialize mocks
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockFirestore = MockFirebaseFirestore();
      mockUsersCollection = MockCollectionReference();
      mockUserDoc = MockDocumentReference();
      mockSettingsCollection = MockCollectionReference();
      mockNotificationDoc = MockDocumentReference();

      // Register fallback values
      registerFallbackValue(const SetOptions());
      registerFallbackValue({});
      registerFallbackValue(FieldValue.serverTimestamp());

      // Setup default mocks
      NotificationServiceTestHelper.setupFirebaseAuthMocks(
        mockFirebaseAuth,
        mockUser,
        userId: 'test_user_456',
        isAuthenticated: true,
      );

      when(() => mockFirestore.collection('users')).thenReturn(mockUsersCollection);
      when(() => mockUsersCollection.doc(any())).thenReturn(mockUserDoc);
      when(() => mockUserDoc.collection('settings')).thenReturn(mockSettingsCollection);
      when(() => mockSettingsCollection.doc('notifications')).thenReturn(mockNotificationDoc);
      when(() => mockNotificationDoc.set(any(), any())).thenAnswer((_) async => {});
    });

    tearDown(() {
      reset(mockFirebaseAuth);
      reset(mockUser);
      reset(mockFirestore);
      reset(mockUsersCollection);
      reset(mockUserDoc);
      reset(mockSettingsCollection);
      reset(mockNotificationDoc);
    });

    test('_saveNotificationSettingsToFirestore() writes complete settings object', () async {
      // Arrange
      final notificationService = NotificationServiceTestHelper.createTestNotificationService(localNotificationsPlugin: mockLocalNotifications, firebaseMessaging: mockFirebaseMessaging, firestore: mockFirestore, auth: mockFirebaseAuth);

      // Since _saveNotificationSettingsToFirestore is private, we test it through public methods
      // that call it, like setNotificationsEnabled
      await notificationService.setNotificationsEnabled(true);

      // Assert
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

    test('_saveNotificationSettingsToFirestore() uses merge:true to preserve other fields', () async {
      // Arrange
      final notificationService = NotificationServiceTestHelper.createTestNotificationService(localNotificationsPlugin: mockLocalNotifications, firebaseMessaging: mockFirebaseMessaging, firestore: mockFirestore, auth: mockFirebaseAuth);

      // Act
      await notificationService.setNotificationsEnabled(false);

      // Assert
      verify(() => mockNotificationDoc.set(
        any(),
        any(that: allOf([
          isA<SetOptions>(),
          predicate<SetOptions>((options) => options.merge == true),
        ])),
      )).called(1);
    });

    test('_saveNotificationSettingsToFirestore() includes serverTimestamp for lastUpdated', () async {
      // Arrange
      final notificationService = NotificationServiceTestHelper.createTestNotificationService(localNotificationsPlugin: mockLocalNotifications, firebaseMessaging: mockFirebaseMessaging, firestore: mockFirestore, auth: mockFirebaseAuth);

      // Act
      await notificationService.setNotificationTime('11:30');

      // Assert
      verify(() => mockNotificationDoc.set(
        any(that: allOf([
          isA<Map<String, dynamic>>(),
          predicate<Map<String, dynamic>>((map) => 
            map.containsKey('lastUpdated')
          ),
        ])),
        any(that: isA<SetOptions>()),
      )).called(1);
    });

    test('_saveNotificationSettingsToFirestore() handles network failures', () async {
      // Arrange
      when(() => mockNotificationDoc.set(any(), any()))
          .thenThrow(Exception('Network error'));
      final notificationService = NotificationServiceTestHelper.createTestNotificationService(localNotificationsPlugin: mockLocalNotifications, firebaseMessaging: mockFirebaseMessaging, firestore: mockFirestore, auth: mockFirebaseAuth);

      // Act & Assert - should not throw
      await expectLater(
        () => notificationService.setNotificationsEnabled(true),
        returnsNormally,
      );
    });

    test('settings persistence handles concurrent operations correctly', () async {
      // Arrange
      final notificationService = NotificationServiceTestHelper.createTestNotificationService(localNotificationsPlugin: mockLocalNotifications, firebaseMessaging: mockFirebaseMessaging, firestore: mockFirestore, auth: mockFirebaseAuth);

      // Act - simulate concurrent operations
      final futures = [
        notificationService.setNotificationsEnabled(true),
        notificationService.setNotificationTime('13:45'),
      ];
      
      await Future.wait(futures);

      // Assert - both operations should complete
      verify(() => mockNotificationDoc.set(any(), any())).called(2);
    });

    test('settings persistence maintains data consistency across operations', () async {
      // Arrange
      final notificationService = NotificationServiceTestHelper.createTestNotificationService(localNotificationsPlugin: mockLocalNotifications, firebaseMessaging: mockFirebaseMessaging, firestore: mockFirestore, auth: mockFirebaseAuth);

      // Act - perform multiple settings operations
      await notificationService.setNotificationsEnabled(true);
      await notificationService.setNotificationTime('16:20');
      await notificationService.setNotificationsEnabled(false);

      // Assert - verify all operations called Firestore
      verify(() => mockNotificationDoc.set(any(), any())).called(3);
    });

    test('settings persistence handles Firestore timeout gracefully', () async {
      // Arrange
      when(() => mockNotificationDoc.set(any(), any()))
          .thenAnswer((_) => Future.delayed(const Duration(seconds: 30), () => {}));
      final notificationService = NotificationServiceTestHelper.createTestNotificationService(localNotificationsPlugin: mockLocalNotifications, firebaseMessaging: mockFirebaseMessaging, firestore: mockFirestore, auth: mockFirebaseAuth);

      // Act & Assert - should not hang or throw
      await expectLater(
        () => notificationService.setNotificationsEnabled(true),
        returnsNormally,
      );
    });

    test('settings persistence validates user authentication before write', () async {
      // Arrange
      NotificationServiceTestHelper.setupFirebaseAuthMocks(
        mockFirebaseAuth,
        mockUser,
        isAuthenticated: false,
      );
      final notificationService = NotificationServiceTestHelper.createTestNotificationService(localNotificationsPlugin: mockLocalNotifications, firebaseMessaging: mockFirebaseMessaging, firestore: mockFirestore, auth: mockFirebaseAuth);

      // Act
      await notificationService.setNotificationsEnabled(true);

      // Assert - no Firestore write should occur
      verifyNever(() => mockNotificationDoc.set(any(), any()));
    });

    test('settings persistence handles partial Firestore data correctly', () async {
      // Arrange
      final mockDocSnapshot = MockDocumentSnapshot();
      when(() => mockNotificationDoc.get()).thenAnswer((_) async => mockDocSnapshot);
      when(() => mockDocSnapshot.exists).thenReturn(true);
      when(() => mockDocSnapshot.data()).thenReturn({
        'notificationsEnabled': true,
        // Missing notificationTime and userTimezone
      });
      
      final notificationService = NotificationServiceTestHelper.createTestNotificationService(localNotificationsPlugin: mockLocalNotifications, firebaseMessaging: mockFirebaseMessaging, firestore: mockFirestore, auth: mockFirebaseAuth);

      // Act
      await notificationService.setNotificationTime('14:00');

      // Assert - should handle missing fields gracefully
      verify(() => mockNotificationDoc.set(
        any(that: allOf([
          isA<Map<String, dynamic>>(),
          predicate<Map<String, dynamic>>((map) => 
            map['notificationTime'] == '14:00' &&
            map['notificationsEnabled'] == true &&
            map.containsKey('userTimezone') // Should provide default
          ),
        ])),
        any(that: isA<SetOptions>()),
      )).called(1);
    });

    test('settings persistence handles empty Firestore document', () async {
      // Arrange
      final mockDocSnapshot = MockDocumentSnapshot();
      when(() => mockNotificationDoc.get()).thenAnswer((_) async => mockDocSnapshot);
      when(() => mockDocSnapshot.exists).thenReturn(true);
      when(() => mockDocSnapshot.data()).thenReturn({}); // Empty document
      
      final notificationService = NotificationServiceTestHelper.createTestNotificationService(localNotificationsPlugin: mockLocalNotifications, firebaseMessaging: mockFirebaseMessaging, firestore: mockFirestore, auth: mockFirebaseAuth);

      // Act
      await notificationService.setNotificationsEnabled(false);

      // Assert - should provide default values
      verify(() => mockNotificationDoc.set(
        any(that: allOf([
          isA<Map<String, dynamic>>(),
          predicate<Map<String, dynamic>>((map) => 
            map['notificationsEnabled'] == false &&
            map.containsKey('notificationTime') &&
            map.containsKey('userTimezone')
          ),
        ])),
        any(that: isA<SetOptions>()),
      )).called(1);
    });

    test('settings persistence uses correct Firestore collection path', () async {
      // Arrange
      final notificationService = NotificationServiceTestHelper.createTestNotificationService(localNotificationsPlugin: mockLocalNotifications, firebaseMessaging: mockFirebaseMessaging, firestore: mockFirestore, auth: mockFirebaseAuth);

      // Act
      await notificationService.setNotificationsEnabled(true);

      // Assert - verify correct path is used
      verify(() => mockFirestore.collection('users')).called(1);
      verify(() => mockUsersCollection.doc('test_user_456')).called(1);
      verify(() => mockUserDoc.collection('settings')).called(1);
      verify(() => mockSettingsCollection.doc('notifications')).called(1);
    });
  });
}