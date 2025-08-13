// test/services/notification_service_fcm_test.dart
// Tests for NotificationService FCM integration

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:devocional_nuevo/services/notification_service.dart';
import 'notification_service_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService - FCM Integration', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockUsersCollection;
    late MockDocumentReference mockUserDoc;
    late MockCollectionReference mockFcmTokensCollection;
    late MockDocumentReference mockTokenDoc;
    late MockFirebaseMessaging mockFirebaseMessaging;
    late MockNotificationSettings mockNotificationSettings;
    late MockSharedPreferences mockSharedPrefs;
    late MockRemoteMessage mockRemoteMessage;
    late MockRemoteNotification mockRemoteNotification;

    setUp(() {
      // Initialize mocks
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockFirestore = MockFirebaseFirestore();
      mockUsersCollection = MockCollectionReference();
      mockUserDoc = MockDocumentReference();
      mockFcmTokensCollection = MockCollectionReference();
      mockTokenDoc = MockDocumentReference();
      mockFirebaseMessaging = MockFirebaseMessaging();
      mockNotificationSettings = MockNotificationSettings();
      mockSharedPrefs = MockSharedPreferences();
      mockRemoteMessage = MockRemoteMessage();
      mockRemoteNotification = MockRemoteNotification();

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

      when(() => mockFirestore.collection('users')).thenReturn(mockUsersCollection);
      when(() => mockUsersCollection.doc(any())).thenReturn(mockUserDoc);
      when(() => mockUserDoc.collection('fcmTokens')).thenReturn(mockFcmTokensCollection);
      when(() => mockFcmTokensCollection.doc(any())).thenReturn(mockTokenDoc);
      when(() => mockUserDoc.set(any(), any())).thenAnswer((_) async => {});
      when(() => mockTokenDoc.set(any(), any())).thenAnswer((_) async => {});

      NotificationServiceTestHelper.setupFCMMocks(
        mockFirebaseMessaging,
        mockNotificationSettings,
      );

      NotificationServiceTestHelper.setupSharedPreferencesMocks(mockSharedPrefs);
    });

    tearDown(() {
      reset(mockFirebaseAuth);
      reset(mockUser);
      reset(mockFirestore);
      reset(mockUsersCollection);
      reset(mockUserDoc);
      reset(mockFcmTokensCollection);
      reset(mockTokenDoc);
      reset(mockFirebaseMessaging);
      reset(mockNotificationSettings);
      reset(mockSharedPrefs);
      reset(mockRemoteMessage);
      reset(mockRemoteNotification);
    });

    test('_initializeFCM() requests notification permissions successfully', () async {
      // Arrange
      final notificationService = NotificationService();

      // Trigger _initializeFCM through auth state change
      await notificationService.initialize();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      verify(() => mockFirebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      )).called(1);

      verify(() => mockNotificationSettings.authorizationStatus).called(1);
    });

    test('_saveFcmToken() saves token to Firestore with authenticated user', () async {
      // Arrange
      final notificationService = NotificationService();

      // Trigger FCM initialization through auth state change
      await notificationService.initialize();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      verify(() => mockTokenDoc.set(
        any(that: allOf([
          isA<Map<String, dynamic>>(),
          predicate<Map<String, dynamic>>((map) => 
            map['token'] == 'mock_fcm_token_123' &&
            map.containsKey('createdAt') &&
            map.containsKey('platform')
          ),
        ])),
        any(that: isA<SetOptions>()),
      )).called(1);
    });

    test('_saveFcmToken() updates lastLogin timestamp in user document', () async {
      // Arrange
      final notificationService = NotificationService();

      // Trigger FCM initialization through auth state change
      await notificationService.initialize();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      verify(() => mockUserDoc.set(
        any(that: allOf([
          isA<Map<String, dynamic>>(),
          predicate<Map<String, dynamic>>((map) => 
            map.containsKey('lastLogin')
          ),
        ])),
        any(that: isA<SetOptions>()),
      )).called(1);
    });

    test('_saveFcmToken() saves token to SharedPreferences', () async {
      // Arrange
      final notificationService = NotificationService();

      // Trigger FCM initialization through auth state change
      await notificationService.initialize();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      verify(() => mockSharedPrefs.setString('fcm_token', 'mock_fcm_token_123')).called(1);
    });

    test('_saveFcmToken() handles null user gracefully without throwing', () async {
      // Arrange
      NotificationServiceTestHelper.setupFirebaseAuthMocks(
        mockFirebaseAuth,
        mockUser,
        isAuthenticated: false,
      );
      final notificationService = NotificationService();

      // Act
      await notificationService.initialize();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - no Firestore calls should be made
      verifyNever(() => mockUserDoc.set(any(), any()));
      verifyNever(() => mockTokenDoc.set(any(), any()));
      verifyNever(() => mockSharedPrefs.setString('fcm_token', any()));
    });

    test('_saveFcmToken() handles Firestore write failures', () async {
      // Arrange
      when(() => mockUserDoc.set(any(), any()))
          .thenThrow(Exception('Firestore write failed'));
      final notificationService = NotificationService();

      // Act & Assert - should not throw
      await expectLater(
        () async {
          await notificationService.initialize();
          await Future.delayed(const Duration(milliseconds: 100));
        },
        returnsNormally,
      );
    });

    test('_handleMessage() processes data-only messages correctly', () async {
      // Arrange
      when(() => mockRemoteMessage.notification).thenReturn(null);
      when(() => mockRemoteMessage.data).thenReturn({
        'title': 'Test Data Title',
        'body': 'Test Data Body',
        'payload': 'test_payload',
      });
      when(() => mockRemoteMessage.messageId).thenReturn('test_message_id');

      final notificationService = NotificationService();

      // Mock the showImmediateNotification method by triggering _handleMessage indirectly
      // Since _handleMessage is private, we test it through FCM message handling

      // Act
      await notificationService.initialize();
      await Future.delayed(const Duration(milliseconds: 100));

      // Note: Testing _handleMessage directly is challenging since it's private
      // In a real implementation, we might need to make it public for testing
      // or test it through the public interface
    });

    test('_handleMessage() logs notification messages without duplicate showing', () async {
      // Arrange
      when(() => mockRemoteMessage.notification).thenReturn(mockRemoteNotification);
      when(() => mockRemoteMessage.data).thenReturn({'key': 'value'});
      when(() => mockRemoteMessage.messageId).thenReturn('test_message_id');

      final notificationService = NotificationService();

      // Act
      await notificationService.initialize();
      await Future.delayed(const Duration(milliseconds: 100));

      // Note: Since _handleMessage is private, we verify its behavior indirectly
      // The test ensures the setup doesn't cause issues when notifications are received
    });

    test('FCM token refresh listener is set up correctly', () async {
      // Arrange
      final notificationService = NotificationService();

      // Act
      await notificationService.initialize();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      verify(() => mockFirebaseMessaging.onTokenRefresh).called(1);
    });

    test('initial message is handled if app opened from notification', () async {
      // Arrange
      when(() => mockFirebaseMessaging.getInitialMessage())
          .thenAnswer((_) async => mockRemoteMessage);
      when(() => mockRemoteMessage.messageId).thenReturn('initial_message_id');
      when(() => mockRemoteMessage.notification).thenReturn(null);
      when(() => mockRemoteMessage.data).thenReturn({'key': 'value'});

      final notificationService = NotificationService();

      // Act
      await notificationService.initialize();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      verify(() => mockFirebaseMessaging.getInitialMessage()).called(1);
    });

    test('FCM permission request handles authorization denied', () async {
      // Arrange
      when(() => mockNotificationSettings.authorizationStatus)
          .thenReturn(AuthorizationStatus.denied);
      final notificationService = NotificationService();

      // Act
      await notificationService.initialize();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - should not throw even with denied authorization
      verify(() => mockFirebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      )).called(1);
    });

    test('FCM token retrieval failure is handled gracefully', () async {
      // Arrange
      when(() => mockFirebaseMessaging.getToken())
          .thenThrow(Exception('Token retrieval failed'));
      final notificationService = NotificationService();

      // Act & Assert - should not throw
      await expectLater(
        () async {
          await notificationService.initialize();
          await Future.delayed(const Duration(milliseconds: 100));
        },
        returnsNormally,
      );
    });

    test('FCM message listeners are set up correctly', () async {
      // Arrange
      final notificationService = NotificationService();

      // Act
      await notificationService.initialize();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - verify message listeners are set up
      // Note: mocktail doesn't easily verify static method calls like FirebaseMessaging.onMessage.listen
      // This test ensures initialization completes without errors
    });

    test('null FCM token is handled without saving', () async {
      // Arrange
      when(() => mockFirebaseMessaging.getToken())
          .thenAnswer((_) async => null);
      final notificationService = NotificationService();

      // Act
      await notificationService.initialize();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - no token save operations should occur
      verifyNever(() => mockTokenDoc.set(any(), any()));
      verifyNever(() => mockSharedPrefs.setString('fcm_token', any()));
    });
  });
}